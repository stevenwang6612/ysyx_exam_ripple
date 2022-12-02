module ysyx_040729_CLINT #(TICK_COUNT = 'h100, DATA_WIDTH = 64)(
    input  [DATA_WIDTH-1:0] clint_addr,
    input  [DATA_WIDTH-1:0] clint_wdata,
    output [DATA_WIDTH-1:0] clint_rdata,
    input                   clint_wen,
    input                   clint_sel,

    //output clint_sip,
    output clint_tirq,

    input  clock,
    input  reset
);

//read data
wire [DATA_WIDTH-1:0] clint_rdata_next;
assign clint_rdata_next = ({DATA_WIDTH{clint_mtimecmp_sel}} &  clint_mtimecmp) |
                     ({DATA_WIDTH{clint_mtime_sel   }} &  clint_mtime   ) ;
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) clint_rdata_inst (clock, reset, clint_rdata_next, clint_rdata, clint_sel);

///timer
wire [11:0] clint_mtimer_next, clint_mtimer;
Reg #(12, 12'h0) CLINT_mtimer (clock, reset, clint_mtimer_next, clint_mtimer, 1);
assign clint_mtimer_next = (clint_mtimer>=TICK_COUNT) ? 12'b0 : clint_mtimer+1;
///
wire [DATA_WIDTH-1:0] clint_mtime_next, clint_mtime, clint_mtime_hwdata;//mtime:0xbff8
wire clint_mtime_wen, clint_mtime_hwen, clint_mtime_sel;
Reg #(DATA_WIDTH, 64'h0) CLINT_mtime (clock, reset, clint_mtime_next, clint_mtime, clint_mtime_wen);
assign clint_mtime_next = clint_mtime_hwen ? clint_mtime_hwdata : clint_wdata;
assign clint_mtime_sel = clint_sel & clint_addr[15:0]==16'hbff8;
assign clint_mtime_wen = (clint_mtime_sel & clint_wen) | clint_mtime_hwen;
assign clint_mtime_hwdata = clint_mtime + 1;
assign clint_mtime_hwen = clint_mtimer>=TICK_COUNT;

wire [DATA_WIDTH-1:0] clint_mtimecmp_next, clint_mtimecmp;//mtimecmp:0x4000
wire clint_mtimecmp_wen, clint_mtimecmp_sel;
Reg #(DATA_WIDTH, 64'h0) CLINT_mtimecmp (clock, reset, clint_mtimecmp_next, clint_mtimecmp, clint_mtimecmp_wen);
assign clint_mtimecmp_next = clint_wdata;
assign clint_mtimecmp_sel = clint_sel & clint_addr[15:0]==16'h4000;
assign clint_mtimecmp_wen = clint_mtimecmp_sel & clint_wen;
    

//irq
assign clint_tirq = clint_mtime >= clint_mtimecmp;


endmodule
