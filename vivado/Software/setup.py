#!/usr/bin/env python
"""
setup.py file for SWIG Interface of Ext

"""
import os
import platform
import re
import subprocess
import sys
from distutils.version import LooseVersion
from os import walk

import numpy
import wget
from setuptools import Extension
from setuptools import setup, find_packages
from setuptools.command.build_ext import build_ext

try:
    # Obtain the numpy include directory.  This logic works across numpy versions.
    numpy_include = numpy.get_include()
except AttributeError:
    numpy_include = numpy.get_numpy_include()


def readme():
    with open('README.md') as f:
        return f.read()



def download_numpy_interface(path):
    """
    Downloads numpy.i
    :return: None
    """
    print("Download Numpy SWIG Interface")
    np_version = re.compile(r'(?P<MAJOR>[0-9]+)\.'
                            '(?P<MINOR>[0-9]+)') \
        .search(numpy.__version__)
    np_version_string = np_version.group()
    np_version_info = {key: int(value)
                       for key, value in np_version.groupdict().items()}

    np_file_name = 'numpy.i'
    np_file_url = 'https://raw.githubusercontent.com/numpy/numpy/maintenance/' + \
                  np_version_string + '.x/tools/swig/' + np_file_name
    if np_version_info['MAJOR'] == 1 and np_version_info['MINOR'] < 9:
        np_file_url = np_file_url.replace('tools', 'doc')

    wget.download(np_file_url, path)

    return

NUMPY_SWIG_FILE_PATH = 'EggDriver/src/numpy.i'

# Download numpy.i if needed
if not os.path.exists(NUMPY_SWIG_FILE_PATH):
    print('Downloading numpy.i')
    project_dir = os.path.dirname(os.path.abspath(__file__))
    download_numpy_interface(path=NUMPY_SWIG_FILE_PATH)

source_files = [
    'EggDriver/src/attr.c',
    'EggDriver/src/base.c',
    'EggDriver/src/eggnet.c',
    'EggDriver/src/eggnet.i',
    'EggDriver/src/eggstatus.c',
    'EggDriver/src/egguio.c',
    'EggDriver/src/helper.c',
    'EggDriver/src/mem.c']

# Convert file paths to absolute paths to avoid any confusion, when changing directories
source_files = [os.path.abspath(sfile) for sfile in source_files]
print("************************ SOURCE FILES *************************")
print(source_files)
print("************************ SOURCE FILES *************************")
include_dirs = [os.path.abspath('./src'), numpy_include]

# Simple Platform Check (not entirely accurate because here should the compiler be checked)
# ToDo: Should be done better for example via CMake -> https://www.benjack.io/2017/06/12/python-cpp-tests.html
if platform.system() == 'Linux':
    
    # Numpy uses restrict pointers, so we need at least c99
    extra_args = ['-std=c99']
    
    # Force to use the ARM GCC compiler
    os.environ['CC'] = 'arm-linux-gnueabihf-gcc'
    os.environ['CXX'] = 'arm-linux-gnueabihf-g++'
    print('Info: ', os.environ['CC'], ' is used')

elif platform.system() == 'Darwin':
    extra_args = ['--verbose', '-Rpass=loop-vectorize', '-Rpass-analysis=loop-vectorize', '-ffast-math']
elif platform.system() == 'Windows':
    # extra_args = ['/Qrestrict', '/W3']
    extra_args = []
else:
    raise RuntimeError('Operating System not supported?')

extra_link_args = []


# --------
# Setup
# --------

EggnetDriver = Extension('_EggnetDriver',
                              sources=source_files,
                              include_dirs=include_dirs,
                              swig_opts=['-py3'],
                              extra_compile_args=extra_args,
                              extra_link_args=extra_link_args,
                              depends=['numpy'],
                              optional=True)

setup(name='EggnetDriver',
      version='1.0',
      author="Lukas Baischer, Benjamin Kulnik",
      author_email="lukas.baischer@student.tuwien.ac.at, benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""Wrapper for the Linux Device Driver of the EggNet""",
      url='https://github.com/marbleton/FPGA_MNIST',
      long_description=readme(),
      long_description_content_type="text/markdown",
      packages=find_packages(),
      package_data={
          # If any package contains *.txt or *.rst files, include them:
          '': ['*.txt', '*.rst', '*.i', '*.c', '*.h'],
      },
      ext_modules=[EggnetDriver],
      install_requires=['numpy', 'wget'],
      )

print("Finished")
