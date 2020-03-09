import idx2numpy
import gzip
import EggNet.Reader


class Dataset:

    def get_train_iterator(self, batch_size):
        raise NotImplementedError()

    def get_test_iterator(self, batch_size):
        raise NotImplementedError()


class MNIST(Dataset):
    _classnames = map(str, [i for i in range(10)])

    def __init__(self, folder_path=None):

        self.downloader = EggNet.Reader.MnistDataDownloader(folder_path=folder_path)

    def train_labels(self):
        imgs_path, lbls_path = self.downloader.get_path(EggNet.Reader.DataSetType.TRAIN)
        return idx2numpy.convert_from_file(gzip.open(filename=lbls_path))

    def train_images(self):
        imgs_path, lbls_path = self.downloader.get_path(EggNet.Reader.DataSetType.TRAIN)
        return idx2numpy.convert_from_file(gzip.open(filename=imgs_path))

    def test_labels(self):
        imgs_path, lbls_path = self.downloader.get_path(EggNet.Reader.DataSetType.TEST)
        return idx2numpy.convert_from_file(gzip.open(filename=lbls_path))

    def test_images(self):
        imgs_path, lbls_path = self.downloader.get_path(EggNet.Reader.DataSetType.TEST)
        return idx2numpy.convert_from_file(gzip.open(filename=imgs_path))

    def get_test_iterator(self, batch_size):
        return DatasetIterator(batch_size=batch_size, x=self.test_images(), y=self.test_labels())

    def get_train_iterator(self, batch_size):
        return DatasetIterator(batch_size=batch_size, x=self.train_images() / 255.0, y=self.train_labels())


class DatasetIterator:

    def __init__(self, batch_size, x,y):
        self.batch_size = batch_size
        self.y = y
        self.x = x

    def __iter__(self):
        self.i = 0

        return self

    def __next__(self):
        i = self.i

        if i > self.x.shape[0]:
            raise StopIteration

        while self.i < self.x.shape[0]:
            x = self.x[i:i + self.batch_size]
            y = self.y[i:i + self.batch_size]
            return x, y


