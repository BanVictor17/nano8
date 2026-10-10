`timescale 1ns / 1ps

module alu8 (
    input logic [7:0] a,
    input logic [7:0] b,
    input enum logic [2:0] {
        ADD        = 3'b000,
        SUB        = 3'b001,
        AND        = 3'b010,
        OR         = 3'b011,
        XOR        = 3'b100,
        PASS_B     = 3'b101,
        RESERVED_1 = 3'b110,
        RESERVED_2 = 3'b111
    } op,
    output logic [7:0] result,
    output logic zero
);

    always_comb begin
        case (op)
            ADD:                    result = a + b;
            SUB:                    result = a - b;
            AND:                    result = a & b;
            OR:                     result = a | b;
            XOR:                    result = a ^ b;
            PASS_B:                 result = b;
            RESERVED_1, RESERVED_2: result = '0;
            default:                result = '0;
        endcase
    end

    assign zero = (result == 8'd0);
endmodule
