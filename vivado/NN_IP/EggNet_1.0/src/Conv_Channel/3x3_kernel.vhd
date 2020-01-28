-- todo weights different resolution from input

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;

entity Kernel3x3 is
	generic(
		BIT_WIDTH_IN : integer := 8;
		BIT_WIDTH_OUT : integer := 16;
		WEIGHT : weight_array_t := (0,0,0,0,0,0,0,0,0)
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		X_i : in std_logic_vector(BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out signed(BIT_WIDTH_OUT - 1 downto 0)
	);
end Kernel3x3;

architecture beh of Kernel3x3 is
begin
	sync : process(Clk_i, n_Res_i)
		type Mult_output_array is array (KERNEL_SIZE - 1 downto 0) of signed(BIT_WIDTH_OUT - 1 downto 0);
		variable M_out : Mult_output_array;
	begin
		if n_Res_i = '0' then
			Y_o <= (others => '0');
		elsif rising_edge(Clk_i) and Valid_i = '1' then
			for I in 0 to 8 loop
				M_out(I) := to_signed(WEIGHT(I), BIT_WIDTH_IN) * signed(X_i((I+1)*BIT_WIDTH_IN - 1 downto I*BIT_WIDTH_IN));
			end loop;
			Y_o <= M_out(0) + M_out(1) + M_out(2) + M_out(3) + M_out(4) + M_out(5) + M_out(6) + M_out(7) + M_out(8);
		end if;
	end process;
end beh;
