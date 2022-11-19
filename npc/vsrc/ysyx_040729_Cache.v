module ysyx_040729_Cache#(
    parameter RW_DATA_WIDTH     = 128,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 32
)(
    input  [63:0] i_addr,
    input         i_valid,
    output [31:0] i_rdata,
    output        i_ready,
    
    //cache<->memory
    //read
    output  [AXI_ADDR_WIDTH-1:0]         r_addr_o,
    output  [2:0]                        r_size_o,
	output                               r_valid_o, 
	input                                r_ready_i,  
    input   [RW_DATA_WIDTH-1:0]          r_data_i,
    //write
    output  [AXI_ADDR_WIDTH-1:0]         w_addr_o,
    output  [RW_DATA_WIDTH-1:0]          w_data_o,
    output  [2:0]                        w_size_o,
    output                               w_valid_o,  
	input                                w_ready_i,

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
);
localparam IDLE=2'b00, CMPTAG=2'b01, ALLOC=2'b10, WRTBK=2'b11;

// -------------- read ----------------

wire [AXI_ADDR_WIDTH-1:0] ir_addr;
wire [2:0]                ir_size;
wire                      ir_valid;
wire                      ir_ready;
wire [RW_DATA_WIDTH-1:0]  ir_data;

//wire [AXI_ADDR_WIDTH-1:0] dr_addr;
//wire [2:0]                dr_size;
//wire                      dr_valid;
//wire                      dr_ready;
//wire [RW_DATA_WIDTH-1:0]  dr_data;

wire ir_hs = ir_valid & ir_ready;
//wire dr_hs = dr_valid & dr_ready;

assign r_addr_o  = ir_addr;
assign r_size_o  = ir_size;
assign r_valid_o = ir_valid;
assign ir_ready  = r_ready_i;
assign ir_data   = r_data_i;

// -------------- write ---------------

assign w_addr_o  = '0;
assign w_data_o  = '0;
assign w_size_o  = '0;
assign w_valid_o = '0;

//--------------- icahce -------------- 2 * 256 * 64
localparam I_WAY = 2, I_LSIZE=32 , I_SET = 64, I_AXISIZE=$clog2(I_LSIZE);
reg  [1:0] istate, istate_next;
reg  [I_SET-1:0] i_V[I_WAY-1:0];
reg  [I_SET-1:0] i_U;
reg  [20:0] i_tag[I_WAY-1:0][I_SET-1:0];
wire [I_WAY-1:0] icache_hit;

wire [20:0] icache_req_tag    = i_addr[31:11];
wire [5:0]  icache_req_index  = i_addr[10: 5];
wire [2:0]  icache_req_offset = i_addr[ 4: 2];

wire icache_req, icache_rdy, icache_rdy_next;
reg icache_rdy_reg;
assign icache_req = i_valid;
assign i_ready = icache_rdy;
assign icache_rdy = icache_rdy_reg;
assign icache_rdy_next = (istate==CMPTAG) & (|icache_hit);
Reg #(1, 1'b0) icache_rdy_inst (clock, reset, icache_rdy_next, icache_rdy_reg, 1);

generate for (genvar i=0; i<I_WAY; ++i) begin
    assign icache_hit[i] = i_V[i][icache_req_index] & (i_tag[i][icache_req_index] == icache_req_tag);
end endgenerate

//FSM
Reg #(2, IDLE) icache_state_inst (clock, reset, istate_next, istate, 1'b1);
assign istate_next = ( {2{istate == IDLE  }}) & ( icache_req ? CMPTAG : IDLE  ) |
			         ( {2{istate == CMPTAG}}) & ( icache_req ? (|icache_hit ? CMPTAG : ALLOC) : IDLE ) |
			         ( {2{istate == ALLOC }}) & ( ir_ready ? CMPTAG : ALLOC ) |
                     ( {2{istate == WRTBK }}) & ( IDLE ) ;

//i_rdata
// reg [31:0] i_rdata_reg;
// wire [31:0] icache_data[I_WAY-1:0];
// assign icache_data[0] = icache_req_offset[2] ? io_sram1_rdata[32*icache_req_offset[1:0] +: 32] : io_sram0_rdata[32*icache_req_offset[1:0] +: 32];
// assign icache_data[1] = icache_req_offset[2] ? io_sram3_rdata[32*icache_req_offset[1:0] +: 32] : io_sram2_rdata[32*icache_req_offset[1:0] +: 32];
// wire [31:0] i_rdata_next = icache_hit[0] ? icache_data[0] : icache_data[1];
// wire i_rdata_en = (istate == CMPTAG) & (|icache_hit);
// Reg #(32, 32'b0) i_rdata_inst (clock, reset, i_rdata_next, i_rdata_reg, i_rdata_en);
// assign i_rdata = i_rdata_reg;
wire [31:0] icache_data[I_WAY-1:0];
assign icache_data[0] = icache_req_offset[2] ? io_sram1_rdata[32*icache_req_offset[1:0] +: 32] : io_sram0_rdata[32*icache_req_offset[1:0] +: 32];
assign icache_data[1] = icache_req_offset[2] ? io_sram3_rdata[32*icache_req_offset[1:0] +: 32] : io_sram2_rdata[32*icache_req_offset[1:0] +: 32];
assign i_rdata = icache_hit[0] ? icache_data[0] : icache_data[1];


//i_V i_tag
wire [I_SET-1:0] ialloc_en[I_WAY-1:0];
generate for (genvar i=0; i<I_WAY; ++i) begin
    for (genvar j=0; j<I_SET; ++j) begin:i_V_tag_inst
        assign ialloc_en[i][j] = (istate==ALLOC) & ir_hs & (i!=i_U[j]) & (j==icache_req_index);
        Reg #(1, 1'b0) i_V_inst (clock, reset, 1'b1, i_V[i][j], ialloc_en[i][j]);
        Reg #(21, 21'b0) i_tag_inst (clock, reset, icache_req_tag, i_tag[i][j], ialloc_en[i][j]);
    end
end endgenerate
//i_U
wire [I_SET-1:0] i_U_next, i_U_en;
generate for (genvar i=0; i<I_SET; ++i) begin:i_U_inst
    Reg #(1, 1'b0) i_U_inst (clock, reset, i_U_next[i], i_U[i], i_U_en[i]);
    assign i_U_next[i] = ialloc_en[0][i] ? 1'b0 : 1'b1;
    assign i_U_en[i] = ialloc_en[0][i] | ialloc_en[1][i];
end endgenerate
//sram
assign io_sram0_addr  = icache_req_index;
assign io_sram0_cen   = 1'b1;
assign io_sram0_wen   = |ialloc_en[0];
assign io_sram0_wmask = 128'hffffffffffffffffffffffffffffffff;
assign io_sram0_wdata = ir_data[127:0];

assign io_sram1_addr  = icache_req_index;
assign io_sram1_cen   = 1'b1;
assign io_sram1_wen   = |ialloc_en[0];
assign io_sram1_wmask = 128'hffffffffffffffffffffffffffffffff;
assign io_sram1_wdata = ir_data[255:128];

assign io_sram2_addr  = icache_req_index;
assign io_sram2_cen   = 1'b1;
assign io_sram2_wen   = |ialloc_en[1];
assign io_sram2_wmask = 128'hffffffffffffffffffffffffffffffff;
assign io_sram2_wdata = ir_data[127:0];

assign io_sram3_addr  = icache_req_index;
assign io_sram3_cen   = 1'b1;
assign io_sram3_wen   = |ialloc_en[1];
assign io_sram3_wmask = 128'hffffffffffffffffffffffffffffffff;
assign io_sram3_wdata = ir_data[255:128];

//icache2mem
reg ir_valid_reg;
assign ir_addr  = {i_addr[31:5], 5'b0};
assign ir_size  = I_AXISIZE[2:0];
assign ir_valid = ir_valid_reg;
wire ir_valid_set = (istate==CMPTAG) & !(|icache_hit);
wire ir_valid_clr = (istate==ALLOC ) & (ir_ready);
Reg #(1, 1'b0) ir_valid_inst (clock, reset, ir_valid_set, ir_valid_reg, ir_valid_set | ir_valid_clr);

//------------------------------------------------

endmodule
