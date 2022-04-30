/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-21 22:04
#
# Filename: ysyx_22040729_Memory.v
#
# Description: Memory 
#
=========================================================*/
module ysyx_22040729_Memory #(DATA_DEPTH = 1,INST_WIDTH = 32, DATA_WIDTH = 64)(
  input  clk,
  input  wen,
  input  [$clog2(DATA_DEPTH)-1:0] addr,
  input  [DATA_WIDTH-1:0] wdata,
  output reg [DATA_WIDTH-1:0] rdata,
  input  [$clog2(DATA_DEPTH)-1:0] iaddr,
  output reg [INST_WIDTH-1:0] irdata
);
reg [7:0] mem [DATA_DEPTH-1:0];

generate for(genvar i=0; i<DATA_WIDTH/8; i++)
  always @(posedge clk) begin
    rdata[8*i+7:8*i] <= mem[addr+i];
  end
endgenerate

generate for(genvar i=0; i<INST_WIDTH/8; i++)
  always @(posedge clk) begin
    irdata[8*i+7:8*i] <= mem[iaddr+i];
  end
endgenerate

generate for(genvar i=0; i<DATA_WIDTH/8; i++)
  always @(posedge clk) begin
    if (wen) mem[addr+i] <= wdata[8*i+7:8*i];
  end
endgenerate

endmodule
