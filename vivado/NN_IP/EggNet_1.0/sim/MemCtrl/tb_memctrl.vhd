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
  
  constant BLOCK_LENGTH : integer := 784;
  constant BLOCKS_TO_TEST : integer := 3;
  
  constant L1_BRAM_ADDR_WIDTH		    : integer := 11; -- maximum = 24 
  constant L1_DATA_WIDTH		        : integer := 8; -- bit depth of one channel  
  constant L1_IN_CHANNEL_NUMBER		  : integer := 1; -- number of input channels 
  constant S_LAYER_DATA_WIDTH		    : integer := 32; 
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
      S_layer_tdata_i   : in std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*(L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)))-1 downto 0);-- if AXI4_STREAM_INPUT = 0 -> (L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) else C_S_AXIS_TDATA_WIDTH
      S_layer_tkeep_i   : in std_logic_vector((((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*(L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)))/8)-1 downto 0);  --only used if next layer is AXI-stream interface 
      S_layer_tlast_i   : in std_logic;
      S_layer_tready_o  : out std_logic;     
      -- Next layer interface 
      M_layer_tvalid_o	: out std_logic;
      M_layer_tdata_1_o : out std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 1 |Vector: trans(1,2,3)
      M_layer_tdata_2_o : out std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 2 |Vector: trans(1,2,3)
      M_layer_tdata_3_o : out std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); --  Output vector element 3 |Vector: trans(1,2,3)
      M_layer_tkeep_o   : out std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0); --only used if next layer is AXI-stream interface (default open)
      M_layer_tnewrow_o : out std_logic;
      M_layer_tlast_o   : out std_logic;
      M_layer_tready_i  : in std_logic;      
      -- M_layer FIFO
      M_layer_fifo_srst : out std_logic;
      M_layer_fifo_in   : out std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);
      M_layer_fifo_wr   : out std_logic;
      M_layer_fifo_rd   : out std_logic;
      M_layer_fifo_out  : in std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);      
      -- BRAM interface
      Bram_clk_o        : out std_logic;
      Bram_pa_addr_o    : out std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
      Bram_pa_data_wr_o : out std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
      Bram_pa_wea_o     : out std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1  downto 0);
      Bram_pb_addr_o    : out std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
      Bram_pb_data_rd_i : in std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
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


  signal layer_clk	            : std_logic;
  signal layer_aresetn          : std_logic;      
  signal s_layer_tvalid         : std_logic;
  signal s_layer_tdata          : std_logic_vector((S_LAYER_DATA_WIDTH)-1 downto 0);
  signal s_layer_tkeep          : std_logic_vector((S_LAYER_DATA_WIDTH/8)-1 downto 0);
  signal s_layer_tlast          : std_logic;
  signal s_layer_tready         : std_logic;     
  signal m_layer_tvalid         : std_logic;
  signal m_layer_tdata_1        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_layer_tdata_2        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_layer_tdata_3        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal m_layer_tkeep          : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*KERNEL_SIZE/8)-1 downto 0);
  signal m_layer_tlast          : std_logic;
  signal m_layer_tnewrow        : std_logic;   
  signal m_layer_tready         : std_logic;   
  signal m_layer_fifo_srst      : std_logic;
  signal m_layer_fifo_in        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);
  signal m_layer_fifo_wr        : std_logic;
  signal m_layer_fifo_rd        : std_logic;
  signal m_layer_fifo_out       : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)*2)-1 downto 0);  
  signal bram_clk               : std_logic;
  signal bram_pa_addr           : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal bram_pa_data_wr        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal bram_pa_wea            : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)/8)-1  downto 0);
  signal bram_pb_addr           : std_logic_vector(L1_BRAM_ADDR_WIDTH-1 downto 0);
  signal bram_pb_data_rd        : std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal bram_pb_rst            : std_logic; -- ACTIVE HIGH!            
  signal axi_lite_reg_addr      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal axi_lite_reg_data      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal s_layer_invalid_block  : std_logic;
  signal bram_block_done     : std_logic;

  signal shiftreg_data_1        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_2        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_3        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_4        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_5        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_6        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_7        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_8        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_data_9        : std_logic_vector(((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER) - 1) downto 0);
  signal shiftreg_tvalid        : std_logic;
  signal shiftreg_tlast         : std_logic;
  signal shiftreg_tready        : std_logic;


  constant TbPeriod : time := 10 ns;
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';
  
  type   RAM_TYPE IS ARRAY(BLOCK_LENGTH*BLOCKS_TO_TEST-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); 
  signal AXI_data_buffer      : RAM_TYPE := (others => X"00");
  type   BRAM_TYPE IS ARRAY(BLOCK_LENGTH*2-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0); 
  signal BRAM_data_buffer      : BRAM_TYPE := (others => X"00"); 
  signal dbg_bram_data_buffer      : BRAM_TYPE := (others => X"00"); 
  type   M_LAYER_TYPE IS ARRAY(BLOCK_LENGTH*3-1 downto 0) OF std_logic_vector((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
  signal M_LAYER_buffer_1      : M_LAYER_TYPE := (others => X"00");
  signal M_LAYER_buffer_2      : M_LAYER_TYPE := (others => X"00");
  signal M_LAYER_buffer_3      : M_LAYER_TYPE := (others => X"00");
  
  signal shiftreg_buffer_1      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_2      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_3      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_4      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_5      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_6      : M_LAYER_TYPE := (others => X"00");  
  signal shiftreg_buffer_7      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_8      : M_LAYER_TYPE := (others => X"00");
  signal shiftreg_buffer_9      : M_LAYER_TYPE := (others => X"00");

  signal start_package    : std_logic;
  signal block_done       : std_logic;
  signal img_length       : integer;  
  signal block_done_sh    : std_logic;
  signal img_length_sh    : integer;
  signal debug            : std_logic; 
  signal debug_done       : std_logic; 
  signal debug_mem_ctrl   : std_logic_vector(DBG_MEM_CTRL_ADDR_WIDTH-1 downto 0);
  signal debug_rea_32bit  : std_logic_vector(DBG_REA_32BIT_WIDTH-1 downto 0);
  signal debug_bram_addr  : std_logic_vector(DBG_BRAM_ADDRESS_WIDTH-1 downto 0);
  
  file file_TEST_DATA : text;
  file file_RESULTS : text;
 
begin

  dut_L1: MemCtrl_3x3
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
    S_layer_tvalid_i	      => s_layer_tvalid       ,
    S_layer_tdata_i         => s_layer_tdata        ,
    S_layer_tkeep_i         => s_layer_tkeep        ,
    S_layer_tlast_i         => s_layer_tlast        ,
    S_layer_tready_o        => s_layer_tready       ,
    M_layer_tvalid_o	      => m_layer_tvalid       ,
    M_layer_tdata_1_o       => m_layer_tdata_1      ,
    M_layer_tdata_2_o       => m_layer_tdata_2      ,
    M_layer_tdata_3_o       => m_layer_tdata_3      ,
    M_layer_tkeep_o         => m_layer_tkeep        ,
    M_layer_tnewrow_o       => m_layer_tnewrow      ,
    M_layer_tlast_o         => m_layer_tlast        ,
    M_layer_tready_i        => m_layer_tready       ,
    M_layer_fifo_srst       => m_layer_fifo_srst    ,
    M_layer_fifo_in         => m_layer_fifo_in      ,
    M_layer_fifo_wr         => m_layer_fifo_wr      ,
    M_layer_fifo_rd         => m_layer_fifo_rd      ,
    M_layer_fifo_out        => m_layer_fifo_out     ,
    Bram_clk_o              => bram_clk             ,
    Bram_pa_addr_o          => bram_pa_addr         ,
    Bram_pa_data_wr_o       => bram_pa_data_wr      ,
    Bram_pa_wea_o           => bram_pa_wea          ,
    Bram_pb_addr_o          => bram_pb_addr         ,
    Bram_pb_data_rd_i       => bram_pb_data_rd      ,
    Bram_pb_rst_o           => bram_pb_rst          ,
    AXI_lite_reg_addr_i     => axi_lite_reg_addr    ,
    AXI_lite_reg_data_o     => axi_lite_reg_data    ,
    S_layer_invalid_block_o => s_layer_invalid_block);

  -- ********************* Instantiation of Block RAM ************************************************  
  Bram_inst : blk_mem_gen_0
  port map (clka  => bram_clk,
            wea   => bram_pa_wea,
            addra => bram_pa_addr,
            dina  => bram_pa_data_wr,
            clkb  => bram_clk,
            addrb => bram_pb_addr,
            doutb => bram_pb_data_rd
  );


  -- ********************* FIFO to buffer 2 lines (3x3 Kernel)   *************************************
  -- Required in order to provide a new Data vector at each clock cycle 
  -- This method triples the performance because only one clock cycle is required to fetch a data vector

  linebuffer: fifo_generator_0 
    port map (
      clk   => layer_clk,
      srst  => m_layer_fifo_srst,
      din   => m_layer_fifo_in,
      wr_en => m_layer_fifo_wr,
      rd_en => m_layer_fifo_rd,
      dout  => m_layer_fifo_out,
      full  => open,
      empty => open 
    );    

  shiftregister: ShiftRegister_3x3
    generic map(
        DATA_WIDTH => (L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)
    )
    port map(
      Clk_i       => layer_clk,		 
      nRst_i      => layer_aresetn, 
      S_data_1_i  => m_layer_tdata_1, 
      S_data_2_i  => m_layer_tdata_2, 
      S_data_3_i  => m_layer_tdata_3, 
      S_tvalid_i  => m_layer_tvalid,
      S_tnewrow_i => m_layer_tnewrow,
      S_tlast_i   => m_layer_tlast, 
      S_tready_o  => m_layer_tready, 
      M_data_1_o  => shiftreg_data_1, 
      M_data_2_o  => shiftreg_data_2, 
      M_data_3_o  => shiftreg_data_3, 
      M_data_4_o  => shiftreg_data_4, 
      M_data_5_o  => shiftreg_data_5, 
      M_data_6_o  => shiftreg_data_6, 
      M_data_7_o  => shiftreg_data_7, 
      M_data_8_o  => shiftreg_data_8, 
      M_data_9_o  => shiftreg_data_9, 
      M_tvalid_o  => shiftreg_tvalid,
      M_tlast_o   => shiftreg_tlast , 
      M_tready_i  => shiftreg_tready 
    );

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that layer_clk is really your main clock signal
  layer_clk <= TbClock;

  stimuli : process
  begin
      -- EDIT Adapt initialization as needed
      start_package <= '0';
      debug <= '0';
      -- Reset generation
      layer_aresetn <= '0';
      wait for 25 ns;
      layer_aresetn <= '1';
      wait for 15 ns;
      start_package <= '1';
      report "send package 1"; 
      wait for 10 ns;
      start_package <= '0';
      wait for 10 us;
      report "send package 1"; 
      start_package <= '1';
      wait for 10 ns;
      start_package <= '0';
      wait for 10 us;
      report "send package 3"; 
      start_package <= '1';
      wait for 10 ns;
      start_package <= '0';
      wait for 100 us;
      -- EDIT Add stimuli here
      wait for 100 * TbPeriod;

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
      s_layer_tdata <= (others => '0');
      s_layer_tkeep <= (others => '0');
      s_layer_tvalid <= '0';
      s_layer_tlast <= '0';
      
      package_active := '0';
      data_counter := 0;
    elsif rising_edge(layer_clk) then 
      if package_active = '1' then 
        s_layer_tvalid <= '1';
        s_layer_tkeep <= (others => '1');
        if s_layer_tready = '1' and s_layer_tvalid = '1' then 
          data_counter := data_counter + 4;
        end if;
        s_layer_tdata <= (AXI_data_buffer(data_counter) & AXI_data_buffer(data_counter+1)  
                        & AXI_data_buffer(data_counter+2) & AXI_data_buffer(data_counter+3));
  
      else 
        if s_layer_tready = '1' then 
          s_layer_tvalid <= '0';
          s_layer_tkeep <= (others => '0');
        end if;  
      end if; 
      if start_package = '1' then 
        package_active := '1';
        data_counter := BLOCK_LENGTH*block_counter;
        block_counter := block_counter +1;
        s_layer_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH*block_counter-4 then 
        package_active := '0';
        data_counter := 0;
        s_layer_tlast <= '1';
      else 
        s_layer_tlast <= '0';
      end if; 
    end if;
  end process;
  
  BRAM_Rec: process(layer_clk,layer_aresetn) 
  begin
    if layer_aresetn = '0' then 
      bram_block_done <= '0';
    elsif rising_edge(layer_clk) then 
      if bram_pa_wea = "1" then 
        BRAM_data_buffer(to_integer(unsigned(bram_pa_addr))) <= bram_pa_data_wr;
      end if;  
      if to_integer(unsigned(bram_pa_addr)) = 784 or to_integer(unsigned(bram_pa_addr)) = 1568 then 
        bram_block_done <= '1'; 
      else 
        bram_block_done <= '0';
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
          dbg_bram_data_buffer(to_integer(data_counter)-1) <= axi_lite_reg_data((L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)-1 downto 0);
        end if;        
        if data_counter > (BLOCK_LENGTH*2) then 
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
  

  M_LAYER_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      block_done <= '0';
    elsif rising_edge(layer_clk) then 
      if m_layer_tvalid = '1' and m_layer_tready = '1' then  
        M_LAYER_buffer_1(data_counter) <= m_layer_tdata_1;
        M_LAYER_buffer_2(data_counter) <= m_layer_tdata_2;
        M_LAYER_buffer_3(data_counter) <= m_layer_tdata_3;
        data_counter := data_counter +1;
      end if;  
      if m_layer_tlast = '1' then 
        block_done <= '1'; 
        img_length <= data_counter;
        data_counter := 0;
      else 
        block_done <= '0';
      end if;
    end if;
  end process;  

  Shiftreg_Rec: process(layer_clk,layer_aresetn) 
    variable data_counter : integer;
  begin
    if layer_aresetn = '0' then 
      data_counter := 0; 
      shiftreg_tready <= '0';
      block_done_sh <= '0';
    elsif rising_edge(layer_clk) then 
      shiftreg_tready <= '1';
      if shiftreg_tvalid = '1' then  
        shiftreg_buffer_1(data_counter) <= shiftreg_data_1;
        shiftreg_buffer_2(data_counter) <= shiftreg_data_2;
        shiftreg_buffer_3(data_counter) <= shiftreg_data_3;
        shiftreg_buffer_3(data_counter) <= shiftreg_data_4;
        shiftreg_buffer_5(data_counter) <= shiftreg_data_5;
        shiftreg_buffer_6(data_counter) <= shiftreg_data_6;
        shiftreg_buffer_7(data_counter) <= shiftreg_data_7;
        shiftreg_buffer_8(data_counter) <= shiftreg_data_8;
        shiftreg_buffer_9(data_counter) <= shiftreg_data_9;
        data_counter := data_counter +1;
      end if;  
      if shiftreg_tlast = '1' then 
        block_done_sh <= '1'; 
        img_length_sh <= data_counter;
        data_counter := 0;
      else 
        block_done_sh <= '0';
      end if;
    end if;
  end process; 



   
  read_file: process
    variable v_ILINE      : line;
    variable read_data    : integer;
  begin
    file_open(file_TEST_DATA, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/testdata.txt",  read_mode);
    report "testdata opened successfully"; 
    for i in 0 to BLOCKS_TO_TEST-1 loop
      for j in 0 to BLOCK_LENGTH-1 loop
        readline(file_TEST_DATA, v_ILINE);
        read(v_ILINE, read_data);
        AXI_data_buffer((i*BLOCK_LENGTH)+j) <= std_logic_vector(to_unsigned(read_data,(L1_DATA_WIDTH*L1_IN_CHANNEL_NUMBER)));
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

  write_file: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until bram_block_done'event and bram_block_done='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/bram" & integer'image(block_cnt) & ".txt", write_mode);
    for i in 0 to 1 loop
      for j in 0 to BLOCK_LENGTH-1 loop
        write_data := to_integer(unsigned(BRAM_data_buffer((i*BLOCK_LENGTH)+j)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    if s_layer_invalid_block = '1' then 
      write(v_OLINE, 1);
      writeline(file_RESULTS, v_OLINE);
    end if;
    file_close(file_RESULTS);
    report "Write bram done"; 
    block_cnt := block_cnt+1;
  end process;
  
  write_file_1: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done'event and block_done='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/m_layer_data1_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length-1 loop
      write_data := to_integer(unsigned(M_LAYER_buffer_1(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/m_layer_data2_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length-1 loop
      write_data := to_integer(unsigned(M_LAYER_buffer_2(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/m_layer_data3_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length-1 loop
      write_data := to_integer(unsigned(M_LAYER_buffer_3(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);    
    report "Write m layer done"; 
    block_cnt := block_cnt+1;
  end process;  

  write_file_shift: process
    variable v_OLINE      : line;  
    variable block_cnt : integer := 0;
    variable write_data : integer := 0;
  begin  
    wait until block_done_sh'event and block_done_sh='1';
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data1_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_1(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data2_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_2(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data3_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_3(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);    
 
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data4_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_4(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data5_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_5(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data6_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_6(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);   
    
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data7_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_7(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data8_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_8(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);
    file_open(file_RESULTS, "C:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/sim/MemCtrl/tmp/shift_data9_b" & integer'image(block_cnt) & ".txt", write_mode);
    for j in 0 to img_length_sh-1 loop
      write_data := to_integer(unsigned(shiftreg_buffer_9(j)));
      write(v_OLINE, write_data);
      writeline(file_RESULTS, v_OLINE); 
    end loop;  
    file_close(file_RESULTS);      
    
    
    
    report "Write shift output done"; 
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
      for j in 0 to BLOCK_LENGTH-1 loop
        write_data := to_integer(unsigned(dbg_bram_data_buffer((i*BLOCK_LENGTH)+j)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    file_close(file_RESULTS);
    report "Write debug done"; 
    block_cnt := block_cnt+1;
  end process;
 


end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_memctrl of tb_memctrl is
    for tb
    end for;
end cfg_tb_memctrl;

