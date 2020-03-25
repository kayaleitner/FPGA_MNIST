# -*- coding: utf-8 -*-
"""
Created on Sat Dec 21 14:41:54 2019

@author: lukas
"""
import subprocess
import os
from shutil import copytree


import numpy as np
import random


# %% run simulation
def run_ghdl_linux(filenames,tb_entity,vcd_name="output.vcd"):
   """
    runs the testbench using ghdl and saves the output of ghdl in tmp/ghdl.log
    ATTENTION: Function not tested yet!
    Doublecheck if shell=True work on linux!

    Parameters
    ----------
    filenames : tuple of strings
        filenames of the vhdl files .
    tb_entity : string
        entity name of the testbench.
    vcd_name : string, optional
        name of the vcd output file. The default is "output.vcd".

    Returns
    -------
    None.

    """

   if not os.path.isdir('tmp'):
       try : os.mkdir('tmp')
       except : print("Error creating tmp folder!")

   command_s = "ghdl -s --workdir=tmp"
   command_a = "ghdl -a --workdir=tmp"
   for i in filenames:
       command_s = command_s + " " + i
       command_a = command_a + " " + i

   command_e = "ghdl -e --workdir=tmp " +  tb_entity
   command_r =  "ghdl -r --workdir=tmp " +  tb_entity + " --vcd=tmp/" + vcd_name
   print(command_s)
   print(command_a)
   print(command_e)
   print(command_r)


   with open("tmp/ghdl.log","a+") as f:
       subprocess.run(command_s,shell=True, stdout=f, text=True, check=True)
       subprocess.run(command_a,shell=True, stdout=f, text=True, check=True)
       subprocess.run(command_e,shell=True, stdout=f, text=True, check=True)
       subprocess.run(command_r,shell=True, stdout=f, text=True, check=True)

def run_ghdl_win(filenames,tb_entity,vcd_name="output.vcd"):
    """
    runs the testbench using ghdl and saves the output of ghdl in tmp/ghdl.log

    Parameters
    ----------
    filenames : tuple of strings
        filenames of the vhdl files .
    tb_entity : string
        entity name of the testbench.
    vcd_name : string, optional
        name of the vcd output file. The default is "output.vcd".

    Returns
    -------
    None.

    """
    if not os.path.isdir('tmp'):
       try : os.mkdir('tmp')
       except : print("Error creating tmp folder!")

    command_s = "ghdl -s --workdir=tmp"
    command_a = "ghdl -a --workdir=tmp"
    for i in filenames:
       command_s = command_s + " " + i
       command_a = command_a + " " + i

    command_s = command_s + " > tmp\ghdl.log"
    command_a = command_a + " > tmp\ghdl.log"
    command_e = "ghdl -e --workdir=tmp " +  tb_entity +" > tmp\ghdl.log"
    command_r =  "ghdl -r --workdir=tmp " +  tb_entity + " --vcd=tmp/" + vcd_name +" > tmp\ghdl.log"
    print(command_s)
    print(command_a)
    print(command_e)
    print(command_r)

    if not os.path.isfile("tmp\ghdl.log"):
        open("tmp\ghdl.log", 'w').close()

    os.popen("cmd")
    subprocess.run(command_s,shell=True, check=True)
    subprocess.run(command_a,shell=True, check=True)
    subprocess.run(command_e,shell=True, check=True)
    subprocess.run(command_r,shell=True, check=True)
    #with open("tmp/ghdl.log","a+") as f:

def run_vivado_sim_win():
    """
    runs the testbench using vivado and saves the output of vivado in
    tmp/sim.log
    This function is specially tailored for the tb_memctrl testbench.
    If anything changes reexport the simulation in vivado. The shell commands
    can be found in tb_memctrl.sh and the path of the files in vlog.prj and in
    vhdl.prj


    Parameters
    ----------


    Returns
    -------
    None.

    """
    print("Start simulation")
    print(os.getcwd())
    if not os.path.isdir('tmp'):
       try : os.mkdir('tmp')
       except : print("Error creating tmp folder!")

    copytree('xsim', 'tmp/xsim') # copy xsim folder to generate output products in tmp folder

    os.chdir('tmp/xsim')

    compile_vlog = "xvlog --relax -prj vlog.prj 2>&1 | tee compile.log"
    compile_vhdl = "xvhdl --relax -prj vhdl.prj 2>&1 | tee compile.log"
    elaborate = 'xelab --relax --debug typical --mt auto -L blk_mem_gen_v8_4_1'\
        ' -L xil_defaultlib -L fifo_generator_v13_2_1 -L unisims_ver -L'\
        ' unimacro_ver -L secureip -L xpm --snapshot tb_memctrl'\
        ' xil_defaultlib.tb_memctrl xil_defaultlib.glbl -log elaborate.log'
    simulate = "xsim tb_memctrl -key {Behavioral:sim_1:Functional:tb_memctrl} -tclbatch cmd.tcl -log simulate.log"


    err_verilog = subprocess.Popen(compile_vlog,shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if err_verilog.poll() == None:
        print("Wait till process finished..")
        err_verilog.wait(timeout=60.0)

    if err_verilog.returncode != 0:
        out, err = err_verilog.communicate()
        err_verilog.kill()
        print(out)
        print(err)
    else:
        print("compile verilog files done!")

    err_vhdl = subprocess.Popen(compile_vhdl,shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if err_vhdl.poll() == None:
        print("Wait till process finished..")
        err_vhdl.wait(timeout=60.0)

    if err_vhdl.returncode != 0:
        out, err = err_vhdl.communicate()
        err_vhdl.kill()
        print(out)
        print(err)
    else:
        print("compile vhdl files done!")

    #err_elaborate = subprocess.Popen(elaborate,shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    # if err_elaborate.poll() == None: 
    #     print("Wait till process finished..")
    #     err_elaborate.wait(timeout=60.0)

    # if err_elaborate.returncode != 0:
    #     out, err = err_elaborate.communicate()
    #     err_elaborate.kill()
    #     print(out)
    #     print(err)
    # else:
    #     print("elaborate design done!")

    subprocess.call(elaborate,shell=True)
    subprocess.call(simulate,shell=True) # For some reason simulation doesn't work with Popen


    os.chdir('../..')
    print(os.getcwd())
    print("End simulation")

# %% wirte to file
def gen_testdata(blocksize,blocknumber,chans,filename="testdata",drange=255,dtype=np.uint8):
    """
    Generates random testdata to be used in the testbench

    Parameters
    ----------
    blocksize : integer
        size of each data block.
    blocknumber : integer
        number of generated blocks.
    chans : integer
        number of input channels
    filename : string, optional
        file name. The default is "testdata".
    drange : integer, optional
        range of random numbers. The default is 255.
    dtype : numpy type, optional
        data type of returned numpy array. The default is np.uint8.

    Returns
    -------
    random_data: numpy array
        generated random number.

    """
    random_data = np.zeros((blocknumber,blocksize,chans),dtype=dtype)
    for k in range(chans):
        with open("tmp/"+ filename + str(k) + ".txt","a+") as f:
            for i in range(blocknumber):
                for j in range(blocksize):
                    random_data[i,j,k] = random.randrange(drange)
                    f.write("{}\n".format(random_data[i,j,k]))
    return random_data

def write_features_to_file(features,filename="feature_map",layernumber=1):
    """


    Parameters
    ----------
    features: numpy array [B,W*H,Co] dtype=np.uint8
        B.. Batch size
        W*H.. Image width times hight
        Co.. output channel number

        feature matrix

    filename : string, optional
        file name. The default is "feature_map"

    Returns
    -------
    None.

    """
    (nbatch, npixel, nchannels) = features.shape

    # TODO The ordering of the values is too important to be left without a comment
    for i in range(nchannels):
        with open("tmp/"+filename+"_L{}".format(layernumber) +"_c{}.txt".format(i),"a+") as f:
            for j in range(nbatch):
                for k in range(npixel):
                    f.write("{}\n".format(features[j,k,i]))


# %% memory controller

def get_vectors_from_data(test_data,img_width,img_hight,kernel_size=3,dtype=np.uint8):
    """
    Generates 3x1 vectors from test data

    Parameters
    ----------
    test_data : numpy array
        generated test data.
    img_width : integer
        with of test matrix.
    img_hight : integer
        hight of test matrix.
    kernel_size : integer, optional
        size of the kernel. The default is 3.
    dtype : numpy dtype, optional
        Data type of numpy array. The default is np.uint8.

    Returns
    -------
    vectors : numpy array
        Vector to compare with the output of the memory controller

    """
    nbatch, image_height_width, nchannels = test_data.shape
    vectors = np.zeros((nbatch,image_height_width,kernel_size,nchannels), dtype=dtype)
    for i in range(nbatch):
        vector_cnt = 0
        for j in range(image_height_width):

            if j < img_width:  # Upper image border
                vectors[i,vector_cnt,0,:] = 0
                vectors[i,vector_cnt,1,:] = test_data[i,j,:]
                vectors[i,vector_cnt,2,:] = test_data[i,j+img_width,:]
                vector_cnt += 1
            elif j >= (img_width*(img_hight-1)): # Lower Image Border
                #print(j)
                vectors[i,vector_cnt,0,:] = test_data[i,j-img_width,:]
                vectors[i,vector_cnt,1,:] = test_data[i,j,:]
                vectors[i,vector_cnt,2,:] = 0
                vector_cnt += 1
            else:
                vectors[i,vector_cnt,0,:] = test_data[i,j-img_width,:]
                vectors[i,vector_cnt,1,:] = test_data[i,j,:]
                vectors[i,vector_cnt,2,:] = test_data[i,j+img_width,:]
                vector_cnt += 1

    return vectors

def get_Kernels(test_vectors,img_width):
    """
    Creates 3x3 kernel which is operated by the conv2d

    Parameters
    ----------
    test_vectors : numpy array
        Generated test vectors 3x1.
    img_width : integer
        with of test matrix.
    Returns
    -------
    Kernel : numpy array
        Kernel to compare with the output of the shiftregister

    """
    kernels = np.zeros((test_vectors.shape[0],test_vectors.shape[1],test_vectors.shape[2],test_vectors.shape[2],test_vectors.shape[3]),dtype=np.uint8)
    for i in range(test_vectors.shape[0]):
        for j in range(test_vectors.shape[1]):
            if j%img_width == 0:
                kernels[i,j,:,0,:] = 0
                kernels[i,j,:,1,:] = test_vectors[i,j,:,:]
                kernels[i,j,:,2,:] = test_vectors[i,j+1,:,:]

            elif j%img_width == img_width-1:
                kernels[i,j,:,0,:] = test_vectors[i,j-1,:,:]
                kernels[i,j,:,1,:] = test_vectors[i,j,:,:]
                kernels[i,j,:,2,:] = 0
            else:
                kernels[i,j,:,0,:] = test_vectors[i,j-1,:,:]
                kernels[i,j,:,1,:] = test_vectors[i,j,:,:]
                kernels[i,j,:,2,:] = test_vectors[i,j+1,:,:]

    return kernels


# %% convolutional layer

def conv_2d(kernels,weights,msb,bias,data_width=8, shifts=None):
    """
    Emulates the operation carried out by the conv2d module in the FPGA

    Parameters
    ----------
    kernel : numpy array [B,W*H,Kh,Kw,Ci]
        B.. Batch size
        W*H.. Image width times hight
        Kh.. Kernel hight
        Kw.. Kernel width
        Ci.. channel number
        Input kernels
    weights : numpy array [Co,Ci,Kh,Kw]
        Co.. output channel number
        Ci.. input channel number
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel
    msb : numpy array [Co,Ci]
        Co.. output channel number
        MSB values for quantization

    Returns
    -------
    features: numpy array [B,W*H,Co] dtype=np.uint8
        B.. Batch size
        W*H.. Image width times hight
        Co.. output channel number

        8 bit output Matrix
    """
    features = np.zeros((kernels.shape[0],kernels.shape[1],weights.shape[0]),dtype=np.uint8)
    for i in range(kernels.shape[0]):
        for j in range(kernels.shape[1]):
            for k in range (weights.shape[0]):
                features[i,j,k] = conv_channel(kernels[i,j,:,:,:],weights[k,:,:,:],msb[k],data_width, bias[k], shifts=shifts)
    return features



def conv_channel(kernels,weights,msb,data_width=8, bias = 0, shifts=None):
    """
    Emulates the operation carried out by the conv_channel module in the FPGA

    Parameters
    ----------
    kernels : numpy array [B,W*H,Kh,Kw,Ci]
        B.. Batch size
        W*H.. Image width times hight
        Kh.. Kernel hight
        Kw.. Kernel width
        Ci.. channel number
        Input kernels
    weights : numpy array [Ci,Kh,Kw]
        Ci.. input channel number
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel
    msb : integer
        MSB postion for quantization

    Returns
    -------
    weighted_sum: np.uint8
        B.. Batch size
        W*H.. Image width times hight

        8 bit output Matrix
    """
    weighted_sum = np.int32(0)
    for k in range (weights.shape[0]):
        weighted_sum+= kernel_3x3(kernels[:,:,k],weights[k,:,:])
    weighted_sum += bias

    # Relu (Additional benefit np.int16(int("0x00FF",16)) & feature would not work for negative numbers because of 2's complement)
    if weighted_sum < 0:
        weighted_sum = 0
    else: # Quantization
        # assert msb+1-data_width == shifts
        weighted_sum >>= msb+1-data_width
        if weighted_sum > int(2**data_width - 1):
            weighted_sum = int(2**data_width - 1)

    return np.uint8(weighted_sum)


def kernel_3x3(kernel,weights):
    """
    Emulates the operation carried out by the 3x3_kernel module in the FPGA

    Parameters
    ----------
    kernel : numpy array [Kh,Kw]
        Kh.. Kernel hight
        Kw.. Kernel width
        Input kernels
    weights : numpy array [Kh,Kw]
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel

    Returns
    -------
    weighted_sum: np.int16
        16 bit output Matrix
    """
    # TODO I Think here is the bug: image has shape [H,W] but weights have [W,H]
    weighted_sum = np.int32(np.sum(kernel * weights))
    return weighted_sum

# %% Result checks
def check_bram(test_data,layernumber):
    """
    checks the 

    Parameters
    ----------
    test_data : numpy array [B,W*H,Ci]
        Data to check. Content of BRAM
    layernumber : integer
        Number of layer

    Returns
    -------
    error_count : interger
        Number of errors.

    """
    BLOCK_SIZE = test_data.shape[1]
    error_count = 0
    for i in range(test_data.shape[0]):
        with open("tmp/l{}".format(layernumber) + "_bram{}.txt".format(i),"r") as f:
            for j in range(test_data.shape[0]*2):
                block_select = 1-(i+1)%2
                read_data = f.readline().rstrip()
                result_data = [int(g) for g in read_data.split(' ')]
                for k in range(test_data.shape[2]):
                    if block_select == 0 and j<BLOCK_SIZE:
                         if result_data[k] != test_data[i,j,k]:
                             print("Error in block {}".format(i) + " channel {}".format(k) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                                    + "{}".format(result_data[k]) + " != {}".format(test_data[i,j,k]))
                             error_count += 1
                    elif block_select == 0 and j>=BLOCK_SIZE and i==0:
                        if result_data[k] != 0:
                             print("Error in block {}".format(i) + " channel {}".format(k) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                                    + "{}".format(result_data[k]) + " != {}".format(0))
                             error_count += 1
                    elif block_select == 0 and j>=BLOCK_SIZE:
                        if result_data[k] != test_data[i-1,j-BLOCK_SIZE,k]:
                             print("Error in block {}".format(i) + " channel {}".format(k) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                                    + "{}".format(result_data[k]) + " != {}".format(test_data[i-1,j-BLOCK_SIZE,k]))
                             error_count += 1
                    elif block_select == 1 and j<BLOCK_SIZE:
                         if result_data[k] != test_data[i-1,j,k]:
                             print("Error in block {}".format(i) + " channel {}".format(k) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                                    + "{}".format(result_data[k]) + " != {}".format(test_data[i-1,j,k]))
                             error_count += 1
                    elif block_select == 1 and j>=BLOCK_SIZE:
                        if result_data[k] != test_data[i,j-BLOCK_SIZE,k]:
                             print("Error in block {}".format(i) + " channel {}".format(k) + " in line {} ,".format(j+block_select*BLOCK_SIZE) \
                                    + "{}".format(result_data[k]) + " != {}".format(test_data[i,j-BLOCK_SIZE,k]))
                             error_count += 1
                    else:
                            print("Error in porgram")

    if error_count == 0:
        print("No errors in BRAM")
    else:
        print("{} errors occured checking BRAM".format(error_count))

    return error_count

def check_vectors(test_vectors,layernumber):
    """
    

    Parameters
    ----------
    test_vectors : numpy array [B,W*H,3,Ci]
        Data to check. Output data of MemCtrl
    layernumber : integer
        Number of layer.

    Returns
    -------
    error_count_vectors : integer
        Number of errors.

    """
    error_count_vectors = 0
    result_vectors = np.zeros((test_vectors.shape[0],test_vectors.shape[1],test_vectors.shape[2],test_vectors.shape[3]),dtype=np.uint8)
    for i in range(test_vectors.shape[0]):
        with open("tmp/l{}".format(layernumber) + "_inVector_1_b{}.txt".format(i),"r") as f:
            for j in range(test_vectors.shape[1]):
                read_data = f.readline().rstrip()
                result_vectors[i,j,0,:] = [int(g) for g in read_data.split(' ')]
                if any(result_vectors[i,j,0,:] != test_vectors[i,j,0,:]):
                    print("Error in tmp/l{}".format(layernumber) + "_inVector_1_b{}.txt" + " in line {} ,".format(j) \
                                + "{}".format(result_vectors[i,j,0,:]) + " != {}".format(test_vectors[i,j,0,:]))
                    error_count_vectors += 1
        with open("tmp/l{}".format(layernumber) + "_inVector_2_b{}.txt".format(i),"r") as f:
            for j in range(test_vectors.shape[1]):
                read_data = f.readline().rstrip()
                result_vectors[i,j,1,:] = [int(g) for g in read_data.split(' ')]
                if any(result_vectors[i,j,1,:] != test_vectors[i,j,1,:]):
                    print("Error in tmp/l{}".format(layernumber) + "_inVector_1_b{}.txt" + " in line {} ,".format(j) \
                                + "{}".format(result_vectors[i,j,1,:]) + " != {}".format(test_vectors[i,j,1,:]))
                    error_count_vectors += 1
        with open("tmp/l{}".format(layernumber) + "_inVector_3_b{}.txt".format(i),"r") as f:
            for j in range(test_vectors.shape[1]):
                read_data = f.readline().rstrip()
                result_vectors[i,j,2,:] = [int(g) for g in read_data.split(' ')]
                if any(result_vectors[i,j,2,:] != test_vectors[i,j,2,:]):
                    print("Error in tmp/l{}".format(layernumber) + "_inVector_1_b{}.txt" + " in line {} ,".format(j) \
                                + "{}".format(result_vectors[i,j,2,:]) + " != {}".format(test_vectors[i,j,2,:]))
                    error_count_vectors += 1
    if error_count_vectors == 0:
        print("Received Kernel vectors successfully!")
    else:
        print("{} errors occured receiving image".format(error_count_vectors))

    return error_count_vectors

def check_kernels(test_kernels,layernumber):
    """
    

    Parameters
    ----------
    test_kernels : numpy array [B,W*H,3,3,Ci]
        Data to check. Output data of shiftreg
    layernumber : TYPE
        DESCRIPTION.

    Returns
    -------
    error_count_kernels : TYPE
        DESCRIPTION.

    """
    error_count_kernels = 0
    result_kernels = np.zeros((test_kernels.shape[0],test_kernels.shape[1],test_kernels.shape[2],test_kernels.shape[3],test_kernels.shape[4]),dtype=np.uint8)
    for i in range(result_kernels.shape[0]):
        file_cnt = 0
        for k in range(test_kernels.shape[2]):
            for h in range(test_kernels.shape[3]):
                file_cnt += 1
                with open("tmp/l{}".format(layernumber) + "_inKernel_{}".format(file_cnt) + "_b{}.txt".format(i),"r") as f:
                    for j in range(result_kernels.shape[1]):
                        read_data = f.readline().rstrip()
                        result_kernels[i,j,h,k,:] = [int(g) for g in read_data.split(' ')]
                        if any(result_kernels[i,j,h,k,:] != test_kernels[i,j,h,k,:]):
                            print("Error in l{}".format(layernumber) + "_inKernel_{}".format(file_cnt) + "_b{}".format(i) + " in line {} ,".format(j) \
                                        + "{}".format(result_kernels[i,j,h,k,:]) + " != {}".format(test_kernels[i,j,h,k,:]))
                            error_count_kernels += 1

    if error_count_kernels == 0:
        print("Received Kernel from shiftregister successfully!")
    else:
        print("{} errors occured receiving image".format(error_count_kernels))

    return error_count_kernels

# %% Mov average attemption 
class FIFO:
    """
    Creates a FIFO
    size: size of fifo
    wrte(data) : writes data into fifo
    read(): reads data from fifo
    """
    def __init__(self, size):
        self.content = np.zeros(int(size))
        self.size = size
        self.rd_pointer = 0
        self.wr_pointer = 0
    def write(self,data):
        wr_pointer = self.wr_pointer + 1
        if wr_pointer >= self.size:
            wr_pointer = 0
        if wr_pointer == self.rd_pointer:
            print("FIFO FULL",data,wr_pointer)
        else:
            self.wr_pointer = wr_pointer
            self.content[wr_pointer] = data
    def read(self):
        if self.rd_pointer == self.wr_pointer:
            print("FIFO empty")
        else:
            data = self.content[self.rd_pointer]
            self.rd_pointer -= 1
            if self.rd_pointer < 0:
                self.rd_pointer = self.size -1
            return data

class MovingAverageFilter:
    """
    Moving average filter
    size: window size
    do_filter(data) : return the new filter value
    """
    def __init__(self, size):
        self.FIFO = FIFO(size)
        self.size = size
        self.counter = 0
        self.sum = 0

    def do_filter(self,data):
        self.counter += 1
        self.sum += data
        if self.counter >= self.size:
            self.sum -= self.FIFO.read()
            self.counter -= 1

        self.FIFO.write(data)
#        print(data,self.sum/self.size)
        return self.sum/self.size

class Data_collector:
    def __init__(self):
        self.data = np.array(0)
    def add(self,data):
        self.data = np.append(self.data,data)
    def get(self):
        return self.data


class Find_MSB:
    """
    Iterative MSB search
    """
    def __init__(self):
        self.comparator = int(0b1)
        self.MSB = 1

    def do(self, data):
        if data > self.comparator:
            print("up ",self.comparator,data)
            self.comparator <<= 1
            self.MSB += 1
        elif data < (self.comparator >> 1):
            print("down ",self.comparator,data)
            self.comparator >>= 1
            self.MSB -= 1
        return self.MSB

class Counter:
    def __init__(self):
        self.underflow = 0
        self.overflow = 0
    def cnt_underflow(self):
        self.underflow += 1
    def cnt_overflow(self):
        self.overflow += 1
    def show(self):
        print("Number of overlfows",self.overflow)
        print("Number of underflow",self.underflow)


def conv_2d_mov_av(kernels,weights,data_collecotr):
    """
    Emulates the operation carried out by the conv2d module in the FPGA

    Parameters
    ----------
    kernel : numpy array [B,W*H,Kh,Kw,Ci]
        B.. Batch size
        W*H.. Image width times hight
        Kh.. Kernel hight
        Kw.. Kernel width
        Ci.. channel number
        Input kernels
    weights : numpy array [Co,Ci,Kh,Kw]
        Co.. output channel number
        Ci.. input channel number
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel

    Returns
    -------
    features: numpy array [B,W*H,Co] dtype=np.uint8
        B.. Batch size
        W*H.. Image width times hight
        Co.. output channel number

        8 bit output Matrix
    """
    features = np.zeros((kernels.shape[0],kernels.shape[1],weights.shape[0]),dtype=np.uint8)
    mav_filter = [ MovingAverageFilter(32) for i in range(weights.shape[0])]
    msb_detect = [ Find_MSB() for i in range(weights.shape[0])]
    cnt = Counter()
    for i in range(kernels.shape[0]):
        for j in range(kernels.shape[1]):
            for k in range (weights.shape[0]):
                features[i,j,k] = conv_channel(kernels[i,j,:,:,:],weights[k,:,:,:],mav_filter[k],msb_detect[k],cnt,data_collecotr)
    cnt.show()
    return features



def conv_channel_mov_av(kernels,weights,mav_filter,msb_detect,cnt,data_collecotr):
    """
    Emulates the operation carried out by the conv_channel module in the FPGA

    Parameters
    ----------
    kernels : numpy array [B,W*H,Kh,Kw,Ci]
        B.. Batch size
        W*H.. Image width times hight
        Kh.. Kernel hight
        Kw.. Kernel width
        Ci.. channel number
        Input kernels
    weights : numpy array [Ci,Kh,Kw]
        Ci.. input channel number
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel
    mav_filter : MovingAverageFilter class
        Moving average filter to normalize conv_channel output
    msb_detect : Find_MSB class
        detects msb of average iterative

    Returns
    -------
    weighted_sum: np.int16
        B.. Batch size
        W*H.. Image width times hight

        8 bit output Matrix
    """
    weighted_sum = np.int32(0)
    for k in range (weights.shape[0]):
        weighted_sum+= kernel_3x3(kernels[:,:,k],weights[k,:,:])

    #weighted_sum -= np.int16(mav_filter.do_filter(np.abs(weighted_sum)))
    data_collecotr.add(weighted_sum)
    average = np.int32(mav_filter.do_filter(np.abs(weighted_sum)))
    msb = msb_detect.do(average)
    # Relu (Additional benefit np.int16(int("0x00FF",16)) & feature would not work for negative numbers because of 2's complement)
    if weighted_sum < 0:
        weighted_sum = 0
    else:
       if msb > 8:
           #print(msb,msb-7,average,weighted_sum,weighted_sum>> msb-8)
           weighted_sum >>= 7 #(msb-8)


       if weighted_sum > 255:
           weighted_sum = 255
           cnt.cnt_overflow()
       elif weighted_sum == 0:
           cnt.cnt_underflow()

    return np.uint8(weighted_sum)



def kernel_3x3_mov_av(kernel,weights):
    """
    Emulates the operation carried out by the 3x3_kernel module in the FPGA

    Parameters
    ----------
    kernel : numpy array [Kh,Kw]
        Kh.. Kernel hight
        Kw.. Kernel width
        Input kernels
    weights : numpy array [Kh,Kw]
        Kh.. Kernel hight
        Kw .. Kernel with
        Weigth matrix for each kernel

    Returns
    -------
    weighted_sum: np.int16
        16 bit output Matrix
    """
    weighted_sum = np.int32(np.sum(kernel * weights))

    return weighted_sum