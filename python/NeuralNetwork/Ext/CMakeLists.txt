cmake_minimum_required(VERSION 3.14)
project(NeuralNetworkExtension)

#cmake_policy(CMP0086 )

add_library(
    nn STATIC
    chelper.c
    cmatmul.c
    cpool.c
    crelu.c
    cconv.c
)


add_executable(scratch scratch.c)
target_link_libraries(scratch PRIVATE nn)

find_package(Python REQUIRED COMPONENTS Interpreter Development NumPy)
find_package(SWIG REQUIRED)

include(UseSWIG)


swig_add_library(pyext
    LANGUAGE python
    SOURCES NNExtension.i
)

target_include_directories(${SWIG_MODULE_pyext_REAL_NAME}  PRIVATE ${Python_INCLUDE_DIRS} ${Python_NumPy_INCLUDE_DIRS} .)
target_link_libraries(${SWIG_MODULE_pyext_REAL_NAME} PRIVATE nn ${Python_LIBRARIES})