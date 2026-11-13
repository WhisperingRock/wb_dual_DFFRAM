printf "\
read_verilog -sv rtl/*.sv
hierarchy -check -top fib
proc
opt
write_json ./synth/design.json\n"

