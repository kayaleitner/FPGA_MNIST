library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use STD.textio.all;

entity tb_EggNet_v1_0_S00_AXIS is
end tb_EggNet_v1_0_S00_AXIS;

architecture tb of tb_EggNet_v1_0_S00_AXIS is

  constant BRAM_ADDR_WIDTH : integer := 11;
  constant BRAM_DATA_WIDTH : integer := 8;
  constant C_S_AXIS_TDATA_WIDTH : integer := 32;
  
  constant BLOCK_LENGTH : integer := 784;
  constant BLOCKS_TO_TEST : integer := 3;

  component EggNet_v1_0_S00_AXIS
    generic (
      BRAM_ADDR_WIDTH		        : integer := 10;
      BRAM_DATA_WIDTH		        : integer := 8;
      BRAM_ADDR_BLOCK_WIDTH     : integer := 784;
      C_S_AXIS_TDATA_WIDTH	: integer	:= 32);
    port (BRAM_PA_addr_o  : out std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
         BRAM_PA_clk_o   : out std_logic;
         BRAM_PA_dout_o  : out std_logic_vector (BRAM_DATA_WIDTH-1 downto 0);
         BRAM_PA_wea_o   : out std_logic_vector ((BRAM_DATA_WIDTH/8)-1  downto 0);
         Invalid_block_o : out std_logic;
         Block_done_o    : out std_logic; 
         S_AXIS_ACLK     : in std_logic;
         S_AXIS_ARESETN  : in std_logic;
         S_AXIS_TREADY   : out std_logic;
         S_AXIS_TDATA    : in std_logic_vector (C_S_AXIS_TDATA_WIDTH-1 downto 0);
         S_AXIS_TKEEP    : in std_logic_vector ((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
         S_AXIS_TLAST    : in std_logic;
         S_AXIS_TVALID   : in std_logic);
  end component;

  signal bram_addr  : std_logic_vector (BRAM_ADDR_WIDTH-1 downto 0);
  signal bram_clk   : std_logic;
  signal bram_dout  : std_logic_vector (BRAM_DATA_WIDTH-1 downto 0);
  signal bram_wea   : std_logic_vector ((BRAM_DATA_WIDTH/8)-1  downto 0);
  signal bram_block_error : std_logic;
  signal block_done     : std_logic;
  signal s_axis_clk     : std_logic;
  signal nRst  : std_logic;
  signal s_axis_tready   : std_logic;
  signal s_axis_tdata    : std_logic_vector (C_S_AXIS_TDATA_WIDTH-1 downto 0);
  signal s_axis_tkeep    : std_logic_vector ((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
  signal s_axis_tlast    : std_logic;
  signal s_axis_tvalid   : std_logic;

  constant TbPeriod : time := 10 ns;
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';
  
  type   RAM_TYPE IS ARRAY(BLOCK_LENGTH*BLOCKS_TO_TEST-1 downto 0) OF std_logic_vector(BRAM_DATA_WIDTH-1 downto 0); 
  signal AXI_data_buffer      : RAM_TYPE := (others => X"00");
  type   BRAM_TYPE IS ARRAY(BLOCK_LENGTH*2-1 downto 0) OF std_logic_vector(BRAM_DATA_WIDTH-1 downto 0); 
  signal BRAM_data_buffer      : BRAM_TYPE := (others => X"00");
  
  signal start_package    : std_logic;
  
  file file_TEST_DATA : text;
  file file_RESULTS : text;
 

  

begin

  dut : EggNet_v1_0_S00_AXIS
  generic map (
    BRAM_ADDR_WIDTH		    => BRAM_ADDR_WIDTH,		   
    BRAM_DATA_WIDTH		    => BRAM_DATA_WIDTH,		   
    BRAM_ADDR_BLOCK_WIDTH => BLOCK_LENGTH,
    C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_TDATA_WIDTH
  )  
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
      start_package <= '0';

      -- Reset generation
      nRst <= '0';
      wait for 25 ns;
      nRst <= '1';
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
      wait for 10 us;
      -- EDIT Add stimuli here
      wait for 100 * TbPeriod;

      -- Stop the clock and hence terminate the simulation
      TbSimEnded <= '1';
      wait;
  end process;

  AXI_master: process(s_axis_clk,nRst) 
    variable data_counter : integer;
    variable block_counter : integer;
    variable package_active : std_logic;
  begin
    if nRst = '0' then 
      s_axis_tdata <= (others => '0');
      s_axis_tkeep <= (others => '0');
      s_axis_tlast <= '0';
      s_axis_tvalid <= '0';
      
      package_active := '0';
      data_counter := 0;
    elsif rising_edge(s_axis_clk) then 
      if package_active = '1' then 
        s_axis_tvalid <= '1';
        s_axis_tkeep <= (others => '1');
        if s_axis_tready = '1' and s_axis_tvalid = '1' then 
          data_counter := data_counter + 4;
        end if;
        s_axis_tdata <= (AXI_data_buffer(data_counter) & AXI_data_buffer(data_counter+1)  
                        & AXI_data_buffer(data_counter+2) & AXI_data_buffer(data_counter+3));
  
      else 
        if s_axis_tready = '1' then 
          s_axis_tvalid <= '0';
          s_axis_tkeep <= (others => '0');
        end if;  
      end if; 
      if start_package = '1' then 
        package_active := '1';
        data_counter := BLOCK_LENGTH*block_counter;
        block_counter := block_counter +1;
        s_axis_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH*block_counter-4 then 
        package_active := '0';
        s_axis_tlast <= '1';
      else 
        s_axis_tlast <= '0';
      end if; 
    end if;
  end process;

  BRAM_Rec: process(s_axis_clk,nRst) 
    variable data_counter : integer;
    variable block_counter : integer;
    variable package_active : std_logic;
  begin
    if nRst = '0' then 
    elsif rising_edge(s_axis_clk) then 
      if bram_wea = "1" then 
        BRAM_data_buffer(to_integer(unsigned(bram_addr))) <= bram_dout;
      end if;  
    end if;
  end process;
  
   
  read_file: process
    variable v_ILINE      : line;
    variable read_data    : integer;
  begin
    file_open(file_TEST_DATA, "tmp/testdata.txt",  read_mode);
    report "testdata opened successfully"; 
    for i in 0 to BLOCKS_TO_TEST-1 loop
      for j in 0 to BLOCK_LENGTH-1 loop
        readline(file_TEST_DATA, v_ILINE);
        read(v_ILINE, read_data);
        AXI_data_buffer((i*BLOCK_LENGTH)+j) <= std_logic_vector(to_unsigned(read_data,BRAM_DATA_WIDTH));
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
    wait until block_done'event and block_done='1';
    file_open(file_RESULTS, "tmp/results" & integer'image(block_cnt) & ".txt", write_mode);
    for i in 0 to 1 loop
      for j in 0 to BLOCK_LENGTH-1 loop
        write_data := to_integer(unsigned(BRAM_data_buffer((i*BLOCK_LENGTH)+j)));
        write(v_OLINE, write_data);
        writeline(file_RESULTS, v_OLINE); 
      end loop;  
    end loop; 
    if bram_block_error = '1' then 
      write(v_OLINE, 1);
      writeline(file_RESULTS, v_OLINE);
    end if;
    file_close(file_RESULTS);
    report "Write results done"; 
    block_cnt := block_cnt+1;
  end process;
end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_EggNet_v1_0_S00_AXIS of tb_EggNet_v1_0_S00_AXIS is
    for tb
    end for;
end cfg_tb_EggNet_v1_0_S00_AXIS;