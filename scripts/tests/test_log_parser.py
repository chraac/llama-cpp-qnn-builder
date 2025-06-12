import unittest

from scripts.log_parser import OpTensor, OpData, OpItem


class OpTensorTestCases(unittest.TestCase):

    def test_given_op_tensor_when_get_name_then_return_correct_name(self):
        ret = OpTensor(dtype=OpTensor.DataType('f32'), shape=[16384, 16384, 1, 1], permute=None)
        self.assertEqual(ret.dtype, OpTensor.DataType.F32)
        self.assertEqual(ret.shape, [16384, 16384, 1, 1])
        self.assertEqual(ret.permute, [0, 1, 2, 3])


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


if __name__ == '__main__':
    unittest.main()
