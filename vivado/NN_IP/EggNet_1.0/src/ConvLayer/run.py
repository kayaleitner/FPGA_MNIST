import os

import pathlib
import vunit
import numpy as np

ROOT = pathlib.Path(__file__).parent

VU = vunit.VUnit.from_argv()

# VU.add_osvvm()


lib = VU.add_library("conv_channel")
VU.enable_check_preprocessing()

lib.add_source_files(pattern=str(ROOT / "*.vhd"))
lib.add_source_files(pattern=str(ROOT / "channels" / "*.vhd"))
lib.add_source_files(pattern=str(ROOT / "channels_shift" / "*.vhd"))

# -- Other Sources
lib.add_source_files(pattern=str(ROOT.parent / "clogb2" / "*.vhd"))
lib.add_source_files(pattern=str(ROOT.parent / "DenseLayer" / "*.vhd"))
lib.add_source_files(pattern=str(ROOT.parent / "Fifo_vhdl" / "*.vhd"))
lib.add_source_files(pattern=str(ROOT.parent / "Pooling" / "*.vhd"))

# See here: https://vunit.github.io/py/opts.html
VU.set_compile_option("ghdl.flags", ["--ieee=synopsys", "--std=08"])


# lib.set_compile_option("ghdl.flags", ["--ieee=synopsys", "--std=08"])


# VU.set_sim_option("ghdl.sim_flags", ["--ieee=synopsys", "--std=08"])
# VU.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "--std=08"])
# lib.add_compile_option(name="--ieee", value="synopsis")

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
        DataChecker.write_data(self.input, os.path.join(output_path, "tb_3x3_shift_kernel_image.csv"))
        DataChecker.write_data(self.temp, os.path.join(output_path, "tb_3x3_shift_kernel_temp.csv"))
        return True

    @staticmethod
    def compute_expected(input_data):
        print(input_data)
        pass

    def post_check(self, output_path):
        expected = self.result
        got = np.recfromcsv(os.path.join(output_path, "tb_3x3_shift_kernel_out.csv"))
        return np.equal(expected, got)

    @staticmethod
    def write_data(input_data, path):
        np.savetxt(fname=path, X=input_data, fmt="%d", delimiter=',')


shift_kernel_test = lib.test_bench('tb_3x3_shift_kernel')

shift_kernel_data = DataChecker.generate_test_data()
checker = DataChecker(d=shift_kernel_data)
shift_kernel_test.set_pre_config(checker.pre_config)
shift_kernel_test.set_post_check(checker.post_check)


# shift_kernel_test.add_config(
#     name='Random Kernel Weights',
#     generics={
#         'BIT_WIDTH_IN': 9,
#         'BIT_WIDTH_OUT': 20,
#         'WEIGHT_SHIFTS': '(' + ', '.join(map(str, shift_kernel_data['kernel_shifts'].tolist())) + ')',
#         'WEIGHT_SIGNS': '(' + ', '.join(map(lambda x: "'" + str(x) + "'", shift_kernel_data['kernel_signs'].tolist())) + ')',
#     }
# )

def encode(tb_cfg):
    return ", ".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])


shift_kernel_test.add_config(
    name='Random Kernel Weights',
    generics=dict(
        encoded_tb_cfg=encode(
            dict(
                kernel_shifts='(' + ', '.join(map(str, shift_kernel_data['kernel_shifts'].tolist())) + ')',
                kernel_signs='(' + ', '.join(map(lambda x: "'" + str(x) + "'", shift_kernel_data['kernel_signs'].tolist())) + ')',
            )
        )
    )
)



if __name__ == '__main__':
    VU.main()
