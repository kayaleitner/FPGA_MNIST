cmake_minimum_required(VERSION 3.10)
project(EggnetDriver C)



###### Setup ######
# Doc:
# https://cmake.org/cmake/help/latest/command/find_package.html

# Find Pthreads
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
find_package(Python REQUIRED COMPONENTS Interpreter Development NumPy)
# find_package(Python 3.6 REQUIRED COMPONENTS Interpreter Devlopment NumPy)


add_library(
    EggnetDriver STATIC
    attr.c
    base.c
    dma-proxy.c
    eggdbg.c
    eggdma.c
    eggstatus.c
    helper.c
    mem.c
)
target_link_libraries(EggnetDriver PUBLIC pthread)
target_include_directories(EggnetDriver PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# Add the python wrapper
add_library(PyEggnetDriver SHARED eggnet_wrap.c)
target_include_directories(PyEggnetDriver 
    PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR} 
    ${Python_INCLUDE_DIRS} 
    ${Python_NumPy_INCLUDE_DIRS}
)
target_link_libraries(PyEggnetDriver PRIVATE EggnetDriver ${Python_LIBS})


