library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.MaxPooling;

entity tb_MaxPooling is
end tb_MaxPooling;

architecture Behavioral of tb_MaxPooling is
	constant CHANNEL_NUMBER : integer := 16; 
	constant DATA_WIDTH     : integer := 8; 
	constant LAYER_HIGHT    : integer := 28;
	constant LAYER_WIDTH    : integer := 28;
	constant BATCH_SIZE     : integer := 3;
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	
	constant INPUT_ARRAY_SIZE : integer := LAYER_HIGHT * LAYER_WIDTH * BATCH_SIZE;
	constant OUTPUT_ARRAY_SIZE : integer := ((LAYER_HIGHT * LAYER_WIDTH)/4) * BATCH_SIZE;
	type t_pixel_array_in is array (0 to INPUT_ARRAY_SIZE - 1) of integer;
	type t_input_array is array (0 to CHANNEL_NUMBER - 1) of t_pixel_array_in;
	type t_pixel_array_out is array (0 to OUTPUT_ARRAY_SIZE - 1) of integer;
	type t_output_array is array (0 to CHANNEL_NUMBER - 1) of t_pixel_array_out;
	
	signal s_Clk_i : std_logic;
	signal s_n_Res_i : std_logic;
	signal s_Valid_i, s_Valid_o : std_logic;
	signal s_Ready_i, s_Ready_o : std_logic;
	signal s_Last_i, s_Last_o : std_logic;
	signal s_S_layer_tdata_i, s_M_layer_tdata_o : std_logic_vector((DATA_WIDTH*CHANNEL_NUMBER)-1 downto 0); 
	
	file input_file, output_file : text;
	signal sim_ended : std_logic := '0';
	constant char_num : string(1 to 10) := "0123456789";
	
begin
	uit : entity work.MaxPooling
	generic map(
		CHANNEL_NUMBER,
		DATA_WIDTH,
		LAYER_HIGHT,
		LAYER_WIDTH
	) port map(
		Layer_clk_i => s_Clk_i,
		Layer_aresetn_i => s_n_Res_i,
		S_layer_tvalid_i => s_Valid_i,
		S_layer_tdata_i => s_S_layer_tdata_i,
		S_layer_tkeep_i => (others => '0'),
		S_layer_tlast_i => s_Last_i,
		S_layer_tready_o => s_Ready_o,
		M_layer_tvalid_o => s_Valid_o,
		M_layer_tdata_o => s_M_layer_tdata_o,
		M_layer_tkeep_o => open,
		M_layer_tlast_o => s_Last_o,
		M_layer_tready_i => s_Ready_i
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
        variable file_name_out : string(1 to 28) := "tmp/pooling_sim_output00.txt";
		variable output_line : line;
		variable K : integer := 0;
	begin
		if s_Valid_o = '1' and rising_edge(s_Clk_i) then
			for I in 0 to CHANNEL_NUMBER - 1 loop
				output(I)(K) := to_integer(unsigned(s_M_layer_tdata_o((I+1)*DATA_WIDTH - 1 downto I*DATA_WIDTH)));
			end loop;
			K := K + 1;
		elsif sim_ended = '1' then
			for I in 0 to CHANNEL_NUMBER - 1 loop
				file_name_out(23) := char_num(I/10 + 1);
				file_name_out(24) := char_num(I mod 10 + 1);
				file_open(output_file, file_name_out, write_mode);
				for J in 0 to OUTPUT_ARRAY_SIZE - 1 loop
					write(output_line, output(I)(J));
					writeline(output_file, output_line);
				end loop;
				file_close(output_file);
			end loop;
		end if;	
	end process;

	set_input : process
		variable input : t_input_array;
        variable file_name : string(1 to 25) := "tmp/conv2d_0_output00.txt";
        variable input_line : line;
		variable K : integer := 0;
        variable input_int : integer;
	begin
		for I in 0 to CHANNEL_NUMBER - 1 loop
			file_name(20) := char_num(I/10 + 1);
			file_name(21) := char_num(I mod 10 + 1);
            file_open(input_file, file_name, read_mode);
			K := 0;
            while not endfile(input_file) loop
                readline(input_file, input_line);
                read(input_line, input_int);
				input(I)(K) := input_int;
				K := K + 1;
            end loop;
            file_close(input_file);
		end loop;
		
		s_S_layer_tdata_i <= (others => '0');
		s_Valid_i <= '0';
		s_Ready_i <= '1';
		s_Last_i <= '0';
		wait until rising_edge(s_n_Res_i);
		wait until rising_edge(s_Ready_o);
		K := 1;
		for J in 0 to INPUT_ARRAY_SIZE - 1 loop
			wait until rising_edge(s_Clk_i);
			while s_Ready_o /= '1' loop
				s_Valid_i <= '0';
				s_S_layer_tdata_i <= (others => '0');
				s_Last_i <= '0';
				wait until rising_edge(s_Clk_i);
			end loop;
			s_Valid_i <= '1';
			for I in 0 to CHANNEL_NUMBER - 1 loop
				s_S_layer_tdata_i((I+1)*DATA_WIDTH - 1 downto I*DATA_WIDTH) <= std_logic_vector(to_unsigned(input(I)(J), DATA_WIDTH));
			end loop;
			if K = LAYER_WIDTH then
				K := 1;
				s_Last_i <= '1';
			else
				K := K + 1;
				s_Last_i <= '0';
			end if;
		end loop;
		wait until rising_edge(s_Clk_i);
		s_Valid_i <= '0';
		s_S_layer_tdata_i <= (others => '0');
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		sim_ended <= '1';
	end process;
end Behavioral;