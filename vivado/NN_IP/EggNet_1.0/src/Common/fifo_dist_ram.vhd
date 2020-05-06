library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity STD_FIFO is
	generic
	(
		DATA_WIDTH : integer := 8;
		FIFO_DEPTH : integer := 256;
		FIFO_STYLE : string  := "distributed"
	);
	port
	(
		Clk_i     : in STD_LOGIC;
		Rst_i     : in STD_LOGIC; -- Active High!
		WriteEn_i : in STD_LOGIC;
		Data_i    : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		ReadEn_i  : in STD_LOGIC;
		Data_o    : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		Empty_o   : out STD_LOGIC;
		Full_o    : out STD_LOGIC
	);
end STD_FIFO;

architecture Behavioral of STD_FIFO is

begin

	-- Memory Pointer Process
	fifo_proc : process (Clk_i)
		type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		variable Memory               : FIFO_Memory;
		attribute ram_style           : string;
		attribute ram_style of Memory : variable is FIFO_STYLE;

		variable Head : natural range 0 to FIFO_DEPTH - 1;
		variable Tail : natural range 0 to FIFO_DEPTH - 1;

		variable Looped : boolean;
	begin
		if rising_edge(Clk_i) then
			if Rst_i = '1' then
				Head := 0;
				Tail := 0;

				Looped := false;

				Full_o  <= '0';
				Empty_o <= '1';
			else
				if (ReadEn_i = '1') then
					if ((Looped = true) or (Head /= Tail)) then
						-- Update data output
						Data_o <= Memory(Tail);

						-- Update Tail pointer as needed
						if (Tail = FIFO_DEPTH - 1) then
							Tail := 0;

							Looped := false;
						else
							Tail := Tail + 1;
						end if;
					end if;
				end if;

				if (WriteEn_i = '1') then
					if ((Looped = false) or (Head /= Tail)) then
						-- Write Data to Memory
						Memory(Head) := Data_i;

						-- Increment Head pointer as needed
						if (Head = FIFO_DEPTH - 1) then
							Head := 0;

							Looped := true;
						else
							Head := Head + 1;
						end if;
					end if;
				end if;

				-- Update Empty_o and Full_o flags
				if (Head = Tail) then
					if Looped then
						Full_o <= '1';
					else
						Empty_o <= '1';
					end if;
				else
					Empty_o <= '0';
					Full_o  <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;