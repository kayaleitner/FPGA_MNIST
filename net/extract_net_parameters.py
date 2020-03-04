import numpy as np
import os
import shutil

# The line below is needed so that torch.load() works as expected

# Chose if you want to use the training parameters from Keras or Torch
from train_keras import load_keras
from train_torch import save_torch_model_weights, load_torch

EXTRACT_FROM_KERAS = True
EXTRACT_FROM_TROCH = True

EXPORT_DIR = 'np'
SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))


def extract(cleanup=True, extract_keras=EXTRACT_FROM_KERAS, extract_torch=EXTRACT_FROM_TROCH):
    # Clean up and create dirs
    if cleanup:
        shutil.rmtree(EXPORT_DIR)
        os.makedirs(EXPORT_DIR, exist_ok=True)

    if extract_keras:
        kmodel = load_keras()
        for l_ix, layer in enumerate(kmodel.layers):
            # print(layer.get_config(), layer.get_weights())
            for w_ix, weight in enumerate(layer.get_weights()):
                # T
                vals = weight.flatten(order='C')  # Save to np format
                np.savetxt(os.path.join(EXPORT_DIR, 'k_{}_{}_{}.txt'.format(l_ix, layer.name, w_ix)), vals,
                           header=str(weight.shape))

    if extract_torch:
        tmodel = load_torch()
        save_torch_model_weights(tmodel)


if __name__ == '__main__':
    extract()
