import numpy as np

import NeuralNetwork


def _read_np_tensor(weight_file):
    with open(weight_file) as f:
        init_line = f.readline()

    # assume the first line is a comment
    assert init_line[0] == '#'
    p1 = init_line.find('(')
    p2 = init_line.find(')')
    dims = [int(ds) for ds in init_line[p1 + 1:p2].split(sep=',') if len(ds) > 0]

    return np.loadtxt(weight_file).reshape(dims)


def read_np_torch(ordering='BCHW', target_dtype=None):
    d = {
        'cn1.b': _read_np_tensor('np/t_0.0.bias.txt'),
        'cn1.k': _read_np_tensor('np/t_0.0.weight.txt'),
        'cn2.b': _read_np_tensor('np/t_3.0.bias.txt'),
        'cn2.k': _read_np_tensor('np/t_3.0.weight.txt'),
        'fc1.b': _read_np_tensor('np/t_7.0.bias.txt'),
        'fc1.w': _read_np_tensor('np/t_7.0.weight.txt'),
        'fc2.b': _read_np_tensor('np/t_9.0.bias.txt'),
        'fc2.w': _read_np_tensor('np/t_9.0.weight.txt'),
    }

    if ordering is 'BCHW':
        pass
    elif ordering is 'BHWC':
        k1 = np.moveaxis(d['cn1.k'], [0, 1], [3, 2])
        k2 = np.moveaxis(d['cn2.k'], [0, 1], [3, 2])

        # k1 = reorder(d['cn1.k'])
        # k2 = reorder(d['cn2.k'])

        assert k1[1, 2, 0, 4] == d['cn1.k'][4, 0, 1, 2]
        assert k2[1, 2, 3, 4] == d['cn2.k'][4, 3, 1, 2]

        d['cn1.k'] = k1
        d['cn2.k'] = k2
        d['fc1.w'] = np.moveaxis(d['fc1.w'], 0, 1)
        d['fc2.w'] = np.moveaxis(d['fc2.w'], 0, 1)

        x = d['fc1.w'].transpose()

        # Hack: Because torch positions the channels first, we have to reorder the following FC weights
        # Input Tensor is: [batch, channels, 7, 7]
        # Reshaped to: [batch, channels * 7 * 7]
        x = x.reshape((-1, 32, 7, 7))
        x = np.moveaxis(x, 1, 3)
        x = np.reshape(x, (32, -1))
        x = x.transpose()
        d['fc1.w'] = x

    else:
        raise NotImplementedError('Expected ordering to be "BCHW" or "BHWC" but is: {}'.format(ordering))

    if target_dtype is not None:
        d_old = d
        d = {}
        for key, values in d_old.items():
            d[key] = values.astype(target_dtype)
    return d


def reorder(x):
    co, ci, h, w, = x.shape
    x_ = np.zeros(shape=(h, w, ci, co), dtype=x.dtype)

    for hx in range(h):
        for wx in range(w):
            for cix in range(ci):
                for cox in range(co):
                    x_[hx, wx, cix, cox] = x[cox, cix, hx, wx]
    return x_


def perform_real_quant(weight_dict, target_bits, frac_bits):
    """

    Performs real quantization, meaning all values will be rounded to
    their fixed point representation

    Args:
        weight_dict: Dictionary containing numpy arrays
        target_bits: Target bit length of the integer values
        frac_bits: Target fraction bit width

    Returns:
        Dictionary with original keys, containing quantized values
    """

    assert target_bits > frac_bits

    # v = Q * 2^-m
    # Q = v * 2^m
    a_max = 2 ** (target_bits - 1) - 1
    a_min = -2 ** (target_bits - 1)
    scale = 2 ** frac_bits

    d_out = {}
    for key, value in weight_dict.items():
        # round weights
        w = np.clip(value * scale, a_min=a_min, a_max=a_max).round().astype(np.int64)
        # Those are now ints, convert back to floats
        d_out[key] = w

    return d_out


def perform_fake_quant(weight_dict, target_bits, frac_bits, target_dtype=np.float64):
    """
    Performs fake quantization, meaning all values will be rounded to
    their expression

    Args:
        weight_dict: Dictionary containing numpy arrays
        target_bits: Target bit length of the integer values
        frac_bits: Target fraction bit width

    Returns:
        Dictionary with original keys, containing quantized values
    """

    assert target_bits > frac_bits

    value_bits = target_bits - frac_bits

    a_max = 2 ** (value_bits - 1) - 1
    a_min = -2 ** (value_bits - 1)
    scale = 1 / 2 ** frac_bits

    d_out = {}
    for key, value in weight_dict.items():
        # round weights
        w = np.clip(value / scale, a_min=a_min, a_max=a_max).round()
        w = (w * scale).astype(dtype=target_dtype)
        # All values
        d_out[key] = w

    return d_out


def init_network_from_weights(qweights, from_torch):
    our_net = NeuralNetwork.nn.Network.LeNet(reshape_torch=from_torch)
    our_net.cn1.weights = qweights['cn1.k']
    our_net.cn1.bias = qweights['cn1.b']
    our_net.cn2.weights = qweights['cn2.k']
    our_net.cn2.bias = qweights['cn2.b']
    our_net.fc1.weights = qweights['fc1.w']
    our_net.fc1.bias = qweights['fc1.b']
    our_net.fc2.weights = qweights['fc2.w']
    our_net.fc2.bias = qweights['fc2.b']
    return our_net


def evaluate_network_full(batch_size, network, train_images, train_labels):
    i = 0
    total_correct = 0

    confusion_matrix = np.zeros(shape=(10, 10))

    while i < train_images.shape[0]:
        x = train_images[i:i + batch_size] / 255.0
        y_ = train_labels[i:i + batch_size]
        y = network.forward(x)
        y = y.argmax(-1)

        # ToDo: Might be a faster way
        for pred, label in zip(y, y_):
            confusion_matrix[pred, label] = confusion_matrix[pred, label] + 1

        total_correct += np.sum(y == y_)
        i += batch_size

    accuracy = total_correct / train_images.shape[0]
    return accuracy, confusion_matrix


def evaluate_network(batch_size, network, train_images, train_labels):
    a, _ = evaluate_network_full(batch_size, network, train_images, train_labels)
    return a


def plot_confusion_matrix(cm: np.ndarray, title='Confusion matrix', target_names=None, normalize=True,
                          cmap=None, filename=None):
    """

    Plot a confusion matrix.

    Taken from: https://www.kaggle.com/grfiv4/plot-a-confusion-matrix

    Args:

        cm: Confusion matrix itself, must be a 2D numpy array
        title: Plot title
        target_names: Axes labels
        normalize: True, for normalized values, false otherwise
        cmap: Optional color map
        filename: Optional filename if the plot should be saved
    Returns:

    """
    assert cm.ndim == 2

    import matplotlib.pyplot as plt
    import itertools

    accuracy = np.trace(cm) / float(np.sum(cm))
    misclass = 1 - accuracy

    if cmap is None:
        cmap = plt.get_cmap('Blues')

    if normalize:
        cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]

    fig = plt.figure(figsize=(8, 6))
    ax = plt.imshow(cm, interpolation='nearest', cmap=cmap)

    plt.title(title)
    plt.colorbar()

    if target_names is not None:
        tick_marks = np.arange(len(target_names))
        plt.xticks(tick_marks, target_names, rotation=45)
        plt.yticks(tick_marks, target_names)

    thresh = cm.max() / 1.5 if normalize else cm.max() / 2

    for i, j in itertools.product(range(cm.shape[0]), range(cm.shape[1])):
        if normalize:
            plt.text(j, i, "{:0.2f}".format(cm[i, j]),
                     horizontalalignment="center",
                     color="white" if cm[i, j] > thresh else "black")
        else:
            plt.text(j, i, "{:,}".format(cm[i, j]),
                     horizontalalignment="center",
                     color="white" if cm[i, j] > thresh else "black")

    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label\naccuracy={:0.4f}; misclass={:0.4f}'.format(accuracy, misclass))
    plt.show()

    if filename is not None:
        fig.savefig(fname=filename, dpi=300)


def plot_convolutions(kernel, order='keras', title='Convolution Kernels', target_names=None, normalize=True,
                      labels=None,
                      cmap=None, filename=None):
    if order is 'keras':
        # Keras order is fine
        pass
    elif order is 'torch':
        # Convert to keras
        # Tensor is: [Co, Ci, H, W]
        # Tensor should be: [H, W, Ci, Co]
        # Use numpy for conversion
        kernel = np.moveaxis(kernel, source=(0, 1), destination=(2, 3))
        pass
    else:
        raise NotImplementedError(f'Not currently implemented. Should be "keras" or "torch" but is: {order}')

    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(nrows=1, ncols=1)

    fig.set_title(title=title)



    pass


def plot_kernel_density():
    """

    Check out:
    https://stackoverflow.com/questions/30145957/plotting-2d-kernel-density-estimation-with-python
    Returns:

    """
    pass
