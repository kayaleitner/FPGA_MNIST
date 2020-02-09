import unittest
import numpy as np
import NeuralNetwork.nn.quant as quant
from NeuralNetwork import nn


class GeneralQuantizationTests(unittest.TestCase):

    def test_next_pow2(self):
        self.assertEqual(1024, quant.next_pow2(1023))
        self.assertEqual(64, quant.next_pow2(63))
        self.assertEqual(32, quant.next_pow2(32))
        self.assertEqual(16, quant.next_pow2(16))
        self.assertEqual(4, quant.next_pow2(4))
        self.assertEqual(8, quant.next_pow2(5))

    def test_quant_mul(self):
        q1 = 32  # 0.5
        s1 = -6
        q2 = 64  # 0.5
        s2 = -7

        qr = q1 * q2
        sr = s1 + s2

        x1 = q1 * 2 ** s1
        x2 = q2 * 2 ** s2
        xr = qr * 2 ** sr

        print("x1 = ", x1)
        print("x2 = ", x2)
        print("v  = ", 0.5 * 0.5)
        print("xr = ", xr)

        self.assertAlmostEqual(0.5 * 0.5, xr)

    def test_quant_add(self):
        q1 = 32  # 0.5
        s1 = -6
        q2 = 64  # 0.5
        s2 = -7

        # Scaling Shift
        sd1 = s1 - s2
        sd2 = s2 - s1

        qr1 = q2 + (q1 << sd1)
        qr2 = q1 + (q2 >> -sd2)
        sr1 = s2
        sr2 = s1

        x1 = q1 * 2 ** s1
        x2 = q2 * 2 ** s2
        xr1 = qr1 * 2 ** sr1
        xr2 = qr2 * 2 ** sr2

        print("x1  = ", x1)
        print("x2  = ", x2)
        print("v   = ", 0.5 + 0.5)
        print("xr1 = ", xr1)
        print("xr2 = ", xr2)

        self.assertAlmostEqual(0.5 + 0.5, xr1)
        self.assertAlmostEqual(0.5 + 0.5, xr2)

    def test_numpy_quant_mul(self):
        kernel = np.random.uniform(low=-1, high=1, size=(3, 3, 1))
        patch = np.random.uniform(low=-1, high=1, size=(3, 3, 1))
        yr_temp = kernel * patch
        yr = yr_temp.flatten().sum()

        s = -4
        scale = quant.fracbits_to_scale(4)
        qkernel = quant.quantise_uniform(kernel, scale, 256).astype(np.int8)
        qpatch = quant.quantise_uniform(patch, scale, 256).astype(np.int8)
        qr_temp = qkernel * qpatch
        qr = qr_temp.flatten().sum(dtype=np.int8)
        qr2 = qr_temp.flatten().astype(np.int16).sum()
        sr = s + s

        scale_out = quant.fracbits_to_scale(8)
        xr_temp = quant.dequantise_uniform(qr_temp, scale_out)
        xr = quant.dequantise_uniform(qr, scale_out)
        xr3 = quant.dequantise_uniform(qr2, scale_out)

        xr2 = xr_temp.flatten().sum()

        print(yr.flatten())
        print(xr.flatten())
        print(yr - xr)

        shift = 3
        qr_temp_shifted = np.right_shift(qr_temp, shift)
        qr3 = qr_temp_shifted.flatten().sum(dtype=np.int8)
        scale3 = quant.fracbits_to_scale(8 - shift)
        yr3 = quant.dequantise_uniform(qr3, scale3)
        print(yr3)

    def test_can_mul_overflow(self):
        self.assertTrue(quant.can_mul_overflow(16, 8, 16, 8, 8))
        self.assertFalse(quant.can_mul_overflow(16, 8, 16, 8, 10))
        self.assertFalse(quant.can_mul_overflow(15, 8, 15, 8, 9))

        for i in range(100):
            a_bits = 16
            b_bits = 16
            out_bits = 16

            # 2.0 * 3.0 = 6.0
            quant.next_pow2(6.0)
            quant.next_pow2(6.0)
            quant.next_pow2(6.0)
            a = quant.quantise_uniform(0.5, scale=1.0 / 16, ncodes=16)
            b = quant.quantise_uniform(0.75, scale=1.0 / 16, ncodes=16)

            overflows = quant.can_mul_overflow(a=a, a_bits=a_bits, b=b, b_bits=b_bits, out_bits=out_bits)

    def test_can_add_overflow(self):
        # No overflow

        # 3 + 3 = 6
        self.assertFalse(quant.can_add_overflow(3, 4, 0, 3, 4, 0, 4))

        # 3 + 0.5
        a = quant.quantise_uniform(0.5, scale=1.0 / 16, ncodes=16)
        b = quant.quantise_uniform(0.75, scale=1.0 / 16, ncodes=16)
        self.assertTrue(quant.can_add_overflow(a, 4, 4, b, 4, 4, 4))
        self.assertFalse(quant.can_add_overflow(a, 4, 4, b, 4, 4, 5))

    def test_quant_kernels(self):
        kernel = np.random.normal(loc=0, scale=0.6, size=(3, 3, 1, 6))
        mu = np.mean(kernel[:, :, :, 0])
        sigma = np.std(kernel[:, :, :, 0])

        bits = 8
        ncodes = 2 ** bits
        qkernel, fracbits = quant.quantize_kernels(kernel=kernel, parameter_bits=bits)
        fkernel = quant.dequantizse_kernels(qkernel, parameter_bits=bits, frac_bits=fracbits)

        self.assertTrue(np.all(qkernel <= ncodes / 2 - 1))
        self.assertTrue(np.all(qkernel >= -ncodes / 2))
        for i in range(1000):
            sigma = np.random.uniform(0.1, 1.0)
            c_in = np.random.randint(1, 16)
            c_out = np.random.randint(1, 16)
            kernel = np.random.normal(loc=0, scale=sigma, size=(3, 3, c_in, c_out))
            bits = np.random.randint(4, 32)
            ncodes = 2 ** bits
            qkernel, fracbits = quant.quantize_kernels(kernel=kernel, parameter_bits=bits)
            self.assertTrue(np.all(qkernel <= ncodes / 2 - 1))
            self.assertTrue(np.all(qkernel >= -ncodes / 2))

    def test_quant_kernel_precision(self):

        kernel = np.random.normal(loc=0, scale=0.5, size=(3, 3, 2, 4))
        image = np.random.normal(loc=0, scale=1.0, size=(3, 10, 10, 2))

        qk4, mk = quant.quantize_kernels(kernel=kernel, parameter_bits=4)
        qi8, mi = quant.quantize_conv_activations(input=image, parameter_bits=8)

        qout = nn.core.conv2d(data_in=qi8, kernel=qk4)
        mout = mk + mi

        pass


class QuantTestCase(unittest.TestCase):

    def test_quant_vec(self):
        import numpy as np
        from NeuralNetwork.nn.quant import quantize_vector
        test_vec = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
        exp_vec = np.array([0, 1, 2, 3, 4, 5, 6, 7], dtype=np.int)
        res = quantize_vector(x=test_vec, bits=3, signed=False)

        self.assertTrue(res.dtype == np.int)
        self.assertTrue(np.allclose(exp_vec, res))

    def test_quant2(self):
        from NeuralNetwork.nn.quant import quantize_vector

        test_vec = np.array([-1, -2, -3, 0, 1, 2, 10, 0.5], dtype=np.float32)
        res = quantize_vector(x=test_vec, bits=3, signed=False, min_value=-1, max_value=1)
        self.assertTrue(np.max(res) <= 1 and np.min(res) >= -1)


class FPTestCase(unittest.TestCase):

    def test_default_fixed_point(self):
        from NeuralNetwork.nn.quant import Fpi
        x = 3.1415
        fp_value = Fpi(value=x, fraction_bits=16, target_type=np.int32, zero_point=0)

        lsb = fp_value.get_lsb()

        xfp = fp_value.asfloat()
        self.assertAlmostEqual(x, xfp, places=3)

    def test_numpy_quant(self):
        from NeuralNetwork.nn.quant import Fpi

        a = np.array([Fpi(1.0)], dtype=Fpi)
        b = np.array([Fpi(2.0)], dtype=Fpi)

        test_array = [1.0, 2.0, 3.0, 4.0, 5.0]
        fpi_array = list(map(lambda x: Fpi(value=x, input_is_float=True, fraction_bits=0), test_array))

        d = np.array(fpi_array, dtype=Fpi)

        e = d + 1

        c = a + b
        print(c)

    def test_quant_1(self):
        from NeuralNetwork.nn.quant import to_fpi, from_fpi, to_fpi_object
        import random

        frac_dict = {
            np.int8: (0, 7),
            np.int16: (0, 15),
            np.int32: (0, 31),
            np.int64: (0, 63),
        }

        for i in range(1000):
            target_dtype = random.choice([np.int8, np.int16, np.int32, np.int64])
            value = random.uniform(1.0, -1.0)
            frac_lower, frac_upper = frac_dict[target_dtype]
            fraction_bits = random.randint(frac_lower, frac_upper)
            precision = 1 / 2 ** fraction_bits

            # fpi1 = to_fpi_easy(value, fraction_bits=fraction_bits, target_dtype=target_dtype)
            fpi2 = to_fpi(value, fraction_bits=fraction_bits, target_type=target_dtype)

            # sf1 = from_fpi(fpi1, fraction_bits=fraction_bits, target_type=target_dtype, zero_point=0.0)
            f2 = from_fpi(fpi2, fraction_bits=fraction_bits, target_type=target_dtype, zero_point=0.0)

            self.assertTrue(abs(f2 - value) < precision)

    def test_fix_point_overflow(self):

        from NeuralNetwork.nn.quant import Fpi

        a = Fpi(120, fraction_bits=1, target_type=np.int8, zero_point=0)
        b = Fpi(120, fraction_bits=1, target_type=np.int8, zero_point=0)

        c = a + b

    def test_fix_point_arithmetic_with_shift(self):

        from NeuralNetwork.nn.quant import to_fpi, from_fpi, Fpi
        import random

        frac_dict = {
            np.int8: (0, 7),
            np.int16: (0, 15),
            np.int32: (0, 31),
            np.int64: (0, 63),
        }

        op_dict = {
            '+': lambda a, b: a + b,
            '-': lambda a, b: a - b,
            '*': lambda a, b: a * b
        }

        for i in range(1000):
            # Select random numbers, datatype and operation
            op = random.choice(['+', '-', '*'])
            target_dtype = random.choice([np.int8, np.int16, np.int32, np.int64])
            value_a = random.uniform(1.0, -1.0)
            value_b = random.uniform(1.0, -1.0)

            operation = op_dict[op]
            frac_lower, frac_upper = frac_dict[target_dtype]
            fraction_bits_a = random.randint(frac_lower, frac_upper)
            fraction_bits_b = random.randint(frac_lower, frac_upper)
            precision = max(1 / 2 ** fraction_bits_a, 1 / 2 ** fraction_bits_b)

            fresult = operation(value_a, value_b)

            # fpi1 = to_fpi_easy(value, fraction_bits=fraction_bits, target_dtype=target_dtype)
            fpi_a = Fpi(value_a, fraction_bits=fraction_bits_a, target_type=target_dtype)
            fpi_b = Fpi(value_b, fraction_bits=fraction_bits_b, target_type=target_dtype)

            fpi_result = operation(fpi_a, fpi_b)

            fpi_value = fpi_result.asfloat()

            if abs(fresult - fpi_value) > precision:
                print("Error")

                # repeat operation
                fpi_c = operation(fpi_a, fpi_b)

            # self.assertTrue(abs(fresult - fpi_value) < precision)

    def test_fix_point_arithmetic(self):

        from NeuralNetwork.nn.quant import to_fpi, from_fpi, Fpi
        import random

        frac_dict = {
            np.int8: (0, 7),
            np.int16: (0, 15),
            np.int32: (0, 31),
            np.int64: (0, 63),
        }

        op_dict = {
            '+': lambda a, b: a + b,
            '-': lambda a, b: a - b,
            '*': lambda a, b: a * b
        }

        for i in range(1000):
            # Select random numbers, datatype and operation
            op = random.choice(['+', '-', '*'])
            target_dtype = random.choice([np.int8, np.int16, np.int32, np.int64])
            value_a = random.uniform(1.0, -1.0)
            value_b = random.uniform(1.0, -1.0)

            operation = op_dict[op]
            frac_lower, frac_upper = frac_dict[target_dtype]
            fraction_bits = random.randint(frac_lower, frac_upper)

            precision = 1 / 2 ** fraction_bits

            fresult = operation(value_a, value_b)

            # fpi1 = to_fpi_easy(value, fraction_bits=fraction_bits, target_dtype=target_dtype)
            fpi_a = Fpi(value_a, fraction_bits=fraction_bits, target_type=target_dtype)
            fpi_b = Fpi(value_b, fraction_bits=fraction_bits, target_type=target_dtype)

            fpi_result = operation(fpi_a, fpi_b)

            fpi_value = fpi_result.asfloat()

            if abs(fresult - fpi_value) > precision:
                print("Error")

                # repeat operation
                fpi_c = operation(fpi_a, fpi_b)

            # self.assertTrue(abs(fresult - fpi_value) < precision)

    def test_random_fpi(self):
        import random
        from NeuralNetwork.nn.quant import Fpi

        for i in range(1000):
            # bitsize = random.choice([8, 16, 32, 64])
            upper = 1.0
            lower = -1.0
            float_val = random.uniform(a=upper, b=lower)
            fpi_val = Fpi(value=float_val, input_is_float=True, fraction_bits=7, target_type=np.int8, zero_point=0)
            self.assertTrue(abs(float_val - fpi_val.asfloat()) <= 0.5 * fpi_val.get_lsb())
            self.assertAlmostEqual(float_val, fpi_val.asfloat(), places=2)

        pass

    def test_random_numpy(self):
        pass

    def test_conv(self):

        bits = 8
        data_in = np.random.normal(size=(1, 7, 7, 3))
        kernel = nn.make_random_kernel(size=(3, 3, 3, 6))

        qkernel8, km = quant.quantize_kernels(kernel, parameter_bits=8)
        qimage8, ki = quant.quantize_conv_activations(data_in, parameter_bits=8)

        fkernel8 = qkernel8 / 2 ** km
        fimage8 = qimage8 / 2 ** ki

        self.assertTrue(np.all(np.abs(qkernel8.flatten()) < 2 ** (bits - 1)))
        self.assertTrue(np.all(np.abs(qimage8.flatten()) < 2 ** (bits - 1)))

        qkernel8 = qkernel8.astype(np.int8)
        qimage8 = qimage8.astype(np.int8)
        dom = 4

        qout, om = nn.fpi_conv2d(data_in=qimage8, data_in_m=ki,
                                 kernel=qkernel8, kernel_m=km)

        fqout = qout.astype(np.float) / 2 ** om
        fout = nn.conv2d(data_in, kernel)

        err = np.abs(fqout - fout)
        self.assertTrue(np.all(err < 0.5))


class QuantLayerTests(unittest.TestCase):

    def test_rescale_layer(self):
        import NeuralNetwork.nn.Layer as layer
        input = np.random.normal(loc=0, scale=0.6, size=(10, 14, 14, 6))
        x, m = quant.quantize_conv_activations(input, parameter_bits=16)
        scale_layer = layer.RescaleLayer(target_bits=8, axis=(1, 2, 3))
        x_, m_ = scale_layer(x, m)

        v1 = x / 2.0 ** (m)
        v2 = x_ / 2.0 ** (m_)


class QuantNetworkTests(unittest.TestCase):

    def test_quant_network(self):
        x = np.random.uniform(low=0, high=1.0, size=(1, 14, 14, 1))
        k1 = nn.make_random_kernel(size=(3, 3, 1, 3))
        k2 = nn.make_random_kernel(size=(3, 3, 3, 9))

        # Quantize Data
        qk1, m1 = nn.quant.quantize_kernels(kernel=k1, parameter_bits=8)
        qk2, m2 = nn.quant.quantize_kernels(kernel=k2, parameter_bits=8)
        xq, mx = nn.quant.quantize_conv_activations(input=x, parameter_bits=8)

        layers = [
            nn.Layer.QuantConv2dLayer(qkernel=qk1, kernel_m=m1),
            nn.Layer.RescaleLayer(target_bits=8, source_bits=20, axis=(1, 2, 3)),
            nn.Layer.QuantConv2dLayer(qkernel=qk2, kernel_m=m2),
            nn.Layer.RescaleLayer(target_bits=8, source_bits=20, axis=(1, 2, 3)),
        ]

        net = nn.Network.Network(layers)
        q_out, q_intermediate_res = net.forward_intermediate(inputs=(xq, mx))
        yq, my = q_out
        self.assertTrue(my.size == 9)

        # Compare to float net
        layers = [
            nn.Layer.Conv2dLayer(in_channels=1, out_channels=3, kernel_size=3, use_bias=False, kernel_init_weights=k1,
                                 bias_init_weights=None, dtype=np.float),
            nn.Layer.Conv2dLayer(in_channels=3, out_channels=9, kernel_size=3, use_bias=False, kernel_init_weights=k2,
                                 bias_init_weights=None, dtype=np.float)
        ]
        float_net = nn.Network.Network(layers)

        y, f_intermediate_res = float_net.forward_intermediate(x)
        yqf = yq / 2 ** my
        self.assertEqual(y.shape, yqf.shape)
        err = y - yqf


        # Outputs Quant
        fq1 = q_intermediate_res[0][0] / 2**q_intermediate_res[0][1]
        fq2 = q_intermediate_res[1][0] / 2**q_intermediate_res[1][1]
        fq3 = q_intermediate_res[2][0] / 2**q_intermediate_res[2][1]
        fq4 = q_intermediate_res[3][0] / 2**q_intermediate_res[3][1]

        f1 = f_intermediate_res[0]
        f2 = f_intermediate_res[1]


if __name__ == '__main__':
    unittest.main()
