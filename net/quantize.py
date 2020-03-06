import os

import numpy as np

import NeuralNetwork
from util import read_np_torch, perform_real_quant, init_network_from_weights, evaluate_network, perform_fake_quant, \
    plot_confusion_matrix, evaluate_network_full


def quant_to_int(x, b, f):
    b_ = b - 1
    return np.clip(x / (2 ** f), a_min=2 ** b_, a_max=2 ** b_ - 1)


def _plot_histogram_fc(x, title='FC Weight Distributions'):
    import matplotlib.pyplot as plt

    assert x.ndim == 2

    n = x.shape[1]

    # 20% Above max value
    ax_lim = 1.2 * np.max(np.abs(x))

    nr = int(np.floor(np.sqrt(n)))
    nc = int(np.ceil(n / nr))
    assert nr * nc >= n

    fig, axes = plt.subplots(nrows=nr, ncols=nc, sharex='all', sharey='all', figsize=(8, 6))
    fig.suptitle(title)
    for ix in range(n):
        i = ix // nc
        j = ix % nc
        axes[i, j].hist(x[:, ix].flatten())
        axes[i, j].set_xlim(-ax_lim, ax_lim)
        axes[i, j].set_title(f'#{ix}')
    fig.show()


def _plot_histogram_array(x: np.ndarray, title="Conv Kernel Plot"):
    import matplotlib.pyplot as plt

    assert x.ndim == 4

    n = x.shape[3]

    # 20% Above max value
    ax_lim = 1.2 * np.max(np.abs(x))

    nr = int(np.floor(np.sqrt(n)))
    nc = int(np.ceil(n / nr))
    assert nr * nc >= n

    fig, axes = plt.subplots(nrows=nr, ncols=nc, sharex='all', sharey='all', figsize=(8, 6))
    fig.suptitle(title)
    for ix in range(n):
        i = ix // nc
        j = ix % nc
        axes[i, j].hist(x[:, :, :, ix].flatten())
        axes[i, j].set_xlim(-ax_lim, ax_lim)
        axes[i, j].set_title(f'#{ix}')
    fig.show()


def main():
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)
    _plot_histogram_array(weights['cn1.k'])
    _plot_histogram_array(weights['cn2.k'])

    _plot_histogram_fc(weights['fc1.w'])
    _plot_histogram_fc(weights['fc2.w'])

    # Input activation bits and fractions
    ia_b = np.array([8, 8, 8, 8])
    ia_f = np.array([4, 6, 6, 6])

    # Weights bits and fractions
    w_b = np.array([8, 8, 8, 8])
    w_f = np.array([4, 6, 6, 6])

    # Output activation bits and fractions
    oa_b = np.array([8, 8, 8, 8])
    oa_f = np.array([6, 6, 6, 6])

    # Check if consistent: input2 must be output 1
    assert np.all(oa_b[:-1] == ia_b[1:])
    assert np.all(oa_f[:-1] == ia_f[1:])

    # Temporary bits and fractions while adding (for bias)
    t_b = ia_b + w_b
    t_f = ia_f + w_f
    shift = t_f - oa_f

    scaling = 0
    a_max = 0
    a_min = 0

    # np.clip(weights['cn1.k'] / scaling, a_min=a_min, a_max=a_max)
    # weights['cn2.k']
    # weights['fc1.w']
    # weights['fc2.w']

    # Should perform well
    qweights = perform_real_quant(weights, target_bits=8, frac_bits=4)
    fweights = perform_fake_quant(weights, target_bits=8, frac_bits=4)

    # Check if it has worked
    our_net = init_network_from_weights(weights, from_torch=False)
    our_quant_net = init_network_from_weights(fweights, from_torch=False)
    mnist = NeuralNetwork.Reader.MNIST(folder_path='/tmp/mnist/')
    test_images = mnist.test_images()
    test_labels = mnist.test_labels()
    batch_size = 50

    classnames = list(map(str, range(10)))

    # Check network performance (might take some time)
    # Accuracy should be at least 90% even with quantization
    accuracy, cm = evaluate_network_full(batch_size, our_net, test_images, test_labels)
    print("Network:             ", accuracy)

    qaccuracy, qcm = evaluate_network_full(batch_size, our_quant_net, test_images, test_labels)
    print("Quantised Network:   ", qaccuracy)

    plot_confusion_matrix(cm, title='Confusion matrix (full precision)',
                          target_names=classnames, filename='images/cm')
    plot_confusion_matrix(qcm, title='Confusion matrix (fake fixed point 8/4)',
                          target_names=classnames, filename='images/qcm')

    # save_weights(fweights, qweights, weights)


def save_weights(fweights, qweights, weights):
    for key, value in qweights.items():
        dirname = os.path.join('final_weights', 'fpi')
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()

        np.savetxt(fname=filename + '.txt', X=x_, fmt='%i', header=str(value.shape))
        np.save(file=filename, arr=value)
    for key, value in fweights.items():
        dirname = os.path.join('final_weights', 'fake_quant')
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()

        np.savetxt(fname=filename + '.txt', X=x_, header=str(value.shape))
        np.save(file=filename, arr=value)
    for key, value in weights.items():
        dirname = os.path.join('final_weights', 'float')
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()

        np.savetxt(fname=filename + '.txt', X=x_, header=str(value.shape))
        np.save(file=filename, arr=value)


if __name__ == '__main__':
    main()
