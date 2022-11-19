module ysyx_040729_CPU #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter INST_WIDTH = 32,
    parameter REG_ADDR_W = 5,
    parameter RESET_ADDR = 64'h80000000
)(
  input  clock,
  input  reset,

//   output                      mem_valid,
//   input                       mem_ready,
//   input   [DATA_WIDTH-1:0]    mem_data_read,
//   output  [DATA_WIDTH-1:0]    mem_data_write,
//   output  [ADDR_WIDTH-1:0]    mem_addr,
//   output  [7:0]               mem_size,
//   output                      mem_req,

  output                      if_valid,
  input                       if_ready,
  input   [INST_WIDTH-1:0]    if_data_read,
  output  [ADDR_WIDTH-1:0]    if_addr
);

wire if_hs = if_valid & if_ready;
assign if_valid = 1;

//Decoder
reg [INST_WIDTH-1:0] instruction;
Reg #(INST_WIDTH, {INST_WIDTH{1'b0}}) instruction_inst (clock, reset, if_data_read, instruction, if_hs);
wire [DATA_WIDTH-1:0] immediate;
wire rf_we, mem_wen, alu_src2_ri, alu_len_dw;
wire ecall, mret, csr_enable;
wire [1:0] npc_src, alu_model;
wire [2:0] rf_wdata_src;
ysyx_040729_Decoder #(32, 64) Decoder_inst(
  .instruction  (instruction),
  .ecall        (ecall),
  .mret         (mret),
  .csr_enable   (csr_enable),
  .rf_we        (rf_we),
  .rf_wdata_src (rf_wdata_src),
  .npc_src      (npc_src),
  .alu_model    (alu_model),
  .alu_len_dw   (alu_len_dw),
  .mem_wen      (mem_wen),
  .alu_src2_ri  (alu_src2_ri),
  .immediate    (immediate)
);


//PC
wire system_jump;
wire [DATA_WIDTH-1:0] pc_next, pc, npc, snpc, dnpc, anpc, bnpc, system_jump_entry;
assign snpc = pc + 4;
assign dnpc = pc + immediate;
assign pc_next =  system_jump ? system_jump_entry : npc;
assign npc =  ({DATA_WIDTH{npc_src == 2'b00}} & snpc) |
              ({DATA_WIDTH{npc_src == 2'b01}} & dnpc) |
              ({DATA_WIDTH{npc_src == 2'b10}} & anpc) |
              ({DATA_WIDTH{npc_src == 2'b11}} & bnpc) ;
Reg #(DATA_WIDTH, RESET_ADDR) PC_inst (clock, reset, pc_next, pc, if_hs);
assign if_addr = pc;


//memory
import "DPI-C" function void pmem_read(input longint raddr, output longint rdata);
import "DPI-C" function void pmem_write(input longint waddr, input longint wdata, input byte wmask);

wire [ADDR_WIDTH-1:0] imem_addr, mem_addr;
wire [DATA_WIDTH-1:0] mem_rdata/*verilator split_var*/, mem_wdata, mem_wdata_temp, mem_rdata_clint;
reg  [DATA_WIDTH-1:0] mem_rdata_temp;
wire [7:0] mem_wmask;

always @(clock or reset or mem_wen or mem_addr or mem_wdata_temp) begin //r/w data
  if (reset) begin
    mem_rdata_temp = 0;
  end else if (mem_wen & clock==0) begin
    pmem_write(mem_addr, mem_wdata_temp, mem_wmask);
    mem_rdata_temp = 0;
  end else begin
    pmem_read(mem_addr, mem_rdata_temp);
    if (mem_addr[DATA_WIDTH-1:16]==48'h200) mem_rdata_temp = mem_rdata_clint;
  end
end
always @(posedge clock) begin
  if(system_jump) pmem_write(0, 0, 0);//for skipping difftest
end
// always @(imem_addr) begin //fetch instruction
//   pmem_read(imem_addr, instruction[31:0]);
// end

assign imem_addr = pc;
assign mem_rdata[7:0] = mem_rdata_temp[7:0];
assign mem_rdata[15: 8] = alu_func3[1:0]==2'b00 ? alu_func3[2] ? '0 : { 8{mem_rdata[ 7]}} : mem_rdata_temp[15: 8];
assign mem_rdata[31:16] = alu_func3[1]==1'b0    ? alu_func3[2] ? '0 : {16{mem_rdata[15]}} : mem_rdata_temp[31:16];
assign mem_rdata[63:32] = alu_func3[1:0]!=2'b11 ? alu_func3[2] ? '0 : {32{mem_rdata[31]}} : mem_rdata_temp[63:32];
assign mem_wdata_temp = mem_wdata;
assign mem_wmask[0] = 1'b1;
assign mem_wmask[1] = alu_func3[1:0]==2'b00 ? '0 : 1'b1;
assign mem_wmask[3:2] = alu_func3[1]==1'b0    ? '0 : '1;
assign mem_wmask[7:4] = alu_func3[1:0]!=2'b11 ? '0 : '1;


//RegFile
import "DPI-C" function void set_gpr_ptr(input reg [63:0] a []);
initial set_gpr_ptr(RF_inst.rf);
wire [REG_ADDR_W-1:0] rf_waddr, rf_raddr1, rf_raddr2;
wire [DATA_WIDTH-1:0] rf_wdata, rf_rdata1, rf_rdata2;
ysyx_040729_RegisterFile #(32, DATA_WIDTH) RF_inst (
  .clk      (clock),
  .rst      (reset),
  .wen    (rf_we),
  .waddr  (rf_waddr),
  .wdata  (rf_wdata),
  .raddr1 (rf_raddr1),
  .rdata1 (rf_rdata1),
  .raddr2 (rf_raddr2),
  .rdata2 (rf_rdata2)
);
assign rf_raddr1 = instruction[19:15];
assign rf_raddr2 = instruction[24:20];
assign rf_waddr  = instruction[11:7];
assign mem_wdata = rf_rdata2;

//ALU
wire [DATA_WIDTH-1:0] ALU_src1, ALU_src2, ALU_result;
wire [2:0] alu_func3;
wire [6:0] alu_func7;
ysyx_040729_ALU #(DATA_WIDTH) ALU_inst (
  .src1         (ALU_src1),
  .src2         (ALU_src2),
  .alu_func3    (alu_func3),
  .alu_func7    (alu_func7),
  .alu_model    (alu_model),
  .alu_len_dw   (alu_len_dw),
  .result       (ALU_result)
);
assign alu_func3 = instruction[14:12];
assign alu_func7 = instruction[31:25];
assign ALU_src1 = rf_rdata1;
assign ALU_src2 = alu_src2_ri ? immediate : rf_rdata2;
assign rf_wdata = ({DATA_WIDTH{rf_wdata_src == 3'b000}} & (ALU_result            )) |
                  ({DATA_WIDTH{rf_wdata_src == 3'b001}} & (mem_rdata             )) |
                  ({DATA_WIDTH{rf_wdata_src == 3'b010}} & (immediate             )) |
                  ({DATA_WIDTH{rf_wdata_src == 3'b011}} & (|npc_src ? snpc : dnpc)) |
                  ({DATA_WIDTH{rf_wdata_src == 3'b100}} & (csr_rdata)) ;
assign mem_addr = ALU_result;
assign anpc = ALU_result;
assign bnpc = ALU_result[0] ? dnpc : snpc;

//Exception
wire exception, ext_irq, tmr_irq, epc_select;
wire [DATA_WIDTH-1:0] excp_mcause;
ysyx_040729_Excp Excp_inst(
  .ext_irq      (ext_irq),
  .tmr_irq      (tmr_irq),
  .ecall        (ecall),
  .excp_mcause  (excp_mcause),
  .epc_select   (epc_select),
  .exception    (exception)
);

//CSR
wire [2:0] csr_wfunc;
wire clint_tirq;
wire [DATA_WIDTH-1:0] csr_rdata, csr_mtvec_vis, csr_mepc_hwdata, csr_mcause_hwdata, csr_mepc_vis;
ysyx_040729_CSR CSR_inst(
  .csr_addr           (instruction[31:20]),
  .csr_wfunc          (csr_wfunc),
  .csr_uimm           (instruction[19:15]),
  .csr_wsrc           (rf_rdata1),
  .csr_rdata          (csr_rdata),
  .csr_mtvec_vis      (csr_mtvec_vis),
  .csr_mepc_vis       (csr_mepc_vis),
  .csr_mepc_hwdata    (csr_mepc_hwdata),
  .csr_mcause_hwdata  (csr_mcause_hwdata),
  .exception          (exception),
  .mret               (mret),
  .eirp_i             (0),
  .tirp_i             (clint_tirq),
  .eirp_o             (ext_irq),
  .tirp_o             (tmr_irq),
  .clk                  (clock),
  .rst                  (reset)
);
assign system_jump_entry =({DATA_WIDTH{exception}} & csr_mtvec_vis) |
                          ({DATA_WIDTH{mret     }} & csr_mepc_vis ) |
                          ({DATA_WIDTH{!(mret | exception)}} & RESET_ADDR);
assign csr_wfunc = instruction[14:12] & {3{csr_enable}};
assign csr_mepc_hwdata = epc_select ? npc : pc;
assign csr_mcause_hwdata = excp_mcause;
assign system_jump = exception | mret;
always @(posedge clock) begin
  if(csr_enable) pmem_write(0, 0, 0);//for skipping difftest
end


//clint
ysyx_040729_CLINT CLINT_inst(
  .clint_addr  (mem_addr),
  .clint_wdata (mem_wdata_temp),
  .clint_rdata (mem_rdata_clint),
  .clint_wen   (mem_wen),
  
  .clint_tirq  (clint_tirq),

  .clk           (clock),
  .rst           (reset)
);


endmodule
