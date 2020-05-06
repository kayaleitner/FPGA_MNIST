library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.clogb2_Pkg.all;

use work.cn_l1_0;
use work.cn_l1_1;
use work.cn_l1_2;
use work.cn_l1_3;
use work.cn_l1_4;
use work.cn_l1_5;
use work.cn_l1_6;
use work.cn_l1_7;
use work.cn_l1_8;
use work.cn_l1_9;
use work.cn_l1_10;
use work.cn_l1_11;
use work.cn_l1_12;
use work.cn_l1_13;
use work.cn_l1_14;
use work.cn_l1_15;



entity Conv2D_Shift_Layer_0 is
  generic
  (
    BIT_WIDTH_IN : INTEGER := 8;
    BIT_WIDTH_OUT : INTEGER := 8;
    INPUT_CHANNELS : INTEGER := 1;
    OUTPUT_CHANNELS : INTEGER := 16;
    OUTPUT_SHIFT : INTEGER := 2;
    OUTPUT_MAX : INTEGER := 15;
    OUTPUT_MIN : INTEGER := 0; 
    KERNEL_WEIGHTS : STRING := "";
    BIAS_WEIGHTS : STRING := ""
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
    X_i : in std_logic_vector(INPUT_CHANNELS * BIT_WIDTH_IN * KERNEL_SIZE - 1 downto 0);
    Y_o : out unsigned(OUTPUT_CHANNELS * BIT_WIDTH_OUT - 1 downto 0)
  );
end Conv2D_Shift_Layer_0;

architecture beh of Conv2D_Shift_Layer_0 is

  -- Define Arrays
  type channel_weights_array_t is array (0 to INPUT_CHANNELS - 1) of weight_array_t;
  type layer_weights_array_t is array (0 to OUTPUT_CHANNELS - 1) of channel_weights_array_t;
  type integer_vector_t is array (natural range<>) of INTEGER;

  signal ready_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);
  signal valid_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);
  signal last_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);

  
  
  signal layer_weights_array : layer_weights_array_t;
  constant layer_bias : integer_vector(0 to OUTPUT_CHANNELS-1) := (others => 0); 
  

  -- WEIGHT_SHIFTS : conv_channel_kernel_shift_t(0 to N_INPUT_CHANNELS-1);
  -- WEIGHT_SIGNS : conv_channel_kernel_sign_t(0 to N_INPUT_CHANNELS-1)

  -- Layer temporary weights, just used to constrain the unconstrained type
  type temp_channel_weights_shifts_t is array(0 to INPUT_CHANNELS-1) of conv_channel_kernel_shift_t;
  type temp_channel_weights_signs_t is array(0 to INPUT_CHANNELS-1) of conv_channel_kernel_sign_t;

  type channel_weights_shifts_array_t is array (0 to OUTPUT_CHANNELS-1) of temp_channel_weights_shifts_t;
  type channel_weights_signs_array_t is array (0 to OUTPUT_CHANNELS-1) of temp_channel_weights_signs_t;
  

  component cn_l1_0 is
    generic
    (
      BIT_WIDTH_IN : INTEGER;
      BIT_WIDTH_OUT : INTEGER;
      N_INPUT_CHANNELS : INTEGER;
      OUTPUT_SHIFT : INTEGER;
      OUTPUT_MAX : INTEGER;
      OUTPUT_MIN : INTEGER;
      BIAS : INTEGER
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
  end component;

begin

  Ready_o <= ready_out(0);
  Valid_o <= valid_out(0);
  Last_o <= last_out(0);

  generate_channels : for I in 0 to OUTPUT_CHANNELS generate
    -- Instantiate hte channels
    conv_channe_i : cn_l1_0
    generic
    map (
      BIT_WIDTH_IN => BIT_WIDTH_IN,
      BIT_WIDTH_OUT => BIT_WIDTH_OUT,
      N_INPUT_CHANNELS => INPUT_CHANNELS,

      -- Must be loaded from elsewhere
      OUTPUT_SHIFT => OUTPUT_SHIFT,
      OUTPUT_MAX => OUTPUT_MAX,
      OUTPUT_MIN => OUTPUT_MIN,
      BIAS => layer_bias(I)
    )
    port map
    (
      Clk_i => Clk_i,
      n_Res_i => n_Res_i,
      Valid_i => Valid_i,
      Valid_o => Valid_o,
      Last_i => Last_i,
      Last_o => Last_o,
      Ready_i => Ready_i,
      Ready_o => Ready_o,
      X_i => X_i,
      Y_o => Y_o((I + 1) * BIT_WIDTH_OUT - 1 downto I * BIT_WIDTH_OUT)
    );
  end generate; -- generate_channels

end beh;