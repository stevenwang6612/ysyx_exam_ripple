module ysyx_040729_EXE_ALU_Multiplier#(
	 parameter	Multiplier_WIDTH		= 64
)(
	input	wire         clock		,//	时钟信号
	input	wire         reset		,//	复位信号（高有效）
	input	wire         mul_valid	,//	为高表示输入的数据有效，如果没有新的乘法输入，在乘法被接受的下一个周期要置低
	input	wire         flush		,//	为高表示取消乘法
	input	wire         mulw		,//	为高表示是 32 位乘法
	input	wire  [1:0]  mul_signed	,//	2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
	input	wire  [Multiplier_WIDTH-1:0]   multiplicand	,//	被乘数，xlen 表示乘法器位数
	input	wire  [Multiplier_WIDTH-1:0]   multiplier	,//	乘数
	output	wire         mul_ready	,//	为高表示乘法器准备好，表示可以输入数据
	output	wire         out_valid	,//	为高表示乘法器输出的结果有效
	output	wire  [Multiplier_WIDTH-1:0]   result_hi,//	高 xlen bits 结果
	output	wire  [Multiplier_WIDTH-1:0]   result_lo //	低 xlen bits 结果
);

wire[Multiplier_WIDTH*2+3:0] x_ext;
wire[Multiplier_WIDTH+2:0]   y_ext;//for booth:++

assign x_ext = mulw ? {(mul_signed[1] ? {(Multiplier_WIDTH+36){multiplicand[31]}} : {(Multiplier_WIDTH+36){1'b0}}), multiplicand[31:0]} :
						{(mul_signed[1] ? {(Multiplier_WIDTH+4){multiplicand[63]}} : {(Multiplier_WIDTH+4){1'b0}}), multiplicand};
assign y_ext = mulw ? {(mul_signed[0] ? {34{multiplier[31]}} : 34'b0), multiplier[31:0], 1'b0} :
						{(mul_signed[0] ? {2{multiplier[63]}} : 2'b0), multiplier, 1'b0};

wire mul_doing;
wire [Multiplier_WIDTH*2+3:0] res;
wire [Multiplier_WIDTH+2  :0] y_shift;
wire [Multiplier_WIDTH*2+3:0] x_shift;
wire [5:0]                    cnt;

wire[131:0] x_comp = (~x_shift) + 1;
wire[131:0] z = {132{y_shift[2:0] == 3'b000 || y_shift[2:0] == 3'b111}} & 132'b0  |
  				{132{y_shift[2:0] == 3'b001 || y_shift[2:0] == 3'b010}} & x_shift |
  				{132{y_shift[2:0] == 3'b101 || y_shift[2:0] == 3'b110}} & x_comp  |
  				{132{y_shift[2:0] == 3'b011}} & {x_shift[130:0], 1'b0}            |
  				{132{y_shift[2:0] == 3'b100}} & {x_comp[130:0], 1'b0};

assign mul_ready = ~mul_doing;
wire mul_done = ~|y_shift | cnt==(mulw?6'd17:6'd33);
assign out_valid = mul_done & mul_doing;
Reg #(Multiplier_WIDTH*2+4, {(Multiplier_WIDTH*2+4){1'b0}}) x_shift_inst (clock, reset, mul_valid ? x_ext : x_shift<<2, x_shift, mul_valid | mul_doing);
Reg #(Multiplier_WIDTH+3, {(Multiplier_WIDTH+3){1'b0}}) y_shift_inst (clock, reset, mul_valid ? y_ext : y_shift>>2, y_shift, mul_valid | mul_doing);
Reg #(Multiplier_WIDTH*2+4, {(Multiplier_WIDTH*2+4){1'b0}}) res_inst (clock, reset, mul_valid ? {(Multiplier_WIDTH*2+4){1'b0}} : z + res, res, mul_valid | (mul_doing&!mul_done));
Reg #(6, 6'b0) cnt_inst (clock, reset, mul_valid ? 6'b0 : cnt+1'b1, cnt, mul_valid | mul_doing);
Reg #(1, 1'b0) mul_doing_inst (clock, reset, mul_valid & mul_ready & ~flush, mul_doing, (mul_valid & mul_ready) | flush | mul_done);

 
assign result_hi = res[127:64];
assign result_lo = res[63:0];

	
endmodule
