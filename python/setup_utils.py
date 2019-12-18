import os
import platform
import re
import sys
import subprocess
from distutils.version import LooseVersion
from os import walk

import numpy
import wget
from setuptools import Extension
from setuptools.command.build_ext import build_ext


def readme():
    with open('README.md') as f:
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
