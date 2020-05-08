cmake_minimum_required(VERSION 3.10)
project(EggnetDriver C)



###### Setup ######
# Doc:
# https://cmake.org/cmake/help/latest/command/find_package.html
# Find Pthreads
#set(THREADS_PREFER_PTHREAD_FLAG ON)
#find_package(Threads REQUIRED)
# find_package(Python REQUIRED COMPONENTS Interpreter Development NumPy)
#find_package(Python 3.6 REQUIRED COMPONENTS Interpreter Devlopment NumPy)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# https://wiki.gentoo.org/wiki/Project:AMD64/Fixing_-fPIC_Errors_Guide
add_library(
    EggnetDriver STATIC
        src/attr.c
        src/base.c
        src/eggdma.c
        src/eggnet.c
        src/eggstatus.c
        src/helper.c
        src/mem.c
)


add_executable(EggnetTest src/main.c)
target_link_libraries(EggnetTest PUBLIC EggnetDriver)

target_include_directories(
    EggnetDriver
        BEFORE
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/arm-linux-gnueabihf
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# See: http://swig.org/Doc4.0/Python.html#Python_nn4
#
target_link_directories(
    EggnetDriver
        BEFORE
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/lib/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/lib/arm-linux-gnueabihf
)

# Link with pthreads
target_link_libraries(EggnetDriver PUBLIC pthreads)


# Add the python wrapper
add_library(PyEggnetDriver MODULE
        src/attr.c
        src/base.c
        src/eggdma.c
        src/eggnet.c
        src/eggstatus.c
        src/helper.c
        src/mem.c
        src/eggnet_wrap.c)

target_include_directories(
    PyEggnetDriver
        BEFORE
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/arm-linux-gnueabihf
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/numpy_include/include/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/python3.6/include/python3.6m
    PRIVATE
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_directories(PyEggnetDriver
        BEFORE PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/lib/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/lib/arm-linux-gnueabihf
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/python3.6/lib
)

target_link_libraries(PyEggnetDriver PRIVATE python3.6m)
set_property(TARGET PyEggnetDriver PROPERTY POSITION_INDEPENDENT_CODE ON)


