library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use STD.textio.all;
library UNISIM;  
use UNISIM.Vcomponents.all;


entity tb_memctrl is
end tb_memctrl;

architecture tb of tb_memctrl is
  
  constant BLOCK_LENGTH_L1 : integer := 784;
  constant BLOCK_LENGTH_L2 : integer := 784;
  constant BLOCKS_TO_TEST : integer := 3;
  
  constant L1_BRAM_ADDR_WIDTH		    : integer := 11; -- maximum = 24 
  constant L1_DATA_WIDTH		        : integer := 8; -- bit depth of one channel  
  constant L1_IN_CHANNEL_NUMBER		  : integer := 1; -- number of input channels
  constant L2_BRAM_ADDR_WIDTH		    : integer := 11; -- maximum = 24 
  constant L2_DATA_WIDTH		        : integer := 8; -- bit depth of one channel  
  constant L2_IN_CHANNEL_NUMBER		  : integer := 16; -- number of input channels 
  constant LAYER_HIGHT            : integer := 28;
  constant LAYER_WIDTH            : integer := 28;  
  constant AXI4_STREAM_INPUT        : integer := 1;  
  constant C_S_AXIS_TDATA_WIDTH	    : integer	:= 32;  
  constant C_S00_AXI_DATA_WIDTH	    : integer	:= 32;  
  constant C_S00_AXI_ADDR_WIDTH	    : integer	:= 4;  
  constant MEM_CTRL_ADDR            : integer range 1 to 15 := 1; -- limited range because of limited address width in AXI_lite_reg_addr  
  constant KERNEL_SIZE                : integer := 3;

  constant DBG_MEM_CTRL_ADDR_WIDTH    : integer := 4;
  constant DBG_REA_32BIT_WIDTH        : integer := 4;
  constant DBG_BRAM_ADDRESS_WIDTH     : integer := 24;

  component blk_mem_gen_0 IS
    PORT (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      clkb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
  end component blk_mem_gen_0;  
  
  component blk_mem_layer_2 IS
    PORT (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      clkb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
  end component blk_mem_layer_2;
  
  component fifo_generator_0 IS
    PORT (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
    );
  END component fifo_generator_0;  

  component fifo_linebuffer_layer_2 IS
    PORT (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
    );
  END component fifo_linebuffer_layer_2; 

  component MemCtrl_3x3 is
    Generic(
      BRAM_ADDR_WIDTH		        : integer range 1 to 24   := 10; -- maximum = 24 
      DATA_WIDTH		            : integer := 8; -- channel number * bit depth maximum = 512    
      IN_CHANNEL_NUMBER		      : integer := 1; 
      LAYER_HIGHT               : integer := 28; -- Layer hight of next layer 
      LAYER_WIDTH               : integer := 28; -- Layer width of next layer 
      
      AXI4_STREAM_INPUT         : integer range 0 to 1 := 0; -- integer to calculate S_LAYER_DATA_WIDTH 
      C_S_AXIS_TDATA_WIDTH	    : integer	:= 32;
      C_S00_AXI_DATA_WIDTH	    : integer	:= 32;
      C_S00_AXI_ADDR_WIDTH	    : integer	:= 4;
      MEM_CTRL_ADDR             : integer range 1 to 15 := 1  -- limited range because of limited address width in AXI_lite_reg_addr
                                                              -- if more than 15 memory controller required change debugging using AXI lite
    );
    Port (
      -- Clk and reset
      Layer_clk_i		    : in std_logic;
      Layer_aresetn_i   : in std_logic;
      
      -- Previous layer interface 
      S_layer_tvalid_i	: in std_logic;
      S_layer_tdata_i   : in std_logic_vector;
      S_layer_tkeep_i   : in std_logic_vector;
      S_layer_tlast_i   : in std_logic;
      S_layer_tready_o  : out std_logic;   
      
      -- Next layer interface 
      M_layer_tvalid_o	: out std_logic;
      M_layer_tdata_1_o : out std_logic_vector;
      M_layer_tdata_2_o : out std_logic_vector;
      M_layer_tdata_3_o : out std_logic_vector;
      M_layer_tkeep_o   : out std_logic_vector;
      M_layer_tnewrow_o : out std_logic;
      M_layer_tlast_o   : out std_logic;
      M_layer_tready_i  : in std_logic;

      -- M_layer FIFO
      M_layer_fifo_srst : out std_logic;
      M_layer_fifo_in   : out std_logic_vector;
      M_layer_fifo_wr   : out std_logic;
      M_layer_fifo_rd   : out std_logic;
      M_layer_fifo_out  : in std_logic_vector;
      
      -- BRAM interface
      Bram_clk_o        : out std_logic;
      Bram_pa_addr_o    : out std_logic_vector;
      Bram_pa_data_wr_o : out std_logic_vector;
      Bram_pa_wea_o     : out std_logic_vector;
      Bram_pb_addr_o    : out std_logic_vector;
      Bram_pb_data_rd_i : in std_logic_vector;
      Bram_pb_rst_o     : out std_logic; -- ACTIVE HIGH!
      
      -- AXI Lite dbg interface 
      AXI_lite_reg_addr_i  : in std_logic_vector;
      AXI_lite_reg_data_o  : out std_logic_vector; 
      
      -- Status
      S_layer_invalid_block_o : out std_logic

    );
  end component MemCtrl_3x3;

  component ShiftRegister_3x3 is
    generic(
        DATA_WIDTH: integer := 8
    );
    Port (
      -- Clk and reset
      Clk_i           : in  STD_LOGIC; -- clock
      nRst_i          : in  STD_LOGIC; -- active low reset 
      
      -- Slave interface to previous memory controller  
      S_data_1_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 1 |Vector: trans(1,2,3)
      S_data_2_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 2 |Vector: trans(1,2,3)
      S_data_3_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 3 |Vector: trans(1,2,3)
      S_tvalid_i	    : in  STD_LOGIC; -- indicates if input data is valid 
      S_tnewrow_i     : in  STD_LOGIC; -- indicates that a new row starts 
      S_tlast_i       : in  STD_LOGIC; -- indicates end of block 
      S_tready_o      : out STD_LOGIC; -- indicates if shiftregister is ready to for new data 

      -- Master interface to next 3x3 kernel matrix multiplier 
      M_data_1_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 11  Matrix  : |11 , 12, 13|
      M_data_2_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 21          : |21 , 22, 23|
      M_data_3_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 31          : |31 , 32, 33|
      M_data_4_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 12
      M_data_5_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 22
      M_data_6_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 32
      M_data_7_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 13
      M_data_8_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 23
      M_data_9_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 33
      M_tvalid_o	    : out STD_LOGIC; -- indicates if output data is valid 
      M_tlast_o       : out STD_LOGIC; -- indicates end of block 
      M_tready_i      : in  STD_LOGIC  -- indicates if next slave is ready to for new data   
    );
  end component ShiftRegister_3x3;

  constant TbPeriod : time := 10 ns;
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

  signal layer_clk	            : std_logic;
  signal layer_aresetn          : std_logic;      
  signal s_l1_tvalid         : std_logic;
  signal s_l1_tdata          : std_logic_vector((C_S_AXIS_TDATA_WIDTH)-1 downto 0);
  signal s_l1_tkeep          : std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
  signal s_l1_tlast          : std_logic;
  signal s_l1_tready         : std_logic;     
  signal m_l1_tvalid         : std_logic;
  signal m_l1_tdata_1        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l1_tdata_2        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l1_tdata_3        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l1_tkeep          : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0);
  signal m_l1_tlast          : std_logic;
  signal m_l1_tnewrow        : std_logic;   
  signal m_l1_tready         : std_logic;   
  signal m_l1_fifo_srst      : std_logic;
  signal m_l1_fifo_in        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);
  signal m_l1_fifo_wr        : std_logic;
  signal m_l1_fifo_rd        : std_logic;
  signal m_l1_fifo_out       : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);  
  signal l1_bram_clk               : std_logic;
  signal l1_bram_pa_addr           : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal l1_bram_pa_data_wr        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_bram_pa_wea            : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1  downto 0);
  signal l1_bram_pb_addr           : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal l1_bram_pb_data_rd        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_bram_pb_rst            : std_logic; -- ACTIVE HIGH!            
  signal axi_lite_reg_addr      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal axi_lite_reg_data      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal s_l1_invalid_block  : std_logic;
  signal l1_bram_block_done     : std_logic;

  signal l1_shreg_data_1        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_2        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_3        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_4        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_5        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_6        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_7        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_8        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_data_9        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_shreg_tvalid        : std_logic;
  signal l1_shreg_tlast         : std_logic;
  signal l1_shreg_tready        : std_logic;

  type   RAM_TYPE_L1 IS ARRAY(BLOCK_LENGTH_L1*BLOCKS_TO_TEST-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); 
  signal AXI_data_buffer_l1      : RAM_TYPE_L1 := (others => X"00");
  type   BRAM_L1_TYPE IS ARRAY(BLOCK_LENGTH_L1*2-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); 
  signal l1_bram_data_buffer      : BRAM_L1_TYPE := (others => X"00"); 
  signal dbg_l1_bram_data_buffer      : BRAM_L1_TYPE := (others => X"00"); 
  type   M_l1_TYPE IS ARRAY(BLOCK_LENGTH_L1*3-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal M_l1_buffer_1      : M_l1_TYPE := (others => X"00");
  signal M_l1_buffer_2      : M_l1_TYPE := (others => X"00");
  signal M_l1_buffer_3      : M_l1_TYPE := (others => X"00");
  
  signal l1_shreg_buffer_1      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_2      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_3      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_4      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_5      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_6      : M_l1_TYPE := (others => X"00");  
  signal l1_shreg_buffer_7      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_8      : M_l1_TYPE := (others => X"00");
  signal l1_shreg_buffer_9      : M_l1_TYPE := (others => X"00");

  signal start_package_l1    : std_logic;
  signal block_done_vec_l1       : std_logic;
  signal img_length_l1       : integer;  
  signal block_done_sh_l1    : std_logic;
  signal img_length_sh_l1    : integer;
  
  
  signal s_l2_tvalid         : std_logic;
  signal s_l2_tdata          : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal s_l2_tkeep          : std_logic_vector(((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)/8)-1 downto 0);
  signal s_l2_tlast          : std_logic;
  signal s_l2_tready         : std_logic;     
  signal m_l2_tvalid         : std_logic;
  signal m_l2_tdata_1        : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l2_tdata_2        : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l2_tdata_3        : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_l2_tkeep          : std_logic_vector(((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0);
  signal m_l2_tlast          : std_logic;
  signal m_l2_tnewrow        : std_logic;   
  signal m_l2_tready         : std_logic;   
  signal m_l2_fifo_srst      : std_logic;
  signal m_l2_fifo_in        : std_logic_vector(((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)*2)-1 downto 0);
  signal m_l2_fifo_wr        : std_logic;
  signal m_l2_fifo_rd        : std_logic;
  signal m_l2_fifo_out       : std_logic_vector(((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)*2)-1 downto 0);  
  signal l2_bram_clk               : std_logic;
  signal l2_bram_pa_addr           : std_logic_vector(L2_BRAM_ADDR_WIDTH-1 downto 0);
  signal l2_bram_pa_data_wr        : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_bram_pa_wea            : std_logic_vector(((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)/8)-1  downto 0);
  signal l2_bram_pb_addr           : std_logic_vector(L2_BRAM_ADDR_WIDTH-1 downto 0);
  signal l2_bram_pb_data_rd        : std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_bram_pb_rst            : std_logic; -- ACTIVE HIGH!            
  signal s_l2_invalid_block  : std_logic;
  signal l2_bram_block_done     : std_logic;

  type   SHREG_TYPE_L2 IS ARRAY(L2_IN_CHANNEL_NUMBER-1 downto 0) OF std_logic_vector(L2_DATA_WIDTH-1 downto 0);
  signal l2_shreg_data_1        : SHREG_TYPE_L2;
  signal l2_shreg_data_2        : SHREG_TYPE_L2;
  signal l2_shreg_data_3        : SHREG_TYPE_L2;
  signal l2_shreg_data_4        : SHREG_TYPE_L2;
  signal l2_shreg_data_5        : SHREG_TYPE_L2;
  signal l2_shreg_data_6        : SHREG_TYPE_L2;
  signal l2_shreg_data_7        : SHREG_TYPE_L2;
  signal l2_shreg_data_8        : SHREG_TYPE_L2;
  signal l2_shreg_data_9        : SHREG_TYPE_L2;
  signal l2_shreg_tvalid        : std_logic;
  signal l2_shreg_tlast         : std_logic;
  signal l2_shreg_tready        : std_logic;

  type   RAM_TYPE_L2 IS ARRAY(BLOCK_LENGTH_L2*BLOCKS_TO_TEST-1 downto 0) OF std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);  
  signal s_data_buffer_l2      : RAM_TYPE_L2;
  type   BRAM_L2_TYPE IS ARRAY(BLOCK_LENGTH_L2*2-1 downto 0) OF std_logic_vector((L2_DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0); 
  signal l2_bram_data_buffer      : BRAM_L2_TYPE; 
  signal dbg_l2_bram_data_buffer      : BRAM_L2_TYPE; 
  
  type   M_l2_TYPE IS ARRAY(BLOCK_LENGTH_L2 downto 0) OF SHREG_TYPE_L2;
  signal M_l2_buffer_1      : M_L2_TYPE;
  signal M_l2_buffer_2      : M_L2_TYPE;
  signal M_l2_buffer_3      : M_L2_TYPE;
  
  signal l2_shreg_buffer_1      : M_L2_TYPE;
  signal l2_shreg_buffer_2      : M_L2_TYPE;
  signal l2_shreg_buffer_3      : M_L2_TYPE;
  signal l2_shreg_buffer_4      : M_L2_TYPE;
  signal l2_shreg_buffer_5      : M_L2_TYPE;
  signal l2_shreg_buffer_6      : M_L2_TYPE;  
  signal l2_shreg_buffer_7      : M_L2_TYPE;
  signal l2_shreg_buffer_8      : M_L2_TYPE;
  signal l2_shreg_buffer_9      : M_L2_TYPE;

  signal start_package_l2    : std_logic;
  signal block_done_vec_l2       : std_logic;
  signal img_length_l2       : integer;  
  signal block_done_sh_l2    : std_logic;
  signal img_length_sh_l2    : integer; 
  
  
  
  signal debug            : std_logic; 
  signal debug_done       : std_logic; 
  signal debug_mem_ctrl   : std_logic_vector(DBG_MEM_CTRL_ADDR_WIDTH-1 downto 0);
  signal debug_rea_32bit  : std_logic_vector(DBG_REA_32BIT_WIDTH-1 downto 0);
  signal debug_bram_addr  : std_logic_vector(DBG_BRAM_ADDRESS_WIDTH-1 downto 0);
  
  file file_TEST_DATA : text;
  file file_RESULTS : text;
  
  signal test_datacounter : integer; 
  signal test_blockcounter: integer; 
 
begin

  MemCtrl_L1: MemCtrl_3x3
  generic map(                                   
    BRAM_ADDR_WIDTH		      => L1_BRAM_ADDR_WIDTH		 ,
    DATA_WIDTH		          => L1_DATA_WIDTH		    ,
    IN_CHANNEL_NUMBER       => L1_IN_CHANNEL_NUMBER,
    LAYER_HIGHT             => LAYER_HIGHT       ,
    LAYER_WIDTH             => LAYER_WIDTH       ,
    AXI4_STREAM_INPUT       => AXI4_STREAM_INPUT   ,
    C_S_AXIS_TDATA_WIDTH    => C_S_AXIS_TDATA_WIDTH,
    C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH,
    C_S00_AXI_ADDR_WIDTH    => C_S00_AXI_ADDR_WIDTH,
    MEM_CTRL_ADDR           => MEM_CTRL_ADDR)       
  port map(
    Layer_clk_i		          => layer_clk		        ,
    Layer_aresetn_i         => layer_aresetn        ,
    S_layer_tvalid_i	      => s_l1_tvalid       ,
    S_layer_tdata_i         => s_l1_tdata        ,
    S_layer_tkeep_i         => s_l1_tkeep        ,
    S_layer_tlast_i         => s_l1_tlast        ,
    S_layer_tready_o        => s_l1_tready       ,
    M_layer_tvalid_o	      => m_l1_tvalid       ,
    M_layer_tdata_1_o       => m_l1_tdata_1      ,
    M_layer_tdata_2_o       => m_l1_tdata_2      ,
    M_layer_tdata_3_o       => m_l1_tdata_3      ,
    M_layer_tkeep_o         => m_l1_tkeep        ,
    M_layer_tnewrow_o       => m_l1_tnewrow      ,
    M_layer_tlast_o         => m_l1_tlast        ,
    M_layer_tready_i        => m_l1_tready       ,
    M_layer_fifo_srst       => m_l1_fifo_srst    ,
    M_layer_fifo_in         => m_l1_fifo_in      ,
    M_layer_fifo_wr         => m_l1_fifo_wr      ,
    M_layer_fifo_rd         => m_l1_fifo_rd      ,
    M_layer_fifo_out        => m_l1_fifo_out     ,
    Bram_clk_o              => l1_bram_clk             ,
    Bram_pa_addr_o          => l1_bram_pa_addr         ,
    Bram_pa_data_wr_o       => l1_bram_pa_data_wr      ,
    Bram_pa_wea_o           => l1_bram_pa_wea          ,
    Bram_pb_addr_o          => l1_bram_pb_addr         ,
    Bram_pb_data_rd_i       => l1_bram_pb_data_rd      ,
    Bram_pb_rst_o           => l1_bram_pb_rst          ,
    AXI_lite_reg_addr_i     => axi_lite_reg_addr    ,
    AXI_lite_reg_data_o     => axi_lite_reg_data    ,
    S_layer_invalid_block_o => s_l1_invalid_block);

  -- ********************* Instantiation of Block RAM ************************************************  
  Bram_layer1 : blk_mem_gen_0
  port map (clka  => l1_bram_clk,
            wea   => l1_bram_pa_wea,
            addra => l1_bram_pa_addr,
            dina  => l1_bram_pa_data_wr,
            clkb  => l1_bram_clk,
            addrb => l1_bram_pb_addr,
            doutb => l1_bram_pb_data_rd
  );


  -- ********************* FIFO to buffer 2 lines (3x3 Kernel)   *************************************
  -- Required in order to provide a new Data vector at each clock cycle 
  -- This method triples the performance because only one clock cycle is required to fetch a data vector

  linebuffer_layer1: fifo_generator_0 
    port map (
      clk   => layer_clk,
      srst  => m_l1_fifo_srst,
      din   => m_l1_fifo_in,
      wr_en => m_l1_fifo_wr,
      rd_en => m_l1_fifo_rd,
      dout  => m_l1_fifo_out,
      full  => open,
      empty => open 
    );    

  shiftregister_layer1: ShiftRegister_3x3
    generic map(
        DATA_WIDTH => (L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)
    )
    port map(
      Clk_i       => layer_clk,		 
      nRst_i      => layer_aresetn, 
      S_data_1_i  => m_l1_tdata_1, 
      S_data_2_i  => m_l1_tdata_2, 
      S_data_3_i  => m_l1_tdata_3, 
      S_tvalid_i  => m_l1_tvalid,
      S_tnewrow_i => m_l1_tnewrow,
      S_tlast_i   => m_l1_tlast, 
      S_tready_o  => m_l1_tready, 
      M_data_1_o  => l1_shreg_data_1, 
      M_data_2_o  => l1_shreg_data_2, 
      M_data_3_o  => l1_shreg_data_3, 
      M_data_4_o  => l1_shreg_data_4, 
      M_data_5_o  => l1_shreg_data_5, 
      M_data_6_o  => l1_shreg_data_6, 
      M_data_7_o  => l1_shreg_data_7, 
      M_data_8_o  => l1_shreg_data_8, 
      M_data_9_o  => l1_shreg_data_9, 
      M_tvalid_o  => l1_shreg_tvalid,
      M_tlast_o   => l1_shreg_tlast , 
      M_tready_i  => l1_shreg_tready 
    );


  MemCtrl_L2: MemCtrl_3x3
  generic map(                                   
    BRAM_ADDR_WIDTH		      => L2_BRAM_ADDR_WIDTH		 ,
    DATA_WIDTH		          => L2_DATA_WIDTH		    ,
    IN_CHANNEL_NUMBER       => L2_IN_CHANNEL_NUMBER,
    LAYER_HIGHT             => LAYER_HIGHT       ,
    LAYER_WIDTH             => LAYER_WIDTH       ,
    AXI4_STREAM_INPUT       => 0   ,
    C_S_AXIS_TDATA_WIDTH    => C_S_AXIS_TDATA_WIDTH,
    C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH,
    C_S00_AXI_ADDR_WIDTH    => C_S00_AXI_ADDR_WIDTH,
    MEM_CTRL_ADDR           => 2)       
  port map(
    Layer_clk_i		          => layer_clk		        ,
    Layer_aresetn_i         => layer_aresetn        ,
    S_layer_tvalid_i	      => s_l2_tvalid       ,
    S_layer_tdata_i         => s_l2_tdata        ,
    S_layer_tkeep_i         => s_l2_tkeep        ,
    S_layer_tlast_i         => s_l2_tlast        ,
    S_layer_tready_o        => s_l2_tready       ,
    M_layer_tvalid_o	      => m_l2_tvalid       ,
    M_layer_tdata_1_o       => m_l2_tdata_1      ,
    M_layer_tdata_2_o       => m_l2_tdata_2      ,
    M_layer_tdata_3_o       => m_l2_tdata_3      ,
    M_layer_tkeep_o         => m_l2_tkeep        ,
    M_layer_tnewrow_o       => m_l2_tnewrow      ,
    M_layer_tlast_o         => m_l2_tlast        ,
    M_layer_tready_i        => m_l2_tready       ,
    M_layer_fifo_srst       => m_l2_fifo_srst    ,
    M_layer_fifo_in         => m_l2_fifo_in      ,
    M_layer_fifo_wr         => m_l2_fifo_wr      ,
    M_layer_fifo_rd         => m_l2_fifo_rd      ,
    M_layer_fifo_out        => m_l2_fifo_out     ,
    Bram_clk_o              => l2_bram_clk             ,
    Bram_pa_addr_o          => l2_bram_pa_addr         ,
    Bram_pa_data_wr_o       => l2_bram_pa_data_wr      ,
    Bram_pa_wea_o           => l2_bram_pa_wea          ,
    Bram_pb_addr_o          => l2_bram_pb_addr         ,
    Bram_pb_data_rd_i       => l2_bram_pb_data_rd      ,
    Bram_pb_rst_o           => l2_bram_pb_rst          ,
    AXI_lite_reg_addr_i     => axi_lite_reg_addr    ,
    AXI_lite_reg_data_o     => axi_lite_reg_data    ,
    S_layer_invalid_block_o => s_l2_invalid_block);

  -- ********************* Instantiation of Block RAM ************************************************  
  Bram_layer2 : blk_mem_layer_2
  port map (clka  => l2_bram_clk,
            wea   => l2_bram_pa_wea,
            addra => l2_bram_pa_addr,
            dina  => l2_bram_pa_data_wr,
            clkb  => l2_bram_clk,
            addrb => l2_bram_pb_addr,
            doutb => l2_bram_pb_data_rd
  );


  -- ********************* FIFO to buffer 2 lines (3x3 Kernel)   *************************************
  -- Required in order to provide a new Data vector at each clock cycle 
  -- This method triples the performance because only one clock cycle is required to fetch a data vector

  linebuffer_layer2: fifo_linebuffer_layer_2 
    port map (
      clk   => layer_clk,
      srst  => m_l2_fifo_srst,
      din   => m_l2_fifo_in,
      wr_en => m_l2_fifo_wr,
      rd_en => m_l2_fifo_rd,
      dout  => m_l2_fifo_out,
      full  => open,
      empty => open 
    );    
  L2_Shiftregs: for i in 0 to L2_IN_CHANNEL_NUMBER-1 generate -- use separated shiftregister in order to enable placer to place the shift register for each channel in a different FPGA region 
    shiftregister_layer2: ShiftRegister_3x3
      generic map(
          DATA_WIDTH => (L2_DATA_WIDTH)
      )
      port map(
        Clk_i       => layer_clk,		 
        nRst_i      => layer_aresetn, 
        S_data_1_i  => m_l2_tdata_1((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i), 
        S_data_2_i  => m_l2_tdata_2((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i), 
        S_data_3_i  => m_l2_tdata_3((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i), 
        S_tvalid_i  => m_l2_tvalid,
        S_tnewrow_i => m_l2_tnewrow,
        S_tlast_i   => m_l2_tlast, 
        S_tready_o  => m_l2_tready, 
        M_data_1_o  => l2_shreg_data_1(i), 
        M_data_2_o  => l2_shreg_data_2(i), 
        M_data_3_o  => l2_shreg_data_3(i), 
        M_data_4_o  => l2_shreg_data_4(i), 
        M_data_5_o  => l2_shreg_data_5(i), 
        M_data_6_o  => l2_shreg_data_6(i), 
        M_data_7_o  => l2_shreg_data_7(i), 
        M_data_8_o  => l2_shreg_data_8(i), 
        M_data_9_o  => l2_shreg_data_9(i), 
        M_tvalid_o  => l2_shreg_tvalid,
        M_tlast_o   => l2_shreg_tlast , 
        M_tready_i  => l2_shreg_tready 
      );
  end generate; 

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that layer_clk is really your main clock signal
  layer_clk <= TbClock;

  stimuli : process
  begin
      -- EDIT Adapt initialization as needed
      start_package_l1 <= '0';
      start_package_l2 <= '0';
      debug <= '0';
      -- Reset generation
      layer_aresetn <= '0';
      wait for 25 ns;
      layer_aresetn <= '1';
      wait for 15 ns;
      start_package_l1 <= '1';
      start_package_l2 <= '1';
      report "send package 1"; 
      wait for 10 ns;
      start_package_l1 <= '0';
      start_package_l2 <= '0';
      wait for 40 us;
      report "send package 2"; 
      start_package_l1 <= '1';
      start_package_l2 <= '1';
      wait for 10 ns;
      start_package_l1 <= '0';
      start_package_l2 <= '0';
      wait for 40 us;
      report "send package 3"; 
      start_package_l1 <= '1';
      start_package_l2 <= '1';
      wait for 10 ns;
      start_package_l1 <= '0';
      start_package_l2 <= '0';
      wait for 100 us;
      -- EDIT Add stimuli here
      wait for 200 * TbPeriod;
      report "End simulation"; 
      -- Stop the clock and hence terminate the simulation
      TbSimEnded <= '1';
      wait;
  end process;

-- ****************** LAYER 1 **********************************************************************
  AXI_master: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
    variable block_counter : integer;
    variable package_active : std_logic;
  begin
    if layer_aresetn = '0' then 
      s_l1_tdata <= (others => '0');
      s_l1_tkeep <= (others => '0');
      s_l1_tvalid <= '0';
      s_l1_tlast <= '0';
      
      package_active := '0';
      data_counter := 0;
      block_counter := 0;
    elsif rising_edge(layer_clk) then 
      if package_active = '1' then 
        s_l1_tvalid <= '1';
        s_l1_tkeep <= (others => '1');
        if s_l1_tready = '1'  and s_l1_tvalid = '1' then 
          data_counter := data_counter + 4;
        end if; 
        s_l1_tdata <= (AXI_data_buffer_l1(data_counter) & AXI_data_buffer_l1(data_counter+1)  
                        & AXI_data_buffer_l1(data_counter+2) & AXI_data_buffer_l1(data_counter+3));                   
  
      else 
        if s_l1_tready = '1' then 
          s_l1_tvalid <= '0';
          s_l1_tkeep <= (others => '0');
        end if;  
      end if; 
      if start_package_l1 = '1' then 
        package_active := '1';
        data_counter := BLOCK_LENGTH_L1*block_counter;
        block_counter := block_counter +1;
        s_l1_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH_L1*block_counter-4 then 
        package_active := '0';
        data_counter := 0;
        s_l1_tlast <= '1';
      else 
        s_l1_tlast <= '0';
      end if; 
    end if;
  end process;
  
  BRAM_Rec_L1: process(layer_clk,layer_aresetn) 
  begin
    if layer_aresetn = '0' then 
      l1_bram_block_done <= '0';
    elsif rising_edge(layer_clk) then 
      if l1_bram_pa_wea = "1" then 
        l1_bram_data_buffer(to_integer(unsigned(l1_bram_pa_addr))) <= l1_bram_pa_data_wr;
      end if;  
      if to_integer(unsigned(l1_bram_pa_addr)) = 784 or to_integer(unsigned(l1_bram_pa_addr)) = (BLOCK_LENGTH_L1*2) then 
        l1_bram_block_done <= '1'; 
      else 
        l1_bram_block_done <= '0';
      end if;      
    end if;
  end process;

  axi_lite_reg_addr <= (debug_mem_ctrl & debug_rea_32bit & debug_bram_addr);

  DEBUG_CONTR: process(layer_clk,layer_aresetn) 
    variable data_counter : unsigned(DBG_BRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
  begin
    if layer_aresetn = '0' then 
      debug_mem_ctrl  <= (others => '0');
      debug_rea_32bit <= (others => '0');
      debug_bram_addr <= (others => '0');       
      debug_done <= '0'; 
    elsif rising_edge(layer_clk) then 
      if debug = '1' then 
        debug_mem_ctrl <= std_logic_vector(to_unsigned(1,debug_mem_ctrl'length));
        debug_bram_addr <= std_logic_vector(data_counter);
        if data_counter > 0 then 
          dbg_l1_bram_data_buffer(to_integer(data_counter)-1) <= axi_lite_reg_data((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
        end if;        
        if data_counter > (BLOCK_LENGTH_L1*2) then 
          data_counter := (others => '0');
          debug_done <= '1';
        else 
          debug_done <= '0';
          data_counter := data_counter +1;
        end if;                
      else 
        data_counter := (others => '0');
        debug_done <= '0';
        debug_mem_ctrl  <= (others => '0');
        debug_rea_32bit <= (others => '0');
        debug_bram_addr <= (others => '0');          
      end if;  
    end if;
  end process;   
  axi_lite_reg_addr <= (debug_mem_ctrl & debug_rea_32bit & debug_bram_addr);

  M_LAYER_1_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      block_done_vec_l1 <= '0';
    elsif rising_edge(layer_clk) then 
      if m_l1_tvalid = '1' and m_l1_tready = '1' then  
        M_l1_buffer_1(data_counter) <= m_l1_tdata_1;
        M_l1_buffer_2(data_counter) <= m_l1_tdata_2;
        M_l1_buffer_3(data_counter) <= m_l1_tdata_3;
        data_counter := data_counter +1;
      end if;  
      if m_l1_tlast = '1' then 
        block_done_vec_l1 <= '1'; 
        img_length_l1 <= data_counter;
        data_counter := 0;
      else 
        block_done_vec_l1 <= '0';
      end if;
    end if;
  end process;  

  Shiftreg_L1_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      l1_shreg_tready <= '0';
      block_done_sh_l1 <= '0';
    elsif rising_edge(layer_clk) then 
      l1_shreg_tready <= '1';
      if l1_shreg_tvalid = '1' then  
        l1_shreg_buffer_1(data_counter) <= l1_shreg_data_1;
        l1_shreg_buffer_2(data_counter) <= l1_shreg_data_2;
        l1_shreg_buffer_3(data_counter) <= l1_shreg_data_3;
        l1_shreg_buffer_4(data_counter) <= l1_shreg_data_4;
        l1_shreg_buffer_5(data_counter) <= l1_shreg_data_5;
        l1_shreg_buffer_6(data_counter) <= l1_shreg_data_6;
        l1_shreg_buffer_7(data_counter) <= l1_shreg_data_7;
        l1_shreg_buffer_8(data_counter) <= l1_shreg_data_8;
        l1_shreg_buffer_9(data_counter) <= l1_shreg_data_9;
        data_counter := data_counter +1;
      end if;  
      if l1_shreg_tlast = '1' then 
        block_done_sh_l1 <= '1'; 
        img_length_sh_l1 <= data_counter;
        data_counter := 0;
      else 
        block_done_sh_l1 <= '0';
      end if;
    end if;
  end process; 
   
  read_testdata_l1: process
    variable v_ILINE      : line;
    variable read_data    : integer;
  begin
    file_open(file_TEST_DATA, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/testdata.txt",  read_mode);
    report "testdata opened successfully"; 
    for i in 0 to BLOCKS_TO_TEST-1 loop
      for j in 0 to BLOCK_LENGTH_L1-1 loop
        readline(file_TEST_DATA, v_ILINE);
        read(v_ILINE, read_data);
        AXI_data_buffer_l1((i*BLOCK_LENGTH_L1)+j) <= std_logic_vector(to_unsigned(read_data,(L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)));
        --report "read_data=" & integer'image(read_data) 
        --        & " i=" & integer'image(i) & " j=" & integer'image(j);              
        if endfile(file_TEST_DATA) = true then 
          exit; 
        end if;
      end loop;  
    end loop;
    file_close(file_TEST_DATA);
    report "Read data done"; 
    wait;
  end process;   

  write_bram_l1: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until l1_bram_block_done'event and l1_bram_block_done='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_bram" & integer'image(block_cnt) & ".txt", write_mode);
    for i in 0 to 1 loop
      for j in 0 to BLOCK_LENGTH_L1-1 loop
        write_data := to_integer(unsigned(l1_bram_data_buffer((i*BLOCK_LENGTH_L1)+j)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    if s_l1_invalid_block = '1' then 
      write(v_OLINE, 1);
      writeline(file_RESULTS, v_OLINE);
    end if;
    file_close(file_RESULTS);
    report "Write bram" & integer'image(block_cnt) & "  done"; 
    block_cnt := block_cnt+1;
  end process;
  
  write_vectors_l1: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done_vec_l1'event and block_done_vec_l1='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inVector_1_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_l1-1 loop
      write_data := to_integer(unsigned(M_l1_buffer_1(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inVector_2_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_l1-1 loop
      write_data := to_integer(unsigned(M_l1_buffer_2(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inVector_3_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_l1-1 loop
      write_data := to_integer(unsigned(M_l1_buffer_3(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);    
    report "Write m layer 1 b" & integer'image(block_cnt) & " done"; 
    block_cnt := block_cnt+1;
  end process;  

  write_shiftreg_l1: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done_sh_l1'event and block_done_sh_l1='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_1_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_1(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_2_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_2(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_3_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_3(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);    
 
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_4_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_4(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_5_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_5(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_6_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_6(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);   
    
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_7_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_7(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_8_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_8(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l1_inKernel_9_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh_l1-1 loop
      write_data := to_integer(unsigned(l1_shreg_buffer_9(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);        
    report "Write shift output b" & integer'image(block_cnt) & " done"; 
    block_cnt := block_cnt+1;
  end process;  


-- ****************** LAYER 2 **********************************************************************  
  L2_MemCtrl_in: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
    variable block_counter : integer;
    variable package_active : std_logic;
  begin
    if layer_aresetn = '0' then 
      s_l2_tdata <= (others => '0');
      s_l2_tkeep <= (others => '0');
      s_l2_tvalid <= '0';
      s_l2_tlast <= '0';
      
      package_active := '0';
      data_counter := 0;
      block_counter := 0;
    elsif rising_edge(layer_clk) then 
      if package_active = '1' then 
        s_l2_tvalid <= '1';
        s_l2_tkeep <= (others => '1');
        if s_l2_tready = '1' and s_l2_tvalid = '1' then 
          data_counter := data_counter + 1;
        end if; 
        s_l2_tdata <= s_data_buffer_l2(data_counter);       
      else 
        if s_l2_tready = '1' then 
          s_l2_tvalid <= '0';
          s_l2_tkeep <= (others => '0');
        end if;  
      end if; 
      if start_package_l2 = '1' then 
        package_active := '1';
        data_counter := BLOCK_LENGTH_L2*block_counter;
        block_counter := block_counter +1;
        s_l2_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH_L2*block_counter-1 then 
        package_active := '0';
        data_counter := 0;
        s_l2_tlast <= '1';
      else 
        s_l2_tlast <= '0';
      end if; 
    end if;
  end process;
  
  BRAM_Rec_l2: process(layer_clk,layer_aresetn) 
  begin
    if layer_aresetn = '0' then 
      l2_bram_block_done <= '0';
    elsif rising_edge(layer_clk) then 
      if l2_bram_pa_wea = (l2_bram_pa_wea'range => '1') then 
        l2_bram_data_buffer(to_integer(unsigned(l2_bram_pa_addr))) <= l2_bram_pa_data_wr;
      end if;  
      if to_integer(unsigned(l2_bram_pa_addr)) = 783 or to_integer(unsigned(l2_bram_pa_addr)) = (BLOCK_LENGTH_L2*2)-1 then 
        l2_bram_block_done <= '1'; 
      else 
        l2_bram_block_done <= '0';
      end if;      
    end if;
  end process;

  M_LAYER_2_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      block_done_vec_l2 <= '0';
    elsif rising_edge(layer_clk) then 
      if m_l2_tvalid = '1' and m_l2_tready = '1' then  
        for i in 0 to L2_IN_CHANNEL_NUMBER-1 loop 
          M_l2_buffer_1(data_counter)(i) <= m_l2_tdata_1((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i);
          M_l2_buffer_2(data_counter)(i) <= m_l2_tdata_2((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i);
          M_l2_buffer_3(data_counter)(i) <= m_l2_tdata_3((L2_DATA_WIDTH*(i+1))-1 downto L2_DATA_WIDTH*i);
        end loop;
        data_counter := data_counter +1;
      end if;  
      if m_l2_tlast = '1' then 
        block_done_vec_l2 <= '1'; 
        img_length_l2 <= data_counter;
        data_counter := 0;
      else 
        block_done_vec_l2 <= '0';
      end if;
    end if;
  end process;  

  Shiftreg_L2_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      l2_shreg_tready <= '0';
      block_done_sh_l2 <= '0';
    elsif rising_edge(layer_clk) then 
      l2_shreg_tready <= '1';
      if l2_shreg_tvalid = '1' then  
        for i in 0 to L2_IN_CHANNEL_NUMBER-1 loop
          l2_shreg_buffer_1(data_counter)(i) <= l2_shreg_data_1(i);
          l2_shreg_buffer_2(data_counter)(i) <= l2_shreg_data_2(i);
          l2_shreg_buffer_3(data_counter)(i) <= l2_shreg_data_3(i);
          l2_shreg_buffer_4(data_counter)(i) <= l2_shreg_data_4(i);
          l2_shreg_buffer_5(data_counter)(i) <= l2_shreg_data_5(i);
          l2_shreg_buffer_6(data_counter)(i) <= l2_shreg_data_6(i);
          l2_shreg_buffer_7(data_counter)(i) <= l2_shreg_data_7(i);
          l2_shreg_buffer_8(data_counter)(i) <= l2_shreg_data_8(i);
          l2_shreg_buffer_9(data_counter)(i) <= l2_shreg_data_9(i);    
        end loop;
        data_counter := data_counter +1;
      end if;
      
      if l2_shreg_tlast = '1' then 
        block_done_sh_l2 <= '1'; 
        img_length_sh_l2 <= data_counter;
        data_counter := 0;
      else 
        block_done_sh_l2 <= '0';
      end if;
    end if;
    test_datacounter <= data_counter;
  end process; 
   
  read_testdata_l2: process
    variable v_ILINE      : line;
    variable read_data    : integer;
  begin
     
    for k in 0 to L2_IN_CHANNEL_NUMBER-1 loop
      file_open(file_TEST_DATA, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/feature_map_L2_c" & integer'image(k) & ".txt",  read_mode);
      report "feature map " & integer'image(k) & " opened successfully";
      for i in 0 to BLOCKS_TO_TEST-1 loop
        for j in 0 to BLOCK_LENGTH_L2-1 loop
          readline(file_TEST_DATA, v_ILINE);
          read(v_ILINE, read_data);
          s_data_buffer_l2((i*BLOCK_LENGTH_L2)+j)(((k+1)*L2_DATA_WIDTH)-1 downto k*L2_DATA_WIDTH) <= std_logic_vector(to_unsigned(read_data,L2_DATA_WIDTH));
          --report "read_data=" & integer'image(read_data) 
          --        & " i=" & integer'image(i) & " j=" & integer'image(j);              
          if endfile(file_TEST_DATA) = true then 
            exit; 
          end if;
        end loop;  
      end loop;
    end loop;
    file_close(file_TEST_DATA);
    report "Read data done"; 
    wait;
  end process;   

  write_bram_l2: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until l2_bram_block_done'event and l2_bram_block_done='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_bram" & integer'image(block_cnt) & ".txt", write_mode);
    for i in 0 to 1 loop
      for j in 0 to BLOCK_LENGTH_L2-1 loop
        for k in 0 to L2_IN_CHANNEL_NUMBER-1 loop 
          write_data := to_integer(unsigned(l2_bram_data_buffer((i*BLOCK_LENGTH_L2)+j)((k+1)*L2_DATA_WIDTH-1 downto k*L2_DATA_WIDTH)));
          write(v_OLINE, write_data);
          write(v_OLINE, string'(" "));
        end loop;  
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    if s_l2_invalid_block = '1' then 
      write(v_OLINE, 1);
      writeline(file_RESULTS, v_OLINE);
    end if;
    file_close(file_RESULTS);
    report "Write bram" & integer'image(block_cnt) & "  done"; 
    block_cnt := block_cnt+1;
  end process;
  
  write_vectors_l2: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done_vec_l2'event and block_done_vec_l2='1';
    for k in 0 to L2_IN_CHANNEL_NUMBER-1 loop
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inVector_1_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_l2-1 loop
        write_data := to_integer(unsigned(M_l2_buffer_1(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inVector_2_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_l2-1 loop
        write_data := to_integer(unsigned(M_l2_buffer_2(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inVector_3_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_l2-1 loop
        write_data := to_integer(unsigned(M_l2_buffer_3(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);    
      report "Write m layer 1 b" & integer'image(block_cnt) & " done";
    end loop;
    block_cnt := block_cnt+1;
  end process;  

  write_shiftreg_l2: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done_sh_l2'event and block_done_sh_l2='1';
    for k in 0 to L2_IN_CHANNEL_NUMBER-1 loop
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_1_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_1(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_2_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_2(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_3_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_3(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);      
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_4_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_4(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_5_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_5(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_6_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_6(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);         
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_7_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_7(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_8_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_8(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);
      file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/l2_inKernel_9_c" & integer'image(k) & "_b" & integer'image(block_cnt) & ".txt", write_mode);
      for j in 0 to img_length_sh_l2-1 loop
        write_data := to_integer(unsigned(l2_shreg_buffer_9(j)(k)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
      file_close(file_RESULTS);      
      report "Write shift output b" & integer'image(block_cnt) & " done"; 
      report "Write kernels channel " & integer'image(k) & " done"; 
    end loop;
    block_cnt := block_cnt+1;
    
  end process;  
 
  write_debug: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until debug_done'event and debug_done='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/debug" & integer'image(block_cnt) & ".txt", write_mode);
    for i in 0 to 1 loop
      for j in 0 to BLOCK_LENGTH_L2-1 loop
        write_data := to_integer(unsigned(dbg_l2_bram_data_buffer((i*BLOCK_LENGTH_L2)+j)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    file_close(file_RESULTS);
    report "Write debug done"; 
    block_cnt := block_cnt+1;
  end process;
 


end tb;


