import unittest
from .FullyConnected import FullyConnectedLayer
import numpy as np


class FullyConnectedLayerTestCase(unittest.TestCase):
    def test_something(self):
        fc = FullyConnectedLayer(1, 10)
        self.assertEqual(fc.W.shape, (1, 10))
        self.assertEqual(fc.b.shape, (10,))

        x = np.random.rand(1, 1)
        y = fc(x)
        self.assertEqual(y.shape, (1, 10))


if __name__ == '__main__':
    unittest.main()
