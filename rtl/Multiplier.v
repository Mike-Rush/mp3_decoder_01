// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
module   Multiplier(Mulin1,
                    Mulin2,
                    Mulout);
            
                  
input  signed[19:0]  Mulin1;
input  signed[19:0]  Mulin2;

output signed[39:0]  Mulout;
reg    signed[39:0]  Mulout;

always@(Mulin1 or Mulin2)
begin
  Mulout=Mulin1*Mulin2;
end

endmodule                   
                  