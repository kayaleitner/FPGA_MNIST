from math import inf

import numpy as np


def quantize_vector(x, bits=8, signed=True, max_value=inf, min_value=-inf) -> np.ndarray:
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
