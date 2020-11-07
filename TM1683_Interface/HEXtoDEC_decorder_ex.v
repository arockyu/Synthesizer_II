/************************************************************************
* 16-bit Hex to dec(signed 4 degit) decorde unit Extensin
*
*************************************************************************
* input mclk        : Master 16MHz clock

***************************************************************************
*    
*  
*
*
****************************************************************************/

//    HEXtoDEC_decorder_ex Inst_Name(
//        .mclk(),
//        .rst(),
//        .en(),
//        .Hex_data(),
//        .MSD_weight(),
//        .exp(),
//        .point(),
//        .dec_out(),
//        .sync(),
//        .state());
//    defparam Inst_Name.eff_degit = 4;


module HEXtoDEC_decorder_ex(
    input mclk,
    input rst,
    input en,
    input [15:0] Hex_data,
    input [14:0] MSD_weight,
    input signed [3:0] exp,
    output [7:0] point,
    output [39:0] dec_out,
    output sync,
    output [2:0] state);

    parameter eff_degit = 4;
    localparam digit_pos_init = (eff_degit-1)*5;
    localparam extra_degits = $clog2( 10**(eff_degit-1) ) + 1;

    //State definition
    localparam IDLE   = 3'b000;
    localparam INIT   = 3'b001;
    localparam STDIV1 = 3'b010;
    localparam STDIV2 = 3'b011;
    localparam FIN    = 3'b111;



    reg [2:0] state = IDLE;
    reg [2:0] next_state;

    //Next State definition
    always @(*)begin
        next_state = state;
        if(rst)next_state = IDLE;
        else begin
            case(state)
                IDLE:if(en)next_state = INIT;
                    
                INIT:next_state = STDIV1;
                STDIV1: 
                    begin
                        if(of) next_state = FIN;
                        else next_state = STDIV2;
                    end
                STDIV2:if(digit_count == 0 & sync2)next_state = FIN;
                FIN:next_state = IDLE;
                default:next_state = state;
            endcase
        end
    end

    wire [extra_degits-1:0] extra_zero = 0;

    reg [3:0] digit_count = eff_degit - 1;
    reg [6:0] digit_pos = digit_pos_init;

    reg signed [3:0] latched_exp = 4'd0;

    reg [14+extra_degits:0] latched_Hex_data =0;
    reg [14+extra_degits:0] latched_weight = 1;

    reg sign_bit = 1'b0;
    reg of = 1'b0;

    reg en1 = 1'b0;
    reg en2 = 1'b0;

    reg [39:0] decoded_out = 40'hfffff_fffff;
    reg [39:0] dec_out = 40'hfffff_fffff;
    reg [7:0] point = 8'h00;
    reg sync = 1'b0;

    wire [39:0] digit_mask = ~(40'h00000_0001f << digit_pos);

    //FSM driven by posedge of mclk
    always @(posedge mclk)begin
        if(rst)begin
            state <= IDLE;

            digit_count <= eff_degit - 1;
            digit_pos <= digit_pos_init;

            latched_exp <= 4'd0;
            latched_Hex_data <= {15'h0000,extra_zero};
            latched_weight <= {15'h0001,extra_zero};

            sign_bit <= 1'b0;
            of <= 1'b0;
            en1 <= 1'b0;
            en2 <= 1'b0;      

            decoded_out <= 40'hfffff_fffff;

            dec_out <= 40'hfffff_fffff;
            point <= 8'hff;
            sync <= 1'b0;

        end else begin
            //****************************** State Change
            state <= next_state;

            case(state)
            //*************************  state IDLE
                IDLE:
                    begin

                            digit_count <= eff_degit - 1;;
                            digit_pos <= digit_pos_init;

                            latched_exp <= exp;
                            latched_Hex_data <= {Hex_data[14:0],extra_zero};
                            latched_weight <= {MSD_weight,extra_zero};

                            sign_bit <= 1'b0;
                            of <= 1'b0;
                            en1 <= 1'b0;
                            en2 <= 1'b0;


                            decoded_out <= 40'hfffff_fffff;
                            sync <= 1'b0;
                    end
            //*************************  state INIT
                INIT:
                    begin
                        if(Hex_data == 16'h7fff)begin
                            of <= 1'b1;
                            decoded_out[4:0] <= 5'h13;
                            decoded_out[9:5] <= 5'h12;
                            point <= 8'h03;
                        end else if(Hex_data == 16'h8000)begin
                            of <= 1'b1;
                            sign_bit <= 1'b1;
                            decoded_out[4:0] <= 5'h13;
                            decoded_out[9:5] <= 5'h12;      
                            decoded_out[14:10] <= 5'h11;   
                            point <= 8'h03;
                        end else begin 
                        
                            if(Hex_data[15])begin
                                sign_bit <= 1'b1;
                                latched_Hex_data <=  { (~Hex_data[14:0] + 15'd1) , extra_zero };
                            end else latched_Hex_data <= { Hex_data[14:0] , extra_zero };
                            
                            if(exp == -1)begin
                                if(Hex_data[15])decoded_out[digit_pos_init + 14 :digit_pos_init + 10] <= 5'h11; 
                                decoded_out[digit_pos_init +9: digit_pos_init +5] <= 5'h00; 
                                point = 8'h10;
                            end else if(exp >= 0)begin
                                if(Hex_data[15])decoded_out[digit_pos_init + 9 :digit_pos_init + 5] <= 5'h11; 
                            end
                            digit_count <= eff_degit - 1;
                            digit_pos <= digit_pos_init;

                            latched_exp <= exp;
                            latched_weight <= {MSD_weight,extra_zero};

                            sync <= 1'b0;
                            en1 <= 1'b0;
                            en2 <= 1'b0;

                        end
                    end
            //*************************  state  STDIV1
                STDIV1:
                    begin
                        en1 <= 1'b1;
                    end
            //*************************  state STDIV2
                STDIV2:
                    begin
                        if(!en2) en2 <= 1'b1;
                        else begin

                            if(sync1)begin
                                latched_weight <= Quo1;
                                en1 <= 1'b0;
                            end else ;

                            if(sync2)begin
                                if(latched_exp == 0)point <= 8'h01 << digit_count;
                                else;
                                decoded_out <= decoded_out & ( digit_mask | ({36'h000000000,Quo2[3:0]} << digit_pos)); 

                                digit_count <= digit_count -1;
                                digit_pos <= digit_pos -5;
                                
                                latched_exp <= latched_exp - 1;
                                latched_Hex_data <= Rem2;

                                en1 <= 1'b1;
                                en2 <= 1'b0;
                            end else;

                        end
                    end
            //*************************  state FIN
                FIN:
                    begin
                        sync <= 1'b1;
                        en1 <= 1'b0;
                        en2 <= 1'b0;

                        dec_out <= decoded_out;
                    end
                default:;
            endcase
        end
    end 

    wire [14+extra_degits:0] Quo1;
    wire [14+extra_degits:0] Rem1;   
    wire sync1;


    //deviders;
    AL_Divider DIV1(
        .mclk(mclk),
        .rst(rst),
        .en(en1),
        .Dividend(latched_weight),
        .Divisor({extra_zero,15'd10}),
        .Quotient(Quo1),
        .Remainder(Rem1),
        .zero_divide(),
        .sync(sync1));
    defparam DIV1.N  = 15 + extra_degits;



    wire [14+extra_degits:0] Quo2;
    wire [14+extra_degits:0] Rem2;   
    wire sync2;

    AL_Divider DIV2(
        .mclk(mclk),
        .rst(rst),
        .en(en2),
        .Dividend(latched_Hex_data),
        .Divisor(latched_weight),
        .Quotient(Quo2),
        .Remainder(Rem2),
        .zero_divide(),
        .sync(sync2));
    defparam DIV2.N  = 15 + extra_degits;


    //
    wire [4:0] deg0 = decoded_out[ 4: 0];
    wire [4:0] deg1 = decoded_out[ 9: 5];
    wire [4:0] deg2 = decoded_out[14:10];
    wire [4:0] deg3 = decoded_out[19:15];
    wire [4:0] deg4 = decoded_out[24:20];
    wire [4:0] deg5 = decoded_out[29:25];
    wire [4:0] deg6 = decoded_out[34:30];
    wire [4:0] deg7 = decoded_out[35:29];


endmodule