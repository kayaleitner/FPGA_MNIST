from __future__ import print_function, division

import os
import numpy as np
import torch
import torch.quantization
import torch.nn as nn
import torch.optim
import torchvision
from torch.utils.data import DataLoader

from extract_net_parameters import load_torch, read_np_torch
from train_torch import evaluate, prepare_datasets, train_network, LEARNING_RATE, evaluate_labels
from train_torch import LeNetV2, ConvBN, LinearRelu, Flatten, LayerActivations

# Import the own made network
import NeuralNetwork
import NeuralNetwork.Ext.NeuralNetworkExtension as nnext


class FixedConvLayer(torch.nn.Module):

    def __init__(self, kernel, bias):
        super(FixedConvLayer, self).__init__()
        self.kernel = kernel
        self.bias = bias

        # self.requires_grad(False)

    def forward(self, x):
        with torch.no_grad():
            x_ = np.moveaxis(x.numpy(), 1, 3)
            y_np = nnext.conv2d(x_, self.kernel, stride=1) + self.bias
            y_ = np.moveaxis(y_np, 3, 1)
            return torch.from_numpy(y_)
            # return nnext.conv2d_3x3(x, self.kernel) + self.bias


def perform_fake_quant(weight_dict, target_bits, frac_bits, target_dtype=np.float64):
    """
    Performs fake quantization, meaning all values will be rounded to
    their expression
    Args:
        weight_dict:
        target_bits:
        frac_bits:

    Returns:

    """

    assert target_bits > frac_bits

    value_bits = target_bits - frac_bits

    a_max = 2 ** (value_bits - 1) - 1
    a_min = -2 ** (value_bits - 1)
    scale = 1 / 2 ** value_bits

    d_out = {}
    for key, value in weight_dict.items():
        # round weights
        w = np.clip(value / scale, a_min=a_min, a_max=a_max).round()

        # Those are now ints, convert back to floats
        w = (w * scale).astype(dtype=target_dtype)

        d_out[key] = w

    return d_out


def main():
    net = load_torch(filepath='torch/LeNet.pth')
    # qnet = load_torch(filepath='torch/QLeNet.pth')
    testloader, trainloader = prepare_datasets()
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=LEARNING_RATE)

    # Read the weights in keras convention
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

    # Training in torch happens with np.float32
    qweights = perform_fake_quant(weight_dict=weights, target_bits=8, frac_bits=4, target_dtype=np.float32)

    # Compare with our net
    mnist = NeuralNetwork.Reader.MNIST(folder_path='/tmp/mnist/')
    train_images = mnist.train_images()
    train_labels = mnist.train_labels()
    our_net = NeuralNetwork.nn.Network.LeNet()
    our_net.cn1.weights = weights['cn1.k']
    our_net.cn1.bias = weights['cn1.b']
    our_net.cn2.weights = weights['cn2.k']
    our_net.cn2.bias = weights['cn2.b']
    our_net.fc1.weights = weights['fc1.w']
    our_net.fc1.bias = weights['fc1.b']
    our_net.fc2.weights = weights['fc2.w']
    our_net.fc2.bias = weights['fc2.b']

    img_batch = train_images[0:50, :, :] / 255
    lbl_batch = train_labels[0:50]
    lbl_our_net, y_our_net_intermediate = our_net.forward_intermediate(img_batch)
    lbl_our_net = lbl_our_net.argmax(1)

    net.eval()
    LayerActivations(net, layer_num=0, validate_func=lambda x,y,z: LayerActivations.torch_convolution_check(x,y,z,kernel=weights['cn1.k']))
    LayerActivations(net, layer_num=3, validate_func=lambda x,y,z: LayerActivations.torch_convolution_check(x,y,z,kernel=weights['cn2.k']))
    lbls = evaluate_labels(net, criterion, data_loader=testloader)
    (top1, top5) = evaluate(net, criterion, data_loader=testloader)


    fixed_conv_model = nn.Sequential(
        FixedConvLayer(kernel=weights['cn1.k'], bias=weights['cn1.b']),
        nn.MaxPool2d(kernel_size=2, stride=2),
        FixedConvLayer(kernel=weights['cn2.k'], bias=weights['cn2.b']),
        nn.MaxPool2d(kernel_size=2, stride=2),
        Flatten(),
        # LinearRelu(in_features=qweights['fc1.w'].shape[1], out_features=qweights['fc1.w'].shape[0]),
        LinearRelu.init_with_weights(w=qweights['fc1.w'], b=qweights['fc1.b']),
        nn.Dropout(p=0.25),
        # LinearRelu(in_features=qweights['fc2.w'].shape[1], out_features=10),
        LinearRelu.init_with_weights(w=qweights['fc2.w'], b=qweights['fc2.b']),
        nn.Softmax(dim=1)
    )

    train_network(fixed_conv_model, 1, criterion=criterion, optimizer=optimizer, trainloader=trainloader)
    fixed_conv_model.eval()
    (top1, top5) = evaluate(fixed_conv_model, criterion, data_loader=testloader)
    print(top1)

    (top1, top5) = evaluate(net, criterion, testloader)


if __name__ == '__main__':
    main()
