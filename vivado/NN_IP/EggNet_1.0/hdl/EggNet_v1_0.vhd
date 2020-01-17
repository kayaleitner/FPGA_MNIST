library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EggNet_v1_0 is
	generic (
		-- Users to add parameters here
    LAYER_HIGHT             : integer := 28;
    LAYER_WIDTH             : integer := 28;
    DATA_WIDTH              : integer := 8;
    L1_IN_CHANNEL_NUMBER	  : integer := 16;    
    L2_IN_CHANNEL_NUMBER	  : integer := 32;      
    L3_IN_CHANNEL_NUMBER	  : integer := 32;      
    
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

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tkeep	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tkeep	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic
	);
end EggNet_v1_0;

architecture arch_imp of EggNet_v1_0 is

  constant L1_BRAM_ADDR_WIDTH		    : integer := 11; -- maximum = 24 
  constant KERNEL_SIZE              : integer := 3;
--constant M_LAYER_DIM_FEATURES : integer := 1; 
  
	-- component declaration
	component EggNet_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
    Status_i : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component EggNet_v1_0_S00_AXI;

component MemCtrl_3x3 is
    Generic(
      BRAM_ADDR_WIDTH		        : integer range 1 to 24   := 10; -- maximum = 24 
      DATA_WIDTH		            : integer := 8; -- channel number * bit depth maximum = 512    
      IN_CHANNEL_NUMBER		      : integer := 1;       
      LAYER_HIGHT               : integer := 28;
      LAYER_WIDTH               : integer := 28;   
      AXI4_STREAM_INPUT         : integer range 0 to 1    := 0;
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
      S_layer_tdata_i   : in std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*(DATA_WIDTH*L1_IN_CHANNEL_NUMBER)))-1 downto 0);-- if AXI4_STREAM_INPUT = 0 -> (DATA_WIDTH*L1_IN_CHANNEL_NUMBER) else C_S_AXIS_TDATA_WIDTH
      S_layer_tkeep_i   : in std_logic_vector((((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*(DATA_WIDTH*L1_IN_CHANNEL_NUMBER)))/8)-1 downto 0);  --only used if next layer is AXI-stream interface 
      S_layer_tlast_i   : in std_logic;
      S_layer_tready_o  : out std_logic;     
      -- Next layer interface 
      M_layer_tvalid_o	: out std_logic;
      M_layer_tdata_1_o : out std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 1 |Vector: trans(1,2,3)
      M_layer_tdata_2_o : out std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 2 |Vector: trans(1,2,3)
      M_layer_tdata_3_o : out std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 3 |Vector: trans(1,2,3)
      M_layer_tkeep_o   : out std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0); --only used if next layer is AXI-stream interface (default open)
      M_layer_tnewrow_o : out std_logic;
      M_layer_tlast_o   : out std_logic;
      M_layer_tready_i  : in std_logic;      
      -- M_layer FIFO
      M_layer_fifo_srst : out std_logic;
      M_layer_fifo_in   : out std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);
      M_layer_fifo_wr   : out std_logic;
      M_layer_fifo_rd   : out std_logic;
      M_layer_fifo_out  : in std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);      
      -- BRAM interface
      Bram_clk_o        : out std_logic;
      Bram_pa_addr_o    : out std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
      Bram_pa_data_wr_o : out std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
      Bram_pa_wea_o     : out std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1  downto 0);
      Bram_pb_addr_o    : out std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
      Bram_pb_data_rd_i : in std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
      Bram_pb_rst_o     : out std_logic; -- ACTIVE HIGH!           
      -- AXI Lite dbg interface 
      AXI_lite_reg_addr_i  : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 	-- 31 downto 28 : Memory controller address | 27 downto 24: 32 bit vector address | 23 downto 0: BRAM address
      AXI_lite_reg_data_o  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);      
      -- Status
      S_layer_invalid_block_o : out std_logic);
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

	component EggNet_v1_0_M00_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M_START_COUNT	: integer	:= 32
		);
		port (
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TKEEP	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component EggNet_v1_0_M00_AXIS;
  
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

  signal l1_m_tvalid            : std_logic;
  signal l1_m_tdata_1           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tdata_2           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tdata_3           : std_logic_vector((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal l1_m_tkeep             : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0);
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
  signal l1_bram_pb_rst         : std_logic; -- ACTIVE HIGH!            
  signal l1_invalid_block_size  : std_logic; -- indicates if blocksize is invalid            
  signal axi_lite_reg_addr      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal axi_lite_reg_data      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  
  signal l1_s_conv_data_1       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_2       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_3       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_4       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_5       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_6       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_7       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_8       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_data_9       : std_logic_vector(((DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal l1_s_conv_tvalid       : std_logic;
  signal l1_s_conv_tlast        : std_logic;
  signal l1_s_conv_tready       : std_logic;  

  signal status : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  
begin

-- Instantiation of Axi Bus Interface S00_AXI
EggNet_v1_0_S00_AXI_inst : EggNet_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
    Status_i    => status,
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
  

  L1_Memory_Controller: MemCtrl_3x3
    generic map(                                   
      BRAM_ADDR_WIDTH		      => L1_BRAM_ADDR_WIDTH,
      DATA_WIDTH		          => DATA_WIDTH,
      IN_CHANNEL_NUMBER       => L1_IN_CHANNEL_NUMBER,
      LAYER_HIGHT             => LAYER_HIGHT,
      LAYER_WIDTH             => LAYER_WIDTH,
      AXI4_STREAM_INPUT       => 1,
      MEM_CTRL_ADDR           => 1,
      C_S_AXIS_TDATA_WIDTH    => C_S00_AXIS_TDATA_WIDTH,
      C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH,
      C_S00_AXI_ADDR_WIDTH    => C_S00_AXI_ADDR_WIDTH
      )       
    port map(
      Layer_clk_i		          => s00_axis_aclk,
      Layer_aresetn_i         => s00_axis_aresetn,
      S_layer_tvalid_i	      => s00_axis_tvalid,
      S_layer_tdata_i         => s00_axis_tdata,
      S_layer_tkeep_i         => s00_axis_tkeep,
      S_layer_tlast_i         => s00_axis_tlast,
      S_layer_tready_o        => s00_axis_tready,
      M_layer_tvalid_o	      => l1_m_tvalid        ,
      M_layer_tdata_1_o       => l1_m_tdata_1       ,
      M_layer_tdata_2_o       => l1_m_tdata_2       ,
      M_layer_tdata_3_o       => l1_m_tdata_3       ,
      M_layer_tkeep_o         => l1_m_tkeep         ,
       M_layer_tnewrow_o      => l1_m_tnewrow       ,
      M_layer_tlast_o         => l1_m_tlast         ,
      M_layer_tready_i        => l1_m_tready        ,
      M_layer_fifo_srst       => l1_m_fifo_srst     ,
      M_layer_fifo_in         => l1_m_fifo_in       ,
      M_layer_fifo_wr         => l1_m_fifo_wr       ,
      M_layer_fifo_rd         => l1_m_fifo_rd       ,
      M_layer_fifo_out        => l1_m_fifo_out      ,
      Bram_clk_o              => l1_bram_clk        ,
      Bram_pa_addr_o          => l1_bram_pa_addr    ,
      Bram_pa_data_wr_o       => l1_bram_pa_data_wr ,
      Bram_pa_wea_o           => l1_bram_pa_wea     ,
      Bram_pb_addr_o          => l1_bram_pb_addr    ,
      Bram_pb_data_rd_i       => l1_bram_pb_data_rd ,
      Bram_pb_rst_o           => l1_bram_pb_rst     ,
      AXI_lite_reg_addr_i     => axi_lite_reg_addr    ,
      AXI_lite_reg_data_o     => axi_lite_reg_data    ,
      S_layer_invalid_block_o => l1_invalid_block_size);

  -- ********************* Instantiation of Block RAM ************************************************  
  L1_bram : blk_mem_gen_0
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

  L1_linebuffer: fifo_generator_0 
    port map (
      clk   => s00_axis_aclk,
      srst  => l1_m_fifo_srst     ,
      din   => l1_m_fifo_in       ,
      wr_en => l1_m_fifo_wr       ,
      rd_en => l1_m_fifo_rd       ,
      dout  => l1_m_fifo_out      ,
      full  => open,
      empty => open 
    );    

  L1_shiftregister: ShiftRegister_3x3
    generic map(
      DATA_WIDTH => (DATA_WIDTH*L1_IN_CHANNEL_NUMBER)
    )
    port map(
      Clk_i       => s00_axis_aclk,		 
      nRst_i      => s00_axis_aresetn, 
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
      
  P_Status: process(s00_axi_aclk,s00_axi_aresetn) is 
  begin 
    if s00_axi_aresetn = '0' then 
      status <= (others => '0');
    elsif rising_edge(s00_axi_aclk) then 
      status(status'left downto 0) <= x"FF00FF00";
    end if;
  end process; 


	-- User logic ends

end arch_imp;
