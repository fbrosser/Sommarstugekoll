-- SEQUENCE DETECTOR
-- seqDet.vhd
--
-- Code detector for authenticating user :
-- 'unlocks' access to menu when given a certain
-- sequence as input. Uses 4 bit vectors (for DTMF).
-- Implemented using a mealy type state machine.
-- 
-- Sommarstugekoll, EDA234
--
-- @author Fredrik Brosser
-- @date 2011-10-27 11:25
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

Entity seqDet is
	port( 
	 -- Clock
	 clk                   : in  std_logic;
	 -- Asynchronous reset
	 rst                   : in  std_logic;
	 -- Clock Enable
	 ce                    : in  std_logic;
	 -- Input vector
	 input                 : in  std_logic_vector(3 downto 0);
	 -- Lock
	 lock                  : out std_logic
	);
End Entity;

Architecture seqDet_bhv of seqDet is

	-- States
	type state_type is (S0, S1, S2, S3, UL);
	-- Current state
	signal state : state_type;
	signal next_state : state_type;

	-- 'Secret' code 1234
	constant code0 : std_logic_vector := "0001";
	constant code1 : std_logic_vector := "0010";
	constant code2 : std_logic_vector := "0011";
	constant code3 : std_logic_vector := "0100";

	begin  
	-- Synchronous process: state changes
	ASM_P: process(clk, rst)
	begin
		-- Asynchronous reset, active high
		if (rst = '1') then
			state <= S0;
		else
		 -- Trigger on positive clock flank
			 if (clk'Event and clk = '1' and ce = '1') then
			  	state <= next_state;
			end if;
		end if;

	end process;

	-- Combinatorial Process
	COMB_P: process(state, input)
	begin
		-- Assign default values
		lock <= '1';
		next_state <= S0;

		case state is
			when S0 =>
				if (input = code0) then
					next_state <= S1;
				end if;
			when S1 =>
				if (input = code1) then
				   	next_state <= S2;
				end if;
			when S2 =>
			 	if (input = code2) then
			     		next_state <= S3;
			   	end if;
		 	when S3 =>
				if (input = code3) then
			     		next_state <= UL;
			     		lock <= '0';
			   	end if;
		 	-- Unlocked!
		 	when UL =>
		     		next_state <= S0;
		     		lock <= '0';
		end case;

	end process;

End Architecture;
