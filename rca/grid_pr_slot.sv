module grid_pr_slot
    import taiga_config::*;
    import riscv_types::*;
    import taiga_types::*;
    import rca_config::*;
(
    input clk,
    input rst,

    //mostly dealing with up to 2 input instructions    
    input [XLEN-1:0] data_in1,
    input [XLEN-1:0] data_in2,

    input data_valid_in1,
    input data_valid_in2,

    output [XLEN-1:0] data_out,
    output data_valid_out
);

//TODO: expand to 2 inputs and FIFO them
    
endmodule