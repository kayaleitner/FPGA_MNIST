# -*- coding: utf-8 -*-
import numpy as np

def quantize(a):
    return min(max(int(a/0.002),-128), 127)

def get_binstr(a):
    binstr = list(format(abs(a), '08b'))
    if(dl1_weights[i][j] < 0):
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

denselayer_1_file_name = "../../../../../net/np/k_14_dense_1_0.txt"
denselayer_2_file_name = "../../../../../net/np/k_17_dense_2_0.txt"

DL1_INPUT_NEURONS = 1568
DL1_OUTPUT_NEURONS = 32
DL2_INPUT_NEURONS = 32
DL2_OUTPUT_NEURONS = 10

dl1_weights_file = open(denselayer_1_file_name, 'r')
dl1_weights = np.array(list(map(quantize, np.loadtxt(dl1_weights_file)))).reshape((DL1_INPUT_NEURONS, DL1_OUTPUT_NEURONS))
dl1_weights_file.close()

dl2_weights_file = open(denselayer_2_file_name, 'r')
dl2_weights = np.array(list(map(quantize, np.loadtxt(dl2_weights_file)))).reshape((DL2_INPUT_NEURONS, DL2_OUTPUT_NEURONS))
dl2_weights_file.close()

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
    for j in range(0, DL2_OUTPUT_NEURONS):
        binstr = get_binstr(dl2_weights[i][j])
        line += binstr
    dl2_mif_file.write(line + "\n")
    
dl2_mif_file.close()