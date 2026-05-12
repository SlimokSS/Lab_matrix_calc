module tb_mat_addsub;

    localparam int N      = 4;
    localparam int DATA_W = 16;
    localparam int TESTS   = 100;

    logic sub;
    logic signed [DATA_W-1:0] mat_a [N][N];
    logic signed [DATA_W-1:0] mat_b [N][N];

    logic signed [DATA_W-1:0] mat_c [N][N];
    logic overflow;

    logic signed [DATA_W-1:0] exp_mat [N][N];
    logic exp_overflow;

    int test_idx;
    int i, j;

    mat_addsub #(
        .N(N),
        .DATA_W(DATA_W)
    ) dut (
        .sub(sub),
        .mat_a(mat_a),
        .mat_b(mat_b),
        .mat_c(mat_c),
        .overflow(overflow)
    );

    initial begin
        $display("Started mat_addsub test");

        repeat (TESTS) begin
            do_random_test();
        end

        $display("All mat_addsub tests finished");
        $finish;
    end

    task automatic do_random_test;
        logic signed [DATA_W:0] tmp_res;
        bit local_overflow;

        begin
            sub = $urandom_range(0, 1);

            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    mat_a[i][j] = $signed($urandom());
                    mat_b[i][j] = $signed($urandom());
                end
            end

            #1;

            local_overflow = 1'b0;

            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    if (sub) begin
                        tmp_res = {mat_a[i][j][DATA_W-1], mat_a[i][j]} -
                                  {mat_b[i][j][DATA_W-1], mat_b[i][j]};
                    end else begin
                        tmp_res = {mat_a[i][j][DATA_W-1], mat_a[i][j]} +
                                  {mat_b[i][j][DATA_W-1], mat_b[i][j]};
                    end

                    exp_mat[i][j] = tmp_res[DATA_W-1:0];

                    if (tmp_res[DATA_W] != tmp_res[DATA_W-1]) begin
                        local_overflow = 1'b1;
                    end
                end
            end

            exp_overflow = local_overflow;

            check_result();
        end
    endtask

    task automatic check_result;
        begin
            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    if (mat_c[i][j] !== exp_mat[i][j]) begin
                        $error(
                            "TEST %0d FAILED: sub=%0b, mat_c[%0d][%0d]=%0d, expected=%0d, a=%0d, b=%0d",
                            test_idx, sub, i, j, mat_c[i][j], exp_mat[i][j], mat_a[i][j], mat_b[i][j]
                        );
                    end
                end
            end

            if (overflow !== exp_overflow) begin
                $error(
                    "TEST %0d FAILED: overflow=%0b, expected_overflow=%0b, sub=%0b",
                    test_idx, overflow, exp_overflow, sub
                );
            end

            test_idx++;
        end
    endtask

endmodule