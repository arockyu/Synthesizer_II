/////////////////////////////////////////////
/// Vriable Freqency1 divider 
/// input clk        : input clock
/// output out       : div_num+1 diveded clock out
/// input div_num    : divid number
/////////////////////////////////////////////

// Instance Format sample
//
// divider_variable inst(
//   .clk(),
//   .out(),
//   .div_num());
// defparam inst.N = 11;

module divider_variable(
  input clk,
  output out,
  input [N-1:0] div_num);
  parameter N = 11;

  //registor definiton
  reg [N-2:0] count_p=0;
  reg [N-2:0] count_n=0;
  reg out=1'b0;

  wire [N-3:0] zero = 0;
  wire [N-2:0] div_num_n = div_num[N-1:1] - 1;
  wire [N-2:0] div_num_p = div_num[N-1:1] + {zero,div_num[0]} - 1;

  always @(posedge clk) begin
    if(out)begin
      count_p <= count_p + 1;
      if (count_p >= div_num_p) begin
        count_n <= 0;
        out <= 1'b0;
      end else;
    end else begin
       count_n <= count_n + 1;
      if (count_n >= div_num_n) begin
        count_p <= 0;
        out <= 1'b1;
      end else;     
    end
  end

endmodule