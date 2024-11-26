`timescale 1ns / 1ps


module Window_function_generator(
        input	wire					clk,
        input	wire					rst_n,
        
        input	wire					en,			//trigger
        input	wire			[3:0]	win_type,	//window type 1:rectangle 2:Tukey 3:triangle 4:Hann 5:Hamming 6:Blackman
        input	wire			[15:0]	n,			//window length
        input	wire			[15:0]	i,			//window index  0 ~ n-1
        input   wire            [7:0]   lgn,
        
        output	wire					busy,		//finish claculating?
        output	wire	signed	[15:0]	win
);
reg signed [15:0] win_buf    = 16'sd256;
reg signed [15:0] win_buf_d0 = 16'sd256;
reg                 busy_buf = 1'b0;


assign busy = busy_buf;

localparam S_IDLE = 4'H1;
localparam S_CAL = 4'H2;
localparam S_END = 4'H3;

reg		[3:0]	state	= S_IDLE;
reg		[3:0]	next_state;

//cnt: control data read of cosine
reg		[3:0]	cnt	= 4'd0;
always @(posedge clk) begin
	case(state)
	S_IDLE: begin
		  cnt  <= 4'd0;
	end
	S_CAL: begin
		  cnt <= cnt + 1'b1;
	end
	default: begin
		  cnt <= 4'd0;
	end
	endcase
end

//edge detection
reg en_r0;
reg en_r1;
always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             en_r0 <= 1'b0;
             en_r1 <= 1'b0;
        end 
        else begin
             en_r0 <= en;
             en_r1 <= en_r0;
        end
end

reg en_flag;
always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             en_flag <= 1'b0;
        end 
        else begin
             en_flag <=  !en_r1 & en_r0;
        end
end

//window judge
always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             state <= S_IDLE;
        end 
        else begin
             state <= next_state;
        end
end

always@(*)begin
    case(state)
    
    S_IDLE: begin
        if(en_flag)begin
             next_state <= S_CAL;
        end 
        else begin
             next_state <= S_IDLE;
        end
     end
     
    S_CAL: begin
       case(win_type)
       4'd1: begin  //rectangle
                next_state <= S_END;
            end
//       4'd2: begin  //turkey
//                if(cnt >= 4'd4)begin
//                    next_state <= S_END;
//                end
//                else begin
//                    next_state <= S_CAL;
//                end
//            end
       4'd3: begin  //triangle
                if(cnt >= 4'd1)begin
                    next_state <= S_END;
                end
                else begin
                    next_state <= S_CAL;
                end
            end
       4'd4: begin  //hann
                if(cnt >= 4'd4)begin
                    next_state <= S_END;
                end
                else begin
                    next_state <= S_CAL;
                end
            end  
       4'd5: begin  //hamming
                if(cnt >= 4'd3)begin
                    next_state <= S_END;
                end
                else begin
                    next_state <= S_CAL;
                end
            end  
       4'd6: begin  //blackman
                if(cnt >= 4'd5)begin
                    next_state <= S_END;
                end
                else begin
                    next_state <= S_CAL;
                end
            end   
       default: next_state <= S_END;                          
       endcase
    end    
     
    S_END:begin
         next_state	<= S_IDLE;
	end
	
	default: begin
		 next_state	<= S_IDLE;
    end   
    endcase
end
//cos_phase
reg		[15:0]	k	= 16'd0;

//sin_rom
reg		[15:0]	cos_phase	= 16'd0;
wire	[15:0]	cos_out;

sin_gen sin_gen_inst_0(
	.clk(clk),
	.phase(cos_phase),		//0~65535 [0~2pi)
	.sin_out(cos_out)			//0~65535
);

wire	signed	[15:0]	cos_val_s;
assign	cos_val_s	= {~cos_out[15], cos_out[14:0]};

//win_buf
reg signed [31:0]multi_tmp = 32'sd0;
always@(posedge clk or negedge rst_n)begin
     if(!rst_n)begin
        win_buf <= 16'sd0;
     end 
     else begin
       case(win_type)
        
       4'd1: begin//rectangle
             win_buf <= 16'sd256;
          end  
//       4'd2: begin  //turkey
//			if(cnt == 4'd5) begin
//				if(i <= k) begin
//					win_buf	<= (16'sd256 - (cos_val_s >>> 7)) >>> 1;
//				end
//				else if(i > n - k - 4'd2) begin
//					win_buf	<= (16'sd256 - (cos_val_s >>> 7)) >>> 1;
//				end
//				else begin
//					win_buf	<= 16'sd256;
//				end
//			end
//			else begin
//				win_buf	<= win_buf;
//			end
//		end
       4'd3: begin  //triangle
                if(cnt == 4'd0)begin
                    multi_tmp	<= (16'sd512 * i)>>> lgn;
                end
                else  if(cnt == 4'd1)begin
                    win_buf	<= 16'sd256 - abs(16'sd256 - multi_tmp[15:0]);
                end
                else begin
                    win_buf <= win_buf;
                end
            end
       4'd4: begin  //hann
                if(cnt == 4'd4)begin
                    win_buf <= 16'sd128 - (cos_val_s >>> 8);
                end
                else begin
                    win_buf <= win_buf;
                end
            end  
       4'd5: begin  //hamming
                if(cnt == 4'd3)begin
                    win_buf <= 16'sd138 - ((16'sd118 * (cos_val_s >>> 7))>>>8);
                end
                else begin
                   win_buf <= win_buf;
                end
            end  
       4'd6: begin  //blackman
                if(cnt == 4'd4)begin
                    win_buf <= 16'sd108 - (cos_val_s >>> 8);
                end
                else if(cnt == 4'd5)begin
                    win_buf <= win_buf + ((16'sd82 * (cos_val_s >>> 7)) >>> 10);
                end 
                else begin
                    win_buf <= win_buf;
                end
            end           
        default: begin 
             win_buf <= win_buf;
        end
        endcase 
        end
end

//busy_buf
always@(posedge clk)begin
    case(state)
    S_IDLE: begin
        busy_buf <= 1'b0;
    end
    default: begin
        busy_buf <= 1'b1;
    end
    endcase
end

//cos_phase
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cos_phase	<= 16'd0;
    end
    else 
    case(state)
    S_CAL: begin
            case(win_type)
            4'd1: begin//rectangle
                cos_phase	<= 16'd0;
            end
//            4'd2: begin//turkey
//                if(cnt == 4'd0)begin
//                    k <= ((n - 4'd2)*25)>>8;
//                end
//                else if(cnt == 4'd1) begin
//                      k <= k;
//                    if(i <= k) begin
//                        cos_phase <= i * (16'd32768 / (k + 1'b1)) + 16'd16384;//sin to cos add 16384
//                    end
//                    else if(i > n - k - 2'd2) begin
//                        cos_phase <= (n - i - 1'b1) * (16'd32768 / (k + 1'b1)) + 16'd16384;
//                    end
//                    else begin
//                        cos_phase <= 16'd0;
//                    end
//                end
//                else begin
//                    cos_phase <= cos_phase;
//                            k <= k;
//                end
//            end
            4'd3: begin//triangle
                cos_phase <=  16'd0;
            end
            4'd4: begin//hann
                cos_phase <=  2'd2 * i * (16'd32768 >> lgn) + 16'd16384;
            end
            4'd5: begin//hamming
                cos_phase <=  2'd2 * i * (16'd32768 >> lgn) + 16'd16384;
            end
            4'd6: begin	//blackman
			if(cnt == 4'd0) begin
				cos_phase <= 2'd2 * i * (16'd32768 >> lgn) + 16'd16384;
			end
			else if(cnt == 4'd2) begin
				cos_phase <= 4'd4 * i * (16'd32768 >> lgn) + 16'd16384;
			end
			else begin
				cos_phase	<= cos_phase;
			end
	     end
            default: begin
                 cos_phase <=  16'd0;
            end
            endcase
    end
    default: begin
         cos_phase <=  cos_phase;
    end
    endcase
end

//win_buf_d0
always @(posedge clk) begin
	case(state)
	S_END: begin
		win_buf_d0	<= win_buf;
	end
	default: begin
		win_buf_d0	<= win_buf_d0;
	end
	endcase
end
assign win  = win_buf_d0;
//------------------func------------------------------
function signed [15:0] abs(input signed [15:0] a);
	begin
		abs = (a >= 16'sd0)? a : -a;
	end
endfunction

endmodule
