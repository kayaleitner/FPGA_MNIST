import unittest
import numpy as np

if __name__ == '__main__':
    import NeuralNetworkExtension as nn

    img = np.random.rand(100, 28, 28, 4).astype(np.float32)
    K = np.random.rand(3, 3, 4, 8).astype(np.float32)
    o = nn.conv2d(img, K, 1)
    print("o.shape = ", o.shape)
    o2 = nn.maxPool2D(o)
    nn.relu4D(o2)
    print("o2.shape = ", o2.shape)


    # Try to trigger exception by prividing bad kernel
    K = np.random.rand(4, 4, 4, 8).astype(np.float32) # only odd numbers are allowed
    o = nn.conv2d(img, K, 1)


class NNExtensionTestCase(unittest.TestCase):

    def test_generic(self):
        import NeuralNetwork.Ext as ext
        img = np.random.rand(100, 28, 28, 4).astype(np.float32)
        K = np.random.rand(3, 3, 4, 8).astype(np.float32)
        o = ext.conv2d(img, K, 1)
        print("o.shape = ", o.shape)
        o2 = ext.maxPool2D(o)
        ext.relu4D(o2)
        print("o2.shape = ", o2.shape)

    def test_conv(self):
        pass

    def test_MaxPool(self):
        pass

    def test_Relu(self):
        from NeuralNetwork.NN.Activations import relu
        import NeuralNetwork.Ext as ext

        sizes_to_test = [
            (1000),
            (100, 100),
            (10, 100, 100),
            (10, 100, 100, 10),
        ]
        for size in sizes_to_test:
            x = 10.0*(np.random.rand(size).astype(np.float32)-0.5)
            x_relu1 = x.copy()
            ext.relu1D(x_relu1)
            x_relu2 = relu(x)
            self.assertTrue(np.allclose(x_relu1, x_relu2))
