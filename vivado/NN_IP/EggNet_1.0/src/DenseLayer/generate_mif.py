# -*- coding: utf-8 -*-
import numpy as np

def get_binstr(a):
    binstr = list(format(abs(a), '08b'))
    if(a < 0):
        for k in range(0, len(binstr)):
            if(binstr[k] == '1'):
                binstr[k] = '0'
            else:
                binstr[k] = '1'
        for k in reversed(range(0, len(binstr))):
            if(binstr[k] == '0'):
                binstr[k] = '1'
                break
            else:
                binstr[k] = '0'
    return "".join(binstr)

denselayer_1_file_name = "../../../../../net/final_weights/fpi/fc1.w.txt"
denselayer_2_file_name = "../../../../../net/final_weights/fpi/fc2.w.txt"
denselayer_1_bias_file_name = "../../../../../net/final_weights/fpi/fc1.b.txt"
denselayer_2_bias_file_name = "../../../../../net/final_weights/fpi/fc2.b.txt"

INPUT_IMAGE_WIDTH = 7
INPUT_IMAGE_HIGHT = 7
INPUT_IMAGE_SIZE = INPUT_IMAGE_WIDTH*INPUT_IMAGE_HIGHT
CL2_OUTPUT_CHANNELS = 32
DL1_INPUT_NEURONS = 1568
DL1_OUTPUT_NEURONS = 32
DL2_INPUT_NEURONS = 32
DL2_OUTPUT_NEURONS = 10

dl1_weights_file = open(denselayer_1_file_name, 'r')
dl1_weights = np.array(list(np.loadtxt(dl1_weights_file, dtype=np.int8))).reshape((DL1_INPUT_NEURONS, DL1_OUTPUT_NEURONS))
dl1_weights_file.close()

dl1_bias_file = open(denselayer_1_bias_file_name, 'r')
dl1_bias = np.loadtxt(dl1_bias_file, dtype=np.int8);
dl1_bias_file.close()

permutation = [None]*DL1_INPUT_NEURONS

for j in range(0, INPUT_IMAGE_SIZE):
    for i in range(0, CL2_OUTPUT_CHANNELS):
        permutation[j*CL2_OUTPUT_CHANNELS + i] = i*INPUT_IMAGE_SIZE + j
idx = np.empty_like(permutation)
idx[permutation] = np.arange(len(permutation))
dl1_weights_permutated = dl1_weights[idx,:]

dl2_weights_file = open(denselayer_2_file_name, 'r')
dl2_weights = np.array(list(np.loadtxt(dl2_weights_file, dtype=np.int8))).reshape((DL2_INPUT_NEURONS, DL2_OUTPUT_NEURONS))
dl2_weights_file.close()

dl2_bias_file = open(denselayer_2_bias_file_name, 'r')
dl2_bias = np.loadtxt(dl2_bias_file, dtype=np.int8);
dl2_bias_file.close()

dl1_mif_file_name = "dense_layer_1.mif"
dl1_mif_file = open(dl1_mif_file_name, 'w')

for i in range(0, DL1_INPUT_NEURONS):
    line = ""
    for j in reversed(range(0, DL1_OUTPUT_NEURONS)):
        binstr = get_binstr(dl1_weights[i][j])
        line += binstr
    dl1_mif_file.write(line + "\n")
        
dl1_mif_file.close()

dl2_mif_file_name = "dense_layer_2.mif"
dl2_mif_file = open(dl2_mif_file_name, 'w')

for i in range(0, DL2_INPUT_NEURONS):
    line = ""
    for j in reversed(range(0, DL2_OUTPUT_NEURONS)):
        binstr = get_binstr(dl2_weights[i][j])
        line += binstr
    dl2_mif_file.write(line + "\n")
    
dl2_mif_file.close()

dl1_bias_mif_file_name = "bias_terms_L1.mif"
dl1_bias_mif_file = open(dl1_bias_mif_file_name, 'w')

for i in range(0, DL1_OUTPUT_NEURONS):
    line = get_binstr(dl1_bias[i]) + "00000000"
    dl1_bias_mif_file.write(line + "\n")

dl1_bias_mif_file.close()

dl2_bias_mif_file_name = "bias_terms_L2.mif"
dl2_bias_mif_file = open(dl2_bias_mif_file_name, 'w')

for i in range(0, DL2_OUTPUT_NEURONS):
    line = get_binstr(dl2_bias[i]) + "00000000"
    dl2_bias_mif_file.write(line + "\n")

dl2_bias_mif_file.close()