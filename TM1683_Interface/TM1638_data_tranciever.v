/************************************************************************
* TM1638 DATA Tranciever Unit
*
*************************************************************************

***************************************************************************
*  
* 
*
****************************************************************************/

module TM1638_data_tranciever(
    input mclk,
    input rst,
    input clk_internal,
    input r_nw,
    output cmd_request,
    input [4:0] data_cnt,
    output [4:0]data_addr,
    input [7:0] wdata,
    output [7:0] rdata,
    output rdata_valid,
    output stb_out,
    output clk_out,
    output dio_out,
    output dio_oe,
    input dio_in,
    input com_start,
    output com_stop,
    output [3:0] state);

    //State Definition
    localparam READY    = 4'b0000;
    localparam START    = 4'b0001;  
    localparam WSTB     = 4'b0010;
    localparam TxCOM    = 4'b0011;
    localparam TxCOMW   = 4'b0100;
    localparam TxDATA   = 4'b0101;
    localparam TxDATAW  = 4'b0110;
    localparam RxWAIT   = 4'b0111;
    localparam RxDATA   = 4'b1000;
    localparam RxDATAW  = 4'b1001;
    localparam STOP0    = 4'b1010;
    localparam STOP1    = 4'b1011;
    localparam STOP2    = 4'b1100;


    reg [3:0] state = READY;
    reg [3:0] state_next;

    wire clk_rise;
    wire clk_fall;

    edge_detector E1(
        .mclk(mclk),
        .signal(clk_internal),
        .pos(clk_rise),
        .neg(clk_fall));
    defparam E1.sync_negegde = 1'b1;

    wire flag_msb_tx;
    wire flag_msb_tx_fall;

    edge_detector E2(
        .mclk(mclk),
        .signal(flag_msb_tx),
        .pos(),
        .neg(flag_msb_tx_fall));
    defparam E2.sync_negegde = 1'b1;

    wire flag_msb_rx;
    wire flag_msb_rx_fall;

    edge_detector E3(
        .mclk(mclk),
        .signal(flag_msb_rx),
        .pos(),
        .neg(flag_msb_rx_fall));
    defparam E3.sync_negegde = 1'b1;



    //////////////////////   FSM TM1638 Tranciever //////////////////////

    //Next State definition
    always @(*)begin
        state_next = state;
        if(rst)state_next = READY;
        case(state)
            READY  :if(com_start) state_next = START;
            START  :if(clk_fall) state_next = WSTB;
            WSTB   :if(clk_fall) state_next = TxCOM;
            TxCOM  :if(clk_fall) state_next = TxCOMW;
            TxCOMW :
                if(flag_msb_tx_fall) begin
                    if (latched_data_cnt == 5'd0) state_next = STOP0; 
                    else if(latched_r_nw) state_next = RxWAIT;
                    else state_next = TxDATA;
                end else;
            TxDATA :if(clk_fall) state_next = TxDATAW;
            TxDATAW:
                if(flag_msb_tx_fall )begin
                    if(latched_data_cnt!= 5'd0)state_next = TxDATA;
                    else state_next = STOP0;
                end
            RxWAIT :
                if(clk_fall) state_next = RxDATA; 
            RxDATA : if(clk_fall) state_next = RxDATAW;   
            RxDATAW:
                if(flag_msb_rx_fall)begin
                    if(latched_data_cnt!= 5'd0)state_next = RxDATA;
                    else state_next = STOP0;
                end
            STOP0  :if(clk_fall)state_next = STOP1;
            STOP1  :if(clk_fall)state_next = STOP2;
            STOP2  :if(clk_fall)state_next = READY;            
            default :state_next = state;

        endcase
    end

 
   
   //FSM driven by posedge of mclk
    reg [4:0] data_addr =5'd0;
    reg stb_out = 1'b1;
    reg clk_oe = 1'b0;
    reg dio_oe = 1'b0;
    reg com_stop = 1'b0;
    reg latched_r_nw = 1'b0;
    reg [4:0] latched_data_cnt =5'd0;
    reg [4:0] latched_data_cnt_const =5'd0;
    reg [7:0] latched_wdata = 8'h00;
    reg [7:0] rdata = 8'h00;    
    reg rdata_valid = 1'b0;
    reg tx_start = 1'b0;
    reg rx_start = 1'b0;
    reg cmd_request = 1'b1;
    
    always @(posedge mclk)begin
        //*************************  Reset condition
        if(rst)begin
            state <= READY;

            stb_out <= 1'b1;
            clk_oe <= 1'b0;
            dio_oe <= 1'b0;
            com_stop <= 1'b0;
            latched_wdata <= 8'h00;
            latched_r_nw <= r_nw;
            latched_data_cnt <=5'd0;
            latched_data_cnt_const <=5'd0;
            rdata <= 8'h00;
            rdata_valid <= 1'b0;
            data_addr <=5'd0;
            tx_start <= 1'b0;
            rx_start <= 1'b0;
            cmd_request <= 1'b1;

        end else begin 
            //*************************  State Change
            state <= state_next;
             
            //*************************  state READY
            if(state == READY)begin
                com_stop<= 1'b0;
                clk_oe <= 1'b0;
                data_addr <=5'd0;
                cmd_request <= 1'b1;

            //*************************  state START
            end else if(state == START) begin         
                latched_r_nw <= r_nw;
                latched_data_cnt <= data_cnt;
                latched_data_cnt_const <= data_cnt;
                stb_out <= 1'b0; 

            //*************************  state WSTB
            end else if(state == WSTB) begin
                data_addr <=5'd0;
                

            //*************************  state TxCOM
            end else if(state == TxCOM) begin
                latched_wdata <= wdata;
                clk_oe <= 1'b1;
                tx_start <= 1'b1;
                dio_oe <= 1'b1;

            //*************************  state TxCOMW
            end else if(state == TxCOMW) begin
                tx_start <= 1'b0;
                cmd_request <= 1'b0;
                if(flag_msb_tx & clk_rise) begin
                    if(latched_data_cnt == 5'd0) clk_oe <= 1'b0;
                    else if(r_nw) begin
                        dio_oe <= 1'b0;
                        clk_oe <= 1'b0;
                    end
                end

            //*************************  state TxDATA    
            end else if(state == TxDATA) begin
                tx_start <= 1'b1;
                latched_wdata <= wdata;
                
                if(clk_rise) latched_data_cnt <= latched_data_cnt -1;

                

            //*************************  state TxDATAW    
            end else if(state == TxDATAW) begin
                tx_start <= 1'b0;
                if(flag_msb_tx & clk_rise )begin
                    if(latched_data_cnt != 5'd0)data_addr<=data_addr+1;
                    else begin
                         clk_oe <= 1'b0;
                         dio_oe <= 1'b0;
                    end
                end else;
                    
            //*************************  state RxWAIT 
            end else if(state == RxWAIT) begin
                cmd_request <= 1'b0;
                //Wait 1 clk cycle

            //*************************  state RxDATA 
            end else if(state == RxDATA) begin
                rdata_valid <= 1'b0;
                rx_start <= 1'b1;
                if(clk_rise) latched_data_cnt <= latched_data_cnt - 1;
                clk_oe <= 1'b1;
                

            //*************************  state RxDATAW
            end else if(state == RxDATAW) begin
                rx_start <= 1'b0;
                rdata <= rdata_rx;
                data_addr <= latched_data_cnt_const - latched_data_cnt - 1;
                if(flag_msb_rx & clk_rise ) begin
                    rdata_valid <= 1'b1;
                    if(latched_data_cnt == 5'd0) clk_oe <= 1'b0;
                end else;
                    
            //*************************  state STOP0
            end else if(state == STOP0) begin
                dio_oe <= 1'b0;
                rdata_valid <= 1'b0;
                //Wait harf clk cycle


            //*************************  state STOP1
            end else if(state == STOP1) begin
                stb_out <= 1'b1; 

            //*************************  state STOP2
            end else if(state == STOP2) begin
               com_stop<= 1'b1;
            end

        end

    end

    ////////////////////////////////////////////////////////////////////////////////


    //  trancemitter unit instance

    TM1638_transmitter U101(
        .mclk(mclk),
        .rst(rst),
        .clk_fall(clk_fall),
        .dio_out(dio_out),
        .wdata(latched_wdata),
        .tx_start(tx_start),
        .flag_msb(flag_msb_tx));


    //  receiver unit instance
    wire [7:0] rdata_rx;

    TM1368_receiver U102(
        .mclk(mclk),
        .rst(rst),
        .clk_fall(clk_fall),
        .clk_rise(clk_rise),
        .dio_in(dio_in),
        .rdata(rdata_rx),
        .rx_start(rx_start),
        .flag_msb(flag_msb_rx));

    //  clk output buffer
    assign clk_out =clk_oe?clk_internal:1'b1;

endmodule