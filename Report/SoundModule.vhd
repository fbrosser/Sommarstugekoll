--------------------------------------------------------------------------------
-- Sound Module
-- EDA234, Group 2
--
-- FILE
-- SoundModule.vhd
-- Last Updated: 2011-12-11
--
-- VERSION
-- Hardware ("production") v1.0
--
-- HARDWARE
-- Target Device: XC9572XL
--
-- DESCRIPTION
-- Controlling external sound chip
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity isdctrl is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  
			  -- To/From control unit
           play : in  STD_LOGIC; 
           ct : in  STD_LOGIC;
			  ctrlAddr : in  STD_LOGIC_VECTOR (3 downto 0);
			  done : out STD_LOGIC;
			  
			  -- From temp module
			  tempAddr : in STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- To/From ISD2560
           eom : in  STD_LOGIC;
           outAddr : out  STD_LOGIC_VECTOR (5 downto 0);
           ce : out  STD_LOGIC);
end isdctrl;

architecture Behavioral of isdctrl is
type state_type is (s0, s1c, s1t, s1to, s2c, s2t, s2to, s3c, s3tm, s3tp, s4tm, s4tp);
signal state, nstate: state_type;
begin

process (eom, play, ct, tempAddr, ctrlAddr, state)
begin
	outAddr <= "000000";
	ce <= '1';			-- Chip Enable active low
	done <= '0';
	nstate <= state;
	
	case state is 
		-- Base state
		when s0 =>
			if play = '1' then
				if ct = '1' then	
					nstate <= s1c;	-- Control unit address
				else
					if tempAddr(6) = '0' then
						nstate <= s1t; 	-- Temp unit address
					else 
						nstate <= s1to;	-- Temp overflow
					end if;
				end if;
			end if;

		-- Control unit addressing
		when s1c =>
			outAddr <= "10" & ctrlAddr;
			nstate <= s2c;
		when s2c =>
			outAddr <= "10" & ctrlAddr;
			ce <= '0';
			if eom = '1' then
				nstate <= s2c; 	-- Wait for sound to finish
			else 
				nstate <= s3c;
			end if;
		when s3c =>
			done <= '1';
			nstate <= s0;

		-- Temp module addressing
		when s1t =>					-- "Regular" address
			outAddr <= tempAddr(5 downto 0);
			nstate <= s2t;
		when s1to =>				-- Overflow case
			outAddr <= "111111";
			nstate <= s2to;
		when s2t =>					
			outAddr <= tempAddr(5 downto 0);
			ce <= '0';
			if eom = '1' then
				nstate <= s2t; 	-- Wait for sound to finish
			else 
				if tempAddr(7) = '0' then
					nstate <= s3tm;
				else 
					nstate <= s3tp;
				end if;
			end if;			
		when s2to =>
			outAddr <= "111111";
			ce <= '0';
			if eom = '1' then
				nstate <= s2to; 	-- Wait for sound to finish
			else 
				if tempAddr(7) = '0' then
					nstate <= s3tm;
				else 
					nstate <= s3tp;
				end if;
			end if;
		when s3tm =>
			outAddr <= "100011";
			nstate <= s4tm;
		when s3tp =>
			outAddr <= "100010";
			nstate <= s4tp;
		when s4tm => 
			outAddr <= "100011";
			ce <= '0';
			if eom = '1' then
				nstate <= s4tm; 	-- Wait for sound to finish
			else 
				nstate <= s3c;
			end if;
		when s4tp => 
			outAddr <= "100010";
			ce <= '0';
			if eom = '1' then
				nstate <= s4tp; 	-- Wait for sound to finish
			else 
				nstate <= s3c;
			end if;
		when others =>
	end case;
end process;

process (clk)
begin
	if clk'event and clk = '1' then
		if(not(reset = '1')) then
			state <= s0;
		else
			state <= nstate;
		end if;
	end if;
end process;


end Behavioral;

