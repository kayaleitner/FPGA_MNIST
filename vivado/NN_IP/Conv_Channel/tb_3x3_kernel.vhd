library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.Kernel3x3;

entity tb_3x3_kernel IS
end tb_3x3_kernel;

architecture beh of tb_3x3_kernel is
	constant BIT_WIDTH_IN : integer := 8;
	constant BIT_WIDTH_OUT : integer := 16;
	constant WEIGHT : kernel_array_t := (0,1,0,0,0,0,0,0,0);
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	
	signal s_Clk_i : std_logic;
	signal s_n_Res_i : std_logic;
	signal s_Valid_i : std_logic;
	signal s_X_i : signed(BIT_WIDTH_IN*3*3 - 1 downto 0);
	signal s_Y_o : signed(BIT_WIDTH_OUT - 1 downto 0);
begin
  
	uit : entity work.Kernel3x3 
	generic map(
		BIT_WIDTH_IN,
		BIT_WIDTH_OUT,
		WEIGHT
	) port map(
		Clk_i => s_Clk_i,
		n_Res_i => s_n_Res_i,
		Valid_i => s_Valid_i,
		X_i => s_X_i,
		Y_o => s_Y_o
	);
  
	-- Generates the clock signal
	clkgen : process
	begin
		s_Clk_i <= '0';
		wait for CLK_PERIOD/2;
		s_Clk_i <= '1';
		wait for CLK_PERIOD/2;
	end process clkgen;

	-- Generates the reset signal
	reset : process
	begin -- process reset
		s_n_Res_i <= '0';
		wait for 125 ns;
		s_n_Res_i <= '1';
		wait;
	end process; 

	input : process
	begin
	s_X_i <= (others => '0');
	s_Valid_i <= '0';
    wait until rising_edge(s_n_Res_i);
	s_Valid_i <= '1';
	for I in 0 to 8 loop
		s_X_i((I+1)*BIT_WIDTH_IN - 1 downto I*BIT_WIDTH_IN) <= to_signed(I, BIT_WIDTH_IN);
	end loop;
	wait until rising_edge(s_Clk_i);
	end process;
end beh;