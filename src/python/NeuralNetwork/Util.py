from numpy import reshape
from numpy.core.multiarray import ndarray

from .Layer import Layer


class ReshapeLayer(Layer):
    newshape: ndarray

    def __init__(self, newshape):
        self.newshape = newshape

    def __call__(self, *args, **kwargs):
        x = args[0]
        return reshape(x, newshape=self.newshape)

    def get_input_shape(self):
        pass  # can be anything

    def get_output_shape(self, input_data_shape: ndarray = None):
        return self.newshape
