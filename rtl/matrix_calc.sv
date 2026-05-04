module matrix_calc #(
    parameter N = 4,
    parameter DATA_W = 16
)
(
    input logic clk,
    input logic rst_n,

    input logic psel,
    input logic penable,
    input logic pwrite,
    input logic [7:0] paddr,
    input logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic pready,
    output logic pslverr,

    input logic signed [DATA_W-1:0] s_axis_a_tdata,
    input logic s_axis_a_tvalid,
    input logic s_axis_a_tlast,
    output logic s_axis_a_tready,

    input logic signed [DATA_W-1:0] s_axis_b_tdata,
    input logic s_axis_b_tvalid,
    input logic s_axis_b_tlast,
    output logic s_axis_b_tready,
    
    output logic signed [DATA_W-1:0] m_axis_res_tdata,
    output logic m_axis_res_tvalid,
    output logic m_axis_res_tlast,
    input logic m_axis_res_tready
);

logic [1:0] op;
logic start;

logic signed [DATA_W-1:0] mat_a [N][N];
logic signed [DATA_W-1:0] mat_b [N][N];
logic signed [DATA_W-1:0] mat_addsub_res [N][N];
logic signed [DATA_W-1:0] mat_transpose_res [N][N];
logic signed [DATA_W-1:0] res_mat [N][N];

logic a_recv_done;
logic b_recv_done;
logic done;
logic busy;
logic overflow;
logic singular;
logic overflow_addsub;
logic send_res;
logic rx_flush;
logic tx_done;

apb_csr u_apb_csr (
    .clk(clk),
    .rst_n(rst_n),

    .done_i(done),
    .busy_i(busy),
    .overflow_i(overflow),
    .singular_i(singular),

    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),

    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr),

    .op_o(op),
    .start_pulse_o(start)
);

axis_rx #(
    .N(N),
    .DATA_W(DATA_W)
)
u_axis_rx_a (
    .clk(clk),
    .rst_n(rst_n),
    .s_tdata(s_axis_a_tdata),
    .s_tvalid(s_axis_a_tvalid),
    .s_tlast(s_axis_a_tlast),
    .flush(rx_flush),
    .s_tready(s_axis_a_tready),
    .mat(mat_a),
    .recv_done(a_recv_done)
);

axis_rx #(
    .N(N),
    .DATA_W(DATA_W)
)
u_axis_rx_b (
    .clk(clk),
    .rst_n(rst_n),
    .s_tdata(s_axis_b_tdata),
    .s_tvalid(s_axis_b_tvalid),
    .s_tlast(s_axis_b_tlast),
    .flush(rx_flush),
    .s_tready(s_axis_b_tready),
    .mat(mat_b),
    .recv_done(b_recv_done)
);

mat_addsub #(
    .N(N),
    .DATA_W(DATA_W)
)
u_mat_addsub (
    .sub(op[0]),
    .mat_a(mat_a),
    .mat_b(mat_b),
    .mat_c(mat_addsub_res),
    .overflow(overflow_addsub)
);

mat_transpose #(
    .N(N),
    .DATA_W(DATA_W)
)
u_mat_transpose (
    .mat_a(mat_a),
    .mat_c(mat_transpose_res)
);

axis_tx #(
    .N(N),
    .DATA_W(DATA_W)
)
u_axis_tx (
    .clk(clk),
    .rst_n(rst_n),
    .send(send_res),
    .is_scalar(1'b0),
    .mat_in(res_mat),
    .scalar_in({DATA_W{1'b0}}),
    .m_tready(m_axis_res_tready),
    .m_tdata(m_axis_res_tdata),
    .m_tvalid(m_axis_res_tvalid),
    .m_tlast(m_axis_res_tlast),
    .tx_done(tx_done)
);

int i, j;

always_comb begin
    if(op == 2'b10) begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                res_mat[i][j] = mat_transpose_res[i][j];
            end
        end
    end else if (op == 2'b00 || op == 2'b01) begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                res_mat[i][j] = mat_addsub_res[i][j];
            end
        end
    end else begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                res_mat[i][j] = {DATA_W{1'b0}};
            end
        end
    end
end

typedef enum logic [1:0] {
    IDLE,
    RECV,
    SEND,
    DONE
} state_t;
state_t state, state_n;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= state_n;
    end
end

always_comb begin
    state_n = state;
    case (state)
        IDLE: begin
            if (start) begin
                state_n = RECV;
            end
        end
        RECV: begin
            if(op == 2'b10 && a_recv_done) begin
                state_n = SEND;
            end else if((op == 2'b00 || op == 2'b01) && (a_recv_done && b_recv_done)) begin
                state_n = SEND;
            end
        end
        SEND: begin
            if (tx_done) begin
                state_n = DONE;
            end
        end 
        DONE: begin
            if (start) begin
                state_n = RECV;
            end 
        end
    endcase
end

always_comb begin 
    busy = 1'b0;
    done = 1'b0;
    rx_flush = 1'b0;
    send_res = 1'b0;
    if (op == 2'b00 || op == 2'b01) begin
        overflow = overflow_addsub;
    end else begin
        overflow = 1'b0;
    end
    singular = 1'b0;
    case (state) 
    RECV: begin
        busy = 1'b1;
    end
    SEND: begin
        busy = 1'b1;
    end
    DONE: begin
        done = 1'b1;
    end
    endcase
    if ((state == IDLE && state_n == RECV) || (state == DONE && state_n == RECV)) begin
        rx_flush = 1'b1;
    end 
    if (state == RECV && state_n == SEND) begin
        send_res = 1'b1;
    end
end
endmodule
