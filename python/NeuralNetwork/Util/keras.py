import os

import numpy as np
import tensorflow.keras as keras


def open_keras_model(save_dir) -> keras.models.Model:
    """
    Reads a keras model form a save directory
    Args:
        save_dir:

    Returns:

    """
    if not os.path.exists(save_dir):
        raise RuntimeError("There is no trained model data!")

    # Reload the model from the 2 files we saved
    with open(os.path.join(save_dir, 'model_config.json')) as json_file:
        json_config = json_file.read()

    model = keras.models.model_from_json(json_config)
    model.load_weights(os.path.join(save_dir, 'weights.h5'))
    return model


def save_keras_model_weights(model: keras.models.Model, save_path='models'):
    """
    Saves the weights of keras models in text files.
    Args:
        model: The keras model with the weights
        save_path: the folder where the weights should be stored

    Returns:
        None
    """
    os.makedirs(save_path, exist_ok=True)
    Ws = model.get_weights()
    for i, weight in enumerate(Ws):
        vals = weight.flatten(order='C')
        np.savetxt(os.path.join(save_path, 'w{}.txt'.format(i)), vals, header=str(weight.shape))
