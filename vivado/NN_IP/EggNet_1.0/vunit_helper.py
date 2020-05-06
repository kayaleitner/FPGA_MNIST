"""
Collection of files and functions to help in the execution of VUNIT

https://vunit.github.io/data_types/user_guide.html
"""

import os
import sys
import json
import logging
import pathlib

import numpy as np
import vunit
import EggNet as egg


# Setup the local path
_LOCAL_PATH = pathlib.Path(__file__).parent
_NET_FINALWEIGHT_PATH = _LOCAL_PATH.parent.parent.parent / 'net' / 'final_weights'


# -- Network Files

# List of keys that can be used to retrieve the values from the npz-dictionary.
_NUMPY_WEIGHT_KEYS = ['cn1.b', 'cn1.k', 'cn2.b',
                      'cn2.k', 'fc1.b', 'fc1.w', 'fc2.b', 'fc2.w']

WEIGHTS_NLQ2_CONFIG = _NET_FINALWEIGHT_PATH / 'nl2' / 'config.json'
WEIGHTS_NLQ3_CONFIG = _NET_FINALWEIGHT_PATH / 'nl3' / 'config.json'
WEIGHTS_NLQ4_CONFIG = _NET_FINALWEIGHT_PATH / 'nl4' / 'config.json'

WEIGHTS_NLQ2_SHIFT = _NET_FINALWEIGHT_PATH / 'nl2' / 'shifts.npz'
WEIGHTS_NLQ3_SHIFT = _NET_FINALWEIGHT_PATH / 'nl3' / 'shifts.npz'
WEIGHTS_NLQ4_SHIFT = _NET_FINALWEIGHT_PATH / 'nl4' / 'shifts.npz'

WEIGHTS_NLQ2_SIGNS = _NET_FINALWEIGHT_PATH / 'nl2' / 'signs.npz'
WEIGHTS_NLQ3_SIGNS = _NET_FINALWEIGHT_PATH / 'nl3' / 'signs.npz'
WEIGHTS_NLQ4_SIGNS = _NET_FINALWEIGHT_PATH / 'nl4' / 'signs.npz'

WEIGHTS_NLQ2_FAKE = _NET_FINALWEIGHT_PATH / 'nl2' / 'fake.npz'
WEIGHTS_NLQ3_FAKE = _NET_FINALWEIGHT_PATH / 'nl3' / 'fake.npz'
WEIGHTS_NLQ4_FAKE = _NET_FINALWEIGHT_PATH / 'nl4' / 'fake.npz'


class DataChecker:
    """
    Provides input data to test bench and checks its output data
    """

    def __init__(self, d):
        self.kernel = d['kernel_shifts']
        self.kernel_signs = d['kernel_signs']
        self.input = d['input']
        self.temp = d['temp']
        self.result = d['result']

    def attach_to_test(self, library: vunit.library.Library, tb_name: str):
        test = library.test_bench(tb_name)
        test.set_pre_config(self.pre_config)
        test.set_post_check(self.post_check)
        return test

    @staticmethod
    def generate_test_data():
        # Generate random arrays
        kernel = np.random.randint(0, 7, size=(9,))
        kernel_signs = np.random.randint(low=0, high=2, size=(9,))
        input = np.random.randint(0, 255, size=(9,))
        # Shift positive values
        temp = (input >> kernel).astype(np.int)
        # Flip negative values
        temp[kernel_signs == 1] = -input[kernel_signs == 1]
        result = np.sum(temp)
        d = {
            'kernel_shifts': kernel,
            'kernel_signs': kernel_signs,
            'input': input,
            'temp': temp,
            'result': result
        }
        return d

    def pre_config(self, output_path):
        DataChecker.write_data(self.input, os.path.join(
            output_path, "tb_3x3_shift_kernel_image.csv"))
        DataChecker.write_data(self.temp, os.path.join(
            output_path, "tb_3x3_shift_kernel_temp.csv"))
        return True

    @staticmethod
    def compute_expected(input_data):
        print(input_data)
        pass

    def post_check(self, output_path):
        expected = self.result
        got = np.recfromcsv(os.path.join(
            output_path, "tb_3x3_shift_kernel_out.csv"))
        return np.equal(expected, got)

    @staticmethod
    def write_data(input_data, path):
        np.savetxt(fname=path, X=input_data, fmt="%d", delimiter=',')


def numpy2mif(output_filepath, array, bitwidth=None):
    if bitwidth == None:
        # Load with auto
        bitwidth = int(np.ceil(np.log2(array.max())))
        logging.warning(
            f"No explicit bitwidth given, {bitwidth:d} will be used")

    # Format with unspecified leading zeros and as binary
    format_string = "{value:0>{width}b}"

    # Use os.linesep to use system line seperators
    mif_string = os.linesep.join(
        map(
            lambda x: format_string.format(width=bitwidth, value=x),
            array
        )
    )

    with open(output_filepath, "w") as f:
        f.write(mif_string)


def setup_mif_files():
    pass


if __name__ == "__main__":

    # Execute tests if the file is used as main
    output_path = _LOCAL_PATH / 'tmp' / 'test.mif'

    # Create a tmp outdir
    os.makedirs(output_path.parent, exist_ok=True)

    numpy2mif(
        output_filepath=output_path,
        array=np.random.randint(low=0, high=15, size=(10,)),
        bitwidth=16
    )

    # --- Read weights
    w_shifts = np.load(WEIGHTS_NLQ2_SHIFT)
    w_signs = np.load(WEIGHTS_NLQ3_SIGNS)
    w_fake = np.load(WEIGHTS_NLQ3_FAKE)
