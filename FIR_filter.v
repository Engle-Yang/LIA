`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module FIR_filter(

    input clk,
    input rst_n,
    input en,
    input [15:0]pi_phase,
    input [7:0] pace,
    input [3:0]  win_type,
    input [15:0] n,
    input [7:0]  lgn,
    input signed [15:0] data_in,
    output reg valid,
    output reg signed [15:0] data_out
    
    );
    wire busy;
    
    reg [15:0]cnt;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
              cnt <= 16'd0;
        end
        else if(cnt == pace - 1'b1) begin
              cnt <= 16'd0;
        end
        else begin
              cnt <= cnt + 1'b1;
        end
    end
    reg clk_s;   
   always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            clk_s <= 1'b0;
        end
        else if(cnt == pace - 1'b1) begin
            clk_s <= ~clk_s;
        end
        else begin
            clk_s <= clk_s;
        end
    end
    
    reg clk_s_r0;  
    reg clk_s_r1;
   always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
          clk_s_r0 <= 1'd0;
          clk_s_r1 <= 1'd0;
        end
        else begin
         clk_s_r1 <= clk_s_r0;
         clk_s_r0 <= clk_s;
        end
    end  
    
     reg clk_flag; 
     always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
          clk_flag <= 1'd0;
        end
        else begin
         clk_flag <= clk_s_r0 & !clk_s_r1;
        end
    end     
    parameter	      N = 256;	
    reg  signed [15:0] coeff[0:N];
    reg  [16*N+15:0]params = 0;
    wire signed [15:0] firwin;
    reg  signed	[15:0] shift_reg[0:N];
    
    reg [15:0]m; 
    //flag enables fir_win
    reg flag; 
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             flag <= 1'b0;
        end
        else if(en&&!busy) begin
             flag <= 1'b1; 
        end
        else if(en&&busy) begin
             flag <= 1'b0;
        end
    end
    //edge detection
    reg busy_r0;
    reg busy_r1;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             busy_r0 <= 1'b0;
             busy_r1 <= 1'b0;
        end 
        else begin
             busy_r0 <= busy;
             busy_r1 <= busy_r0;
        end
    end
    reg busy_rise;
    reg busy_fall;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             busy_rise <= 1'b0;
             busy_fall <= 1'b0;
        end 
        else begin
             busy_rise <= !busy_r1 & busy_r0;
             busy_fall <= busy_r1 & !busy_r0;
        end
    end
    
    //calculate nexr coeff
    reg [15:0]n_r;
    reg [15:0]win_type_r;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
                   n_r <= 16'b0;
            win_type_r <= 16'b0;
        end
        else  begin
                   n_r <= n;
            win_type_r <= win_type;   
       end    
    end 
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
                m <= 16'b0;
        end
        else if(n!=n_r || win_type!=win_type_r) begin
                m <= 1'b0;   
           params <= 0;
           end  
        else begin
            if(en&&busy_fall) begin
                    m <= m + 1'b1;
      params[((N-m)<<4)+: 16]<= firwin;
            end
            else if(m == n + 1'b1 ||m > n + 1'b1  ) begin
                    m <= 1'b0;
            end
        end
    end
    integer	p;
    always @(*) begin
        for(p=0; p<N+1; p=p+1) begin
            coeff[p] <= params[((N-p) << 4) +: 16];
        end
    end
    //valid
    reg [15:0]n_r_s;
    reg [15:0]win_type_r_s;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
                  n_r_s <= 16'b0;
           win_type_r_s <= 16'b0;
        end
        else if(clk_flag) begin
                  n_r_s <= n;
           win_type_r_s <= win_type;   
       end    
    end 
    reg [15:0]cnt2;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
                cnt2 <= 16'b0;
        end
        else  if(clk_flag) begin
        if(n!=n_r_s || win_type!=win_type_r_s)  begin
                cnt2 <= 16'b0;   
            end 
        else begin
            if(cnt2==n) begin
                cnt2 <= 16'b0;   
            end  
            else if(en) begin
                cnt2 <= cnt2 + 1'b1;
            end
            else begin
                 cnt2 <= cnt2;
            end
          end
        end
    end
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
                valid <= 1'b0;
        end
        else if(n!=n_r_s || win_type!=win_type_r_s||!en) begin
                valid <= 1'b0;   
           end  
        else if(en&&cnt2 == n) begin
                valid <= 1'b1;
        end
    end
    
    
    FIRwin_generator FIRwin_generator_inst(
        .clk		(clk),
        .rst_n		(rst_n),
        .pi_phase   (pi_phase),
        .en			(flag),			//rising edge trigger
        .win_type	(win_type),		//
        .n			(n),		//length
        .lgn	    (lgn),
        .i			(m),			//index
    
        .busy		(busy),				//
        .firwin		(firwin)
    );
    //sliding reg
    integer i;
    always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
          for(i=N; i>-1; i=i-1) begin
             shift_reg[i] <= 16'd0;
         end
    end
    else if(clk_flag)begin
            for(i=N; i>-1; i=i-1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
                shift_reg[0] <= data_in;
           end
    end
  
    //multiply
    reg	signed	[31:0] multi[0:N];
    integer	j;
    always @(posedge clk) begin
        for(j=0; j<N+1; j=j+1) begin
            multi[j] <= shift_reg[j] * coeff[j];
        end
    end
    
    //add
    reg	signed [47:0]sum[0:N];
    integer	k;
    // ?????
    always @(posedge clk) begin
        sum[0] <= multi[0];
        for (k = 1; k < N + 1; k = k + 1) begin
            sum[k] <= sum[k-1] + multi[k];
        end
    end
//??
        reg signed	[47:0]	sum_shift_s;
        always @(posedge clk) begin
            sum_shift_s <= sum[N]>>> 16;
            end   
         
        always @(posedge clk ) begin	
           if(sum_shift_s >= 32'sd32767) begin	//????????
                data_out <= 16'sd32767;
            end
            else if(sum_shift_s <= -32'sd32768) begin
                data_out <= -16'sd32768;
            end
            else begin
                data_out <= sum_shift_s[15:0];
            end
        end


endmodule
