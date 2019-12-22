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
       

   subprocess.run(command_s,shell=True, check=True)
   subprocess.run(command_a,shell=True, check=True)
   subprocess.run(command_e,shell=True, check=True)   
   subprocess.run(command_r,shell=True, check=True)
   #with open("tmp/ghdl.log","a+") as f:       
   
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

random_data = gen_testdata(783,3)
print(random_data)