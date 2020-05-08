"""
This file is used to discover testbenches in the current fodler

"""
import os
import argparse

TESTBENCH_DEFAULT_PREFIX = 'tb_'
TESTBENCH_EXTENSIONS = ['.vhd', '.py']

def get_working_dir():
    return os.path.pardir(os.path.abspath(__file__))
    

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('prefix', type=str, default=TESTBENCH_DEFAULT_PREFIX)
    args = parser.parse_args()

    prefix = args.prefix





if __name__ == "__main__":
    main()