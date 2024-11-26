`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2024 04:43:03 PM
// Design Name: 
// Module Name: FIR_windows_generate_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIR_window_function_generate_tb(

    ); 
       reg    				clk;
       reg 					rst_n;
        
       reg 					en;		//trigger
       reg 			[3:0]	win_type;	//window type 1:rectangle 2:Tukey 3:triangle 4:Hann 5:Hamming 6:Blackman
       reg 			[15:0]	n;			//window length
       reg 			[7:0]	lgn=8'd6;			//window length
       reg 			[15:0]	i;			//window index  0 ~ n-1
     
       wire 				busy;		//finish claculating?
       wire signed	[15:0]	win;
        Window_function_generator function_instance(
       				.clk(clk),
        			.rst_n(rst_n),
        
        			.en(en),			//trigger
        			.win_type(win_type),	//window type 1:rectangle 2:Tukey 3:triangle 4:Hann 5:Hamming 6:Blackman
        			.n(n),			//window length
        			.lgn(lgn),
        			.i(i),			//window index  0 ~ n-1
     
        			.busy(busy),		//finish claculating?
        		    .win(win)
);

//task calculate window
task cal_win;
	input	[3:0]	WIN_TYPE;
	input	[15:0]	N;

	integer	k;
	begin
		n = N;
		win_type = WIN_TYPE;
		#10;

		for (k = 0; k < N; k = k + 1'b1) begin
			i	= k;
			en	= 1'b1;
			wait(busy);
			#10;
			en	= 1'b0;
			wait(~busy);
			#10;
		end
	end
endtask


initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    en = 1'b0;
    win_type = 3'd1;
    n = 16'd0;
    i = 16'd0;
    #21 rst_n = 1'b1;
    
    #1000;
	cal_win(1, 64);		//rectangle
	#1000;
	cal_win(3, 64);		//triangle

//	#1000;
//	cal_win(2, 64);		//turkey

	#1000;
	cal_win(4, 64);		//hann

	#1000;
	cal_win(5, 64);		//hamm

	#1000;
	cal_win(6, 64);		//blackman

	#200;
	$stop;
end
always#5 clk = ~clk;

endmodule
