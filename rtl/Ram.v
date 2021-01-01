// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
module Ram(CLK,
             A,
           WEN,
           CEN,
             D,
             Q);

input         CLK;
input  [12:0] A;
input         WEN;
input         CEN;
input  [19:0] D;
output [19:0] Q;



reg   [19:0] Q;
reg   [19:0] Memory[0:8191];


always@(posedge CLK)
 if(!CEN)
 begin
	if(WEN)
	  Q<=Memory[A];
   else
	  Memory[A]<=D;
 end

endmodule

