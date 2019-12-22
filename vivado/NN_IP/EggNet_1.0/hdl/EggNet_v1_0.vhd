library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EggNet_v1_0 is
	generic (
		-- Users to add parameters here

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
  --constant S_LAYER_DIM_FEATURES : integer := 1; 
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

  component MemCtrl is
      generic(
        BRAM_ADDR_WIDTH		        : integer := 10;
        BRAM_DATA_WIDTH		        : integer := 8;
        BRAM_ADDR_BLOCK_WIDTH     : integer := 784;
        S_LAYER_DIM_FEATURES      : integer := 1; -- different to M_LAYER if input layer 
        M_LAYER_DIM_FEATURES      : integer := 1;
        
        AXI4_STREAM_INPUT         : boolean := true;
        C_S_AXIS_TDATA_WIDTH	: integer	:= 32
      );
      Port (
        -- Previous layer interface 
        S_layer_clk_i		    : in std_logic;
        S_layer_aresetn_i   : in std_logic;
        S_layer_tvalid_i	: in std_logic;
        S_layer_tdata_i   : in std_logic_vector(S_LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
        S_layer_tkeep_i   : in std_logic_vector((S_LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
        S_layer_tlast_i   : in std_logic;
        S_layer_tready_o  : out std_logic;
        
        -- Next layer interface 
        M_layer_clk_i		    : in std_logic;
        M_layer_aresetn_i   : in std_logic;
        M_layer_tvalid_o	: out std_logic;
        M_layer_tdata_o   : out std_logic_vector(M_LAYER_DIM_FEATURES*BRAM_DATA_WIDTH-1 downto 0);
        M_layer_tkeep_o   : out std_logic_vector((M_LAYER_DIM_FEATURES*BRAM_DATA_WIDTH/8)-1 downto 0);
        M_layer_tlast_o   : out std_logic;
        M_layer_tready_i  : in std_logic;
        
        -- Status
        S_layer_invalid_block_o : out std_logic;
        S_layer_block_done_o : out std_logic

      );
  end component MemCtrl;

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
  
Memory_Controller_0: MemCtrl
  generic map(
    BRAM_ADDR_WIDTH       => 11,
    BRAM_DATA_WIDTH       => 8,
    BRAM_ADDR_BLOCK_WIDTH => 784,
    S_LAYER_DIM_FEATURES  => 4, -- different to M_LAYER if input layer 
    M_LAYER_DIM_FEATURES  => 4,
    
    AXI4_STREAM_INPUT      => true,
    C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
  )
  port map(
    -- Previous layer interface 
    S_layer_clk_i		  => s00_axis_aclk,
    S_layer_aresetn_i => s00_axis_aresetn,
    S_layer_tvalid_i	=> s00_axis_tvalid,
    S_layer_tdata_i   => s00_axis_tdata,
    S_layer_tkeep_i   => s00_axis_tkeep,
    S_layer_tlast_i   => s00_axis_tlast,
    S_layer_tready_o  => s00_axis_tready,
    
    -- Next layer interface 
    M_layer_clk_i		  => m00_axis_aclk,
    M_layer_aresetn_i => m00_axis_aresetn,
    M_layer_tvalid_o	=> m00_axis_tvalid,
    M_layer_tdata_o   => m00_axis_tdata,
    M_layer_tkeep_o   => m00_axis_tkeep,
    M_layer_tlast_o   => m00_axis_tlast,
    M_layer_tready_i  => m00_axis_tready,
    
    -- Status
    S_layer_invalid_block_o => open,
    S_layer_block_done_o    => open);

-- -- Instantiation of Axi Bus Interface M00_AXIS
-- EggNet_v1_0_M00_AXIS_inst : EggNet_v1_0_M00_AXIS
	-- generic map (
		-- C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
		-- C_M_START_COUNT	=> C_M00_AXIS_START_COUNT
	-- )
	-- port map (
		-- M_AXIS_ACLK	=> m00_axis_aclk,
		-- M_AXIS_ARESETN	=> m00_axis_aresetn,
		-- M_AXIS_TVALID	=> m00_axis_tvalid,
		-- M_AXIS_TDATA	=> m00_axis_tdata,
		-- M_AXIS_TKEEP	=> m00_axis_tkeep,
		-- M_AXIS_TLAST	=> m00_axis_tlast,
		-- M_AXIS_TREADY	=> m00_axis_tready
	-- );

	-- Add user logic here
-- m00_axis_tvalid <= s00_axis_tvalid;
-- m00_axis_tdata	<= s00_axis_tdata;
-- m00_axis_tkeep	<= s00_axis_tkeep;
-- m00_axis_tlast	<= s00_axis_tlast;
-- s00_axis_tready <= m00_axis_tready;

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
