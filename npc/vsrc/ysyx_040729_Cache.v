module ysyx_040729_Cache(
    input [63:0] cpu_req_addr,
    input cpu_req_valid,
    output reg [31:0] cpu_data_read,
    output reg cpu_ready,
    
    //cache<->memory
    output reg [63:0]   rw_addr_o,
    output reg          rw_req_o,//
    output reg          rw_valid_o,
    input [127:0]       data_read_i,//finish burst
    input               rw_ready_i,//data_read_i in ram

    output[5:0]	    io_sram0_addr,
    output	        io_sram0_cen,
    output	        io_sram0_wen,
    output[127:0]	io_sram0_wmask,
    output[127:0]	io_sram0_wdata,
    input [127:0]	io_sram0_rdata,

    output[5:0]	    io_sram1_addr,
    output	        io_sram1_cen,
    output	        io_sram1_wen,
    output[127:0]	io_sram1_wmask,
    output[127:0]	io_sram1_wdata,
    input [127:0]	io_sram1_rdata,

    output[5:0]	    io_sram2_addr,
    output	        io_sram2_cen,
    output	        io_sram2_wen,
    output[127:0]	io_sram2_wmask,
    output[127:0]	io_sram2_wdata,
    input [127:0]	io_sram2_rdata,

    output[5:0]	    io_sram3_addr,
    output	        io_sram3_cen,
    output	        io_sram3_wen,
    output[127:0]	io_sram3_wmask,
    output[127:0]	io_sram3_wdata,
    input [127:0]	io_sram3_rdata,

    input clock,
    input reset
)