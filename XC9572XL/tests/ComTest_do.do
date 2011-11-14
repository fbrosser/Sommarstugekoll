restart -f -nowave
view signals wave
add wave clk rst trig state nextState data wrIt E A t512 t16 doneSend
force clk 0 0, 1 50 ns -repeat 100 ns
force rst 0 0, 1 50, 0 100
force trig 0 0, 1 200, 0 300

run 10000