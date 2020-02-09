library ieee;
use ieee.std_logic_1164.all;

entity ShiftRegister_3x3 is
  generic(
      DATA_WIDTH: integer := 8
  );
  Port (
    -- Clk and reset
    Clk_i           : in  STD_LOGIC; -- clock
    nRst_i          : in  STD_LOGIC; -- active low reset 
    
    -- Slave interface to previous memory controller  
    S_data_1_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 1 |Vector: trans(1,2,3)
    S_data_2_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 2 |Vector: trans(1,2,3)
    S_data_3_i      : in  STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); --  Input vector element 3 |Vector: trans(1,2,3)
    S_tvalid_i	    : in  STD_LOGIC; -- indicates if input data is valid 
    S_tnewrow_i     : in  STD_LOGIC; -- indicates that a new row starts 
    S_tlast_i       : in  STD_LOGIC; -- indicates end of block 
    S_tready_o      : out STD_LOGIC; -- indicates if shiftregister is ready to for new data 

    -- Master interface to next 3x3 kernel matrix multiplier 
    M_data_1_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 11  Matrix  : |11 , 12, 13|
    M_data_2_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 21          : |21 , 22, 23|
    M_data_3_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 31          : |31 , 32, 33|
    M_data_4_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 12
    M_data_5_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 22
    M_data_6_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 32
    M_data_7_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 13
    M_data_8_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 23
    M_data_9_o      : out STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0); -- Output matrix element 33
    M_tvalid_o	    : out STD_LOGIC; -- indicates if output data is valid 
    M_tlast_o       : out STD_LOGIC; -- indicates end of block 
    M_tready_i      : in  STD_LOGIC  -- indicates if next slave is ready to for new data   
  );
end ShiftRegister_3x3;

architecture Behavioral of ShiftRegister_3x3 is

  type STATES is (INIT,NEW_LINE,RUN);
  signal state     :STATES;
  
  signal data_buffer_1 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_buffer_2 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_buffer_3 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  
  signal data_1    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_2    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_3    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_4    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_5    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_6    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_7    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_8    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
  signal data_9    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);

begin

  M_data_1_o <= data_1;
  M_data_2_o <= data_2;
  M_data_3_o <= data_3;
  M_data_4_o <= data_4;
  M_data_5_o <= data_5;
  M_data_6_o <= data_6;
  M_data_7_o <= data_7;
  M_data_8_o <= data_8;
  M_data_9_o <= data_9;

  shifting: process(Clk_i, nRst_i)
  begin
    if nRst_i = '0' then
      data_1 <= (others => '0');
      data_2 <= (others => '0');
      data_3 <= (others => '0');
      data_4 <= (others => '0');
      data_5 <= (others => '0');
      data_6 <= (others => '0');
      data_7 <= (others => '0');
      data_8 <= (others => '0');
      data_9 <= (others => '0');
      data_buffer_1 <= (others => '0');      
      data_buffer_2 <= (others => '0');     
      data_buffer_3 <= (others => '0');     
      state <= INIT;
      M_tlast_o <= '0';
      M_tvalid_o <= '0';
      S_tready_o <= '1';
    elsif rising_edge(Clk_i) then
      
      case(state) is 
        when INIT => 
          S_tready_o <= '1';
          M_tlast_o <= '0';
          M_tvalid_o <= '0';
          if S_tvalid_i = '1' and S_tnewrow_i = '1' then
            state <= NEW_LINE;
            data_buffer_1 <= S_data_1_i;
            data_buffer_2 <= S_data_2_i;
            data_buffer_3 <= S_data_3_i; 
          end if; 
          

        when NEW_LINE => 
          S_tready_o <= '1';
          M_tlast_o <= '0';
          if S_tvalid_i = '1' then
            state <= RUN;
            data_1 <= (others => '0');
            data_2 <= (others => '0');
            data_3 <= (others => '0');
            data_4 <= data_buffer_1;
            data_5 <= data_buffer_2;
            data_6 <= data_buffer_3;
            data_7 <= S_data_1_i;
            data_8 <= S_data_2_i;
            data_9 <= S_data_3_i;
            M_tvalid_o <= '1';
          else 
            M_tvalid_o <= '0';
          end if;
        
        when RUN => 
          S_tready_o <= M_tready_i;
          if S_tvalid_i = '1' then
            M_tvalid_o <= '1';
            if M_tready_i = '1' then 
              if S_tnewrow_i = '1' then 
                data_1 <= data_4;
                data_2 <= data_5;
                data_3 <= data_6;
                data_4 <= data_7;
                data_5 <= data_8;
                data_6 <= data_9;
                data_7 <= (others => '0');
                data_8 <= (others => '0');
                data_9 <= (others => '0'); 
                data_buffer_1 <= S_data_1_i;
                data_buffer_2 <= S_data_2_i;
                data_buffer_3 <= S_data_3_i;   
                if S_tlast_i = '1' then 
                  state <= INIT;
                else 
                  state <= NEW_LINE;
                end if;
              else  
                data_1 <= data_4;
                data_2 <= data_5;
                data_3 <= data_6;
                data_4 <= data_7;
                data_5 <= data_8;
                data_6 <= data_9;
                data_7 <= S_data_1_i;
                data_8 <= S_data_2_i;
                data_9 <= S_data_3_i;
              end if;
              if S_tlast_i = '1' then 
                M_tlast_o <= S_tlast_i; 
              end if;
            end if; 
          end if; 
        when others => 
          state <= INIT;  
      end case;
    end if;
  end process;
end Behavioral;
