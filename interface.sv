interface nn_if();

    logic rst_n;
    logic start;

    logic signed [7:0]  act  [0:3];
    logic signed [7:0]  wt   [0:3];
    logic signed [31:0] bias;
    logic        [3:0]  scale;

    // DUT outputs (READ ONLY)
    logic signed [7:0]  out;
    logic               done;


endinterface
