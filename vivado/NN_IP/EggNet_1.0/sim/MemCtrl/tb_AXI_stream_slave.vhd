library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

entity tb_EggNet_v1_0_S00_AXIS is
end tb_EggNet_v1_0_S00_AXIS;

architecture tb of tb_EggNet_v1_0_S00_AXIS is

  constant BRAM_ADDR_WIDTH : integer := 11;
  constant BRAM_DATA_WIDTH : integer := 8;
  constant c_s_axis_tdata_width : integer := 32;

    component EggNet_v1_0_S00_AXIS
        port (BRAM_PA_addr_o  : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
              BRAM_PA_clk_o   : out std_logic;
              BRAM_PA_dout_o  : out std_logic_vector (BRAM_DATA_WIDTH-1 downto 0);
              BRAM_PA_wea_o   : out std_logic_vector ((BRAM_DATA_WIDTH/8)-1  downto 0);
              Invalid_block_o : out std_logic;
              Block_done_o    : out std_logic; 
              S_AXIS_ACLK     : in std_logic;
              S_AXIS_ARESETN  : in std_logic;
              S_AXIS_TREADY   : out std_logic;
              S_AXIS_TDATA    : in std_logic_vector (c_s_axis_tdata_width-1 downto 0);
              S_AXIS_TKEEP    : in std_logic_vector ((c_s_axis_tdata_width/8)-1 downto 0);
              S_AXIS_TLAST    : in std_logic;
              S_AXIS_TVALID   : in std_logic);
    end component;

    signal bram_addr  : std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
    signal bram_clk   : std_logic;
    signal bram_dout  : std_logic_vector (BRAM_DATA_WIDTH-1 downto 0);
    signal bram_wea   : std_logic_vector ((BRAM_DATA_WIDTH/8)-1  downto 0);
    signal bram_block_error : std_logic
    signal block_done     : std_logic;
    signal s_axis_clk     : std_logic;
    signal nRst  : std_logic;
    signal s_axis_tready   : std_logic;
    signal s_axis_tdata    : std_logic_vector (c_s_axis_tdata_width-1 downto 0);
    signal s_axis_tkeep    : std_logic_vector ((c_s_axis_tdata_width/8)-1 downto 0);
    signal s_axis_tlast    : std_logic;
    signal s_axis_tvalid   : std_logic;

    constant TbPeriod : time := 10 ns;
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';
    
    type   RAM_TYPE IS ARRAY(255 downto 0) OF std_logic_vector(7 downto 0); 
    signal data_buffer      : RAM_TYPE := (others => X"00");

begin

    dut : EggNet_v1_0_S00_AXIS
    port map (BRAM_PA_addr_o  => bram_addr,
              BRAM_PA_clk_o   => bram_clk,
              BRAM_PA_dout_o  => bram_dout,
              BRAM_PA_wea_o   => bram_wea,
              Invalid_block_o => bram_block_error,
              Block_done_o    => block_done,
              S_AXIS_ACLK     => s_axis_clk,
              S_AXIS_ARESETN  => nRst,
              S_AXIS_TREADY   => s_axis_tready,
              S_AXIS_TDATA    => s_axis_tdata,
              S_AXIS_TKEEP    => s_axis_tkeep,
              S_AXIS_TLAST    => s_axis_tlast,
              S_AXIS_TVALID   => s_axis_tvalid);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that s_axis_clk is really your main clock signal
    s_axis_clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        s_axis_tdata <= (others => '0');
        s_axis_tkeep <= (others => '0');
        s_axis_tlast <= '0';
        s_axis_tvalid <= '0';

        -- Reset generation
        nRst <= '0';
        wait for 25 ns;
        nRst <= '1';
        wait for 15 ns;
        

        -- EDIT Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_EggNet_v1_0_S00_AXIS of tb_EggNet_v1_0_S00_AXIS is
    for tb
    end for;
end cfg_tb_EggNet_v1_0_S00_AXIS;