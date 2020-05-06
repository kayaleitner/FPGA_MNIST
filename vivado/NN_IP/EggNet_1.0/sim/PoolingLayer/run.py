import os
import sys
sys.path.append("../..")

# This imports the toplevel run
import pathlib
import run 
from run import VU, lib, ROOT, SRC_ROOT, SIM_ROOT


LOCAL_ROOT = pathlib.Path(__file__).parent
lib.add_source_files(LOCAL_ROOT / "*.vhd")

# -- Setup Tests
tb_hpool = lib.test_bench("tb_hpool")


if __name__ == "__main__":
    VU.main()