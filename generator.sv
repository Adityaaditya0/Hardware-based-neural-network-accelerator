`include "transaction.sv"

class nn_generator;
    nn_trans tr;
    mailbox  mbox;

    function new(mailbox mbox);
        this.mbox = mbox;
    endfunction

    // ------------------------------------------------------------------
    // Helpers to build a directed transaction and queue it
    // ------------------------------------------------------------------
    local task send(nn_trans t);
        $display("\n[GEN] %-22s  ACT=%p  WT=%p  BIAS=%0d  SCALE=%0d",
                 t.test_type.name(), t.act, t.wt, t.bias, t.scale);
        mbox.put(t);
    endtask

    // ------------------------------------------------------------------
    // TC-1  All activations zero → sparsity, every product skipped
    //       Expected output: saturate(bias >>> scale)
    // ------------------------------------------------------------------
    local task tc_sparse_all_zero();
        tr = new();
        tr.test_type = SPARSE_ALL_ZERO;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd0;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd100;
        tr.bias  = 32'sd64;
        tr.scale = 4'd1;   // 64 >>> 1 = 32 → within range
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-2  One non-zero activation, rest sparse
    //       Tests that sparsity_detector correctly gates one lane
    // ------------------------------------------------------------------
    local task tc_sparse_one_nonzero();
        tr = new();
        tr.test_type = SPARSE_ONE_NONZERO;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd0;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd0;
        tr.act[2]  = 8'sd3;
        tr.wt[2]   = 8'sd4;    // product = 12
        tr.bias    = 32'sd0;
        tr.scale   = 4'd0;     // 12 → out = 12
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-3  Positive overflow → quantizer must saturate at +127
    //       4 × (127×127) = 64516 → after any scale ≤ 8 still > 127
    // ------------------------------------------------------------------
    local task tc_saturate_pos();
        tr = new();
        tr.test_type = SATURATE_POS;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd127;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd127;
        tr.bias  = 32'sd0;
        tr.scale = 4'd0;   // sum=64516 → clamped to 127
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-4  Negative overflow → quantizer must saturate at -128
    //       4 × (-128×127) = -65024 → saturate to -128
    // ------------------------------------------------------------------
    local task tc_saturate_neg();
        tr = new();
        tr.test_type = SATURATE_NEG;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = -8'sd128;
        foreach (tr.wt[i])  tr.wt[i]  =  8'sd127;
        tr.bias  = 32'sd0;
        tr.scale = 4'd0;   // sum=-65024 → clamped to -128
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-5  All activations and weights at maximum positive value
    //       with a scale that brings the result within range
    //       4×(127×127)=64516; scale=9 → 64516>>9=126 (within range)
    // ------------------------------------------------------------------
    local task tc_all_max_pos();
        tr = new();
        tr.test_type = ALL_MAX_POS;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd127;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd127;
        tr.bias  = 32'sd0;
        tr.scale = 4'd9;   // 64516 >>> 9 = 126
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-6  All activations/weights at minimum (most-negative) value
    //       (-128)×(-128)=16384; 4×16384=65536; scale=9 → 128 → sat +127
    // ------------------------------------------------------------------
    local task tc_all_max_neg();
        tr = new();
        tr.test_type = ALL_MAX_NEG;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = -8'sd128;
        foreach (tr.wt[i])  tr.wt[i]  = -8'sd128;
        tr.bias  = 32'sd0;
        tr.scale = 4'd9;   // 65536 >>> 9 = 128 → saturates to 127
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-7  Zero bias: verify bias path has no side-effect
    // ------------------------------------------------------------------
    local task tc_zero_bias();
        tr = new();
        tr.test_type = ZERO_BIAS;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd10;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd3;   // each product = 30
        tr.bias  = 32'sd0;                         // sum = 120
        tr.scale = 4'd0;                           // out = 120
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-8  Large scale (maximum shift = 15):
    //       any reasonable sum right-shifted 15 places → typically 0
    // ------------------------------------------------------------------
    local task tc_large_scale();
        tr = new();
        tr.test_type = LARGE_SCALE;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd50;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd50;   // each = 2500; sum = 10000
        tr.bias  = 32'sd0;
        tr.scale = 4'd15;  // 10000 >>> 15 = 0
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-9  Mixed-sign activations: some positive, some negative
    //       Tests that signed multiplication and accumulation work
    // ------------------------------------------------------------------
    local task tc_mixed_signs();
        tr = new();
        tr.test_type = MIXED_SIGNS;
        tr.eot       = 0;
        tr.act[0] =  8'sd10;  tr.wt[0] =  8'sd5;   // +50
        tr.act[1] = -8'sd10;  tr.wt[1] =  8'sd5;   // -50
        tr.act[2] =  8'sd20;  tr.wt[2] = -8'sd3;   // -60
        tr.act[3] = -8'sd20;  tr.wt[3] = -8'sd3;   // +60
        tr.bias  = 32'sd0;   // sum = 0
        tr.scale = 4'd0;     // out = 0
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // TC-10  FSM done-pulse: verify the controller asserts done
    //        (checked by the driver reading vif.done after clk edges)
    // ------------------------------------------------------------------
    local task tc_fsm_done();
        tr = new();
        tr.test_type = FSM_DONE_CHECK;
        tr.eot       = 0;
        foreach (tr.act[i]) tr.act[i] = 8'sd1;
        foreach (tr.wt[i])  tr.wt[i]  = 8'sd1;
        tr.bias  = 32'sd0;
        tr.scale = 4'd0;
        send(tr);
    endtask

    // ------------------------------------------------------------------
    // Main run task
    // ------------------------------------------------------------------
    task run(int rand_count = 10);
        // ── Directed corner-case tests ──────────────────────────────────
        tc_sparse_all_zero();
        tc_sparse_one_nonzero();
        tc_saturate_pos();
        tc_saturate_neg();
        tc_all_max_pos();
        tc_all_max_neg();
        tc_zero_bias();
        tc_large_scale();
        tc_mixed_signs();
        tc_fsm_done();

        // ── Random tests ────────────────────────────────────────────────
        repeat (rand_count) begin
            tr = new();
            tr.test_type = RANDOM;
            tr.eot       = 0;
            assert(tr.randomize());
            $display("\n[GEN] RANDOM  ACT=%p  WT=%p  BIAS=%0d  SCALE=%0d",
                     tr.act, tr.wt, tr.bias, tr.scale);
            mbox.put(tr);
        end

        // ── End-of-test sentinel ────────────────────────────────────────
        tr      = new();
        tr.eot  = 1;
        mbox.put(tr);
    endtask

endclass
