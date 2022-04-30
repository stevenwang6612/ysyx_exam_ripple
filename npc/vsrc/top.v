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
localparam MEM_BDEPTH = 4096;
localparam RESET_ADDR = 64'h80000000;


//Decoder
wire [INST_WIDTH-1:0] instruction;
wire [DATA_WIDTH-1:0] immediate;
wire rf_we;
ysyx_22040729_Decoder #(32, 64) Decoder_inst(
  .instruction  (instruction),
  .rf_we        (rf_we),
  .immediate    (immediate)
);
export "DPI-C" function getINST;
function int unsigned getINST();
  return instruction;
endfunction

//PC
wire [DATA_WIDTH-1:0] pc_next, pc;
assign pc_next = pc + 4;
Reg #(DATA_WIDTH, RESET_ADDR) PC_inst (clk, rst, pc_next, pc, 1);
export "DPI-C" function getPC;
function longint unsigned getPC();
  return pc;
endfunction

//memory
import "DPI-C" function void set_mem_ptr(input reg [7:0] a []);
wire [$clog2(MEM_BDEPTH)-1:0] imem_addr;
wire [DATA_WIDTH-1:0] mem_rdata;
ysyx_22040729_Memory #(MEM_BDEPTH, INST_WIDTH, DATA_WIDTH) memory_inst (
  .clk   (clk),
  .wen   ('0),
  .addr  ('0),
  .wdata ('0),
  .rdata (mem_rdata),
  .iaddr (imem_addr),
  .irdata(instruction)
);
assign imem_addr = pc[$clog2(MEM_BDEPTH)-1:0] - RESET_ADDR[$clog2(MEM_BDEPTH)-1:0];
initial set_mem_ptr(memory_inst.mem);

//RegFile
import "DPI-C" function void set_gpr_ptr(input reg [63:0] a []);
wire [REG_ADDR_W-1:0] rf_waddr, rf_raddr1, rf_raddr2;
wire [DATA_WIDTH-1:0] rf_wdata, rf_rdata1, rf_rdata2;
ysyx_22040729_RegisterFile #(32, DATA_WIDTH) RF_inst (
  .clk    (clk),
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
initial set_gpr_ptr(RF_inst.rf);

//ALU
wire [DATA_WIDTH-1:0] ALU_src1, ALU_src2, ALU_result;
ysyx_22040729_ALU #(DATA_WIDTH) ALU_inst (
  .src1   (ALU_src1),
  .src2   (ALU_src2),
  .result (ALU_result)
);
assign ALU_src1 = rf_rdata1;
assign ALU_src2 = immediate;
assign rf_wdata = ALU_result;

endmodule
