library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.kernel_pkg.all;
use work.Conv2D_0;
use work.MaxPooling;

entity tb_conv2d_0 is
end tb_conv2d_0;

architecture beh of tb_conv2d_0 is
	constant BIT_WIDTH_IN : integer := 8; -- change this to 5 if running with int8
	constant BIT_WIDTH_OUT : integer := 4; -- this too
	constant INPUT_CHANNELS : integer := 1;
	constant OUTPUT_CHANNELS : integer := 16;
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	constant IMG_WIDTH : integer := 28;
	constant IMG_HEIGHT : integer := 28;
	constant BATCH_SIZE : integer := 3;
	constant INPUT_ARRAY_SIZE : integer := IMG_WIDTH * IMG_HEIGHT * BATCH_SIZE;
	constant POOLING_OUTPUT_ARRAY_SIZE : integer := (IMG_WIDTH * IMG_HEIGHT * BATCH_SIZE)/4;
	
	type t_pixel_array is array (0 to INPUT_ARRAY_SIZE - 1) of integer;
	type t_pixel_array_pool is array (0 to POOLING_OUTPUT_ARRAY_SIZE) of integer;
	type t_kernel_array is array (0 to KERNEL_SIZE - 1) of t_pixel_array;
	
	signal s_Clk_i, s_n_Res_i, s_C0_Valid_i, s_C0_Valid_o : std_logic;
	signal s_C0_Last_i, s_C0_Last_o, s_C0_Ready_o : std_logic;
	signal s_Pool_Last_o, s_Pool_Valid_o, s_Pool_Ready_o : std_logic;
	signal s_C0_X_i : std_logic_vector(BIT_WIDTH_IN*INPUT_CHANNELS*KERNEL_SIZE - 1 downto 0);
	signal s_C0_Y_o : unsigned(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0);
	signal conv2d_done : std_logic := '0';
	signal sim_ended : std_logic := '0';
	signal s_Pool_Data_o : std_logic_vector((BIT_WIDTH_OUT*OUTPUT_CHANNELS)-1 downto 0);
	
	file kernel_file : text;
	constant char_num : string(1 to 10) := "0123456789";
	
begin
  
	---------------------------------------------------------
	-- Init DUTs
	---------------------------------------------------------

	uit_0 : entity work.Conv2D_0
	generic map(
		BIT_WIDTH_IN,
		BIT_WIDTH_OUT,
		INPUT_CHANNELS,
		OUTPUT_CHANNELS
	) port map(
		Clk_i => s_Clk_i,
		n_Res_i => s_n_Res_i,
		Valid_i => s_C0_Valid_i,
		Valid_o => s_C0_Valid_o,
		X_i => s_C0_X_i,
		Y_o => s_C0_Y_o,
		Last_i => s_C0_Last_i,
		Ready_i => s_Pool_Ready_o,
		Last_o => s_C0_Last_o,
		Ready_o => s_C0_Ready_o
	);
	
	uit_1 : entity work.MaxPooling
	generic map(
		CHANNEL_NUMBER => OUTPUT_CHANNELS,
		DATA_WIDTH => BIT_WIDTH_OUT,
		LAYER_HIGHT => IMG_HEIGHT,
		LAYER_WIDTH => IMG_WIDTH
	) port map(
		Layer_clk_i => s_Clk_i,
		Layer_aresetn_i => s_n_Res_i,
		
		S_layer_tvalid_i => s_C0_Valid_o,
		S_layer_tdata_i => std_logic_vector(s_C0_Y_o),
		S_layer_tkeep_i => (others => '0'), 
		S_layer_tlast_i => s_C0_Last_o,
		S_layer_tready_o => s_Pool_Ready_o,
		
		M_layer_tvalid_o => s_Pool_Valid_o,
		M_layer_tdata_o => s_Pool_Data_o,
		M_layer_tkeep_o => open,
		M_layer_tlast_o => s_Pool_Last_o,
		M_layer_tready_i => '1'
	);
  
	---------------------------------------------------------
	-- Helpers
	---------------------------------------------------------
	
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
	
	---------------------------------------------------------
	-- Generate Output Conv2D
	---------------------------------------------------------
	
	-- Process to write the output of conv layer to file
	get_output_conv2d : process(s_Clk_i, conv2d_done)
		variable K : integer := 0;
		type t_output_array is array(0 to OUTPUT_CHANNELS - 1) of t_pixel_array;
		variable output : t_output_array;
		variable output_line : line;
        variable file_name_out : string(1 to 25) := "tmp/conv2d_0_output00.txt";
	begin
		if s_C0_Valid_o = '1' and rising_edge(s_Clk_i) then
			--report integer'image(K);
			for I in 0 to OUTPUT_CHANNELS - 1 loop
				output(I)(K) := to_integer(s_C0_Y_o((I+1)*BIT_WIDTH_OUT - 1 downto I*BIT_WIDTH_OUT));
			end loop;
			K := K + 1;
		elsif conv2d_done = '1' then
			for J in 0 to OUTPUT_CHANNELS - 1 loop
				file_name_out(20) := char_num(J/10 + 1);
				file_name_out(21) := char_num(J mod 10 + 1);
				file_open(kernel_file, file_name_out, write_mode);
				for I in 0 to INPUT_ARRAY_SIZE - 1 loop
					write(output_line, output(J)(I));
					writeline(kernel_file, output_line);
				end loop;
				file_close(kernel_file);
			end loop;
		end if;	
	end process;
	
	-- Process to write the output of pool layer to file
	get_output_pooling : process(s_Clk_i, sim_ended)
		variable K : integer := 0;
		type t_output_array_pool is array(0 to OUTPUT_CHANNELS - 1) of t_pixel_array_pool;
		variable output : t_output_array_pool;
		variable output_line : line;
        variable file_name_out : string(1 to 26) := "tmp/pooling_0_output00.txt";
	begin
		if s_Pool_Valid_o = '1' and rising_edge(s_Clk_i) then
			--report integer'image(K);
			for I in 0 to OUTPUT_CHANNELS - 1 loop
				output(I)(K) := to_integer(unsigned(s_Pool_Data_o((I+1)*BIT_WIDTH_OUT - 1 downto I*BIT_WIDTH_OUT)));
			end loop;
			K := K + 1;
		elsif sim_ended = '1' then
			for J in 0 to OUTPUT_CHANNELS - 1 loop
				file_name_out(21) := char_num(J/10 + 1);
				file_name_out(22) := char_num(J mod 10 + 1);
				file_open(kernel_file, file_name_out, write_mode);
				for I in 0 to POOLING_OUTPUT_ARRAY_SIZE - 1 loop
					write(output_line, output(J)(I));
					writeline(kernel_file, output_line);
				end loop;
				file_close(kernel_file);
			end loop;
		end if;	
	end process;

	set_input : process
	    variable kernel_input : t_kernel_array;
        variable input_line : line;
        variable output_line : line;
        variable input_int : integer;
        variable file_name : string(1 to 23) := "tmp/conv2d_0_input0.txt";
		variable K : integer := 0;
	begin
		
		-- First Read contents of file and store it in the kernel_input array
		for I in 0 to KERNEL_SIZE - 1 loop
			file_name(19) := char_num(I+1);
            file_open(kernel_file, file_name, read_mode);
			K := 0;
            while not endfile(kernel_file) loop
                readline(kernel_file, input_line);
				read(input_line, input_int);
				-- Testbench: Reads first the pixels and then the weight terms
				-- # TODO The ordering of the values in the file is crucial and should be documented
				-- Looks like the convention is for reading:
				--
				--	1) read all input pixles for the first 3x3 input -> first -> first col, first row
				--  2) read all input pixels for the second 3x3 input -> second -> first col, second row
				--  3) ...
				kernel_input(I)(K) := input_int;
				K := K + 1;
            end loop;
            file_close(kernel_file);
		end loop;
		
		s_C0_Last_i <= '0';
		s_C0_X_i <= (others => '0');
		s_C0_Valid_i <= '0';
		wait until rising_edge(s_n_Res_i);
		wait until rising_edge(s_C0_Ready_o);

		-- Pipe the output to the actual conv channel
		for J in 0 to INPUT_ARRAY_SIZE - 1 loop
			
			wait until rising_edge(s_Clk_i);
			while s_C0_Ready_o = '0' loop
				s_C0_Last_i <= '0';
				s_C0_X_i <= (others => '0');
				s_C0_Valid_i <= '0';
				wait until rising_edge(s_Clk_i);
			end loop;
			
			-- For the end of every line send the Last_i signal
			if (J mod IMG_WIDTH) = IMG_WIDTH - 1 then
				s_C0_Last_i <= '1';
			else
				s_C0_Last_i <= '0';
			end if;

			s_C0_Valid_i <= '1';
			for I in 0 to KERNEL_SIZE - 1 loop
				s_C0_X_i((I+1)*BIT_WIDTH_IN - 1 downto I*BIT_WIDTH_IN) <= std_logic_vector(to_unsigned(kernel_input(I)(J), BIT_WIDTH_IN));
			end loop;
		
			end loop;
		wait until rising_edge(s_Clk_i);

		s_C0_Last_i <= '0';
		s_C0_Valid_i <= '0';
		s_C0_X_i <= (others => '0');
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		conv2d_done <= '1';
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		wait until rising_edge(s_Clk_i);
		sim_ended <= '1';
		wait;
	end process;
end beh;