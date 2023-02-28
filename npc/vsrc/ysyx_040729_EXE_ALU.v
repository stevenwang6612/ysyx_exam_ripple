/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-21 22:23
#
# Filename: ysyx_22040729_ALU.v
#
# Description: 
#
=========================================================*/
module ysyx_040729_EXE_ALU #(DATA_WIDTH = 64)(
  input  clock,
  input  reset,
  input  exe_flow,
  input  [DATA_WIDTH-1:0] src1,
  input  [DATA_WIDTH-1:0] src2,
  input  [2:0] alu_func3,
  input  [6:0] alu_func7,
  input  alu_src2_ri,
  input  alu_len_dw,

  input  mem_hazard,
  output alu_busy,
  output [DATA_WIDTH-1:0] result
);
wire [DATA_WIDTH-1:0] result_before_dw;
assign result = alu_len_dw ? {{33{result_before_dw[31]}}, result_before_dw[30:0]} : result_before_dw;

wire [DATA_WIDTH-1:0] result_rbasic, result_ibasic;
assign result_before_dw = alu_src2_ri ? result_ibasic : result_rbasic;

//add
wire [DATA_WIDTH:0] add_result;
assign add_result = src1 + src2;

//sub
wire [DATA_WIDTH:0] sub_result;
assign sub_result = src1 - src2;

//sll
wire [DATA_WIDTH-1:0] sll_result;
assign sll_result = src1 << src2[5:0];

//slt
wire [DATA_WIDTH-1:0] slt_result;
assign slt_result = {{DATA_WIDTH-1{1'b0}}, sub_result[DATA_WIDTH-1]};

//sltu
wire [DATA_WIDTH-1:0] sltu_result;
assign sltu_result = {{DATA_WIDTH-1{1'b0}}, sub_result[DATA_WIDTH]};

//xor
wire [DATA_WIDTH-1:0] xor_result;
assign xor_result = src1 ^ src2;

//srl(a)
wire [DATA_WIDTH-1:0] srla_result, srl_result, sra_result, srl_result_t, srlw_result_t, sra_result_t, sraw_result_t, eff_mask, eff_mask_w;
wire [5:0] shift_amount = {alu_len_dw ? 1'b0 : src2[5], src2[4:0]};
assign eff_mask = {DATA_WIDTH{1'b1}} >> shift_amount;
assign eff_mask_w = {{DATA_WIDTH/2{1'b0}}, eff_mask[DATA_WIDTH-1:DATA_WIDTH/2]};
assign srl_result_t = src1 >> shift_amount;
assign srlw_result_t = srl_result_t & eff_mask_w;
assign sra_result_t = (srl_result_t & eff_mask) | ({DATA_WIDTH{src1[DATA_WIDTH-1]}} & (~eff_mask));
assign sraw_result_t = (srl_result_t & eff_mask_w) | ({DATA_WIDTH{src1[DATA_WIDTH/2-1]}} & (~eff_mask_w));
assign srl_result = alu_len_dw ? srlw_result_t : srl_result_t;
assign sra_result = alu_len_dw ? sraw_result_t : sra_result_t;
assign srla_result = alu_func7[5] ? sra_result : srl_result;

//or
wire [DATA_WIDTH-1:0] or_result;
assign or_result = src1 | src2;

//and
wire [DATA_WIDTH-1:0] and_result;
assign and_result = src1 & src2;

//mul
wire [2*DATA_WIDTH-1:0] mul_result;
wire mul_src1_sign, mul_src2_sign;
wire mul_cal, mul_ready, mul_out_valid, mul_valid;
Reg #(1, 1'b0) mul_cal_inst (clock, reset, exe_flow, mul_cal, exe_flow | mul_out_valid);
wire mul_busy = {alu_func7[0],alu_func3[2]}==2'b10 & mul_cal & !mul_out_valid & ~mem_hazard;
assign mul_valid = {alu_func7[0],alu_func3[2]}==2'b10 & mul_cal & mul_ready & ~mem_hazard;
assign mul_src1_sign = alu_func3[1:0]!=2'b11;
assign mul_src2_sign = !alu_func3[1];
ysyx_040729_EXE_ALU_Multiplier #(DATA_WIDTH) multiplier_inst(
  .clock          (clock),
	.reset          (reset),
	.mul_valid      (mul_valid),
	.flush          (exe_flow),
	.mulw	          (alu_len_dw),
	.mul_signed     ({mul_src1_sign, mul_src2_sign}),
	.multiplicand   (src1),
	.multiplier     (src2),
	.mul_ready      (mul_ready),
	.out_valid      (mul_out_valid),
	.result_hi      (mul_result[127:64]),
	.result_lo      (mul_result[63:0])
);

//div
wire [DATA_WIDTH-1:0] div_quo, div_rem, div_quo_temp, div_rem_temp, div_dividend, div_divisor;
wire div_sign;
wire div_cal, div_ready, div_out_valid, div_valid;
Reg #(1, 1'b0) div_cal_inst (clock, reset, exe_flow, div_cal, exe_flow | div_out_valid);
wire div_busy = {alu_func7[0],alu_func3[2]}==2'b11 & div_cal & !div_out_valid & ~mem_hazard;
assign div_valid = {alu_func7[0],alu_func3[2]}==2'b11 & div_cal & div_ready & ~mem_hazard;

ysyx_040729_EXE_ALU_Divider #(DATA_WIDTH, DATA_WIDTH) divider_inst( 
  .clock       (clock),
  .reset       (reset),
  .dividend    (div_dividend),
  .divisor     (div_divisor),
  .div_valid   (div_valid),
  .divw        (alu_len_dw),
  .flush       (exe_flow),
  .div_ready   (div_ready),
  .out_valid   (div_out_valid),
  .quotient    (div_quo_temp),
  .remainder   (div_rem_temp)
);
wire [DATA_WIDTH-1:0] div_dividend_t = alu_len_dw ? {src1[DATA_WIDTH/2-1:0], {DATA_WIDTH/2{1'b0}}} : src1;
wire [DATA_WIDTH-1:0] div_divisor_t  = alu_len_dw ? {src2[DATA_WIDTH/2-1:0], {DATA_WIDTH/2{1'b0}}} : src2;
assign div_sign = !alu_func3[0];
assign div_dividend = div_sign & div_dividend_t[DATA_WIDTH-1] ? ~div_dividend_t + 1'b1 : div_dividend_t;
assign div_divisor  = div_sign & div_divisor_t[DATA_WIDTH-1] ? ~div_divisor_t + 1'b1 : div_divisor_t;
assign div_quo      = (div_sign & (div_dividend_t[DATA_WIDTH-1] ^ div_divisor_t[DATA_WIDTH-1])) ? ~div_quo_temp + 1'b1 : div_quo_temp;
assign div_rem      = (div_sign & div_dividend_t[DATA_WIDTH-1]) ? ~div_rem_temp + 1'b1 : div_rem_temp;

assign alu_busy = mul_busy | div_busy;

//result_rbasic
MuxKey #(16, 4, DATA_WIDTH) mux_rbasic (
  result_rbasic,
  {alu_func7[0],alu_func3}, {
    4'b0000, alu_func7[5] ? sub_result[DATA_WIDTH-1:0] : add_result[DATA_WIDTH-1:0], //add sub
    4'b0001, sll_result,    //sll
    4'b0010, slt_result,    //slt
    4'b0011, sltu_result,   //sltu
    4'b0100, xor_result,    //xor
    4'b0101, srla_result,   //srl(a)
    4'b0110, or_result,     //or
    4'b0111, and_result,    //and
    4'b1000, mul_result[DATA_WIDTH-1:0],              //mul
    4'b1001, mul_result[2*DATA_WIDTH-1:DATA_WIDTH],   //mulh
    4'b1010, mul_result[2*DATA_WIDTH-1:DATA_WIDTH],   //mulhsu
    4'b1011, mul_result[2*DATA_WIDTH-1:DATA_WIDTH],   //mulsu
    4'b1100, div_quo,                                 //div
    4'b1101, div_quo,                                 //divu
    4'b1110, div_rem,                                 //rem
    4'b1111, div_rem}                                 //remu
);

//result_ibasic
MuxKey #(8, 3, DATA_WIDTH) mux_ibasic (
  result_ibasic,
  alu_func3, {
    3'b000, add_result[DATA_WIDTH-1:0],  //addi
    3'b001, sll_result,                  //slli
    3'b010, slt_result,                  //slti
    3'b011, sltu_result,                 //sltui
    3'b100, xor_result,                  //xori
    3'b101, srla_result,                 //srl(a)i
    3'b110, or_result,                   //ori
    3'b111, and_result}                  //andi
);



endmodule
