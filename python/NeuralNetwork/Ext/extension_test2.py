import unittest
from .NeuralNetworkExtension import conv2d, relu4D, maxPool2D
import numpy as np


class NNExtensionTestCase(unittest.TestCase):

    def test_generic(self):
        img = np.random.rand(100, 28, 28, 4).astype(np.float32)
        K = np.random.rand(3, 3, 4, 8).astype(np.float32)
        o = conv2d(img, K, 1)
        print("o.shape = ", o.shape)
        o2 = maxPool2D(o)
        relu4D(o2)
        print("o2.shape = ", o2.shape)

    def test_conv(self):
        pass

    def test_MaxPool(self):
        pass

    def test_Relu(self):
        pass
