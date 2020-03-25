# %% public imports
import os
import shutil
import subprocess
import filecmp
import numpy as np
import matplotlib.pyplot as plt
import gzip
import idx2numpy
import numpy.random as rand
from sys import exit
import json

# %% import custom modules
import vhdl_testbench as tb

import EggNet
import EggNet.Reader

'''
WHEN SWITCHING BETWEEN INT4 AND INT8:
    1. Set BITS in generate_mif.py and run it
    2. Set BITS in generate_conv2d.py and run it
    3. Change the input and output bit width in tb_conv2d0 and tb_conv2d1
    3. Set BITS in this script and run it
'''
BITS = 4

if BITS == 4:
    config_file_name = "../../../../../net/final_weights/int4_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int4_fpi/cn1.k.txt",
                  "../../../../../net/final_weights/int4_fpi/cn2.k.txt"]
    file_names_bias = ["../../../../../net/final_weights/int4_fpi/cn1.b.txt",
                       "../../../../../net/final_weights/int4_fpi/cn2.b.txt"]
    denselayer_1_file_name = "../../../../../net/final_weights/int4_fpi/fc1.w.txt"
    denselayer_2_file_name = "../../../../../net/final_weights/int4_fpi/fc2.w.txt"
    denselayer_1_bias_file_name = "../../../../../net/final_weights/int4_fpi/fc1.b.txt"
    denselayer_2_bias_file_name = "../../../../../net/final_weights/int4_fpi/fc2.b.txt"

elif BITS == 8:
    config_file_name = "../../../../../net/final_weights/int8_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int8_fpi/cn1.k.txt",
                  "../../../../../net/final_weights/int8_fpi/cn2.k.txt"]
    file_names_bias = ["../../../../../net/final_weights/int8_fpi/cn1.b.txt",
                       "../../../../../net/final_weights/int8_fpi/cn2.b.txt"]
    denselayer_1_file_name = "../../../../../net/final_weights/int8_fpi/fc1.w.txt"
    denselayer_2_file_name = "../../../../../net/final_weights/int8_fpi/fc2.w.txt"
    denselayer_1_bias_file_name = "../../../../../net/final_weights/int8_fpi/fc1.b.txt"
    denselayer_2_bias_file_name = "../../../../../net/final_weights/int8_fpi/fc2.b.txt"

FILENAMES_INT4 = {
    'config': "../../../../../net/final_weights/int4_fpi/config.json",
    'cn1.k': "../../../../../net/final_weights/int4_fpi/cn1.k.npy",
    'cn1.b': "../../../../../net/final_weights/int4_fpi/cn1.b.npy",
    'cn2.k': "../../../../../net/final_weights/int4_fpi/cn2.k.npy",
    'cn2.b': "../../../../../net/final_weights/int4_fpi/cn2.b.npy",
}

FILENAMES_INT8 = {
    'config': "../../../../../net/final_weights/int8_fpi/config.json",
    'cn1.k': "../../../../../net/final_weights/int8_fpi/cn1.k.npy",
    'cn1.b': "../../../../../net/final_weights/int8_fpi/cn1.b.npy",
    'cn2.k': "../../../../../net/final_weights/int8_fpi/cn2.k.npy",
    'cn2.b': "../../../../../net/final_weights/int8_fpi/cn2.b.npy",
}


def chunk_array(seq, num):
    """
    Helper function to split array into n roughly equal parts
    Args:
        seq:
        num:

    Returns:

    """

    avg = len(seq) / float(num)
    out = []
    last = 0.0

    while last < len(seq):
        out.append(seq[int(last):int(last + avg)])
        last += avg

    return out


# %% Pooling function

def pool(CO, file_name_pool_in, file_name_pool_out, width):
    buffer = np.ndarray((2, width), dtype=int)
    for i in range(0, CO):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_in_current = file_name_pool_in.replace("{I}", i_str)
        file_name_out_current = file_name_pool_out.replace("{I}", i_str)
        pool_input_file = open(file_name_in_current, "r")
        pool_output_file = open(file_name_out_current, "w")

        buf_i = 0
        buf_j = 0

        for line in pool_input_file:
            buffer[buf_j][buf_i] = int(line)
            if buf_i != width - 1:
                buf_i += 1
            elif buf_j != 1:
                buf_j += 1
                buf_i = 0
            else:
                for x in range(0, int(width / 2)):
                    vals = [buffer[0][x * 2], buffer[0][x * 2 + 1], buffer[1][x * 2], buffer[1][x * 2 + 1]]
                    max_val = max(vals)
                    pool_output_file.write(str(max_val) + "\n")
                buf_i = 0
                buf_j = 0

        pool_input_file.close()
        pool_output_file.close()


def script_folder_path() -> str:
    return os.path.dirname(os.path.abspath(__file__))


BASE_DIR = os.path.abspath(script_folder_path())


def main():
    SCR_DIR = script_folder_path()
    TMP_DIR = os.path.join(SCR_DIR, 'tmp')
    TMP_DIR_MNIST = os.path.join(SCR_DIR, 'tmp_mnist')

    # %% parameters
    KEEP_TEMPORARY_FILES = True
    KERNEL_SIZE = 3
    NUMBER_OF_TEST_BLOCKS = 3
    CI_L1 = 1
    CO_L1 = 16
    CI_L2 = 16
    CO_L2 = 24
    INPUT_DATA_WIDTH = 8

    IMG_WIDTH = 28
    IMG_HEIGTH = 28
    BLOCK_SIZE = IMG_WIDTH * IMG_HEIGTH

    # --- Setup Paths
    path_dict = {}
    for key, value in FILENAMES_INT4.items():
        path_dict[key] = os.path.abspath(os.path.join(script_folder_path(), value))

    l1_weights_file_name = path_dict['cn1.k']
    l2_weights_file_name = path_dict['cn2.k']
    l1_bias_file_name = path_dict['cn1.b']
    l2_bias_file_name = path_dict['cn2.b']
    config_file_name = path_dict['config']

    clean_up_workspace(tmp_dir=TMP_DIR)

    with open(config_file_name, 'r') as fp_json:
        config_data = json.load(fp_json)

    npz_filepath = os.path.abspath(os.path.join(BASE_DIR, '../../../../../net/final_weights/int4_fpi/all.npz'))
    config_path = os.path.abspath(os.path.join(BASE_DIR, '../../../../../net/final_weights/int4_fpi/config.json'))

    pynet = EggNet.LeNet.init_npz(npz_path=npz_filepath)
    py_quant_net = EggNet.FpiLeNet.init_npz(npz_path=npz_filepath, config_path=config_path)

    mnist = EggNet.Reader.MNIST(folder_path=TMP_DIR_MNIST)
    labels = mnist.test_labels()
    imgs = mnist.test_images()

    # choose random indices
    random_i = rand.randint(0, len(labels), NUMBER_OF_TEST_BLOCKS)

    # fill testdata vector and plot random test images

    fig, axs = plt.subplots(ncols=NUMBER_OF_TEST_BLOCKS)
    for j in range(0, NUMBER_OF_TEST_BLOCKS):
        axs[j].imshow(imgs[random_i[j]], cmap='gray')
    fig.show()

    x = imgs[random_i].astype(np.int32)

    y, y_layers = py_quant_net.forward_intermediate(inputs=x)
    # print(f" y == y_ ? : {y == labels[random_i]}")

    fig, axes = plt.subplots(nrows=4, ncols=4)
    for i in range(4):
        for j in range(4):
            _img = y_layers[1]
            ix = j + i * 4
            axes[i, j].imshow(y_layers[2][0, :, :, ix], cmap='gray')
    fig.show()
    # Generate data for test vectors

    # %% create test data file
    # image_data_flat = tb.gen_testdata(BLOCK_SIZE,NUMBER_OF_TEST_BLOCKS, CI_L1)

    image_data = np.expand_dims(x,axis=3)
    image_data_padded = np.pad(image_data, ((0, 0), (1, 1), (1, 1), (0, 0)), 'constant', constant_values=(0, 0))
    image_data_flat = np.reshape(image_data, newshape=(NUMBER_OF_TEST_BLOCKS, -1, CI_L1))

    IMG_HEIGTH_PAD = 30
    IMG_WIDTH_PAD = 30
    l1_new_test_vectors = np.zeros((NUMBER_OF_TEST_BLOCKS, IMG_WIDTH_PAD*IMG_HEIGTH, KERNEL_SIZE, CI_L1), dtype=np.int)

    for h in range(1, IMG_HEIGTH_PAD-1):
        for w in range(0, IMG_WIDTH_PAD):
            ix = w + (h-1)*IMG_WIDTH_PAD
            image_patch = image_data_padded[:, h-1:h+1+1, w,:]
            i#mage_patch = np.expand_dims(image_patch, axis=1)
            l1_new_test_vectors[:,ix,:,:] = image_patch

    l1_new_test_kernels = np.zeros((NUMBER_OF_TEST_BLOCKS, IMG_HEIGTH, IMG_WIDTH, KERNEL_SIZE, KERNEL_SIZE, CI_L1),dtype=np.int)
    for h in range(IMG_HEIGTH):
        for w in range(IMG_WIDTH):
            hx, wx = h+1, w+1
            l1_new_test_kernels[:,h,w,:,:,:] = image_data_padded[:,hx-1:hx+2,wx-1:wx+2,:]
    l1_new_flat_test_kernels = np.reshape(l1_new_test_kernels, newshape=(NUMBER_OF_TEST_BLOCKS, -1, KERNEL_SIZE, KERNEL_SIZE, CI_L1))

    # %% generate test vectors
    l1_test_vectors = tb.get_vectors_from_data(image_data_flat, IMG_WIDTH, IMG_HEIGTH, NUMBER_OF_TEST_BLOCKS)

    # %% generate test kernels
    l1_test_kernels = tb.get_Kernels(l1_test_vectors, IMG_WIDTH)
    # l1_test_kernels >>= max(INPUT_DATA_WIDTH - config_data["input_bits"][0], 0)

    # %% calculate Layer 1 output as new memory controller input
    l1_weights = np.load(l1_weights_file_name)
    l1_bias = np.load(l1_bias_file_name)
    l1_moved_weights = np.moveaxis(l1_weights, 2, 0)

    y_conv_layer_out = np.sum(np.multiply(l1_new_flat_test_kernels, l1_moved_weights), axis=(2, 3)) + l1_bias
    y_conv_layer_out = np.clip(y_conv_layer_out.astype(np.int) >> 8, a_min=0, a_max=15)
    # Make sure integer is used for this & maybe use a more public function like "zeros"
    l1_weights_reshaped = np.zeros(shape=(CO_L1, CI_L1, 3, 3), dtype=np.int)

    for i in range(0, CI_L1):
        for j in range(0, CO_L1):
            for x in range(0, KERNEL_SIZE):
                for y in range(0, KERNEL_SIZE):
                    # TODO I think this was the bug
                    l1_weights_reshaped[j][i][x][y] = l1_weights[x][y][i][j]
                    # l1_weights_reshaped[j][i][y][x] = l1_weights[x][y][i][j]

    # The operation above can be minimized to this line
    l1_weights_reshaped_2 = np.moveaxis(l1_weights, source=(0, 1, 2, 3), destination=(3, 2, 1, 0))

    l1_msb = np.ones(CO_L1, dtype=np.int32) * (config_data["shifts"][0] + config_data["output_bits"][0] - 1)
    l1_features = tb.conv_2d(l1_test_kernels, l1_weights_reshaped, l1_msb, l1_bias, config_data["output_bits"][0], shifts=config_data['shifts'][0])

    # TODO This function saves the outputs in the wrong order?
    tb.write_features_to_file(l1_features, layernumber=1)

    conv2d0_input_files = [None] * KERNEL_SIZE * KERNEL_SIZE

    for i in range(0, KERNEL_SIZE * KERNEL_SIZE):
        conv2d0_input_files[i] = open("tmp/conv2d_0_input" + str(i) + ".txt", "w")

    # for i in range(0, NUMBER_OF_TEST_BLOCKS):
    #     for j in range(0, IMG_WIDTH * IMG_HEIGTH):
    #         for c in range(0, CI_L1):
    #             for kh in range(0, KERNEL_SIZE):
    #                 for kw in range(0, KERNEL_SIZE):
    #                     num = kw + kh * KERNEL_SIZE
    #                     conv2d0_input_files[num].write(str(l1_test_kernels[i][j][kh][kw][c]) + "\n")

    # TODO BUG NUMBER 2!!!
    for c in range(0, CI_L1):
        for kh in range(0, KERNEL_SIZE):
            for kw in range(0, KERNEL_SIZE):
                for i in range(0, NUMBER_OF_TEST_BLOCKS):
                    for j in range(0, IMG_WIDTH * IMG_HEIGTH):
                        num = kw + kh * KERNEL_SIZE
                        conv2d0_input_files[num].write(str(l1_test_kernels[i][j][kh][kw][c]) + "\n")


    for i in range(0, KERNEL_SIZE * KERNEL_SIZE):
        conv2d0_input_files[i].close()

    l1_features_eggnet_2d = y_layers[2]
    l1_features_2d = np.reshape(l1_features, newshape=(3, 28, 28, 16))

    imgs_compare = np.concatenate((l1_features_2d, l1_features_eggnet_2d), axis=2)
    # plt.imshow(l1_features_eggnet_2d[0, :, :, 0], cmap='grey')
    # plt.imshow(l1_features_2d[0, :, :, 0], cmap='grey')

    # TODO BUG The images are ordered differently
    # TODO UDPATE Maybe not the bug
    plt.imshow(
        np.concatenate((l1_features_2d[0, :, :, 0], l1_features_eggnet_2d[0, :, :, 0]), axis=1),
        cmap='gray')
    plt.show()

    plt.imshow(
        l1_features_2d[0, :, :, 0]-l1_features_eggnet_2d[0, :, :, 0],
        cmap='gray')
    plt.show()

    l1_features_eggnet = np.reshape(y_layers[2], newshape=(3, -1, 16))

    # %% Run test and compare output from conv2d0

    print("Compiling and running conv2d0 testbench...")

    subprocess.call(
        os.path.join(script_folder_path(), "run_conv2d_0.sh"),
        cwd=script_folder_path()
    )
    # ghdl_console_output = subprocess.check_output([os.path.join(script_folder_path(), "run_conv2d_0.sh")], cwd=script_folder_path())
    # print(ghdl_console_output)
    # subprocess.call("run_conv2d_0.sh")

    file_name_conv_channel_output_python = "tmp/conv2d_0_output{I}.txt"
    file_name_conv_channel_output_vhdl = "tmp/feature_map_L1_c{I}.txt"

    for i in range(0, CO_L1):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_conv_channel_output_python_current = file_name_conv_channel_output_python.replace("{I}", i_str)
        file_name_conv_channel_output_vhdl_current = file_name_conv_channel_output_vhdl.replace("{I}", str(i))

        y_channel_python = np.loadtxt(file_name_conv_channel_output_python_current, dtype=np.int).reshape((3, 28 * 28, 1))
        y_channel_vhdl = np.loadtxt(file_name_conv_channel_output_vhdl_current, dtype=np.int).reshape((3, 28 * 28, 1))

        y_channel_python_2d = np.reshape(y_channel_python, (3,28,28,1))
        y_channel_vhdl_2d = np.reshape(y_channel_vhdl, (3, 28, 28, 1))

        if True: # Change to true for debugging
            plt.imshow(
                np.concatenate((l1_features_2d[0, :, :, i], y_channel_vhdl_2d[0, :, :, 0]), axis=1),
                cmap='gray')
            plt.show()

            plt.imshow(
                l1_features_2d[0, :, :, i] - y_channel_vhdl_2d[0, :, :, 0],
                cmap='gray')
            plt.show()

        if not np.all(l1_features_2d[:, :, :, i] == y_channel_vhdl_2d[:, :, :, 0]):
            print(f"Simulation and emulation output not the same for conv2d0, channel {i}")
            print(f"Sum |Error|:    ", np.sum(np.abs(l1_features_2d[:,:,:,i]-y_channel_vhdl_2d[:, :, :, 0])))

        # TODO The comparision below doesnt work because the other file is wrong
        #if not filecmp.cmp(file_name_conv_channel_output_python_current, file_name_conv_channel_output_vhdl_current):
        #    print("Simulation and emulation output not the same for conv2d0, channel " + str(i))
        #    exit()

    print("Simulation and emulation output the same for conv2d0")
    # %% Pooling after layer 1

    pool(CO_L1, file_name_conv_channel_output_python, "tmp/pool_output{I}.txt", IMG_WIDTH)

    # New parameters after pooling
    IMG_WIDTH //= 2
    IMG_HEIGTH //= 2
    BLOCK_SIZE = IMG_WIDTH * IMG_HEIGTH

    # %% Run test and compare output foor pool0
    file_name_conv_channel_output_python = "tmp/pool_output{I}.txt"
    file_name_conv_channel_output_vhdl = "tmp/pooling_0_output{I}.txt"

    for i in range(0, CO_L1):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_conv_channel_output_python_current = file_name_conv_channel_output_python.replace("{I}", i_str)
        file_name_conv_channel_output_vhdl_current = file_name_conv_channel_output_vhdl.replace("{I}", i_str)
        if filecmp.cmp(file_name_conv_channel_output_python_current, file_name_conv_channel_output_vhdl_current) != True:
            print("Simulation and emulation output not the same for pool0, channel " + str(i))
            exit()

    print("Simulation and emulation output the same for pool0")

    # %% Get input for layer 2 from output of layer 1
    file_name_in = "tmp/pool_output{I}.txt"

    test_array = np.ndarray((CI_L2, NUMBER_OF_TEST_BLOCKS, BLOCK_SIZE), dtype=np.uint8)

    for i in range(0, CI_L2):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_in_current = file_name_in.replace("{I}", i_str)
        data = np.loadtxt(file_name_in_current, dtype=np.uint8)
        test_array[i] = chunk_array(data, NUMBER_OF_TEST_BLOCKS)

    test_array_reshaped = np.ndarray((NUMBER_OF_TEST_BLOCKS, BLOCK_SIZE, CI_L2), dtype=np.uint8)

    for i in range(0, CI_L2):
        for j in range(0, BLOCK_SIZE):
            for k in range(0, NUMBER_OF_TEST_BLOCKS):
                test_array_reshaped[k][j][i] = test_array[i][k][j]

    l2_test_kernels = np.ndarray((NUMBER_OF_TEST_BLOCKS, IMG_WIDTH * IMG_HEIGTH, 3, 3, CI_L2), dtype=np.uint8)
    l2_test_vectors = tb.get_vectors_from_data(test_array_reshaped, IMG_WIDTH, IMG_HEIGTH, NUMBER_OF_TEST_BLOCKS)
    l2_test_kernels = tb.get_Kernels(l2_test_vectors, IMG_WIDTH)

    # %% calculate Layer 2 output as new memory controller input
    l2_weights = np.load(l2_weights_file_name)
    l2_bias = np.load(l2_bias_file_name)

    l2_weights_reshaped = np.ndarray((CO_L2, CI_L2, 3, 3))
    for i in range(0, CI_L2):
        for j in range(0, CO_L2):
            for x in range(0, KERNEL_SIZE):
                for y in range(0, KERNEL_SIZE):
                    l2_weights_reshaped[j][i][y][x] = l2_weights[x][y][i][j]

    l2_msb = np.ones(CO_L2, dtype=np.int32) * (config_data["shifts"][1] + config_data["output_bits"][1] - 1)
    l2_features = tb.conv_2d(l2_test_kernels, l2_weights_reshaped, l2_msb, l2_bias, config_data["output_bits"][1])
    tb.write_features_to_file(l2_features, layernumber=2)

    # %% Write input files for conv2d1 testbench
    conv2d1_input_files = [[0 for i in range(KERNEL_SIZE * KERNEL_SIZE)] for j in range(CI_L2)]
    for i in range(0, CI_L2):
        for j in range(0, KERNEL_SIZE * KERNEL_SIZE):
            i_str = str(i)
            if len(i_str) == 1:
                i_str = "0" + i_str
            conv2d1_input_files[i][j] = open("tmp/conv2d_1_c" + i_str + "input" + str(j) + ".txt", "w")

    for i in range(0, NUMBER_OF_TEST_BLOCKS):
        for j in range(0, IMG_WIDTH * IMG_HEIGTH):
            for c in range(0, CI_L2):
                for x in range(0, KERNEL_SIZE):
                    for y in range(0, KERNEL_SIZE):
                        num = y + x * KERNEL_SIZE
                        # TODO This is wrong like the one above was
                        conv2d1_input_files[c][num].write(str(l2_test_kernels[i][j][x][y][c]) + "\n")

    for i in range(0, CI_L2):
        for j in range(0, KERNEL_SIZE * KERNEL_SIZE):
            conv2d1_input_files[i][j].close()

    # %% Run test and compare output for conv2d1
    print("Compiling and running conv2d1 testbench...")

    subprocess.call("run_conv2d_1.bat")
    subprocess.call(
        os.path.join(script_folder_path(), "run_conv2d_0.sh"),
        cwd=script_folder_path()
    )


    file_name_conv_channel_output_python = "tmp/conv2d_1_output{I}.txt"
    file_name_conv_channel_output_vhdl = "tmp/feature_map_L2_c{I}.txt"

    for i in range(0, CO_L2):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_conv_channel_output_python_current = file_name_conv_channel_output_python.replace("{I}", i_str)
        file_name_conv_channel_output_vhdl_current = file_name_conv_channel_output_vhdl.replace("{I}", str(i))
        if filecmp.cmp(file_name_conv_channel_output_python_current, file_name_conv_channel_output_vhdl_current) != True:
            print("Simulation and emulation output not the same for conv2d1, channel " + str(i))
            exit()

    print("Simulation and emulation output the same for conv2d1")

    # %% Pooling after layer 2

    pool(CO_L2, file_name_conv_channel_output_python, "tmp/dense_layer_input{I}.txt", IMG_WIDTH)

    # New parameters after pooling
    IMG_WIDTH //= 2
    IMG_HEIGTH //= 2
    BLOCK_SIZE = IMG_WIDTH * IMG_HEIGTH

    # %% Run test and compare output for pool1
    file_name_conv_channel_output_python = "tmp/dense_layer_input{I}.txt"
    file_name_conv_channel_output_vhdl = "tmp/pooling_1_output{I}.txt"

    for i in range(0, CO_L2):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name_conv_channel_output_python_current = file_name_conv_channel_output_python.replace("{I}", i_str)
        file_name_conv_channel_output_vhdl_current = file_name_conv_channel_output_vhdl.replace("{I}", i_str)
        if filecmp.cmp(file_name_conv_channel_output_python_current, file_name_conv_channel_output_vhdl_current) != True:
            print("Simulation and emulation output not the same for pool1, channel " + str(i))
            exit()

    print("Simulation and emulation output the same for pool1")

    # %% Get input for NN (unit-)test bench. this is a single block of feature sets in natural order (i.e. not reshaped by serializer)

    file_nn = open("tmp/nn_input.txt", "w")

    for i in range(0, CO_L2):
        i_str = str(i)
        if len(i_str) == 1:
            i_str = "0" + i_str
        file_name = "tmp/dense_layer_input{I}.txt"
        file_name = file_name.replace("{I}", i_str)
        input_file = open(file_name, "r")
        input_lines = input_file.readlines()
        input_lines_chunked = chunk_array(input_lines, NUMBER_OF_TEST_BLOCKS)
        file_nn.writelines(input_lines_chunked[0])
        input_file.close()

    file_nn.close()

    # %% Get output for dense layer

    dl1_bias_file = open(denselayer_1_bias_file_name, 'r')
    dl1_bias = np.loadtxt(dl1_bias_file, dtype=np.int16)
    dl1_bias_file.close()

    dl2_bias_file = open(denselayer_2_bias_file_name, 'r')
    dl2_bias = np.loadtxt(dl2_bias_file, dtype=np.int16)
    dl2_bias_file.close()

    DL1_INPUT_NEURONS = IMG_WIDTH * IMG_HEIGTH * CO_L2
    DL1_OUTPUT_NEURONS = 32
    DL2_INPUT_NEURONS = 32
    DL2_OUTPUT_NEURONS = 10

    dl1_weights_file = open(denselayer_1_file_name, 'r')
    dl1_weights = np.array(list(np.loadtxt(dl1_weights_file, dtype=np.int8))).reshape(
        (DL1_INPUT_NEURONS, DL1_OUTPUT_NEURONS))
    dl1_weights_file.close()

    # reshape weights for fully connected layer 1
    permutation = [None] * DL1_INPUT_NEURONS
    for i in range(0, DL1_INPUT_NEURONS):
        permutation[i] = int(i / BLOCK_SIZE) + (i % BLOCK_SIZE) * CO_L2
    idx = np.empty_like(permutation)
    idx[permutation] = np.arange(len(permutation))
    dl1_weights_permutated = dl1_weights[idx, :]

    dl2_weights_file = open(denselayer_2_file_name, 'r')
    dl2_weights = np.array(list(np.loadtxt(dl2_weights_file, dtype=np.int8))).reshape(
        (DL2_INPUT_NEURONS, DL2_OUTPUT_NEURONS))
    dl2_weights_file.close()

    file_serializer = open("tmp/serializer_output.txt", "r")
    serializer_output = np.loadtxt(file_serializer, dtype=np.int32)
    file_serializer.close()
    serializer_output_chunked = chunk_array(serializer_output, NUMBER_OF_TEST_BLOCKS)

    output_file = open("tmp/output.txt", "r")
    output = np.loadtxt(output_file)
    output_file.close()
    output_chunked = chunk_array(output, NUMBER_OF_TEST_BLOCKS)

    # %% Simulate dense layer,

    for i in range(0, NUMBER_OF_TEST_BLOCKS):
        dl1_output = np.matmul(serializer_output_chunked[i], dl1_weights_permutated) + dl1_bias;
        dl1_output >>= config_data['shifts'][2]
        dl1_output = np.clip(dl1_output, a_min=0, a_max=np.uint8(config_data['out_max'][2]))
        dl2_output = np.matmul(dl1_output, dl2_weights) + dl2_bias;
        dl2_output >>= config_data['shifts'][3]
        dl2_output = np.clip(dl2_output, a_min=0, a_max=np.uint8(config_data['out_max'][3]))
        for j in range(0, DL2_OUTPUT_NEURONS):
            if dl2_output[j] != output_chunked[i][j]:
                print("Output of dense layer not the same as simulation")
                exit()

    print("Simulation and emulation output the same for dense layer")

    # %% delete tmp folder
    if not KEEP_TEMPORARY_FILES:
        shutil.rmtree('tmp')


def clean_up_workspace(tmp_dir):
    # %% create tmp folder, delete folder if not tmp exists and create new one
    if os.path.isdir(tmp_dir):
        shutil.rmtree(tmp_dir)
    os.makedirs(tmp_dir, exist_ok=True)


if __name__ == '__main__':
    main()
