--------------------------------------------------------------------------------
-- Control Unit
-- Fredrik Brosser
-- EDA234, Group 2
--
-- FILE
-- ControlUnit.vhd
-- Last Updated: 2011-11-27
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
			  
			  -- Push Buttons (Human Interface)
				Buttons		: in		std_logic_vector(3 downto 0);
			  --FuncButton0 	: in   	std_logic;
			  --FuncButton1 	: in   	std_logic;
			  --TRdButton 		: in   	std_logic;
			  --TSelButton 	: in   	std_logic;

			  -- Read Temperature command signal to Temperature module
				TRd     		: out  	std_logic;
			  -- Select signal for temperature sensors (sensor 0/1)
				TSel    		: out 	std_logic;
			  -- Temperature Available signal from Temperature module
				TAv				: in  	std_logic;			  
			  -- Delay signal (from Temperature module)
				delay			: in		std_logic;
			  
			  -- Function control output to Function module
				Func    		: out  	std_logic_vector(3 downto 0);
			  -- Enable signal for Function module
				En				: out		std_logic;
			  
				-- Data input from DTMF module
				DTMFData		: in  	std_logic_vector(3 downto 0);
				-- Data available signal from DTMF module
				DAv			: in		std_logic;
				-- Acknowledgement signal to DTMF module
				Ack			: out		std_logic
				
			  -- Will be adding more signals later on. Something like :
			 
			  -- R/W'              out (DTMF module)
			  -- Play              out (Sound module)
			  -- DoneS             in  (ound module)
	);
end ControlUnit;

Architecture Behavioral of ControlUnit is
  
   	-- State variable (as integer)
	signal state 			 	: integer range 0 to 3;
	signal nextState 		 	: integer range 0 to 3;
	
	signal TSelStatus 		: std_logic;
	signal nextTSelStatus 	: std_logic;
  
	begin

		TSel <= TSelStatus;
		En <= '1';
	
		SyncP : process(clk, rstInt)
		begin
			if(not(rstInt) = '1') then
				state 		<= 0;
				TSelStatus 	<= '0';
				Func 			<= (others => '0');
			elsif(clk'Event and clk = '1') then
				state 		<= nextState;
				TSelStatus 	<= nextTSelStatus;
				Func <= Buttons(3 downto 2) & "00";
			end if;
		end process;
		
		TempP : process(Buttons, state, delay, TAv, TSelStatus)
		begin
			-- Defaults
			nextState <= state;
			nextTSelStatus <= TSelStatus;
			Ack <= '0';
			
			case state is
				when 0 =>
					-- OFF State
					TRd <= '0';
					if(Buttons(0) = '1' and delay = '1') then
						nextState <= state + 1;
					end if;
				when 1 =>
					TRd <= '1';
					--nextTSelStatus <= Buttons(1);
					if(DAv = '1') then
						Ack <= '1';
						if (DTMFData = "0001") then 
							nextTSelStatus <= '1';
						else 
							nextTSelStatus <= '0';
						end if;
					end if;
					--if(Buttons(1) = '1' and delay = '1') then
					--	nextTSelStatus <= not(TSelStatus);
					--end if;
					if(delay = '1') then
						nextState <= state + 1;
					end if;
				when 2 =>
					TRd <= '0';
					if(delay = '1') then
						nextState <= state + 1;
					end if;
				when 3 =>
					TRd <= '0';
					if(TAv = '1' and delay = '1') then
						nextState <= 0;
					end if;
			end case;
		end process;
end Behavioral;

