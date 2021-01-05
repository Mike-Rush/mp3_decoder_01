module AHB_my_VIP(
  input  wire           HCLK,
  input  wire           HRESETn,

  input  wire           HSEL,
  input  wire   [31:0]  HADDR,
  input  wire    [1:0]  HTRANS,
  input  wire           HWRITE,
  input  wire    [2:0]  HSIZE,
  input  wire    [3:0]  HPROT,
  input  wire           HREADY,
  input  wire   [31:0]  HWDATA,
  output wire           HREADYOUT,
  output wire   [31:0]  HRDATA,
  output wire           HRESP
);
assign HRESP=0;
assign HREADYOUT=1;
assign HRDATA=0;
reg HWRITE_t,HREADY_t,HSEL_t;
reg [31:0] HADDR_t;
bit [0:16'h400][7:0] fname;
bit [31:0] fname_len;
always @(posedge HCLK)
begin
  HADDR_t<=HADDR;
  HSEL_t<=HSEL;
  HREADY_t<=HREADY;
  HWRITE_t<=HWRITE;
end
integer outf;
always @(posedge HCLK)
begin
	if (HADDR_t==32'h40000000&&HSEL_t&&HREADY_t&&HWRITE_t)
	begin
		$write("%c", HWDATA[7:0]);
    //$write("%x\n", HWDATA[7:0]);
    //$write("putc CALLED\n");
	end else if (HADDR_t==32'h40000008&&HSEL_t&&HREADY_t&&HWRITE_t)
  begin
    $write("%08x\n", HWDATA[31:0]);
  end else if (HADDR_t==32'h4000000C&&HSEL_t&&HREADY_t&&HWRITE_t)
  begin
    fname_len=HWDATA;
  end else if (HADDR_t==32'h40000010&&HSEL_t&&HREADY_t&&HWRITE_t)
  begin
    outf=$fopen(string'(fname[0:fname_len-1]),"w");
  end
  else if (HADDR_t>=32'h40001000&&HADDR_t<=32'h40001400&&HSEL_t&&HREADY_t&&HWRITE_t)
  begin
    fname[HADDR_t-32'h40001000]=HWDATA[31:24];
    fname[HADDR_t-32'h40001000+1]=HWDATA[23:16];
    fname[HADDR_t-32'h40001000+2]=HWDATA[15:8];
    fname[HADDR_t-32'h40001000+3]=HWDATA[7:0];
  end
end
always @(posedge HCLK)
begin
	if (HADDR_t==32'h40000004&&HSEL_t&&HREADY_t&&HWRITE_t)
	begin
    $fclose(outf);
		$stop;
	end
end
endmodule 