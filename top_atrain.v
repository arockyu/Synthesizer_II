// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input   CLK,    // 16MHz clock
    
    output  LED,    // User/boot LED next to power LED
    output  USBPU,  // USB pull-up resistor

    //debug I/O prots
    output OUT1, //Pin11 ->OUT
    output OUT2, //Pin6 ->OUT
    output OUT3, //PIin7 ->OUT
    output OUT4, //Pin8 ->OUT
    output OUT5, //Pin9 ->OUT
    output OUT6, //Pin10 ->OUT
    input   nRST,  // Pin12-> IN

    //PWM Signal Output
    output  PWM_OUT,  // Pin13-> OUT

);
    // drive USB pull-up resistor to '0' to disable USB comunication
    assign USBPU = 0;

    // set the on board LED continious on to indicate user program mode
    assign LED = 1;

    // parameter tone_A4 = 11'd567; //A4
    // parameter tone_B4 = 11'd505; //B4
    // parameter tone_C4 = 11'd477; //C4
    // parameter tone_D4 = 11'd425; //D4
    // parameter tone_E4 = 11'd378; //E4
    // parameter tone_F4 = 11'd357; //F4
    // parameter tone_G4 = 11'd318; //G4
    // parameter tone_A5 = 11'd283; //A5 

    parameter tone_F1  = 11'd1275; //F1
    parameter tone_F1S = 11'd1203; //F#1
    parameter tone_G1  = 11'd1035; //G1
    parameter tone_G1S = 11'd1072; //G#1
    parameter tone_A2  = 11'd1011; //A2
    parameter tone_B2  = 11'd955; //B2
    parameter tone_C2  = 11'd901; //C2
    parameter tone_C2S = 11'd850; //C#2    
    parameter tone_D2  = 11'd803; //D2
    parameter tone_D2S = 11'd757; //D#2    
    parameter tone_E2  = 11'd715; //E2

    parameter tone_F2  = 11'd675; //F2
    parameter tone_F2S = 11'd637; //F#2
    parameter tone_G2  = 11'd601; //G2
    parameter tone_G2S = 11'd567; //G#2
    parameter tone_A3  = 11'd535; //A3
    parameter tone_B3  = 11'd505; //B3
    parameter tone_C3  = 11'd477; //C3
    parameter tone_C3S = 11'd450; //C#3    
    parameter tone_D3  = 11'd425; //D3
    parameter tone_D3S = 11'd401; //D#3    
    parameter tone_E3  = 11'd378; //E3
    parameter tone_F3  = 11'd357; //F3
    parameter tone_F3S = 11'd337; //F#3
    parameter tone_G3  = 11'd318; //G3
    parameter tone_G3S = 11'd300; //G#3
    parameter tone_A4  = 11'd283; //A4
    parameter tone_A4S = 11'd267; //A#4
    parameter tone_B4  = 11'd252; //B4
    parameter tone_C4  = 11'd238; //C4
    parameter tone_C4S = 11'd224; //C#4    
    parameter tone_D4  = 11'd212; //D4
    parameter tone_D4S = 11'd200; //D#4    
    parameter tone_E4  = 11'd189; //E4
    parameter tone_F4  = 11'd178; //F4
    parameter tone_F4S = 11'd168; //F#4
    parameter tone_G4  = 11'd158; //G4
    parameter tone_G4S = 11'd149; //G#4
    parameter tone_A5  = 11'd141; //A5 
    parameter tone_A5S = 11'd133; //A#5 
    parameter tone_B5  = 11'd126; //B5 
    parameter tone_C5  = 11'd118; //C5
    parameter tone_C5S = 11'd112; //C#5
    parameter tone_D5  = 11'd105; //D5
    parameter tone_D5S = 11'd99; //D#5
    parameter tone_E5  = 11'd94; //E5

    reg [8:0] addr0 = 9'h000;
    reg [8:0] addr1 = 9'h000;

    reg [15:0] wdata = 16'h0000;

    wire [15:0] rdata0 ;
    wire [15:0] rdata1 ;

    wire clk64m_a;
    wire clk64m_b;
    wire clk64m_ga;
    wire clk64m_gb;

    wire clk0;
    wire clk1;

    wire clk_low;
    wire clk_chk;

    wire [15:0] silent = 16'h7FFF;

    reg  OE0 = 1'b0;
    reg  OE1 = 1'b0;

    wire  [15:0] data_out0 =  ((OE0 ? rdata0  : silent) );
    wire  [15:0] data_out1 =  ((OE1 ? rdata1  : silent) )>>4; 
    // wire signed [15:0] data_out_sig = (data_out0>>5) + (data_out1>>6);
    // wire [15:0] data_out  =  data_out_sig  + silent;        

    reg [10:0] div_num0 = tone_A4;
    reg [10:0] div_num1 = tone_A2;

    RAM_512x16_3 M0(
        .ram_addr(addr0),
        .ram_wdata(wdata),
        .ram_rdata(rdata0),
        .ce(1'b1),
        .clk(clk0),
        .we(1'b0),
        .re(1'b1));

    RAM_512x16 M1(
        .ram_addr(addr1),
        .ram_wdata(wdata),
        .ram_rdata(rdata1),
        .ce(1'b1),
        .clk(clk1),
        .we(1'b0),
        .re(1'b1));

    PWM_generator U0(
        .clk(clk64m_a),
        .d_in(data_out0[15:7]),
        //.d_in(11'h3ff),
        .pwm_out(OUT1) );
    defparam U0.fclkm = 64000000;
    defparam U0.fs = 44100;
    defparam U0.res = 9;

    PWM_generator U1(
        .clk(clk64m_a),
        .d_in(data_out1[15:7]),
        //.d_in(11'h3ff),
        .pwm_out(PWM_OUT) );
    defparam U1.fclkm = 64000000;
    defparam U1.fs = 44100;
    defparam U1.res = 9;


    PLL64m U10( .REFERENCECLK(CLK),
                .PLLOUTCOREA(clk64m_a),
                .PLLOUTCOREB(clk64m_b),
                .PLLOUTGLOBALA(clk64m_ga),
                .PLLOUTGLOBALB(clk64m_gb),
                .RESET(1'b1),
                .LOCK(OUT6));

    divider_variable D0(
        .clk(clk64m_a),
        .out(clk0),
        .div_num(div_num0));

    divider_variable D1(
        .clk(clk64m_a),
        .out(clk1),
        .div_num(div_num1));

    // divider D11(clk128m_b,clk_chk);
    // defparam D11.divide_num=63999999;
   
    divider D12(CLK,clk_low);
    defparam D12.divide_num=1142856; //12Hz

    always @(negedge clk0)begin
        addr0 <= addr0 + 1;
    end

    always @(negedge clk1)begin
        addr1 <= addr1 + 1;
    end

    reg [15:0] count = 16'd760;



    // Take The 'A' Train lead part

    always @(posedge clk_low,negedge nRST)begin
        if(~nRST)begin
            count <= 16'd0;
            OE0 <= 1'b0;
            div_num0 <= tone_C4;
        end
        else if(count != 16'd760) begin
            count <= count +1;
            case(count)
                16'd1   : {OE0,div_num0} <= {1'b1,tone_G4};
                16'd27  : {OE0,div_num0} <= {1'b0,tone_G4};         
                16'd29  : {OE0,div_num0} <= {1'b1,tone_E5};  
                16'd36  : {OE0,div_num0} <= {1'b0,tone_E5};  
                16'd37  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd42  : {OE0,div_num0} <= {1'b0,tone_G4};       
                16'd43  : {OE0,div_num0} <= {1'b1,tone_C5};    
                16'd48  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd49  : {OE0,div_num0} <= {1'b1,tone_E5}; 
                16'd53  : {OE0,div_num0} <= {1'b1,tone_G4S};    
                16'd93  : {OE0,div_num0} <= {1'b0,tone_G4S}; 

                16'd97  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd120 : {OE0,div_num0} <= {1'b0,tone_A5}; 

                16'd121  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd125  : {OE0,div_num0} <= {1'b1,tone_A5S};    
                16'd127  : {OE0,div_num0} <= {1'b1,tone_B5}; 
                16'd131  : {OE0,div_num0} <= {1'b1,tone_E5};        
                16'd133  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd137  : {OE0,div_num0} <= {1'b1,tone_F4S};       
                16'd139  : {OE0,div_num0} <= {1'b1,tone_F4};     
                16'd143  : {OE0,div_num0} <= {1'b1,tone_C5S}; 

                16'd145  : {OE0,div_num0} <= {1'b1,tone_C5};     
                16'd149  : {OE0,div_num0} <= {1'b1,tone_E4}; 
                16'd189  : {OE0,div_num0} <= {1'b0,tone_E4}; 

                16'd193  : {OE0,div_num0} <= {1'b1,tone_G4};
                16'd219  : {OE0,div_num0} <= {1'b0,tone_G4};         
                16'd221  : {OE0,div_num0} <= {1'b1,tone_E5};  
                16'd228  : {OE0,div_num0} <= {1'b0,tone_E5};  
                16'd229  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd234  : {OE0,div_num0} <= {1'b0,tone_G4};       
                16'd235  : {OE0,div_num0} <= {1'b1,tone_C5};    
                16'd240  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd241  : {OE0,div_num0} <= {1'b1,tone_E5}; 
                16'd245  : {OE0,div_num0} <= {1'b1,tone_G4S};    
                16'd285  : {OE0,div_num0} <= {1'b0,tone_G4S}; 

                16'd289  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd312  : {OE0,div_num0} <= {1'b0,tone_A5}; 

                16'd313  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd317  : {OE0,div_num0} <= {1'b1,tone_A5S};    
                16'd319  : {OE0,div_num0} <= {1'b1,tone_B5}; 
                16'd323  : {OE0,div_num0} <= {1'b1,tone_E5};        
                16'd325  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd329  : {OE0,div_num0} <= {1'b1,tone_F4S};       
                16'd331  : {OE0,div_num0} <= {1'b1,tone_F4};     
                16'd335  : {OE0,div_num0} <= {1'b1,tone_C5S}; 

                16'd337  : {OE0,div_num0} <= {1'b1,tone_C5};     
                16'd341  : {OE0,div_num0} <= {1'b1,tone_E4}; 
                16'd381  : {OE0,div_num0} <= {1'b0,tone_E4}; 

                16'd385  : {OE0,div_num0} <= {1'b1,tone_A5};     
                16'd389  : {OE0,div_num0} <= {1'b1,tone_C5}; 
                16'd408  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd409  : {OE0,div_num0} <= {1'b1,tone_E5};     
                16'd413  : {OE0,div_num0} <= {1'b1,tone_F4}; 
                16'd420  : {OE0,div_num0} <= {1'b0,tone_F4}; 
                16'd421  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd426  : {OE0,div_num0} <= {1'b0,tone_A5}; 
                16'd427  : {OE0,div_num0} <= {1'b1,tone_C5}; 
                16'd432  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd433  : {OE0,div_num0} <= {1'b1,tone_E5};     
                16'd437  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd480  : {OE0,div_num0} <= {1'b0,tone_A5};                 

                16'd481  : {OE0,div_num0} <= {1'b1,tone_A5};     
                16'd485  : {OE0,div_num0} <= {1'b1,tone_C5}; 
                16'd504  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd505  : {OE0,div_num0} <= {1'b1,tone_E5};     
                16'd509  : {OE0,div_num0} <= {1'b1,tone_F4S}; 
                16'd516  : {OE0,div_num0} <= {1'b0,tone_F4S}; 
                16'd517  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd522  : {OE0,div_num0} <= {1'b0,tone_A5}; 
                16'd523  : {OE0,div_num0} <= {1'b1,tone_C5}; 
                16'd528  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd529  : {OE0,div_num0} <= {1'b1,tone_E5};     
                16'd533  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd564  : {OE0,div_num0} <= {1'b0,tone_A5};
                16'd565  : {OE0,div_num0} <= {1'b1,tone_G4S}; 
                16'd576  : {OE0,div_num0} <= {1'b0,tone_G4S};
                
                16'd577  : {OE0,div_num0} <= {1'b1,tone_G4};
                16'd603  : {OE0,div_num0} <= {1'b0,tone_G4};         
                16'd605  : {OE0,div_num0} <= {1'b1,tone_E5};  
                16'd612  : {OE0,div_num0} <= {1'b0,tone_E5};  
                16'd613  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd618  : {OE0,div_num0} <= {1'b0,tone_G4};       
                16'd619  : {OE0,div_num0} <= {1'b1,tone_C5};    
                16'd624  : {OE0,div_num0} <= {1'b0,tone_C5}; 

                16'd625  : {OE0,div_num0} <= {1'b1,tone_E5}; 
                16'd629  : {OE0,div_num0} <= {1'b1,tone_G4S};    
                16'd669  : {OE0,div_num0} <= {1'b0,tone_G4S}; 

                16'd673  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd696  : {OE0,div_num0} <= {1'b0,tone_A5}; 

                16'd697  : {OE0,div_num0} <= {1'b1,tone_A5}; 
                16'd701  : {OE0,div_num0} <= {1'b1,tone_A5S};    
                16'd703  : {OE0,div_num0} <= {1'b1,tone_B5}; 
                16'd707  : {OE0,div_num0} <= {1'b1,tone_E5};        
                16'd709  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd713  : {OE0,div_num0} <= {1'b1,tone_F4S};       
                16'd715  : {OE0,div_num0} <= {1'b1,tone_F4};     
                16'd719  : {OE0,div_num0} <= {1'b1,tone_C5S}; 
                
                16'd721  : {OE0,div_num0} <= {1'b1,tone_C5}; 
                16'd725  : {OE0,div_num0} <= {1'b1,tone_E4}; 
                16'd732  : {OE0,div_num0} <= {1'b0,tone_E4}; 
                16'd733  : {OE0,div_num0} <= {1'b1,tone_F4}; 
                16'd738  : {OE0,div_num0} <= {1'b0,tone_F4}; 
                16'd739  : {OE0,div_num0} <= {1'b1,tone_F4S}; 
                16'd744  : {OE0,div_num0} <= {1'b0,tone_F4S}; 

                16'd745  : {OE0,div_num0} <= {1'b1,tone_G4}; 
                16'd749  : {OE0,div_num0} <= {1'b1,tone_A5};    
                16'd751  : {OE0,div_num0} <= {1'b1,tone_B5}; 
                16'd755  : {OE0,div_num0} <= {1'b1,tone_C5};
                16'd757  : {OE0,div_num0} <= {1'b0,tone_C5};

            endcase
        end
    end 

    // Take The 'A' Train base part

    always @(posedge clk_low,negedge nRST)begin
        if(~nRST)begin
            OE1 <= 1'b0;
            div_num1 <= tone_C4;
        end
        else begin
            case(count)
                16'd1   : {OE1,div_num1} <= {1'b1,tone_C2};        
                16'd7   : {OE1,div_num1} <= {1'b1,tone_D2};  
                16'd13  : {OE1,div_num1} <= {1'b1,tone_E2};    
                16'd19  : {OE1,div_num1} <= {1'b1,tone_G2};    
                16'd22  : {OE1,div_num1} <= {1'b0,tone_G2};                  
                16'd23  : {OE1,div_num1} <= {1'b1,tone_G2};  

                16'd25  : {OE1,div_num1} <= {1'b1,tone_C3};
                16'd28  : {OE1,div_num1} <= {1'b0,tone_C3};          
                16'd29  : {OE1,div_num1} <= {1'b1,tone_C3};  
                16'd31  : {OE1,div_num1} <= {1'b1,tone_A3};        
                16'd37  : {OE1,div_num1} <= {1'b1,tone_C3};    
                16'd43  : {OE1,div_num1} <= {1'b1,tone_G2};                  
 
                16'd49  : {OE1,div_num1} <= {1'b1,tone_D2};        
                16'd55  : {OE1,div_num1} <= {1'b1,tone_E2};  
                16'd61  : {OE1,div_num1} <= {1'b1,tone_F2S};       
                16'd67  : {OE1,div_num1} <= {1'b1,tone_A3};    
                16'd69  : {OE1,div_num1} <= {1'b1,tone_F2};                  
                16'd71  : {OE1,div_num1} <= {1'b1,tone_D2}; 

                16'd73  : {OE1,div_num1} <= {1'b1,tone_A3};                               
                16'd79  : {OE1,div_num1} <= {1'b1,tone_G2};     
                16'd85  : {OE1,div_num1} <= {1'b1,tone_F2S};     
                16'd91  : {OE1,div_num1} <= {1'b1,tone_C2S};     
                16'd95  : {OE1,div_num1} <= {1'b1,tone_D2};   
                16'd100 : {OE1,div_num1} <= {1'b0,tone_D2};  
                16'd101 : {OE1,div_num1} <= {1'b1,tone_D2};     
                16'd103 : {OE1,div_num1} <= {1'b1,tone_E2};     
                16'd109 : {OE1,div_num1} <= {1'b1,tone_F2};     
                16'd115 : {OE1,div_num1} <= {1'b1,tone_F2S};

                16'd121 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd126 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd127 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd129 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd131 : {OE1,div_num1} <= {1'b1,tone_G1S};                
                16'd133 : {OE1,div_num1} <= {1'b1,tone_G1};
                16'd139 : {OE1,div_num1} <= {1'b1,tone_B2};

                16'd145 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd151 : {OE1,div_num1} <= {1'b1,tone_G2S};
                16'd157 : {OE1,div_num1} <= {1'b1,tone_A3};
                16'd163 : {OE1,div_num1} <= {1'b1,tone_D2S};
                16'd167 : {OE1,div_num1} <= {1'b1,tone_D2};

                16'd175 : {OE1,div_num1} <= {1'b1,tone_F2S};
                16'd179 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd186 : {OE1,div_num1} <= {1'b0,tone_G2};                
                16'd187 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd191 : {OE1,div_num1} <= {1'b1,tone_C2};

                16'd199 : {OE1,div_num1} <= {1'b1,tone_D2};  
                16'd205 : {OE1,div_num1} <= {1'b1,tone_E2};    
                16'd211 : {OE1,div_num1} <= {1'b1,tone_G2};    
                16'd214 : {OE1,div_num1} <= {1'b0,tone_G2};   
                16'd215 : {OE1,div_num1} <= {1'b1,tone_G2}; 

                16'd217 : {OE1,div_num1} <= {1'b1,tone_C3};         
                16'd220 : {OE1,div_num1} <= {1'b1,tone_C3};  
                16'd221 : {OE1,div_num1} <= {1'b1,tone_C3}; 
                16'd223 : {OE1,div_num1} <= {1'b1,tone_A3};        
                16'd229 : {OE1,div_num1} <= {1'b1,tone_C3};    
                16'd235 : {OE1,div_num1} <= {1'b1,tone_G2};                  
 
                16'd241 : {OE1,div_num1} <= {1'b1,tone_D2};        
                16'd247 : {OE1,div_num1} <= {1'b1,tone_E2};  
                16'd253 : {OE1,div_num1} <= {1'b1,tone_F2S};       
                16'd259 : {OE1,div_num1} <= {1'b1,tone_A3};    
                16'd261 : {OE1,div_num1} <= {1'b1,tone_F2};                  
                16'd263 : {OE1,div_num1} <= {1'b1,tone_D2}; 

                16'd265 : {OE1,div_num1} <= {1'b1,tone_A3};                               
                16'd271 : {OE1,div_num1} <= {1'b1,tone_G2};     
                16'd277 : {OE1,div_num1} <= {1'b1,tone_F2S};     
                16'd283 : {OE1,div_num1} <= {1'b1,tone_C2S};     
                16'd287 : {OE1,div_num1} <= {1'b1,tone_D2}; 

                16'd292 : {OE1,div_num1} <= {1'b0,tone_D2};  
                16'd293 : {OE1,div_num1} <= {1'b1,tone_D2};     
                16'd295 : {OE1,div_num1} <= {1'b1,tone_E2};     
                16'd301 : {OE1,div_num1} <= {1'b1,tone_F2};     
                16'd307 : {OE1,div_num1} <= {1'b1,tone_F2S};

                16'd313 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd318 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd319 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd321 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd323 : {OE1,div_num1} <= {1'b1,tone_G1S};                
                16'd325 : {OE1,div_num1} <= {1'b1,tone_G1};
                16'd331 : {OE1,div_num1} <= {1'b1,tone_B2};

                16'd337 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd343 : {OE1,div_num1} <= {1'b1,tone_G2S};
                16'd349 : {OE1,div_num1} <= {1'b1,tone_A3};
                16'd355 : {OE1,div_num1} <= {1'b1,tone_D2S};
                16'd359 : {OE1,div_num1} <= {1'b1,tone_D2};

                16'd367 : {OE1,div_num1} <= {1'b1,tone_F2S};
                16'd371 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd378 : {OE1,div_num1} <= {1'b0,tone_G2};                
                16'd379 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd383 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd384 : {OE1,div_num1} <= {1'b0,tone_C2};

                16'd385 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd391 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd397 : {OE1,div_num1} <= {1'b1,tone_A3};
                16'd403 : {OE1,div_num1} <= {1'b1,tone_G2};

                16'd409 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd415 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd421 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd427 : {OE1,div_num1} <= {1'b1,tone_G2};

                16'd433 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd439 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd445 : {OE1,div_num1} <= {1'b1,tone_A3};
                16'd451 : {OE1,div_num1} <= {1'b1,tone_G2};

                16'd457 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd463 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd469 : {OE1,div_num1} <= {1'b1,tone_F2};
                16'd475 : {OE1,div_num1} <= {1'b1,tone_G2};

                16'd481 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd487 : {OE1,div_num1} <= {1'b1,tone_E2};
                16'd493 : {OE1,div_num1} <= {1'b1,tone_F2S};
                16'd499 : {OE1,div_num1} <= {1'b1,tone_A2};
                16'd503 : {OE1,div_num1} <= {1'b1,tone_E2};

                16'd505 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd511 : {OE1,div_num1} <= {1'b1,tone_E2};
                16'd517 : {OE1,div_num1} <= {1'b1,tone_F2S};
                16'd523 : {OE1,div_num1} <= {1'b1,tone_A2};
                16'd527 : {OE1,div_num1} <= {1'b1,tone_E2};

                16'd529 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd534 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd541 : {OE1,div_num1} <= {1'b1,tone_A2};
                16'd547 : {OE1,div_num1} <= {1'b1,tone_G2S};

                16'd553 : {OE1,div_num1} <= {1'b1,tone_G2};   
                16'd554 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd557 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd562 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd563 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd570 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd571 : {OE1,div_num1} <= {1'b1,tone_G2};                
                16'd575 : {OE1,div_num1} <= {1'b1,tone_C2};


                16'd583 : {OE1,div_num1} <= {1'b1,tone_D2};  
                16'd589 : {OE1,div_num1} <= {1'b1,tone_E2};    
                16'd595 : {OE1,div_num1} <= {1'b1,tone_G2};    
                16'd598 : {OE1,div_num1} <= {1'b0,tone_G2};                  
                16'd599 : {OE1,div_num1} <= {1'b1,tone_G2};  

                16'd601 : {OE1,div_num1} <= {1'b1,tone_C3};
                16'd604 : {OE1,div_num1} <= {1'b0,tone_C3};          
                16'd605 : {OE1,div_num1} <= {1'b1,tone_C3};  
                16'd607 : {OE1,div_num1} <= {1'b1,tone_A3};        
                16'd613 : {OE1,div_num1} <= {1'b1,tone_C3};    
                16'd619 : {OE1,div_num1} <= {1'b1,tone_G2};                  
 
                16'd625 : {OE1,div_num1} <= {1'b1,tone_D2};        
                16'd631 : {OE1,div_num1} <= {1'b1,tone_E2};  
                16'd637 : {OE1,div_num1} <= {1'b1,tone_F2S};       
                16'd643 : {OE1,div_num1} <= {1'b1,tone_A3};    
                16'd645 : {OE1,div_num1} <= {1'b1,tone_F2};                  
                16'd647 : {OE1,div_num1} <= {1'b1,tone_D2}; 

                16'd649 : {OE1,div_num1} <= {1'b1,tone_A3};                               
                16'd655 : {OE1,div_num1} <= {1'b1,tone_G2};     
                16'd661 : {OE1,div_num1} <= {1'b1,tone_F2S};     
                16'd667 : {OE1,div_num1} <= {1'b1,tone_C2S};     
                16'd671 : {OE1,div_num1} <= {1'b1,tone_D2};   

                16'd676 : {OE1,div_num1} <= {1'b0,tone_D2};  
                16'd677 : {OE1,div_num1} <= {1'b1,tone_D2};     
                16'd679 : {OE1,div_num1} <= {1'b1,tone_E2};     
                16'd685 : {OE1,div_num1} <= {1'b1,tone_F2};     
                16'd691 : {OE1,div_num1} <= {1'b1,tone_F2S};

                16'd697 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd702 : {OE1,div_num1} <= {1'b0,tone_G2};
                16'd703 : {OE1,div_num1} <= {1'b1,tone_G2};
                16'd705 : {OE1,div_num1} <= {1'b1,tone_D2};
                16'd707 : {OE1,div_num1} <= {1'b1,tone_G1S};                
                16'd709 : {OE1,div_num1} <= {1'b1,tone_G1};
                16'd715 : {OE1,div_num1} <= {1'b1,tone_B2};

                16'd721 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd727 : {OE1,div_num1} <= {1'b1,tone_G2S};
                16'd733 : {OE1,div_num1} <= {1'b1,tone_A3};
                16'd739 : {OE1,div_num1} <= {1'b1,tone_D2};

                16'd745 : {OE1,div_num1} <= {1'b1,tone_C2};
                16'd757 : {OE1,div_num1} <= {1'b0,tone_C2};

            endcase
        end
    end


    // assign OUT1=data_out0[15];
    assign OUT2=data_out0[14];
    assign OUT3=data_out0[13];
    assign OUT4=data_out0[12];
    //assign OUT5=rdata0[11];
    //assign OUT6=rdata[10];
    assign OUT5=nRST;

endmodule

