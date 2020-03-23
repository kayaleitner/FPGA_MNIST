library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.clogb2_Pkg.all;
use work.ShiftKernel3x3;


	entity {{ conv_channel_name }} is
		generic
		(
			BIT_WIDTH_IN : INTEGER := {{ input_bits }};
			BIT_WIDTH_OUT : INTEGER := {{ output_bits }};
			N_INPUT_CHANNELS : INTEGER := {{ n_input_channels }};
			OUTPUT_SHIFT : INTEGER := {{ output_shift }};
			OUTPUT_MAX : INTEGER := {{ output_max_value }};
			OUTPUT_MIN : INTEGER := {{ output_min_value }};
			BIAS : INTEGER := {{ bias }}
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
			X_i : in std_logic_vector(N_INPUT_CHANNELS * BIT_WIDTH_IN * KERNEL_SIZE - 1 downto 0);
			Y_o : out unsigned(BIT_WIDTH_OUT - 1 downto 0)
		);
	end {{ conv_channel_name }};

	architecture beh of {{ conv_channel_name }} is

		--constant SUM_WIDTH : integer := BIT_WIDTH_IN + integer(ceil(log2(real(N)))) + 1;
		-- Temporary width of for the summation to prevent overflowing
		constant SUM_WIDTH : INTEGER := BIT_WIDTH_IN + clogb2(N_INPUT_CHANNELS * KERNEL_SIZE + 1) + 1;

		signal K_out : signed(N_INPUT_CHANNELS * BIT_WIDTH_IN - 1 downto 0);

		type term_vector_t is array (INTEGER range <>) of signed(SUM_WIDTH - 1 downto 0);
		signal term_vector : term_vector_t(0 to N_INPUT_CHANNELS - 1);

		-- Array of Array of weights
		type kernel_array_t is array (0 to N_INPUT_CHANNELS - 1) of conv_kernel_3x3_weight_shift_t;
		type kernel_sign_array_t is array (0 to N_INPUT_CHANNELS - 1)  of conv_kernel_3x3_weight_sign_t;
		-- IMPORTANT: Kernels must be in column major order!
		-- So:
		-- 		KERNELS[0] = w[0,0]	= First row, first col
		-- 		KERNELS[1] = w[1,0] = second row, first col
		-- 		KERNELS[2] = w[2,0] = third row, first col
		-- 		KERNELS[3] = w[0,1]	= first row, second col
		-- 		...
		--
		-- Example:
		--  constant KERNELS : kernel_array_t := (0 => (-13, 34, 127, 22, -24, 112, -95, 70, 10), 1 => (-14, 8, -22, -24, 18, 2, 25, -10, -39), 2 => (-48, 13, 12, -53, -17, -23, 15, 37, 7), 3 => (77, -9, 66, 31, 48, 61, -53, 30, -13), 4 => (52, 67, 127, 86, 15, 97, -1, 45, 52), 5 => (-32, 24, -1, -49, -16, 1, 15, 19, 4), 6 => (-6, 11, 57, -10, 24, -1, -57, 6, 12), 7 => (8, -6, -59, -13, -27, -44, 3, -43, -1), 8 => (-68, 96, 15, -21, 58, -25, 61, 56, -10), 9 => (-62, 7, 58, -51, -20, 38, -58, -3, 42), 10 => (-6, 12, 6, -7, 30, 30, -2, 24, 10), 11 => (-31, -59, -32, -30, -12, -37, -4, -24, -41), 12 => (-19, 83, 19, 43, 31, -18, 79, -15, 8), 13 => (-44, -26, 21, -50, 9, -19, 1, 19, -26), 14 => (-20, 34, 11, -18, 29, 23, -20, -1, -6), 15 => (2, -48, -83, -22, -85, -37, -17, -3, -23));
		constant WEIGHT_SHIFTS : kernel_array_t := {{ conv_channel_weights }};
		constant WEIGHT_SIGNS : kernel_sign_array_t := {{ conv_channel_signs }};
		signal start_addition : std_logic := '0';
		signal is_last : std_logic := '0';

		

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


	begin
		Ready_o <= not(Valid_i) and Ready_i and not(start_addition);

		
		kernels_gen : for I in 0 to N_INPUT_CHANNELS - 1 generate
			-- Generate pseudo entities
			krnl : entity ShiftKernel3x3 
				generic map(
					BIT_WIDTH_IN,
					SUM_WIDTH,
					WEIGHT_SHIFTS(I),
					WEIGHT_SIGNS(I)
				) port map
				(
					Clk_i,
					n_Res_i,
					Valid_i,
					X_i((I + 1) * BIT_WIDTH_IN * KERNEL_SIZE - 1 downto I * BIT_WIDTH_IN * 3 * 3),
					K_out((I + 1) * SUM_WIDTH - 1 downto I * SUM_WIDTH)
				);
			term_vector(I) <= resize(K_out((I + 1) * SUM_WIDTH - 1 downto I * SUM_WIDTH), SUM_WIDTH);
		end generate;

		adder : process (Clk_i, n_Res_i)
			variable add_out : signed(SUM_WIDTH - 1 downto 0);
			variable out_shift_temp : signed(SUM_WIDTH-1 downto 0) := (others => '0');
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
					
					-- Correctly account for potential over- or underflow
					if to_integer(add_out) > OUTPUT_MAX then
						Y_o <= to_unsigned(OUTPUT_MAX, BIT_WIDTH_OUT);
					elsif to_integer(add_out) < OUTPUT_MIN then
						Y_o <= to_unsigned(OUTPUT_MIN, BIT_WIDTH_OUT);
					else
						-- Shift it so its compatibel with the output
						if OUTPUT_SHIFT < 0 then
							-- Shift to the left
							out_shift_temp := shift_left(add_out, OUTPUT_SHIFT);
						else
							-- Shift to the right
							out_shift_temp := shift_right(add_out, OUTPUT_SHIFT);
						end if;
						-- Simpy truncate the upper bits
						Y_o <= 	unsigned(std_logic_vector(out_shift_temp(BIT_WIDTH_OUT-1 downto 0)));
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


