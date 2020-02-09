library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

  component fifo_generator_1 IS
    PORT (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
    );
  END component fifo_generator_1;  


  type  STATES is (INIT,START,FIRST_LINE,POOL); 
  type  FIFO_TYPE IS ARRAY(CHANNEL_NUMBER-1 downto 0) OF std_logic_vector(DATA_WIDTH-1 downto 0); 
  type  BUFFER_TYPE IS ARRAY(CHANNEL_NUMBER-1 downto 0) OF std_logic_vector(DATA_WIDTH-1 downto 0); 
  
  signal state        :STATES;
  
  signal pool_buffer_0  : BUFFER_TYPE;
  signal pool_buffer_1  : BUFFER_TYPE;
  signal fifo_out       : FIFO_TYPE;
  signal fifo_srst      : std_logic;
  signal fifo_wr        : std_logic;
  signal fifo_rd        : std_logic;
  signal output_en      : std_logic;
  signal s_ready        : std_logic;
  signal m_tvalid       : std_logic;
  
begin 

  linebuffer: for i in 0 to CHANNEL_NUMBER-1 generate
    channelbuffer: fifo_generator_1 
      port map (
        clk   => Layer_clk_i,
        srst  => fifo_srst,
        din   => S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)),
        wr_en => fifo_wr,
        rd_en => fifo_rd,
        dout  => fifo_out(i),
        full  => open,
        empty => open 
      );  
  end generate;
  M_layer_tvalid_o <= m_tvalid;
  M_layer_tkeep_o <= (others => '1') when m_tvalid = '1' else (others => '0');
  S_layer_tready_o <= s_ready;
  fifo_wr <= S_layer_tvalid_i and s_ready; 

  pooling: process(Layer_clk_i,Layer_aresetn_i)
    variable col_cnt  : integer; 
    variable row_cnt  : integer;
  begin
    if Layer_aresetn_i = '0' then 
      m_tvalid <= '0';
      M_layer_tdata_o  <= (others => '0');
      M_layer_tlast_o  <= '0';
      for i in 0 to CHANNEL_NUMBER-1 loop
        pool_buffer_0(i) <= (others => '0');
        pool_buffer_1(i) <= (others => '0');
      end loop;  
      s_ready <= '0';  
      fifo_rd <= '0';
      fifo_srst <= '0';
      state <= INIT;
      col_cnt := 0; 
      output_en <= '0';
    elsif rising_edge(Layer_clk_i) then 
      case(state) is 
        when INIT => 
          fifo_srst <= '1';
          s_ready <= '0'; 
          fifo_rd <= '0';
          state <= START; 
          
        when START => 
          fifo_srst <= '0'; 
          s_ready <= '0'; 
          fifo_rd <= '0';          
          state <= FIRST_LINE;
        
        when FIRST_LINE => 
          s_ready <= '1';
          output_en <= '0';
          if fifo_wr = '1' then 
            if col_cnt = LAYER_WIDTH-1 then 
              col_cnt := 0;
              state <= POOL; 
              fifo_rd <= '1';
            else 
              col_cnt := col_cnt +1;
              fifo_rd <= '0';
            end if;  
          end if;

        when POOL => 
          s_ready <= M_layer_tready_i;  
          if fifo_wr = '1' then 
            fifo_rd <= '1';
            output_en <= not output_en;
            for i in 0 to CHANNEL_NUMBER-1 loop
              pool_buffer_0(i) <= fifo_out(i);
              pool_buffer_1(i) <= S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
            end loop;                        
            if output_en = '1' then 
              m_tvalid <= '1';               
              -- Pooling for all channels 
              for i in 0 to CHANNEL_NUMBER-1 loop
                -- starting with S_layer_tdata_i because it is the most critical signal in case of timing 
                if S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) > pool_buffer_0(i) and
                   S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) > fifo_out(i)      and
                   S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) > pool_buffer_1(i) then 
                  -- S_layer_tdata_i is the paximum value 
                  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= 
                                          S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
                -- next fifo_out because it is used some where else and therefore timing is more critical
                elsif fifo_out(i)  > pool_buffer_0(i) and fifo_out(i)  > pool_buffer_1(i) then -- if S_layer_tdata_i is not the maximum value it does not have to be considered in the next stage 
                  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= fifo_out(i);
                -- pool_buffer FF can be freely placed inside the FPGA and therefore timing is not critical
                elsif pool_buffer_0(i) > pool_buffer_1(i) then -- if fifo_out is not the maximum value it does not have to be considered in the next stage
                  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= pool_buffer_0(i);
                else -- if all others are not the maximum pool_buffer_1 is the maximum value. If some values are equal pool_buffer_1 wins (leads maybe to some issues)
                  M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= pool_buffer_1(i);  
                end if;
              end loop;   
              if S_layer_tlast_i = '1' then 
                M_layer_tlast_o <= '1';
                state <= START; 
                fifo_srst <= '1'; 
                s_ready <= '0'; 
                fifo_rd <= '0';                
              end if; 
            else 
              -- If matrix width is odd 
              if S_layer_tlast_i = '1' then 
                M_layer_tlast_o <= '1';
                m_tvalid <= '1'; 
                for i in 0 to CHANNEL_NUMBER-1 loop  
                  if S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) > fifo_out(i) then 
                    M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= 
                                          S_layer_tdata_i(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
                  else 
                    M_layer_tdata_o(((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH)) <= fifo_out(i);
                  end if;
                end loop;  
                state <= START; 
                fifo_srst <= '1'; 
                s_ready <= '0'; 
                fifo_rd <= '0';                 
              else 
                m_tvalid <= '0'; 
              end if;
            end if;
            if col_cnt >= LAYER_WIDTH then 
              row_cnt := row_cnt +1;
              col_cnt := 0;
            else  
              col_cnt := col_cnt +1;
            end if;
          else 
            fifo_rd <= '0';
          end if; 
        when others => 
          state <= INIT;
      end case;    
    end if;
  end process;

end Behavioral;