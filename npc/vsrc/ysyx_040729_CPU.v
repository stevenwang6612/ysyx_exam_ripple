module ysyx_040729_CPU #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,
    parameter REG_ADDR_W = 5,
    parameter RESET_ADDR = 64'h80000000,
    parameter RESET_INST = 32'h00000013
)(
  input  clock,
  input  reset,
  output fence_o,

  output                      mem_valid,
  input                       mem_ready,
  input   [DATA_WIDTH-1:0]    mem_data_read,
  output  [DATA_WIDTH-1:0]    mem_data_write,
  output  [ADDR_WIDTH-1:0]    mem_addr,
  output  [2:0]               mem_size,
  output                      mem_wen,

  output                      if_valid,
  input                       if_ready,
  input   [INST_WIDTH-1:0]    if_data_read,
  output  [ADDR_WIDTH-1:0]    if_addr
);

wire flow_if, flow_id, flow_exe, flow_mem, flow_wb;
wire flush_if, flush_id, flush_exe, flush_mem; //flush_wb;
wire stall_if, stall_id, stall_exe, stall_mem, stall_wb;
wire if_hs  = if_valid & if_ready;
wire mem_hs = mem_valid & mem_ready;

wire alu_busy;
//wire if_hs_d, mem_hs_d;
//Reg #(1, 1'b0) if_hs_d_inst (clock, reset, if_hs, if_hs_d, 1);
//Reg #(1, 1'b0) mem_hs_d_inst (clock, reset, mem_hs, mem_hs_d, 1);
wire flow   = (if_hs | ~if_valid) & (mem_hs | ~mem_valid) & (~fence_o | mem_ready) & !alu_busy;
wire mem_hazard_id, mem_hazard_exe;

assign flow_if   = flow & ~stall_if;
assign flow_id   = flow & ~stall_id;
assign flow_exe  = flow & ~stall_exe;
assign flow_mem  = flow & ~stall_mem;
assign flow_wb   = flow & ~stall_wb;
assign stall_if  = mem_hazard_exe | mem_hazard_id;
assign stall_id  = mem_hazard_exe | mem_hazard_id;
assign stall_exe = mem_hazard_exe;
assign stall_mem = 0;
assign stall_wb  = 0;
//--------------------IF-------------------------
wire boot;
wire [INST_WIDTH-1:0] instruction, instruction_load;
wire [DATA_WIDTH-1:0] pc, pc_next, pc_id;

Reg #(1, 1'b1) if_valid_inst (clock, reset, flow_if, if_valid, flow_if | if_ready);
assign if_addr = pc[ADDR_WIDTH-1:0];
Reg #(1, 0) boot_inst (clock, reset, 1, boot, flow_if);
Reg #(DATA_WIDTH, RESET_ADDR) PC_inst (clock, reset, flush_if ? pc_next : pc+4, pc, flow_if);

assign instruction = boot ? if_data_read : RESET_INST;
Reg #(INST_WIDTH, RESET_INST) instruction_load_inst (clock, reset, instruction, instruction_load, if_hs);

//-------------------------IF2ID---------------------------------------
assign flush_if = !(pc_next==pc | flush_id | ~boot) | system_jump;
assign instruction_id = flush_id ? RESET_INST : if_hs ? instruction : instruction_load;
Reg #(1, 1'b0) flush_id_stage_inst (clock, reset, flush_if, flush_id, flow_id);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) PC_stage_inst (clock, reset, pc, pc_id, flow_id);

//--------------------ID---------------------------
wire rf_we_exe, mem_wen_exe, alu_src2_ri_exe, alu_len_dw_exe;
wire rf_we_id, mem_wen_id, alu_src2_ri_id, alu_len_dw_id;
wire [2:0] rf_wdata_src_exe, rf_wdata_src_id;
wire [REG_ADDR_W-1:0] rf_waddr_exe, rf_waddr_id;
wire [INST_WIDTH-1:0] instruction_id, instruction_exe;
wire [DATA_WIDTH-1:0] immediate_exe, immediate_id, pc_exe;
wire [DATA_WIDTH-1:0] rf_rdata1_exe, rf_rdata2_exe, rf_rdata1_id, rf_rdata2_id;

wire rf_we_wb;
wire [REG_ADDR_W-1:0] rf_waddr_wb;
wire [DATA_WIDTH-1:0] rf_wdata_wb;
wire [DATA_WIDTH-1:0] npc;

wire ecall, mret, csr_enable;
wire system_jump;
wire [DATA_WIDTH-1:0] system_jump_entry;
ysyx_040729_IDU #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(DATA_WIDTH),
  .INST_WIDTH(INST_WIDTH),
  .REG_ADDR_W(REG_ADDR_W)
) IDU_inst (
  .clock                  (clock),
  .reset                  (reset),

  .instruction_i          (instruction_id),
  .pc_i                   (pc_id),
  .system_jump_i          (system_jump),
  .system_jump_entry_i    (system_jump_entry),
  .rf_we_i                (rf_we_wb),
  .rf_waddr_i             (rf_waddr_wb),
  .rf_wdata_i             (rf_wdata_wb),

  .rf_we_exe_i            (rf_we_exe),
  .rf_we_mem_i            (rf_we_mem),
  .rf_wdata_src_exe_i     (rf_wdata_src_exe),
  .rf_wdata_src_mem_i     (rf_wdata_src_mem),
  .dst_addr_exe_i         (rf_waddr_exe),
  .dst_addr_mem_i         (rf_waddr_mem),
  .ALU_result_exe_i       (ALU_result_exe),
  .immediate_exe_i        (immediate_exe),
  .pc_exe_i               (pc_exe),
  .ALU_result_mem_i       (ALU_result_mem),
  .immediate_mem_i        (immediate_mem),
  .pc_mem_i               (pc_mem),

  .mem_hazard_o           (mem_hazard_id),

  .rf_we_o                (rf_we_id),
  .rf_waddr_o             (rf_waddr_id),
  .rf_rdata1_o            (rf_rdata1_id),
  .rf_rdata2_o            (rf_rdata2_id),
  .mem_wen_o              (mem_wen_id),
  .alu_src2_ri_o          (alu_src2_ri_id),
  .alu_len_dw_o           (alu_len_dw_id),
  .rf_wdata_src_o         (rf_wdata_src_id),
  .immediate_o            (immediate_id),
  .ecall_o                (ecall),
  .mret_o                 (mret),
  .csr_enable_o           (csr_enable),
  .npc                    (npc),
  .pc_next_o              (pc_next)
);
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
wire [2:0] csr_wfunc;
wire clint_tirq;
wire [DATA_WIDTH-1:0] csr_rdata_id, csr_rdata_exe, csr_mtvec_vis, csr_mepc_hwdata, csr_mcause_hwdata, csr_mepc_vis;
ysyx_040729_CSR CSR_inst(
  .csr_addr           (instruction_id[31:20]),
  .csr_wfunc          (csr_wfunc),
  .csr_uimm           (instruction_id[19:15]),
  .csr_wsrc           (rf_rdata1_id),
  .csr_rdata          (csr_rdata_id),
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
  .flow_i             (flow_id),
  .clock              (clock),
  .reset              (reset)
);
assign system_jump_entry =({DATA_WIDTH{exception}} & csr_mtvec_vis) |
                          ({DATA_WIDTH{mret     }} & csr_mepc_vis ) |
                          ({DATA_WIDTH{!(mret | exception)}} & RESET_ADDR);
assign csr_wfunc = instruction_id[14:12] & {3{csr_enable}};
assign csr_mepc_hwdata = epc_select ? flush_id ? pc : npc : pc_id;
assign csr_mcause_hwdata = excp_mcause;
assign system_jump = exception | mret;

//---------------------------ID2EXE-------------------------------
Reg #(1, 1'b0) flush_exe_stage_inst (clock, reset, flush_id | mem_hazard_id, flush_exe, flow_exe);
Reg #(1, 1'b0) rf_we_exe_stage_inst (clock, reset, mem_hazard_id?1'b0:rf_we_id, rf_we_exe, flow_exe);
Reg #(1, 1'b0) mem_wen_exe_stage_inst (clock, reset, mem_hazard_id?1'b0:mem_wen_id, mem_wen_exe, flow_exe);
Reg #(1, 1'b0) alu_src2_ri_exe_stage_inst (clock, reset, alu_src2_ri_id, alu_src2_ri_exe, flow_exe);
Reg #(1, 1'b0) alu_len_dw_exe_stage_inst (clock, reset, alu_len_dw_id, alu_len_dw_exe, flow_exe);
Reg #(3, 3'b0) rf_wdata_src_exe_stage_inst (clock, reset, mem_hazard_id?3'b0:rf_wdata_src_id, rf_wdata_src_exe, flow_exe);
Reg #(REG_ADDR_W, {REG_ADDR_W{1'b0}}) rf_waddr_exe_stage_inst (clock, reset, rf_waddr_id, rf_waddr_exe, flow_exe);
Reg #(INST_WIDTH, RESET_INST) instruction_exe_stage_inst (clock, reset, instruction_id, instruction_exe, flow_exe);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) rf_rdata1_exe_stage_inst (clock, reset, rf_rdata1_id, rf_rdata1_exe, flow_exe);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) rf_rdata2_exe_stage_inst (clock, reset, rf_rdata2_id, rf_rdata2_exe, flow_exe);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) csr_rdata_exe_stage_inst (clock, reset, csr_rdata_id, csr_rdata_exe, flow_exe);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) immediate_exe_stage_inst (clock, reset, immediate_id, immediate_exe, flow_exe);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) pc_exe_stage_inst (clock, reset, pc_id, pc_exe, flow_exe);


//-------------------------------EXE----------------------------
wire rf_we_mem, mem_wen_mem;
wire [2:0] rf_wdata_src_mem;
wire [REG_ADDR_W-1:0] rf_waddr_mem;
wire [INST_WIDTH-1:0] instruction_mem;
wire [DATA_WIDTH-1:0] mem_wdata_exe, mem_wdata_mem, pc_mem, immediate_mem;
wire [DATA_WIDTH-1:0] ALU_result_mem, ALU_result_exe;
ysyx_040729_EXE #(
  .DATA_WIDTH(DATA_WIDTH),
  .INST_WIDTH(INST_WIDTH),
  .REG_ADDR_W(REG_ADDR_W)
) EXE_inst(
  .clock               (clock),
  .reset               (reset),
  .exe_flow            (flow_exe),
  .rf_rdata1_i         (rf_rdata1_exe),
  .rf_rdata2_i         (rf_rdata2_exe),
  .alu_src2_ri_i       (alu_src2_ri_exe),
  .alu_len_dw_i        (alu_len_dw_exe),
  .immediate_i         (immediate_exe),
  .instruction_i       (instruction_exe),
  .csr_rdata_i         (csr_rdata_exe),
  .rf_we_wb_i          (rf_we_wb        ),
  .rf_we_mem_i         (rf_we_mem       ),
  .rf_wdata_src_mem_i  (rf_wdata_src_mem),
  .dst_addr_wb_i       (rf_waddr_wb     ),
  .dst_addr_mem_i      (rf_waddr_mem    ),
  .rf_wdata_wb_i       (rf_wdata_wb     ),

  .alu_busy            (alu_busy),
  .mem_hazard_o        (mem_hazard_exe),
  .mem_wdata_exe_o     (mem_wdata_exe),
  .ALU_result_o        (ALU_result_exe)
);


//----------------------------EXE2MEM-----------------------
Reg #(1, 1'b0) flush_mem_stage_inst (clock, reset, flush_exe|mem_hazard_exe, flush_mem, flow_mem);
Reg #(1, 1'b0) rf_we_mem_stage_inst (clock, reset, mem_hazard_exe?1'b0:rf_we_exe, rf_we_mem, flow_mem);
Reg #(1, 1'b0) mem_wen_mem_stage_inst (clock, reset, mem_hazard_exe?1'b0:mem_wen_exe, mem_wen_mem, flow_mem);
Reg #(3, 3'b0) rf_wdata_src_mem_stage_inst (clock, reset, mem_hazard_exe?3'b0:rf_wdata_src_exe, rf_wdata_src_mem, flow_mem);
Reg #(REG_ADDR_W, {REG_ADDR_W{1'b0}}) rf_waddr_mem_stage_inst (clock, reset, rf_waddr_exe, rf_waddr_mem, flow_mem);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) ALU_result_mem_stage_inst (clock, reset, ALU_result_exe, ALU_result_mem, flow_mem);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) mem_wdata_mem_stage_inst (clock, reset, mem_wdata_exe, mem_wdata_mem, flow_mem);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) immediate_mem_stage_inst (clock, reset, immediate_exe, immediate_mem, flow_mem);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) pc_mem_stage_inst (clock, reset, pc_exe, pc_mem, flow_mem);
Reg #(INST_WIDTH, {INST_WIDTH{1'b0}}) instruction_mem_stage_inst (clock, reset, instruction_exe, instruction_mem, flow_mem);


//----------------------------MEM----------------------------------
wire [2:0] rf_wdata_src_wb;
wire [DATA_WIDTH-1:0] pc_wb, immediate_wb, ALU_result_wb, mem_rdata_clint, mem_rdata_wb/*verilator split_var*/;

wire mem_wdata_forward = (|instruction_mem[24:20]) & (instruction_mem[24:20]==rf_waddr_wb ) & rf_we_wb;
wire mem_addr_forward  = (|instruction_mem[19:15]) & (instruction_mem[19:15]==rf_waddr_wb ) & rf_we_wb;

wire clint_sel, clint_sel_wb;

wire mem_valid_set, mem_valid_clr, mem_valid_reg;
Reg #(1, 1'b0) mem_valid_inst (clock, reset, mem_valid_set, mem_valid_reg, mem_valid_set | mem_valid_clr);
assign mem_valid_set  = ((rf_wdata_src_exe==3'b001) | mem_wen_exe) & flow_mem;
assign mem_valid_clr  = mem_ready | clint_sel;
assign mem_valid      = mem_valid_reg & ~clint_sel;
assign mem_data_write = mem_wdata_forward ? rf_wdata_wb : mem_wdata_mem; //forward
assign mem_addr       = (mem_addr_forward ? rf_wdata_wb[31:0] : ALU_result_mem[31:0]) + immediate_mem[31:0];
assign mem_wen        = mem_wen_mem;
assign mem_size       = instruction_mem[14:12];

assign fence_o = {instruction_mem[14:12], instruction_mem[6:0]} == 10'b0010001111;

//clint
ysyx_040729_CLINT CLINT_inst(
  .clint_addr  (mem_addr[15:0]),
  .clint_wdata (mem_data_write),
  .clint_rdata (mem_rdata_clint),
  .clint_wen   (mem_wen),
  .clint_sel   (clint_sel),
  .clint_size  (mem_size),
  
  .clint_tirq  (clint_tirq),

  .clock       (clock),
  .reset       (reset)
);
assign clint_sel = mem_addr[ADDR_WIDTH-1:16]==16'h0200;

//---------------------------MEM2WB--------------------------------
//wire [INST_WIDTH-1:0] instruction_wb;
//wire [2:0] mem_addr_wb;
//Reg #(3, 3'b0) mem_addr_wb_stage_inst (clock, reset, mem_addr[2:0], mem_addr_wb, flow_wb);
Reg #(1, 1'b0) clint_sel_wb_stage_inst (clock, reset, clint_sel, clint_sel_wb, flow_wb);
assign mem_rdata_wb = clint_sel_wb ? mem_rdata_clint : mem_data_read;
//Reg #(1, 1'b0) flush_wb_stage_inst (clock, reset, flush_mem, flush_wb, flow_wb);
Reg #(1, 1'b0) rf_we_wb_stage_inst (clock, reset, rf_we_mem, rf_we_wb, flow_wb);
Reg #(3, 3'b0) rf_wdata_src_wb_stage_inst (clock, reset, rf_wdata_src_mem, rf_wdata_src_wb, flow_wb);
Reg #(REG_ADDR_W, {REG_ADDR_W{1'b0}}) rf_waddr_wb_stage_inst (clock, reset, rf_waddr_mem, rf_waddr_wb, flow_wb);
//Reg #(INST_WIDTH, {INST_WIDTH{1'b0}}) instruction_wb_stage_inst (clock, reset, instruction_mem, instruction_wb, flow_wb);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) ALU_result_wb_stage_inst (clock, reset, ALU_result_mem, ALU_result_wb, flow_wb);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) immediate_wb_stage_inst (clock, reset, immediate_mem, immediate_wb, flow_wb);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) pc_wb_stage_inst (clock, reset, pc_mem, pc_wb, flow_wb);

//----------------------------WB-------------------------------------
wire exec_once;
wire [DATA_WIDTH-1:0] rf_wdata_wb, rf_wdata_wb_t, rf_wdata_wb_load;
assign rf_wdata_wb_t = ({DATA_WIDTH{rf_wdata_src_wb == 3'b000}} & (ALU_result_wb  )) |
                       ({DATA_WIDTH{rf_wdata_src_wb == 3'b001}} & (mem_rdata_wb   )) |
                       ({DATA_WIDTH{rf_wdata_src_wb == 3'b010}} & (immediate_wb   )) |
                       ({DATA_WIDTH{rf_wdata_src_wb == 3'b100}} & (pc_wb + immediate_wb)) |
                       ({DATA_WIDTH{rf_wdata_src_wb == 3'b101}} & (pc_wb + 64'd4  )) ;
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) rf_wdata_wb_load_inst (clock, reset, rf_wdata_wb_t, rf_wdata_wb_load, exec_once);
assign rf_wdata_wb = exec_once ? rf_wdata_wb_t : rf_wdata_wb_load;

//------------------------------------------------------------------
Reg #(1, 1'b0) exec_once_inst (clock, reset, flow_wb&~flush_mem, exec_once, 1);



endmodule
