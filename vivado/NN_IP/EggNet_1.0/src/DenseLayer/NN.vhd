library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.all;
use ieee.std_logic_unsigned.all;
use work.layer;

entity NeuralNetwork is
	generic(
		VECTOR_WIDTH : integer := 8;
		INPUT_COUNT  : integer := 1568;
		OUTPUT_COUNT : integer := 10
	); 
	port(
		Clk_i    : in std_logic;
		Resetn_i : in std_logic;
		Valid_i  : in std_logic;
		Data_i   : in std_logic_vector(VECTOR_WIDTH -1 downto 0); 
		Last_i   : in std_logic;
		Ready_i  : in std_logic;
		Ready_o  : out std_logic;
		Valid_o  : out std_logic;   
		Data_o   : out std_logic_vector(OUTPUT_COUNT * VECTOR_WIDTH - 1 downto 0)
	);
end NeuralNetwork;

architecture Behavioral of NeuralNetwork is
	constant INPUT_COUNT_L1 : integer := INPUT_COUNT;
	constant OUTPUT_COUNT_L1 : integer := 32;
	constant INPUT_COUNT_L2 : integer := OUTPUT_COUNT_L1;
	constant OUTPUT_COUNT_L2 : integer := OUTPUT_COUNT;

	signal s_L1_Reset_i, s_L2_Reset_i : std_logic := '0';
	signal s_L1_Start_i, s_L2_Start_i : std_logic := '0';
	signal s_L1_Rd_en_o, s_L2_Rd_en_o : std_logic;
	signal s_L1_Data_i, s_L2_Data_i : std_logic_vector(VECTOR_WIDTH-1 downto 0) := (others => '0');
	signal s_L1_Data_o : std_logic_vector((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT_L1)))))-1 downto 0);
	signal s_L2_Data_o : std_logic_vector((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT_L2)))))-1 downto 0);
	signal s_L1_Rd_addr_i : std_logic_vector(integer(ceil(log2(real(OUTPUT_COUNT_L1))))-1 downto 0) := (others => '0');
	signal s_L2_Rd_addr_i : std_logic_vector(integer(ceil(log2(real(OUTPUT_COUNT_L2))))-1 downto 0) := (others => '0');
	signal s_L1_Finished_o, s_L2_Finished_o : std_logic;
	signal s_L1_Rd_en_i, s_L2_Rd_en_i : std_logic := '0';

	signal Data_o_reg : std_logic_vector(OUTPUT_COUNT * VECTOR_WIDTH - 1 downto 0);

    type state_type is (
		ST_IDLE, 
		ST_INPUT_L1, 
		ST_WAIT_L1, 
		ST_INPUT_L2, 
		ST_WAIT_L2, 
		ST_OUTPUT,
		ST_END
	);
    signal state, state_next : state_type := ST_IDLE;
	signal state_temp : integer := 0;

	signal data_cnt_L1, data_cnt_L1_next   : integer range 0 to INPUT_COUNT_L1 := 0;
	signal data_cnt_L2, data_cnt_L2_next   : integer range 0 to INPUT_COUNT_L2 := 0;
	signal data_cnt_out, data_cnt_out_next : integer range 0 to OUTPUT_COUNT_L2 := 0;
	
begin
    dense_layer_1 : entity work.layer
    generic map(
		VECTOR_WIDTH  => VECTOR_WIDTH,
        INPUT_COUNT   => INPUT_COUNT_L1,
        OUTPUT_COUNT  => OUTPUT_COUNT_L1,
		ROM_FILE      => "dense_layer_1.mif")
    port map(
		Resetn_i => Resetn_i,
		Reset_calculation_i => s_L1_Reset_i,
		Clk_i => Clk_i,
		Start_i => s_L1_Start_i,
		Rd_en_o => s_L1_Rd_en_o,
		Data_i => s_L1_Data_i,
		Data_o => s_L1_Data_o,
		Rd_addr_i => s_L1_Rd_addr_i,
		Finished_o => s_L1_Finished_o,
		Rd_en_i => s_L1_Rd_en_i
	);
	
    dense_layer_2 : entity work.layer
    generic map(
		VECTOR_WIDTH  => VECTOR_WIDTH,
        INPUT_COUNT   => INPUT_COUNT_L2,
        OUTPUT_COUNT  => OUTPUT_COUNT_L2,
		ROM_FILE      => "dense_layer_2.mif")
    port map(
		Resetn_i => Resetn_i,
		Reset_calculation_i => s_L2_Reset_i,
		Clk_i => Clk_i,
		Start_i => s_L2_Start_i,
		Rd_en_o => s_L2_Rd_en_o,
		Data_i => s_L2_Data_i,
		Data_o => s_L2_Data_o,
		Rd_addr_i => s_L2_Rd_addr_i,
		Finished_o => s_L2_Finished_o,
		Rd_en_i => s_L2_Rd_en_i
	);
	
	state_machine_nextstate : process(state, s_L1_Rd_en_o, s_L1_Data_o, s_L1_Finished_o, s_L2_Rd_en_o, s_L2_Data_o, s_L2_Finished_o, Valid_i, Data_i, Last_i, Ready_i, data_cnt_L1, data_cnt_L2, data_cnt_out)
	begin
		state_next <= state;
		case state is
			when ST_IDLE => 
				state_temp <= 0;
				if Valid_i = '1' then
					state_next <= ST_INPUT_L1;
				end if;
			when ST_INPUT_L1 => 
				state_temp <= 1;
				if data_cnt_L1 = INPUT_COUNT_L1 - 1 then
					state_next <= ST_WAIT_L1;
				end if;
			when ST_WAIT_L1 => 
				state_temp <= 2;
				if s_L1_Finished_o = '1' then
					state_next <= ST_INPUT_L2;
				end if;
			when ST_INPUT_L2 => 
				state_temp <= 3;
				if data_cnt_L2 = INPUT_COUNT_L2 - 1 then
					state_next <= ST_WAIT_L2;
				end if;
			when ST_WAIT_L2 => 
				state_temp <= 4;
				if s_L2_Finished_o = '1' then
					state_next <= ST_OUTPUT;
				end if;
			when ST_OUTPUT =>
				state_temp <= 5;
				if data_cnt_out = OUTPUT_COUNT_L2 - 1 then
					state_next <= ST_END;
				end if;
			when ST_END =>
				state_temp <= 6;
				state_next <= ST_IDLE;
		end case;
	end process;
	
	state_machine_output : process(state, s_L1_Rd_en_o, s_L1_Data_o, s_L1_Finished_o, s_L2_Rd_en_o, s_L2_Data_o, s_L2_Finished_o, Valid_i, Data_i, Last_i, Ready_i, data_cnt_L1, data_cnt_L2, data_cnt_out)
		variable output_L1_cropped : std_logic_vector(VECTOR_WIDTH-1 downto 0);
		variable output_L2_cropped : std_logic_vector(VECTOR_WIDTH-1 downto 0);
	begin
		data_cnt_L1_next <= data_cnt_L1;
		data_cnt_L2_next <= data_cnt_L2;
		data_cnt_out_next <= data_cnt_out;
		Valid_o <= '0';
		Data_o <= (others => '0');
		Ready_o <= '0';
		s_L1_Rd_addr_i <= (others => '0');
		s_L2_Rd_addr_i <= (others => '0');
		s_L1_Rd_en_i <= '0';
		s_L2_Rd_en_i <= '0';
		s_L1_Start_i <= '0';
		s_L2_Start_i <= '0';
		s_L1_Data_i <= (others => '0');
		s_L2_Data_i <= (others => '0');
		s_L1_Reset_i <= '0';
		s_L2_Reset_i <= '0';
		case state is
			when ST_IDLE => 
				Ready_o <= '1';
				data_cnt_L1_next <= 0;
				if Valid_i = '1' then
					data_cnt_L1_next <= 1;
					s_L1_Start_i <= '1';
					s_L1_Data_i <= Data_i;
				end if;
				Data_o_reg <= (others => '0');
			when ST_INPUT_L1 => 
				Ready_o <= '1';
				if Valid_i = '1' then
					data_cnt_L1_next <= (data_cnt_L1 + 1) mod INPUT_COUNT_L1;
					s_L1_Data_i <= Data_i;
				end if;
			when ST_WAIT_L1 => 
				Ready_o <= '0';
				data_cnt_L1_next <= 0;
				data_cnt_L2_next <= 0;
			when ST_INPUT_L2 => 
				Ready_o <= '0';
				data_cnt_L2_next <= (data_cnt_L2 + 1) mod INPUT_COUNT_L2;
				s_L1_Rd_addr_i <= std_logic_vector(to_unsigned(data_cnt_L2, s_L1_Rd_addr_i'length));
				s_L1_Rd_en_i <= '1';
				if signed(s_L1_Data_o(s_L1_Data_o'length - 1 downto VECTOR_WIDTH)) < 0 then
					output_L1_cropped := (others => '0');
				elsif signed(s_L1_Data_o(s_L1_Data_o'length - 1 downto VECTOR_WIDTH)) > 255 then
					output_L1_cropped := (others => '1');
				else 
					output_L1_cropped := s_L1_Data_o(VECTOR_WIDTH * 2 - 1 downto VECTOR_WIDTH);
				end if;
				s_L2_Data_i <= output_L1_cropped;
				if data_cnt_L2 = 0 then
					s_L2_Start_i <= '1';
				end if;
			when ST_WAIT_L2 => 
				Ready_o <= '0';
				data_cnt_L2_next <= 0;
			when ST_OUTPUT =>
				data_cnt_out_next <= (data_cnt_out + 1) mod OUTPUT_COUNT_L2;
				Ready_o <= '0';
				s_L2_Rd_addr_i <= std_logic_vector(to_unsigned(data_cnt_out, s_L2_Rd_addr_i'length));
				s_L2_Rd_en_i <= '1';
				if signed(s_L2_Data_o(s_L2_Data_o'length - 1 downto VECTOR_WIDTH)) < 0 then
					output_L2_cropped := (others => '0');
				elsif signed(s_L2_Data_o(s_L2_Data_o'length - 1 downto VECTOR_WIDTH)) > 255 then
					output_L2_cropped := (others => '1');
				else 
					output_L2_cropped := s_L2_Data_o(VECTOR_WIDTH * 2 - 1 downto VECTOR_WIDTH);
				end if;
				Data_o_reg((data_cnt_out+1)*VECTOR_WIDTH - 1 downto data_cnt_out*VECTOR_WIDTH) <= output_L2_cropped;
			when ST_END =>
				Valid_o <= '1';
				Data_o <= Data_o_reg;
				data_cnt_out_next <= 0;
				s_L1_Reset_i <= '1';
				s_L2_Reset_i <= '1';
		end case;
	end process;
	
    sync : process(Clk_i, Resetn_i)
    begin
		if Resetn_i = '0' then
			data_cnt_L1 <= 0;
			data_cnt_L2 <= 0;
			data_cnt_out <= 0;
			state <= ST_IDLE;
        elsif rising_edge(Clk_i) then
			state <= state_next;
			data_cnt_L1 <= data_cnt_L1_next;
			data_cnt_L2 <= data_cnt_L2_next;
			data_cnt_out <= data_cnt_out_next;
		end if; 
    end process;
	
end architecture;