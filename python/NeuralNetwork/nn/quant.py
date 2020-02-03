from __future__ import division, print_function, absolute_import

from enum import Enum
from math import inf

import numpy as np
import numbers


def np_limits(dtype):
    min_value = np.iinfo(dtype).min
    max_value = np.iinfo(dtype).max
    return min_value, max_value


def np_bits(dtype):
    d = {
        np.int64: 64,
        np.uint64: 64,
        np.int32: 32,
        np.uint32: 32,
        np.int16: 16,
        np.uint16: 16,
        np.int8: 8,
        np.uint8: 8,
    }
    return d[dtype]


def np_ncodes(dtype):
    if dtype in (np.int64, np.uint64):
        return 2 ** 64
    elif dtype in (np.int32, np.uint32):
        return 2 ** 32
    elif dtype in (np.int16, np.uint16):
        return 2 ** 16
    elif dtype in (np.int8, np.uint8):
        return 2 ** 8
    else:
        raise Exception()


def to_fpi_old(x, fraction_bits, target_type, zero_point=0):
    non_fraction_bits = np_bits(target_type) - fraction_bits - 1
    max_val = (2 ** non_fraction_bits) - 1
    min_val = -(2 ** non_fraction_bits)
    # At least a single bit is needed
    # ToDo: Is this always the case?
    assert non_fraction_bits > 0

    lsb = (max_val - min_val) / np_ncodes(target_type)
    value = np.round(x / lsb + zero_point).astype(target_type)
    return value


def to_fpi(x, fraction_bits, target_type, zero_point=0):
    (a_min, a_max) = np_limits(target_type)
    val = np.clip(x / (2 ** (-fraction_bits)), a_min=a_min, a_max=a_max).round().astype(target_type)
    return val


def to_fpi_object(x, fraction_bits, target_type, zero_point=0):
    if not np.isscalar(x):
        x_shape = x.shape
        x_converted = map(lambda val: Fpi(val,
                                          fraction_bits=fraction_bits,
                                          target_type=target_type,
                                          zero_point=zero_point),
                          x.reshape(-1))
        y = np.array(list(x_converted), dtype=Fpi)
        return y.reshape(x_shape)
    else:
        val = to_fpi(x, fraction_bits, target_type, zero_point=0)
        return Fpi(value=val, fraction_bits=fraction_bits, target_type=target_type, zero_point=zero_point)


def from_fpi(x, fraction_bits, target_type, zero_point):
    return x * 2 ** (-fraction_bits)


class Fpi(numbers.Number):
    """
    Implements a fixed point integer class
    """

    def __init__(self, value: int, fraction_bits: int, target_type=np.int8, zero_point=0):

        if isinstance(value, float):
            value = to_fpi(value, fraction_bits=fraction_bits, target_type=target_type, zero_point=zero_point)

        assert np_bits(target_type) > fraction_bits
        self.value = np.cast[target_type](value)
        self.fraction_bits = fraction_bits
        self.dtype = target_type
        self.fvalue = from_fpi(value, fraction_bits=fraction_bits, target_type=target_type, zero_point=zero_point)
        self.zero_point = zero_point

    def get_lsb(self) -> float:
        non_fraction_bits = np_bits(self.dtype) - self.fraction_bits - 1
        max_val = (2 ** non_fraction_bits) - 1
        min_val = -(2 ** non_fraction_bits)
        lsb = (max_val - min_val) / np_ncodes(self.dtype)
        return lsb

    def asfloat(self):
        """
        Converts the fixed point value to the float datatype

            # scale = self.get_lsb()
            # return (self.value - self.zero_point) * scale

        Returns:
            The value as a float
        """

        return from_fpi(self.value, fraction_bits=self.fraction_bits, target_type=self.dtype, zero_point=self.dtype)

    def __eq__(self, o: object) -> bool:

        if isinstance(o, Fpi):
            return o.dtype == self.dtype and o.fraction_bits == self.fraction_bits and o.value == self.value
        else:
            return False

    def __ne__(self, o: object) -> bool:
        return not self.__eq__(o)

    def __str__(self) -> str:
        return "{:.3}<{}/{}>".format(self.asfloat(), np_bits(self.dtype), self.fraction_bits)

    def __repr__(self) -> str:
        return self.__str__()

    def convert_and_check_input(self, other):
        if isinstance(other, Fpi):
            pass
        elif isinstance(other, float):
            other = Fpi(other, fraction_bits=self.fraction_bits, target_type=self.dtype)
        elif isinstance(other, int):
            other = Fpi(other, fraction_bits=self.fraction_bits, target_type=self.dtype)
        else:
            raise NotImplementedError()

        assert self.dtype == other.dtype
        assert self.zero_point == other.zero_point == 0
        return other

    def __add__(self, other):

        other = self.convert_and_check_input(other)

        a = self
        b = other
        frac_diff = a.fraction_bits - b.fraction_bits
        aval = a.value
        bval = b.value
        if frac_diff > 0:
            # a is larger, shift b
            bval = bval << frac_diff
            cfrac = a.fraction_bits
        else:
            aval = aval << frac_diff
            cfrac = b.fraction_bits

        cval = aval + bval
        return Fpi(value=cval, fraction_bits=cfrac, target_type=self.dtype, zero_point=self.zero_point)

    def __sub__(self, other):
        other = self.convert_and_check_input(other)
        a = self
        b = other
        frac_diff = a.fraction_bits - b.fraction_bits
        aval = a.value
        bval = b.value
        if frac_diff > 0:
            # a is larger, shift b
            bval = bval << frac_diff
            cfrac = a.fraction_bits
        else:
            aval = aval << frac_diff
            cfrac = b.fraction_bits

        cval = aval - bval
        return Fpi(value=cval, fraction_bits=cfrac, target_type=self.dtype, zero_point=self.zero_point)

    def __mul__(self, other):
        """
        v = Q 2^{-m}

        v1 * v2 = Q1 * Q2 * 2^{-m1-m2}
        Args:
            other:

        Returns:

        """

        if isinstance(other, Fpi):
            assert self.dtype == other.dtype
            assert self.zero_point == other.zero_point == 0
            val = other.value * self.value
            frac_bits = other.fraction_bits + self.fraction_bits
            x = Fpi(value=val, fraction_bits=frac_bits, target_type=self.dtype, zero_point=self.zero_point)
            return x
        raise NotImplementedError()

    def __divmod__(self, other):
        raise NotImplementedError()


def to_fix_point(value: float, fraction_bits: int, target_type: np.dtype, zero_point=0.0) -> Fpi:
    non_fraction_bits = np_bits(target_type) - fraction_bits - 1
    # At least a single bit is needed
    # ToDo: Is this always the case?
    assert non_fraction_bits > 0
    max_val = (2 ** non_fraction_bits) - 1
    min_val = -(2 ** non_fraction_bits)
    lsb = (max_val - min_val) / np_ncodes(target_type)
    value = np.round(value / lsb + zero_point).astype(target_type)
    fix_val = Fpi(value, fraction_bits=fraction_bits, target_type=target_type, zero_point=zero_point)
    return fix_val


class QuantConvLayerType(Enum):
    FULL_LAYER = 0,
    PER_CHANNEL = 1,


class QuantFullyConnectedType(Enum):
    FULL_LAYER = 0


def np_quant(x, target_dtype=np.int16, max_value=inf, min_value=-inf):
    ncodes = np_ncodes(target_dtype)
    (limit_lower, limit_upper) = np_limits(target_dtype)

    if max_value == inf:
        max_value = np.max(x)

    if min_value == -inf:
        min_value = np.min(x)

    val_range = (max_value - min_value)
    x = np.clip(x, a_min=min_value, a_max=max_value)

    limit_lower + np.round(x / val_range)


def dequantize_vector(x, max_value, min_value):
    ncodes = np_ncodes(x.dtype)
    lsb = (max_value - min_value) / ncodes
    return x * lsb


def quantize_vector(x, target_type, signed=True, max_value=inf, min_value=-inf) -> np.ndarray:
    """
    Performs deterministic rounding quantization to a vector

    Args:
        x:
        target_type:
        signed:
        max_value:
        min_value:

    Returns:

    """
    if max_value == inf:
        max_value = np.max(x)

    if min_value == -inf:
        min_value = np.min(x)

    n_codes = np_ncodes(dtype=target_type)
    (min_code, max_code) = np_limits(dtype=target_type)

    if max_value == min_value == 0:
        lsb = 1
    else:
        lsb = (max_value - min_value) / n_codes

    xc = np.clip(x, a_min=min_value, a_max=max_value)
    y = np.round(xc / lsb - 0.5).clip(min=min_code, max=max_code).astype(dtype=target_type)
    return y


def cluster_quantization(w, n_centroids):
    """
    Performs k-means quantization to input matrix
    Args:
        w:
        x:
        n_centroids:

    Returns:

    """

    # ToDo: Implement cluster quantization

    pass
