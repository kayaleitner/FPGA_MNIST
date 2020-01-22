import unittest
from NeuralNetwork.NN.FullyConnected import FullyConnectedLayer
import numpy as np
import tensorflow as tf


class FullyConnectedLayerTestCase(unittest.TestCase):

    def test_something(self):
        fc = FullyConnectedLayer(1, 10)
        self.assertEqual(fc.W.shape, (1, 10))
        self.assertEqual(fc.b.shape, (10,))

        x = np.random.rand(1, 1)
        y = fc(x)
        self.assertEqual(y.shape, (1, 10))

    def test_relu(self):
        fc = FullyConnectedLayer(1, 10, activation='relu')
        self.assertEqual(fc.W.shape, (1, 10))
        self.assertEqual(fc.b.shape, (10,))

        x = np.random.rand(1, 1)
        y = fc(x)
        self.assertEqual(y.shape, (1, 10))

    def test_tf_compare(self):
        x = np.random.rand(10, 1) .astype(np.float32)  # create 4 test images
        fc = FullyConnectedLayer(input_size=1, output_size=10, activation='relu')
        y = fc(x)

        W = fc.W
        b = fc.b

        y_tf = tf.matmul(x, W) + b
        y_tf = tf.nn.relu(y_tf)
        y_tf = y_tf.numpy()  # calculate numpy array

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            self.assertAlmostEqual(v1, v2, delta=0.1)


if __name__ == '__main__':
    unittest.main()
