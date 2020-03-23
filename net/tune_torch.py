from __future__ import print_function, division

import numpy as np
import torch
import torch.quantization
import torch.nn as nn
import torch.optim

from util import read_np_torch, evaluate_network
from train_torch import evaluate, prepare_datasets, LEARNING_RATE, evaluate_labels, load_torch, \
    save_torch_model_weights
from train_torch import LinearRelu, Flatten
from debug import LayerActivations

# Import the own made network
from EggNet import NeuralNetwork
import EggNet.NeuralNetwork.Ext.NeuralNetworkExtension as nnext


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


def main():


    net = load_torch(filepath='torch/LeNet.pth')
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

    save_torch_model_weights(net)


    # qnet = load_torch(filepath='torch/QLeNet.pth')
    testloader, trainloader = prepare_datasets()
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=LEARNING_RATE)

    net.eval()
    (top1, top5) = evaluate(net, criterion, data_loader=testloader)
    print("top1 performance: ", top1)

    # Read the weights in keras convention
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)
    weights_torch = read_np_torch(ordering='BCHW', target_dtype=np.float32)

    # Training in torch happens with np.float32
    #qweights = perform_fake_quant(weight_dict=weights, target_bits=5, frac_bits=3, target_dtype=np.float32)
    #qweights_torch = perform_fake_quant(weight_dict=weights_torch, target_bits=8, frac_bits=4, target_dtype=np.float32)

    # Compare with our net
    mnist = NeuralNetwork.Reader.MNIST(folder_path='/tmp/mnist/')
    test_images = mnist.test_images()
    test_labels = mnist.test_labels()
    # our_net = init_network_from_weights(qweights, from_torch=True)

    batch_size = 50
    accuracy = evaluate_network(batch_size, our_net, test_images, test_labels)
    print("Accuracy: ", accuracy)

    net.eval()
    # Reshape images
    #img_bach_torch = np.reshape(img_batch, newshape=(-1, 1, 28, 28)).astype(np.float32)
    #_imshow(img_bach_torch, mode='torch')
    #lbl_torch = net(torch.from_numpy(img_bach_torch))
    lbl_torch = lbl_torch.topk(1)[1].numpy().flatten()  # TODO Maybe simplify this expression a bit

    # To check the output of the fully connected layers against our net
    LayerActivations(net, layer_num=0, validate_func=LayerActivations)
    LayerActivations(net, layer_num=4, validate_func=None)
    LayerActivations(net, layer_num=7, validate_func=None)
    LayerActivations(net, layer_num=9, validate_func=None)

    lbls = evaluate_labels(net, criterion, data_loader=testloader)
    (top1, top5) = evaluate(net, criterion, data_loader=testloader)

    fixed_conv_model = nn.Sequential(
        FixedConvLayer(kernel=weights['cn1.k'], bias=weights['cn1.b']),
        nn.MaxPool2d(kernel_size=2, stride=2),
        FixedConvLayer(kernel=weights['cn2.k'], bias=weights['cn2.b']),
        nn.MaxPool2d(kernel_size=2, stride=2),
        Flatten(),
        # LinearRelu(in_features=qweights['fc1.w'].shape[1], out_features=qweights['fc1.w'].shape[0]),
        LinearRelu.init_with_weights(w=weights_torch['fc1.w'], b=weights_torch['fc1.b']),
        nn.Dropout(p=0.25),
        # LinearRelu(in_features=qweights['fc2.w'].shape[1], out_features=10),
        LinearRelu.init_with_weights(w=weights_torch['fc2.w'], b=weights_torch['fc2.b']),
        nn.Softmax(dim=1)
    )

    #train_network(fixed_conv_model, 1, criterion=criterion, optimizer=optimizer, trainloader=trainloader)
    #fixed_conv_model.eval()
    #(top1, top5) = evaluate(fixed_conv_model, criterion, data_loader=testloader)
    #print(top1)

    #(top1, top5) = evaluate(net, criterion, testloader)


if __name__ == '__main__':
    main()
