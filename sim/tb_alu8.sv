`timescale 1ns / 1ps

module tb_alu8;
    logic [7:0] a;
    logic [7:0] b;
    typedef enum logic [2:0] {
        ADD        = 3'b000,
        SUB        = 3'b001,
        AND        = 3'b010,
        OR         = 3'b011,
        XOR        = 3'b100,
        PASS_B     = 3'b101,
        RESERVED_1 = 3'b110,
        RESERVED_2 = 3'b111
    } alu_op_t;
    alu_op_t op;
    logic [7:0] result;
    logic zero;

    alu8 alu8_inst (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero)
    );

    task automatic check(input logic [7:0] _a, input logic [7:0] _b, input alu_op_t _op, input logic [7:0] _result);
        a  = _a;
        b  = _b;
        op = _op;
        #1;

        if (result !== _result)
            $fatal(1, "op=%0d a=%0d b=%0d: expected result=%0d, got %0d", _op, _a, _b, _result, result);
        if (zero !== (_result == 8'd0))
            $fatal(1, "op=%0d a=%0d b=%0d: expected zero=%b, got %b", _op, _a, _b, (_result == 8'd0), zero);
    endtask

    initial begin
        check(8'd254, 8'd3,  ADD,        8'd1);
        check(8'd255, 8'd1,  ADD,        8'd0);
        check(8'd0,   8'd1,  SUB,        8'd255);
        check(8'd42,  8'd42, SUB,        8'd0);
        check(8'd12,  8'd10, AND,        8'd8);
        check(8'd12,  8'd10, OR,         8'd14);
        check(8'd12,  8'd10, XOR,        8'd6);
        check(8'd42,  8'd42, XOR,        8'd0);
        check(8'd77,  8'd23, PASS_B,     8'd23);
        check(8'd77,  8'd0,  PASS_B,     8'd0);
        check(8'd12,  8'd10, RESERVED_1, 8'd0);
        check(8'd12,  8'd10, RESERVED_2, 8'd0);

        $display("ALU tests passed (12 checks)");
        $finish;
    end
endmodule
