`timescale 1ns / 1ps

module tb_instruction_register;

    logic clk;
    logic rst;
    logic load_en;
    logic [15:0] instr_in;
    logic [15:0] instr_out;
    logic pc_inc_en;
    logic pc_load_en;
    logic [7:0] pc_load_addr;
    logic [7:0] pc;
    logic [15:0] rom_instr;
    logic ir_load_en;
    logic [15:0] ir;

    instruction_register instruction_register_inst (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .instr_in(instr_in),
        .instr_out(instr_out)
    );

    pc8 pc8_inst (
        .clk(clk),
        .rst(rst),
        .inc_en(pc_inc_en),
        .load_en(pc_load_en),
        .load_addr(pc_load_addr),
        .pc(pc)
    );

    instruction_rom instruction_rom_inst (
        .clk(clk),
        .addr(pc),
        .instr(rom_instr)
    );

    instruction_register fetched_ir_inst (
        .clk(clk),
        .rst(rst),
        .load_en(ir_load_en),
        .instr_in(rom_instr),
        .instr_out(ir)
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
        load_en = 1'b0;
        instr_in = 16'd1000;
        pc_inc_en = 1'b0;
        pc_load_en = 1'b0;
        pc_load_addr = 8'd0;
        ir_load_en = 1'b0;

        clock_cycles(1);
        if (instr_out !== 16'd0) $fatal(1, "Reset failed to clear the instruction register");
        rst = 1'b0;

        load_en = 1'b1;
        clock_cycles(1);
        if (instr_out !== 16'd1000) $fatal(1, "IR failed to capture 1000");

        load_en = 1'b0;
        instr_in = 16'd50000;
        #1;
        if (instr_out !== 16'd1000) $fatal(1, "Changing instr_in changed IR without a clock edge");
        clock_cycles(2);
        if (instr_out !== 16'd1000) $fatal(1, "IR changed with load_en=0");

        load_en = 1'b1;
        #1;
        if (instr_out !== 16'd1000) $fatal(1, "IR changed before a rising edge");
        clk = 1'b0;
        #1;
        if (instr_out !== 16'd1000) $fatal(1, "IR changed on a falling edge");
        clk = 1'b1;
        #1;
        if (instr_out !== 16'd50000) $fatal(1, "IR failed to capture 50000");

        rst = 1'b1;
        instr_in = 16'd65535;
        #1;
        if (instr_out !== 16'd50000) $fatal(1, "Synchronous reset changed IR without a rising edge");
        clock_cycles(1);
        if (instr_out !== 16'd0) $fatal(1, "Reset failed to take priority over IR loading");

        rst = 1'b0;
        clock_cycles(1);
        if (instr_out !== 16'd65535) $fatal(1, "IR failed to preserve all 16 input bits");
        load_en = 1'b0;
        instr_in = 16'd0;
        clock_cycles(2);
        if (instr_out !== 16'd65535) $fatal(1, "IR failed to hold its value");

        rst = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd0 || ir !== 16'd0 || rom_instr !== 16'd1000)
            $fatal(1, "Fetch path reset failed");
        rst = 1'b0;

        pc_inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd1 || rom_instr !== 16'd1000 || ir !== 16'd0)
            $fatal(1, "IR failed to hold while PC advanced");

        pc_inc_en = 1'b0;
        ir_load_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd1 || rom_instr !== 16'd2000 || ir !== 16'd1000)
            $fatal(1, "Expected PC=1 ROM=2000 IR=1000, got PC=%0d ROM=%0d IR=%0d", pc, rom_instr, ir);

        ir_load_en = 1'b0;
        clock_cycles(2);
        if (pc !== 8'd1 || rom_instr !== 16'd2000 || ir !== 16'd1000)
            $fatal(1, "IR failed to preserve the instruction while ROM read the next word");

        ir_load_en = 1'b1;
        pc_inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd2 || rom_instr !== 16'd2000 || ir !== 16'd2000)
            $fatal(1, "IR capture and PC increment failed");

        ir_load_en = 1'b0;
        pc_inc_en = 1'b0;
        clock_cycles(1);
        if (pc !== 8'd2 || rom_instr !== 16'd3000 || ir !== 16'd2000)
            $fatal(1, "IR changed when ROM refreshed its output");

        pc_load_en = 1'b1;
        pc_load_addr = 8'd255;
        clock_cycles(1);
        if (pc !== 8'd255 || rom_instr !== 16'd3000 || ir !== 16'd2000)
            $fatal(1, "IR changed during a PC address load");

        pc_load_en = 1'b0;
        clock_cycles(1);
        if (rom_instr !== 16'd50000 || ir !== 16'd2000)
            $fatal(1, "ROM failed to prepare the word at address 255");

        ir_load_en = 1'b1;
        pc_inc_en = 1'b1;
        clock_cycles(1);
        if (pc !== 8'd0 || rom_instr !== 16'd50000 || ir !== 16'd50000)
            $fatal(1, "IR capture failed during PC wraparound");

        ir_load_en = 1'b0;
        pc_inc_en = 1'b0;
        clock_cycles(1);
        if (rom_instr !== 16'd1000 || ir !== 16'd50000)
            $fatal(1, "IR failed to hold after PC wraparound");

        rst = 1'b1;
        ir_load_en = 1'b1;
        pc_inc_en = 1'b1;
        pc_load_en = 1'b1;
        pc_load_addr = 8'd2;
        #1;
        if (ir !== 16'd50000) $fatal(1, "Fetch IR reset took effect without a rising edge");
        clock_cycles(1);
        if (pc !== 8'd0 || ir !== 16'd0)
            $fatal(1, "Fetch path reset failed to take priority over enabled controls");

        $display("Instruction register tests passed");
        $finish;
    end
endmodule
