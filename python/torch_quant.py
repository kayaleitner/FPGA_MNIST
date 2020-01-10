"""
This scripts shall observe the influence of accuracy on different quantization strategies
"""
import os
import numpy as np

import NeuralNetwork.NN as NN
import NeuralNetwork.Ext as Ext
import NeuralNetwork.Reader as Reader

import torch
import torch.nn.modules as modules
import tensorflow as tf
import tensorflow.keras as keras

"""
Prepartions: MNIST, loadweights, etc
"""

# Prepare Reader
data_loader = Reader.MnistDataDownloader("test/MNIST/")
path_img, path_lbl = data_loader.get_path(Reader.DataSetType.TRAIN)
reader = Reader.MnistDataReader(path_img, path_lbl)

# Load Weights
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

nn_lenet = NN.LeNet.load_from_files(save_dir=save_dir)

