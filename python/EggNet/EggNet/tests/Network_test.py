import unittest

import numpy as np

import EggNet
from EggNet.Network import Network, check_layers


class NetworkTestCase(unittest.TestCase):

    def testDataShapeCheck(self):
        layers = [
            EggNet.FullyConnectedLayer(input_size=1, output_size=10),
            EggNet.FullyConnectedLayer(input_size=20, output_size=20),
            EggNet.FullyConnectedLayer(input_size=20, output_size=10),
            EggNet.FullyConnectedLayer(input_size=10, output_size=1),
        ]
        self.assertRaises(ValueError, check_layers, layers)

        layers = [
            EggNet.FullyConnectedLayer(input_size=1, output_size=10),
            EggNet.FullyConnectedLayer(input_size=10, output_size=20),
            EggNet.FullyConnectedLayer(input_size=20, output_size=10),
            EggNet.FullyConnectedLayer(input_size=10, output_size=1),
        ]

        try:
            check_layers(layers)
        except ValueError:
            self.fail(msg="Layers check failed")

    def test_forward_prop(self):

        layers = [
            EggNet.ReshapeLayer(newshape=[-1, 28, 28, 1]),
            EggNet.Conv2dLayer(in_channels=1, out_channels=16, kernel_size=3),  # [? 28 28 16]
            EggNet.MaxPool2dLayer(size=2),  # [? 14 14 16]
            EggNet.Conv2dLayer(in_channels=16, out_channels=32, kernel_size=3),  # [? 14 14 32]
            EggNet.MaxPool2dLayer(size=2),  # [?  7  7 32]
            # ConvLayer(in_channels=32, out_channels=64, kernel_size=3),  # [?  7  7 64]
            # MaxPool2dLayer(size=2),
            EggNet.ReshapeLayer(newshape=[-1, 32 * 7 * 7]),
            EggNet.FullyConnectedLayer(input_size=32 * 7 * 7, output_size=64),
            EggNet.FullyConnectedLayer(input_size=64, output_size=10),
        ]

        n = Network(layers)

        # create test data
        x = np.random.rand(10, 28, 28)

        y = n.forward(x)
