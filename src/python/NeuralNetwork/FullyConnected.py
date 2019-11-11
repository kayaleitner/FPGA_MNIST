import numpy as np
from numpy.core._multiarray_umath import ndarray

from .Layer import Layer


class FullyConnectedLayer(Layer):
    W: ndarray  # Weights of the layer
    b: ndarray  # bias of the layer

    def __init__(self, input_size, output_size):
        self.W = np.random.rand(output_size, input_size)
        self.b = np.random.rand(output_size, 1)

    def __call__(self, *args, **kwargs):
        return self.W * args[0] + self.b
