//*******//***********************************************************
//

//data        : 2007-07-14 8:50:00 
//version     : 1.0
//
//module name : Controll
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



module Controll(Clk,
                Rst,  
                Enable,
                            Enable_syn,
                                Enable_huf, 
                                Enable_req,    
                                Enable_ste,
                                Enable_ala,
                                Enable_imd, 
                                Enable_fil,
                                Enable_i2s,
                    Done_req, 
                    Done_syn,
                                Done_huf,
                                Done_ste,
                                Done_ala,  
                                Done_imd,  
                                Done_fil,
                                Done_i2s,       
                                Mode,
                                Channel,
                Granule);
    
input      Clk;
input      Rst;
input      Enable;
input      Done_syn;
input      Done_huf;   
input      Done_req;  
input      Done_ste;
input      Done_ala;   
input      Done_imd;   
input      Done_fil;
input      Done_i2s;
input[1:0] Mode; 

output     Enable_syn;
output     Enable_huf;
output     Enable_req;
output     Enable_ste;
output     Enable_ala; 
output     Enable_imd;
output     Enable_fil;
output     Enable_i2s;
output     Channel;
output     Granule;  

reg        Enable_syn;
reg        Enable_huf;   
reg        Enable_req;   
reg        Enable_ste;
reg        Enable_ala; 
reg        Enable_imd;  
reg        Enable_fil;
reg        Enable_i2s;
reg        Channel;
reg        Granule;

reg        Gr;
reg        Ch;



reg [4 :0] CS, NS;

parameter  
          NULL =4'b0000,
          SYCN =4'b0001,
          HUFF =4'b0010,
          REQT =4'b0011,   
          STER =4'b0100,
          ALAI =4'b0101,  
          IMDT =4'b0110,
          FILT =4'b0111,
                         WRITE=4'b1000,
          DONE =4'b1001;
          


//****************************MAIN**********************************************//          
always@(posedge Clk)
begin
  if(!Rst)
    CS<=#`DLY NULL;
  else
    CS<=#`DLY NS;          
end

always@(Done_huf or Done_syn or Enable or CS or Gr or Done_req
        or Done_ste or Done_ala or Mode or Ch or Done_imd or Done_fil or Done_i2s)
begin
  case(CS)
   NULL:if(Enable)
         NS=SYCN;
       else
         NS=NULL; 
      
   SYCN:if(Done_syn)
         NS=HUFF;
        else
         NS=SYCN;
   
   HUFF:if(Done_huf)
         NS=REQT;
        else
         NS=HUFF;    
        
   REQT:if(Done_req)
         begin
         if(Mode==3)
          NS=ALAI;   //DONE;//
         else
         begin
         if(Ch==0)
          NS=HUFF;
         else
          NS=STER;  //DONE;//
         end
         end            
        else
         NS=REQT;    
         
   STER:if(Done_ste)
         NS=ALAI;
        else
         NS=STER;   
   
   ALAI:if(Done_ala)
         begin
         if(Mode==3)
          NS=IMDT;
         else
         begin
         if(Ch==0)
          NS=ALAI;
         else
          NS=IMDT;
         end
         end            
        else
         NS=ALAI;  
         
   
   IMDT:if(Done_imd)
         begin
         if(Mode==3)
          NS=FILT;
         else
         begin
         if(Ch==0)
          NS=IMDT;
         else
          NS=FILT;
         end
         end            
        else
         NS=IMDT;                
   
   FILT:if(Done_fil)
         begin
         if(Mode==3)
          NS=WRITE;
         else
         begin
         if(Ch==0)
          NS=FILT;
         else
          NS=WRITE;
         end
         end            
        else
         NS=FILT;    
                        
        WRITE:if(Done_i2s)
                 NS=DONE;
         else
          NS=WRITE;
                           
        
   DONE:if(Mode==3)
        begin
        if(Gr==1)
          NS=SYCN;
        else
          NS=HUFF;
       end
     else
      begin
        if((Gr==1)&&(Ch==1))
          NS=SYCN;
        else
          NS=HUFF;
       end    
       
        default: NS=NULL;
  endcase
end
  
always@(posedge Clk)
begin
 if((CS==SYCN)&&(!Done_syn))
   Enable_syn<=#`DLY 1'b1;
 else
   Enable_syn<=#`DLY 1'b0;
end   

always@(posedge Clk)
begin
 if((CS==HUFF)&&(!Done_huf))
   Enable_huf<=#`DLY 1'b1;
 else
   Enable_huf<=#`DLY 1'b0;
end  

always@(posedge Clk)
begin
 if(CS==REQT)
   Enable_req<=#`DLY 1'b1;
 else
   Enable_req<=#`DLY 1'b0;
end  

always@(posedge Clk)
begin
 if((CS==STER))
   Enable_ste<=#`DLY 1'b1;
 else
   Enable_ste<=#`DLY 1'b0; 
end  
   
always@(posedge Clk)
begin
 if((CS==ALAI)&&(!Done_ala))
   Enable_ala<=#`DLY 1'b1;
 else
   Enable_ala<=#`DLY 1'b0;
end  

always@(posedge Clk)
begin
 if((CS==IMDT)&&(!Done_imd))
   Enable_imd<=#`DLY 1'b1;
 else
   Enable_imd<=#`DLY 1'b0;
end  

always@(posedge Clk)
begin
 if((CS==FILT)&&(!Done_fil))
   Enable_fil<=#`DLY 1'b1;
 else
   Enable_fil<=#`DLY 1'b0;
end   

always@(posedge Clk)
begin
 if((CS==WRITE)&&(!Done_i2s))
   Enable_i2s<=#`DLY 1'b1;
 else
   Enable_i2s<=#`DLY 1'b0;
end  


always@(posedge Clk)
begin
  if(!Rst)
    Ch<=#`DLY 1'b0;
  else
  begin
   case(CS)
    REQT:if((Done_req)&&(Mode!=3)&&(Ch==0))
           Ch<=#`DLY 1'b1; 
    
    STER:if(Done_ste)
           Ch<=#`DLY 1'b0;
    
    ALAI:if((Done_ala)&&(Mode!=3)&&(Ch==0))
           Ch<=#`DLY 1'b1;  
             else if((Done_ala)&&(Ch==1))
                   Ch<=#`DLY 1'b0;  
          
    IMDT:if((Done_imd)&&(Mode!=3)&&(Ch==0))
           Ch<=#`DLY 1'b1; 
         else if((Done_imd)&&(Ch==1))
                   Ch<=#`DLY 1'b0;   
           
    FILT:if((Done_fil)&&(Mode!=3)&&(Ch==0))
           Ch<=#`DLY 1'b1;           
                          
    DONE:if(Mode!=3)
           Ch<=#`DLY ~Ch;
    endcase
  end
end 

always@(posedge Clk)
begin
  if(!Rst)
    Gr<=#`DLY 1'b0;
  else if((CS==DONE)&&(Gr==0)&&(Ch==1)&&(Mode!=3))
    Gr<=#`DLY 1'b1;
  else if((CS==DONE)&&(Gr==0)&&(Ch==0)&&(Mode==3))
    Gr<=#`DLY 1'b1;
  else if((CS==DONE)&&(Gr==1)&&(Ch==1)&&(Mode!=3))
    Gr<=#`DLY 1'b0;
  else if((CS==DONE)&&(Gr==1)&&(Ch==0)&&(Mode==3))
    Gr<=#`DLY 1'b0;
end 

always@(Gr)
begin
  Granule=Gr;
end

always@(Ch)
begin
  Channel=Ch;
end
  
endmodule 
          
          
