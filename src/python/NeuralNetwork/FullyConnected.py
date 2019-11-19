import numpy as np
from numpy.core.multiarray import ndarray

from .Layer import Layer


class FullyConnectedLayer(Layer):
    W: ndarray  # Weights of the layer, dimensions: [IN x OUT]
    b: ndarray  # bias of the layer

    def __init__(self, input_size, output_size):
        self.W = np.random.rand(input_size, output_size)
        self.b = np.random.rand(output_size)

    def __call__(self, *args, **kwargs):
        # use the '@' sign to refer to a tensor dot
        return args[0] @ self.W + self.b

    def get_input_shape(self):
        return self.W.shape[0], -1

    def get_output_shape(self, input_data_shape: ndarray = None):
        return self.W.shape[1], -1
