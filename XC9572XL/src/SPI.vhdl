----------------------------------------------------------------------------------
-- SPI Serial Communication
-- 
-- SPI.vhdl
--
-- Serial Communication using SPI (for four bits)
-- 
-- Sommarstugekoll, EDA234
--
-- @date 2011-11-06
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Entity SPI is
    Port ( data 	: in  	STD_LOGIC_VECTOR (3 downto 0);
           clk 		: in  	STD_LOGIC;
           reset 	: in  	STD_LOGIC;
           sck 		: out  STD_LOGIC;
           sdi 		: out  STD_LOGIC;
           cs 		: out  STD_LOGIC;
           oe 		: out  STD_LOGIC);
End Entity;

Architecture SPI_bhv of SPI is
	signal T 		: integer range 0 to 37;
	signal nextT 	: integer range 0 to 37;	 
begin
	oe <= '0';
	
	SyncP : process(clk)
	begin
		if(clk'Event and clk = '1') then 
			if(reset = '1') then
				T <= 0;
			else
				T <= nextT;
			end if;
		end if;
	end process;
	
	CombP : process(T, data)
	begin
		cs <= '0';
		sck <= '0';
		sdi <= '0';
		nextT <= T + 1;
		
		case(T) is
			when 0 => cs <= '1';
			when 3 => sck <= '1';
			when 5 => sck <= '1';
			when 6 => sdi <= '1';
			when 7 => sck <= '1'; sdi <= '1';
			when 8 => sdi <= '1';
			when 9 => sck <= '1'; sdi <= '1';
			when 10 => sdi <= data(3);
			when 11 => sdi <= data(3); sck <= '1';
			when 12 => sdi <= data(2);
			when 13 => sdi <= data(2); sck <= '1';
			when 14 => sdi <= data(1);
			when 15 => sdi <= data(1); sck <= '1';
			when 16 => sdi <= data(0);
			when 17 => sdi <= data(0); sck <= '1';
			when 19 | 21 | 23 | 25 | 27 | 29 | 31 | 33 => sck <= '1';
			when 35 => cs <= '1'; sck <= '1';
			when 36 => cs <= '1'; nextT <= 0;
			when others =>
		end case;
	end process;
End Architecture;

