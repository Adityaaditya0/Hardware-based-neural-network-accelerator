class nn_driver;

    virtual nn_if vif;
    mailbox       gen_mbox;   // transactions from generator
    mailbox       sb_mbox;    // completed transactions to scoreboard
    nn_trans      tr;

    function new(virtual nn_if vif, mailbox gen_mbox, mailbox sb_mbox);
        this.vif      = vif;
        this.gen_mbox = gen_mbox;
        this.sb_mbox  = sb_mbox;
    endfunction

    task run();
        // De-assert start while idle
        vif.start <= 1'b0;

        forever begin
            gen_mbox.get(tr);

            // ── End-of-test sentinel ──────────────────────────────────
            if (tr.eot) begin
                $display("\n[DRIVER] End-of-test sentinel received — finishing.");
                break;
            end

            // ── Apply inputs on rising edge ───────────────────────────
            @(posedge vif.clk);
            vif.act   <= tr.act;
            vif.wt    <= tr.wt;
            vif.bias  <= tr.bias;
            vif.scale <= tr.scale;
            vif.start <= 1'b1;

            // ── Wait one cycle for FSM to move IDLE→COMPUTE ───────────
            @(posedge vif.clk);
            vif.start <= 1'b0;

            // ── Wait one more cycle for FSM to reach DONE ────────────
            @(posedge vif.clk);
            // Sample 1 ns after the clock edge so non-blocking assignments
            // from the DUT's always blocks have settled (standard SV technique)
            #1;

            // ── Capture outputs ───────────────────────────────────────
            tr.dut_out = vif.out;
            tr.done = vif.done;

            // Verify done asserts for FSM_DONE_CHECK scenario
            if (tr.test_type == FSM_DONE_CHECK) begin
                if (tr.done)
                    $display("[DRIVER] FSM_DONE_CHECK PASS — done asserted ✅");
                else
                    $display("[DRIVER] FSM_DONE_CHECK FAIL — done NOT asserted ❌");
            end

            $display("[DRIVER] %-22s  out=%4d  done=%0b",
                     tr.test_type.name(), tr.dut_out, tr.done);
            $display("----------------------------------------------------------");

            // Forward to scoreboard
            sb_mbox.put(tr);
        end
    endtask

endclass
