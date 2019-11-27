#!/usr/bin/env python
"""
setup.py file for SWIG Interface of NeuralNetworkExtension

"""

import os
import re
import sys
import setuptools
from setuptools import setup, Extension

# from distutils.core import setup, Extension
from os import walk
from os.path import exists

# Third-party modules - we depend on numpy for everything
import numpy
# Import requests module, to download numpy.i in case
import requests

from setup_utils import download_numpy_interface

# Obtain the numpy include directory.  This logic works across numpy versions.
try:
    numpy_include = numpy.get_include()
except AttributeError:
    numpy_include = numpy.get_numpy_include()


# Download numpy.i if needed
if not exists('numpy.i'):
    print("Downloading numpy.i")
    download_numpy_interface()


def readme():
    with open('README.md') as f:
        return f.read()


# Build Extension
print(sys.platform)


source_files = ['./NNExtension.i', './conv.c']
include_dirs = ['.', numpy_include]
extra_args = ['--verbose']
extra_link_args = []
#source_files = [os.path.abspath(source_file) for source_file in source_files]

NN_ext_module = Extension('_NeuralNetworkExtension',
                        #define_macros=[('NDEBUG', 1)],
                        sources=source_files,
                        include_dirs=include_dirs,
                        swig_opts=['-c++', '-py3'],
                        extra_compile_args=extra_args,
                        extra_link_args=extra_link_args)

setup(name='FpgaMnistNN',
      version='1.0',
      author="Benjamin Kulnik",
      author_email="benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""NN calculation library for python""",
      long_description=readme(),
      #py_modules=["FpgaMnistNN"],
      ext_modules=[NN_ext_module],
      # long_description_content_type="text/markdown",
      # cmdClass={'install': Build_ext_first},
      requires=['numpy'],
      install_requires=[
          'numpy',
      ],
      # packages=['AdcCalculationsLib'],
      # package_dir={'AdcCalculationsLib': 'AdcCalculationsLib/'},
      )

print("Finished")
