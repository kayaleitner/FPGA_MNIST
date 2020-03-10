import numpy as np
import EggNet


def _read_np_tensor(weight_file: str):
    if weight_file.endswith('.npy'):
        is_binary = True
    elif weight_file.endswith('.txt'):
        is_binary = False
    else:
        raise NotImplementedError()

    if is_binary:
        return np.load(weight_file)
    else:
        with open(weight_file) as f:
            init_line = f.readline()

        # assume the first line is a comment
        assert init_line[0] == '#'
        p1 = init_line.find('(')
        p2 = init_line.find(')')
        dims = [int(ds) for ds in init_line[p1 + 1:p2].split(sep=',') if len(ds) > 0]

        return np.loadtxt(weight_file).reshape(dims)


def read_np_torch(ordering='BCHW', binary=True, target_dtype=None):
    if binary:
        d = {
            'cn1.b': _read_np_tensor('np/t_0.0.bias.npy'),
            'cn1.k': _read_np_tensor('np/t_0.0.weight.npy'),
            'cn2.b': _read_np_tensor('np/t_3.0.bias.npy'),
            'cn2.k': _read_np_tensor('np/t_3.0.weight.npy'),
            'fc1.b': _read_np_tensor('np/t_7.0.bias.npy'),
            'fc1.w': _read_np_tensor('np/t_7.0.weight.npy'),
            'fc2.b': _read_np_tensor('np/t_9.bias.npy'),
            'fc2.w': _read_np_tensor('np/t_9.weight.npy'),
        }
    else:
        d = {
            'cn1.b': _read_np_tensor('np/t_0.0.bias.txt'),
            'cn1.k': _read_np_tensor('np/t_0.0.weight.txt'),
            'cn2.b': _read_np_tensor('np/t_3.0.bias.txt'),
            'cn2.k': _read_np_tensor('np/t_3.0.weight.txt'),
            'fc1.b': _read_np_tensor('np/t_7.0.bias.txt'),
            'fc1.w': _read_np_tensor('np/t_7.0.weight.txt'),
            'fc2.b': _read_np_tensor('np/t_9.bias.txt'),
            'fc2.w': _read_np_tensor('np/t_9.weight.txt'),
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


def read_np_keras(binary=True, target_dtype=None):
    if binary:
        d = {
            'cn1.b': _read_np_tensor('np/k_cn1.bias.npy'),
            'cn1.k': _read_np_tensor('np/k_cn1.weight.npy'),
            'cn2.b': _read_np_tensor('np/k_cn2.bias.npy'),
            'cn2.k': _read_np_tensor('np/k_cn2.weight.npy'),
            'fc1.b': _read_np_tensor('np/k_fc1.bias.npy'),
            'fc1.w': _read_np_tensor('np/k_fc1.weight.npy'),
            'fc2.b': _read_np_tensor('np/k_fc2.bias.npy'),
            'fc2.w': _read_np_tensor('np/k_fc2.weight.npy'),
        }
    else:
        d = {
            'cn1.b': _read_np_tensor('np/k_0.0.bias.txt'),
            'cn1.k': _read_np_tensor('np/k_0.0.weight.txt'),
            'cn2.b': _read_np_tensor('np/k_3.0.bias.txt'),
            'cn2.k': _read_np_tensor('np/k_3.0.weight.txt'),
            'fc1.b': _read_np_tensor('np/k_7.0.bias.txt'),
            'fc1.w': _read_np_tensor('np/k_7.0.weight.txt'),
            'fc2.b': _read_np_tensor('np/k_9.bias.txt'),
            'fc2.w': _read_np_tensor('np/k_9.weight.txt'),
        }

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


def perform_real_quant(weight_dict,
                       in_bits: np.ndarray, in_frac: np.ndarray,
                       w_bits: np.ndarray, w_frac: np.ndarray,
                       out_bits: np.ndarray, out_frac: np.ndarray,
                       activations_signed: np.ndarray,
                       additions=np.ndarray([16, 32, 1568, 32]),
                       traget_dtype=np.int32):
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

    # Use short notations
    ia_b = in_bits
    ia_f = in_frac
    w_b = w_bits
    w_f = w_frac
    oa_b = out_bits
    oa_f = out_frac

    # Check if consistent: input2 must be output 1
    assert np.all(oa_b[:-1] == ia_b[1:])
    assert np.all(oa_f[:-1] == ia_f[1:])

    # Temporary bits and fractions while adding (for bias)
    t_b = ia_b + w_b
    t_f = ia_f + w_f
    shift = t_f - oa_f

    # v = Q * 2^-m
    # Q = v * 2^m

    # Scaling for weights
    bias_max = 2.0 ** (t_b - 1) - 1
    bias_min = -2.0 ** (t_b - 1)
    bias_scale = 1 / 2 ** t_f

    w_max = 2.0 ** (w_bits - 1) - 1
    w_min = -2.0 ** (w_bits - 1)
    w_scale = 1 / 2 ** w_f

    out_max = np.zeros_like(out_bits)
    out_min = np.zeros_like(out_bits)
    out_scale = np.zeros_like(out_bits)

    for i in range(len(out_bits)):
        if activations_signed[i]:
            out_max[i] = 2.0 ** (oa_b[i] - 1) - 1
            out_min[i] = -2.0 ** (oa_b[i] - 1)
            out_scale[i] = 1 / 2 ** oa_f[i]
        else:
            out_max[i] = 2.0 ** (oa_b[i]) - 1
            out_min[i] = 0
            out_scale[i] = 1 / 2 ** oa_f[i]


    options = {
        'input_bits': ia_b,
        'input_frac': ia_f,
        'output_bits': oa_b,
        'output_frac': oa_f,
        'weight_bits': w_b,
        'weight_frac': w_f,
        'w_max': w_max,
        'w_min': w_min,
        'w_scale': w_scale,
        'bias_max': bias_max,
        'bias_min': bias_min,
        'bias_scale': bias_scale,
        'out_max': out_max,
        'out_min': out_min,
        'out_max_f': out_max * out_scale,
        'out_min_f': out_min * out_scale,
        'out_scale': out_scale,
        'shifts': shift
    }

    # ToDo: This becomes a bit hacky
    wi = 0
    bi = 0
    d_out = {}
    for i, (key, value) in enumerate(weight_dict.items()):
        # check key if it is weight or bias
        if key.endswith('.b'):
            w = np.clip(value / bias_scale[bi], a_min=bias_min[bi], a_max=bias_max[bi]).round().astype(traget_dtype)
            bi += 1
        else:
            w = np.clip(value / w_scale[wi], a_min=w_min[wi], a_max=w_max[wi]).round().astype(traget_dtype)
            wi += 1
        # Those are now ints, convert back to floats
        d_out[key] = w
    return d_out, shift, options


def quant2float(qweights, options):
    w_scale = options['w_scale']
    bias_scale = options['bias_scale']

    wi = 0
    bi = 0
    d_out = {}
    for i, (key, value) in enumerate(qweights.items()):
        # check key if it is weight or bias
        if key.endswith('.b'):
            w = value * bias_scale[bi]
            bi += 1
        else:
            w = value * w_scale[wi]
            wi += 1
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

    a_max = 2.0 ** (value_bits - 1) - 1
    a_min = -2.0 ** (value_bits - 1)
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
    our_net = EggNet.LeNet(reshape_torch=from_torch)
    our_net.cn1.weights = qweights['cn1.k']
    our_net.cn1.bias = qweights['cn1.b']
    our_net.cn2.weights = qweights['cn2.k']
    our_net.cn2.bias = qweights['cn2.b']
    our_net.fc1.weights = qweights['fc1.w']
    our_net.fc1.bias = qweights['fc1.b']
    our_net.fc2.weights = qweights['fc2.w']
    our_net.fc2.bias = qweights['fc2.b']
    return our_net


def init_fake_network_from_weights(qweights, shift, options):
    our_net = EggNet.FpiLeNet(qweights, shifts=shift, options=options, real_quant=False)
    return our_net


def init_quant_network_from_weights(qweights, shift, options):
    our_net = EggNet.FpiLeNet(qweights, shifts=shift, options=options, real_quant=True)
    return our_net


def evaluate_network_full(batch_size, network, train_images, train_labels,
                          images_as_int=False, n_batches=None, intermediates=False):
    i = 0
    total_correct = 0

    confusion_matrix = np.zeros(shape=(10, 10))
    INTERESTING_LAYER_INDICES = (1, 3, 6, 7)
    y_layers_out = None

    while i < train_images.shape[0]:

        if images_as_int:
            x = train_images[i:i + batch_size].astype(np.int32)
        else:
            x = train_images[i:i + batch_size] / 255.0

        y_ = train_labels[i:i + batch_size]
        y, y_layers = network.forward_intermediate(x)

        if intermediates:
            if y_layers_out is None:
                y_layers_out = y_layers
            else:
                for ix in INTERESTING_LAYER_INDICES:
                    y_layers_out[ix] = np.concatenate((y_layers_out[ix], y_layers[ix]), axis=0)
        y = y.argmax(-1)

        # ToDo: Might be a faster way
        for pred, label in zip(y, y_):
            confusion_matrix[pred, label] = confusion_matrix[pred, label] + 1

        total_correct += np.sum(y == y_)
        i += batch_size

        if n_batches is not None and i / batch_size > n_batches:
            break

    accuracy = total_correct / train_images.shape[0]

    if intermediates:
        # Remove other layers
        y_layers_out = [y_layers_out[i] for i in INTERESTING_LAYER_INDICES]
        return accuracy, confusion_matrix, y_layers_out
    else:
        return accuracy, confusion_matrix


def evaluate_network(batch_size, network, train_images, train_labels):
    a, _, _ = evaluate_network_full(batch_size, network, train_images, train_labels)
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


def plot_convolutions(kernel, nrows=4, c_out=None, order='keras', title='Convolution Kernels', target_names=None,
                      normalize=True,
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

    fh, fw, ci, co = kernel.shape

    ncols = ci // nrows + 1

    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(8, 6))

    for c_out in co:
        for r in range(nrows):
            axes.set_ylabel('')
            for c in range(ncols):
                axes[r, c].matshow(np.mean(kernel[:, :, :, c_out], axis=-1))
                plt.show()


def plot_kernel_density():
    """

    Check out:
    https://stackoverflow.com/questions/30145957/plotting-2d-kernel-density-estimation-with-python
    Returns:

    """
    pass
