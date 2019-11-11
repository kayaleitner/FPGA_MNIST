import numpy as np
from numpy.core._multiarray_umath import ndarray

from .Layer import Layer


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


class ConvLayer(Layer):
    kernel: ndarray

    def __init__(self, in_channels, out_channels, kernel_size):
        self.kernel = init_kernel(in_channels, out_channels, kernel_size)

    def __call__(self, *args, **kwargs):
        return self.conv2d_simple(args[0])

    def conv2d_simple(self, data_in):
        """
        Calculates the 2D convolution with zero padding
        :param data_in: tensor with [batch, in_height, in_width, in_channels] dimensions
        :return:
        """
        if not isinstance(self.kernel, np.ndarray):
            raise ValueError("Only numpy arrays are supported")

        if not isinstance(data_in, np.ndarray):
            raise ValueError("Only numpy arrays are supported")

        fh, fw, kin_ch, kout_ch = self.kernel.shape
        batch, in_h, in_w, in_ch = data_in.shape

        if kin_ch != in_ch:
            raise ValueError("Input channel mismatch")

        # Check if the filter has an uneven width
        assert (1 == fh % 2)
        assert (1 == fw % 2)

        pad_h2 = int((fh - 1) / 2)
        pad_w2 = int((fw - 1) / 2)

        out = np.zeros(shape=[batch, in_h, in_w, kout_ch])

        # ToDo: This can be cleaned up
        for b in range(batch):
            for i in range(in_h):
                for j in range(in_w):
                    for k in range(kout_ch):

                        # calculate the conv for the kernel patch
                        # out[b, i, j, k] = sum_{di, dj, q} input[b, i + di, j + dj, q] * filter[di, dj, q, k]

                        patch_sum = 0

                        for di in range(-pad_h2, pad_h2):
                            for dj in range(-pad_w2, pad_w2):
                                for q in range(kin_ch):
                                    if 0 <= i + di < in_h and 0 <= j + dj < in_w:
                                        patch_sum += data_in[b, i + di, j + dj, q] * self.kernel[di, dj, q, k]

        return out


def apply_pool(data_in: ndarray, pool_size: int, f):
    """
    :param pool_size:
    :param f:
    :type data_in: ndarray
    """
    if not isinstance(data_in, ndarray):
        raise ValueError("Must be numpy array")

    if not callable(f):
        raise ValueError("Must be a callable function")

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


class AveragePoolLayer(Layer):
    PoolSize: int

    def __init__(self, size=2):
        self.PoolSize = size

    def __call__(self, *args, **kwargs):
        data_in = args[0]
        np.max()
        return apply_pool(data_in, pool_size=self.PoolSize, f=np.mean)
