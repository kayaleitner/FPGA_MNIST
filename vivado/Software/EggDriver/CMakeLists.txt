cmake_minimum_required(VERSION 3.15)
project(EggnetDriver)



###### Setup ######
# Doc:
# https://cmake.org/cmake/help/latest/command/find_package.html
# Find Pthreads
#set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
find_package(SWIG REQUIRED)
# find_package(Python REQUIRED COMPONENTS Interpreter Development NumPy)
#set(Python_ROOT_DIR ~/.pyenv/versions/3.6.10)
#set(Python_DIR ~/.pyenv/versions/3.6.10)
# find_package(Python  REQUIRED COMPONENTS Interpreter Development NumPy)

include(UseSWIG)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# https://wiki.gentoo.org/wiki/Project:AMD64/Fixing_-fPIC_Errors_Guide


swig_add_library(EggnetDriver
        LANGUAGE python
        SOURCES
            src/eggnet.i
            src/attr.c
            src/base.c
            src/eggdma.c
            src/eggnet.c
            src/eggstatus.c
            src/helper.c
            src/mem.c
            src/egg_event_handler.cpp
)
target_include_directories(${SWIG_MODULE_EggnetDriver_REAL_NAME}
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/numpy_include/include/
        ${CMAKE_CURRENT_SOURCE_DIR}/../sysroots/python3.6/include/python3.6m
)
target_link_libraries(${SWIG_MODULE_EggnetDriver_REAL_NAME}
        PUBLIC
        pthread
)

set_property(TARGET EggnetDriver PROPERTY SWIG_COMPILE_OPTIONS -py3)
set_property(TARGET EggnetDriver PROPERTY SWIG_SUPPORT_FILES_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set_property(TARGET EggnetDriver PROPERTY SWIG_OUTFILE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib)

add_custom_command(TARGET ${SWIG_MODULE_EggnetDriver_REAL_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:${SWIG_MODULE_EggnetDriver_REAL_NAME}> ${CMAKE_CURRENT_SOURCE_DIR}/lib
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_BINARY_DIR}/EggNetDriverCore.py ${CMAKE_CURRENT_SOURCE_DIR}/lib
)
