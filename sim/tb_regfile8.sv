`timescale 1ns / 1ps

module tb_regfile8;

    logic clk;
    logic rst;
    logic write_en;
    logic [2:0] write_addr;
    logic [7:0] write_data;
    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;
    logic [7:0] read_data_a;
    logic [7:0] read_data_b;

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

    task automatic clock_cycles(input int unsigned cycles);
        repeat (cycles) begin
            clk = 1'b0;
            #1;
            clk = 1'b1;
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        write_en = 1'b0;
        write_addr = 3'd0;
        write_data = 8'd0;
        read_addr_a = 3'd0;
        read_addr_b = 3'd0;

        clock_cycles(1);
        rst = 1'b0;

        for (int i = 0; i < 8; i++) begin
            read_addr_a = i;
            read_addr_b = 7 - i;
            #1;
            if (read_data_a !== 8'd0 || read_data_b !== 8'd0)
                $fatal(1, "Reset failed to clear R%0d or R%0d", i, 7 - i);
        end

        write_en = 1'b1;
        for (int i = 0; i < 8; i++) begin
            write_addr = i;
            write_data = 10 + i;
            clock_cycles(1);
        end
        write_en = 1'b0;

        for (int i = 0; i < 8; i++) begin
            read_addr_a = i;
            read_addr_b = 7 - i;
            #1;
            if (read_data_a !== 10 + i)
                $fatal(1, "Port A returned incorrect data for R%0d", i);
            if (read_data_b !== 17 - i)
                $fatal(1, "Port B returned incorrect data for R%0d", 7 - i);
        end

        write_addr = 3'd2;
        write_data = 8'd99;
        read_addr_a = 3'd2;
        read_addr_b = 3'd5;
        #1;
        if (read_data_a !== 8'd12 || read_data_b !== 8'd15)
            $fatal(1, "Read ports failed to update without a clock edge");
        clock_cycles(2);
        if (read_data_a !== 8'd12 || read_data_b !== 8'd15)
            $fatal(1, "Register contents changed with write_en=0");

        write_en = 1'b1;
        write_data = 8'd17;
        clock_cycles(1);
        write_en = 1'b0;
        read_addr_b = 3'd2;
        #1;
        if (read_data_a !== 8'd17 || read_data_b !== 8'd17)
            $fatal(1, "Both ports should read R2 as 17");

        write_en = 1'b1;
        write_data = 8'd99;
        #1;
        if (read_data_a !== 8'd17 || read_data_b !== 8'd17)
            $fatal(1, "Register changed without a rising edge");
        clk = 1'b0;
        #1;
        if (read_data_a !== 8'd17 || read_data_b !== 8'd17)
            $fatal(1, "Register changed on a falling edge");
        clk = 1'b1;
        #1;
        if (read_data_a !== 8'd99 || read_data_b !== 8'd99)
            $fatal(1, "Register failed to update after a rising edge");
        write_en = 1'b0;

        for (int i = 0; i < 8; i++) begin
            read_addr_a = i;
            read_addr_b = i;
            #1;
            if (i == 2) begin
                if (read_data_a !== 8'd99 || read_data_b !== 8'd99)
                    $fatal(1, "R2 failed to preserve its new value");
            end else begin
                if (read_data_a !== 10 + i || read_data_b !== 10 + i)
                    $fatal(1, "Writing R2 changed R%0d", i);
            end
        end

        rst = 1'b1;
        write_en = 1'b1;
        write_addr = 3'd5;
        write_data = 8'd200;
        read_addr_a = 3'd2;
        read_addr_b = 3'd5;
        #1;
        if (read_data_a !== 8'd99 || read_data_b !== 8'd15)
            $fatal(1, "Synchronous reset changed registers without a rising edge");
        clock_cycles(1);
        if (read_data_a !== 8'd0 || read_data_b !== 8'd0)
            $fatal(1, "Reset failed to take priority over a write");
        rst = 1'b0;
        write_en = 1'b0;

        for (int i = 0; i < 8; i++) begin
            read_addr_a = i;
            read_addr_b = 7 - i;
            #1;
            if (read_data_a !== 8'd0 || read_data_b !== 8'd0)
                $fatal(1, "Reset failed to clear R%0d or R%0d", i, 7 - i);
        end

        $display("Register file tests passed");
        $finish;
    end
endmodule
