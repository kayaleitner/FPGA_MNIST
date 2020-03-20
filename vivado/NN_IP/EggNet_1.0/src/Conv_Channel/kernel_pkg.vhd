package kernel_pkg is
    constant KERNEL_SIZE : INTEGER := 9;
    type weight_array_t is array (0 to KERNEL_SIZE - 1) of INTEGER;

    -- Array to store the amount of the shifts, corresponding to nonlinear quantization
    type conv_kernel_3x3_weight_shift_t is array(0 to KERNEL_SIZE-1) of INTEGER;
    
    -- Array to store the sign of the shifts, where 0 corresponds to positive (+) and 1 corresponds to negative (-)
    constant CONV_KERNEL_WEIGHT_SIGN_NEGATIVE : BIT = '1';
    constant CONV_KERNEL_WEIGHT_SIGN_POSITIVE : BIT = '0';
    type conv_kernel_3x3_weight_sign_t is array(0 to KERNEL_SIZE-1) of BIT;

end package kernel_pkg;