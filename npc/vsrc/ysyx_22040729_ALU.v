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
  output [DATA_WIDTH-1:0] result
);
assign result = src1 + src2;
endmodule
