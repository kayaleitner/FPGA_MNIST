#
# CMake Toolchain for Cross-Compiling from Windows to Linux-ARM-v7
#

# Setup system
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
# set(CMAKE_SYSTEM_VERSION 1)

set(XILINX_TOOL_PATH "C:/Xilinx/SDK/2017.4/gnu/aarch32/nt/gcc-arm-linux-gnueabi/bin")
set(XILINX_TC_PREFIX arm-linux-gnueabihf)

# 
# set(MYROOT ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/plnx_arm-tcbootstrap/sysroot-providers)
set(MYROOT ${CMAKE_SOURCE_DIR}/sysroots)
set(CMAKE_SYSROOT ${MYROOT})


# this needs to be set
# https://stackoverflow.com/questions/53633705/cmake-the-c-compiler-is-not-able-to-compile-a-simple-test-program
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_MAKE_PROGRAM C:/Xilinx/SDK/2017.4/gnuwin/bin/make.exe)
set(CMAKE_BUILD_TYPE "Debug")



# specify the cross compiler
set(CMAKE_C_COMPILER    ${XILINX_TOOL_PATH}/${XILINX_TC_PREFIX}-gcc.exe CACHE PATH "" FORCE)
set(CMAKE_CXX_COMPILER  ${XILINX_TOOL_PATH}/${XILINX_TC_PREFIX}-g++.exe CACHE PATH "" FORCE)
set(CMAKE_ASM_COMPILER  ${XILINX_TOOL_PATH}/${XILINX_TC_PREFIX}-gcc.exe CACHE PATH "" FORCE)
set(CMAKE_AR            ${XILINX_TOOL_PATH}/${XILINX_TC_PREFIX}-ar.exe CACHE PATH "" FORCE)
set(CMAKE_LINKER        ${XILINX_TOOL_PATH}/${XILINX_TC_PREFIX}-ld.exe CACHE PATH "" FORCE)


# set(COMPILE_FLAGS "-lrt -Wall -lpthread")
# set(CMAKE_THREAD_PREFER_PTHREAD TRUE) 


# where is the target environment 
set(CMAKE_FIND_ROOT_PATH  ${MYROOT})
# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)