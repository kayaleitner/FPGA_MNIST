library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MemCtrl_AXIS is
	generic (
    BRAM_ADDR_WIDTH		        : integer := 10;
    BRAM_DATA_WIDTH		        : integer := 8;
    BRAM_ADDR_BLOCK_WIDTH     : integer := 784;
		C_S_AXIS_TDATA_WIDTH	    : integer	:= 32
	);
	port (
    -- BRAM write
    Bram_pa_addr_o          : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    Bram_pa_data_wr_o       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    Bram_pa_wea_o           : out std_logic_vector((BRAM_DATA_WIDTH/8)-1  downto 0);
    -- Status               
    Invalid_block_o         : out std_logic; -- '1' if no tlast signal or if block size not correct 
    Block_done_o            : out std_logic; -- indicates if block received successfully 
    Next_block_wr_i         : in std_logic_vector(1 downto 0);
    Dbg_active_i            : in std_logic;
		-- AXI4Stream sink: Clock
    S_layer_clk_i     : in std_logic;
    S_layer_resetn_i  : in std_logic;
    S_layer_tvalid_i	: in std_logic;
    S_layer_tdata_i   : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0); -- if AXI4_STREAM_INPUT = 0 -> (DATA_WIDTH*IN_CHANNEL_NUMBER) else C_S_AXIS_TDATA_WIDTH
    S_layer_tkeep_i   : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0); --only used if next layer is AXI-stream interface
    S_layer_tlast_i   : in std_logic;
    S_layer_tready_o  : out std_logic
	);
end MemCtrl_AXIS;

architecture arch_imp of MemCtrl_AXIS is

constant AXI_WIDTH_MUL  : integer := natural(C_S_AXIS_TDATA_WIDTH/BRAM_DATA_WIDTH); 

type WR_STATES_AXI is (START,NEW_DATA,SAVE); 
signal wr_state_axi     :WR_STATES_AXI;

signal axi_wr_tlast_R :std_logic;
signal rd_data_buffer :std_logic_vector(C_S_AXIS_TDATA_WIDTH-BRAM_DATA_WIDTH-1 downto 0);
signal wr_block_done  :std_logic;

begin
  
  Block_done_o <= wr_block_done;
  
  AXI_stream_write: process(S_layer_clk_i, S_layer_resetn_i) 
    variable state_cnt   : integer := 0;
    variable position    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, BRAM_ADDR_WIDTH); 
    variable buf_cnt : integer := 0;
  begin
    if S_layer_resetn_i = '0' then 
      
      Bram_pa_addr_o <= (others => '0');
      Bram_pa_data_wr_o <= (others => '0');
      Bram_pa_wea_o <= (others => '0');
      
      S_layer_tready_o <= '0';
      
      wr_state_axi <= START;
      wr_block_done <= '1';
      
      position := to_unsigned(0, position'length);
      state_cnt := 0;
      buf_cnt := 0;
      Invalid_block_o <= '0';
      axi_wr_tlast_R <= '0';
      rd_data_buffer <= (others => '0');
      
    elsif rising_edge(S_layer_clk_i) then  
      case wr_state_axi is 

        when START => -- If data is available transfer starts 
          if Next_block_wr_i(0) = '1' then 
            position := to_unsigned(0, position'length);
            Bram_pa_addr_o <= (others => '0');
            S_layer_tready_o <= '1';
            wr_state_axi <= NEW_DATA;
          elsif Next_block_wr_i(1) = '1' then  
            position := to_unsigned(BRAM_ADDR_BLOCK_WIDTH,position'length);
            Bram_pa_addr_o <= std_logic_vector(position);
            S_layer_tready_o <= '1';
            wr_state_axi <= NEW_DATA;
          else 
            S_layer_tready_o <= '0'; 
          end if;
          Bram_pa_data_wr_o <= (others => '0');
          Bram_pa_wea_o <= (others => '0');          
          state_cnt := 0;
          
        when NEW_DATA => 
          if S_layer_tvalid_i = '1' then 
            wr_block_done <= '0';
            rd_data_buffer <= S_layer_tdata_i(C_S_AXIS_TDATA_WIDTH-BRAM_DATA_WIDTH-1 downto 0);             
            Bram_pa_data_wr_o <= S_layer_tdata_i(C_S_AXIS_TDATA_WIDTH-1 downto C_S_AXIS_TDATA_WIDTH-BRAM_DATA_WIDTH);
            S_layer_tready_o <= '0';
            Bram_pa_addr_o <= std_logic_vector(position);
            Bram_pa_wea_o <= (others => '1');
            position := position+1; 
            state_cnt := state_cnt+1; 
            wr_state_axi <= SAVE; 
            axi_wr_tlast_R <= S_layer_tlast_i;
            buf_cnt := AXI_WIDTH_MUL-1;
          else 
            Bram_pa_wea_o <= (others => '0');  
          end if;   
          if state_cnt >= BRAM_ADDR_BLOCK_WIDTH then 
            wr_state_axi <= START;
            S_layer_tready_o <= '0';
            state_cnt := 0;
            wr_block_done <= '1'; 
            Invalid_block_o <= not S_layer_tlast_i;
          end if;
          if wr_block_done = '1' and Dbg_active_i = '1' then 
            wr_state_axi <= START;
          end if;
        when SAVE => 
          buf_cnt := buf_cnt-1;
          Bram_pa_data_wr_o <= rd_data_buffer((buf_cnt+1)*BRAM_DATA_WIDTH-1 downto buf_cnt*BRAM_DATA_WIDTH);
          S_layer_tready_o <= '0';
          Bram_pa_addr_o <= std_logic_vector(position);
          Bram_pa_wea_o <= (others => '1');
          position := position+1; 
          state_cnt := state_cnt+1;
          
          if state_cnt >= BRAM_ADDR_BLOCK_WIDTH then 
            wr_state_axi <= START;
            S_layer_tready_o <= '0';
            state_cnt := 0;
            wr_block_done <= '1'; 
            Invalid_block_o <= not axi_wr_tlast_R;
          elsif buf_cnt = 0 then 
            wr_state_axi <= NEW_DATA;
            S_layer_tready_o <= '1';
          end if;          
        when others => 
          wr_state_axi <= START;
      end case;
    end if;
  end process;  

end arch_imp;