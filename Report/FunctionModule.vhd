--------------------------------------------------------------------------------
-- Function Module
-- EDA234, Group 2
--
-- FILE
-- FunctionModule.vhd
-- Last Updated: 2011-12-08
--
-- VERSION
-- Hardware ("production") v1.3
--
-- HARDWARE
-- Target Device: XC9572XL
--
-- DESCRIPTION
-- The Function Module is a simple module responsible for keeping track of and
-- updating the status (on/off) of the functions used.
--
--------------------------------------------------------------------------------

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
			en			:	in		std_logic;
			-- Input from Control Unit
			funcIn	:	in		std_logic_vector(3 downto 0);
			-- Output to actual functions to be controlled
			funcOut	:	out	std_logic_vector(3 downto 0)
	);
end FunctionModule;

Architecture Behavioral of FunctionModule is
begin
	funcP : process(funcIn, rstInt, clk, en) 
	begin
		if(not(rstInt) = '1') then
			funcOut <= (others => '0');
		elsif (clk'Event and clk = '1' and en = '1') then
			funcOut <= funcIn;
		end if;
	end process;
end Behavioral;

