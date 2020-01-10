import matplotlib.pyplot as plt
import numpy as np

import torch
import torch.nn.functional as F

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


# helper functions

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


# helper function
def select_n_random(data, labels, n=100):
    """
    Selects n random datapoints and their corresponding labels from a dataset
    """
    assert len(data) == len(labels)

    perm = torch.randperm(len(data))
    return data[perm][:n], labels[perm][:n]


