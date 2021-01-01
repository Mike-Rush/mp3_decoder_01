  //*******//***********************************************************
//
//data        : 2007-07-14 8:50:00 
//version     : 1.0
//
//module name : Memorysel
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


module Memorysel(Clk,
                 Enable_syn,
                 Enable_huf, 
                 Enable_req,
                 Enable_ste,
                 Enable_ala, 
                 Enable_imd,   
                 Enable_fil,
				 Enable_i2s,
                 RamWEn_syn,
                 RamCen_syn,
                 RamA_syn,
                 RamD_Syn,
                 RamWEn_huf,
                 RamCen_huf,
                 RamA_huf,
                 RamD_huf,
			     RamWEn_req,
                 RamCen_req,
                 RamA_req,
                 RamD_req,
                 RamWEn_ste,
                 RamCen_ste,
                 RamA_ste,
                 RamD_ste,
                 RamWEn_ala,
                 RamCen_ala,
                 RamA_ala,
                 RamD_ala,
                 RamWEn_imd,
                 RamCen_imd,
                 RamA_imd,
                 RamD_imd, 
                 RamWEn_fil,
                 RamCen_fil,
                 RamA_fil,
                 RamD_fil,
					  RamWEn_i2s,
                 RamCen_i2s,
                 RamA_i2s,
                 Ram_Wen,
                 Ram_Cen,
                 Ram_A,
                 Ram_D,
                 Rom_A,
                 Rom_CEN,
                 RomA_huf,
                 RomCEN_huf,
                 RomA_req,
                 RomCEN_req,
				 RomCEN_imd,
				 RomA_imd, 
				 RomCEN_fil,
				 RomA_fil,
                 Mulin1,
                 Mulin2,
                 Mulin1_req,
                 Mulin2_req,
                 Mulin1_ste,
                 Mulin2_ste,
                 Mulin1_ala,
                 Mulin2_ala,
                 Mulin1_imd,
                 Mulin2_imd,
                 Mulin1_fil,
                 Mulin2_fil);

input       Clk;        
        
input       Enable_syn;
input       Enable_huf;
input       Enable_req;   
input       Enable_ste;
input       Enable_ala; 
input       Enable_imd; 
input       Enable_fil;
input       Enable_i2s;

input       RamCen_huf;
input       RamCen_syn;  
input       RamCen_req;  
input       RamCen_ste;
input       RamCen_ala;    
input       RamCen_imd;  
input       RamCen_fil;
input       RamCen_i2s;

input       RamWEn_huf;
input       RamWEn_syn;     
input       RamWEn_req;   
input       RamWEn_ste;
input       RamWEn_ala;
input       RamWEn_imd;    
input       RamWEn_fil;
input       RamWEn_i2s;

input       RomCEN_req;
input       RomCEN_huf;   
input       RomCEN_imd;  
input       RomCEN_fil;

input[12:0] RomA_huf;
input[12:0] RomA_req;    
input[12:0] RomA_imd;  
input[12:0] RomA_fil;


input[19:0] RamD_huf;
input[19:0] RamD_Syn;  
input[19:0] RamD_req;
input[19:0] RamD_ste;
input[19:0] RamD_ala;   
input[19:0] RamD_imd;   
input[19:0] RamD_fil;

input[12:0] RamA_huf;
input[12:0] RamA_syn;
input[12:0] RamA_req;   
input[12:0] RamA_ste;
input[12:0] RamA_ala;     
input[12:0] RamA_imd;    
input[12:0] RamA_fil;
input[12:0] RamA_i2s;

input[19:0] Mulin1_req;
input[19:0] Mulin2_req;
input[19:0] Mulin1_ste;
input[19:0] Mulin2_ste;
input[19:0] Mulin1_ala;
input[19:0] Mulin2_ala; 
input[19:0] Mulin1_imd;
input[19:0] Mulin2_imd;   
input[19:0] Mulin1_fil;
input[19:0] Mulin2_fil;


output      Ram_Wen;
output      Ram_Cen;
output      Rom_CEN;
output[19:0]Ram_D;
output[12:0]Ram_A;  
output[12:0]Rom_A;       

output[19:0]Mulin1;
output[19:0]Mulin2;


reg         Ram_Wen;
reg         Ram_Cen;
reg         Rom_CEN;

reg   [12:0]Rom_A;
reg   [19:0]Ram_D;
reg   [12:0]Ram_A;   

reg   signed[19:0]Mulin1;
reg   signed[19:0]Mulin2;  

always@(Enable_huf or Enable_syn or RamA_syn or RamA_huf
        or RamD_Syn or RamD_huf or RamWEn_syn or RamWEn_huf
        or RamCen_syn or RamCen_huf or Enable_req or RamA_req
        or RamD_req or RamCen_req or RamWEn_req or RomA_req or
        RomA_huf or RomCEN_huf or RomCEN_req or Enable_ste or 
        RamWEn_ste or RamCen_ste or RamA_ste or RamD_ste or
        Enable_ala or RamWEn_ala or RamCen_ala or RamA_ala or
        RamD_ala  or RamCen_imd or
        RamWEn_imd or RamA_imd or RamD_imd or Enable_imd or RomA_imd
        or RomCEN_imd or  RamCen_fil or
        RamWEn_fil or RamA_fil or RamD_fil or Enable_fil or RomA_fil
        or RomCEN_fil  or  RamWEn_i2s or RamA_i2s or RamCen_i2s or Enable_i2s)
        
begin
   case({Enable_i2s,Enable_fil,Enable_imd,Enable_ala,Enable_ste,Enable_req ,Enable_huf,Enable_syn})
     1: begin
          Ram_A=RamA_syn;
          Ram_D=RamD_Syn;
          Ram_Cen=RamCen_syn;
          Ram_Wen=RamWEn_syn;
		    Rom_CEN=1'b1;
          Rom_A=13'b0;   
        end
     
     2: begin
          Ram_A=RamA_huf;
          Ram_D=RamD_huf;
          Ram_Cen=RamCen_huf;
          Ram_Wen=RamWEn_huf;    
          Rom_A=RomA_huf;
          Rom_CEN=RomCEN_huf; 
        end  
        
     4: begin
          Ram_A=RamA_req;
          Ram_D=RamD_req;
          Ram_Cen=RamCen_req;
          Ram_Wen=RamWEn_req;
          Rom_A=RomA_req;
          Rom_CEN=RomCEN_req; 
        end
        
     8: begin
          Ram_A=RamA_ste;
          Ram_D=RamD_ste;
          Ram_Cen=RamCen_ste;
          Ram_Wen=RamWEn_ste;
		  Rom_CEN=1'b1;
          Rom_A=13'b0;   
        end  
             
     16: begin
          Ram_A=RamA_ala;
          Ram_D=RamD_ala;
          Ram_Cen=RamCen_ala;
          Ram_Wen=RamWEn_ala;
		  Rom_CEN=1'b1;
          Rom_A=13'b0; 
        end 
        
     32: begin
          Ram_A=RamA_imd;
          Ram_D=RamD_imd;
          Ram_Cen=RamCen_imd;
          Ram_Wen=RamWEn_imd;
          Rom_A=RomA_imd;
          Rom_CEN=RomCEN_imd;  
        end 
        
     64: begin
          Ram_A=RamA_fil;
          Ram_D=RamD_fil;
          Ram_Cen=RamCen_fil;
          Ram_Wen=RamWEn_fil;
          Rom_A=RomA_fil;
          Rom_CEN=RomCEN_fil;  
        end        
   
	 128 :begin
          Ram_A=RamA_i2s;
          Ram_Cen=RamCen_i2s;
          Ram_Wen=RamWEn_i2s;  
			 Ram_D=20'b0;
			 Rom_CEN=1'b1;
          Rom_A=13'b0; 
        end       
	 
	 
	          
    default:    
        begin
          Ram_A=13'b0;
          Ram_D=20'b0;
          Ram_Cen=1'b1;
          Ram_Wen=1'b1;   
          Rom_CEN=1'b1;
          Rom_A=13'b0; 
        end      
   endcase
end


always@(posedge Clk )
        
begin
   case({Enable_fil,Enable_imd,Enable_ala,Enable_ste,Enable_req ,Enable_huf,Enable_syn})
        
     4: begin
          Mulin1<=#`DLY Mulin1_req;
          Mulin2<=#`DLY Mulin2_req;
        end
        
     8: begin  
          Mulin1<=#`DLY Mulin1_ste;
          Mulin2<=#`DLY Mulin2_ste;
        end  
             
     16: begin
          Mulin1<=#`DLY Mulin1_ala;
          Mulin2<=#`DLY Mulin2_ala;
        end 
        
     32: begin  
          Mulin1<=#`DLY Mulin1_imd;
          Mulin2<=#`DLY Mulin2_imd;
        end 
        
     64: begin  
          Mulin1<=#`DLY Mulin1_fil;
          Mulin2<=#`DLY Mulin2_fil;
        end        
             
    default:    
        begin
          Mulin1<=#`DLY 20'b0;
          Mulin2<=#`DLY 20'b0;
        end      
   endcase
end

endmodule
     




       