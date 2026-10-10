`timescale 1ns / 1ps

module regfile8 (
    input logic clk,
    input logic rst,

    input logic       write_en,
    input logic [2:0] write_addr,
    input logic [7:0] write_data,

    input  logic [2:0] read_addr_a,
    input  logic [2:0] read_addr_b,
    output logic [7:0] read_data_a,
    output logic [7:0] read_data_b
);

    logic [7:0] regs[0:7];

    always_ff @(posedge clk) begin
        if (rst == 1'b1) begin
            for (int i = 0; i < 8; i++) begin
                regs[i] <= 8'd0;
            end
        end else if (write_en == 1'b1) begin
            regs[write_addr] <= write_data;
        end
    end

    assign read_data_a = regs[read_addr_a];
    assign read_data_b = regs[read_addr_b];

endmodule
