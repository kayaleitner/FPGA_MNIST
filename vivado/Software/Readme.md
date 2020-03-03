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


## Usage Dockcross

Compilation can also happen via docker. See the [Dockcross Project](https://github.com/dockcross/dockcross) for details.
To compile this project run the following commands inside a terminal (and check your docker instance is running):

````shell script
mkdir build
docker run --rm dockcross/linux-armv7a > ./dockcross-linux-armv7a
chmod +x ./dockcross-linux-armv7a
dockcross-linux-armv7a cmake -Bbuild -Heggnet
dockcross-linux-armv7a cmake --build build
````
