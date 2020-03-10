import os
import unittest

import matplotlib.pyplot as plt
import numpy as np
import tensorflow.keras.backend as K
from tensorflow import keras

import EggNet
from EggNet.Reader import MnistDataDownloader, MnistDataReader, DataSetType


class MnistConvTestCase(unittest.TestCase):

    def test_blur(self):
        k = EggNet.make_gauss_kernel()
        cl = EggNet.Conv2dLayer(in_channels=1, out_channels=1, kernel_size=5)
        loader = MnistDataDownloader("../../test/MNIST/")
        path_img, path_lbl = loader.get_path(DataSetType.TRAIN)

        reader = MnistDataReader(path_img, path_lbl)
        for lbl, img in reader.get_next(4):
            img = img.astype(np.float) / 255.0
            img = np.reshape(img, newshape=[-1, 28, 28, 1])
            k = np.reshape(k, newshape=[k.shape[0], k.shape[1], 1, 1])
            cl.kernel = k
            img_out = cl(img)

            # Check the dimensions
            self.assertEqual(img_out.shape, (4, 28, 28, 1))

            # Uncomment to see the image
            img_out = np.reshape(img_out, newshape=[1, 4 * 28, 28, 1])
            img_out = np.squeeze(img_out)
            plt.imshow(img_out, cmap='gray', vmin=0.0, vmax=1.0)
            plt.show()
            break

    def test_tensorflow_parameter_0(self):
        r1 = EggNet.ReshapeLayer(newshape=[-1, 28, 28, 1])
        cn1 = EggNet.Conv2dLayer(in_channels=1, out_channels=16, kernel_size=3, activation='relu')  # [? 28 28 16]

        checkpoint_path = "test/training_1/cp.ckpt"
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

        # See Keras Documentation
        # https://www.tensorflow.org/api_docs/python/tf/keras/layers/Conv2D
        #
        # Default ordering of weights for Conv: (batch, height, width, channels)
        # Default ordering of weights for Dense
        self.assertEqual(cn1.kernel.shape, Ws[0].shape)
        self.assertEqual(cn1.b.shape, Ws[1].shape)

        # Assign values
        cn1.kernel = Ws[0]
        cn1.b = Ws[1]
        layers = [r1, cn1, ]
        interesting_layers = [1]  # don't care about reshape layers
        n = EggNet.Network(layers)

        loader = MnistDataDownloader("../../test/MNIST/")
        path_img, path_lbl = loader.get_path(DataSetType.TRAIN)
        reader = MnistDataReader(path_img, path_lbl)

        for lbls, imgs in reader.get_next(10):
            imgs = imgs.astype(np.float) / 255.0
            imgs_r = np.reshape(imgs, newshape=[-1, 28, 28, 1])

            # Check the tensorflow model
            y_keras = model.predict(imgs)

            # Keras Model Debug
            inp = model.input  # input placeholder
            outputs = [layer.output for layer in model.layers]  # all layer outputs
            outputs = [outputs[i] for i in (1, 2, 3, 4, 6, 8)]  # remove dropout, reshape
            functors = [K.function([inp], [out]) for out in outputs]  # evaluation functions
            layer_outs = [func([imgs, 1.]) for func in functors]
            # print(layer_outs)

            # Check the results of the own made NN
            y, zs = n.forward_intermediate(imgs_r)
            zs = [zs[i] for i in interesting_layers]  # remove reshape layers
            eps = 0.1
            index = 0
            for l_keras_out, l_out in zip(layer_outs, zs):
                err = np.abs((l_keras_out - l_out).flatten())
                # print(l_keras_out - l_out)

                # err_image = 1.0 * (np.abs(l_keras_out - l_out) > eps)
                # # err_image = np.reshape(err_image[], newshape=(1, -1, 28, 1))
                # err_image = np.squeeze(err_image[0, :, :, 0])
                # plt.imshow(err_image, vmin=0.0, vmax=1.0, cmap='gray')
                # plt.show()

                right_indices = indices(err < eps, lambda b: b)
                false_indices = indices(err > eps, lambda b: b)
                wrong_values = err[false_indices]
                # print(wrong_values)

                if not np.all(right_indices):
                    print("error in layer ", index)
                index += 1

            lbls_pred_keras = y_keras.argmax(axis=1)
            lbls_pred = y.argmax(axis=1)
            print("Original:  ", lbls.reshape(-1))
            print("Keras:     ", lbls_pred_keras.reshape(-1))
            print("Our Model: ", lbls_pred.reshape(-1))

            break
            # img_out = np.reshape(imgs, newshape=[1, -1, 28, 1])
            # img_out = np.squeeze(img_out)
            # plt.imshow(img_out, cmap='gray', vmin=0.0, vmax=1.0)
            # plt.show()

    def test_tensorflow_parameter(self):
        r1 = EggNet.ReshapeLayer(newshape=[-1, 28, 28, 1])
        cn1 = EggNet.Conv2dLayer(in_channels=1, out_channels=16, kernel_size=3, activation='relu')  # [? 28 28 16]
        mp1 = EggNet.MaxPool2dLayer(size=2)  # [? 14 14 16]
        cn2 = EggNet.Conv2dLayer(in_channels=16, out_channels=32, kernel_size=3, activation='relu')  # [? 14 14 32]
        mp2 = EggNet.MaxPool2dLayer(size=2)  # [?  7  7 32]
        r2 = EggNet.ReshapeLayer(newshape=[-1, 32 * 7 * 7])
        fc1 = EggNet.FullyConnectedLayer(input_size=32 * 7 * 7, output_size=64, activation='relu')
        fc2 = EggNet.FullyConnectedLayer(input_size=64, output_size=10, activation='softmax')

        checkpoint_path = "test/training_1/cp.ckpt"
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

        # K0 = Ws[0]
        # plt.imshow(K0[:,:,1,1], vmin=0.0, vmax=1.0, cmap='gray')
        # plt.show()

        # See Keras Documentation
        # https://www.tensorflow.org/api_docs/python/tf/keras/layers/Conv2D
        #
        # Default ordering of weights for Conv: (batch, height, width, channels)
        # Default ordering of weights for Dense
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

        layers = [r1, cn1, mp1, cn2, mp2, r2, fc1, fc2]
        interesting_layers = [1, 2, 3, 4, 6, 7]  # don't care about reshape layers

        net = EggNet.Network(layers)

        loader = MnistDataDownloader("../../test/MNIST/")
        path_img, path_lbl = loader.get_path(DataSetType.TRAIN)
        reader = MnistDataReader(path_img, path_lbl)

        for lbls, imgs in reader.get_next(20):
            imgs = imgs.astype(np.float) / 255.0
            imgs_r = np.reshape(imgs, newshape=[-1, 28, 28, 1])

            # Check the tensorflow model
            y_keras = model.predict(imgs)

            # Keras Model Debug
            inp = model.input  # input placeholder
            outputs = [layer.output for layer in model.layers]  # all layer outputs
            outputs = [outputs[i] for i in (1, 2, 3, 4, 6, 8)]  # remove dropout, reshape
            functors = [K.function([inp], [out]) for out in outputs]  # evaluation functions
            layer_outs = [func([imgs, 1.]) for func in functors]
            # print(layer_outs)

            # Check the results of the own made NN
            y, zs = net.forward_intermediate(imgs_r)
            zs = [zs[i] for i in interesting_layers]  # remove reshape layers
            eps = 0.1
            index = 0
            for l_keras_out, l_out in zip(layer_outs, zs):

                l_keras_out = l_keras_out[0]  # why ever
                err = np.abs((l_keras_out - l_out))
                # err_subs = ind2sub(indices(err.flatten(), lambda x: x > 1), l_out.shape)
                # self.assertTrue(np.allclose(l_out, l_keras_out))

                #print(l_keras_out - l_out)

                # img_keras = np.squeeze()
                # err_image = 1.0 * (np.abs(l_keras_out - l_out) > eps)

                # Test: Shift l_out

                # l_out[:, 0:-1, 0:-1, :] = l_out[:, 1:, 1:, :]

                # err_image = l_keras_out - l_out
                # # err_image = np.reshape(err_image, newshape=(1, 28, 28, 1))
                # # err_image = np.squeeze(err_image[0, :, :, 0])
                # err_image = np.concatenate([np.squeeze(err_image[0, :, :, i]) for i in range(4)], axis=1)
                # img_keras = np.concatenate([np.squeeze(l_keras_out[0, :, :, i]) for i in range(4)], axis=1)
                # img_nn = np.concatenate([np.squeeze(l_out[0, :, :, i]) for i in range(4)], axis=1)
                # img = np.concatenate([img_nn, img_keras, err_image], axis=0)
                #
                # fig, ax = plt.subplots()
                # _im = ax.imshow(img, cmap='gray')
                # ax.set_title('Computation Layer {}'.format(index))
                # ax.set_yticks([14, 14 + 28, 14 + 2 * 28])
                # ax.set_yticklabels(['Our NN', 'Keras', 'Difference'])
                # fig.colorbar(_im)
                # plt.show()

                #right_indices = indices(err < eps, lambda b: b)
                #false_indices = indices(err > eps, lambda b: b)
                #wrong_values = err[false_indices]
                #print(wrong_values)

                if not np.allclose(l_out, l_keras_out, atol=0.0001):
                    print("error in layer ", index)
                    breakpoint()
                index += 1

            lbls_pred_keras = y_keras.argmax(axis=1)
            lbls_pred = y.argmax(axis=1)
            print("Original:  ", lbls.reshape(-1))
            print("Keras:     ", lbls_pred_keras.reshape(-1))
            print("Our Model: ", lbls_pred.reshape(-1))

            break
            # img_out = np.reshape(imgs, newshape=[1, -1, 28, 1])
            # img_out = np.squeeze(img_out)
            # plt.imshow(img_out, cmap='gray', vmin=0.0, vmax=1.0)
            # plt.show()
