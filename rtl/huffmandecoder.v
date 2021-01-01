//***********************************************************
//
//copyright 2007, DTK
//all right reserved
//
//data        : 2007-07-14 8:50:00 
//version     : 1.0
//
//module name : huffmandecoder
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-07-11  11:30:00   
//***********************************************************   
`define DLY      0
`timescale 1ns / 1ps
module huffmandecoder(Clk,
                      Enable,
                      Rst,   
                      Granule,
                                      Channel,
                                      Sfrq,
                                      Ram_WEN,
                      Ram_CEN,
                      Ram_A,
                      Ram_D,
                      Ram_Q,   
                      Rom_A,
                      Rom_Q,
                      Rom_CEN,
                      Main_data,        
                      Scfsi0,
                                      Scfsi1,
                                      Scfsi2,
                                      Scfsi3, 
                                      Blocksplit_flag,
                      Block_type,
                      Switch_point,
                      Part2_3_length, 
                      Big_values,
                      Scalefac_compress,
                      count1table_select,
                      Table_select0,
                                      Table_select1,
                                      Table_select2,
                      Region1,
                      Region2,
                      Done);       
                      
// module port List
input             Clk;
input             Rst;
input                     Enable;
input                     Granule;
input                     Channel; 
input[10:0]           Main_data;
input[19:0]       Rom_Q;
input[19:0]       Ram_Q;    
input[1 :0]       Sfrq;
input                     Blocksplit_flag;
input[1 :0]       Block_type;
input             Switch_point;        
input             Scfsi0;
input                 Scfsi1;
input             Scfsi2;        
input             Scfsi3;
input[11:0]       Part2_3_length; 
input[8 :0]       Big_values;
input[3 :0]       Scalefac_compress;
input[4 :0]       Table_select0;
input[4 :0]           Table_select1;
input[4 :0]           Table_select2;
input[3 :0]       Region1;
input[2 :0]       Region2;   
input             count1table_select; 
output            Done;
output                Ram_WEN;
output            Ram_CEN;
output[12:0]      Ram_A;
output[19:0]      Ram_D;
output[12:0]      Rom_A;
output            Rom_CEN;


reg               Done;
reg                       Ram_WEN;
reg               Ram_CEN;
reg[12:0]         Ram_A;
reg[19:0]         Ram_D; 
reg[12:0]         Rom_A;
reg               Rom_CEN;    


//inter variable

parameter  IDLE=2'b00,
           RUN =2'b01,
           READ=2'b10;
           
reg[1 :0] CS,NS;
reg[5 :0] Pointer;
reg[31:0] Data0;                  //* synthesis syn_preserve =1 */;
reg[15:0] Dout;
reg[12:0] Addr0;
reg[10:0] Temp0;    
reg[5 :0] Temp1; 
reg[31:0] Temp2;
reg[3 :0] Bit_Cnt; 
reg       Bit_use; 
reg       Incr0;
reg       Bit_in;

reg[2 :0] Slen0,Slen1,Slen2;     //scale
reg[4 :0] Sfb;
reg[3 :0] CSS, NSS;
reg[12:0] Bitleft;
reg[1 :0] Block;      
reg[1 :0] Win;
reg       Scale_WEN;
reg       Scale_CEN;
reg[3 :0] Scale_D;
reg[12:0] Scale_A; 
reg[2 :0] Scale_Cnt;   
reg       Scale_use;

reg[9 :0] R1start;               //huffman
reg[9 :0] R2start;

reg[3 :0] Reg1_addr;
reg[2 :0] Reg2_addr;
reg[12:0] Reg_addr; 
reg[1 :0] Cnt0;
reg[4 :0] Temp3;
reg[4 :0] Temp4;
reg[3 :0] Temp5; 
reg[3 :0] Linbit;
reg[4 :0] Table;  
reg[11:0] Huff_saddr;   
reg[12:0] Huff_addr;
reg[12:0] Rom_addr;
reg       Big_flag;
reg[2 :0] Vwxy;  
reg[12:0] Value;
reg[12:0] Value_reg;
reg       Value_flag; 
reg[7 :0] Count1;     
reg       Count1_flar; 
reg[13:0] Temp6; 
reg[19:0] Temp7;
reg[9 :0] Temp11;
reg[19:0] Data1;  
reg[9 :0] Line;
reg       Sign;   
reg[7 :0] Win_width; 
reg[9 :0] Sfbindex;
reg[2 :0] Cnt1;
reg[7 :0] Cnt2;
reg[3 :0] Cnt3; 
reg[12:0] Addr1;
reg[9 :0] A1,A2,A3;
reg       Reorder;
reg[12:0] Sfb_addr;
reg       Scale_flag; 
reg       Sign_flag;
reg       Zero_flag;
reg       Sfb_flag;
reg[3 :0] Temp8;     
reg       Discard;

parameter 
          NULL   =4'b0000,
          STYPE  =4'b0001,
          LTYPE  =4'b0010,
          CALRG  =4'b0011,
          SELRG  =4'b0100,  
          FIND0  =4'b0101,
          FIND1  =4'b0110, 
          COUNT1 =4'b0111, 
          BIGS   =4'b1000, 
          REORD  =4'b1001,
          ZERO   =4'b1010,
          SAVE   =4'b1011,
          DONE   =4'b1100,
                  BUSY   =4'b1101,
                  WAIT   =4'b1110,
          WRITE  =4'b1111; 


//bit_buff  
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY IDLE;
  else
    CS<=#`DLY NS;
end

always@(CS or Incr0 or Enable)
begin
  case(CS)
    IDLE: if(Enable)
            NS=RUN;
          else
            NS=IDLE;
            
    RUN : if(!Enable)
            NS=IDLE;
          else if(Incr0)
            NS=READ;
          else
            NS=RUN;
  
   READ:    NS=RUN;
   
   default: NS=RUN;
 endcase
end

always@(posedge Clk)
begin
  if(!Rst)
    Addr0<=#`DLY 13'b0 ;
  else if((!Granule)&&(!Channel)&&(CS==IDLE)&&(Enable==1))
    Addr0<=#`DLY {2'b00, Main_data};
  else 
    Addr0<=#`DLY {2'b0,Temp0};
end

always@(Addr0 or Incr0)
begin
  if(Incr0)
    Temp0=Addr0+1;
  else
    Temp0=Addr0;
end  
   
always@(Temp1 or CS)
begin
 if(((Temp1==63)||(Temp1<24))&&(CS==RUN))
   Incr0=1'b1;
 else
   Incr0=1'b0;
end           

always@(posedge Clk)
begin
  if(CS==READ)
    Bit_in<=#`DLY 1'b1;
  else
    Bit_in<=#`DLY 1'b0;
end
    
always@(Bit_Cnt or Pointer or  Bit_in)
begin
  Temp1=Pointer+{Bit_in,3'b0}-Bit_Cnt;
end

always@(posedge Clk)
begin
  if((!Granule)&&(!Channel)&&(Enable)&&(CS==NULL))
    Pointer<=#`DLY 6'b111111;
  else
    Pointer<=#`DLY Temp1;
end

always@(Ram_Q or Pointer or Data0)
begin
  case(Pointer)
    0: begin Temp2={23'b0,Data0[0   ],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    1: begin Temp2={22'b0,Data0[1 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    2: begin Temp2={21'b0,Data0[2 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    3: begin Temp2={20'b0,Data0[3 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    4: begin Temp2={19'b0,Data0[4 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    5: begin Temp2={18'b0,Data0[5 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    6: begin Temp2={17'b0,Data0[6 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    7: begin Temp2={16'b0,Data0[7 :0],Ram_Q[19:12]}; Dout=Temp2[15:0];  end
    8: begin Temp2={15'b0,Data0[8 :0],Ram_Q[19:12]}; Dout=Temp2[16:1];  end
    9: begin Temp2={14'b0,Data0[9 :0],Ram_Q[19:12]}; Dout=Temp2[17:2];  end
    10:begin Temp2={13'b0,Data0[10:0],Ram_Q[19:12]}; Dout=Temp2[18:3];  end
    11:begin Temp2={12'b0,Data0[11:0],Ram_Q[19:12]}; Dout=Temp2[19:4];  end
    12:begin Temp2={11'b0,Data0[12:0],Ram_Q[19:12]}; Dout=Temp2[20:5];  end
    13:begin Temp2={10'b0,Data0[13:0],Ram_Q[19:12]}; Dout=Temp2[21:6];  end
    14:begin Temp2={9 'b0,Data0[14:0],Ram_Q[19:12]}; Dout=Temp2[22:7];  end
    15:begin Temp2={8 'b0,Data0[15:0],Ram_Q[19:12]}; Dout=Temp2[23:8];  end
    16:begin Temp2={7 'b0,Data0[16:0],Ram_Q[19:12]}; Dout=Temp2[24:9];  end
    17:begin Temp2={6 'b0,Data0[17:0],Ram_Q[19:12]}; Dout=Temp2[25:10]; end
    18:begin Temp2={5 'b0,Data0[18:0],Ram_Q[19:12]}; Dout=Temp2[26:11]; end
    19:begin Temp2={4 'b0,Data0[19:0],Ram_Q[19:12]}; Dout=Temp2[27:12]; end
    20:begin Temp2={3 'b0,Data0[20:0],Ram_Q[19:12]}; Dout=Temp2[28:13]; end
    21:begin Temp2={2 'b0,Data0[21:0],Ram_Q[19:12]}; Dout=Temp2[29:14]; end
    22:begin Temp2={1 'b0,Data0[22:0],Ram_Q[19:12]}; Dout=Temp2[30:15]; end
    23:begin Temp2={Data0[23:0],Ram_Q[19:12]};       Dout=Temp2[31:16]; end
    24:begin Temp2=Data0;                            Dout=Temp2[24: 9]; end
    25:begin Temp2=Data0;                            Dout=Temp2[25:10]; end
    26:begin Temp2=Data0;                            Dout=Temp2[26:11]; end
    27:begin Temp2=Data0;                            Dout=Temp2[27:12]; end
    28:begin Temp2=Data0;                            Dout=Temp2[28:13]; end
    29:begin Temp2=Data0;                            Dout=Temp2[29:14]; end
    30:begin Temp2=Data0;                            Dout=Temp2[30:15]; end
    31:begin Temp2=Data0;                            Dout=Temp2[31:16]; end
    default: begin Temp2={24'b0,Ram_Q[19:12]};       Dout=Temp2[15: 0]; end
  endcase
end    
    
always@(posedge Clk)
begin
 if(Bit_in)
   Data0<=#`DLY Temp2;
end
    
always@(Pointer or CS)
begin
 if((Pointer!=63)&&(Pointer>=15)&&(CS!=IDLE))
   Bit_use=1'b1;
 else
   Bit_use=1'b0;
end    

always@(Scale_Cnt or Rom_Q or Sign_flag or Linbit or Count1_flar or Value_flag or CSS or Discard)
begin 
 if((CSS==FIND1 &&(Rom_Q[15:8]!=0))||(Sign_flag))
   Bit_Cnt=4'b0001;
 else if(Value_flag)
   Bit_Cnt=Linbit;
 else if(Count1_flar)
   Bit_Cnt=4'b0100;
 else if(CSS==DONE)
   Bit_Cnt={3'b0,Discard};
 else
   Bit_Cnt=Scale_Cnt;
end    
    
//depart scale factor and huffmandata

always@(Scalefac_compress)       //scale_factor leng table
 begin 
   case(Scalefac_compress)
    4:  Slen0=3'b011;
    5:  Slen0=3'b001;
    6:  Slen0=3'b001;
    7:  Slen0=3'b001;
    8:  Slen0=3'b010;
    9:  Slen0=3'b010;
    10: Slen0=3'b010;
    11: Slen0=3'b011;
    12: Slen0=3'b011; 
    13 :Slen0=3'b011;
    14: Slen0=3'b100; 
    15: Slen0=3'b100;
    default: Slen0=3'b000;
   endcase
end

always@(Scalefac_compress)      //scale_factor leng table
 begin 
   case(Scalefac_compress)
    0:  Slen1=3'b000;
    1:  Slen1=3'b001;
    2:  Slen1=3'b010;
    4:  Slen1=3'b000;
    5:  Slen1=3'b001;
    6:  Slen1=3'b010;
    8:  Slen1=3'b001;
    9:  Slen1=3'b010;
    11: Slen1=3'b001;
         12: Slen1=3'b010; 
    13: Slen1=3'b011;
    14: Slen1=3'b010; 
    default: Slen1=3'b011;
   endcase
end

always@(Slen1 or Slen0 or Sfb or CSS or Block)
begin      
  case(CSS)
    STYPE  : begin if((Sfb==12)||(Sfb==13))
                     Slen2=3'b0;
                    else if(Sfb<=5)  
                     Slen2=Slen0; 
                    else 
                                         Slen2=Slen1; end
                    
    default: begin if((Sfb==23)||(Sfb==22)||(Sfb==21)||((Sfb==8)&&(Block==3)))
                     Slen2=3'b0;
                    else if(Sfb>=11) 
                     Slen2=Slen1; 
                    else 
                                         Slen2=Slen0; end
  endcase
end

always@(Blocksplit_flag or Block_type or Switch_point)
begin
  if((Blocksplit_flag==1)&&(Block_type==2)) begin
      if (Switch_point==1) 
                Block=2'b11;                    //mix   sfb
          else                                             
        Block=2'b10;  end               //short sfb
  else 
            Block=2'b00;                    //long  sfb
end 

always@(posedge Clk)
begin
 if(!Rst)
   CSS<=#`DLY NULL;
 else
   CSS<=#`DLY NSS;
end

always@(CSS or Enable or Bit_use or Block or Cnt0 or Blocksplit_flag or Block_type or Sfb or Win or Incr0
        or Big_values or Line or Bitleft or count1table_select or Vwxy or Reorder or Rom_Q or Sfbindex or
            Cnt1 or Big_flag or Scale_flag or Zero_flag)
begin
  case(CSS)
     
   NULL: if(Enable&&Bit_use)begin
           if(Block==2)
             NSS=STYPE;
           else
             NSS=LTYPE; end
          else
             NSS=NULL;
   
   STYPE: if((Sfb==13)&&(Win==3))
            NSS=CALRG;
          else
            NSS=WAIT;
            
   LTYPE: if((Block==3)&&(Sfb==8))
            NSS=STYPE;
          else if((Sfb==23))
            NSS=CALRG;
          else
            NSS=WAIT;   

   WAIT  : NSS=WRITE;
            
   WRITE : if(Scale_flag)
             NSS=LTYPE;
            else
             NSS=STYPE;         
            
            
   CALRG : if(((Blocksplit_flag)&&(Block_type==2))||(Cnt0==3))
             NSS=SELRG;
           else
             NSS=CALRG;
             
   SELRG : if (Line<{Big_values,1'b0})
             NSS=FIND0;  
           else if((Line<576)&&(Bitleft[12:2]!=0)) 
             NSS=COUNT1;
           else if(Line<576)
             NSS=REORD;   
           else                 
             NSS=DONE;
            
   
   FIND0 : NSS=FIND1;
   
   FIND1 : if(Rom_Q[15:8]==0) begin
            if(Big_flag)
             NSS=BIGS;
            else
             NSS=REORD; end
           else
             NSS=FIND0;   
             
  BIGS  : NSS=REORD;           
             
  COUNT1: if(!count1table_select)
            NSS=FIND0;
          else 
            NSS=REORD;  
            
  REORD: if(Reorder==0)
           begin  
           if(Zero_flag)
            NSS=ZERO;
           else
            NSS=SAVE; end
          else if((Line!=Sfbindex)&&(Cnt1==0))
           begin
           if(Zero_flag)
            NSS=ZERO;
           else
            NSS=SAVE; end
          else if(Cnt1==3)
           begin
           if(Zero_flag)
            NSS=ZERO;
           else
            NSS=SAVE; end         
          else
            NSS=REORD;  
            
  SAVE : if((Big_flag)&&(Vwxy==2)&&(!Incr0))
           NSS=BIGS;
         else if((Vwxy==3)&&(!Incr0))
           NSS=SELRG;
         else if(!Incr0)
           NSS=REORD;
                        else
                          NSS=SAVE;           
              
  ZERO : if(Line==576)
                   NSS=DONE;
         else
           NSS=REORD;
              
  DONE :  if(Bitleft==0)
            NSS=BUSY;
          else
            NSS=DONE; 
           
  BUSY :  NSS=NULL;

  default :NSS=NULL;                                                      
 endcase 
end

always@(Line or Big_values) 
begin 
  if(Line<{Big_values,1'b0})
    Big_flag=1'b1; 
  else
    Big_flag=1'b0;
end
 
always@(posedge Clk)
begin
 if((CSS==DONE)&&(Bitleft==0))
   Done<=1'b1;
  else
   Done<=1'b0;
end


always@(posedge Clk)     //scale_factor 
begin
  if(CSS==NULL)
    Sfb<=#`DLY 5'b0;
  else if((CSS==WRITE)&&((!Sfb_flag)||(Win==2)))
    Sfb<=#`DLY Sfb+1;
  else if((CSS==LTYPE)&&(Sfb==8)&&(Block==3))
    Sfb<=#`DLY 5'b00011;
end
    
always@(posedge Clk)
begin
  if((CSS==NULL)||(Win==3))
    Win<=#`DLY 2'b0;
  else if((CSS==WRITE)&&(Sfb_flag))
    Win<=#`DLY Win+1;
end

always@(posedge Clk)
begin 
 if(CSS==LTYPE)
   Scale_flag<=#`DLY 1'b1;
 else if (CSS==STYPE)
   Scale_flag<=#`DLY 1'b0;
end
   

always@(CSS or Scale_use)
begin
 if((CSS==WRITE)&&(Scale_use))begin
  Scale_WEN=1'b0; 
  Scale_CEN=1'b0; end
 else  begin
  Scale_WEN=1'b1; 
  Scale_CEN=1'b1; end
end

always@(Sfb or Win or Channel or Scale_flag)
begin
 if(Scale_flag)
  Scale_A={7'b0,Channel, Sfb}+2624;
 else   
  Scale_A={6'b0,1'b1,Sfb[3:0],Win}+2624;
end 
                             
always@(posedge Clk)
begin 
 if((CSS==STYPE)||(CSS==LTYPE))begin 
 case(Slen2)
   1: Scale_D<={3'b0,Dout[15]};
   2: Scale_D<={2'b0,Dout[15:14]};
   3: Scale_D<={1'b0,Dout[15:13]};
   4: Scale_D<=Dout[15:12];
   default:Scale_D<=4'b0;
 endcase end
end 

always@(Scfsi0 or Scfsi1 or Scfsi2 or Scfsi3  or Sfb or Granule or Block)
begin 
 if((!Granule)||(Block==2)||(Block==3)||(Sfb==21)||(Sfb==22)||(Sfb==23))
  Scale_use=1'b1;
 else if((Scfsi0==0)&&(Sfb<6))
  Scale_use=1'b1;
 else if((Scfsi1==0)&&(Sfb>=6)&&(Sfb<11))
  Scale_use=1'b1;
 else if((Scfsi2==0)&&(Sfb>=11)&&(Sfb<16))
  Scale_use=1'b1;
 else if((Scfsi3==0)&&(Sfb>=16)&&(Sfb<21))
  Scale_use=1'b1;  
 else 
  Scale_use=1'b0;
end
  
always@(posedge Clk)//Incr0 or CSS or Scale_use or Slen2)
begin
 if(((CSS==STYPE)||(CSS==LTYPE))&&(Scale_use))
   Scale_Cnt<=Slen2;
 else
   Scale_Cnt<=3'b0;
end
  
//huffman 
always@(Blocksplit_flag or Block_type or Region1 or Region2)     //cale r1start r2start
begin
 if(Blocksplit_flag) begin 
     Reg2_addr=3'b000; 
   if(Block_type==2)
     Reg1_addr=4'b1000;
   else   
     Reg1_addr=4'b0111; end 
 else begin
   Reg1_addr=Region1;
   Reg2_addr=Region2; end
end   
           
always@(posedge Clk)
begin
  if(CSS==NULL)
    Cnt0<=#`DLY 2'b0;
  else if(CSS==CALRG)
    Cnt0<=#`DLY Cnt0+1;
end

always@(posedge Clk)
begin
  if(CSS==NULL)
    R1start<=#`DLY 10'b0000100100;
  else if(Cnt0==2)
    R1start<=#`DLY Rom_Q[9:0];
end
   
always@(posedge Clk)
begin
  if(CSS==NULL)
    R2start<=#`DLY 10'b1001000000;
  else if((Cnt0==3)&&(!Blocksplit_flag))
    R2start<=#`DLY Rom_Q[9:0];
end
    
always@(Reg2_addr or Reg1_addr)
begin
  Temp3=Reg1_addr+1;
  Temp4=Reg1_addr+Reg2_addr+2;
end

always@(Temp3 or Temp4 or Cnt0 or Sfrq)
begin
  if(Cnt0==0)
    Reg_addr={6'b0,Sfrq,Temp3}+2816;
  else
    Reg_addr={6'b0,Sfrq,Temp4}+2816;
end  
  
always@(Table)      //Linbit and huffman table addr
begin
  case(Table)
    16:Linbit=4'b0001; 
    17:Linbit=4'b0010; 
    18:Linbit=4'b0011; 
    19:Linbit=4'b0100; 
    20:Linbit=4'b0110; 
    21:Linbit=4'b1000; 
    22:Linbit=4'b1010; 
    23:Linbit=4'b1101;
    24:Linbit=4'b0100; 
    25:Linbit=4'b0101; 
    26:Linbit=4'b0110; 
    27:Linbit=4'b0111; 
    28:Linbit=4'b1000; 
    29:Linbit=4'b1001; 
    30:Linbit=4'b1011; 
    31:Linbit=4'b1101;
    default:Linbit=4'b0000;
  endcase
end      
  
always@(Table)
begin
  case(Table)  
   0:Huff_saddr=12'b000000000000; 
   1:Huff_saddr=12'b000000000001; 
   2:Huff_saddr=12'b000000001000; 
   3:Huff_saddr=12'b000000011001;
   4:Huff_saddr=12'b000000000000;
   5:Huff_saddr=12'b000000101010; 
   6:Huff_saddr=12'b000001001001;
   7:Huff_saddr=12'b000001101000;
   8:Huff_saddr=12'b000010101111; 
   9:Huff_saddr=12'b000011110110; 
  10:Huff_saddr=12'b000100111101; 
  11:Huff_saddr=12'b000110111100;
  12:Huff_saddr=12'b001000111011; 
  13:Huff_saddr=12'b001010111010; 
  14:Huff_saddr=12'b000000000000; 
  15:Huff_saddr=12'b010010111001;
  16:Huff_saddr=12'b011010111000;
  17:Huff_saddr=12'b011010111000; 
  18:Huff_saddr=12'b011010111000; 
  19:Huff_saddr=12'b011010111000;
  20:Huff_saddr=12'b011010111000; 
  21:Huff_saddr=12'b011010111000; 
  22:Huff_saddr=12'b011010111000; 
  23:Huff_saddr=12'b011010111000; 
  default:Huff_saddr=12'b100010110111; 
 endcase
end  
  
always@(R1start or R2start or Line or Table_select0 or Table_select1 or Table_select2)
begin
 if(Line<R1start)
   Table=Table_select0;
 else if(Line>=R1start&&Line<R2start)
   Table=Table_select1;
 else
   Table=Table_select2;
end  

always@(CSS or Huff_saddr or Dout or Rom_addr or Rom_Q or Sfb_addr)      //look up huffman table
begin
  if(CSS==SELRG)
   Huff_addr={1'b0,Huff_saddr};
  else if(CSS==COUNT1)
   Huff_addr=13'b0101010110110; 
  else if((CSS==FIND1)&&(Rom_Q[15:8]!=0))
   begin
   if (Dout[15])
     Huff_addr=Rom_addr+Rom_Q[7: 0];
   else
     Huff_addr=Rom_addr+Rom_Q[15:8];
        end 
  else if(CSS==REORD)
     Huff_addr=Sfb_addr; 
  else 
     Huff_addr=Rom_addr;
end  


always@(posedge Clk)
begin
 Rom_addr<=#`DLY Huff_addr;
end

//Linbit 
always@(Vwxy or Count1)
begin
 if(Vwxy==2)
   Temp5=Count1[7:4];
 else   
   Temp5=Count1[3:0];
end

always@(CSS or Temp5)
begin 
  if((CSS==BIGS)&&(Temp5==15))
    Value_flag=1'b1;
  else
    Value_flag=1'b0;
end
  
always@(posedge Clk)
begin
  if(CSS==BIGS) 
    begin
         if(Temp5==15)
         begin
    case(Linbit)
     1: Value<=#`DLY {12'b0,Dout[15]};
     2: Value<=#`DLY {11'b0,Dout[15:14]};
     3: Value<=#`DLY {10'b0,Dout[15:13]};
     4: Value<=#`DLY {9'b0, Dout[15:12]};
     5: Value<=#`DLY {8'b0 ,Dout[15:11]};
     6: Value<=#`DLY {7'b0 ,Dout[15:10]};
     7: Value<=#`DLY {6'b0 ,Dout[15:9]};
     8: Value<=#`DLY {5'b0 ,Dout[15:8]};
     9: Value<=#`DLY {4'b0 ,Dout[15:7]};
    10: Value<=#`DLY {3'b0 ,Dout[15:6]};
    11: Value<=#`DLY {2'b0 ,Dout[15:5]};
    12: Value<=#`DLY {1'b0 ,Dout[15:4]};
    13: Value<=#`DLY  Dout[15:3];
    default:Value<=#`DLY 13'b0;
    endcase 
         end         
   else
   Value<=#`DLY 13'b0;
   end
end

always@(posedge Clk)
begin
 if(CSS==REORD)
   Value_reg<=#`DLY Value;
end

//Coun1 
always@(CSS or  count1table_select or Bitleft)
begin
  if((CSS==COUNT1)&&(count1table_select)&&(Bitleft[12:2]!=0))
    Count1_flar=1;
  else
    Count1_flar=0;
end

always@(posedge Clk)
begin
 if((CSS==FIND1)&&(Rom_Q[15:8]==0))
   Count1<=#`DLY Rom_Q[7:0];
 if(Count1_flar)
   Count1<=#`DLY {4'b0,~Dout[15:12]};
end     

//Write huffman data to Ram
always@(Big_flag or Vwxy or Value_reg or Count1)        
begin 
  case(Vwxy)
   0: Temp6={13'b0,Count1[3]}; 
   1: Temp6={13'b0,Count1[2]};   
   2: begin
       if(Big_flag)
         Temp6=Count1[7:4]+Value_reg;
       else 
         Temp6={13'b0,Count1[1]};
       end  
   default:
      begin
       if(Big_flag)
         Temp6=Count1[3:0]+Value_reg;
       else
         Temp6={13'b0,Count1[0]}; 
       end     
  endcase
end

always@(Temp6 or CSS)
begin
 if(CSS==ZERO)
  Temp7=20'b0;
 else
  Temp7={7'b0,Temp6[12:0]};
end
   
always@(Temp7 or Sign)
begin 
  if(Temp7!=0) begin
    if(Sign)
      Data1=~{Temp7}+1;
    else
      Data1=Temp7; end
  else   
    Data1=Temp7;
end

always@(Big_flag or Temp5 or    Temp7)
begin
 if(Big_flag)
   Temp8=Temp5;
 else
   Temp8=Temp7[3:0];
end

always@(posedge Clk)
begin
  if((CSS==REORD)&&(Temp8!=0)&&(Cnt1==0))
    Sign<=Dout[15];
end

always@(CSS or Temp8 or Bitleft or Cnt1)
if((CSS==REORD)&&(Temp8!=0)&&(Bitleft[12:0]!=0)&&(Cnt1==0))
    Sign_flag=1'b1;
else
    Sign_flag=1'b0;

always@(posedge Clk)
begin
  if(NSS==NULL)
    Zero_flag<=#`DLY 1'b0;
  else if((Bitleft[12:2]==0)&&((CSS==COUNT1)||(CSS==SELRG)))
    Zero_flag<=#`DLY 1'b1;
end    

always@(posedge Clk)
begin
  if(NSS==NULL)
    Sfb_flag<=#`DLY 1'b0;
  else if(CSS==STYPE)
    Sfb_flag<=#`DLY 1'b1;
end    

always@(posedge Clk)
begin
  if((CSS==FIND0)&&(Big_flag))
    Vwxy<=#`DLY 2'b10;
  else if(CSS==COUNT1)
    Vwxy<=#`DLY 2'b00;
  else if((CSS==SAVE)&&(!Incr0))
    Vwxy<=#`DLY Vwxy+1;
end  

always@(posedge Clk)
begin
 if(CSS==NULL)
   Line<=#`DLY 10'b0;
 else if((CSS==SAVE||CSS==ZERO)&&(!Incr0))
   Line<=#`DLY Line+1;
end

//receder addr            SAVE

always@(Line or Block)
begin
 if((Block==0)||((Block==3)&&(Line<36)))
   Reorder=1'b0;
 else
   Reorder=1'b1;
end 

always@(posedge Clk)
begin
 if((CSS==NULL)&&(Block==2))
   Sfbindex<=#`DLY 10'b0000001100;
 else if((CSS==NULL)&&(Block==3))
   Sfbindex<=#`DLY 10'b0000110000;
 else if(Cnt1==2)
   Sfbindex<=#`DLY Rom_Q[9:0];
end    

always@(posedge Clk)
begin
 if((CSS==REORD)&&(Line==Sfbindex))
   Cnt1<=#`DLY Cnt1+1;    
  else
   Cnt1<=#`DLY 2'b0;
end 

always@(posedge Clk)
begin
  if(!Rst)
    Cnt3<=#`DLY 4'b0000; 
  else if((CSS==NULL)&&(Block==3))
    Cnt3<=#`DLY 4'b0011; 
  else if((CSS==NULL)&&(Block==2))
    Cnt3<=#`DLY 4'b0000; 
  else if(Cnt1==3)
    Cnt3<=#`DLY Cnt3+1;
end
   
always@(Cnt3 or Sfrq or Cnt1)
begin
  if(Cnt1[0]==0)
    Sfb_addr=2914+{4'b0,Sfrq,Cnt3};
  else
    Sfb_addr=2961+{4'b0,Sfrq,Cnt3};
end   

always@(posedge Clk)
begin
 if(CSS==NULL)
   Win_width<=#`DLY 8'b00000100;
 else if(Cnt1==3)
   Win_width<=#`DLY Rom_Q[7:0];
end


always@(Sfbindex or Win_width)
begin
  A3=Sfbindex-Win_width;
  A2=Sfbindex-{1'b0,Win_width,1'b0};
  A1=Sfbindex-{1'b0,Win_width,1'b0}-Win_width;
end 

always@(Line or A1 or A2 or A3 or Reorder or Channel or Win_width or Cnt2)
begin
  if(!Reorder)
   begin 
    Addr1={2'b01,Channel,Line};
    Temp11=10'b0; 
   end
  else if((A1<=Line)&&(Line<A2)) 
   begin
    Temp11=Line+{1'b0,Cnt2,1'b0};
    Addr1={2'b01,Channel,Temp11};
   end 
  else if((A2<=Line)&&(Line<A3))
   begin
    Temp11=(Line+{1'b0,Cnt2,1'b0})-(Win_width-1);
    Addr1={2'b01,Channel,Temp11};
   end 
  else
   begin
    Temp11=(Line+{1'b0,Cnt2,1'b0})-{(Win_width-1),1'b0};
    Addr1={2'b01,Channel,Temp11};
   end 
end                              
 
always@(posedge Clk)
begin 
 if((CSS==NULL)||(Cnt2==Win_width))
  Cnt2<=#`DLY 8'b0;
 else if((!Incr0)&&((CSS==SAVE)||(CSS==ZERO)))
  Cnt2<=#`DLY Cnt2+1;  
end  

always@(CSS or Bitleft)
begin
 if((CSS==DONE)&&(Bitleft!=0))
  Discard=1'b1;
 else
  Discard=1'b0;
end
                                
//Bit left of Granule or Channel
always@(posedge Clk)
begin
 if(CSS==NULL)
   Bitleft<=#`DLY Part2_3_length;
 else 
   Bitleft<=#`DLY Bitleft-Bit_Cnt; 
end

//read rom
always@(posedge Clk)
begin
 if((CSS==CALRG)||(CSS==SELRG)||(CSS==FIND0)||(CSS==FIND1)||(CSS==REORD)||(CSS==COUNT1))
   Rom_CEN<=#`DLY 1'b0;
 else
   Rom_CEN<=#`DLY 1'b1;
end

always@(posedge Clk)
begin
 if(CSS==CALRG)
   Rom_A<=#`DLY Reg_addr;
 else 
   Rom_A<=#`DLY Huff_addr;
end

//write and read Ram 
always@(posedge Clk)
begin
 if(Incr0)
  Ram_CEN<=#`DLY 1'b0;
 else if(CSS==WRITE)
  Ram_CEN<=#`DLY Scale_CEN;
 else if((CSS==SAVE)||(CSS==ZERO))
  Ram_CEN<=#`DLY 1'b0;
 else
  Ram_CEN<=#`DLY 1'b1;
end

always@(posedge Clk)
begin
 if(Incr0)
  Ram_WEN<=#`DLY 1'b1;
 else if(CSS==WRITE)
  Ram_WEN<=#`DLY Scale_WEN;
 else if((CSS==SAVE)||((CSS==ZERO)&&(Line!=576)))
  Ram_WEN<=#`DLY 1'b0;
 else
  Ram_WEN<=#`DLY 1'b1;
end

always@(posedge Clk)
begin
 if(Incr0)
  Ram_A<=#`DLY Addr0;
 else if(CSS==WRITE)
  Ram_A<=#`DLY Scale_A; 
 else 
  Ram_A<=#`DLY Addr1;
end

always@(posedge Clk)
begin
 if(CSS==WRITE)
  Ram_D<=#`DLY Scale_D; 
 else 
  Ram_D<=#`DLY Data1;
end  
  
endmodule
