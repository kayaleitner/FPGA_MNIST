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
    with open('./README.md') as f:
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


# Download numpy.i if needed
if not os.path.exists('./EggNetExtension/numpy.i'):
    print('Downloading numpy.i')
    project_dir = os.path.dirname(os.path.abspath(__file__))
    download_numpy_interface(path='./EggNetExtension/')

source_files = ['./EggNetExtension/NNExtension.i', './EggNetExtension/cconv.c',
                './EggNetExtension/cpool.c', './EggNetExtension/crelu.c',
                './EggNetExtension/cmatmul.c', './EggNetExtension/chelper.c']

print("************************ SOURCE FILES *************************")
print(source_files)
print("************************ SOURCE FILES *************************")
include_dirs = ['./EggNetExtension/', numpy_include]

# Simple Platform Check (not entirely accurate because here should the compiler be checked)
# ToDo: Should be done better for example via CMake -> https://www.benjack.io/2017/06/12/python-cpp-tests.html
if platform.system() == 'Linux':
    extra_args = ['-std=gnu99']
elif platform.system() == 'Darwin':
    extra_args = ['--verbose', '-Rpass=loop-vectorize', '-Rpass-analysis=loop-vectorize', '-ffast-math']
elif platform.system() == 'Windows':
    # extra_args = ['/Qrestrict', '/W3']
    extra_args = []
else:
    raise RuntimeError('Operating System not supported?')
extra_link_args = []

NN_ext_module = Extension('EggNetExtension._EggNetExtension',
                          sources=source_files,
                          include_dirs=include_dirs,
                          swig_opts=['-py3'],
                          extra_compile_args=extra_args,
                          extra_link_args=extra_link_args,
                          depends=['numpy'],
                          optional=False)

setup(name='EggNetExtension',
      version='1.0',
      author="Benjamin Kulnik",
      author_email="benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""NN calculation library for python""",
      url='https://github.com/marbleton/FPGA_MNIST',
      packages=['EggNetExtension'],
      package_data={
          # If any package contains *.txt or *.rst files, include them:
          '': ['*.txt', '*.rst', '*.i', '*.c', '*.h'],
      },
      ext_modules=[NN_ext_module],
      install_requires=['numpy', 'wget', 'idx2numpy'],
      )
