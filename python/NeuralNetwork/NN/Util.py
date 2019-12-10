import numpy as np
from numpy import reshape
from numpy.core.multiarray import ndarray
from NeuralNetwork.NN.Layer import Layer


def indices(a, func):
    return [i for (i, val) in enumerate(a) if func(val)]


def ind2sub(ind, shape):
    d = np.cumprod(list(reversed(shape)))

    s = []
    for (i, shape_i) in enumerate(shape):
        d /= shape_i
        s.append(ind % d)

    return tuple(s)


class ReshapeLayer(Layer):
    newshape: ndarray

    def __init__(self, newshape):
        self.newshape = newshape

    def __call__(self, *args, **kwargs):
        x = args[0]
        return reshape(x, newshape=self.newshape)

    def get_input_shape(self):
        pass  # can be anything

    def get_output_shape(self, input_data_shape: ndarray = None):
        return self.newshape
