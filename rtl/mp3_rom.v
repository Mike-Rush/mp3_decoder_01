`timescale 1ns / 1ps
module mp3_rom(clk,dout,en,addr);
    input  clk;
    output [19:0] dout;
    input  en;
    input  [12:0] addr;

reg   [19:0] dout;
reg   [19:0] Memory[0:8191];              

initial $readmemb("rom8192.mif",Memory);
always@(posedge clk)
 if(!en)
	dout<=Memory[addr];


endmodule
                        