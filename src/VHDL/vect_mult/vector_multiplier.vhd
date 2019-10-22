----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:58:14 10/18/2019 
-- Design Name: 
-- Module Name:    matrix_multiplier - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.math_real."ceil";
use IEEE.math_real."log2";

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vector_multiplier is
	Generic(vector_length : integer := 16);	--select number of multipliers
    Port ( 
			  clk_i : in std_logic;
			  write_i : in std_logic;
			  data_i : in std_logic_vector(7 downto 0);
			  address_i : in std_logic_vector(8 downto 0);
			  weight_write_i : in std_logic;
			  weight_data_i : in std_logic_vector(7 downto 0);
			  weight_address_i : in std_logic_vector(8 downto 0);
           output_o : out  STD_LOGIC_VECTOR (7 downto 0));
end vector_multiplier;

architecture Behavioral of vector_multiplier is



type multiplied is array (vector_length-1 downto 0) of std_logic_vector(7 downto 0);
signal s_multiplied : multiplied;	--signals to hold intermediate results

signal s_result : std_logic_vector(7+integer(ceil(log2(real(vector_length)))) downto 0);	--final result vector


--signals to hold input values
signal s_data : std_logic_vector(511 downto 0);
signal s_weights : std_logic_vector(511 downto 0);

begin


-- dummy data and weight loaders for large arrays of input data

data_input: entity work.data_loader
port map
(
	clk_i => clk_i,
	write_i => write_i,
	data_i => data_i,
	address_i => address_i,
	data_o => s_data
);

weight_input: entity work.data_loader
port map
(
	clk_i => clk_i,
	write_i => weight_write_i,
	data_i => weight_data_i,
	address_i => weight_address_i,
	data_o => s_weights
);



-- generation of multipliers for vector multiplication

generate_multipliers: for i in 0 to vector_length-1 generate
	
	multiplier_block:entity work.multiplier
	port map
	(
		a_in => s_data(i*8+7 downto  i*8),
		b_in => s_weights(i*8+7 downto i*8),
		c_out => s_multiplied(i)
	);
	
end generate generate_multipliers;





sum_multiplied_results : process(s_multiplied)
	variable sum : std_logic_vector(7+integer(ceil(log2(real(vector_length)))) downto 0):=(others=>'0');
begin
	
	for n in s_multiplied'range loop
		sum := sum + s_multiplied(n);                         
	end loop;
	s_result <= sum;    

end process;


output_o <= s_result(7 downto 0);	--take 8 bits from the result as output


end Behavioral;

