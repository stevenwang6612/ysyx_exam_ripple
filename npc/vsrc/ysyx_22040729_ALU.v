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
module ysyx_22040729_ALU #(DATA_WIDTH = 64)(
  input  [DATA_WIDTH-1:0] src1,
  input  [DATA_WIDTH-1:0] src2,
  input  [2:0] alu_func3,
  input  [6:0] alu_func7,
  input  [1:0] alu_model,
  input  alu_len_dw,
  output [DATA_WIDTH-1:0] result
);
wire [DATA_WIDTH-1:0] result_before_dw;
assign result = alu_len_dw ? {{33{result_before_dw[31]}}, result_before_dw[30:0]} : result_before_dw;

wire [DATA_WIDTH-1:0] result_default, result_rbasic, result_ibasic, result_branch;
MuxKey #(4, 2, DATA_WIDTH) mux_lau_model (
  result_before_dw,
  alu_model, {
    2'b00, result_default,
    2'b01, result_rbasic,
    2'b10, result_ibasic,
    2'b11, result_branch}
);

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
wire [DATA_WIDTH-1:0] srla_result, srl_result, sra_result;
wire [DATA_WIDTH/2-1:0] srlw_result, sraw_result;
assign srlw_result = src1[DATA_WIDTH/2-1:0] >> src2[5:0];
assign sraw_result = $signed(src1[DATA_WIDTH/2-1:0]) >>> src2[5:0];
assign srl_result = alu_len_dw ? {{DATA_WIDTH/2{1'b0}}, srlw_result} : src1 >> src2[5:0];
assign sra_result = alu_len_dw ? {{DATA_WIDTH/2{1'b0}}, sraw_result} : $signed(src1) >>> src2[5:0];
assign srla_result = alu_func7[5] ? sra_result : srl_result;

//or
wire [DATA_WIDTH-1:0] or_result;
assign or_result = src1 | src2;

//and
wire [DATA_WIDTH-1:0] and_result;
assign and_result = src1 & src2;

//mul
wire [2*DATA_WIDTH-1:0] mul_src1, mul_src2, mul_result;
wire mul_src1_sign, mul_src2_sign;
assign mul_src1_sign = alu_func3[1:0]!=2'b11;
assign mul_src2_sign = !alu_func3[1];
assign mul_src1 = mul_src1_sign ? {{DATA_WIDTH{src1[DATA_WIDTH-1]}}, src1} : {{DATA_WIDTH{1'b0}}, src1};
assign mul_src2 = mul_src2_sign ? {{DATA_WIDTH{src2[DATA_WIDTH-1]}}, src2} : {{DATA_WIDTH{1'b0}}, src2};
assign mul_result = mul_src1 * mul_src2;

//div
wire [DATA_WIDTH-1:0] div_quo, div_rem, div_quo_temp, div_rem_temp, div_dividend, div_divisor;
wire div_sign;
ysyx_22040729_Divider #(DATA_WIDTH) divider_inst( 
  .dividend (div_dividend),
  .divisor  (div_divisor ),
  .quo      (div_quo_temp),
  .rem      (div_rem_temp)
);
assign div_sign = !alu_func3[0];
assign div_dividend = div_sign & src1[DATA_WIDTH-1] ? ~src1 + 1'b1 : src1;
assign div_divisor  = div_sign & src2[DATA_WIDTH-1] ? ~src2 + 1'b1 : src2;
assign div_quo      = (div_sign & (src1[DATA_WIDTH-1] ^ src2[DATA_WIDTH-1])) ? ~div_quo_temp + 1'b1 : div_quo_temp;
assign div_rem      = div_rem_temp;


//result_default
assign result_default = add_result[DATA_WIDTH-1:0];

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

//result_branch
MuxKey #(6, 3, 1) mux_branch (
  result_branch[0],
  alu_func3, {
    3'b000, !(|sub_result),              //beq 
    3'b001, |sub_result,                 //bne
    3'b100, sub_result[DATA_WIDTH-1],    //blt
    3'b101, !sub_result[DATA_WIDTH-1],   //bge
    3'b110, sub_result[DATA_WIDTH],      //bltu
    3'b111, !sub_result[DATA_WIDTH]}     //bgeu
);
assign result_branch[DATA_WIDTH-1:1] = '0;


endmodule
