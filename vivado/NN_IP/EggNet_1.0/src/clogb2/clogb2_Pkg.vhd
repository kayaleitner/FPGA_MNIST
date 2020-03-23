library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package clogb2_Pkg is

	-- # TODO Logarithms are not defined for negative values -> change interface to NATURAL instead of INTEGER
	function clogb2 (bit_depth : INTEGER) return INTEGER;

end clogb2_Pkg;

package body clogb2_Pkg is

	function clogb2 (bit_depth : INTEGER) return INTEGER is
		variable depth : INTEGER := bit_depth;
		variable count : INTEGER := 1;
	begin
		for i in 1 to bit_depth loop -- Works for up to 32 bit integers
			if (bit_depth <= 2) then
				count := 1;
			else
				if (depth <= 1) then
					count := count;
				else
					depth := depth / 2;
					count := count + 1;
				end if;
			end if;
		end loop;
		return(count);
	end;

end clogb2_Pkg;