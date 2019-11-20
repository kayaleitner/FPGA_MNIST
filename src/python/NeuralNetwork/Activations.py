import numpy as np

from .Layer import Layer


def relu(x: np.ndarray) -> np.ndarray:
    """
    Applies the Relu activation function to the input
    :param x: values
    :return:
    """
    z = x
    z[x < 0] = 0
    return z


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
    norm = np.sum(x, axis=x.ndim-1)
    return x / norm[..., np.newaxis]


class ActivationLayer(Layer):

    # act_func: (np.ndarray) : np.ndarray

    def __init__(self, func):
        self.act_func = func

    def __call__(self, *args, **kwargs):
        x = args[0]
        return self.act_func(x)

    def get_output_shape(self, input_data_shape: np.ndarray = None):
        return input_data_shape.shape

    def get_input_shape(self):
        # accepts every shape
        pass


class ReluActivationLayer(ActivationLayer):

    def __init__(self):
        ActivationLayer.__init__(self, func=relu)


class SoftmaxLayer(ActivationLayer):

    def __init__(self):
        ActivationLayer.__init__(self, func=softmax)