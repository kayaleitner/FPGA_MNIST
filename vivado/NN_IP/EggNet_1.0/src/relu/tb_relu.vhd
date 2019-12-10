import IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_relu is
  port (
    clock
  ) ;
end tb_relu ;

architecture arch of tb_relu is

component relu_nbit 
    generic( N : integer );
    port (x_in : in std_logic_vector(N-1 downto 0);x_out : out std_logic_vector(N-1 downto 0));
end component;

----------------------------------------------
-- Signal Definitions --
signal sim_end : std_logic := '0';
constant PERIOD : time := 20 ns;
constant N_BITS_TEST : integer := 8;
signal input_data : std_logic_vector(N_BITS_TEST-1 downto 0);
signal output_data : std_logic_vector(N_BITS_TEST-1 downto 0);

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
    ("01111111", "00000000"),
);



begin

    -- port mapping
    dut : relu_nbit port map(
       generic map(N := N_BITS_TEST)
       port map()
    );


    clkgen : process
    begin
        if sim_end = '0' then
            clk <= '0';
            wait for PERIOD/2;
            clk <= '1';
            wait for PERIOD/2;
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
        input_data <= std_logic_vector(to_signed(test_vectors(i).test_value, 8));
        output_data <= std_logic_vector(to_signed(test_vectors(i).exp_out, 8));
            

        wait for CLK_PERIOD/2;
        
        assert (to_integer(signed(LED)) = test_vectors(i).LED)
        -- image is used for string-representation of integer etc.
        report  "test_vector " & integer'image(i) & " failed " & 
            " for input a = " & integer'image(test_vectors(i).A) & 
            " and b = " & integer'image(test_vectors(i).B) & " delivered result "
            & integer'image(to_integer(signed(LED))) & " (should be: " & 
            integer'image(test_vectors(i).LED) & ")"
            severity error;
            
        wait for CLK_PERIOD/2;
    end loop;
    
    -- End simulation
    ENDSIM <= '1';
    wait;            
    end process STIM;

end architecture ; -- arch