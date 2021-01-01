//***********************************************************
//
//data        : 2007-10-15  16:45:00  
//version     : 1.0
//
//module name : Filterbank
//
//modification history
//---------------------------------
//firt finish  
//             2007-10-15  16:45:00   
//***********************************************************
// synopsys translate_off
//`include "timescale.v"
// synopsys translate_on
`define DLY      0    
module write_i2s_fifo(Clk,
                      Rst,
                      Mode,
                      Write_enable,
                      Write_done,
                      Ram_addr,
                      Ram_out,
                      Ram_wen,
                      Ram_cen,
                      Winc,
                      Wdata,
                      Wfull
                      );

// Global signal
input           Rst;
input           Clk;

//Connect with I2S fifo
input           Wfull;
output          Winc;
output[31:0]    Wdata;

//Connect with  MP3 Decoder  
input [1 :0]    Mode;
input           Write_enable;   
input [19:0]    Ram_out;
output          Write_done;
output          Ram_wen;
output          Ram_cen;
output[12:0]    Ram_addr;   


reg             Ram_cen;
reg   [12:0]    Ram_addr;
reg             Write_done;
reg             Winc;
//mian 
reg [1 :0] current_state, next_state;
reg [4 :0] Sfb_cnt;
reg [4 :0] Line_cnt;  
reg [2 :0] Write_cnt;
reg [15:0] Data_reg;
wire[9 :0] Temp;

//for test
//integer    file;
//reg signed[15 :0] Data0;    
//integer    file0;
//reg signed[15 :0] Data1; 
//test end

parameter 
          IDLE  =2'b00,
          FULL  =2'b01,
          WRITE =2'b10,
          READY =2'b11;
          
          
always@(posedge Clk)
begin
  if(!Rst)
    current_state<=#`DLY IDLE;
  else
    current_state<=#`DLY next_state;
end

always@(Sfb_cnt or current_state or Wfull or Write_cnt or Write_enable)
begin
  next_state=IDLE;
  case(current_state)
    IDLE: if(Write_enable)
            next_state=FULL;
    
    FULL:if(Sfb_cnt==18)
            next_state=READY;
          else if(Wfull)
            next_state=FULL;
          else
            next_state=WRITE;
    
    WRITE: if(Write_cnt==4)
             next_state=FULL;
           else
                            next_state=WRITE;
             
    READY:next_state=IDLE;
   endcase
end     

always@(posedge Clk)
begin 
  if(Write_cnt==1||Write_cnt==2)
  Data_reg<=#`DLY Ram_out[15:0];
end

assign Wdata={16'b0,Data_reg};


always@(posedge Clk)
begin
  if(current_state==IDLE)
    Sfb_cnt<=#`DLY 5'b0;
  else if(Line_cnt==31&&Write_cnt==4)
    Sfb_cnt<=#`DLY Sfb_cnt+1;
end
            
always@(posedge Clk)
begin
  if(current_state==IDLE)
    Line_cnt<=#`DLY 5'b0;
  else if(Write_cnt==4)
    Line_cnt<=#`DLY Line_cnt+1;
end          

always@(posedge Clk)
begin
  if(Sfb_cnt==18)
    Write_done<=#`DLY 1'b1;
  else
    Write_done<=#`DLY 1'b0;
end

assign Ram_wen=1'b1;

always@(posedge Clk)
begin
  if((!Wfull)&&(Write_cnt==0||Write_cnt==5))
    Ram_cen<=#`DLY 1'b0;
  else 
    Ram_cen<=#`DLY 1'b1;
end


always@(posedge Clk)
begin
  if(Write_cnt==3)
    begin
    if(!Wfull)
     Write_cnt<=#`DLY Write_cnt+1;
    end
  else if(current_state==WRITE)
    Write_cnt<=#`DLY Write_cnt+1;
  else 
    Write_cnt<=#`DLY 3'b0;
end

assign Temp={2'b0,Line_cnt[4:0],4'b0000}+{Line_cnt[4:0],1'b0}+Sfb_cnt;

always@(posedge Clk)
begin 
  if(Mode==3||current_state==FULL)
    Ram_addr<=#`DLY{3'b010,Temp};
  else    
    Ram_addr<=#`DLY{3'b011,Temp};
end

  

always@(posedge Clk)
begin
  if(Write_cnt==1||(Write_cnt==3&&!Wfull))
    Winc<=#`DLY 1'b1;
  else
    Winc<=#`DLY 1'b0;
end


//*************for test****************//
/*initial file=$fopen("pcm.txt");    

always@(posedge Clk)
begin
  if(Winc&&!Wfull&&Write_cnt==4)
    begin
    Data0=Data_reg; 
    $fdisplay(file,"%d",Data0);
    end
end

initial file0=$fopen("pcm0.txt");    

always@(posedge Clk)
begin
  if(Winc&&!Wfull&&Write_cnt==2)
    begin
    Data1=Data_reg; 
    $fdisplay(file0,"%d",Data1);
    end
end
 
 
//end test*/
    

endmodule
