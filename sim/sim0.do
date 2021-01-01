quit -sim
.main clear
vlib work
vmap work work
vlog -f list.txt
vsim -gui work.mp3dec_tb
add wave -group mp3tb_top sim:*
add wave -group mp3dec_syn sim:Mp3Decode_u0/Syn_UT/*
add wave -group mp3dec_ctl sim:Mp3Decode_u0/Con_UT/*
add wave -group mp3dec_dout sim:Mp3Decode_u0/i2s_UT/*
add wave -group mp3dec_fltbnk sim:Mp3Decode_u0/Fil_UT/*
add wave -group mp3dec_RAM sim:Mp3Decode_u0/Ram_A
add wave -group mp3dec_RAM sim:Mp3Decode_u0/Ram_D
add wave -group mp3dec_RAM sim:Mp3Decode_u0/Ram_Q
add wave -group mp3dec_RAM sim:Mp3Decode_u0/Ram_CEN
add wave -group mp3dec_RAM sim:Mp3Decode_u0/Ram_WEN
run -all