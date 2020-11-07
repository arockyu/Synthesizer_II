/************************************************************************
* TM1368 Transmitter Unit
*
*************************************************************************
* input mclk        : Master 16MHz clock
***************************************************************************
*  
* 
*
****************************************************************************/

module TM1638_transmitter(
    input mclk,
    input rst,
    input clk_fall,
    output dio_out,
    input [7:0] wdata,
    input tx_start,
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

    //////////////////////   FSM TM1638 Transmittor //////////////////////

    //Next State definition
    always @(*)begin
        state_next = state; 
        if(rst)state_next = IDLE; 
        case(state)
            IDLE   :if(tx_start) state_next <= BYTE0;
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

    reg dio_out = 1'b1;
    reg flag_msb = 1'b0;    

    always @(posedge mclk)begin
        if (rst) begin
            state <= IDLE;

            dio_out <= 1'b1;
            flag_msb <= 1'b0; 
 
        end else begin
            //****************************** State Change
            state <= state_next;

            //****************************** Byte Transfer
 
            if (state == BYTE0) begin
                dio_out <= wdata[0]; 
                flag_msb  <= 1'b0;
            end else if (state == BYTE1) dio_out <= wdata[1];    
            else if (state == BYTE2) dio_out <= wdata[2];    
            else if (state == BYTE3) dio_out <= wdata[3];    
            else if (state == BYTE4) dio_out <= wdata[4];
            else if (state == BYTE5) dio_out <= wdata[5];    
            else if (state == BYTE6) dio_out <= wdata[6];    
            else if (state == BYTE7) begin
                dio_out <= wdata[7]; 
                flag_msb  <= 1'b1;
            end else if(state == IDLE)begin
                dio_out <= 1'b1;
                flag_msb  <= 1'b0;
            end

        end        
    end  

endmodule