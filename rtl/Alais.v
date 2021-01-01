//***********************************************************
//
//data        : 2007-07-11 11:30:00 
//version     : 1.0
//
//module name : alais
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-07-25  11:30:00   
//***********************************************************
`define DLY      0       
module     Alais(Clk,
                 Rst,
                 Enable,   
                 Done,  
                 Mulin1_ala,
                 Mulin2_ala,
                 Mulout, 
                 Channel,
                 Ram_WEN,
                 Ram_CEN,
                 Ram_A,
                 Ram_D,  
                 Ram_Q,
                                 Blocksplit_flag,
                 Block_type,
                 Switch_point);
                 
input         Clk;
input         Rst;
input         Enable;
input         Channel;
input[19:0]   Ram_Q;
input         Blocksplit_flag;
input[1 :0]   Block_type;
input         Switch_point;  
input[39:0]   Mulout;

output        Done;
output        Ram_CEN;
output        Ram_WEN;
output[12:0]  Ram_A;
output[19:0]  Ram_D;

output[19:0]  Mulin1_ala;
output[19:0]  Mulin2_ala;

reg           Done;
reg           Ram_CEN;
reg           Ram_WEN;
reg[12:0]     Ram_A;
reg[19:0]     Ram_D;

reg signed[19:0] Mulin1_ala;
reg signed[19:0] Mulin2_ala;    

//register
reg[1 :0]     CS,NS;
parameter     
              IDLE=2'b00,
              CALU=2'b01, 
              WAIT=2'b10,
              DONE=2'b11;
                                 

reg[4 :0]    Sfb_Cnt;
reg[2 :0]    Bfly_Cnt;
reg[2 :0]    Calu_Cnt;
reg[9 :0]    Addr_inl;
reg[19:0]    Data0_reg;
reg[19:0]    Data1_reg;
  
reg signed[20:0]Data2_reg;
reg signed[20:0]Data3_reg;            



//variable
reg[1 :0]  Block;
reg[19:0]  Coff_cs;
reg[19:0]  Coff_ca;
reg signed[19:0]Temp;
reg       Ramwen;
reg       Ramcen;
reg[12:0] Ramaddr;
reg[9 :0] Temp1;

//*****************************MAIN************************************//
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY IDLE;
  else
    CS<=#`DLY NS; 
end

always@(CS or Enable or Block or Bfly_Cnt or Calu_Cnt or Sfb_Cnt)
begin
  case(CS)
    0:if(Enable==1)
        begin
        if(Block==2)
        NS=WAIT;
        else
        NS=CALU;
        end
      else
        NS=IDLE;
    
    1: if((Calu_Cnt==7)&&(Bfly_Cnt==7)&&((Block==3)||((Block==0)&&(Sfb_Cnt==30))))
        NS=WAIT;
       else
        NS=CALU;
    
    2:NS=DONE;
    
    3:NS=IDLE;
  endcase
end

always@(posedge Clk)
begin 
 if(CS==WAIT)
   Done<=#`DLY 1'b1;
  else
   Done<=#`DLY 1'b0;
end              

//Block TYPE
always@(Blocksplit_flag or Block_type or Switch_point)
begin
  if((Blocksplit_flag==1)&&(Block_type==2)) 
      begin
      if (Switch_point==1) 
           Block=2'b11;                         //mix   sfb
          else                                             
       Block=2'b10;                                         //short sfb
      end              
  else 
         Block=2'b00;                           //long  sfb
end  
        
//alais table
always @(Bfly_Cnt)
begin
  case(Bfly_Cnt)
   0:Coff_cs=20'd449573;
   1:Coff_cs=20'd462287;
   2:Coff_cs=20'd497879;
   3:Coff_cs=20'd515540;
   4:Coff_cs=20'd521938;
   5:Coff_cs=20'd523848;
   6:Coff_cs=20'd524235;
   default Coff_cs=20'd524283;
  endcase
end

always @(Bfly_Cnt)
begin
  case(Bfly_Cnt)
   0:Coff_ca=20'd778832;
   1:Coff_ca=20'd801253;
   2:Coff_ca=20'd884276;
   3:Coff_ca=20'd953201;
   4:Coff_ca=20'd998992;
   5:Coff_ca=20'd1027098;
   6:Coff_ca=20'd1041132;
   default Coff_ca=20'd1046636;
  endcase
end


//Controll Signal
always@(posedge Clk)
begin
  if(CS==IDLE)
    Calu_Cnt<=#`DLY 3'b0;
  else if(CS==CALU)
    Calu_Cnt<=#`DLY Calu_Cnt+1;
end

always@(posedge Clk)
begin
  if(CS==IDLE)
    Bfly_Cnt<=#`DLY 3'b0;
  else if(Calu_Cnt==7)
    Bfly_Cnt<=#`DLY Bfly_Cnt+1;
end
 
always@(posedge Clk)
begin
  if(CS==IDLE)
    Sfb_Cnt<=#`DLY 5'b0;
  else if((Calu_Cnt==7)&&(Bfly_Cnt==7))
    Sfb_Cnt<=#`DLY Sfb_Cnt+1;
end 
 
//calculate 
always@(posedge Clk)
begin
  if(Calu_Cnt==2)
    Data0_reg<=#`DLY Ram_Q;
end  

always@(posedge Clk)
begin
  if(Calu_Cnt==3)
    Data1_reg<=#`DLY Ram_Q;
end

always@(Calu_Cnt or Ram_Q or Data0_reg or Data1_reg)
begin
 case(Calu_Cnt)
   2: Mulin1_ala= Ram_Q;
   3: Mulin1_ala= Ram_Q;
   4: Mulin1_ala= Data0_reg;
   5: Mulin1_ala= Data1_reg;
  default:Mulin1_ala= 20'b0;
 endcase    
end
 
always@(Calu_Cnt or Coff_cs or  Coff_ca)
begin
 case(Calu_Cnt)
   2: Mulin2_ala= Coff_cs;
   3: Mulin2_ala= Coff_ca;
   4: Mulin2_ala= Coff_ca;
   5: Mulin2_ala= Coff_cs;
  default:Mulin2_ala= 20'b0;
 endcase    
end 
 
always@(posedge Clk)
begin
  if(Calu_Cnt==3||Calu_Cnt==5)
    Data2_reg<=#`DLY Mulout[38:18];
end  
 
always@(posedge Clk)
begin
  if(Calu_Cnt==4||Calu_Cnt==6)
    Data3_reg<=#`DLY Mulout[38:18];
end  


always@(Calu_Cnt or Data2_reg or Data3_reg)
begin
  if(Calu_Cnt==5)
   Temp={Data2_reg[20:1]+Data2_reg[0]}-{Data3_reg[20:1]+Data3_reg[0]};   
  else if(Calu_Cnt==7)
   Temp={Data2_reg[20:1]+Data2_reg[0]}+{Data3_reg[20:1]+Data3_reg[0]}; 
  else
   Temp=20'b0;
end

//Ram read and write
always@(posedge Clk)
begin
  if(CS==IDLE)
    Addr_inl<=#`DLY 10'd17;
  else if((Bfly_Cnt==7)&&(Calu_Cnt==7))
    Addr_inl<=#`DLY Addr_inl+18;
end

always@(Calu_Cnt)
begin
  case(Calu_Cnt)
   0: begin
      Ramwen=1'b1;
      Ramcen=1'b0;
      end
   1: begin
      Ramwen=1'b1;
      Ramcen=1'b0;
      end
   5: begin
      Ramwen=1'b0;
      Ramcen=1'b0;
      end
   7:begin
      Ramwen=1'b0;
      Ramcen=1'b0;
      end
  default:
      begin
      Ramwen=1'b1;
      Ramcen=1'b1;
      end
  endcase
end

always@(Addr_inl or Bfly_Cnt or Calu_Cnt or Channel)
begin
   Temp1=Addr_inl+Bfly_Cnt+1;
   case(Calu_Cnt)
   0: Ramaddr={2'b01,Channel,(Addr_inl-Bfly_Cnt)};
   1: Ramaddr={2'b01,Channel,Temp1};
   5: Ramaddr={2'b01,Channel,(Addr_inl-Bfly_Cnt)};
   7: Ramaddr={2'b01,Channel,Temp1};
  default:Ramaddr=13'b0;
  endcase
end     

always@(posedge Clk)
begin
  Ram_WEN<=#`DLY Ramwen;
  Ram_CEN<=#`DLY Ramcen;
  Ram_A  <=#`DLY Ramaddr;
  Ram_D  <=#`DLY Temp;
end

endmodule         
         
    
   
      
   
  


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
