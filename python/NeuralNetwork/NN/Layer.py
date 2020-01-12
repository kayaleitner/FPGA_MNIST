import numpy as np
from numpy.core.multiarray import ndarray


class Layer:
    """
    Abstract base class for a neural network layer instance
    """

    def __call__(self, *args, **kwargs):
        raise NotImplementedError()

    def backprop(self, *args):
        raise NotImplementedError()

    def update_weights(self, *args):
        raise NotImplementedError()

    def __add__(self, other: object) -> list:
        """
        Combine them in a list
        :param other:
        :return:
        """
        return [self, other]

    def get_input_shape(self):
        """
        Get the valid shape of input data for this layer
        :return: a tuple with the valid dimensions
        """
        raise NotImplementedError()

    def get_output_shape(self, input_data_shape: ndarray = None):
        """
        Get the shape of the output data with respect to input data of this layer
        :param input_data_shape: An optional input tensor
        :return: a tuple with the valid dimensions
        """
        raise NotImplementedError()

    def cast(self, new_dtype):
        """
        Casts the layer to new datatype (no copy)
        Args:
            new_dtype: the new data type that should be casted to

        Returns:
            None
        """
        pass

    def __copy__(self):
        """
        Create a copy of the layer object and returns it
        Returns:
            A copy of the the layer
        """
        raise NotImplementedError()

    def deepcopy(self):
        """
        Creates a deep copy of the layer
        Returns:
            A deep copy of the object

        """
        return self.__copy__()
