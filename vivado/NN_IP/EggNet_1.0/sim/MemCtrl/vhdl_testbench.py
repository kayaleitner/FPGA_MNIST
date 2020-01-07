# -*- coding: utf-8 -*-
"""
Created on Sat Dec 21 14:41:54 2019

@author: lukas
"""
import subprocess
import os

import numpy as np
import random

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
    
    os.chdir('xsim')
    
    compile_vlog = "xvlog --relax -prj vlog.prj 2>&1 | tee compile.log"           
    compile_vhdl = "xvhdl --relax -prj vhdl.prj 2>&1 | tee compile.log"
    elaborate = 'xelab --relax --debug typical --mt auto -L blk_mem_gen_v8_4_1'\
        ' -L xil_defaultlib -L fifo_generator_v13_2_1 -L unisims_ver -L'\
        ' unimacro_ver -L secureip -L xpm --snapshot tb_memctrl'\
        ' xil_defaultlib.tb_memctrl xil_defaultlib.glbl -log elaborate.log'       
    simulate = "xsim tb_memctrl -key {Behavioral:sim_1:Functional:tb_memctrl} -tclbatch cmd.tcl -log simulate.log"            


    subprocess.call(compile_vlog,shell=True)
    subprocess.call(compile_vhdl,shell=True)
    subprocess.call(elaborate,shell=True)
    subprocess.call(simulate,shell=True)
    os.chdir('..')
    print(os.getcwd())
    print("End simulation")
             
def gen_testdata(blocksize,blocknumber,filename="testdata.txt",drange=255,dtype=np.uint8):
    """
    Generates random testdata to be used in the testbench 

    Parameters
    ----------
    blocksize : integer
        size of each data block.
    blocknumber : integer
        number of generated blocks.
    filename : string, optional
        file name. The default is "testdata.txt".
    drange : integer, optional
        range of random numbers. The default is 255.
    dtype : numpy type, optional
        data type of returned numpy array. The default is np.uint8.

    Returns
    -------
    random_data: numpy array
        generated random number.

    """
    random_data = np.zeros((blocknumber,blocksize),dtype=dtype)
    with open("tmp/"+filename,"a+") as f:
        for i in range(blocknumber):
            for j in range(blocksize):
                random_data[i,j] = random.randrange(drange)
                f.write("{}\n".format(random_data[i,j]))
    return random_data

def get_vectors_from_data(test_data,img_width,img_hight,blocknumber,kernel_size=3,dtype=np.uint8):
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
    blocknumber : integer
        number of blocks which are tested.
    kernel_size : integer, optional
        size of the kernel. The default is 3.
    drange : integer, optional
        Data. The default is 255.
    dtype : numpy dtype, optional
        Data type of numpy array. The default is np.uint8.

    Returns
    -------
    vectors : numpy array
        Vector to compare with the output of the memory controller 

    """
    vector_number_per_block = (img_width+(kernel_size-1))*(img_hight+kernel_size-1)
    vectors = np.zeros((blocknumber,vector_number_per_block,kernel_size),dtype=dtype)
    for i in range(blocknumber):
        vector_cnt = 0
        for j in range(img_width*(img_hight+2)):
            if j % img_width == 0 and j != 0:
                for k in range((kernel_size-1)):
                    vectors[i,vector_cnt,0] = 0
                    vectors[i,vector_cnt,1] = 0
                    vectors[i,vector_cnt,2] = 0
                    vector_cnt += 1
                    
            if j < img_width:  
                vectors[i,vector_cnt,0] = 0
                vectors[i,vector_cnt,1] = 0
                vectors[i,vector_cnt,2] = test_data[i,j]
                vector_cnt += 1
            elif j < img_width*2:  
                vectors[i,vector_cnt,0] = 0
                vectors[i,vector_cnt,1] = test_data[i,j-img_width]
                vectors[i,vector_cnt,2] = test_data[i,j]   
                vector_cnt += 1
            elif j >= (img_width*(img_hight+1)):
                vectors[i,vector_cnt,0] = test_data[i,j-2*img_width]
                vectors[i,vector_cnt,1] = 0
                vectors[i,vector_cnt,2] = 0      
                vector_cnt += 1
            elif j >= (img_width*img_hight):    
                #print(j)
                vectors[i,vector_cnt,0] = test_data[i,j-2*img_width]
                vectors[i,vector_cnt,1] = test_data[i,j-img_width]
                vectors[i,vector_cnt,2] = 0  
                vector_cnt += 1
            else:  
                vectors[i,vector_cnt,0] = test_data[i,j-2*img_width]
                vectors[i,vector_cnt,1] = test_data[i,j-img_width]
                vectors[i,vector_cnt,2] = test_data[i,j]   
                vector_cnt += 1
                
    return vectors

def get_Kernels(test_vectors):
    """
    Creates 3x3 

    Parameters
    ----------
    test_vectors : numpy array
        Generated test vectors 3x1.

    Returns
    -------
    Kernel : numpy array
        Kernel to compare with the output of the shiftregister

    """
    kernels = np.zeros((test_vectors.shape[0],test_vectors.shape[1],test_vectors.shape[2],test_vectors.shape[2]),dtype=np.uint8)
    for i in range(test_vectors.shape[0]):
        kernels[i,0,:,2] = test_vectors[i,0,:]
        for j in range(test_vectors.shape[1]-1):
            kernels[i,j+1,:,0] = kernels[i,j,:,1]
            kernels[i,j+1,:,1] = kernels[i,j,:,2]
            kernels[i,j+1,:,2] = test_vectors[i,j+1,:]
    return kernels