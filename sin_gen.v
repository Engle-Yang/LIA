
module sin_gen(

    input			clk,
    input	[15:0]	phase,		//0~65535 [0~2pi)
    output	[15:0]	sin_out
);

//---------------------sin LUT-------------------------
wire	[7:0]	addr1;
wire	[7:0]	addr2;
wire	[15:0]	sin_dat1;
wire	[15:0]	sin_dat2;

//sin rom, 16bit, 256 depth
sin_rom sin_rom_inst1(
	.clka	(clk),
	.ena    (1'b1),
	.addra	(addr1),
	.douta	(sin_dat1)
);

sin_rom sin_rom_inst2(
	.clka	(clk),
	.ena    (1'b1),
	.addra	(addr2),
	.douta	(sin_dat2)
);

//----------linear interpolation-------------------
assign	addr1	= (phase>>8);
assign	addr2	= (phase>>8)+1;

wire	[15:0]	phase1;
wire	[15:0]	phase2;

assign	phase1	= addr1<<8;
assign	phase2	= addr2<<8;

reg		[15:0]	phase_d0;
reg		[15:0]	phase_d1;	//synchronization
reg		[15:0]	phase1_d0;
reg		[15:0]	phase1_d1;

always @(posedge clk) begin
	phase_d0	<= phase;
	phase_d1	<= phase_d0;

	phase1_d0	<= phase1;
	phase1_d1	<= phase1_d0;
end

reg     [31:0] multi_reg;
reg     [31:0] sin_out_reg;
// Step 1: Calculate multi
always @(posedge clk) begin
        if (sin_dat2 > sin_dat1) begin
            multi_reg <= (sin_dat2 - sin_dat1) * (phase_d1 - phase1_d1);
        end else begin
            multi_reg <= (sin_dat1 - sin_dat2) * (phase_d1 - phase1_d1);
        end
    end


// Step 2: Calculate sin_out
always @(posedge clk) begin
        if (sin_dat2 > sin_dat1) begin
            sin_out_reg <= sin_dat1 + (multi_reg >> 8);
        end else begin
            sin_out_reg <= sin_dat1 - (multi_reg >> 8);
        end
    end


// Assign outputs
assign sin_out = sin_out_reg;

endmodule
