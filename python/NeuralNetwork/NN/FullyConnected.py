from typing import Optional

import numpy as np
from numpy.core.multiarray import ndarray

from NeuralNetwork.NN.Layer import Layer
from NeuralNetwork.NN.Activations import relu, softmax


class FullyConnectedLayer(Layer):
    activation: Optional[str]
    W: ndarray  # Weights of the layer, dimensions: [IN x OUT]
    b: ndarray  # bias of the layer

    def __init__(self, input_size, output_size, activation=None, dtype=np.float32, weights=None, bias=None):
        self.input_size = input_size
        self.output_size = output_size
        self.activation = activation
        self.dtype = dtype

        if weights is None:
            self.W = np.random.rand(input_size, output_size).astype(dtype=dtype)
        else:
            assert isinstance(weights, np.ndarray)
            assert np.all(weights.shape == (input_size, output_size))
            self.W = weights

        if bias is None:
            self.b = np.random.rand(output_size).astype(dtype=dtype)
        else:
            assert isinstance(weights, np.ndarray)
            assert np.all(weights.shape == (input_size, output_size))
            self.W = weights

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
        layer = self.__copy__()
        layer.W = layer.W.astype(dtype=new_dtype)
        layer.b = layer.b.astype(dtype=new_dtype)
        return layer

    def __copy__(self):
        c = FullyConnectedLayer(input_size=self.input_size,
                                output_size=self.output_size,
                                dtype=self.dtype,
                                weights=self.W.copy(),
                                bias=self.b.copy())
        return c
