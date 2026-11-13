`timescale 1ns/1ps


typedef struct packed
{
	logic 			block;		//MSB
	logic [7:0]		addr;
	logic [1:0]		byte_offset;
} addr_t;

typedef struct packed 
{
	logic 			en;
	logic [3:0] 	wen;
	addr_t			addr;
	logic [31:0]	din;
} import_t;

typedef struct packed 
{
	logic 			stall;
	logic [31:0]	dout;
} export_t;

`ifdef USE_SVA
typedef class rand_mempacket;
`endif



module tb_dualport_DFFRAM512x32();

	// ~~~~ testing ~~~~
	`ifdef LOCALTEST
		import tb_utils_pkg::*;
		testcase tc; 
		logic [31:0] tnum;
	`endif

	// ~~~~ Gate-level ~~~~
	`ifdef USE_POWER_PINS
		wire VPWR;
		wire VGND;
		assign VPWR = 1;
		assign VGND = 0;
	`endif

	// ~~~~ locals ~~~~
	localparam				CLK_PERIOD_NS	= 10;
	localparam int unsigned RAND_SEED		= 42;
	logic					clk,
							resetn;

	`ifdef USE_SVA
	rand_mempacket 			rpacket0, rpacket1;
	`endif
	import_t 				pA_in, pB_in; 
	export_t 				pA_out, pB_out; 

	// port operation is either {0-inactive, 1-R, 3-R/W}
	wire [1:0] pA_operation =	{1'b0, pA_in.en} | 
								{pA_in.en && (pA_in.wen !== 4'h0), 1'b0};

	// port operation is either {0-inactive, 1-R, 3-R/W}
	wire [1:0] pB_operation =	{1'b0, pB_in.en} | 
								{pB_in.en && (pB_in.wen !== 4'h0), 1'b0};
	
	// ~~~~	functions ~~~~
	function automatic import_t send_packet(input import_t driver, input import_t receiver);
		receiver = driver;
		return receiver; 
	endfunction
	// ~~~~	tasks ~~~~

	// ~~~~ instantiations ~~~~
	dualport_DFFRAM512x32 DUT
	(
		.clk_i		(clk),
		.rstn_i		(resetn),
		.pA_en_i	(pA_in.en),
		.pB_en_i	(pB_in.en),
		.pA_we_oh_i	(pA_in.wen),	// 4b
		.pB_we_oh_i	(pB_in.wen),	// 4b
		.pA_addr_i	(pA_in.addr),	// 11b
		.pB_addr_i	(pB_in.addr),	// 11b
		.pA_data_i	(pA_in.din),	// 32b
		.pB_data_i	(pB_in.din),	// 32b

		.pA_stall_o	(pA_out.stall),
		.pB_stall_o	(pB_out.stall),
		.pA_data_o	(pA_out.dout),	// 32b	
		.pB_data_o	(pB_out.dout)	// 32b

		`ifdef GATELEVEL
		,
		.VPWR		(VPWR),
		.VGND		(VGND)
		`endif
	);

	// ~~~~ heartbeat ~~~~
	always #(CLK_PERIOD_NS/2) clk = ~clk;

	// ~~~~ SVA ~~~~
	`ifdef USE_SVA

		// ~~ sequences (DNU w/ Icarus) ~~
		// ~~ properties (DNU w/ Icarus) ~~
		property porta_stall;
			@(posedge clk) disable iff(!resetn || $past(!resetn))
				($past(pA_out.stall) === 1'b1) |-> ($past(pA_in) === pA_in)
		endproperty

		property portb_stall;
			@(posedge clk) disable iff(!resetn || $past(!resetn))
				($past(pB_out.stall) === 1'b1) |-> ($past(pB_in) === pB_in)
		endproperty

		property stalls_allowed;
			@(posedge clk) disable iff(!resetn || $past(!resetn))
				!(pA_out.stall && pB_out.stall)
		endproperty

		property stall_required;
			@(posedge clk) disable iff(!resetn || $past(!resetn))
				(
					(pA_in.en && pB_in.en) &&
					(pA_in.addr.block === pB_in.addr.block)
				) |-> (pA_out.stall ^ pB_out.stall)
		endproperty

		// ~~ concurrents (DNU w/ Icarus) ~~
		userT_porta_hold_inputs_on_stall : assert property(porta_stall) else begin
			static string mes = "CC: upstream should have kept portA input data stable on stall";
			`ifdef	LOCALTEST tc.err(mes);
					$display("%0t\n", $time);
			`else	$display("%0t | %s\n", $time, mes);
			`endif
		end

		userT_portb_hold_inputs_on_stall : assert property(portb_stall) else begin
			static string mes = "CC: upstream should have kept portB input data stable on stall";
			`ifdef	LOCALTEST tc.err(mes);
					$display("%0t\n", $time);
			`else	$display("%0t | %s\n", $time, mes);
			`endif
		end

		ctrlT_at_most_one_stall: assert property(stalls_allowed) else begin
			static string mes = "CC: witnessed both port stalls";
			`ifdef	LOCALTEST tc.err(mes);
			`else	$display("%s\n",mes);
					$display("%0t\n", $time);
			`endif
		end

		ctrlT_stall_necessary: assert property(stall_required) else begin
			static string mes = "CC: didn't see a needed stall";
			`ifdef	LOCALTEST tc.err(mes);
			`else	$display("%s\n",mes);
					$display("%0t\n", $time);
			`endif
		end

	`endif

	// ~~~~ time-based testing ~~~~
	initial begin

		// ~~ waveforms ~~
		$dumpfile("tb_dualport_DFFRAM512x32.vcd");
		$dumpvars(0);

		// ~~ class instances ~~
		`ifdef LOCALTEST tc	= new(); `endif

		`ifdef USE_SVA
		rpacket0	= new();
		rpacket0.srandom(RAND_SEED);
		if(rpacket0.randomize() == 0)
			$fatal(1, "Couldn't get rand working");

		rpacket1	= new();
		rpacket1.srandom(RAND_SEED+1);
		if(rpacket1.randomize() == 0)
			$fatal(1, "Couldn't get rand working");
		`endif

		// ~~ defaults ~~
		clk 	= 1'b1;
		resetn	= 1'b0;
		pA_in	= '0;
		pB_in	= '0;

		// ~~ fresh start ~~
		repeat(10) begin @(posedge clk); end
		resetn	= 1'b1;
		repeat(2) begin @(posedge clk); end

		// ~~ immediates ~~
		`ifdef LOCALTEST
		tc.new_test("Basic Write");
		tnum = tc.get_testnum();
		`endif

			pA_in.en 		= 1'b1; 
			pA_in.wen		= 4'hF;
			pA_in.addr		= {1'b0, 8'hAB, 2'b00};
			pA_in.din		= 32'hDEAD_BEEF;

			pB_in.en 		= 1'b1; 
			pB_in.wen		= 4'b1001;
			pB_in.addr		= {1'b1, 8'h00, 2'b00};
			pB_in.din		= 32'h1337_1337;

			@(posedge clk);	// full cycle to write
			@(posedge clk);	// full cycle to read

			@(negedge clk);
			assert(pA_out.dout === 32'hDEAD_BEEF) else begin
				static string mes = "pA didn't W, then R correctly";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end
			assert(pB_out.dout === 32'h1300_0037) else begin
				static string mes = "pB didn't W, then R correctly";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end
			assert(pA_out.stall === 1'b0 && pB_out.stall === 1'b0) else begin
				static string mes = "unexpected stall occured";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end

			@(posedge clk); //alignment

		`ifdef LOCALTEST tc.test_done(); `endif


		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~
		
		`ifdef LOCALTEST
		tc.new_test("Basic Read from reverse port");
		tnum = tc.get_testnum();
		`endif

			// sanitize
			pA_in = '0; 
			pB_in = '0; 
			repeat(5) begin @(posedge clk); end
			
			pB_in.en 				= 1'b1; 
			pB_in.wen				= 4'h0;
			pB_in.addr.block		= 1'b0;
			pB_in.addr.addr			= 8'hAB;
			pB_in.addr.byte_offset	= 2'b00;

			pA_in.en 				= 1'b1; 
			pA_in.wen				= 4'h0;
			pA_in.addr.block		= 1'b1;
			pA_in.addr.addr			= 8'h00;
			pA_in.addr.byte_offset	= 2'b00;
			@(posedge clk); // full cycle to read

			@(negedge clk);
			assert(pB_out.dout === 32'hDEAD_BEEF) else begin
				static string mes = "pB didn't output correctly";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end
			assert(pA_out.dout === 32'h1300_0037) else begin
				static string mes = "pA didn't output correctly";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end
			assert(pA_out.stall === 1'b0 && pB_out.stall === 1'b0) else begin
				static string mes = "Unexpected stall occurred";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end

			@(posedge clk);
		`ifdef LOCALTEST tc.test_done(); `endif
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

		`ifdef LOCALTEST
		tc.new_test("First stall is default A");
		tnum = tc.get_testnum();
		`endif
			
			pA_in.en 	= 1'b1; 
			pA_in.wen	= 4'hF;
			pA_in.addr 	= {1'b0, 8'hAB, 2'b00};
			pA_in.din	= 32'hABCD_1234;

			pB_in.en 				= 1'b1; 
			pB_in.wen				= 4'h0;
			pB_in.addr = {1'b0, 8'h11, 2'b00};

			@(negedge clk); // stall(s) declared for next cycle 
			assert(pA_out.stall === 1'b1) else begin
				static string mes = "expected pA to stall";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end
			assert(pB_out.stall === 1'b0) else begin
				static string mes = "expected pB to NOT stall";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end

			@(posedge clk); // full cycle to read			
			pB_in.en = 1'b0; // dont stall B too

			@(negedge clk);
			assert(pB_out.dout === 32'h0000_0000) else begin
				static string mes = "expected pB to output old contents";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end

			@(negedge clk); // new data written and read
			assert(pA_out.dout === 32'hABCD_1234) else begin
				static string mes = "expected old value on pA";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end

			assert(pA_out.stall === 1'b0 && pB_out.stall === 1'b0) else begin
				static string mes = "expected no stalls";
				`ifdef 	LOCALTEST tc.err(mes);
				`else	$display("%s\n", mes);
				`endif
			end


			@(posedge clk); // alignment
		`ifdef LOCALTEST tc.test_done(); `endif

		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~

	`ifdef USE_SVA		
		`ifdef LOCALTEST
		tc.new_test("Rand testing on concurrents");
		tnum = tc.get_testnum();
		`endif

			repeat(100) @(posedge clk) begin
				rpacket0.randomize();
				rpacket1.randomize();

				pA_in = (!pA_out.stall) ?
							send_packet
							(
								.driver		(rpacket0.to_bus()),
								.receiver	(pA_in)
							) :
							pA_in;

				pB_in = (!pB_out.stall) ?
							send_packet
							(
								.driver		(rpacket1.to_bus()),
								.receiver	(pB_in)
							) :
							pB_in;
			end
		`ifdef LOCALTEST tc.test_done(); `endif
	`endif
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

		$finish();
	end

endmodule


`ifdef USE_SVA
class rand_mempacket;

	// ~~~~ parameters ~~~~
	rand bit 		block;
	rand bit [7:0]	addr;
	rand bit [1:0]	byte_offset; 
	rand bit 		en;
	rand bit [3:0]	wen;
	rand bit [31:0]	din; 

	// ~~~~ constraints (unsupported icarus)~~~~
	constraint align_addr{byte_offset == 2'b00;} // remain word aligned

	// ~~~~ methods ~~~~
	function automatic import_t to_bus();
		import_t t;
		
		t.addr.block		= block; 
		t.addr.addr			= addr; 
		t.addr.byte_offset	= byte_offset;

		t.en				= en;
		t.wen				= wen;

		t.din				= din;
		return t;
	endfunction
endclass
`endif

