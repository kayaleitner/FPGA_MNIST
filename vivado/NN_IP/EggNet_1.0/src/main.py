import os
import shutil
import subprocess
import argparse
from typing import List
import logging

TEST_BENCH_PREFIXES = ['tb_']
TEST_BENCH_SUFFIXES = ['_tb']

testbench_logger = logging.Logger(name='', level=logging.DEBUG)


def main():
    """
    Main Script Entry Point
    """
    generate_layers()
    run_py_testbenches()


def script_folder_path():
    """
    Evaluates the absolute folder path of the script
    Returns:
        The absolute folder path
    """
    return os.path.dirname(os.path.abspath(__file__))


def generate_layers():
    """
    Runs all "Generate" scripts
    """
    for root, dirs, files in os.walk(script_folder_path()):

        # We only care about files
        for file in files:
            if file.startswith('generate_') and file.endswith('.py'):
                # Run the python script
                testbench_logger.info(file)
                subprocess.check_output(['python', file], cwd=root, stderr=subprocess.STDOUT)


def run_py_testbenches():
    """
    Runs all python "Testbenches"
    """
    for root, dirs, files in os.walk(script_folder_path()):

        # We only care about files
        for file in files:
            if file.endswith('.py') and (file.startswith('tb_') or file.endswith('_tb.py')):
                # Run the python script
                testbench_logger.info(file)
                subprocess.check_output(['python', file], cwd=root)


def has_prefix(filename: str, list_of_prefixes: List[str]):
    for prefix in list_of_prefixes:
        if filename.startswith(prefix):
            return True
    return False


if __name__ == "__main__":
    main()
