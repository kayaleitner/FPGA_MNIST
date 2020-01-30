import unittest
import numpy as np


class QuantTestCase(unittest.TestCase):

    def test_quant_vec(self):
        import numpy as np
        from NeuralNetwork.NN.Quant import quantize_vector
        test_vec = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
        exp_vec = np.array([0, 1, 2, 3, 4, 5, 6, 7], dtype=np.int)
        res = quantize_vector(x=test_vec, bits=3, signed=False)

        self.assertTrue(res.dtype == np.int)
        self.assertTrue(np.allclose(exp_vec, res))

    def test_quant2(self):
        from NeuralNetwork.NN.Quant import quantize_vector

        test_vec = np.array([-1, -2, -3, 0, 1, 2, 10, 0.5], dtype=np.float32)
        res = quantize_vector(x=test_vec, bits=3, signed=False, min_value=-1, max_value=1)
        self.assertTrue(np.max(res) <= 1 and np.min(res) >= -1)


class FPTestCase(unittest.TestCase):

    def test_default_fixed_point(self):
        from NeuralNetwork.NN.Quant import fpi
        x = 3.1415
        fp_value = fpi(value=x, fraction_bits=16, target_type=np.int32, zero_point=0)

        lsb = fp_value.get_lsb()

        xfp = fp_value.asfloat()
        self.assertAlmostEqual(x, xfp, places=3)

    def test_numpy_quant(self):
        from NeuralNetwork.NN.Quant import fpi

        a = np.array([fpi(1.0)], dtype=fpi)
        b = np.array([fpi(2.0)], dtype=fpi)

        test_array = [1.0, 2.0, 3.0, 4.0, 5.0]
        fpi_array = list(map(lambda x: fpi(value=x, input_is_float=True, fraction_bits=0), test_array))

        d = np.array(fpi_array, dtype=fpi)

        e = d + 1

        c = a + b
        print(c)

    def test_quant_1(self):
        from NeuralNetwork.NN.Quant import to_fpi, from_fpi, to_fpi_object
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

        from NeuralNetwork.NN.Quant import fpi

        a = fpi(120, fraction_bits=1, target_type=np.int8, zero_point=0)
        b = fpi(120, fraction_bits=1, target_type=np.int8, zero_point=0)


        c = a+b

    def test_fix_point_arithmetic_with_shift(self):

        from NeuralNetwork.NN.Quant import to_fpi, from_fpi, fpi
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
            precision = max(1 / 2 ** fraction_bits_a, 1/2**fraction_bits_b)

            fresult = operation(value_a, value_b)

            # fpi1 = to_fpi_easy(value, fraction_bits=fraction_bits, target_dtype=target_dtype)
            fpi_a = fpi(value_a, fraction_bits=fraction_bits_a, target_type=target_dtype)
            fpi_b = fpi(value_b, fraction_bits=fraction_bits_b, target_type=target_dtype)

            fpi_result = operation(fpi_a, fpi_b)

            fpi_value = fpi_result.asfloat()

            if abs(fresult - fpi_value) > precision:
                print("Error")

                # repeat operation
                fpi_c = operation(fpi_a, fpi_b)

            #self.assertTrue(abs(fresult - fpi_value) < precision)

    def test_fix_point_arithmetic(self):

        from NeuralNetwork.NN.Quant import to_fpi, from_fpi, fpi
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
            fpi_a = fpi(value_a, fraction_bits=fraction_bits, target_type=target_dtype)
            fpi_b = fpi(value_b, fraction_bits=fraction_bits, target_type=target_dtype)

            fpi_result = operation(fpi_a, fpi_b)

            fpi_value = fpi_result.asfloat()

            if abs(fresult - fpi_value) > precision:
                print("Error")

                # repeat operation
                fpi_c = operation(fpi_a, fpi_b)

            # self.assertTrue(abs(fresult - fpi_value) < precision)

    def test_random_fpi(self):
        import random
        from NeuralNetwork.NN.Quant import fpi

        for i in range(1000):
            # bitsize = random.choice([8, 16, 32, 64])
            upper = 1.0
            lower = -1.0
            float_val = random.uniform(a=upper, b=lower)
            fpi_val = fpi(value=float_val, input_is_float=True, fraction_bits=7, target_type=np.int8, zero_point=0)
            self.assertTrue(abs(float_val - fpi_val.asfloat()) <= 0.5 * fpi_val.get_lsb())
            self.assertAlmostEqual(float_val, fpi_val.asfloat(), places=2)

        pass

    def test_random_numpy(self):
        pass


if __name__ == '__main__':
    unittest.main()
