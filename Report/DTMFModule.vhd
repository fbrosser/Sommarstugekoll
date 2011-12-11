--------------------------------------------------------------------------------
-- DTMF Module
-- EDA234, Group 2
--
-- FILE
-- DTMFModule.vhd
-- Last Updated: 2011-12-09
--
-- VERSION
-- Hardware ("production") v1.1
--
-- HARDWARE
-- Target Device: XC9572XL
--
-- DESCRIPTION
-- DTMF Module, responsible for decoding DTMF data and presenting it
-- to the control unit.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DTMFModule is
port(
	-- Clock
	clk							: in std_logic;
	-- Asynchronous reset
	rst							: in std_logic;
	-- Start signal
	sigInit						: in std_logic;
	-- Early steering from DTMF chip via IRQ pin
	irq							: in std_logic;
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
	intDataBus					: out std_logic_vector (3 downto 0)
	
	);	
end DTMFModule;

architecture Behavioral of DTMFModule is
	
	-- State declaration
	type stateType is (	s0,  s1,  s2,  s3,  s4,  s5,  s6,  s7,  s8,  s9,  s10, s11, s12, s13, s14, s15,
						s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29);
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
	stateP : process(state, sigInit, dataToControl, irq, extDataBus, ack)
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
		
		-- Send data to control unit		
		intDataBus <= dataToControl;
		
		case state is
			when s0 =>
				if (sigInit = '0') then
					nextState <= s1;
				end if;
				
			-- 1) Read Status Register
			when s1 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s2;
			when s2 =>
				rs0 <= '1';
				rw <= '1';
				phi2 <= '1';
				nextState <= s3;
			when s3 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s4;
				
			-- 2) Write "0000" to Control Register A
			when s4 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s5;
			when s5 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s6;
			when s6 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s7;
				
			-- 3) Write "0000" to Control Register A
			when s7 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s8;
			when s8 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s9;
			
			-- 4) Write "1000" to Control Register A
			when s9 =>
				rs0 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s10;
			when s10 =>
				rs0 <= '1';
				phi2 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s11;
			when s11 =>
				rs0 <= '1';
				outDataBus <= "1000";
				outputEnable <= '1';
				nextState <= s12;
			
			-- 5) Write "0000" to Control Register B
			when s12 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s13;
			when s13 =>
				rs0 <= '1';
				phi2 <= '1';
				outputEnable <= '1';
				nextState <= s14;
			when s14 =>
				rs0 <= '1';
				outputEnable <= '1';
				nextState <= s15;
				
			-- 6) Read Status Register
			when s15 =>
				rs0 <= '1';
				rw <= '1';
				nextState <= s16;
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
			-- b3 set Write to CRB in next write phase
			when s18 =>
				rs0 <= '1';
				outDataBus <= "1101";
				outputEnable <= '1';
				nextState <= s19;
			when s19 =>
				rs0 <= '1';
				phi2 <= '1';
				outDataBus <= "1101";
				outputEnable <= '1';
				nextState <= s20;
			when s20 =>
				rs0 <= '1';
				outDataBus <= "1101";
				outputEnable <= '1';
				nextState <= s21;
			
			-- Write "0010" to Control Register B
			-- b0 clr Enable burst mode
			-- b1 set Enable test mode
			-- b2 clr Disable single tone generation
			-- b3 clr Don't care as single tone generations is not active
			when s21 =>
				rs0 <= '1';
				outDataBus <= "0010";
				outputEnable <= '1';
				nextState <= s22;
			when s22 =>
				rs0 <= '1';
				phi2 <= '1';
				outDataBus <= "0010";
				outputEnable <= '1';
				nextState <= s23;
			when s23 =>
				rs0 <= '1';
				outDataBus <= "0010";
				outputEnable <= '1';
				nextState <= s24;
			
			-- Idle state
			when s24 =>
				-- Wait for DTMF data present in the DTMF chip
				if (irq = '0') then
					nextState <= s25;
				end if;
			
			-- Read DTMF data from MT8880C
			when s25 =>
				rw <= '1';
				nextState <= s26;
			when s26 =>
				rw <= '1';
				phi2 <= '1';
				nextState <= s27;
			when s27 =>
				rw <= '1';
				phi2 <= '1';
				nextDataToControl <= extDataBus;
				nextState <= s28;
			when s28 =>
				rw <= '1';
				dav <= '1';
				nextState <= s29;
				
			-- Wait for control unit to acknowledge data
			when s29 =>
				dav <= '1';
				if (ack = '1') then
					nextState <= s24;
				end if;
			
			when others =>
				nextState <= s0;
				
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
		
end Behavioral;
