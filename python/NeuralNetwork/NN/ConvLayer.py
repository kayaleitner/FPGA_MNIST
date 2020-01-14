import math
from typing import Optional

import numpy as np
from numpy.core.multiarray import ndarray

from NeuralNetwork.NN.Activations import relu
from NeuralNetwork.NN.Layer import Layer
from NeuralNetwork.NN.Quant import quantize_vector


def init_kernel(input_channels: int, out_channels: int = 3, kernel_size: int = 5, dtype=np.float32) -> ndarray:
    """
    Creates a new convolution filter with random initialization
    Args:
        input_channels:
        out_channels:
        kernel_size:
        dtype:

    Returns:

    """
    return np.random.rand(kernel_size, kernel_size, input_channels, out_channels).astype(dtype=dtype)


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

    out = np.zeros(shape=[batch, in_h, in_w, kout_ch], dtype=data_in.dtype)
    # pad input
    in_padded = np.pad(data_in, ((0, 0), (fh2, fh2), (fw2, fw2), (0, 0)), 'constant', constant_values=(0, 0))
    # in_padded = np.pad(data_in, ((0, 0), (30, 30), (30, 30), (0, 0)), 'constant', constant_values=(0, 0))
    # img = np.squeeze(in_padded)
    # fig, ax = plt.subplots()
    # _im = ax.imshow(img, cmap='gray')
    # fig.colorbar(_im)
    # plt.show()

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
                    patch = in_padded[b, i:i + fh, j:j + fw, :]  # 3d tensor 3x3x16
                    # patch_sum is always int64
                    patch_sum = np.sum(patch * kernel[:, :, :, k], axis=(0, 1, 2))  # sum along all axis

                    if kernel.dtype.kind in 'ui':  # check if datatype is unsigned or integer
                        min_value = np.iinfo(kernel.dtype).min
                        max_value = np.iinfo(kernel.dtype).max
                        out[b, i_out, j_out, k] = np.clip(patch_sum, a_min=min_value, a_max=max_value).astype(
                            kernel.dtype)
                    else:
                        out[b, i_out, j_out, k] = patch_sum
                    j_out += 1
                j_out = 0
                i_out += 1

    return out


def conv2d_fast(data_in, kernel, stride=1):
    """
    Calculates a fast convolution using the C module
    Args:
        data_in: input tensor, should have the shape [BATCH, HEIGHT, WIDTH, CHANNELS]
        kernel: kernel tensor, should have the shape [CHANNEL_OUT, CHANNEL_IN, K_HEIGHT, K_WIDTH]
        stride: strides between the convolution operations, default is 1

    Returns:
        the convolution result
    """
    import NeuralNetwork.Ext.NeuralNetworkExtension as nnext
    # ToDo: Find a way to move this type checking to the wrapper layer in C

    if data_in.dtype == np.float32:
        return nnext.conv2d_float(data_in=data_in, kernel=kernel, stride=stride)

    elif data_in.dtype == np.float64:
        return nnext.conv2d_double(data_in=data_in, kernel=kernel, stride=stride)

    elif data_in.dtype == np.int8:
        return nnext.conv2d_int8_t(data_in=data_in, kernel=kernel, stride=stride)

    elif data_in.dtype == np.int16:
        return nnext.conv2d_int16_t(data_in=data_in, kernel=kernel, stride=stride)

    elif data_in.dtype == np.int32:
        return nnext.conv2d_int32_t(data_in=data_in, kernel=kernel, stride=stride)

    else:
        # ToDo: Add missing types
        raise NotImplementedError()


class Conv2dLayer(Layer):
    activation: Optional[str]
    b: ndarray
    kernel: ndarray

    def __init__(self,
                 in_channels,
                 out_channels,
                 kernel_size,
                 activation=None,
                 dtype=np.float32,
                 kernel_init_weights=None,
                 bias_init_weights=None):

        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size
        self.activation = activation
        self.dtype = dtype

        if kernel_init_weights is None:
            self.kernel = init_kernel(in_channels, out_channels, kernel_size, dtype=dtype)
        else:
            self.kernel = kernel_init_weights

        if bias_init_weights is None:
            self.b = np.random.rand(out_channels).astype(dtype=dtype)
        else:
            self.b = bias_init_weights

    @property
    def weights(self):
        return self.kernel

    @weights.setter
    def weights(self, value):
        assert isinstance(value, np.ndarray)
        self.kernel = value

    @property
    def bias(self):
        return self.b

    @bias.setter
    def bias(self, value):
        assert isinstance(value, np.ndarray)
        self.b = value

    @property
    def activation_func(self):
        return self.activation

    @activation_func.setter
    def activation_func(self, value):
        assert value in ('relu', 'softmax', None)
        self.activation = value

    def __call__(self, *args, **kwargs):
        if self.dtype in (np.float32, np.float64):
            z = conv2d_fast(args[0], self.kernel, stride=1) + self.b
        else:
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

    def cast(self, new_dtype: np.dtype):
        self.dtype = new_dtype
        self.kernel = self.kernel.astype(dtype=new_dtype)
        self.b = self.b.astype(dtype=new_dtype)

    def __copy__(self):
        c = Conv2dLayer(in_channels=self.in_channels,
                        out_channels=self.out_channels,
                        kernel_size=self.kernel_size,
                        activation=self.activation,
                        dtype=self.dtype,
                        kernel_init_weights=self.kernel.copy(),
                        bias_init_weights=self.b.copy())
        return c

    def quantize_layer(self, target_type, max_value, min_value):
        self.dtype = target_type
        self.kernel = quantize_vector(self.kernel, target_type=target_type, max_value=max_value, min_value=min_value)
        self.b = quantize_vector(self.b, target_type=target_type, max_value=max_value, min_value=min_value)


def pooling_max(data_in: ndarray, pool_size: int, stride=2):
    batch, in_h, in_w, in_ch = data_in.shape

    out_h = int(in_h / stride)
    out_w = int(in_w / stride)

    pool_out = np.zeros(shape=[batch, out_h, out_w, in_ch], dtype=data_in.dtype)
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


class MaxPool2dLayer(Layer):
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

    def __copy__(self):
        return MaxPool2dLayer(size=self.PoolSize)


class AveragePool2dLayer(Layer):
    PoolSize: int

    def __init__(self, size=2):
        self.PoolSize = size

    def __call__(self, *args, **kwargs):
        data_in = args[0]
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

    def __copy__(self):
        return AveragePool2dLayer(size=self.PoolSize)
