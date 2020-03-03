import numpy as np
import os
import torch
import keras
import shutil

# The line below is needed so that torch.load() works as expected
from train_torch import LeNetV2, ConvBN, LinearRelu, Flatten

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


def load_torch(filepath=TORCH_SAVE_FILE):
    from train_torch import get_lenet_model

    # Create a model instance, make sure that save data and source code is in sync
    # model = get_lenet_model()
    # model.load_state_dict(torch.load(TORCH_STATES_SAVE_FILE))

    # ToDo: Better way would be the line below but it doesnt work for me :(
    model = torch.load(filepath)

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


def _read_np_tensor(weight_file):
    with open(weight_file) as f:
        init_line = f.readline()

    # assume the first line is a comment
    assert init_line[0] == '#'
    p1 = init_line.find('(')
    p2 = init_line.find(')')
    dims = [int(ds) for ds in init_line[p1 + 1:p2].split(sep=',') if len(ds) > 0]

    return np.loadtxt(weight_file).reshape(dims)


def reorder(x):
    co, ci, h, w, = x.shape
    x_ = np.zeros(shape=(h, w, ci, co), dtype=x.dtype)

    for hx in range(h):
        for wx in range(w):
            for cix in range(ci):
                for cox in range(co):
                    x_[hx, wx, cix, cox] = x[cox, cix, hx, wx]
    return x_


def read_np_torch(ordering='BCHW', target_dtype=None):
    d = {
        'cn1.b': _read_np_tensor('np/t_0.0.bias.txt'),
        'cn1.k': _read_np_tensor('np/t_0.0.weight.txt'),
        'cn2.b': _read_np_tensor('np/t_3.0.bias.txt'),
        'cn2.k': _read_np_tensor('np/t_3.0.weight.txt'),
        'fc1.b': _read_np_tensor('np/t_7.0.bias.txt'),
        'fc1.w': _read_np_tensor('np/t_7.0.weight.txt'),
        'fc2.b': _read_np_tensor('np/t_9.0.bias.txt'),
        'fc2.w': _read_np_tensor('np/t_9.0.weight.txt'),
    }

    if ordering is 'BCHW':
        pass
    elif ordering is 'BHWC':
        k1 = np.moveaxis(d['cn1.k'], [0, 1], [3, 2])
        k2 = np.moveaxis(d['cn2.k'], [0, 1], [3, 2])

        # k1 = reorder(d['cn1.k'])
        # k2 = reorder(d['cn2.k'])

        assert k1[1, 2, 0, 4] == d['cn1.k'][4, 0, 1, 2]
        assert k2[1, 2, 3, 4] == d['cn2.k'][4, 3, 1, 2]

        d['cn1.k'] = k1
        d['cn2.k'] = k2
        d['fc1.w'] = np.moveaxis(d['fc1.w'], 0, 1)
        d['fc2.w'] = np.moveaxis(d['fc2.w'], 0, 1)



    else:
        raise NotImplementedError('Expected ordering to be "BCHW" or "BHWC" but is: {}'.format(ordering))

    if target_dtype is not None:
        d_old = d
        d = {}
        for key, values in d_old.items():
            d[key] = values.astype(target_dtype)
    return d


if __name__ == '__main__':
    extract()
