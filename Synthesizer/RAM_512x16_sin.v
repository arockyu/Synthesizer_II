module RAM_512x16_sin (
    input [8:0] ram_addr,
    input [15:0] ram_wdata,
    output [15:0] ram_rdata,
    input ce,
    input clk,
    input we,
    input re);

    wire [15:0] ram_rdata0;
    wire [15:0] ram_rdata1;

    assign ram_rdata = ram_addr[8] ? ram_rdata1 : ram_rdata0;

    SB_RAM40_4K RAM_inst0(
        .RDATA(ram_rdata0),
        .RADDR({3'b000,ram_addr[7:0]}),
        .RCLK(clk),
        .RCLKE(re&ce),
        .RE(re&ce),
        .WDATA(ram_wdata),
        .WADDR({3'b000,ram_addr[7:0]}),
        .WCLK(clk),
        .WCLKE(we&ce),
        .WE(we&ce),
        .MASK(16'h0000));
    defparam RAM_inst0.READ_MODE =0;
    defparam RAM_inst0.WRITE_MODE =0;

    SB_RAM40_4K RAM_inst1(
        .RDATA(ram_rdata1),
        .RADDR({3'b000,ram_addr[7:0]}),
        .RCLK(clk),
        .RCLKE(re&ce),
        .RE(re&ce),
        .WDATA(ram_wdata),
        .WADDR({3'b000,ram_addr[7:0]}),
        .WCLK(clk),
        .WCLKE(we&ce),
        .WE(we&ce),
        .MASK(16'h0000));
    defparam RAM_inst0.READ_MODE =0;
    defparam RAM_inst0.WRITE_MODE =0;

    /*sin wave*/
    defparam RAM_inst0.INIT_0 = 256'h976D_95E1_9454_92C7_9139_8FAA_8E1B_8C8B_8AFA_896A_87D8_8647_84B5_8323_8191_7FFF;
    defparam RAM_inst0.INIT_1 = 256'hAF86_AE10_AC98_AB1E_A9A3_A826_A6A7_A527_A3A5_A223_A09E_9F19_9D92_9C0A_9A82_98F8;
    defparam RAM_inst0.INIT_2 = 256'hC5CC_C47A_C324_C1CD_C073_BF16_BDB7_BC55_BAF2_B98C_B823_B6B9_B54C_B3DE_B26D_B0FB;
    defparam RAM_inst0.INIT_3 = 256'hD963_D842_D71D_D5F4_D4C9_D39A_D268_D132_CFFA_CEBF_CD80_CC3F_CAFA_C9B3_C869_C71C;
    defparam RAM_inst0.INIT_4 = 256'hE98B_E8A5_E7BC_E6CE_E5DD_E4E7_E3EE_E2F1_E1F0_E0EB_DFE2_DED6_DDC6_DCB3_DB9C_DA81;
    defparam RAM_inst0.INIT_5 = 256'hF5A4_F503_F45E_F3B4_F306_F254_F19D_F0E1_F022_EF5E_EE95_EDC9_ECF8_EC23_EB4A_EA6C;
    defparam RAM_inst0.INIT_6 = 256'hFD38_FCE2_FC88_FC28_FBC4_FB5C_FAEE_FA7C_FA04_F989_F908_F883_F7F9_F76B_F6D8_F640;
    defparam RAM_inst0.INIT_7 = 256'hFFFC_FFF5_FFE8_FFD7_FFC1_FFA6_FF86_FF61_FF37_FF08_FED4_FE9C_FE5E_FE1C_FDD5_FD89;
    defparam RAM_inst0.INIT_8 = 256'hFDD5_FE1C_FE5E_FE9C_FED4_FF08_FF37_FF61_FF86_FFA6_FFC1_FFD7_FFE8_FFF5_FFFC_FFFF;
    defparam RAM_inst0.INIT_9 = 256'hF6D8_F76B_F7F9_F883_F908_F989_FA04_FA7C_FAEE_FB5C_FBC4_FC28_FC88_FCE2_FD38_FD89;
    defparam RAM_inst0.INIT_A = 256'hEB4A_EC23_ECF8_EDC9_EE95_EF5E_F022_F0E1_F19D_F254_F306_F3B4_F45E_F503_F5A4_F640;
    defparam RAM_inst0.INIT_B = 256'hDB9C_DCB3_DDC6_DED6_DFE2_E0EB_E1F0_E2F1_E3EE_E4E7_E5DD_E6CE_E7BC_E8A5_E98B_EA6C;
    defparam RAM_inst0.INIT_C = 256'hC869_C9B3_CAFA_CC3F_CD80_CEBF_CFFA_D132_D268_D39A_D4C9_D5F4_D71D_D842_D963_DA81;
    defparam RAM_inst0.INIT_D = 256'hB26D_B3DE_B54C_B6B9_B823_B98C_BAF2_BC55_BDB7_BF16_C073_C1CD_C324_C47A_C5CC_C71C;
    defparam RAM_inst0.INIT_E = 256'h9A82_9C0A_9D92_9F19_A09E_A223_A3A5_A527_A6A7_A826_A9A3_AB1E_AC98_AE10_AF86_B0FB;
    defparam RAM_inst0.INIT_F = 256'h8191_8323_84B5_8647_87D8_896A_8AFA_8C8B_8E1B_8FAA_9139_92C7_9454_95E1_976D_98F8;

    defparam RAM_inst1.INIT_0 = 256'h6891_6A1D_6BAA_6D37_6EC5_7054_71E3_7373_7504_7694_7826_79B7_7B49_7CDB_7E6D_7FFF;
    defparam RAM_inst1.INIT_1 = 256'h5078_51EE_5366_54E0_565B_57D8_5957_5AD7_5C59_5DDB_5F60_60E5_626C_63F4_657C_6706;
    defparam RAM_inst1.INIT_2 = 256'h3A32_3B84_3CDA_3E31_3F8B_40E8_4247_43A9_450C_4672_47DB_4945_4AB2_4C20_4D91_4F03;
    defparam RAM_inst1.INIT_3 = 256'h269B_27BC_28E1_2A0A_2B35_2C64_2D96_2ECC_3004_313F_327E_33BF_3504_364B_3795_38E2;
    defparam RAM_inst1.INIT_4 = 256'h1673_1759_1842_1930_1A21_1B17_1C10_1D0D_1E0E_1F13_201C_2128_2238_234B_2462_257D;
    defparam RAM_inst1.INIT_5 = 256'h0A5A_0AFB_0BA0_0C4A_0CF8_0DAA_0E61_0F1D_0FDC_10A0_1169_1235_1306_13DB_14B4_1592;
    defparam RAM_inst1.INIT_6 = 256'h02C6_031C_0376_03D6_043A_04A2_0510_0582_05FA_0675_06F6_077B_0805_0893_0926_09BE;
    defparam RAM_inst1.INIT_7 = 256'h0002_0009_0016_0027_003D_0058_0078_009D_00C7_00F6_012A_0162_01A0_01E2_0229_0275;
    defparam RAM_inst1.INIT_8 = 256'h0229_01E2_01A0_0162_012A_00F6_00C7_009D_0078_0058_003D_0027_0016_0009_0002_0000;
    defparam RAM_inst1.INIT_9 = 256'h0926_0893_0805_077B_06F6_0675_05FA_0582_0510_04A2_043A_03D6_0376_031C_02C6_0275;
    defparam RAM_inst1.INIT_A = 256'h14B4_13DB_1306_1235_1169_10A0_0FDC_0F1D_0E61_0DAA_0CF8_0C4A_0BA0_0AFB_0A5A_09BE;
    defparam RAM_inst1.INIT_B = 256'h2462_234B_2238_2128_201C_1F13_1E0E_1D0D_1C10_1B17_1A21_1930_1842_1759_1673_1592;
    defparam RAM_inst1.INIT_C = 256'h3795_364B_3504_33BF_327E_313F_3004_2ECC_2D96_2C64_2B35_2A0A_28E1_27BC_269B_257D;
    defparam RAM_inst1.INIT_D = 256'h4D91_4C20_4AB2_4945_47DB_4672_450C_43A9_4247_40E8_3F8B_3E31_3CDA_3B84_3A32_38E2;
    defparam RAM_inst1.INIT_E = 256'h657C_63F4_626C_60E5_5F60_5DDB_5C59_5AD7_5957_57D8_565B_54E0_5366_51EE_5078_4F03;
    defparam RAM_inst1.INIT_F = 256'h7E6D_7CDB_7B49_79B7_7826_7694_7504_7373_71E3_7054_6EC5_6D37_6BAA_6A1D_6891_6706;

endmodule
