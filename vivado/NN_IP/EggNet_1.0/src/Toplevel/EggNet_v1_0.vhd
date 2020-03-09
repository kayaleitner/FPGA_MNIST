library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.kernel_pkg.all; -- defines kernel size

use work.EggNet_v1_0_S00_AXI;
use work.MemCtrl_3x3;
use work.STD_FIFO;
use work.ShiftRegister_3x3;
use work.Conv2D_0;
use work.MaxPooling;
use work.Conv2D_1;
use work.Serializer;
use work.NeuralNetwork;
use work.AXI_steam_master;



entity EggNet_v1_0 is
	generic (
		-- Users to add parameters here
    LAYER_HIGHT             : integer := 28;
    LAYER_WIDTH             : integer := 28;
    DATA_WIDTH              : integer := 6;
    L1_IN_CHANNEL_NUMBER	  : integer := 1;    
    L2_IN_CHANNEL_NUMBER	  : integer := 16;      
    L3_IN_CHANNEL_NUMBER	  : integer := 32;    
    MEM_CTRL_NUMBER         : integer := 4;  
    OUTPUT_COUNT            : integer := 10; 
    PATH                    : string := "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0";
    
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
    
    
    -- AXI stream clock and reset 
		axis_aclk	: in std_logic;
		axis_aresetn	: in std_logic;    

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tkeep	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tkeep	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;
    
    -- Interrupts 
    Res_itrp_o : out std_logic
    
    
    -- ;ila_s00_axis_tready	: out std_logic;
		-- ila_s00_axis_tdata	: out std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		-- ila_s00_axis_tkeep	: out std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- ila_s00_axis_tlast	: out std_logic;
		-- ila_s00_axis_tvalid	: out std_logic

    -- ;ila_m00_axis_tvalid	: out std_logic;
		-- ila_m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		-- ila_m00_axis_tkeep	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- ila_m00_axis_tlast	: out std_logic;
		-- ila_m00_axis_tready	: out std_logic
    

    -- ;ila_dbg_bram_addr_in     : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    -- ila_dbg_bram_addr_check  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);  
    -- ila_dbg_bram_data_out    : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    -- ila_dbg_32bit_select     : out std_logic_vector(3 downto 0);
    -- ila_dbg_enable           : out std_logic; 
    -- ila_layer_properties     : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);  
    -- ila_status               : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0)  
	);
end EggNet_v1_0;

architecture arch_imp of EggNet_v1_0 is

 --attribute X_INTERFACE_INFO of Res_itrp_o : signal is "xilinx.com:signal:interrupt:1.0 irq INTERRUPT";
 --attribute X_INTERFACE_PARAMETER of Res_itrp_o : signal is "SENSITIVITY EDGE_RISING";

  constant L1_BRAM_ADDR_WIDTH		    : integer := 11; -- maximum = 24 
  constant L2_BRAM_ADDR_WIDTH		    : integer := 9; -- maximum = 24 
  constant MEM_CTRL_ADDR_WITDH      : integer := 8; -- don't change
  constant BRAM_MIN_DATA_WIDTH      : integer := 8; --required since 8 is the minimum data width of a BRAM
--constant M_LAYER_DIM_FEATURES : integer := 1; 

  signal l1_m_tvalid            : std_logic;
  signal l1_m_tdata_1           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tdata_2           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tdata_3           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tkeep             : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1 downto 0);
  signal l1_m_tnewrow           : std_logic;
  signal l1_m_tlast             : std_logic;
  signal l1_m_tready            : std_logic;   
  signal l1_m_fifo_srst         : std_logic;
  signal l1_m_fifo_in           : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);
  signal l1_m_fifo_wr           : std_logic;
  signal l1_m_fifo_rd           : std_logic;
  signal l1_m_fifo_out          : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);  
  signal l1_bram_clk            : std_logic;
  signal l1_bram_pa_addr        : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal l1_bram_pa_data_wr     : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_bram_pa_wea         : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1  downto 0);
  signal l1_bram_pb_addr        : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal l1_bram_pb_data_rd     : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);       
  signal l1_bram_pa_data_wr_8   : std_logic_vector(BRAM_MIN_DATA_WIDTH-1 downto 0);
  signal l1_bram_pb_data_rd_8   : std_logic_vector(BRAM_MIN_DATA_WIDTH-1 downto 0);
  
  signal l1_s_conv_data_1       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_2       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_3       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_4       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_5       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_6       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_7       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_8       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_9       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_reshape : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER*KERNEL_SIZE) - 1) downto 0);
  signal l1_s_conv_tvalid       : std_logic;
  signal l1_s_conv_tlast        : std_logic;
  signal l1_s_conv_tready       : std_logic;  
  signal l1_m_conv_data_unsig   : unsigned(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_m_conv_data         : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_m_conv_tvalid       : std_logic;
  signal l1_m_conv_tlast        : std_logic;
  signal l1_m_conv_tready       : std_logic;   
  
   
  
  signal l2_s_tvalid	          : std_logic;
  signal l2_s_tdata             : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1) downto 0);
  signal l2_s_tlast             : std_logic;
  signal l2_s_tready            : std_logic;     
  signal l2_m_tvalid            : std_logic;
  signal l2_m_tdata_1           : std_logic_vector((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_m_tdata_2           : std_logic_vector((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_m_tdata_3           : std_logic_vector((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_m_tkeep             : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)/8)-1 downto 0);
  signal l2_m_tnewrow           : std_logic;
  signal l2_m_tlast             : std_logic;
  signal l2_m_tready            : std_logic;   
  signal l2_m_fifo_srst         : std_logic;
  signal l2_m_fifo_in           : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)*2)-1 downto 0);
  signal l2_m_fifo_wr           : std_logic;
  signal l2_m_fifo_rd           : std_logic;
  signal l2_m_fifo_out          : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)*2)-1 downto 0);  
  signal l2_bram_clk            : std_logic;
  signal l2_bram_pa_addr        : std_logic_vector(L2_BRAM_ADDR_WIDTH-1 downto 0);
  signal l2_bram_pa_data_wr     : std_logic_vector((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l2_bram_pa_wea         : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)/8)-1  downto 0);
  signal l2_bram_pb_addr        : std_logic_vector(L2_BRAM_ADDR_WIDTH-1 downto 0);
  signal l2_bram_pb_data_rd     : std_logic_vector((DATA_WIDTH*L2_IN_CHANNEL_NUMBER)-1 downto 0);       
  
  signal l2_s_conv_data_1       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_2       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_3       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_4       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_5       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_6       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_7       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_8       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_9       : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_s_conv_data_reshape : std_logic_vector(((DATA_WIDTH*L2_IN_CHANNEL_NUMBER*KERNEL_SIZE) - 1) downto 0);
  signal l2_s_conv_tvalid       : std_logic;
  signal l2_s_conv_tlast        : std_logic;
  signal l2_s_conv_tready       : std_logic;   
  signal l2_m_conv_data_unsig   : unsigned(((DATA_WIDTH*L3_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_m_conv_data         : std_logic_vector(((DATA_WIDTH*L3_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l2_m_conv_tvalid       : std_logic;
  signal l2_m_conv_tlast        : std_logic;
  signal l2_m_conv_tready       : std_logic;  
  
  signal l3_s_tvalid	          : std_logic;
  signal l3_s_tdata             : std_logic_vector(((DATA_WIDTH*L3_IN_CHANNEL_NUMBER)-1) downto 0);
  signal l3_s_tlast             : std_logic;
  signal l3_s_tready            : std_logic;    
  signal l3_m_tvalid            : std_logic;    
  signal l3_m_tdata             : std_logic_vector(OUTPUT_COUNT*DATA_WIDTH - 1 downto 0);
  signal l3_m_tlast             : std_logic;
  signal l3_m_tready            : std_logic;
  
  signal serializer_valid       : std_logic;
  signal serializer_data        : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal serializer_ready       : std_logic;
  
  signal output_reg             : std_logic_vector(OUTPUT_COUNT*DATA_WIDTH - 1 downto 0);
  
  signal dbg_bram_addr_in       : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal dbg_bram_addr_check    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);  
  signal dbg_bram_data_out      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal dbg_32bit_select       : std_logic_vector(3 downto 0); 
  signal dbg_enable_AXI         : std_logic;   
  signal dbg_enable             : std_logic_vector(MEM_CTRL_NUMBER downto 0);   
  signal axi_mem_ctrl_addr      : std_logic_vector(MEM_CTRL_ADDR_WITDH-1 downto 0);  
  signal axi_progress           : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);   
  
  type STATUS_ARR is ARRAY (0 to MEM_CTRL_NUMBER) of std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal status                 : STATUS_ARR;
  signal layer_properties       : STATUS_ARR; 
  signal axi_layer_properties   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal axi_status             : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal all_running            : std_logic;
  
  
  signal l1_s_tready            : std_logic;
  
  
begin

-- Debug Outputs for ILA 
s00_axis_tready <= l1_s_tready ;

-- ila_s00_axis_tready <= l1_s_tready;
-- ila_s00_axis_tdata	<= s00_axis_tdata	 ;
-- ila_s00_axis_tkeep	<= s00_axis_tkeep	 ;
-- ila_s00_axis_tlast	<= s00_axis_tlast	 ;
-- ila_s00_axis_tvalid <= s00_axis_tvalid ;

-- ila_m00_axis_tvalid <= l1_s_conv_tvalid;
-- ila_m00_axis_tdata	<= (l1_s_conv_data_1 & l1_s_conv_data_2 & l1_s_conv_data_3 & l1_s_conv_data_4);
-- ila_m00_axis_tkeep	<= (others => '1');
-- ila_m00_axis_tlast	<= l1_s_conv_tlast;
-- ila_m00_axis_tready	<= m00_axis_tready;


-- ila_dbg_bram_addr_in    <= dbg_bram_addr_in     ;
-- ila_dbg_bram_addr_check <= dbg_bram_addr_check  ;
-- ila_dbg_bram_data_out   <= dbg_bram_data_out    ;
-- ila_dbg_32bit_select    <= dbg_32bit_select     ;
-- ila_dbg_enable          <= dbg_enable(1)        ;
-- ila_layer_properties    <= layer_properties(1)  ;
-- ila_status              <= status(1);

-- *************** Status and Debugging  using AXI-lite ********************************************
layer_properties(0)(7 downto 0) <= std_logic_vector(to_unsigned(MEM_CTRL_NUMBER,8));
layer_properties(0)(31 downto 7) <= (others => '0'); -- FIND SOMETHING USEFULL 
status(0)(7 downto 0) <= (others => '0'); -- find something usefull here
status(0)(15 downto 8) <= (others => '0'); -- Memory Controller Address = 0 for overall status. DO NOT CHANGE!
status(0)(31 downto 16) <= x"F0F0"; -- find something usefull here 

Running_flag: process(s00_axi_aclk,s00_axi_aresetn) is 
  variable debugging : std_logic;
begin 
  if s00_axi_aresetn = '0' then 
    debugging := '0';
  elsif rising_edge(s00_axi_aclk) then 
    debugging := '0';
    for i in 1 to MEM_CTRL_NUMBER loop 
      debugging := debugging and status(i)(17);
    end loop; 
    all_running <= not debugging;  
  end if;
end process; 

Dbg_ctrl: process(s00_axi_aclk,s00_axi_aresetn) is 
begin 
  if s00_axi_aresetn = '0' then 
    axi_status <= (others => '0');
  elsif rising_edge(s00_axi_aclk) then 
     
    if unsigned(axi_mem_ctrl_addr) <= to_unsigned(MEM_CTRL_NUMBER,axi_mem_ctrl_addr'length) then 
      axi_status <= status(to_integer(unsigned(axi_mem_ctrl_addr)));
      axi_layer_properties <= layer_properties(to_integer(unsigned(axi_mem_ctrl_addr)));
      dbg_enable(to_integer(unsigned(axi_mem_ctrl_addr))) <= dbg_enable_AXI;
    end if;   
  end if;
end process; 


-- Instantiation of Axi Bus Interface S00_AXI
EggNet_v1_0_S00_AXI_inst : entity work.EggNet_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
    Status_i               => axi_status,              
    Dbg_bram_addr_o        => dbg_bram_addr_in ,
    Dbg_bram_addr_check_i  => dbg_bram_addr_check  ,
    Dbg_bram_data_i        => dbg_bram_data_out    ,
    Dbg_32bit_select_o     => dbg_32bit_select     ,
    Dbg_enable_o           => dbg_enable_AXI       ,
    AXI_mem_ctrl_addr_o    => axi_mem_ctrl_addr    ,
    AXI_layer_properties_i => axi_layer_properties ,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- *************** Layer1 Conv2d *******************************************************************

-- Memory controller + BRAM + FIFO +ShiftRegister_3x3
  L1_Memory_Controller: entity work.MemCtrl_3x3
    generic map(                                   
      BRAM_ADDR_WIDTH		      => L1_BRAM_ADDR_WIDTH,
      DATA_WIDTH		          => DATA_WIDTH,
      IN_CHANNEL_NUMBER       => L1_IN_CHANNEL_NUMBER,
      LAYER_HIGHT             => LAYER_HIGHT,
      LAYER_WIDTH             => LAYER_WIDTH,
      AXI4_STREAM_INPUT       => 1,
      MEM_CTRL_ADDR           => 1,
      C_S_AXIS_TDATA_WIDTH    => C_S00_AXIS_TDATA_WIDTH,
      C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH
      )       
    port map(
      Layer_clk_i		          => axis_aclk,
      Layer_aresetn_i         => axis_aresetn,
      S_layer_tvalid_i	      => s00_axis_tvalid,
      S_layer_tdata_i         => s00_axis_tdata,
      S_layer_tkeep_i         => s00_axis_tkeep,
      S_layer_tlast_i         => s00_axis_tlast,
      S_layer_tready_o        => l1_s_tready,
      M_layer_tvalid_o	      => l1_m_tvalid        ,
      M_layer_tdata_1_o       => l1_m_tdata_1       ,
      M_layer_tdata_2_o       => l1_m_tdata_2       ,
      M_layer_tdata_3_o       => l1_m_tdata_3       ,
       M_layer_tnewrow_o      => l1_m_tnewrow       ,
      M_layer_tlast_o         => l1_m_tlast         ,
      M_layer_tready_i        => l1_m_tready        ,
      M_layer_fifo_srst_o     => l1_m_fifo_srst     ,
      M_layer_fifo_in_o       => l1_m_fifo_in       ,
      M_layer_fifo_wr_o       => l1_m_fifo_wr       ,
      M_layer_fifo_rd_o       => l1_m_fifo_rd       ,
      M_layer_fifo_out_i      => l1_m_fifo_out      ,
      Bram_clk_o              => l1_bram_clk        ,
      Bram_pa_addr_o          => l1_bram_pa_addr    ,
      Bram_pa_data_wr_o       => l1_bram_pa_data_wr ,
      Bram_pa_wea_o           => l1_bram_pa_wea     ,
      Bram_pb_addr_o          => l1_bram_pb_addr    ,
      Bram_pb_data_rd_i       => l1_bram_pb_data_rd ,
      Dbg_bram_addr_i         => dbg_bram_addr_in ,
      Dbg_bram_addr_o         => dbg_bram_addr_check,
      Dbg_bram_data_o         => dbg_bram_data_out,
      Dbg_32bit_select_i      => dbg_32bit_select  ,
      Dbg_enable_i            => dbg_enable(1),
      Layer_properties_o      => layer_properties(1),
      Status_o                => status(1));
      
  L1_bram : entity work.blk_mem_gen_0
  port map (clka  => l1_bram_clk,
            wea   => l1_bram_pa_wea,
            addra => l1_bram_pa_addr,
            dina  => l1_bram_pa_data_wr_8,
            clkb  => l1_bram_clk,
            addrb => l1_bram_pb_addr,
            doutb => l1_bram_pb_data_rd_8
  );

-- required because minimum DATA_WIDTH of BRAM is 8
MAP_2_8bit: if DATA_WIDTH < 8 generate
  l1_bram_pa_data_wr_8(BRAM_MIN_DATA_WIDTH-1 downto DATA_WIDTH) <= (others => '0');
  l1_bram_pa_data_wr_8(DATA_WIDTH-1 downto 0) <= l1_bram_pa_data_wr; 
  l1_bram_pb_data_rd <= l1_bram_pb_data_rd_8(DATA_WIDTH-1 downto 0);
end generate MAP_2_8bit;  

NO_MAP_2_8bit: if DATA_WIDTH >= 8 generate
  l1_bram_pa_data_wr_8 <= l1_bram_pa_data_wr; 
  l1_bram_pb_data_rd <= l1_bram_pb_data_rd_8;
end generate NO_MAP_2_8bit;

  linebuffer_layer1: entity work.STD_FIFO
    generic map (
        DATA_WIDTH => 2*DATA_WIDTH * L1_IN_CHANNEL_NUMBER,
        FIFO_DEPTH => LAYER_WIDTH+1
    )
    port map (
      Clk_i     => axis_aclk,
      Rst_i     => l1_m_fifo_srst     ,
      Data_i    => l1_m_fifo_in       ,
      WriteEn_i => l1_m_fifo_wr       ,
      ReadEn_i  => l1_m_fifo_rd       ,
      Data_o    => l1_m_fifo_out      ,
      Full_o    => open,
      Empty_o   => open
    );    
    

  L1_shiftregister: entity work.ShiftRegister_3x3
    generic map(
      DATA_WIDTH => (DATA_WIDTH*L1_IN_CHANNEL_NUMBER)
    )
    port map(
      Clk_i       => axis_aclk,		 
      nRst_i      => axis_aresetn, 
      S_data_1_i  => l1_m_tdata_1, 
      S_data_2_i  => l1_m_tdata_2, 
      S_data_3_i  => l1_m_tdata_3, 
      S_tvalid_i  => l1_m_tvalid,
      S_tnewrow_i => l1_m_tnewrow,
      S_tlast_i   => l1_m_tlast, 
      S_tready_o  => l1_m_tready, 
      M_data_1_o  => l1_s_conv_data_1, 
      M_data_2_o  => l1_s_conv_data_2, 
      M_data_3_o  => l1_s_conv_data_3, 
      M_data_4_o  => l1_s_conv_data_4, 
      M_data_5_o  => l1_s_conv_data_5, 
      M_data_6_o  => l1_s_conv_data_6, 
      M_data_7_o  => l1_s_conv_data_7, 
      M_data_8_o  => l1_s_conv_data_8, 
      M_data_9_o  => l1_s_conv_data_9, 
      M_tvalid_o  => l1_s_conv_tvalid,
      M_tlast_o   => l1_s_conv_tlast , 
      M_tready_i  => l1_s_conv_tready
    );      
 
-- Conv2d 
  l1_s_conv_data_reshape <= (l1_s_conv_data_1 & l1_s_conv_data_2 & l1_s_conv_data_3 & l1_s_conv_data_4 & l1_s_conv_data_5 & l1_s_conv_data_6 & l1_s_conv_data_7 & l1_s_conv_data_8 & l1_s_conv_data_9);
  L1_conv2d : entity work.Conv2D_0 --Todo: Edit to real name
    generic map(
      BIT_WIDTH_IN => DATA_WIDTH,
      BIT_WIDTH_OUT => DATA_WIDTH,
      INPUT_CHANNELS => L1_IN_CHANNEL_NUMBER,
      OUTPUT_CHANNELS => L2_IN_CHANNEL_NUMBER)
    port map(
      Clk_i   => axis_aclk,		
      n_Res_i => axis_aresetn,
      Valid_i => l1_s_conv_tvalid,
      Valid_o => l1_m_conv_tvalid,
      Last_i  => l1_s_conv_tlast,
      Last_o  => l1_m_conv_tlast,
      Ready_i => l1_m_conv_tready,
      Ready_o => l1_s_conv_tready,
      X_i     => l1_s_conv_data_reshape,
      Y_o     => l1_m_conv_data_unsig
    );
    l1_m_conv_data <= std_logic_vector(l1_m_conv_data_unsig);
-- MaxPooling   
  L1_maxPooling: entity work.MaxPooling
  generic map(
    CHANNEL_NUMBER    => L2_IN_CHANNEL_NUMBER,
    DATA_WIDTH        => DATA_WIDTH,
    LAYER_HIGHT       => LAYER_HIGHT,
    LAYER_WIDTH       => LAYER_WIDTH)
  port map(
    -- Clk and reset
    Layer_clk_i		    => axis_aclk,		
    Layer_aresetn_i   => axis_aresetn,

    S_layer_tvalid_i	=> l1_m_conv_tvalid,
    S_layer_tdata_i   => l1_m_conv_data,
    S_layer_tkeep_i   => (others => '1'),
    S_layer_tlast_i   => l1_m_conv_tlast,
    S_layer_tready_o  => l1_m_conv_tready,  

    M_layer_tvalid_o	=> l2_s_tvalid,
    M_layer_tdata_o   => l2_s_tdata,
    M_layer_tkeep_o   => open,
    M_layer_tlast_o   => l2_s_tlast,
    M_layer_tready_i  => l2_s_tready
  );
 
-- *************** Layer2 Conv2d *******************************************************************

-- Memory controller + BRAM + FIFO +ShiftRegister_3x3
  L2_Memory_Controller: entity work.MemCtrl_3x3
    generic map(                                   
      BRAM_ADDR_WIDTH		      => L2_BRAM_ADDR_WIDTH,
      DATA_WIDTH		          => DATA_WIDTH,
      IN_CHANNEL_NUMBER       => L2_IN_CHANNEL_NUMBER,
      LAYER_HIGHT             => LAYER_HIGHT/2,
      LAYER_WIDTH             => LAYER_WIDTH/2,
      AXI4_STREAM_INPUT       => 0,
      MEM_CTRL_ADDR           => 2,
      C_S_AXIS_TDATA_WIDTH    => C_S00_AXIS_TDATA_WIDTH,
      C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH
      )       
    port map(
      Layer_clk_i		          => axis_aclk,
      Layer_aresetn_i         => axis_aresetn,
      S_layer_tvalid_i	      => l2_s_tvalid,
      S_layer_tdata_i         => l2_s_tdata,
      S_layer_tkeep_i         => (others => '1'),
      S_layer_tlast_i         => l2_s_tlast,
      S_layer_tready_o        => l2_s_tready,
      M_layer_tvalid_o	      => l2_m_tvalid        ,
      M_layer_tdata_1_o       => l2_m_tdata_1       ,
      M_layer_tdata_2_o       => l2_m_tdata_2       ,
      M_layer_tdata_3_o       => l2_m_tdata_3       ,
       M_layer_tnewrow_o      => l2_m_tnewrow       ,
      M_layer_tlast_o         => l2_m_tlast         ,
      M_layer_tready_i        => l2_m_tready        ,
      M_layer_fifo_srst_o     => l2_m_fifo_srst     ,
      M_layer_fifo_in_o       => l2_m_fifo_in       ,
      M_layer_fifo_wr_o       => l2_m_fifo_wr       ,
      M_layer_fifo_rd_o       => l2_m_fifo_rd       ,
      M_layer_fifo_out_i      => l2_m_fifo_out      ,
      Bram_clk_o              => l2_bram_clk        ,
      Bram_pa_addr_o          => l2_bram_pa_addr    ,
      Bram_pa_data_wr_o       => l2_bram_pa_data_wr ,
      Bram_pa_wea_o           => l2_bram_pa_wea     ,
      Bram_pb_addr_o          => l2_bram_pb_addr    ,
      Bram_pb_data_rd_i       => l2_bram_pb_data_rd ,
      Dbg_bram_addr_i         => dbg_bram_addr_in ,
      Dbg_bram_addr_o         => dbg_bram_addr_check,
      Dbg_bram_data_o         => dbg_bram_data_out,
      Dbg_32bit_select_i      => dbg_32bit_select  ,
      Dbg_enable_i            => dbg_enable(2),
      Layer_properties_o      => layer_properties(2),
      Status_o                => status(2));
      
  L2_bram : entity work.blk_mem_layer_2
  port map (clka  => l2_bram_clk,
            wea   => l2_bram_pa_wea,
            addra => l2_bram_pa_addr,
            dina  => l2_bram_pa_data_wr,
            clkb  => l2_bram_clk,
            addrb => l2_bram_pb_addr,
            doutb => l2_bram_pb_data_rd
  );

  linebuffer_layer2: entity work.STD_FIFO
    generic map (
        DATA_WIDTH => 2*DATA_WIDTH * L2_IN_CHANNEL_NUMBER,
        FIFO_DEPTH => LAYER_WIDTH/2+1
    )
    port map (
      Clk_i     => axis_aclk,
      Rst_i     => l2_m_fifo_srst     ,
      Data_i    => l2_m_fifo_in       ,
      WriteEn_i => l2_m_fifo_wr       ,
      ReadEn_i  => l2_m_fifo_rd       ,
      Data_o    => l2_m_fifo_out      ,
      Full_o    => open,
      Empty_o   => open
    );    
    

  L2_shiftregister: entity work.ShiftRegister_3x3
    generic map(
      DATA_WIDTH => (DATA_WIDTH*L2_IN_CHANNEL_NUMBER)
    )
    port map(
      Clk_i       => axis_aclk,		 
      nRst_i      => axis_aresetn, 
      S_data_1_i  => l2_m_tdata_1, 
      S_data_2_i  => l2_m_tdata_2, 
      S_data_3_i  => l2_m_tdata_3, 
      S_tvalid_i  => l2_m_tvalid,
      S_tnewrow_i => l2_m_tnewrow,
      S_tlast_i   => l2_m_tlast, 
      S_tready_o  => l2_m_tready, 
      M_data_1_o  => l2_s_conv_data_1, 
      M_data_2_o  => l2_s_conv_data_2, 
      M_data_3_o  => l2_s_conv_data_3, 
      M_data_4_o  => l2_s_conv_data_4, 
      M_data_5_o  => l2_s_conv_data_5, 
      M_data_6_o  => l2_s_conv_data_6, 
      M_data_7_o  => l2_s_conv_data_7, 
      M_data_8_o  => l2_s_conv_data_8, 
      M_data_9_o  => l2_s_conv_data_9, 
      M_tvalid_o  => l2_s_conv_tvalid,
      M_tlast_o   => l2_s_conv_tlast , 
      M_tready_i  => l2_s_conv_tready
    );      
 
-- Conv2d 
  l2_s_conv_data_reshape <= (l2_s_conv_data_1 & l2_s_conv_data_2 & l2_s_conv_data_3 & l2_s_conv_data_4 & l2_s_conv_data_5 & l2_s_conv_data_6 & l2_s_conv_data_7 & l2_s_conv_data_8 & l2_s_conv_data_9);
  
  L2_conv2d : entity work.Conv2D_1 --Todo: Edit to real name
    generic map(
      BIT_WIDTH_IN => DATA_WIDTH,
      BIT_WIDTH_OUT => DATA_WIDTH,
      INPUT_CHANNELS => L2_IN_CHANNEL_NUMBER,
      OUTPUT_CHANNELS => L3_IN_CHANNEL_NUMBER)
    port map(
      Clk_i   => axis_aclk,		
      n_Res_i => axis_aresetn,
      Valid_i => l2_s_conv_tvalid,
      Valid_o => l2_m_conv_tvalid,
      Last_i  => l2_s_conv_tlast,
      Last_o  => l2_m_conv_tlast,
      Ready_i => l2_m_conv_tready,
      Ready_o => l2_s_conv_tready,
      X_i     => l2_s_conv_data_reshape,
      Y_o     => l2_m_conv_data_unsig
    );
    l2_m_conv_data <= std_logic_vector(l2_m_conv_data_unsig);
-- MaxPooling   
  L2_maxPooling: entity work.MaxPooling
  generic map(
    CHANNEL_NUMBER    => L3_IN_CHANNEL_NUMBER,
    DATA_WIDTH        => DATA_WIDTH,
    LAYER_HIGHT       => LAYER_HIGHT/2,
    LAYER_WIDTH       => LAYER_WIDTH/2)
  port map(
    -- Clk and reset
    Layer_clk_i		  => axis_aclk,		
    Layer_aresetn_i   => axis_aresetn,

    S_layer_tvalid_i  => l2_m_conv_tvalid,
    S_layer_tdata_i   => l2_m_conv_data,
    S_layer_tkeep_i   => (others => '1'),
    S_layer_tlast_i   => l2_m_conv_tlast,
    S_layer_tready_o  => l2_m_conv_tready,  

    M_layer_tvalid_o  => l3_s_tvalid,
    M_layer_tdata_o   => l3_s_tdata,
    M_layer_tkeep_o   => open,
    M_layer_tlast_o   => l3_s_tlast,
    M_layer_tready_i  => l3_s_tready
  ); 
  
-- *************** Layer3-4 Fully-Connected ********************************************************
  
  FC_serializer: entity work.Serializer
  generic map(
    VECTOR_WIDTH    => DATA_WIDTH,
    INPUT_CHANNELS  => L3_IN_CHANNEL_NUMBER
  ) port map(
    Clk_i    => axis_aclk,
    n_Res_i  => axis_aresetn,
	
    Valid_i  => l3_s_tvalid,
    Ready_o  => l3_s_tready,
    Data_i   => l3_s_tdata,
	
    Valid_o  => serializer_valid,
    Data_o   => serializer_data,
    Ready_i  => serializer_ready
  );
  
  FC_NN: entity work.NeuralNetwork
  generic map(
    VECTOR_WIDTH  => DATA_WIDTH,
    INPUT_COUNT   => ((LAYER_HIGHT*LAYER_WIDTH)/16)*L3_IN_CHANNEL_NUMBER,
    OUTPUT_COUNT  => OUTPUT_COUNT,
    PATH          => PATH
  ) port map (
    Clk_i     => axis_aclk,
    Resetn_i  => axis_aresetn,	
    Valid_i   => serializer_valid,
    Data_i    => serializer_data,
    Ready_o   => serializer_ready,
    Ready_i   => l3_m_tready,
    Valid_o   => l3_m_tvalid,
    Last_o    => l3_m_tlast,    
    Data_o    => l3_m_tdata  );

-- *************** Data Output to DMA **************************************************************
  AXIS_Master: entity work.AXI_steam_master
	generic map (
    OUTPUT_NUMBER 		      => OUTPUT_COUNT,
    DATA_WIDTH    		      => DATA_WIDTH,
		C_M_AXIS_TDATA_o_WIDTH	=> C_M00_AXIS_TDATA_WIDTH)
	port map(
		Clk_i	          => axis_aclk,
		nRst_i	        => axis_aresetn,
    Layer_tvalid_i	=> l3_m_tvalid,
    Layer_tdata_i   => l3_m_tdata,
    Layer_tlast_i   => l3_m_tlast,
    Layer_tready_o  => l3_m_tready,
    Interrupt       => Res_itrp_o,
		M_axis_tvalid_o	=> m00_axis_tvalid,
		M_axis_tdata_o	=> m00_axis_tdata,
		M_axis_tkeep_o	=> m00_axis_tkeep,
		M_axis_tlast_o	=> m00_axis_tlast,
		M_axis_tready_i	=> m00_axis_tready	);
	-- User logic ends

end arch_imp;
