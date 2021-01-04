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
  input  wire 		   mp3dec_clk,
  output wire 		   mp3dec_intr
	);
reg [31:0] HADDR_t;
reg [2:0] st,st_t;
reg HWRITE_t,HREADYOUT_t,ahb_active_t;
reg reg_MP3DEC_EN,mp3dec_en_t,mp3dec_en_clk_dec;
reg fifo_rst;
wire reg_module_rst;
reg mp3dec_rst,mp3dec_rst_t,mp3dec_rst_clk_dec;
reg [15:0] reg_IFIFO_LTH,reg_IFIFO_MTH;
reg [15:0] reg_OFIFO_LTH,reg_OFIFO_MTH;
reg [31:0] reg_MP3DEC_INTMSK;
reg [31:0] HRDATA_sm;
wire [31:0] HRDATA_fifo;
wire [31:0] ififo_din,ififo_dout;
wire [31:0] ofifo_din,ofifo_dout;
wire [9:0] ififo_rd_dcnt;
wire [9:0] ofifo_wr_dcnt;
wire ififo_wrrst_busy,ififo_rdrst_busy,ififo_almost_empty,ififo_rd_en,ififo_wr_en,ififo_almost_full;
wire ofifo_wrrst_busy,ofifo_rdrst_busy,ofifo_almost_empty,ofifo_rd_en,ofifo_wr_en,ofifo_almost_full; 
wire ahb_active=HTRANS[1]&&HSEL&&HREADY;
assign HRESP=1'b0;
always @(posedge HCLK) begin
	st_t<=st;
	HADDR_t<=HADDR;
	HWRITE_t<=HWITE;
	HREADYOUT_t<=HREADYOUT;
	ahb_active_t<=ahb_active;
end
mp3dec_fifo input_fifo(
  .rst(fifo_rst),
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
  .rst(fifo_rst),
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
assign HRDATA_fifo=ofifo_dout;
Mp3Decode Mp3Decode_u0(
	.Clk           (mp3dec_clk),
	.Rst           (mp3dec_rst_clk_dec),
	.Enable        (mp3dec_en_clk_dec),
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
always @(mp3dec_clk)
begin
	mp3dec_en_t<=reg_MP3DEC_EN;
	mp3dec_en_clk_dec<=MP3DEC_EN_t;
	mp3dec_rst_t<=mp3dec_rst;
	mp3dec_rst_clk_dec<=mp3dec_rst_t;
end
assign reg_module_rst=fifo_rst;
//AHB IF
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn) begin
		st<=`S_NORMAL;
		HREADYOUT<=1'b0;
		fifo_rst<=1'b1;
		cnt0<=0;
		mp3dec_rst<=0;
		HRDATA_sm<=0;
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
					`MP3DEC_RST:begin HRDATA_sm<={31'b0,reg_module_rst};HREADYOUT<=1'b1;end
					`MP3DEC_FIFOCNT:begin HRDATA_sm<={6'b0,ififo_rd_dcnt,6'b0,ofifo_wr_dcnt};HREADYOUT<=1'b1;end
					`MP3DEC_FIFOSTA:begin HRDATA_sm<={30'b0,ififo_almost_full,ofifo_almost_empty};HREADYOUT<=1'b1;end
					`MP3DEC_INTTH0:begin HRDATA_sm<={reg_IFIFO_MTH,reg_IFIFO_LTH};HREADYOUT<=1'b1;end
					`MP3DEC_INTTH1:begin HRDATA_sm<={reg_OFIFO_MTH,reg_OFIFO_LTH};HREADYOUT<=1'b1;end
					`MP3DEC_INTSTA:begin HRDATA_sm<={26'b0,intr[5:0]};HREADYOUT<=1'b1;end
					`MP3DEC_INTMSK:begin HRDATA_sm<=reg_MP3DEC_INTMSK;HREADYOUT<=1'b1;end
					default:begin
						HRDATA_sm<=0;
						HREADYOUT<=1'b1;
					end
					endcase
				end
			end
		end
		`S_WR_MP3_DEC_RST_0:begin
			HREADYOUT<=1'b0;
			fifo_rst<=HWDATA[0];cnt0<=0;
			if (HWDATA[0]==1'b1) begin
				mp3dec_rst<=0;
				st<=`S_WR_MP3_DEC_RST_1;
			end else begin
				st<=`S_WR_MP3_DEC_RST_2;
			end
		end
		`S_WR_MP3_DEC_RST_1:begin
			cnt0<=cnt0+1'b1;
			if (cnt0==`RST1_CYCLE_NUM) begin st<=`S_NORMAL;HREADYOUT<=1'b1;end 
			else begin st<=S_WR_MP3_DEC_RST_1;HREADYOUT<=1'b0;end
		end
		`S_WR_MP3_DEC_RST_2:begin
			cnt0<=cnt0+1'b1;
			if (cnt0==`RST0_CYCLE_NUM) begin st<=`S_WR_MP3_DEC_RST_3;HREADYOUT<=1'b1;end 
			else begin st<=S_WR_MP3_DEC_RST_2;HREADYOUT<=1'b0;end
		end
		`S_WR_MP3_DEC_RST_3:begin
			mp3dec_rst<=1'b1;
			if ((!ififo_wrrst_busy)&&(!ofifo_rdrst_busy)) begin st<=`S_NORMAL;HREADYOUT<=1'b1;end 
			else begin st<=S_WR_MP3_DEC_RST_3;HREADYOUT<=1'b0;end
		end
		endcase
	end
end
//gen HRDATA(comb logic)
always @(*)
begin
	if ((HADDR_t[7]) && (!HWRITE_t) && (st==`S_NORMAL) && ahb_active_t) HRDATA<=HRDATA_fifo;
	else HRDATA<=HRDATA_sm;
end
//1-cycle WR DATA
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn) begin
		reg_MP3DEC_EN<=0;
		reg_MP3DEC_INTMSK<=0;
		reg_IFIFO_MTH<=0;reg_IFIFO_LTH<=0;reg_OFIFO_MTH<=0;reg_OFIFO_LTH<=0;
	end else begin
		if ((!HADDR_t[7])&&HWRITE_t&&ahb_active_t&&(st==`S_NORMAL)) begin
			case (HADDR_t[7:0])
			`MP3_DECEN:begin reg_MP3DEC_EN<=HWDATA[0];end
			`MP3DEC_INTTH0:begin reg_IFIFO_MTH<=HWDATA[31:16];reg_IFIFO_LTH<=HWDATA[15:0];end
			`MP3DEC_INTTH1:begin reg_OFIFO_MTH<=HWDATA[31:16];reg_OFIFO_LTH<=HWDATA[15:0];end
			`MP3DEC_INTMSK:begin reg_MP3DEC_INTMSK<=HWDATA; end
			endcase
		end
	end
end
//intr control
scd #(.dw(10)) scd_ififo_mth(
	.clk(HCLK),
	.s  (ififo_rd_dcnt),
	.pv (reg_IFIFO_MTH),
	.nv (reg_IFIFO_MTH+1'b1),
	.sc (intr_src[5])
	);
scd #(.dw(10)) scd_ififo_lth(
	.clk(HCLK),
	.s  (ififo_rd_dcnt),
	.pv (reg_IFIFO_LTH),
	.nv (reg_IFIFO_LTH-1'b1),
	.sc (intr_src[4])
	);
scd #(.dw(10)) scd_ofifo_mth(
	.clk(HCLK),
	.s  (ofifo_wr_dcnt),
	.pv (reg_OFIFO_MTH),
	.nv (reg_OFIFO_MTH+1'b1),
	.sc (intr_src[3])
	);
scd #(.dw(10)) scd_ofifo_lth(
	.clk(HCLK),
	.s  (ofifo_wr_dcnt),
	.pv (reg_OFIFO_LTH),
	.nv (reg_OFIFO_LTH-1'b1),
	.sc (intr_src[2])
	);
genvar i;
generate
	for (i=0;i<6;i=i+1)
	begin
		always @(posedge HCLK or negedge HRESETn)
		begin
			if (!HRESETn) intr[i]<=0;
			else begin
				if (intr_src[i]&&(!reg_MP3DEC_INTMSK[i])) intr[i]<=1;
				else if ((!HADDR_t[7]&&HWRITE_t&(st==`S_NORMAL)&&ahb_active_t&&(HADDR_t[7:0]==`MP3DEC_INTCLR) && HWDATA[i])
				begin
					intr[i]<=0;
				end else intr[i]<=intr[i];
			end
		end
	end
end
assign mp3_intr=intr[0] || intr[1] || intr[2] || intr[3] || intr[4] || intr[5];
endmodule
