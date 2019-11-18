import numpy as np


def mean_squared_error(predictions: np.ndarray, labels: np.ndarray) -> np.ndarray:
    """
    Calculates the mean squared error
    :param predictions: Array of predictions with dimensions [batch out_size]
    :param labels: Array of labels with dimensions [batch out_size]
    :return:
    """
    return np.sum(np.sum((predictions - labels) ** 2))


def cross_entropy(predictions, labels):
    """
    Calculates the cross entropy cost
    :param predictions: Array of predictions with dimensions [batch out_size]
    :param labels: Array of labels with dimensions [batch out_size]
    :return:
    """
    return np.sum(np.sum(labels * np.log(predictions) + (1 - labels) * np.log(1 - predictions)))
