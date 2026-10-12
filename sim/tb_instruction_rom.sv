`timescale 1ns / 1ps

module tb_instruction_rom;

    logic clk;
    logic [7:0] addr;
    logic [15:0] instr;
    logic rst;
    logic inc_en;
    logic load_en;
    logic [7:0] load_addr;
    logic [7:0] pc;
    logic [15:0] fetched_instr;

    instruction_rom instruction_rom_inst (
        .clk(clk),
        .addr(addr),
        .instr(instr)
    );

    pc8 pc8_inst (
        .clk(clk),
        .rst(rst),
        .inc_en(inc_en),
        .load_en(load_en),
        .load_addr(load_addr),
        .pc(pc)
    );

    instruction_rom pc_rom_inst (
        .clk(clk),
        .addr(pc),
        .instr(fetched_instr)
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
        addr = 8'd0;
        rst = 1'b1;
        inc_en = 1'b0;
        load_en = 1'b0;
        load_addr = 8'd0;
        #1;
        if (instr !== 16'bx) $fatal(1, "ROM output changed before the first rising edge");

        clock_cycles(1);
        if (instr !== 16'd1000) $fatal(1, "ROM[0] should contain 1000");

        addr = 8'd1;
        #1;
        if (instr !== 16'd1000) $fatal(1, "ROM output changed without a rising edge");
        clk = 1'b0;
        #1;
        if (instr !== 16'd1000) $fatal(1, "ROM output changed on a falling edge");
        clk = 1'b1;
        #1;
        if (instr !== 16'd2000) $fatal(1, "ROM[1] should contain 2000");

        addr = 8'd2;
        clock_cycles(1);
        if (instr !== 16'd3000) $fatal(1, "ROM[2] should contain 3000");

        addr = 8'd255;
        #1;
        if (instr !== 16'd3000) $fatal(1, "Changing the address updated ROM output without a clock edge");
        clock_cycles(1);
        if (instr !== 16'd50000) $fatal(1, "ROM[255] should contain 50000");

        addr = 8'd3;
        #1;
        if (instr !== 16'd50000) $fatal(1, "ROM output failed to hold before reading a default address");
        for (int i = 3; i < 255; i++) begin
            addr = i;
            clock_cycles(1);
            if (instr !== 16'd0) $fatal(1, "ROM[%0d] should contain zero, got %0d", i, instr);
        end

        rst = 1'b0;
        load_en = 1'b1;
        load_addr = 8'd1;
        clock_cycles(1);
        if (pc !== 8'd1 || fetched_instr !== 16'd1000)
            $fatal(1, "Expected PC=1 and word=1000 after loading PC, got PC=%0d word=%0d", pc, fetched_instr);

        load_en = 1'b0;
        inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd2 || fetched_instr !== 16'd2000)
            $fatal(1, "Expected PC=2 and word=2000, got PC=%0d word=%0d", pc, fetched_instr);
        clock_cycles(1);
        if (pc !== 8'd3 || fetched_instr !== 16'd3000)
            $fatal(1, "Expected PC=3 and word=3000, got PC=%0d word=%0d", pc, fetched_instr);

        inc_en = 1'b0;
        clock_cycles(1);
        if (pc !== 8'd3 || fetched_instr !== 16'd0)
            $fatal(1, "ROM failed to read the current address while PC held its value");

        load_en = 1'b1;
        load_addr = 8'd255;
        clock_cycles(1);
        if (pc !== 8'd255 || fetched_instr !== 16'd0)
            $fatal(1, "ROM failed to use the old PC during an address load");
        load_en = 1'b0;
        clock_cycles(1);
        if (pc !== 8'd255 || fetched_instr !== 16'd50000)
            $fatal(1, "ROM failed to read address 255 after the PC load");

        inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd0 || fetched_instr !== 16'd50000)
            $fatal(1, "ROM failed to use the old PC during wraparound");
        inc_en = 1'b0;
        clock_cycles(1);
        if (pc !== 8'd0 || fetched_instr !== 16'd1000)
            $fatal(1, "ROM failed to read address zero after PC wraparound");

        $display("Instruction ROM tests passed");
        $finish;
    end
endmodule
