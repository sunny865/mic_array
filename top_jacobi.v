module top_jacobi(
    input clk,
    input rst_n,
    output wire [31:0] quotient_out
  );
wire start_r;
wire [31:0] divisor_r;
wire [31:0] dividend_r;
wire [31:0] quotient_out_o;
wire complete_o;
assign quotient_out = quotient_out_o;
  jacobi j1(
    .clk(clk),
    .rst_n(rst_n),
    .start_r(start_r),
    .divisor_r(divisor_r),
    .dividend_r(dividend_r),
    .quotient_out_o(quotient_out_o),
    .complete_o(complete_o)
  );

Fixed_Point_Divider_Top int8_16(
		.dividend(dividend_r), //input [23:0] dividend
		.divisor(divisor_r), //input [23:0] divisor
		.start(start_r), //input start
		.clk(clk), //input clk
		.quotient_out(quotient_out_o), //output [23:0] quotient_out
		.complete(complete_o) //output complete
);

endmodule
