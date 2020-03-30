library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MemCtrl_c2d is
  Generic(
    BRAM_ADDR_WIDTH		        : integer range 1 to 24   := 10; -- maximum = 24 
    DATA_WIDTH		            : integer := 8; -- channel number * bit depth maximum = 512    
    IN_CHANNEL_NUMBER		      : integer range 1 to 256 := 1; 
    LAYER_HIGHT               : integer range 1 to 4096 := 28; -- Layer hight of next layer 
    LAYER_WIDTH               : integer range 1 to 4096 := 28; -- Layer width of next layer     
    AXI4_STREAM_INPUT         : integer range 0 to 1 := 0; -- integer to calculate S_LAYER_DATA_WIDTH 
    MEM_CTRL_ADDR             : integer := 255; 
    C_S_AXIS_TDATA_WIDTH	    : integer	:= 32;
    C_S00_AXI_DATA_WIDTH	    : integer	:= 32
  );
  Port (
    -- Clk and reset
    Layer_clk_i		    : in std_logic;
    Layer_aresetn_i   : in std_logic;

    -- Previous layer interface
    S_layer_tvalid_i	: in std_logic;
    S_layer_tdata_i   : in std_logic_vector((DATA_WIDTH*IN_CHANNEL_NUMBER)-1 downto 0); -- if AXI4_STREAM_INPUT = 0 -> (DATA_WIDTH*IN_CHANNEL_NUMBER) else C_S_AXIS_TDATA_WIDTH
    S_layer_tlast_i   : in std_logic;
    S_layer_tready_o  : out std_logic;

    -- Next layer interface
    M_layer_tvalid_o	: out std_logic;
    M_layer_tdata_o   : out std_logic_vector((DATA_WIDTH)-1 downto 0); --  Output vector element 1 |Vector: trans(1,2,3)
    M_layer_tlast_o   : out std_logic;
    M_layer_tready_i  : in std_logic;
    
    -- BRAM interface
    Bram_clk_o        : out std_logic;
    Bram_pa_addr_o    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    Bram_pa_data_wr_o : out std_logic_vector((DATA_WIDTH*IN_CHANNEL_NUMBER)-1 downto 0);
    Bram_pa_wea_o     : out std_logic_vector(((DATA_WIDTH*IN_CHANNEL_NUMBER)/8)-1  downto 0);
    Bram_pb_addr_o    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    Bram_pb_data_rd_i : in std_logic_vector((DATA_WIDTH*IN_CHANNEL_NUMBER)-1 downto 0);
    
    -- AXI Lite dbg interface 
    Dbg_bram_addr_i  : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); -- BRAM address 
    Dbg_bram_addr_o  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); -- BRAM address to double check if address fits to data 
    Dbg_bram_data_o  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); -- 32 bit vector tile 
    Dbg_32bit_select_i: in std_logic_vector(3 downto 0); 
    Dbg_enable_i     : in std_logic;   
    -- Status
    Layer_properties_o : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    Status_o : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) -- (1 downto 0) --> WR_STATE 
                                                                     -- (3 downto 2) --> RD_STATE
                                                                     -- (4) --> wr_invalid_block
                                                                     -- (7 downto 5) --> Next Layer type :  000 : Dense
                                                                     --                                     001 : Conv 1x1 
                                                                     --                                     010 : Conv 3x3 
                                                                     --                                     011 : Conv 5x5 
                                                                     --                                     100 : Average pooling
                                                                     -- (15 downto 8) --> Address of Memory controller 
                                                                     -- (16) --> Debug error; 
                                                                     -- (17) --> Debug active;
  );
end MemCtrl_c2d;

architecture Behavioral of MemCtrl_c2d is

constant BRAM_ADDR_BLOCK_WIDTH      : integer := LAYER_HIGHT * LAYER_WIDTH;
constant BRAM_DATA_WIDTH            : integer := (DATA_WIDTH*IN_CHANNEL_NUMBER);
constant DBG_MEM_CTRL_ADDR_WIDTH    : integer := 4;
constant DBG_REA_32BIT_WIDTH        : integer := 4;
constant DBG_BRAM_ADDRESS_WIDTH     : integer := 24;
constant DBG_MAX_REA                : integer := BRAM_DATA_WIDTH/C_S00_AXI_DATA_WIDTH;

type RD_STATES is (START,MOVE, WAIT_CY, SERIALIZE, STOP);
type DBG_STATES is (IDLE,GET_DATA,WAIT_CY);
type WR_STATES is (START,MOVE); 
type WR_BL_STATES is (IDLE,BLOCK0,BLOCK1,DEBUG); 
type RD_BL_STATES is (IDLE,BLOCK0,BLOCK1,DEBUG); 

type TYPE_32BIT_ARRAY is array (0 to DBG_MAX_REA) of std_logic_vector((C_S_AXIS_TDATA_WIDTH-1)downto 0);

signal rd_state         :RD_STATES;
signal wr_state         :WR_STATES;
signal dbg_state         :DBG_STATES;
signal rd_bl_state      :RD_BL_STATES;
signal wr_bl_state      :WR_BL_STATES;

signal mem_rd_addr      :std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal m_layer_tvalid   :std_logic;
signal m_newrow         :std_logic;

signal dbg_active_rd    :std_logic;
signal dbg_active_wr    :std_logic;
signal dbg_active       :std_logic;
signal dbg_mem_addr     :std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal dbg_memctrl_addr :std_logic_vector(DBG_MEM_CTRL_ADDR_WIDTH-1 downto 0);

signal dbg_rea32_addr   :std_logic_vector(DBG_REA_32BIT_WIDTH-1 downto 0);
signal dbg_axi_ram_addr :std_logic_vector(DBG_BRAM_ADDRESS_WIDTH-1 downto 0);
signal dbg_32bit_data   :std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
signal dbg_bram_addr_out:std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal dbg_error        :std_logic;

signal next_block_read  :std_logic_vector(1 downto 0); -- 00 wait, 01 block 0, 10 block 1
signal next_block_write :std_logic_vector(1 downto 0); -- 00 wait, 01 block 0, 10 block 1
signal rd_block_done    :std_logic;
signal rd_block_done_R  :std_logic;
signal wr_block_done    :std_logic;
signal wr_block_done_R  :std_logic;
signal block_full       :std_logic_vector(1 downto 0);
signal wr_invalid_block :std_logic;

signal serialize_cnt_sig  :integer;

begin

-- ********************* Layer and status informaiton **********************************************
Layer_properties_o(11 downto 0) <= std_logic_vector(to_unsigned(LAYER_WIDTH-1,12)); -- Since 0 size is not possible 0 means size 1 
Layer_properties_o(23 downto 12) <= std_logic_vector(to_unsigned(LAYER_HIGHT-1,12)); -- Since 0 size is not possible 0 means size 1
Layer_properties_o(31 downto 24) <= std_logic_vector(to_unsigned(IN_CHANNEL_NUMBER-1,8)); -- Since 0 size is not possible 0 means size 1; 
Status_o(7 downto 5) <= "000"; -- ID for conv3x3 
Status_o(15 downto 8) <=  std_logic_vector(to_unsigned(MEM_CTRL_ADDR,8));
Status_o(16) <= dbg_error;
Status_o(17) <= dbg_active;
Status_o(31 downto 18) <= (others => '0'); -- Add usefull informaiton

-- ********************* Block control *************************************************************
BlockControl: process(Layer_clk_i,Layer_aresetn_i)
begin
  if Layer_aresetn_i = '0' then
    next_block_read  <= "00";
    next_block_write <= "01";
    block_full <= "00";
    rd_bl_state <= IDLE;
    wr_bl_state <= BLOCK0;
    rd_block_done_R <= '1';
    wr_block_done_R <= '1';
    Status_o (3 downto 0) <= (others => '0');
    dbg_active_rd <= '0';  
    dbg_active_wr <= '0';  
    
  elsif rising_edge(Layer_clk_i) then 
    rd_block_done_R <= '0';
    wr_block_done_R <= '0';  
    case wr_bl_state is 
      when IDLE =>
        dbg_active_rd <= '0';
        Status_o(1 downto 0) <= "00"; 
        next_block_write <= "00";
        if Dbg_enable_i = '1' then 
          wr_bl_state <= DEBUG;        
        elsif block_full(0) = '0' then 
          wr_bl_state <= BLOCK0;         
        elsif block_full(1) = '0' then 
          wr_bl_state <= BLOCK1; 
        end if;
        
      when BLOCK0 => 
        Status_o(1 downto 0) <= "01";
        if wr_block_done_R = '0' then 
          next_block_write <= "00";  
        else 
          next_block_write <= "01";  
        end if;
        if wr_block_done = '1' and wr_block_done_R = '0' then 
          block_full(0) <= '1';
          if block_full(1) = '0' then
            wr_bl_state <= BLOCK1;
          else
            wr_bl_state <= IDLE;
          end if; 
        elsif Dbg_enable_i = '1' and wr_block_done = '1' then
          wr_bl_state <= DEBUG;
          next_block_write <= "00";
          Status_o(1 downto 0) <= "11";
        end if;
        
      when BLOCK1 => 
        Status_o(1 downto 0) <= "10";
         if wr_block_done_R = '0' then 
          next_block_write <= "00";  
        else 
          next_block_write <= "10";
        end if;  
        if wr_block_done = '1' and wr_block_done_R = '0' then 
          block_full(1) <= '1';
          if block_full(0) = '0' then
            wr_bl_state <= BLOCK0;
          else
            wr_bl_state <= IDLE;
          end if;
        elsif Dbg_enable_i = '1' and wr_block_done = '1' then
          wr_bl_state <= DEBUG;
          next_block_write <= "00";
          Status_o(1 downto 0) <= "11";
        end if; 
        
      when DEBUG => 
        Status_o(1 downto 0) <= "11";
        next_block_write <= "00";
        dbg_active_rd <= '1';
        if Dbg_enable_i = '0' then 
          wr_bl_state <= IDLE;
        end if;
      when others => 
        wr_bl_state <= IDLE;
    end case;

    case rd_bl_state is
      when IDLE =>
        next_block_read <= "00";
        Status_o(3 downto 2) <= "00";
        if Dbg_enable_i = '1' then 
          rd_bl_state <= DEBUG;
          Status_o(3 downto 2) <= "11";
        elsif block_full(0) = '1' then 
          Status_o(3 downto 2) <= "01";
          rd_bl_state <= BLOCK0;
        elsif block_full(1) = '1' then 
          Status_o(3 downto 2) <= "10";
          rd_bl_state <= BLOCK1; 
        end if;
      when BLOCK0 =>
        if rd_block_done_R = '0' then
          next_block_read <= "00"; -- to avoid to use the same block twice
        else
          next_block_read <= "01";
        end if;
        if rd_block_done = '1' and rd_block_done_R = '0' then
          block_full(0) <= '0';
          if block_full(1) = '1' then
            rd_bl_state <= BLOCK1;
          else
            rd_bl_state <= IDLE;
          end if;
        end if;
      when BLOCK1 =>
        if rd_block_done_R = '0' then
          next_block_read <= "00"; -- to avoid to use the same block twice
        else
          next_block_read <= "10";
        end if;
        if rd_block_done = '1' and rd_block_done_R = '0' then
          block_full(1) <= '0';
          if block_full(0) = '1' then
            rd_bl_state <= BLOCK0;
          else
            rd_bl_state <= IDLE;
          end if;  
        end if;   
      when DEBUG => 
        next_block_read <= "00";
        dbg_active_wr <= '1';
        if Dbg_enable_i = '0' then 
          rd_bl_state <= IDLE;
        end if;
        
      when others => 
        rd_bl_state <= IDLE;        
    end case; 
    rd_block_done_R <= rd_block_done;
    wr_block_done_R <= wr_block_done;
  end if;
end process;

-- ********************* Read block RAM (debug off) ************************************************
M_layer_tvalid_o <= m_layer_tvalid;
Status_o(4) <= wr_invalid_block;

DefaultRead: process(Layer_clk_i, Layer_aresetn_i)
  variable state_cnt   : integer := 0;
  variable position    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, BRAM_ADDR_WIDTH);
  variable rd_pixel_row_cnt : integer := 0;
  variable serialize_cnt  : integer := 0;
begin
  if Layer_aresetn_i = '0' then
    mem_rd_addr <= (others => '0');
    M_layer_tlast_o <= '0';
    m_layer_tvalid <= '0';
    M_layer_tdata_o <= (others => '0');

    rd_state <= START;
    rd_block_done <= '1'; -- indicate if block is

    position := to_unsigned(0, position'length);
    state_cnt := 0;
    rd_pixel_row_cnt := 0;
    serialize_cnt := 0;
    
  elsif rising_edge(Layer_clk_i) then   
    case rd_state is 
    
      when START => -- If data is available transfer starts and reset fifo 
        if next_block_read(0) = '1' then 
          position := to_unsigned(0, position'length);
          mem_rd_addr <= (others => '0');
          rd_state <= WAIT_CY;
          rd_block_done <= '0';
        elsif next_block_read(1) = '1' then
          position := to_unsigned(BRAM_ADDR_BLOCK_WIDTH,position'length);
          mem_rd_addr <= std_logic_vector(position);
          rd_state <= WAIT_CY;
          rd_block_done <= '0';
        end if;
        state_cnt := 0;
        rd_pixel_row_cnt := 0;
        m_layer_tvalid <= '0';
        M_layer_tlast_o <= '0';
        
      when WAIT_CY => -- Required because fetching data from BRAM takes 2 cycles (pipelined) 
        if IN_CHANNEL_NUMBER = 1 then 
          position := position+1;
          mem_rd_addr <= std_logic_vector(position);
        end if;   
        if state_cnt = 1 then 
          rd_state <= MOVE;
          state_cnt := 0;
        else
          state_cnt := state_cnt+1;
        end if;        
      when MOVE =>            

        M_layer_tdata_o <= Bram_pb_data_rd_i(DATA_WIDTH-1 downto 0);    
        m_layer_tvalid <= '1';             
        -- Positon count 
        if M_layer_tready_i = '1' then -- Wait till slave is ready
          
          -- Spezial treatment of 1 or 2 input channels because of BRAM structure (Hopefully optimized so that the unused cases don't require extra array
          if IN_CHANNEL_NUMBER = 2 then -- neccassary since BRAM needs to cycles to provide new data 
            rd_state <= SERIALIZE; 
            serialize_cnt := serialize_cnt+1;
            if position < 2*BRAM_ADDR_BLOCK_WIDTH-1 then
              position := position+1;
            end if;
            mem_rd_addr <= std_logic_vector(position);
          elsif IN_CHANNEL_NUMBER = 1 then 
            if state_cnt < BRAM_ADDR_BLOCK_WIDTH-1 then
              state_cnt := state_cnt +1;
            else
              rd_state <= START;
              M_layer_tlast_o <= '1';
              rd_block_done <= '1';
              serialize_cnt := 0;
              state_cnt := 0;
            end if;          
            if position < 2*BRAM_ADDR_BLOCK_WIDTH-1 then
              position := position+1;
            end if;
            mem_rd_addr <= std_logic_vector(position);          
          else
            rd_state <= SERIALIZE; 
            serialize_cnt := serialize_cnt+1;
          end if; 
        end if;
      
      when SERIALIZE => 
      
          M_layer_tdata_o <= Bram_pb_data_rd_i((DATA_WIDTH*(serialize_cnt+1))-1 downto DATA_WIDTH*serialize_cnt);  
          m_layer_tvalid <= '1';
          
          if M_layer_tready_i = '1' then -- Wait till slave is ready
            serialize_cnt := serialize_cnt+1;
            if serialize_cnt = IN_CHANNEL_NUMBER-2 then
              if position < 2*BRAM_ADDR_BLOCK_WIDTH-1 then
                position := position+1;
              end if;
              mem_rd_addr <= std_logic_vector(position);
            elsif serialize_cnt = IN_CHANNEL_NUMBER then 
              if state_cnt < BRAM_ADDR_BLOCK_WIDTH-1 then
                state_cnt := state_cnt +1;
                serialize_cnt := 0;
                rd_state <= MOVE;
              else
                rd_state <= START;
                M_layer_tlast_o <= '1';
                rd_block_done <= '1';
                serialize_cnt := 0;
                state_cnt := 0;
              end if;          
            end if;
          end if;

      when others =>
        rd_state <= START;
    end case;
    serialize_cnt_sig <= serialize_cnt;
  end if;
end process;

-- ********************* Write block RAM (default) *************************************************
Bram_clk_o <= Layer_clk_i;

DefaultWriteP: process(Layer_clk_i, Layer_aresetn_i) 
  variable state_cnt   : integer := 0;
  variable position    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, BRAM_ADDR_WIDTH);
begin
  if Layer_aresetn_i = '0' then 
    
    Bram_pa_addr_o <= (others => '0');
    Bram_pa_data_wr_o <= (others => '0');
    Bram_pa_wea_o <= (others => '0');
    
    S_layer_tready_o <= '0';
    
    wr_state <= START;
    wr_block_done <= '1';
    
    position := to_unsigned(0, position'length);
    state_cnt := 0;
    wr_invalid_block <= '0';
  elsif rising_edge(Layer_clk_i) then
    case wr_state is

      when START => -- If data is available transfer starts
        if next_block_write(0) = '1' then
          position := to_unsigned(0, position'length);
          Bram_pa_addr_o <= (others => '0');
          S_layer_tready_o <= '1';
          wr_state <= MOVE;
        elsif next_block_write(1) = '1' then
          position := to_unsigned(BRAM_ADDR_BLOCK_WIDTH,position'length);
          Bram_pa_addr_o <= std_logic_vector(position);
          S_layer_tready_o <= '1';
          wr_state <= MOVE;
        else
          S_layer_tready_o <= '0';
        end if;
        Bram_pa_data_wr_o <= (others => '0');
        Bram_pa_wea_o <= (others => '0');
        state_cnt := 0;
        
      when MOVE => 
        if S_layer_tvalid_i = '1' then 
          wr_block_done <= '0';
          Bram_pa_data_wr_o <= S_layer_tdata_i;
          Bram_pa_addr_o <= std_logic_vector(position);
          Bram_pa_wea_o <= (others => '1');
          position := position+1;
          state_cnt := state_cnt+1;
        else
          Bram_pa_wea_o <= (others => '0');
        end if;
        if state_cnt >= BRAM_ADDR_BLOCK_WIDTH then
          wr_state <= START;
          S_layer_tready_o <= '0';
          state_cnt := 0;
          wr_block_done <= '1'; 
          wr_invalid_block <= not S_layer_tlast_i;
        end if;
        if wr_block_done = '1' and dbg_active = '1' then 
          wr_state <= START;
        end if;
      when others => 
        wr_state <= START;
    end case;
  end if;
end process;

-- ********************* Read from memory address using AXI-lite interface (debug on) **************
dbg_active <= dbg_active_rd and dbg_active_wr;
Dbg_bram_data_o <= dbg_32bit_data when dbg_active = '1' else (others => 'Z'); 
Dbg_bram_addr_o(BRAM_ADDR_WIDTH-1 downto 0) <= dbg_bram_addr_out when dbg_active = '1' else (others => 'Z'); 
Dbg_bram_addr_o(C_S_AXIS_TDATA_WIDTH-1 downto BRAM_ADDR_WIDTH) <= (others => '0') when dbg_active = '1' else (others => 'Z');
Bram_pb_addr_o <= dbg_mem_addr when dbg_active = '1' else mem_rd_addr;

-- Offers the possability to read from the bram 
DbgMemory: process(Layer_clk_i, Layer_aresetn_i) 
  variable dbg_32bit_array : TYPE_32BIT_ARRAY;
begin 
  if Layer_aresetn_i = '0' then 
    dbg_32bit_data <= (others => '0');
    dbg_state <= IDLE;
    dbg_mem_addr <= (others => '0');
    dbg_bram_addr_out <= (others => '1');
    dbg_error <= '0';
  elsif rising_edge(Layer_clk_i) then 
    case dbg_state is 
      when IDLE => 
        dbg_bram_addr_out <= (others => '1');
        if dbg_active = '1' then 
          if next_block_read(0) = '1' then 
            dbg_mem_addr <= Dbg_bram_addr_i(BRAM_ADDR_WIDTH-1 downto 0); 
            dbg_error <= '0';
            dbg_state <= WAIT_CY;
          elsif next_block_read(1) = '1' then 
            dbg_mem_addr <= std_logic_vector(unsigned(Dbg_bram_addr_i(BRAM_ADDR_WIDTH-1 downto 0))+to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH)); 
            dbg_error <= '0';    
            dbg_state <= WAIT_CY;            
          else 
            dbg_error <= '1';
          end if;
        end if;         
      when WAIT_CY =>
        -- BRAM read access needs 2 clock cycles 
        dbg_state <= GET_DATA;
          
      when GET_DATA => 
        -- Extract 32 bit vectors of BRAM 
        for i in 0 to DBG_MAX_REA loop
          if i < DBG_MAX_REA then 
            dbg_32bit_array(i) := Bram_pb_data_rd_i((C_S_AXIS_TDATA_WIDTH + (i*C_S_AXIS_TDATA_WIDTH)-1) downto (i*C_S_AXIS_TDATA_WIDTH));
          else 
            dbg_32bit_array(i)((BRAM_DATA_WIDTH - (i*C_S_AXIS_TDATA_WIDTH)-1) downto 0) := Bram_pb_data_rd_i(BRAM_DATA_WIDTH-1 downto (i*C_S_AXIS_TDATA_WIDTH));
          end if;
        end loop;
        -- Select 32 bit vector tile 
        if to_integer(unsigned(Dbg_32bit_select_i)) <= DBG_MAX_REA then 
          dbg_32bit_data <= dbg_32bit_array(to_integer(unsigned(Dbg_32bit_select_i)));
        else 
          dbg_32bit_data <= dbg_32bit_array(DBG_MAX_REA);
        end if;    
        -- Update output address to indicate that read is successfully done 
        if next_block_read(0) = '1' then 
            dbg_bram_addr_out(BRAM_ADDR_WIDTH-1 downto 0) <= dbg_mem_addr; 
            dbg_error <= '0';
          elsif next_block_read(1) = '1' then 
            dbg_bram_addr_out(BRAM_ADDR_WIDTH-1 downto 0) <= std_logic_vector(unsigned(dbg_mem_addr)-to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH)); 
            dbg_error <= '0';            
          else 
            dbg_error <= '1';
          end if;
        dbg_state <= IDLE; 
      when others => 
        dbg_state <= IDLE; 
    end case; 
  end if;
end process;

end Behavioral;
