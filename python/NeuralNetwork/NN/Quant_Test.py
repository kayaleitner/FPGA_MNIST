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
