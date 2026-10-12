`timescale 1ns / 1ps

module instruction_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] instr
);

    always_ff @(posedge clk) begin
        case (addr)
            8'd0: instr <= 16'd1000;
            8'd1: instr <= 16'd2000;
            8'd2: instr <= 16'd3000;
            8'd255: instr <= 16'd50000;
            default: instr <= 16'd0;
        endcase
    end

endmodule
