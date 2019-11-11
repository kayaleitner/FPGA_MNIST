import unittest
from .FullyConnected import FullyConnectedLayer


class FullyConnectedLayerTestCase(unittest.TestCase):
    def test_something(self):
        fc = FullyConnectedLayer(1, 10)
        self.assertEqual(fc.W.shape, (10, 1))
        self.assertEqual(fc.b.shape, (10, 1))

        y = fc(2)
        self.assertEqual(y.shape, (10, 1))


if __name__ == '__main__':
    unittest.main()
