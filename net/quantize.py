import os

import numpy as np

import NeuralNetwork
from util import read_np_torch, perform_real_quant, init_network_from_weights, evaluate_network, perform_fake_quant, \
    plot_confusion_matrix, evaluate_network_full


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
