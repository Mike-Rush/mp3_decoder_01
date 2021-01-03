# MP3 Decoder IP

This is a MP3 decoder IP with AHB wrapper.

## How to use MP3 decoder 

You can use mp3_to_mem <mp3_filename> to cut mp3 frame.  
Testbench=./sim/mp3dec_tb.sv  
Input file=./sim/t01.mp3  
Output file=./sim/t01.pcm  
Sim Script=./sim/sim0.do or ./sim/sim0_nowave.do   
You can use Adobe Audition to listen to the PCM file(16bit,2 Channels,Big-Endian)

## Some thing about AHB Wrapper

### Structure



### Address Map

| Address Partition | Type     | Register Name  | Description                                            |
| ----------------- | -------- | -------------- | ------------------------------------------------------ |
| 0x00              | Register | MP3DEC_RST     | module reset(low active)                               |
| 0x04              | Register | MP3DEC_FIFOCNT | FIFO data count (in AHB clock domain)                  |
| 0x08              | Register | MP3DEC_FIFOSTA | FIFO status (In AHB clock domain)                      |
| 0x0C              | Register | MP3DEC_INTTH0  | input FIFO interrupt threshold                         |
| 0x10              | Register | MP3DEC_INTTH1  | output FIFO interrupt threshold                        |
| 0x1C              | Register | MP3DEC_INTSTA  | interrupt status                                       |
| 0x20              | Register | MP3DEC_INTCLR  | interrupt clear                                        |
| 0x80              | Register | MP3DEC_FIFO    | write data to input FIFO or read data from output FIFO |

### Interrupt Definition

| Name          | Bit  | Trigger Condition                                         |
| ------------- | ---- | --------------------------------------------------------- |
| INT_IFIFO_MTH | 5    | MP3DEC_FIFOCNT[31:16]>MP3DEC_INTTH0[31:16]                |
| INT_IFIFO_LTH | 4    | MP3DEC_FIFOCNT[31:16]<MP3DEC_INTTH0[15:0]                 |
| INT_OFIFO_MTH | 3    | MP3DEC_FIFOCNT[15:0]>MP3DEC_INTTH0[31:16]                 |
| INT_OFIFO_LTH | 2    | MP3DEC_FIFOCNT[15:0]<MP3DEC_INTTH0[31:16]                 |
| INT_IFIFO_OVR | 1    | MP3DEC_FIFOSTA[1]==1 && still trying to write MP3DEC_FIFO |
| INT_OFIFO_UDR | 0    | MP3DEC_FIFOSTA[0]==1 && still trying to read MP3DEC_FIFO  |

### Register Definition

#### MP3DEC_RST

| Bit  | R/W  | Description              |
| ---- | ---- | ------------------------ |
| 31:1 | -    | reserved                 |
| 0    | RW   | module reset(low active) |

#### MP3DEC_FIFOCNT

| Bit   | R/W  | Description                                 |
| ----- | ---- | ------------------------------------------- |
| 31:16 | R    | input FIFO data count(in AHB clock domain)  |
| 15:0  | R    | output FIFO data count(in AHB clock domain) |

#### MP3DEC_FIFOSTA

| Bit  | R/W | Description       |
| ---- | ----------------- | ----------------- |
| 31:2 | - | reserved          |
| 1    | R   | input FIFO full  |
| 0    | R   | output FIFO empty |

#### MP3DEC_INTTH0

| Bit   | R/W  | Description                                                  |
| ----- | ---- | ------------------------------------------------------------ |
| 31:16 | RW   | INT_IFIFO_MTH will be triggered if MP3DEC_FIFOCNT[31:16]>MP3DEC_INTTH0[31:16] |
| 15:0  | RW   | INT_IFIFO_LTH will be triggered if MP3DEC_FIFOCNT[31:16]<MP3DEC_INTTH0[15:0] |

#### MP3DEC_INTTH1

| Bit   | R/W  | Description                                                  |
| ----- | ---- | ------------------------------------------------------------ |
| 31:16 | RW   | INT_OFIFO_MTH will be triggered if MP3DEC_FIFOCNT[15:0]>MP3DEC_INTTH1[31:16] |
| 15:0  | RW   | INT_OFIFO_LTH will be triggered if MP3DEC_FIFOCNT[15:0]>MP3DEC_INTTH1[31:16] |

#### MP3DEC_INTSTA

| Bit  | R/W  | Description |
| ---- | ---- | ----------- |
| 31:6 | -    | reserved    |
| 5:0  | R    |             |



### Programmer's Model

