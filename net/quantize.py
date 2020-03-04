import os

import numpy as np

import NeuralNetwork
from util import read_np_torch, perform_real_quant, init_network_from_weights, evaluate_network, perform_fake_quant


def main():
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

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

    # Check network performance (might take some time)
    # Accuracy should be at least 90% even with quantization
    # accuracy = evaluate_network(batch_size, our_net, test_images, test_labels)
    # qaccuracy = evaluate_network(batch_size, our_quant_net, test_images, test_labels)
    # print("Network:             ", accuracy)
    # print("Quantised Network:   ", qaccuracy)

    for key, value in qweights.items():
        filename = os.path.join('final_weights', key)
        x_ = value.flatten()

        np.savetxt(fname=filename + '.txt', X=x_, fmt='%i', header=str(value.shape))
        np.save(file=filename, arr=value)


if __name__ == '__main__':
    main()
