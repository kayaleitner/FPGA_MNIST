import numpy as np
from numpy.core.multiarray import ndarray

from .Layer import Layer


class FullyConnectedLayer(Layer):
    W: ndarray  # Weights of the layer, dimensions: [OUT x IN]
    b: ndarray  # bias of the layer

    def __init__(self, input_size, output_size):
        self.W = np.random.rand(output_size, input_size)
        self.b = np.random.rand(output_size, 1)

    def __call__(self, *args, **kwargs):
        # use the '@' sign to refer to a tensor dot
        return self.W @ args[0] + self.b

    def get_input_shape(self):
        return self.W.shape[1], -1

    def get_output_shape(self, input_data_shape: ndarray = None):
        return self.W.shape[0], -1


