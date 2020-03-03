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


add_library(
    EggnetDriver STATIC
    attr.c
    base.c
    # dma-proxy.c
    eggdbg.c
    eggdma.c
    eggstatus.c
    helper.c
    mem.c
)


target_include_directories(
    EggnetDriver 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/arm-linux-gnueabihf
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_directories(
    EggnetDriver
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/lib/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/lib/arm-linux-gnueabihf
)

# Link with pthreads
target_link_libraries(EggnetDriver PUBLIC pthreads)


# Add the python wrapper
add_library(PyEggnetDriver SHARED eggnet_wrap.c)

target_include_directories(
    PyEggnetDriver 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/arm-linux-gnueabihf
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/include/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/numpy_include
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/python3.6/include/python3.6m
    PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_directories(PyEggnetDriver
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/usr/lib/
    ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/linux/lib/arm-linux-gnueabihf
    ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/python3.6/lib
)

target_link_libraries(PyEggnetDriver PRIVATE EggnetDriver python3.6m)


