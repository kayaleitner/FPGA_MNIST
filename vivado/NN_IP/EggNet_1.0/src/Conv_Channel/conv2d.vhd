library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg;

entity Conv2D is
	generic(
		BIT_WIDTH_IN : integer := 8;
		BIT_WIDTH_OUT : integer := 8;
		INPUT_CHANNELS : integer := 2;
		OUTPUT_CHANNELS : integer := 2;
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		X_i : in signed(INPUT_CHANNELS*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out signed(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0)
	);
end Conv2D;

--Define the two convolutional layers here with their respective
--generated channels.

architecture ConvLayer_1 of Conv2D is
begin
end beh;

architecture ConvLayer_2 of Conv2D is
begin
end beh;
