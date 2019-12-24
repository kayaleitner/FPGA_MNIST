#!/usr/bin/env python
"""
setup.py file for SWIG Interface of Ext

"""
import os
import platform
import numpy
from setuptools import setup, Extension, find_packages

from setup_utils import download_numpy_interface, readme, SwigExtension

try:
    # Obtain the numpy include directory.  This logic works across numpy versions.
    numpy_include = numpy.get_include()
except AttributeError:
    numpy_include = numpy.get_numpy_include()

# Download numpy.i if needed
if not os.path.exists('NeuralNetwork/Ext/numpy.i'):
    print('Downloading numpy.i')
    project_dir = os.path.dirname(os.path.abspath(__file__))
    i_numpy_path = os.path.join(project_dir, 'NeuralNetwork', 'Ext')
    download_numpy_interface(path=i_numpy_path)

source_files = ['./NeuralNetwork/Ext/NNExtension.i', './NeuralNetwork/Ext/cconv.c',
                './NeuralNetwork/Ext/cpool.c', './NeuralNetwork/Ext/crelu.c',
                './NeuralNetwork/Ext/cmatmul.c', './NeuralNetwork/Ext/chelper.c']
source_files = [os.path.abspath(sfile) for sfile in source_files]
include_dirs = ['./NeuralNetwork/Ext/', numpy_include]

# Simple Platform Check (not entirely accurate because here should the compiler be checked)
# ToDo: Should be done better for example via CMake -> https://www.benjack.io/2017/06/12/python-cpp-tests.html
if platform.system() == 'Linux':
    extra_args = []
elif platform.system() == 'Darwin':
    extra_args = ['--verbose', '-Rpass=loop-vectorize', '-Rpass-analysis=loop-vectorize', '-ffast-math']
elif platform.system() == 'Windows':
    extra_args = []
else:
    raise RuntimeError('Operating System not supported?')
extra_link_args = []

NN_ext_module = SwigExtension('NeuralNetwork/Ext/' + '_NeuralNetworkExtension',
                              sources=source_files,
                              include_dirs=include_dirs,
                              swig_opts=['-py3'],
                              extra_compile_args=extra_args,
                              extra_link_args=extra_link_args)

setup(name='NeuralNetwork',
      version='1.0',
      author="Benjamin Kulnik",
      author_email="benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""NN calculation library for python""",
      url='https://github.com/marbleton/FPGA_MNIST',
      long_description=readme(),
      long_description_content_type="text/markdown",
      py_modules=["NeuralNetwork"],
      packages=find_packages(),
      ext_modules=[NN_ext_module],
      requires=['numpy', 'wget', 'flask', 'tensorflow', 'keras', 'torch', 'torchvision', 'scipy',
                'git+https://github.com/Xilinx/brevitas.git'],
      install_requires=['numpy', 'wget'],
      )

print("Finished")
