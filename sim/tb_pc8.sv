`timescale 1ns / 1ps

module tb_pc8;

    logic clk;
    logic rst;
    logic inc_en;
    logic load_en;
    logic [7:0] load_addr;
    logic [7:0] pc;

    pc8 pc8_inst (
        .clk(clk),
        .rst(rst),
        .inc_en(inc_en),
        .load_en(load_en),
        .load_addr(load_addr),
        .pc(pc)
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
        inc_en = 1'b0;
        load_en = 1'b0;
        load_addr = 8'd0;

        clock_cycles(1);
        if (pc !== 8'd0) $fatal(1, "Reset failed to clear PC");
        rst = 1'b0;

        inc_en = 1'b1;
        clock_cycles(3);
        if (pc !== 8'd3) $fatal(1, "PC failed to increment to 3");

        inc_en = 1'b0;
        clock_cycles(2);
        if (pc !== 8'd3) $fatal(1, "PC changed with both enables disabled");

        load_en = 1'b1;
        load_addr = 8'd42;
        #1;
        if (pc !== 8'd3) $fatal(1, "PC loaded an address without a rising edge");
        clock_cycles(1);
        if (pc !== 8'd42) $fatal(1, "PC failed to load address 42");

        load_addr = 8'd9;
        clock_cycles(1);
        if (pc !== 8'd9) $fatal(1, "PC failed to load address 9");

        inc_en = 1'b1;
        load_addr = 8'd42;
        #1;
        if (pc !== 8'd9) $fatal(1, "PC changed without a rising edge");
        clk = 1'b0;
        #1;
        if (pc !== 8'd9) $fatal(1, "PC changed on a falling edge");
        clk = 1'b1;
        #1;
        if (pc !== 8'd42) $fatal(1, "Load failed to take priority over increment");

        load_addr = 8'd17;
        clock_cycles(1);
        if (pc !== 8'd17) $fatal(1, "PC failed to load address 17 with inc_en=1");

        rst = 1'b1;
        load_addr = 8'd99;
        #1;
        if (pc !== 8'd17) $fatal(1, "Synchronous reset changed PC without a rising edge");
        clock_cycles(1);
        if (pc !== 8'd0) $fatal(1, "Reset failed to take priority over load and increment");

        rst = 1'b0;
        inc_en = 1'b0;
        load_addr = 8'd255;
        clock_cycles(1);
        if (pc !== 8'd255) $fatal(1, "PC failed to load address 255");

        load_en = 1'b0;
        inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd0) $fatal(1, "PC failed to wrap from 255 to zero");

        inc_en = 1'b0;
        load_addr = 8'd200;
        #1;
        if (pc !== 8'd0) $fatal(1, "Changing load_addr affected PC with load_en=0");
        clock_cycles(2);
        if (pc !== 8'd0) $fatal(1, "PC failed to hold its value after wraparound");

        $display("PC tests passed");
        $finish;
    end
endmodule
