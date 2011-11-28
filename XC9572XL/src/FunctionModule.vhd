--------------------------------------------------------------------------------
-- Function Module
-- Fredrik Brosser
-- EDA234, Group 2
--
-- FILE
-- FunctionModule.vhd
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
-- The Function Module is a simple module responsible for keeping track of and
-- updating the status (on/off) of the functions used.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Entity FunctionModule is
	port(	-- Global clock
			clk		: 	in		std_logic;
			-- Global reset
			rstInt	: 	in		std_logic;
			-- Enable signal from control unit
			En			:	in		std_logic;
			-- Input from Control Unit
			FuncIn	:	in		std_logic_vector(3 downto 0);
			-- Output to actual functions to be controlled
			FuncOut	:	out	std_logic_vector(3 downto 0)
	);
end FunctionModule;

Architecture Behavioral of FunctionModule is
	-- Internal vectors to keep track of function status
   signal FuncStatus 		: std_logic_vector(3 downto 0);
   signal nextFuncStatus 	: std_logic_vector(3 downto 0);
begin

	-- Synchronous (clocked) process
	SyncP : process(clk, rstInt)
	begin
		if(not(rstInt) = '1') then
			-- Reset all functions (set to 0)
			FuncStatus <= (others => '0');
		elsif(clk'Event and clk = '1') then
			FuncStatus <= nextFuncStatus;
		end if;
	end process;
	
	FuncP : process(FuncIn, FuncStatus, En)
	begin
		nextFuncStatus <= FuncStatus;
		FuncOut 			<= FuncStatus;
		if(En = '1') then
			-- Toggling of functions
			for i in 0 to (FuncIn'length - 1) loop
				if(FuncIn(i) = '1') then
					nextFuncStatus(i) <= not(FuncStatus(i));
				end if;
			end loop;
		end if;
	end process;
end Behavioral;

