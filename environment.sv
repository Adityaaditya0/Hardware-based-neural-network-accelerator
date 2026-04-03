`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "scoreboard.sv"
`include "coverage.sv"

class nn_env;

    nn_generator  gen;
    nn_driver     drv;
    nn_scoreboard sb;
    nn_coverage   cov;

    mailbox gen_mbox;  // generator → driver
    mailbox sb_mbox;   // driver → scoreboard/coverage

    virtual nn_if vif;

    function new(virtual nn_if vif);
        this.vif = vif;

        gen_mbox = new();
        sb_mbox  = new();

        gen = new(gen_mbox);
        sb  = new();
        cov = new();
        drv = new(vif, gen_mbox, sb_mbox);
    endfunction

    // Drain all completed transactions from the scoreboard mailbox
    task drain_scoreboard();
        nn_trans tr;
        while (sb_mbox.num() > 0) begin
            sb_mbox.get(tr);
            sb.check(tr.act, tr.wt, tr.bias, tr.scale, tr.dut_out,
                     tr.test_type.name());
            cov.sample(tr.act, tr.wt, tr.bias, tr.scale, tr.dut_out);
        end
    endtask

    task run();
        // Generator sends all items + EOT then exits.
        // Driver reads until EOT then breaks — so both finish cleanly.
        fork
            gen.run(10);
            drv.run();
        join   // wait for both to complete (no deadlock: driver exits on EOT)

        // Drain scoreboard mailbox (all transactions are now in sb_mbox)
        drain_scoreboard();

        sb.report();
        cov.report();
    endtask

endclass
