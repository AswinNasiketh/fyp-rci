/*
 * Copyright © 2017 Eric Matthews,  Lesley Shannon
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Initial code developed under the supervision of Dr. Lesley Shannon,
 * Reconfigurable Computing Lab, Simon Fraser University.
 *
 * Author(s):
 *             Eric Matthews <ematthew@sfu.ca>
 */

import taiga_config::*;
import taiga_types::*;

module register_file(
        input logic clk,
        input logic rst,
        input logic inorder,
        register_file_writeback_interface.unit rf_wb,
        register_file_decode_interface.unit rf_decode
        );

    (* ramstyle = "MLAB, no_rw_check" *) logic [XLEN-1:0] register [0:31];
    (* ramstyle = "MLAB, no_rw_check" *) logic  [$clog2(INFLIGHT_QUEUE_DEPTH)-1:0] in_use_by [0:31];

    logic rs1_feedforward;
    logic rs2_feedforward;

    logic [0:31] future_rd_one_hot;
    logic [0:31] wb_addr_one_hot;
    logic [0:31] new_inuse;
    logic [0:31] inuse;


    logic in_use_match;
    logic [$clog2(INFLIGHT_QUEUE_DEPTH)-1:0] in_use_by_id;

    //////////////////////////////////////////
    //Assign zero to r0 and initialize all registers to zero
    initial begin
        for (integer i=0; i<32; i++) begin
            register[i] = 0;
            inuse[i] = 0;
            in_use_by[i] = '0;
        end
    end

    //Writeback unit does not assert rf_wb.valid_write when the target register is r0
    always_ff @ (posedge clk) begin
        if (rf_wb.valid_write & (in_use_match | inorder)) //inorder needed for case when multiple outstanding writes to this register (common pattern: load, store, load) where the first load hasn't completed by the second causes an exception.  Without inorder we wouldn't commit the first load
            register[rf_wb.rd_addr] <= rf_wb.rd_data;
    end

    always_comb begin
        future_rd_one_hot = 0;
        future_rd_one_hot[rf_decode.future_rd_addr] = rf_decode.instruction_issued;

        wb_addr_one_hot = 0;
        wb_addr_one_hot[rf_wb.rd_addr] = rf_wb.valid_write & in_use_match;

        new_inuse = (inuse & ~wb_addr_one_hot) | future_rd_one_hot;
    end

    assign inuse[0] = 0;
    always_ff @ (posedge clk) begin
        if (rst)
            inuse[1:31] <= 0;
        else
            inuse[1:31] <= new_inuse[1:31];
    end

    always_ff @ (posedge clk) begin
        if (rf_decode.instruction_issued)
            in_use_by[rf_decode.future_rd_addr] <= rf_decode.id;
    end

    assign in_use_by_id = in_use_by[rf_wb.rd_addr];
    assign in_use_match = (in_use_by_id == rf_wb.id);

    assign rs1_feedforward = (rf_decode.rs1_addr == rf_wb.rd_addr) && rf_wb.valid_write && in_use_match;
    assign rs2_feedforward = (rf_decode.rs2_addr == rf_wb.rd_addr) && rf_wb.valid_write && in_use_match;

    assign rf_decode.rs1_data = rs1_feedforward ? rf_wb.rd_data : register[rf_decode.rs1_addr];
    assign rf_decode.rs2_data = rs2_feedforward ? rf_wb.rd_data : register[rf_decode.rs2_addr];

    assign rf_decode.rs1_conflict = inuse[rf_decode.rs1_addr]  & ~rs1_feedforward;
    assign rf_decode.rs2_conflict = inuse[rf_decode.rs2_addr]  & ~rs2_feedforward;

endmodule
