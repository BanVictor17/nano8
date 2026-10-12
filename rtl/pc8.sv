`timescale 1ns / 1ps

module pc8 (
    input logic clk,
    input logic rst,
    input logic inc_en,
    input logic load_en,
    input logic [7:0] load_addr,
    output logic [7:0] pc
);

    always_ff @(posedge clk) begin
        if (rst == 1'b1) pc <= 8'd0;
        else if (load_en == 1'b1) pc <= load_addr;
        else if (inc_en == 1'b1) pc <= pc + 8'd1;
        else pc <= pc;
    end

endmodule
