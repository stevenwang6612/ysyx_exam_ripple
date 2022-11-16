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
  input  rst,

  // Advanced eXtensible Interface
    input                               axi_aw_ready_i,              
    output                              axi_aw_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o,
    output [2:0]                        axi_aw_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_aw_user_o,
    output [7:0]                        axi_aw_len_o,
    output [2:0]                        axi_aw_size_o,
    output [1:0]                        axi_aw_burst_o,
    output                              axi_aw_lock_o,
    output [3:0]                        axi_aw_cache_o,
    output [3:0]                        axi_aw_qos_o,
    output [3:0]                        axi_aw_region_o,

    input                               axi_w_ready_i,                
    output                              axi_w_valid_o,
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o,
    output [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_o,
    output                              axi_w_last_o,
    output [AXI_USER_WIDTH-1:0]         axi_w_user_o,
    
    output                              axi_b_ready_o,                
    input                               axi_b_valid_i,
    input  [1:0]                        axi_b_resp_i,                 
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_b_user_i,

    input                               axi_ar_ready_i,                
    output                              axi_ar_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o,
    output [2:0]                        axi_ar_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_ar_user_o,
    output [7:0]                        axi_ar_len_o,
    output [2:0]                        axi_ar_size_o,
    output [1:0]                        axi_ar_burst_o,
    output                              axi_ar_lock_o,
    output [3:0]                        axi_ar_cache_o,
    output [3:0]                        axi_ar_qos_o,
    output [3:0]                        axi_ar_region_o,
    
    output                              axi_r_ready_o,                 
    input                               axi_r_valid_i,                
    input  [1:0]                        axi_r_resp_i,
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i,
    input                               axi_r_last_i,
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_r_user_i,

    output                              exec_once
);
localparam DATA_WIDTH = 64;
localparam ADDR_WIDTH = 64;
localparam INST_WIDTH = 32;
localparam REG_ADDR_W = 5;
localparam RESET_ADDR = 64'h80000000;
localparam RW_DATA_WIDTH    = 64;
localparam RW_ADDR_WIDTH    = 64;
localparam AXI_DATA_WIDTH   = 64;
localparam AXI_ADDR_WIDTH   = 64;
localparam AXI_ID_WIDTH     = 4;
localparam AXI_STRB_WIDTH   = AXI_DATA_WIDTH/8;
localparam AXI_USER_WIDTH   = 1;

 wire if_valid, if_ready;
 wire [DATA_WIDTH-1:0]    if_data_read;
 wire [ADDR_WIDTH-1:0]    if_addr;
 assign exec_once = if_ready;

ysyx_22090729_CPU #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH),
  .INST_WIDTH(INST_WIDTH),
  .REG_ADDR_W(REG_ADDR_W),
  .RESET_ADDR(RESET_ADDR)
)cpu_inst(
  .clk       (clk),
  .rst       (rst),

//.mem_valid       (),
//.mem_ready       (),
//.mem_data_read   (),
//.mem_data_write  (),
//.mem_addr        (),
//.mem_size        (),
//.mem_req         (),

  .if_valid        (if_valid),
  .if_ready        (if_ready),
  .if_data_read    (if_data_read[INST_WIDTH-1:0]),
  .if_addr         (if_addr)
);
export "DPI-C" function getPC;
function longint unsigned getPC();
  return if_addr;
endfunction
export "DPI-C" function getINST;
function int unsigned getINST();
  return if_data_read[INST_WIDTH-1:0];
endfunction


//axi
ysyx_22040729_AXI # (
    .RW_DATA_WIDTH (DATA_WIDTH),
    .RW_ADDR_WIDTH (ADDR_WIDTH),
    .AXI_DATA_WIDTH(DATA_WIDTH),
    .AXI_ADDR_WIDTH(ADDR_WIDTH),
    .AXI_ID_WIDTH  (AXI_ID_WIDTH  ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_USER_WIDTH(AXI_USER_WIDTH)
)AXI_inst(
    .clock              (clk),
    .reset              (rst),

	  .rw_req_i           (0),
    .rw_valid_i         (if_valid),      //IF&MEM输入信号
	  .rw_ready_o         (if_ready),      //IF&MEM输入信号
    .data_read_o        (if_data_read),  //IF&MEM输入信号
    .rw_w_data_i        (0),             //IF&MEM输入信号
    .rw_addr_i          (if_addr),       //IF&MEM输入信号
    .rw_size_i          (0),             //IF&MEM输入信号



    .axi_aw_ready_i     (axi_aw_ready_i ),            
    .axi_aw_valid_o     (axi_aw_valid_o ),
    .axi_aw_addr_o      (axi_aw_addr_o  ),
    .axi_aw_prot_o      (axi_aw_prot_o  ),
    .axi_aw_id_o        (axi_aw_id_o    ),
    .axi_aw_user_o      (axi_aw_user_o  ),
    .axi_aw_len_o       (axi_aw_len_o   ),
    .axi_aw_size_o      (axi_aw_size_o  ),
    .axi_aw_burst_o     (axi_aw_burst_o ),
    .axi_aw_lock_o      (axi_aw_lock_o  ),
    .axi_aw_cache_o     (axi_aw_cache_o ),
    .axi_aw_qos_o       (axi_aw_qos_o   ),
    .axi_aw_region_o    (axi_aw_region_o),

    .axi_w_ready_i      (axi_w_ready_i  ),                
    .axi_w_valid_o      (axi_w_valid_o  ),
    .axi_w_data_o       (axi_w_data_o   ),
    .axi_w_strb_o       (axi_w_strb_o   ),
    .axi_w_last_o       (axi_w_last_o   ),
    .axi_w_user_o       (axi_w_user_o   ),
    
    .axi_b_ready_o      (axi_b_ready_o  ),                
    .axi_b_valid_i      (axi_b_valid_i  ),
    .axi_b_resp_i       (axi_b_resp_i   ),                 
    .axi_b_id_i         (axi_b_id_i     ),    
    .axi_b_user_i       (axi_b_user_i   ),

    .axi_ar_ready_i     (axi_ar_ready_i ),                
    .axi_ar_valid_o     (axi_ar_valid_o ),
    .axi_ar_addr_o      (axi_ar_addr_o  ),
    .axi_ar_prot_o      (axi_ar_prot_o  ),
    .axi_ar_id_o        (axi_ar_id_o    ),
    .axi_ar_user_o      (axi_ar_user_o  ),
    .axi_ar_len_o       (axi_ar_len_o   ),
    .axi_ar_size_o      (axi_ar_size_o  ),
    .axi_ar_burst_o     (axi_ar_burst_o ),
    .axi_ar_lock_o      (axi_ar_lock_o  ),
    .axi_ar_cache_o     (axi_ar_cache_o ),
    .axi_ar_qos_o       (axi_ar_qos_o   ),
    .axi_ar_region_o    (axi_ar_region_o),
    
    .axi_r_ready_o      (axi_r_ready_o  ),                 
    .axi_r_valid_i      (axi_r_valid_i  ),                
    .axi_r_resp_i       (axi_r_resp_i   ),
    .axi_r_data_i       (axi_r_data_i   ),
    .axi_r_last_i       (axi_r_last_i   ),
    .axi_r_id_i         (axi_r_id_i     ),
    .axi_r_user_i       (axi_r_user_i   )
);



endmodule
