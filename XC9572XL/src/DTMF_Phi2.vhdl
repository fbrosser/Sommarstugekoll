----------------------------------------------------------------------------------
-- 'Phi2' Clock generator
-- 
-- DTMF_Phi2.vhdl
--
-- Generates clock signal for DTMF Module (MT8880).
-- Implemented using a Mealy type state machine.
-- 
-- Sommarstugekoll, EDA234
--
-- @date 2011-10-31
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

Entity DTMF_Phi2 is
	port(
	 -- Clock
	 clk			: in  std_logic;
	 -- Asynchronous reset
	 rst			: in  std_logic;
	 -- Clock Enable
	 ce    : in  std_logic;
	 -- Output signal to MT8880
	 phi2		: out std_logic
	);
End Entity;

Architecture DTMF_Phi2_bhv of DTMF_Phi2 is

	-- States
	type stateType is (S0, S1, S2, S3, S4, S5, S6);

	-- Current state
	signal state : stateType;
	signal nextState : stateType;

	begin  
	-- Synchronous process: state changes
	SyncP: process(clk, rst)
	begin

	end process;

	-- Combinatorial Process
	CombP: process(state)

	begin

	end process;

End Architecture;
