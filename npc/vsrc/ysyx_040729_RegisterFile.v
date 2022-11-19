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
module ysyx_040729_RegisterFile #(REGI_DEPTH = 32, DATA_WIDTH = 64) (
  input  clk,
  input  rst,
  input  wen,
  input  [$clog2(REGI_DEPTH)-1:0] waddr,
  input  [$clog2(REGI_DEPTH)-1:0] raddr1,
  input  [$clog2(REGI_DEPTH)-1:0] raddr2,
  input  [DATA_WIDTH-1:0] wdata,
  output reg [DATA_WIDTH-1:0] rdata1,
  output reg [DATA_WIDTH-1:0] rdata2
);
reg [DATA_WIDTH-1:0] rf [REGI_DEPTH-1:0];

always @(*) begin
  rdata1 = rst ? '0 : raddr1=='0 ? '0 : rf[raddr1];
end

always @(*) begin
  rdata2 = rst ? '0 : raddr2=='0 ? '0 : rf[raddr2];
end

always @(posedge clk) begin
  if (wen&!rst) rf[waddr] <= waddr=='0 ? '0 : wdata;
end
endmodule
