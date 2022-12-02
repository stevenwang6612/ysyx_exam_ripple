module ysyx_040729_EXE_ALU_Divider#(
	 parameter	DIVISOR_WIDTH		= 32
	,parameter	DIVIDEND_WIDTH		= 32
)(
	 input	wire	[DIVISOR_WIDTH-1:0]		dividend
	,input	wire	[DIVIDEND_WIDTH-1:0]	divisor
	//------------------------------------------------//
	,output	reg		[DIVISOR_WIDTH-1:0]		quotient	
	,output	reg		[DIVIDEND_WIDTH-1:0]	remainders
);
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
			remainders 	= tempa[DIVISOR_WIDTH +: DIVIDEND_WIDTH];
			//$display("@%10t : dividend is %d,divisor is %d/n", $time,dividend,divisor);
			//$display("@%10t : quotient is %d,remainders is %d/n", $time,quotient,remainders);
		end else begin
			quotient	= {DIVISOR_WIDTH{1'b0}};
			remainders	= {DIVIDEND_WIDTH{1'b0}};
			tempa = 0;
			tempb = 0;
			//$display("@%10t : divisor is not a valid value ...", $time);
		end
	end
	
endmodule
