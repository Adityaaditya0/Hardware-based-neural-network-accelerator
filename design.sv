  module sparsity_detector (
    input  wire signed [7:0] activation,
    output wire              valid
);
    assign valid = (activation != 8'sd0);
endmodule


/* =====================================================
   INT8 PARALLEL MAC (SPARSITY AWARE)
   ===================================================== */
module mac_int8 (
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  w,
    input  wire               valid,
    output wire signed [15:0] p
);
    assign p = valid ? (a * w) : 16'sd0;
endmodule


/* =====================================================
   PARALLEL MAC ARRAY + BIAS
   ===================================================== */
module mac_array_parallel #(
    parameter N = 4
)(
    input  wire signed [7:0]  act  [0:N-1],
    input  wire signed [7:0]  wt   [0:N-1],
    input  wire signed [31:0] bias,
    output wire signed [31:0] sum_out
);
    wire valid [0:N-1];
    wire signed [15:0] prod [0:N-1];
    wire signed [31:0] ext  [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : MACS
            sparsity_detector sd (
                .activation(act[i]),
                .valid(valid[i])
            );

            mac_int8 mac (
                .a(act[i]),
                .w(wt[i]),
                .valid(valid[i]),
                .p(prod[i])
            );

            assign ext[i] = {{16{prod[i][15]}}, prod[i]};
        end
    endgenerate

    // Parallel reduction + bias
    assign sum_out = ext[0] + ext[1] + ext[2] + ext[3] + bias;
endmodule


/* =====================================================
   QUANTIZER (INT32 → INT8, SATURATING)
   ===================================================== */
module quantizer (
    input  wire signed [31:0] in,
    input  wire [3:0]         scale,
    output reg  signed [7:0]  out
);
    wire signed [31:0] scaled;
    assign scaled = in >>> scale;

    always @(*) begin
        if (scaled > 127)
            out = 8'sd127;
        else if (scaled < -128)
            out = -8'sd128;
        else
            out = scaled[7:0];
    end
endmodule


/* =====================================================
   CONTROLLER FSM
   ===================================================== */
module controller (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg  compute_en,
    output reg  done
);
    typedef enum logic [1:0] {IDLE, COMPUTE, DONE} state_t;
    state_t state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else case (state)
            IDLE:    state <= start ? COMPUTE : IDLE;
            COMPUTE: state <= DONE;
            DONE:    state <= IDLE;
        endcase
    end

    always @(*) begin
        compute_en = (state == COMPUTE);
        done       = (state == DONE);
    end
endmodule


/* =====================================================
   TOP MODULE (FULLY SYNTHESIZABLE)
   ===================================================== */
module nn_accelerator_top (
    
    input  wire               start,

    input  wire signed [7:0]  act  [0:3],
    input  wire signed [7:0]  wt   [0:3],
    input  wire signed [31:0] bias,
    input  wire [3:0]         scale,

    output wire signed [7:0]  out,
    output wire               done
);
    wire compute_en;
    wire signed [31:0] mac_sum;

    controller ctrl (
        .start(start),
        .compute_en(compute_en),
        .done(done)
    );

    mac_array_parallel macarr (
        .act(act),
        .wt(wt),
        .bias(bias),
        .sum_out(mac_sum)
    );

    quantizer qtz (
        .in(mac_sum),
        .scale(scale),
        .out(out)
    );
endmodule


