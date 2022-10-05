module tb_top_jacobi();

reg clk;
reg rst_n;
wire [23:0] out;
always #10 clk = ~clk;

initial begin
    clk = 'd0;
    rst_n = 'd0;
    #50
    @ (posedge clk) rst_n = 'd1;
    #500000 $stop;
end

top_jacobi j1(
    .clk(clk),
    .rst_n(rst_n),
    .quotient_out(out)
);

endmodule
