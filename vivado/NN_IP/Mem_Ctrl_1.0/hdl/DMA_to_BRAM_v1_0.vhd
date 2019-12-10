library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA_to_BRAM_v1_0 is
	generic (
		-- Users to add parameters here
    BRAM_ADDR_WIDTH		        : integer := 10;
    BRAM_DATA_WIDTH		        : integer := 8;
    
		IS_INPUT_LAYER            : boolean := false;
    RGB_INPUT                 : boolean := false;
    NEXT_LAYER_IS_CNN         : boolean := true;
    
    LAYER_DIM_ROW		          : integer := 28;
		LAYER_DIM_COL		          : integer := 28;
		LAYER_DIM_FEATURES	      : integer := 4;
    
		USE_MAX_POOLING		        : boolean := false;
		MAX_POOLING_SIZE	        : integer := 2; 
		
		
 
		
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 8;

		-- Parameters of Axi Master Bus Interface M00_AXIS_DMA
		C_M00_AXIS_DMA_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_DMA_START_COUNT	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S00_AXIS_DMA
		C_S00_AXIS_DMA_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
		-- BRAM Interface 
		-- Write (To safe data from input layer)
    BRAM_PA_addr         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    BRAM_PA_clk          : out std_logic;
    BRAM_PA_dout         : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    BRAM_PA_wea          : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
    -- READ (To read data required for ouput layer)
    BRAM_PB_addr         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    BRAM_PB_clk          : out std_logic;
    BRAM_PB_din          : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    BRAM_PB_rst          : out std_logic; 

		-- Source layer interface 
		s_layer_clk_i		    : in std_logic;
    s_layer_aresetn_i   : in std_logic;
		s_layer_tvalid_i	: in std_logic;
		s_layer_tdata_i   : in std_logic_vector(LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
    s_layer_tkeep_i   : in std_logic_vector((LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
		s_layer_tlast_i   : in std_logic;
    s_layer_tready_o  : out std_logic;
    
		-- Next layer interface 
		m_layer_clk_i		    : in std_logic;
    m_layer_aresetn_i   : in std_logic;
		m_layer_tvalid_o	: out std_logic;
		m_layer_tdata_o   : out std_logic_vector(LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
    m_layer_tkeep_o   : out std_logic_vector((LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
		m_layer_tlast_o   : out std_logic;
    m_layer_tready_i  : in std_logic;   
    
    -- Dbg signals 
    Dbg_s00_axis_dma_aclk     : out std_logic;
    Dbg_s00_axis_dma_aresetn  : out std_logic;
    Dbg_m00_axis_dma_tready	  : out std_logic;
    Dbg_s00_axis_dma_tdata	  : out std_logic_vector(C_S00_AXIS_DMA_TDATA_WIDTH-1 downto 0);
    Dbg_s00_axis_dma_tkeep	  : out std_logic_vector((C_S00_AXIS_DMA_TDATA_WIDTH/8)-1 downto 0);
    Dbg_s00_axis_dma_tlast	  : out std_logic;
    Dbg_s00_axis_dma_tvalid	  : out std_logic;
    

    
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

		-- Ports of Axi Master Bus Interface M00_AXIS_DMA
		m00_axis_dma_aclk	: in std_logic;
		m00_axis_dma_aresetn	: in std_logic;
		m00_axis_dma_tvalid	: out std_logic;
		m00_axis_dma_tdata	: out std_logic_vector(C_M00_AXIS_DMA_TDATA_WIDTH-1 downto 0);
		m00_axis_dma_tkeep	: out std_logic_vector((C_M00_AXIS_DMA_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_dma_tlast	: out std_logic;
		m00_axis_dma_tready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS_DMA
		s00_axis_dma_aclk	: in std_logic;
		s00_axis_dma_aresetn	: in std_logic;
		s00_axis_dma_tready	: out std_logic;
		s00_axis_dma_tdata	: in std_logic_vector(C_S00_AXIS_DMA_TDATA_WIDTH-1 downto 0);
		s00_axis_dma_tkeep	: in std_logic_vector((C_S00_AXIS_DMA_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_dma_tlast	: in std_logic;
		s00_axis_dma_tvalid	: in std_logic
	);
end DMA_to_BRAM_v1_0;

architecture arch_imp of DMA_to_BRAM_v1_0 is

	-- component declaration
	component DMA_to_BRAM_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
		);
		port (
		-- Users to add ports here
    Status_i            : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		Training_Mode_o			: out std_logic;
    Update_Weights_o    : out std_logic;
		-- User ports ends    
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
	end component DMA_to_BRAM_v1_0_S00_AXI;

	component DMA_to_BRAM_v1_0_M00_AXIS_DMA is
		generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M_START_COUNT	: integer	:= 32
		);
		port (
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component DMA_to_BRAM_v1_0_M00_AXIS_DMA;

	component DMA_to_BRAM_v1_0_S00_AXIS_DMA is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic
		);
	end component DMA_to_BRAM_v1_0_S00_AXIS_DMA;

  signal training_Mode    :std_logic;
  signal update_Weights   :std_logic;
	signal status		        :std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  
begin

-- Instantiation of Axi Bus Interface S00_AXI
DMA_to_BRAM_v1_0_S00_AXI_inst : DMA_to_BRAM_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
  -- user signals
    Status_i => status,
  	Training_Mode_o	 => training_Mode,
    Update_Weights_o => update_Weights,
  -- AXI  
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

-- -- Instantiation of Axi Bus Interface M00_AXIS_DMA
-- DMA_to_BRAM_v1_0_M00_AXIS_DMA_inst : DMA_to_BRAM_v1_0_M00_AXIS_DMA
	-- generic map (
		-- C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_DMA_TDATA_WIDTH,
		-- C_M_START_COUNT	=> C_M00_AXIS_DMA_START_COUNT
	-- )
	-- port map (
		-- M_AXIS_ACLK	=> m00_axis_dma_aclk,
		-- M_AXIS_ARESETN	=> m00_axis_dma_aresetn,
		-- M_AXIS_TVALID	=> m00_axis_dma_tvalid,
		-- M_AXIS_TDATA	=> m00_axis_dma_tdata,
		-- M_AXIS_TSTRB	=> m00_axis_dma_tstrb,
		-- M_AXIS_TLAST	=> m00_axis_dma_tlast,
		-- M_AXIS_TREADY	=> m00_axis_dma_tready
	-- );

-- -- Instantiation of Axi Bus Interface S00_AXIS_DMA
-- DMA_to_BRAM_v1_0_S00_AXIS_DMA_inst : DMA_to_BRAM_v1_0_S00_AXIS_DMA
	-- generic map (
		-- C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_DMA_TDATA_WIDTH
	-- )
	-- port map (
		-- S_AXIS_ACLK	=> s00_axis_dma_aclk,
		-- S_AXIS_ARESETN	=> s00_axis_dma_aresetn,
		-- S_AXIS_TREADY	=> s00_axis_dma_tready,
		-- S_AXIS_TDATA	=> s00_axis_dma_tdata,
		-- S_AXIS_TSTRB	=> s00_axis_dma_tstrb,
		-- S_AXIS_TLAST	=> s00_axis_dma_tlast,
		-- S_AXIS_TVALID	=> s00_axis_dma_tvalid
	-- );

	-- Add user logic here



  m00_axis_dma_tvalid <= s00_axis_dma_tvalid;
  m00_axis_dma_tdata  <= s00_axis_dma_tdata;
  m00_axis_dma_tkeep  <= s00_axis_dma_tkeep;
  m00_axis_dma_tlast  <= s00_axis_dma_tlast;
  s00_axis_dma_tready <= m00_axis_dma_tready; 
  
  Dbg_s00_axis_dma_aclk     <= s00_axis_dma_aclk;
  Dbg_s00_axis_dma_aresetn  <= s00_axis_dma_aresetn;
  Dbg_m00_axis_dma_tready   <= m00_axis_dma_tready;
  Dbg_s00_axis_dma_tdata	  <= s00_axis_dma_tdata;
  Dbg_s00_axis_dma_tkeep	  <= s00_axis_dma_tkeep;
  Dbg_s00_axis_dma_tlast	  <= s00_axis_dma_tlast;
  Dbg_s00_axis_dma_tvalid	  <= s00_axis_dma_tvalid;
  
  
  Sampling_to_out: process(m_layer_clk_i,m_layer_aresetn_i) is 
  begin 
    if m_layer_aresetn_i = '0' then 
      m_layer_tvalid_o	<= '0';
      m_layer_tdata_o   <= (others => '0');
      m_layer_tkeep_o   <= (others => '0');
      m_layer_tlast_o   <= '0';
    elsif rising_edge(m_layer_clk_i) then 
      m_layer_tvalid_o	<= s00_axis_dma_tvalid;
      m_layer_tdata_o   <= s00_axis_dma_tdata;
      m_layer_tkeep_o   <= s00_axis_dma_tkeep;
      m_layer_tlast_o   <= s00_axis_dma_tlast;
    end if;
  end process;
		 
     
  P_Status: process(s00_axi_aclk,s00_axi_aresetn) is 
  begin 
    if s00_axi_aresetn = '0' then 
      status <= (others => '0');
    elsif rising_edge(s00_axi_aclk) then 
      status(status'left downto 4) <= x"FF00FF0";
      status(3 downto 2) <= "00";
      status(1) <= training_Mode;
      status(2) <= update_Weights;
    end if;
  end process;     

	-- User logic ends

end arch_imp;
