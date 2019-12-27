from numpy.core.multiarray import ndarray


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

    def get_input_shape(self):
        """
        Get the valid shape of input data for this layer
        :return: a tuple with the valid dimensions
        """
        return NotImplementedError

    def get_output_shape(self, input_data_shape: ndarray = None):
        """
        Get the shape of the output data with respect to input data of this layer
        :param input_data_shape: An optional input tensor
        :return: a tuple with the valid dimensions
        """
        return NotImplementedError
