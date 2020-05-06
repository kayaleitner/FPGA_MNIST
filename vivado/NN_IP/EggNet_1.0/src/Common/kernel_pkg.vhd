library ieee;
use ieee.std_logic_1164.all;

-- Kernel PKG
-- Contains defintions that are used in the Generic Interfaces of various entities
package kernel_pkg is
    
    constant KERNEL_SIZE : integer := 9;
    type weight_array_t is array (0 to KERNEL_SIZE - 1) of integer;

    constant KERNEL_WIDTH  : natural := 3;
    constant KERNEL_HEIGHT : natural := 3;
    type kernel_weight_slice_t is array(0 to KERNEL_HEIGHT) of integer;
    type kernel_weight_2d_t is array(0 to KERNEL_HEIGHT - 1) of kernel_weight_slice_t;

    -- Array to store the amount of the shifts, corresponding to nonlinear quantization
    type conv_kernel_3x3_weight_shift_t is array(0 to KERNEL_SIZE - 1) of integer;

    ---------------------------------------------------------------------
    -- Convolution Channel Types
    ---------------------------------------------------------------------

    -- subtype INT_4 is integer range -8 to 7;
    -- subtype UINT_4 is integer range 0 to 15;
    -- subtype INT_8 is integer range -128 to 127;
    -- subtype UINT_8 is integer range 0 to 255;

    -- type C_KERNEL_I4 is array (natural range <>, natural range <>) of INT_4;
    -- type C_KERNEL_I8 is array (natural range <>, natural range <>) of INT_8;
    -- type C_KERNEL_FLAT_I4 is array (natural range <>) of INT_4;
    -- type C_KERNEL_FLAT_I8 is array (natural range <>) of INT_8;
    -- type C_KERNEL_FLAT_3x3_I4 is array(0 to 9 - 1) of INT_4;
    -- type C_KERNEL_FLAT_3x3_I8 is array(0 to 9 - 1) of INT_8;
    -- -- Array to store the sign of the shifts, where 0 corresponds to positive (+) and 1 corresponds to negative (-)
    -- constant CONV_KERNEL_WEIGHT_SIGN_NEGATIVE : std_logic := '1';
    -- constant CONV_KERNEL_WEIGHT_SIGN_POSITIVE : std_logic := '0';
    -- type conv_kernel_3x3_weight_sign_t is array(0 to KERNEL_SIZE - 1) of std_logic;
    -- type conv_channel_kernel_shift_t is array (natural range <>) of conv_kernel_3x3_weight_shift_t;
    -- type conv_channel_kernel_sign_t is array (natural range <>) of conv_kernel_3x3_weight_sign_t;
    -- type conv_channel_array is array (natural range <>) of < element_type > ;
    
end package kernel_pkg;



package body kernel_pkg is

end package body;