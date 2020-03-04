import os
import numpy as np

from lib.convnet_drawer.matplotlib_util import save_model_to_file
from util import read_np_torch, plot_convolutions
import matplotlib.pyplot as plt


def main():
    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

    # make_conv_net_plot()

    make_training_plots()

    # plot_convolutions(weights['cn1.k'], nrows=1)
    # plot_convolutions(weights['cn2.k'], nrows=16)


def make_conv_net_plot():
    from lib.convnet_drawer.convnet_drawer import Model, Conv2D, MaxPooling2D, Flatten, Dense
    # from lib.convnet_drawer.pptx_util import save_model_to_pptx
    import lib.convnet_drawer.config as config

    config.inter_layer_margin = 65
    config.channel_scale = 4 / 5

    model = Model(input_shape=(28, 28, 1))
    model.add(Conv2D(16, (3, 3), (1, 1), padding="same"))
    model.add(MaxPooling2D((2, 2)))
    model.add(Conv2D(32, (3, 3), padding="same"))
    model.add(MaxPooling2D((2, 2)))
    model.add(Flatten())
    model.add(Dense(32))
    model.add(Dense(10))
    model.save_fig(filename='images/network.svg')

    # save via matplotlib
    save_model_to_file(model, "images/network.png")
    # We dont need powerpoint
    # save_model_to_pptx(model, os.path.splitext(os.path.basename(__file__))[0] + ".pptx")


def make_training_plots():
    hist_acc = np.load('runs/history_accuracy.npy')
    hist_loss = np.load('runs/history_loss.npy')

    DATASET_LEN = 60 * 1000
    N = 50  # filter length

    x = hist_loss
    fig = plt.figure(figsize=(8, 6))
    plt.semilogy(x[:, 0] / DATASET_LEN, x[:, 1], label='Loss (Minibatch)')
    x_ = np.convolve(x[:, 1], np.ones((N,)) / N, mode='same')
    plt.semilogy(x[:-N, 0] / DATASET_LEN, x_[:-N], label='Running Mean, N=50')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.title('Training Loss')
    plt.legend()
    plt.show()
    fig.savefig('images/training_loss.png', dpi=300)

    x = hist_acc
    fig = plt.figure(figsize=(8, 6))
    plt.plot(x[:, 0] / DATASET_LEN, x[:, 1], label='Accuracy (Minibatch)')
    x_ = np.convolve(x[:, 1], np.ones((N,)) / N, mode='same')
    plt.plot(x[:-N, 0] / DATASET_LEN, x_[:-N], label='Running Mean, N=50')
    plt.xlabel('Epochs')
    plt.ylabel('Accuracy')
    plt.title('Network Accuracy')
    plt.legend()
    plt.show()
    fig.savefig('images/training_accuracy.png', dpi=300)


pass

if __name__ == '__main__':
    main()
