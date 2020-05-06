# -*- coding: utf-8 -*-
"""
Top Level VUNIT
===============


Created on Mon Mar 23 12:20:15 2020

@author: lukas
@author: Benjamin
"""

import os
import pathlib
from vunit import VUnit

# import vcd.gtkw as gtkw


ROOT = pathlib.Path(__file__).parent
SRC_ROOT = pathlib.Path(__file__).parent / 'src'
SIM_ROOT = pathlib.Path(__file__).parent / 'sim'

# --- Setup VUNIT
VU = VUnit.from_argv()


# Enable location preprocessing but exclude all but check_false to make the example less bloated
VU.enable_location_preprocessing()
VU.enable_check_preprocessing()
VU.add_osvvm()  # Add support for OSVVM


lib = VU.add_library("EggNet", vhdl_standard="08")

# -------------------------- 
# -- Setup Libraries
# --------------------------

lib.add_source_files(SRC_ROOT / "AXI_Stream_Master" / "*.vhd")
lib.add_source_files(SRC_ROOT / "AXI-lite" / "*.vhd")
lib.add_source_files(SRC_ROOT / "bram_vhdl" / "*.vhd")
lib.add_source_files(SRC_ROOT / "Common" / "*.vhd")
# lib.add_source_files(SRC_ROOT / "ConvLayer" / "*.vhd")
# lib.add_source_files(SRC_ROOT / "DenseLayer" / "*.vhd")
lib.add_source_files(SRC_ROOT / "MemCtrl" / "*.vhd")
lib.add_source_files(SRC_ROOT / "MemCtrl_Conv_to_Dense" / "*.vhd")
lib.add_source_files(SRC_ROOT / "PoolingLayer" / "*.vhd")
lib.add_source_files(SRC_ROOT / "ReluLayer" / "*.vhd")
lib.add_source_files(SRC_ROOT / "ShiftRegister" / "*.vhd")
# lib.add_source_files(SRC_ROOT / "TopLevel" / "*.vhd")


# -------------------------- 
# -- Setup Testbenches
# --------------------------

# -- Setup Generics
# VU.set_generic("DATA_WIDTH", 3)
lib.add_source_files(SIM_ROOT / "PoolingLayer" / "*.vhd")
# tb_hpool = lib.test_bench('tb_hpool').set_generic()


# -------------------------- 
# -- Setup Compile Options
# --------------------------

VU.set_compile_option("ghdl.a_flags", ["--ieee=synopsys"])
# for ghdl wavefrom use ["--wave=output.ghw"]
VU.set_sim_option("ghdl.sim_flags", ["--vcd=output.vcd"], allow_empty=True)
# VU.set_sim_option("ghdl.elab_run", ["--vcd=output.vcd", "-frelaxed", "-frelaxed-rules"], allow_empty=True)
# wave = gtkw.GTKWSave('output.vcd') # Not working yet



if __name__ == "__main__":
    VU.main()

