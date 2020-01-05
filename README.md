# MNIST on FPGA

![General CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/CI/badge.svg)
![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/Python%20package/badge.svg)
![GitHub](https://img.shields.io/github/license/marbleton/FPGA_MNIST)

This is a university project at TU Vienna to create a neural network hardware accelerator with an FPGA.

## Goals

- Setup FPGA to communicate with PC or use embedded Linux
- Implement Forward & Backward Propagation in Python to ensure functionality
- Create VHDL files for the various operations
- Handle on board communication
- Make all calculations efficient by using pipelined calculations

## Top Level Overview

![System Overview](tex/specification/svg-extract/1-NN-concept_svg-tex.png "Top Level Overview")

For more details see the [Specification Document](tex/specification/specification.pdf)

## Build

For a quickstart run the script `bootstrap.sh`.

### Requirements

- Vivado, at least 2017.4, for creating the FPGA implemenation
- Python, >3.6 + packages in `python/requirements.txt`
- C11 compiler for the Python Swig Extension
- GHDL: For VHDL testbench simulation checking

### Python with SWIG Extension

To accelerate certain neural network functions (conv2d, pool, etc.) those are reprogrammed in C and wrapped via SWIG. See `python/README.md` for more details on this topic.
