library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.Kernel3x3;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;

entity ConvChannel is
	generic(
		BIT_WIDTH_IN : integer := 8;
		KERNEL_WIDTH_OUT : integer := 16;
		BIT_WIDTH_OUT : integer := 8;
		N : integer := 2
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		X_i : in std_logic_vector(N*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out signed(BIT_WIDTH_OUT - 1 downto 0)
	);
end ConvChannel;

architecture beh of ConvChannel is
	signal K_out : signed(N*KERNEL_WIDTH_OUT - 1 downto 0);
	type kernel_array_t is array (0 to N-1) of weight_array_t;
	constant DEFAULT_KERNELS : kernel_array_t :=
		((0,1,2,3,4,5,6,7,8),
		 (8,7,6,5,4,3,2,1,0));
	--This is replaced by a script:
	--constant KERNELS : kernel_array_t :=
	--({kernel_array})
begin
	kernels : for I in 0 to N-1 generate
		krnl : entity Kernel3x3 generic map(
			BIT_WIDTH_IN,
			KERNEL_WIDTH_OUT,
			DEFAULT_KERNELS(I)
		) port map(
			Clk_i, 
			n_Res_i, 
			Valid_i, 
			X_i((I+1)*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto I*BIT_WIDTH_IN*3*3), 
			K_out((I+1)*KERNEL_WIDTH_OUT - 1 downto I*KERNEL_WIDTH_OUT)
		); 
	end generate;
	
	adder : process(Clk_i, n_Res_i)
		constant ADD_OUTPUT_LEN : integer := BIT_WIDTH_IN*KERNEL_SIZE + (ceil(log2(BIT_WIDTH_IN*KERNEL_SIZE)));
		signal A_o : std_logic_vector(ADD_OUTPUT_LEN - 1 downto 0)
	begin
		if n_Res_i = '0' then
			Y_o <= (others => '0');
		elsif rising_edge(Clk_i) and Valid_i = '1' then
			--TODO implement adder tree?
		end if;
	end process;
end beh;
