module ysyx_040729_EXE_ALU_Divider#(
	parameter	DIVISOR_WIDTH		= 32,
	parameter	DIVIDEND_WIDTH		= 32
)(
	input  clock,
    input  reset,
	input  [DIVISOR_WIDTH-1:0]	dividend,
	input  [DIVIDEND_WIDTH-1:0]	divisor,
    input  div_valid,
    input  divw,
    input  flush,
    output div_ready,
    output out_valid,
	output [DIVIDEND_WIDTH-1:0]	quotient,
	output [DIVISOR_WIDTH-1:0]	remainder
);
wire [DIVISOR_WIDTH+DIVIDEND_WIDTH-1:0] dividend_shift, dividend_shift_next;
wire [DIVISOR_WIDTH-1:0]  divisor_shift;
wire [$clog2(DIVIDEND_WIDTH):0] cnt;
wire div_doing;
wire div_done = cnt==(divw?DIVIDEND_WIDTH/2:DIVIDEND_WIDTH);
assign div_ready = ~div_doing;
assign out_valid = div_done & div_doing;

Reg #(DIVISOR_WIDTH+DIVIDEND_WIDTH, {(DIVISOR_WIDTH+DIVIDEND_WIDTH){1'b0}}) dividend_shift_inst (clock, reset, dividend_shift_next, dividend_shift, div_valid | (div_doing&!div_done));
Reg #(DIVISOR_WIDTH, {(DIVISOR_WIDTH){1'b0}}) divisor_shift_inst (clock, reset, divw?{{DIVIDEND_WIDTH/2{1'b0}},divisor[DIVIDEND_WIDTH-1:DIVIDEND_WIDTH/2]}:divisor, divisor_shift, div_valid);
Reg #($clog2(DIVIDEND_WIDTH)+1, {($clog2(DIVIDEND_WIDTH)+1){1'b0}}) cnt_inst (clock, reset,
	div_valid ? {($clog2(DIVIDEND_WIDTH)+1){1'b0}} : cnt+1'b1, cnt, div_valid | div_doing);
Reg #(1, 1'b0) div_doing_inst (clock, reset, div_valid & div_ready & ~flush, div_doing, (div_valid & div_ready) | flush | div_done);
assign dividend_shift_next = div_valid ? {{(DIVISOR_WIDTH){1'b0}}, dividend} :
                             subres[DIVISOR_WIDTH] ? {dividend_shift[DIVISOR_WIDTH+DIVIDEND_WIDTH-2:0], 1'b0} :
							 {subres[DIVISOR_WIDTH-1:0], dividend_shift[DIVIDEND_WIDTH-2:0], 1'b1};

wire [DIVISOR_WIDTH:0] subres;
assign subres = {dividend_shift[DIVISOR_WIDTH+DIVIDEND_WIDTH-2:DIVIDEND_WIDTH-1]} - divisor_shift;//unsigned substract
assign remainder = dividend_shift[DIVISOR_WIDTH+DIVIDEND_WIDTH-1:DIVIDEND_WIDTH];
assign quotient  = dividend_shift[DIVIDEND_WIDTH-1:0];

/*
//==============================================================================================
//======								define signal									========
//==============================================================================================
    reg	[DIVISOR_WIDTH+DIVIDEND_WIDTH-1:0]		tempa	;	
    reg	[DIVISOR_WIDTH+DIVIDEND_WIDTH-1:0]		tempb	;	
	integer	i;
//==============================================================================================
//======                               behave of RTL                                    ========
//==============================================================================================
	//--------------------------------------------------------------------
	//------    	Calculation 						           	------
	//--------------------------------------------------------------------
	always @(dividend or divisor)begin 
		if(divisor != 0)begin
			tempa = {{DIVIDEND_WIDTH{1'b0}},dividend};  
			tempb = {divisor,{DIVISOR_WIDTH{1'b0}}};  
			for(i = 0;i < DIVISOR_WIDTH;i = i + 1)begin
				tempa = {tempa[0 +: (DIVISOR_WIDTH+DIVIDEND_WIDTH-1)],1'b0};
				if(tempa[DIVISOR_WIDTH +: DIVIDEND_WIDTH] >= divisor)begin
					tempa = tempa - tempb + 1;
				end else begin
					tempa = tempa;
				end
			end
			quotient 	= tempa[0 +: DIVISOR_WIDTH];
			remainder 	= tempa[DIVISOR_WIDTH +: DIVIDEND_WIDTH];
			//$display("@%10t : dividend is %d,divisor is %d/n", $time,dividend,divisor);
			//$display("@%10t : quotient is %d,remainder is %d/n", $time,quotient,remainder);
		end else begin
			quotient	= {DIVISOR_WIDTH{1'b0}};
			remainder	= {DIVIDEND_WIDTH{1'b0}};
			tempa = 0;
			tempb = 0;
			//$display("@%10t : divisor is not a valid value ...", $time);
		end
	end
	*/
	
endmodule
