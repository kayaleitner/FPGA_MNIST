library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.ConvChannel;

entity tb_conv_channel is
end tb_conv_channel;

architecture beh of tb_conv_channel is
	constant BIT_WIDTH_IN : integer := 8;
	constant KERNEL_WIDTH_OUT : integer := 16;
	constant BIT_WIDTH_OUT : integer := 8;
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	constant N : integer := 3;
	
	signal s_Clk_i, s_n_Res_i, s_Valid_i : std_logic;
	signal s_X_i : std_logic_vector(BIT_WIDTH_IN*N*KERNEL_SIZE - 1 downto 0);
	signal s_Y_o : signed(BIT_WIDTH_OUT - 1 downto 0);
begin
  
	uit : entity work.ConvChannel 
	generic map(
		BIT_WIDTH_IN,
		KERNEL_WIDTH_OUT,
		BIT_WIDTH_OUT,
		N
	) port map( --default generics
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
		wait for 55 ns;
		s_n_Res_i <= '1';
		wait;
	end process; 

	input : process
	begin
		s_X_i <= (others => '0');
		s_Valid_i <= '0';
		wait until rising_edge(s_n_Res_i);
		s_Valid_i <= '1';
		for I in 0 to N*KERNEL_SIZE - 1 loop
			s_X_i((I+1)*BIT_WIDTH_IN - 1 downto I*BIT_WIDTH_IN) <= std_logic_vector(to_signed(I, BIT_WIDTH_IN));
		end loop;
		wait until rising_edge(s_Clk_i);
	end process;
end beh;