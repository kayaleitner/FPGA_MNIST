import os, wget
import numpy as np
import idx2numpy


class DataHandler:

    def __init__(self, rootPath):
        self.Downloaded = { "test_images": False,
                            "test_labels": False,
                            "train_images": False,
                            "train_labels": False}

        self.rootPath = rootPath
        self.Urls = {
            "test_images": "http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz",
            "test_labels": "http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz",
            "train_images": "http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz",
            "train_labels": "http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"}

        self.fileNames = {
            "test_images": r"t10k-images-idx3-ubyte.gz",
            "test_labels": r"t10k-labels-idx1-ubyte.gz",
            "train_images": r"train-images-idx3-ubyte.gz",
            "train_labels": r"train-labels-idx1-ubyte.gz"}

        for x in self.Urls:
            if os.path.exists(os.path.join(self.rootPath, self.fileNames[x] + ".gz")):
                self.Downloaded[x] = True
            elif os.path.exists(os.path.join(self.rootPath, self.fileNames[x])):
                self.Downloaded[x] = True
            else:
                self.download_files(x, self.rootPath)

        self.testImageData = self.extract_files_python(self.fileNames["test_images"])
        self.testLabelData = self.extract_files_python(self.fileNames["test_labels"])
        self.trainImageData = None
        self.trainLabelData = None

    def download_files(self, name, path):
        try:
            print("Downloading " + name + " from " + path)
            wget.download(self.Urls[name], path)
            self.Downloaded[name] = True
        except Exception as e:
            print("An error occurred downloading:" + name, e)

    def extract_files_python(self, file_path):
        import gzip
        file_path = file_path
        return idx2numpy.convert_from_file(gzip.open(file_path))

    def extract_files_linux(self, file_path):
        import subprocess
        proc = subprocess.Popen(["gunzip", "-c", file_path], stdout=subprocess.PIPE)
        return idx2numpy.convert_from_string(proc.stdout.read())

    def send_to_fpga(self, data):
        pass
