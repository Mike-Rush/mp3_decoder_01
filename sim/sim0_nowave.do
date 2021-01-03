quit -sim
.main clear
vlib work
vmap work work
vlog -f list.txt
vsim -voptargs=+noacc work.mp3dec_tb
run -all