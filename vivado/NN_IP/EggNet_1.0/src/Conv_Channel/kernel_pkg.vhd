library ieee;
use ieee.std_logic_1164.all;

package kernel_pkg is
    constant KERNEL_SIZE : INTEGER := 9;
    type weight_array_t is array (0 to KERNEL_SIZE - 1) of INTEGER;

    constant KERNEL_WIDTH : NATURAL := 3;
    constant KERNEL_HEIGHT : NATURAL := 3;
    type kernel_weight_slice_t is array(0 to KERNEL_HEIGHT) of INTEGER; 
    type kernel_weight_2d_t is array(0 to KERNEL_HEIGHT-1) of kernel_weight_slice_t; 

    -- Array to store the amount of the shifts, corresponding to nonlinear quantization
    type conv_kernel_3x3_weight_shift_t is array(0 to KERNEL_SIZE-1) of INTEGER;
    
    -- Array to store the sign of the shifts, where 0 corresponds to positive (+) and 1 corresponds to negative (-)
    constant CONV_KERNEL_WEIGHT_SIGN_NEGATIVE : std_logic := '1';
    constant CONV_KERNEL_WEIGHT_SIGN_POSITIVE : std_logic := '0';
    type conv_kernel_3x3_weight_sign_t is array(0 to KERNEL_SIZE-1) of std_logic;

end package kernel_pkg;