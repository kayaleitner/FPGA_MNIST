# MNIST on FPGA

![GitHub](https://img.shields.io/github/license/marbleton/FPGA_MNIST)

![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/Python/badge.svg)
![Python-Package CI Badge](https://github.com/marbleton/FPGA_MNIST/workflows/VHDL%20Testbenches/badge.svg)

This is a university project at TU Vienna to create a neural network hardware accelerator with an FPGA.
The network is designed and trained using _Pytorch_ and _Keras_ in Python.
Using _Xilinx Vivado_ the Neural Network is implemented on _Digilent Zedboard_ featuring a Zynq-7000 ARM/FPGA SoC.
The FPGA-Net can be controlled via a Webinterface based on Python Flask.  
For more details see the [Specification Document](tex/documentation/documentation.pdf)

## Authors

Baischer Lukas, Leitner Anton, Kulnik Benjamin, Marschner Stefan, Cerv Miha

## Project Structure

`net`: Here is everything stored that is relevant for training and designing the network. Pretrained netork parameters are available for _torch_, _keras_ and in _numpy_ format.

`vivado`:
This is the main project folder where the VHDL implementaiton of the neural network is stored. Additionally the linux driver software source files are stored in `vivado/Software`. For compiling and running the testbenches **ghdl 0.3.7**  and **Vivado 2017.4** have been used. Additional python is needed to generate some of the source files or to run some
testbenches.

`python`:
This folder contains support software to verify the network. All basic network operations like 2d convolutions and poolingis reprogrammed. This is not necessary but helped to understand the internal functioning of the opaque interfaces of _keras_ and _pytorch_.

`webapp`:
Here the Web app control software is stored. It is based on _Flask_ and the _LTEAdmin_. Here images can be upladed
the netork evaluates it and sends back the result.

`tex`:
Contains the documentation of the project in Latex format. A precompiled PDF is available.

`data`:
Contains project data, e.g. the _MNIST_ dataset.

## Software Overview


```text
+----------------------------+    +-----------------------------+
|  CPU   +-----------------+ |    |                             |
|        |                 | |    |                             |
|        |    Flask        | |    |                             |
|        |                 | |    |                             |
|        +------+-+--------+ |    |                             |
|               ^ |          |    |                             |
|               | |          |    |     FPGA                    |
|               | v          |    |     Eggnet Implementation   |
|        +------+-+--------+ |    |                             |
|        |                 +----->+                             |
|        |   EggNet Driver | |    |                             |
|        |                 +<-----+                             |
|        +-----------------+ |    |                             |
+----------------------------+    +-----------------------------+
```

## Tasks

- [x] Train a Neural Network using Python
- [x] Verfiy all the calculations
- [x] Prepare Linux for the Zedboard
- [x] Write the basic Neural Network Operations in VHDL
- [x] Write a custom driver for the FPGA
- [x] Setup FPGA to communicate with PC or use embedded Linux
- [x] Verfiy VHDL implementation
- [x] Optimize Network: Fixed Point
- [ ] Optimize Network: Parallelization and Pipelining
- [ ] Install driver, python and setup software on the zedboard

### Optional Tasks

Other nice to have features, which will be tried to implement, if there is enough time.

- [x] Webinterface for Easy Control
- [ ] Backpropagation on FPGA
- [ ] Custom Pytorch Extension to use the FPGA from within Torch
- [x] CI Pipeline for VHDL/Vivado Build & Tests

## Top Level Overview

![System Overview](tex/documentation/svg-extract/1-NN-concept_svg-tex.png "Top Level Overview")

For more details see the [Specification Document](tex/documentation/documentation.pdf)

## Build


### Requirements

- Vivado 2017.4, for creating the FPGA implemenation
- Python, >3.6 + packages in `python/requirements.txt`
- C11 compiler for the Python Swig Extension
- GHDL: For VHDL testbench simulation checking

### Python Support Package with SWIG Extension

To accelerate certain neural network functions (conv2d, pool, etc.) those are reprogrammed in C and wrapped via SWIG. 
See `python/README.md` for more details on this topic.

### Vivado Project

Open Vivado and select: `Execute Tcl Script`. Navigate to `vivado/project`. If problems occur use the cleanup script
in the folder (either `cleanup.sh` for Linux/Unix or `cleanup.cmd` for Windows). The bitstream can then be generated in
Vivado as usual.

### Linux Kernel Driver

First the python wrapper must be created using swig. Make sure `SWIG >4.0` is installed and run the commands inside a 
terminal:

````shell script
cd projeckt/Software/eggnet
swig -python eggnet.i
````

This should create two files, `eggnet_wrap.c` and `EggnetDriverCore.py`. The first one must then be build togehter 
with the rest of the project using the Vivado SDK or CMake.

## Additional Information and Further Reading

Backpropagation in CNNs:

- https://jefkine.com/general/2016/09/05/backpropagation-in-convolutional-neural-networks/
- https://medium.com/the-bioinformatics-press/only-numpy-understanding-back-propagation-for-max-pooling-layer-in-multi-layer-cnn-with-example-f7be891ee4b4
- A guide to convolution arithmetic for deep learning: https://arxiv.org/pdf/1603.07285.pdf

Vanishing Gradients Problem:

- https://www.jefkine.com/general/2018/05/21/2018-05-21-vanishing-and-exploding-gradient-problems/

Large-scale Learning with SVM and Convolutional Nets for Generic Object Categorization:

- http://yann.lecun.com/exdb/publis/pdf/huang-lecun-06.pdf