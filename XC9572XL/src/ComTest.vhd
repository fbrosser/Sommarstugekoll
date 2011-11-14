----------------------------------------------------------------------------------
-- Fredrik Brosser
-- DS18S20 1-Wire Communication
-- EDA234, Group 2
--
-- Comtest.vhd
-- Last Updated: 2011-11-14
--
-- Target Device: XC9572XL
-- I/O Pins Used:
-- Macrocells Used:
-- Product Terms Used:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity ComTest is
	port(	 clk	  :	in		std_logic;
			   rst	  :	in		std_logic;
			   trig	 :	in		std_logic;
			   Q     : out std_logic
	);
end ComTest;

architecture Behavioral of ComTest is
	
	-- Buffer Enable
	signal E : std_logic;
	-- Output signal to buffer
	signal A : std_logic;
	
	-- State variables (as integers)
	signal state 			 : integer range 0 to 31;
	signal nextState : integer range 0 to 31;
	
	-- Data to be sent on bus
	signal data					 : std_logic_vector(7 downto 0);
	-- Counter used when sending a logical 0 on bus
	signal wrIt					 : std_logic_vector(1 downto 0);
	
  -- Pulse indicating that we've finished sending byte
	signal doneSend  : std_logic;
	
	-- Timing pulses, 512 and 16 us, respectively
	signal t512      : std_logic;
	signal t16       : std_logic;
	-- Internal counter used to create timing pulses
	signal cntInt    : std_logic_vector(8 downto 0);
	
	-- Signals used in simulation
	-- signal check     : std_logic;
	-- signal access    : std_logic;
	
begin
  
----------------------------------------------------------------------------------		
-- BusP, process responsible for handling the buffered output to the bus,
-- according to the enable signal
--
----------------------------------------------------------------------------------		
  BusP : process(A, E)
  begin
	   if (E = '1') then
	     Q <= A;
	   else				   
	     Q <= 'Z';
	   end if;
  end process;
	
----------------------------------------------------------------------------------		
-- SyncP, synchronous (clocked) process responsible for clocking in the new
-- states according to nextState
--
----------------------------------------------------------------------------------		
	SyncP : process(clk, rst)
	begin
		if(rst = '1') then 
			state <= 0;
		elsif(clk'Event and clk = '1') then
			state <= nextState;
		end if;
	end process;
	
----------------------------------------------------------------------------------		
-- SendP, State Machine handling the master side of the 1-wire bus
-- communication with the DS18S20. Divided into stages/modes as follows:
--  
-- 1. INIT (Reset - Presence pulses)
-- 2. SEND (Transmission of data from Master to DS18S20)
-- 3. RECEIVE (Master reads data from DS18S20)
-- 4. IDLE (Bus is idle, pulled high by pull-up resistor)
--
----------------------------------------------------------------------------------		
	SendP : process(trig, state, t512, t16)
	begin
	
		-- Defaults
		nextState <= state;
		E <= '0';
		doneSend <= '0';
		
		case state is
----------------------------------------------------------------------------------		  
-- INIT
----------------------------------------------------------------------------------		
			when 0 =>
		    -- Wait for button press
				if((trig) = '1') then
				  nextState <= state + 1;
				end if;
			when 1 =>
				-- Enable output and send logical 0
				E <= '1';
				A <= '0';
				if(t512 = '1') then 
					nextState <= state + 1;
				end if;
			when 2 =>
				-- Put bus into threestate and wait for response
				E <= '0';
				if(t512 = '1') then 
					nextState <= state + 1;
				end if;
			when 3 =>
				-- Wait for timeout and then start sending ROM Command
				if(t512 = '1') then 
					nextState <= state + 1;
					--data <= (others=>'0');
					-- data <= X"CC";
				end if;
----------------------------------------------------------------------------------		  
-- SEND
----------------------------------------------------------------------------------  
      -- Set data to be sent and prepare for transmit
		  when 4 =>
		     E <= '0';
		     data <= X"CC";
		     wrIt <= "11";
		     nextState <= 5;
		  -- Send logical 0 or 1
		  -- by driving bus low for a certain number of 16 us periods (x1 for 1's, x4 for 0's)
		  when 5 | 7 | 9 | 11 | 13 | 15 | 17 | 19 =>
				E <= '1';
				A <= '0';	
				-- Send logical 1
				if(data(conv_integer(7-((state-5)/2))) = '1' and t16 = '1') then
					nextState <= state + 1;	
				-- Send logical 0
				elsif(data(conv_integer(7-((state-5)/2))) = '0' and wrIt = "00"  and t16 = '1') then
					nextState <= state + 1;
					wrIt <= "11";
				else
				  if(t16 = '1') then
					  wrIt <= (wrIt - 1);
					end if;
				end if;
			-- Recovery time between transmitted bits
			when 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 =>
				E <= '0';
					if(t16 = '1') then
						nextState <= state + 1;
					end if;		
			-- Done sending. Disable buffer and give pulse on doneSend
			when 21 =>
			   E <= '0';
			   doneSend <= '1';
			   nextState <= state + 1;
			when others =>
				 E <= '0';
		end case;	
	end process;
	
----------------------------------------------------------------------------------		
-- CountP, internal counter responsible for creating pulses with certain
-- time intervals. Uses a local (to the Architecture) counter variable.
--  
-- t512 : pulse every 512 us 
-- t16  : pulse every 16  us
--
----------------------------------------------------------------------------------				
  CountP : process(clk)
  begin
    if(clk'Event and clk = '1') then
      -- Reset
      if(rst = '1') then
        cntInt <= (others => '0');
      else
			 -- Give part-output every 16 us
			 if(cntInt(0) = '1') then
			   t16 <= '1';
			 else
			   t16 <= '0';
			 end if;
			 -- Give pulse on output and reset counter every 512 us
       if(cntInt = 6) then
          t512 <= '1';
          cntInt <= (others => '0');
        -- Count up
        else
          t512 <= '0';
          cntInt <= cntInt + 1;
        end if;
      end if;
    end if;
  end process;
    
end Behavioral;
