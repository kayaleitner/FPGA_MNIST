library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.ConvChannel0;
use work.ConvChannel1;
use work.ConvChannel2;
use work.ConvChannel3;
use work.ConvChannel4;
use work.ConvChannel5;
use work.ConvChannel6;
use work.ConvChannel7;
use work.ConvChannel8;
use work.ConvChannel9;
use work.ConvChannel10;
use work.ConvChannel11;
use work.ConvChannel12;
use work.ConvChannel13;
use work.ConvChannel14;
use work.ConvChannel15;
use work.clogb2_Pkg.all;

entity Conv2D_0 is
  generic
  (
    BIT_WIDTH_IN : INTEGER := 8;
    BIT_WIDTH_OUT : INTEGER := 8;
    INPUT_CHANNELS : INTEGER := 1;
    OUTPUT_CHANNELS : INTEGER := 16
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
end Conv2D_0;

architecture beh of Conv2D_0 is
  signal ready_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);
  signal valid_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);
  signal last_out : std_logic_vector(OUTPUT_CHANNELS - 1 downto 0);

  constant WEIGHT_SHIFTS : kernel_array_t := (0 => (3, 1, 1, 4, 3, 2, 1, 1, 3));
  constant WEIGHT_SIGNS : kernel_sign_array_t := (0 => ('0', '0', '0', '1', '1', '0', '1', '1', '0'));
		
begin
  Ready_o <= ready_out(0);
  Valid_o <= valid_out(0);
  Last_o <= last_out(0);
  convchan0 : entity ConvChannel0
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port map
    (
      Clk_i, n_Res_i,
      Valid_i, valid_out(0), Last_i, last_out(0), Ready_i, ready_out(0),
      X_i,
      Y_o(1 * BIT_WIDTH_OUT - 1 downto 0 * BIT_WIDTH_OUT)
    );

  convchan1 : entity ConvChannel1
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(1), Last_i, last_out(1), Ready_i, ready_out(1),
    X_i,
    Y_o(2 * BIT_WIDTH_OUT - 1 downto 1 * BIT_WIDTH_OUT)
    );

  convchan2 : entity ConvChannel2
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(2), Last_i, last_out(2), Ready_i, ready_out(2),
    X_i,
    Y_o(3 * BIT_WIDTH_OUT - 1 downto 2 * BIT_WIDTH_OUT)
    );

  convchan3 : entity ConvChannel3
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(3), Last_i, last_out(3), Ready_i, ready_out(3),
    X_i,
    Y_o(4 * BIT_WIDTH_OUT - 1 downto 3 * BIT_WIDTH_OUT)
    );

  convchan4 : entity ConvChannel4
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(4), Last_i, last_out(4), Ready_i, ready_out(4),
    X_i,
    Y_o(5 * BIT_WIDTH_OUT - 1 downto 4 * BIT_WIDTH_OUT)
    );

  convchan5 : entity ConvChannel5
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(5), Last_i, last_out(5), Ready_i, ready_out(5),
    X_i,
    Y_o(6 * BIT_WIDTH_OUT - 1 downto 5 * BIT_WIDTH_OUT)
    );

  convchan6 : entity ConvChannel6
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(6), Last_i, last_out(6), Ready_i, ready_out(6),
    X_i,
    Y_o(7 * BIT_WIDTH_OUT - 1 downto 6 * BIT_WIDTH_OUT)
    );

  convchan7 : entity ConvChannel7
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(7), Last_i, last_out(7), Ready_i, ready_out(7),
    X_i,
    Y_o(8 * BIT_WIDTH_OUT - 1 downto 7 * BIT_WIDTH_OUT)
    );

  convchan8 : entity ConvChannel8
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(8), Last_i, last_out(8), Ready_i, ready_out(8),
    X_i,
    Y_o(9 * BIT_WIDTH_OUT - 1 downto 8 * BIT_WIDTH_OUT)
    );

  convchan9 : entity ConvChannel9
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(9), Last_i, last_out(9), Ready_i, ready_out(9),
    X_i,
    Y_o(10 * BIT_WIDTH_OUT - 1 downto 9 * BIT_WIDTH_OUT)
    );

  convchan10 : entity ConvChannel10
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(10), Last_i, last_out(10), Ready_i, ready_out(10),
    X_i,
    Y_o(11 * BIT_WIDTH_OUT - 1 downto 10 * BIT_WIDTH_OUT)
    );

  convchan11 : entity ConvChannel11
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(11), Last_i, last_out(11), Ready_i, ready_out(11),
    X_i,
    Y_o(12 * BIT_WIDTH_OUT - 1 downto 11 * BIT_WIDTH_OUT)
    );

  convchan12 : entity ConvChannel12
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(12), Last_i, last_out(12), Ready_i, ready_out(12),
    X_i,
    Y_o(13 * BIT_WIDTH_OUT - 1 downto 12 * BIT_WIDTH_OUT)
    );

  convchan13 : entity ConvChannel13
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(13), Last_i, last_out(13), Ready_i, ready_out(13),
    X_i,
    Y_o(14 * BIT_WIDTH_OUT - 1 downto 13 * BIT_WIDTH_OUT)
    );

  convchan14 : entity ConvChannel14
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(14), Last_i, last_out(14), Ready_i, ready_out(14),
    X_i,
    Y_o(15 * BIT_WIDTH_OUT - 1 downto 14 * BIT_WIDTH_OUT)
    );

  convchan15 : entity ConvChannel15
    generic
    map(
    BIT_WIDTH_IN => BIT_WIDTH_IN,
    BIT_WIDTH_OUT => BIT_WIDTH_OUT)
    port
    map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(15), Last_i, last_out(15), Ready_i, ready_out(15),
    X_i,
    Y_o(16 * BIT_WIDTH_OUT - 1 downto 15 * BIT_WIDTH_OUT)
    );

end beh;