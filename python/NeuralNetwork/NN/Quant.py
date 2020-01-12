from enum import Enum
from math import inf

import numpy as np


class Fp:

    def asfloat(self):
        raise NotImplementedError()


class Fp8(Fp):

    def asfloat(self):
        pass

    def __init__(self, value, bits, min_value, max_value, signed=True):
        self.value = value
        self.bits = bits
        self.min_value = min_value
        self.max_value = max_value
        self.signed = signed
        self.qvalue = quantize_vector(value, bits=bits, min_value=min_value, max_value=max_value, signed=signed)


class QuantConvLayerType(Enum):
    FULL_LAYER = 0,
    PER_CHANNEL = 1,


class QuantFullyConnectedType(Enum):
    FULL_LAYER = 0


def np_limits(dtype):
    if dtype is np.int64:
        return -2 ** 63, 2 ** 63 - 1
    elif dtype is np.int32:
        return -2 ** 31, 2 ** 31 - 1
    elif dtype is np.int16:
        return -2 ** 15, 2 ** 15 - 1
    elif dtype is np.int8:
        return -2 ** 7, 2 ** 7 - 1
    elif dtype is np.uint64:
        return 0, 2 ** 64 - 1
    elif dtype is np.uint32:
        return 0, 2 ** 32 - 1
    elif dtype is np.uint16:
        return 0, 2 ** 16 - 1
    elif dtype is np.uint8:
        return 0, 2 ** 8 - 1
    else:
        return -inf, inf


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


def dequantize_vector(x, bits, max_value, min_value, signed=True):
    lsb = (max_value-min_value) / (2**bits)

    if signed:
        # apply shift to 0x00 up to 0xFF
        xnorm = x + 2**(bits-1)

    xnorm * lsb + min_value
    return x * lsb + min_value

    if signed:
        # Normalize between -1 and 1
        xnorm = 2*(x + 2**(bits-1)) / (2**bits-1) - 1
        return xnorm * (max_value-min_value) + min_value
    else:
        # Normalize between 0 and 1
        xnorm = x / (2 ** bits - 1)
        return xnorm * (max_value-min_value) + min_value


def quantize_vector(x, bits=8, signed=True, max_value=inf, min_value=-inf) -> np.ndarray:
    """
    Performs deterministic rounding quantization to a vector

    Args:
        x:
        bits:
        signed:
        max_value:
        min_value:

    Returns:

    """
    if max_value == inf:
        max_value = np.max(x)

    if min_value == -inf:
        min_value = np.min(x)

    n_codes = 2 ** bits

    if signed:
        min_code = -n_codes // 2
        max_code = n_codes // 2 - 1
        offset_shift = n_codes // 2
    else:
        min_code = 0
        max_code = n_codes - 1
        offset_shift = 0

    lsb = (max_value - min_value) / n_codes
    xc = np.clip(x, a_min=min_value, a_max=max_value)
    y = np.round(xc / lsb - 0.5).astype(np.int)
    yq = np.clip(y, a_min=min_code, a_max=max_code) + offset_shift
    return yq


def cluster_quantization(w, n_centroids):
    """
    Performs k-means quantization to input matrix
    Args:
        x:
        n_centroids:

    Returns:

    """

    # ToDo: Implement cluster quantization

    pass
