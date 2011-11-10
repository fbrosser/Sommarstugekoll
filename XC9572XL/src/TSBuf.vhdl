----------------------------------------------------------------------------------
-- Tristate buffer
--
-- TSBuf.vhdl
--
-- Buffer and 2-1 MUX for 1-Wire bus:
-- Enable signal 	high => Strong drive on bus according to select signal
-- 			low  => Tri-state (4k7 Pullup resistor to Vcc)
--
-- Sommarstugekoll, EDA234
--
-- @date 2011-11-10
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

Entity TSBuf is
  port ( sel    : in  std_logic;
         A 	: in  std_logic;
         B	: in  std_logic;
         Q      : out std_logic);
End Entity;

Architecture TSBuf_bhv of TSBuf is
begin
  -- Select input A
  Q <= A when (sel = '1' and E = '1') else 'Z';
  -- Select input B
  Q <= B when (sel = '0' and E = '1') else 'Z';
  -- Pull-up resistor
  Q <= 'H';          
End Architecture;
