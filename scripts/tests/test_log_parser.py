import unittest

from scripts.log_parser import OpTensor, OpData, OpItem


class OpTensorTestCases(unittest.TestCase):

    def test_given_op_tensor_when_get_name_then_return_correct_name(self):
        ret = OpTensor(dtype=OpTensor.DataType('f32'), shape=[16384, 16384, 1, 1], permute=None)
        self.assertEqual(ret.dtype, OpTensor.DataType.F32)
        self.assertEqual(ret.shape, [16384, 16384, 1, 1])
        self.assertEqual(ret.permute, [0, 1, 2, 3])


TEST_LOG_LINES = """
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 268 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 633 us
[profiler][MUL]compute, [hexagon-npu]: 1217 us, [CPU]: 35 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 276 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 278 us
[profiler][NONE]compute, [hexagon-npu]: 794 us, [CPU]: 6 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 262 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 321 us
[profiler][NONE]compute, [hexagon-npu]: 684 us, [CPU]: 3 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 271 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 303 us
[profiler][NONE]compute, [hexagon-npu]: 696 us, [CPU]: 6 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 323 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 345 us
[profiler][NONE]compute, [hexagon-npu]: 777 us, [CPU]: 4 us
  MUL(type=f16,ne=[10,5,4,3],nr=[1,2,2,2]): [1;32mOK[0m
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 440 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 575 us
[profiler][NONE]compute, [hexagon-npu]: 1413 us, [CPU]: 10 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 450 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 524 us
[profiler][NONE]compute, [hexagon-npu]: 1091 us, [CPU]: 12 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 455 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 1171 us
[profiler][MUL_MAT]compute, [hexagon-npu]: 1723 us, [CPU]: 43 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 617 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 441 us
[profiler][NONE]compute, [hexagon-npu]: 1152 us, [CPU]: 9 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 437 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 601 us
[profiler][NONE]compute, [hexagon-npu]: 1142 us, [CPU]: 12 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 456 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 524 us
[profiler][NONE]compute, [hexagon-npu]: 1070 us, [CPU]: 10 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 459 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 486 us
[profiler][NONE]compute, [hexagon-npu]: 1063 us, [CPU]: 8 us
  MUL_MAT(type_a=f32,type_b=f32,m=16,n=1,k=256,bs=[1,1],nr=[1,1],per=[0,1,2,3],v=0): [1;32mOK[0m
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 301 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 370 us
[profiler][PERMUTE]compute, [hexagon-npu]: 944 us, [CPU]: 142 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 280 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 235 us
[profiler][PERMUTE]compute, [hexagon-npu]: 700 us, [CPU]: 7 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 231 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 305 us
[profiler][PERMUTE]compute, [hexagon-npu]: 685 us, [CPU]: 6 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 286 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 10080 us
[profiler][FLASH_ATTN_EXT]compute, [hexagon-npu]: 12372 us, [CPU]: 18290 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 258 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 206 us
[profiler][NONE]compute, [hexagon-npu]: 667 us, [CPU]: 7 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 175 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 267 us
[profiler][NONE]compute, [hexagon-npu]: 549 us, [CPU]: 6 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 252 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 310 us
[profiler][NONE]compute, [hexagon-npu]: 685 us, [CPU]: 6 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 301 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 241 us
[profiler][NONE]compute, [hexagon-npu]: 664 us, [CPU]: 4 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 333 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 225 us
[profiler][NONE]compute, [hexagon-npu]: 677 us, [CPU]: 5 us
[profiler][hexagon-npu][0xb400007b714311d8]update, handle(0xe8aa20), dur: 314 us
[profiler][hexagon-npu][0xb400007b714311d8]compute, handle(0xe8aa20), dur: 241 us
[profiler][NONE]compute, [hexagon-npu]: 817 us, [CPU]: 106 us
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=f16,permute=[0,2,1,3]): [1;32mOK[0m
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=bf16,permute=[0,1,2,3]): not supported [hexagon-npu] 
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=bf16,permute=[0,2,1,3]): not supported [hexagon-npu] 
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=q8_0,permute=[0,1,2,3]): not supported [hexagon-npu] 
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=q8_0,permute=[0,2,1,3]): not supported [hexagon-npu] 
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=q4_0,permute=[0,1,2,3]): not supported [hexagon-npu] 
  FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=1,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=q4_0,permute=[0,2,1,3]): not supported [hexagon-npu] 
"""


class OpItemTestCases(unittest.TestCase):

    # MUL(type=f16,ne=[10,5,4,3],nr=[1,1,1,1]): [1;32mOK[0m
    def test_given_mul_prop_when_parse_then_return_correct_properties(self):
        op_data = OpData(
            name='MUL',
            total_us=976,
            cpu_total_us=99,
            update_us=279,
            compute_us=328,
        )

        op_item = OpItem(
            name='MUL',
            prop='type=f16,ne=[10,5,4,3],nr=[1,1,1,1]',
            data=op_data,
        )

        self.assertEqual(op_item.name, 'MUL')
        self.assertEqual(op_item.data, op_data)
        self.assertEqual(op_item.props['type'], OpTensor.DataType.F16)
        self.assertEqual(op_item.props['ne'], [10, 5, 4, 3])
        self.assertEqual(op_item.props['nr'], [1, 1, 1, 1])

    # MUL_MAT(type_a=q4_K,type_b=f32,m=16,n=8,k=256,bs=[2,3],nr=[1,1],per=[0,3,2,1],v=0): [1;32mOK[0m
    def test_given_mul_mat_prop_when_parse_then_return_correct_properties(self):
        op_data = OpData(
            name='MUL_MAT',
            total_us=976,
            cpu_total_us=99,
            update_us=279,
            compute_us=328,
        )

        op_item = OpItem(
            name='MUL_MAT',
            prop='type_a=q4_K,type_b=f32,m=16,n=8,k=256,bs=[2,3],nr=[1,1],per=[0,3,2,1],v=0',
            data=op_data,
        )

        self.assertEqual(op_item.name, 'MUL_MAT')
        self.assertEqual(op_item.data, op_data)
        self.assertEqual(op_item.props['type_a'], OpTensor.DataType.Q4_K)
        self.assertEqual(op_item.props['type_b'], OpTensor.DataType.F32)
        self.assertEqual(op_item.props['m'], 16)
        self.assertEqual(op_item.props['n'], 8)
        self.assertEqual(op_item.props['k'], 256)
        self.assertEqual(op_item.props['bs'], [2, 3])
        self.assertEqual(op_item.props['nr'], [1, 1])
        self.assertEqual(op_item.props['per'], [0, 3, 2, 1])
        self.assertEqual(op_item.props['v'], 0)

    # FLASH_ATTN_EXT(hsk=192,hsv=128,nh=4,nr=4,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=f16,permute=[0,1,2,3]): [1;32mOK[0m
    def test_given_flash_attn_ext_prop_when_parse_then_return_correct_properties(self):
        op_data = OpData(
            name='FLASH_ATTN_EXT',
            total_us=976,
            cpu_total_us=99,
            update_us=279,
            compute_us=328,
        )

        op_item = OpItem(
            name='FLASH_ATTN_EXT',
            prop='hsk=192,hsv=128,nh=4,nr=4,kv=512,nb=35,mask=1,max_bias=0.000000,logit_softcap=0.000000,prec=f32,type_KV=f16,permute=[0,1,2,3]',
            data=op_data,
        )

        self.assertEqual(op_item.name, 'FLASH_ATTN_EXT')
        self.assertEqual(op_item.data, op_data)
        self.assertEqual(op_item.props['hsk'], 192)
        self.assertEqual(op_item.props['hsv'], 128)
        self.assertEqual(op_item.props['nh'], 4)
        self.assertEqual(op_item.props['nr'], 4)
        self.assertEqual(op_item.props['kv'], 512)
        self.assertEqual(op_item.props['nb'], 35)
        self.assertEqual(op_item.props['mask'], 1)
        self.assertAlmostEqual(op_item.props['max_bias'], 0.0)
        self.assertAlmostEqual(op_item.props['logit_softcap'], 0.0)
        self.assertEqual(op_item.props['prec'], OpTensor.DataType.F32)
        self.assertEqual(op_item.props['type_KV'], OpTensor.DataType.F16)
        self.assertEqual(op_item.props['permute'], [0, 1, 2, 3])

    def test_given_log_lines_when_parse_then_return_correct_op_items(self):
        op_items = OpItem.list_from_iterable(iter(TEST_LOG_LINES.split('\n')))

        self.assertEqual(len(op_items), 3)
        self.assertEqual(op_items[0].name, 'MUL')
        self.assertEqual(op_items[0].data.total_us, 1217)
        self.assertEqual(op_items[0].data.cpu_total_us, 35)
        self.assertEqual(op_items[0].data.update_us, 268)
        self.assertEqual(op_items[0].data.compute_us, 633)
        self.assertEqual(op_items[0].props['type'], OpTensor.DataType.F16)

        self.assertEqual(op_items[1].name, 'MUL_MAT')
        self.assertEqual(op_items[1].data.total_us, 1723)
        self.assertEqual(op_items[1].data.cpu_total_us, 43)
        self.assertEqual(op_items[1].data.update_us, 455)
        self.assertEqual(op_items[1].data.compute_us, 1171)
        self.assertEqual(op_items[1].props['type_a'], OpTensor.DataType.F32)
        self.assertEqual(op_items[1].props['type_b'], OpTensor.DataType.F32)

        self.assertEqual(op_items[2].name, 'FLASH_ATTN_EXT')
        self.assertEqual(op_items[2].props['hsk'], 192)
        self.assertEqual(op_items[2].props['hsv'], 128)
        self.assertEqual(op_items[2].data.total_us, 12372)
        self.assertEqual(op_items[2].data.cpu_total_us, 18290)
        self.assertEqual(op_items[2].data.update_us, 286)
        self.assertEqual(op_items[2].data.compute_us, 10080)


if __name__ == '__main__':
    unittest.main()
