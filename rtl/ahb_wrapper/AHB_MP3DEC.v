module AHB_MP3DEC(
  input  wire          HCLK,      // system bus clock
  input  wire          HRESETn,   // system bus reset
  input  wire          HSEL,      // AHB peripheral select
  input  wire          HREADY,    // AHB ready input
  input  wire    [1:0] HTRANS,    // AHB transfer type
  input  wire    [2:0] HSIZE,     // AHB hsize
  input  wire          HWRITE,    // AHB hwrite
  input  wire   [31:0] HADDR,     // AHB address bus
  input  wire    [2:0] HBURST,    // AHB burst type
  input  wire   [31:0] HWDATA,    // AHB write data bus
  output reg           HREADYOUT, // AHB ready output to S->M mux
  output wire          HRESP,     // AHB response
  output reg    [31:0] HRDATA,    // AHB read data bus;
  input  wire 		   MP3DEC_CLK,
  output wire 		   MP3DEC_INTR
	);
reg [31:0] HADDR_t;
reg [2:0] st,st_t;
reg HWRITE_t,HREADYOUT_t,ahb_active_t;
reg MP3DEC_RST;
reg MP3DEC_EN;
wire ahb_active=HTRANS[1]&&HSEL&&HREADY;
assign HRESP=1'b0;
wire [31:0] ififo_datin;
wire ififo_wrrst_busy,ififo_rdrst_busy,ififo_almost_empty,ififo_rd_en;
always @(posedge HCLK) begin
	st_t<=st;
	HADDR_t<=HADDR;
	HWRITE_t<=HWITE;
	HREADYOUT_t<=HREADYOUT;
	ahb_active_t<=ahb_active;
end
mp3dec_fifo input_fifo(
  .rst(MP3DEC_RST),
  .wr_clk(HCLK),
  .rd_clk(MP3DEC_CLK),
  .din,
  .wr_en,
  .rd_en(ififo_rd_en),
  .dout(ififo_datin),
  .full,
  .almost_full,
  .empty,
  .almost_empty(ififo_almost_empty),
  .rd_data_count,
  .wr_data_count(),
  .wr_rst_busy(ififo_wrrst_busy),
  .rd_rst_busy(ififo_rdrst_busy)
);
Mp3Decode Mp3Decode_u0(
	.Clk           (MP3DEC_CLK),
	.Rst           (MP3DEC_RST),
	.Enable        (MP3DEC_EN),
	.fifo_empty    (ififo_rdrst_busy||ififo_almost_empty),
	.fifo_ren      (ififo_rd_en),
	.fifo_datain   (ififo_datin),
	.Music_mode    (),
	.Sample_freq   (),
	.Bitrate       (),
	.Invalid_format(),
	.Wfull         (Wfull),
	.Winc          (Winc),
	.Wdata         (Wdata)
);

endmodule
