module ysyx_040729_Cache#(
    parameter RW_DATA_WIDTH     = 128,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter RESET_INST = 32'h00000013
)(
    input  [63:0] i_addr,
    output [31:0] i_rdata,
    input         i_valid,
    output        i_ready,

    input  [63:0] d_addr,
    input         d_wen,
    input  [1 :0] d_size,
    input  [63:0] d_wdata,
    output [63:0] d_rdata,
    input         d_valid,
    output        d_ready,
    
    
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
    
    output[5:0]	    io_sram4_addr,
    output	        io_sram4_cen,
    output	        io_sram4_wen,
    output[127:0]	io_sram4_wmask,
    output[127:0]	io_sram4_wdata,
    input [127:0]	io_sram4_rdata,

    output[5:0]	    io_sram5_addr,
    output	        io_sram5_cen,
    output	        io_sram5_wen,
    output[127:0]	io_sram5_wmask,
    output[127:0]	io_sram5_wdata,
    input [127:0]	io_sram5_rdata,

    output[5:0]	    io_sram6_addr,
    output	        io_sram6_cen,
    output	        io_sram6_wen,
    output[127:0]	io_sram6_wmask,
    output[127:0]	io_sram6_wdata,
    input [127:0]	io_sram6_rdata,

    output[5:0]	    io_sram7_addr,
    output	        io_sram7_cen,
    output	        io_sram7_wen,
    output[127:0]	io_sram7_wmask,
    output[127:0]	io_sram7_wdata,
    input [127:0]	io_sram7_rdata,


    input clock,
    input reset
);
localparam IDLE=2'b11, CMPTAG=2'b00, ALLOC=2'b01, WRTBK=2'b10;

// -------------- read ----------------

wire [AXI_ADDR_WIDTH-1:0] ir_addr;
wire [2:0]                ir_size;
wire                      ir_valid;
wire                      ir_ready;
wire [RW_DATA_WIDTH-1:0]  ir_data;

wire [AXI_ADDR_WIDTH-1:0] dr_addr;
wire [2:0]                dr_size;
wire                      dr_valid;
wire                      dr_ready;
wire [RW_DATA_WIDTH-1:0]  dr_data;

wire ir_hs = ir_valid & ir_ready;
wire dr_hs = dr_valid & dr_ready;

wire arb_id, arb_id_next;//arbiter: icache first
Reg #(1, 1'b0) arb_id_inst (clock, reset, arb_id_next, arb_id, ir_valid | dr_valid);
assign arb_id_next = (~ir_valid & dr_valid) | (ir_valid & dr_valid & arb_id & ~dr_ready);

assign r_addr_o  = arb_id ? dr_addr  : ir_addr ;
assign r_size_o  = arb_id ? dr_size  : ir_size ;
assign r_valid_o = arb_id ? dr_valid : ir_valid;
assign ir_ready  = arb_id ? 1'b0     : r_ready_i;
assign dr_ready  = arb_id ? r_ready_i: 1'b0;
assign ir_data   = r_data_i;
assign dr_data   = r_data_i;


// -------------- write ---------------
wire [AXI_ADDR_WIDTH-1:0] dw_addr;
wire [2:0]                dw_size;
wire                      dw_valid;
wire                      dw_ready;
wire [RW_DATA_WIDTH-1:0]  dw_data;

wire dw_hs = dw_valid & dw_ready;

assign w_addr_o  = dw_addr;
assign w_data_o  = dw_data;
assign w_size_o  = dw_size;
assign w_valid_o = dw_valid;
assign dw_ready  = w_ready_i;

//--------------- icahce -------------- 2 * 256 * 64
localparam I_WAY = 2, I_LSIZE=32 , I_SET = 64, I_AXISIZE=$clog2(I_LSIZE);
reg  [1:0] istate, istate_next, istate_prev;
reg  [I_SET-1:0] i_V[I_WAY-1:0];
reg  [I_SET-1:0] i_U;
reg  [20:0] i_tag[I_WAY-1:0][I_SET-1:0];
wire [I_WAY-1:0] icache_hit;

wire [20:0] icache_req_tag    = i_addr[31:11];
wire [5:0]  icache_req_index  = i_addr[10: 5];
wire [2:0]  icache_req_offset = i_addr[ 4: 2];

wire icache_req, icache_rdy, icache_rdy_next, icache_rdy_d;
assign icache_req = i_valid;
assign i_ready = icache_rdy;
assign icache_rdy = (istate==CMPTAG) & (|icache_hit) & icache_req;
Reg #(1, 1'b0) icache_rdy_d_inst (clock, reset, icache_rdy, icache_rdy_d, 1);

generate for (genvar i=0; i<I_WAY; ++i) begin
    assign icache_hit[i] = i_V[i][icache_req_index] & (i_tag[i][icache_req_index] == icache_req_tag);
end endgenerate

//FSM
Reg #(2, CMPTAG) icache_state_inst (clock, reset, istate_next, istate, 1'b1);
Reg #(2, CMPTAG) icache_state_prev_inst (clock, reset, istate, istate_prev, 1'b1);
assign istate_next = ( {2{istate == IDLE  }}) & ( CMPTAG ) |
			         ( {2{istate == CMPTAG}}) & ( icache_req & ~|icache_hit ? ALLOC : CMPTAG ) |
			         ( {2{istate == ALLOC }}) & ( ir_hs ? CMPTAG : ALLOC ) |
                     ( {2{istate == WRTBK }}) & ( CMPTAG ) ;

//i_rdata
wire [2:0]  icache_req_offset_d;
Reg #(3, 3'b0) icache_req_offset_stage_inst (clock, reset, icache_req_offset, icache_req_offset_d, icache_rdy);
wire [D_WAY-1:0] icache_hit_d;
Reg #(D_WAY, {D_WAY{1'b0}}) icache_hit_stage_inst (clock, reset, icache_hit, icache_hit_d, icache_rdy);
wire [31:0] icache_data_t[I_WAY-1:0];
wire [31:0] icache_data, icache_data_d;
Reg #(32, RESET_INST) icache_data_stage_inst (clock, reset, icache_data, icache_data_d, icache_rdy_d);
assign icache_data_t[0] = icache_req_offset_d[2] ? io_sram1_rdata[32*icache_req_offset_d[1:0] +: 32] : io_sram0_rdata[32*icache_req_offset_d[1:0] +: 32];
assign icache_data_t[1] = icache_req_offset_d[2] ? io_sram3_rdata[32*icache_req_offset_d[1:0] +: 32] : io_sram2_rdata[32*icache_req_offset_d[1:0] +: 32];
assign icache_data = icache_hit_d[0] ? icache_data_t[0] : icache_data_t[1];
assign i_rdata = icache_rdy_d ? icache_data : icache_data_d;


//i_V i_tag
wire [I_SET-1:0] ialloc_en[I_WAY-1:0];
generate for (genvar i=0; i<I_WAY; ++i) begin
    for (genvar j=0; j<I_SET; ++j) begin:i_V_tag_inst
        assign ialloc_en[i][j] = (istate==ALLOC) & ir_hs & (i!=i_U[icache_req_index]) & (j==icache_req_index);
        Reg #(1, 1'b0) i_V_inst (clock, reset, 1'b1, i_V[i][j], ialloc_en[i][j]);
        Reg #(21, 21'b0) i_tag_inst (clock, reset, icache_req_tag, i_tag[i][j], ialloc_en[i][j]);
    end
end endgenerate
//i_U
wire [I_SET-1:0] i_U_en;
wire i_U_next = icache_hit[0] ? 1'b0 : 1'b1;
generate for (genvar i=0; i<I_SET; ++i) begin:i_U_inst
    Reg #(1, 1'b0) i_U_inst (clock, reset, i_U_next, i_U[i], i_U_en[i]);
    assign i_U_en[i] = (i==icache_req_index) & |icache_hit;
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
wire ir_valid_set = (istate==CMPTAG) & !(|icache_hit) & icache_req;
wire ir_valid_clr = (istate==ALLOC ) & (ir_ready);
Reg #(1, 1'b0) ir_valid_inst (clock, reset, ir_valid_set, ir_valid_reg, ir_valid_set | ir_valid_clr);

//------------------------------------------------
//--------------- dcahce -------------- 2 * 256 * 64
localparam D_WAY = 2, D_LSIZE=32 , D_SET = 64, D_AXISIZE=$clog2(D_LSIZE);
reg  [1:0] dstate, dstate_next, dstate_prev;
reg  [D_SET-1:0] d_V[D_WAY-1:0];
reg  [D_SET-1:0] d_D[D_WAY-1:0];
reg  [D_SET-1:0] d_U;
reg  [20:0] d_tag[D_WAY-1:0][I_SET-1:0];
wire [D_WAY-1:0] dcache_hit;

wire [20:0] dcache_req_tag    = d_addr[31:11];
wire [5:0]  dcache_req_index  = d_addr[10: 5];
wire [1:0]  dcache_req_offset = d_addr[ 4: 3];

wire dcache_req, dcache_rdy, dcache_rdy_next, dcache_rdy_d;
assign dcache_req = d_valid;
assign d_ready = dcache_rdy;
assign dcache_rdy = (dstate==CMPTAG) & (|dcache_hit) & dcache_req;
Reg #(1, 1'b0) dcache_rdy_d_inst (clock, reset, dcache_rdy&~d_wen, dcache_rdy_d, 1);
//

generate for (genvar i=0; i<D_WAY; ++i) begin
    assign dcache_hit[i] = d_V[i][dcache_req_index] & (d_tag[i][dcache_req_index] == dcache_req_tag);
end endgenerate

//FSM
Reg #(2, CMPTAG) dcache_state_inst (clock, reset, dstate_next, dstate, 1'b1);
Reg #(2, CMPTAG) dcache_state_prev_inst (clock, reset, dstate, dstate_prev, 1'b1);
assign dstate_next = ( {2{dstate == IDLE  }}) & ( CMPTAG  ) |
			         ( {2{dstate == CMPTAG}}) & ( dcache_req & ~|dcache_hit ? ALLOC : CMPTAG ) |
			         ( {2{dstate == ALLOC }}) & ( dr_hs      ? CMPTAG : ALLOC ) |
                     ( {2{dstate == WRTBK }}) & ( CMPTAG ) ;

//
wire [1:0]  dcache_req_offset_d;
Reg #(2, 2'b0) dcache_req_offset_stage_inst (clock, reset, dcache_req_offset, dcache_req_offset_d, dcache_rdy&~d_wen);
wire [D_WAY-1:0] dcache_hit_d;
Reg #(D_WAY, {D_WAY{1'b0}}) dcache_hit_stage_inst (clock, reset, dcache_hit, dcache_hit_d, dcache_rdy&~d_wen);
wire [63:0] dcache_data_t[D_WAY-1:0];
wire [63:0] dcache_data, dcache_data_d;
Reg #(64, {64{1'b0}}) dcache_data_stage_inst (clock, reset, dcache_data, dcache_data_d, dcache_rdy_d);
assign dcache_data_t[0] = dcache_req_offset_d[1] ? io_sram5_rdata[64*dcache_req_offset_d[0] +: 64] : io_sram4_rdata[64*dcache_req_offset_d[0] +: 64];
assign dcache_data_t[1] = dcache_req_offset_d[1] ? io_sram7_rdata[64*dcache_req_offset_d[0] +: 64] : io_sram6_rdata[64*dcache_req_offset_d[0] +: 64];
assign dcache_data = dcache_hit_d[0] ? dcache_data_t[0] : dcache_data_t[1];
assign d_rdata = dcache_rdy_d ? dcache_data : dcache_data_d;


//d_V d_tag
wire [D_SET-1:0] dalloc_en[D_WAY-1:0];
generate for (genvar i=0; i<D_WAY; ++i) begin
    for (genvar j=0; j<D_SET; ++j) begin:d_V_tag_inst
        assign dalloc_en[i][j] = (dstate==ALLOC) & dr_hs & (i!=d_U[dcache_req_index]) & (j==dcache_req_index);
        Reg #(1, 1'b0) d_V_inst (clock, reset, 1'b1, d_V[i][j], dalloc_en[i][j]);
        Reg #(21, 21'b0) d_tag_inst (clock, reset, dcache_req_tag, d_tag[i][j], dalloc_en[i][j]);
    end
end endgenerate
//d_U
wire [I_SET-1:0] d_U_en;
wire d_U_next = dcache_hit[0] ? 1'b0 : 1'b1;
generate for (genvar i=0; i<I_SET; ++i) begin:d_U_inst
    Reg #(1, 1'b0) d_U_inst (clock, reset, d_U_next, d_U[i], d_U_en[i]);
    assign d_U_en[i] = (i==dcache_req_index) & |dcache_hit;
end endgenerate
//d_D
wire [D_SET-1:0] ddirty_set[D_WAY-1:0];
generate for (genvar i=0; i<D_WAY; ++i) begin
    for (genvar j=0; j<D_SET; ++j) begin:d_D_inst
        assign ddirty_set[i][j] = (dstate==CMPTAG) & d_wen & (dcache_hit[i]) & (j==dcache_req_index);
        Reg #(1, 1'b0) d_D_inst (clock, reset, ddirty_set[i][j], d_D[i][j], dalloc_en[i][j] | ddirty_set[i][j]);
    end
end endgenerate
//sram
wire [63:0] sram_wmask_t = ({64{d_size==2'b00}} & 64'hFF)|
                           ({64{d_size==2'b01}} & 64'hFFFF)|
                           ({64{d_size==2'b10}} & 64'hFFFFFFFF)|
                           ({64{d_size==2'b11}} & 64'hFFFFFFFFFFFFFFFF);
wire [127:0] sram_wdata = {64'b0, d_wdata} << ({ d_addr[3:0], 3'b0 });
wire [127:0] sram_wmask = {64'b0, sram_wmask_t} << ({ d_addr[3:0], 3'b0 });

assign io_sram4_addr  = dcache_req_index;
assign io_sram4_cen   = 1'b1;
assign io_sram4_wen   = |dalloc_en[0] | (dcache_hit[0] & ~dcache_req_offset[1] & d_wen);
assign io_sram4_wmask = |dalloc_en[0] ? 128'hffffffffffffffffffffffffffffffff : sram_wmask;
assign io_sram4_wdata = |dalloc_en[0] ? dr_data[127:0] : sram_wdata;

assign io_sram5_addr  = dcache_req_index;
assign io_sram5_cen   = 1'b1;
assign io_sram5_wen   = |dalloc_en[0] | (dcache_hit[0] & dcache_req_offset[1] & d_wen);
assign io_sram5_wmask = |dalloc_en[0] ? 128'hffffffffffffffffffffffffffffffff : sram_wmask;
assign io_sram5_wdata = |dalloc_en[0] ? dr_data[255:128] : sram_wdata;

assign io_sram6_addr  = dcache_req_index;
assign io_sram6_cen   = 1'b1;
assign io_sram6_wen   = |dalloc_en[1] | (dcache_hit[1] & ~dcache_req_offset[1] & d_wen);
assign io_sram6_wmask = |dalloc_en[1] ? 128'hffffffffffffffffffffffffffffffff : sram_wmask;
assign io_sram6_wdata = |dalloc_en[1] ? dr_data[127:0] : sram_wdata;

assign io_sram7_addr  = dcache_req_index;
assign io_sram7_cen   = 1'b1;
assign io_sram7_wen   = |dalloc_en[1] | (dcache_hit[1] & dcache_req_offset[1] & d_wen);
assign io_sram7_wmask = |dalloc_en[1] ? 128'hffffffffffffffffffffffffffffffff : sram_wmask;
assign io_sram7_wdata = |dalloc_en[1] ? dr_data[255:128] : sram_wdata;

//dcache2mem
///read
reg dr_valid_reg;
assign dr_addr  = {d_addr[31:5], 5'b0};
assign dr_size  = D_AXISIZE[2:0];
assign dr_valid = dr_valid_reg;
wire dr_valid_set = (dstate==CMPTAG) & !(|dcache_hit) & dcache_req;
wire dr_valid_clr = (dstate==ALLOC ) & (dr_ready);
Reg #(1, 1'b0) dr_valid_inst (clock, reset, dr_valid_set, dr_valid_reg, dr_valid_set | dr_valid_clr);
///write
reg dw_valid_reg;
assign dw_addr  = {d_addr[31:5], 5'b0};
assign dw_size  = D_AXISIZE[2:0];
assign dw_data  = dcache_hit[0] ? {io_sram5_rdata, io_sram4_rdata} : {io_sram7_rdata, io_sram6_rdata};
assign dw_valid = dw_valid_reg;
wire dw_valid_set = (dstate==ALLOC ) & d_D[~d_U[dcache_req_index]][dcache_req_index];
wire dw_valid_clr = (dstate==ALLOC ) & (dw_ready);
Reg #(1, 1'b0) dw_valid_inst (clock, reset, dw_valid_set, dw_valid_reg, dw_valid_set | dw_valid_clr);


endmodule
