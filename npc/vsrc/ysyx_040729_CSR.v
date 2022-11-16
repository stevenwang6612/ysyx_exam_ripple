module ysyx_22040729_CSR #(DATA_WIDTH = 64)(
    input  [11:0] csr_addr,
    input  [2:0]  csr_wfunc,
    input  [4:0]  csr_uimm,
    input  [DATA_WIDTH-1:0] csr_wsrc,
    output [DATA_WIDTH-1:0] csr_rdata,

    output [DATA_WIDTH-1:0] csr_mtvec_vis,
    output [DATA_WIDTH-1:0] csr_mepc_vis,
    input  [DATA_WIDTH-1:0] csr_mepc_hwdata,
    input  [DATA_WIDTH-1:0] csr_mcause_hwdata,

    input  exception,
    input  mret,

    input  eirp_i,
    input  tirp_i,
    output eirp_o,
    output tirp_o,

    input  clk,
    input  rst
);

//write data
wire [DATA_WIDTH-1:0] csr_wdata, csr_wdata_temp;
assign csr_wdata_temp = csr_wfunc[2] ? {{DATA_WIDTH-5{1'b0}}, csr_uimm} : csr_wsrc;
assign csr_wdata  = ({DATA_WIDTH{csr_wfunc[1:0]==2'b01}} & ( csr_wdata_temp            )) |
                    ({DATA_WIDTH{csr_wfunc[1:0]==2'b10}} & ( csr_wdata_temp | csr_rdata)) |
                    ({DATA_WIDTH{csr_wfunc[1:0]==2'b11}} & (~csr_wdata_temp & csr_rdata)) ;
////
//read data
assign csr_rdata =  ({DATA_WIDTH{csr_mstatus_sel}} &  csr_mstatus) |
                    ({DATA_WIDTH{csr_mtvec_sel  }} &  csr_mtvec  ) |
                    ({DATA_WIDTH{csr_mepc_sel   }} &  csr_mepc   ) |
                    ({DATA_WIDTH{csr_mcause_sel }} &  csr_mcause ) ;
////


wire [DATA_WIDTH-1:0] csr_mstatus;//mstatus:0x300
wire csr_mstatus_sel = csr_addr==12'h300;

wire csr_mstatus_mie, csr_mstatus_mie_next, csr_mstatus_mie_hwdata; // mie
wire csr_mstatus_mie_wen, csr_mstatus_mie_hwwen;
Reg #(1, 1'b0) CSR_mstatus_mie (clk, rst, csr_mstatus_mie_next, csr_mstatus_mie, csr_mstatus_mie_wen);
assign csr_mstatus_mie_next = csr_mstatus_mie_hwwen ? csr_mstatus_mie_hwdata : csr_wdata[3];
assign csr_mstatus_mie_hwdata = mret ? csr_mstatus_mpie : 0;
assign csr_mstatus_mie_wen = (csr_mstatus_sel & |csr_wfunc[1:0]) | csr_mstatus_mie_hwwen;
assign csr_mstatus_mie_hwwen = exception | mret;

wire csr_mstatus_mpie, csr_mstatus_mpie_next, csr_mstatus_mpie_hwdata; // mpie
wire csr_mstatus_mpie_wen, csr_mstatus_mpie_hwwen;
Reg #(1, 1'b0) CSR_mstatus_mpie (clk, rst, csr_mstatus_mpie_next, csr_mstatus_mpie, csr_mstatus_mpie_wen);
assign csr_mstatus_mpie_next = csr_mstatus_mpie_hwwen ? csr_mstatus_mpie_hwdata : csr_wdata[7];
assign csr_mstatus_mpie_hwdata = csr_mstatus_mie;
assign csr_mstatus_mpie_wen = (csr_mstatus_sel & |csr_wfunc[1:0]) | csr_mstatus_mpie_hwwen;
assign csr_mstatus_mpie_hwwen = exception;

assign csr_mstatus = {28'h0, 2'b10, 2'b10, 19'b0, 2'b11, 3'b0, csr_mstatus_mpie, 3'b0, csr_mstatus_mie, 3'b0};


wire [DATA_WIDTH-1:0] csr_mie_next, csr_mie;//mie:0x304
wire csr_mie_wen, csr_mie_sel;
wire csr_mie_meie, csr_mie_mtie;
Reg #(1, 1'b0) CSR_mie_meie (clk, rst, csr_mie_next[11], csr_mie_meie, csr_mie_wen);
Reg #(1, 1'b0) CSR_mie_mtie (clk, rst, csr_mie_next[ 7], csr_mie_mtie, csr_mie_wen);
assign csr_mie = {52'b0, csr_mie_meie, 3'b0, csr_mie_mtie, 7'b0};
assign csr_mie_next = csr_wdata;
assign csr_mie_sel = csr_addr==12'h304;
assign csr_mie_wen = csr_mie_sel & |csr_wfunc[1:0];
assign eirp_o = csr_mstatus_mie & csr_mie_meie & eirp_i;
assign tirp_o = csr_mstatus_mie & csr_mie_mtie & tirp_i;

wire [DATA_WIDTH-1:0] csr_mtvec_next, csr_mtvec;//mtvec:0x305
wire csr_mtvec_wen, csr_mtvec_sel;
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) CSR_mtvec (clk, rst, csr_mtvec_next, csr_mtvec, csr_mtvec_wen);
assign csr_mtvec_next = csr_wdata;
assign csr_mtvec_sel = csr_addr==12'h305;
assign csr_mtvec_wen = csr_mtvec_sel & |csr_wfunc[1:0];
assign csr_mtvec_vis = csr_mtvec;

wire [DATA_WIDTH-1:0] csr_mepc_next, csr_mepc;//mepc:0x341
wire csr_mepc_wen, csr_mepc_wen_hw, csr_mepc_sel;
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) CSR_mepc (clk, rst, csr_mepc_next, csr_mepc, csr_mepc_wen);
assign csr_mepc_next = csr_mepc_wen_hw ? csr_mepc_hwdata : csr_wdata;
assign csr_mepc_sel = csr_addr==12'h341;
assign csr_mepc_wen = (csr_mepc_sel & |csr_wfunc[1:0]) | csr_mepc_wen_hw;
assign csr_mepc_wen_hw = exception;
assign csr_mepc_vis = csr_mepc;

wire [DATA_WIDTH-1:0] csr_mcause_next, csr_mcause;//mcause:0x342
wire csr_mcause_wen, csr_mcause_wen_hw, csr_mcause_sel;
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) CSR_mcause (clk, rst, csr_mcause_next, csr_mcause, csr_mcause_wen);
assign csr_mcause_next = csr_mcause_wen_hw ? csr_mcause_hwdata : csr_wdata;
assign csr_mcause_sel = csr_addr==12'h342;
assign csr_mcause_wen = (csr_mcause_sel & |csr_wfunc[1:0]) | csr_mcause_wen_hw;
assign csr_mcause_wen_hw = exception;

wire [DATA_WIDTH-1:0] csr_mip;//mip:0x344
wire csr_mip_wen, csr_mip_sel;
wire csr_mip_meip, csr_mip_mtip;
Reg #(1, 1'b0) CSR_mip_meip (clk, rst, eirp_i, csr_mip_meip, 1'b1);
Reg #(1, 1'b0) CSR_mip_mtip (clk, rst, tirp_i, csr_mip_mtip, 1'b1);
assign csr_mip = {52'b0, csr_mip_meip, 3'b0, csr_mip_mtip, 7'b0};
assign csr_mip_sel = csr_addr==12'h344;
    
endmodule
