library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.NeuralNetwork;

entity tb_NN is
end tb_NN;

architecture Behavioral of tb_NN is
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	constant VECTOR_WIDTH : integer := 8;
	constant INPUT_COUNT  : integer := 1176;
	constant OUTPUT_COUNT : integer := 10;
	
	type t_pixel_array is array (0 to INPUT_COUNT - 1) of integer;
	
	signal s_Clk_i, s_n_Res_i, s_Valid_i, s_Valid_o : std_logic;
	signal s_Ready_i, s_Ready_o, s_Last_o : std_logic;
	signal s_Data_i : std_logic_vector(VECTOR_WIDTH -1 downto 0);
	signal s_Data_o : std_logic_vector(OUTPUT_COUNT*VECTOR_WIDTH -1 downto 0);
	signal sim_ended : std_logic := '0';
	
	file input_file : text;
	file output_file : text;
begin
  
	uit : entity work.NeuralNetwork
	generic map(
		PATH => "../../"
	) port map(
		Clk_i => s_Clk_i,
		Resetn_i => s_n_Res_i,
		Valid_i => s_Valid_i,
		Data_i => s_Data_i,
		Valid_o => s_Valid_o,
		Data_o => s_Data_o,
		Ready_i => s_Ready_i,
		Ready_o => s_Ready_o,
		Last_o => s_Last_o
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
	
	get_output : process(s_Clk_i, sim_ended)
		--variable output_line : line;
        --variable file_name_out : string(1 to 17) := "tmp/nn_output.txt";
	begin
		if s_Valid_o = '1' and rising_edge(s_Clk_i) then
			for J in 0 to OUTPUT_COUNT - 1 loop
				report integer'image(to_integer(unsigned(s_Data_o((J+1)*VECTOR_WIDTH - 1 downto J*VECTOR_WIDTH))));
			end loop;
		end if;	
	end process;

	set_input : process
	    variable layer_input : t_pixel_array;
        variable input_line : line;
        variable input_int : integer;
        variable file_name_in : string(1 to 16) := "tmp/nn_input.txt";
		variable K : integer := 0;
	begin
		s_Ready_i <= '1';
		
		file_open(input_file, file_name_in, read_mode);
		K := 0;
		while not endfile(input_file) loop
			readline(input_file, input_line);
			read(input_line, input_int);
			layer_input(K) := input_int;
			K := K + 1;
		end loop;
		file_close(input_file);
		
		s_Data_i <= (others => '0');
		s_Valid_i <= '0';
		wait until rising_edge(s_n_Res_i);
		for J in 0 to INPUT_COUNT - 1 loop
			wait until rising_edge(s_Clk_i);
			s_Valid_i <= '0';
			wait until rising_edge(s_Clk_i);
			s_Valid_i <= '1';
			s_Data_i <= std_logic_vector(to_unsigned(layer_input(J), VECTOR_WIDTH));
		end loop;
		wait until rising_edge(s_Clk_i);
		s_Valid_i <= '0';
		s_Data_i <= (others => '0');
		wait until rising_edge(s_Clk_i);
		for I in 0 to 2000 loop
			wait until rising_edge(s_Clk_i);
		end loop;
		wait until rising_edge(s_Clk_i);
		sim_ended <= '1';
		wait;
	end process;
end Behavioral;