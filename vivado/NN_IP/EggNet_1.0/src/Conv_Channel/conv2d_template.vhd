library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;

entity Conv2DTemplate is
	generic(
		BIT_WIDTH_IN : integer := 8;
		BIT_WIDTH_OUT : integer := 8;
		INPUT_CHANNELS : integer := 2;
		OUTPUT_CHANNELS : integer := 2
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		Valid_o : out std_logic;
		X_i : in std_logic_vector(INPUT_CHANNELS*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out unsigned(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0)
	);
end Conv2DTemplate;
