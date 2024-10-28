`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module multi(
    input clk,
    input rst_n,
    input cEn,
    input [15:0] sig_i_1,
    input [15:0] sig_i_2, 
    output reg [31:0] sig_o
    );
    wire [31:0]P;
    
    always@(posedge clk or negedge rst_n)begin
     if(!rst_n)begin
         sig_o <= 0;
     end
        else begin
            if(cEn)
             sig_o <= P;
      end
    end

  multiply_1 multiply_x(
  .CLK(clk),
  .A(sig_i_1),
  .B(sig_i_2),
  .P(P)
  );  
    
    
endmodule
