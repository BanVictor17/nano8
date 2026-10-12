`timescale 1ns / 1ps

module instruction_register (
    input logic clk,
    input logic rst,
    input logic load_en,
    input logic [15:0] instr_in,
    output logic [15:0] instr_out
);

    always_ff @(posedge clk) begin
        if (rst == 1'b1) instr_out <= 16'd0;
        else if (load_en == 1'b1) instr_out <= instr_in;
        else instr_out <= instr_out;
    end

endmodule
