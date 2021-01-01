//***********************************************************
//data        : 2007-07-11 11:30:00 
//version     : 1.0
//
//module name : Stereo
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-07-27  11:30:00   
//***********************************************************
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`define DLY      0       
module    Stereo(Clk,
                 Rst,
                 Enable,   
                 Done,  
                 Mulin1_ste,
                 Mulin2_ste,
                 Mulout,
                 Ram_WEN,
                 Ram_CEN,
                 Ram_A,
                 Ram_D,  
                 Ram_Q,
                                 Mode,
                                 Mode_ext);
                 
input         Clk;
input         Rst;
input         Enable;
input[19:0]   Ram_Q;  
input signed[39:0] Mulout;
input[1 :0]   Mode;  
input[1 :0]   Mode_ext;

output        Done;
output        Ram_CEN;
output        Ram_WEN;
output[12:0]  Ram_A;
output[19:0]  Ram_D;


output signed[19:0]  Mulin1_ste;
output signed[19:0]  Mulin2_ste;

reg           Done;
reg           Ram_CEN;
reg           Ram_WEN;
reg[12:0]     Ram_A;
reg[19:0]     Ram_D;


reg signed[19:0] Mulin2_ste;

//register
reg[1 :0]  CS,NS;

parameter
         IDLE=2'b00,
         MSTE=2'b01,
         DONE=2'b10;
         
         
reg[3 :0] Ms_Cnt;
reg[9 :0] Line_Cnt;
reg signed[20:0] Data0_reg;                
reg signed[20:0] Data1_reg;           
         
//variable
reg       Ramwen;
reg       Ramcen;
reg[12:0] Ramaddr;


//******************************MAIN***************************************
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY IDLE;
   else
    CS<=#`DLY NS;
end

always@(CS or Line_Cnt or Enable or Mode or Mode_ext)
begin
  case(CS)
    IDLE:if(Enable)
         begin
         if((Mode==1)&&(Mode_ext==2))
          NS=MSTE;
         else
          NS=DONE;
         end
       else
         NS=IDLE;
    
    MSTE:if(Line_Cnt==576)
          NS=DONE;
         else
          NS=MSTE;         
    
    DONE:NS=IDLE;   
    
    default:NS=IDLE;
  endcase
end

//calculate MS Stereo
always@(posedge Clk)
begin
 if(NS==IDLE)
   Line_Cnt<=#`DLY 10'b0;
 else if(Ms_Cnt[3]==1)
   Line_Cnt<=#`DLY Line_Cnt+1;
end

always@(posedge Clk)
begin
  if(NS==IDLE||Ms_Cnt[3]==1)
    Ms_Cnt<=#`DLY 4'b0;
  else if(CS==MSTE)
    Ms_Cnt<=#`DLY Ms_Cnt+1;
end

always@(posedge Clk)
begin
  if(Ms_Cnt==2)
    Data0_reg<=#`DLY {1'b0,Ram_Q};
  else if(Ms_Cnt==5||Ms_Cnt==6)
    Data0_reg<=#`DLY Mulout[38:18];
end 
 
always@(posedge Clk)
begin
  if(Ms_Cnt==3)
    Data1_reg<=#`DLY {1'b0,Ram_Q};
end    

always@(posedge Clk)
begin
  if((Line_Cnt==576)&&(CS==MSTE)||(CS==DONE))
    Done<=#`DLY 1'b1;
  else
    Done<=#`DLY 1'b0;
end 
 
//Multipiler 

assign   Mulin1_ste= 20'd370728;
 

always@(Data0_reg or Data1_reg or Ms_Cnt)
begin
  case(Ms_Cnt)
    4:Mulin2_ste= Data0_reg[19:0]+Data1_reg[19:0];
    5:Mulin2_ste= Data0_reg[19:0]-Data1_reg[19:0];
    default: Mulin2_ste= 20'b0;
  endcase
end

//Ram read and write
always@(Ms_Cnt or Line_Cnt)
begin
  case(Ms_Cnt)
    0:begin
      Ramwen=1'b1;
      Ramcen=1'b0;
      Ramaddr={3'b010,Line_Cnt};
      end
      
    1:begin
      Ramwen=1'b1;
      Ramcen=1'b0;
      Ramaddr={3'b011,Line_Cnt};
      end
    
    6:begin
      Ramwen=1'b0;
      Ramcen=1'b0;
      Ramaddr={3'b010,Line_Cnt};
      end
    
    7:begin
      Ramwen=1'b0;
      Ramcen=1'b0;
      Ramaddr={3'b011,Line_Cnt};
      end
   default: 
      begin
      Ramwen=1'b1;
      Ramcen=1'b1;
      Ramaddr=13'b0;
      end
  endcase
end 

always@(posedge Clk)
begin
  Ram_WEN<=#`DLY Ramwen;
  Ram_CEN<=#`DLY Ramcen;
  Ram_A  <=#`DLY Ramaddr;
end     

always@(posedge Clk)
begin
  if(Ms_Cnt==6||Ms_Cnt==7)
    Ram_D<=#`DLY Data0_reg[20:1]+Data0_reg[0];
  else 
    Ram_D<=#`DLY 20'b0;
end

endmodule  
 
 

 
 







