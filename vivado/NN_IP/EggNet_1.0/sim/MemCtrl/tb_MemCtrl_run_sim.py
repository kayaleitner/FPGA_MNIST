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

# %% create tmp folder, delete folder if not tmp exists and create new one
if os.path.isdir('tmp'):
    shutil.rmtree('tmp')
    
try : os.mkdir('tmp')
except : print("Error creating tmp folder!")

# %% create test data file

image_data = tb.gen_testdata(BLOCK_SIZE,NUMBER_OF_TEST_BLOCKS)
             
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
    
# %% generate test vectors 
test_vectors = tb.get_vectors_from_data(image_data,IMG_WIDTH,IMG_HIGTH,NUMBER_OF_TEST_BLOCKS)
    
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
# %% delete tmp folder 
error_count = error_count_rec_images + error_count_vectors
if not KEEP_TEMPORARY_FILES and error_count == 0:
    shutil.rmtree('tmp')
