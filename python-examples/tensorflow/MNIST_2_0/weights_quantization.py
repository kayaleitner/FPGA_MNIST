import json
import os

import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

os.environ["KERAS_BACKEND"] = "plaidml.keras.backend"
import keras

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
Ws_float16 = map(lambda x: x.astype(np.float16), Ws)

# Map data
weight_data = [
    {"Layer": "Conv1", "Weights": Ws[0], "Bias": Ws[1]},
    {"Layer": "Conv2", "Weights": Ws[2], "Bias": Ws[3]},
    {"Layer": "Conv3", "Weights": Ws[4], "Bias": Ws[5]},
    {"Layer": "Fc1", "Weights": Ws[6], "Bias": Ws[7]},
    {"Layer": "Fc2", "Weights": Ws[8], "Bias": Ws[9]},
]

for i, weight in enumerate(Ws):
    vals = weight.flatten(order='C')
    np.savetxt(os.path.join("network_parameters", '{}.txt'.format(i)), vals, header=str(weight.shape))

# Check if the order is correct of the saved weights
weight_files = [os.path.join('network_parameters', f) for f in os.listdir('network_parameters') if f.endswith('.txt')]
weight_files.sort()
for i, weight_file in enumerate(weight_files):
    weight_loaded = np.loadtxt(weight_file)
    weight_orig = Ws[i]
    weight_loaded = np.reshape(weight_loaded, newshape=weight_orig.shape)  # obtain original shape
    if not np.allclose(weight_loaded, weight_orig):
        print("Error, values are not close at index ", i)

# Analyse Weights
figsize = (10, 8)
cols = 3
rows = len(Ws) // cols + 1


def trim_axs(axs, N):
    """little helper to massage the axs list to have correct length..."""
    axs = axs.flat
    for ax in axs[N:]:
        ax.remove()
    return axs[:N]


fig1, axs = plt.subplots(rows, cols, figsize=figsize, constrained_layout=True)
axs = trim_axs(axs, len(Ws))
i = 0
for ax, layer_weights in zip(axs, Ws):
    ax.set_title('Layer {} Weights ({})'.format(i, layer_weights.size))
    ax.set_xlim([-1, 1])
    ax.hist(layer_weights.flatten())
    i += 1

plt.show()
