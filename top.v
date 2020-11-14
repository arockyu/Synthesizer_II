`define VIOLIN  // SIN_WAVE , TRUMPET , VIOLIN , CLARINET , ORGAN


// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    
    output LED,    // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor

    // Reset(Active-Low)
    input nRST,


    //PLL
    output PLL_LOCK, // Pin4


    //PWM Signal Output
    output PWM0,
    output PWM1,

    //TM1638 I/O Interface
    output STB_TM, // Pin24 
    output CLK_TM,  // Pin23 
    inout DIO_TM  // Pin23 

);
    
    // drive USB pull-up resistor to '0' to disable USB comunication
    assign USBPU = 0;

    // set the on board LED continious on to indicate user program mode
    assign LED = 1;

    parameter DATA_INIT = 16'd440;
    parameter DATA_MIN  = 16'd20;
    parameter DATA_MAX  = 16'd9999;

    wire dio_in;
    wire dio_oe;
    wire dio_out;

    wire [7:0] push_button;
    wire [39:0] reg7seg;
    reg [3:0] leds_point = 4'h01 ;
    wire [7:0] reg7segdots;
    reg out_enable = 1'b0;
    reg [3:0] RAM_sel = 4'd0;
    wire reconfig = (|push_button[3:0]) | (|push_button[7:6]) ;

    //wire clk64m;
    wire clk128m;
    wire pll_out;
    wire lock;

    pll128m PLL1(.REFERENCECLK(CLK),
                .PLLOUTCORE(),
                .PLLOUTGLOBAL(pll_out),
                .RESET(nRST),
                .LOCK(lock));

    SB_GB GBUF1 (
        .USER_SIGNAL_TO_GLOBAL_BUFFER (pll_out),
        .GLOBAL_BUFFER_OUTPUT (clk128m));

    assign PLL_LOCK = lock;

    wire busy;

    TM1638_board_interface_ex U101(
        .mclk(CLK),
        .rst(!nRST),
        .leds({out_enable,reconfig,lock,1'b0,leds_point}),
        .led_7seg(reg7seg),
        .led_7seg_en(8'hff),
        .led_7seg_dots(reg7segdots),
        .push_buttons(push_button),
        .busy(busy),
        .stb_out(STB_TM),
        .clk_out(CLK_TM),
        .dio_oe(dio_oe),
        .dio_out(dio_out),
        .dio_in(dio_in),   
        .state());

    BUS_interface U102(
        .bus_pack(DIO_TM),  
        .bus_out(dio_out),
        .bus_oe(dio_oe),
        .bus_in(dio_in));

    reg [15:0] data_reg = DATA_INIT;

    wire reconfig_rise,reconfig_fall;

    edge_detector E1(CLK,reconfig,reconfig_rise,reconfig_fall);
    defparam E1.sync_negegde = 1'b0;

    always @(posedge CLK)begin
        if(!nRST)begin
            data_reg <= DATA_INIT;
            RAM_sel <= 4'd0;
            leds_point <= 4'h01;
            out_enable <= 1'b0;
        end else if(reconfig_rise) begin
            if (push_button[0]) begin
                if(leds_point != 4'h01 ) leds_point <=  leds_point >> 1;
                else;
            end
            else if (push_button[1])begin 
                if(leds_point != 4'h8 ) leds_point <=  leds_point << 1;
                else;
            end
            else if (push_button[2])begin
                case(leds_point)
                    4'h01:if(data_reg <= DATA_MAX - 16'd1    ) data_reg <= data_reg + 16'd1;
                    4'h02:if(data_reg <= DATA_MAX - 16'd10   ) data_reg <= data_reg + 16'd10;
                    4'h04:if(data_reg <= DATA_MAX - 16'd100  ) data_reg <= data_reg + 16'd100;
                    4'h08:if(data_reg <= DATA_MAX - 16'd1000 ) data_reg <= data_reg + 16'd1000;
                    //5'h10:if(data_reg <= DATA_MAX - 16'd10000) data_reg <= data_reg + 16'd10000;
                endcase
            end
            else if (push_button[3]) begin
                case(leds_point)
                    4'h01:if(data_reg >= DATA_MIN + 16'd1    ) data_reg <= data_reg - 16'd1;
                    4'h02:if(data_reg >= DATA_MIN + 16'd10   ) data_reg <= data_reg - 16'd10;
                    4'h04:if(data_reg >= DATA_MIN + 16'd100  ) data_reg <= data_reg - 16'd100;
                    4'h08:if(data_reg >= DATA_MIN + 16'd1000 ) data_reg <= data_reg - 16'd1000;
                    //5'h10:if(data_reg >= DATA_MIN + 16'd10000) data_reg <= data_reg - 16'd10000;
                endcase
            end else if (push_button[6]) begin
                if(RAM_sel == 4'd4) RAM_sel <= 4'd0;
                else RAM_sel <= RAM_sel + 4'd1;
            end else if (push_button[7]) out_enable <= !out_enable;
        end else;
    end
    
    wire sync;
    wire [2:0] U105_state;
    wire busy_rise,busy_fall;

    edge_detector E2(CLK,busy,busy_rise,busy_fall);
    defparam E2.sync_negegde = 1'b1;


    HEXtoDEC_decorder_ex U105(
        .mclk(CLK),
        .rst(!nRST),
        .en(busy_fall),
        .Hex_data(data_reg),
        .MSD_weight(15'd1000),
        .exp(4'd3),
        .point(reg7segdots),
        .dec_out(reg7seg),
        .sync(sync),
        .state(U105_state));        
    defparam U105.eff_degit = 4;

    wire [31:0] quo;
    wire sync_div;
    AL_Divider U106(
        .mclk(CLK),
        .rst(!nRST),
        .en(!busy),
        .Dividend(32'd250000),
        .Divisor({16'h0000,data_reg}),
        .Quotient(quo),
        .Remainder(),
        .zero_divide(),
        .sync(sync_div));
    defparam U106.N = 32;

    
    reg [15:0] div_num = 16'd125;
    always @(negedge sync_div) begin
        if(!nRST)begin
            div_num <= 16'd125;
        end else begin
            div_num <= quo[15:0]; //- 16'd1;
        end
    end

    wire clk0;
    divider_variable D0(
        .clk(clk128m),
        .rst(!nRST),
        .out(clk0),
        .div_num(div_num));
    defparam D0.N = 16;

    reg [8:0] addr0 = 9'h000;

    always @(posedge clk0) begin
        if(!nRST)begin
            addr0 <= 9'h000;
        end else begin
            addr0 <= addr0 +1;
        end
    end

    wire [15:0] rdata0;
    RAM_512x16_sin M0(
        .ram_addr(addr0),
        .ram_wdata(16'h0000),
        .ram_rdata(rdata0),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));     

    wire [15:0] rdata1;
    RAM_512x16_trum M1(
        .ram_addr(addr0),
        .ram_wdata(16'h0000),
        .ram_rdata(rdata1),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));

    wire [15:0] rdata2;
    RAM_512x16_violin M2(
        .ram_addr(addr0),
        .ram_wdata(16'h0000),
        .ram_rdata(rdata2),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));

    wire [15:0] rdata3;
    RAM_512x16_clarinet M3(
        .ram_addr(addr0),
        .ram_wdata(16'h0000),
        .ram_rdata(rdata3),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));

    wire [15:0] rdata4;
    RAM_512x16_organ M4(
        .ram_addr(addr0),
        .ram_wdata(16'h0000),
        .ram_rdata(rdata4),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));


    wire [15:0] rdata_l =   (RAM_sel == 4'd0) ? rdata0 :
                            (RAM_sel == 4'd1) ? rdata1 :
                            (RAM_sel == 4'd2) ? rdata2 :
                            (RAM_sel == 4'd3) ? rdata3 : 
                            (RAM_sel == 4'd4) ? rdata4 : rdata0;

    PWM_generator P0(
        .clk(clk128m),
        .d_in(out_enable ? rdata_l[15:6] : 10'h1ff),
        .pwm_out(PWM0) );
        defparam P0.res = 10;              
        defparam P0.chn = 1;  
        defparam P0.fclkm = 128000000;     //Frequency of master clock input(default :16MHZ)
        defparam P0.fs =125000;            //Sample/sec (default:10kHz)


    // divider D1(
    //     .clk(clk128m),
    //     .out(PWM1));
    // defparam D1.divide_num=12799;// N : Div parameter N+1 Divide
    assign PWM1 = clk0;

    // PWM_generator　P1(
    //     .clk(clk128m)
    //     .d_in(),
    //     .pwm_out(PWM1) );
    //     defpram P1.res = 8;              
    //     defpram P1.chn = 1;  
    //     defpram P1.fclkm = 128000000;     //Frequency of master clock input(default :16MHZ)
    //     defpram P1.fs =44100;            //Sample/sec (default:10kHz)

endmodule

