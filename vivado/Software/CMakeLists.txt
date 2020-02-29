cmake_minimum_required(VERSION 3.10)
project(EggnetDriver C)

# Disable using default system libraries
#set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "")
#set(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES "")

# Set global Include Directories
include_directories(
    ${CMAKE_SOURCE_DIR}/eggnet/
    ${CMAKE_SOURCE_DIR}/sysroots/usr/include/
    ${CMAKE_SOURCE_DIR}/sysroots/usr/include/arm-linux-gnueabihf
    # Use the paths below if the zedboard is conencted via SAMBA or similiar
    #T:/include/arm-linux-gnueabihf
    #T:/include
)

link_directories(BEFORE
    ${CMAKE_SOURCE_DIR}/sysroots/lib/
    ${CMAKE_SOURCE_DIR}/sysroots/usr/lib/arm-linux-gnueabihf
    ${CMAKE_SOURCE_DIR}/sysroots/usr/lib/
    #T:/lib/arm-linux-gnueabihf    
    #T:/lib
)



add_library(eggnet_driver
    STATIC
    eggnet/eggnet.c
)

add_executable(egghello eggnet/egghello.c)
target_link_directories(egghello  BEFORE PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/sysroots/usr/lib/arm-linux-gnueabihf)

# Create the wrapper library
add_library(eggnet_py_wrapper SHARED eggnet/eggnet_wrap.c)


# Add the python include directory
target_include_directories(eggnet_py_wrapper 
    PRIVATE
    eggnet/
    sysroots/miniconda/include/python3.4m
)

# Specify the directory to search libraries
target_link_directories(eggnet_py_wrapper
    PRIVATE    
    sysroots/miniconda/lib/
)

# Link against our eggnet_driver and python
target_link_libraries(eggnet_py_wrapper PRIVATE eggnet_driver python3.4m)