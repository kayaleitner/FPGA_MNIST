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

"""
Preparations: MNIST, loadweights, etc
"""

mnist_data_dir = 'test/MNIST'
nn_save_dir = 'test/lenet'
keras_save_dir = 'test/training_1'

# Prepare Reader
data_loader = Reader.MnistDataDownloader(folder_path=mnist_data_dir)
path_img, path_lbl = data_loader.get_path(dataset_type=Reader.DataSetType.TRAIN)
reader = Reader.MnistDataReader(image_filename=path_img, label_filename=path_lbl)

# Load models
keras_lenet = NeuralNetwork.Util.open_keras_model(save_dir=keras_save_dir)
nn_lenet = NN.LeNet.load_from_files(save_dir=nn_save_dir)

# Compare results
keras_lenet()