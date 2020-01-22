cmake_minimum_required(VERSION 3.10)
project(EggnetDriver C)

# Disable using default system libraries
set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "")
set(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES "")

add_library(eggnet_driver
    eggnet/eggnet.c
)

find_library(pthreads REQUIRED)


set_target_properties(eggnet_driver PROPERTIES LINKER_LANGUAGE C)

target_include_directories(eggnet_driver
                           PUBLIC sysroots/plnx_arm-tcbootstrap/usr/include/ eggnet/ ${PTHREAD_INCLUDE_DIR})

target_link_directories(eggnet_driver
                        PUBLIC sysroots/plnx_arm-tcbootstrap/usr/lib ${PTHREAD_LINK_DIR})