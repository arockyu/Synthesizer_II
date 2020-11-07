/************************************************************************
* TM1638 Interface Unit
*
*************************************************************************
*
***************************************************************************
*  
*
****************************************************************************/

module TM1638_interface(
    input mclk,
    input rst,
    input [4:0] waddr,
    input fetch,
    input [7:0] wdata,
    input [4:0] raddr,
    output [7:0] rdata,
    output stb_out,
    output clk_out,
    output dio_oe,
    output dio_out,
    input dio_in,
    output busy,
    output [2:0] state);

    parameter master_clock = 16000000; //[Hz]
    parameter com_rate = 500000; //[bps]
    parameter sampling_cycle = 500; //[Hz]
    parameter com_start_width = 4'd10;

    localparam div_num_sample = master_clock/sampling_cycle - 1;
    localparam div_num_com = master_clock/com_rate - 1;

    //state
    localparam IDLE     = 3'b000;
    localparam MODEW    = 3'b001;
    localparam ADDRW    = 3'b010;
    localparam DISP     = 3'b011;
    localparam MODER    = 3'b100;



    //clock division
    wire clk_smp;

    wire clk_internal;

    divider D1(mclk,clk_smp);
    defparam D1.divide_num = div_num_sample;

    divider D2(mclk,clk_internal);
    defparam D2.divide_num = div_num_com;


    wire clk_smp_rise;

    edge_detector E1(
        .mclk(mclk),
        .signal(clk_smp),
        .pos(clk_smp_rise),
        .neg());
    defparam E1.sync_negegde = 1'b1;

    wire fetch_fall;
    edge_detector E2(
        .mclk(mclk),
        .signal(fetch),
        .pos(),
        .neg(fetch_fall));
    defparam E2.sync_negegde = 1'b1;

    wire rdata_valid;
    wire rdata_valid_fall;
    edge_detector E3(
        .mclk(mclk),
        .signal(rdata_valid),
        .pos(),
        .neg(rdata_valid_fall));
    defparam E3.sync_negegde = 1'b1;


    wire com_stop;
    wire com_stop_fall;
    edge_detector E4(
        .mclk(mclk),
        .signal(com_stop),
        .pos(),
        .neg(com_stop_fall));
    defparam E4.sync_negegde = 1'b1;



    reg [2:0] state = IDLE;
    reg [2:0] state_next;

    reg busy = 1'b0;


    reg frag_modew_start = 1'b0;
    reg frag_addrw_start = 1'b0;
    reg frag_moder_start = 1'b0;
    reg frag_disp_start = 1'b0;

    reg com_start = 1'b0;

    reg r_nw = 1'b1;
    reg [4:0] data_count = 5'd0;
    reg [7:0] cmd_addr= 8'h00;


    wire [4:0] data_addr;

    reg [3:0] com_start_counter = com_start_width;

    //////////////////////   FSM TM1638 Interface Periodic Control //////////////////////

    //Next State definition
    always @(*)begin
        state_next = state;
        if(rst) state_next = IDLE;
        case(state)
            IDLE :if(clk_smp_rise) state_next = MODEW;
            MODEW:if(com_stop_fall) state_next = ADDRW;
            ADDRW:if(com_stop_fall) state_next = DISP;
            DISP :if(com_stop_fall) state_next = MODER;
            MODER:if(com_stop_fall) state_next = IDLE;
            default:state_next = state; 
        endcase
    end

    //FSM driven by posedge of mclk
    always @(posedge mclk)begin

        //*************************  Reset condition
        if(rst)begin
            state <= IDLE;

            busy <= 1'b0;

            frag_modew_start <= 1'b0;
            frag_addrw_start <= 1'b0;
            frag_moder_start <= 1'b0;
            frag_disp_start <= 1'b0;

            com_start <= 1'b0; 

            r_nw = 1'b1;
            data_count = 5'd0;
            cmd_addr <= 8'h00;

            com_start_counter <= com_start_width;

        end else begin 

        //*************************  State Change
            state <= state_next;
            
        //*************************  state BOOT
            case(state)
                IDLE :
                    begin
                        busy <= 1'b0;
                        frag_modew_start <= 1'b0;
                        frag_addrw_start <= 1'b0;
                        frag_moder_start <= 1'b0;
                        frag_disp_start <= 1'b0;
                    
                    end 
                MODEW:
                    begin
                        busy <= 1'b1;
                        r_nw = 1'b0;
                        data_count = 5'd0;
                        cmd_addr <= 8'h40;         
                        if(!frag_modew_start)begin
                            frag_modew_start<=1'b1;
                            com_start <= 1'b1;
                            com_start_counter <= com_start_width;
                        end else begin
                            if(com_start_counter != 4'd0)com_start_counter <= com_start_counter - 1;
                            else com_start <= 1'b0;
                        end          
                    end 
                ADDRW:
                    begin
                        r_nw = 1'b0;
                        data_count = 5'd16;
                        cmd_addr <= 8'hC0;         
                        if(!frag_addrw_start)begin
                            frag_addrw_start<=1'b1;
                            com_start <= 1'b1;
                            com_start_counter <= com_start_width;
                        end else begin
                            if(com_start_counter != 4'd0)com_start_counter <= com_start_counter - 1;
                            else com_start <= 1'b0;
                        end          
                    end 
                DISP :
                    begin
                        r_nw = 1'b0;
                        data_count = 5'd0;
                        cmd_addr <= 8'h8F;         
                        if(!frag_disp_start)begin
                            frag_disp_start<=1'b1;
                            com_start <= 1'b1;
                            com_start_counter <= com_start_width;
                        end else begin
                            if(com_start_counter != 4'd0)com_start_counter <= com_start_counter - 1;
                            else com_start <= 1'b0;
                        end          
                    end
                MODER:
                    begin
                        r_nw = 1'b1;
                        data_count = 5'd4;
                        cmd_addr <= 8'h42;         
                        if(!frag_moder_start)begin
                            frag_moder_start<=1'b1;
                            com_start <= 1'b1;
                            com_start_counter <= com_start_width;
                        end else begin
                            if(com_start_counter != 4'd0)com_start_counter <= com_start_counter - 1;
                            else com_start <= 1'b0;
                        end          
                    end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////////////    


    //20 byte data registors
    wire [7:0] rxdata;

    reg [7:0] data_reg[19:0];

    initial begin
        data_reg[ 0]=8'h00;
        data_reg[ 1]=8'h00;
        data_reg[ 2]=8'h00;
        data_reg[ 3]=8'h00;
        data_reg[ 4]=8'h00;    
        data_reg[ 5]=8'h00;
        data_reg[ 6]=8'h00;
        data_reg[ 7]=8'h00;
        data_reg[ 8]=8'h00;
        data_reg[ 9]=8'h00;  
        data_reg[10]=8'h00;
        data_reg[11]=8'h00;
        data_reg[12]=8'h00;
        data_reg[13]=8'h00;
        data_reg[14]=8'h00;    
        data_reg[15]=8'h00;
        data_reg[16]=8'h00;   
        data_reg[17]=8'h00;
        data_reg[18]=8'h00;
        data_reg[19]=8'h00;
    end

    always @(posedge mclk)begin
        if(rst) begin
            data_reg[ 0] <= 8'h00;
            data_reg[ 1] <= 8'h00;
            data_reg[ 2] <= 8'h00;
            data_reg[ 3] <= 8'h00;
            data_reg[ 4] <= 8'h00;    
            data_reg[ 5] <= 8'h00;
            data_reg[ 6] <= 8'h00;
            data_reg[ 7] <= 8'h00;
            data_reg[ 8] <= 8'h00;
            data_reg[ 9] <= 8'h00;  
            data_reg[10] <= 8'h00;
            data_reg[11] <= 8'h00;
            data_reg[12] <= 8'h00;
            data_reg[13] <= 8'h00;
            data_reg[14] <= 8'h00;    
            data_reg[15] <= 8'h00;          
        end else begin
            if (fetch_fall) begin
                if( waddr >= 5'd0 && waddr <= 5'd15) data_reg[waddr] <= wdata;
            end
            if (rdata_valid_fall) data_reg[data_addr+16] <= rxdata;
        end
    end

    assign rdata = data_reg[raddr];
    

    // TM1638_Tranciever

    wire cmd_request;
    wire [7:0] txdata;
    assign txdata = (cmd_request) ? cmd_addr : data_reg[data_addr];

    TM1638_data_tranciever U101 (
        .mclk(mclk),
        .rst(rst),
        .clk_internal(clk_internal),
        .r_nw(r_nw),
        .cmd_request(cmd_request),
        .data_cnt(data_count),
        .data_addr(data_addr),
        .wdata(txdata),
        .rdata(rxdata),
        .rdata_valid(rdata_valid),
        .stb_out(stb_out),
        .clk_out(clk_out),
        .dio_out(dio_out),
        .dio_oe(dio_oe),
        .dio_in(dio_in),
        .com_start(com_start),
        .com_stop(com_stop),
        .state());


endmodule