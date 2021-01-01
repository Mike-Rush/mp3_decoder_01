//***********************************************************
//
//filename    : Imdct.v
//data        : 2007-07-11 11:30:00 
//version     : 1.0
//
//module name : Imdct
//
//modification history
//---------------------------------
//firt finish  2006
//             2007-07-30  15:51:00   
//***********************************************************
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`define DLY      0       
module     Imdct(Clk,
                 Rst,
                 Enable,   
                 Done,  
                 Mulin1_imd,
                 Mulin2_imd,
                 Mulout, 
                 Channel,
                 Mode,
                 Ram_WEN,
                 Ram_CEN,
                 Ram_A,
                 Ram_D,  
                 Ram_Q, 
                 Rom_A,
                 Rom_Q,
                 Rom_CEN,
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
input[19:0]   Rom_Q;
input[1 :0]   Mode;

output        Done;
output        Ram_CEN;
output        Ram_WEN; 
output        Rom_CEN;
output[12:0]  Rom_A;
output[12:0]  Ram_A;
output[19:0]  Ram_D;

output[19:0]  Mulin1_imd;
output[19:0]  Mulin2_imd;

reg           Done;
reg           Ram_CEN;
reg           Ram_WEN;   
reg           Rom_CEN;
reg[12:0]     Rom_A;
reg[12:0]     Ram_A;
reg[19:0]     Ram_D;

reg signed[19:0] Mulin1_imd;
reg signed[19:0] Mulin2_imd;    
                               
//inter register
reg[2 :0]    CS,NS;  
reg signed[20:0] Mulout_reg; 
reg signed[19:0] Data_reg;
reg signed[19:0] Adder_reg;  
reg[4 :0]    Line_cnt;
reg[4 :0]    Imdct_cnt;
reg[5 :0]    Sfb_cnt;
reg[9 :0]    Ram_Point;
reg[8 :0]    Rom_Point;  
reg[4 :0]    Short_Cnt0;
reg[2 :0]    Short_Cnt1;
reg          Flag;
parameter   
            IDLE  =3'b000,
            SELTY =3'b001,
            IMDCT =3'b010,
            SHORT =3'b011,
            OUTPT =3'b100,
            UPDAT =3'b101,
            READY =3'b110;

//inter variable 
reg[1 :0]   Block;
reg         RamCEN_i;
reg         RamWEn_i;
reg[12:0]   RamAddr_i;  
reg[19:0]   RamD_i;

reg         RomCEN_i;
reg[12:0]   RomAddr_i;  

reg[5 :0]   RamAddr_l0;
reg[5 :0]   RamAddr_l1;
reg[5 :0]   RamAddr_s0;
reg[5 :0]   RamAddr_s1;
  

reg         RamCEN_s;
reg         RamWEn_s;
reg[12:0]   RamAddr_s;    

reg         RamCEN_o;
reg         RamWEn_o;
reg[12:0]   RamAddr_o;  
reg[19:0]   RamD_o;
  
reg signed[19:0] Temp0;
reg signed[19:0] Temp1;
reg       [5 :0] Temp3;
reg       [9 :0] Temp2;
reg       [5 :0] Temp4;
//************************************MAIN**************************//
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY 3'b0;
  else
    CS<=#`DLY  NS;
end

always@(CS or Enable or Sfb_cnt or Block or Line_cnt or Short_Cnt1 or Short_Cnt0)
begin
  case(CS)
    
    IDLE :if(Enable)
           NS=IMDCT;
         else
           NS=IDLE;
    
    SELTY:if(Sfb_cnt==32)
           NS=READY;
          else      
           NS=IMDCT;
    
    IMDCT:if(Line_cnt==18)
           begin
           if(Block==2)
           NS=SHORT;
           else
           NS=OUTPT;
           end           
          else
           NS=IMDCT;
    
    SHORT:if(Short_Cnt1==5&&Short_Cnt0==11)
           NS=OUTPT;
          else
           NS=SHORT;                                
                                            
    OUTPT:if(Line_cnt==18)
            NS=SELTY;
          else
            NS=OUTPT;
    
    READY:NS=IDLE; 
    
    default:NS=IDLE;
   endcase
end
    



always@(Block_type or Blocksplit_flag or Sfb_cnt or Switch_point)
begin
 if((Blocksplit_flag)&&(Switch_point)&&(Sfb_cnt<2))
  Block=2'b00;
 else
  Block=Block_type;
end   

always@(posedge Clk)
begin
  if((Sfb_cnt==32)&&(CS==SELTY))
     Done<=#`DLY 1'b1;
  else 
     Done<=#`DLY 1'b0;
end

//Calculate IMDCT 
always@(posedge Clk)
begin
  if((CS==SELTY)||(CS==IDLE)||(Imdct_cnt==27)||((CS==OUTPT)&&(Imdct_cnt==6)))
    Imdct_cnt<=#`DLY 5'b0;
  else if(CS==IMDCT||CS==OUTPT)
    Imdct_cnt<=#`DLY Imdct_cnt+1;
end

always@(posedge Clk)
begin
  if(CS==SELTY||Line_cnt==18||(CS==IDLE))
    Line_cnt<=#`DLY 5'b0;
  else if(Imdct_cnt==26||((CS==OUTPT)&&(Imdct_cnt==5)))
    Line_cnt<=#`DLY Line_cnt+1;
end

always@(posedge Clk)
begin
  if(CS==IDLE)
    Sfb_cnt<=#`DLY 5'b0;
  else if((CS==OUTPT)&&(Line_cnt==18))
    Sfb_cnt<=#`DLY Sfb_cnt+1;
end

//Ram addr  
always@(Imdct_cnt)
begin 
   case(Imdct_cnt)
     18,19,20,21,22,23,26:RamCEN_i=1'b1;
   default: RamCEN_i=1'b0;
   endcase
end
     
     
always@(Imdct_cnt)     
begin 
 if((Imdct_cnt==24)||(Imdct_cnt==25))
   RamWEn_i=1'b0;
 else
   RamWEn_i=1'b1;
end

always@(Line_cnt)
begin
  case(Line_cnt)
   1: begin RamAddr_l0=6'd1;RamAddr_l1=6'd16;
            RamAddr_s0=6'd1;RamAddr_s1=6'd4;end 
            
   2: begin RamAddr_l0=6'd2;RamAddr_l1=6'd15;
            RamAddr_s0=6'd2;RamAddr_s1=6'd3;end    
            
   3: begin RamAddr_l0=6'd3;RamAddr_l1=6'd14;
            RamAddr_s0=6'd6;RamAddr_s1=6'd11;end    
            
   4: begin RamAddr_l0=6'd4;RamAddr_l1=6'd13;
            RamAddr_s0=6'd7;RamAddr_s1=6'd10;end   
            
   5: begin RamAddr_l0=6'd5;RamAddr_l1=6'd12;
            RamAddr_s0=6'd8;RamAddr_s1=6'd9;end   
            
   6: begin RamAddr_l0=6'd6;RamAddr_l1=6'd11;
            RamAddr_s0=6'd24;RamAddr_s1=6'd29;end   
            
   7: begin RamAddr_l0=6'd7;RamAddr_l1=6'd10;
            RamAddr_s0=6'd25;RamAddr_s1=6'd28;end    
            
   8: begin RamAddr_l0=6'd8;RamAddr_l1=6'd9 ;
            RamAddr_s0=6'd26;RamAddr_s1=6'd27;end   
            
   9: begin RamAddr_l0=6'd18;RamAddr_l1=6'd35;
            RamAddr_s0=6'd30;RamAddr_s1=6'd35;end   
            
   10:begin RamAddr_l0=6'd19;RamAddr_l1=6'd34;
            RamAddr_s0=6'd31;RamAddr_s1=6'd34;end   
            
   11:begin RamAddr_l0=6'd20;RamAddr_l1=6'd33;
            RamAddr_s0=6'd32;RamAddr_s1=6'd33;end  
            
   12:begin RamAddr_l0=6'd21;RamAddr_l1=6'd32;
            RamAddr_s0=6'd12;RamAddr_s1=6'd17;end   
            
   13:begin RamAddr_l0=6'd22;RamAddr_l1=6'd31;
            RamAddr_s0=6'd13;RamAddr_s1=6'd16;end   
            
   14:begin RamAddr_l0=6'd23;RamAddr_l1=6'd30;
            RamAddr_s0=6'd14;RamAddr_s1=6'd15;end   
            
   15:begin RamAddr_l0=6'd24;RamAddr_l1=6'd29;
            RamAddr_s0=6'd18;RamAddr_s1=6'd23;end   
            
   16:begin RamAddr_l0=6'd25;RamAddr_l1=6'd28;
            RamAddr_s0=6'd19;RamAddr_s1=6'd22;end   
            
   17:begin RamAddr_l0=6'd26;RamAddr_l1=6'd27;
            RamAddr_s0=6'd20;RamAddr_s1=6'd21;end   
            
   default:begin 
            RamAddr_l0=6'd0;RamAddr_l1=6'd17;
            RamAddr_s0=6'd0;RamAddr_s1=6'd5;end
  endcase
end 


always@(Block or RamAddr_l0 or RamAddr_l1 or RamAddr_s0 or 
        RamAddr_s1 or Imdct_cnt or Line_cnt or Channel or Ram_Point)
begin
   case(Imdct_cnt)
    24:begin 
       if (Block==2)
        RamAddr_i={7'b1001001,RamAddr_s0};
       else
        RamAddr_i={7'b1001001,RamAddr_l0};   
       end
        
    25:begin
       if(Block==2) 
        RamAddr_i={7'b1001001,RamAddr_s1};
       else
        RamAddr_i={7'b1001001,RamAddr_l1};
       end
    default: RamAddr_i={2'b01,Channel,Imdct_cnt+Ram_Point};
   endcase
end 

always@(Imdct_cnt or Mulout_reg or Data_reg)
begin
  if(Imdct_cnt==24||Imdct_cnt==25)
    RamD_i=Mulout_reg[20:1]+Mulout_reg[0];
  else 
    RamD_i=Mulout_reg[19:0]+Data_reg;
end 


//Rom Addr    
always@(posedge Clk)          
begin
 if(CS==IDLE)
   Ram_Point<=#`DLY 10'b0;
 else if(CS==SELTY)    
   Ram_Point<=#`DLY Ram_Point+18;
end

always@(Imdct_cnt)
begin 
  case(Imdct_cnt)
    18,19,22,23,24,25,26,27:RomCEN_i=1'b1;
    default: RomCEN_i=1'b0;
  endcase
end

always@(posedge Clk)
begin
 if(CS==IDLE||CS==SELTY)
   Rom_Point<=#`DLY 9'b0;   
 else if(Imdct_cnt<18)
   Rom_Point<=#`DLY Rom_Point+1;
end

always@(Rom_Point or Imdct_cnt or Block or RamAddr_l0 or RamAddr_l1 or RamAddr_s0 or RamAddr_s1)
begin
 case(Block)
   0:begin
     case(Imdct_cnt)
      20:RomAddr_i={7'b1000110,RamAddr_l0}; 
      21:RomAddr_i={7'b1000110,RamAddr_l1};
      default:RomAddr_i={4'b1000,Rom_Point}; 
     endcase
    end  
   1:begin
     case(Imdct_cnt)
      20:RomAddr_i={7'b1000111,RamAddr_l0};
      21:RomAddr_i={7'b1000111,RamAddr_l1};
      default:RomAddr_i={4'b1000,Rom_Point}; 
     endcase
    end      
   2:begin
     case(Imdct_cnt)
      20 :RomAddr_i={7'b1001111,RamAddr_s0};
      21 :RomAddr_i={7'b1001111,RamAddr_s1};
      default:RomAddr_i={4'b1001,Rom_Point};  
     endcase
    end  
   default:begin
     case(Imdct_cnt)
      20:RomAddr_i={7'b1001110,RamAddr_l0};
      21:RomAddr_i={7'b1001110,RamAddr_l1};
      default:RomAddr_i={4'b1000,Rom_Point};  
     endcase
    end
 endcase
end

//Multiplier
always@(Rom_Q or CS)
begin
 if(CS==IMDCT)
   Mulin1_imd=Rom_Q;
 else
   Mulin1_imd=20'b0;
end
  
always@(Imdct_cnt or CS or Adder_reg or Ram_Q)
begin
 if(CS==IMDCT)
   begin
   if(Imdct_cnt==22||Imdct_cnt==23)
     Mulin2_imd=Adder_reg;
   else
     Mulin2_imd= Ram_Q;
   end
 else
   Mulin2_imd=20'b0; 
end
    
always@(posedge Clk)
begin
 if(CS==IMDCT)
   Mulout_reg<=#`DLY Mulout[38:18];   
 else if(Short_Cnt1==2||((CS==OUTPT)&&(Imdct_cnt==3)))
   Mulout_reg<=#`DLY {1'b0,Ram_Q};   
end  
  
always@(posedge Clk)
begin
 case(Imdct_cnt)
  0: Adder_reg<=#`DLY 20'b0;
  4,5,6,7,8,9,10,11,12,13,14,15,
  16,17,18,19,20,21:Adder_reg<=#`DLY Mulout_reg[20:1]+Mulout_reg[0]+Adder_reg;
 endcase
end     
  
//add three short block 
always@(posedge Clk)
begin
 if(CS==IMDCT||Short_Cnt1==5)
   Short_Cnt1<=#`DLY 3'b0;
 else if(CS==SHORT)
   Short_Cnt1<=#`DLY Short_Cnt1+1;
end

always@(posedge Clk)
begin
 if(CS==IMDCT)
   Short_Cnt0<=#`DLY 4'b0;
 else if(Short_Cnt1==5)
   Short_Cnt0<=#`DLY Short_Cnt0+1;
end

always@(posedge Clk)
begin
 if(Short_Cnt1==3||((CS==OUTPT)&&((Imdct_cnt==2)||(Imdct_cnt==4))))
   Data_reg<=#`DLY Ram_Q;

end    
     
always@(Short_Cnt1)
begin
 if((Short_Cnt1==0)||(Short_Cnt1==1)||(Short_Cnt1==4))
   RamCEN_s=1'b0;
 else
   RamCEN_s=1'b1;
end 
 
always@(Short_Cnt1 )
begin
 if(Short_Cnt1==4)
   RamWEn_s=1'b0;
 else
   RamWEn_s=1'b1;
end  
 
always@(Short_Cnt1 or Short_Cnt0)
begin
  if(Short_Cnt1==0)
    begin
         Temp4=Short_Cnt0+24;
    RamAddr_s={7'b1001001, Temp4};
         end
  else
    begin
         Temp4=Short_Cnt0+6;
    RamAddr_s={7'b1001001,Temp4};
         end
end   
 
//OUTPT 
always@(posedge Clk)
begin 
 if(!Rst)
  Flag<=#`DLY 1'b0;
 else if((CS==READY)&&((Mode==3)||(Channel)))
  Flag<=#`DLY 1'b1;
end

always@(Imdct_cnt)
begin
 if(Imdct_cnt==3||Imdct_cnt==6)
   RamCEN_o=1'b1;
 else
   RamCEN_o=1'b0;
end 
  
always@(Imdct_cnt)
begin
 if(Imdct_cnt==4||Imdct_cnt==5)
   RamWEn_o=1'b0;
 else
   RamWEn_o=1'b1;
end 

always@(Imdct_cnt or Line_cnt or Block or Ram_Point or Channel)
begin
  Temp3=5'b0;
  Temp2=Line_cnt+Ram_Point;
  case(Imdct_cnt)
    0: RamAddr_o={2'b10,Channel,Temp2};
    1: if(Block!=2)
             begin
                  Temp3=Line_cnt;
        RamAddr_o={7'b1001001,Temp3};
                  end
       else
                  begin
                  Temp3=Line_cnt-6;
        RamAddr_o={7'b1001001,Temp3}; 
                  end
    
    2:if(Block!=2)
             begin
                  Temp3=Line_cnt+18;
        RamAddr_o={7'b1001001,Temp3};
                  end
       else
                  begin
                  Temp3=Line_cnt+12;
        RamAddr_o={7'b1001001,Temp3};
                  end
    4:RamAddr_o={2'b01,Channel,Temp2};
    5:RamAddr_o={2'b10,Channel,Temp2};
    default:RamAddr_o=13'b0;
  endcase
end    
 
always@(Block or Data_reg or Imdct_cnt or Flag or Line_cnt)
begin
  if(Imdct_cnt==4)
    begin
    if(!Flag)
      Temp0=20'b0;
    else 
      Temp0=Data_reg;
    end   
  else if(Imdct_cnt==5)
    begin
    if((Block==2)&&((Line_cnt==12)||(Line_cnt==13)||(Line_cnt==14)||
      (Line_cnt==15)||(Line_cnt==16)||(Line_cnt==17)))
      Temp0=20'b0;
    else 
      Temp0=Data_reg; 
    end
  else
    Temp0=20'b0;
end

always@(Block or Mulout_reg or Imdct_cnt or Line_cnt)
begin
  if(Imdct_cnt==4)
    begin
    if((Block==2)&&((Line_cnt==0)||(Line_cnt==1)||(Line_cnt==2)||
      (Line_cnt==3)||(Line_cnt==4)||(Line_cnt==5)))
      Temp1=20'b0;
    else 
      Temp1=Mulout_reg[19:0]; 
    end
  else
     Temp1=20'b0;
end

always@(Imdct_cnt or Temp0 or Temp1 or Sfb_cnt or Line_cnt)
begin
 if(Imdct_cnt==4)
   begin
    if(Sfb_cnt[0]&&Line_cnt[0])
      RamD_o=#`DLY ~(Temp0+Temp1)+1;
    else
      RamD_o=Temp0+Temp1;
    end
 else
   RamD_o=Temp0;
end

// write and read the memory
always@(posedge Clk)
begin 
 case(CS)
   IMDCT: begin
          Ram_CEN<=#`DLY RamCEN_i;
          Ram_WEN<=#`DLY RamWEn_i;
          Ram_A  <=#`DLY RamAddr_i;
          end
          
   SHORT: begin
          Ram_CEN<=#`DLY RamCEN_s;
          Ram_WEN<=#`DLY RamWEn_s;
          Ram_A  <=#`DLY RamAddr_s;
          end
          
    OUTPT:begin
          Ram_CEN<=#`DLY RamCEN_o;
          Ram_WEN<=#`DLY RamWEn_o;
          Ram_A  <=#`DLY RamAddr_o;
          end     
          
   default:begin
          Ram_CEN<=#`DLY 1'b1;
          Ram_WEN<=#`DLY 1'b1;
          Ram_A  <=#`DLY 20'b0;
          end  
  endcase   
end

always@(posedge Clk)
begin 
  if(CS==OUTPT)    
         Ram_D<=#`DLY RamD_o;    
  else
    Ram_D<=#`DLY RamD_i;
end

always@(posedge Clk)
begin 
  begin
    Rom_CEN<=#`DLY RomCEN_i;      
    Rom_A  <=#`DLY RomAddr_i;
  end
end



endmodule                               
