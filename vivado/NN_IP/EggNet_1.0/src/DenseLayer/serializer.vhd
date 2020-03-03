library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Serializer is
	generic(
		VECTOR_WIDTH : integer := 8;
		INPUT_CHANNELS : integer := 32
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		Last_i : in std_logic;
		Ready_i : in std_logic;
		Valid_o : out std_logic;
		Last_o : out std_logic;
		Ready_o : out std_logic;
		Data_i : in std_logic_vector(INPUT_CHANNELS*VECTOR_WIDTH - 1 downto 0);
		Data_o : out std_logic_vector(VECTOR_WIDTH - 1 downto 0)
	);
end Serializer;

architecture Behavioral of Serializer is
	signal Data_i_reg : std_logic_vector(INPUT_CHANNELS*VECTOR_WIDTH - 1 downto 0);
	signal serialize : std_logic;
	signal output_counter : integer range 0 to INPUT_CHANNELS - 1 := 0;
	signal is_last : std_logic;
	signal s_Valid_o : std_logic;
begin
	
	Valid_o <= s_Valid_o;
	Ready_o <= not(s_Valid_o) and Ready_i and not(Valid_i) and not(serialize);

	output: process(Clk_i)
	begin
		if n_Res_i = '0' then
			s_Valid_o <= '0';
			Last_o <= '0';
			Data_o <= (others => '0');
			serialize <= '0';
			output_counter <= 0;
			is_last <= '0';
			Data_i_reg <= (others => '0');
		elsif rising_edge(Clk_i) then
			Data_o <= (others => '0');
			s_Valid_o <= '0';
			Last_o <= '0';
			if serialize = '1' then
				if Ready_i = '1' then
					Data_o <= Data_i_reg((output_counter+1) * VECTOR_WIDTH - 1 downto output_counter*VECTOR_WIDTH);
					s_Valid_o <= '1';
					if output_counter = INPUT_CHANNELS - 1 then
						if is_last = '1' then
							Last_o <= '1';
						end if;
						serialize <= '0';
					end if;
					output_counter <= (output_counter + 1) mod INPUT_CHANNELS;
				end if;
			else
				if Valid_i = '1' then
					is_last <= Last_i;
					serialize <= '1';
					Data_i_reg <= Data_i;
					if Ready_i = '1' then
						s_Valid_o <= '1';
						Data_o <= Data_i(VECTOR_WIDTH - 1 downto 0);
						output_counter <= (output_counter + 1) mod INPUT_CHANNELS;
					end if;
				end if;
			end if;
		end if;
	end process;
end Behavioral;