import math
from typing import Optional

import numpy as np
from numpy.core.multiarray import ndarray

from .Layer import Layer
from .Activations import relu


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


def conv2d(data_in: ndarray, kernel: ndarray, stride: int = 1):
    """
    Perform a 2D convolution over a batch of tensors. This is equivalent to

     output[b, i, j, k] =
         sum_{di, dj, q} input[b, strides[1] * i + di, strides[2] * j + dj, q] *
                         filter[di, dj, q, k]

    :param data_in: Input data tensor with shape [batch, height, width, channels_in]
    :param kernel: Convolution kernel tensor with shape [kernel_height, kernel_width, channels_in, channels_out]
    :param stride: Integer for the step width
    :return: Tensor with shape [batch, height/stride, width/stride, channels_out]
    """

    # Obtain shapes
    fh, fw, kin_ch, kout_ch = kernel.shape
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

    # Given an input tensor of shape [batch, in_height, in_width, in_channels] and a filter / kernel tensor of
    # shape [filter_height, filter_width, in_channels, out_channels], this op performs the following:
    #
    # 1) Flattens the filter to a 2-D matrix with shape [filter_height * filter_width * in_channels,
    # output_channels].
    #
    # 2) Extracts image patches from the input tensor to form a virtual tensor of shape [batch,
    # out_height, out_width, filter_height * filter_width * in_channels].
    #
    # 3) For each patch, right-multiplies the
    # filter matrix and the image patch vector

    # pad input
    in_padded = np.pad(data_in, ((0, 0), (2, 2), (2, 2), (0, 0)), 'constant', constant_values=(0, 0))

    # kflat = np.reshape(kernel, newshape=(-1, kout_ch))
    # vout = np.zeros(shape=(batch, in_h, in_w, fh * fw * in_ch))  # create virtual out
    #
    # for b in range(batch):
    #     for i in range(in_h):
    #         for j in range(in_w):
    #             vout[b, i, j, :] = np.reshape(in_padded[b, i:i+fh, j:j+fw, :], newshape=(-1))
    #
    # out = np.dot(vout, kflat)

    # output[b, i, j, k] =
    #     sum_{di, dj, q} input[b, strides[1] * i + di, strides[2] * j + dj, q] *
    #                     filter[di, dj, q, k]
    for b in range(batch):
        for k in range(kout_ch):
            # k = kernel[:, :, q, k]  # 2d kernel

            # Perform convolution
            i_out, j_out = 0, 0
            for i in range(0, in_h, stride):
                for j in range(0, in_w, stride):
                    patch = in_padded[b, i:i + fh, j:j + fw, :]  # 3d tensor
                    patch_sum = np.sum(patch * kernel[:, :, :, k], axis=(0, 1, 2))  # sum along all axis
                    out[b, i_out, j_out, k] = patch_sum
                    j_out += 1
                j_out = 0
                i_out += 1

    return out


class ConvLayer(Layer):
    activation: Optional[str]
    b: ndarray
    kernel: ndarray

    def __init__(self, in_channels, out_channels, kernel_size, activation=None):
        self.kernel = init_kernel(in_channels, out_channels, kernel_size)
        self.b = np.random.rand(out_channels)
        self.activation = activation

    def __call__(self, *args, **kwargs):
        z = conv2d(args[0], self.kernel, stride=1) + self.b

        if self.activation is None:
            return z
        elif self.activation is "relu":
            return relu(z)
        else:
            raise ValueError("Activation of {} is not valid".format(self.activation))

    def get_input_shape(self):
        # Input data:  [batch, in_height, in_width, in_channels]
        # Kernel size: [fh, fw, kin_ch, kout_ch]
        #
        # Data can be arbitrary shaped except the number of input channels, which must match the number of output
        # channels
        return -1, -1, -1, self.kernel.shape[2]

    def get_output_shape(self, input_data_shape: ndarray = None):
        # Input data:  [batch, in_height, in_width, in_channels]
        # Kernel size: [fh, fw, kin_ch, kout_ch]
        return -1, -1, -1, self.kernel.shape[3]


def pooling_max(data_in: ndarray, pool_size: int, stride=2):
    batch, in_h, in_w, in_ch = data_in.shape

    out_h = int(in_h / stride)
    out_w = int(in_w / stride)

    pool_out = np.zeros(shape=[batch, out_h, out_w, in_ch])
    i_out, j_out = 0, 0

    for i in range(0, in_h, stride):
        for j in range(0, in_w, stride):
            data_slice = data_in[:, i:i + pool_size, j:j + pool_size, :]
            data_slice_max = np.amax(data_slice, axis=(1, 2))
            pool_out[:, i_out, j_out, :] = data_slice_max
            j_out += 1
        i_out += 1
        j_out = 0
    return pool_out


def apply_pool(data_in: ndarray, pool_size: int, f, stride=2):
    """

    :param data_in: The data that should be processed
    :param pool_size: The size of the patch which is used, for pooling values. It is applied as [pool_size x
    pool_size] along the image width and height axis
    :param f: A callable, which gets a list of values and returns a
    value (e.g. the maximum)
    :param stride: The stride between to pool processes
    :type data_in: ndarray
    """

    batch, in_h, in_w, in_ch = data_in.shape

    out_h = int(in_h / pool_size)
    out_w = int(in_w / pool_size)

    pool_out = np.zeros(shape=[batch, out_h, out_w, in_ch])

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
                    pool_out[b, i, j, c] = val

    return pool_out


class MaxPoolLayer(Layer):
    PoolSize: int

    def __init__(self, size=2):
        self.PoolSize = size

    def __call__(self, *args, **kwargs):
        data_in = args[0]
        return pooling_max(data_in, pool_size=self.PoolSize, stride=self.PoolSize)

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
