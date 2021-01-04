module scd(
	clk,
	s,
	sc,
	pv,
	nv
);
parameter dw=1;
input clk;
input [dw-1:0] s,pv,nv;
output sc;
reg [dw-1:0] s_t;
always @(posedge clk) begin 
	s_t<=s;
end
assign sc= ( (s_t==pv) && (s==nv) )?1'b1:1'b0;
endmodule