import numpy as np
from numpy.core.multiarray import ndarray


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


def make_gauss_kernel(size=5, sigma=1.6) -> ndarray:
    """
    Creates a gaussian blur filter kernel
    Args:
        size:
        sigma:

    Returns:

    """
    k = np.zeros(shape=[size, size])

    for i in range(size):
        for j in range(size):
            x = i - float(size) / 2
            y = j - float(size) / 2
            k[i, j] = 1 / (2 * np.pi * sigma ** 2) * np.exp(-(x ** 2 + y ** 2) / (2 * sigma ** 2))

    return k


def make_random_kernel(size=(3, 3), mu=0.5, sigma=0.3):
    return np.random.normal(loc=mu, scale=sigma, size=size)


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
    if kernel.dtype.kind in 'ui':  # check if datatype is unsigned or integer
        out = np.zeros(shape=[batch, in_h, in_w, kout_ch], dtype=np.int32)
    else:
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

                    if kernel.dtype.kind in 'ui':  # check if datatype is unsigned or integer
                        patch16 = patch.astype(np.int16)
                        kernel16 = kernel.astype(np.int16)
                        temp = patch16 * kernel16[:, :, :, k]
                        temp = temp.flatten().astype(np.int64)
                        # patch_sum = np.sum(patch * kernel[:, :, :, k], axis=(0, 1, 2))  # sum along all axis
                        # min_value = np.iinfo(kernel.dtype).min
                        # max_value = np.iinfo(kernel.dtype).max
                        patch_sum = np.sum(temp)
                        out[b, i_out, j_out, k] = patch_sum
                    else:
                        # patch_sum is always int64
                        patch_sum = np.sum(patch * kernel[:, :, :, k], axis=(0, 1, 2))  # sum along all axis
                        out[b, i_out, j_out, k] = patch_sum
                    j_out += 1
                j_out = 0
                i_out += 1

    return out


def fpi_conv2d(data_in: ndarray,
               data_in_m: int,
               kernel: ndarray,
               kernel_m: int,
               stride: int = 1):
    if kernel.dtype.kind not in 'i':  # check if datatype is unsigned or integer
        raise ValueError('kernel datatype must be integer')

    # Obtain shapes
    fh, fw, kin_ch, kout_ch = kernel.shape
    batch, in_h, in_w, in_ch = data_in.shape

    if kin_ch != in_ch:
        raise ValueError("Input channel mismatch")

    # Check if the filter has an uneven width
    assert (1 == fh % 2)
    assert (1 == fw % 2)

    # Find the midpoint of the filter. This only works for odd filter sizes
    fh2 = (fh - 1) // 2
    fw2 = (fw - 1) // 2

    import NeuralNetwork.nn.quant as quant

    """ Output bytes """
    # the patch has shape e.g. (3,3,3)
    # how much space must be left to sum up those values?
    patch_size = kin_ch * fh * fw
    additional_bits_needed = np.log2(quant.next_pow2(patch_size)).astype(np.int)
    outbits = quant.np_bits(data_in.dtype) + quant.np_bits(kernel.dtype) + additional_bits_needed
    data_out_type = quant.datatype_for_bits(outbits)
    out = np.zeros(shape=[batch, in_h, in_w, kout_ch], dtype=data_out_type)

    # The output scaling is identical to the kernel shift plus the minimum image channel shift. This is because the
    # kernels dont disturb each other but the image channels must be rescaled due the fact that they are summed up
    out_m = kernel_m + np.min(data_in_m)
    image_axis_shift = (data_in_m - np.min(data_in_m)).astype(np.int)

    """ Input Padding """
    in_padded = np.pad(data_in, ((0, 0), (fh2, fh2), (fw2, fw2), (0, 0)), 'constant', constant_values=(0, 0))

    for b in range(batch):
        for k in range(kout_ch):

            i_out, j_out = 0, 0
            for i in range(0, in_h, stride):
                for j in range(0, in_w, stride):
                    patch = in_padded[b, i:i + fh, j:j + fw, :]  # 3d tensor 3x3x16
                    # temp = patch * kernel[:, :, :, k]
                    temp_control = patch.astype(np.float) * kernel[:, :, :, k].astype(np.float)
                    temp = np.multiply(patch, kernel[:, :, :, k], dtype=data_out_type)
                    assert np.allclose(temp, temp_control)

                    # Shift the kernel
                    for ix_ax, ax_shift in enumerate(image_axis_shift):
                        temp[:, :, ix_ax] = np.right_shift(temp[:, :, ix_ax], ax_shift)
                        temp_control[:, :, ix_ax] = temp_control[:, :, ix_ax] / 2 ** ax_shift

                    patch_sum = temp.flatten().sum(dtype=data_out_type)
                    patch_control_sum = temp_control.flatten().sum()
                    if np.abs(patch_sum - patch_control_sum) > 10:
                        print("Significant Difference here")
                        assert np.allclose(patch_sum, patch_control_sum)

                    out[b, i_out, j_out, k] = patch_sum
                    j_out += 1
                j_out = 0
                i_out += 1

    return out, out_m, outbits


def q_matmul(w, x, b):
    pass


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


def mean_squared_error(predictions: np.ndarray, labels: np.ndarray) -> np.ndarray:
    """
    Calculates the mean squared error
    :param predictions: Array of predictions with dimensions [batch out_size]
    :param labels: Array of labels with dimensions [batch out_size]
    :return:
    """
    return np.sum(np.sum((predictions - labels) ** 2))


def cross_entropy(predictions, labels):
    """
    Calculates the cross entropy cost
    :param predictions: Array of predictions with dimensions [batch out_size]
    :param labels: Array of labels with dimensions [batch out_size]
    :return:
    """
    return np.sum(np.sum(labels * np.log(predictions) + (1 - labels) * np.log(1 - predictions)))


def relu(x: np.ndarray) -> np.ndarray:
    """
    Applies the Relu activation function to the input
    :param x: values
    :return:
    """
    return x.clip(min=0)


def drelu(x: np.ndarray) -> np.ndarray:
    """
    Evaluates the derivative of the relu func (which is equivalent to the step func)
    :param x:
    :return:
    """
    return (x > 0) * 1.0  # multiply to convert from boolean to float


def softmax(x: np.ndarray) -> np.ndarray:
    """
    Calculates the softmax func

    y = x / sum(x)

    :param x: Array with dimensions [batch out_dim]
    """
    norm = np.sum(np.exp(x), axis=-1, keepdims=True)
    return np.exp(x) / norm
