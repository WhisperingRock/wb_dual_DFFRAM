/*
*	Purpose :	Vertically combine two DFFRAM256x32 macros
*				for 512x32 = 2k RAM module. Collision avoidance
*				included.
*	
*	Author :	WhisperingRock
*
*	Version:	0.1
*/ 
`timescale 1ns/1ps

module dualport_DFFRAM512x32
(
	input logic 		clk_i,
	input logic			rstn_i,
	input logic 		pA_en_i,	pB_en_i,
	input logic [3:0]	pA_we_oh_i,	pB_we_oh_i,
	input logic [10:0]	pA_addr_i,	pB_addr_i, //byte offset [1:0] ignored 
	input logic [31:0]	pA_data_i,	pB_data_i,

	output logic 		pA_stall_o, pB_stall_o,
	output logic [31:0] pA_data_o,	pB_data_o
);

	// ~~~~ local vars ~~~~
	// ~~ mux signals ~~
	logic	sel_in_0,
			sel_in_1,
			sel_out_A_curr,
			sel_out_A_next,
			sel_out_B_curr,
			sel_out_B_next;

	logic [3:0]		we_ram0,		we_ram1;
	logic 			en_ram0,		en_ram1;
	logic [7:0]		addr_ram0,		addr_ram1;
	logic [31:0]	din_ram0,		din_ram1;
	logic [31:0]	dout_ram0_c,	dout_ram0_n,
					dout_ram1_c, 	dout_ram1_n;

	// ~~ collision signals ~~ 
	logic	stale_port_curr,
			stale_port_next;

	logic	pA_block_id, 
			pB_block_id;
	assign	pA_block_id = pA_addr_i[10];
	assign	pB_block_id = pB_addr_i[10];

	logic port_collision; 
	assign port_collision	= (
								(pA_en_i && pB_en_i) &&
								(pA_block_id == pB_block_id)
							);

	// ~~~~ instantiations ~~~~
	DFFRAM256x32 RAM0(
        .CLK(clk_i),
        .WE0(we_ram0),
        .EN0(en_ram0),
        .Di0(din_ram0),
        .Do0(dout_ram0_n),
        .A0(addr_ram0)
	);

	DFFRAM256x32 RAM1(
        .CLK(clk_i),
        .WE0(we_ram1),
        .EN0(en_ram1),
        .Di0(din_ram1),
        .Do0(dout_ram1_n),
        .A0(addr_ram1)
	);

	// ~~~~ synch logic ~~~~
	always_ff @(posedge clk_i) begin

		// priority 0 : reset
		if(rstn_i == 1'b0) begin
			stale_port_curr <= 1'b0;
		end

		// priority 1 : active
		else begin
			stale_port_curr	<= stale_port_next;
			sel_out_A_curr	<= sel_out_A_next;
			sel_out_B_curr	<= sel_out_B_next;

			dout_ram0_c 	<= dout_ram0_n; 
			dout_ram1_c 	<= dout_ram1_n; 
		end
	end

	// ~~~~ comb logic ~~~~
	always_comb begin

		// ~~ defaults ~~
		sel_in_0			= 1'b0;
		sel_out_A_next		= 1'b0;
		sel_in_1			= 1'b1;
		sel_out_B_next		= 1'b1;

		pA_stall_o			= 1'b0;
		pB_stall_o			= 1'b0;

		stale_port_next		= stale_port_curr;

		if(port_collision) begin
			sel_in_0 		= stale_port_curr;
			sel_out_A_next	= stale_port_curr;
			sel_in_1 		= !stale_port_curr;
			sel_out_B_next	= !stale_port_curr;

			pA_stall_o		= stale_port_curr;
			pB_stall_o		= !stale_port_curr;

			stale_port_next	= !stale_port_curr; // alternate priority
		end

		// ... or some port is active
		else if(pA_en_i || pB_en_i) begin

			// if both en, the block num decides SEL
			if(pA_en_i && pB_en_i) begin
				if(pA_block_id == 1'b1) begin
					sel_in_0			= pA_block_id;
					sel_out_A_next		= pA_block_id;
					sel_in_1			= !pA_block_id;
					sel_out_B_next		= !pA_block_id;
				end
				else begin
					sel_in_0			= !pB_block_id;
					sel_out_A_next		= !pB_block_id;
					sel_in_1			= pB_block_id;
					sel_out_B_next		= pB_block_id;
				end
			end
			// only portA's block id maters
			else if(pA_en_i) begin
				sel_in_0			= pA_block_id;
				sel_out_A_next		= pA_block_id;
				sel_in_1			= !pA_block_id;
				sel_out_B_next		= !pA_block_id;
			end
			// only portB's block id maters
			else begin
				sel_in_0			= !pB_block_id;
				sel_out_A_next		= !pB_block_id;
				sel_in_1			= pB_block_id;
				sel_out_B_next		= pB_block_id;
			end
		end

		// ... or no port is active
		else begin end


		// mux logic
		if(sel_in_0 == 1'b0) begin
			en_ram0		= pA_en_i; 
			we_ram0		= pA_we_oh_i;
			addr_ram0	= pA_addr_i[9:2];
			din_ram0	= pA_data_i;
		end
		else begin
			en_ram0		= pB_en_i; 
			we_ram0		= pB_we_oh_i;
			addr_ram0	= pB_addr_i[9:2];
			din_ram0	= pB_data_i;
		end

		if(sel_in_1 == 1'b0) begin
			en_ram1		= pA_en_i; 
			we_ram1		= pA_we_oh_i;
			addr_ram1	= pA_addr_i[9:2];
			din_ram1	= pA_data_i;
		end
		else begin
			en_ram1		= pB_en_i; 
			we_ram1		= pB_we_oh_i;
			addr_ram1	= pB_addr_i[9:2];
			din_ram1	= pB_data_i;
		end

		pA_data_o = (sel_out_A_curr == 1'b0) ? dout_ram0_c : dout_ram1_c;
		pB_data_o = (sel_out_B_curr == 1'b0) ? dout_ram0_c : dout_ram1_c;

	end

endmodule
