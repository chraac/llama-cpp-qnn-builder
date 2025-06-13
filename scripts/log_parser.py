import argparse
import csv
import enum
import os
import re
from typing import Iterator

# [profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 279 us
# [profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 328 us
OP_BREAKDOWN_LINE = re.compile(
    r'\[profiler]\[hexagon-npu]\[0x[a-f0-9]+](update|compute), handle\(0x[a-f0-9]+\), dur: (\d+) us'
)

# [profiler][MUL_MAT]compute, [hexagon-npu]: 976 us, [CPU]: 99 us
# [profiler][NONE]compute, [hexagon-npu]: 667 us, [CPU]: 4 us
OP_TIME_CONSUME_LINE = re.compile(
    r'\[profiler]\[([A-Z_]+)]compute, \[hexagon-npu]: (\d+) us, \[CPU]: (\d+) us'
)

# MUL(type=f16,ne=[10,5,4,3],nr=[1,1,1,1]): [1;32mOK[0m
# MUL_MAT(type_a=q4_K,type_b=f32,m=16,n=8,k=256,bs=[2,3],nr=[1,1],per=[0,3,2,1],v=0): [1;32mOK[0m
# FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=4,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=f16,permute=[0,1,2,3]): [1;32mOK[0m
OP_SECTION_END = re.compile(r' +([A-Z_]+)\(([^(]+)\): \[1;32mOK\[0m')

OP_PROP_ITEM = re.compile(r'([a-zA-Z_]+)=(([a-zA-Z0-9_]+)|(\[[0-9,]+]))[ ,]*')
OP_TYPE_PROPS = re.compile(r'type[_a-zA-Z]*')
OP_FLOAT_PROPS = re.compile(r'max_bias|logit_softcap')
OP_BOOL_PROPS = re.compile(r'mask')
OP_ARRAY_PROPS = re.compile(r'ne|nr|bs|per|permute|[mnkv]|hsk|hsv|nh|kv|nb')
OP_ARRAY_PROP_ITEMS = re.compile(r'\[([0-9]+,?)+]')


class OpData:
    def __init__(self, name: str, total_us: int, cpu_total_us: int, update_us: int, compute_us: int):
        self.name = name
        self.total_us = total_us
        self.cpu_total_us = cpu_total_us
        self.update_us = update_us
        self.compute_us = compute_us

    def __repr__(self) -> str:
        return (f'OpData(name={self.name}, total_us={self.total_us}, update_us={self.update_us},'
                f' compute_us={self.compute_us})')


class OpTensor:
    class DataType(enum.Enum):
        NONE = 'none'
        F16 = 'f16'
        F32 = 'f32'
        Q4_K = 'q4_K'
        Q8_K = 'q8_K'
        Q4_0 = 'q4_0'
        Q8_0 = 'q8_0'

    def __init__(self, dtype: DataType, shape: list[int], permute: list[int] | None = None):
        self.dtype = dtype
        self.shape = shape
        self.permute = permute if permute is not None else [0, 1, 2, 3]

    def __repr__(self) -> str:
        return f'OpTensor(dtype={self.dtype.value}, shape={self.shape}, permute={self.permute})'


class OpItem:
    class Fields(enum.Enum):
        NAME = 'name'
        DIMS = 'dims'
        TYPE = 'type'
        CPU_TOTAL_US = 'cpu_total_us'
        TOTAL_US = 'total_us'
        UPDATE_US = 'update_us'
        COMPUTE_US = 'compute_us'

    def __init__(self, name: str, prop: str, data: OpData):
        self.name: str = name
        self.data: OpData = data
        self.raw_prop: str = prop
        self.props: list = OpItem.__parse_prop(prop)
        self._output_tensor = None

    def __repr__(self) -> str:
        return f'OpItem(name={self.name}, data={self.data})'

    def get_output_tensor(self) -> OpTensor:
        return self._output_tensor

    def to_list_props(self) -> dict[Fields: str]:
        ret: dict[OpItem.Fields: str] = {
            OpItem.Fields.NAME: self.name,
            OpItem.Fields.DIMS: OpItem.__dims_to_str(self.get_output_tensor().shape),
            OpItem.Fields.TYPE: str(self.get_output_tensor().dtype.value),
            OpItem.Fields.CPU_TOTAL_US: str(self.data.cpu_total_us),
            OpItem.Fields.TOTAL_US: str(self.data.total_us),
            OpItem.Fields.UPDATE_US: str(self.data.update_us),
            OpItem.Fields.COMPUTE_US: str(self.data.compute_us),
        }
        return self._to_list_props(ret)

    # noinspection PyMethodMayBeStatic
    def _to_list_props(self, dic: dict[Fields: str]) -> dict[Fields: str]:
        return dic

    @staticmethod
    def list_from_iterable(lines: Iterator) -> list:
        lst: list[OpItem] = []
        update_us: int = 0
        compute_us: int = 0
        dic: dict[str:OpData] = {}
        for line in lines:
            if match := OP_BREAKDOWN_LINE.match(line):
                item_type = match.group(1)
                if item_type == 'update':
                    update_us = int(match.group(2))
                elif item_type == 'compute':
                    compute_us = int(match.group(2))
            elif match := OP_TIME_CONSUME_LINE.match(line):
                op_name = match.group(1)
                if op_name != 'NONE':
                    dic[op_name] = OpData(op_name, int(match.group(2)), int(match.group(3)), update_us, compute_us)
            elif match := OP_SECTION_END.match(line):
                op_name = match.group(1)
                if dic[op_name]:
                    data = dic[op_name]
                    lst.append(OpItem(name=op_name, prop=match.group(2), data=data))
            else:
                continue
        return lst

    @staticmethod
    def __parse_prop(prop: str) -> dict[str:(OpTensor.DataType | int | float | bool | list)]:
        ret = {}
        for match in OP_PROP_ITEM.finditer(prop):
            key = match.group(1)
            value = match.group(2)
            if key == 'prec':
                ret[key] = OpTensor.DataType.NONE if value == 'def' else OpTensor.DataType(value)
            elif OP_TYPE_PROPS.match(key):
                ret[key] = OpTensor.DataType(value)
            elif OP_FLOAT_PROPS.match(key):
                ret[key] = float(value)
            elif OP_BOOL_PROPS.match(key):
                ret[key] = value == '1'
            elif OP_ARRAY_PROPS.match(key):
                if OP_ARRAY_PROP_ITEMS.match(value):
                    array_str = filter(lambda s: len(s) > 0, re.split(r'[,\[\]]', value))
                    ret[key] = list(map(int, array_str))
                else:
                    ret[key] = int(value)
            else:
                continue
        return ret

    @staticmethod
    def __dims_to_str(dims: list[int]) -> str:
        return 'x'.join(map(str, dims))


class OpUnary(OpItem):
    def __init__(self, name: str, prop: str, data: OpData):
        super().__init__(name, prop, data)
        self._output_tensor = OpTensor(
            dtype=self.props['type'],
            shape=self.props['ne'],
            permute=None,
        )

    def __repr__(self) -> str:
        return f'OpUnary(name={self.name}, tensor={self.tensor}, data={self.data})'


class OpBinary(OpItem):
    def __init__(self, name: str, prop: str, data: OpData):
        super().__init__(name, prop, data)
        self._output_tensor = OpTensor(
            dtype=self.props['type'],
            shape=self.props['ne'],
            permute=None,
        )

    def __repr__(self) -> str:
        return f'OpUnary(name={self.name}, tensor={self.tensor}, data={self.data})'


class OpMulMat(OpItem):
    def __init__(self, name: str, prop: str, data: OpData):
        super().__init__(name, prop, data)
        self._output_tensor = OpTensor(
            dtype=self.props['type_b'],
            shape=[self.props['k'], self.props['m'], self.props['n'], 1],
            permute=self.props['per'],
        )

    def __repr__(self) -> str:
        return f'OpMulMat(name={self.name}, tensor={self.tensor}, data={self.data})'


class OpFlashAttnExt(OpItem):
    def __init__(self, name: str, prop: str, data: OpData):
        super().__init__(name, prop, data)
        self._output_tensor = OpTensor(
            dtype=self.props['type_KV'],
            shape=[self.props['hsk'], self.props['nh'] * self.props['nr'], self.props['nb'], 1],
            permute=self.props['permute'],
        )

    def __repr__(self) -> str:
        return f'OpFlashAttnExt(name={self.name}, tensor={self.tensor}, data={self.data})'


def items_from_iterable(lines: Iterator) -> list[OpItem]:
    def map_item_subtype(item: OpItem) -> OpItem:
        if item.name == 'MUL_MAT':
            return OpMulMat(name=item.name, prop=item.raw_prop, data=item.data)
        elif item.name == 'FLASH_ATTN_EXT':
            return OpFlashAttnExt(name=item.name, prop=item.raw_prop, data=item.data)
        elif item.name == 'RMS_NORM':
            return OpUnary(name=item.name, prop=item.raw_prop, data=item.data)
        return OpBinary(name=item.name, prop=item.raw_prop, data=item.data)

    lst: list[OpItem] = OpItem.list_from_iterable(lines)
    return [map_item_subtype(it) for it in lst]


class LogParser:

    def __init__(self, input_file: str, encoding: str | None):
        self._input_file = input_file
        self._encoding = encoding

    def parse_and_save(self, output_file: str):
        ops: list[OpItem] = []
        print(f'Parsing log file: {self._input_file} with encoding: {self._encoding}')
        with open(self._input_file, 'r', encoding=self._encoding) as file:
            ops = items_from_iterable(file)
        print('Successfully parsed log file, now saving to CSV...')
        LogParser.__save_csv(ops, output_file)
        print(f'Successfully saved {len(ops)} operations to {output_file}.')

    @staticmethod
    def __save_csv(ops: list[OpItem], output_file: str):
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([e.value for e in OpItem.Fields])
            for item in ops:
                props = item.to_list_props()
                writer.writerow([props[e] for e in OpItem.Fields])


def get_file_encoding(file_name: str) -> str | None:
    """
    Detect the encoding of a file.
    :param file_name: The name of the file to check.
    :return: The detected encoding, or 'utf-8' if detection fails.
    """
    enc_list = [
        'utf_16_beUTF-16BEall',
        'utf_16_le',
        'utf_8',
        'unicode_escape',
        'unicode_internal',
    ]
    for encode in enc_list:
        try:
            with open(file_name, encoding=encode) as f:
                f.read()
            return encode  # Default to utf-8 if no BOM is found
        except Exception as e:
            print(f"Error reading file {file_name}: {e}")
    return None


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--filename', type=str, help='Specify the log file to parse')
    args = parser.parse_args()
    output_name = f'{os.path.splitext(args.filename)[0]}.csv'
    print(f'Output file name: {output_name}')
    LogParser(args.filename, get_file_encoding(args.filename)).parse_and_save(output_name)
