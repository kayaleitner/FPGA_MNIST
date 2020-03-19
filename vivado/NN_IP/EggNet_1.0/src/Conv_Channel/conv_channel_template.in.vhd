library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.clogb2_Pkg.all;

entity {{ conv_channel_name }} is
	generic
	(
		BIT_WIDTH_IN : INTEGER := {{ bit_width_in }};
		KERNEL_WIDTH_OUT : INTEGER := {{ kernel_width }};
		BIT_WIDTH_OUT : INTEGER := {{ bit_width_out }};
		N : INTEGER := 2;
		OUTPUT_MSB : INTEGER := 15;
		BIAS : INTEGER := 0
	);
	port
	(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		Valid_o : out std_logic;
		Last_i : in std_logic;
		Last_o : out std_logic;
		Ready_i : in std_logic;
		Ready_o : out std_logic;
		X_i : in std_logic_vector(N * BIT_WIDTH_IN * KERNEL_SIZE - 1 downto 0);
		Y_o : out unsigned(BIT_WIDTH_OUT - 1 downto 0)
	);
end {{ conv_channel_name }};

architecture beh of {{ conv_channel_name }} is

	--constant SUM_WIDTH : integer := KERNEL_WIDTH_OUT + integer(ceil(log2(real(N)))) + 1;
	constant SUM_WIDTH : INTEGER := KERNEL_WIDTH_OUT + clogb2(N) + 1;

	signal K_out : signed(N * KERNEL_WIDTH_OUT - 1 downto 0);

	type term_vector_t is array (INTEGER range <>) of signed(SUM_WIDTH - 1 downto 0);
	signal term_vector : term_vector_t(0 to N - 1);

	type kernel_array_t is array (0 to N - 1) of weight_array_t;
	-- constant KERNELS : kernel_array_t := (0 => (53, -10, -82, 36, 9, -56, 61, 31, -44));
	constant KERNELS : kernel_array_t := (0 => {{ conv_channel_weights }});

	function ternary_adder_tree
	(
		input_term_vector : term_vector_t
	)
		return signed is
		constant N_t : NATURAL := input_term_vector'length;
		constant t_vec : term_vector_t(0 to (N_t - 1)) := input_term_vector;
		constant LEFT_TREE_N : NATURAL := ((N_t + 2) / 3);
		constant MIDDLE_TREE_N : NATURAL := (((N_t - LEFT_TREE_N) + 1) / 2);
		constant RIGHT_TREE_N : NATURAL := (N_t - LEFT_TREE_N - MIDDLE_TREE_N);
		constant LEFT_TREE_LOW_INDEX : NATURAL := 0;
		constant LEFT_TREE_HIGH_INDEX : NATURAL := (LEFT_TREE_LOW_INDEX + LEFT_TREE_N - 1);
		constant MIDDLE_TREE_LOW_INDEX : NATURAL := (LEFT_TREE_HIGH_INDEX + 1);
		constant MIDDLE_TREE_HIGH_INDEX : NATURAL := (MIDDLE_TREE_LOW_INDEX + MIDDLE_TREE_N - 1);
		constant RIGHT_TREE_LOW_INDEX : NATURAL := (MIDDLE_TREE_HIGH_INDEX + 1);
		constant RIGHT_TREE_HIGH_INDEX : NATURAL := (RIGHT_TREE_LOW_INDEX + RIGHT_TREE_N - 1);
	begin
		if (N_t = 1) then
			return t_vec(0);
		elsif (N_t = 2) then
			return t_vec(0) + t_vec(1);
		else
			return ternary_adder_tree(t_vec(LEFT_TREE_LOW_INDEX to LEFT_TREE_HIGH_INDEX))
			+ ternary_adder_tree(t_vec(MIDDLE_TREE_LOW_INDEX to MIDDLE_TREE_HIGH_INDEX))
			+ ternary_adder_tree(t_vec(RIGHT_TREE_LOW_INDEX to RIGHT_TREE_HIGH_INDEX));
		end if;
	end function ternary_adder_tree;

	signal start_addition : std_logic := '0';
	signal is_last : std_logic := '0';

begin
	Ready_o <= not(Valid_i) and Ready_i and not(start_addition);

	kernels_gen : for I in 0 to N - 1 generate
		krnl : entity Kernel3x3 generic
			map(
			BIT_WIDTH_IN,
			KERNEL_WIDTH_OUT,
			KERNELS(I)
			) port map
			(
			Clk_i,
			n_Res_i,
			Valid_i,
			X_i((I + 1) * BIT_WIDTH_IN * KERNEL_SIZE - 1 downto I * BIT_WIDTH_IN * 3 * 3),
			K_out((I + 1) * KERNEL_WIDTH_OUT - 1 downto I * KERNEL_WIDTH_OUT)
			);
		term_vector(I) <= resize(K_out((I + 1) * KERNEL_WIDTH_OUT - 1 downto I * KERNEL_WIDTH_OUT), SUM_WIDTH);
	end generate;

	adder : process (Clk_i, n_Res_i)
		variable add_out : signed(SUM_WIDTH - 1 downto 0);
	begin
		if n_Res_i = '0' then
			Y_o <= (others => '0');
			Valid_o <= '0';
			Last_o <= '0';
			start_addition <= '0';
			is_last <= '0';
		elsif rising_edge(Clk_i) then
			Valid_o <= '0';
			Last_o <= '0';
			if start_addition = '1' and Ready_i = '1' then
				add_out := ternary_adder_tree(term_vector) + to_signed(BIAS, SUM_WIDTH);
				if add_out(SUM_WIDTH - 1) = '1' then
					Y_o <= (others => '0');
				elsif add_out(SUM_WIDTH - 1 downto OUTPUT_MSB + 1) /= (add_out(SUM_WIDTH - 1 downto OUTPUT_MSB + 1)'range => '0') then
					Y_o <= (others => '1');
				else
					Y_o <= unsigned(std_logic_vector(add_out(OUTPUT_MSB downto OUTPUT_MSB - BIT_WIDTH_OUT + 1)));
				end if;
				Valid_o <= '1';
				if is_last = '1' then
					Last_o <= '1';
				else
					Last_o <= '0';
				end if;
				is_last <= '0';
				start_addition <= '0';
			end if;
			if Valid_i = '1' then
				is_last <= Last_i;
				start_addition <= '1';
			end if;
		end if;
	end process;
end beh;