cmake_minimum_required(VERSION 3.14)
project(NeuralNetworkExtension C)

#cmake_policy(CMP0086 )
set (CMAKE_C_STANDARD 11)

find_package(Python REQUIRED COMPONENTS Interpreter Development NumPy)
find_package(SWIG REQUIRED)
include(UseSWIG)



# -------------------------
# Targets
# -------------------------


add_library(
    EggNetExtension_c STATIC
    chelper.c
    cmatmul.c
    cpool.c
    crelu.c
    cconv.c
)
target_compile_features(EggNetExtension_c PUBLIC c_restrict)

add_executable(scratch scratch.c)
target_link_libraries(scratch PRIVATE EggNetExtension_c)

add_executable(perfcheck perfcheck.c cpool.c cconv.c)
# target_link_libraries(perfcheck PRIVATE EggNetExtension_c)



swig_add_library(pyext
    LANGUAGE python
    SOURCES NNExtension.i
)

target_include_directories(${SWIG_MODULE_pyext_REAL_NAME}
        PRIVATE
        ${Python_INCLUDE_DIRS}
        ${Python_NumPy_INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}
)
target_link_libraries(${SWIG_MODULE_pyext_REAL_NAME} PRIVATE EggNetExtension_c ${Python_LIBRARIES})