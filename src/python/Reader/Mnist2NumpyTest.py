import os
import unittest
from .Mnist2Numpy import MnistDataReader, MnistDataDownloader


class Mnist2NumpyTestCase(unittest.TestCase):

    def test_mnist_download(self):
        loader = MnistDataDownloader()

        loader.download_mnist()

    def test_mnist2numpy(self):
        MNIST_TEST_FILE_NAME = "t10k-images-idx3-ubyte.gz"
        MNIST_LBL_FILE_NAME = "t10k-labels-idx1-ubyte.gz"

        script_path = os.path.realpath(__file__)
        script_folder = os.path.dirname(script_path)

        file_path = os.path.join(script_folder, MNIST_TEST_FILE_NAME)
        lbl_path = os.path.join(script_folder, MNIST_LBL_FILE_NAME)
        f = MnistDataReader(image_filename=file_path, label_filename=lbl_path)

        for lbls, imgs in f.get_next(100):
            self.assertEqual(imgs.shape, (100, 28, 28))
            self.assertEqual(lbls.shape, (100, 1))
            break


if __name__ == '__main__':
    unittest.main()
