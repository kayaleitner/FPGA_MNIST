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
		Data_i   : in std_logic_vector(INPUT_COUNT * VECTOR_WIDTH -1 downto 0); 
		Last_i   : in std_logic;
		Ready_i  : in std_logic;   
		Valid_o  : out std_logic;   
		Data_o   : out std_logic_vector(OUTPUT_COUNT * VECTOR_WIDTH - 1 downto 0)
	);
end NeuralNetwork;

architecture Behavioral of NeuralNetwork is
	constant INPUT_COUNT_L1 : integer := INPUT_COUNT;
	constant OUTPUT_COUNT_L1 : integer := 32;
	constant INPUT_COUNT_L2 : integer := OUTPUT_COUNT_L1;
	constant OUTPUT_COUNT_L2 : integer := OUTPUT_COUNT;

	signal s_L1_Start_i, s_L2_Start_i : std_logic;
	signal s_L1_Rd_en_o, s_L2_Rd_en_o : std_logic;
	signal s_L1_Data_i, s_L2_Data_i : std_logic_vector(VECTOR_WIDTH-1 downto 0);
	signal s_L1_Data_o : std_logic_vector((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT_L1)))))-1 downto 0);
	signal s_L2_Data_o : std_logic_vector((2*VECTOR_WIDTH + integer(ceil(log2(real(INPUT_COUNT_L2)))))-1 downto 0);
	signal s_L1_Rd_addr_i : std_logic_vector(integer(ceil(log2(real(OUTPUT_COUNT_L1))))-1 downto 0);
	signal s_L2_Rd_addr_i : std_logic_vector(integer(ceil(log2(real(OUTPUT_COUNT_L2))))-1 downto 0);
	signal s_L1_Finished_o, s_L2_Finished_o : std_logic;
	signal s_L1_Rd_en_i, s_L2_Rd_en_i : std_logic;

begin
    dense_layer_1 : entity work.layer
    generic map(
		VECTOR_WIDTH  => VECTOR_WIDTH,
        INPUT_COUNT   => INPUT_COUNT_L1,
        OUTPUT_COUNT  => OUTPUT_COUNT_L1,
		ROM_FILE      => "dense_layer_1.mif")
    port map(
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
		Clk_i => Clk_i,
		Start_i => s_L2_Start_i,
		Rd_en_o => s_L2_Rd_en_o,
		Data_i => s_L2_Data_i,
		Data_o => s_L2_Data_o,
		Rd_addr_i => s_L2_Rd_addr_i,
		Finished_o => s_L2_Finished_o,
		Rd_en_i => s_L2_Rd_en_i
	);
	
end architecture;