LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY tb_relu IS

END tb_relu;

ARCHITECTURE arch OF tb_relu IS

    COMPONENT relu_nbit
        GENERIC (N : INTEGER);
        PORT (
            x_i : IN std_logic_vector(N - 1 DOWNTO 0);
            x_o : OUT std_logic_vector(N - 1 DOWNTO 0));
    END COMPONENT;

    ----------------------------------------------
    -- Signal Definitions --
    SIGNAL clk : std_logic := '0';
    SIGNAL sim_end : std_logic := '0';
    CONSTANT CLK_PERIOD : TIME := 20 ns;
    CONSTANT N_BITS_TEST : INTEGER := 8;
    SIGNAL input_data : std_logic_vector(N_BITS_TEST - 1 DOWNTO 0);
    SIGNAL output_data : std_logic_vector(N_BITS_TEST - 1 DOWNTO 0);
    SIGNAL exp_output_data : std_logic_vector(N_BITS_TEST - 1 DOWNTO 0);

    ----------------------------------------------

    -- declare record type
    TYPE test_vector IS RECORD
        test_value : std_logic_vector(N_BITS_TEST - 1 DOWNTO 0);
        exp_out : std_logic_vector(N_BITS_TEST - 1 DOWNTO 0);
    END RECORD;

    TYPE test_vector_array IS ARRAY (NATURAL RANGE <>) OF test_vector;
    CONSTANT test_vectors : test_vector_array := (
    -- Test Negative values
    ("00000000", "00000000"),
    ("10000000", "00000000"),
    ("10010010", "00000000"),
    ("11111111", "00000000"),

    -- Test Positive values
    ("00000000", "00000000"),
    ("01011010", "00000000"),
    ("00010010", "00000000"),
    ("01111111", "00000000")
    );

BEGIN

    -- port mapping
    dut : relu_nbit
    GENERIC MAP(
        N => N_BITS_TEST
    )
    PORT MAP(
        x_i => input_data,
        x_o => output_data
    );

    clkgen : PROCESS
    BEGIN
        IF sim_end = '0' THEN
            clk <= '0';
            WAIT FOR CLK_PERIOD/2;
            clk <= '1';
            WAIT FOR CLK_PERIOD/2;
        ELSE
            WAIT;
        END IF;
    END PROCESS; -- clkgen
    STIM : PROCESS
    BEGIN

        -- Offset is 5 ns
        WAIT FOR CLK_PERIOD/4;

        -- Check all test vectors
        FOR i IN test_vectors'RANGE LOOP
            -- Assign values of vector to signals
            input_data <= test_vectors(i).test_value;
            exp_output_data <= test_vectors(i).exp_out;
            WAIT FOR CLK_PERIOD/2;
            ASSERT (output_data = test_vectors(i).exp_out)

            -- image is used for string-representation of integer etc.

            REPORT "test_vector " & INTEGER'image(i) & " failed " SEVERITY error;

            WAIT FOR CLK_PERIOD/2;
        END LOOP;

        -- End simulation
        sim_end <= '1';
        WAIT;
    END PROCESS STIM;

END ARCHITECTURE; -- arch