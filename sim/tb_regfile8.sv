`timescale 1ns / 1ps

module tb_regfile8;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic write_en = 1'b0;
    logic [2:0] write_addr = 3'd0;
    logic [7:0] write_data = 8'd0;
    logic [2:0] read_addr_a = 3'd0;
    logic [2:0] read_addr_b = 3'd0;
    logic [7:0] read_data_a;
    logic [7:0] read_data_b;
    int checks = 0;

    regfile8 regfile8_inst (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    always #5 clk = ~clk;

    task automatic check_outputs(
        input logic [7:0] expected_a,
        input logic [7:0] expected_b
    );
        #1;
        if (read_data_a !== expected_a)
            $fatal(1, "time=%0t port A R%0d: expected %0d, got %0d",
                   $time, read_addr_a, expected_a, read_data_a);
        if (read_data_b !== expected_b)
            $fatal(1, "time=%0t port B R%0d: expected %0d, got %0d",
                   $time, read_addr_b, expected_b, read_data_b);
        checks++;
    endtask

    task automatic check_reads(
        input logic [2:0] addr_a,
        input logic [2:0] addr_b,
        input logic [7:0] expected_a,
        input logic [7:0] expected_b
    );
        read_addr_a = addr_a;
        read_addr_b = addr_b;
        check_outputs(expected_a, expected_b);
    endtask

    task automatic write_register(
        input logic [2:0] addr,
        input logic [7:0] data
    );
        // Keep write controls stable around the rising edge.
        @(negedge clk);
        write_en = 1'b1;
        write_addr = addr;
        write_data = data;
        @(posedge clk);
        #1;
        @(negedge clk);
        write_en = 1'b0;
    endtask

    task automatic check_all_zero;
        for (int i = 0; i < 8; i++) begin
            check_reads(i[2:0], 3'd7 - i[2:0], 8'd0, 8'd0);
        end
    endtask

    initial begin
        @(posedge clk);
        check_all_zero();

        @(negedge clk);
        rst = 1'b0;

        for (int i = 0; i < 8; i++) begin
            write_register(i[2:0], 8'd10 + i[7:0]);
        end
        for (int i = 0; i < 8; i++) begin
            check_reads(i[2:0], 3'd7 - i[2:0],
                        8'd10 + i[7:0], 8'd17 - i[7:0]);
        end

        @(negedge clk);
        write_en = 1'b0;
        write_addr = 3'd2;
        write_data = 8'd99;
        check_reads(3'd2, 3'd5, 8'd12, 8'd15);
        @(posedge clk);
        check_outputs(8'd12, 8'd15);

        write_register(3'd2, 8'd17);
        check_reads(3'd2, 3'd2, 8'd17, 8'd17);

        @(negedge clk);
        write_en = 1'b1;
        write_addr = 3'd2;
        write_data = 8'd99;
        check_outputs(8'd17, 8'd17);
        @(posedge clk);
        check_outputs(8'd99, 8'd99);
        @(negedge clk);
        write_en = 1'b0;

        for (int i = 0; i < 8; i++) begin
            check_reads(i[2:0], i[2:0],
                        (i == 2) ? 8'd99 : 8'd10 + i[7:0],
                        (i == 2) ? 8'd99 : 8'd10 + i[7:0]);
        end

        @(negedge clk);
        rst = 1'b1;
        write_en = 1'b1;
        write_addr = 3'd5;
        write_data = 8'd200;
        // Reset must preserve the old values until the rising edge.
        check_reads(3'd2, 3'd5, 8'd99, 8'd15);
        @(posedge clk);
        check_outputs(8'd0, 8'd0);
        @(negedge clk);
        rst = 1'b0;
        write_en = 1'b0;
        check_all_zero();

        $display("Register file tests passed (%0d checks)", checks);
        $finish;
    end
endmodule
