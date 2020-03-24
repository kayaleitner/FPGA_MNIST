# -*- coding: utf-8 -*-

import os
import shutil
import numpy as np
import re
import json
import argparse

BITS = 4
num_layers = 2

config_file_name = "../../../../../net/final_weights/int8_fpi/config.json"

file_names = ["../../../../../net/final_weights/int8_fpi/cn1.k.txt",
              "../../../../../net/final_weights/int8_fpi/cn2.k.txt"]

binary_files = ["../../../../../net/final_weights/int8_fpi/cn1.k.npy",
                "../../../../../net/final_weights/int8_fpi/cn2.k.npy"]

num_layers = 2
if BITS == 4:
    config_file_name = "../../../../../net/final_weights/int4_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int4_fpi/cn1.k.txt",
                  "../../../../../net/final_weights/int4_fpi/cn2.k.txt"]
    file_names_bias = ["../../../../../net/final_weights/int4_fpi/cn1.b.txt",
                       "../../../../../net/final_weights/int4_fpi/cn2.b.txt"]
elif BITS == 8:
    config_file_name = "../../../../../net/final_weights/int8_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int8_fpi/cn1.k.txt",
                  "../../../../../net/final_weights/int8_fpi/cn2.k.txt"]
    file_names_bias = ["../../../../../net/final_weights/int8_fpi/cn1.b.txt",
                       "../../../../../net/final_weights/int8_fpi/cn2.b.txt"]


def main():

    weight_paths = list(map(script_relative_path_to_abspath, binary_files))
    template_path = script_relative_path_to_abspath('conv2d_template.in.vhd')
    output_path = script_relative_path_to_abspath('channels/conv2d_benni.vhd')

    num_input_channels = [None] * num_layers
    num_output_channels = [None] * num_layers
    kernel_arrays = [None] * num_layers
    kernel_strings = [None] * num_layers
    channel_strings = [None] * num_layers
    msb = [None] * num_layers
    biases = [None] * num_layers

    # %% create tmp folder, delete folder if not tmp exists and create new one
    if os.path.isdir('channels'):
        shutil.rmtree('channels')

    try:
        os.mkdir('channels')
    except:
        print("Error creating temp channel folder!")

    fp_json = open(config_file_name, 'r')
    config_data = json.load(fp_json)

    cn1_k = np.load(weight_paths[0])
    cn2_k = np.load(weight_paths[1])

    create_conv_channel(template_file_path=template_path,
                        output_file_path=output_path,
                        conv_weights=cn1_k[:, :, :, 0],
                        conv_channel_name='conv2d_channel_benni')
    
    for i in range(0, num_layers):
        msb[i] = config_data["shifts"][i] + config_data["output_bits"][i] - 1
        file = open(file_names[i], 'r')
        file_bias = open(file_names_bias[i], 'r')
        def_line = file.readline()
        regex = re.compile(r"# \(3, 3, (.*?)\)\n")
        channel_def = list(map(int, regex.match(def_line).group(1).split(',')))
        num_input_channels[i] = channel_def[0]
        num_output_channels[i] = channel_def[1]
        kernel_arrays[i] = list(np.loadtxt(file, dtype=np.int8))
        kernel_arrays[i] = np.array(kernel_arrays[i]).reshape((3, 3, num_input_channels[i], num_output_channels[i]))
        kernel_strings[i] = np.ndarray((num_input_channels[i], num_output_channels[i]), dtype=object)
        biases[i] = list(np.loadtxt(file_bias, dtype=np.int16))

        for x in range(0, num_input_channels[i]):
            for y in range(0, num_output_channels[i]):
                kernel_strings[i][x][y] = "(" + \
                                           str(kernel_arrays[i][0][0][x][y]) + ", " + \
                                           str(kernel_arrays[i][1][0][x][y]) + ", " + \
                                           str(kernel_arrays[i][2][0][x][y]) + ", " + \
                                           str(kernel_arrays[i][0][1][x][y]) + ", " + \
                                           str(kernel_arrays[i][1][1][x][y]) + ", " + \
                                           str(kernel_arrays[i][2][1][x][y]) + ", " + \
                                           str(kernel_arrays[i][0][2][x][y]) + ", " + \
                                           str(kernel_arrays[i][1][2][x][y]) + ", " + \
                                           str(kernel_arrays[i][2][2][x][y]) + ")"
        channel_strings[i] = []
        for y in range(0, num_output_channels[i]):
            channel_strings[i].append('')
            channel_strings[i][y] += '('
            for x in range(0, num_input_channels[i]):
                channel_strings[i][y] += str(x) + " => "
                channel_strings[i][y] += kernel_strings[i][x][y]
                if x != num_input_channels[i] - 1:
                    channel_strings[i][y] += ', '
            channel_strings[i][y] += ')'
        file.close()
        file_bias.close()

    tp_file = open('conv_channel_template.vhd', 'r')
    tp_str = tp_file.read()
    i_convchan = 0
    for i in range(0, num_layers):
        for j in range(0, len(channel_strings[i])):
            tp_str_new = tp_str.replace("ConvChannelTemplate", "ConvChannel" + str(i_convchan))
            tp_str_new = re.sub("constant KERNELS : kernel_array_t :=[^\n]*\n",
                                "constant KERNELS : kernel_array_t := " + channel_strings[i][j] + ";\n", tp_str_new)
            tp_str_new = re.sub("\tN : integer :=[^\n]*\n", "\tN : integer := " + str(num_input_channels[i]) + ";\n",
                                tp_str_new)
            tp_str_new = re.sub("\tOUTPUT_MSB : integer :=[^\n]*\n", "\tOUTPUT_MSB : integer := " + str(msb[i]) + ";\n",
                                tp_str_new)
            tp_str_new = re.sub("\tBIAS : integer :=[^\n]*\n", "\tBIAS : integer := " + str(biases[i][j]) + "\n",
                                tp_str_new)
            tp_str_new = re.sub("\tBIT_WIDTH_IN : integer :=[^\n]*\n",
                                "\tBIT_WIDTH_IN : integer := " + str(config_data["input_bits"][i]) + ";\n", tp_str_new)
            tp_str_new = re.sub("\tBIT_WIDTH_OUT : integer :=[^\n]*\n",
                                "\tBIT_WIDTH_OUT : integer := " + str(config_data["output_bits"][i]) + ";\n",
                                tp_str_new)
            tp_str_new = re.sub("\tKERNEL_WIDTH_OUT : integer :=[^\n]*\n", "\tKERNEL_WIDTH_OUT : integer := " + str(
                config_data["output_bits"][i] + config_data["input_bits"][i] + int(np.ceil(np.log2(9)))) + ";\n",
                                tp_str_new)
            tp_file_new = open("channels/convchannel" + str(i_convchan) + ".vhd", 'w')
            tp_file_new.write(tp_str_new)
            tp_file_new.close()
            i_convchan += 1
    tp_file.close()

    tp_file = open('conv2d_template.vhd', 'r')
    tp_str = tp_file.read()
    entity_str = \
        "  convchan{I}" + " : entity " + "ConvChannel{J} \n" + \
        "  generic map( \n\
    BIT_WIDTH_IN => BIT_WIDTH_IN, \n\
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) \n" + \
        "  port map(\n\
    Clk_i, n_Res_i,\n\
    Valid_i, valid_out({K}), Last_i, last_out({K}), Ready_i, ready_out({K}),\n" + \
        "    X_i,\n\
    Y_o({I+1}*BIT_WIDTH_OUT - 1 downto {I}*BIT_WIDTH_OUT)\n\
  ); \n\n"
    i_convchan = 0
    for i in range(0, num_layers):
        use_str = ""
        i_convchan_old = i_convchan
        for y in range(0, num_output_channels[i]):
            use_str += "use work.ConvChannel" + str(i_convchan) + ";\n"
            i_convchan += 1
        i_convchan = i_convchan_old
        tp_str_new = tp_str.replace(
            "use work.kernel_pkg.all;\n", "use work.kernel_pkg.all;\n" + use_str)
        tp_str_new = tp_str_new.replace("Conv2DTemplate", "Conv2D_" + str(i))
        tp_str_new = re.sub("INPUT_CHANNELS : integer := [^\n]*\n", "INPUT_CHANNELS : integer := " + str(
            num_input_channels[i]) + ";\n", tp_str_new)
        tp_str_new = re.sub("OUTPUT_CHANNELS : integer := [^\n]*\n", "OUTPUT_CHANNELS : integer := " + str(
            num_output_channels[i]) + "\n", tp_str_new)
        tp_str_new += "\narchitecture beh of " + "Conv2D_" + str(i) + " is\n " + \
                      "  signal ready_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n" + \
                      "  signal valid_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n" + \
                      "  signal last_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n" + \
                      "begin\n" + \
                      "  Ready_o <= ready_out(0);\n" + \
                      "  Valid_o <= valid_out(0);\n" + \
                      "  Last_o <= last_out(0);\n"

        for y in range(0, num_output_channels[i]):
            entity_str_new = entity_str.replace("{J}", str(i_convchan))
            entity_str_new = entity_str_new.replace("{I}", str(y))
            entity_str_new = entity_str_new.replace(
                "{K}", str(i_convchan - i_convchan_old))
            entity_str_new = entity_str_new.replace("{I+1}", str(y + 1))
            tp_str_new += entity_str_new
            i_convchan += 1

        tp_str_new += "end beh;"
        tp_file_new = open("conv2d_" + str(i) + ".vhd", 'w')
        tp_file_new.write(tp_str_new)
        tp_file_new.close()
    tp_file.close()


def script_dir():
    """
    The current absolute directory
    Returns:

    """
    return os.path.dirname(os.path.abspath(__file__))


def create_conv_channel(template_file_path, output_file_path, conv_weights, conv_channel_name):
    """
    Refined creation of the convolutional channels
    Args:
        template_file_path:
        output_file_path:
        conv_weights:
        conv_channel_name:
    """
    with open(template_file_path, 'r') as ftemp:
        template = ftemp.read()

    # Replace all conv_channel_names by their names
    template = re.sub(
        pattern=r'{{[ ]*conv_channel_name[ ]*}}',
        repl=lambda x: conv_channel_name,
        string=template
    )

    # Convert weights to (x,y,z) format
    # By using order 'F' we flatten from the first axis to the last
    conv_weight_str = '(' + ','.join(map(str, conv_weights.flatten(order='F'))) + ')'
    # Replace all conv_channel_weights by their weights
    template = re.sub(
        pattern=r'{{[ ]*conv_channel_weights[ ]*}}',
        repl=lambda x: conv_weight_str,
        string=template
    )

    with open(output_file_path, 'w') as f:
        f.write(template)


def script_relative_path_to_abspath(fpath):
    """
    Appends the path to the script path and converts the result to an absolute path
    Args:
        fpath: Path to append

    Returns:
        The absolute combined path
    """
    return os.path.abspath(os.path.join(script_dir(), fpath))


if __name__ == '__main__':
    main()
