import os

import numpy as np
from extract_net_parameters import read_np_torch
from tune_torch import perform_real_quant


def main():
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

    # Should perform well
    qweights = perform_real_quant(weights, target_bits=8, frac_bits=4)

    for key, value in qweights.items():
        filename = os.path.join('final_weights', f'{key}.txt')
        x_ = value.flatten()
        np.savetxt(fname=filename, X=x_, fmt='%i', header=str(value.shape))


if __name__ == '__main__':
    main()
