library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.kernel_pkg.all;
use work.ShiftKernel3x3;

library vunit_lib;
context vunit_lib.vunit_context;

-------------------------------------------------------------------
-- Randomized test using coverage with OSVVM                     --
-------------------------------------------------------------------


entity tb_3x3_shift_kernel is
    generic (
        runner_cfg : string;
        tb_path    : string;
        csv_image  : string := "tb_3x3_shift_kernel_image.csv";
        csv_temp   : string := "tb_3x3_shift_kernel_temp.csv";
        csv_o      : string := "tb_3x3_shift_kernel_out.csv";
        BIT_WIDTH_IN : NATURAL;
		BIT_WIDTH_OUT : NATURAL;
		encoded_tb_cfg : string
		-- WEIGHT_SHIFTS : conv_kernel_3x3_weight_shift_t := (0, 0, 0, 0, 0, 0, 0, 0, 0);
		-- WEIGHT_SIGNS : conv_kernel_3x3_weight_sign_t := ('0', '0', '0', '0', '0', '0', '0', '0', '0')
    );
end tb_3x3_shift_kernel;



architecture beh of tb_3x3_shift_kernel is

    type tb_cfg_t is record
        kernel_shifts     : conv_kernel_3x3_weight_shift_t;
        kernel_signs      : conv_kernel_3x3_weight_sign_t;
    end record tb_cfg_t;

	-- This function initializes ROM with the data from a .mif file.
	impure function string_to_int_vec(mif_file_name : in string) 
	return conv_kernel_3x3_weight_shift_t is
		file mif_file 		: text open read_mode is mif_file_name;
		variable mif_line	: line;
		variable temp_bv	: bit_vector(DATA_WIDTH-1 downto 0);
		variable temp_mem	: mem_type;
	begin

		for i in 0 to KERNEL_SIZE-1 loop
			readline (mif_file, mif_line);
			read(mif_line, temp_bv);
			temp_mem(i) := to_stdlogicvector(temp_bv);
		end loop;

		return temp_mem;
	end function;

    impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
    begin
        return (kernel_shifts => conv_kernel_3x3_weight_shift_t'value(get(encoded_tb_cfg, "kernel_shifts")),
                kernel_signs => conv_kernel_3x3_weight_sign_t'value(get(encoded_tb_cfg, "kernel_signs"))
        );
    end function decode;

    constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

	-- Setup data in and output
	-- constant BIT_WIDTH_IN : INTEGER := 8;
	-- constant BIT_WIDTH_OUT : INTEGER := 20;
	-- test kernel: Used from layer 0
	-- constant WEIGHT_SHIFTS : conv_kernel_3x3_weight_shift_t := (1, 4, 1, 2, 4, 1, 1, 2, 2);
	-- constant WEIGHT_SIGNS : conv_kernel_3x3_weight_sign_t := ('0', '1', '1', '0', '0', '1', '0', '0', '1');
	-- constant INPUTS : weight_array_t := (0, 0, 0, 74, 247, 41, 69, 215, 148);

	constant CLK_PERIOD : TIME := 10 ns; -- 100MHz
	 
	-- Delay constants
	 constant OP_DELAY : TIME := 10 ns;

	signal s_Clk_i, s_n_Res_i, s_Valid_i : std_logic;
	signal s_X_i : std_logic_vector(BIT_WIDTH_IN * KERNEL_SIZE - 1 downto 0);
	signal s_Y_o : signed(BIT_WIDTH_OUT - 1 downto 0);
begin



	uit : entity work.ShiftKernel3x3
		generic map(
			BIT_WIDTH_IN=>BIT_WIDTH_IN,
			BIT_WIDTH_OUT=>BIT_WIDTH_OUT,
			WEIGHT_SHIFTS=>tb_cfg.weight_shifts,
			WEIGHT_SIGNS=>tb_cfg.weight_signs
		) 
		port map (
			Clk_i => s_Clk_i,
			n_Res_i => s_n_Res_i,
			Valid_i => s_Valid_i,
			X_i => s_X_i,
			Y_o => s_Y_o
		);


	

	-- Generates the clock signal
	clkgen : process
	begin
		s_Clk_i <= '0';
		wait for CLK_PERIOD/2;
		s_Clk_i <= '1';
		wait for CLK_PERIOD/2;
	end process clkgen;

	-- Generates the reset signal
	reset : process
	begin -- process reset
		s_n_Res_i <= '0';
		wait for 55 ns;
		s_n_Res_i <= '1';
		wait;
	end process;

	input : process
		variable seed1 : POSITIVE;
		variable seed2 : POSITIVE;
		variable x : real;
		variable y : INTEGER;
		variable result : INTEGER := 0;

        -- Read the test data
		variable image : integer_array_t := load_csv(tb_path & csv_image);
		variable temp : integer_array_t := load_csv(tb_path & csv_temp);

	begin

	    -- Init VUNIT
        test_runner_setup(runner, runner_cfg);

        -- Not working
        -- info("Runner Config: " & to_string(runner_cfg));
        -- info("Image Data: " & to_string(image));
        -- info("Temp Data:  " & to_string(temp));

		s_X_i <= (others => '0');
		s_Valid_i <= '0';

		wait until rising_edge(s_n_Res_i);
		s_Valid_i <= '1';

		--fill input vector with random values between - 2**(BIT_WIDTH_IN - 1) and  2**(BIT_WIDTH_IN - 1) - 1
		for I in 0 to KERNEL_SIZE loop

			-- y := integer(floor(x * (2.0 ** BIT_WIDTH_IN)));
			-- y := image(I);
			y := get(image, 0, I);

			-- Print input
			report "X(" & INTEGER'image(I) & "):            " & INTEGER'image(y);
			report "WEIGHT_SHIFT(" & INTEGER'image(I) & "): " & INTEGER'image(WEIGHT_SHIFTS(I));
			report "WEIGHT_SIGNS(" & INTEGER'image(I) & "): " & std_logic'image(WEIGHT_SIGNS(I));
			
			s_X_i((I + 1) * BIT_WIDTH_IN - 1 downto I * BIT_WIDTH_IN) <= std_logic_vector(to_signed(y, BIT_WIDTH_IN));

		end loop;

		--Compare expected to actual result
		report "Result: " & INTEGER'image(result);
		wait until rising_edge(s_Clk_i);
		s_Valid_i <= '0';
		wait until rising_edge(s_Clk_i);
		report "Output from uit: " & INTEGER'image(to_integer(s_Y_o));
		assert to_integer(s_Y_o) = result report "Actual and expected output does not match up!" severity error;

        test_runner_cleanup(runner);
	end process;
end beh;