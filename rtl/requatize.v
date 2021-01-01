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
//             2007-07-19  11:30:00   
//***********************************************************
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`define DLY      0       
module requatize(Clk,
                 Rst,
                 Enable,   
                 Done,  
                 Mulin1,
                 Mulin2,
                 Mulout,
                 Channel,
                 Rom_CEN,
                 Rom_A,
                 Rom_Q,
                 Ram_WEN,
                 Ram_CEN,
                 Ram_A,
                 Ram_D,  
                 Ram_Q,
                                 Sfrq,
                                 Blocksplit_flag,
                 Block_type,
                 Switch_point,
                                 Global_gain,
                 Sub0_gain,
                                 Sub1_gain,
                                 Sub2_gain,
                 Preflag,
                 Scalefac_scale);
                 
input         Clk;
input         Rst;
input         Enable;
input[19:0]   Rom_Q;
input         Channel;
input[19:0]   Ram_Q;
input         Blocksplit_flag;
input[1 :0]   Block_type;
input         Switch_point;
input[7 :0]       Global_gain;
input[2 :0]   Sub0_gain;
input[2 :0]       Sub1_gain;
input[2 :0]       Sub2_gain;
input         Preflag;
input         Scalefac_scale;   
input[39:0]   Mulout;
input[1 :0]   Sfrq;

output        Done;
output        Ram_CEN;
output        Ram_WEN;
output[12:0]  Ram_A;
output[19:0]  Ram_D;

output[12:0]  Rom_A;
output        Rom_CEN;
output[19:0]  Mulin1;
output[19:0]  Mulin2;

reg           Done;
reg           Ram_CEN;
reg           Ram_WEN;
reg[12:0]     Ram_A;
reg[19:0]     Ram_D;

reg[12:0]     Rom_A;
reg           Rom_CEN;
reg[19:0]     Mulin1;
reg[19:0]     Mulin2;

//inter variable  and register

parameter
          IDLE   =4'b0000,
          SAMPLE =4'b0001,
          SFBSEL =4'b0010,
          SCALE  =4'b0011,
          MULTI  =4'b0100,
          MULTO  =4'b0101,
          WRITE  =4'b0110,
          READY  =4'b0111,
                         WAIT   =4'b1000;

//Register          
reg [3 :0] CS,NS;
reg [19:0] Sample_reg; 
reg [15:0] Sample_reg_Temp0;
reg [9 :0] Sample_reg_Temp1;
reg [2 :0] Sample_Cnt;
reg [9 :0] Line_reg;
reg [3 :0] Scale_reg;   
reg [2 :0] Scale_Cnt;
reg [9 :0] Index_reg;   
reg [4 :0] Sfb_reg;       
reg [2 :0] Sfb_Cnt;          
reg [1 :0] Win_reg;
reg [20:0] Mulout_reg; 
reg [3 :0] Is_Exp ;   
reg        Sign_reg;
reg        Is_Big;
//Variable
reg[1 :0]  Block;          
reg[12:0]  Ram_addr;
reg        Ram_we;
reg        Ram_ce;
reg[12:0]  Rom_addr;
reg        Rom_ce; 
reg        Long;
reg [2 :0] Sub_gain;
reg [1 :0] Pretab;
reg [4 :0] Temp2;
reg [19:0] Gain_Correct;   
reg [3 :0] Is_Exp_Temp;   
reg [7 :0] Temp3;
reg [19:0] Temp4;
reg [19:0] Temp5;

reg signed[8 :0] Temp0; 
reg signed[8 :0] Temp1;  
reg signed[19:0] Temp6;
reg signed[5 :0] Exp_A;
reg signed[6 :0] Ind_A;    
reg signed[2 :0] Ind_B;
reg signed[5 :0] Exp_B;
reg signed[5 :0] Inx;
reg signed[7 :0] Exp;     
//**********************************MAIN**********************************//
always@(posedge Clk)
begin
 if(!Rst)
   CS<=#`DLY IDLE;
 else
   CS<=#`DLY NS;
end

always@(CS or Line_reg or Sample_Cnt or Index_reg or Sfb_Cnt or Scale_Cnt or Enable)
begin
  case(CS) 
  
   IDLE:   if(Enable)
             NS=SAMPLE;
           else 
             NS=IDLE; 
   SAMPLE: if(Sample_Cnt==5)
             NS=SFBSEL;
           else
             NS=SAMPLE;              
   SFBSEL: if((Line_reg!=Index_reg)||((Sfb_Cnt==2)&&(Line_reg==36)))
             NS=SCALE;
           else
             NS=SFBSEL;    
   SCALE:  if(Scale_Cnt==2)
             NS=MULTI;
           else
           NS=SCALE;  
   MULTI:  NS=MULTO;
   MULTO:  NS=WAIT ;
        WAIT :  NS=WRITE;  
   WRITE:  if(Line_reg==575)
                  NS=READY;
                          else 
                            NS=SAMPLE;
   READY:  NS=IDLE; 
   default:NS=IDLE;
  endcase            
end    

always@(posedge Clk)
begin
 if((CS==MULTO)&&(Line_reg==575))
   Done<=#`DLY 1'b1;
 else 
   Done<=#`DLY 1'b0;
end


//save and cale |is|^(4/3)
always@(posedge Clk)
begin
 if(!Rst||Sample_Cnt==5)
   Sample_Cnt<=#`DLY 3'b0;
 else if(CS==SAMPLE)
   Sample_Cnt<=#`DLY Sample_Cnt+1;
end

always@(posedge Clk)
begin
 if(Sample_Cnt==2)
   Sample_reg<=#`DLY Ram_Q;
 else if(Sample_Cnt==5)
   Sample_reg<=#`DLY Rom_Q; 
end 

always@(posedge Clk)
begin
 if(Sample_Cnt==2)
   Sign_reg<=#`DLY Ram_Q[15];
end

always@(Sample_reg)
begin
 if(Sample_reg[15])
  Sample_reg_Temp0=~(Sample_reg[15:0])+1;
 else
  Sample_reg_Temp0=Sample_reg[15:0];
end

always@(Sample_reg_Temp0)
begin
 if(Sample_reg_Temp0[15:10]!=0)
   Sample_reg_Temp1=Sample_reg_Temp0[12:3];
 else
   Sample_reg_Temp1=Sample_reg_Temp0[9 :0];
end  
           
always@(posedge Clk)           
begin
  if(Sample_Cnt==0)
    Is_Big<=#`DLY 1'b0;
  else if((Sample_Cnt==3)&&(Sample_reg_Temp0[15:10]!=0))
    Is_Big<=#`DLY 1'b1;
end           
           
always@(Sample_reg_Temp1)
begin
 if(Sample_reg_Temp1==0||Sample_reg_Temp1==1)
   Is_Exp_Temp=4'b0;
 else if(Sample_reg_Temp1==2)
   Is_Exp_Temp=4'b0010;
 else if(Sample_reg_Temp1==3||Sample_reg_Temp1==4)
   Is_Exp_Temp=4'b0011;
 else if((Sample_reg_Temp1>4)&&(Sample_reg_Temp1<9))
   Is_Exp_Temp=4'b0100;
 else if((Sample_reg_Temp1>8)&&(Sample_reg_Temp1<14))
   Is_Exp_Temp=4'b0101;                 
 else if((Sample_reg_Temp1>13)&&(Sample_reg_Temp1<23))
   Is_Exp_Temp=4'b0110;          
 else if((Sample_reg_Temp1>22)&&(Sample_reg_Temp1<39))
   Is_Exp_Temp=4'b0111;          
 else if((Sample_reg_Temp1>38)&&(Sample_reg_Temp1<65))
   Is_Exp_Temp=4'b1000;          
 else if((Sample_reg_Temp1>64)&&(Sample_reg_Temp1<108))
   Is_Exp_Temp=4'b1001;
 else if((Sample_reg_Temp1>107)&&(Sample_reg_Temp1<182))
   Is_Exp_Temp=4'b1010;
 else if((Sample_reg_Temp1>181)&&(Sample_reg_Temp1<305))
   Is_Exp_Temp=4'b1011;
 else if((Sample_reg_Temp1>304)&&(Sample_reg_Temp1<513))
   Is_Exp_Temp=4'b1100;
 else if((Sample_reg_Temp1>512)&&(Sample_reg_Temp1<862))
   Is_Exp_Temp=4'b1101;
 else          
   Is_Exp_Temp=4'b1110;
end

always@(posedge Clk)
begin
  if(Sample_Cnt==3)
    Is_Exp <=#`DLY Is_Exp_Temp;
end               
           
//Block TYPE
always@(Blocksplit_flag or Block_type or Switch_point)
begin
  if((Blocksplit_flag==1)&&(Block_type==2)) 
      begin
      if (Switch_point==1) 
                 Block=2'b11;                     //mix   sfb
           else                                            
       Block=2'b10;                                         //short sfb
                end              
  else 
            Block=2'b00;                     //long  sfb
end 
 
always@(Block or Line_reg)
begin
 if((Block==0)||((Block==3)&&(Line_reg<35)))
   Long=1;
 else
   Long=0;
end 

//look up table of sfb index
always@(posedge Clk)
begin
  if(CS==SFBSEL)
    Sfb_Cnt<=#`DLY Sfb_Cnt+1;
  else
    Sfb_Cnt<=#`DLY 2'b0;
end

always@(posedge Clk)
begin      
 case(Block)
   0: begin 
      if(CS==IDLE)
        Index_reg<=#`DLY 10'b0000000100;
      else if(Sfb_Cnt==2)
        Index_reg<=#`DLY Rom_Q[9:0];
      end
     
   2:begin 
      if(CS==IDLE)
        Index_reg<=#`DLY 10'b0000001100;
      else if(Sfb_Cnt==2)
        Index_reg<=#`DLY Rom_Q[9:0];
      end  
  
  3:begin 
      if(CS==IDLE)
        Index_reg<=#`DLY 10'b0000000100;  
      else if(Line_reg==36)
        Index_reg<=#`DLY 10'b0000110000;
      else if(Sfb_Cnt==2)
        Index_reg<=#`DLY Rom_Q[9:0];
      end  
  endcase
end 

always@(posedge Clk)
begin
  if(CS==IDLE)
    Sfb_reg<=#`DLY 5'b0;
  else if((Line_reg==36)&&(Block==3))
    Sfb_reg<=#`DLY 5'b00011;
  else if(Sfb_Cnt==2)
    Sfb_reg<=#`DLY Sfb_reg+1;
end    
//read Scalefactor
always@(posedge Clk)
begin
 if(CS==SCALE)
   Scale_Cnt<=#`DLY Scale_Cnt+1;
 else 
   Scale_Cnt<=#`DLY 2'b0;
end

always@(posedge Clk)
begin
  if(Scale_Cnt==2)
    Scale_reg<=#`DLY Ram_Q[3:0];
end
//Calculate
always@(Win_reg or Sub0_gain or Sub1_gain or Sub2_gain)
begin
  case(Win_reg)
    0: Sub_gain=Sub0_gain;
    1: Sub_gain=Sub1_gain;
    default:Sub_gain=Sub2_gain;
  endcase
end


always@(Sfb_reg)
begin 
  case(Sfb_reg)
        11: Pretab=2'b01;
        12: Pretab=2'b01;
        13: Pretab=2'b01;
        14: Pretab=2'b01;
        15: Pretab=2'b10;
        16: Pretab=2'b10;
        17: Pretab=2'b11;
        18: Pretab=2'b11;
        19: Pretab=2'b11;
        20: Pretab=2'b10;
   default:Pretab=2'b00;
  endcase
end   

always@(Inx)
begin 
  case(Inx[3:0])
    0:Gain_Correct=20'd110218;
    1:Gain_Correct=20'd131072;
    2:Gain_Correct=20'd155872;
    3:Gain_Correct=20'd185364;
    4:Gain_Correct=20'd220436;
    5:Gain_Correct=20'd262144;
    6:Gain_Correct=20'd311744;
    7:Gain_Correct=20'd370728;
    8:Gain_Correct=20'd440872;
    default:Gain_Correct=20'd0;
   endcase
end

always@(Global_gain)
begin
    Temp0=Global_gain-210;
end

always@(posedge Clk)
begin
  if(!Long)
    Temp1<=#`DLY Temp0-{Sub_gain,3'b0};
  else
    Temp1<=#`DLY Temp0;
end

always@(Temp1)
begin
  Ind_A={4'b0,Temp1[1:0]};
  Exp_A=Temp1[8:2];
end

always@(Pretab or Preflag or Scale_reg or Scalefac_scale or Long)
begin

  if(Long&&Preflag)
    Temp2={1'b0, Scale_reg}+Pretab;
  else
    Temp2={1'b0, Scale_reg};

  if(!Scalefac_scale)
    begin
         Exp_B={2'b0,Temp2[4:1]};
    if(Temp2[0])
     Ind_B=3'b010;
         else
          Ind_B=3'b000; 
    end
  else
    begin
    Ind_B=3'b000;
    Exp_B={1'b0,Temp2};
    end
end

always@(Ind_A or Ind_B)
begin
  Inx=Ind_A-Ind_B+5;
end  

//Multipiler  
always@(CS or Gain_Correct or Sample_reg)
begin
  if(CS==MULTI)
   begin
   Mulin1=Gain_Correct;
        Mulin2=Sample_reg;
        end
  else
   begin
   Mulin1=20'b0;
        Mulin2=20'b0;
        end   
end
      


always@(posedge Clk)
begin
 if(CS==MULTO)
  Mulout_reg<=#`DLY Mulout[37:17];
end 

//Write data to Ram
always@(Exp_A or Exp_B or Is_Exp or Is_Big)
begin
 Exp=({Exp_A[5],Exp_A[5],Exp_A}-{2'b0,Exp_B})+({4'b0,Is_Exp}+{5'b0,Is_Big,2'b0});
end

always@(Mulout_reg)
begin
 Temp6=Mulout_reg[20:1]+Mulout_reg[0];
end

always@(Exp)
begin
 if(Exp[7])
  Temp3=~(Exp)+1;
 else
  Temp3=Exp;
end   

always@(posedge Clk)
begin
 if(Exp[7])
   Temp4<=#`DLY Temp6>>Temp3;
 else
   Temp4<=#`DLY Temp6<<Temp3;
end

always@(Temp4 or Sign_reg or Temp6)
begin
 if(Temp6==0)
    Temp5=20'b0;
 else
  begin
  if(Sign_reg)
    Temp5=~(Temp4)+1;
  else
    Temp5=Temp4;
  end    
end

always@(posedge Clk)
begin
  if(CS==WRITE)
    Ram_D<=#`DLY Temp5;
end
//Incr Lin and Win
always@(posedge Clk)
begin
 if(CS==IDLE)
   Line_reg<=#`DLY 10'b0;
 else if(CS==WRITE)
   Line_reg<=#`DLY Line_reg+1;
end
   
always@(posedge Clk)
begin
  if(CS==IDLE||Win_reg==3)
    Win_reg<=#`DLY 2'b0;
  else if(CS==WRITE)
    Win_reg<=#`DLY Win_reg+1;
end 
     
//Ram and Ram operations   
always@(CS or Line_reg or  Sample_Cnt or Win_reg or Channel or Sfb_reg or Scale_Cnt or Long)
begin 
  if((CS==SAMPLE)&&(Sample_Cnt==0))
    begin
      Ram_we=1'b1;
      Ram_ce=1'b0;
      Ram_addr={2'b01,Channel,Line_reg};
    end
   else if((CS==SCALE)&&(Scale_Cnt==0))
    begin  
      Ram_we=1'b1;
      Ram_ce=1'b0;
      if(Long)
      Ram_addr=2624+{7'b0,Channel, Sfb_reg};
      else    
      Ram_addr=2624+{6'b0,1'b1,Sfb_reg[3:0],Win_reg};
    end   
  else if(CS==WRITE)
   begin 
    Ram_we=1'b0;
    Ram_ce=1'b0;
    Ram_addr={2'b01,Channel,Line_reg};
   end
  else
   begin 
    Ram_we=1'b1;
    Ram_ce=1'b1;
    Ram_addr=13'b0;
   end
end

             
always@(CS or Sample_reg_Temp1 or  Sample_Cnt or Sfrq or Sfb_reg or Long)
begin           
  case(CS) 
      SAMPLE:if(Sample_Cnt==3) 
               begin
               Rom_ce=1'b0;
               Rom_addr=Sample_reg_Temp1+3007; 
               end
             else               
               begin 
               Rom_ce=1'b1;
               Rom_addr=13'b0;  
               end
              
      SFBSEL:if(Sample_Cnt==0)  
               begin
               Rom_ce=1'b0;
               if(Long)
               Rom_addr=2818+{6'b0,Sfrq,Sfb_reg};
               else    
               Rom_addr=2914+{7'b0,Sfrq,Sfb_reg[3:0]}; 
               end  
             else                
               begin 
               Rom_ce=1'b1;
               Rom_addr=13'b0;   
               end
                
     default:begin
              Rom_ce=1'b1;
              Rom_addr=13'b0;
             end
  endcase          
end

always@(posedge Clk)
begin
  Ram_A<=#`DLY Ram_addr;
  Ram_WEN<=#`DLY Ram_we;
  Ram_CEN<=#`DLY Ram_ce;
end

always@(posedge Clk)
begin
  Rom_A<=#`DLY Rom_addr;
  Rom_CEN<=#`DLY  Rom_ce;
end
        
endmodule 
                 
