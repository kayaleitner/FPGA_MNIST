import os
import unittest
from .Mnist2Numpy import MnistDataReader, MnistDataDownloader, DataSetType


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

    def test_usingCache(self):

        # Is relative to working directory
        rel_path = "../../data/MNIST/"
        data_path = os.path.abspath(rel_path)

        # Should download to this folder
        loader = MnistDataDownloader(folder_path=data_path)

        lbl1, imgs1 = loader.get_path(DataSetType.TRAIN)
        self.assertIsNotNone(lbl1)
        self.assertIsNotNone(imgs1)

        lbl2, imgs2 = loader.get_path(DataSetType.TEST)
        self.assertIsNotNone(lbl2)
        self.assertIsNotNone(imgs2)

if __name__ == '__main__':
    unittest.main()
