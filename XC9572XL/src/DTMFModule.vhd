----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:36:10 11/23/2011 
-- Design Name: 
-- Module Name:    dtmfDecoder - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dtmfdecoder is
port(
	-- Clock
	clk							: in std_logic;
	-- Asynchronous reset
	rst							: in std_logic;
	-- Start signal
	sigInit						: in std_logic;
	-- Early steering from DTMF chip
	est							: in std_logic;
	-- Acknowledge signal from control unit
	ack							: in std_logic;
	-- Input vector
	extDataBus 					: inout std_logic_vector (3 downto 0);
	-- Phi2 clock
	phi2						: out std_logic;
	-- Read/Write select
	rw							: out std_logic;
	-- Register select
	rs0 						: out std_logic;
	-- Data valid signal to control unit
	dav							: out std_logic;
	-- Data bus to control unit
	intDataBus					: out std_logic_vector (3 downto 0);
	-- LED DEBUG
	led							: out std_logic_vector (3 downto 0));	
end dtmfdecoder;

architecture dtmfDecoder_bhv of dtmfDecoder is
	
	-- State declaration
	type stateType is (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26);
	-- Current state
	signal state				: stateType;
	-- Next state	
	signal nextState			: stateType;
	-- Data to control unit
	signal dataToControl		: std_logic_vector(3 downto 0);
	-- Next data to control unit
	signal nextDataToControl	: std_logic_vector(3 downto 0);
	-- Output drive enable
	signal outputEnable			: std_logic;
	-- Internal output data bus
	signal outDataBus			: std_logic_vector(3 downto 0);
	-- Internal input data bus
	
begin
	-- Synchronous process controling state changes
	syncP : process(clk, rst)
	begin
		-- Asynchronous reset, active high
		if (rst = '0') then
			state <= s0;
			dataToControl <= "0000";
		-- Trigger state changes on positive clock flank
		elsif (clk'Event and clk = '1') then
			state <= nextState;
			dataToControl <= nextDataToControl;
		end if;
	end process;

	-- Asynchronous process describing states
	stateP : process(state, sigInit, dataToControl, est, extDataBus, ack)
	begin
		-- Assign default values to signals
		phi2 <= '0';
		rw <= '0';
		rs0 <= '0';
		outputEnable <= '0';
		outDataBus <= "0000";
		--inDataBus <= "0000";
		nextState <= state;
		dav <= '0';
		nextDataToControl <= dataToControl;
		led <= "1111";
		
		-- Send data to control unit		
		intDataBus <= dataToControl;
		
		case state is
			when s0 =>
				if (sigInit = '0') then
					nextState <= s1;
				end if;
				led <= "1110";
				
			-- 1) Read Status Register
			when s1 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s2;
				-- led <= "0001";
			when s2 =>
				rs0 <= '1';
				rw <= '1';
				phi2 <= '1';
				nextState <= s3;
				-- led <= "0010";
			when s3 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s4;
				-- led <= "0011";
				
			-- 2) Write "0000" to Control Register A
			when s4 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s5;
				-- led <= "0100";
			when s5 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s6;
				-- led <= "0101";
			when s6 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s7;
				-- led <= "0110";
				
			-- 3) Write "0000" to Control Register A
			when s7 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s8;
				-- led <= "0111";
			when s8 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s9;
				-- led <= "1000";
			
			-- 4) Write "1000" to Control Register A
			when s9 =>
				rs0 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s10;
				-- led <= "1001";
			when s10 =>
				rs0 <= '1';
				phi2 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s11;
				-- led <= "1010";
			when s11 =>
				rs0 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s12;
				-- led <= "1011";
			
			-- 5) Write "0000" to Control Register B
			when s12 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s13;
				-- led <= "1100";
			when s13 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s14;
				-- led <= "1101";
			when s14 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s15;
				-- led <= "1110";
				
			-- 6) Read Status Register
			when s15 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s16;
				-- led <= "1111";
			when s16 =>
				rs0 <= '1';
				rw <= '1';
				phi2 <= '1';
				nextState <= s17;
			when s17 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s18;
				
			-- Chip init ready, now init chip interface
			-- Write "1101" to Control Register A
			-- b0 set Enable tone output
			-- b1 clr Enable DTMF
			-- b2 set Enable IRQ
			-- b3 clr Do not write to CRB in next write phase
			when s18 =>
				rs0 <= '1';
				outDataBus <= "0101";
				outputEnable <= '1';
				nextState <= s19;
			when s19 =>
				rs0 <= '1';
				phi2 <= '1';
				outDataBus <= "0101";
				outputEnable <= '1';
				nextState <= s20;
			when s20 =>
				rs0 <= '1';
				outDataBus <= "0101";
				outputEnable <= '1';
				nextState <= s21;
			
			-- Idle state
			when s21 =>
				-- Wait for DTMF data present in the DTMF chip
				if (est = '1') then
					nextState <= s22;
				end if;
				led <= "0000";
			
			-- Read DTMF data from MT8880C
			when s22 =>
				rw <= '1';
				nextState <= s23;
			when s23 =>
				rw <= '1';
				phi2 <= '1';
				nextState <= s24;
			when s24 =>
				rw <= '1';
				phi2 <= '1';
				nextDataToControl <= extDataBus;
				nextState <= s25;
			when s25 =>
				rw <= '1';
				dav <= '1';
				nextState <= s26;
				
			-- Wait for control unit to acknowledge data
			when s26 =>
				dav <= '1';
				--if (ack = '1') then
					nextState <= s21;
				--end if;
				
		end case;

	end process;
	
	-- Asynchronous process controling tristate outputs
	ouputEnableP : process(outputEnable, outDataBus)
	begin
		if (outputEnable = '1') then
			extDataBus <= outDataBus;
		else
			extDataBus <= "ZZZZ";
		end if;
	end process;
		
end dtmfDecoder_bhv;
