module adaptive_coulomb_counter #(
    parameter integer WL = 16,
    parameter integer SOC_INIT = 16'd16384   // 0.5 in Q1.15
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              cc_en,

    input  wire signed [WL-1:0] current_i,  // Q8.8
    output reg  [WL-1:0]        soc_o        // Q1.15
);

    // CONSTANTS 
    // η = 0.85 → Q1.15
    localparam signed [15:0] ETA = 16'h6CCD;

    // (dt / (C * 3600)) scaled to Q1.15
    // 3.86e-5 * 2^15 ≈ 1.26 → ≈ 1
    localparam signed [15:0] DT_C_INV = 16'sd1;

    // INTERNAL 
    wire signed [31:0] cur_eta;
    wire signed [31:0] delta_soc_ext;
    wire signed [15:0] delta_soc;

    // current × η
    assign cur_eta = current_i * ETA;               // Q8.8 × Q1.15 → Q9.23

    // × dt/C
    assign delta_soc_ext = cur_eta * DT_C_INV;       // Q9.23 × Q1.15 → Q10.38

    // align to Q1.15
    assign delta_soc = delta_soc_ext >>> 23;

    // ACCUMULATOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            soc_o <= SOC_INIT;
        else if (cc_en) begin
            if ($signed(soc_o) + delta_soc < 0)
                soc_o <= 16'd0;
            else if ($signed(soc_o) + delta_soc > 16'h7FFF)
                soc_o <= 16'h7FFF;
            else
                soc_o <= soc_o + delta_soc;
        end
    end

endmodule
