/************************************************************************
* TM1638 Board I/F Unit
*
*************************************************************************

***************************************************************************
*  
* 
*
****************************************************************************/

module TM1638_board_interface_ex(
    input mclk,
    input rst,
    input [7:0] leds,
    input [39:0] led_7seg,
    input [7:0] led_7seg_en,
    input [7:0] led_7seg_dots,
    output [7:0] push_buttons,
    output busy,
    output stb_out,
    output clk_out,
    output dio_oe,
    output dio_out,
    input dio_in,   
    output [2:0] state);

    parameter sampling_cycle = 500;
    
    //State Definition

    localparam IDLE = 3'b000;
    localparam INIT = 3'b001;
    localparam DATA_READ = 3'b010;  
    localparam DATA_WRITE_S = 3'b011;
    localparam DATA_WRITE = 3'b100;
    

    //clock division
    wire clk_fetch;

    divider D1(mclk,clk_fetch);
    defparam D1.divide_num = 7;



    //edge_detection

    wire clk_fetch_rise;
    wire clk_fetch_fall;
    edge_detector E1(
        .mclk(mclk),
        .signal(clk_fetch),
        .pos(clk_fetch_rise),
        .neg(clk_fetch_fall));
    defparam E1.sync_negegde = 1'b1;

    wire busy_fall;
    edge_detector E2(
        .mclk(mclk),
        .signal(busy),
        .pos(),
        .neg(busy_fall));
    defparam E2.sync_negegde = 1'b1;

    //7seg decoder

    wire [6:0] pat7seg;
    wire [39:0] led_7seg_shifted = led_7seg >> bit_position;
    wire [4:0] hex = led_7seg_shifted[4:0];

    hexto7seg_ex U11(
        .oe(led_7seg_en[4'd7 - (write_count[3:0]>>1)]),
        .hex(hex),
        .pat7seg(pat7seg)
    );

    //////////////////////   FSM TM1638 Interface Periodic Control //////////////////////
    reg [2:0] state = INIT;
    reg [2:0] state_next;

    //Next State definition
    always @(*)begin
        state_next = state;
        if(rst) state_next = IDLE;
        case(state)
            IDLE        :if(busy_fall)      state_next = INIT;
            INIT        :if(clk_fetch_rise) state_next = DATA_READ;
            DATA_READ   :if(flag_read_fin)  state_next = DATA_WRITE_S;
            DATA_WRITE_S:if(clk_fetch_rise) state_next = DATA_WRITE;
            DATA_WRITE  :if(flag_write_fin) state_next = IDLE;
            default   :state_next = state; 
        endcase
    end

    //FSM driven by posedge of mclk

    reg [7:0] push_buttons = 8'h00;

    reg flag_write_fin = 1'b0;
    reg flag_read_fin = 1'b0;

    reg fetch_oe =1'b0;

    reg [4:0] write_count = 5'd0;
    reg [5:0] bit_position = 6'd35;
    reg [4:0] read_count  = 5'd0;

    reg [7:0] wdata = 8'h00;

    always @(posedge mclk)begin

        //*************************  Reset condition
        if(rst)begin
            state <= IDLE;

            push_buttons <=8'h00;

            flag_write_fin <= 1'b0;
            flag_read_fin <= 1'b0;

            fetch_oe <= 1'b0;
            
            write_count <= 5'd0;
            bit_position <= 6'd35;
            read_count  <= 5'd0;

            wdata <= 8'd0;

        end else begin 

        //*************************  State Change
            state <= state_next;
            
        //*************************  state BOOT
            case(state)
                IDLE :
                    begin
                        fetch_oe<=1'b0;
                        flag_write_fin <= 1'b0;
                        flag_read_fin <= 1'b0;
                        write_count <= 5'd0;
                        bit_position = 6'd35;
                        read_count  <= 5'd0;
                        
                    end
                INIT :
                    fetch_oe<=1'b0;

                DATA_READ :
                    begin
                        fetch_oe <=0;
                        if(clk_fetch_fall)begin
                            push_buttons[7-read_count] <= rdata[0];
                            push_buttons[3-read_count] <= rdata[4];
                            if(read_count == 5'd3) flag_read_fin <= 1'b1;
                        end
                        if(clk_fetch_rise)begin
                            if(read_count != 5'd3) read_count <= read_count +1;
                        end

                    end                    
                DATA_WRITE_S:
                    begin
                        fetch_oe <=1;
                        wdata <= 8'd0; 
                    end

                DATA_WRITE:
                    begin
                        
                        wdata <=    (write_count == 5'h0 ) ? {led_7seg_dots[7] ,pat7seg} :
                                    (write_count == 5'h2 ) ? {led_7seg_dots[6] ,pat7seg} :
                                    (write_count == 5'h4 ) ? {led_7seg_dots[5] ,pat7seg} :
                                    (write_count == 5'h6 ) ? {led_7seg_dots[4] ,pat7seg} :
                                    (write_count == 5'h8 ) ? {led_7seg_dots[3] ,pat7seg} :
                                    (write_count == 5'ha ) ? {led_7seg_dots[2] ,pat7seg} :
                                    (write_count == 5'hc ) ? {led_7seg_dots[1] ,pat7seg} :
                                    (write_count == 5'he ) ? {led_7seg_dots[0] ,pat7seg} :
                                    (write_count == 5'h1 ) ? {7'b0000000 , leds[7]} :
                                    (write_count == 5'h3 ) ? {7'b0000000 , leds[6]} :
                                    (write_count == 5'h5 ) ? {7'b0000000 , leds[5]} :
                                    (write_count == 5'h7 ) ? {7'b0000000 , leds[4]} :
                                    (write_count == 5'h9 ) ? {7'b0000000 , leds[3]} :
                                    (write_count == 5'hb ) ? {7'b0000000 , leds[2]} :
                                    (write_count == 5'hd ) ? {7'b0000000 , leds[1]} :
                                    (write_count == 5'hf ) ? {7'b0000000 , leds[0]} : 8'h00;

                        if(clk_fetch_rise)begin
                            if(write_count != 5'd15) begin
                                write_count <= write_count + 1;
                                if(write_count[0] & bit_position != 0)bit_position <= bit_position - 5;
                            end
                        end

                        if(clk_fetch_fall)begin
                            if(write_count == 5'd15) flag_write_fin <= 1'b1;
                        end
                    end

            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////////////// 

    wire fetch = fetch_oe & clk_fetch;
    wire [7:0] rdata;

    TM1638_interface U101(
        .mclk(mclk),
        .rst(rst),
        .waddr(write_count),
        .fetch(fetch),
        .wdata(wdata),
        .raddr(read_count+5'd16),
        .rdata(rdata),
        .stb_out(stb_out),
        .clk_out(clk_out),
        .dio_oe(dio_oe),
        .dio_out(dio_out),
        .dio_in(dio_in),
        .busy(busy),
        .state());
    defparam U101.sampling_cycle = sampling_cycle;
endmodule