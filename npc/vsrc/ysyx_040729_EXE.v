module ysyx_040729_EXE #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter INST_WIDTH = 32,
    parameter REG_ADDR_W = 5
)(
  input  clock,
  input  reset,

  input  [DATA_WIDTH-1:0] rf_rdata1_i,
  input  [DATA_WIDTH-1:0] rf_rdata2_i,
  input  alu_src2_ri_i,
  input  alu_len_dw_i,
  input  [DATA_WIDTH-1:0] immediate_i,
  input  [ADDR_WIDTH-1:0] pc_i,
  input  [INST_WIDTH-1:0] instruction_i,
  input  [DATA_WIDTH-1:0] csr_rdata_i,
  input                   rf_we_wb_i,
  input                   rf_we_mem_i,
  input  [2:0]            rf_wdata_src_mem_i,
  input  [REG_ADDR_W-1:0] dst_addr_wb_i,
  input  [REG_ADDR_W-1:0] dst_addr_mem_i,
  input  [DATA_WIDTH-1:0] rf_wdata_wb_i,
  input  [DATA_WIDTH-1:0] ALU_result_mem_i,
  input  [DATA_WIDTH-1:0] immediate_mem_i,
  input  [DATA_WIDTH-1:0] pc_mem_i,

  output                  mem_hazard_o,
  output [DATA_WIDTH-1:0] mem_wdata_exe_o,
  output [DATA_WIDTH-1:0] ALU_result_o
);
wire mem_cmd = {instruction_i[6], instruction_i[4:2]}==4'b0;
wire csr_cmd = instruction_i[6:2]==5'b11100;
wire std_cmd = !(mem_cmd | csr_cmd);

//forward
wire [REG_ADDR_W-1:0] src1_addr    = instruction_i[19:15];
wire [REG_ADDR_W-1:0] src2_addr    = instruction_i[24:20];
wire                  rf_we_wb     = rf_we_wb_i;
wire                  rf_we_mem    = rf_we_mem_i;
wire [REG_ADDR_W-1:0] dst_addr_wb  = dst_addr_wb_i;
wire [REG_ADDR_W-1:0] dst_addr_mem = dst_addr_mem_i;
wire [DATA_WIDTH-1:0] rf_wdata_wb  = rf_wdata_wb_i;
// wire [DATA_WIDTH-1:0] rf_wdata_mem = ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b000}} & (ALU_result_mem_i  )) |
//                                      ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b010}} & (immediate_mem_i   )) |
//                                      ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b100}} & (pc_mem_i + immediate_mem_i)) |
//                                      ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b101}} & (pc_mem_i + 64'd4  ));
wire src1_forward_wb  = (|src1_addr) & (src1_addr==dst_addr_wb ) & rf_we_wb ;
wire src1_forward_mem = (|src1_addr) & (src1_addr==dst_addr_mem) & rf_we_mem;
wire src2_forward_wb  = (|src2_addr) & (src2_addr==dst_addr_wb ) & rf_we_wb ;
wire src2_forward_mem = (|src2_addr) & (src2_addr==dst_addr_mem) & rf_we_mem;
wire src1_forward_wbed, src2_forward_wbed;
wire [DATA_WIDTH-1:0] rf_wdata_wbed;
Reg #(1, 1'b0) src1_forward_wbed_inst (clock, reset, mem_hazard_o&src1_forward_wb, src1_forward_wbed, 1);
Reg #(1, 1'b0) src2_forward_wbed_inst (clock, reset, mem_hazard_o&src2_forward_wb, src2_forward_wbed, 1);
Reg #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) rf_wdata_wbed_inst (clock, reset, rf_wdata_wb, rf_wdata_wbed, mem_hazard_o&(src1_forward_wb|src2_forward_wb));

assign mem_wdata_exe_o = src2_forward_wb ? rf_wdata_wb : rf_rdata2_i;

assign mem_hazard_o = (rf_wdata_src_mem_i == 3'b001) & (src1_forward_mem|src2_forward_mem) & ~mem_cmd;

//ALU
wire [DATA_WIDTH-1:0] ALU_src1, ALU_src2, ALU_result;
wire [2:0] alu_func3 = instruction_i[14:12];
wire [6:0] alu_func7 = instruction_i[31:25];
ysyx_040729_EXE_ALU #(DATA_WIDTH) ALU_inst (
  .src1         (ALU_src1),
  .src2         (ALU_src2),
  .alu_func3    (alu_func3),
  .alu_func7    (alu_func7),
  .alu_src2_ri  (alu_src2_ri_i),
  .alu_len_dw   (alu_len_dw_i),
  .result       (ALU_result)
);
assign ALU_src1 = src1_forward_mem ? rf_rdata1_i :
                  src1_forward_wb ? rf_wdata_wb : 
                  src1_forward_wbed ? rf_wdata_wbed : rf_rdata1_i;
assign ALU_src2 = alu_src2_ri_i ? immediate_i : 
                  src2_forward_mem ? rf_rdata2_i :
                  src2_forward_wb ? rf_wdata_wb :
                  src2_forward_wbed ? rf_wdata_wbed : rf_rdata2_i;
assign ALU_result_o = ({DATA_WIDTH{std_cmd}} & (ALU_result )) |
                      ({DATA_WIDTH{mem_cmd}} & (ALU_src1   )) |
                      ({DATA_WIDTH{csr_cmd}} & (csr_rdata_i));

endmodule
