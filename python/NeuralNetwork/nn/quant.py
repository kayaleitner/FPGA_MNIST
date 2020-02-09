from __future__ import division, print_function, absolute_import

from collections import namedtuple
from enum import Enum
import math
from math import inf
from typing import NamedTuple, Any

import numpy as np
import numbers

import NeuralNetwork.nn as nn


def np_limits(dtype):
    min_value = np.iinfo(dtype).min
    max_value = np.iinfo(dtype).max
    return min_value, max_value


def datatype_for_bits(bits):
    if bits <= 8:
        return np.int8
    elif bits <= 16:
        return np.int16
    elif bits <= 32:
        return np.int32
    elif bits <= 64:
        return np.int64
    else:
        raise NotImplementedError()


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
    # ToDo: This doesnt work reliably. Why?
    # return d[dtype]

    return int(np.log2(np_ncodes(dtype)))


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


class np_Fpi:

    def __init__(self, values, m, bit_width):
        # super(Fpi, self).__init__(values)
        super(Fpi, self).__init__()
        self.values = values
        self.m = m
        self.bit_width = bit_width

    def __add__(self, other):
        raise NotImplementedError()
        if not isinstance(other, Fpi):
            other = Fpi(other, m=0, bit_width=64)

        result = Fpi()

    def __mul__(self, other):
        raise NotImplementedError()

    def __abs__(self):
        raise NotImplementedError()

    def __sub__(self, other):
        raise NotImplementedError()


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


def _make_divisible(v, divisor, min_value=None):
    """
    This function is taken from the original tf repo.
    It ensures that all layers have a channel number that is divisible by 8
    It can be seen here:
    https://github.com/tensorflow/models/blob/master/research/slim/nets/mobilenet/mobilenet.py

    Taken from: https://pytorch.org/tutorials/advanced/static_quantization_tutorial.html#post-training-static-quantization

    :param v:
    :param divisor:
    :param min_value:
    :return:
    """
    if min_value is None:
        min_value = divisor
    new_v = max(min_value, int(v + divisor / 2) // divisor * divisor)
    # Make sure that round down does not go down by more than 10%.
    if new_v < 0.9 * v:
        new_v += divisor
    return new_v


def quantise_affine(x, ncodes, scale, zero_point):
    """
    Implements quantisation of a vector according to:

    Quantizing deep convolutional networks for efficient inference: A whitepaper
    Raghuraman Krishnamoorthi
    2018
    https://arxiv.org/pdf/1806.08342.pdf

    Args:
        x:
        ncodes:
        scale:
        zero_point:

    Returns:

    """
    x_int = np.round(x / scale) + zero_point
    x_q = np.clip(x_int, a_min=0, a_max=ncodes - 1)
    return x_q


def dequantise_affine(xq, scale, zero_point):
    """
    Implements dequantisation of a vector according to:

    Quantizing deep convolutional networks for efficient inference: A whitepaper
    Raghuraman Krishnamoorthi
    2018
    https://arxiv.org/pdf/1806.08342.pdf

    Args:
        xq:
        scale:
        zero_point:

    Returns:

    """
    xfloat = (xq - zero_point) * scale
    return xfloat


def quantise_uniform(x, scale, ncodes, signed=True):
    x_int = np.round(x / scale)
    if signed:
        xq = np.clip(x_int, a_min=-ncodes / 2, a_max=ncodes / 2 - 1)
    else:
        xq = np.clip(x_int, a_min=0, a_max=ncodes / 2 - 1)
    return xq


def dequantise_uniform(xq, scale):
    return xq * scale


def qint_add_primitive(q1, s1, q2, s2):
    """
    Adds two quantized values q1 and q2 where qi = xi / si



    Here xi is the floating point representation of the value
    Args:
        q1: The quantized integer code of value 1
        s1: The scale of value 1
        q2: The quantized integer code of value 2
        s2: The scale of value 2

    Returns:
        q_result, s_result
    """
    return (s2 * q1 + s1 * q2) / (q1 * q2), q1 * q2


def qint_multiply_primitive(q1, s1, q2, s2):
    return q1 * q2, s1 * s2


def scale_to_fracbits(scale):
    return np.log2(scale)


def next_pow2(x):
    i = np.ceil(np.log2(x))
    return 2 ** i


def fracbits_to_scale(bits):
    return 1 / np.where(bits < 0, 1 / (2 ** (-bits)), 2 ** bits)


BIT_SIZE_MAPPING = {
    8: np.int8,
    16: np.int16,
    32: np.int32,
    64: np.int64,
}


def quantize_conv_activations(input, parameter_bits, mode=QuantConvLayerType.PER_CHANNEL, per_batch=False):
    # Idea: try to maximize precision
    # Only symmetric values are possible now
    #
    # Input Shape = [B, H, W, C]
    # is identical to the kernel shape. Therefore the same function can be used

    if per_batch:
        raise NotImplementedError()
    else:
        return quantize_kernels(kernel=input, parameter_bits=parameter_bits, mode=mode)


def quantize_kernels(kernel, parameter_bits, mode=QuantConvLayerType.PER_CHANNEL, signed=True):
    """
    Quantize kernel
    Args:
        kernel: The kernel that should be quantized
        parameter_bits: the number of bits used for the final value
        mode: the mode that should be used

    Returns:

    """
    # Idea: try to maximize precision
    # Only symmetric values are possible now
    target_type = datatype_for_bits(parameter_bits)

    if mode is QuantConvLayerType.PER_CHANNEL:
        # Determine maximum value for each channel, e.g.: 0.4
        max_vals = np.max(np.abs(kernel), axis=(0, 1, 2))
    elif mode is QuantConvLayerType.FULL_LAYER:
        # Determine the maximum value for the whole kernel layer
        # gives a scalar value
        max_vals = np.max(np.abs(kernel), axis=(0, 1, 2, 3))
    else:
        raise NotImplementedError()

    # Determine the upper power of 2 (which can be negative, e.g. for a max_val = 0.4 it would be 0.5 == 2^-1)
    sbits = np.ceil(np.log2(max_vals))

    # Scale =
    # Divide by PowerOf2 MaxValue: value is in range -1 to 1
    # Multiply by the number of available codes, e.g. 128, so it is in range -128, +128
    scale = 2 ** (sbits - parameter_bits + 1)  # = 2 ** sbits / (2**(parameter_bits-1))

    # Calculate fracbits: E.g. for parameter_bits : 8
    # A scale from 1 corresponds to 8 fracbits
    # A scale from 0.5 corresponds to 9 fracbits
    # v = Q * 2^-m

    if signed:
        # So, for signed, this would be:
        m = parameter_bits - sbits - 1
    else:
        # and for unsigned
        m = parameter_bits - sbits + 1

    # Use this helper function which applies scale and clips it to the right number of bits
    qkernel = quantise_uniform(kernel, scale=scale, ncodes=2 ** parameter_bits).astype(dtype=target_type)

    return qkernel, m


def can_mul_overflow(a, a_bits, b, b_bits, out_bits):
    """
    Args:
        a:
        a_bits:
        b:
        b_bits:
        out_bits:

    Returns:

    """
    max_val = np.maximum(2 ** a_bits, 2 ** b_bits)
    out_max_val = 2 ** out_bits

    # Upcast to floating point
    a64 = np.cast[float](a)
    b64 = np.cast[float](b)

    # Multiply
    c64 = a64 * b64

    #
    return np.any(abs(c64) >= out_max_val / 2)


def can_add_overflow(a, a_bits, a_frac, b, b_bits, b_frac, out_bits):
    af = np.cast[np.float](a)
    bf = np.cast[np.float](b)

    delta = a_frac - b_frac

    if delta > 0:
        # a is larger, shift b
        sdelta = 2.0 ** delta
        bf = bf * sdelta
        if np.any(abs(bf) > 2 ** (b_bits - 1)): return True

    else:
        # b is larger, shift a
        sdelta = 2.0 ** (-delta)
        af = af * sdelta
        if np.any(abs(af) > 2 ** (b_bits - 1)): return True

    cf = af + bf

    return np.any(abs(cf) > 2 ** (out_bits - 1))


def can_kernel_overflow(qkernel, kernel_bits, kernel_frac_bits,
                        qinputs, input_bits, input_frac_bits,
                        output_bits, output_frac_bits):
    qout = nn.conv2d(qinputs, qkernel)


def dequantizse_kernels(qkernel, parameter_bits, frac_bits, mode=QuantConvLayerType.PER_CHANNEL):
    scale = 2.0 ** (-frac_bits)
    return dequantise_uniform(qkernel, scale)


def fpi_conv2D(data_in, kernel_in, dtype_out=np.int8, stride=1):
    nn.conv2d(data_in=data_in.astype(dtype_out), kernel=kernel_in.astype(dtype_out), )
