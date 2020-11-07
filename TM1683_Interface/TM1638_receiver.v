/************************************************************************
* TM1368 Receiver(Rx) Unit
*
*************************************************************************
* input mclk        : Master 16MHz clock

***************************************************************************
*  
* 
*
****************************************************************************/

module TM1368_receiver(
    input mclk,
    input rst,
    input clk_fall,
    input clk_rise,
    input dio_in,
    output [7:0] rdata,
    input rx_start,
    output flag_msb);

    localparam IDLE  = 4'b1000;
    localparam BYTE0 = 4'b0000;
    localparam BYTE1 = 4'b0001;
    localparam BYTE2 = 4'b0010;
    localparam BYTE3 = 4'b0011;
    localparam BYTE4 = 4'b0100;
    localparam BYTE5 = 4'b0101; 
    localparam BYTE6 = 4'b0110;
    localparam BYTE7 = 4'b0111;

    //state
    reg [3:0] state = IDLE;
    reg [3:0] state_next;

    //////////////////////   FSM TM1638 Recirever //////////////////////

    //Next State definition
    always @(*)begin
        state_next = state; 
        if(rst)state_next = IDLE; 
        case(state)
            IDLE   :if(rx_start) state_next = BYTE0;
            BYTE0  :if(clk_fall) state_next = BYTE1;
            BYTE1  :if(clk_fall) state_next = BYTE2;
            BYTE2  :if(clk_fall) state_next = BYTE3; 
            BYTE3  :if(clk_fall) state_next = BYTE4; 
            BYTE4  :if(clk_fall) state_next = BYTE5; 
            BYTE5  :if(clk_fall) state_next = BYTE6; 
            BYTE6  :if(clk_fall) state_next = BYTE7; 
            BYTE7  :if(clk_fall) state_next = IDLE; 
            default:state_next = state; 
        endcase

    end

    //FSM driven by posedge of mclk  
    reg [7:0] rdata = 1'b0;  
    reg flag_msb = 1'b0;  

    always @(posedge mclk)begin
        if(rst)begin
            state <= IDLE;
            flag_msb  <= 1'b0;       
            rdata <= 8'h00;
            
        end else begin
            //****************************** State Change 
            state <= state_next;

            //****************************** Byte Receive
            if(clk_rise) begin
                if      (state == BYTE0 ) rdata[0] <= dio_in; 
                else if (state == BYTE1 ) rdata[1] <= dio_in;    
                else if (state == BYTE2 ) rdata[2] <= dio_in;   
                else if (state == BYTE3 ) rdata[3] <= dio_in;   
                else if (state == BYTE4 ) rdata[4] <= dio_in; 
                else if (state == BYTE5 ) rdata[5] <= dio_in;    
                else if (state == BYTE6 ) rdata[6] <= dio_in;     
                else if (state == BYTE7 ) rdata[7] <= dio_in; 
                else;
            end else if(state == BYTE0) flag_msb  <= 1'b0;
            else if (state == BYTE7) flag_msb  <= 1'b1;
            else if(state == IDLE) flag_msb  <= 1'b0;

        end   
    end 

endmodule