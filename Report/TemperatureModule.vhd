----------------------------------------------------------------------------------
-- Temperature Module
-- DS18S20 1-Wire Communication
-- EDA234, Group 2
--
-- FILE
-- tempModule.vhd
-- Last Updated: 2011-12-11
--
-- VERSION
-- Hardware ("production") v1.5
--
-- HARDWARE
-- Target Device: XC9572XL
--
-- DESCRIPTION
-- Temperature module connected to two DS18S20 temperature sensors
-- communicating via a 1-wire serial protocol. 
-- Module has to be reset, then the control unit can request a (by setting tRd high)
-- temperature read/conversion from the selected temperature sensor
-- (tSel = 0 or 1 for sensor 0 and 1, respectively). When there is 
-- valid data on the bus (conversion and read cycle finished), the 
-- temperature module responds by setting tAv (temperature Available) high.
-- The temperature can the be read from the bus (temp[7..0]).
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Entity temperatureModule is
	port(	 	-- Global clock
				clk	  	:	in		std_logic;
				-- Global reset (Internal)
			   rstInt	:	in		std_logic;
				-- Temperature Read, trigger signal from Control Unit
			   tRd	 	:	in		std_logic;
				-- Signal to MUX, for selecting active sensor (0/1 for dq0/dq1, resp.)
				tSel		:	in		std_logic;
				
				-- Temperature Available, indicates valid data on temperature output bus
				tAv		: 	out	std_logic;
				-- Internal temperature data output
				temp		:	out	std_logic_vector(7 downto 0);
				
				-- Output to 1-Wire bus 1 (temperature sensor 0)
			   dq0     	: 	inout std_logic;
				-- Output to 1-Wire bus 0 (temperature sensor 1)
			   dq1     	: 	inout std_logic
	);
end temperatureModule;

Architecture Behavioral of temperatureModule is
	
	-- Internal signal declarations
	
	-- Buffer Enable
	signal E 					: std_logic;
	signal nextE				: std_logic;
	
	-- Valid data on temperature bus
	signal tAvInt				: std_logic;
	signal nexttAvInt			: std_logic;
	
	-- State variable (as integer)
	signal state 			 	: integer range 0 to 15;
	signal nextState 		 	: integer range 0 to 15;
	
	-- Data to be sent on bus
	signal data					: std_logic_vector(7 downto 0);
	signal nextData			: std_logic_vector(7 downto 0);
	
	-- Internal temperature data output
	signal tempOut				: std_logic_vector(7 downto 0);
	signal nexttempOut		: std_logic_vector(7 downto 0);
	
	-- Reading sign bit from sensor
	signal signBit				: std_logic;
	signal nextSignBit		: std_logic;
	
	-- Sampling of bus by master
	signal sample				: std_logic;
	signal nextSample			: std_logic;
	
	-- Counter used when sending a logical 0 on bus ('Zero Counter')
	signal ZC					: std_logic_vector(3 downto 0);
	signal nextZC  			: std_logic_vector(3 downto 0);
	
	-- Signal for keeping track of our progress through the read-cycle 
	signal progress  			: std_logic_vector(1 downto 0);
	signal nextProgress  	: std_logic_vector(1 downto 0);
	
	-- Counter for keeping track of which bit we are currently transmitting or sampling
	signal bitCnt				: std_logic_vector(2 downto 0);
	signal nextBitCnt			: std_logic_vector(2 downto 0);

	-- Internal counter used to create timing pulses
	signal cntInt    			: std_logic_vector(8 downto 0);
	signal nextCntInt    	: std_logic_vector(8 downto 0);
	
	-- Timing pulses, 512, 256, 8 and 4 us, respectively
	signal delayLong      	: std_logic;
	signal delayMedium	 	: std_logic;
	signal delayShort       : std_logic;
	signal delayTiny			: std_logic;
	
	-- Constants related to timing
	constant LongDelayConstant 	: std_logic_vector := "111111110";
	constant MediumDelayConstant 	: std_logic_vector := "11111111";
	constant ShortDelayConstant 	: std_logic_vector := "111";
	constant TinyDelayConstant 	: std_logic_vector := "11";
  	
	-- Base value (reset) for ZC
	constant ZCrst 					: std_logic_vector := "1010";

	-- Begin architecture
	begin
	
	-- Assign internal temperature available signal to output
	tAv 		<= tAvInt;
	-- Assign internal temperature bus to output
	temp 		<= tempOut;
	
----------------------------------------------------------------------------------		
-- SyncP, synchronous (clocked) process responsible for clocking in the new
-- states according to nextState
--
-- NB! : This is the only clocked process, 
-- keeping track of all state or value updates (current => next)
--
----------------------------------------------------------------------------------		
	SyncP : process(clk, rstInt)
	begin
		if(not(rstInt) = '1') then 
			state 	<= 0;
			cntInt 	<= (others => '0');
			progress <= (others => '0');
			bitCnt 	<= (others => '1');
			data 		<= (others => '1');
			tempOut 	<= (others => '1');
			ZC 		<= ZCrst; 
			sample 	<= '1';
			E 			<= '0';
			signBit 	<= '0';
			tAvInt	<= '0';
		elsif(clk'Event and clk = '1') then
			state 	<= nextState;
			ZC 		<= nextZC;
			E 			<= nextE;
			-- Increment internal counter
			cntInt 	<= nextCntInt;
			progress <= nextProgress;
			bitCnt 	<= nextBitCnt;
			data 		<= nextData;
			sample 	<= nextSample;
			tempOut 	<= nexttempOut;
			signBit 	<= nextSignBit;
			tAvInt 	<= nexttAvInt;
		end if;
	end process;
	
----------------------------------------------------------------------------------		
-- BusP, process responsible for handling the buffered output to the bus,
-- according to the enable signal.
-- Works as a buffer and MUX for the 1-wire buses
--
----------------------------------------------------------------------------------		
	BusP : process(E, tSel)
	begin
		-- Default : both buses in threestate
		dq0 <= 'Z';
		dq1 <= 'Z';
		-- Drive selected bus low if output enabled
		if (E = '1') then
			if(tSel = '0') then
				dq0 <= '0';
			elsif(tSel = '1') then
				dq1 <= '0';
			end if;
	   end if;
	end process;
	
----------------------------------------------------------------------------------		
-- CountP, internal counter responsible for creating pulses with certain
-- time intervals. Uses a local (to the Architecture) counter variable.
--
----------------------------------------------------------------------------------				
	CountP : process(cntInt)
	begin
		-- Increment internal counter
      nextCntInt <= cntInt + 1;
		-- Gives pulses every 4 us
		if(cntInt(1 downto 0) = TinyDelayConstant) then
			delayTiny <= '1';
		else
			delayTiny <= '0';
		end if;
		-- Gives pulses every 8 us
		if(cntInt(2 downto 0) = ShortDelayConstant) then
		  delayShort <= '1';
		else
		  delayShort <= '0';
		end if;    
		-- Gives pulses every 256 us
		if(cntInt(7 downto 0) = MediumDelayConstant) then
			delayMedium <= '1';
		else
			delayMedium <= '0';
		end if;
		-- Gives pulses every 512 us
		if(cntInt = LongDelayConstant) then
			delayLong 	<= '1';
			nextCntInt 	<= (others => '0');
		else
			delayLong 	<= '0';
		end if;  
	end process;
	
----------------------------------------------------------------------------------		
-- ComP, State Machine handling the master side of the 1-wire bus
-- communication with the DS18S20. Divided into stages/modes as follows:
--  
-- 1. INIT (Reset - Presence pulses)
-- 2. SEND (Transmission of data from Master to DS18S20)
-- 3. READ (Master reads data from DS18S20)
-- 4. IDLE (Bus is idle, pulled high by pull-up resistor)
--
----------------------------------------------------------------------------------		
	ComP : process(tRd, state, delayLong, delayMedium, delayShort, delayTiny, progress, ZC, bitCnt, tSel, dq0, dq1, sample, data, E, tempOut, signBit, tAvInt)
	begin
	
		-- Defaults
		nextState 		<= state;
		nextProgress 	<= progress;
		nextBitCnt 		<= bitCnt;
		nextZC 			<= ZC;
		nextSample 		<= sample;
		nextData 		<= data;
		nextE 			<= E;
		nexttempOut 	<= tempOut;
		nextSignBit 	<= signBit;
		nexttAvInt 		<= tAvInt;
		
		case state is
		
----------------------------------------------------------------------------------		  
-- INIT
----------------------------------------------------------------------------------		
			when 0 =>
			  -- Initialization of signals
			  nextProgress <= "00";
			  nextZC <= ZCrst;
			  nextSignBit 	<= '0';
			  nextE 	<= '0';
		    -- Wait for trigger from control unit
				if(tRd = '1') then
				  nextState  <= state + 1;
				  -- Entering the read cycle - data no longer valid
				  nexttAvInt <= '0';
				end if;
			when 1 =>
				-- Enable output and send logical 0
				nextE <= '0';
				if(delayLong = '1') then 
					nextState <= state + 1;
				end if;
			when 2 =>
				nextE <= '1';
				if(delayLong = '1') then 
					nextState <= state + 1;
					-- CCh, Skip ROM
					nextData <= X"CC";
				end if;				
			when 3 =>
				-- Put bus into threestate and wait for response
				nextE <= '0';
				if(delayLong = '1') then 
					nextState <= state + 1;
				end if;
				
----------------------------------------------------------------------------------		  
-- SEND
----------------------------------------------------------------------------------  
      -- Prepare for transmit of the byte in data
		  when 4 =>
			  -- Release bus and delay
		     nextE <= '0';
			  if(delayShort = '1') then
					nextState <= 5;
			  end if;		  
		  -- Send logical 0 or 1 by driving bus low for a certain number of shortDelay periods (1 for 1's, ZCrst for 0's)
		  when 5 =>
				-- Send logical 1
				if(data(7-conv_integer(bitCnt)) = '1' and delayShort = '1') then
					nextE <= '0';
					-- Write slot complete, reset iterator and send next bit
					if(ZC = "0000") then
						nextState <= state + 1;
						nextZC <= ZCrst;
					-- Drive bus low for one delay period
					elsif(ZC = ZCrst) then
						nextE <= '1';
						NextZC <= (ZC - 1);					
					-- Decrement iterator, bus is pulled high
					else
						NextZC <= (ZC - 1);
					end if;	
				-- Send logical 0
				elsif(data(7-conv_integer(bitCnt)) = '0' and delayShort = '1') then
					nextE <= '1';
					-- Write slot complete, reset iterator and send next bit
					if(ZC = "0000") then
						nextState <= state + 1;
						nextZC <= ZCrst;
					-- Decrement iterator, bus is kept low
					else
						NextZC <= (ZC - 1);
					end if;
				end if;
			-- Recovery time between transmitted bits, and decrementing bit counter
			when 6 =>
				nextE <= '0';
				if(delayShort = '1') then
					if(bitCnt = "000") then
						-- Done sending byte, move on and reset bit counter
						nextState <= state + 1;
						nextBitCnt <= (others => '1');
					else
						-- Send next bit
						nextBitCnt <= bitCnt - 1;
						nextState <= state - 1;
					end if;
				end if;		
			-- Done sending Command, disable buffer and prepare to send next byte,
			-- or if the temp sensor is converting temperature, wait for it to finish
			when 7 =>
			   nextE <= '0';
				if(delayShort = '1') then
					-- Converting temperature, go to read
					if(progress = "01") then
						nextState <= 9;
					-- Move on
					else
						nextState <= state + 1;
					end if;
				end if;
			-- Prepare to send next Command or start reading temperature
			when 8 =>
				nextE <= '0';
			  	-- Increase progress variable. NB: assignment at end of process, will compare with 'old' value!
				nextProgress <= progress + 1;
			   case progress is
			      when "00" =>
			         -- Issue Convert T Command (44h)
			         nextData 		<= X"44";
			         nextState 		<= 4;
			      when "01" =>
			         -- Do reset and Skip ROM (CCh)
						nextData 		<= X"CC";
						nextState 		<= 1;
			      when "10" =>
			         -- Issue Read Scratchpad Command (BEh)
			         nextData 		<= X"BE";
			         nextState 		<= 4;
			      when "11" =>
			         -- Master goes into Rx mode
			         nextState 	 	<= state + 1;
						nextProgress 	<= "11";
			      when others =>
			         -- We should not be here, something is terribly wrong: do full reset and start over
			         nextProgress 	<= "00";
			         nextState 		<= 0;
			   end case;
				
----------------------------------------------------------------------------------		  
-- READ
----------------------------------------------------------------------------------		  
----------------------------------------------------------------------------------		  
--
-- Master reads 9 bytes from the bus, starting with LSB of Byte 0
-- However, we are only interested in the temperature registers (Byte 0 and 1),
-- so a reset pulse is given after nine bits (8 temp + 1 sign) have been read,
-- telling the DS18S20 to discontinue transfer.
--
----------------------------------------------------------------------------------  
			-- Delay and prepare for read phase
			when 9 =>
				nextE <= '0';
				if(delayMedium = '1') then 
					nextState <= state + 1;
				end if;
			-- Pull bus low and wait for response (initiate read time slot, Tinit = 4 us)
			when 10 =>
				nextE <= '1';
				if(delayTiny = '1') then 
					nextState <= state + 1;
				end if;
			-- Release bus and allow pullup resistor to perform its magic (Trc = 4 us)	
			when 11 =>
				nextE <= '0';
				if(delayTiny = '1') then 
					nextState <= state + 1;
				end if;	
			-- Sample bus (Tsample = 4 us)	
			when 12 =>
				nextE <= '0';
				-- MUX'ed sampling from buses
				if(tSel = '0') then
					nextSample <= dq0;
				elsif(tSel = '1') then
					nextSample <= dq1;
				end if;
				if(delayTiny = '1') then 
					nextState <= state + 1;
				end if;					
			-- Recovery time between read slots
			when 13 =>
				nextE <= '0';
				if(delayMedium = '1') then 
					nextState <= state + 1;
				end if;	
			-- Go back and sample next bit (or wait for conversion to finish)
			when 14 =>	
				nextE <= '0';
				-- Reading 9th bit (temperature sign) and finishing up reading
				if(signBit = '1') then
					
					-- Negative temperature, perform 2-com. to sign-value conv.
					if(sample = '1') then
						nexttempOut <= (not(tempOut)) + 1;
					end if;
					
					nexttempOut(7) <= sample;
					nextState <= state + 1;
					nextProgress <= "00";
				else
					-- Waiting for conversion to finish
					if(progress = "01") then
						if(sample = '0') then
							nextState <= 10;
						elsif(sample = '1') then
							nextState <= 8;
						else
							nextState <= 10;
						end if;
					elsif(progress = "11") then
						nextState <= 10;
						-- Reading temperature bit
						if(bitCnt = "000") then
							nextBitCnt <= (others => '1');
							nexttempOut(7-conv_integer(bitCnt)) <= sample;
							nextSignBit <= '1';
						else
							nextBitCnt <= bitCnt - 1;
							nexttempOut(7-conv_integer(bitCnt)) <= sample;
						end if;
					-- Should not be here. If we are, go back and read again
					else
						nextState <= 10;
					end if;
				end if;
			
			when 15 =>
				-- Data on TOut bus is now valid. Go back and wait for next trigger.
				nexttAvInt 	<= '1';
				nextE 		<= '0';
				nextState 	<= 0;
						
			-- Other states. Should never be here.
			when others => 
				nextE 		<= '0';
				nextState 	<= 0;
				
		end case;	
	end process;
end Behavioral;

