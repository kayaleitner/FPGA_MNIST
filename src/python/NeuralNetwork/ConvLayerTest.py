import unittest
import numpy as np
from .ConvLayer import ConvLayer, MaxPoolLayer


class ConvLayerTest(unittest.TestCase):

    def test_pool(self):
        pl = MaxPoolLayer(size=2)

        img = np.array([
            [1, 2, 1, 1],
            [1, 1, 3, 1],
            [1, 4, 1, 1],
            [1, 1, 1, 5],
        ])

        img = np.reshape(img, newshape=(1, 4, 4, 1))

        exp_img = np.array([
            [2, 3],
            [4, 5]
        ])
        exp_img = np.reshape(exp_img, newshape=(1, 2, 2, 1))

        p_img = pl(img)

        self.assertEqual(p_img.shape, (1, 2, 2, 1))
        self.assertTrue(np.array_equal(p_img, exp_img))

    def test_conv(self):
        cl = ConvLayer(in_channels=1, out_channels=3, kernel_size=5)

        test_img = np.random.rand(4, 28, 28, 1)  # create 4 test images

        cl_out = cl.__call__(test_img)
        # Check Shape
        self.assertEqual(cl_out.shape, (4, 28, 28, 3))


if __name__ == '__main__':
    unittest.main()
