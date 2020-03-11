LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY shift_register IS
    GENERIC (
        DATA_WIDTH : INTEGER := 8
    );
    PORT (
        Clk_i : IN STD_LOGIC;
        Reset_i : IN STD_LOGIC;

        Direction_i : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        Data_1_i : IN STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_2_i : IN STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_3_i : IN STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);

        Data_1_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_2_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_3_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_4_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_5_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_6_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_7_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_8_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        Data_9_o : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);

        err_o : OUT STD_LOGIC
    );
END shift_register;

ARCHITECTURE Behavioral OF shift_register IS

    SIGNAL data_1 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_2 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_3 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_4 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_5 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_6 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_7 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_8 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL data_9 : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);

    SIGNAL init : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    shifting : PROCESS (Clk_i, Reset_i)
    BEGIN
        IF (Reset_i = '') THEN
            Data_1_o <= (OTHERS => '0');
            Data_2_o <= (OTHERS => '0');
            Data_3_o <= (OTHERS => '0');
            Data_4_o <= (OTHERS => '0');
            Data_5_o <= (OTHERS => '0');
            Data_6_o <= (OTHERS => '0');
            Data_7_o <= (OTHERS => '0');
            Data_8_o <= (OTHERS => '0');
            Data_9_o <= (OTHERS => '0');
            err_o <= '1';
            init <= "00";

        ELSIF rising_edge(Clk_i) THEN

            CASE init IS
                WHEN "00" =>
                    data_3 <= Data_1_i;
                    data_6 <= Data_2_i;
                    data_9 <= Data_3_i;
                    init <= "01";
                WHEN "01" =>
                    data_2 <= Data_1_i;
                    data_5 <= Data_2_i;
                    data_8 <= Data_3_i;
                    init <= "11";
                WHEN "11" =>
                    CASE Direction_i IS
                        WHEN "01" =>
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

                        WHEN "10" =>
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

                        WHEN "11" =>
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
                        WHEN OTHERS => err_o <= '1';
                    END CASE;
                WHEN OTHERS => err_o <= '1';
            END CASE;
        END IF;
    END PROCESS;
END Behavioral;