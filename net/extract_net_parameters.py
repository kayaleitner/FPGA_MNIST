import numpy as np
import os
import torch
import keras
import shutil

# Chose if you want to use the training parameters from Keras or Torch
EXTRACT_FROM_KERAS = True
EXTRACT_FROM_TROCH = True

EXPORT_DIR = 'np'

SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))

KERAS_SAVE_DIR = 'keras'
KERAS_CONFIG_FILE = os.path.join(KERAS_SAVE_DIR, 'model_config.json')
KERAS_WEIGHTS_FILE = os.path.join(KERAS_SAVE_DIR, 'weights.h5')

TORCH_SAVE_DIR = os.path.join(SCRIPT_PATH, 'torch')
TORCH_SAVE_FILE = os.path.join(TORCH_SAVE_DIR, 'LeNet.pth')
TORCH_STATES_SAVE_FILE = os.path.join(TORCH_SAVE_DIR, 'LeNetStates.pth')


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
        tmodel.eval()  # Put in eval mode
        for key, weights in tmodel.state_dict().items():
            weights = weights.numpy()
            vals = weights.flatten(order='C')
            np.savetxt(os.path.join(EXPORT_DIR, 't_{}.txt'.format(key)), vals,
                       header=str(weights.shape))


def load_torch():
    from train_torch import get_lenet_model
    # Create a model instance, make sure that save data and source code is in sync
    model = get_lenet_model()
    model.load_state_dict(torch.load(TORCH_STATES_SAVE_FILE))

    # ToDo: Better way would be the line below but it doesnt work for me :(
    # model = torch.load(TORCH_SAVE_FILE)

    return model


def load_keras() -> keras.Model:
    if not os.path.exists(KERAS_CONFIG_FILE) or not os.path.exists(KERAS_WEIGHTS_FILE):
        raise RuntimeError("There is no trained model data! (or the model might have the wrong filename?)")

    # Reload the model from the 2 files we saved
    with open(KERAS_CONFIG_FILE) as json_file:
        json_config = json_file.read()

    model = keras.models.model_from_json(json_config)
    model.load_weights(KERAS_WEIGHTS_FILE)
    return model


if __name__ == '__main__':
    extract()
