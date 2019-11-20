import unittest

import numpy as np
import tensorflow as tf
from tensorflow import keras
from .ConvLayer import ConvLayer, MaxPoolLayer, test_kernel_gauss


class PoolLayerTest(unittest.TestCase):

    def test_pool(self):
        pl = MaxPoolLayer(size=2)

        img = np.array([
            [1, 2, 1, 1],
            [1, 1, 3, 1],
            [1, 4, 1, 1],
            [4.3, 1, 1, 5],
        ])

        img = np.reshape(img, newshape=(1, 4, 4, 1))

        exp_img = np.array([
            [2, 3],
            [4.3, 5]
        ])
        exp_img = np.reshape(exp_img, newshape=(1, 2, 2, 1))

        p_img = pl(img)

        self.assertEqual(p_img.shape, (1, 2, 2, 1))
        self.assertTrue(np.array_equal(p_img, exp_img))

    def test_tf_compare(self):
        b = 0
        test_img = np.random.rand(10, 128, 128, 3)  # create 4 test images

        y_tf = tf.nn.max_pool2d(test_img, ksize=2, strides=2, padding='SAME', data_format='NHWC')
        y_tf = y_tf.numpy()  # calculate numpy array

        mp = MaxPoolLayer(size=2)
        y = mp(test_img)

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            self.assertAlmostEqual(v1, v2, delta=0.01)


class ConvLayerTest(unittest.TestCase):

    def test_conv(self):
        cl = ConvLayer(in_channels=1, out_channels=3, kernel_size=5)

        test_img = np.random.rand(4, 28, 28, 1)  # create 4 test images

        cl_out = cl.__call__(test_img)
        # Check Shape
        self.assertEqual(cl_out.shape, (4, 28, 28, 3))

    def test_tf_compare_zero(self):

        kernel = np.zeros(shape=(5, 5, 8, 16))
        b = np.zeros(16)

        x = np.random.rand(5, 28, 28, 8)  # create 4 test images

        y_tf = tf.nn.conv2d(x, kernel, strides=1, padding='SAME')
        y_tf = y_tf.numpy()  # calculate numpy array
        cl = ConvLayer(in_channels=1, out_channels=3, kernel_size=5)
        cl.kernel = kernel
        cl.b = b
        y = cl(x)

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            self.assertAlmostEqual(v1, 0, delta=0.0001)
            self.assertAlmostEqual(v2, 0, delta=0.0001)

    def test_tf_compare1(self):
        # kernel = test_kernel_gauss(size=5, sigma=1.6)
        # kernel = kernel[..., np.newaxis, np.newaxis]
        kernel = np.random.rand(5, 5, 1, 3)
        # kernel = np.zeros(shape=(5, 5, 1, 3))
        b = np.zeros(3)

        x = np.random.rand(5, 28, 28, 1)  # create 4 test images

        y_tf = tf.nn.conv2d(x, kernel, strides=1, padding='SAME')
        y_tf = y_tf.numpy()  # calculate numpy array
        cl = ConvLayer(in_channels=1, out_channels=3, kernel_size=5)
        cl.kernel = kernel
        cl.b = b
        y = cl(x)

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            # self.assertAlmostEqual(v1,0,delta=0.0001)
            # self.assertAlmostEqual(v2, 0, delta=0.0001)
            self.assertAlmostEqual(v1, v2, delta=0.001)

    def test_tf_compare2(self):
        # kernel = test_kernel_gauss(size=5, sigma=1.6)
        # kernel = kernel[..., np.newaxis, np.newaxis]
        kernel = np.random.rand(5, 5, 8, 16)
        b = np.zeros(16)
        x = np.random.rand(5, 28, 28, 8)  # create 4 test images

        y_tf = tf.nn.conv2d(x, kernel, strides=1, padding='SAME')
        y_tf = y_tf.numpy()  # calculate numpy array
        cl = ConvLayer(in_channels=8, out_channels=16, kernel_size=5)
        cl.kernel = kernel
        cl.b = b
        y = cl(x)

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            self.assertAlmostEqual(v1, v2, delta=0.001)

    def test_tf_compare3(self):
        # kernel = test_kernel_gauss(size=5, sigma=1.6)
        # kernel = kernel[..., np.newaxis, np.newaxis]
        kernel = 2.0 * (np.random.rand(5, 5, 8, 16) - 0.5)
        b = np.zeros(16)
        x = np.random.rand(30, 28, 28, 8)  # create 4 test images

        y_tf = tf.nn.conv2d(x, kernel, strides=1, padding='SAME')
        y_tf = tf.nn.relu(y_tf)
        y_tf = y_tf.numpy()  # calculate numpy array
        cl = ConvLayer(in_channels=8, out_channels=16, kernel_size=5, activation='relu')
        cl.kernel = kernel
        cl.b = b
        y = cl(x)

        self.assertEqual(y_tf.shape, y.shape)

        for v1, v2 in zip(y_tf.flatten(), y.flatten()):
            self.assertAlmostEqual(v1, v2, delta=0.001)


if __name__ == '__main__':
    unittest.main()
