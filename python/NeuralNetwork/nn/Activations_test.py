import unittest
import numpy as np

import NeuralNetwork.nn.core


class ActionFuncsCase(unittest.TestCase):

    def test_relu1(self):
        x = np.array([-1, -2, 2, 1])
        x_exp = np.array([0, 0, 2, 1])
        x_relu = NeuralNetwork.nn.core.relu(x)
        print(x_relu)
        self.assertTrue(np.all(np.equal(x_relu, x_exp)))

    def test_relu2(self):
        x = np.zeros(shape=(10, 10))
        x[:, 0:5] = 1  # 1 at even indices
        x[:, 5:] = -1  # -1 at odd indices

        x_exp = np.zeros(shape=(10, 10))
        x_exp[:, 0:5] = 1
        print(x)
        print(x_exp)

        x_relu = np.apply_along_axis(NeuralNetwork.nn.core.relu, -2, x)
        # x_relu = relu(x)
        self.assertTrue(np.all(np.equal(x_relu, x_exp)))


if __name__ == '__main__':
    unittest.main()
