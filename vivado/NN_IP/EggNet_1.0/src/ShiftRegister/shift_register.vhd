library ieee;
use ieee.std_logic_1164.all;

entity shift_register is
    generic(
        DATA_WIDTH: integer := 8
    );
    Port (
        Clk_i:       in   STD_LOGIC;
        Reset_i:     in   STD_LOGIC;

        Direction_i:in   STD_LOGIC_VECTOR(1 downto 0);
        Data_1_i:   in   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_2_i:   in   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_3_i:   in   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);

        Data_1_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_2_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_3_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_4_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_5_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_6_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_7_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_8_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
        Data_9_o: out   STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);

        err_o:        out   STD_LOGIC
    );
end shift_register;

architecture Behavioral of shift_register is

    signal data_1    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_2    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_3    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_4    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_5    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_6    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_7    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_8    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);
    signal data_9    : STD_LOGIC_VECTOR((DATA_WIDTH - 1) downto 0);

    signal init      : STD_LOGIC_VECTOR(1 downto 0);

begin

    shifting: process(Clk_i, Reset_i)
    begin
        if (Reset_i = '') then
            Data_1_o <= (others => '0');
            Data_2_o <= (others => '0');
            Data_3_o <= (others => '0');
            Data_4_o <= (others => '0');
            Data_5_o <= (others => '0');
            Data_6_o <= (others => '0');
            Data_7_o <= (others => '0');
            Data_8_o <= (others => '0');
            Data_9_o <= (others => '0');
            err_o <= '1';
            init <= "00";

        elsif rising_edge(Clk_i) then

            case init is
                when "00" =>
                    data_3 <= Data_1_i;
                    data_6 <= Data_2_i;
                    data_9 <= Data_3_i;
                    init <= "01";
                when "01" =>
                    data_2 <= Data_1_i;
                    data_5 <= Data_2_i;
                    data_8 <= Data_3_i;
                    init <= "11";
                when "11" =>
                    case Direction_i is
                        when "01"   =>
                            Data_1_o <= data_2;
                            Data_2_o <= data_3;
                            Data_3_o <= Data_1_i;
                            Data_4_o <= data_5;
                            Data_5_o <= data_6;
                            Data_6_o <= Data_2_i;
                            Data_7_o <= data_8;
                            Data_8_o <= data_9;
                            Data_9_o <= Data_3_i;

                            data_1 <= data_2;
                            data_2 <= data_3;
                            data_3 <= Data_1_i;
                            data_4 <= data_5;
                            data_5 <= data_6;
                            data_6 <= Data_2_i;
                            data_7 <= data_8;
                            data_8 <= data_9;
                            data_9 <= Data_3_i;

                        when "10"   =>
                            Data_1_o <= Data_1_i;
                            Data_2_o <= data_1;
                            Data_3_o <= data_2;
                            Data_4_o <= Data_2_i;
                            Data_5_o <= data_4;
                            Data_6_o <= data_5;
                            Data_7_o <= Data_3_i;
                            Data_8_o <= data_7;
                            Data_9_o <= data_8;

                            data_1 <= Data_1_i;
                            data_2 <= data_1;
                            data_3 <= data_2;
                            data_4 <= Data_2_i;
                            data_5 <= data_4;
                            data_6 <= data_5;
                            data_7 <= Data_3_i;
                            data_8 <= data_7;
                            data_9 <= data_8;

                        when "11"   =>
                            Data_1_o <= data_4;
                            Data_2_o <= data_5;
                            Data_3_o <= data_6;
                            Data_4_o <= data_7;
                            Data_5_o <= data_8;
                            Data_6_o <= data_9;
                            Data_8_o <= Data_1_i;
                            Data_7_o <= Data_2_i;
                            Data_9_o <= Data_3_i;

                            data_1 <= data_4;
                            data_2 <= data_5;
                            data_3 <= data_6;
                            data_4 <= data_7;
                            data_5 <= data_8;
                            data_6 <= data_9;
                            data_7 <= Data_1_i;
                            data_8 <= Data_2_i;
                            data_9 <= Data_3_i;
                        when others => err_o <= '1';
                    end case;
                when others => err_o <= '1';
            end case;
        end if;
    end process;
end Behavioral;
