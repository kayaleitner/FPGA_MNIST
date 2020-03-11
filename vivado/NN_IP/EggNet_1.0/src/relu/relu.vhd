LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY relu_nbit IS
    GENERIC (N : INTEGER);
    PORT (
        x_i : IN std_logic_vector(N - 1 DOWNTO 0);
        x_o : OUT std_logic_vector(N - 1 DOWNTO 0)
    );
END relu_nbit;
ARCHITECTURE behavior OF relu_nbit IS

BEGIN

    x_o <= x_i WHEN x_i(N - 1) = '0' ELSE
        (OTHERS => '0');

END behavior; -- behavior