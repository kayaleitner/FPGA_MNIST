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
	constant INPUT_COUNT  : integer := 1568;
	constant OUTPUT_COUNT : integer := 10;
	
	type t_pixel_array is array (0 to INPUT_COUNT - 1) of integer;
	
	signal s_Clk_i, s_n_Res_i, s_Valid_i, s_Valid_o : std_logic;
	signal s_Data_i : std_logic_vector(BIT_WIDTH_IN*INPUT_CHANNELS*KERNEL_SIZE - 1 downto 0);
	signal s_Data_o : unsigned(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0);
	signal sim_ended : std_logic := '0';
	
	file input_file : text;
	file output_file : text;
begin
  
	uit : entity work.NeuralNetwork
	port map(
		Clk_i => s_Clk_i,
		Resetn_i => s_n_Res_i,
		Valid_i => s_Valid_i,
		Data_i => s_Data_i,
		Last_i => '0',
		Ready_i => '1',
		Valid_o => s_Valid_o,
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
	
	get_output : process(s_Clk_i, sim_ended)
		variable output : t_output_array;
		variable output_line : line;
        variable file_name_out : string(1 to 17) := "tmp/nn_output.txt";
	begin
		if s_Valid_o = '1' and rising_edge(s_Clk_i) then
			file_open(output_file, file_name_out, write_mode);
			for I in 0 to INPUT_COUNT - 1 loop
				write(output_line, s_Data_o((I+1)*VECTOR_WIDTH - 1 downto I*VECTOR_WIDTH));
				writeline(output_file, output_line);
			end loop;
			file_close(output_file);
		end if;	
	end process;

	set_input : process
	    variable layer_input : t_pixel_array;
        variable input_line : line;
        variable input_int : integer;
        variable file_name_in : string(1 to 16) := "tmp/nn_input.txt";
		variable K : integer := 0;
	begin
		
		for I in 0 to INPUT_COUNT - 1 loop
			file_name(19) := char_num(I+1);
            file_open(input_file, file_name_in, read_mode);
			K := 0;
            while not endfile(input_file) loop
                readline(input_file, input_line);
                read(input_line, input_int);
				layer_input(K) := input_int;
				K := K + 1;
            end loop;
            file_close(input_file);
		end loop;
		
		s_Data_i <= (others => '0');
		s_Valid_i <= '0';
		wait until rising_edge(s_n_Res_i);
		for J in 0 to INPUT_COUNT - 1 loop
			wait until rising_edge(s_Clk_i);
			s_Valid_i <= '1';
			s_Data_i <= std_logic_vector(to_unsigned(layer_input(K), VECTOR_WIDTH));
		end loop;
		wait until rising_edge(s_Clk_i);
		s_Valid_i <= '0';
		s_Data_i <= (others => '0');
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		sim_ended <= '1';
		wait;
	end process;
end beh;