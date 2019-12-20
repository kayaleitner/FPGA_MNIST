import numpy as np
from numpy import reshape
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


def channels_last_2_channels_first(x: np.ndarray):
    """
    Converts a tensor with shape [B,H,W,C] to a tensor with shape [B,C,H,W]
    ToDo: Definitely needs a test
    """
    B, H, W, C = x.shape
    y = np.zeros(shape=(B, C, H, W))
    for b in range(B):
        for h in range(H):
            for w in range(W):
                for c in range(C):
                    # ToDo: Vectorize without changing behaviour or rewrite in C for performance
                    y[b, c, h, w] = x[b, h, w, c]


def channels_first_2_channels_last(x: np.ndarray):
    """
    Converts a tensor with shape [B,C,H,W] to a tensor with shape [B,H,W,C]
    ToDo: Definitely needs a test
    """
    B, C, H, W = x.shape
    y = np.zeros(shape=(B, H, W, C))
    for b in range(B):
        for h in range(H):
            for w in range(W):
                for c in range(C):
                    # ToDo: Vectorize without changing behaviour or rewrite in C for performance
                    y[b, h, w, c] = x[b, c, h, w]


class ReshapeLayer(Layer):
    newshape: np.ndarray

    def __init__(self, newshape):
        self.newshape = newshape

    def __call__(self, *args, **kwargs):
        x = args[0]
        return reshape(x, newshape=self.newshape)

    def get_input_shape(self):
        pass  # can be anything

    def get_output_shape(self, input_data_shape: np.ndarray = None):
        return self.newshape
