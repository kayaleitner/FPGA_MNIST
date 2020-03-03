----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:38:59 11/04/2019 
-- Design Name: 
-- Module Name:    romModule - Behavioral 
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
use IEEE.math_real.all;
use STD.textio.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity romModule is
	Generic(    DATA_WIDTH : integer := 256;
				DATA_DEPTH : integer := 2048;
				ROM_FILE   : string  := "rom_content.mif"
				);
    Port ( clk_i : in  STD_LOGIC;
           address_i : in  STD_LOGIC_VECTOR (integer(ceil(log2(real(DATA_DEPTH))))-1 downto 0);
           data_o : out  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0')
			  );
end romModule;

architecture Behavioral of romModule is

-- Definition of storage array.
type mem_type is array (0 to (2**integer(ceil(log2(real(DATA_DEPTH)))))-1) of std_logic_vector(DATA_WIDTH-1 downto 0);    

-- This function initializes ROM with the data from a .mif file.
impure function init_mem(mif_file_name : in string) return mem_type is
	file mif_file 		: text open read_mode is mif_file_name;
	variable mif_line	: line;
	variable temp_bv	: bit_vector(DATA_WIDTH-1 downto 0);
	variable temp_mem	: mem_type;
begin

	for i in 0 to DATA_DEPTH-1 loop
		readline (mif_file, mif_line);
		read(mif_line, temp_bv);
		temp_mem(i) := to_stdlogicvector(temp_bv);
	end loop;

	return temp_mem;
end function;

signal ROM : mem_type := init_mem(ROM_FILE);
 
begin

    process (clk_i)
    begin
        if ( rising_edge(clk_i) ) then
            data_o <= ROM(to_integer(unsigned(address_i)));
        end if;
    end process;

end Behavioral;

