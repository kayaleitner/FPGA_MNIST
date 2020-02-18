# %% public imports
import os 
import shutil
import numpy as np
import matplotlib.pyplot as plt 

# %% import custom modules
import vhdl_testbench as tb 

def quantize(a):
    return min(max(int(a/0.002),-128), 127)

# %% parameter
KEEP_TEMPORARY_FILES = True
IMG_WIDTH = 28
IMG_HIGTH = 28
KERNEL_SIZE = 3
BLOCK_SIZE = IMG_WIDTH*IMG_HIGTH
NUMBER_OF_TEST_BLOCKS = 3
CI_L1 = 1
CO_L1 = 16

weights_file_name = "../../../../../net/np/k_3_conv2d_1_0.txt"

# %% create tmp folder, delete folder if not tmp exists and create new one
if os.path.isdir('tmp'):
    shutil.rmtree('tmp')
    
try : os.mkdir('tmp')
except : print("Error creating tmp folder!")

# %% create test data file
image_data = tb.gen_testdata(BLOCK_SIZE,NUMBER_OF_TEST_BLOCKS)

# %% generate test vectors 
test_vectors = tb.get_vectors_from_data(image_data,IMG_WIDTH,IMG_HIGTH,NUMBER_OF_TEST_BLOCKS)

# %% generate test kernels 
test_kernels = tb.get_Kernels(test_vectors,IMG_WIDTH)

# %% calculate Layer output as new memory controller input 
weights_file = open(weights_file_name, 'r')
weights = np.array(list(map(quantize, np.loadtxt(weights_file)))).reshape((3,3,CI_L1,CO_L1))
weights_file.close()

weights_reshaped = np.ndarray((CO_L1,CI_L1,3,3))
for i in range(0, CI_L1):
    for j in range(0, CO_L1):
        for x in range(0,KERNEL_SIZE):
            for y in range(0,KERNEL_SIZE):
                weights_reshaped[j][i][y][x] = weights[x][y][i][j]

conv2d_input_files = [None]*KERNEL_SIZE*KERNEL_SIZE
for i in range(0, KERNEL_SIZE*KERNEL_SIZE):
    conv2d_input_files[i] = open("tmp/conv2d_input" + str(i) + ".txt", "w")
    
for i in range(0, NUMBER_OF_TEST_BLOCKS):
    for j in range(0, IMG_WIDTH*IMG_HIGTH):
        for c in range(0, CI_L1):
            for x in range(0, KERNEL_SIZE):
                for y in range(0, KERNEL_SIZE):
                    num = y + x*KERNEL_SIZE
                    conv2d_input_files[num].write(str(test_kernels[i][j][x][y][c]) + "\n")
    
for i in range(0, KERNEL_SIZE*KERNEL_SIZE):
    conv2d_input_files[i].close()

#weights_L1 = np.int8(np.random.normal(0,0.3,size=(CO_L1,CI_L1,KERNEL_SIZE,KERNEL_SIZE))*128)
msb = np.ones(CO_L1,dtype=np.int32)*15
features_L1 = tb.conv_2d(test_kernels,weights_reshaped,msb)

tb.write_features_to_file(features_L1,layernumber=2)
      
# %% delete tmp folder 
if not KEEP_TEMPORARY_FILES and error_count == 0:
    shutil.rmtree('tmp')
