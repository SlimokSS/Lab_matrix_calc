module mat_addsub #(
    parameter N = 4,
    parameter DATA_W = 16
)
(
    input logic sub, //Type of operation
    input logic signed [DATA_W-1:0] mat_a [N][N],
    input logic signed [DATA_W-1:0] mat_b [N][N],
    
    output logic signed [DATA_W-1:0] mat_c [N][N],
    output logic overflow //Overflow flag
);
    logic signed [DATA_W:0] ext_res [N][N];
    genvar r, c;
    generate
        for (r = 0; r < N; r++) begin : gen_row
            for (c = 0; c < N; c++) begin : gen_col
                assign ext_res[r][c] = sub ? {mat_a[r][c][DATA_W-1], mat_a[r][c]} - {mat_b[r][c][DATA_W-1], mat_b[r][c]} : {mat_a[r][c][DATA_W-1], mat_a[r][c]} + {mat_b[r][c][DATA_W-1], mat_b[r][c]}; 
                assign mat_c[r][c] = ext_res[r][c][DATA_W-1:0];
            end
        end
    endgenerate
    
    int i, j;
    always_comb begin
        overflow = 1'b0;
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                if (ext_res[i][j][DATA_W] != ext_res[i][j][DATA_W-1]) begin
                    overflow = 1'b1;
                end
            end
        end
    end
endmodule