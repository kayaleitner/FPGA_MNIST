import unittest

import numpy as np

from .ConvLayer import ConvLayer, MaxPoolLayer, test_kernel_gauss
from ..Reader import MnistDataReader, MnistDataDownloader, DataSetType


class PoolLayerTest(unittest.TestCase):

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


class ConvLayerTest(unittest.TestCase):

    def test_conv(self):
        cl = ConvLayer(in_channels=1, out_channels=3, kernel_size=5)

        test_img = np.random.rand(4, 28, 28, 1)  # create 4 test images

        cl_out = cl.__call__(test_img)
        # Check Shape
        self.assertEqual(cl_out.shape, (4, 28, 28, 3))

    def test_blur(self):
        k = test_kernel_gauss()
        cl = ConvLayer(in_channels=1, out_channels=1, kernel_size=5)
        loader = MnistDataDownloader("MNIST/")
        path_img, path_lbl = loader.get_path(DataSetType.TRAIN)

        reader = MnistDataReader(path_img, path_lbl)
        for lbl, img in reader.get_next(4):
            img = img.astype(np.float) / 255.0
            img = np.reshape(img, newshape=[-1, 28, 28, 1])
            k = np.reshape(k, newshape=[k.shape[0], k.shape[1], 1, 1])
            cl.kernel = k
            img_out = cl.conv_simple(data_in=img)

            # Check the dimensions
            self.assertEqual(img_out.shape, (4, 28, 28, 1))

            # Uncomment to see the image
            # img_out = np.reshape(img_out, newshape=[1, 4 * 28, 28, 1])
            # img_out = np.squeeze(img_out)
            # plt.imshow(img_out, cmap='gray', vmin=0.0, vmax=1.0)
            # plt.show()

            break


if __name__ == '__main__':
    unittest.main()
