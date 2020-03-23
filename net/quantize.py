import os

import numpy as np
import json

import EggNet
import EggNet.Reader
from util import perform_real_quant, init_network_from_weights, plot_confusion_matrix, evaluate_network_full, \
    quant2float, init_fake_network_from_weights, read_np_keras, \
    init_quant_network_from_weights


def quant_to_int(x, b, f):
    b_ = b - 1
    return np.clip(x / (2 ** f), a_min=2 ** b_, a_max=2 ** b_ - 1)


def _plot_histogram_fc(x, layout=None, title='FC Weight Distributions', filename=None):
    import matplotlib.pyplot as plt

    assert x.ndim == 2

    n = x.shape[1]

    # 20% Above max value
    ax_lim = 1.2 * np.max(np.abs(x))

    if layout is not None:
        assert len(layout) == 2
        nr, nc = layout
    else:
        nr = int(np.floor(np.sqrt(n)))
        nc = int(np.ceil(n / nr))
    assert nr * nc >= n

    fig, axes = plt.subplots(nrows=nr, ncols=nc, sharex='all', sharey='all', figsize=(10, 6), constrained_layout=True)

    for ix in range(n):
        i = ix // nc
        j = ix % nc
        axes[i, j].hist(x[:, ix].flatten())
        axes[i, j].set_xlim(-ax_lim, ax_lim)
        # axes[i, j].set_title(f'#{ix}')
    fig.suptitle(title, fontsize=16)
    plt.tight_layout()
    fig.show()

    if filename is not None:
        fig.savefig(fname=filename, dpi=300)


def _plot_histogram_array(x: np.ndarray,
                          layout=None,
                          title="Conv Kernel Plot", filename=None):
    import matplotlib.pyplot as plt

    assert x.ndim == 4

    n = x.shape[3]

    # 20% Above max value
    ax_lim = 1.2 * np.max(np.abs(x))

    if layout is not None:
        assert len(layout) == 2
        nr, nc = layout
    else:
        nr = int(np.floor(np.sqrt(n)))
        nc = int(np.ceil(n / nr))
    assert nr * nc >= n

    fig, axes = plt.subplots(nrows=nr, ncols=nc, sharex='all', sharey='all', figsize=(10, 6), constrained_layout=True)
    fig.suptitle(title, fontsize=16)
    for ix in range(n):
        i = ix // nc
        j = ix % nc
        axes[i, j].hist(x[:, :, :, ix].flatten())
        axes[i, j].set_xlim(-ax_lim, ax_lim)
        # axes[i, j].set_title(f'#{ix}')
    fig.show()

    if filename is not None:
        fig.savefig(fname=filename, dpi=300)


def _quant_weight_error_plot(fweights, weights, layer):
    if layer.startswith('cn'):
        _plot_histogram_array(x=fweights[layer] - weights[layer], title=f'Error plot: {layer}')
    elif layer.startswith('fc'):
        _plot_histogram_fc(x=fweights[layer] - weights[layer], title=f'Error plot: {layer}')
    else:
        raise NotImplementedError(f'Expected cnX.k or fcX.w layer id but got: "{layer}"')


def make_plots():
    weights = read_np_keras(target_dtype=np.float32)

    # Input activation bits and fractions
    ia_b = np.array([9, 4, 4, 4])
    ia_f = np.array([8, 2, 0, 0])

    # zB
    # v = Q * 2^-2
    # |Q| = 4bit

    # Weights bits and fractions
    # w_b = np.array([4, 4, 4, 4])
    # w_f = np.array([4, 4, 4, 4])
    w_b = np.array([4, 4, 4, 4])
    w_f = np.array([2, 5, 5, 5])

    # Output activation bits and fractions
    oa_b = np.array([4, 4, 4, 4])
    oa_f = np.array([2, 0, 0, 2])

    # Last Output is signed, because we dont have a ReLU Layer there
    oa_signed = np.array([False, False, False, True])

    qweights, shift, options = perform_real_quant(weight_dict=weights,
                                                  in_bits=ia_b, in_frac=ia_f,
                                                  w_bits=w_b, w_frac=w_f,
                                                  out_bits=oa_b, out_frac=oa_f, activations_signed=oa_signed)

    fweights = quant2float(qweights, options)

    our_net = init_network_from_weights(weights, from_torch=False)
    mnist = EggNet.Reader.MNIST(folder_path='/tmp/mnist/')
    test_images = mnist.test_images()
    test_labels = mnist.test_labels()
    batch_size = 50

    # ---- Evaluate Normal ----
    _, _, y_layers = evaluate_network_full(batch_size, our_net, test_images, test_labels, n_batches=20,
                                           intermediates=True)

    _plot_histogram_array(weights['cn1.k'], layout=(4, 4), filename='images/hist_cn1_k.png')
    _plot_histogram_array(weights['cn2.k'], layout=(4, 6), filename='images/hist_cn2_k.png')
    _plot_histogram_fc(weights['fc1.w'], layout=(4, 8), filename='images/hist_fc1_w.png')
    _plot_histogram_fc(weights['fc2.w'], layout=(2, 5), filename='images/hist_fc2_w.png')

    _plot_histogram_array(y_layers[0], layout=(4, 4), title='Output CN1', filename='images/hist_ao1.png')
    _plot_histogram_array(y_layers[1], layout=(4, 6), title='Output CN2', filename='images/hist_ao2.png')
    _plot_histogram_fc(y_layers[2], layout=(4, 8), title='Output FC1', filename='images/hist_ao3.png')
    _plot_histogram_fc(y_layers[3], layout=(2, 5), title='Output FC2', filename='images/hist_ao4.png')


def main():
    weights = read_np_keras(target_dtype=np.float32)
    # weights = read_np_torch(ordering="BHWC", target_dtype=np.float32)

    # Input activation bits and fractions
    ia_b = np.array([9, 4, 4, 4])
    ia_f = np.array([8, 2, 0, 0])

    # Weights bits and fractions
    # w_b = np.array([4, 4, 4, 4])
    # w_f = np.array([4, 4, 4, 4])
    w_b = np.array([4, 4, 4, 4])
    w_f = np.array([2, 5, 5, 5])

    # Output activation bits and fractions
    oa_b = np.array([4, 4, 4, 4])
    oa_f = np.array([2, 0, 0, 2])

    # Last Output is signed, becuase we dont have a ReLU Layer there
    oa_signed = np.array([False, False, False, True])

    qweights, shift, options = perform_real_quant(weight_dict=weights,
                                                  in_bits=ia_b, in_frac=ia_f,
                                                  w_bits=w_b, w_frac=w_f,
                                                  out_bits=oa_b, out_frac=oa_f, activations_signed=oa_signed)
    fweights = quant2float(qweights, options)
    save_weights(fweights, qweights, weights, config=options, qprefix='int4')

    np.savez('final_weights/float/all', **weights)
    np.savez('final_weights/int4_fake_quant/all', **fweights)
    np.savez('final_weights/int4_fpi/all', **qweights)

    # Check if it has worked
    our_net = init_network_from_weights(weights, from_torch=False)
    fake_net = init_fake_network_from_weights(qweights=fweights, shift=shift, options=options)
    quant_net = init_quant_network_from_weights(qweights=qweights, shift=shift, options=options)

    mnist = EggNet.Reader.MNIST(folder_path='/tmp/mnist/')
    test_images = mnist.test_images()
    test_labels = mnist.test_labels()
    batch_size = 50

    # Check network performance (might take some time)
    # Accuracy should be at least 90% even with quantization

    # ---- Evaluate Normal ----
    accuracy, cm = evaluate_network_full(
        batch_size, our_net, test_images, test_labels)
    print("Network:             ", accuracy)

    # ---- Evaluate Real Quant  ----
    qaccuracy, qcm = evaluate_network_full(batch_size, quant_net, test_images, test_labels,
                                           images_as_int=True)
    print("Quantised Network:   ", qaccuracy)

    # ---- Evaluate Fake Quant  ----
    # fqaccuracy, fqcm = evaluate_network_full(batch_size, fake_net, test_images, test_labels)
    # print("Quantised Network:   ", qaccuracy)

    classnames = list(map(str, range(10)))

    plot_confusion_matrix(cm, title='Confusion matrix (full precision)',
                          target_names=classnames, filename='images/cm')
    plot_confusion_matrix(qcm, title='Confusion matrix (fixed point)',
                          target_names=classnames, filename='images/qcm')


def prepare_config(config):
    """
    Prepares a dictionary to be stored as a json.
    Converts all numpy arrays to regular arrays
    Args:
        config: The config with numpy arrays

    Returns:
        The numpy free config
    """
    c = {}
    for key, value in config.items():
        if isinstance(value, np.ndarray):
            value = value.tolist()
        c[key] = value
    return c


def save_weights(fweights, qweights, weights, config, qprefix):
    """
    Saves the weights in numpy and text format. Also stores a config.json file
    Args:
        fweights:
        qweights:
        weights:
        config:

    Returns:

    """

    config = prepare_config(config)

    # --------------------
    # -- Save Real Quant
    # --------------------

    dirname = os.path.join('final_weights', f'{qprefix}_fpi')
    with open(os.path.join(dirname, 'config.json'), 'w') as fp:
        json.dump(config, fp)
    for key, value in qweights.items():
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()
        np.savetxt(fname=filename + '.txt', X=x_, fmt='%i', header=str(value.shape))
        np.save(file=filename, arr=value)

    # --------------------
    # -- Save Fake Quant
    # --------------------

    dirname = os.path.join('final_weights', f'{qprefix}_fake_quant')
    with open(os.path.join(dirname, 'config.json'), 'w') as fp:
        json.dump(config, fp)
    for key, value in fweights.items():
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()
        np.savetxt(fname=filename + '.txt', X=x_, header=str(value.shape))
        np.save(file=filename, arr=value)

    # --------------------
    # -- Save Floats
    # --------------------
    for key, value in weights.items():
        dirname = os.path.join('final_weights', 'float')
        os.makedirs(dirname, exist_ok=True)
        filename = os.path.join(dirname, key)
        x_ = value.flatten()
        np.savetxt(fname=filename + '.txt', X=x_, header=str(value.shape))
        np.save(file=filename, arr=value)


if __name__ == '__main__':
    make_plots()
    main()
