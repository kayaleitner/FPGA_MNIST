package kernel_pkg is
	constant KERNEL_SIZE : integer := 9;
    type weight_array_t is array (0 to KERNEL_SIZE - 1) of integer;
end package kernel_pkg;