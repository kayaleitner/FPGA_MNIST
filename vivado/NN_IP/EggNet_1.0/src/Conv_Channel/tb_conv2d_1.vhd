library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;
use work.kernel_pkg.all;
use work.Conv2D_1;
use work.MaxPooling;
use work.Serializer;

entity tb_conv2d_1 is
end tb_conv2d_1;

architecture beh of tb_conv2d_1 is
	constant BIT_WIDTH_IN : integer := 8;
	constant BIT_WIDTH_OUT : integer := 8;
	constant INPUT_CHANNELS : integer := 16;
	constant OUTPUT_CHANNELS : integer := 24;
	constant CLK_PERIOD : time := 10 ns; -- 100MHz
	constant IMG_WIDTH : integer := 14;
	constant IMG_HEIGHT : integer := 14;
	constant BATCH_SIZE : integer := 3;
	constant INPUT_ARRAY_SIZE : integer := IMG_WIDTH * IMG_HEIGHT * BATCH_SIZE;
	constant POOLING_OUTPUT_ARRAY_SIZE : integer := (IMG_WIDTH * IMG_HEIGHT * BATCH_SIZE)/4;
	constant SERIALIZER_OUTPUT_ARRAY_SIZE : integer := POOLING_OUTPUT_ARRAY_SIZE * OUTPUT_CHANNELS;
	
	type t_pixel_array is array (0 to INPUT_ARRAY_SIZE - 1) of integer;
	type t_pixel_array_pool is array (0 to POOLING_OUTPUT_ARRAY_SIZE - 1) of integer;
	type t_kernel_array is array (0 to KERNEL_SIZE - 1) of t_pixel_array;
	type t_channel_array is array(0 to INPUT_CHANNELS - 1) of t_kernel_array;
	type t_serializer_array is array(0 to SERIALIZER_OUTPUT_ARRAY_SIZE - 1) of integer;
	
	signal s_Clk_i, s_n_Res_i, s_C1_Valid_i, s_C1_Valid_o : std_logic;
	signal s_C1_Last_o, s_C1_Last_i, s_C1_Ready_o : std_logic;
	signal s_C1_X_i : std_logic_vector(BIT_WIDTH_IN*INPUT_CHANNELS*KERNEL_SIZE - 1 downto 0);
	signal s_C1_Y_o : unsigned(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0);
	signal s_Pool_Last_o, s_Pool_Valid_o, s_Pool_Ready_o : std_logic;
	signal s_Pool_Data_o : std_logic_vector((BIT_WIDTH_OUT*OUTPUT_CHANNELS)-1 downto 0);
	signal s_Serializer_Data_o : std_logic_vector(BIT_WIDTH_OUT-1 downto 0);
	signal s_Serializer_Ready_o, s_Serializer_Valid_o, s_Serializer_Last_o : std_logic;
	signal s_Serializer_Ready_i : std_logic;
	
	file kernel_file : text;
	constant char_num : string(1 to 10) := "0123456789";
	
	signal sim_ended : std_logic := '0';
	signal conv2d_done : std_logic := '0';
	signal pool_done : std_logic := '0';
	signal serialize_done : std_logic := '0';
	
begin
  
	uit_0 : entity work.Conv2D_1
	generic map(
		BIT_WIDTH_IN,
		BIT_WIDTH_OUT,
		INPUT_CHANNELS,
		OUTPUT_CHANNELS
	) port map( --default generics
		Clk_i => s_Clk_i,
		n_Res_i => s_n_Res_i,
		Valid_i => s_C1_Valid_i,
		Valid_o => s_C1_Valid_o,
		X_i => s_C1_X_i,
		Y_o => s_C1_Y_o,
		Last_i => s_C1_Last_i,
		Ready_i => s_Pool_Ready_o,
		Last_o => s_C1_Last_o,
		Ready_o => s_C1_Ready_o
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
		
		S_layer_tvalid_i => s_C1_Valid_o,
		S_layer_tdata_i => std_logic_vector(s_C1_Y_o),
		S_layer_tkeep_i => (others => '0'), 
		S_layer_tlast_i => s_C1_Last_o,
		S_layer_tready_o => s_Pool_Ready_o,
		
		M_layer_tvalid_o => s_Pool_Valid_o,
		M_layer_tdata_o => s_Pool_Data_o,
		M_layer_tkeep_o => open,
		M_layer_tlast_o => s_Pool_Last_o,
		M_layer_tready_i => s_Serializer_Ready_o
	);
	
	uit_2 : entity work.Serializer
	generic map(
		VECTOR_WIDTH => BIT_WIDTH_OUT,
		INPUT_CHANNELS => OUTPUT_CHANNELS
	) port map(
		Clk_i => s_Clk_i,
		n_Res_i => s_n_Res_i,
		Valid_i => s_Pool_Valid_o,
		Ready_i => s_Serializer_Ready_i,
		Valid_o => s_Serializer_Valid_o,
		Ready_o => s_Serializer_Ready_o,
		Data_i => s_Pool_Data_o,
		Data_o => s_Serializer_Data_o
	);
  
	set_ready : process(s_Clk_i)
		variable seed1 : positive := 1;
		variable seed2 : positive := 1;
		variable x : real;
		variable y : integer;
	begin
		if rising_edge(s_Clk_i) then
			uniform(seed1, seed2, x);
			y := integer(floor(x * 2.0));
			if y = 0 then
				s_Serializer_Ready_i <= '1';
			else
				s_Serializer_Ready_i <= '0';
			end if;
		end if;
	end process;
  
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
	
	get_output_conv2d : process(s_Clk_i, conv2d_done)
		variable K : integer := 0;
		type t_output_array is array(0 to OUTPUT_CHANNELS - 1) of t_pixel_array;
		variable output : t_output_array;
		variable output_line : line;
        variable file_name_out : string(1 to 25) := "tmp/conv2d_1_output00.txt";
	begin
		if s_C1_Valid_o = '1' and rising_edge(s_Clk_i) then
			--report integer'image(K);
			for I in 0 to OUTPUT_CHANNELS - 1 loop
				output(I)(K) := to_integer(s_C1_Y_o((I+1)*BIT_WIDTH_OUT - 1 downto I*BIT_WIDTH_OUT));
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
	
	get_output_pooling : process(s_Clk_i, pool_done)
		variable K : integer := 0;
		type t_output_array_pool is array(0 to OUTPUT_CHANNELS - 1) of t_pixel_array_pool;
		variable output : t_output_array_pool;
		variable output_line : line;
        variable file_name_out : string(1 to 26) := "tmp/pooling_1_output00.txt";
	begin
		if s_Pool_Valid_o = '1' and rising_edge(s_Clk_i) then
			for I in 0 to OUTPUT_CHANNELS - 1 loop
				output(I)(K) := to_integer(unsigned(s_Pool_Data_o((I+1)*BIT_WIDTH_OUT - 1 downto I*BIT_WIDTH_OUT)));
			end loop;
			K := K + 1;
		elsif pool_done = '1' then
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
	
	get_output_serializer : process(s_Clk_i, serialize_done)
		variable K : integer := 0;
		variable output : t_serializer_array;
		variable output_line : line;
        variable file_name_out : string(1 to 25) := "tmp/serializer_output.txt";
	begin
		if s_Serializer_Valid_o = '1' and rising_edge(s_Clk_i) then
			output(K) := to_integer(unsigned(s_Serializer_Data_o));
			K := K + 1;
		elsif serialize_done = '1' then
			file_open(kernel_file, file_name_out, write_mode);
			for I in 0 to SERIALIZER_OUTPUT_ARRAY_SIZE - 1 loop
				write(output_line, output(I));
				writeline(kernel_file, output_line);
			end loop;
			file_close(kernel_file);
		end if;	
	end process;

	set_input : process
	    variable channel_input : t_channel_array;
        variable input_line : line;
        variable input_int : integer;
        variable file_name : string(1 to 26) := "tmp/conv2d_1_c00input0.txt";
		variable K : integer := 0;
	begin
		for J in 0 to INPUT_CHANNELS - 1 loop
			for I in 0 to KERNEL_SIZE - 1 loop
				file_name(22) := char_num(I+1);
				file_name(15) := char_num(J/10 + 1);
				file_name(16) := char_num(J mod 10 + 1);
				file_open(kernel_file, file_name, read_mode);
				K := 0;
				while not endfile(kernel_file) loop
					readline(kernel_file, input_line);
					read(input_line, input_int);
					channel_input(J)(I)(K) := input_int;
					K := K + 1;
				end loop;
				file_close(kernel_file);
			end loop;
		end loop;
		
		s_C1_Last_i <= '0';
		s_C1_X_i <= (others => '0');
		s_C1_Valid_i <= '0';
		wait until rising_edge(s_n_Res_i);
		wait until rising_edge(s_C1_Ready_o);
		for L in 0 to INPUT_ARRAY_SIZE - 1 loop
			wait until rising_edge(s_Clk_i);
			while s_C1_Ready_o = '0' loop
				s_C1_Last_i <= '0';
				s_C1_X_i <= (others => '0');
				s_C1_Valid_i <= '0';
				wait until rising_edge(s_Clk_i);
			end loop;
			if (L mod IMG_WIDTH) = IMG_WIDTH - 1 then
				s_C1_Last_i <= '1';
			else
				s_C1_Last_i <= '0';
			end if;
			s_C1_Valid_i <= '1';
			for J in 0 to INPUT_CHANNELS - 1 loop
				for I in 0 to KERNEL_SIZE - 1 loop
					s_C1_X_i((J)*(KERNEL_SIZE*BIT_WIDTH_IN) + (I+1)*BIT_WIDTH_IN - 1 downto J*(KERNEL_SIZE*BIT_WIDTH_IN) + I*BIT_WIDTH_IN) <= std_logic_vector(to_unsigned(channel_input(J)(I)(L), BIT_WIDTH_IN));
				end loop;
			end loop;
		end loop;
		wait until rising_edge(s_Clk_i);
		s_C1_Last_i <= '0';
		s_C1_Valid_i <= '0';
		s_C1_X_i <= (others => '0');
		for L in 0 to 20 loop
			wait until rising_edge(s_Clk_i);
		end loop;
		conv2d_done <= '1';
		for L in 0 to 20 loop
			wait until rising_edge(s_Clk_i);
		end loop;
		pool_done <= '1';
		for L in 0 to 20 loop
			wait until rising_edge(s_Clk_i);
		end loop;
		serialize_done <= '1';
		for L in 0 to 20 loop
			wait until rising_edge(s_Clk_i);
		end loop;
		sim_ended <= '1';
		wait;
	end process;
end beh;