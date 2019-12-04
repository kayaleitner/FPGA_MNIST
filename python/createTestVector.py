import numpy as np
from numpy.random import rand
from numpy import *
from pathlib import Path
import csv

# activation function? if we'd use ReLU with grayscale images the value stays
# the same

# This script creates a .csv file in the work directory
# containing integer numbers in the following form
# Input X  : x1, x2, x3, ... xN_inputlayer
# Weight W1: w11, w12, w13, ... w1N_inputlayer
# Weight W1: w21, w22, w23, ... w2N_inputlayer
# ...
# Weight W1: wN_hiddenlayer1, wN_hiddenlayer2 ... wN_hiddenlayerN_inputlayer
# Weight W2: w11, w12, ... w1hiddenlayer;
# Weight W2: ...
# Weight W2: wN_inputlayer1, ... wN_inputlayerN_hiddenlayer
# Output Y : y1, y2, y3, ... yN_outputlayer;

## Parameters
N_inputlayer = 28*28;   # Nodes Input Layer
N_outputlayer = N_inputlayer; # Nodes Output Layer
N_hiddenlayer = 200; # Nodes Hidden Layer
file_name = "test_vectors" # name of .csv file

# Neural Network consits of Input Layer, Hidden Layer, Output Layer
# Input Layer has 28 * 28 = 784 nodes
# Hidden Layer has a abitrary number of nodes, we choose 200
# Output Layer has 784 nodes

## Input Layer
X = floor(rand(1,N_inputlayer)*256);    #create 784 random Pixels range 0:255
W1 = floor(rand(N_inputlayer,N_hiddenlayer)*256);  #create 784 randoms weights 200 times

## Hidden Layer
H1 = X.dot(W1); #multiply Pixels with s_weights
H1 =  floor(H1 / 255);

W2 = floor(rand(N_hiddenlayer,N_inputlayer)*256); # create 200 random weights 784 times

## Output layer
Y = floor(H1.dot(W2) / 255); # multiplay hidden layer with weights to

#write Data to .csv file
#path = str(Path().absolute()) + "\\" + file_name + ".csv";

with open(file_name + ".csv", 'w', newline = '') as csvFile:
    writer = csv.writer(csvFile)
    for x in X:
        writer.writerow(x.astype(integer))

    for w1 in W1.transpose():
        writer.writerow(w1.astype(integer))

    for w2 in W2.transpose():
        writer.writerow(w2.astype(integer))

    for y in Y:
        writer.writerow(y.astype(integer))
