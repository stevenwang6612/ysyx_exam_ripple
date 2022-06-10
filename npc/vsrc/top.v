/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-20 20:44
#
# Filename: top.v
#
# Description: top
#
=========================================================*/
module top(
  input  clk,
  input  rst
);
localparam DATA_WIDTH = 64;
localparam INST_WIDTH = 32;
localparam REG_ADDR_W = 5;
localparam MEM_BDEPTH = 65536;
localparam RESET_ADDR = 64'h80000000;


//Decoder
wire [INST_WIDTH-1:0] instruction;
wire [DATA_WIDTH-1:0] immediate;
wire rf_we, mem_wen, alu_src2_ri, alu_len_dw;
wire [1:0] rf_wdata_src, npc_src, alu_model;
ysyx_22040729_Decoder #(32, 64) Decoder_inst(
  .instruction  (instruction),
  .rf_we        (rf_we),
  .rf_wdata_src (rf_wdata_src),
  .npc_src      (npc_src),
  .alu_model    (alu_model),
  .alu_len_dw    (alu_len_dw),
  .mem_wen      (mem_wen),
  .alu_src2_ri  (alu_src2_ri),
  .immediate    (immediate)
);
export "DPI-C" function getINST;
function int unsigned getINST();
  return instruction;
endfunction

//PC
wire [DATA_WIDTH-1:0] pc_next, pc, snpc, dnpc, anpc, bnpc;
assign snpc = pc + 4;
assign dnpc = pc + immediate;
assign pc_next = npc_src== 2'b00 ? snpc :
                 npc_src== 2'b01 ? dnpc :
                 npc_src== 2'b10 ? anpc : bnpc;
Reg #(DATA_WIDTH, RESET_ADDR) PC_inst (clk, rst, pc_next, pc, 1);
export "DPI-C" function getPC;
function longint unsigned getPC();
  return pc;
endfunction

//memory
import "DPI-C" function void set_mem_ptr(input reg [7:0] a []);
initial set_mem_ptr(memory_inst.mem);
wire [$clog2(MEM_BDEPTH)-1:0] imem_addr, mem_addr;
wire [DATA_WIDTH-1:0] mem_rdata/*verilator split_var*/, mem_wdata, mem_rdata_temp, mem_wdata_temp;
ysyx_22040729_Memory #(MEM_BDEPTH, INST_WIDTH, DATA_WIDTH) memory_inst (
  .clk   (clk),
  .rst   (rst),
  .wen   (mem_wen),
  .addr  (mem_addr),
  .wdata (mem_wdata_temp),
  .rdata (mem_rdata_temp),
  .iaddr (imem_addr),
  .irdata(instruction)
);
assign imem_addr = pc[$clog2(MEM_BDEPTH)-1:0] - RESET_ADDR[$clog2(MEM_BDEPTH)-1:0];
assign mem_rdata[7:0] = mem_rdata_temp[7:0];
assign mem_rdata[15: 8] = alu_func3[1:0]==2'b00 ? alu_func3[2] ? '0 : { 8{mem_rdata[ 7]}} : mem_rdata_temp[15: 8];
assign mem_rdata[31:16] = alu_func3[1]==1'b0    ? alu_func3[2] ? '0 : {16{mem_rdata[15]}} : mem_rdata_temp[31:16];
assign mem_rdata[63:32] = alu_func3[1:0]!=2'b11 ? alu_func3[2] ? '0 : {32{mem_rdata[31]}} : mem_rdata_temp[63:32];
assign mem_wdata_temp[7:0] = mem_wdata[7:0];
assign mem_wdata_temp[15: 8] = alu_func3[1:0]==2'b00 ? {mem_rdata_temp[15: 8]} : mem_wdata[15: 8];
assign mem_wdata_temp[31:16] = alu_func3[1]==1'b0    ? {mem_rdata_temp[31:16]} : mem_wdata[31:16];
assign mem_wdata_temp[63:32] = alu_func3[1:0]!=2'b11 ? {mem_rdata_temp[63:32]} : mem_wdata[63:32];

//RegFile
import "DPI-C" function void set_gpr_ptr(input reg [63:0] a []);
initial set_gpr_ptr(RF_inst.rf);
wire [REG_ADDR_W-1:0] rf_waddr, rf_raddr1, rf_raddr2;
wire [DATA_WIDTH-1:0] rf_wdata, rf_rdata1, rf_rdata2;
ysyx_22040729_RegisterFile #(32, DATA_WIDTH) RF_inst (
  .clk    (clk),
  .rst   (rst),
  .wen    (rf_we),
  .waddr  (rf_waddr),
  .wdata  (rf_wdata),
  .raddr1 (rf_raddr1),
  .rdata1 (rf_rdata1),
  .raddr2 (rf_raddr2),
  .rdata2 (rf_rdata2)
);
assign rf_raddr1 = instruction[19:15];
assign rf_raddr2 = instruction[24:20];
assign rf_waddr  = instruction[11:7];
assign mem_wdata = rf_rdata2;

//ALU
wire [DATA_WIDTH-1:0] ALU_src1, ALU_src2, ALU_result;
wire [2:0] alu_func3;
wire [6:0] alu_func7;
ysyx_22040729_ALU #(DATA_WIDTH) ALU_inst (
  .src1         (ALU_src1),
  .src2         (ALU_src2),
  .alu_func3    (alu_func3),
  .alu_func7    (alu_func7),
  .alu_model    (alu_model),
  .alu_len_dw   (alu_len_dw),
  .result       (ALU_result)
);
assign alu_func3 = instruction[14:12];
assign alu_func7 = instruction[31:25];
assign ALU_src1 = rf_rdata1;
assign ALU_src2 = alu_src2_ri ? immediate : rf_rdata2;
assign rf_wdata = rf_wdata_src == 2'b00 ? ALU_result :
                  rf_wdata_src == 2'b01 ? mem_rdata  :
                  rf_wdata_src == 2'b10 ? immediate  :
                  |npc_src ? snpc : dnpc ;
assign mem_addr = ALU_result[$clog2(MEM_BDEPTH)-1:0];
assign anpc = ALU_result;
assign bnpc = ALU_result[0] ? dnpc : snpc;


endmodule
