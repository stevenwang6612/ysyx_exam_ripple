module ysyx_040729_CLINT #(TICK_COUNT = 'h2, DATA_WIDTH = 64, ADDR_WIDTH=16)(
    input  [ADDR_WIDTH-1:0] clint_addr,
    input  [DATA_WIDTH-1:0] clint_wdata,
    output [DATA_WIDTH-1:0] clint_rdata,
    input                   clint_wen,
    input                   clint_sel,
    input  [2:0]            clint_size,

    //output clint_sip,
    output clint_tirq,

    input  clock,
    input  reset
);

//read data
wire [DATA_WIDTH-1:0] clint_rdata_next_t, clint_rdata_next/*verilator split_var*/;
assign clint_rdata_next_t = ({DATA_WIDTH{clint_mtimecmp_sel}} &  clint_mtimecmp) |
                            ({DATA_WIDTH{clint_mtime_sel   }} &  clint_mtime   ) ;
assign clint_rdata_next[7:0]   = clint_rdata_next_t[8*clint_addr[2:0] +: 8];
assign clint_rdata_next[15: 8] = clint_size[1:0]==2'b00 ? clint_size[2] ? '0 : { 8{clint_rdata_next[ 7]}} : clint_rdata_next_t[(8+(16*clint_addr[2:1])) +: 8];
assign clint_rdata_next[31:16] = clint_size[1]  ==1'b0  ? clint_size[2] ? '0 : {16{clint_rdata_next[15]}} : clint_rdata_next_t[(16+(32*clint_addr[2])) +: 16];
assign clint_rdata_next[63:32] = clint_size[1:0]!=2'b11 ? clint_size[2] ? '0 : {32{clint_rdata_next[31]}} : clint_rdata_next_t[63:32];
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) clint_rdata_inst (clock, reset, clint_rdata_next, clint_rdata, clint_sel&~clint_wen);

///timer
wire [11:0] clint_mtimer_next, clint_mtimer;
Reg #(12, 12'h0) CLINT_mtimer (clock, reset, clint_mtimer_next, clint_mtimer, 1);
assign clint_mtimer_next = (clint_mtimer>=TICK_COUNT) ? 12'b0 : clint_mtimer+1;
///
wire [DATA_WIDTH-1:0] clint_mtime_next, clint_mtime, clint_mtime_hwdata;//mtime:0xbff8
wire clint_mtime_wen, clint_mtime_hwen, clint_mtime_sel;
Reg #(DATA_WIDTH, 64'h0) CLINT_mtime (clock, reset, clint_mtime_next, clint_mtime, clint_mtime_wen);
assign clint_mtime_next = clint_mtime_hwen ? clint_mtime_hwdata : clint_wdata;
assign clint_mtime_sel = clint_sel & clint_addr[15:3]=={12'hbff, 1'b1};
assign clint_mtime_wen = (clint_mtime_sel & clint_wen) | clint_mtime_hwen;
assign clint_mtime_hwdata = clint_mtime + 1;
assign clint_mtime_hwen = clint_mtimer>=TICK_COUNT;

wire [DATA_WIDTH-1:0] clint_mtimecmp_next, clint_mtimecmp;//mtimecmp:0x4000
wire clint_mtimecmp_wen, clint_mtimecmp_sel;
Reg #(DATA_WIDTH, 64'h0) CLINT_mtimecmp (clock, reset, clint_mtimecmp_next, clint_mtimecmp, clint_mtimecmp_wen);
assign clint_mtimecmp_next = clint_wdata;
assign clint_mtimecmp_sel = clint_sel & clint_addr[15:3]=={12'h400, 1'b0};
assign clint_mtimecmp_wen = clint_mtimecmp_sel & clint_wen;
    

//irq
assign clint_tirq = clint_mtime >= clint_mtimecmp;


endmodule
