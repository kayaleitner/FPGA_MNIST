import os

import EggNet.Reader
import numpy as np

from util import read_np_keras

weights = read_np_keras(target_dtype=np.float32)

N_BITS = 2
mnist = EggNet.Reader.MNIST(folder_path='/tmp/mnist/')
test_images = mnist.test_images()
test_labels = mnist.test_labels()
batch_size = 50

for N_BITS in range(2, 6):
    # The magnitude boundaries, not accounting for the sign
    N_CODES = 2 ** N_BITS
    boundaries = 2.0 ** -(0.5 + np.arange(0, N_CODES - 1))

    test_data = np.random.rand(5)
    np.digitize(test_data, boundaries)

    d_val = {}
    d_sign = {}
    fweights = {}
    for key, value in weights.items():
        # d_val[key] = np.digitize(np.abs(value), bins=boundaries)
        d_val[key] = np.clip(-np.round(np.log2(np.abs(value))), a_min=0, a_max=N_CODES - 1)
        d_sign[key] = np.sign(value)
        fweights[key] = d_sign[key] * 2.0 ** (-d_val[key])

    os.makedirs(f'final_weights/nl{N_BITS}',exist_ok=True)
    np.savez(f'final_weights/nl{N_BITS}/fake', **fweights)
    np.savez(f'final_weights/nl{N_BITS}/shifts', **d_val)
    np.savez(f'final_weights/nl{N_BITS}/signs', **d_sign)

    # our_net = init_network_from_weights(fweights, from_torch=False)
    # accuracy, cm = evaluate_network_full(batch_size, our_net, test_images, test_labels)
    # print(f"{N_BITS} Bit Network:             {accuracy}")

