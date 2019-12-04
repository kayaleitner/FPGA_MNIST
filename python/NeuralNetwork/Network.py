from typing import List
import numpy as np

from NeuralNetwork.Costs import mean_squared_error
from NeuralNetwork.Layer import Layer


def check_layers(list_of_layers: List[Layer]):
    """

    :type list_of_layers: List[Layer]
    """

    for i in range(1, len(list_of_layers)):
        l1 = list_of_layers[i - 1]
        l2 = list_of_layers[i]

        # Get the shapes and convert to numpy arrays
        l1_shape_out = np.array(l1.get_output_shape())
        l2_shape_in = np.array(l2.get_input_shape())

        if l2_shape_in.ndim == 0:
            # Zero dimension layer accepts every input
            continue

        if not (l1_shape_out.ndim == l2_shape_in.ndim):
            raise ValueError(
                "Output of layer {} dim({}) but input of layer {} has dim({})".format(i, len(l1_shape_out), i + 1,
                                                                                      len(l2_shape_in)))
        if not np.all(l1_shape_out == l2_shape_in):
            raise ValueError(
                "Layer {} has dimensions [{}] but layer {} has [{}]".format(i, l1_shape_out, i + 1, l2_shape_in))


class Network:
    layers: List[Layer]

    def __init__(self, list_of_layers: List[Layer]):
        """

        :type list_of_layers: List[Layer]
        """
        # check_layers(list_of_layers)

        self.layers = list_of_layers

    def forward(self, x):
        z, _ = self.forward_intermediate(x)
        return z

    def forward_intermediate(self, x):
        z = x  # copy data
        zs = []
        for l in self.layers:
            z = l(z)
            zs.append(z)
        return z, zs

    def backprop(self, x, y_):
        y, zs = self.forward_intermediate(x)
        loss = mean_squared_error(y, y_)
        delta = y - y_
        deltas = []
        for l in self.layers:
            delta = l.backprop(delta)
            deltas.append(delta)
            l.update_weights(delta)
