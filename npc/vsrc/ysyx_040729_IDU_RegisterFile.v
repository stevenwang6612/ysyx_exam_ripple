/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified:	2022-04-20 20:49
#
# Filename:		ysyx_22040729_RegisterFile.v
#
# Description: RegisterFile
#
=========================================================*/
module ysyx_040729_IDU_RegisterFile #(REGI_DEPTH = 32, DATA_WIDTH = 64) (
  input  clock,
  input  reset,
  input  wen,
  input  [$clog2(REGI_DEPTH)-1:0] waddr,
  input  [$clog2(REGI_DEPTH)-1:0] raddr1,
  input  [$clog2(REGI_DEPTH)-1:0] raddr2,
  input  [DATA_WIDTH-1:0] wdata,
  output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2
);
reg [DATA_WIDTH-1:0] rf [REGI_DEPTH-1:0];

assign rdata1 = reset ? '0 : raddr1=='0 ? '0 : (wen & raddr1==waddr) ? wdata : rf[raddr1];

assign rdata2 = reset ? '0 : raddr2=='0 ? '0 : (wen & raddr2==waddr) ? wdata : rf[raddr2];

always @(posedge clock) begin
  if (wen&!reset) rf[waddr] <= waddr=='0 ? '0 : wdata;
end
endmodule
