from typing import Optional

import numpy as np
from numpy.core.multiarray import ndarray

from NeuralNetwork.NN.Layer import Layer
from NeuralNetwork.NN.Activations import relu, softmax


class FullyConnectedLayer(Layer):
    activation: Optional[str]
    W: ndarray  # Weights of the layer, dimensions: [IN x OUT]
    b: ndarray  # bias of the layer

    def __init__(self, input_size, output_size, activation=None, dtype=np.float32):
        self.W = np.random.rand(input_size, output_size).astype(dtype=dtype)
        self.b = np.random.rand(output_size).astype(dtype=dtype)
        self.activation = activation
        self.dtype = dtype

    def __call__(self, *args, **kwargs):
        # use the '@' sign to refer to a tensor dot
        # calculate z = xW + b
        z = args[0] @ self.W + self.b

        if self.activation is None:
            return z
        elif self.activation is "relu":
            # return np.apply_over_axis(relu, z, 1)
            return relu(z)
        elif self.activation is "softmax":
            # return np.apply_over_axis(softmax, z, 1)
            return softmax(z)
        else:
            raise ValueError("Activation of {} is not valid".format(self.activation))

    def get_input_shape(self):
        return self.W.shape[0], -1

    def get_output_shape(self, input_data_shape: ndarray = None):
        return self.W.shape[1], -1

    def cast(self, new_dtype: np.dtype):
        self.W = self.W.astype(dtype=new_dtype)
        self.b = self.b.astype(dtype=new_dtype)
