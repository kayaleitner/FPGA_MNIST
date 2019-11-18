# Toolchain file for cross compile
#
# Found https://forums.xilinx.com/t5/Xilinx-Evaluation-Boards/Xilinx-SDK-2017-4-CMake/td-p/893672

SET(CMAKE_SYSTEM_NAME "Linux")
SET(CMAKE_SYSTEM_VERSION 1)

set (CMAKE_SYSTEM_NAME      "Linux")

# specify the cross compiler
set (CMAKE_SYSTEM_PROCESSOR "arm")
set (CROSS_PREFIX           "arm-linux-gnueabihf-")

set (CMAKE_MAKE_PROGRAM     "C:/Xilinx/SDK/2017.4/gnuwin/bin/make.exe" CACHE PATH "" FORCE)
set (CMAKE_C_COMPILER       "${CROSS_PREFIX}gcc" CACHE PATH "" FORCE)
set (CMAKE_CXX_COMPILER     "${CROSS_PREFIX}g++" CACHE PATH "" FORCE)
set (CMAKE_ASM_COMPILER     "${CROSS_PREFIX}gcc" CACHE PATH "" FORCE)
set (CMAKE_AR               "${CROSS_PREFIX}ar" CACHE FILEPATH "Archiver")

set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM	NEVER)
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY	NEVER)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE	NEVER)