import gzip as gz
import struct as struct
import tempfile
from os.path import join
from typing import List

import numpy as np
import wget


class MnistDataDownloader:
    datapaths: List[str]
    TRAIN_IMG_TMP_FILENAME = r"train-images-idx3-ubyte.gz"
    TRAIN_LBL_TMP_FILENAME = r"train-labels-idx3-ubyte.gz"
    TEST_IMG_TMP_FILENAME = r"test-images-idx3-ubyte.gz"
    TEST_LBL_TMP_FILENAME = r"test-labels-idx3-ubyte.gz"

    TRAIN_IMAGES_URL = r"http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz"
    TRAIN_LABELS_URL = r"http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"
    TEST_IMAGES_URL = r"http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz"
    TEST_LABELS_URL = r"http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz"

    def download_mnist(self):
        tmp_path = tempfile.gettempdir()
        data = [
            (self.TRAIN_IMG_TMP_FILENAME, self.TRAIN_IMAGES_URL),
            (self.TRAIN_LBL_TMP_FILENAME, self.TRAIN_LABELS_URL),
            (self.TEST_IMG_TMP_FILENAME, self.TEST_IMAGES_URL),
            (self.TEST_LBL_TMP_FILENAME, self.TEST_LABELS_URL)
        ]
        self.datapaths = []
        for filename, url in data:
            fullpath = join(tmp_path, filename)
            print("Download {}".format(filename))
            wget.download(url, fullpath)
            self.datapaths.append(fullpath)


class MnistDataReader:

    def __init__(self, filename):
        print("Init idx to numpy converter")

        self.f = gz.open(filename, 'rb')

        self.__get_MagicNumber()
        self.__numberImages = struct.unpack('>i', self.f.read(4))
        self.__numberRows = struct.unpack('>i', self.f.read(4))
        self.__numberColumns = struct.unpack('>i', self.f.read(4))
        print("Number of Images %d" % (self.__numberImages[0]))
        print("Number of Rows %d" % self.__numberRows)
        print("Number of Columns %d" % self.__numberColumns)
        self.__actualImg = 0

    def __del__(self):
        try:
            self.f.close()
        except:
            print("ERROR closing file")
        print("File closed")

    def __get_MagicNumber(self):
        zero, data_type, dims = struct.unpack('>HBB', self.f.read(4))
        if data_type == 0x08:
            self.__type = '>B'
        elif data_type == 0x09:
            self.__type = '>b'
        elif data_type == 0x0B:
            self.__type = '>h'
        elif data_type == 0x0C:
            self.__type = '>i'
        elif data_type == 0x0D:
            self.__type = '>f'
        elif data_type == 0x0E:
            self.__type = '>d'
        else:
            raise Exception('Error reading magic number : Data type {} not supported'.format(data_type))
        self.dim = dims

    def get_Data_type(self):
        return self.__type

    def get_Dimension(self):
        return self.__dim

    def get_ImagesNumber(self):
        return self.__numberImages

    def get_RowNumber(self):
        return self.__numberRows

    def get_ColumnNumber(self):
        return self.__numberColumns

    def get_ActualImageNumber(self):
        return self.__actualImg

    def get_Arrays(self, number: int) -> np.ndarray:
        """
        Returns the images as numpy arrays
        :param number: the number of images that should be retrieved
        :return:
        """
        if self.__actualImg + number <= self.__numberImages[0]:
            self.__actualImg = self.__actualImg + number
            length = int(self.__numberRows[0] * self.__numberColumns[0] * number)
            arr = np.arange(length, dtype=np.uint8)
            for a in range(length - 1):
                arr[a] = np.uint8(struct.unpack(self.__type, self.f.read(1)))

            # nparr = np.array(arr,dtype=np.uint8)
            return np.reshape(arr, (number, self.__numberRows[0], self.__numberColumns[0]))
        else:
            print("Image number exceeds file size")
            return 0
