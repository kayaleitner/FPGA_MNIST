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
    with open('../README.md') as f:
        return f.read()


def recursive_source_file_search(f, path):
    """
    Recursively searches in path for .c or .cpp files and adds them to f
    :param f: list of strings
    :param path: folder path that should be searched
    :return: None
    """
    for (dirpath, dirnames, filenames) in walk(path):
        for filename in filenames:
            if filename.endswith('.c') or filename.endswith('.cpp'):
                if dirpath == "./":
                    f.append(filename)
                else:
                    f.append(dirpath + "/" + filename)

        for dirname in dirnames:
            # ToDo: Check, if this recursive call is even necessary or if walk() does all the work
            subdirpath = os.path.join(dirpath, dirname)
            recursive_source_file_search(f, subdirpath)
    return


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


class SwigExtension(Extension):
    pass


class CMakeExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)


class CMakeBuild(build_ext):
    """
    CMake Build Extension from
    https://www.benjack.io/2017/06/12/python-cpp-tests.html
    """

    def run(self):
        try:
            out = subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError(
                "CMake must be installed to build the following extensions: " +
                ", ".join(e.name for e in self.extensions))

        if platform.system() == "Windows":
            cmake_version = LooseVersion(re.search(r'version\s*([\d.]+)',
                                                   out.decode()).group(1))
            if cmake_version < '3.1.0':
                raise RuntimeError("CMake >= 3.1.0 is required on Windows")

        for ext in self.extensions:
            self.build_extension(ext)

    def build_extension(self, ext):
        extdir = os.path.abspath(
            os.path.dirname(self.get_ext_fullpath(ext.name)))
        cmake_args = ['-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + extdir,
                      '-DPYTHON_EXECUTABLE=' + sys.executable]

        cfg = 'Debug' if self.debug else 'Release'
        build_args = ['--config', cfg]

        if platform.system() == "Windows":
            cmake_args += ['-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_{}={}'.format(
                cfg.upper(),
                extdir)]
            if sys.maxsize > 2 ** 32:
                cmake_args += ['-A', 'x64']
            build_args += ['--', '/m']
        else:
            cmake_args += ['-DCMAKE_BUILD_TYPE=' + cfg]
            build_args += ['--', '-j2']

        env = os.environ.copy()
        env['CXXFLAGS'] = '{} -DVERSION_INFO=\\"{}\\"'.format(
            env.get('CXXFLAGS', ''),
            self.distribution.get_version())
        if not os.path.exists(self.build_temp):
            os.makedirs(self.build_temp)
        subprocess.check_call(['cmake', ext.sourcedir] + cmake_args,
                              cwd=self.build_temp, env=env)
        subprocess.check_call(['cmake', '--build', '.'] + build_args,
                              cwd=self.build_temp)
        print()  # Add an empty line for cleaner output


# Download numpy.i if needed
if not os.path.exists('./numpy.i'):
    print('Downloading numpy.i')
    project_dir = os.path.dirname(os.path.abspath(__file__))
    download_numpy_interface(path='.')

source_files = ['./NNExtension.i', './cconv.c',
                './cpool.c', './crelu.c',
                'cmatmul.c', './chelper.c']
source_files = [os.path.abspath(sfile) for sfile in source_files]
print("************************ SOURCE FILES *************************")
print(source_files)
print("************************ SOURCE FILES *************************")
include_dirs = [os.path.abspath('NeuralNetwork/Ext/'), numpy_include]

# Simple Platform Check (not entirely accurate because here should the compiler be checked)
# ToDo: Should be done better for example via CMake -> https://www.benjack.io/2017/06/12/python-cpp-tests.html
if platform.system() == 'Linux':
    extra_args = []
elif platform.system() == 'Darwin':
    extra_args = ['--verbose', '-Rpass=loop-vectorize', '-Rpass-analysis=loop-vectorize', '-ffast-math']
elif platform.system() == 'Windows':
    # extra_args = ['/Qrestrict', '/W3']
    extra_args = []
else:
    raise RuntimeError('Operating System not supported?')
extra_link_args = []

NN_ext_module = SwigExtension('_EggNetExtension',
                              sources=source_files,
                              include_dirs=include_dirs,
                              swig_opts=['-py3'],
                              extra_compile_args=extra_args,
                              extra_link_args=extra_link_args,
                              depends=['numpy'],
                              optional=True)

setup(name='EggNetExtension',
      version='1.0',
      author="Benjamin Kulnik",
      author_email="benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""NN calculation library for python""",
      url='https://github.com/marbleton/FPGA_MNIST',
      long_description=readme(),
      long_description_content_type="text/markdown",
      packages=find_packages(),
      package_data={
          # If any package contains *.txt or *.rst files, include them:
          '': ['*.txt', '*.rst', '*.i', '*.c', '*.h'],
      },
      ext_modules=[NN_ext_module],
      test_requires=['numpy', 'wget', 'idx2numpy', 'tensorflow', 'keras', 'torch'],
      install_requires=['numpy', 'wget', 'idx2numpy'],
      )


