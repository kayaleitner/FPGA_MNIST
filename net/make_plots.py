import os
import numpy as np

from lib.convnet_drawer.matplotlib_util import save_model_to_file
from util import read_np_torch, plot_convolutions


def main():

    weights = read_np_torch(ordering='BHWC', target_dtype=np.float32)

    # make_conv_net_plot()

    # plot_convolutions(weights['cn1.k'], nrows=1)
    plot_convolutions(weights['cn2.k'], nrows=16)



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


if __name__ == '__main__':
    main()
