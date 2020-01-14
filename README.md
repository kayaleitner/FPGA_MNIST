# MNIST on FPGA

![General CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/CI/badge.svg)
![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/Python%20package/badge.svg)

This is a university project at TU Vienna to create a neural network hardware accelerator with an FPGA.

## Tasks

✅Train a Neural Network using Python
✅Verfiy all the calculations
✅Prepare Linux for the Zedboard
✅Write the basic Neural Network Operations in VHDL
🟨Write a custom driver for the FPGA
🟨Setup FPGA to communicate with PC or use embedded Linux
🟨Verfiy VHDL implementation
🟨Optimize Network: Fixed Point
🟨Optimize Network: Parallelization and Pipelining
⬜️Install driver, python and setup software on the zedboard

### Optional Tasks

🟨Webinterface for Easy Control
⬜️Backpropagation on FPGA
⬜️Custom Pytorch Extension to use the FPGA from within Torch
⬜️CI Pipeline for VHDL/Vivado Build & Tests

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
