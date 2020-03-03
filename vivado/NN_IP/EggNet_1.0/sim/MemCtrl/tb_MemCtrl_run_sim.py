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
import subprocess
import platform
import matplotlib.pyplot as plt

# %% import custom modules
import vhdl_testbench as tb

# %% parameter
KEEP_TEMPORARY_FILES = True
IMG_WIDTH = 28
IMG_HIGTH = 28
KERNEL_SIZE = 3
BLOCK_SIZE = IMG_WIDTH * IMG_HIGTH
NUMBER_OF_TEST_BLOCKS = 3
CI_L1 = 1
CO_L1 = 16


def main():
    # %% create tmp folder, delete folder if not tmp exists and create new one
    if os.path.isdir('tmp'):
        shutil.rmtree('tmp')

    try:
        os.mkdir('tmp')
    except:
        print("Error creating tmp folder!")

    # %% create test data file
    image_data = np.uint8(np.random.normal(0, 0.3, size=(NUMBER_OF_TEST_BLOCKS, BLOCK_SIZE, CI_L1)) * 256)
    tb.write_features_to_file(image_data, layernumber=1)
    # image_data = tb.gen_testdata(BLOCK_SIZE,NUMBER_OF_TEST_BLOCKS)

    # %% generate test vectors layer 1
    test_vectors_l1 = tb.get_vectors_from_data(image_data, IMG_WIDTH, IMG_HIGTH)

    # %% generate test kernels layer 1
    test_kernels_l1 = tb.get_Kernels(test_vectors_l1, IMG_WIDTH)
    # %% calculate Layer output as new memory controller input
    weights_L1 = np.int8(np.random.normal(0, 0.3, size=(CO_L1, CI_L1, KERNEL_SIZE, KERNEL_SIZE)) * 128)
    msb = np.ones(CO_L1, dtype=np.int32) * 15
    features_l2 = tb.conv_2d(test_kernels_l1, weights_L1, msb)

    tb.write_features_to_file(features_l2, layernumber=2)
    # %% generate test vectors layer 2
    test_vectors_l2 = tb.get_vectors_from_data(features_l2, IMG_WIDTH, IMG_HIGTH)

    # %% generate test kernels layer 2
    test_kernels_l2 = tb.get_Kernels(test_vectors_l2, IMG_WIDTH)

    # %% run ghdl
    # Saving console ouput in log file is not working on windows

    filenames = ["tb_memctrl.vhd", "../../src/bram_vhdl/bram.vhd", "../../src/MemCtrl/MemCtrl.vhd",
                 "../../src/MemCtrl/Shiftregister_3x3.vhd", "../../src/Fifo_vhdl/fifo_dist_ram.vhd",
                 "../../src/MemCtrl/MemCtrl_AXIS.vhd"]

    tb_entity = "tb_memctrl"

    if has_ghdl():
        tb.run_ghdl(filenames, tb_entity)

    if has_vivado():
        tb.run_vivado_sim_win()

    # %% check bram layer 1
    error_count_bram_l1 = tb.check_bram(image_data, 1)

    # %% check memory controller output layer 1
    error_count_vectors_l1 = tb.check_vectors(test_vectors_l1, 1)

    # %% check memory shiftregister output
    error_count_kernels_l1 = tb.check_kernels(test_kernels_l1, 1)

    error_count_l1 = error_count_bram_l1 + error_count_vectors_l1 + error_count_kernels_l1
    # %% check bram layer 2
    error_count_bram_l2 = tb.check_bram(features_l2, 2)

    # %% check memory controller output layer 1
    error_count_vectors_l2 = tb.check_vectors(test_vectors_l2, 2)

    # %% check memory shiftregister output
    error_count_kernels_l2 = tb.check_kernels(test_kernels_l2, 2)

    error_count_l2 = error_count_bram_l2 + error_count_vectors_l2 + error_count_kernels_l2
    # %% delete tmp folder
    error_count = error_count_l1 + error_count_l2

    if not KEEP_TEMPORARY_FILES and error_count == 0:
        shutil.rmtree('tmp')

    msg = f"""
Simulation finished

Layer 1
----------------------------------
Error BRAM L1:          {error_count_bram_l1}
Error Vectors L1:       {error_count_vectors_l1}
Error Kernels L1:       {error_count_kernels_l1}
Error BRAM L1:          {error_count_bram_l1}
------------------------------------
Total:                  {error_count_l1}

Layer 2
----------------------------------
Error BRAM L2:          {error_count_bram_l2}
Error Vectors L2:       {error_count_vectors_l2}
Error Kernels L2:       {error_count_kernels_l2}
Error BRAM L2:          {error_count_bram_l2}
------------------------------------
Total:                  {error_count_l2}


        """
    print(msg)
    if error_count != 0:
        raise Exception("Some Checks failed! \n\n" + msg)

def has_vivado():
    # Unfortunately only windows is supported for vivado.
    if platform.platform() == 'Windows':
        return True
    else:
        return False


def has_ghdl():
    # subprocess.check_output("ghdl --version")
    return 0 == subprocess.call(["ghdl", "--version"])


if __name__ == '__main__':
    main()
