import argparse
import enum
import re

# [profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 279 us
# [profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 328 us
OP_BREAKDOWN_LINE = re.compile(
    r'\[profiler]\[hexagon-npu]\[0x[a-f0-9]+](update|compute), handle\([0x[a-f0-9]+]\), dur: (\d+) us'
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
OP_TYPE_PROPS = re.compile(r'type[_a-zA-Z]*|prec')
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
        return f'OpData(name={self.name}, total_us={self.total_us}, update_us={self.update_us}, compute_us={self.compute_us})'


class OpTensor:
    class DataType(enum.Enum):
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
    def __init__(self, name: str, prop: str, data: OpData):
        self.name = name
        self.data = data
        self.props = OpItem.__parse_prop(prop)

    def __repr__(self) -> str:
        return f'OpItem(name={self.name}, data={self.data})'

    @staticmethod
    def __parse_prop(prop: str) -> dict[str:(OpTensor.DataType | int | float | bool | list)]:
        ret = {}
        for match in OP_PROP_ITEM.finditer(prop):
            key = match.group(1)
            value = match.group(2)
            if OP_TYPE_PROPS.match(key):
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
                print(f'Unknown property key: {key} with value: {value}')
                continue
        return ret


class LogParser:
    def __init__(self, filename: str):
        self.filename = filename

    def parse(self):
        lst: list[OpItem] = []
        with open(self.filename, 'r') as file:
            update_us: int = 0
            compute_us: int = 0
            dic: dict[str:OpData] = {}
            for line in file:
                if match := OP_BREAKDOWN_LINE.match(line):
                    item_type = match.group(1)
                    if item_type == 'update':
                        update_us = int(match.group(2))
                    elif item_type == 'compute':
                        compute_us = int(match.group(2))
                elif match := OP_TIME_CONSUME_LINE.match(line):
                    op_name = match.group(1)
                    if op_name is not 'NONE':
                        dic[op_name] = OpData(op_name, int(match.group(2)), int(match.group(3)), update_us, compute_us)
                elif match := OP_SECTION_END.match(line):
                    op_name = match.group(1)
                    if dic[op_name]:
                        data = dic[op_name]
                        lst.append(OpItem(name=op_name, prop=match.group(2), data=data))
                else:
                    continue


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--filename', type=str, help='Specify the log file to parse')
    args = parser.parse_args()
    parser = LogParser(args.filename)
