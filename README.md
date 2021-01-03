# MP3 Decoder IP

This is a MP3 decoder IP with AHB wrapper.

## How to use MP3 decoder 

You can use mp3_to_mem <mp3_filename> to cut mp3 frame.  
Testbench=./sim/mp3dec_tb.sv  
Input file=./sim/t01.mp3  
Output file=./sim/t01.pcm  
Sim Script=./sim/sim0.do or ./sim/sim0_nowave.do 
You can use Adobe Audition to listen to the PCM file(16bit,2 Channels,Big-Endian)

## Some thing  about AHB Wrapper

### REG Map



### Programer's Model