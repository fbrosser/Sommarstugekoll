-- SPI_do.do
-- Fredrik Brosser
-- 2011-11-06
restart -f -nowave
view signals wave
add wave clk reset T nextT data cs sck sdi
force reset 1 0, 0 80 ns
force clk 0 0, 1 50 ns -repeat 100 ns
force data 1010
run 4000