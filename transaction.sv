class nn_trans;

    rand logic signed [7:0]  act  [0:3];
    rand logic signed [7:0]  wt   [0:3];
    rand logic signed [31:0] bias;
    rand logic [3:0]         scale;
  logic [7:0]out;
  logic done;

    // No output here – output comes from DUT only

    // Optional constraints (safe ranges)
    constraint c1 { bias inside {[-128:128]}; }
    constraint c2 { scale inside {[0:4]}; }

endclass
