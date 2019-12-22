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
    Invalid_block_o        : out std_logic; -- '1' if no tlast signal or if block size not correct 
    Block_done_o           : out std_logic; -- indicates if block received successfully 
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
	-- Total number of input data.
	constant NUMBER_OF_INPUT_WORDS  : integer := 4;
	-- bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
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
	-- FIFO write pointer
	signal write_pointer : integer;-- range 0 to bit_num-1 ;
	-- sink has accepted all the streaming data and stored in FIFO
	signal writes_done : std_logic;

	type BYTE_FIFO_TYPE is array (0 to (NUMBER_OF_INPUT_WORDS-1)) of std_logic_vector(((C_S_AXIS_TDATA_WIDTH)-1)downto 0);
  signal stream_data_fifo : BYTE_FIFO_TYPE;
  -- user defined constants  
  constant BLOCK_0_START_ADDR : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0'); 
  constant BLOCK_1_START_ADDR : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := std_logic_vector(
                                    to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH));
  -- user defined signals
  signal block_select       : std_logic; -- 0 = block 0, 1 = block 1
  signal block_active       : std_logic; -- indicates if a block is active 
  signal block_active_R     : std_logic; -- indicates if a block is active 
  signal addr_counter       : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
  signal bram_byte_counter  : std_logic_vector(1 downto 0); -- used to tranfrom 8 bit to 32 bit  
  signal bram_buffer        : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0); -- buffers data
  signal bram_addr          : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal tlast_buf          : std_logic; -- buffers tlast 
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
	axis_tready <= '1' when ((mst_exec_state = WRITE_FIFO) and (write_pointer < NUMBER_OF_INPUT_WORDS-1)) 
                  else '0';

	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      write_pointer <= 0;
	      writes_done <= '0';
	    else
	        if (fifo_wren = '1' and bram_byte_counter = "11" and write_pointer > 0) then
	          -- write pointer is incremented after every write to the FIFO
	          -- when FIFO write signal is enabled.
	          writes_done <= '0';
          elsif fifo_wren = '1' and write_pointer < NUMBER_OF_INPUT_WORDS-1 then
	          -- -- write pointer is incremented after every write to the FIFO
	          -- -- when FIFO write signal is enabled.
	          write_pointer <= write_pointer + 1;
	          writes_done <= '0';  
          elsif fifo_wren = '0' and bram_byte_counter = "11"  and write_pointer > 0 then 
            write_pointer <= write_pointer - 1; 
	        end if;
          -- if (S_AXIS_TLAST = '1' and write_pointer = 0) then
	          -- -- if fifo is empty and tlast signal is dected transaction is done 
            -- writes_done <= '1';
	        -- end if;
	    end if;
	  end if;
	end process;

	-- FIFO write enable generation
	fifo_wren <= S_AXIS_TVALID and axis_tready;

	-- -- FIFO Implementation
	 -- FIFO_GEN: for byte_index in 0 to (C_S_AXIS_TDATA_WIDTH/8-1) generate

	 
	 -- begin   
	  -- Streaming input data is stored in FIFO
	  process(S_AXIS_ACLK)
	  begin
	    if (rising_edge (S_AXIS_ACLK)) then
	      if (fifo_wren = '1') then	        
          stream_data_fifo(0) <= S_AXIS_TDATA;--S_AXIS_TDATA((byte_index*8+7) downto (byte_index*8));
          for i in 1 to NUMBER_OF_INPUT_WORDS-1 loop 
            stream_data_fifo(i) <= stream_data_fifo(i-1);
          end loop; 
	      end if;  
	    end  if;
	  end process;

	-- end generate FIFO_GEN;

	-- Add user logic here
  
 	Conv32_to_8: process(S_AXIS_ARESETN,S_AXIS_ACLK)
	begin
	  if S_AXIS_ARESETN = '0' then
      bram_buffer <= (others => '0');
      bram_addr <= (others => '0');
      block_select <= '1';
      block_active <= '0';
      bram_byte_counter <= (others => '1');
      addr_counter <= (others => '0');
      bram_addr <= (others => '0');
      block_active_R <= '0';      
      tlast_buf <= '0';
      Invalid_block_o <= '0';
      Block_done_o <= '1';
      BRAM_PA_wea_o <= (others => '0');
    elsif (rising_edge (S_AXIS_ACLK)) then
      if bram_byte_counter = "11" then 
        -- check if data is available in FIFO 
        if write_pointer > 0 then 
          Invalid_block_o <= '0';
          bram_buffer <= stream_data_fifo(write_pointer-1);
          bram_byte_counter <= (others => '0');
          BRAM_PA_wea_o <= (others => '1');
          Block_done_o <= '0';  
          -- Set initial address of RAM block 
          if block_active = '0' then 
            block_active <= '1';
            block_select <= not block_select; 
            if block_select = '1' then 
              bram_addr <= BLOCK_0_START_ADDR;
            else 
              bram_addr <= BLOCK_1_START_ADDR;
            end if;  
          end if;  
        else -- if FIFO is empty transaction ends and it is checked if block size is valid 
          block_active <= '0';
          BRAM_PA_wea_o <= (others => '0');
          Block_done_o <= '1';  
          tlast_buf <= '0';
          if block_select = '0' then 
            if bram_addr = std_logic_vector(unsigned(BLOCK_0_START_ADDR)+
                                          to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH)-1) then
              
              Invalid_block_o <= not tlast_buf; -- block is invalid if no tlast signal is detected
            else 
              Invalid_block_o <= '1';
            end if;
          else 
            if bram_addr = std_logic_vector(unsigned(BLOCK_0_START_ADDR)+
                                          to_unsigned(BRAM_ADDR_BLOCK_WIDTH,BRAM_ADDR_WIDTH)-1) then
                
              Invalid_block_o <= not tlast_buf; -- block is invalid if no tlast signal is detected
            else 
              Invalid_block_o <= '1';
            end if;
          end if;    
        end if;  
      else -- byte counter to save each byte successively 
        bram_byte_counter <= std_logic_vector(unsigned(bram_byte_counter)+1);
      end if;   
      -- if block active increment block ram address at each clock 
      if block_active = '1' then
        bram_addr <= std_logic_vector(unsigned(bram_addr)+1);
      end if;
      -- buffer tlast signal till FIFO is empty 
      if S_AXIS_TLAST = '1' then 
        tlast_buf <= '1';
      end if;  
	  end  if;
	end process;
  
  with bram_byte_counter select 
    BRAM_PA_dout_o <= bram_buffer((BRAM_DATA_WIDTH*1)-1 downto 0)                   when "11",
                      bram_buffer((BRAM_DATA_WIDTH*2)-1 downto (BRAM_DATA_WIDTH*1)) when "10",
                      bram_buffer((BRAM_DATA_WIDTH*3)-1 downto (BRAM_DATA_WIDTH*2)) when "01",
                      bram_buffer((BRAM_DATA_WIDTH*4)-1 downto (BRAM_DATA_WIDTH*3)) when "00",
                      (others => '0')                                               when others;
  
  BRAM_PA_clk_o <= S_AXIS_ACLK;  
  BRAM_PA_addr_o <= bram_addr;
  -- User logic ends

end arch_imp;
