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
module ysyx_040729_Decoder #(INST_WIDTH = 32, DATA_WIDTH = 64) (
  input  [INST_WIDTH-1:0] instruction,

  output ecall,
  output mret,
  output csr_enable,

  output rf_we,  
  output [2:0] rf_wdata_src,
  output [1:0] npc_src,
  output [1:0] alu_model,
  output alu_len_dw,
  output alu_src2_ri,
  output mem_wen,
  output [DATA_WIDTH-1:0] immediate
);

localparam NONE_TYPE = 3'd0;
localparam R_TYPE    = 3'd1;
localparam I_TYPE    = 3'd2;
localparam S_TYPE    = 3'd3;
localparam B_TYPE    = 3'd4;
localparam U_TYPE    = 3'd5;
localparam J_TYPE    = 3'd6;
localparam SYS_TYPE  = 3'd7;

wire [6:0] opcode;
assign opcode = instruction[6:0];

wire [2:0] inst_type;

assign ecall = instruction==32'h00000073;
assign mret  = instruction==32'h30200073;
assign csr_enable = inst_type==SYS_TYPE;

MuxKey #(12, 5, 11) opcode_decode (
  {rf_wdata_src, npc_src, alu_model, alu_len_dw, inst_type},
  opcode[6:2], {
  5'b01101, 3'b010, 2'b00, 2'b00, 1'b0, U_TYPE,     //LUI
  5'b00101, 3'b011, 2'b00, 2'b00, 1'b0, U_TYPE,     //AUIPC
  5'b11011, 3'b011, 2'b01, 2'b00, 1'b0, J_TYPE,     //JAL
  5'b11001, 3'b011, 2'b10, 2'b00, 1'b0, I_TYPE,     //JALR
  5'b11000, 3'b000, 2'b11, 2'b11, 1'b0, B_TYPE,     //BEQ
  5'b00000, 3'b001, 2'b00, 2'b00, 1'b0, I_TYPE,     //LB
  5'b01000, 3'b000, 2'b00, 2'b00, 1'b0, S_TYPE,     //SB
  5'b00100, 3'b000, 2'b00, 2'b10, 1'b0, I_TYPE,     //ADDI
  5'b01100, 3'b000, 2'b00, 2'b01, 1'b0, R_TYPE,     //ADD
  5'b00110, 3'b000, 2'b00, 2'b10, 1'b1, I_TYPE,     //ADDIW
  5'b01110, 3'b000, 2'b00, 2'b01, 1'b1, R_TYPE,     //ADDW
  5'b11100, 3'b100, 2'b00, 2'b00, 1'b0, SYS_TYPE}   //SYSTEM
);

MuxKey #(7, 3, 3) inst_type_decode (
  {rf_we, mem_wen, alu_src2_ri},
  inst_type, {
  R_TYPE,   1'b1, 1'b0, 1'b0,
  I_TYPE,   1'b1, 1'b0, 1'b1,
  S_TYPE,   1'b0, 1'b1, 1'b1,
  B_TYPE,   1'b0, 1'b0, 1'b0,
  U_TYPE,   1'b1, 1'b0, 1'b0,
  J_TYPE,   1'b1, 1'b0, 1'b0,
  SYS_TYPE, 1'b1, 1'b0, 1'b1}
);

assign immediate[63:31] = {33{instruction[31]}};
assign immediate[30:20] = inst_type==U_TYPE ? instruction[30:20] : {11{instruction[31]}};
assign immediate[19:12] = (inst_type==U_TYPE || inst_type==J_TYPE) ? instruction[19:12] : {8{instruction[31]}};
assign immediate[11:11] = (inst_type==I_TYPE || inst_type==S_TYPE) ? instruction[31] :
                          (inst_type==J_TYPE) ? instruction[20] :
                          (inst_type==B_TYPE) ? instruction[7] : 1'b0;
assign immediate[10: 5] = (inst_type==I_TYPE || inst_type==S_TYPE || inst_type==B_TYPE || inst_type==J_TYPE) ? instruction[30:25] : 6'b0;
assign immediate[ 4: 1] = (inst_type==I_TYPE || inst_type==J_TYPE) ? instruction[24:21] : (inst_type==S_TYPE || inst_type==B_TYPE) ? instruction[11:8] : 4'b0;
assign immediate[ 0: 0] = inst_type==I_TYPE ? instruction[20] : inst_type==S_TYPE ? instruction[7] : 1'b0;




endmodule
