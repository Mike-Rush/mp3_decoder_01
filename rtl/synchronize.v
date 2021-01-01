//***********************************************************
//
//data        : 2007-07-11 11:30:00 
//version     : 1.0
//
//module name : synchronize
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-11-07  11:30:00   
//***********************************************************
`define DLY      0 
`timescale 1ns / 1ps
module synchronize(Clk,
                   Rst,
				   Enable,  
				   Done,
					fifo_empty, 
               fifo_datain,
               fifo_ren,
				   Granule,
				   Channel,
				   Ram_WEN,
					Invalid_format,
                   Ram_CEN,
                   Ram_A,
                   Ram_D,
						 Sfrq,
				   Mode,
					    Bitrate,
                   Mode_ext,
				   Blocksplit_flag,
                   Block_type,
                   Switch_point,
				   Global_gain,
                   Sub0_gain,
				   Sub1_gain,
				   Sub2_gain,
                   Preflag,
                   Scalefac_scale,
				   Main_data,        
                   Scfsi0,
				   Scfsi1,
				   Scfsi2,
				   Scfsi3,
                   Part2_3_length, 
                   Big_values,
                   Scalefac_compress,
                   count1table_select,
                   Table_select0,
				   Table_select1,
				   Table_select2,
                   Region1,
                   Region2);


// module port List
input              Clk;
input              Rst;
input			   Enable;
input			   Granule;
input			   Channel;
input              fifo_empty; 
input [31 :0]      fifo_datain;
output             fifo_ren;
output		       Ram_WEN;
output             Ram_CEN;
output[12:0]       Ram_A;
output[19:0]       Ram_D;
output[1 :0]	   Mode;
output[1 :0]       Mode_ext;
output			   Blocksplit_flag;
output[1 :0]       Block_type;
output             Switch_point;
output[7 :0]	   Global_gain;
output[2 :0]       Sub0_gain;
output[2 :0]	   Sub1_gain;
output[2 :0]	   Sub2_gain;
output             Preflag;
output             Scalefac_scale;
output[10:0]	   Main_data;        
output             Scfsi0;
output		       Scfsi1;
output	           Scfsi2;	 
output             Scfsi3;
output[11:0]       Part2_3_length; 
output[8 :0]       Big_values;
output[3 :0]       Scalefac_compress;
output[4 :0]       Table_select0;
output[4 :0]	   Table_select1;
output[4 :0]	   Table_select2;
output[3 :0]       Region1;
output[2 :0]       Region2;   
output             Done;
output             count1table_select;
output[1 :0]       Sfrq;
output[3 :0]       Bitrate;
output             Invalid_format;

reg		        Ram_WEN;
reg             Ram_CEN;
reg[12:0]       Ram_A/* synthesis syn_preserve =1 */;
reg[19:0]       Ram_D/* synthesis syn_preserve =1 */;
reg[1 :0]	    Sfrq;
reg[1 :0]	    Mode;
reg[1 :0]       Mode_ext;
reg			    Blocksplit_flag;
reg[1 :0]       Block_type;
reg             Switch_point;
reg[7 :0]	    Global_gain;
reg[2 :0]       Sub0_gain;
reg[2 :0]	    Sub1_gain;
reg[2 :0]	    Sub2_gain;
reg             Preflag;
reg             Scalefac_scale;
reg[10:0]	    Main_data;        
reg             Scfsi0;
reg		        Scfsi1;
reg	            Scfsi2;	 
reg             Scfsi3;
reg[11:0]       Part2_3_length; 
reg[8 :0]       Big_values;
reg[3 :0]       Scalefac_compress;
reg[4 :0]       Table_select0;
reg[4 :0]	    Table_select1;
reg[4 :0]	    Table_select2;
reg[3 :0]       Region1;
reg[2 :0]       Region2;   
reg             Done;  
reg             count1table_select;
reg[3 :0]       Bitrate;
reg             Invalid_format;
//Inter Signal List 
parameter  SYNC_WORD=15'b111111111111101;

parameter   
           IDLE=3'b000,
		   COMP=3'b001,
           REQU=3'b010,
           DOUT=3'b011,
           DONE=3'b100;  
           
parameter  NULL=3'b000,
           SYNC=3'b001,
           HEAD=3'b010,  
           CRC =3'b011,
           SIDE=3'b100,
           MAIN=3'b101,
           READ=3'b110;
           
reg  [2  :0] CS,  NS;   
reg  [2  :0] CSS, NSS;
reg  [2  :0] Cnt0;
reg  [2  :0] Data_pointer;
reg  [31 :0] Data_save;
reg  [7  :0] Data_reg;
reg  [14 :0] Pdata;
reg  [16 :0] Head_bit;
reg  [255:0] Side_bit; 
reg  [8  :0] Cnt1;  
reg  [10 :0] Cnt2;
reg  [10 :0] Main_Len; 
reg          Main_use; 
reg  [10 :0] Main_Addr; 
reg  [10 :0] Addr_offset;
reg  [10 :0] L0;
reg  [10 :0] L1;
reg  [10 :0] L2;
reg  [10 :0] L3;  
reg          Ch;
reg          Si_req;   
reg          Si;
reg          Si_use;
reg			 Data_use;
reg          Data_req;
reg  [11:0]  Data_cnt;

integer      Side_Len;


//*******************************main*************************************************************//

//Require MP3 Data
always@(posedge Clk)
begin
 if(!Rst)
   CS<=#`DLY IDLE;
 else
   CS<=#`DLY NS;
end


always@(Data_use or Enable or CS or Cnt0 or Si_req or CSS or Data_pointer or Done)
begin
  NS=IDLE;
  case(CS)
   IDLE: if(Enable&&(CSS!=READ)&&(~Done))
          NS=COMP;
         else
          NS=IDLE;
	
	COMP: if(Data_pointer[2])
	       NS=REQU;
		  else
		   NS=DOUT;  
          
   REQU: if(Data_use)         
          NS=COMP;
         else       
          NS=REQU; 
                    
   DOUT: if((Cnt0==7)&&(Si_req==1)||(CSS==MAIN))
          NS=DONE;
         else
          NS=DOUT;  
                    
   DONE: NS=IDLE;
  endcase
end

always@(posedge Clk)
begin
 if(Data_use)
   Data_save<=#`DLY fifo_datain;
end

always@(posedge Clk)
begin
  Data_use<=#`DLY Data_req;
end

always@(CS or fifo_empty or Data_use)
begin
 if((CS==REQU)&&(!fifo_empty)&&(~Data_use))
   Data_req= 1'b1;
 else
   Data_req= 1'b0;
end

assign fifo_ren=Data_req;

always@(posedge Clk)
begin
 if(!Rst)
   Data_pointer<=#`DLY 3'b100;  
 else if(CS==REQU&&Enable)
   Data_pointer<=#`DLY 3'b000;
 else if(CS==DONE&&Enable)
   Data_pointer<=#`DLY Data_pointer+1;
end

always@(Data_save or Data_pointer)
begin
  case(Data_pointer)
     3: Data_reg=Data_save[7 : 0];
	 2: Data_reg=Data_save[15: 8];
	 1: Data_reg=Data_save[23:16];
	 default: Data_reg=Data_save[31:24];
   endcase
end

always@(posedge Clk)
begin
 if(CS==REQU||CSS==NULL)
  Cnt0<=#`DLY 3'b0;
 else if((Si_req)&&(CS==DOUT)) 
  Cnt0<=#`DLY Cnt0+1;
end

always@(Cnt0 or Data_reg)
begin
 Si=Data_reg[(~Cnt0)];
end 

always@(CS or Si_req)
begin
 if(CS==DOUT)
  Si_use<=#`DLY Si_req;
 else
  Si_use<=#`DLY 1'b0;
end

//synchronize depart header side_infor Main_data from MP3 bit stream

always@(posedge Clk)
begin
  if(!Rst)
    CSS<=#`DLY NULL;
  else
    CSS<=#`DLY NSS;
end

always@(CSS or Pdata or Si or Cnt1 or Main_Len or Head_bit or Side_Len or Enable or Cnt2 or Done)  
begin
   case(CSS)
    NULL: if(Enable&(~Done))
           NSS=SYNC;
          else
           NSS=NULL; 
   
   SYNC: if(Pdata[14:0]==SYNC_WORD)
           NSS=HEAD;
         else       
           NSS=SYNC;
           
   HEAD: if(Cnt1==17)
           NSS=CRC;
         else
           NSS=HEAD;
  
   CRC:  if((Cnt1==16)||(Head_bit[16]))
           NSS=SIDE;
         else
           NSS=CRC; 

   SIDE: if(Cnt1==Side_Len)
           NSS=MAIN;
         else
           NSS=SIDE;
   
   MAIN: if(Cnt2==Main_Len)
           NSS=READ;
         else
           NSS=MAIN;
  
  READ:    NSS=NULL;
  
  default: NSS=NULL;
 endcase
end  

always@(CSS or Pdata or Si or Cnt1 or Head_bit or Side_Len or Main_Len or Cnt2)  
begin
   case(CSS) 
    SYNC: if(Pdata[14:0]==SYNC_WORD)
           Si_req=1'b0;
         else       
           Si_req=1'b1;
           
    HEAD: if(Cnt1==17)
           Si_req=1'b0;
         else
           Si_req=1'b1;
  
   CRC:  if((Cnt1==16)||(Head_bit[16]))
           Si_req=1'b0;
         else
           Si_req=1'b1; 

   SIDE: if(Cnt1==Side_Len)
           Si_req=1'b0;
         else
           Si_req=1'b1;
   
   MAIN: if(Cnt2==Main_Len)
           Si_req=1'b0;
         else
           Si_req=1'b1;  
           
  default: Si_req=1'b0;
 endcase
end  

always@(posedge Clk)
begin
 if(CSS==READ)
   Done<=#`DLY  1'b1;
 else
   Done<=#`DLY  1'b0;
end 

//Si counter
always@(posedge Clk)
begin
 if(!Si_req)
  Cnt1<=#`DLY 8'b0;
 else if(Si_use)
  Cnt1<=#`DLY Cnt1+1;
end

//Main data Counter
always@(posedge Clk)
begin
 if(!Si_req)
  Cnt2<=#`DLY 11'b0;
 else if(!Main_use)
  Cnt2<=#`DLY Cnt2+1;
end

//depart SYNC_WORD
always@(posedge Clk)
begin 
  if(CSS==NULL)
    Pdata<=#`DLY 15'b0;
  else if((CSS==SYNC)&&(Si_use))
    Pdata<=#`DLY {Pdata[13:0],Si};
end

//depart  Head Ifor
always@(posedge Clk)
begin 
  if((CSS==HEAD)&&(Si_use))
    Head_bit<=#`DLY {Head_bit[15:0],Si};
end
 
//depart  Side Ifor
always@(posedge Clk)
begin 
  if((CSS==SIDE)&&(Si_use))
    Side_bit<=#`DLY {Side_bit[254:0],Si};
end     
      
//side infor length
always@(Ch)
begin
  if(Ch)
    Side_Len=136;
  else
    Side_Len=256;
end

always@(Head_bit)
begin
  Ch=Head_bit[7]&Head_bit[6];
end

//current data not a mp3 format
always@(posedge Clk)
begin
 if(!Rst)
   Data_cnt<=#`DLY 12'b0;
 else if(CSS==HEAD)
   Data_cnt<=#`DLY 12'b1111_1111_1111;
 else if(CSS==SYNC&&Data_use&&Data_cnt!=4095)
   Data_cnt<=#`DLY Data_cnt+1;
end

always@(posedge Clk)
begin
 if(!Rst)
   Invalid_format<=#`DLY 1'b0;
 else if(Data_cnt==4094||(CSS==MAIN&&Mode_ext[0]&&Mode==1))
   Invalid_format<=#`DLY 1'b1;
end

//Main data Length Table
always@(Head_bit)
begin
  case(Head_bit[15:12])
   1: begin L0=11'd105; L1=11'd65;  L2=11'd57;  end
   2: begin L0=11'd141; L1=11'd91;  L2=11'd81;  end
   3: begin L0=11'd177; L1=11'd117; L2=11'd105; end
   4: begin L0=11'd213; L1=11'd143; L2=11'd129; end
   5: begin L0=11'd249; L1=11'd169; L2=11'd153; end
   6: begin L0=11'd321; L1=11'd222; L2=11'd201; end
   7: begin L0=11'd393; L1=11'd274; L2=11'd249; end
   8: begin L0=11'd465; L1=11'd326; L2=11'd297; end
   9: begin L0=11'd537; L1=11'd378; L2=11'd345; end
   10:begin L0=11'd681; L1=11'd483; L2=11'd441; end
   11:begin L0=11'd825; L1=11'd587; L2=11'd537; end
   12:begin L0=11'd969; L1=11'd692; L2=11'd633; end
   13:begin L0=11'd1113;L1=11'd796; L2=11'd729; end
  default:begin L0=11'd1401;L1=11'd1005;L2=11'd921; end
  endcase
end 

always@(Head_bit or L0 or L1 or L2)
begin
 case(Head_bit[11:10]) 
  0: L3=L1;
  1: L3=L2;
  default:L3=L0;
 endcase
end

always@(Ch or Head_bit or L3)
begin
 Main_Len=L3+{Ch,Ch,Ch,Ch}+{Head_bit[16],~Head_bit[9]}+{Head_bit[9],1'b0};
end 

//Write Main data to Memory 
always@(CSS or Si_use)
begin
 if((Si_use)&&(CSS==MAIN))
   Main_use=1'b0; 
 else
   Main_use=1'b1;
end

always@(posedge Clk)
begin
 Ram_WEN<=#`DLY Main_use;
end

always@(posedge Clk)
begin
 Ram_CEN<=#`DLY Main_use;
end

always@(posedge Clk)
begin 
 if(!Main_use)
 Ram_D<=#`DLY {Data_reg,12'b0};
end 
   
always@(posedge Clk)
begin
 if(!Rst)
   Main_Addr<=#`DLY 11'b0;
 else if(!Main_use)
   Main_Addr<=#`DLY Main_Addr+1;
end

always@(posedge Clk)
begin
 Ram_A<=#`DLY {2'b0,Main_Addr};
end

//output Side Information
always@(posedge Clk)
begin
 if(CSS==HEAD)
   Addr_offset<=#`DLY Main_Addr;
end

always@(Head_bit or Side_bit or Addr_offset or Ch)
begin
  if(Ch)
    Main_data=Addr_offset-Side_bit[135:127];
  else
    Main_data=Addr_offset-Side_bit[255:247];
end

always@(Head_bit)
begin
  Mode=Head_bit[7:6];
  Mode_ext=Head_bit[5:4];
  Sfrq=Head_bit[11:10];
  Bitrate=Head_bit[15:12];
end

always@(Ch or Channel or Granule or Side_bit)
begin
  case({Ch,Granule,Channel})
    3'b100 : begin Blocksplit_flag=Side_bit[84];
                   Block_type=Side_bit[83:82]&{Side_bit[84],Side_bit[84]};
                   Switch_point=Side_bit[81]; end 
                   
    3'b000 :begin Blocksplit_flag=Side_bit[202];
                   Block_type=Side_bit[201:200]&{Side_bit[202],Side_bit[202]};
                   Switch_point=Side_bit[199]; end   
                   
    3'b001 :begin Blocksplit_flag=Side_bit[143];
                   Block_type=Side_bit[142:141]&{Side_bit[143],Side_bit[143]};
                   Switch_point=Side_bit[140]; end    
                   
    3'b010 :begin Blocksplit_flag=Side_bit[84];
                   Block_type=Side_bit[83:82]&{Side_bit[84],Side_bit[84]};
                   Switch_point=Side_bit[81]; end   
                   
    default: begin Blocksplit_flag=Side_bit[25];
                   Block_type=Side_bit[24:23]&{Side_bit[25],Side_bit[25]};
                   Switch_point=Side_bit[22]; end    
   endcase
end

always@(Ch or Channel or Granule or Side_bit)
begin
  case({Ch,Granule,Channel})
    3'b100 : begin Global_gain=Side_bit[96:89];
                   Sub0_gain=Side_bit[70:68];
                   Sub1_gain=Side_bit[67:65];
                   Sub2_gain=Side_bit[64:62]; 
                   Preflag=Side_bit[61];
                   Scalefac_scale=Side_bit[60];  
                   Region1=Side_bit[68:65];
                   Region2=Side_bit[64:62];
                   end  
                   
    3'b000 :begin  Global_gain=Side_bit[214:207];
                   Sub0_gain=Side_bit[188:186];
                   Sub1_gain=Side_bit[185:183];
                   Sub2_gain=Side_bit[182:180]; 
                   Preflag=Side_bit[179];
                   Scalefac_scale=Side_bit[178]; 
                   Region1=Side_bit[186:183];
                   Region2=Side_bit[182:180];
                   end   
                   
    3'b001 :begin  Global_gain=Side_bit[155:148];
                   Sub0_gain=Side_bit[129:127];
                   Sub1_gain=Side_bit[126:124];
                   Sub2_gain=Side_bit[123:121]; 
                   Preflag=Side_bit[120];
                   Scalefac_scale=Side_bit[119]; 
                   Region1=Side_bit[127:124];
                   Region2=Side_bit[123:121];
                   end   
                   
    3'b010 :begin  Global_gain=Side_bit[96:89];
                   Sub0_gain=Side_bit[70:68];
                   Sub1_gain=Side_bit[67:65];
                   Sub2_gain=Side_bit[64:62]; 
                   Preflag=Side_bit[61];
                   Scalefac_scale=Side_bit[60];
                   Region1=Side_bit[68:65];
                   Region2=Side_bit[64:62];end 
                    
                   
    default:begin  Global_gain=Side_bit[37:30];
                   Sub0_gain=Side_bit[11:9];
                   Sub1_gain=Side_bit[8:6];
                   Sub2_gain=Side_bit[5:3]; 
                   Preflag=Side_bit[2];
                   Scalefac_scale=Side_bit[1];
                   Region1=Side_bit[9:6];
                   Region2=Side_bit[5:3];end    
   endcase
end
                  
always@(Ch or Channel or Granule or Side_bit)
begin
  case({Ch,Granule,Channel})
    3'b100 : begin Scfsi0=1'b0;
				   Scfsi1=1'b0;
				   Scfsi2=1'b0;
				   Scfsi3=1'b0;
                   Part2_3_length=Side_bit[117:106];
                   Big_values=Side_bit[105:97];
                   Scalefac_compress=Side_bit[88:85];
                   count1table_select=Side_bit[59];end  
                   
   3'b110 : begin  Scfsi0=Side_bit[121];
				   Scfsi1=Side_bit[120];
				   Scfsi2=Side_bit[119];
				   Scfsi3=Side_bit[118];
                   Part2_3_length=Side_bit[58:47]; 
                   Big_values=Side_bit[46:38];
                   Scalefac_compress=Side_bit[29:26];
                   count1table_select=Side_bit[0];end  
                   
    3'b000 :begin  Scfsi0=1'b0;
				   Scfsi1=1'b0;
				   Scfsi2=1'b0;
				   Scfsi3=1'b0;
                   Part2_3_length=Side_bit[235:224]; 
                   Big_values=Side_bit[223:215];
                   Scalefac_compress=Side_bit[206:203];
                   count1table_select=Side_bit[177]; end   
                   
    3'b001 :begin  Scfsi0=1'b0;
				   Scfsi1=1'b0;
				   Scfsi2=1'b0;
				   Scfsi3=1'b0;
                   Part2_3_length=Side_bit[176:165];
                   Big_values=Side_bit[164:156];
                   Scalefac_compress=Side_bit[147:144];
                   count1table_select=Side_bit[118]; end    
                   
    3'b010 :begin  Scfsi0=Side_bit[243];
				   Scfsi1=Side_bit[242];
				   Scfsi2=Side_bit[241];
				   Scfsi3=Side_bit[240];
                   Part2_3_length=Side_bit[117:106];
                   Big_values=Side_bit[105:97];
                   Scalefac_compress=Side_bit[88:85];
                   count1table_select=Side_bit[59];
                   end  
                    
                   
    default:begin  Scfsi0=Side_bit[239];
				   Scfsi1=Side_bit[238];
				   Scfsi2=Side_bit[237];
				   Scfsi3=Side_bit[236];
                   Part2_3_length=Side_bit[58:47]; 
                   Big_values=Side_bit[46:38];
                   Scalefac_compress=Side_bit[29:26];
                   count1table_select=Side_bit[0]; end    
   endcase
end

always@(Ch or Channel or Granule or Side_bit)
begin
   case({Ch,Granule,Channel})
     3'b100: begin 
               if(Side_bit[84]) begin 
                Table_select0=Side_bit[80:76];
                Table_select1=Side_bit[75:71];
                Table_select2=5'b0;  end 
              else  begin 
                Table_select0=Side_bit[83:79];
                Table_select1=Side_bit[78:74];
                Table_select2=Side_bit[73:69]; end
             end                                                   
     
     3'b000: begin 
               if(Side_bit[202]) begin 
                Table_select0=Side_bit[198:194];
                Table_select1=Side_bit[193:189];
                Table_select2=5'b0;  end 
              else  begin 
                Table_select0=Side_bit[201:197];
                Table_select1=Side_bit[196:192];
                Table_select2=Side_bit[191:187]; end
             end    
     
     3'b001:begin 
               if(Side_bit[143]) begin 
                Table_select0=Side_bit[139:135];
                Table_select1=Side_bit[134:130];
                Table_select2=5'b0;  end 
              else  begin 
                Table_select0=Side_bit[142:138];
                Table_select1=Side_bit[137:133];
                Table_select2=Side_bit[132:128]; end
             end    
     
     3'b010:begin 
               if(Side_bit[84]) begin 
                Table_select0=Side_bit[80:76];
                Table_select1=Side_bit[75:71];
                Table_select2=5'b0;  end 
              else  begin 
                Table_select0=Side_bit[83:79];
                Table_select1=Side_bit[78:74];
                Table_select2=Side_bit[73:69]; end
             end    
     
     default:begin 
               if(Side_bit[25]) begin 
                Table_select0=Side_bit[21:17];
                Table_select1=Side_bit[16:12];
                Table_select2=5'b0;  end 
              else  begin 
                Table_select0=Side_bit[24:20];
                Table_select1=Side_bit[19:15];
                Table_select2=Side_bit[14:10]; end
             end    
    endcase
end
        
//synopsys translate_off
//********************************Test*****************************// 

    
integer Y;                                                                
initial begin                                                             
  Y = $fopen("./MP3_USED_DATA.txt","w");                                      
end   

always@(posedge Clk)
begin                                             
  if(Data_use)
      $fdisplay(Y,"%h%h%h%h",fifo_datain[31:24],fifo_datain[23:16],fifo_datain[15:8],fifo_datain[7:0]);                                                                   
end
//synopsys translate_on
endmodule
