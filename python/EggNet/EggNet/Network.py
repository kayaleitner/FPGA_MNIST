import os
from typing import List

import numpy as np

import EggNet


def check_layers(list_of_layers):
    """

    :type list_of_layers: List[Layer]
    """

    for i in range(1, len(list_of_layers)):
        l1 = list_of_layers[i - 1]
        l2 = list_of_layers[i]

        # Get the shapes and convert to numpy arrays
        l1_shape_out = np.array(l1.get_output_shape())
        l2_shape_in = np.array(l2.get_input_shape())

        if l2_shape_in.ndim == 0:
            # Zero dimension layer accepts every input
            continue

        if not (l1_shape_out.ndim == l2_shape_in.ndim):
            raise ValueError(
                "Output of layer {} dim({}) but input of layer {} has dim({})".format(i, len(l1_shape_out), i + 1,
                                                                                      len(l2_shape_in)))
        if not np.all(l1_shape_out == l2_shape_in):
            raise ValueError(
                "Layer {} has dimensions [{}] but layer {} has [{}]".format(i, l1_shape_out, i + 1, l2_shape_in))


def metric_accuracy(y1: np.ndarray, y2: np.ndarray, metric_state):
    metric_state.append(np.sum(y1.argmax(-1) == y2.argmax(-1)))
    return metric_state


class Network:

    def __init__(self, list_of_layers):
        """

        :type list_of_layers: List[Layer]
        """
        # check_layers(list_of_layers)

        self.layers = list_of_layers

    def __call__(self, *args, **kwargs):
        return self.forward(*args, **kwargs)

    def eval(self, dataset, metric=metric_accuracy, metric_state=None):
        if metric_state is None:
            metric_state = []
        for x, y in dataset:
            y_ = self.forward(x)
            metric(y, y_, metric_state)
        return metric_state

    def eval_accuracy(self, dataset):
        hist = []
        for x, y in dataset:
            y_ = self.forward(x)
            hist.append(np.sum(y_.argmax(-1) == y.argmax(-1)))
        return np.mean(hist)

    def forward(self, inputs, **kwargs):
        z, _ = self.forward_intermediate(inputs)
        return z

    def forward_intermediate(self, inputs):
        z = inputs
        zs = []
        for ix, layer in enumerate(self.layers):
            z = layer(z)
            zs.append(z)
        return z, zs

    def backprop(self, x, y_):
        y, zs = self.forward_intermediate(x)
        loss = EggNet.mean_squared_error(y, y_)
        delta = y - y_
        deltas = []
        for layer in self.layers:
            delta = layer.backprop(delta)
            deltas.append(delta)
            layer.update_weights(delta)

    def __copy__(self):
        net = Network(list_of_layers=[layer.deepcopy() for layer in self.layers])
        return net

    def cast(self, new_dtype: np.dtype):

        # Only cast to other floating point types
        if not (new_dtype in (np.float, np.float32, np.float16)):
            # for integer types take special considerations
            return self.quantize_network(network=self, target_dype=new_dtype)
        else:
            layers = [layer.deepcopy() for layer in self.layers]

            for layer in layers:
                layer.cast(new_dtype)

            net = Network(list_of_layers=layers)
            return net

    def quantize_network(self, new_dtype, max_value, min_value,
                         full_layer_quant_type,
                         conv_layer_quant_type):
        """
        Quantizes the weights and activations of the network and returns a copy

        A Survey on Methods and Theories of Quantized Neural Networks,
        Yunhui Guo
        University of California, San Diego,
        arXiv:1808.04752v2, 2018

        Args:
            min_value:
            max_value:
            target_dype:
            full_layer_quant_type:
            conv_layer_quant_type:

        Returns:

        """

        layers_copy = [layer.deepcopy() for layer in self.layers]
        for layer in layers_copy:
            layer.quantize_layer(target_type=new_dtype, max_value=max_value, min_value=min_value)
        net = Network(list_of_layers=layers_copy)
        return net

    def get_network_weights(self):
        weights_dict = {}

        for i, layer in enumerate(self.layers):
            if isinstance(layer, EggNet.FullyConnectedLayer):
                weights_dict["{}:FC:W".format(i)] = layer.weights
                weights_dict["{}:FC:b".format(i)] = layer.bias
            elif isinstance(layer, EggNet.Conv2dLayer):
                weights_dict["{}:Conv2D:kernel".format(i)] = layer.weights
                weights_dict["{}:Conv2D:b".format(i)] = layer.bias

        return weights_dict

    def evaluate_network_accuracy(self, batch_size, train_images, train_labels,
                                  images_as_int=False, n_batches=None, intermediates=False):
        i = 0
        total_correct = 0

        if n_batches is None:
            N = train_images.shape[0]
        else:
            N = n_batches * batch_size

        while i < N - 1:

            if images_as_int:
                x = train_images[i:i + batch_size].astype(np.int32)
            else:
                x = train_images[i:i + batch_size] / 255.0

            y_ = train_labels[i:i + batch_size]
            y = self.forward(x)
            y = y.argmax(-1)

            total_correct += np.sum(y == y_)
            i += batch_size

        accuracy = total_correct / N

        return accuracy


class LeNet(Network):
    """
    Implementation of LeNet with own Neural Network Library
    """

    CN1_SHAPE = (1, 16, 3, 3)
    CN2_SHAPE = (16, 32, 3, 3)
    FC1_SHAPE = (32 * 7 * 7, 32)
    FC2_SHAPE = (32, 10)

    def __init__(self, dtype=np.float32, reshape_torch=False):
        """
        Initializes a new LeNet inspired network
        Args:
            dtype: Datatype to be used
            reshape_torch: set this, if the training parameters came from Pytorch which requires a custom reshape
        """
        self.reshape_torch = reshape_torch
        r1 = EggNet.ReshapeLayer(newshape=[-1, 28, 28, 1])
        cn1 = EggNet.Conv2dLayer(in_channels=1, out_channels=16, kernel_size=3, activation='relu',
                                 dtype=np.float32)  # [? 28 28 16]
        mp1 = EggNet.MaxPool2dLayer(size=2)  # [? 14 14 16]
        cn2 = EggNet.Conv2dLayer(in_channels=16, out_channels=32, kernel_size=3, activation='relu')  # [? 14 14 32]
        mp2 = EggNet.MaxPool2dLayer(size=2)  # [?  7  7 32]
        r2 = EggNet.FlattenLayer()
        fc1 = EggNet.FullyConnectedLayer(input_size=32 * 7 * 7, output_size=32, activation='relu', dtype=np.float32)
        fc2 = EggNet.FullyConnectedLayer(input_size=32, output_size=10, activation='softmax')

        # Store a reference to each layer
        self.r1 = r1
        self.cn1 = cn1
        self.mp1 = mp1
        self.cn2 = cn2
        self.mp2 = mp2
        self.r2 = r2
        self.fc1 = fc1
        self.fc2 = fc2
        self.lenet_layers = [r1, cn1, mp1, cn2, mp2, r2, fc1, fc2]

        super(LeNet, self).__init__(self.lenet_layers)

    @staticmethod
    def init_npz(npz_path: str):
        qweights = np.load(npz_path)
        return init_network_from_weights(weights=qweights)

    @staticmethod
    def get_keras_model(save_dir=None):
        import keras

        if save_dir is not None:
            return EggNet.util.open_keras_model(save_dir=save_dir)

        IMG_HEIGHT, IMG_WIDTH = 28, 28
        (x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
        x_train, x_test = x_train / 255.0, x_test / 255.0

        # Define Constraints (useful for quantization)
        kernel_constraint = keras.constraints.max_norm(max_value=1)

        """
        Define the model here

        Changes:
        - Added initial BatchNorm: Makes sense to distribute the input image data evenly around zero
        - Increased value of dropout layer to .5 in first fully connected layer 
        - Removed bias from conv layers
        """
        model = keras.models.Sequential(name="KerasEggNet", layers=[
            # Hack: Reshape the image to 1D to make the Keras BatchNorm layer work
            keras.layers.Reshape(target_shape=(IMG_HEIGHT, IMG_WIDTH, 1), input_shape=(IMG_HEIGHT, IMG_WIDTH)),
            keras.layers.Conv2D(16, kernel_size=3, padding='same', activation='linear', use_bias=True,
                                kernel_constraint=kernel_constraint),
            keras.layers.Dropout(0.2),
            keras.layers.ReLU(),
            keras.layers.MaxPooling2D(),
            keras.layers.Conv2D(32, kernel_size=3, padding='same', activation='linear', use_bias=True,
                                kernel_constraint=kernel_constraint),
            keras.layers.Dropout(0.2),
            keras.layers.ReLU(),
            keras.layers.MaxPooling2D(),
            keras.layers.Flatten(),
            keras.layers.Dense(32, activation='linear', kernel_constraint=kernel_constraint),
            keras.layers.Dropout(0.2),
            keras.layers.ReLU(),
            keras.layers.Dense(10, activation='softmax', kernel_constraint=kernel_constraint)
        ])
        # You must install pydot and graphviz for `pydotprint` to work.
        # keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)
        model.compile(optimizer='adam',
                      loss='sparse_categorical_crossentropy',
                      metrics=['accuracy'])
        model.build()
        return model

    @staticmethod
    def load_from_files(save_dir):
        """
        Loads the LeNet with the files specified in the passed directory
        Args:
            save_dir:

        Returns:

        """

        model = LeNet()
        model.cn1.kernel = np.loadtxt(os.path.join(save_dir, 'w0.txt')).reshape(model.cn1.kernel.shape)
        model.cn1.b = np.loadtxt(os.path.join(save_dir, 'w1.txt')).reshape(model.cn1.b.shape)
        model.cn2.kernel = np.loadtxt(os.path.join(save_dir, 'w2.txt')).reshape(model.cn2.kernel.shape)
        model.cn2.b = np.loadtxt(os.path.join(save_dir, 'w3.txt')).reshape(model.cn2.b.shape)
        model.fc1.W = np.loadtxt(os.path.join(save_dir, 'w4.txt')).reshape(model.fc1.W.shape)
        model.fc1.b = np.loadtxt(os.path.join(save_dir, 'w5.txt')).reshape(model.fc1.b.shape)
        model.fc2.W = np.loadtxt(os.path.join(save_dir, 'w6.txt')).reshape(model.fc2.W.shape)
        model.fc2.b = np.loadtxt(os.path.join(save_dir, 'w7.txt')).reshape(model.fc2.b.shape)

        return model

    @staticmethod
    def load_from_files_generic(save_dir):
        """

        Args:
            save_dir:

        Returns:

        """
        for root, dirs, files in os.walk(top=save_dir):
            txt_files = filter(lambda s: s.endswith('.txt'), files)
            for i, weight_file in enumerate(txt_files):

                # Get shape
                with open(weight_file) as f:
                    init_line = f.readline()
                    # assume the first line is a comment
                    assert init_line[0] == '#'
                    p1 = init_line.find('(')
                    p2 = init_line.find(')')
                    dims = [int(ds) for ds in init_line[p1:p2].split(sep=',')]
                    # dims is tuple now
                    if len(dims) == 4:
                        # conv layer
                        pass
                    elif len(dims) == 2:
                        # fully connected
                        pass
                    elif len(dims) == 1:
                        # bias
                        pass

                weight_loaded = np.loadtxt(weight_file)
                # ToDo: Finish this up by mapping the weights to the right layer


def _lenet_to_dict(network: LeNet):
    d = {
        'conv1_k': network.cn1.kernel,
        'conv1_b': network.cn1.bias,
        'conv2_k': network.cn2.kernel,
        'conv2_b': network.cn2.bias,
        'fc1_w': network.fc1.weights,
        'fc1_b': network.fc1.bias,
        'fc2_w': network.fc2.weights,
        'fc2_b': network.fc2.bias
    }

    return d


def _get_layers(weights_dict, target_bits, fraction_bits):
    assert target_bits > fraction_bits

    value_bits = target_bits - fraction_bits

    a_max = 2 ** (value_bits - 1) - 1
    a_min = -2 ** (value_bits - 1)
    scale = 1 / 2 ** value_bits

    c1_k1 = weights_dict['conv1_k']
    c1_b1 = weights_dict['conv1_b']
    c2_k2 = weights_dict['conv2_k']
    c2_b2 = weights_dict['conv2_b']

    fc1_w = weights_dict['fc1_w']
    fc1_b = weights_dict['fc1_b']
    fc2_w = weights_dict['fc2_w']
    fc2_b = weights_dict['fc2_b']

    # ni3 = nn_lenet_f64.fc1.input_size
    # no3 = nn_lenet_f64.fc1.output_size
    # ni4 = nn_lenet_f64.fc2.input_size
    # no4 = nn_lenet_f64.fc2.output_size
    ni3, no3 = fc1_w.shape
    ni4, no4 = fc2_w.shape

    qk1 = np.clip(c1_k1 / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qb1 = np.clip(c1_b1 / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qk2 = np.clip(c2_k2 / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qb2 = np.clip(c2_b2 / scale, a_max=a_max, a_min=a_min).astype(np.int8)

    qw3 = np.clip(fc1_w / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qb3 = np.clip(fc1_b / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qw4 = np.clip(fc2_w / scale, a_max=a_max, a_min=a_min).astype(np.int8)
    qb4 = np.clip(fc2_b / scale, a_max=a_max, a_min=a_min).astype(np.int8)

    dfrac_bits = 2 * fraction_bits

    layers = [

        EggNet.ReshapeLayer(newshape=(-1, 28, 28, 1)),
        EggNet.Conv2dLayer(in_channels=1, out_channels=3, kernel_size=3, kernel_init_weights=qk1,
                           bias_init_weights=qb1, use_bias=True),
        EggNet.ShiftLayer(target_bits=target_bits, target_frac_bits=fraction_bits, source_bits=16,
                          source_frac_bits=dfrac_bits),
        EggNet.ReluActivationLayer(),
        EggNet.MaxPool2dLayer(),
        EggNet.Conv2dLayer(in_channels=3, out_channels=9, kernel_size=3, kernel_init_weights=qk2,
                           bias_init_weights=qb2, use_bias=True),
        EggNet.ShiftLayer(target_bits=target_bits, target_frac_bits=fraction_bits, source_bits=16,
                          source_frac_bits=dfrac_bits),
        EggNet.ReluActivationLayer(),
        EggNet.MaxPool2dLayer(),
        EggNet.FlattenLayer(),
        EggNet.BreakpointLayer(enabled=False),
        EggNet.FullyConnectedLayer(input_size=ni3, output_size=no3, dtype=np.int16, weights=qw3, bias=qb3),
        EggNet.ShiftLayer(target_bits=target_bits, target_frac_bits=fraction_bits, source_bits=16,
                          source_frac_bits=dfrac_bits),
        EggNet.ReluActivationLayer(),
        EggNet.FullyConnectedLayer(input_size=ni4, output_size=no4, dtype=np.int16, weights=qw4, bias=qb4),
        EggNet.ShiftLayer(target_bits=target_bits, target_frac_bits=fraction_bits, source_bits=16,
                          source_frac_bits=dfrac_bits),
        EggNet.SoftmaxLayer()
    ]

    return layers


class FpiLeNet(Network):

    def __init__(self, weights, options, shifts, real_quant=False):
        # Check input

        r1 = EggNet.ReshapeLayer(newshape=[-1, 28, 28, 1])
        cn1 = EggNet.Conv2dLayer(in_channels=1, out_channels=16, kernel_size=3, activation='relu',
                                 dtype=np.float32)  # [? 28 28 16]
        mp1 = EggNet.MaxPool2dLayer(size=2)  # [? 14 14 16]
        cn2 = EggNet.Conv2dLayer(in_channels=16, out_channels=32, kernel_size=3, activation='relu')  # [? 14 14 32]
        mp2 = EggNet.MaxPool2dLayer(size=2)  # [?  7  7 32]
        r2 = EggNet.FlattenLayer()
        fc1 = EggNet.FullyConnectedLayer(input_size=32 * 7 * 7, output_size=32, activation='relu', dtype=np.float32)

        if real_quant:
            fc2 = EggNet.FullyConnectedLayer(input_size=32, output_size=10, activation=None)
        else:
            fc2 = EggNet.FullyConnectedLayer(input_size=32, output_size=10, activation='softmax')

        if real_quant:
            rs1 = EggNet.SimpleShiftLayer(shift=shifts[0], a_min=options['out_min'][0], a_max=options['out_max'][0])
            rs2 = EggNet.SimpleShiftLayer(shift=shifts[1], a_min=options['out_min'][1], a_max=options['out_max'][1])
            rs3 = EggNet.SimpleShiftLayer(shift=shifts[2], a_min=options['out_min'][2], a_max=options['out_max'][2])
            rs4 = EggNet.SimpleShiftLayer(shift=shifts[3], a_min=options['out_min'][3], a_max=options['out_max'][3])
        else:
            # scales = 2.0 ** (-shifts)
            scales = np.ones(shape=(4,))
            rs1 = EggNet.ScaleLayer(scale=scales[0], a_min=options['out_min_f'][0], a_max=options['out_max_f'][0])
            rs2 = EggNet.ScaleLayer(scale=scales[1], a_min=options['out_min_f'][1], a_max=options['out_max_f'][1])
            rs3 = EggNet.ScaleLayer(scale=scales[2], a_min=options['out_min_f'][2], a_max=options['out_max_f'][2])
            rs4 = EggNet.ScaleLayer(scale=scales[3], a_min=options['out_min_f'][3], a_max=options['out_max_f'][3])
        self.rs1 = rs1
        self.rs2 = rs2
        self.rs3 = rs3
        self.rs4 = rs4

        # Store a reference to each layer
        self.r1 = r1
        self.cn1 = cn1
        self.mp1 = mp1
        self.cn2 = cn2
        self.mp2 = mp2
        self.r2 = r2
        self.fc1 = fc1
        self.fc2 = fc2

        self.cn1.weights = weights['cn1.k']
        self.cn1.bias = weights['cn1.b']
        self.cn2.weights = weights['cn2.k']
        self.cn2.bias = weights['cn2.b']
        self.fc1.weights = weights['fc1.w']
        self.fc1.bias = weights['fc1.b']
        self.fc2.weights = weights['fc2.w']
        self.fc2.bias = weights['fc2.b']

        self.lenet_layers = [r1,
                             cn1, mp1, rs1,
                             cn2, mp2, rs2,
                             r2,
                             fc1, rs3,
                             fc2, rs4]

        super(FpiLeNet, self).__init__(self.lenet_layers)

    @staticmethod
    def init_npz(npz_path: str, config_path: str):
        import json
        qweights = np.load(npz_path)

        with open(config_path, "r") as f:
            options = json.load(f)
        shift = options['shifts']
        return init_quant_network_from_weights(qweights, shift=shift, options=options)


def init_network_from_weights(weights, from_torch=False):
    """
    Initializes a new network from passed weight dictionary.

    Args:
        weights: The network weight dict
        from_torch: Can be set to true if the weights are from torch and needs additional shuffling

    Returns:
        The initialized network
    """
    our_net = LeNet(reshape_torch=from_torch)
    our_net.cn1.weights = weights['cn1.k']
    our_net.cn1.bias = weights['cn1.b']
    our_net.cn2.weights = weights['cn2.k']
    our_net.cn2.bias = weights['cn2.b']
    our_net.fc1.weights = weights['fc1.w']
    our_net.fc1.bias = weights['fc1.b']
    our_net.fc2.weights = weights['fc2.w']
    our_net.fc2.bias = weights['fc2.b']
    return our_net


def init_fake_network_from_weights(qweights, shift, options):
    """

    Args:
        qweights:
        shift:
        options:

    Returns:

    """
    our_net = FpiLeNet(qweights, shifts=shift, options=options, real_quant=False)
    return our_net


def init_quant_network_from_weights(qweights, shift, options):
    """

    Args:
        qweights:
        shift:
        options:

    Returns:

    """
    our_net = FpiLeNet(qweights, shifts=shift, options=options, real_quant=True)
    return our_net
