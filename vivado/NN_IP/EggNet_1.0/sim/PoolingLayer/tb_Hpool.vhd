library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.EggNetCommon.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_hpool is
    generic (
        runner_cfg            : string;
        tb_path               : string;
        ACTIVATION_WIDTH_BITS : natural := 15;
        N_CHANNELS            : natural := 4;
        TB_PERIOD             : time    := 10 ns
    );
end entity tb_Hpool;

architecture rtl of tb_hpool is

    -- Signals for UUT
    signal clk      : std_logic                                            := '0';
    signal sim_done : std_logic                                            := '0';
    signal rst      : std_logic                                            := '0';
    signal valid_i  : std_logic                                            := '0';
    signal valid_o  : std_logic                                            := '0';
    signal x_i      : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');
    signal y_o      : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');

    -- Variables defined for VUNIT
    -- shared variable input_data, ref_output_data : integer_array_t;
    -- signal start, data_check_done, stimuli_done : boolean := false;

    -- Expected input type
    type test_input_sample is record
        valid_i : std_logic;
        x_i     : integer;
    end record;

    -- Expected output type
    type test_output_sample is record
        valid_o : std_logic;
        y_o     : integer;
    end record;

    type test_input_vector_t is array (natural range <>) of test_input_sample;
    type test_output_vector_t is array (natural range <>) of test_output_sample;

    constant test_input_vector : test_input_vector_t := (
    ('1', 1), -- Test 1
    ('1', 2),
    ('1', 3), -- Test 2
    ('1', 4),
    ('1', 4), -- Test 3
    ('0', 2),
    ('0', 2), -- Test 4
    ('0', 2),
    ('1', 9), -- Test 5
    ('1', 2)
    );

    constant test_output_vector : test_output_vector_t := (
    ('0', 0), -- Test 1
    ('1', 2),
    ('0', 0), -- Test 2
    ('1', 4),
    ('0', 0), -- Test 3
    ('0', 0),
    ('0', 0), -- Test 4
    ('0', 0),
    ('0', 0), -- Test 5
    ('1', 9)
    );
begin

    clk <= not clk after TB_PERIOD/2 when sim_done /= '1' else
        '0';

    test_runner : process
    begin
        test_runner_setup(runner, runner_cfg);
        sim_done <= '0';
        rst      <= '1';
        wait for TB_PERIOD;

        -- Read the data files
        -- input_data      := load_csv(tb_path & "input.csv");
        -- ref_output_data := load_csv(tb_path & "output.csv");

        rst <= '0';
        wait for TB_PERIOD;

        for i in test_output_vector'range loop

            -- info("Iteration: " & i'image);
            --info("Iteration");
            debug("Iteration");

            -- Set inputs
            wait until falling_edge(clk);
            valid_i <= test_input_vector(i).valid_i;
            x_i     <= std_logic_vector(to_unsigned(test_input_vector(i).x_i, ACTIVATION_WIDTH_BITS));

            -- Check output
            wait until rising_edge(clk);
            wait for TB_PERIOD/16;
            check_equal(valid_o, test_output_vector(i).valid_o);
            if valid_o = '1' then
                check_equal(unsigned(y_o), test_output_vector(i).y_o);
            end if;

        end loop;

        sim_done <= '1';
        test_runner_cleanup(runner);
    end process; -- test_runner

    -- 
    -- Instantiate the HPool Entity
    hpool_0 : entity work.HPool
        generic map(
            ACTIVATION_WIDTH_BITS => ACTIVATION_WIDTH_BITS
        )
        port map(
            clk_i   => clk,
            rst_i   => rst,
            valid_i => valid_i,
            valid_o => valid_o,
            x_i     => x_i,
            y_o     => y_o
        );

end architecture;