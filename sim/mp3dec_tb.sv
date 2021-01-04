`include "../rtl/timescale.v"
`define p_clk 4
module mp3dec_tb;
parameter N=20;
integer i;
integer fmp3,fpcm;
integer mp3_size;
integer mem_ptr;
integer framecnt,framecnt0;
reg [31:0] mp3memory[(1<<N):0];
reg Clk,Rst,Enable,fifo_empty,Wfull;
reg [31:0] fifo_datain;
wire[1 :0]       Music_mode;
wire[1 :0]       Sample_freq;
wire[3 :0]       Bitrate; 
wire             fifo_ren;    
wire             Invalid_format;   
wire Winc;
wire [31:0]	Wdata;
reg [15:0] pcmout;
Mp3Decode Mp3Decode_u0(
	.Clk           (Clk),
	.Rst           (Rst),
	.Enable        (Enable),
	.fifo_empty    (fifo_empty),
	.fifo_datain   (fifo_datain),
	.Music_mode    (Music_mode),
	.Sample_freq   (Sample_freq),
	.Bitrate       (Bitrate),
	.fifo_ren      (fifo_ren),
	.Invalid_format(Invalid_format),
	.Wfull         (Wfull),
	.Winc          (Winc),
	.Wdata         (Wdata)
);
initial begin
	Clk=0;
	forever begin
		#(`p_clk/2.0)
		Clk=~Clk;
	end
end
initial begin
	fmp3=$fopen("./t02.mp3","rb");
	$fseek(fmp3,0,2);
	framecnt0=0;framecnt=0;
	mp3_size=$ftell(fmp3);
	$display("mp3 file size=%0d bytes",mp3_size);
	$rewind(fmp3);
	$fread(mp3memory,fmp3);
	for (i=0;i<10;i++) 
	begin
		$display("mp3memory[%0d]=%08x",i,mp3memory[i]);
	end
	Rst=0;fifo_empty=1'b1;Enable=1'b0;Wfull=1'b1;
	#(`p_clk*30);
	Rst=1;fifo_empty=1'b0;Enable=1'b1;
	mem_ptr=0;fifo_datain=mp3memory[mem_ptr];
	Wfull=1'b0;
	#(`p_clk*2);
	fpcm=$fopen("./t02.pcm","wb");
	forever begin
		@(posedge Clk)
		if (Rst) begin
			if (fifo_ren) begin
				fifo_datain=mp3memory[mem_ptr];
				mem_ptr++;
				if (mem_ptr==mp3_size/4) begin
					$display("mp3 reach end\n");
					fifo_empty=1'b1;
					#(`p_clk*500000);
					$stop;
				end
			end
		end
	end
end
always @(posedge Mp3Decode_u0.Done_i2s) begin
	framecnt0++;
	if (framecnt0%2==0) begin
		framecnt=framecnt0/2;
		$display("Frame %0d End",framecnt);
		$display("Progress=%f%%",mem_ptr*100.0/(mp3_size/4.0));
	end
	if (framecnt==5000) begin
		#(`p_clk*20000);
		$stop;
	end
end
always @(posedge Winc) begin
	pcmout=Wdata[15:0];
	$fwrite(fpcm,"%c%c",pcmout[15:8],pcmout[7:0]);
end
endmodule