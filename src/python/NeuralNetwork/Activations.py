import numpy as np


def relu(x: np.ndarray) -> np.ndarray:
    """
    Applies the Relu activation function to the input
    :param x: values
    :return:
    """
    return np.maximum(x, 0)


def drelu(x: np.ndarray) -> np.ndarray:
    """
    Evaluates the derivative of the relu func (which is equivalent to the step func)
    :param x:
    :return:
    """
    return (x > 0) * 1.0  # multiply to convert from boolean to float


def softmax(x: np.ndarray) -> np.ndarray:
    """
    Calculates the softmax func

    y = x / mean(x)
    
    :param x: Array with dimensions [batch out_dim]
    """

    return x / np.mean(x, axis=1)
