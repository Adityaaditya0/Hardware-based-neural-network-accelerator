`timescale 1ns/1ps

`include "interface.sv"
`include "test.sv"

module tb_top;

    // ── Clock generation ──────────────────────────────────────────────
    // 10 ns period (100 MHz)
    nn_if intf();

    initial intf.clk = 1'b0;
    always #5 intf.clk = ~intf.clk;

    // ── Reset sequence ────────────────────────────────────────────────
    initial begin
        intf.rst_n = 1'b0;
        intf.start = 1'b0;
        repeat (4) @(posedge intf.clk);
        intf.rst_n = 1'b1;
    end

    // ── Run test ──────────────────────────────────────────────────────
    initial begin
        nn_test t;
        // Wait for reset de-assertion before starting test
        @(posedge intf.rst_n);
        @(posedge intf.clk);

        t = new(intf);
        t.run();

        #100 $finish;
    end

    // ── DUT instantiation ─────────────────────────────────────────────
    nn_accelerator_top dut (
        .clk  (intf.clk),
        .rst_n(intf.rst_n),
        .start(intf.start),
        .act  (intf.act),
        .wt   (intf.wt),
        .bias (intf.bias),
        .scale(intf.scale),
        .out  (intf.out),
        .done (intf.done)
    );

    // ── Waveform dump ─────────────────────────────────────────────────
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
