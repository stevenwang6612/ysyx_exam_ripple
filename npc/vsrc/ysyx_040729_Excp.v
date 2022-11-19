module ysyx_040729_Excp #(DATA_WIDTH = 64)(
    input  ext_irq,
    input  tmr_irq,
    input  ecall,

    output [DATA_WIDTH-1:0]excp_mcause,
    output epc_select,

    output exception
);

wire interrupt = ext_irq | tmr_irq;
wire [3:0] itrpt_cause, error_cause;

assign exception = ext_irq | tmr_irq | ecall;

assign epc_select = interrupt;

assign excp_mcause[DATA_WIDTH-1] = interrupt;
assign excp_mcause[DATA_WIDTH-2:4] = {DATA_WIDTH-5{1'b0}};
assign excp_mcause[3:0] = interrupt ? itrpt_cause : error_cause;
assign itrpt_cause = ext_irq ? 4'hb :
                     tmr_irq ? 4'h7 :
                     4'h0;
assign error_cause = 4'hb;
    
endmodule
