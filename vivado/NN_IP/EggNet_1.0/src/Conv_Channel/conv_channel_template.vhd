library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;
use work.kernel_pkg.all;
use work.Kernel3x3;

entity ConvChannelTemplate is
	generic(
		BIT_WIDTH_IN : integer := 8;
		KERNEL_WIDTH_OUT : integer := 20;
		BIT_WIDTH_OUT : integer := 8;
		N : integer := 2;
		OUTPUT_MSB : integer := 15
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		Valid_o : out std_logic;
		X_i : in std_logic_vector(N*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out unsigned(BIT_WIDTH_OUT - 1 downto 0)
	);
end ConvChannelTemplate;

architecture beh of ConvChannelTemplate is
	
	constant SUM_WIDTH : integer := KERNEL_WIDTH_OUT + integer(ceil(log2(real(N))));
	
    signal s_add_out : signed(SUM_WIDTH-1 downto 0);
	signal K_out : signed(N*KERNEL_WIDTH_OUT - 1 downto 0);
	
	type term_vector_t is array (integer range <>) of signed(SUM_WIDTH - 1 downto 0);
	signal term_vector : term_vector_t(0 to N-1);
	
	type kernel_array_t is array (0 to N-1) of weight_array_t;
	constant KERNELS : kernel_array_t := ((-90,80,-70,-60,50,-40,30,-20,-10), (10,20,-30,-40,50,-60,-70,80,90));
	
	function ternary_adder_tree
	(
		input_term_vector   : term_vector_t
	)
	return signed is
		constant    N_t                     	: natural                       := input_term_vector'length;
		constant    t_vec             		    : term_vector_t(0 to (N_t - 1))	:= input_term_vector;
		constant    LEFT_TREE_N                 : natural                       := ((N_t + 2) / 3);
		constant    MIDDLE_TREE_N               : natural                       := (((N_t - LEFT_TREE_N) + 1) / 2);
		constant    RIGHT_TREE_N                : natural                       := (N_t - LEFT_TREE_N - MIDDLE_TREE_N);
		constant    LEFT_TREE_LOW_INDEX         : natural                       := 0;
		constant    LEFT_TREE_HIGH_INDEX        : natural                       := (LEFT_TREE_LOW_INDEX + LEFT_TREE_N - 1);
		constant    MIDDLE_TREE_LOW_INDEX       : natural                       := (LEFT_TREE_HIGH_INDEX + 1);
		constant    MIDDLE_TREE_HIGH_INDEX      : natural                       := (MIDDLE_TREE_LOW_INDEX + MIDDLE_TREE_N - 1);
		constant    RIGHT_TREE_LOW_INDEX        : natural                       := (MIDDLE_TREE_HIGH_INDEX + 1);
		constant    RIGHT_TREE_HIGH_INDEX       : natural                       := (RIGHT_TREE_LOW_INDEX + RIGHT_TREE_N - 1);
    begin
		if (N_t = 1) then
			return t_vec(0);
		elsif (N_t = 2) then
			report integer'image(SUM_WIDTH);
			report integer'image(to_integer(t_vec(0)));
			report integer'image(to_integer(t_vec(1)));
			return t_vec(0) + t_vec(1);
		else
			return	 ternary_adder_tree(t_vec(LEFT_TREE_LOW_INDEX   to LEFT_TREE_HIGH_INDEX  ))
					+ternary_adder_tree(t_vec(MIDDLE_TREE_LOW_INDEX to MIDDLE_TREE_HIGH_INDEX))
					+ternary_adder_tree(t_vec(RIGHT_TREE_LOW_INDEX  to RIGHT_TREE_HIGH_INDEX ));
		end if;
	end function ternary_adder_tree;
	
	signal start_addition : std_logic := '0';

begin
	kernels_gen : for I in 0 to N-1 generate
		krnl : entity Kernel3x3 generic map(
			BIT_WIDTH_IN,
			KERNEL_WIDTH_OUT,
			KERNELS(I)
		) port map(
			Clk_i, 
			n_Res_i, 
			Valid_i, 
			X_i((I+1)*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto I*BIT_WIDTH_IN*3*3), 
			K_out((I+1)*KERNEL_WIDTH_OUT - 1 downto I*KERNEL_WIDTH_OUT)
		); 
		term_vector(I) <= resize(K_out((I+1)*KERNEL_WIDTH_OUT - 1 downto I*KERNEL_WIDTH_OUT), SUM_WIDTH);
	end generate;
	
	   
	adder : process(Clk_i, n_Res_i)
	    variable add_out : signed(SUM_WIDTH-1 downto 0);
	begin
		if n_Res_i = '0' then
			Y_o <= (others => '0');
            Valid_o <= '0';
			start_addition <= '0';
		elsif rising_edge(Clk_i) then
            Valid_o <= '0';
			if start_addition = '1' then
				start_addition <= '0';
				add_out := ternary_adder_tree(term_vector);
				s_add_out <= add_out;
				if add_out(SUM_WIDTH-1) = '1' then
				    Y_o <= (others => '0');
				elsif add_out(SUM_WIDTH-1 downto OUTPUT_MSB+1) /= (add_out(SUM_WIDTH-1 downto OUTPUT_MSB+1)'range => '0') then
				    Y_o <= (others => '1');
				else
				    Y_o <= unsigned(std_logic_vector(add_out(OUTPUT_MSB downto OUTPUT_MSB-BIT_WIDTH_OUT+1)));
				end if;
				Valid_o <= '1';
			end if;
			if Valid_i = '1' then
				start_addition <= '1';
			end if;
		end if;
	end process;
end beh;
