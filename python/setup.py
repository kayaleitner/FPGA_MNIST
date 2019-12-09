#!/usr/bin/env python
"""
setup.py file for SWIG Interface of Ext

"""

from os.path import exists

import numpy
from setuptools import setup, Extension, find_packages

from setup_utils import download_numpy_interface, readme

try:
    # Obtain the numpy include directory.  This logic works across numpy versions.
    numpy_include = numpy.get_include()
except AttributeError:
    numpy_include = numpy.get_numpy_include()

# Download numpy.i if needed
if not exists('NeuralNetwork/Ext/numpy.i'):
    print("Downloading numpy.i")
    download_numpy_interface()

source_files = ['./NeuralNetwork/Ext/NNExtension.i', './NeuralNetwork/Ext/cconv.c',
                './NeuralNetwork/Ext/cpool.c', './NeuralNetwork/Ext/crelu.c', 
                './NeuralNetwork/Ext/cmatmul.c', './NeuralNetwork/Ext/chelper.c']
include_dirs = ['./NeuralNetwork/Ext/', numpy_include]
extra_args = ['--verbose']
extra_link_args = []

NN_ext_module = Extension('NeuralNetwork/Ext/' + '_NeuralNetworkExtension',
                          sources=source_files,
                          include_dirs=include_dirs,
                          swig_opts=['-c++', '-py3'],
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
      requires=['numpy', 'wget'],
      install_requires=['numpy', 'wget'],
      )

print("Finished")
