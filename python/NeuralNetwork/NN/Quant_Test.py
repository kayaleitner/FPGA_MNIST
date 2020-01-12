import unittest


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
        import numpy as np
        from NeuralNetwork.NN.Quant import quantize_vector

        test_vec = np.array([-1, -2, -3, 0, 1, 2, 10, 0.5], dtype=np.float32)
        res = quantize_vector(x=test_vec, bits=3, signed=False, min_value=-1, max_value=1)
        self.assertTrue(np.max(res) <= 1 and np.min(res) >= -1)


if __name__ == '__main__':
    unittest.main()
