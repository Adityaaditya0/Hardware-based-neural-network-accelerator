/* =====================================================
   FUNCTIONAL COVERAGE — tracks scenario completeness
   ===================================================== */
class nn_coverage;

    // -------------------------------------------------------
    // Covergroup: sampled once per transaction
    // -------------------------------------------------------
    covergroup nn_cg;

        // Scale value — all 16 possible shifts (0..15)
        cp_scale: coverpoint tr_scale {
            bins shift_none  = {0};
            bins shift_small = {[1:3]};
            bins shift_mid   = {[4:7]};
            bins shift_large = {[8:11]};
            bins shift_max   = {[12:15]};
        }

        // Bias sign
        cp_bias_sign: coverpoint tr_bias_sign {
            bins negative = {-1};
            bins zero     = {0};
            bins positive = {1};
        }

        // Activation sparsity level
        cp_sparsity: coverpoint tr_zero_count {
            bins all_nonzero = {0};
            bins one_zero    = {1};
            bins two_zeros   = {2};
            bins three_zeros = {3};
            bins all_zeros   = {4};
        }

        // DUT output range
        cp_output: coverpoint tr_out_range {
            bins sat_neg  = {-1};   // saturated at -128
            bins negative = {0};    // -127..-1
            bins zero     = {1};    // exactly 0
            bins positive = {2};    // 1..126
            bins sat_pos  = {3};    // saturated at 127
        }

        // Cross: sparsity × output saturation
        cx_sparse_sat: cross cp_sparsity, cp_output;

    endgroup

    // -------------------------------------------------------
    // Sampled variables (written before each sample() call)
    // -------------------------------------------------------
    logic [3:0]   tr_scale;
    int           tr_bias_sign;   // -1, 0, +1
    int           tr_zero_count;  // 0..4 activations that are zero
    int           tr_out_range;   // -1=sat_neg, 0=neg, 1=zero, 2=pos, 3=sat_pos

    function new();
        nn_cg = new();
    endfunction

    task sample(
        input logic signed [7:0]  act   [0:3],
        input logic signed [7:0]  wt    [0:3],
        input logic signed [31:0] bias,
        input logic        [3:0]  scale,
        input logic signed [7:0]  out
    );
        int zc;

        // Scale
        tr_scale = scale;

        // Bias sign
        if      ($signed(bias) > 0)  tr_bias_sign =  1;
        else if ($signed(bias) < 0)  tr_bias_sign = -1;
        else                         tr_bias_sign =  0;

        // Zero-activation count
        zc = 0;
        for (int i = 0; i < 4; i++)
            if (act[i] == 8'sd0) zc++;
        tr_zero_count = zc;

        // Output range bucket
        if      (out === 8'sd127)             tr_out_range =  3;
        else if (out === -8'sd128)            tr_out_range = -1;
        else if (out === 8'sd0)               tr_out_range =  1;
        else if ($signed(out) > 8'sd0)        tr_out_range =  2;
        else                                  tr_out_range =  0;

        nn_cg.sample();
    endtask

    function void report();
        $display("");
        $display("============================================================");
        $display("  FUNCTIONAL COVERAGE REPORT");
        $display("  Coverage: %.1f%%", nn_cg.get_coverage());
        $display("============================================================");
        $display("");
    endfunction

endclass
