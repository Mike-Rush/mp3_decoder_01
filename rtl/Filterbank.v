//***********************************************************
//
//
//data        : 2007-08-6   08:45:00  
//data        : 2008-01-23 
 
//version     : 1.0
//
//module name : Filterbank
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-08-6  08:45:00 

                              
//***********************************************************
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`define DLY      0       
module Filterbank(Clk,
                  Rst,
                  Enable,   
                  Done,  
                  Mulin1_fil,
                  Mulin2_fil,
                  Mulout, 
                  Channel,
                  Ram_WEN,
                  Ram_CEN,
                  Ram_A,
                  Ram_D,  
                  Ram_Q, 
                  Rom_A,
                  Rom_Q,
                  Rom_CEN);
                 
input         Clk;
input         Rst;
input         Enable;
input         Channel;
input[19:0]   Ram_Q;
input[39:0]   Mulout;
input[19:0]   Rom_Q;


output        Done;
output        Ram_CEN;
output        Ram_WEN; 
output        Rom_CEN;
output[12:0]  Rom_A;
output[12:0]  Ram_A;
output[19:0]  Ram_D;

output[19:0]  Mulin1_fil;
output[19:0]  Mulin2_fil;

reg           Done;
reg           Ram_CEN;
reg           Ram_WEN;   
reg           Rom_CEN;
reg[12:0]     Rom_A;
reg[12:0]     Ram_A;
reg[19:0]     Ram_D;

reg signed[19:0] Mulin1_fil;
reg signed[19:0] Mulin2_fil;   

//inter register
reg[3 :0] Fifo_point0;
reg[3 :0] Fifo_point1;
reg[9 :0] Clear_Cnt0;
reg       Clear_Cnt1;  
reg       Clear_flag;        

reg[2 :0] CS,NS;
reg[4 :0] Sfb_cnt;
reg[4 :0] Line_cnt;
reg[5 :0] Mdct_cnt;          
reg       Mdct_en0;
reg       Mdct_en1;

reg signed[19:0] Data0_reg;
reg signed[19:0] Data1_reg;
reg signed[19:0] Accum_reg;
reg signed[39:0] Mulout_reg;  
reg signed[45:0] Adder_reg;

parameter 
          IDLE =3'b000,
          CLEAR=3'b001,
          MDCT =3'b010,
          ACCUM=3'b011, 
          SELST=3'b100,
          READY=3'b101;
          
          
//inter variable

reg        RamWen_c;
reg[12:0]  RamAddr_c;


reg        RamCen_m;
reg        RamWen_m;
reg[12:0]  RamAddr_m;
reg[19:0]  RamD_m; 
reg        RomCen_m;
reg[12:0]  RomAddr_m;  

reg        RamCen_a;
reg        RamWen_a;
reg[12:0]  RamAddr_a;
reg        RomCen_a;
reg[12:0]  RomAddr_a;
    
reg        Mdct_en;    

reg[5 :0]  Addr1;
reg[5 :0]  Addr2;  
reg[4 :0]  Addr3;

reg[5 :0]  Temp2;
reg[5 :0]  Temp3;
reg[5 :0]  Temp4;
reg[4 :0]  Temp5;  
reg[9 :0]  Temp6;   
reg[9 :0]  Temp7;
reg[3 :0]  Temp8; 
reg[9 :0]  Temp10; 
reg[15:0]  Temp12;
reg[9 :0]  Temp11;

reg signed[19:0]Temp0; 
wire       Poverflow;
wire       Noverflow;

//****************************MIAN**************************************// 
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY IDLE;
  else
    CS<=#`DLY NS;
end

always@(CS or Clear_Cnt0 or Enable or Clear_flag or Line_cnt or Mdct_cnt or Sfb_cnt or Clear_Cnt1)
begin
  case(CS)
    IDLE: if(Enable)
            begin
            if(Clear_flag)
             NS=MDCT;
            else
             NS=CLEAR;
            end
          else
            NS=IDLE;
            
   CLEAR:if(Clear_Cnt0==1023&&Clear_Cnt1==1)
          NS=MDCT;
         else
          NS=CLEAR;
          
          
   MDCT :if(Line_cnt==31&&Mdct_cnt==39)
           NS=ACCUM;
         else
           NS=MDCT;
                        
   ACCUM:if(Line_cnt==31&&Mdct_cnt==21)
           NS=SELST;
         else
           NS=ACCUM;
   
   
   SELST:if(Sfb_cnt==17)
           NS=READY;
         else
           NS=MDCT;   
     
   READY:  NS=IDLE;
   
   default: NS=IDLE;
 endcase
end

always@(posedge Clk)
begin
  if(Sfb_cnt==17&&CS==SELST)
    Done<=#`DLY 1'b1;
  else
    Done<=#`DLY 1'b0;
end
//Clear MDCT FIFO
always@(posedge Clk)
begin
  if(!Rst)
    Clear_flag<=#`DLY 1'b0;
  else if(Clear_Cnt0==1023)
    Clear_flag<=#`DLY 1'b1;
end

always@(posedge Clk)
begin
  if(CS==CLEAR)
    Clear_Cnt1<=#`DLY ~Clear_Cnt1;  
  else
    Clear_Cnt1<=#`DLY 1'b0;
end

always@(posedge Clk)
begin
  if(!Rst)
    Clear_Cnt0<=#`DLY 10'b0;
  else if(Clear_Cnt1)
    Clear_Cnt0<=#`DLY Clear_Cnt0+1;
end
             
always@(Clear_Cnt0 or Clear_Cnt1 )
begin 
   RamWen_c=1'b0;
   RamAddr_c={2'b11,Clear_Cnt1,Clear_Cnt0};
end

//32-64 Point MDCt
always@(posedge Clk)
begin
  if(CS==IDLE||Mdct_cnt==39||((CS==ACCUM)&&(Mdct_cnt==21)))
    Mdct_cnt<=#`DLY 6'b0;
  else if(CS==MDCT||CS==ACCUM)
    Mdct_cnt<=#`DLY Mdct_cnt+1;
end

always@(posedge Clk)
begin
 if(CS==IDLE)
   Line_cnt<=#`DLY 5'b0;
 else if(Mdct_cnt==39||((CS==ACCUM)&&(Mdct_cnt==21)))
   Line_cnt<=#`DLY  Line_cnt+1;
end    

always@(posedge Clk)
begin
  if(CS==IDLE)
    Sfb_cnt<=#`DLY 5'b0;
  else if(CS==SELST)
    Sfb_cnt<=#`DLY Sfb_cnt+1;
end
         
always@(posedge Clk)
begin
  if(!Rst)
    begin
    Fifo_point0<=#`DLY 4'b0;
    Fifo_point1<=#`DLY 4'b0;
    end
  else if(CS==SELST)
    begin
    if(Channel)       
     Fifo_point1<=#`DLY Fifo_point1-1;
    else
     Fifo_point0<=#`DLY Fifo_point0-1;
    end
end
     
always@(posedge Clk)
begin  
 if(CS==MDCT)
   begin
     Data0_reg<=#`DLY Ram_Q;
     Data1_reg<=#`DLY Data0_reg;
   end
end

always@(Rom_Q)
begin
  Mulin1_fil=Rom_Q;
end

always@(Data0_reg or Data1_reg or Line_cnt)
begin
  if(!Line_cnt[0])
   Temp0=Data1_reg+Data0_reg;
  else
   Temp0=Data0_reg-Data1_reg;
end

always@(CS or Ram_Q or Temp0 or Mdct_en)
begin
   if(CS==ACCUM) 
     Mulin2_fil=Ram_Q;
   else if(Mdct_en)  
     Mulin2_fil=Temp0; 
        else
         Mulin2_fil=20'b0;   
end
    
always@(Mdct_cnt)
begin
  if(Mdct_cnt[5:1]!=0&&Mdct_cnt[5:1]!=1&&Mdct_cnt[5:1]!=18
    &&Mdct_cnt[5:1]!=19&&(!Mdct_cnt[0]))
    Mdct_en=1'b1;
  else
    Mdct_en=1'b0;
end
   
always@(posedge Clk)
begin
  Mdct_en1<=#`DLY Mdct_en0;
  Mdct_en0<=#`DLY Mdct_en;
end

always@(posedge Clk)
begin
  if(Mdct_en0&&(CS==MDCT))
   Mulout_reg[20:0]<=#`DLY Mulout[38:18];
  else
   Mulout_reg<=#`DLY Mulout;
end

always@(posedge Clk)
begin
  if(Mdct_cnt==0)
    Accum_reg<=#`DLY 20'b0;
  else if(Mdct_en1)
    Accum_reg<=#`DLY Accum_reg+Mulout_reg[0]+Mulout_reg[20:1];
end

always@(Mdct_cnt)
begin
  if(Mdct_cnt==0||Mdct_cnt[0]||(Mdct_cnt[5]&&(Mdct_cnt[4:0]!=0)))
    RomCen_m=1'b1;
  else 
    RomCen_m=1'b0;
end

always@(Mdct_cnt or Line_cnt)
begin 
  Temp8=Mdct_cnt[4:1]-1;
  RomAddr_m={4'b1010,Line_cnt,Temp8};
end


always@(CS or Mdct_cnt)
begin
 if((CS==MDCT&&(!Mdct_cnt[5]))||(Mdct_cnt==37||Mdct_cnt==38))
   RamCen_m=1'b0;
 else
   RamCen_m=1'b1;
end

always@(Mdct_cnt)
begin
  if(Mdct_cnt==37||Mdct_cnt==38)
    RamWen_m=1'b0;
  else
    RamWen_m=1'b1;
end

always@(Line_cnt)
begin 
  Temp2=32-Line_cnt;
  Temp3=16+Line_cnt;
  Temp4=80-Line_cnt;
  if(Line_cnt==16)
    begin
    Addr1=6'b010000;  
    Addr2=6'b110000;
    end
  else if(!Line_cnt[4])  
    begin
    Addr1={1'b0,Line_cnt};  
    Addr2=Temp2;
    end
  else
    begin
    Addr1=Temp3;  
    Addr2=Temp4;
    end
end
   
always@(Channel or Addr1 or Addr2 or Mdct_cnt or Fifo_point0 or Fifo_point1 or Sfb_cnt )
begin 
  Temp5=~{1'b0,Mdct_cnt[5:1]};
  Temp6={2'b0,Mdct_cnt[5:1],4'b0000}+{Mdct_cnt[5:1],1'b0}+Sfb_cnt;  
  Temp7={Temp5,4'b0}+{Temp5,1'b0}+Sfb_cnt;
  case(Mdct_cnt)
    37:begin
       if(Channel)
        RamAddr_m={3'b111,Fifo_point1,Addr1};
       else
        RamAddr_m={3'b110,Fifo_point0,Addr1}; 
       end
     
    38:begin
       if(Channel)
        RamAddr_m={3'b111,Fifo_point1,Addr2};
       else
        RamAddr_m={3'b110,Fifo_point0,Addr2}; 
       end 
       
    default:   
       begin
        if(Mdct_cnt[0])
        RamAddr_m={2'b01,Channel,Temp6};
       else
        RamAddr_m={2'b01,Channel,Temp7}; 
       end
  endcase
end                              
       
always@( Line_cnt or Mdct_cnt or Accum_reg )
begin
  if(Mdct_cnt==37)
    begin
    if(Line_cnt==16)
      RamD_m=20'b0;
     else
      RamD_m=Accum_reg;
    end
  else
    begin 
    if(!Line_cnt[4])      
      RamD_m=~Accum_reg+1;
    else
      RamD_m=Accum_reg;
    end
end

//Add 512 Wind and output    
always@(Mdct_cnt )
begin
  if(Mdct_cnt[4]==0)
    RomCen_a=1'b0;
  else
    RomCen_a=1'b1;
end

always@(Mdct_cnt or Line_cnt)
begin
 RomAddr_a={4'b1011,Mdct_cnt[3:0],Line_cnt};
end

always@( Mdct_cnt )
begin
  if(Mdct_cnt[4]==0||Mdct_cnt==20)
    RamCen_a=1'b0;
  else
    RamCen_a=1'b1;
end   

always@(Mdct_cnt )
begin
  if(Mdct_cnt==20)
    RamWen_a=1'b0;
  else
    RamWen_a=1'b1;
end

always@(Mdct_cnt)
begin
  case(Mdct_cnt)
   0 :Addr3=5'b00000;
   1 :Addr3=5'b00011;
   2 :Addr3=5'b00100;
   3 :Addr3=5'b00111;
   4 :Addr3=5'b01000;
   5 :Addr3=5'b01011;
   6 :Addr3=5'b01100;
   7 :Addr3=5'b01111;
   8 :Addr3=5'b10000;
   9 :Addr3=5'b10011;
   10:Addr3=5'b10100;
   11:Addr3=5'b10111;
   12:Addr3=5'b11000;
   13:Addr3=5'b11011;
   14:Addr3=5'b11100;
   default: Addr3=5'b11111;
  endcase
end

always@(Channel or Fifo_point0 or Fifo_point1 or Line_cnt or Mdct_cnt or Sfb_cnt or Addr3)
begin
  begin 
    Temp11={2'b0,Line_cnt[4:0],4'b0000}+{Line_cnt[4:0],1'b0}+Sfb_cnt;
  if(Channel)
    Temp10=Line_cnt+{Addr3,5'b0}+{Fifo_point1,6'b0};
  else
    Temp10=Line_cnt+{Addr3,5'b0}+{Fifo_point0,6'b0};
  end 
  if(Mdct_cnt==20)
    RamAddr_a={2'b01, Channel,Temp11};  
  else 
    RamAddr_a={2'b11, Channel,Temp10};
end  
  
always@(posedge Clk)
begin
  if(Mdct_cnt==0)
    Adder_reg<=#`DLY 46'b0;
  else if((CS==ACCUM)&&(Mdct_cnt!=0&&Mdct_cnt!=1&&Mdct_cnt!=2&&Mdct_cnt!=3&&Mdct_cnt!=20)) 
    Adder_reg<=#`DLY Adder_reg+{Mulout_reg[39],Mulout_reg[39],Mulout_reg[39],Mulout_reg[39],Mulout_reg[39],Mulout_reg[39],Mulout_reg};
end  

assign  Poverflow=|Adder_reg[44:37];
assign  Noverflow=&Adder_reg[44:37];    

always@(Adder_reg or Poverflow or Noverflow )
 begin
 if(!Adder_reg[45]&&Poverflow)
   Temp12=16'b0111_1111_1111_1111;
 else if (Adder_reg[45]&&!Noverflow)
   Temp12=16'b1000_0000_0000_0000;
 else
   Temp12=Adder_reg[37:22];
end

//Rom And Ram 
always@(posedge Clk)
begin
 if(CS==MDCT)
  begin
  Rom_CEN<=#`DLY RomCen_m;
  Rom_A<=#`DLY   RomAddr_m;
  end
 else
  begin
  Rom_CEN<=#`DLY RomCen_a;
  Rom_A<=#`DLY   RomAddr_a;
  end
end

always@(posedge Clk)
begin
 if(CS==MDCT)
  begin
  Ram_CEN<=#`DLY RamCen_m;
  Ram_A<=#`DLY   RamAddr_m;  
  Ram_D<=#`DLY   RamD_m;
  Ram_WEN<=#`DLY RamWen_m;
  end
 else if(CS==CLEAR)
  begin
  Ram_CEN<=#`DLY 1'b0;
  Ram_A<=#`DLY   RamAddr_c;  
  Ram_D<=#`DLY   20'b0;
  Ram_WEN<=#`DLY 1'b0;
  end
 else
  begin
  Ram_CEN<=#`DLY RamCen_a;
  Ram_A<=#`DLY   RamAddr_a;  
  Ram_D<=#`DLY   Temp12;
  Ram_WEN<=#`DLY RamWen_a;
  end
end
  
  
endmodule  
                              
