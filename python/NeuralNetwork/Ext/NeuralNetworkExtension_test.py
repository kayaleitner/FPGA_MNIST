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
    K = np.random.rand(4, 4, 4, 8).astype(
        np.float32)  # only odd numbers are allowed
    o = nn.conv2d(img, K, 1)


def get_uniform_test_image_and_kernel(shape_image, shape_kernel):
    K = np.random.rand(*shape_kernel).astype(np.float32) - 0.5
    I = np.random.rand(*shape_image).astype(np.float32) - 0.5
    return I, K


class NNExtensionTestCase(unittest.TestCase):
    NUMERIC_EPS = 1e-4

    def test_generic(self):
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d, maxPool2D, relu4D
        I, K = get_uniform_test_image_and_kernel(
            (10, 28, 28, 10), (3, 3, 10, 20))
        o = conv2d(I, K, 1)
        print("o.shape = ", o.shape)
        o2 = maxPool2D(o)
        relu4D(o2)
        print("o2.shape = ", o2.shape)

    def test_conv(self):
        from NeuralNetwork.nn.core import conv2d
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
        self.assertTrue(np.allclose(Y, Y_ext2, atol=self.NUMERIC_EPS))

    def test_conv_speed(self):
        import time
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d_3x3
        from NeuralNetwork.Ext.NeuralNetworkExtension import conv2d as conv2d_ext
        from NeuralNetwork.nn.core import conv2d

        n_runs = 10
        # Get large image data set
        I, K = get_uniform_test_image_and_kernel(
            (10, 28, 28, 6), (3, 3, 6, 12))

        print("Code         Time")

        t_start = time.time()
        for i in range(n_runs):
            _ = conv2d_3x3(I, K)
        t_end = time.time()
        t_cext = (t_end - t_start) / n_runs
        print("C-Ext       ", t_cext)

        t_start = time.time()
        for i in range(n_runs):
            _ = conv2d_ext(I, K, 1)
        t_end = time.time()
        t_cext2 = (t_end - t_start) / n_runs
        print("C-Ext2      ", t_cext2)

        t_start = time.time()
        for i in range(n_runs):
            _ = conv2d(I, K)
        t_end = time.time()
        t_py = (t_end - t_start) / n_runs
        print("Python      ", t_py)

        # Speedup is >100
        print("Speedup:  ", t_py / t_cext)

    def test_relu_speed(self):
        import time
        from NeuralNetwork.Ext.NeuralNetworkExtension import relu4D
        from NeuralNetwork.nn.core import relu

        n_runs = 100
        # Get large image data set
        I, _ = get_uniform_test_image_and_kernel(
            (10, 28, 28, 6), (3, 3, 6, 12))

        print("Code         Time")

        t_start = time.time()
        for i in range(n_runs):
            _ = relu4D(I)
        t_end = time.time()
        t_cext = (t_end - t_start) / n_runs
        print("C-Ext       ", t_cext)

        t_start = time.time()
        for i in range(n_runs):
            _ = relu(I)
        t_end = time.time()
        t_py = (t_end - t_start) / n_runs
        print("Python      ", t_py)

        # Speedup is ~2
        print("Speedup:  ", t_py / t_cext)

    def test_pool_speed(self):
        import time
        from NeuralNetwork.Ext.NeuralNetworkExtension import maxPool2D
        from NeuralNetwork.nn.core import pooling_max

        n_runs = 100
        # Get large image data set
        I, _ = get_uniform_test_image_and_kernel(
            (10, 28, 28, 6), (3, 3, 6, 12))

        print("Code         Time")

        t_start = time.time()
        for i in range(n_runs):
            _ = maxPool2D(I)
        t_end = time.time()
        t_cext = (t_end - t_start) / n_runs
        print("C-Ext       ", t_cext)

        t_start = time.time()
        for i in range(n_runs):
            _ = pooling_max(I, pool_size=2)
        t_end = time.time()
        t_py = (t_end - t_start) / n_runs
        print("Python      ", t_py)

        # Speedup is ~2
        print("Speedup:  ", t_py / t_cext)

    def test_relu_1(self):
        from NeuralNetwork.Ext.NeuralNetworkExtension import relu1D
        negatives = np.random.rand(1000).astype(np.float32) - 10
        self.assertTrue(np.all(negatives < 0))
        relu1D(negatives)
        self.assertTrue(np.all(negatives < 0.00000001))
        self.assertTrue(np.all(negatives > -0.00000001))

    def test_relu_ndim(self):
        from NeuralNetwork.nn.core import relu
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

            self.assertTrue(np.allclose(
                x_relu1, x_relu2, atol=self.NUMERIC_EPS))

    def test_int(self):
        from NeuralNetwork.nn.core import relu
        import NeuralNetwork.Ext.NeuralNetworkExtension as NNExt
        x1 = np.random.rand(100).astype(dtype=np.int16) * 10 - 5
        x2 = x1.copy()
        NNExt.relu_int16_t(x1)
        x2 = relu(x2)
        np.allclose(x1, x2, atol=self.NUMERIC_EPS)
