# How to use Xilinx SDK with Linux

## Create Test project in Xilinx SDK
1. Copy sysroots for your SDK workspace for linux libraries   
If you are using a virutal machine for petalinux then you have to enable symlinks in your virtual box shared folder  
Copy the sysroots folder from <plnx-proj-root>/build/tmp to your shared folder  
Then copy the sysroots folder to your SDK project workspace
2. Create new Application Project in the SDK  
![Linux Application Project](file://fig/createLinApp.PNG)
3. Enable Linux System Root and define your systemroots 
4. For pthread.h following setting is necassary in linker Flags (-pthread):  
![Linux Application Project](file://fig/pthread.PNG)

## Setting up connection to board using SSH 
1. Open run configurations 
2. Create new Remote ARM Linux Application (If not visible disable Filter configuration types)
3. Create new connection 
4. Select SSH only --> Next 
5. Set Host name to IP address of baord 
6. Give a meaningful connection name and description --> Next --> Finish
7. Set Remote Absolute File Path for C/C++ application using browse 
8. Expand root --> Connection starts --> User ID = root --> no password 
9. New Window opens password is root 
10. select destination folder for your application (example: /tmp/dma-proxy.elf)
10. Press run
