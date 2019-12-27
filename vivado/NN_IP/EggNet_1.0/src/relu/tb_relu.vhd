library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_relu is
  
end tb_relu ;

architecture arch of tb_relu is

component relu_nbit 
    generic( N : integer );
    port (
        x_i : in std_logic_vector(N-1 downto 0);
        x_o : out std_logic_vector(N-1 downto 0));
end component;

----------------------------------------------
-- Signal Definitions --
signal clk : std_logic := '0';
signal sim_end : std_logic := '0';
constant CLK_PERIOD : time := 20 ns;
constant N_BITS_TEST : integer := 8;
signal input_data : std_logic_vector(N_BITS_TEST-1 downto 0);
signal output_data : std_logic_vector(N_BITS_TEST-1 downto 0);
signal exp_output_data : std_logic_vector(N_BITS_TEST-1 downto 0);

----------------------------------------------

-- declare record type
type test_vector is record
    test_value : std_logic_vector(N_BITS_TEST-1 downto 0); 
    exp_out : std_logic_vector(N_BITS_TEST-1 downto 0); 
end record; 

type test_vector_array is array (natural range <>) of test_vector;
constant test_vectors : test_vector_array := (
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



begin

    -- port mapping
    dut : relu_nbit 
    generic map(
        N => N_BITS_TEST
    )
    port map(
        x_i => input_data, 
        x_o => output_data
    );
    


    clkgen : process
    begin
        if sim_end = '0' then
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        else
            wait;
        end if;
    end process ; -- clkgen


    STIM: process
    begin
    
    -- Offset is 5 ns
    wait for CLK_PERIOD/4;
    
    -- Check all test vectors
    for i in test_vectors'range loop
        -- Assign values of vector to signals
        input_data <= test_vectors(i).test_value;
        exp_output_data <= test_vectors(i).exp_out;
            

        wait for CLK_PERIOD/2;
        

        assert (output_data = test_vectors(i).exp_out)
        
        -- image is used for string-representation of integer etc.

        report  "test_vector " & integer'image(i) & " failed "  severity error;

        wait for CLK_PERIOD/2;
    end loop;
    
    -- End simulation
    sim_end <= '1';
    wait;            
    end process STIM;

end architecture ; -- arch