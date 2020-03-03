################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/dma-proxy.c \
../src/eggnet.c \
../src/eggnet_wrap.c 

OBJS += \
./src/dma-proxy.o \
./src/eggnet.o \
./src/eggnet_wrap.o 

C_DEPS += \
./src/dma-proxy.d \
./src/eggnet.d \
./src/eggnet_wrap.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 Linux gcc compiler'
	arm-linux-gnueabihf-gcc -Wall -O0 -g3 -I"C:\Users\benjaminkulnik\Developer\FPGA_MNIST\vivado\Software\sysroots\plnx_arm-tcbootstrap\usr\include" -I"C:\Users\benjaminkulnik\Developer\FPGA_MNIST\vivado\Software\sysroots\miniconda\include\python3.4m" -c -fmessage-length=0 -MT"$@" -fPIC -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


