import re
import os
from os import walk
import numpy
import wget
from setuptools import Extension


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

