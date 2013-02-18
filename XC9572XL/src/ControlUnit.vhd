--------------------------------------------------------------------------------
-- Control Unit
-- Fredrik Brosser
-- EDA234, Group 2
--
-- FILE
-- ControlUnit.vhd
-- Last Updated: 2011-12-10
--
-- VERSION
-- Hardware ("production") v1.0
--
-- HARDWARE
-- Target Device: XC9572XL
-- I/O Pins Used:
-- Macrocells Used:
-- Product Terms Used:
--
-- DESCRIPTION
-- The Control Unit
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Entity ControlUnit is
	port(	  -- Global clock
				clk				: in		std_logic;
			  -- Global reset
				rstInt			: in		std_logic;
			  
			  -- Switch for ON/OFF (Human Interface)
				button			: in		std_logic;

			  -- TEMPERATURE MODULE
			  -- Read Temperature command signal to Temperature module
				tRd     		: out  	std_logic;
			  -- Select signal for temperature sensors (sensor 0/1)
				tSel    		: out 	std_logic;
			  -- Temperature Available signal from Temperature module
				tAv				: in  	std_logic;
			  
			  -- FUNCTION MODULE
			  -- Function control output to Function module
				func    		: out  	std_logic_vector(3 downto 0);
			  -- Enable signal for Function module
				en				: out		std_logic;
			  
			   -- DTMF MODULE
				-- Data input from DTMF module
				dData		: in  	std_logic_vector(3 downto 0);
				-- Data available signal from DTMF module
				dAv			: in		std_logic;
				-- Acknowledgement signal to DTMF module
				dAck			: out		std_logic;

				-- Call In Progress-signal
				cIP			: in		std_logic;
				
				-- KEYBOARD MODULE
				-- Data input from keyboard
				kData			: in		std_logic_vector(3 downto 0);
				-- Data available signal from keyboard
				kAv			: in		std_logic;
				-- Acknowledgement signal from keyboard
				kAck			: out		std_logic;
				-- Keyboard Output Enable
				kOe			: out		std_logic;
				
				-- SOUND MODULE
				-- Done (playing sound) signal from Sound module
				sDone			: in		std_logic;
				-- Play signal to Sound module
				sPlay			: out		std_logic;
				-- Select signal to Sound module (temp / sound)
				sSel			: out		std_logic;
				-- Address bus to Sound Module
				sAddr			: out		std_logic_vector(3 downto 0)


	);
end ControlUnit;

Architecture Behavioral of ControlUnit is
  
   	-- State variable (as integer)
	signal state 			 	: integer range 0 to 3;
	signal nextState 		 	: integer range 0 to 3;
	
	signal funcStatus 		: std_logic_vector(3 downto 0);
	signal nextFuncStatus 	: std_logic_vector(3 downto 0);	
	
	signal tSelStatus 		: std_logic;
	signal nextTSelStatus 	: std_logic;
	
	signal sAddrInt			: std_logic_vector(3 downto 0);
	signal nextSAddrInt		: std_logic_vector(3 downto 0);
	
	signal sPlayInt			: std_logic;
	signal nextSPlayInt		: std_logic;
		
	signal sSelInt				: std_logic;
	signal nextSSelInt		: std_logic;
	
	begin

		tSel 	<= tSelStatus;
		func 	<= funcStatus;
		sAddr <= sAddrInt;
		sPlay <= sPlayInt;
		sSel 	<= sSelInt;
	
		-- Synchronous (clocked) process, handing state changes
		syncP : process(clk, rstInt)
		begin
			if(not(rstInt) = '1') then
				state 		<= 0;
				tSelStatus 	<= '0';
				funcStatus 	<= (others => '0');
				sAddrInt		<= (others => '0');
				sPlayInt		<= '0';
				sSelInt		<= '0';
			elsif(clk'Event and clk = '1') then
				state 		<= nextState;
				tSelStatus 	<= nextTSelStatus;
				funcStatus 	<= nextFuncStatus;
				sAddrInt		<= nextSAddrInt;
				sPlayInt		<= nextSPlayInt;
				sSelInt		<= nextSSelInt;
			end if;
		end process;
		
		commandP : process(dAv, dData, kAv, kData, funcStatus, tSelStatus, sSelInt, sAddrInt, sPlayInt)
		begin
		
			kOe				<= '0';
			nextTSelStatus <= TSelStatus;
			nextFuncStatus <= FuncStatus;
			nextSAddrInt 	<= SAddrInt;
			nextSSelInt		<= SSelInt;
			nextSPlayInt	<= SPlayInt; 
			
			dAck <= '0';
			kAck <= '0';
			en <= '0';
			
			-- Command from Manual Control Panel
			if(kAv = '1') then
				kAck <= '1';
				case kData(2 downto 0) is
					when "000" =>	-- 1
						nextSAddrInt	<= "1111";
						nextSSelInt 	<= '1';
						nextSPlayInt 	<= '1';
						en <= '1';
						nextFuncStatus(0) <= '1';
					when "001" =>	-- 2
						en <= '1';
						nextFuncStatus(1) <= '1';
					when "010" =>	-- 3
						en <= '1';
						nextFuncStatus(2) <= '1';
					when "011" =>	-- A
						nextTSelStatus <= '0';
					when "100" =>	-- 4
						en <= '1';
						nextFuncStatus(0) <= '0';
					when "101" =>	-- 5
						en <= '1';
						nextFuncStatus(1) <= '0';
					when "110" =>	-- 6
						en <= '1';
						nextFuncStatus(2) <= '0';
					when "111" =>	-- B
						nextTSelStatus <= '1';
					--when "1000" => -- 7
					--	En <= '1';
					--	nextFuncStatus(3) <= '1';
					--when "1001" => -- 8
					--	En <= '1';
					--	nextFuncStatus(3) <= '0';
					when others =>
				end case;
			-- Command from DTMF Module
			elsif(dAv = '1') then
				dAck <= '1';
				-- Respond to input
				case dData is
					when "0001" =>	-- 1
						en <= '1';
						nextFuncStatus(0) <= '1';
					when "0010" =>	-- 2
						en <= '1';
						nextFuncStatus(1) <= '1';
					when "0011" =>	-- 3
						en <= '1';
						nextFuncStatus(2) <= '1';
					when "0100" =>	-- 4
						en <= '1';
						nextFuncStatus(0) <= '0';
					when "0101" =>	-- 5
						en <= '1';
						nextFuncStatus(1) <= '0';
					when "0110" =>	-- 6
						en <= '1';
						nextFuncStatus(2) <= '0';
					when "0111" =>	-- 7
						en <= '1';
						nextFuncStatus(3) <= '1';
					when "1000" => -- 8
						en <= '1';
						nextFuncStatus(3) <= '0';
					when "1001" => -- 9
						nextTSelStatus <= '1';
					when "1010" => -- 0
						nextTSelStatus <= '0';
					when others =>		
				end case;
			end if;
			
		end process;
		
		-- Process handing the temperature reading and sounds
		tempP : process(button, state, tAv)
		begin
			-- Defaults
			nextState <= state;
	
			case state is
				when 0 =>
					-- OFF State
					tRd <= '0';
					if(button = '1') then
						nextState <= state + 1;
					end if;
				when 1 =>
					tRd <= '1';
					nextState <= state + 1;
				when 2 =>
					tRd <= '0';
					nextState <= state + 1;
				when 3 =>
					tRd <= '0';
					if(tAv = '1') then
						nextState <= 0;
					end if;
			end case;
	end process;
end Behavioral;

