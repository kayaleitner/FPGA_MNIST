import unittest

import numpy as np

from .Activations import ReluActivationLayer
from .FullyConnected import FullyConnectedLayer
from .Network import Network, check_layers


class NetworkTestCase(unittest.TestCase):

    def testDataShapeCheck(self):
        layers = [
            FullyConnectedLayer(input_size=1, output_size=10),
            FullyConnectedLayer(input_size=20, output_size=20),
            FullyConnectedLayer(input_size=20, output_size=10),
            FullyConnectedLayer(input_size=10, output_size=1),
        ]
        self.assertRaises(ValueError, check_layers, layers)

        init_net_callable = lambda x: Network(list_of_layers=x)
        self.assertRaises(ValueError, init_net_callable, layers)

        layers = [
            FullyConnectedLayer(input_size=1, output_size=10),
            FullyConnectedLayer(input_size=10, output_size=20),
            FullyConnectedLayer(input_size=20, output_size=10),
            FullyConnectedLayer(input_size=10, output_size=1),
        ]

        try:
            check_layers(layers)
        except ValueError:
            self.fail(msg="Layers check failed")

    def test_forward_prop(self):

        layers = [
            FullyConnectedLayer(input_size=1, output_size=10),
            ReluActivationLayer(),
            FullyConnectedLayer(input_size=10, output_size=20),
            ReluActivationLayer(),
            FullyConnectedLayer(input_size=20, output_size=10),
            ReluActivationLayer(),
            FullyConnectedLayer(input_size=10, output_size=1),
        ]

        n = Network(layers)

        # create test data
        x = np.random.rand(1, 10)

        y = n.forward(x)
