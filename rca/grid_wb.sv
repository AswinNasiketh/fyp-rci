module grid_wb
    import taiga_config::*;
    import riscv_types::*;
    import taiga_types::*;
    import rca_config::*;
(
    input [XLEN-1:0] io_unit_output_data [NUM_IO_UNITS],
    input io_unit_output_data_valid [NUM_IO_UNITS],
    input io_unit_ls_requested [NUM_IO_UNITS],
    input [NUM_IO_UNITS-1:0] io_unit_ls_mask,

    input [$clog2(NUM_IO_UNITS+1)-1:0] io_unit_sels [NUM_WRITE_PORTS],
    input io_unit_sels_valid,

    output [XLEN-1:0] output_data [NUM_WRITE_PORTS],
    output wb_committing
);

    logic [XLEN-1:0] unit_output_data [NUM_IO_UNITS + 1];
    logic unit_output_data_valid [NUM_IO_UNITS + 1];

    always_comb begin
        for(int i = 0; i < NUM_IO_UNITS; i++) begin
            unit_output_data[i] = io_unit_output_data[i];
            unit_output_data_valid[i] = io_unit_output_data_valid[i];
        end
    end

    assign unit_output_data[NUM_IO_UNITS] = 0;
    assign unit_output_data_valid[NUM_IO_UNITS] = 1; //always 1 to prevent port_ready_for_commit from being blocked by unused write ports
    

    logic [NUM_WRITE_PORTS-1:0] port_ready_for_commit;

    always_comb begin
        for (int i = 0; i < NUM_WRITE_PORTS; i++)
            port_ready_for_commit[i] = io_unit_sels_valid && unit_output_data_valid[io_unit_sels[i]];
    end
    
    logic [NUM_IO_UNITS-1:0] io_unit_ls_requested_p; //packed version
    logic [NUM_IO_UNITS-1:0] ls_requests_complete;

    always_comb begin
        for(int i = 0; i < NUM_IO_UNITS; i++)
            io_unit_ls_requested_p[i] = io_unit_ls_requested[i];
    end

    assign ls_requests_complete = (~io_unit_ls_mask) | io_unit_ls_requested_p;

    assign wb_committing = (&port_ready_for_commit) && (&ls_requests_complete);

    genvar i;

    generate 
        for(i = 0; i < NUM_WRITE_PORTS; i++)
            assign output_data[i] = unit_output_data[io_unit_sels[i]];
    endgenerate

    
endmodule