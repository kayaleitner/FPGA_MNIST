library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package EggNetCommon is
    ----------------------------------------
    -- Default Types
    ----------------------------------------

    subtype INT_4 is integer range -8 to 7;
    subtype UINT_4 is integer range 0 to 15;
    subtype INT_8 is integer range -128 to 127;
    subtype UINT_8 is integer range 0 to 255;
    ----------------------------------------
    -- ARRAY TYPES: Convolutional Layer
    ----------------------------------------
    type CHANNEL_ARRAY is array (natural range <>) of signed;
    type U_CHANNEL_ARRAY is array (natural range <>) of unsigned;

    type channel_vector_t is array (natural range <>) of std_logic_vector;
end package;

package body EggNetCommon is

end package body;