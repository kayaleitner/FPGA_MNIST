import numpy as np


def adam_step(i, g, params, alpha=0.001, beta1=0.9, beta2=0.999, eps=1e-8):
    """
    Implements the ADAM optimization algorithm according to: https://arxiv.org/abs/1412.6980

    :param i: the current iteration index
    :param g: the gradient of the weight
    :param params: a parameter dictionary used to store the momentum
    :param alpha: learning rate
    :param beta1: 1st momentum decay rate
    :param beta2: 2nd momentum decay rate
    :param eps: small epsilon to avoid division by zero
    :return: the correction term to update the parameter the gradient belongs to
    """

    # Calculate the ADAM momenta
    mi = params['mi']
    vi = params['vi']

    mi = beta1 * mi + (1 - beta1) * g
    vi = beta2 * vi + (1 - beta2) * (g ** 2)
    mi_ = mi / (1 - beta1 ** (i+1))
    vi_ = vi / (1 - beta2 ** (i+1))

    # Update
    params['mi'] = mi
    params['vi'] = vi

    return alpha * mi_ / (np.sqrt(vi_) + eps)


def gradient_descent_step(g, learning_rate=0.00001):
    """
    simple gradient descent
    :param g: the gradient
    :param learning_rate: the learning rate
    :return: the corrective term for the parameters the gradient belongs to
    """
    return learning_rate * g
