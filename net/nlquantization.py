import os
import json

import EggNet
import EggNet.Reader
import numpy as np

from quantize import prepare_config
from util import read_np_keras, perform_real_quant

weights = read_np_keras(target_dtype=np.float32)

N_BITS = 2
mnist = EggNet.Reader.MNIST(folder_path='/tmp/mnist/')
test_images = mnist.test_images()
test_labels = mnist.test_labels()
batch_size = 50

# Input activation bits and fractions
ia_b = np.array([9, 4, 4, 4])  # Bits of the input activations
ia_f = np.array([8, 2, 0, 0])  # Fractions of the input activations

# Weight bits and fractions:
# We set them to zero for non-linear quantization because we only apply right shifts
w_b = np.array([0, 0, 0, 0])  # Bits of the weights
w_f = np.array([0, 0, 0, 0])  # Fractions of the weights

# Output activation bits and fractions
oa_b = np.array([4, 4, 4, 4])  # Bits of the output activations
oa_f = np.array([2, 0, 0, 2])  # Fraction Bits of the output activations
oa_signed = np.array([False, False, False, True])  # Sign Bits of the output activations

# Scaling for weights
bias_max = 2.0 ** (oa_b - 1) - 1
bias_min = -2.0 ** (oa_b - 1)
bias_scale = 1 / 2 ** oa_f

# Calculate how much additional bits are needed to account for the summation of the results
accum_additional_bits = np.array([
    np.ceil(np.log2(3 * 3 + 1)),  # 3x3 Kernel over 1 input channel
    np.ceil(np.log2(3 * 3 * 16 + 1)),  # 3x3 Kernel over 16 input channels
    np.ceil(np.log2(7 * 7 * 24 + 1)),  # FC layer over 7x7x24 inputs
    np.ceil(np.log2(32 + 1)),  # FC Layer over 32 inputs
], dtype=np.int)

# Recycle old linear quantization for the biases
qweights, shift, options = perform_real_quant(weights,
                                              in_bits=ia_b, in_frac=ia_f,
                                              w_bits=w_b, w_frac=w_f,
                                              out_bits=oa_b, out_frac=oa_f, activations_signed=oa_signed)

for N_BITS in range(2, 5):
    # The magnitude boundaries, not accounting for the sign
    N_CODES = 2 ** N_BITS
    boundaries = 2.0 ** -(0.5 + np.arange(0, N_CODES - 1))

    test_data = np.random.rand(5)
    np.digitize(test_data, boundaries)

    d_val = {}
    d_sign = {}
    fweights = {}
    for key, value in weights.items():

        # For nonlinear quantized weights, also the sign is needed
        d_sign[key] = np.sign(value).astype(np.int)

        # The kernels/weights are quantized using non-linear quantization
        if key in ['cn1.k', 'cn2.k', 'fc1.w', 'fc2.w']:
            # d_val[key] = np.digitize(np.abs(value), bins=boundaries)
            d_val[key] = np.clip(-np.round(np.log2(np.abs(value))), a_min=0, a_max=N_CODES - 1).astype(np.int)
            fweights[key] = d_sign[key] * 2.0 ** (-d_val[key])

        # Bias is done using conventional linear quantization like the activations itself
        if key in ['cn1.b', 'cn2.b', 'fc1.b', 'fc2.b']:
            # Recycle the linear bias terms
            d_val[key] = qweights[key]

    dirname = f'final_weights/nl{N_BITS}'
    os.makedirs(dirname, exist_ok=True)
    np.savez(f'{dirname}/fake', **fweights)
    np.savez(f'{dirname}/shifts', **d_val)
    np.savez(f'{dirname}/signs', **d_sign)

    # our_net = init_network_from_weights(fweights, from_torch=False)
    # accuracy, cm = evaluate_network_full(batch_size, our_net, test_images, test_labels)
    # print(f"{N_BITS} Bit Network:             {accuracy}")

    # Save the config.json
    options['nl_weight_bits'] = N_BITS
    options['accumulator_additional_bits'] = accum_additional_bits
    # Convert numpy arrays to regular lists so we can save it as json
    json_config = prepare_config(options)

    with open(os.path.join(dirname, 'config.json'), 'w') as fp:
        json.dump(json_config, fp)


