library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use STD.textio.all;

entity tb_memctrl is
Generic (
  -- PATH : string := "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/"
  -- Try relative path
  PATH : string := "./"
 );
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
  constant MEM_CTRL_NUMBER         : integer := 4;

  constant DBG_REA_32BIT_WIDTH        : integer := 4;
  constant DBG_BRAM_ADDRESS_WIDTH     : integer := L1_BRAM_ADDR_WIDTH;

  

  constant TbPeriod : time := 10 ns;
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';
  signal start_package : std_logic;

  signal s_tvalid         : std_logic;
  signal s_tdata          : std_logic_vector((C_S00_AXI_DATA_WIDTH)-1 downto 0);
  signal s_tkeep          : std_logic_vector(((C_S00_AXI_DATA_WIDTH)/8)-1 downto 0);
  signal s_tlast          : std_logic;
  signal s_tready         : std_logic;
  signal m_tvalid         : std_logic;
  signal m_tdata          : std_logic_vector((C_M00_AXI_DATA_WIDTH)-1 downto 0);
  signal m_tkeep           : std_logic_vector(((C_M00_AXI_DATA_WIDTH)/8)-1 downto 0);
  signal m_tlast          : std_logic;
  signal m_tready         : std_logic;
  signal interrupt        : std_logic;
  
  type   M_TYPE IS ARRAY(OUTPUT_COUNT-1 downto 0) OF std_logic_vector(DATA_WIDTH-1 downto 0);;
  signal M_buffer      : M_TYPE;  
  signal results_length   : integer;
  signal results_done     : std_logic;
  

begin

 
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
		s00_axi_aclk	  => '0',
		s00_axi_aresetn	=> '0',
		s00_axi_awaddr	=> (others => '0'),
		s00_axi_awprot	=> (others => '0'),
		s00_axi_awvalid	=> '0',
		s00_axi_awready	=> open,
		s00_axi_wdata 	=> (others => '0'),
		s00_axi_wstrb	  => (others => '0'),
		s00_axi_wvalid	=> '0',
		s00_axi_wready	=> open,
		s00_axi_bresp	  => open,
		s00_axi_bvalid	=> open,
		s00_axi_bready	=> '0',
		s00_axi_araddr	=> (others => '0'),
		s00_axi_arprot	=> (others => '0'),
		s00_axi_arvalid	=> '0',
		s00_axi_arready	=> open,
		s00_axi_rdata	  => open,
		s00_axi_rresp	  => open,
		s00_axi_rvalid	=> open,
		s00_axi_rready	=> '0',
		axis_aclk	      => layer_clk		 ,
		axis_aresetn	  => layer_aresetn ,
		s00_axis_tready	=> s_tvalid   ,
		s00_axis_tdata	=> s_tdata    ,
		s00_axis_tkeep	=> s_tkeep    ,
		s00_axis_tlast	=> s_tlast    ,
		s00_axis_tvalid	=> s_tready   ,
		m00_axis_tvalid	=> m_tvalid   ,
		m00_axis_tdata	=> m_tdata    ,
		m00_axis_tkeep	=> m_tkeep     ,
		m00_axis_tlast	=> m_tlast    ,
		m00_axis_tready	=> m_tready   ,
    Res_itrp_o      => interrupt, 
	);
end EggNet_v1_0;

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that layer_clk is really your main clock signal
  layer_clk <= TbClock;

  stimuli : process
  begin
      -- EDIT Adapt initialization as needed
      report "Init Simulation";
      start_package <= '0';
      -- Reset generation
      layer_aresetn <= '0';
      wait for 25 ns;
      report "Start Simulation";
      layer_aresetn <= '1';
      wait for 15 ns;
      start_package <= '1';
      report "send package 1";
      wait for 10 ns;
      start_package <= '0';
      wait for 40 us;
      report "send package 2"; 
      start_package <= '1';
      wait for 10 ns;
      start_package <= '0';
      wait for 40 us;
      report "send package 3";
      start_package <= '1';
      wait for 10 ns;
      start_package <= '0';
      wait for 100 us;
      -- EDIT Add stimuli here
      wait for 5000 * TbPeriod;
      report "End simulation";
      -- Stop the clock and hence terminate the simulation
      TbSimEnded <= '1';
      wait;
  end process;

  AXI_master: process(layer_clk,layer_aresetn)
    variable data_counter : integer;
    variable block_counter : integer;
    variable package_active : std_logic;
  begin
    if layer_aresetn = '0' then
      s_tdata <= (others => '0');
      s_tkeep <= (others => '0');
      s_tvalid <= '0';
      s_tlast <= '0';

      package_active := '0';
      data_counter := 0;
      block_counter := 0;
    elsif rising_edge(layer_clk) then
      if package_active = '1' then
        s_tvalid <= '1';
        s_tkeep <= (others => '1');
        if s_tready = '1'  and s_tvalid = '1' then
          data_counter := data_counter + 4;
        end if;
        s_tdata <= (AXI_data_buffer(data_counter) & AXI_data_buffer(data_counter+1)
                        & AXI_data_buffer(data_counter+2) & AXI_data_buffer(data_counter+3));

      else
        if s_tready = '1' then
          s_tvalid <= '0';
          s_tkeep <= (others => '0');
        end if;
      end if;
      if start_package = '1' then
        package_active := '1';
        data_counter := BLOCK_LENGTH*block_counter;
        s_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH_L1*(block_counter+1)-4 then 
        package_active := '0';
        block_counter := block_counter +1;
        data_counter := 0;
        s_tlast <= '1';
      elsif s_tready = '1' then 
        s_tlast <= '0';
      end if;
    end if;
  end process;

  M_LAYER_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
    variable result_counter : integer;
  begin
    if layer_aresetn = '0' then
      data_counter := 0;
      results_done <= '0';
      result_counter := 0;
      m_tready <= '0';
    elsif rising_edge(layer_clk) then
      m_tready <= '1';
      if m__tvalid = '1' and m_tready = '1' then
        for i in 0 to m_tkeep'length-1
          if m_tkeep(i) = '1' then
            result_counter := result_counter +1;
            M_buffer(result_counter) <= m_tdata(DATA_WIDTH*(i+1) downto DATA_WIDTH*i);
          end if; 
        end loop;  
      end if;
      if m_l1_tlast = '1' then
        results_done <= '1';
        results_length <= result_counter;
        result_counter := 0;
      else
        results_done <= '0';
      end if;
    end if;
  end process;

  write_results: process
    variable v_OLINE      : line;
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin
    wait until results_done'event and results_done='1';
    file_open(file_RESULTS, PATH & "tmp/results_" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to results_length-1 loop
      write_data := to_integer(unsigned(M_buffer(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE);
    end loop;
    file_close(file_RESULTS);
    report "Write results " & integer'image(block_cnt) & " done";
    block_cnt := block_cnt+1;
  end process;

end tb;
