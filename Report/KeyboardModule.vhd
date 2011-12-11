--------------------------------------------------------------------------------
-- Keyboard Module
-- EDA234, Group 2
--
-- FILE
-- KeyboardModule.vhd
-- Last Updated: 2011-12-06
--
-- VERSION
-- Hardware ("production") v1.2
--
-- HARDWARE
-- Target Device: XC9572XL
--
-- DESCRIPTION
-- Synchronization and Available / Ack Data Transfer from Keyboard
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Entity KeyboardModule is
	port(	-- Global clock
			clk				: in		std_logic;
			-- Global reset
			rstInt			: in		std_logic;
			-- Data Available signal from Keyboard 
			kbAvIn			: in		std_logic;
			-- Data from Keyboard
			kbDataIn			: in		std_logic_vector(3 downto 0);
			-- Acknowledgement signal from Control Unit
			kbAck				: in		std_logic;
			-- Data output to Control Unit
			kbDataOut		: out		std_logic_vector(3 downto 0);
			-- Data Available signal output to Control Unit
			kbAvOut			: out		std_logic
	);
end KeyboardModule;

Architecture Behavioral of KeyboardModule is

   	-- State variable (as integer)
	signal state 			 	: integer range 0 to 3;
	signal nextState 		 	: integer range 0 to 3;
	signal kbDataOutInt		: std_logic_vector(3 downto 0);
	signal nextKBDataOutInt	: std_logic_vector(3 downto 0);
	
begin

	-- Concurrent Assignment
	kbDataOut			<= kbDataOutInt;
	
	syncP : process(clk, rstInt)
	begin
		if(not(rstInt) = '1') then
			state 			<= 0;
			kbDataOutInt 	<= (others => '0');
		elsif(clk'Event and clk = '1') then
			state 			<= nextState;
			kbDataOutInt 	<= nextKBDataOutInt;
		end if;
	end process;
	
	keyboardP : process(kbDataIn, kbAvIn, kbAck, state, kbDataOutInt)
	begin
	
		-- Defaults
		nextState 			<= state;
		nextKBDataOutInt 	<= kbDataOutInt;
		
		case state is
			when 0 =>
				kbAvOut <= '0';
				if(kbAvIn = '1') then
					nextState <= state + 1;
				end if;
			when 1 =>
				kbAvOut <= '1';
				nextKBDataOutInt <= kbDataIn;
				nextState <= state + 1;
			when 2 =>
				kbAvOut <= '1';
				if(kbAck = '1') then
					nextState <= state + 1;
				end if;
			when 3 =>
				kbAvOut <= '0';
				if(kbAvIn = '0') then
					nextState <= 0;
				end if;
			end case;
	end process;
		
end Behavioral;
