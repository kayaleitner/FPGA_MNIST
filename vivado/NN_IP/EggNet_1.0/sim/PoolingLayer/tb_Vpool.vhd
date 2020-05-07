library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.EggNetCommon.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_vpool is
    generic (
        runner_cfg            : string;
        tb_path               : string;
        ACTIVATION_WIDTH_BITS : natural := 15;
        N_CHANNELS            : natural := 4;
        IMAGE_WIDTH           : natural := 6; -- Width of the image
        TB_PERIOD             : time    := 10 ns
    );
end entity tb_vpool;

architecture rtl of tb_vpool is

    -- Signals for UUT
    signal clk               : std_logic                                            := '0';
    signal sim_done          : std_logic                                            := '0';
    signal rst               : std_logic                                            := '0';
    signal valid_i           : std_logic                                            := '0';
    signal valid_o           : std_logic                                            := '0';
    signal x_i               : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');
    signal y_o               : std_logic_vector(ACTIVATION_WIDTH_BITS - 1 downto 0) := (others => '0');
    signal dbg_cnt           : natural;
    signal dbg_is_buffering  : std_logic := '0';
    signal dbg_fifo_read_en  : std_logic := '0';
    signal dbg_fifo_write_en : std_logic := '0';
    signal dbg_fifo_empty    : std_logic := '0';
    signal dbg_fifo_full     : std_logic := '0';

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
        valid_o           : std_logic;
        y_o               : integer;
        dbg_is_buffering  : std_logic;
        dbg_fifo_read_en  : std_logic;
        dbg_fifo_write_en : std_logic;
    end record;

    type test_input_vector_t is array (natural range <>) of test_input_sample;
    type test_output_vector_t is array (natural range <>) of test_output_sample;

    constant test_input_vector : test_input_vector_t := (
    ('1', 11), -- Buffer
    ('1', 12),
    ('1', 13),
    ('1', 4), -- Pool
    ('1', 5),
    ('1', 14),
    ('1', 2), -- Buffer
    ('1', 2),
    ('1', 9)
    );

    constant test_output_vector : test_output_vector_t := (
    ('0', 0, '1', '0', '1'),
    ('0', 2, '1', '0', '1'),
    ('0', 0, '1', '0', '1'),
    ('1', 11, '0', '1', '0'),
    ('1', 12, '0', '1', '0'),
    ('1', 14, '0', '1', '0'),
    ('0', 0, '1', '0', '1'),
    ('0', 0, '1', '0', '1'),
    ('0', 0, '1', '0', '1')
    );
begin

    clk <= not clk after TB_PERIOD/2 when sim_done /= '1' else '0';

    test_runner : process
    begin
        test_runner_setup(runner, runner_cfg);
        sim_done <= '0';
        valid_i  <= '0';
        rst      <= '1';
        wait for TB_PERIOD;
        rst      <= '0';

        -- Read the data files
        -- input_data      := load_csv(tb_path & "input.csv");
        -- ref_output_data := load_csv(tb_path & "output.csv");

        info("Buffer: #   IS_BUFF FULL EMPTY");
        
        for i in test_output_vector'range loop

            -- Set inputs
            wait until falling_edge(clk);
            valid_i <= test_input_vector(i).valid_i;
            x_i     <= std_logic_vector(to_unsigned(test_input_vector(i).x_i, ACTIVATION_WIDTH_BITS));

            -- Check output
            wait until rising_edge(clk);
            --wait for TB_PERIOD/4;
            
            info("        " & integer'image(i) & "    " & std_logic'image(dbg_is_buffering) & "  " & std_logic'image(valid_o) & "  " & std_logic'image(dbg_fifo_full) & "  " & std_logic'image(dbg_fifo_empty) & "  ");
            -- Checks
            check_equal(valid_o, test_output_vector(i).valid_o, "valid_o wrong");
            check_equal(dbg_is_buffering, test_output_vector(i).dbg_is_buffering, "dbg_is_buffering wrong");
            check_equal(dbg_fifo_read_en, test_output_vector(i).dbg_fifo_read_en, "dbg_fifo_read_en wrong");
            check_equal(dbg_fifo_write_en, test_output_vector(i).dbg_fifo_write_en, "dbg_fifo_write_en wrong");
            

            if valid_o = '1' then
                --check_equal(unsigned(y_o), test_output_vector(i).y_o);
            end if;

        end loop;

        sim_done <= '1';
        test_runner_cleanup(runner);
    end process; -- test_runner

    -- 
    -- Instantiate the HPool Entity
    vpool_0 : entity work.VPool
        generic map(
            IMAGE_WIDTH           => IMAGE_WIDTH,
            ACTIVATION_WIDTH_BITS => ACTIVATION_WIDTH_BITS
        )
        port map(
            clk_i             => clk,
            rst_i             => rst,
            valid_i           => valid_i,
            valid_o           => valid_o,
            x_i               => x_i,
            y_o               => y_o,
            dbg_is_buffering  => dbg_is_buffering,
            dbg_fifo_empty    => dbg_fifo_empty,
            dbg_fifo_full     => dbg_fifo_full,
            dbg_fifo_read_en  => dbg_fifo_read_en,
            dbg_fifo_write_en => dbg_fifo_write_en,
            dbg_cnt           => dbg_cnt
        );

end architecture;