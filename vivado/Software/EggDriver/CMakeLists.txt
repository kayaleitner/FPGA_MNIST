cmake_minimum_required(VERSION 3.10)
project(EggnetDriver C)



###### Setup ######
# Doc:
# https://cmake.org/cmake/help/latest/command/find_package.html
# Find Pthreads

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
find_package(Python 3.6 REQUIRED COMPONENTS Interpreter Devlopment NumPy)
find_package(SWIG REQUIRED)
include(UseSWIG)

# This triggers the -fPIC flag, which is required for some sort of dynamic linking?
# https://wiki.gentoo.org/wiki/Project:AMD64/Fixing_-fPIC_Errors_Guide
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

##################################
# Pure C Version of the Library
##################################
add_library(
    EggnetDriver 
    STATIC
        src/attr.c
        src/base.c
        src/eggdma.c
        src/eggnet.c
        src/eggstatus.c
        src/helper.c
        src/mem.c
)

# Sometimes CMake messes up local header files, so manually specify to use the source root as a Include Directory
target_include_directories(EggnetDriver PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# See: http://swig.org/Doc4.0/Python.html#Python_nn4
# Link with pthreads
target_link_libraries(EggnetDriver PUBLIC pthreads)


# Just a test executable
add_executable(EggnetTest src/main.c)
target_link_libraries(EggnetTest PUBLIC EggnetDriver)



##################################
# Python Module of the Library with SWIG
##################################
swig_add_library(PyEggnetDriver
    LANGUAGE python
    SOURCES
        src/eggnet.i
        src/attr.c
        src/base.c
        src/eggdma.c
        src/eggnet.c
        src/eggstatus.c
        src/egguio.c
        src/helper.c
        src/mem.c
)

target_include_directories(${SWIG_MODULE_EggnetDriver_REAL_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
    PUBLIC_HEADER
        ${Python_INCLUDE_DIR}
        ${NumPy_INCLUDE_DIR}
)
target_link_libraries(${SWIG_MODULE_EggnetDriver_REAL_NAME} PUBLIC pthread)

# target_link_libraries(PyEggnetDriver PRIVATE python3.6m)
#set_property(TARGET PyEggnetDriver PROPERTY POSITION_INDEPENDENT_CODE ON)
#set_property(TARGET EggnetDriver PROPERTY SWIG_COMPILE_OPTIONS -py3)
#set_property(TARGET EggnetDriver PROPERTY SWIG_SUPPORT_FILES_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
#set_property(TARGET EggnetDriver PROPERTY SWIG_OUTFILE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib)

add_custom_command(TARGET ${SWIG_MODULE_EggnetDriver_REAL_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:${SWIG_MODULE_EggnetDriver_REAL_NAME}> ${CMAKE_CURRENT_SOURCE_DIR}/lib
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_BINARY_DIR}/EggNetDriverCore.py ${CMAKE_CURRENT_SOURCE_DIR}/lib
)
