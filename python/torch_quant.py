"""
This scripts shall observe the influence of accuracy on different quantization strategies
"""
import os
import numpy as np

import NeuralNetwork.Util
import NeuralNetwork.NN as NN
import NeuralNetwork.Ext as Ext
import NeuralNetwork.Reader as Reader

import torch
import torch.nn.modules as modules

import tensorflow as tf
import tensorflow.keras as keras
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape, Dropout


def train_keras(save_dir, IMG_HEIGHT=28, IMG_WIDTH=28):
    checkpoint_filepath = os.path.join(save_dir, "cp.ckpt")
    weight_filepath = os.path.join(save_dir, 'weights.h5')
    config_filepath = os.path.join(save_dir, 'model_config.json')

    (x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
    x_train, x_test = x_train / 255.0, x_test / 255.0

    model = Sequential([
        Reshape((IMG_HEIGHT, IMG_WIDTH, 1), input_shape=(IMG_HEIGHT, IMG_WIDTH)),
        Conv2D(16, 3, padding='same', activation='relu', use_bias=True),  # 3x3x4 filter
        Dropout(0.2),
        MaxPooling2D(),
        Conv2D(32, 3, padding='same', activation='relu', use_bias=True),  # 3x3x8 filter
        Dropout(0.2),
        MaxPooling2D(),
        Flatten(),
        Dense(32, activation='relu'),
        Dropout(0.2),
        Dense(10, activation='softmax')
    ])

    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])

    # Display the model's architecture
    model.summary()

    # Create a callback that saves the model's weights
    cp_callback = keras.callbacks.ModelCheckpoint(filepath=checkpoint_filepath,
                                                  save_weights_only=True,
                                                  verbose=1)

    # For higher GPU Utilization it is useful to increase batch_size but this can slow down training
    history = model.fit(x_train, y_train, epochs=10, batch_size=200, callbacks=[cp_callback])

    # Save JSON config to disk
    json_config = model.to_json()
    with open(config_filepath, 'w') as json_file:
        json_file.write(json_config)

    model.save_weights(weight_filepath)
    model.evaluate(x_test, y_test, verbose=2)

    return model


if __name__ == '__main__':
    """
    Preparations: MNIST, loadweights, etc
    """

    mnist_data_dir = 'test/MNIST'
    nn_save_dir = 'test/lenet'
    keras_save_dir = 'test/training_1'

    # Train Keras (optional if data is already stored)
    # m = train_keras(save_dir=keras_save_dir)
    # NeuralNetwork.Util.save_keras_model_weights(m, save_path=nn_save_dir)

    # Prepare Reader
    data_loader = Reader.MnistDataDownloader(folder_path=mnist_data_dir)
    path_img, path_lbl = data_loader.get_path(dataset_type=Reader.DataSetType.TRAIN)
    reader = Reader.MnistDataReader(image_filename=path_img, label_filename=path_lbl)

    # Load models
    keras_lenet = NeuralNetwork.Util.open_keras_model(save_dir=keras_save_dir)
    nn_lenet = NN.Network.LeNet.load_from_files(save_dir=nn_save_dir)

    # Compare results
    (lbls, imgs) = next(reader.get_next(batch_size=10))
    imgs_float = imgs.astype(dtype=np.float) / 256
    lbls_keras = keras_lenet(inputs=imgs_float)
    lbls_nn = nn_lenet.forward(x=imgs_float)

    # Cast to numpy
    lbls_keras = lbls_keras.argmax(axis=1)
    lbls_nn = lbls_nn.argmax(axis=1)

    print("Keras:  ", lbls_keras)
    print("NN:     ", lbls_nn)

    assert np.all(lbls_nn, lbls_keras)
