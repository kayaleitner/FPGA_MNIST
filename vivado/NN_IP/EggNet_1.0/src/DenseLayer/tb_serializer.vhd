library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Serializer;

entity tb_Serializer is
end tb_Serializer;

architecture Behavioral of tb_Serializer is
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	constant INPUT_CHANNELS : integer := 16;
	constant VECTOR_WIDTH : integer := 8;
	
	signal s_Clk_i : std_logic;
	signal s_n_Res_i : std_logic;
	signal s_Valid_i : std_logic;
	signal s_Last_i : std_logic;
	signal s_Ready_i : std_logic;
	signal s_Valid_o : std_logic;
	signal s_Last_o : std_logic;
	signal s_Ready_o : std_logic;
	signal s_Data_i : std_logic_vector(INPUT_CHANNELS*VECTOR_WIDTH - 1 downto 0);
	signal s_Data_o : std_logic_vector(VECTOR_WIDTH - 1 downto 0);
	
	type t_int_2d_array is array(0 to 3, 0 to INPUT_CHANNELS - 1) of integer;
	
	signal sim_ended : std_logic := '0';
	
begin
  
	uit : entity work.Serializer
	generic map(
		VECTOR_WIDTH => VECTOR_WIDTH,
		INPUT_CHANNELS => INPUT_CHANNELS
	)
	port map(
		Clk_i => s_Clk_i, 
		n_Res_i => s_n_Res_i, 
		Valid_i => s_Valid_i, 
		Last_i => s_Last_i, 
		Ready_i => s_Ready_i, 
		Valid_o => s_Valid_o, 
		Last_o => s_Last_o, 
		Ready_o => s_Ready_o, 
		Data_i => s_Data_i, 
		Data_o => s_Data_o
	);
  
	-- Generates the clock signal
	clkgen : process
	begin
		if sim_ended = '0' then
			s_Clk_i <= '0';
			wait for CLK_PERIOD/2;
			s_Clk_i <= '1';
			wait for CLK_PERIOD/2;
		else
			wait;
		end if;
	end process clkgen;

	-- Generates the reset signal
	reset : process
	begin -- process reset
		s_n_Res_i <= '0';
		wait for 55 ns;
		s_n_Res_i <= '1';
		wait;
	end process; 
	
	set_input : process
		variable input : t_int_2d_array := (
			( 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16),
			(17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32),
			(33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48),
			(49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64)
		);
	begin
		s_Valid_i <= '0';
		s_Last_i <= '0';
		s_Ready_i <= '1';
		s_Data_i <= (others => '0');
		wait until rising_edge(s_n_Res_i);
		for J in 0 to 3 loop
			wait until rising_edge(s_Ready_o);
			wait until rising_edge(s_Clk_i);
			s_Valid_i <= '1';
			for I in 0 to INPUT_CHANNELS - 1 loop
				s_Data_i((I+1)*VECTOR_WIDTH - 1 downto I*VECTOR_WIDTH) <= std_logic_vector(to_unsigned(input(J, I), VECTOR_WIDTH));
			end loop;
			if J = 3 then
				s_Last_i <= '1';
			end if;
			wait until rising_edge(s_Clk_i);
			s_Data_i <= (others => '0');
			s_Valid_i <= '0';
		end loop;
		s_Last_i <= '0';
		s_Data_i <= (others => '0');
		wait until rising_edge(s_Last_o);
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		sim_ended <= '1';
	end process;
end Behavioral;