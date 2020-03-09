import os
import unittest
from EggNet.NeuralNetwork.Reader import MnistDataReader, MnistDataDownloader, DataSetType
from EggNet.NeuralNetwork.Reader import Dataset

class Mnist2NumpyTestCase(unittest.TestCase):

    def test_mnist2numpy(self):
        from urllib.error import URLError
        MNIST_TEST_FILE_NAME = "t10k-images-idx3-ubyte.gz"
        MNIST_LBL_FILE_NAME = "t10k-labels-idx1-ubyte.gz"

        script_path = os.path.realpath(__file__)
        script_folder = os.path.dirname(script_path)

        file_path = os.path.join(script_folder, MNIST_TEST_FILE_NAME)
        lbl_path = os.path.join(script_folder, MNIST_LBL_FILE_NAME)
        try:
            f = MnistDataReader(image_filename=file_path, label_filename=lbl_path)
            for lbls, imgs in f.get_next(100):
                self.assertEqual(imgs.shape, (100, 28, 28))
                self.assertEqual(lbls.shape, (100, 1))
                break
        except URLError as err:
            import logging
            logging.warning("There was an errror downloading stuff: ", err)

        

    def test_usingCache(self):
        from urllib.error import URLError
        # Is relative to working directory
        rel_path = "../../../data/MNIST/"
        data_path = os.path.abspath(rel_path)

        # Should download to this folder
        try:
            loader = MnistDataDownloader(folder_path=data_path)
            lbl1, imgs1 = loader.get_path(DataSetType.TRAIN)
            self.assertIsNotNone(lbl1)
            self.assertIsNotNone(imgs1)

            lbl2, imgs2 = loader.get_path(DataSetType.TEST)
            self.assertIsNotNone(lbl2)
            self.assertIsNotNone(imgs2)
        except URLError as err:
            import logging
            logging.warning("There was an errror downloading stuff: ", err)

class DatasetTestCase(unittest.TestCase):

    def test_train(self):
        mnist = Dataset()

        lbls = mnist.train_labels()
        imgs = mnist.train_images()




if __name__ == '__main__':
    unittest.main()
