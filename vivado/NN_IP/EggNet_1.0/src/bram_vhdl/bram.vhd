library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY bram IS
  GENERIC (
      BRAM_ADDR_WIDTH		        : integer range 1 to 24   := 10; -- maximum = 24
      BRAM_DATA_WIDTH		        : integer := 32;
      BRAM_SIZE                 : integer := 1568
  );

  PORT (
    clk_i : IN STD_LOGIC;
    rst_i : IN STD_LOGIC;

    wea_i        : IN STD_LOGIC_VECTOR(((BRAM_DATA_WIDTH)/8)-1 DOWNTO 0);
    pa_data_i    : IN STD_LOGIC_VECTOR((BRAM_DATA_WIDTH) - 1 DOWNTO 0);
    pb_data_o    : OUT STD_LOGIC_VECTOR((BRAM_DATA_WIDTH) - 1 DOWNTO 0);

    -- ADRESS POINTER
    pa_addr_i : IN STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH - 1 DOWNTO 0);
    pb_addr_i : IN STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH - 1 DOWNTO 0)
  );
END bram;

ARCHITECTURE Behavioral of bram is

    type TYPE_DATAWIDTH_ARRAY is array (0 to BRAM_SIZE-1) of STD_LOGIC_VECTOR(BRAM_DATA_WIDTH - 1 DOWNTO 0);
    signal ram : TYPE_DATAWIDTH_ARRAY;

    signal pa_addr : STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH - 1 DOWNTO 0);
    signal pa_data : STD_LOGIC_VECTOR((BRAM_DATA_WIDTH) - 1 DOWNTO 0);
    signal write_enable : STD_LOGIC_VECTOR(((BRAM_DATA_WIDTH ) / 8) - 1 DOWNTO 0);

    signal pb_addr : STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH - 1 DOWNTO 0);
    --signal pb_data : STD_LOGIC_VECTOR((BRAM_DATA_WIDTH) - 1 DOWNTO 0);

    constant BYTE_WIDTH : integer := 8;

begin
    bramming: process(clk_i)
    begin

    if rising_edge(clk_i) then
        if (rst_i = '1') then
            pa_addr <= (others => '0');
            pb_addr <= (others => '0');
        else
            pa_addr <= pa_addr_i;
            pa_data <= pa_data_i;
            write_enable <= wea_i;

            for i in 0 to BRAM_DATA_WIDTH  / BYTE_WIDTH - 1 loop
                if (write_enable(i) = '1') then
                    ram(to_integer(unsigned(pa_addr)))( (i+1)* BYTE_WIDTH - 1 DOWNTO i*BYTE_WIDTH ) <= pa_data((i+1)* BYTE_WIDTH - 1 DOWNTO i*8);
                end if;
            end loop;


            pb_addr <= pb_addr_i;
            pb_data_o <= ram(to_integer(unsigned(pb_addr)));
            --pb_data_o <= pb_data;
            end if;
        end if;
    END process;
end Behavioral;
