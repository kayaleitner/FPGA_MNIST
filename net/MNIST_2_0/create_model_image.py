import os
import tensorflow as tf
import numpy as np
from tensorflow import keras
import json
import matplotlib.pyplot as plt


checkpoint_path = "training_1/cp.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)


if not os.path.exists(checkpoint_dir):
    raise RuntimeError("There is no trained model data!")

# Reload the model from the 2 files we saved
with open('training_1/model_config.json') as json_file:
    json_config = json_file.read()

model = keras.models.model_from_json(json_config)
model.load_weights('training_1/weights.h5')

# Print a summary
model.summary()

# Make sure all dependencies, e.g. graphviz are installed
keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)
