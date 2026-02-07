`timescale 1ns/1ps

`include "nn_if.sv"
`include "nn_test.sv"

module tb_top;



  nn_if intf();initial begin
        // ✅ DECLARATION MUST COME FIRST
        nn_test t;
        t = new(intf);
        t.run();

        #200 $finish;
    end

    nn_accelerator_top dut (
        .start(intf.start),
        .act(intf.act),
        .wt(intf.wt),
        .bias(intf.bias),
        .scale(intf.scale),
        .out(intf.out),
        .done(intf.done)
    );

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

    
endmodule
