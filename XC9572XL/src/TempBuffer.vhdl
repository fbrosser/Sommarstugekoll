----------------------------------------------------------------------------------
-- Temperature Buffer and MUX
--
-- TempBuffer.vhdl
--
-- Buffer and MUX for serial communication with
-- DS18S20 Digital Thermometer
-- 
-- Sommarstugekoll, EDA234
--
-- @date 2011-11-01
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

Entity TempBuffer is
	port(
	        -- Temperature input to Temperature Module
	        Tin   :   out   std_logic;
	        -- Temperature output from Temperature Module
          Tout  :   in    std_logic;
          -- Sensor select (1/0 for In/Out) from Control Unit
          TSel  :   in    std_logic;
          
          -- Note the use of 'inout' below to allow bidirectional serial communication.
          
          -- Temperature sensor 0 (DS18S20-0)
          T0    :   inout std_logic;
          -- Temperature sensor 1 (DS18S20-1)
          T1    : 	 inout std_logic
	);
End Entity;

Architecture TempBuffer_bhv of TempBuffer is
begin
  TempBufferP : process(Tsel, T0, T1) 
  begin
    case TSel is
      -- Select Temperature sensor 0
      when '0' =>
        
      -- Select Temperature sensor 1
      when '1' =>
        
      when others =>
        
  end process;
  
End Architecture;
