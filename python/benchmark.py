from __future__ import print_function, division, absolute_import

import numpy as np
import NeuralNetwork.nn as nn
import NeuralNetwork.Reader as reader

if __name__ == '__main__':
    nn_save_dir = 'test/lenet'
    mnist_data_dir = 'test/MNIST'
    keras_save_dir = '../net/keras'
    BATCH_SIZE = 1000

    # Prepare Reader
    data_loader = reader.MnistDataDownloader(folder_path=mnist_data_dir)
    path_img, path_lbl = data_loader.get_path(dataset_type=reader.DataSetType.TRAIN)
    reader = reader.MnistDataReader(image_filename=path_img, label_filename=path_lbl)

    LeNet = nn.Network.LeNet.load_from_files(save_dir=nn_save_dir)
    keras_lenet = NeuralNetwork.util.open_keras_model(save_dir=keras_save_dir)

    n_correct_samples = 0
    n_correct_samples_keras = 0
    n_samples = 0
    for (lbls, imgs) in reader.get_iterator(batchsize=BATCH_SIZE):
        imgs_float = imgs.astype(dtype=np.float) / 255.0

        lbls_keras = keras_lenet(inputs=imgs_float)
        lbls_keras = lbls_keras.numpy().argmax(-1)

        lbls_pred = LeNet.forward(imgs_float)
        lbls_pred = lbls_pred.argmax(-1)

        if not np.all(lbls_keras == lbls_pred):
            false_indices = NeuralNetwork.util.indices(lbls_pred == lbls_keras, lambda x: x == False)
            print("{:3} Errors at indices: {}".format(len(false_indices), false_indices))

        n_samples += len(lbls)
        n_correct_samples += np.sum(lbls.flatten() == lbls_pred.flatten())
        n_correct_samples_keras += np.sum(lbls_keras.flatten() == lbls_pred.flatten())

    accuracy = 100 * n_correct_samples / n_samples
    accuracy_keras = 100 * n_correct_samples_keras / n_samples

    print("EggNet Total Accuracy: {}".format(accuracy))
    print("Keras  Total Accuracy: {}".format(accuracy_keras))
