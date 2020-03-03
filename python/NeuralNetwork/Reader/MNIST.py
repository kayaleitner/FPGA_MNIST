from NeuralNetwork.Reader.Mnist2Numpy import MnistDataReader, MnistDataDownloader, DataSetType
import idx2numpy
import gzip


class Dataset:
    pass


class MNIST(Dataset):
    _classnames = map(str, [i for i in range(10)])

    def __init__(self, folder_path=None):
        self.downloader = MnistDataDownloader(folder_path=folder_path)

    def train_labels(self):
        imgs_path, lbls_path = self.downloader.get_path(DataSetType.TRAIN)
        return idx2numpy.convert_from_file(gzip.open(filename=lbls_path))

    def train_images(self):
        imgs_path, lbls_path = self.downloader.get_path(DataSetType.TRAIN)
        return idx2numpy.convert_from_file(gzip.open(filename=imgs_path))

    def test_labels(self):
        imgs_path, lbls_path = self.downloader.get_path(DataSetType.TEST)
        return idx2numpy.convert_from_file(gzip.open(filename=lbls_path))

    def test_images(self):
        imgs_path, lbls_path = self.downloader.get_path(DataSetType.TEST)
        return idx2numpy.convert_from_file(gzip.open(filename=imgs_path))
