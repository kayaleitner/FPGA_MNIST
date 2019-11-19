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

# Extract the weights
Ws = model.get_weights()
Ws_float16 = map(lambda x: x.as_type(np.float16), Ws)

# Map data
weight_data = [
    {"Layer": "Conv1", "Weights": Ws[0], "Bias": Ws[1]},
    {"Layer": "Conv2", "Weights": Ws[2], "Bias": Ws[3]},
    {"Layer": "Conv3", "Weights": Ws[4], "Bias": Ws[5]},
    {"Layer": "Fc1", "Weights": Ws[6], "Bias": Ws[7]},
    {"Layer": "Fc2", "Weights": Ws[8], "Bias": Ws[9]},
]


with open("weight_data.json", "wb") as f:
    json_data = json.dumps(weight_data)
    f.write(json_data)

