import os
import unittest

import matplotlib.pyplot as plt
import numpy as np
from tensorflow import keras

from .NeuralNetwork.Activations import SoftmaxLayer, ReluActivationLayer
from .NeuralNetwork.ConvLayer import ConvLayer, test_kernel_gauss, MaxPoolLayer
from .NeuralNetwork.FullyConnected import FullyConnectedLayer
from .NeuralNetwork.Network import Network
from .NeuralNetwork.Util import ReshapeLayer
from .Reader import MnistDataReader, MnistDataDownloader, DataSetType


class MnistConvTestCase(unittest.TestCase):

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

    def test_tensorflow_parameter(self):
        r1 = ReshapeLayer(newshape=[-1, 28, 28, 1])
        cn1 = ConvLayer(in_channels=1, out_channels=16, kernel_size=3)  # [? 28 28 16]
        relu1 = ReluActivationLayer()
        mp1 = MaxPoolLayer(size=2)  # [? 14 14 16]
        cn2 = ConvLayer(in_channels=16, out_channels=32, kernel_size=3)  # [? 14 14 32]
        relu2 = ReluActivationLayer()
        mp2 = MaxPoolLayer(size=2)  # [?  7  7 32]
        # ConvLayer(in_channels=32, out_channels=64, kernel_size=3),  # [?  7  7 64]
        # MaxPoolLayer(size=2),
        r2 = ReshapeLayer(newshape=[-1, 32 * 7 * 7])
        fc1 = FullyConnectedLayer(input_size=32 * 7 * 7, output_size=64)
        relu3 = ReluActivationLayer()
        fc2 = FullyConnectedLayer(input_size=64, output_size=10)
        sm1 = SoftmaxLayer()

        checkpoint_path = "python/training_1/cp.ckpt"
        checkpoint_dir = os.path.abspath(os.path.dirname(checkpoint_path))
        os.path.join(checkpoint_dir, "model_config.json")
        if not os.path.exists(checkpoint_dir):
            raise RuntimeError("There is no trained model data!")

        # Reload the model from the 2 files we saved
        with open(os.path.join(checkpoint_dir, "model_config.json")) as json_file:
            json_config = json_file.read()

        model = keras.models.model_from_json(json_config)
        model.load_weights(os.path.join(checkpoint_dir, "weights.h5"))

        # Print a summary
        Ws = model.get_weights()

        self.assertEqual(cn1.kernel.shape, Ws[0].shape)
        self.assertEqual(cn1.b.shape, Ws[1].shape)
        self.assertEqual(cn2.kernel.shape, Ws[2].shape)
        self.assertEqual(cn2.b.shape, Ws[3].shape)
        self.assertEqual(fc1.W.shape, Ws[4].shape)
        self.assertEqual(fc1.b.shape, Ws[5].shape)
        self.assertEqual(fc2.W.shape, Ws[6].shape)
        self.assertEqual(fc2.b.shape, Ws[7].shape)

        # Assign values
        cn1.kernel = Ws[0]
        cn1.b = Ws[1]
        cn2.kernel = Ws[2]
        cn2.b = Ws[3]
        fc1.W = Ws[4]
        fc1.b = Ws[5]
        fc2.W = Ws[6]
        fc2.b = Ws[7]

        layers = [r1, cn1, relu1, mp1, cn2, relu2, mp2, r2, fc1, relu3, fc2, sm1]
        n = Network(layers)

        loader = MnistDataDownloader("MNIST/")
        path_img, path_lbl = loader.get_path(DataSetType.TRAIN)
        reader = MnistDataReader(path_img, path_lbl)

        for lbls, imgs in reader.get_next(10):
            imgs = imgs.astype(np.float) / 255.0
            imgs = np.reshape(imgs, newshape=[-1, 28, 28, 1])
            y, zs = n.forward_intermediate(imgs)
            lbls_pred = y.argmax(axis=1)
            print(lbls.reshape(-1))
            print(lbls_pred.reshape(-1))

            break
            # img_out = np.reshape(imgs, newshape=[1, -1, 28, 1])
            # img_out = np.squeeze(img_out)
            # plt.imshow(img_out, cmap='gray', vmin=0.0, vmax=1.0)
            # plt.show()


