import IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity relu_nbit is
    generic( N : integer );
    port (
        x_i : in std_logic_vector(N-1 downto 0);
        x_o : out std_logic_vector(N-1 downto 0)
    );
end relu_nbit;


architecture behavior of relu_nbit is

begin

    x_o <= x_i when x_i(N-1) = '0' else (others => '0');

end behavior ; -- behavior