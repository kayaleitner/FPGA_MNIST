"""
This scripts shall observe the influence of accuracy on different quantization strategies
"""
from __future__ import absolute_import, print_function, division

import os

import numpy as np
import tensorflow.keras as keras
from tensorflow.keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape, Dropout
from tensorflow.keras.models import Sequential
from matplotlib import pyplot as plt

import NeuralNetwork.nn as nn
import NeuralNetwork.Reader as Reader
import NeuralNetwork.nn.util
import NeuralNetwork.nn.quant as nnquant
from NeuralNetwork.nn.util import plot_network_parameter_histogram

"""
Preparations: MNIST, loadweights, etc
"""

BATCH_SIZE = 1
FRACTION_BITS = 8
RESOLUTION = 1 / (2 ** FRACTION_BITS)

mnist_data_dir = 'test/MNIST'
nn_save_dir = 'test/lenet'
# keras_save_dir = 'test/training_1'
keras_save_dir = '../net/keras'

INT_MAX_VAL = 2 ** 16

# Train Keras (optional if data is already stored)
# m = train_keras(save_dir=keras_save_dir)
# NeuralNetwork.Util.save_keras_model_weights(m, save_path=nn_save_dir)

# Prepare Reader
data_loader = Reader.MnistDataDownloader(folder_path=mnist_data_dir)
path_img, path_lbl = data_loader.get_path(dataset_type=Reader.DataSetType.TRAIN)
reader = Reader.MnistDataReader(image_filename=path_img, label_filename=path_lbl)

# Load models
keras_lenet = nn.util.open_keras_model(save_dir=keras_save_dir)
nn_lenet_f64 = nn.Network.LeNet.load_from_files(save_dir=nn_save_dir)


for ix_layer, layer in enumerate(nn_lenet_f64.layers):
    if isinstance(layer, NeuralNetwork.nn.Layer.Conv2dLayer):
        kernel = layer.kernel
        scales = np.max(np.abs(kernel), axis=(1, 2, 3))
        plot_network_parameter_histogram([kernel.flatten()], cols=1)
        plt.savefig(f'{ix_layer}_weights_conv_hist_layer.png')

        bias = layer.b
        scales = np.max(np.abs(kernel), axis=(1, 2, 3))
        plot_network_parameter_histogram([bias.flatten()], cols=1)
        plt.savefig(f'{ix_layer}_weights_conv_bias_hist_layer.png')

    elif isinstance(layer, NeuralNetwork.nn.Layer.FullyConnectedLayer):
        W = layer.W
        scales = np.max(np.abs(W), axis=(1))
        plot_network_parameter_histogram([W.flatten()], cols=1)
        plt.savefig(f'{ix_layer}_weights_fc_hist_layer.png')


        bias = layer.b
        scales = np.max(np.abs(kernel), axis=(1, 2, 3))
        plot_network_parameter_histogram([bias.flatten()], cols=1)
        plt.savefig(f'{ix_layer}_weights_fc_bias_hist_layer.png')
        pass
    else:
        continue


for layer in nn_lenet_f64.layers:
    if isinstance(layer, NeuralNetwork.nn.Layer.Conv2dLayer):
        kernel = layer.kernel
        scales = np.max(np.abs(kernel), axis=(1, 2, 3))
        pass
    elif isinstance(layer, NeuralNetwork.nn.Layer.FullyConnectedLayer):

        pass
    else:
        continue

nn_lenet_f32 = nn_lenet_f64.cast(new_dtype=np.float32)
nn_lenet_f16 = nn_lenet_f64.cast(new_dtype=np.float16)

nn_lenet_i32 = nn_lenet_f64.quantize_network(new_dtype=np.int32, min_value=-INT_MAX_VAL, max_value=INT_MAX_VAL)
nn_lenet_i16 = nn_lenet_f64.quantize_network(new_dtype=np.int16, min_value=-INT_MAX_VAL, max_value=INT_MAX_VAL)
nn_lenet_i8 = nn_lenet_f64.quantize_network(new_dtype=np.int8, min_value=-INT_MAX_VAL, max_value=INT_MAX_VAL)

# Compare results
(lbls, imgs) = next(reader.get_next(batch_size=BATCH_SIZE))
imgs_float = imgs.astype(dtype=np.float) / 256
lbls_keras = keras_lenet(inputs=imgs_float)

imgs_i8 = nnquant.to_fpi_object(imgs_float, target_type=np.int8, fraction_bits=7)
imgs_i16 = nnquant.to_fpi_object(imgs_float, target_type=np.int16, fraction_bits=15)
imgs_i32 = nnquant.to_fpi_object(imgs_float, target_type=np.int32, fraction_bits=31)

lbls_keras = lbls_keras.numpy().argmax(axis=1)

# lbls_nn_f64 = nn_lenet_f64.forward(x=imgs_float).argmax(axis=1)
lbls_nn_f64, nnf64_activations = nn_lenet_f64.forward_intermediate(imgs_float)

# Plot Network Weights
#
plot_network_parameter_histogram(weights=nn_lenet_f64.get_network_weights(), bins=32)

plot_network_parameter_histogram(weights=nn_lenet_i32.get_network_weights(), bins=32)

# Plot Network Activations
plot_network_parameter_histogram(weights=nnf64_activations, bins=32)

lbls_nn_f64 = lbls_nn_f64.argmax(axis=1)
lbls_nn_f32 = nn_lenet_f32.forward(x=imgs_float).argmax(axis=1)
lbls_nn_f16 = nn_lenet_f16.forward(x=imgs_float).argmax(axis=1)

lbls_nn_i8 = nn_lenet_i8.forward(x=imgs_i8)
lbls_nn_i16 = nn_lenet_i16.forward(x=imgs_i16)
lbls_nn_i32, nn32_activations = nn_lenet_i32.forward_intermediate(x=imgs_i32)

i_activation = 0
for iact, fact in zip(nn32_activations, nnf64_activations):
    # The back to float converted integer value
    dq_iact = nnquant.dequantize_vector(iact, min_value=-INT_MAX_VAL, max_value=INT_MAX_VAL)
    plot_network_parameter_histogram([dq_iact, fact])
    plt.savefig(f'activation_hist_layer{i_activation}.png')
    i_activation += 1

lbls_nn_i8 = lbls_nn_i8.argmax(axis=1)
lbls_nn_i16 = lbls_nn_i16.argmax(axis=1)
lbls_nn_i32 = lbls_nn_i32.argmax(axis=1)

print("Keras | F64 | F32 | F16 | I32 | I16 | I8 ")
print("-----------------------------------------")
for i in range(lbls_nn_i8.shape[0]):
    print(" {}     {}   {}   {}  {}   {}   {} ".format(lbls_keras[i], lbls_nn_f64[i], lbls_nn_f32[i],
                                                       lbls_nn_f16[i],
                                                       lbls_nn_i32[i], lbls_nn_i16[i], lbls_nn_i8[i]))


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
    print("Hello")
