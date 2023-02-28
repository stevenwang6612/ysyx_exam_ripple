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
  input  clock,
  input  reset,

  // Advanced eXtensible Interface
    input                               axi_aw_ready_i,              
    output                              axi_aw_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o,
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o,
    output [7:0]                        axi_aw_len_o,
    output [2:0]                        axi_aw_size_o,
    output [1:0]                        axi_aw_burst_o,

    input                               axi_w_ready_i,                
    output                              axi_w_valid_o,
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o,
    output [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_o,
    output                              axi_w_last_o,
    
    output                              axi_b_ready_o,                
    input                               axi_b_valid_i,
    input  [1:0]                        axi_b_resp_i,                 
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i,

    input                               axi_ar_ready_i,                
    output                              axi_ar_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o,
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o,
    output [7:0]                        axi_ar_len_o,
    output [2:0]                        axi_ar_size_o,
    output [1:0]                        axi_ar_burst_o,
    
    output                              axi_r_ready_o,                 
    input                               axi_r_valid_i,                
    input  [1:0]                        axi_r_resp_i,
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i,
    input                               axi_r_last_i,
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i,

    output                              exec_once
);
localparam DATA_WIDTH = 64;
localparam ADDR_WIDTH = 32;
localparam INST_WIDTH = 32;
localparam REG_ADDR_W = 5;
localparam RESET_ADDR = 64'h80000000;
localparam RW_DATA_WIDTH    = 256;
localparam AXI_DATA_WIDTH   = 64;
localparam AXI_ADDR_WIDTH   = 32;
localparam AXI_ID_WIDTH     = 4;
localparam AXI_STRB_WIDTH   = AXI_DATA_WIDTH/8;

 wire if_valid, if_ready, mem_valid, mem_ready, mem_wen;
 wire fence;
 wire [2:0] mem_size;
 wire [INST_WIDTH-1:0]    if_data_read;
 wire [ADDR_WIDTH-1:0]    if_addr;
 wire [ADDR_WIDTH-1:0]    mem_addr;
 wire [DATA_WIDTH-1:0]    mem_data_read, mem_data_write;

 wire [DATA_WIDTH-1:0]    pc_vis, pc_out;
 wire [INST_WIDTH-1:0]    instruction_vis, instruction_out;

ysyx_040729_CPU #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH),
  .INST_WIDTH(INST_WIDTH),
  .REG_ADDR_W(REG_ADDR_W),
  .RESET_ADDR(RESET_ADDR)
)cpu_inst(
  .clock       (clock),
  .reset       (reset),
  .fence_o     (fence),

  .mem_valid       (mem_valid),
  .mem_ready       (mem_ready),
  .mem_data_read   (mem_data_read),
  .mem_data_write  (mem_data_write),
  .mem_addr        (mem_addr),
  .mem_size        (mem_size),
  .mem_wen         (mem_wen),

  .if_valid        (if_valid),
  .if_ready        (if_ready),
  .if_data_read    (if_data_read),
  .if_addr         (if_addr)
);
Reg #(INST_WIDTH, {INST_WIDTH{1'b0}}) instruction_out_stage_inst (clock, reset, cpu_inst.instruction_mem, instruction_out, 1);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) pc_out_stage_inst (clock, reset, cpu_inst.pc_mem, pc_out, 1);
assign exec_once = cpu_inst.exec_once;
export "DPI-C" function getPC;
function longint unsigned getPC();
  return pc_out;
endfunction
export "DPI-C" function getINST;
function int unsigned getINST();
  return instruction_out;
endfunction
import "DPI-C" function void set_gpr_ptr(input reg [63:0] a []);
initial set_gpr_ptr(cpu_inst.IDU_inst.RF_inst.rf);
import "DPI-C" function void set_difftest_skip();
always @(posedge clock)begin
  if(cpu_inst.clint_sel) set_difftest_skip();
  //if(cpu_inst.instruction_mem[6:0]==7'b1110011) set_difftest_skip();
end

//cache
wire [AXI_ADDR_WIDTH-1:0] r_addr_c2a, w_addr_c2a;
wire [2:0] r_size_c2a, w_size_c2a;
wire r_valid_c2a, r_ready_c2a, w_valid_c2a, w_ready_c2a;
wire [RW_DATA_WIDTH-1:0] r_data_c2a, w_data_c2a;

wire [5:0]	  io_sram0_addr , io_sram1_addr , io_sram2_addr , io_sram3_addr , io_sram4_addr , io_sram5_addr , io_sram6_addr , io_sram7_addr ;
wire  	      io_sram0_cen  , io_sram1_cen  , io_sram2_cen  , io_sram3_cen  , io_sram4_cen  , io_sram5_cen  , io_sram6_cen  , io_sram7_cen  ;
wire  	      io_sram0_wen  , io_sram1_wen  , io_sram2_wen  , io_sram3_wen  , io_sram4_wen  , io_sram5_wen  , io_sram6_wen  , io_sram7_wen  ;
wire [127:0]	io_sram0_wmask, io_sram1_wmask, io_sram2_wmask, io_sram3_wmask, io_sram4_wmask, io_sram5_wmask, io_sram6_wmask, io_sram7_wmask;
wire [127:0]	io_sram0_wdata, io_sram1_wdata, io_sram2_wdata, io_sram3_wdata, io_sram4_wdata, io_sram5_wdata, io_sram6_wdata, io_sram7_wdata;
wire [127:0]	io_sram0_rdata, io_sram1_rdata, io_sram2_rdata, io_sram3_rdata, io_sram4_rdata, io_sram5_rdata, io_sram6_rdata, io_sram7_rdata;
ysyx_040729_Cache #(
  .RW_DATA_WIDTH (RW_DATA_WIDTH),
  .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
)cache_inst(
  .i_addr_i           (if_addr),
  .i_valid_i          (if_valid),
  .i_rdata_o          (if_data_read),
  .i_ready_o          (if_ready),

  .d_addr_i           (mem_addr),
  .d_wen_i            (mem_wen),
  .d_size_i           (mem_size),
  .d_wdata_i          (mem_data_write),
  .d_rdata_o          (mem_data_read),
  .d_valid_i          (mem_valid),
  .d_ready_o          (mem_ready),


  .r_addr_o           (r_addr_c2a ),
  .r_size_o           (r_size_c2a ),
  .r_valid_o          (r_valid_c2a),
  .r_ready_i          (r_ready_c2a),
  .r_data_i           (r_data_c2a ),

  .w_addr_o           (w_addr_c2a ),
  .w_data_o           (w_data_c2a ),
  .w_size_o           (w_size_c2a ),
  .w_valid_o          (w_valid_c2a),
  .w_ready_i          (w_ready_c2a),


  .io_sram0_addr      (io_sram0_addr ),
  .io_sram0_cen       (io_sram0_cen  ),
  .io_sram0_wen       (io_sram0_wen  ),
  .io_sram0_wmask     (io_sram0_wmask),
  .io_sram0_wdata     (io_sram0_wdata),
  .io_sram0_rdata     (io_sram0_rdata),

  .io_sram1_addr      (io_sram1_addr ),
  .io_sram1_cen       (io_sram1_cen  ),
  .io_sram1_wen       (io_sram1_wen  ),
  .io_sram1_wmask     (io_sram1_wmask),
  .io_sram1_wdata     (io_sram1_wdata),
  .io_sram1_rdata     (io_sram1_rdata),

  .io_sram2_addr      (io_sram2_addr ),
  .io_sram2_cen       (io_sram2_cen  ),
  .io_sram2_wen       (io_sram2_wen  ),
  .io_sram2_wmask     (io_sram2_wmask),
  .io_sram2_wdata     (io_sram2_wdata),
  .io_sram2_rdata     (io_sram2_rdata),

  .io_sram3_addr      (io_sram3_addr ),
  .io_sram3_cen       (io_sram3_cen  ),
  .io_sram3_wen       (io_sram3_wen  ),
  .io_sram3_wmask     (io_sram3_wmask),
  .io_sram3_wdata     (io_sram3_wdata),
  .io_sram3_rdata     (io_sram3_rdata),
  
  .io_sram4_addr      (io_sram4_addr ),
  .io_sram4_cen       (io_sram4_cen  ),
  .io_sram4_wen       (io_sram4_wen  ),
  .io_sram4_wmask     (io_sram4_wmask),
  .io_sram4_wdata     (io_sram4_wdata),
  .io_sram4_rdata     (io_sram4_rdata),

  .io_sram5_addr      (io_sram5_addr ),
  .io_sram5_cen       (io_sram5_cen  ),
  .io_sram5_wen       (io_sram5_wen  ),
  .io_sram5_wmask     (io_sram5_wmask),
  .io_sram5_wdata     (io_sram5_wdata),
  .io_sram5_rdata     (io_sram5_rdata),

  .io_sram6_addr      (io_sram6_addr ),
  .io_sram6_cen       (io_sram6_cen  ),
  .io_sram6_wen       (io_sram6_wen  ),
  .io_sram6_wmask     (io_sram6_wmask),
  .io_sram6_wdata     (io_sram6_wdata),
  .io_sram6_rdata     (io_sram6_rdata),

  .io_sram7_addr      (io_sram7_addr ),
  .io_sram7_cen       (io_sram7_cen  ),
  .io_sram7_wen       (io_sram7_wen  ),
  .io_sram7_wmask     (io_sram7_wmask),
  .io_sram7_wdata     (io_sram7_wdata),
  .io_sram7_rdata     (io_sram7_rdata),

  .fence_i            (fence),
  .clock              (clock),
  .reset              (reset)
);
S011HD1P_X32Y2D128_BW sram0(io_sram0_rdata, clock, io_sram0_cen, io_sram0_wen, io_sram0_wmask, io_sram0_addr, io_sram0_wdata);
S011HD1P_X32Y2D128_BW sram1(io_sram1_rdata, clock, io_sram1_cen, io_sram1_wen, io_sram1_wmask, io_sram1_addr, io_sram1_wdata);
S011HD1P_X32Y2D128_BW sram2(io_sram2_rdata, clock, io_sram2_cen, io_sram2_wen, io_sram2_wmask, io_sram2_addr, io_sram2_wdata);
S011HD1P_X32Y2D128_BW sram3(io_sram3_rdata, clock, io_sram3_cen, io_sram3_wen, io_sram3_wmask, io_sram3_addr, io_sram3_wdata);
S011HD1P_X32Y2D128_BW sram4(io_sram4_rdata, clock, io_sram4_cen, io_sram4_wen, io_sram4_wmask, io_sram4_addr, io_sram4_wdata);
S011HD1P_X32Y2D128_BW sram5(io_sram5_rdata, clock, io_sram5_cen, io_sram5_wen, io_sram5_wmask, io_sram5_addr, io_sram5_wdata);
S011HD1P_X32Y2D128_BW sram6(io_sram6_rdata, clock, io_sram6_cen, io_sram6_wen, io_sram6_wmask, io_sram6_addr, io_sram6_wdata);
S011HD1P_X32Y2D128_BW sram7(io_sram7_rdata, clock, io_sram7_cen, io_sram7_wen, io_sram7_wmask, io_sram7_addr, io_sram7_wdata);


//axi

ysyx_040729_AXI # (
    .RW_DATA_WIDTH (RW_DATA_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_ID_WIDTH  (AXI_ID_WIDTH  ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH)
)AXI_inst(
    .clock              (clock),
    .reset              (reset),

	  .r_addr_i           (r_addr_c2a ),
    .r_size_i           (r_size_c2a ),
    .r_valid_i          (r_valid_c2a),
    .r_ready_o          (r_ready_c2a),
    .r_data_o           (r_data_c2a ),

    .w_addr_i           (w_addr_c2a ),
    .w_data_i           (w_data_c2a ),
    .w_size_i           (w_size_c2a ),
    .w_valid_i          (w_valid_c2a),
    .w_ready_o          (w_ready_c2a),

    .axi_aw_ready_i     (axi_aw_ready_i ),            
    .axi_aw_valid_o     (axi_aw_valid_o ),
    .axi_aw_addr_o      (axi_aw_addr_o  ),
    .axi_aw_id_o        (axi_aw_id_o    ),
    .axi_aw_len_o       (axi_aw_len_o   ),
    .axi_aw_size_o      (axi_aw_size_o  ),
    .axi_aw_burst_o     (axi_aw_burst_o ),

    .axi_w_ready_i      (axi_w_ready_i  ),                
    .axi_w_valid_o      (axi_w_valid_o  ),
    .axi_w_data_o       (axi_w_data_o   ),
    .axi_w_strb_o       (axi_w_strb_o   ),
    .axi_w_last_o       (axi_w_last_o   ),
    
    .axi_b_ready_o      (axi_b_ready_o  ),                
    .axi_b_valid_i      (axi_b_valid_i  ),
    .axi_b_resp_i       (axi_b_resp_i   ),                 
    .axi_b_id_i         (axi_b_id_i     ),    

    .axi_ar_ready_i     (axi_ar_ready_i ),                
    .axi_ar_valid_o     (axi_ar_valid_o ),
    .axi_ar_addr_o      (axi_ar_addr_o  ),
    .axi_ar_id_o        (axi_ar_id_o    ),
    .axi_ar_len_o       (axi_ar_len_o   ),
    .axi_ar_size_o      (axi_ar_size_o  ),
    .axi_ar_burst_o     (axi_ar_burst_o ),
    
    .axi_r_ready_o      (axi_r_ready_o  ),                 
    .axi_r_valid_i      (axi_r_valid_i  ),                
    .axi_r_resp_i       (axi_r_resp_i   ),
    .axi_r_data_i       (axi_r_data_i   ),
    .axi_r_last_i       (axi_r_last_i   ),
    .axi_r_id_i         (axi_r_id_i     )
);



endmodule
