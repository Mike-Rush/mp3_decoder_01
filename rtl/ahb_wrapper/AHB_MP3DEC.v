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
reg reg_MP3DEC_EN,MP3DEC_EN_t,MP3DEC_EN_CLK_DEC;
reg reg_MP3DEC_RST;
reg [15:0] reg_IFIFO_LTH,reg_IFIFO_MTH;
reg [15:0] reg_OFIFO_LTH,reg_OFIFO_MTH;
wire ahb_active=HTRANS[1]&&HSEL&&HREADY;
assign HRESP=1'b0;
wire [31:0] ififo_din,ififo_dout;
wire [31:0] ofifo_din,ofifo_dout;
wire [9:0] ififo_rd_dcnt;
wire [9:0] ofifo_wr_dcnt;
wire ififo_wrrst_busy,ififo_rdrst_busy,ififo_almost_empty,ififo_rd_en,ififo_wr_en,ififo_almost_full;
wire ofifo_wrrst_busy,ofifo_rdrst_busy,ofifo_almost_empty,ofifo_rd_en,ofifo_wr_en,ofifo_almost_full; 
always @(posedge HCLK) begin
	st_t<=st;
	HADDR_t<=HADDR;
	HWRITE_t<=HWITE;
	HREADYOUT_t<=HREADYOUT;
	ahb_active_t<=ahb_active;
end
mp3dec_fifo input_fifo(
  .rst(reg_MP3DEC_RST),
  .wr_clk(HCLK),
  .rd_clk(MP3DEC_CLK),
  .din(ififo_din),
  .wr_en(ififo_wr_en),
  .rd_en(ififo_rd_en),
  .dout(ififo_dout),
  .full(),
  .almost_full(ififo_almost_full),
  .empty(),
  .almost_empty(ififo_almost_empty),
  .rd_data_count(ififo_rd_dcnt),
  .wr_data_count(),
  .wr_rst_busy(ififo_wrrst_busy),
  .rd_rst_busy(ififo_rdrst_busy)
);
assign ififo_wr_en=HADDR_t[7]&&HWRITE_t&&(!ififo_almost_full)&&(st_t==`S_NORMAL);
assign ififo_din=HWDATA[31:0];
mp3dec_fifo output_fifo(
  .rst(reg_MP3DEC_RST),
  .wr_clk(MP3DEC_CLK),
  .rd_clk(HCLK),
  .din(ofifo_din),
  .wr_en(ofifo_wr_en),
  .rd_en(ofifo_rd_en),
  .dout(ofifo_dout),
  .full(),
  .almost_full(ofifo_almost_full),
  .empty(),
  .almost_empty(ofifo_almost_empty),
  .rd_data_count(),
  .wr_data_count(ofifo_wr_dcnt),
  .wr_rst_busy(ofifo_rdrst_busy),
  .rd_rst_busy(ofifo_wrrst_busy)
);
assign ofifo_rd_en=HADDR[7]&&(!HWRITE)&&(!ofifo_almost_empty)&&(st==`S_NORMAL);
Mp3Decode Mp3Decode_u0(
	.Clk           (MP3DEC_CLK),
	.Rst           (reg_MP3DEC_RST),
	.Enable        (MP3DEC_EN_CLK_DEC),
	.fifo_empty    (ififo_rdrst_busy||ififo_almost_empty),
	.fifo_ren      (ififo_rd_en),
	.fifo_datain   (ififo_dout),
	.Music_mode    (),
	.Sample_freq   (),
	.Bitrate       (),
	.Invalid_format(),
	.Wfull         (ofifo_wrrst_busy||ofifo_almost_full),
	.Winc          (ofifo_wr_en),
	.Wdata         (ofifo_din)
);
//bit cross domain
always @(MP3DEC_CLK)
begin
	MP3DEC_EN_t<=reg_MP3DEC_EN;
	MP3DEC_EN_CLK_DEC<=MP3DEC_EN_t;
end
//AHB IF
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn) begin
		st<=`S_NORMAL;
		HREADYOUT<=1'b0;
		reg_MP3DEC_RST<=1'b0;
		cnt0<=0;
	end else begin
		case (st)
		`S_NORMAL:begin
			if (ahb_active) begin
				if (HWRITE) begin
					case (HADDR[7:0])
					`MP3DEC_RST:begin
						HREADYOUT<=1'b0;
						st<=S_WR_MP3_DEC_RST_0;
					end
					default:begin
						HREADYOUT<=1'b1;
						st<=`S_NORMAL;
					end
					endcase 
				end else begin
					case (HADDR[7:0])
					`MP3DEC_EN:begin HRDATA_sm<={31'b0,reg_MP3DEC_EN};HREADYOUT<=1'b1;end
					`MP3DEC_RST:begin HRDATA_sm<={31'b0,reg_MP3DEC_RST};HREADYOUT<=1'b1;end
					`MP3DEC_FIFOCNT:begin HRDATA_sm<={6'b0,ififo_rd_dcnt,6'b0,ofifo_wr_dcnt};HREADYOUT<=1'b1;end
					`MP3DEC_FIFOSTA:begin HRDATA_sm<={30'b0,ififo_almost_full,ofifo_almost_empty};end
					`MP3DEC_INTTH0:begin end

					default:begin
						HREADYOUT<=1'b1;
						HRDATA_sm<=0;
					end
					endcase
				end
			end
		end
		`S_WR_MP3_DEC_RST_0:begin
			HREADYOUT<=1'b0;
			reg_MP3DEC_RST<=HWDATA[0];
			if (HWDATA[0]==1'b0) begin
				cnt0<=0;
				st<=`WR_MP3_DEC_RST_1;
			end else begin
				st<=`WR_MP3_DEC_RST_2;
			end
		end
		`S_WR_MP3_DEC_RST_1:begin
			cnt0<=cnt0+1'b1;
			if (cnt0==RST_CYCLE_NUM) begin st<=`S_NORMAL;HREADYOUT<=1'b1;end 
			else begin st<=S_WR_MP3_DEC_RST_1;HREADYOUT<=1'b0;end
		end
		`S_WR_MP3_DEC_RST_2:begin
			if ((!ififo_wrrst_busy)&&(!ofifo_rdrst_busy)) begin st<=`S_NORMAL;HREADYOUT<=1'b1;end 
			else begin st<=S_WR_MP3_DEC_RST_2;HREADYOUT<=1'b0;end
		end
	end
end
endmodule
