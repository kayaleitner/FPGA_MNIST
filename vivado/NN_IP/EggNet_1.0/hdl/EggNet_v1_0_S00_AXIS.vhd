library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EggNet_v1_0_S00_AXIS is
	generic (
		-- Users to add parameters here
    BRAM_ADDR_WIDTH		        : integer := 10;
    BRAM_DATA_WIDTH		        : integer := 8;
    BRAM_ADDR_BLOCK_WIDTH     : integer := 784;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
    -- BRAM write
    BRAM_PA_addr_o         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    BRAM_PA_clk_o          : out std_logic;
    BRAM_PA_dout_o         : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    BRAM_PA_wea_o          : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
    -- Status
    Invalid_block_o        : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TKEEP	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end EggNet_v1_0_S00_AXIS;

architecture arch_imp of EggNet_v1_0_S00_AXIS is
	-- function called clogb2 that returns an integer which has the 
	-- value of the ceiling of the log base 2.
	function clogb2 (bit_depth : integer) return integer is 
	variable depth  : integer := bit_depth;
	  begin
	    if (depth = 0) then
	      return(0);
	    else
	      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	        if(depth <= 1) then 
	          return(clogb2);      
	        else
	          depth := depth / 2;
	        end if;
	      end loop;
	    end if;
	end;    

	-- Total number of input data.
	constant NUMBER_OF_INPUT_WORDS  : integer := 8;
	-- bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	constant bit_num  : integer := clogb2(NUMBER_OF_INPUT_WORDS-1);
	-- Define the states of state machine
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO
	type state is ( IDLE,        -- This is the initial/idle state 
	                WRITE_FIFO); -- In this state FIFO is written with the
	                             -- input stream data S_AXIS_TDATA 
	signal axis_tready	: std_logic;
	-- State variable
	signal  mst_exec_state : state;  
	-- FIFO implementation signals
	signal  byte_index : integer;    
	-- FIFO write enable
	signal fifo_wren : std_logic;
	-- FIFO full flag
	signal fifo_full_flag : std_logic;
	-- FIFO write pointer
	signal write_pointer : integer range 0 to bit_num-1 ;
	-- sink has accepted all the streaming data and stored in FIFO
	signal writes_done : std_logic;

	type BYTE_FIFO_TYPE is array (0 to (NUMBER_OF_INPUT_WORDS-1)) of std_logic_vector(((C_S_AXIS_TDATA_WIDTH/4)-1)downto 0);
  
  -- user defined constants  
  constant BLOCK_0_START_ADDR : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0'); 
  constant BLOCK_1_START_ADDR : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := std_logic_vector(
                                    to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH);
  -- user defined signals
  signal block_select : std_logic; -- 0 = block 0, 1 = block 1
  signal block_active : std_logic; -- indicates if a block is active 
  signal bram_ready : std_logic; -- indicates if a block is active 
  signal bram_byte_counter : std_logic_vector(1 downto 0); -- used to tranfrom 8 bit to 32 bit  
  signal bram_byte_counter : std_logic_vector(1 downto 0); -- used to tranfrom 8 bit to 32 bit  
  signal bram_buffer  : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
  signal bram_addr    : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
begin
	-- I/O Connections assignments

	S_AXIS_TREADY	<= axis_tready;
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      -- Synchronous reset (active low)
	      mst_exec_state      <= IDLE;
	    else
	      case (mst_exec_state) is
	        when IDLE     => 
	          -- The sink starts accepting tdata when 
	          -- there tvalid is asserted to mark the
	          -- presence of valid streaming data 
	          if (S_AXIS_TVALID = '1')then
	            mst_exec_state <= WRITE_FIFO;
	          else
	            mst_exec_state <= IDLE;
	          end if;
	      
	        when WRITE_FIFO => 
	          -- When the sink has accepted all the streaming input data,
	          -- the interface swiches functionality to a streaming master
	          if (writes_done = '1') then
	            mst_exec_state <= IDLE;
	          else
	            -- The sink accepts and stores tdata 
	            -- into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end if;
	        
	        when others    => 
	          mst_exec_state <= IDLE;
	        
	      end case;
	    end if;  
	  end if;
	end process;
	-- AXI Streaming Sink 
	-- 
	-- The example design sink is always ready to accept the S_AXIS_TDATA  until
	-- the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	axis_tready <= '1' when ((mst_exec_state = WRITE_FIFO) and (write_pointer <= NUMBER_OF_INPUT_WORDS-1)) else '0';

	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      write_pointer <= 0;
	      writes_done <= '0';
	    else
	      if (write_pointer <= NUMBER_OF_INPUT_WORDS-1) then
	        if (fifo_wren = '1' and bram_ready = '1' and bram_byte_counter = "11" ) then
	          -- write pointer is incremented after every write to the FIFO
	          -- when FIFO write signal is enabled.
	          writes_done <= '0';
          elsif (fifo_wren = '1' and bram_ready ='1' and bram_byte_counter /= "11" ) then
	          -- write pointer is incremented after every write to the FIFO
	          -- when FIFO write signal is enabled.
	          write_pointer <= write_pointer + 1;
	          writes_done <= '0';  
          elsif fifo_wren = '0' and bram_ready = '1' and bram_byte_counter = "11"  then 
            write_pointer <= write_pointer - 1; 
	        end if;
	        if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
	          -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	          -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	          writes_done <= '1';
	        end if;
	      end  if;
	    end if;
	  end if;
	end process;

	-- FIFO write enable generation
	fifo_wren <= S_AXIS_TVALID and axis_tready;

	-- FIFO Implementation
	 FIFO_GEN: for byte_index in 0 to (C_S_AXIS_TDATA_WIDTH/8-1) generate

	 signal stream_data_fifo : BYTE_FIFO_TYPE;
	 begin   
	  -- Streaming input data is stored in FIFO
	  process(S_AXIS_ACLK)
	  begin
	    if (rising_edge (S_AXIS_ACLK)) then
	      if (fifo_wren = '1') then
	        stream_data_fifo(write_pointer) <= S_AXIS_TDATA((byte_index*8+7) downto (byte_index*8));
	      end if;  
	    end  if;
	  end process;

	end generate FIFO_GEN;

	-- Add user logic here
  
 	Conv32_to_8: process(S_AXIS_ARESETN,S_AXIS_ACLK)
	begin
	  if S_AXIS_ARESETN = '0' then
      bram_buffer <= (others => '0');
      bram_addr <= (others => '0');
      block_select <= '0';
      block_active <= '0';
      bram_byte_counter (others => '11');
    elsif (rising_edge (S_AXIS_ACLK)) then
      if bram_byte_counter = "11" then 
        if bram_ready = '1' and write_pointer > 0 then 
          bram_buffer <= stream_data_fifo(write_pointer-1);
          bram_byte_counter <= (others => '0');
        end if;  
      else 
        bram_byte_counter <= std_logic_vector(unsigned(bram_byte_counter)+1);
      end if;
       
	  end  if;
	end process 

 	Conv32_to_8: process(S_AXIS_ARESETN,S_AXIS_ACLK)
	begin
	  if S_AXIS_ARESETN = '0' then
      bram_buffer <= (others => '0');
      bram_addr <= (others => '0');
      block_select <= '0';
      block_active <= '0';
      bram_byte_counter (others => '11');
    elsif (rising_edge (S_AXIS_ACLK)) then
      if bram_byte_counter = "11" and bram_ready then 
        bram_buffer <= stream_data_fifo(write_pointer);
        bram_byte_counter <= (others => '0');
      else 
        bram_byte_counter <= std_logic_vector(unsigned(bram_byte_counter)+1);
      end if;
       
	  end  if;
	end process 
  
  with bram_byte_counter select BRAM_PA_dout_o <=
	bram_buffer((BRAM_DATA_WIDTH*1)-1 downto 0) when "00",
	bram_buffer((BRAM_DATA_WIDTH*2)-1 downto (BRAM_DATA_WIDTH*1) when "01",
	bram_buffer((BRAM_DATA_WIDTH*3)-1 downto (BRAM_DATA_WIDTH*2) when "10",
	bram_buffer((BRAM_DATA_WIDTH*4)-1 downto (BRAM_DATA_WIDTH*3) when "11";
  
  BRAM_PA_clk_o <= S_AXIS_ACLK;  
	BRAM_PA_wea_o <= (others => '1');
  
  -- User logic ends

end arch_imp;
