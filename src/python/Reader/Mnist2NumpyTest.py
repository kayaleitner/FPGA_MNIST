import os
import unittest
from .Mnist2Numpy import MnistDataReader, MnistDataDownloader


class Mnist2NumpyTestCase(unittest.TestCase):

    def test_mnist_download(self):
        loader = MnistDataDownloader()

        loader.download_mnist()


    def test_mnist2numpy(self):

        MNIST_TEST_FILE_NAME = "t10k-images-idx3-ubyte.gz"
        script_path = os.path.realpath(__file__)
        script_folder = os.path.dirname(script_path)

        file_path = os.path.join(script_folder, MNIST_TEST_FILE_NAME)
        f = MnistDataReader(file_path)

        img = f.get_Arrays(100)
        self.assertEqual(img.shape, [100, 28, 28])

        img = f.get_Arrays(200)
        self.assertEqual(img.shape, [200, 28, 28])


if __name__ == '__main__':
    unittest.main()
