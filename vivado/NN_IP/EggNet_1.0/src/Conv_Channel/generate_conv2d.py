# -*- coding: utf-8 -*-

import os 
import shutil
import numpy as np
import re
import json

BITS = 8

num_layers = 2

if BITS == 4:
    config_file_name = "../../../../../net/final_weights/int4_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int4_fpi/cn1.k.txt",
             "../../../../../net/final_weights/int4_fpi/cn2.k.txt"]
elif BITS == 8:
    config_file_name = "../../../../../net/final_weights/int8_fpi/config.json"
    file_names = ["../../../../../net/final_weights/int8_fpi/cn1.k.txt",
                 "../../../../../net/final_weights/int8_fpi/cn2.k.txt"]
    
if __name__ == '__main__':
    num_input_channels = [None]*num_layers
    num_output_channels = [None]*num_layers
    kernel_arrays = [None]*num_layers
    kernel_strings = [None]*num_layers
    channel_strings = [None]*num_layers
    msb = [None]*num_layers
    
# %% create tmp folder, delete folder if not tmp exists and create new one
    if os.path.isdir('channels'):
        shutil.rmtree('channels')
        
    try : os.mkdir('channels')
    except : print("Error creating temp channel folder!")
    
    fp_json = open(config_file_name, 'r')
    config_data = json.load(fp_json)
    
    for i in range(0, num_layers):
        msb[i] = config_data["shifts"][i] + config_data["output_bits"][i] - 1
        file = open(file_names[i], 'r')
        def_line = file.readline()
        regex = re.compile("# \(3, 3, (.*?)\)\n")
        channel_def = list(map(int, regex.match(def_line).group(1).split(',')))
        num_input_channels[i] = channel_def[0]
        num_output_channels[i] = channel_def[1]
        kernel_arrays[i] = list(np.loadtxt(file, dtype=np.int8))
        kernel_arrays[i] = np.array(kernel_arrays[i]).reshape((3,3,num_input_channels[i], num_output_channels[i]))
        kernel_strings[i] = np.ndarray((num_input_channels[i], num_output_channels[i]), dtype=object)

        for x in range(0, num_input_channels[i]):
            for y in range(0, num_output_channels[i]):
                kernel_strings[i][x][y] = "(" + \
                str(kernel_arrays[i][0][0][x][y]) + ", " +\
                str(kernel_arrays[i][1][0][x][y]) + ", " +\
                str(kernel_arrays[i][2][0][x][y]) + ", " +\
                str(kernel_arrays[i][0][1][x][y]) + ", " +\
                str(kernel_arrays[i][1][1][x][y]) + ", " +\
                str(kernel_arrays[i][2][1][x][y]) + ", " +\
                str(kernel_arrays[i][0][2][x][y]) + ", " +\
                str(kernel_arrays[i][1][2][x][y]) + ", " +\
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
        
    tp_file = open('conv_channel_template.vhd', 'r')
    tp_str = tp_file.read()
    i_convchan = 0
    for i in range(0, num_layers):
        for j in range(0,len(channel_strings[i])):
            tp_str_new = tp_str.replace("ConvChannelTemplate", "ConvChannel" + str(i_convchan))
            tp_str_new = re.sub("constant KERNELS : kernel_array_t :=[^\n]*\n", "constant KERNELS : kernel_array_t := " + channel_strings[i][j] + ";\n", tp_str_new)
            tp_str_new = re.sub("\tN : integer :=[^\n]*\n", "\tN : integer := " + str(num_input_channels[i]) + ";\n", tp_str_new)
            tp_str_new = re.sub("\tOUTPUT_MSB : integer :=[^\n]*\n", "\tOUTPUT_MSB : integer := " + str(msb[i]) + ";\n", tp_str_new)
            tp_str_new = re.sub("\tBIT_WIDTH_IN : integer :=[^\n]*\n", "\tBIT_WIDTH_IN : integer := " + str(config_data["input_bits"][i]) + ";\n", tp_str_new)
            tp_str_new = re.sub("\tBIT_WIDTH_OUT : integer :=[^\n]*\n", "\tBIT_WIDTH_OUT : integer := " + str(config_data["output_bits"][i]) + ";\n", tp_str_new)
            tp_str_new = re.sub("\tKERNEL_WIDTH_OUT : integer :=[^\n]*\n", "\tKERNEL_WIDTH_OUT : integer := " + str(config_data["output_bits"][i] + config_data["input_bits"][i] + int(np.ceil(np.log2(9)))) + ";\n", tp_str_new)
            tp_file_new = open("channels/convchannel" + str(i_convchan) + ".vhd", 'w')
            tp_file_new.write(tp_str_new)
            tp_file_new.close()
            i_convchan += 1
    tp_file.close();
    
    tp_file = open('conv2d_template.vhd', 'r')
    tp_str = tp_file.read()
    entity_str = \
"  convchan{I}" + " : entity " + "ConvChannel{J} \n" + \
"  generic map( \n\
    BIT_WIDTH_IN => BIT_WIDTH_IN, \n\
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) \n" + \
"  port map(\n\
    Clk_i, n_Res_i,\n\
    Valid_i, valid_out({K}), Last_i, last_out({K}), Ready_i, ready_out({K}),\n"+  \
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
        tp_str_new = tp_str.replace("use work.kernel_pkg.all;\n", "use work.kernel_pkg.all;\n" + use_str)
        tp_str_new = tp_str_new.replace("Conv2DTemplate", "Conv2D_" + str(i))
        tp_str_new = re.sub("INPUT_CHANNELS : integer := [^\n]*\n", "INPUT_CHANNELS : integer := " + str(num_input_channels[i]) + ";\n", tp_str_new)
        tp_str_new = re.sub("OUTPUT_CHANNELS : integer := [^\n]*\n", "OUTPUT_CHANNELS : integer := " + str(num_output_channels[i]) + "\n", tp_str_new)
        tp_str_new += "\narchitecture beh of " + "Conv2D_" + str(i) + " is\n " + \
                    "  signal ready_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n"+ \
                    "  signal valid_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n"+ \
                    "  signal last_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);\n"+ \
                    "begin\n"+\
                    "  Ready_o <= ready_out(0);\n"+ \
                    "  Valid_o <= valid_out(0);\n"+ \
                    "  Last_o <= last_out(0);\n"
        
        for y in range(0, num_output_channels[i]):
            entity_str_new = entity_str.replace("{J}", str(i_convchan))
            entity_str_new = entity_str_new.replace("{I}", str(y))
            entity_str_new = entity_str_new.replace("{K}", str(i_convchan-i_convchan_old))
            entity_str_new = entity_str_new.replace("{I+1}", str(y+1))
            tp_str_new += entity_str_new
            i_convchan += 1
        
        tp_str_new += "end beh;"
        tp_file_new = open("conv2d_" + str(i) + ".vhd", 'w')
        tp_file_new.write(tp_str_new)
        tp_file_new.close()
    tp_file.close();