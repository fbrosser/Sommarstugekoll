-- Test Bench for Sequence Detector
 -- seqDet_do.do
 -- 
 -- Sommarstugekoll, EDA234
 --
 -- @author Fredrik Brosser
 -- @date 2011-10-27 14:51
 --

 restart -f -nowave
 view signals wave
 add wave clk rst ce input state next_state lock
 force ce 0 0, 1 50
 force rst 0 0, 1 50, 0 100
 force clk 0 0, 1 50 -repeat 100
 force input "0000" 0, "0001" 200, "0010" 300, "0011" 400, "0100" 500, "0101" 600, "0000" 700, "0001" 800, "0010" 900, "0100" 1000
 run 1500
