library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.clogb2_Pkg.all;


-- Based on auto generated file by Vivado 

entity AXI_steam_master is
	generic (
		-- Users to add parameters here
    OUTPUT_NUMBER 		        : integer := 10;
    DATA_WIDTH    		        : integer := 8;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_axis_tdata_o_WIDTH.
		C_M_axis_tdata_o_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
		-- Clock and reset
		Clk_i	: in std_logic;		-- 
		nRst_i	: in std_logic;    
    
    -- Output layer interface 
    Layer_tvalid_i	: in std_logic;
    Layer_tdata_i   : in std_logic_vector(DATA_WIDTH*OUTPUT_NUMBER-1 downto 0);
    Layer_tlast_i   : in std_logic;
    Layer_tready_o  : out std_logic; 
		-- Interrupt
    Interrupt       : out std_logic;
    -- User ports ends
		-- Do not modify the ports beyond this line
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_axis_tvalid_o	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_axis_tdata_o	: out std_logic_vector(C_M_axis_tdata_o_WIDTH-1 downto 0);
		-- TKEEP is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_axis_tkeep_o	: out std_logic_vector((C_M_axis_tdata_o_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_axis_tlast_o	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_axis_tready_i	: in std_logic
	);
end AXI_steam_master;

architecture implementation of AXI_steam_master is                                                                    

	function get_remainder (data_width, output_num, axis_data_width : integer) return integer is                  
	 	variable remainder  : integer := (data_width*output_num) mod axis_data_width;                                                                   
	begin                                                                   
    if remainder = 0 then 
      remainder := remainder + axis_data_width;
    end if; 
    return(remainder);        	                                              
	end;    

  constant REMAINDER_SIZE : integer := get_remainder(DATA_WIDTH,OUTPUT_NUMBER,C_M_axis_tdata_o_WIDTH); 
  constant CYC_PER_OUTPUT : integer := (DATA_WIDTH*OUTPUT_NUMBER-1)/C_M_axis_tdata_o_WIDTH+1; -- DATA_WIDTH*OUTPUT_NUMBER-1 because in case of DATA_WIDTH*OUTPUT_NUMBER = C_M_axis_tdata_o_WIDTH counter size shall be 0
  constant REMAINDER_BYTES_KEEP : std_logic_vector(DATA_WIDTH*OUTPUT_NUMBER/8-1 downto 0) := std_logic_vector(to_unsigned(2**((REMAINDER_SIZE-1)/8+1)-1,DATA_WIDTH*OUTPUT_NUMBER/8));


  type STATES is (START,SEND_DATA, WAIT_FOR_READY);   
  
  signal state : STATES;
  signal next_state : STATES;
  
  signal data_buf : std_logic_vector(DATA_WIDTH*OUTPUT_NUMBER-1 downto 0); 
  signal last_buf : std_logic;
  signal m_last   : std_logic;

begin
-- I/O Connections assignments

Interrupt <= m_last;
M_axis_tlast_o <= m_last;

AXIS_Master: process(Clk_i, nRst_i)     
  variable data_cnt : integer range 0 to CYC_PER_OUTPUT := 0; 
begin    
  if nRst_i = '0' then 

    M_axis_tvalid_o	<= '0';
    M_axis_tdata_o <= (others => '0');
    M_axis_tkeep_o <= (others => '0');
    m_last <= '0';    
    Layer_tready_o <= '0';
    next_state <= START;
    state <= START;
    last_buf <= '0';

  elsif (rising_edge (Clk_i)) then     
    case state is 
      when START => 
        if Layer_tvalid_i = '1' then 
          data_buf <= Layer_tdata_i;
          data_cnt := data_cnt+1;
          M_axis_tvalid_o <= '1';
          last_buf <= Layer_tlast_i;
          if data_cnt = CYC_PER_OUTPUT then 
            M_axis_tdata_o <= (others => '0'); -- set rest of the vector to 0 --> have to be before M_axis_tdata_o(REMAINDER_SIZE-1 downto 0) <= Layer_tdata_i... 
            M_axis_tdata_o(REMAINDER_SIZE-1 downto 0) <= Layer_tdata_i(Layer_tdata_i'left downto Layer_tdata_i'left-REMAINDER_SIZE);
            M_axis_tkeep_o <= REMAINDER_BYTES_KEEP;
            m_last <= Layer_tlast_i;
            if M_axis_tready_i = '1' then 
              state <= START; 
              Layer_tready_o <= '1';
            else 
              state <= WAIT_FOR_READY;
              next_state <= START;
              Layer_tready_o <= '0';
            end if; 
            data_cnt := 0;            
          else 
            M_axis_tdata_o <= Layer_tdata_i(C_M_axis_tdata_o_WIDTH-1 downto 0);
            Layer_tready_o <= '0';
            m_last <= '0';
            if M_axis_tready_i = '1' then 
              state <= SEND_DATA; 
            else 
              state <= WAIT_FOR_READY;
              next_state <= SEND_DATA;
            end if; 
          end if;
        else 
          m_last <= '0';
          M_axis_tvalid_o <= '0';
          Layer_tready_o <= '1';
          data_cnt := 0;
        end if; 
      when SEND_DATA =>
        M_axis_tvalid_o <= '1';
        if data_cnt = CYC_PER_OUTPUT-1 then 
          M_axis_tdata_o <= (others => '0'); -- set rest of the vector to 0 --> have to be before M_axis_tdata_o(REMAINDER_SIZE-1 downto 0) <= Layer_tdata_i... 
          M_axis_tdata_o(REMAINDER_SIZE-1 downto 0) <= Layer_tdata_i(Layer_tdata_i'left downto Layer_tdata_i'left-REMAINDER_SIZE);
          M_axis_tkeep_o <= REMAINDER_BYTES_KEEP;
          Layer_tready_o <= '1';
          m_last <= last_buf;
          state <= START; 
          data_cnt := 0;
        else             
          M_axis_tdata_o <= data_buf((data_cnt+1)*C_M_axis_tdata_o_WIDTH downto data_cnt*C_M_axis_tdata_o_WIDTH);
        end if;
        if M_axis_tready_i = '1' then 
          data_cnt := data_cnt+1;
        end if;
      when WAIT_FOR_READY => 
        if M_axis_tready_i = '1' then
          state <= next_state;
        end if;
      when others => 
        M_axis_tvalid_o	<= '0';
        M_axis_tdata_o <= (others => '0');
        M_axis_tkeep_o <= (others => '0');    
        m_last <= '0';     
        state <= START; 
    end case;   
  end if;      
end process;

end implementation;
