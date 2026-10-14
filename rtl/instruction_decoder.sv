`timescale 1ns / 1ps

module instruction_decoder (
    input logic [15:0] instr,
    output logic [3:0] opcode,
    output logic [2:0] rd,
    output logic [2:0] rs,
    output logic [7:0] imm,
    output logic valid
);

    assign opcode = instr[15:12];
    assign rd = instr[11:9];
    assign rs = instr[8:6];
    assign imm = instr[7:0];

    always_comb begin
        case (opcode)
            0 || 15: valid = (instr[11:0] == 12'd0);
            1: valid = (instr[8] == 1'd0);
            2 || 3 || 4 || 5 || 6 || 7: valid = (instr[5:0] == 6'd0);
            default: valid = 0;
        endcase
    end

endmodule
