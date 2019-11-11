import numpy as np


class Layer:
    """
    Abstract base class for a neural network layer instance
    """

    def __call__(self, *args, **kwargs):
        raise NotImplementedError()

    def __add__(self, other: object) -> list:
        """
        Combine them in a list
        :param other:
        :return:
        """
        return [self, other]
