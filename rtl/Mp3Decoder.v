//***********************************************************
//data        : 2007-07-11 11:30:00 
//version     : 1.0
//
//module name : Mp3Decode
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-07-11  11:30:00   
//***********************************************************
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`define DLY      0 
module Mp3Decode  (Clk,
                   Rst,
				   Enable,  
				   fifo_empty, 
                   fifo_datain,
                   fifo_ren,
				   Invalid_format,
                   Music_mode,
				   Bitrate,
				   Sample_freq,
                   Winc,
                   Wdata,
                   Wfull);


// module port List
input              Clk;
input              Rst;
input			   Enable;
input			   fifo_empty;
input [31:0]	   fifo_datain;



output[1 :0]       Music_mode;
output[1 :0]       Sample_freq;
output[3 :0]       Bitrate; 
output             fifo_ren;    
output             Invalid_format;   

//Connect with I2S fifo
input              Wfull;
output             Winc;
output[31:0]       Wdata;

//inter variable
wire[1 :0]         Mode_ext;
wire			   Granule;
wire			   Channel;
wire[1 :0]	       Mode;
wire			   Blocksplit_flag;
wire[1 :0]         Block_type;
wire               Switch_point;
wire               Scfsi0;
wire		       Scfsi1;
wire	           Scfsi2;	 
wire               Scfsi3;   
wire[7 :0]	       Global_gain;
wire[2 :0]         Sub0_gain;
wire[2 :0]	       Sub1_gain;
wire[2 :0]	       Sub2_gain;
wire               Preflag;
wire               Scalefac_scale;
wire[11:0]         Part2_3_length; 
wire[8 :0]         Big_values;
wire[3 :0]         Scalefac_compress;
wire[4 :0]         Table_select0;
wire[4 :0]	       Table_select1;
wire[4 :0]	       Table_select2;
wire[3 :0]         Region1;
wire[2 :0]         Region2;   
wire[10:0]	       Main_data;        
wire               count1table_select; 
wire[1 :0]         Sfrq;  

wire               Done_syn;
wire               Done_huf;  
wire               Done_req;  
wire               Done_ste;
wire               Done_ala;  
wire               Done_imd; 
wire               Done_fil;
wire               Done_i2s;
wire               Enable_syn;
wire               Enable_huf;   
wire               Enable_req; 
wire               Enable_ste;
wire               Enable_ala;
wire               Enable_imd;
wire               Enable_fil;
wire               Enable_i2s;

wire[19:0]         Rom_Q;
wire[12:0]         Rom_A;
wire               Rom_CEN;

wire[12:0]         RomA_huf;
wire               RomCEN_huf; 

wire[12:0]         RomA_req;
wire               RomCEN_req;

wire[12:0]         RomA_imd;
wire               RomCEN_imd; 

wire[12:0]         RomA_fil;
wire               RomCEN_fil;

wire[19:0]         Ram_Q;   
wire[19:0]         Ram_D;
wire[12:0]         Ram_A;
wire               Ram_CEN;
wire               Ram_WEN;

wire		       RamWEN_syn;
wire               RamCEN_syn;
wire[12:0]         RamA_syn;
wire[19:0]         RamD_syn;
                              
wire		       RamWEN_huf;
wire               RamCEN_huf;
wire[12:0]         RamA_huf;
wire[19:0]         RamD_huf;    

wire		       RamWEN_req;
wire               RamCEN_req;
wire[12:0]         RamA_req;
wire[19:0]         RamD_req;                            


wire		       RamWEN_ste;
wire               RamCEN_ste;
wire[12:0]         RamA_ste;
wire[19:0]         RamD_ste;                                        
                              
wire		       RamWEN_ala;
wire               RamCEN_ala;
wire[12:0]         RamA_ala;
wire[19:0]         RamD_ala;  

wire		       RamWEN_imd;
wire               RamCEN_imd;
wire[12:0]         RamA_imd;
wire[19:0]         RamD_imd;   

wire		       RamWEN_fil;
wire               RamCEN_fil;
wire[12:0]         RamA_fil;
wire[19:0]         RamD_fil; 

wire		       RamWEN_i2s;
wire               RamCEN_i2s;
wire[12:0]         RamA_i2s;                              
                                     
wire[19:0]         Mulin1_req;
wire[19:0]         Mulin2_req;    

wire[19:0]         Mulin1_ste;
wire[19:0]         Mulin2_ste;

wire[19:0]         Mulin1_ala;
wire[19:0]         Mulin2_ala;
 
wire[19:0]         Mulin1_imd;
wire[19:0]         Mulin2_imd;

wire[19:0]         Mulin1_fil;
wire[19:0]         Mulin2_fil;

wire[19:0]         Mulin1;
wire[19:0]         Mulin2;
wire[39:0]         Mulout;                                     
//***********************main**************************************


synchronize Syn_UT(.Clk(Clk),
                   .Rst(Rst),
				   .Enable(Enable_syn),  
				   .Done(Done_syn),
				   .fifo_empty(fifo_empty), 
                   .fifo_datain(fifo_datain),
                   .fifo_ren(fifo_ren),
				   .Granule(Granule),
				   .Channel(Channel),
				   .Ram_WEN(RamWEN_syn),
                   .Ram_CEN(RamCEN_syn),
                   .Ram_A(RamA_syn),
                   .Ram_D(RamD_syn),
				   .Mode(Mode),
				   .Sfrq(Sfrq),
				   .Bitrate(Bitrate),
                   .Mode_ext(Mode_ext),
				   .Invalid_format(Invalid_format),
				   .Blocksplit_flag(Blocksplit_flag),
                   .Block_type(Block_type),
                   .Switch_point(Switch_point),
				   .Global_gain(Global_gain),
                   .Sub0_gain(Sub0_gain),
				   .Sub1_gain(Sub1_gain),
				   .Sub2_gain(Sub2_gain),
                   .Preflag(Preflag),
                   .Scalefac_scale(Scalefac_scale),
				   .Main_data(Main_data),        
                   .Scfsi0(Scfsi0),
				   .Scfsi1(Scfsi1),
				   .Scfsi2(Scfsi2),
				   .Scfsi3(Scfsi3),
                   .Part2_3_length(Part2_3_length), 
                   .Big_values(Big_values),
                   .Scalefac_compress(Scalefac_compress),
                   .count1table_select(count1table_select),
                   .Table_select0(Table_select0),
				   .Table_select1(Table_select1),
				   .Table_select2(Table_select2),
                   .Region1(Region1),
                   .Region2(Region2));

assign  Music_mode=Mode;
assign  Sample_freq=Sfrq;                                             
                                            
huffmandecoder huf_UT(.Clk(Clk),
                      .Enable(Enable_huf),
                      .Rst(Rst),   
                      .Granule(Granule),
				      .Channel(Channel),
				      .Sfrq(Sfrq),
				      .Ram_WEN(RamWEN_huf),
                      .Ram_CEN(RamCEN_huf),
                      .Ram_A(RamA_huf),
                      .Ram_D(RamD_huf),
                      .Ram_Q(Ram_Q),
                      .Rom_Q(Rom_Q),   
                      .Rom_A(RomA_huf),
                      .Rom_CEN(RomCEN_huf),
                      .Main_data(Main_data),        
                      .Scfsi0(Scfsi0),
				      .Scfsi1(Scfsi1),
				      .Scfsi2(Scfsi2),
				      .Scfsi3(Scfsi3), 
				      .Blocksplit_flag(Blocksplit_flag),
                      .Block_type(Block_type),
                      .Switch_point(Switch_point),
                      .Part2_3_length(Part2_3_length), 
                      .Big_values(Big_values),
                      .Scalefac_compress(Scalefac_compress),
                      .count1table_select(count1table_select),
                      .Table_select0(Table_select0),
				      .Table_select1(Table_select1),
				      .Table_select2(Table_select2),
                      .Region1(Region1),
                      .Region2(Region2),
                      .Done(Done_huf));    
                      
                      
mp3_rom        rom_UT(.addr(Rom_A),
	                  .clk(Clk),
	                  .dout(Rom_Q),
	                  .en(Rom_CEN));
	                  
Ram            Ram_UT(.CLK(Clk),
                      .A(Ram_A),
                      .WEN(Ram_WEN),
                      .CEN(Ram_CEN),
                      .D(Ram_D),
                      .Q(Ram_Q));	                                                             




Controll       Con_UT(.Clk(Clk),
                      .Rst(Rst),  
                      .Enable(Enable),
				      .Done_syn(Done_syn),
				      .Done_huf(Done_huf),
				      .Enable_syn(Enable_syn),
				      .Enable_huf(Enable_huf),
					  .Enable_req(Enable_req), 
					  .Enable_ste(Enable_ste), 
					  .Enable_ala(Enable_ala),    
					  .Enable_fil(Enable_fil),     
					  .Enable_imd(Enable_imd),
					  .Enable_i2s(Enable_i2s),
					  .Done_i2s(Done_i2s),
					  .Done_fil(Done_fil),
					  .Done_ala(Done_ala),  
					  .Done_imd(Done_imd),
					  .Done_req(Done_req),
					  .Done_ste(Done_ste),
			      	  .Mode(Mode),
				      .Channel(Channel),
                      .Granule(Granule));  
                      
                      
Memorysel    Msel_UT(.Clk(Clk),
                     .Enable_syn(Enable_syn),
                     .Enable_huf(Enable_huf),
					 .Enable_req(Enable_req),
				     .Enable_ste(Enable_ste),
					 .Enable_ala(Enable_ala), 
					 .Enable_imd(Enable_imd), 
					 .Enable_fil(Enable_fil), 
					 .Enable_i2s(Enable_i2s),
                     .RamWEn_syn(RamWEN_syn),
                     .RamCen_syn(RamCEN_syn),
                     .RamA_syn(RamA_syn),
                     .RamD_Syn(RamD_syn),
                     .RamWEn_huf(RamWEN_huf),
                     .RamCen_huf(RamCEN_huf),
                     .RamA_huf(RamA_huf),
                     .RamD_huf(RamD_huf),
				     .RamWEn_req(RamWEN_req),
                     .RamCen_req(RamCEN_req),
                     .RamA_req(RamA_req),
                     .RamD_req(RamD_req),
                     .Ram_Wen(Ram_WEN),
                     .Ram_Cen(Ram_CEN),
                     .Ram_A(Ram_A),
                     .Ram_D(Ram_D),
                     .Rom_CEN(Rom_CEN),
                     .Rom_A(Rom_A),
                     .RomCEN_req(RomCEN_req),
                     .RomA_req(RomA_req), 
                     .RomCEN_imd(RomCEN_imd),
                     .RomA_imd(RomA_imd),  
                     .RomCEN_fil(RomCEN_fil),
                     .RomA_fil(RomA_fil),
                     .RomCEN_huf(RomCEN_huf),
                     .RomA_huf(RomA_huf),  
                     .RamWEn_ste(RamWEN_ste),
                     .RamCen_ste(RamCEN_ste),
                     .RamA_ste(RamA_ste),
                     .RamD_ste(RamD_ste),
                     .RamWEn_ala(RamWEN_ala),
                     .RamCen_ala(RamCEN_ala),
                     .RamA_ala(RamA_ala),
                     .RamD_ala(RamD_ala),
                     .RamWEn_imd(RamWEN_imd),
                     .RamCen_imd(RamCEN_imd),
                     .RamA_imd(RamA_imd),
                     .RamD_imd(RamD_imd),  
                     .RamWEn_fil(RamWEN_fil),
                     .RamCen_fil(RamCEN_fil),
                     .RamA_fil(RamA_fil),
                     .RamD_fil(RamD_fil),
					 .RamWEn_i2s(RamWEN_i2s),
                     .RamCen_i2s(RamCEN_i2s),
                     .RamA_i2s(RamA_i2s),
                     .Mulin1(Mulin1),
                     .Mulin2(Mulin2),
                     .Mulin1_req(Mulin1_req),
                     .Mulin2_req(Mulin2_req),
                     .Mulin1_ste(Mulin1_ste),
                     .Mulin2_ste(Mulin2_ste),
                     .Mulin1_ala(Mulin1_ala),
                     .Mulin2_ala(Mulin2_ala),
                     .Mulin1_imd(Mulin1_imd),
                     .Mulin2_imd(Mulin2_imd),
                     .Mulin1_fil(Mulin1_fil),
                     .Mulin2_fil(Mulin2_fil));  
                     
Multiplier   Mult_UT(.Mulin1(Mulin1),
                     .Mulin2(Mulin2),
                     .Mulout(Mulout));
                                 
                     
                     
requatize    Req_UT(.Clk(Clk),
                    .Rst(Rst),
                    .Enable(Enable_req),   
                    .Done(Done_req),  
                    .Mulin1(Mulin1_req),
                    .Mulin2(Mulin2_req),
                    .Mulout(Mulout),
                    .Channel(Channel), 
                    .Rom_Q(Rom_Q),
                    .Rom_CEN(RomCEN_req),
                    .Rom_A(RomA_req),
                    .Ram_WEN(RamWEN_req),
                    .Ram_CEN(RamCEN_req),
                    .Ram_A(RamA_req),
                    .Ram_D(RamD_req),  
                    .Ram_Q(Ram_Q),
				    .Sfrq(Sfrq),
				    .Blocksplit_flag(Blocksplit_flag),
                    .Block_type(Block_type),
                    .Switch_point(Switch_point),
				    .Global_gain(Global_gain),
                    .Sub0_gain(Sub0_gain),
				    .Sub1_gain(Sub1_gain),
				    .Sub2_gain(Sub2_gain),
                    .Preflag(Preflag),
                    .Scalefac_scale(Scalefac_scale)); 
                    
                    
                    
Stereo    Ste_UT(.Clk(Clk),
                 .Rst(Rst),
                 .Enable(Enable_ste),   
                 .Done(Done_ste),  
                 .Mulin1_ste(Mulin1_ste),
                 .Mulin2_ste(Mulin2_ste),
                 .Mulout(Mulout),
                 .Ram_WEN(RamWEN_ste),
                 .Ram_CEN(RamCEN_ste),
                 .Ram_A(RamA_ste),
                 .Ram_D(RamD_ste),  
                 .Ram_Q(Ram_Q),
				 .Mode(Mode),
				 .Mode_ext(Mode_ext));  
				 
Alais    Ala_UT(.Clk(Clk),
                .Rst(Rst),
                .Enable(Enable_ala),   
                .Done(Done_ala),  
                .Mulin1_ala(Mulin1_ala),
                .Mulin2_ala(Mulin2_ala),
                .Mulout(Mulout), 
                .Channel(Channel),
                .Ram_WEN(RamWEN_ala),
                .Ram_CEN(RamCEN_ala),
                .Ram_A(RamA_ala),
                .Ram_D(RamD_ala),  
                .Ram_Q(Ram_Q),
				.Blocksplit_flag(Blocksplit_flag),
                .Block_type(Block_type),
                .Switch_point(Switch_point));     
                
                
Imdct    Imd_UT(.Clk(Clk),
                .Rst(Rst),
                .Enable(Enable_imd),   
                .Done(Done_imd),  
                .Mulin1_imd(Mulin1_imd),
                .Mulin2_imd(Mulin2_imd),
                .Mulout(Mulout), 
                .Channel(Channel),
                .Mode(Mode),
                .Ram_WEN(RamWEN_imd),
                .Ram_CEN(RamCEN_imd),
                .Ram_A(RamA_imd),
                .Ram_D(RamD_imd),  
                .Ram_Q(Ram_Q), 
                .Rom_A(RomA_imd),
                .Rom_Q(Rom_Q),
                .Rom_CEN(RomCEN_imd),
				    .Blocksplit_flag(Blocksplit_flag),
                .Block_type(Block_type),
                .Switch_point(Switch_point));                
                             
Filterbank Fil_UT(.Clk(Clk),
                  .Rst(Rst),
                  .Enable(Enable_fil),   
                  .Done(Done_fil),  
                  .Mulin1_fil(Mulin1_fil),
                  .Mulin2_fil(Mulin2_fil),
                  .Mulout(Mulout), 
                  .Channel(Channel),
                  .Ram_WEN(RamWEN_fil),
                  .Ram_CEN(RamCEN_fil),
                  .Ram_A(RamA_fil),
                  .Ram_D(RamD_fil),  
                  .Ram_Q(Ram_Q), 
                  .Rom_A(RomA_fil),
                  .Rom_Q(Rom_Q),
				  .Rom_CEN(RomCEN_fil));                      
                     
write_i2s_fifo i2s_UT(.Clk(Clk),
                      .Rst(Rst),
                      .Write_enable(Enable_i2s),   
                      .Write_done(Done_i2s), 
                      .Mode(Mode),
                      .Ram_addr(RamA_i2s),
                      .Ram_out(Ram_Q),
                      .Ram_wen(RamWEN_i2s),
                      .Ram_cen(RamCEN_i2s),
                      .Winc(Winc),
                      .Wdata(Wdata),
                      .Wfull(Wfull));		
                                                                            
                
endmodule 
