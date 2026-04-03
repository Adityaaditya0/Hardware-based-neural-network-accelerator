// Test scenario identifiers — used for labelling scoreboard output
typedef enum {
    RANDOM,
    SPARSE_ALL_ZERO,
    SPARSE_ONE_NONZERO,
    SATURATE_POS,
    SATURATE_NEG,
    ALL_MAX_POS,
    ALL_MAX_NEG,
    ZERO_BIAS,
    LARGE_SCALE,
    MIXED_SIGNS,
    FSM_DONE_CHECK
} test_type_e;

class nn_trans;

    rand logic signed [7:0]  act  [0:3];
    rand logic signed [7:0]  wt   [0:3];
    rand logic signed [31:0] bias;
    rand logic [3:0]         scale;
    logic signed [7:0]       dut_out;
    logic                    done;
    test_type_e              test_type;
    bit                      eot;    // end-of-test sentinel (no payload)

    // Default constraints keep random tests in a reasonable range
    constraint c1 { bias  inside {[-256:256]}; }
    constraint c2 { scale inside {[0:7]};      }

endclass
