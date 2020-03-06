library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use STD.textio.all;

entity tb_AXIstreamMaster is
end tb_AXIstreamMaster;

architecture tb of tb_AXIstreamMaster is
  constant ARRAY_SIZE : integer := 100;
  constant OUTPUT_SIZE : integer := 10;
  constant DATA_WIDTH : integer := 8;
  constant AXIS_SIZE : integer := 32;
  constant DATA_PER_STIM : integer := AXIS_SIZE/DATA_WIDTH;
  
  type DATA_ARR : IS ARRAY(ARRAY_SIZE downto 0) OF std_logic_vector((DATA_WIDTH)-1 downto 0); 
  type STIM_ARR : IS ARRAY(ARRAY_SIZE downto 0) OF std_logic_vector((DATA_WIDTH*OUTPUT_SIZE)-1 downto 0); 

  constant TbPeriod       : time := 10 ns;
  
  signal TbClock          : std_logic := '0';
  signal TbSimEnded       : std_logic := '0';
  
  signal data             : DATA_ARR; 
  signal stim_data        : STIM_ARR; 
  signal new_data         : std_logic_vector; 
  signal test_datacounter : integer;
  
  signal layer_clk        : std_logic;
  signal layer_aresetn    : std_logic;
  signal layer_tvalid     : std_logic;
  signal layer_tdata      : std_logic_vector((DATA_WIDTH*OUTPUT_SIZE)-1 downto 0); 
  signal layer_tlast      : std_logic;
  signal layer_tready     : std_logic;
  signal interrupt        : std_logic;
  signal m_axis_tvalid    : std_logic;
  signal m_axis_tdata	    : std_logic_vector(AXI_SIZE-1 downto 0);
  signal m_axis_tkeep	    : std_logic_vector(AXIS_SIZE/8-1 downto 0);
  signal m_axis_tlast	    : std_logic;
  signal m_axis_tready    : std_logic;

begin

  CreateStimuliData: process
  begin 
    for i in 0 to ARRAY_SIZE loop
      data(i) <= std_logic_vector(to_unsigned(i,OUTPUT_SIZE*DATA_WIDTH));
    end loop;
    for i in 0 to ARRAY_SIZE/DATA_PER_STIM loop
      for j in DATA_PER_STIM loop 
        stim_data(i)((j+1)*DATA_WIDTH-1 downto j*DATA_WIDTH) <= data(DATA_PER_STIM*i+j);
      end loop;
    end loop;
  end process;   
  
  Stimuli: process
  begin 
    layer_aresetn <= '0';
    new_data <= '0';
    wait for 20 ns; 
    layer_aresetn <= '1'; 
    wait for 20 ns; 
    new_data <= '1'; 
    wait;
  end process;
  

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that layer_clk is really your main clock signal
  layer_clk <= TbClock;

  AXI_master: process(layer_clk,layer_aresetn)
    variable data_counter : integer;
    variable block_counter : integer;
    variable new_data : std_logic;
  begin
    if layer_aresetn = '0' then
      layer_tdata <= (others => '0');
      layer_tkeep <= (others => '0');
      layer_tvalid <= '0';
      layer_tlast <= '0';

      new_data := '0';
      data_counter := 0;
      block_counter := 0;
    elsif rising_edge(layer_clk) then
      if new_data = '1' then
        layer_tvalid <= '1';
        layer_tkeep <= (others => '1');
        if layer_tready = '1'  and layer_tvalid = '1' then
          data_counter := data_counter + 1;
        end if;
        layer_tdata <= stim_data(data_counter);

      else
        if layer_tready = '1' then
          layer_tvalid <= '0';
          layer_tkeep <= (others => '0');
        end if;
      end if;
      if start_package_l1 = '1' then
        new_data := '1';
        data_counter := BLOCK_LENGTH_L1*block_counter;
        layer_tlast <= '0';
      elsif data_counter >= BLOCK_LENGTH_L1*(block_counter+1)-4 then 
        new_data := '0';
        block_counter := block_counter +1;
        data_counter := 0;
        layer_tlast <= '1';
      elsif layer_tready = '1' then 
        layer_tlast <= '0';
      end if;
    end if;
    test_datacounter <= data_counter;
  end process;
  
  DUT: entity work.AXI_steam_master 
  generic map(
    OUTPUT_NUMBER 		      => OUTPUT_NUMBER,
    DATA_WIDTH    		      => DATA_WIDTH,
		C_M_AXIS_TDATA_o_WIDTH	=> AXIS_SIZE	)
	port map (
		Clk_i	          => layer_clk     ,
		nRst_i	        => layer_aresetn ,
    Layer_tvalid_i	=> layer_tvalid  ,
    Layer_tdata_i   => layer_tdata   ,
    Layer_tlast_i   => layer_tlast   ,
    Layer_tready_o  => layer_tready  ,
    Interrupt       => interrupt     ,
		M_axis_tvalid_o	=> m_axis_tvalid ,
		M_axis_tdata_o	=> m_axis_tdata	 ,
		M_axis_tkeep_o	=> m_axis_tkeep	 ,
		M_axis_tlast_o	=> m_axis_tlast	 ,
		M_axis_tready_i	=> m_axis_tready);

end tb;
