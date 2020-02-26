library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.STD_FIFO;

entity MaxPooling is
  Generic(
    CHANNEL_NUMBER    : integer := 16;  -- number of output channels of previous layer 
    DATA_WIDTH        : integer := 8;   -- data with of each output channel 
    LAYER_HIGHT       : integer := 28;  -- previous layer matrix hight
    LAYER_WIDTH       : integer := 28  -- previous layer matrix width
 );
  Port (
    -- Clk and reset
    Layer_clk_i		    : in std_logic;
    Layer_aresetn_i   : in std_logic;
    
    -- Previous layer interface 
    S_layer_tvalid_i	: in std_logic;
    S_layer_tdata_i   : in std_logic_vector((DATA_WIDTH*CHANNEL_NUMBER)-1 downto 0); 
    S_layer_tkeep_i   : in std_logic_vector(((DATA_WIDTH*CHANNEL_NUMBER)/8)-1 downto 0);  
    S_layer_tlast_i   : in std_logic;
    S_layer_tready_o  : out std_logic;   
    
    -- Next layer interface 
    M_layer_tvalid_o	: out std_logic;
    M_layer_tdata_o   : out std_logic_vector((DATA_WIDTH*CHANNEL_NUMBER)-1 downto 0); --  Output vector element 1 |Vector: trans(1,2,3)
    M_layer_tkeep_o   : out std_logic_vector(((DATA_WIDTH*CHANNEL_NUMBER)/8)-1 downto 0); --only used if next layer is AXI-stream interface (default open)
    M_layer_tlast_o   : out std_logic;
    M_layer_tready_i  : in std_logic
  );
end MaxPooling;

architecture Behavioral of MaxPooling is

  type  STATES is (INIT,START,FIRST_LINE,POOL); 
  type  FIFO_TYPE IS ARRAY(CHANNEL_NUMBER-1 downto 0) OF std_logic_vector(DATA_WIDTH-1 downto 0); 
  type  BUFFER_TYPE IS ARRAY(CHANNEL_NUMBER-1 downto 0) OF std_logic_vector(DATA_WIDTH-1 downto 0); 
  
  signal state, state_next        :STATES;
  
  signal pool_buffer_0  : BUFFER_TYPE;
  signal pool_buffer_1  : BUFFER_TYPE;
  signal pool_buffer_2  : BUFFER_TYPE;
  signal fifo_out       : FIFO_TYPE;
  signal fifo_srst      : std_logic;
  signal fifo_wr        : std_logic;
  signal fifo_rd        : std_logic;
  signal output_en      : std_logic;
  signal s_ready        : std_logic;
  signal m_tvalid       : std_logic;
  signal last : std_logic;
  
begin 

  linebuffer: for i in 0 to CHANNEL_NUMBER-1 generate
    channelbuffer: entity work.STD_FIFO 
      port map (
        Clk_i   => Layer_clk_i,
        Rst_i  => fifo_srst,
        Data_i   => S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)),
        WriteEn_i => fifo_wr,
        ReadEn_i => fifo_rd,
        Data_o  => fifo_out(i),
        Full_o  => open,
        Empty_o => open 
      );  
  end generate;
  M_layer_tvalid_o <= m_tvalid;
  M_layer_tkeep_o <= (others => '1') when m_tvalid = '1' else (others => '0');
  S_layer_tready_o <= s_ready and not S_layer_tlast_i;

  pooling: process(state, S_layer_tvalid_i, S_layer_tdata_i, S_layer_tkeep_i, S_layer_tlast_i, M_layer_tready_i)
    variable col_cnt  : integer; 
    variable row_cnt  : integer;
    variable opt1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable opt2 : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable opt3 : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable opt4 : std_logic_vector(DATA_WIDTH-1 downto 0);
  begin
    if Layer_aresetn_i = '0' then 
      m_tvalid <= '0';
      M_layer_tdata_o  <= (others => '0');
      M_layer_tlast_o  <= '0';
      for i in 0 to CHANNEL_NUMBER-1 loop
        pool_buffer_0(i) <= (others => '0');
        pool_buffer_1(i) <= (others => '0');
		pool_buffer_2(i) <= (others => '0');
      end loop;  
      s_ready <= '0';  
      fifo_rd <= '0';
      fifo_srst <= '0';
      col_cnt := 0; 
    else
      M_layer_tlast_o  <= '0';
      M_layer_tdata_o  <= (others => '0');
      m_tvalid <= '0';
	  state_next <= state;
      case(state) is 
        when INIT => 
          fifo_srst <= '1';
          s_ready <= '0'; 
          fifo_rd <= '0';
          state_next <= START; 
          
        when START => 
          fifo_srst <= '0'; 
          s_ready <= '0'; 
          fifo_rd <= '0';     
		  col_cnt := 0;
          state_next <= FIRST_LINE;
        
        when FIRST_LINE => 
          s_ready <= '1';
          if fifo_wr = '1' then 
		    if col_cnt = LAYER_WIDTH-1 then 
              col_cnt := 0;
              state_next <= POOL; 
            else 
              fifo_rd <= '0';
              col_cnt := col_cnt +1;
            end if;  
          end if;

        when POOL => 
          s_ready <= M_layer_tready_i;
          fifo_rd <= S_layer_tvalid_i;
          if fifo_wr = '1' then
            for i in 0 to CHANNEL_NUMBER-1 loop
              pool_buffer_0(i) <= fifo_out(i);
              pool_buffer_1(i) <= S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
			  pool_buffer_2(i) <= pool_buffer_1(i);
            end loop;                        
            if output_en = '1' or last = '1' then 
              m_tvalid <= '1';
              -- Pooling for all channels 
              for i in 0 to CHANNEL_NUMBER-1 loop
			    opt1 := pool_buffer_2(i);
			    opt2 := fifo_out(i);
			    opt3 := pool_buffer_0(i);
			    opt4 := pool_buffer_1(i);
                if unsigned(opt1) > unsigned(opt2) and unsigned(opt1) > unsigned(opt3) and unsigned(opt1) > unsigned(opt4) then
				  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= opt1;
                elsif unsigned(opt2) > unsigned(opt3) and unsigned(opt2) > unsigned(opt4) and unsigned(opt2) > unsigned(opt1) then
				  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= opt2;
                elsif unsigned(opt3) > unsigned(opt4) and unsigned(opt3) > unsigned(opt1) and unsigned(opt3) > unsigned(opt2) then
				  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= opt3;
				else
				  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= opt4;
				end if;
              end loop;
              if last = '1' then 
                M_layer_tlast_o <= '1';
                state_next <= START; 
                fifo_srst <= '1'; 
                s_ready <= '0';      
              end if; 
            end if;
            if col_cnt >= LAYER_WIDTH then 
              row_cnt := row_cnt +1;
              col_cnt := 0;
            else  
              col_cnt := col_cnt +1;
            end if;
		  else 
            for i in 0 to CHANNEL_NUMBER-1 loop
              pool_buffer_1(i) <= S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
		    end loop;
          end if; 
        when others => 
          state_next <= INIT;
      end case;    
    end if;
  end process;
  
  sync : process(Layer_clk_i,Layer_aresetn_i)
  begin
    fifo_wr <= S_layer_tvalid_i and s_ready; 
    if Layer_aresetn_i = '0' then
	  state <= INIT;
	  last <= '0';
      output_en <= '0';
	elsif rising_edge(Layer_clk_i) then
      if state = POOL then 
        output_en <= not output_en;
	  else
        output_en <= '0';
	  end if;
	  if state = FIRST_LINE and state_next = POOL then
        output_en <= '1';
	  end if;
	  state <= state_next;
	  last <= S_layer_tlast_i;
	end if;
  end process;

end Behavioral;