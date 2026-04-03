/* =====================================================
   SCOREBOARD — Reference Model + Output Checker
   ===================================================== */
class nn_scoreboard;

    int pass_count;
    int fail_count;

    function new();
        pass_count = 0;
        fail_count = 0;
    endfunction

    // -------------------------------------------------------
    // Reference model: mirrors the RTL computation exactly
    //   1. sparsity_detector  → skip multiply when act[i]==0
    //   2. mac_int8           → 8-bit signed multiply
    //   3. mac_array_parallel → sum 4 products + bias (32-bit)
    //   4. quantizer          → arithmetic right-shift, saturate
    // -------------------------------------------------------
    function automatic logic signed [7:0] compute_expected(
        input logic signed [7:0]  act  [0:3],
        input logic signed [7:0]  wt   [0:3],
        input logic signed [31:0] bias,
        input logic        [3:0]  scale
    );
        logic signed [15:0] prod;
        logic signed [31:0] sum;
        logic signed [31:0] scaled;

        sum = bias;
        for (int i = 0; i < 4; i++) begin
            if (act[i] != 8'sd0) begin
                prod = act[i] * wt[i];      // 16-bit signed multiply
                sum  = sum + $signed(prod); // sign-extend to 32 bits automatically
            end
        end

        scaled = sum >>> scale;   // arithmetic right shift

        if (scaled > 32'sd127)
            return 8'sd127;
        else if (scaled < -32'sd128)
            return -8'sd128;
        else
            return scaled[7:0];
    endfunction

    // -------------------------------------------------------
    // Check one transaction
    // -------------------------------------------------------
    task check(
        input logic signed [7:0]  act        [0:3],
        input logic signed [7:0]  wt         [0:3],
        input logic signed [31:0] bias,
        input logic        [3:0]  scale,
        input logic signed [7:0]  actual_out,
        input string              label
    );
        logic signed [7:0] expected;
        expected = compute_expected(act, wt, bias, scale);

        if (actual_out === expected) begin
            $display("[SB PASS] %-20s  expected=%4d  got=%4d",
                     label, expected, actual_out);
            pass_count++;
        end else begin
            $display("[SB FAIL] %-20s  expected=%4d  got=%4d",
                     label, expected, actual_out);
            $display("          ACT=%p  WT=%p  BIAS=%0d  SCALE=%0d",
                     act, wt, bias, scale);
            fail_count++;
        end
    endtask

    // -------------------------------------------------------
    // Final summary
    // -------------------------------------------------------
    function void report();
        $display("");
        $display("============================================================");
        $display("  SCOREBOARD FINAL REPORT");
        $display("  PASS  : %0d", pass_count);
        $display("  FAIL  : %0d", fail_count);
        $display("  TOTAL : %0d", pass_count + fail_count);
        if (fail_count == 0)
            $display("  STATUS: ALL TESTS PASSED ✅");
        else
            $display("  STATUS: %0d TEST(S) FAILED ❌", fail_count);
        $display("============================================================");
        $display("");
    endfunction

endclass
