# -*- coding: utf-8 -*-
"""
Created on Sun Jan  5 14:24:56 2020

@author: lukas

Generates random test data to test the memory controller and runs the 
simulation test the module using ghdl 
"""

# %% public imports
import os 
import shutil
import numpy as np

# %% import custom modules
import vhdl_testbench as tb 

# %% parameter
KEEP_TEMPORARY_FILES = True
IMG_WIDTH = 28
IMG_HIGTH = 28
KERNEL_SIZE = 3
BLOCK_SIZE = IMG_WIDTH*IMG_HIGTH
NUMBER_OF_TEST_BLOCKS = 3
CI_L1 = 1
CO_L1 = 16

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
weights_L1 = np.ones((CO_L1,CI_L1,KERNEL_SIZE,KERNEL_SIZE),dtype=np.int8)
weights_L1[:,:,1,:] = 0
weights_L1[:,:,2,:] = -1
features_L1 = tb.conv_2d(test_kernels,weights_L1)
             
# %% run ghdl 
# Saving console ouput in log file is not working on windows            
tb.run_vivado_sim_win()


# %% check results 
error_count_rec_images = 0

for i in range(NUMBER_OF_TEST_BLOCKS):
    with open("tmp/bram{}.txt".format(i),"r") as f:
        for j in range(2*BLOCK_SIZE):
            block_select = 1-(i+1)%2
            result_data = int(f.readline())
            if block_select == 0 and j<BLOCK_SIZE:
                 if result_data != image_data[i,j]:
                     print("Error in block {}".format(i) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                            + "{}".format(result_data) + " != {}".format(image_data[i,j]))
                     error_count_rec_images += 1
            elif block_select == 0 and j>=BLOCK_SIZE and i==0:
                if result_data != 0:
                     print("Error in block {}".format(i) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                            + "{}".format(result_data) + " != {}".format(0))
                     error_count_rec_images += 1
            elif block_select == 0 and j>=BLOCK_SIZE:
                if result_data != image_data[i-1,j-BLOCK_SIZE]:
                     print("Error in block {}".format(i) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                            + "{}".format(result_data) + " != {}".format(image_data[i-1,j-BLOCK_SIZE]))
                     error_count_rec_images += 1           
            elif block_select == 1 and j<BLOCK_SIZE:
                 if result_data != image_data[i-1,j]:
                     print("Error in block {}".format(i) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                            + "{}".format(result_data) + " != {}".format(image_data[i-1,j]))
                     error_count_rec_images += 1
            elif block_select == 1 and j>=BLOCK_SIZE:
                if result_data != image_data[i,j-BLOCK_SIZE]:
                     print("Error in block {}".format(i) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                            + "{}".format(result_data) + " != {}".format(image_data[i,j-BLOCK_SIZE]))
                     error_count_rec_images += 1   
            else:
                    print("Error in porgram")
                    
if error_count_rec_images == 0:
    print("Received image data successfully!")
else:
    print("{} errors occured receiving image".format(error_count_rec_images))    
      
# %% check memory controller output 
error_count_vectors = 0
result_vectors = np.zeros((test_vectors.shape[0],test_vectors.shape[1],test_vectors.shape[2]),dtype=np.uint8)
for i in range(NUMBER_OF_TEST_BLOCKS):
    with open("tmp/m_layer_data1_b{}.txt".format(i),"r") as f:
        for j in range(test_vectors.shape[1]):
            result_vectors[i,j,0] = int(f.readline())
            if result_vectors[i,j,0] != test_vectors[i,j,0]:
                print("Error in m_layer_data1_b{}".format(i) + " in line {} ,".format(j) \
                            + "{}".format(result_vectors[i,j,0]) + " != {}".format(test_vectors[i,j,0]))
                error_count_vectors += 1
    with open("tmp/m_layer_data2_b{}.txt".format(i),"r") as f:
        for j in range(test_vectors.shape[1]):
            result_vectors[i,j,1] = int(f.readline())
            if result_vectors[i,j,1] != test_vectors[i,j,1]:
                print("Error in m_layer_data1_b{}".format(i) + " in line {} ,".format(j) \
                            + "{}".format(result_vectors[i,j,1]) + " != {}".format(test_vectors[i,j,1]))
                error_count_vectors += 1        
    with open("tmp/m_layer_data3_b{}.txt".format(i),"r") as f:
        for j in range(test_vectors.shape[1]):
            result_vectors[i,j,2] = int(f.readline())
            if result_vectors[i,j,2] != test_vectors[i,j,2]:
                print("Error in m_layer_data1_b{}".format(i) + " in line {} ,".format(j) \
                            + "{}".format(result_vectors[i,j,2]) + " != {}".format(test_vectors[i,j,2]))
                error_count_vectors += 1                
if error_count_vectors == 0:
    print("Received Kernel vectors successfully!")
else:
    print("{} errors occured receiving image".format(error_count_vectors))     

    
# %% check memory shiftregister output 
error_count_kernels = 0
result_kernels = np.zeros((test_kernels.shape[0],test_kernels.shape[1],test_kernels.shape[2],test_kernels.shape[3]),dtype=np.uint8)
for i in range(result_kernels.shape[0]):
    file_cnt = 0
    for k in range(test_kernels.shape[2]):
        for h in range(test_kernels.shape[3]):
            file_cnt += 1
            with open("tmp/shift_data{}".format(file_cnt) + "_b{}.txt".format(i),"r") as f:
                for j in range(result_kernels.shape[1]):
                    result_kernels[i,j,h,k] = int(f.readline())
                    if result_kernels[i,j,h,k] != test_kernels[i,j,h,k,0]:
                        print("Error in shift_data{}".format(file_cnt) + "_b{}".format(i) + " in line {} ,".format(j) \
                                    + "{}".format(result_kernels[i,j,h,k]) + " != {}".format(test_kernels[i,j,h,k,0]))
                        error_count_kernels += 1
    
if error_count_kernels == 0:
    print("Received Kernel from shiftregister successfully!")
else:
    print("{} errors occured receiving image".format(error_count_kernels)) 

      
# %% delete tmp folder 
error_count = error_count_rec_images + error_count_vectors
if not KEEP_TEMPORARY_FILES and error_count == 0:
    shutil.rmtree('tmp')
