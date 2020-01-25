# MNIST on FPGA

![GitHub](https://img.shields.io/github/license/marbleton/FPGA_MNIST)

![General CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/CI/badge.svg)
![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/Python/badge.svg)
![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/VHDL%20Testbenches/badge.svg)




This is a university project at TU Vienna to create a neural network hardware accelerator with an FPGA.

## Tasks

- [x] Train a Neural Network using Python
- [x] Verfiy all the calculations
- [x] Prepare Linux for the Zedboard
- [x] Write the basic Neural Network Operations in VHDL
- [ ] Write a custom driver for the FPGA
- [ ] Setup FPGA to communicate with PC or use embedded Linux
- [ ] Verfiy VHDL implementation
- [ ] Optimize Network: Fixed Point
- [ ] Optimize Network: Parallelization and Pipelining
- [ ] Install driver, python and setup software on the zedboard

### Optional Tasks

- [ ] Webinterface for Easy Control
- [ ] Backpropagation on FPGA
- [ ] Custom Pytorch Extension to use the FPGA from within Torch
- [ ] CI Pipeline for VHDL/Vivado Build & Tests

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

## Neural Network Architecture
