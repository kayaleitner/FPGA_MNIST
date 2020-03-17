import numpy as np

import EggNetExtension as nnext


class LayerActivations:
    features = None

    def __init__(self, model, layer_num, validate_func):
        self.hook = model[layer_num].register_forward_hook(self.hook_fn)
        self.validate_func = validate_func

    def hook_fn(self, module, input, output):
        validated_out = self.validate_func(module, input, output)
        self.features = output.cpu()

    def remove(self):
        self.hook.remove()

    @staticmethod
    def torch_conv_weights_to_keras(x):
        # x_ = x.numpy()
        # H W Ci Co
        # Co Ci H W
        x_ = np.moveaxis(x, (0, 1), (3, 2))
        return x_

    @staticmethod
    def torch_conv_activations_to_keras(x):
        x_ = x.numpy()
        # B H W C
        # B C H W
        x_ = np.moveaxis(x_, 1, 3)
        return x_

    @staticmethod
    def torch_convolution_check(module, x, y, kernel, bias):
        # Use tupel unpacking?
        x = x[0]
        # x = x.numpy()
        # y = y.numpy()
        x = LayerActivations.torch_conv_activations_to_keras(x)
        y = LayerActivations.torch_conv_activations_to_keras(y)
        # import NeuralNetwork
        # y_ = NeuralNetwork.nn.conv2d_torch(x, kernel)
        y_ = nnext.conv2d_float(x, kernel, stride=1) + bias


def _imshow(image_batch, nbatch=0, nchannel=0, mode='keras'):
    import matplotlib.pyplot as plt
    if mode is 'keras':
        plt.imshow(image_batch[nbatch, :, :, nchannel], cmap='gray')
    elif mode is 'torch':
        plt.imshow(image_batch[nbatch, nchannel, :, :], cmap='gray')
    else:
        raise TypeError('Unknown mode')
    plt.show()


def _kernelshow(kernel, ci, co):
    import matplotlib.pyplot as plt
    plt.imshow(kernel[:, :, ci, co], cmap='gray')
    plt.show()


def _shift_image(image, dx, dy):
    return np.roll(image, shift=(dy, dx), axis=(1, 2))
    # e = np.empty_like(image)
    # e[:, :dx, :dy, :] = 0
    # e[:, dx:, dy:, :] = image[:, :-dx, :-dy, :]


def check_torch_conv_hook(m, x, y, kernel, bias):
    x = x[0]

    xk = LayerActivations.torch_conv_activations_to_keras(x)
    yk = LayerActivations.torch_conv_activations_to_keras(y)
    kk = LayerActivations.torch_conv_weights_to_keras(kernel)
    x = x.numpy()
    y = y.numpy()

    from EggNet import NeuralNetwork
    bk = bias
    bias = np.reshape(bias, newshape=(1, -1, 1, 1))  # make 4d
    y_ = NeuralNetwork.nn.conv2d_torch(x, kernel) + bias
    yk_ = NeuralNetwork.nn.conv2d(xk, kk) + bk
    # Check if y and y_ are equal

    e = y - y_
    ek = yk - yk_
