module battery_model_simple #(
    parameter WL = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              bm_en,

    input  wire signed [15:0] current_i,   // Q8.8
    input  wire        [15:0] soc_i,        // Q1.15

    input  wire        [15:0] r0_i,          // Q8.8
    input  wire        [15:0] r1_i,          // Q8.8
    input  wire        [15:0] alpha_i,       // dt / tau in Q1.15

    output reg  signed [15:0] v_pred_o       // Q8.8
);

    // INTERNAL
    reg signed [15:0] vp;          // polarization voltage Q8.8
    wire signed [15:0] vocv;       // from LUT
    wire signed [31:0] i_r0;
    wire signed [31:0] i_r1;
    wire signed [31:0] vp_next_ext;
    wire signed [15:0] vp_next;

    // OCV LUT
    ocv_lut_wrapper ocv_lut (
        .soc_i(soc_i),
        .vocv_o(vocv)
    );

    // RC DYNAMICS
    assign i_r1 = current_i * r1_i;    // Q8.8 × Q8.8 → Q16.16

    assign vp_next_ext =
        vp + ((alpha_i * ((i_r1 >>> 8) - vp)) >>> 15);

    assign vp_next = vp_next_ext[15:0];

    // STATE UPDATE
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            vp <= 16'd0;
        else if (bm_en)
            vp <= vp_next;
    end

    // OUTPUT VOLTAGE
    assign i_r0 = current_i * r0_i;    // Q16.16

    always @(*) begin
        v_pred_o = vocv
                 - (i_r0 >>> 8)
                 - vp;
    end

endmodule
