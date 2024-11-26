`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// test amplitude change before and after filterring
// input 100kHz   filter fs 1MHz  fc 100kHz
//////////////////////////////////////////////////////////////////////////////////


module amplitude_tb(
    );
        reg                 clk;
        reg                 rst_n;
        reg                 en;
        reg			[15:0]	pi_phase;			//??????fln,fhn????fs/2
        reg			[3:0]	win_type;	//?????1:????2:????3:????4:????5:????6:?????
        reg         [7:0]   pace;
        reg	        [15:0]	n;			//?????
        reg	        [7:0]	lgn=8'd6;
        reg signed [15:0]   data_in;
        wire                valid;
        wire signed	[15:0]	data_out;
        reg signed	[15:0]	data_out_sample;
        wire signed [15:0]d1;

       dds_100kHz dds_100kHz (//0.1M
              .aclk(clk),                                // input wire aclk
              .m_axis_data_tdata(d1)      // output wire [15 : 0] m_axis_data_tdata
        ); 

        reg signed [15:0]   multiply;
        
    initial begin
     multiply = 0;
    end
    always #1 multiply =d1;
    
    initial begin
     data_in = 16'd0;
    end
    initial begin
     pace = 8'd20;
     pi_phase = 16'd6554;
    end
    always #1000 begin
    data_in = multiply;
    data_out_sample = data_out;
    end
    //        clk 40M
    initial begin
    clk = 1'b0;
    end
    always #12.5 clk =~clk;   
    
      FIR_filter FIR_filter_inst(
            .clk			(clk),
            .rst_n			(rst_n),
            .en				(en),			//?
            .pi_phase		(pi_phase),			//
            .win_type		(win_type),		//
            .pace		    (pace),
            .n				(n),			//?????
            .lgn		    (lgn),	
            .data_in		(data_in),			//
            .valid	        (valid),
            .data_out	    (data_out)
);
    reg  signed	[15:0] shift_reg[0:7];
    integer i;

    
    initial begin
          for(i=0; i<8; i=i+1) begin
             shift_reg[i] <= 16'd0;
         end
    end
   always #12.5 begin
            for(i=8; i>-1; i=i-1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
                shift_reg[0] <= data_out;
           end
    
    reg signed [15:0]data;
    initial begin
    data = 16'b0;
    end
    always #12.5 data = (shift_reg[0]+shift_reg[1]+shift_reg[2]+shift_reg[3]+shift_reg[4]+shift_reg[5]+shift_reg[6]+shift_reg[7])>>>3;  

  
    initial begin
	rst_n		<= 1'b0;
	en			<= 1'b0;
	win_type    <= 4'd1;
	n		    <= 16'd64;
	#121;
	rst_n	<= 1'b1;
	#1000;
	en	<= 1'b1;
	#200000;
	win_type    <= 4'd4;
	n		    <= 16'd64;	
	#200000;
	win_type    <= 4'd3;
	n		    <= 16'd64;
	#200000;
	$stop;
   
end

    
    
endmodule

