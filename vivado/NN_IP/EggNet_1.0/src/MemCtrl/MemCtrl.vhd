library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MemCtrl_3x3 is
  Generic(
    BRAM_ADDR_WIDTH		        : integer range 1 to 24   := 10; -- maximum = 24 
    BRAM_DATA_WIDTH		        : integer range 1 to 512  := 8; -- channel number * bit depth  
    S_LAYER_HIGHT             : integer := 28;
    S_LAYER_WIDTH             : integer := 28;
    POOLING_FACTOR            : integer range 1 to 2    := 1; -- No pooling if POOLING_FACTOR = 1 
    STEP_SIZE                 : integer range 1 to 2    := 1;
    
    AXI4_STREAM_INPUT         : integer range 0 to 1 := 0; -- integer to calculate S_LAYER_DATA_WIDTH 
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
    S_layer_tdata_i   : in std_logic_vector((BRAM_DATA_WIDTH+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*BRAM_DATA_WIDTH))-1 downto 0); -- if AXI4_STREAM_INPUT = 0 -> BRAM_DATA_WIDTH else C_S_AXIS_TDATA_WIDTH
    S_layer_tkeep_i   : in std_logic_vector(((BRAM_DATA_WIDTH+(AXI4_STREAM_INPUT*C_S_AXIS_TDATA_WIDTH)-(AXI4_STREAM_INPUT*BRAM_DATA_WIDTH))/8)-1 downto 0); --only used if next layer is AXI-stream interface 
    S_layer_tlast_i   : in std_logic;
    S_layer_tready_o  : out std_logic;
    
    -- Next layer interface 
    M_layer_tvalid_o	: out std_logic;
    M_layer_tdata_1_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0); --  Output vector element 1 |Vector: trans(1,2,3)
    M_layer_tdata_2_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0); --  Output vector element 2 |Vector: trans(1,2,3)
    M_layer_tdata_3_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0); --  Output vector element 3 |Vector: trans(1,2,3)
    M_layer_tkeep_o   : out std_logic_vector((BRAM_DATA_WIDTH*3/8)-1 downto 0); --only used if next layer is AXI-stream interface (default open)
    M_layer_tlast_o   : out std_logic;
    M_layer_tshdir_o  : out std_logic_vector(1 downto 0); -- shiftregister direction 01 -> shift right, 10 -> shift down, 11 -> shift up, 00 -> reset shiftregister  
    M_layer_tready_i  : in std_logic;
    
    -- BRAM interface
    Bram_clk_o        : out std_logic;
    Bram_pa_addr_o    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    Bram_pa_data_wr_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    Bram_pa_wea_o     : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
    Bram_pb_addr_o    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    Bram_pb_data_rd_i : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    Bram_pb_rst_o     : out std_logic; -- ACTIVE HIGH!
    
    -- AXI Lite dbg interface 
    AXI_lite_reg_addr_i  : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 	-- 31 downto 28 : Memory controller address | 27 downto 24: 32 bit vector address | 23 downto 0: BRAM address
    AXI_lite_reg_data_o  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    
    -- Status
    S_layer_invalid_block_o : out std_logic

  );
end MemCtrl_3x3;

architecture Behavioral of MemCtrl_3x3 is

constant BRAM_ADDR_BLOCK_WIDTH      : integer := S_LAYER_HIGHT * S_LAYER_WIDTH;
constant DBG_MEM_CTRL_ADDR_WIDTH    : integer := 4;
constant DBG_REA_32BIT_WIDTH        : integer := 4;
constant DBG_BRAM_ADDRESS_WIDTH     : integer := 24;
constant DBG_MAX_REA                : integer := BRAM_DATA_WIDTH/C_S00_AXI_DATA_WIDTH;
constant M_LAYER_HIGHT              : integer := 28/POOLING_FACTOR;
constant M_LAYER_WIDTH              : integer := 28/POOLING_FACTOR;
constant KERNEL_SIZE                : integer := 3;

type RD_STATES is (IDLE, START,MOVE_RIGHT, MOVE_DOWN, WAIT_CY, PADDING, STOP);
type WR_STATES is (START,MOVE_LEFT,MOVE_RIGHT, MOVE_DOWN_NL, MOVE_DOWN_NR,STOP); 
type WR_BL_STATES is (IDLE,BLOCK0,BLOCK1); 
type RD_BL_STATES is (IDLE,BLOCK0,BLOCK1); 

type TYPE_32BIT_ARRAY is array (0 to DBG_MAX_REA) of std_logic_vector((C_S_AXIS_TDATA_WIDTH-1)downto 0);

function clogb2 (bit_depth : integer) return integer is                  
	variable depth  : integer := bit_depth;                               
	variable count  : integer := 1;                                       
begin                                                                   
	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
     if (bit_depth <= 2) then                                           
       count := 1;                                                      
     else                                                               
       if(depth <= 1) then                                              
	       count := count;                                                
	     else                                                             
	       depth := depth / 2;                                            
         count := count + 1;                                            
	     end if;                                                          
	   end if;                                                            
  end loop;                                                             
  return(count);        	                                              
end; 

component EggNet_v1_0_S00_AXIS is
	generic (
	C_S_AXIS_TDATA_WIDTH	: integer	:= 32;
  BRAM_ADDR_WIDTH		        : integer := 10;
  BRAM_DATA_WIDTH		        : integer := 8;
  BRAM_ADDR_BLOCK_WIDTH     : integer := 784  
	);
	port (
  BRAM_PA_addr_o      : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  BRAM_PA_clk_o       : out std_logic;
  BRAM_PA_dout_o      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  BRAM_PA_wea_o       : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
  Invalid_block_o     : out std_logic;
  Block_done_o        : out std_logic; 
  Next_block_wr_i     : in std_logic_vector(1 downto 0);
	S_AXIS_ACLK	        : in std_logic;
	S_AXIS_ARESETN	    : in std_logic;
	S_AXIS_TREADY	      : out std_logic;
	S_AXIS_TDATA	      : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	S_AXIS_TKEEP	      : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
	S_AXIS_TLAST	      : in std_logic;
	S_AXIS_TVALID	      : in std_logic
	);
end component EggNet_v1_0_S00_AXIS;

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

signal rd_state         :RD_STATES;
signal wr_state         :WR_STATES;
signal rd_bl_state      :RD_BL_STATES;
signal wr_bl_state      :WR_BL_STATES;

signal mem_rd_addr      :std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
signal m_layer_tvalid   :std_logic; 

signal dbg_active       :std_logic;
signal dbg_memctrl_addr :std_logic_vector(DBG_MEM_CTRL_ADDR_WIDTH-1 downto 0); 
signal dbg_rea32_addr   :std_logic_vector(DBG_REA_32BIT_WIDTH-1 downto 0);
signal dbg_axi_ram_addr :std_logic_vector(DBG_BRAM_ADDRESS_WIDTH-1 downto 0);
signal dbg_32bit_data   :std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);

signal next_block_read  :std_logic_vector(1 downto 0); -- 00 wait, 01 block 0, 10 block 1 
signal next_block_write :std_logic_vector(1 downto 0); -- 00 wait, 01 block 0, 10 block 1 
signal rd_block_done    :std_logic;
signal rd_block_done_R  :std_logic;
signal wr_block_done    :std_logic; 
signal wr_block_done_R  :std_logic; 
signal block_full       :std_logic_vector(1 downto 0);

signal fifo_in          :std_logic_vector((BRAM_DATA_WIDTH*(KERNEL_SIZE-1))-1 downto 0);
signal fifo_out         :std_logic_vector((BRAM_DATA_WIDTH*(KERNEL_SIZE-1))-1 downto 0);
signal fifo_empty       :std_logic;
signal fifo_full        :std_logic;
signal fifo_srst        :std_logic;
signal fifo_rd          :std_logic;
signal fifo_wr          :std_logic;


begin
-- ********************* Block control *************************************************************
BlockControl: process(Layer_clk_i,Layer_aresetn_i) 
begin 
  if Layer_aresetn_i = '0' then 
    next_block_read  <= "00";
    next_block_write <= "01";
    block_full <= "00"; 
    rd_bl_state <= IDLE;  
    wr_bl_state <= BLOCK0;
    rd_block_done_R <= '0';
    wr_block_done_R <= '0';
  elsif rising_edge(Layer_clk_i) then 
    case wr_bl_state is 
      when IDLE =>
        next_block_write <= "00";
        if block_full(0) = '0' then 
          wr_bl_state <= BLOCK0;
        elsif block_full(1) = '0' then 
          wr_bl_state <= BLOCK1; 
        end if;
      when BLOCK0 => 
        next_block_write <= "01";
        
        if wr_block_done = '1' and wr_block_done_R = '0' then 
          block_full(0) <= '1';
          if block_full(1) = '0' then
            wr_bl_state <= BLOCK1;
          else 
            wr_bl_state <= IDLE;
          end if;  
        end if;
      when BLOCK1 => 
        next_block_write <= "10";
        if wr_block_done = '1' and wr_block_done_R = '0' then 
          block_full(1) <= '1';
          if block_full(0) = '0' then
            wr_bl_state <= BLOCK0;
          else 
            wr_bl_state <= IDLE;
          end if;  
        end if; 
      when others => 
        wr_bl_state <= IDLE;
    end case;
      
    case rd_bl_state is 
      when IDLE =>
        next_block_read <= "00";
        if block_full(0) = '1' then 
          rd_bl_state <= BLOCK0;
        elsif block_full(1) = '1' then 
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
      when others => 
        rd_bl_state <= IDLE;        
    end case; 
    rd_block_done_R <= rd_block_done;
    wr_block_done_R <= wr_block_done;  
  end if;
end process; 

-- ********************* FIFO to buffer 2 lines (3x3 Kernel)   *************************************
-- Required in order to provide a new Data vector at each clock cycle 
-- This method triples the performance because only one clock cycle is required to fetch a data vector

linebuffer: fifo_generator_0 
  port map (
    clk   => Layer_clk_i,
    srst  => fifo_srst,
    din   => fifo_in,
    wr_en => fifo_wr,
    rd_en => fifo_rd,
    dout  => fifo_out,
    full  => fifo_empty,
    empty => fifo_full 
  );
   
-- ********************* Read block RAM (debug off) ************************************************
M_layer_tvalid_o <= m_layer_tvalid;
M_layer_tkeep_o <= (others => '1') when m_layer_tvalid = '1' else (others => '0');

DefaultRead: process(Layer_clk_i, Layer_aresetn_i) 
  variable state_cnt   : integer range 0 to (BRAM_ADDR_WIDTH-1) := 0;
  variable position    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, BRAM_ADDR_WIDTH);
  variable rd_pixel_row_cnt : integer range 0 to (M_LAYER_WIDTH+KERNEL_SIZE) := 0;
begin
  if Layer_aresetn_i = '0' then 
    mem_rd_addr <= (others => '0');
    M_layer_tlast_o <= '0';
    m_layer_tvalid <= '0';
    M_layer_tshdir_o <= "00"; 
    M_layer_tdata_1_o <= (others => '0');
    M_layer_tdata_2_o <= (others => '0');
    M_layer_tdata_3_o <= (others => '0');
    
    rd_state <= START;
    rd_block_done <= '1'; -- indicate if block is 
    
    position := to_unsigned(0, position'length);
    state_cnt := 0;
    rd_pixel_row_cnt := 0;
    
    fifo_srst <= '0';
    fifo_in <= (others => '0');
    fifo_rd <= '0';
    fifo_wr <= '0';
    
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
          rd_state <= MOVE_RIGHT; 
          rd_block_done <= '0';
        end if;
        state_cnt := 0;
        rd_pixel_row_cnt := 0;
        M_layer_tshdir_o <= "00";
        m_layer_tvalid <= '0';
        M_layer_tlast_o <= '0';
        fifo_srst <= '1'; 
        fifo_wr <= '0';
        fifo_rd <= '0';
        
      when WAIT_CY => -- Required because fetching data from BRAM takes 2 cycles (pipelined) 
        fifo_srst <= '0';
        position := position+1;
        mem_rd_addr <= std_logic_vector(position);
        if state_cnt = 1 then 
          rd_state <= MOVE_RIGHT;
          state_cnt := 0;
        else 
          state_cnt := state_cnt+1;
        end if;
      when MOVE_RIGHT => 
        m_layer_tvalid <= '1';    
        -- Upper Padding 
        if rd_pixel_row_cnt = 0 then
            fifo_in((2*BRAM_DATA_WIDTH)-1 downto BRAM_DATA_WIDTH) <= (others => '0');
            fifo_in(BRAM_DATA_WIDTH-1 downto 0) <= Bram_pb_data_rd_i;
            M_layer_tdata_1_o <= (others => '0');
            M_layer_tdata_2_o <= (others => '0');
            M_layer_tdata_3_o <= Bram_pb_data_rd_i; 
            fifo_rd <= '0';
        -- Lower Padding 
        elsif rd_pixel_row_cnt > (M_LAYER_HIGHT-1) then
            fifo_in((2*BRAM_DATA_WIDTH)-1 downto BRAM_DATA_WIDTH) <= fifo_out(BRAM_DATA_WIDTH-1 downto 0);
            fifo_in(BRAM_DATA_WIDTH-1 downto 0) <= (others => '0');
            fifo_rd <= '1'; -- overwritten if M_layer_tready_i = '0' (More readable like this) 
            M_layer_tdata_1_o <= fifo_out((2*BRAM_DATA_WIDTH)-1 downto BRAM_DATA_WIDTH);
            M_layer_tdata_2_o <= fifo_out(BRAM_DATA_WIDTH-1 downto 0);
            M_layer_tdata_3_o <= (others => '0');            
            
            
        -- Default Vector
        else
            fifo_in((2*BRAM_DATA_WIDTH)-1 downto BRAM_DATA_WIDTH) <= fifo_out(BRAM_DATA_WIDTH-1 downto 0);
            fifo_in(BRAM_DATA_WIDTH-1 downto 0) <= Bram_pb_data_rd_i;
            fifo_rd <= '1'; -- overwritten if M_layer_tready_i = '0' (More readable like this) 
            M_layer_tdata_1_o <= fifo_out((2*BRAM_DATA_WIDTH)-1 downto BRAM_DATA_WIDTH);
            M_layer_tdata_2_o <= fifo_out(BRAM_DATA_WIDTH-1 downto 0);
            M_layer_tdata_3_o <= Bram_pb_data_rd_i;             
        end if;  
        -- Positon count 
        if M_layer_tready_i = '1' then -- Wait till slave is ready
          if state_cnt < M_LAYER_WIDTH-2 then  
            state_cnt := state_cnt +1;            
            if position < 2*BRAM_ADDR_BLOCK_WIDTH-1 then
              position := position+1;             
            end if;
            mem_rd_addr <= std_logic_vector(position);
          elsif state_cnt < M_LAYER_WIDTH-1 then -- necassary because BRAM read takes 2 cycles 
            state_cnt := state_cnt +1;
            fifo_rd <= '0';
          else   
            rd_state <= PADDING;
            fifo_rd <= '0';
            rd_pixel_row_cnt := rd_pixel_row_cnt +1;
            state_cnt := 0;  
          end if;      
          M_layer_tshdir_o <= "01";   
          fifo_wr <= '1';          
        else 
          fifo_wr <= '0';
          fifo_rd <= '0';
          M_layer_tshdir_o <= "00";
        end if;
        
      when PADDING =>  -- set output vector to 0 for KERNEL_SIZE-1 cycles       
        m_layer_tvalid <= '1';
        fifo_wr <= '0'; 
        fifo_rd <= '0';
        M_layer_tdata_1_o <= (others => '0');
        M_layer_tdata_2_o <= (others => '0');
        M_layer_tdata_3_o <= (others => '0');
        
        if M_layer_tready_i = '1' then -- Wait till slave is ready
          M_layer_tshdir_o <= "01"; 
          if position < 2*BRAM_ADDR_BLOCK_WIDTH-1 then
            position := position+1;             
          end if;         
          mem_rd_addr <= std_logic_vector(position);       
          fifo_rd <= '1';
          if state_cnt = KERNEL_SIZE-2 then -- state_cnt = 1 
            if rd_pixel_row_cnt = (M_LAYER_HIGHT-1+KERNEL_SIZE) then 
              rd_state <= START;  
              rd_block_done <= '1';
              M_layer_tlast_o <= '1'; 
              fifo_rd <= '0';
            else
              rd_state <= MOVE_RIGHT;
            end if;
            state_cnt := 0;
          else 
            state_cnt := state_cnt +1;
          end if;
        else 
          M_layer_tshdir_o <= "00";
        end if;   
        
      when others => 
        wr_state <= START;
    end case;
  end if;
end process;

-- ********************* Write block RAM (default) *************************************************
DefaultWrite : if AXI4_STREAM_INPUT = 0 generate 
  Bram_clk_o <= Layer_clk_i;
  
  DefaultWriteP: process(Layer_clk_i, Layer_aresetn_i) 
    variable state_cnt   : integer range 0 to (BRAM_ADDR_WIDTH-1) := 0;
    variable position    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, BRAM_ADDR_WIDTH);
    variable wr_pixel_row_cnt : integer range 0 to (S_LAYER_WIDTH+KERNEL_SIZE) := 0;
  begin
    if Layer_aresetn_i = '0' then 
      
      Bram_pa_addr_o <= (others => '0');
      Bram_pa_data_wr_o <= (others => '0');
      Bram_pa_wea_o <= (others => '0');
      
      S_layer_tready_o <= '0';
      
      wr_state <= START;
      wr_block_done <= '0';
      
      position := to_unsigned(0, position'length);
      state_cnt := 0;
      wr_pixel_row_cnt := 0;
      
    elsif rising_edge(Layer_clk_i) then  
      case wr_state is 

        when START => -- If data is available transfer starts 
          if next_block_read(0) = '1' then 
            position := to_unsigned(0, position'length);
            Bram_pa_addr_o <= (others => '0');
            S_layer_tready_o <= '1';
            wr_state <= MOVE_RIGHT;
          elsif next_block_read(1) = '1' then  
            position := to_unsigned(BRAM_ADDR_BLOCK_WIDTH,position'length);
            Bram_pa_addr_o <= std_logic_vector(position);
            S_layer_tready_o <= '1';
            wr_state <= MOVE_RIGHT;
          else 
            S_layer_tready_o <= '0'; 
          end if;
          Bram_pa_data_wr_o <= (others => '0');
          Bram_pa_wea_o <= (others => '0');          
          state_cnt := 0;
          wr_pixel_row_cnt := 0;
          wr_block_done <= '0'; 
          
        when MOVE_LEFT => 
          if S_layer_tvalid_i = '1' then 
            Bram_pa_data_wr_o <= S_layer_tdata_i;
            Bram_pa_addr_o <= std_logic_vector(position);
            Bram_pa_wea_o <= (others => '1');
            position := position-1; 
            state_cnt := state_cnt+1; 
          else 
            Bram_pa_wea_o <= (others => '0');
          end if;   
          if state_cnt = S_LAYER_WIDTH-1 then 
            wr_state <= MOVE_DOWN_NR;
            state_cnt := 0;
          end if;
          
        when MOVE_RIGHT => 
          if S_layer_tvalid_i = '1' then 
            Bram_pa_data_wr_o <= S_layer_tdata_i;
            Bram_pa_addr_o <= std_logic_vector(position);
            Bram_pa_wea_o <= (others => '1');
            position := position+1; 
            state_cnt := state_cnt+1; 
          else 
            Bram_pa_wea_o <= (others => '0');  
          end if;   
          if state_cnt = S_LAYER_WIDTH-1 then 
            wr_state <= MOVE_DOWN_NL;
            state_cnt := 0;
          end if;
                    
        when MOVE_DOWN_NL => 
          if S_layer_tvalid_i = '1' then 
            Bram_pa_data_wr_o <= S_layer_tdata_i;
            Bram_pa_addr_o <= std_logic_vector(position);
            Bram_pa_wea_o <= (others => '1');
            position := position+S_LAYER_WIDTH; 
            state_cnt := 0; 
            wr_pixel_row_cnt := wr_pixel_row_cnt+1;
            if wr_pixel_row_cnt >= (S_LAYER_HIGHT-1) then
              wr_state <= START;
              wr_block_done <= '1';
              S_layer_invalid_block_o <= not S_layer_tlast_i;
            else
              wr_state <= MOVE_LEFT;
            end if;
          else 
            Bram_pa_wea_o <= (others => '0');  
          end if;  
          
        when MOVE_DOWN_NR => 
          if S_layer_tvalid_i = '1' then 
            Bram_pa_data_wr_o <= S_layer_tdata_i;
            Bram_pa_addr_o <= std_logic_vector(position);
            Bram_pa_wea_o <= (others => '1');
            position := position+S_LAYER_WIDTH; 
            state_cnt := 0; 
            wr_pixel_row_cnt := wr_pixel_row_cnt+1;
            if wr_pixel_row_cnt >= (S_LAYER_HIGHT-1) then
              wr_state <= START;
              wr_block_done <= '1';
              S_layer_invalid_block_o <= not S_layer_tlast_i;
            else
              wr_state <= MOVE_RIGHT;
            end if;  
          else 
            Bram_pa_wea_o <= (others => '0');  
          end if; 
   
        when others => 
          wr_state <= START;
      end case;
    end if;
  end process;  
end generate;

-- ********************* Write block RAM using AXI-stream interface ******************************** 
AXI4_stream : if AXI4_STREAM_INPUT=1 generate 
  -- Instantiation of Axi Bus Interface S00_AXIS if previous layer is input layer 
  EggNet_v1_0_S00_AXIS_inst : EggNet_v1_0_S00_AXIS
    generic map (
      BRAM_ADDR_WIDTH		    => BRAM_ADDR_WIDTH,		   
      BRAM_DATA_WIDTH		    => BRAM_DATA_WIDTH,		   
      BRAM_ADDR_BLOCK_WIDTH => BRAM_ADDR_BLOCK_WIDTH,
      C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_TDATA_WIDTH
    )
    port map (
      -- BRAM Port A 
      BRAM_PA_addr_o  => Bram_pa_addr_o,
      BRAM_PA_clk_o   => Bram_clk_o,
      BRAM_PA_dout_o  => Bram_pa_data_wr_o,
      BRAM_PA_wea_o   => Bram_pa_wea_o, 
      -- Status
      Invalid_block_o => S_layer_invalid_block_o,
      Block_done_o => wr_block_done,
      Next_block_wr_i => next_block_write,
      -- AXI4 stream slave interface 
      S_AXIS_ACLK	=> Layer_clk_i,
      S_AXIS_ARESETN	=> Layer_aresetn_i,
      S_AXIS_TREADY	=> s_layer_tready_o,
      S_AXIS_TDATA	=> s_layer_tdata_i,
      S_AXIS_TKEEP	=> s_layer_tkeep_i,
      S_AXIS_TLAST	=> s_layer_tlast_i,
      S_AXIS_TVALID	=> s_layer_tvalid_i
    );
end generate;

-- ********************* Read from memory address using AXI-lite interface (debug on) **************
dbg_memctrl_addr <= AXI_lite_reg_addr_i((C_S_AXIS_TDATA_WIDTH-1) downto (C_S_AXIS_TDATA_WIDTH-DBG_MEM_CTRL_ADDR_WIDTH)); --31 downto 28
dbg_rea32_addr   <= AXI_lite_reg_addr_i((C_S_AXIS_TDATA_WIDTH-DBG_MEM_CTRL_ADDR_WIDTH-1) downto (C_S_AXIS_TDATA_WIDTH - DBG_MEM_CTRL_ADDR_WIDTH - DBG_REA_32BIT_WIDTH)); -- 27 downto 24
dbg_axi_ram_addr <= AXI_lite_reg_addr_i(DBG_BRAM_ADDRESS_WIDTH-1 downto 0); -- 23 downto 0
dbg_active <= '1' when dbg_memctrl_addr = std_logic_vector(to_unsigned(MEM_CTRL_ADDR,DBG_MEM_CTRL_ADDR_WIDTH)) 
                  else '0';

AXI_lite_reg_data_o <= dbg_32bit_data when dbg_active = '1' else (others => 'Z'); 
Bram_pb_addr_o <= dbg_axi_ram_addr(BRAM_ADDR_WIDTH-1 downto 0) when dbg_active = '1' else mem_rd_addr;

DbgMemory: process(Layer_clk_i, Layer_aresetn_i) 
  variable dbg_32bit_array : TYPE_32BIT_ARRAY;
begin 
  if Layer_aresetn_i = '0' then 
    Bram_pb_rst_o <= '1';  
    dbg_32bit_data <= (others => '0');
  elsif rising_edge(Layer_clk_i) then 
    Bram_pb_rst_o <= '0'; 
    if dbg_active = '1' then      
      for i in 0 to DBG_MAX_REA loop
        if i < DBG_MAX_REA then 
          dbg_32bit_array(i) := Bram_pb_data_rd_i((C_S_AXIS_TDATA_WIDTH + (i*C_S_AXIS_TDATA_WIDTH)-1) downto (i*C_S_AXIS_TDATA_WIDTH));
        else 
          dbg_32bit_array(i)((BRAM_DATA_WIDTH - (i*C_S_AXIS_TDATA_WIDTH)-1) downto 0) := Bram_pb_data_rd_i(BRAM_DATA_WIDTH-1 downto (i*C_S_AXIS_TDATA_WIDTH));
        end if;
      end loop;
      if to_integer(unsigned(dbg_rea32_addr)) <= DBG_MAX_REA then 
        dbg_32bit_data <= dbg_32bit_array(to_integer(unsigned(dbg_rea32_addr)));
      else 
        dbg_32bit_data <= dbg_32bit_array(DBG_MAX_REA);
      end if;
    end if;
  end if;
end process;
      
end Behavioral;

-- when START => -- If data is available transfer starts 
        -- if next_block_read(0) = '1' then 
          -- position := to_unsigned(0, position'length);
          -- mem_rd_addr <= (others => '0');
          -- next_rd_state <= MOVE_RIGHT;
          -- rd_state <= MOVE_RIGHT;
        -- elsif next_block_read(1) = '1' then 
          -- position := to_unsigned(BRAM_ADDR_BLOCK_WIDTH,position'length);
          -- mem_rd_addr <= std_logic_vector(position);
          -- next_rd_state <= MOVE_RIGHT;
          -- rd_state <= MOVE_RIGHT; 
        -- end if;
        -- state_cnt := 0;
        -- fetch_cnt := 0;
        -- rd_pixel_row_cnt := 0;
        -- M_layer_tshdir_o <= "00";
        -- m_layer_tvalid <= '0';
        -- M_layer_tlast_o <= '0';
        -- rd_block_done <= '0';
      
      -- when STOP =>
        -- m_layer_tvalid <= '1';
        -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i;
        -- -- M_layer_tshdir_o not defined because it should not change in this state 
        -- if M_layer_tready_i = '1' then 
          -- rd_state <= START;
          -- state_cnt := 0;
          -- M_layer_tlast_o <= '1';
          -- fetch_cnt := 0;
          -- rd_block_done <= '1';
        -- end if;
        
      -- when MOVE_LEFT => 
        -- m_layer_tvalid <= '1';
        -- M_layer_tshdir_o <= "10";
        -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i; -- The first vector element which is not 0 --> look at fetch state  
        -- if M_layer_tready_i = '1' then       
          -- if state_cnt < M_LAYER_WIDTH-1 then  
            -- mem_rd_addr <= std_logic_vector(position);
            -- next_rd_state <= MOVE_LEFT;
            -- state_cnt := state_cnt +1;
          -- else 
            -- if rd_pixel_row_cnt = (M_LAYER_HIGHT-1+KERNEL_SIZE-1) then 
              -- next_rd_state <= STOP;
              -- state_cnt := 0;
            -- else   
              -- next_rd_state <= MOVE_DOWN_NR;
              -- state_cnt := 0;
            -- end if;  
          -- end if;  
          -- rd_state <= FETCH;
          -- fetch_cnt := 0;
          -- position := position-1;
          -- mem_rd_addr <= std_logic_vector(position);
        -- end if;
        
      -- when MOVE_RIGHT => 
        -- m_layer_tvalid <= '0';
        -- M_layer_tshdir_o <= "01";    
        -- if state_cnt < M_LAYER_WIDTH-1 then  
          -- next_rd_state <= MOVE_RIGHT;
          -- state_cnt := state_cnt +1;
        -- else 
          -- if rd_pixel_row_cnt = (M_LAYER_HIGHT-1+KERNEL_SIZE-1) then 
            -- next_rd_state <= STOP;
            -- state_cnt := 0;
          -- else   
            -- next_rd_state <= MOVE_DOWN_NL;
            -- state_cnt := 0;
          -- end if;  
        -- end if;  
        -- rd_state <= FETCH;
        -- position := position+1;  
        -- mem_rd_addr <= std_logic_vector(position);
        
      -- when MOVE_DOWN_NL => 
        -- M_layer_tshdir_o <= "11";
        -- m_layer_tvalid <= '1';
        -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i; -- The first vector element which is not 0 --> look at fetch state  
        -- if M_layer_tready_i = '1' then      
          -- next_rd_state <= MOVE_LEFT;
          -- rd_state <= PADDING_R;
          -- state_cnt := 0;
          -- fetch_cnt := 0;
          -- rd_pixel_row_cnt := rd_pixel_row_cnt+1;
          -- position := position+M_LAYER_WIDTH;
          -- mem_rd_addr <= std_logic_vector(position);      
        -- end if;  
        
      -- when MOVE_DOWN_NR => 
        -- M_layer_tshdir_o <= "11";
        -- m_layer_tvalid <= '1';
        -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i; -- The first vector element which is not 0 --> look at fetch state  
        -- if M_layer_tready_i = '1' then
          -- next_rd_state <= MOVE_RIGHT;
          -- rd_state <= PADDING_L;
          -- state_cnt := 0;
          -- fetch_cnt := 0;
          -- rd_pixel_row_cnt := rd_pixel_row_cnt+1;
          -- position := position+M_LAYER_WIDTH;
          -- mem_rd_addr <= std_logic_vector(position); 
        -- end if;
      
      -- when PADDING_L => -- padding in left direction 
        -- -- set output vector to 0 for KERNEL_SIZE-1 cycles
        -- M_layer_tshdir_o <= "10";
        -- m_layer_tvalid <= '1';
        -- for i in 0 to KERNEL_SIZE-1 loop -- sets all elements of vector to 0
          -- data_out(i) <= (others => '0');
        -- end loop;   
        -- if M_layer_tready_i = '1' then -- data accept by client if ready = 1 -> increase state_cnt
          -- if state_cnt >= KERNEL_SIZE-2 then -- 0 Vectors for KERNEL_SIZE-1 cycles if same padding is used
            -- m_layer_tvalid <= '0';
            -- state_cnt := 0;
            -- if next_rd_state = MOVE_RIGHT then 
              -- rd_state <= PADDING_R;
            -- else   
              -- rd_state <= FETCH;
            -- end if;  
          -- else 
            -- state_cnt := state_cnt +1;
          -- end if;  
        -- end if;
        
      -- when PADDING_R => -- padding left and right of the matrix 
        -- -- set output vector to 0 for KERNEL_SIZE-1 cycles
        -- M_layer_tshdir_o <= "01";
        -- m_layer_tvalid <= '1';
        -- for i in 0 to KERNEL_SIZE-1 loop -- sets all elements of vector to 0
          -- data_out(i) <= (others => '0');
        -- end loop;   
        -- if M_layer_tready_i = '1' then -- data accept by client if ready = 1 -> increase state_cnt
          -- if state_cnt >= KERNEL_SIZE-2 then -- 0 Vectors for KERNEL_SIZE-1 cycles if same padding is used
            -- m_layer_tvalid <= '0';
            -- state_cnt := 0;
            -- if next_rd_state = MOVE_LEFT then 
              -- rd_state <= PADDING_L;
            -- else   
              -- rd_state <= FETCH;
            -- end if;  
          -- else 
            -- state_cnt := state_cnt +1;
          -- end if;  
        -- end if;            

      -- -- ADD Padding for row 1 and higher
 
        
      -- when others => 
        -- wr_state <= START;
    -- end case;
    
    -- std_cnt_sig <= state_cnt; -- only for debugging 
    
    -- padding_R  <= padding; 
    -- padding_RR <= padding_R; -- because data is 2 cycles slower than address     
    -- if padding_RR = '0' then 
      -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i;
    -- else 
      -- data_out(KERNEL_SIZE-1-fetch_cnt) <= (others => '0');
    -- end if;
      -- when push => 
        -- m_layer_tvalid <= '1';
        -- if rd_pixel_row_cnt = 0 then 
          -- data_out(KERNEL_SIZE-1) <= Bram_pb_data_rd_i;
          -- for i in 0 to KERNEL_SIZE-2 loop 
            -- data_out(i) <= (others => '0');
          -- end loop; 
          -- rd_state <= next_rd_state;
        -- else
          -- mem_rd_addr <= std_logic_vector(position-M_LAYER_WIDTH);
          -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i; -- The first vector element which is not 0 --> if no padding element 0 
          -- fetch_cnt := 1; 
          -- rd_state <= FETCH; 
        -- end if;
        
      -- when FETCH =>        
        -- m_layer_tvalid <= '0';
        -- -- *** Same padding ***
        -- if rd_pixel_row_cnt < KERNEL_SIZE-1 then -- Upper padding 
          -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i;
          -- for i in 0 to KERNEL_SIZE-rd_pixel_row_cnt-2 loop 
            -- data_out(i) <= (others => '0');
          -- end loop;
          -- if rd_pixel_row_cnt = 0 then 
            -- rd_state <= next_rd_state;
            -- fetch_cnt := 0;
          -- elsif fetch_cnt >= rd_pixel_row_cnt-1 then 
            -- rd_state <= next_rd_state;
            -- mem_rd_addr <= std_logic_vector(position-((fetch_cnt+1)*M_LAYER_WIDTH));
            -- fetch_cnt := fetch_cnt +1; 
          -- else 
            -- mem_rd_addr <= std_logic_vector(position-((fetch_cnt+1)*M_LAYER_WIDTH));
            -- fetch_cnt := fetch_cnt +1;
          -- end if;
          
        -- elsif rd_pixel_row_cnt > (M_LAYER_HIGHT-1) then -- lower padding 
          -- for i in 0 to rd_pixel_row_cnt-M_LAYER_HIGHT loop 
            -- data_out(KERNEL_SIZE-1-i) <= (others => '0');
          -- end loop;
          -- -- ATTENTION this works only if the position stays in the last row during padding 
          -- mem_rd_addr <= std_logic_vector(position-((fetch_cnt+1)*M_LAYER_WIDTH));
          -- data_out(KERNEL_SIZE-1-fetch_cnt-(rd_pixel_row_cnt-(M_LAYER_HIGHT-1))) <= Bram_pb_data_rd_i;
          -- if rd_pixel_row_cnt-(M_LAYER_HIGHT-1) = KERNEL_SIZE-1 then 
            -- rd_state <= next_rd_state;
            -- fetch_cnt := KERNEL_SIZE-1; 
          -- elsif fetch_cnt >= KERNEL_SIZE-1-(rd_pixel_row_cnt-(M_LAYER_HIGHT-1)) then 
            -- rd_state <= next_rd_state;
            -- fetch_cnt := KERNEL_SIZE-1;   
          -- else 
            -- fetch_cnt := fetch_cnt +1;
          -- end if;        
        -- -- *** Default data fetch *** 
        -- else   
          -- mem_rd_addr <= std_logic_vector(position-((fetch_cnt+1)*M_LAYER_WIDTH));
          -- data_out(KERNEL_SIZE-1-fetch_cnt) <= Bram_pb_data_rd_i;
          -- if fetch_cnt >= KERNEL_SIZE-2 then 
            -- rd_state <= next_rd_state;
          -- end if;    
          -- fetch_cnt := fetch_cnt +1;
        -- end if; 