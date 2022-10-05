module jacobi(
    input clk,
    input rst_n,
    input data,
    output reg valid,
    output reg result,
    output reg start_r,
    output reg [31:0] divisor_r,
    output reg [31:0] dividend_r,
    input [31:0] quotient_out_o,
    input complete_o
);

parameter matrix_m = 7;
parameter matrix_n = 7;
integer i;
integer j;

reg [2:0] state;
reg [23:0] R_array [matrix_m - 1 :0][matrix_n - 1 : 0];
reg [7:0] cnt;

always @ (posedge clk or negedge rst_n)
if(~rst_n)
    cnt <= 'd0;
else if(state == 'd0)
    cnt <= cnt + 'd1;
else
    cnt <= 'd0;


/*state
 'b000   IDLE
 'b001   Findmax
 'b010   Findfinish
 'b011   finish
 'b100   Load_to_reg
*/
reg [7:0] max_index_i;
reg [7:0] max_index_j;
reg [24:0] max;
reg [24:0] cycle_cnt;
reg [23:0] theta;
reg [23:0] tan;
reg [23:0] cos;
reg [23:0] sin;
reg [23:0] cycle;
reg eigen_start;
wire start;
reg sig_fl;

always @ (posedge clk or negedge rst_n)
if(~rst_n) begin
    for(i = 0; i < matrix_m; i=i+1) begin
        for(j = 0; j < matrix_n; j=j+1) begin
        R_array[i][j] <= 'd8 + i;
        end
    end
    state <= 'd0;
    cycle <= 'd0;
end
else begin
case(state)
	 3'b000: begin
	 eigen_start <= 1'b1;               
       if (eigen_start == 1'b1) begin  //å¼å§å¯»æ¾æå¤§å¼
            max <= 'd0;
            max_index_i <= 'd0;
            max_index_j <= 'd0;
            state <= 'b001;
            start_r <= 'd1;
		 end
	 end	
	 3'b001: begin                      //å¯»æ¾æå¤§å¼  
         eigen_start <= 1'b0;
         for(i = 0; i < matrix_m; i=i+1) begin
                 for(j = i+1; j < matrix_n; j=j+1) begin
                    if(R_array[i][j] > max) begin
                        max <= R_array[i][j];
                        max_index_i <= i;
                        max_index_j <= j;
                     end
                end
         end
         state <= 'b010;
	 end
	 3'b010: begin       //å¯»æ¾å®æï¼å¤æ­é¨é	 
        if(max > 'd10) begin
            state <= 'b011;
            cycle <= cycle + 'd1;
        end
        else begin
            state <= 'b000;
        end
	 end

      3'b011: begin       //è®¡ç®æè½¬è§åº¦	 
        dividend_r <= $signed(max) * $signed(24'd2);
        if(R_array[max_index_j][max_index_j] > R_array[max_index_i][max_index_i]) begin
          divisor_r <= R_array[max_index_j][max_index_j] - R_array[max_index_i][max_index_i];
          sig_fl <= 'd1;
        end
      else begin
        divisor_r <= R_array[max_index_i][max_index_i] - R_array[max_index_j][max_index_j];
        sig_fl <= 'd0;
      end
        state <= 3'b100;
	 end
       3'b100: begin     //åå¥tan
       start_r <= 'd0;
        if(complete_o == 'd1) begin
          
            tan <= quotient_out_o;
            state <= 3'b101;
        end
     end
       3'b101: begin     //è¯»åsin,cosï¼è®¡ç®ç©éµ,load_to_reg
         for(i = 0; i < matrix_m; i=i+1) begin
                 for(j = i+1; j < matrix_n; j=j+1) begin
                    if(i == max_index_i) begin
                            if(j == max_index_j) begin
                            R_array[i][j] <= ($signed(R_array[i][j])*((($signed(cos)*$signed(cos)-$signed(sin)*$signed(sin)))>>16)+$signed(R_array[j][j]-R_array[i][i])*(($signed($signed(sin)*$signed(cos)))>>16))>>16;
                         end
                            else if(j == max_index_i) begin
                            R_array[i][j] <= ($signed(($signed(R_array[i][i])*$signed(cos)+$signed(R_array[i][j])*$signed(sin))>>16)*$signed(cos)+$signed(($signed(R_array[i][j])*$signed(cos)+$signed(R_array[j][j])*$signed(sin))>>16)*$signed(sin))>>16;
                         end    
                            else R_array[i][j] <= ($signed(R_array[i][j])*$signed(cos) + $signed(R_array[max_index_j][j])*$signed(sin))>>16;
                    end
                    else if(i == max_index_j) begin
                            if(j == max_index_j) begin
                            R_array[j][j] <= ($signed(($signed(R_array[j][j])*$signed(cos)-$signed(R_array[i][j])*$signed(sin))>>16)*$signed(cos)+$signed(($signed(R_array[i][j])*$signed(cos)-$signed(R_array[i][i])*$signed(sin))>>16)*$signed(sin))>>16;
                         end    
                            else 
                            R_array[i][j] <= ($signed(R_array[i][j])*$signed(cos) - $signed(R_array[max_index_i][j])*$signed(sin))>>16;
                    end
      
                end
         end        
            state <= 3'b110;  
     end
    3'b110: begin
      eigen_start <= 1'b1;
      state <= 3'b000;
    end
	 default:state <= 3'b000;
    endcase 

end

always @ (posedge clk) begin
  if(sig_fl == 'd0) begin
    if(tan >= 'd0 && tan < 'h001936) begin 
            theta <= 'd0;
            cos <= 'h010000;      //左移16位
            sin <= 'd0;
            end
    else if(tan >= 'h001936 && tan < 'h0032eb) begin
            cos <= 'h00ffb1;
            sin <= 'h000c8f;
    end
    else if(tan >= 'h0032eb && tan < 'h004da8) begin
            cos <= 'h00fec4;
            sin <= 'h001917;
    end
    else if(tan >= 'h004da8 && tan < 'h006a09) begin
            cos <= 'h00fd3a;
            sin <= 'h002590;
    end
    else if(tan >= 'h006a09 && tan < 'h0088d5) begin
            cos <= 'h00fb14;
            sin <= 'h0031f1;
    end
    else if(tan >= 'h0088d5 && tan < 'h00ab0d) begin
            cos <= 'h00f853;
            sin <= 'h003e33;
    end
    else if(tan >= 'h00ab0d && tan < 'h00d218) begin
            cos <= 'h00f4fa;
            sin <= 'h004a50;
    end
    else if(tan >= 'h00d218 && tan < 'h010000) begin
            cos <= 'h00f109;
            sin <= 'h00563e;
    end
    else if(tan >= 'h010000 && tan < 'h0137ef) begin
            cos <= 'h00ec83;
            sin <= 'h0061f7;
    end
    else if(tan >= 'h0137ef && tan < 'h017f21) begin
            cos <= 'h00e76b;
            sin <= 'h006d74;
    end
    else if(tan >= 'h017f21 && tan < 'h01def1) begin
            cos <= 'h00e1c5;
            sin <= 'h0078ad;
    end
    else if(tan >= 'h01def1 && tan < 'h026a09) begin
            cos <= 'h00db94;
            sin <= 'h00839c;
    end
    else if(tan >= 'h026a09 && tan < 'h034bed) begin
            cos <= 'h00d4db;
            sin <= 'h008e39;
    end
    else if(tan >= 'h034bed && tan < 'h0506ff) begin
            cos <= 'h00cd9f;
            sin <= 'h00987f;
    end
    else if(tan >= 'h0506ff && tan < 'h0a2736) begin
            cos <= 'h00c5e4;
            sin <= 'h00a267;
    end
    else if(tan >= 'h0a2736 && tan < 'hefffff) begin
            cos <= 'h00bdae;
            sin <= 'h00abeb;
    end  
  end
else if(sig_fl == 'd1) begin
  if(tan >= 'd0 && tan < 'h001936) begin 
            cos <= 'h000c8f;      //左移16位
            sin <= 'h00ffb1;
            end
    else if(tan >= 'h001936 && tan < 'h0032eb) begin
            cos <= 'h001917;
            sin <= 'h00fec4;
    end
    else if(tan >= 'h0032eb && tan < 'h004da8) begin
            cos <= 'h002590;
            sin <= 'h00fd3a;
    end
    else if(tan >= 'h004da8 && tan < 'h006a09) begin
            cos <= 'h0031f1;
            sin <= 'h00fb14;
    end
    else if(tan >= 'h006a09 && tan < 'h0088d5) begin
            cos <= 'h003e33;
            sin <= 'h00f853;
    end
    else if(tan >= 'h0088d5 && tan < 'h00ab0d) begin
            cos <= 'h004a50;
            sin <= 'h00f4fa;
    end
    else if(tan >= 'h00ab0d && tan < 'h00d218) begin
            cos <= 'h00563e;
            sin <= 'h00f109;
    end
    else if(tan >= 'h00d218 && tan < 'h010000) begin
            cos <= 'h0061f7;
            sin <= 'h00ec83;
    end
    else if(tan >= 'h010000 && tan < 'h0137ef) begin
            cos <= 'h006d74;
            sin <= 'h00e76b;
    end
    else if(tan >= 'h0137ef && tan < 'h017f21) begin
            cos <= 'h0078ad;
            sin <= 'h00e1c5;
    end
    else if(tan >= 'h017f21 && tan < 'h01def1) begin
            cos <= 'h00839c;
            sin <= 'h00db94;
    end
    else if(tan >= 'h01def1 && tan < 'h026a09) begin
            cos <= 'h008e39;
            sin <= 'h00d4db;
    end
    else if(tan >= 'h026a09 && tan < 'h034bed) begin
            cos <= 'h00987f;
            sin <= 'h00cd9f;
    end
    else if(tan >= 'h034bed && tan < 'h0506ff) begin
            cos <= 'h00a267;
            sin <= 'h00c5e4;
    end
    else if(tan >= 'h0506ff && tan < 'h0a2736) begin
            cos <= 'h00abeb;
            sin <= 'h00bdae;
    end
    else if(tan >= 'h0a2736 && tan < 'hefffff) begin
            cos <= 'h00b504;
            sin <= 'h00b504;
    end  
end 
end



endmodule
