import unittest
from .FullyConnected import FullyConnectedLayer
import numpy as np


class FullyConnectedLayerTestCase(unittest.TestCase):
    def test_something(self):
        fc = FullyConnectedLayer(1, 10)
        self.assertEqual(fc.W.shape, (10, 1))
        self.assertEqual(fc.b.shape, (10, 1))

        x = np.random.rand(1, 1)
        y = fc(x)
        self.assertEqual(y.shape, (10, 1))


if __name__ == '__main__':
    unittest.main()
