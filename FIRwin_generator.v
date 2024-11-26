`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module FIRwin_generator(
    input clk,
    input rst_n,
    input en,
    input [15:0] pi_phase,
    input [3:0]  win_type,
    input [15:0] n,
    input [7:0]  lgn,
    input [15:0] i,
    output busy,
    output [15:0] firwin
    );


    
    localparam S_IDLE = 4'H1;
    localparam  S_CAL = 4'H2;
    localparam  S_END = 4'H4;
    
    reg [3:0] state = S_IDLE;
    reg [3:0] next_state;
    
    //cnt control flow
    reg		[3:0]	cnt	= 4'd0;
    
    always @(posedge clk) begin
        case(state)
        S_IDLE: begin
            cnt	<= 4'd0;
        end
        S_CAL: begin
            cnt	<= cnt + 1'b1;
        end
        default: begin
            cnt	<= 4'd0;
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
    

    //sin_phase calculate//////////////////////////// 
    reg [15:0] sin_phase = 16'd0;
    //i_buf
    reg	signed [15:0] i_buf;
    always @(posedge clk) begin
        if(i > (n >>> 1)) begin
            i_buf <= n - i;	//???????????????i_buf???????
        end
        else begin
            i_buf <= i;
        end
    end
      
    reg	signed	[15:0]	s_mlti2;
    always @(posedge clk) begin
        s_mlti2	<= n - i_buf * 4'sd2;
    end
    
    reg signed [15:0] s_mlti2_d1;
    always @(posedge clk) begin
        s_mlti2_d1 <= s_mlti2;  
    end
    reg [47:0] multi_tmp;
    always @(*) begin
        case(state)
        S_IDLE: begin
            multi_tmp <= 48'd0; 
        end  
        S_CAL: begin
            multi_tmp <= (pi_phase * s_mlti2_d1) >> 1;
        end
        S_END: begin
            multi_tmp <= 48'd0; 
        end    
        default:  multi_tmp <= 48'd0; 
        endcase
    end
    
    always @(*) begin
        case(state)
        S_CAL: begin
            sin_phase <= multi_tmp[15:0]; 
        end
        S_END: begin
            sin_phase <= sin_phase; 
        end    
        default:  sin_phase <= sin_phase; 
        endcase
    end
    
        //sin rom 
 
    wire [15:0] sin_out;   
    sin_gen sin_gen_inst_1(
	.clk		(clk),
	.phase		(sin_phase),		//???0~65535??[0~2pi)
	.sin_out	(sin_out)			//0~65535
);
    
    wire signed	[15:0] sin_val_s;
    assign	sin_val_s	= {~sin_out[15], sin_out[14:0]};
    //window function
    wire	signed	[15:0]	win;
    Window_function_generator FIR_windows_function_inst(
        .clk		(clk),
        .rst_n		(rst_n),
    
        .en			(en),			//rising edge trigger
        .win_type	(win_type),		//
        .n			(n + 1'b1),		//length
        .lgn	    (lgn),
        .i			(i),			//index
    
        .busy		(),				//
        .win		(win)
    );

    //state 
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
            if(cnt >= 4'd12)begin////???cnt=7???????????firwin?????????firwin
                 next_state <= S_END;
            end 
            else begin
                 next_state <= S_CAL;
            end                
        end    
        S_END:begin
             next_state	<= S_IDLE;
        end	
        default: begin
             next_state	<= S_IDLE;
        end   
     endcase
    end
    wire signed [23:0]m_axis_dout_tdata;
    div_gen divide (
          .aclk(clk),
          .s_axis_divisor_tvalid(cnt==4'd5),    // input wire s_axis_divisor_tvalid
          .s_axis_divisor_tdata(s_mlti2_d1),      // input wire [15 : 0] s_axis_divisor_tdata
          .s_axis_dividend_tvalid(cnt==4'd5),  // input wire s_axis_dividend_tvalid
          .s_axis_dividend_tdata(sin_val_s),    // input wire [15 : 0] s_axis_dividend_tdata
          .m_axis_dout_tvalid(),          // output wire m_axis_dout_tvalid
          .m_axis_dout_tdata(m_axis_dout_tdata)            // output wire [23 : 0] m_axis_dout_tdata
        );
    reg [15:0]quot;
    always@(posedge clk)begin
          quot <= m_axis_dout_tdata[17:2];
    end 
    reg signed [31:0] firwin_buf = 32'sd256;
    reg signed [31:0] win_tmp = 32'sd256;
    always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                 firwin_buf	 <= 32'sd256;
            end 
            else if(cnt == 4'd7)begin
                if((~n[0])&&(i_buf == n/4'sd2))begin
                    firwin_buf <= (pi_phase * 16'sd804) >>> 8;	//3.1415=804/256
                 end
                 else begin
                    firwin_buf <= ({{16{quot[15]}}, quot}) * 4'sd2;
                 end
            end
//            else if(cnt == 4'd8)begin
//                if((~n[0])&&(i_buf == n/4'sd2))begin
//                    firwin_buf <= (win_tmp * 16'sd804) >>> 8;	//3.1415=804/256
//                 end
//                 else begin
//                    firwin_buf <= win_tmp * 4'sd2;
//                 end
//            end            
            else if(cnt == 4'd8)begin
                firwin_buf <= (firwin_buf * win)>>>16;
            end 
            else begin
                firwin_buf <= firwin_buf;
            end
         end
    //firwin_buf_d0  
    reg signed [15:0] firwin_buf_d0 = 16'sd256;
    always @(posedge clk) begin
        case(state)
        S_END: begin
            firwin_buf_d0	<= firwin_buf[15:0];
        end
        default: begin
            firwin_buf_d0	<= firwin_buf_d0;
        end
        endcase
    end
    assign firwin = firwin_buf_d0;     
      
   //busy_buf
    reg busy_buf = 1'b0;
    always @(*) begin
        case(state)
        S_IDLE: begin
            busy_buf <= 1'b0;
        end
        default: begin
            busy_buf <= 1'b1;
        end
        endcase
    end     
    assign busy = busy_buf;


endmodule