module mat_transpose #(
    parameter N = 4,
    parameter DATA_W = 16
)
(
    input logic signed [DATA_W-1:0] mat_a [N][N],
    output logic signed [DATA_W-1:0] mat_c [N][N]
);

genvar r, c;

generate
    for (r = 0; r < N; r++) begin : gen_row
        for (c = 0; c < N; c++) begin : gen_col
            assign mat_c[r][c] = mat_a[c][r];
        end
    end
endgenerate

endmodule
