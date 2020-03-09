library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.EggNet_v1_0;

entity tb_toplevel is
end tb_toplevel;

architecture tb of tb_toplevel is

	-- User Parameters
	constant LAYER_HIGHT             : integer := 28;
	constant LAYER_WIDTH             : integer := 28;
	constant DATA_WIDTH              : integer := 6;
	constant L1_IN_CHANNEL_NUMBER	 : integer := 1;    
	constant L2_IN_CHANNEL_NUMBER	 : integer := 16;      
	constant L3_IN_CHANNEL_NUMBER	 : integer := 32;    
	constant MEM_CTRL_NUMBER         : integer := 4;  
	constant OUTPUT_COUNT            : integer := 10; 
	constant PATH                    : string := "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0";
	
	-- Parameters of Axi Slave Bus Interface S00_AXI
	constant C_S00_AXI_DATA_WIDTH	: integer	:= 32;
	constant C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

	-- Parameters of Axi Slave Bus Interface S00_AXIS
	constant C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;

	-- Parameters of Axi Master Bus Interface M00_AXIS
	constant C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
	constant C_M00_AXIS_START_COUNT	: integer	:= 32

	constant TbPeriod : time := 10 ns;
	
	signal TbClock : std_logic := '0';
	signal TbSimEnded : std_logic := '0';

	-- Ports of Axi Slave Bus Interface S00_AXI
	signal s_s00_axi_aclk		: in std_logic;
	signal s_s00_axi_aresetn	: in std_logic;
	signal s_s00_axi_awaddr		: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
	signal s_s00_axi_awprot		: in std_logic_vector(2 downto 0);
	signal s_s00_axi_awvalid	: in std_logic;
	signal s_s00_axi_awready	: out std_logic;
	signal s_s00_axi_wdata		: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal s_s00_axi_wstrb		: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
	signal s_s00_axi_wvalid		: in std_logic;
	signal s_s00_axi_wready		: out std_logic;
	signal s_s00_axi_bresp		: out std_logic_vector(1 downto 0);
	signal s_s00_axi_bvalid		: out std_logic;
	signal s_s00_axi_bready		: in std_logic;
	signal s_s00_axi_araddr		: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
	signal s_s00_axi_arprot		: in std_logic_vector(2 downto 0);
	signal s_s00_axi_arvalid	: in std_logic;
	signal s_s00_axi_arready	: out std_logic;
	signal s_s00_axi_rdata		: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal s_s00_axi_rresp		: out std_logic_vector(1 downto 0);
	signal s_s00_axi_rvalid		: out std_logic;
	signal s_s00_axi_rready		: in std_logic;
    
	-- AXI stream clock and reset 
	signal s_axis_aclk			: in std_logic;
	signal s_axis_aresetn		: in std_logic;    

	-- Ports of Axi Slave Bus Interface S00_AXIS
	signal s_s00_axis_tready	: out std_logic;
	signal s_s00_axis_tdata		: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
	signal s_s00_axis_tkeep		: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal s_s00_axis_tlast		: in std_logic;
	signal s_s00_axis_tvalid	: in std_logic;

	-- Ports of Axi Master Bus Interface M00_AXIS
	signal s_m00_axis_tvalid	: out std_logic;
	signal s_m00_axis_tdata		: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
	signal s_m00_axis_tkeep		: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal s_m00_axis_tlast		: out std_logic;
	signal s_m00_axis_tready	: in std_logic;
    
	-- Interrupts 
	signal s_Res_itrp_o : out std_logic
	
	signal start_package : std_logic;

begin
	-- Clock generation
	TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

	EggNet : entity work.EggNet_v1_0
	generic map (
		-- Users to add parameters here
		LAYER_HIGHT			=> LAYER_HIGHT,
		LAYER_WIDTH			=> LAYER_WIDTH,
		DATA_WIDTH			=> DATA_WIDTH,
		L1_IN_CHANNEL_NUMBER=> L1_IN_CHANNEL_NUMBER, 
		L2_IN_CHANNEL_NUMBER=> L2_IN_CHANNEL_NUMBER,     
		L3_IN_CHANNEL_NUMBER=> L3_IN_CHANNEL_NUMBER,  
		MEM_CTRL_NUMBER		=> MEM_CTRL_NUMBER,
		OUTPUT_COUNT		=> OUTPUT_COUNT,
		PATH 				=> PATH
	) port map (
		s00_axi_aclk		=> s_s00_axi_aclk,
		s00_axi_aresetn		=> s_s00_axi_aresetn,
		s00_axi_awaddr		=> s_s00_axi_awaddr,
		s00_axi_awprot		=> s_s00_axi_awprot,
		s00_axi_awvalid		=> s_s00_axi_awvalid,
		s00_axi_awready		=> s_s00_axi_awready,
		s00_axi_wdata		=> s_s00_axi_wdata,
		s00_axi_wstrb		=> s_s00_axi_wstrb,
		s00_axi_wvalid		=> s_s00_axi_wvalid,
		s00_axi_wready		=> s_s00_axi_wready,
		s00_axi_bresp		=> s_s00_axi_bresp,
		s00_axi_bvalid		=> s_s00_axi_bvalid,
		s00_axi_bready		=> s_s00_axi_bready,
		s00_axi_araddr		=> s_s00_axi_araddr,
		s00_axi_arprot		=> s_s00_axi_arprot,
		s00_axi_arvalid		=> s_s00_axi_arvalid,
		s00_axi_arready		=> s_s00_axi_arready,
		s00_axi_rdata		=> s_s00_axi_rdata,
		s00_axi_rresp		=> s_s00_axi_rresp,
		s00_axi_rvalid		=> s_s00_axi_rvalid,
		s00_axi_rready		=> s_s00_axi_rready,
		axis_aclk			=> s_axis_aclk,
		axis_aresetn		=> s_axis_aresetn,
		s00_axis_tready		=> s_s00_axis_tready,
		s00_axis_tdata		=> s_s00_axis_tdata,
		s00_axis_tkeep		=> s_s00_axis_tkeep,
		s00_axis_tlast		=> s_s00_axis_tlast,
		s00_axis_tvalid		=> s_s00_axis_tvalid,
		m00_axis_tvalid		=> s_m00_axis_tvalid,
		m00_axis_tdata		=> s_m00_axis_tdata,
		m00_axis_tkeep		=> s_m00_axis_tkeep,
		m00_axis_tlast		=> s_m00_axis_tlast,
		m00_axis_tready		=> s_m00_axis_tready,
		Res_itrp_o			=> s_Res_itrp_o
	);

	stimuli : process
	begin
		report "Init Simulation";
		debug <= '0';
		s_s00_axi_aresetn <= '0';
		wait for 25 ns;
		report "Start Simulation";
		s_s00_axi_aresetn <= '1';
		wait for 15 ns;
		TbSimEnded <= '1';
		wait;
	end process;

	AXI_master: process(layer_clk,layer_aresetn)
		variable data_counter : integer;
		variable block_counter : integer;
		variable package_active : std_logic;
	begin
		if layer_aresetn = '0' then
			s_m00_axis_tdata <= (others => '0');
			s_m00_axis_tkeep <= (others => '0');
			s_m00_axis_tvalid <= '0';
			s_m00_axis_tlast <= '0';
			package_active := '0';
			data_counter := 0;
			block_counter := 0;
		elsif rising_edge(layer_clk) then
			if package_active = '1' then
				s_m00_axis_tvalid <= '1';
				s_m00_axis_tkeep <= (others => '1');
				if s_m00_axis_tready = '1'  and s_m00_axis_tvalid = '1' then
					data_counter := data_counter + 4;
				end if;
				s_m00_axis_tdata <= (AXI_data_buffer_l1(data_counter) & AXI_data_buffer_l1(data_counter+1)
							       & AXI_data_buffer_l1(data_counter+2) & AXI_data_buffer_l1(data_counter+3));
			else
				if s_m00_axis_tready = '1' then
					s_m00_axis_tvalid <= '0';
					s_m00_axis_tkeep <= (others => '0');
				end if;
			end if;
			if start_package = '1' then
				package_active := '1';
				data_counter := BLOCK_LENGTH_L1*block_counter;
				s_m00_axis_tlast <= '0';
			elsif data_counter >= BLOCK_LENGTH_L1*(block_counter+1)-4 then 
				package_active := '0';
				block_counter := block_counter +1;
				data_counter := 0;
				s_m00_axis_tlast <= '1';
			elsif s_m00_axis_tready = '1' then 
				s_m00_axis_tlast <= '0';
			end if;
		end if;
		test_datacounter <= data_counter;
	end process;

end tb;
