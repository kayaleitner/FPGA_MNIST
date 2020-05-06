library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package EggNetCommon is


    subtype INT_4 is INTEGER range -8 to 7;
    subtype UINT_4 is INTEGER range 0 to 15;
    subtype INT_8 is INTEGER range -128 to 127;
    subtype UINT_8 is INTEGER range 0 to 255;

    type CHANNEL_ARRAY is array (NATURAL range <>) of signed;
    type U_CHANNEL_ARRAY is array (NATURAL range <>) of unsigned;

    

end package;


package body EggNetCommon is
    
end package body;

