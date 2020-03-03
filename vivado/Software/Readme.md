# How to use Xilinx SDK with Linux

## Create Test project in Xilinx SDK

01. Copy sysroots for your SDK workspace for linux libraries

If you are using a virutal machine for petalinux then you have to enable symlinks in your virtual box shared folder  
Copy the sysroots folder from <plnx-proj-root>/build/tmp to your shared folder  
Then copy the sysroots folder to your SDK project workspace

02. Create new Application Project in the SDK  

![Linux Application Project](file://fig/createLinApp. PNG)

03. Enable Linux System Root and define your systemroots 
04. For pthread.h following setting is necassary in linker Flags (-pthread):  

![Linux Application Project](file://fig/pthread. PNG)

## Setting up connection to board using SSH 

01. Open run configurations 
02. Create new Remote ARM Linux Application (If not visible disable Filter configuration types)
03. Create new connection 
04. Select SSH only --> Next 
05. Set Host name to IP address of baord 
06. Give a meaningful connection name and description --> Next --> Finish
07. Set Remote Absolute File Path for C/C++ application using browse 
08. Expand root --> Connection starts --> User ID = root --> no password 
09. New Window opens password is root 
10. select destination folder for your application (example: /tmp/dma-proxy.elf)
10. Press run


## Cross-Compile with CMAKE

### Setup Compiler Toolchain

Install the required compiler toolchain, which should be already installed if you use the Xilinx SDK. Alternative download the GNU compile utils for `arm-linux-gnueabihf`

Additionally you will need:

- SWIG, >4.0
- CMake, >3.10

### Setup Environment

To successfully cross compile the Linux Environment must be replicated on the host machine. Therefore all contents of the `/usr/` and `/lib/` folders should be copied.
This location of this folder must then be passed to CMake via a parameter or by modifing the toolchain file.
An example toolchain file which should work is provided in `cmake\xillinx-win-to-armv7-linux.cmake`.

### Preperations for the python wrapper

Run Swig and create a wrapper file

```bash
cd eggnet
swig -python eggnet.i
```

This should create a `eggnet_wrap.c` file and a `EggNetDriverCore.py`. The first one must be compiled using the toolchain and linked against the python version that should be used. The second one is a simple proxy file to make calling provided funtions more pythonic, e.g. by using keyword args.

### Build

First create a folder to build the setup:

```bash

mkdir build
cd build

cmake .. -T path/to/toolchain.cmake
cmake --build . name-of-target

```


### Using Dockcross

Compilation can also happen via docker. See the [Dockcross Project](https://github.com/dockcross/dockcross) for details.
To compile this project run the following commands inside a terminal (and check your docker instance is running):

````shell script
mkdir build
docker run --rm dockcross/linux-armv7a > ./dockcross-linux-armv7a
chmod +x ./dockcross-linux-armv7a
dockcross-linux-armv7a cmake -Bbuild -Heggnet
dockcross-linux-armv7a cmake --build build
````
