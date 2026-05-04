module tb_mat_addsub;

    localparam N = 2;
    localparam DATA_W = 4;

    logic sub;
    logic signed [DATA_W-1:0] mat_a [N][N];
    logic signed [DATA_W-1:0] mat_b [N][N];
    logic signed [DATA_W-1:0] mat_c [N][N];
    logic signed [DATA_W-1:0] exp_mat [N][N];
    logic overflow;

mat_addsub #(
    .N(N),
    .DATA_W(DATA_W)
)
    dut(
    .sub(sub),
    .mat_a(mat_a),
    .mat_b(mat_b),
    .mat_c(mat_c),
    .overflow(overflow)
);

task automatic check_result(

    input string test_addsub,
    input logic signed [DATA_W-1:0] exp_mat [N][N],
    input logic exp_overflow

);
int i,j;
bit error_flag;

error_flag = 1'b0;
for (i = 0; i < N; i++) begin
    for (j = 0; j < N; j++) begin
        if (mat_c[i][j] != exp_mat[i][j]) begin
            error_flag = 1'b1;
        end
    end
end
if (overflow != exp_overflow) begin
    error_flag = 1'b1;
end

if (error_flag) begin
    $display("%s FAIL", test_addsub);
end else begin
    $display("%s PASS", test_addsub);
end

endtask

initial begin

    mat_a[0][0] = 3;
    mat_a[0][1] = -1;
    mat_a[1][0] = 2;
    mat_a[1][1] = -4;

    mat_b[0][0] = 2;
    mat_b[0][1] = 6;
    mat_b[1][0] = -1;
    mat_b[1][1] = 7;

    exp_mat[0][0] = 5;
    exp_mat[0][1] = 5;
    exp_mat[1][0] = 1;
    exp_mat[1][1] = 3;

    sub = 1'b0;

    #1;
    
    check_result("add_no_overflow", exp_mat, 1'b0);

    #1;

    mat_a[0][0] = 7;
    mat_a[0][1] = -3;
    mat_a[1][0] = 5;
    mat_a[1][1] = 2;

    mat_b[0][0] = 5;
    mat_b[0][1] = 3;
    mat_b[1][0] = -1;
    mat_b[1][1] = -2;

    exp_mat[0][0] = 2;
    exp_mat[0][1] = -6;
    exp_mat[1][0] = 6;
    exp_mat[1][1] = 4;

    sub = 1'b1;

    #1;
    
    check_result("minus_no_overflow", exp_mat, 1'b0);

    #1;

    mat_a[0][0] = 7;
    mat_a[0][1] = 5;
    mat_a[1][0] = 6;
    mat_a[1][1] = 3;

    mat_b[0][0] = -2;
    mat_b[0][1] = -4;
    mat_b[1][0] = -5;
    mat_b[1][1] = -8;

    exp_mat[0][0] = -7;
    exp_mat[0][1] = -7;
    exp_mat[1][0] = -5;
    exp_mat[1][1] = -5;

    sub = 1'b1;

    #1;
    
    check_result("minus_with_overflow", exp_mat, 1'b1);

    #1;

    $finish;
end

endmodule