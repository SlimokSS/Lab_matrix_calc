module tb_mat_transpose;

    localparam int N      = 4;
    localparam int DATA_W = 16;
    localparam int TESTS  = 100;

    logic signed [DATA_W-1:0] mat_a [N][N];
    logic signed [DATA_W-1:0] mat_c [N][N];
    logic signed [DATA_W-1:0] exp_mat [N][N];

    int test_idx;
    int i, j;

    mat_transpose #(
        .N(N),
        .DATA_W(DATA_W)
    ) dut (
        .mat_a(mat_a),
        .mat_c(mat_c)
    );

    initial begin
        $display("Started mat_transpose test");

        repeat (TESTS) begin
            do_random_test();
        end

        $display("All mat_transpose tests finished");
        $finish;
    end

    task automatic do_random_test;
        begin
            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    mat_a[i][j] = $signed($urandom());
                end
            end

            #1;

            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    exp_mat[i][j] = mat_a[j][i];
                end
            end

            check_result();
        end
    endtask

    task automatic check_result;
        begin
            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    if (mat_c[i][j] !== exp_mat[i][j]) begin
                        $error(
                            "TEST %0d FAILED: mat_c[%0d][%0d]=%0d, expected=%0d, mat_a[%0d][%0d]=%0d",
                            test_idx, i, j, mat_c[i][j], exp_mat[i][j], j, i, mat_a[j][i]
                        );
                    end
                end
            end

            test_idx++;
        end
    endtask

endmodule