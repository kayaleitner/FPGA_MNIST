library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all;
use work.ConvChannel16;
use work.ConvChannel17;
use work.ConvChannel18;
use work.ConvChannel19;
use work.ConvChannel20;
use work.ConvChannel21;
use work.ConvChannel22;
use work.ConvChannel23;
use work.ConvChannel24;
use work.ConvChannel25;
use work.ConvChannel26;
use work.ConvChannel27;
use work.ConvChannel28;
use work.ConvChannel29;
use work.ConvChannel30;
use work.ConvChannel31;
use work.ConvChannel32;
use work.ConvChannel33;
use work.ConvChannel34;
use work.ConvChannel35;
use work.ConvChannel36;
use work.ConvChannel37;
use work.ConvChannel38;
use work.ConvChannel39;
use work.clogb2_Pkg.all;

entity Conv2D_1 is
	generic(
		BIT_WIDTH_IN : integer := 8;
		BIT_WIDTH_OUT : integer := 8;
		INPUT_CHANNELS : integer := 16;
		OUTPUT_CHANNELS : integer := 24
	);
	port(
		Clk_i : in std_logic;
		n_Res_i : in std_logic;
		Valid_i : in std_logic;
		Valid_o : out std_logic;
		Last_i : in std_logic;
		Last_o : out std_logic;
		Ready_i : in std_logic;
		Ready_o : out std_logic;
		X_i : in std_logic_vector(INPUT_CHANNELS*BIT_WIDTH_IN*KERNEL_SIZE - 1 downto 0);
		Y_o : out unsigned(OUTPUT_CHANNELS*BIT_WIDTH_OUT - 1 downto 0)
	);
end Conv2D_1;

architecture beh of Conv2D_1 is
   signal ready_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);
  signal valid_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);
  signal last_out :std_logic_vector(OUTPUT_CHANNELS-1 downto 0);
begin
  Ready_o <= ready_out(0);
  Valid_o <= valid_out(0);
  Last_o <= last_out(0);
  convchan0 : entity ConvChannel16 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(0), Last_i, last_out(0), Ready_i, ready_out(0),
    X_i,
    Y_o(1*BIT_WIDTH_OUT - 1 downto 0*BIT_WIDTH_OUT)
  ); 

  convchan1 : entity ConvChannel17 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(1), Last_i, last_out(1), Ready_i, ready_out(1),
    X_i,
    Y_o(2*BIT_WIDTH_OUT - 1 downto 1*BIT_WIDTH_OUT)
  ); 

  convchan2 : entity ConvChannel18 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(2), Last_i, last_out(2), Ready_i, ready_out(2),
    X_i,
    Y_o(3*BIT_WIDTH_OUT - 1 downto 2*BIT_WIDTH_OUT)
  ); 

  convchan3 : entity ConvChannel19 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(3), Last_i, last_out(3), Ready_i, ready_out(3),
    X_i,
    Y_o(4*BIT_WIDTH_OUT - 1 downto 3*BIT_WIDTH_OUT)
  ); 

  convchan4 : entity ConvChannel20 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(4), Last_i, last_out(4), Ready_i, ready_out(4),
    X_i,
    Y_o(5*BIT_WIDTH_OUT - 1 downto 4*BIT_WIDTH_OUT)
  ); 

  convchan5 : entity ConvChannel21 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(5), Last_i, last_out(5), Ready_i, ready_out(5),
    X_i,
    Y_o(6*BIT_WIDTH_OUT - 1 downto 5*BIT_WIDTH_OUT)
  ); 

  convchan6 : entity ConvChannel22 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(6), Last_i, last_out(6), Ready_i, ready_out(6),
    X_i,
    Y_o(7*BIT_WIDTH_OUT - 1 downto 6*BIT_WIDTH_OUT)
  ); 

  convchan7 : entity ConvChannel23 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(7), Last_i, last_out(7), Ready_i, ready_out(7),
    X_i,
    Y_o(8*BIT_WIDTH_OUT - 1 downto 7*BIT_WIDTH_OUT)
  ); 

  convchan8 : entity ConvChannel24 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(8), Last_i, last_out(8), Ready_i, ready_out(8),
    X_i,
    Y_o(9*BIT_WIDTH_OUT - 1 downto 8*BIT_WIDTH_OUT)
  ); 

  convchan9 : entity ConvChannel25 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(9), Last_i, last_out(9), Ready_i, ready_out(9),
    X_i,
    Y_o(10*BIT_WIDTH_OUT - 1 downto 9*BIT_WIDTH_OUT)
  ); 

  convchan10 : entity ConvChannel26 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(10), Last_i, last_out(10), Ready_i, ready_out(10),
    X_i,
    Y_o(11*BIT_WIDTH_OUT - 1 downto 10*BIT_WIDTH_OUT)
  ); 

  convchan11 : entity ConvChannel27 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(11), Last_i, last_out(11), Ready_i, ready_out(11),
    X_i,
    Y_o(12*BIT_WIDTH_OUT - 1 downto 11*BIT_WIDTH_OUT)
  ); 

  convchan12 : entity ConvChannel28 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(12), Last_i, last_out(12), Ready_i, ready_out(12),
    X_i,
    Y_o(13*BIT_WIDTH_OUT - 1 downto 12*BIT_WIDTH_OUT)
  ); 

  convchan13 : entity ConvChannel29 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(13), Last_i, last_out(13), Ready_i, ready_out(13),
    X_i,
    Y_o(14*BIT_WIDTH_OUT - 1 downto 13*BIT_WIDTH_OUT)
  ); 

  convchan14 : entity ConvChannel30 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(14), Last_i, last_out(14), Ready_i, ready_out(14),
    X_i,
    Y_o(15*BIT_WIDTH_OUT - 1 downto 14*BIT_WIDTH_OUT)
  ); 

  convchan15 : entity ConvChannel31 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(15), Last_i, last_out(15), Ready_i, ready_out(15),
    X_i,
    Y_o(16*BIT_WIDTH_OUT - 1 downto 15*BIT_WIDTH_OUT)
  ); 

  convchan16 : entity ConvChannel32 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(16), Last_i, last_out(16), Ready_i, ready_out(16),
    X_i,
    Y_o(17*BIT_WIDTH_OUT - 1 downto 16*BIT_WIDTH_OUT)
  ); 

  convchan17 : entity ConvChannel33 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(17), Last_i, last_out(17), Ready_i, ready_out(17),
    X_i,
    Y_o(18*BIT_WIDTH_OUT - 1 downto 17*BIT_WIDTH_OUT)
  ); 

  convchan18 : entity ConvChannel34 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(18), Last_i, last_out(18), Ready_i, ready_out(18),
    X_i,
    Y_o(19*BIT_WIDTH_OUT - 1 downto 18*BIT_WIDTH_OUT)
  ); 

  convchan19 : entity ConvChannel35 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(19), Last_i, last_out(19), Ready_i, ready_out(19),
    X_i,
    Y_o(20*BIT_WIDTH_OUT - 1 downto 19*BIT_WIDTH_OUT)
  ); 

  convchan20 : entity ConvChannel36 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(20), Last_i, last_out(20), Ready_i, ready_out(20),
    X_i,
    Y_o(21*BIT_WIDTH_OUT - 1 downto 20*BIT_WIDTH_OUT)
  ); 

  convchan21 : entity ConvChannel37 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(21), Last_i, last_out(21), Ready_i, ready_out(21),
    X_i,
    Y_o(22*BIT_WIDTH_OUT - 1 downto 21*BIT_WIDTH_OUT)
  ); 

  convchan22 : entity ConvChannel38 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(22), Last_i, last_out(22), Ready_i, ready_out(22),
    X_i,
    Y_o(23*BIT_WIDTH_OUT - 1 downto 22*BIT_WIDTH_OUT)
  ); 

  convchan23 : entity ConvChannel39 
  generic map( 
    BIT_WIDTH_IN => BIT_WIDTH_IN, 
    BIT_WIDTH_OUT => BIT_WIDTH_OUT) 
  port map(
    Clk_i, n_Res_i,
    Valid_i, valid_out(23), Last_i, last_out(23), Ready_i, ready_out(23),
    X_i,
    Y_o(24*BIT_WIDTH_OUT - 1 downto 23*BIT_WIDTH_OUT)
  ); 

end beh;