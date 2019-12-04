import os
import re
import sys

from os import walk
from os.path import exists
import numpy
import requests


def recursive_source_file_search(f, path):
    """
Recursivly searches in path for .c or .cpp files and adds them to f
    :param f: list of strings
    :param path: folder path that should be searched
    :return: None
    """
    for (dirpath, dirnames, filenames) in walk(path):

        for filename in filenames:
            if re.match("..*\\.c$", filename) is not None or re.match("..*\\.cpp$", filename) is not None:
                if dirpath == "./":
                    f.append(filename)
                else:
                    f.append(dirpath + "/" + filename)

        for dirname in dirnames:
            subdirpath = dirpath + dirname
            recursive_source_file_search(f, subdirpath)
    return


def download_numpy_interface():
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

    chunk_size = 8196
    with open(np_file_name, 'wb') as file:
        for chunk in requests.get(np_file_url,
                                  stream=True).iter_content(chunk_size):
            file.write(chunk)

    return

