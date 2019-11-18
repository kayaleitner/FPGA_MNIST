import numpy as np
from numpy.core.multiarray import ndarray

from .Layer import Layer
import math


def init_kernel(input_channels: int, out_channels: int = 3, kernel_size: int = 5) -> ndarray:
    """
    Creates a new convolution filter
    :rtype: ndarray
    :param out_channels:
    :param input_channels:
    :param kernel_size:
    :return: Filter tensor with dimension [filter_height, filter_width, in_channels, out_channels]
    """
    return np.random.rand(kernel_size, kernel_size, input_channels, out_channels)


def test_kernel_gauss(size=5, sigma=1.6) -> ndarray:
    k = np.zeros(shape=[size, size])

    for i in range(size):
        for j in range(size):
            x = i - float(size) / 2
            y = j - float(size) / 2
            k[i, j] = 1 / (2 * np.pi * sigma ** 2) * np.exp(-(x ** 2 + y ** 2) / (2 * sigma ** 2))

    return k


class ConvLayer(Layer):
    kernel: ndarray

    def __init__(self, in_channels, out_channels, kernel_size):
        self.kernel = init_kernel(in_channels, out_channels, kernel_size)

    def __call__(self, *args, **kwargs):
        return self.conv_simple(args[0])

    def get_input_shape(self):
        # Input data:  [batch, in_height, in_width, in_channels]
        # Kernel size: [fh, fw, kin_ch, kout_ch]
        #
        # Data can be arbitrary shaped except the number of input channels, which must match the number of output
        # channels
        return -1, -1, -1, self.kernel.shape[2]

    def get_output_shape(self):
        # Input data:  [batch, in_height, in_width, in_channels]
        # Kernel size: [fh, fw, kin_ch, kout_ch]
        return -1, -1, -1, self.kernel.shape[3]

    def conv_simple(self, data_in):
        """
        Calculates the 2D convolution with zero padding
        :param data_in: tensor with [batch, in_height, in_width, in_channels] dimensions
        :return:
        """

        fh, fw, kin_ch, kout_ch = self.kernel.shape
        batch, in_h, in_w, in_ch = data_in.shape

        if kin_ch != in_ch:
            raise ValueError("Input channel mismatch")

        # Check if the filter has an uneven width
        assert (1 == fh % 2)
        assert (1 == fw % 2)

        # Find the midpoint of the filter. This only works for odd filter sizes
        fh2 = int((fh - 1) / 2)
        fw2 = int((fw - 1) / 2)

        out = np.zeros(shape=[batch, in_h, in_w, kout_ch])

        # ToDo: This can be cleaned up
        for b in range(batch):
            for i in range(in_h):
                for j in range(in_w):
                    for k in range(kout_ch):

                        # calculate the convolution for the kernel patch
                        # out[b, i, j, k] = sum_{di, dj, q} input[b, i + di, j + dj, q] * filter[di, dj, q, k]

                        patch_sum = 0

                        for di in range(-fh2, fh2):  #
                            for dj in range(-fw2, fw2):
                                for q in range(kin_ch):
                                    # Bounds check (because padding is outside of array
                                    if 0 <= i + di < in_h and 0 <= j + dj < in_w:
                                        patch_sum += data_in[b, i + di, j + dj, q] * \
                                                     self.kernel[fh2 + di, fw2 + dj, q, k]

                        out[b, i, j, k] = patch_sum
        return out


def apply_pool(data_in: ndarray, pool_size: int, f):
    """
    :param data_in: The data that should be processed
    :param pool_size: The size of the patch which is used, for pooling values. It is applied as [pool_size x
    pool_size] along the image width and height axis
    :param f: A callable, which gets a list of values and returns a
    value (e.g. the maximum)
    :type data_in: ndarray
    """

    batch, in_h, in_w, in_ch = data_in.shape

    out_h = int(in_h / pool_size)
    out_w = int(in_w / pool_size)

    out = np.zeros(shape=[batch, out_h, out_w, in_ch])

    for b in range(batch):
        for i in range(out_h):
            for j in range(out_w):
                for c in range(in_ch):
                    i1 = i * pool_size
                    j1 = j * pool_size

                    i2 = min(i * pool_size + pool_size, in_h)
                    j2 = min(j * pool_size + pool_size, in_w)

                    data_slice = data_in[b, i1:i2, j1:j2, c]
                    data_slice = np.reshape(data_slice, newshape=(-1, 1))
                    val = f(data_slice)
                    out[b, i, j, c] = val

    return out


class MaxPoolLayer(Layer):
    PoolSize: int

    def __init__(self, size=2):
        self.PoolSize = size

    def __call__(self, *args, **kwargs):
        data_in = args[0]
        return apply_pool(data_in, pool_size=self.PoolSize, f=np.max)

    def get_input_shape(self):
        # Input is completely arbitrary
        return -1, -1, -1, -1

    def get_output_shape(self, input_data_shape: ndarray = None):
        # Input data:  [batch, in_height, in_width, in_channels]
        batch, in_w, in_h, nch = input_data_shape.shape
        out_w = math.ceil(in_w / self.PoolSize)
        out_h = math.ceil(in_h / self.PoolSize)
        return -1, out_w, out_h, -1


class AveragePoolLayer(Layer):
    PoolSize: int

    def __init__(self, size=2):
        self.PoolSize = size

    def __call__(self, *args, **kwargs):
        data_in = args[0]
        np.max()
        return apply_pool(data_in, pool_size=self.PoolSize, f=np.mean)

    def get_input_shape(self):
        # Input is completely arbitrary
        return -1, -1, -1, -1

    def get_output_shape(self, input_data_shape: ndarray = None):
        # Input data:  [batch, in_height, in_width, in_channels]
        batch, in_w, in_h, nch = input_data_shape.shape
        out_w = math.ceil(in_w / self.PoolSize)
        out_h = math.ceil(in_h / self.PoolSize)
        return -1, out_w, out_h, -1

