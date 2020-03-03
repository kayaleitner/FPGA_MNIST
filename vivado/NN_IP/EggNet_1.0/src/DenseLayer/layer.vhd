--------------------------------------------------------
--------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:40:39 11/18/2019 
-- Design Name: 
-- Module Name:    layer - Behavioral 
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
use ieee.math_real.all;
use ieee.std_logic_unsigned.all;


LIBRARY work;
USE work.denseLayerPkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity layer is
Generic (  VECTOR_WIDTH   : integer := 8;
           INPUT_COUNT    : integer := 1568;
           OUTPUT_COUNT   : integer := 32;
           ROM_FILE       : string  := "rom_content.mif";
           BIAS_WIDTH     : integer := 16;
           BIAS_FILE      : string  := "bias_terms.mif");
Port ( 
	  Resetn_i : in STD_LOGIC;
      Reset_calculation_i : in STD_LOGIC;
      Clk_i : in  STD_LOGIC;
      Start_i : in  STD_LOGIC;
      Rd_en_o : out  STD_LOGIC;
      Data_i : in  STD_LOGIC_VECTOR (VECTOR_WIDTH-1 downto 0);
      Data_o : out  STD_LOGIC_VECTOR ((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT)))))-1 downto 0);
      Rd_addr_i : in STD_LOGIC_VECTOR (integer(ceil(log2(real(OUTPUT_COUNT))))-1 downto 0);
      Finished_o : out std_logic;
      Rd_en_i : in std_logic
      );
end layer;

architecture Behavioral of layer is

    signal s_weight_data : array_type(OUTPUT_COUNT-1 downto 0)(VECTOR_WIDTH-1 downto 0) := (others => (others => '0'));
    signal s_weight_data_vector : std_logic_vector((VECTOR_WIDTH*OUTPUT_COUNT)-1 downto 0) := (others => '0');
    signal s_weight_addr : std_logic_vector(integer(ceil(log2(real(INPUT_COUNT))))-1 downto 0) := (others => '0');
    signal s_multiplier_output : array_type(OUTPUT_COUNT-1 downto 0)((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT)))))-1 downto 0) := (others => (others => '0'));
    signal s_write_multiplier_output : std_logic := '0';
    signal s_sending : std_logic := '0';

begin


    -- ROM that holds the weights. Outputsall of the weights for current pixel in one big vector.
    weightsROM : entity work.romModule
    generic map(DATA_WIDTH => OUTPUT_COUNT*VECTOR_WIDTH,
                DATA_DEPTH => INPUT_COUNT,
                ROM_FILE   => ROM_FILE)
    port map(Clk_i=>Clk_i,
        Address_i => s_weight_addr,
        Data_o => s_weight_data_vector
    );
    
    -- This cuts the combined weight vector into weight array.
    process(s_weight_data_vector)
    begin
        for i in 0 to OUTPUT_COUNT-1 loop
            s_weight_data(i) <= s_weight_data_vector(i*VECTOR_WIDTH+VECTOR_WIDTH-1 downto i*VECTOR_WIDTH);
        end loop;
    end process;
    
    -- This block takes in input pixels one by one, multiplies it with appropriate weights and accumulates result.
    -- Accumulated values are then available on the output.
    multiplierBlock : entity work.vectorMultiplier
    generic map(    VECTOR_WIDTH => VECTOR_WIDTH,
                    INPUT_COUNT => INPUT_COUNT,
                    OUTPUT_COUNT => OUTPUT_COUNT,
                    BIAS_WIDTH => BIAS_WIDTH,
                    BIAS_FILE => BIAS_FILE)
    port map
    (
		Resetn_i => Resetn_i,
		Reset_calculation_i => Reset_calculation_i,
        Clk_i => Clk_i,
        Rd_en_o => Rd_en_o,
        Data_i => Data_i,
        Weights_address_o => s_weight_addr,
        Weights_i => s_weight_data,
        Output_o => s_multiplier_output,
        Start_calculation_i => Start_i,
        Write_Data_o => s_write_multiplier_output
    );
    
    
	process(Rd_addr_i, Rd_en_i)
	begin
		if Rd_en_i = '1' then
			Data_o <= s_multiplier_output(to_integer(unsigned(Rd_addr_i)));
		else
			Data_o <= (others => '0');
		end if;
	end process;
    Finished_o <= s_write_multiplier_output;

end Behavioral;

