#!/usr/bin/env python

from setuptools import setup, find_packages

setup(name='EggNet',
      version='1.0',
      author="Benjamin Kulnik",
      author_email="benjamin.kulnik@student.tuwien.ac.com",
      license="MIT",
      description="""NN calculation library for python""",
      url='https://github.com/marbleton/FPGA_MNIST',
      long_description_content_type="text/markdown",
      packages=find_packages(),
      package_data={
          # If any package contains *.txt or *.rst files, include them:
          '': ['*.txt', '*.rst', '*.i', '*.c', '*.h'],
      },
      test_requires=['numpy', 'wget', 'idx2numpy', 'tensorflow', 'keras', 'torch'],
      install_requires=['numpy', 'wget', 'idx2numpy'],
      )
