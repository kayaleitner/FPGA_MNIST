import os

import numpy as np
import torch
from tensorflow_core.python.keras.api._v2 import keras as keras
from torch.nn import functional as F


def indices(a, func):
    return [i for (i, val) in enumerate(a) if func(val)]


def ind2sub(ind, shape):
    d = np.cumprod(list(reversed(shape)))

    s = []
    for (i, shape_i) in enumerate(shape):
        d /= shape_i
        s.append(ind % d)

    return tuple(s)


def channels_last_2_channels_first(x: np.ndarray):
    """
    Converts a tensor with shape [B,H,W,C] to a tensor with shape [B,C,H,W]
    ToDo: Definitely needs a test
    """
    B, H, W, C = x.shape
    y = np.zeros(shape=(B, C, H, W))
    for b in range(B):
        for h in range(H):
            for w in range(W):
                for c in range(C):
                    # ToDo: Vectorize without changing behaviour or rewrite in C for performance
                    y[b, c, h, w] = x[b, h, w, c]


def channels_first_2_channels_last(x: np.ndarray):
    """
    Converts a tensor with shape [B,C,H,W] to a tensor with shape [B,H,W,C]
    ToDo: Definitely needs a test
    """
    B, C, H, W = x.shape
    y = np.zeros(shape=(B, H, W, C))
    for b in range(B):
        for h in range(H):
            for w in range(W):
                for c in range(C):
                    # ToDo: Vectorize without changing behaviour or rewrite in C for performance
                    y[b, h, w, c] = x[b, c, h, w]


MNIST_CLASSES = tuple(map(str, [i for i in range(10)]))
FASHION_MNIST_CLASSES = (
    'T-shirt/top', 'Trouser', 'Pullover', 'Dress', 'Coat', 'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle Boot')


def matplotlib_imshow(img, one_channel=False, denorm_func=None):
    """

    Args:
        img: Image to show
        one_channel:
        denorm_func: A function which denormalizes the image

    Returns:
        None
    """
    import matplotlib.pyplot as plt

    if one_channel:
        img = img.mean(dim=0)
    # ToDo: Somethings still wrong here
    if denorm_func is not None:
        # img = img / 2 + 0.5  # denormalize
        img = denorm_func(img)
    npimg = img.numpy()
    if one_channel:
        plt.imshow(npimg, cmap="Greys")
    else:
        plt.imshow(np.transpose(npimg, (1, 2, 0)))


def images_to_probs(net, images):
    """
    Generates predictions and corresponding probabilities from a trained
    network and a list of images
    """
    output = net(images)
    # convert output probabilities to predicted class
    preds_tensor = torch.argmax(output, dim=1)
    preds = np.squeeze(preds_tensor.numpy())
    return preds, [F.softmax(el, dim=0)[i].item() for i, el in zip(preds, output)]


def plot_classes_preds(net, images, labels, classes):
    """
    Generates matplotlib Figure using a trained network, along with images
    and labels from a batch, that shows the network's top prediction along
    with its probability, alongside the actual label, coloring this
    information based on whether the prediction was correct or not.
    Uses the "images_to_probs" function.
    """
    import matplotlib.pyplot as plt
    preds, probs = images_to_probs(net, images)
    # plot the images in the batch, along with predicted and true labels
    fig = plt.figure(figsize=(12, 48))
    for idx in range(4):
        ax = fig.add_subplot(1, 4, idx + 1, xticks=[], yticks=[])
        matplotlib_imshow(images[idx], one_channel=True)
        ax.set_title("{0}, {1:.1f}%\n(label: {2})".format(
            classes[preds[idx]],
            probs[idx] * 100.0,
            classes[labels[idx]]),
            color=("green" if preds[idx] == labels[idx].item() else "red"))
    return fig


def select_n_random(data, labels, n=100):
    """
    Selects n random datapoints and their corresponding labels from a dataset
    """
    assert len(data) == len(labels)

    perm = torch.randperm(len(data))
    return data[perm][:n], labels[perm][:n]


def trim_axs(axs, N):
    """little helper to massage the axs list to have correct length..."""
    axs = axs.flat
    for ax in axs[N:]:
        ax.remove()
    return axs[:N]


def plot_feature_maps(kernels, **kwargs):
    """

    Args:
        kernels: A kernel numpy array with dimensions [HEIGHT, WIDTH, CHANNELS_IN, CHANNELS-OUT]
        **kwargs:

    Returns:

    """
    import matplotlib.pyplot as plt

    # Shape is HWCC

    rows = (len(weights) // cols) + 1

    fig1, axs = plt.subplots(rows, cols, figsize=figsize, constrained_layout=True)
    axs = trim_axs(axs, len(weights))
    i = 0
    for ax, layer_weights in zip(axs, weights):
        ax.hist(layer_weights.flatten(), **kwargs)
        i += 1

    return fig1, axs


def plot_network_parameter_histogram(weights, names=None, cols=3, figsize=(10, 8), xlim=None, **kwargs):
    """
    Plots a histogram distribution plot of the weights
    Args:
        weights: iterable or dictionary of layer weights
        names: names that should be used for the titles, if the `weights` is not a dictionary
        cols: number of columns
        figsize: the size of the figure
        xlim: limits for the x-axis
        kwargs: additional kwargs that are passed to `matplotlib`

    Returns: The figure and the axes

    """
    import matplotlib.pyplot as plt

    if names is None and isinstance(weights, dict):
        names = [str(k) for k in weights.keys()]
        weights = weights.values()
    elif names is None:
        names = ["W_{}: {}".format(i, w.shape) for i, w in enumerate(weights)]
    else:
        assert len(names) == len(weights)

    rows = (len(weights) // cols) + 1

    fig1, axs = plt.subplots(rows, cols, figsize=figsize, constrained_layout=True)
    axs = trim_axs(axs, len(weights))
    i = 0
    for ax, layer_weights in zip(axs, weights):
        ax.set_title(names[i])
        if xlim is not None:
            ax.set_xlim(xlim)
        ax.hist(layer_weights.flatten(), **kwargs)
        i += 1

    return fig1, axs


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