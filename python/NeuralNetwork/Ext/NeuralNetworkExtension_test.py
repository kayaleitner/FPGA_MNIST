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
    K = np.random.rand(4, 4, 4, 8).astype(np.float32)  # only odd numbers are allowed
    o = nn.conv2d(img, K, 1)


def get_uniform_test_image_and_kernel(shape_image, shape_kernel):
    K = np.random.rand(*shape_kernel).astype(np.float32) - 0.5
    I = np.random.rand(*shape_image).astype(np.float32) - 0.5
    return I, K


class NNExtensionTestCase(unittest.TestCase):

    def test_generic(self):
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d, maxPool2D, relu4D
        I, K = get_uniform_test_image_and_kernel((10, 28, 28, 10), (3, 3, 10, 20))
        o = conv2d(I, K, 1)
        print("o.shape = ", o.shape)
        o2 = maxPool2D(o)
        relu4D(o2)
        print("o2.shape = ", o2.shape)

    def test_conv(self):
        from NeuralNetwork.NN.ConvLayer import conv2d
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d as conv2d_ext
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d_3x3

        # Get images and kernel and keep workload small
        I, K = get_uniform_test_image_and_kernel((5, 14, 14, 3), (3, 3, 3, 6))

        Y_ext = conv2d_ext(I, K, 1)
        Y_ext2 = conv2d_3x3(I, K)
        Y = conv2d(I, K, stride=1)

        self.assertEqual(Y.shape, Y_ext.shape)
        for (di_1, di_2) in zip(Y.shape, Y_ext.shape):
            self.assertEqual(di_1, di_2)
        # self.assertTrue(np.allclose(Y, Y_ext2))

    def test_relu_1(self):
        from NeuralNetwork.Ext.NeuralNetworkExtension import relu1D
        negatives = np.random.rand(1000).astype(np.float32) - 10
        self.assertTrue(np.all(negatives < 0))
        relu1D(negatives)
        self.assertTrue(np.all(negatives < 0.00000001))
        self.assertTrue(np.all(negatives > -0.00000001))

    def test_relu_ndim(self):
        from NeuralNetwork.NN.Activations import relu
        import NeuralNetwork.Ext.NeuralNetworkExtension as ext

        sizes_to_test = [
            (100, 100),
            (10, 100, 100),
            (10, 100, 100, 10),
        ]
        for size in sizes_to_test:
            x = np.random.rand(*size).astype(np.float32)
            x_relu1 = x.copy()
            x_relu2 = relu(x)

            if x.ndim == 2:
                ext.relu2D(x_relu1)
            elif x.ndim == 3:
                ext.relu3D(x_relu1)
            elif x.ndim == 4:
                ext.relu4D(x_relu1)
            else:
                raise ValueError()

            self.assertTrue(np.allclose(x_relu1, x_relu2))
