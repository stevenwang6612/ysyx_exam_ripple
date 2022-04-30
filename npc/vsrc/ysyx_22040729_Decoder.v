/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-21 22:16
#
# Filename: ysyx_22040729_Decoder.v
#
# Description: 
#
=========================================================*/
module ysyx_22040729_Decoder #(INST_WIDTH = 32, DATA_WIDTH = 64) (
  input  [INST_WIDTH-1:0] instruction,
  output rf_we,
  output [DATA_WIDTH-1:0] immediate
);

localparam NONE_TYPE = 3'd0;
localparam R_TYPE    = 3'd1;
localparam I_TYPE    = 3'd2;
localparam S_TYPE    = 3'd3;
localparam B_TYPE    = 3'd4;
localparam U_TYPE    = 3'd5;
localparam J_TYPE    = 3'd6;
localparam SPEC_TYPE = 3'd7;

wire [6:0] opcode;
assign opcode = instruction[6:0];

wire [2:0] inst_type;

MuxKey #(2, 5, 3) opcode_decode (
  inst_type, 
  opcode[6:2], {
  5'b00100, 3'd2,
  5'b11100, 3'd7}
);

MuxKey #(6, 3, 1) inst_type_decode (
  {rf_we},
  inst_type, {
  3'd1, 1'b1,
  3'd2, 1'b1,
  3'd3, 1'b0,
  3'd4, 1'b0,
  3'd5, 1'b1,
  3'd6, 1'b1}
);

assign immediate[63:31] = {33{instruction[31]}};
assign immediate[30:20] = inst_type==U_TYPE ? instruction[30:20] : {11{instruction[31]}};
assign immediate[19:12] = (inst_type==U_TYPE || inst_type==J_TYPE) ? instruction[19:12] : {8{instruction[31]}};
assign immediate[11:11] = (inst_type==I_TYPE || inst_type==S_TYPE) ? instruction[31] :
                          (inst_type==J_TYPE) ? instruction[20] :
                          (inst_type==B_TYPE) ? instruction[7] : 1'b0;
assign immediate[10: 5] = (inst_type==I_TYPE || inst_type==S_TYPE || inst_type==B_TYPE || inst_type==J_TYPE) ? instruction[30:25] : 6'b0;
assign immediate[ 4: 1] = inst_type==I_TYPE ? instruction[24:21] : (inst_type==S_TYPE || inst_type==B_TYPE) ? instruction[11:8] : 4'b0;
assign immediate[ 0: 0] = inst_type==I_TYPE ? instruction[20] : inst_type==S_TYPE ? instruction[7] : 1'b0;




endmodule
