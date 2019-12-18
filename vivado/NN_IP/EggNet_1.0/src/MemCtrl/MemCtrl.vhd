library ieee;
use ieee.std_logic_1164.all;

entity MemCtrl is
    generic(
      BRAM_ADDR_WIDTH		        : integer := 10;
      BRAM_DATA_WIDTH		        : integer := 8;
      BRAM_ADDR_BLOCK_WIDTH     : integer := 784;
      
      AXI4_STRAM_INPUT          : boolean := false;
      
    );
    Port (
      -- Previous layer interface 
      S_layer_clk_i		    : in std_logic;
      S_layer_aresetn_i   : in std_logic;
      S_layer_tvalid_i	: in std_logic;
      S_layer_tdata_i   : in std_logic_vector(LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
      S_layer_tkeep_i   : in std_logic_vector((LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
      S_layer_tlast_i   : in std_logic;
      S_layer_tready_o  : out std_logic;
      
      -- Next layer interface 
      M_layer_clk_i		    : in std_logic;
      M_layer_aresetn_i   : in std_logic;
      M_layer_tvalid_o	: out std_logic;
      M_layer_tdata_o   : out std_logic_vector(LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
      M_layer_tkeep_o   : out std_logic_vector((LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
      M_layer_tlast_o   : out std_logic;
      M_layer_tready_i  : in std_logic;
      
      -- Status
      S_layer_invalid_block_o : out std_logic;
    

    );
end MemCtrl;

architecture Behavioral of MemCtrl is

component EggNet_v1_0_S00_AXIS is
	generic (
	C_S_AXIS_TDATA_WIDTH	: integer	:= 32
  BRAM_ADDR_WIDTH		        : integer := 10;
  BRAM_DATA_WIDTH		        : integer := 8;
  BRAM_ADDR_BLOCK_WIDTH     : integer := 784;  
	);
	port (
  BRAM_addr_o         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  BRAM_clk_o          : out std_logic;
  BRAM_dout_o         : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  BRAM_wea_o          : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
  Invalid_block_o     : out std_logic;
	S_AXIS_ACLK	: in std_logic;
	S_AXIS_ARESETN	: in std_logic;
	S_AXIS_TREADY	: out std_logic;
	S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	S_AXIS_TKEEP	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
	S_AXIS_TLAST	: in std_logic;
	S_AXIS_TVALID	: in std_logic
	);
end component EggNet_v1_0_S00_AXIS;

component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    rstb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rsta_busy : OUT STD_LOGIC;
    rstb_busy : OUT STD_LOGIC
  );
end component blk_mem_gen_0;

signal bram_clk  :std_logic;
signal bram_pa_addr :std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal bram_pa_data_wr :std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
signal bram_pa_wea  :std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
signal bram_pb_addr :std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal bram_pb_data_rd :std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
signal bram_pb_rst  :std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0); -- ACTIVE HIGH!



begin

AXI4_stream : if AXI4_STRAM_INPUT generate 
  -- Instantiation of Axi Bus Interface S00_AXIS if previous layer is input layer 
  EggNet_v1_0_S00_AXIS_inst : EggNet_v1_0_S00_AXIS
    generic map (
      BRAM_ADDR_WIDTH		    => BRAM_ADDR_WIDTH,		   
      BRAM_DATA_WIDTH		    => BRAM_DATA_WIDTH,		   
      BRAM_ADDR_BLOCK_WIDTH => BRAM_ADDR_BLOCK_WIDTH,
      C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
    )
    port map (
      -- BRAM Port A 
      BRAM_addr_o  => bram_pa_addr,
      BRAM_clk_o   => bram_clk,
      BRAM_dout_o  => bram_pa_data_wr,
      BRAM_wea_o   => bram_pa_wea, 
      -- Stauts
      Invalid_block_o => S_layer_invalid_block_o,
      -- AXI4 stream slave interface 
      S_AXIS_ACLK	=> s_layer_clk_i,
      S_AXIS_ARESETN	=> s_layer_aresetn_i,
      S_AXIS_TREADY	=> s_layer_tready_o,
      S_AXIS_TDATA	=> s_layer_tdata_i,
      S_AXIS_TKEEP	=> s_layer_tkeep_i,
      S_AXIS_TLAST	=> s_layer_tlast_i,
      S_AXIS_TVALID	=> s_layer_tvalid_i
    );
end generate;
  
Bram_inst : blk_mem_gen_0
port map (clka  => bram_clk,
          wea   => bram_pa_wea,
          addra => bram_pa_addr,
          dina  => bram_pa_data_wr,
          clkb  => bram_clk,
          rstb  => bram_pb_rst,
          addrb => bram_pb_addr,
          doutb => bram_pb_data_rd,
          rsta_busy => open,
          rstb_busy => open
);


    
end Behavioral;
