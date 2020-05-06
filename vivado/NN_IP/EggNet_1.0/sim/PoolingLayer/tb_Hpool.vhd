library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.EggNetCommon.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_hpool is
    generic (
        runner_cfg : string;
        tb_path    : string
    );
end entity tb_Hpool;

architecture rtl of tb_hpool is

begin

    begin
	    -- Init VUNIT
        test_runner_setup(runner, runner_cfg);

        test_runner_cleanup(runner);
	end process;

end architecture;