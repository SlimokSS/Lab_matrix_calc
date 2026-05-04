module axis_rx #(
    parameter N = 4,
    parameter DATA_W = 16
) 
(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [DATA_W-1:0] s_tdata,
    input  logic s_tvalid,
    input  logic s_tlast,
    input  logic flush, // Reset counter

    output logic s_tready,
    output logic signed [DATA_W-1:0] mat [N][N],
    output logic recv_done
);

localparam int TOTAL = N*N;
localparam int CNT_W = $clog2(TOTAL);
logic [CNT_W-1:0] elem_cnt;
logic [$clog2(N)-1:0] row_cnt;
logic [$clog2(N)-1:0] col_cnt;
logic buf_full;
assign s_tready = ~buf_full;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        recv_done <= 1'b0;
        buf_full <= 1'b0;
        elem_cnt <= 0;
        row_cnt <= 0;
        col_cnt <= 0;
    end
    else if (flush) begin
        elem_cnt <= 0;
        row_cnt <= 0;
        col_cnt <= 0;
        recv_done <= 1'b0;
        buf_full <= 1'b0;
    end
    else begin
        if (s_tvalid && s_tready) begin
            if (col_cnt == N - 1) begin
                row_cnt <= row_cnt + 1;
                col_cnt <= 0;
            end else begin
                col_cnt <= col_cnt + 1;
            end
            mat[row_cnt][col_cnt] <= s_tdata;
            elem_cnt <= elem_cnt + 1;
            if ((elem_cnt == TOTAL - 1) && s_tlast) begin
                recv_done <= 1'b1;
                buf_full <= 1'b1;
            end
        end
    end
end
endmodule