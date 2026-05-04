module axis_tx #(
    parameter N = 4,
    parameter DATA_W = 16
)
(
    input logic clk,
    input logic rst_n,
    input logic send,
    input logic is_scalar,
    input logic signed [DATA_W - 1:0] mat_in [N][N],
    input logic signed [DATA_W - 1:0] scalar_in,
    input logic m_tready,

    output logic signed [DATA_W - 1:0] m_tdata,
    output logic m_tvalid,
    output logic m_tlast,
    output logic tx_done
);

localparam int TOTAL = N*N;
localparam int CNT_W = $clog2(TOTAL);
logic [CNT_W - 1:0] elem_cnt;

logic [$clog2(N) - 1:0] row_idx;
logic [$clog2(N) - 1:0] col_idx;

assign row_idx = elem_cnt / N;
assign col_idx = elem_cnt % N;

typedef enum logic [0:0] {
    IDLE,
    SEND
} state_t;
state_t state, state_n;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        elem_cnt <= 0;
    end else begin
        state <= state_n;
        if (state == IDLE) begin
            elem_cnt <= 0;
        end else if (state == SEND) begin
            if (m_tvalid && m_tready) begin
                if (!is_scalar) begin
                    if (elem_cnt == TOTAL - 1) begin
                        elem_cnt <= 0;
                    end else begin
                        elem_cnt <= elem_cnt + 1;
                    end
                end else begin
                    elem_cnt <= 0;
                end
            end
        end
    end
end

always_comb begin
    state_n = state;
    case (state) 
        IDLE: begin
            if (send) begin
                state_n = SEND;
            end 
        end
        SEND: begin
            if (!is_scalar) begin 
                if(m_tvalid && m_tready && elem_cnt == TOTAL - 1) begin
                    state_n = IDLE;
                end 
            end else begin
                    if(m_tvalid && m_tready) begin
                        state_n = IDLE;
                    end
            end
        end
    endcase
end

always_comb begin
    m_tdata = {DATA_W{1'b0}};
    m_tvalid = 1'b0;
    m_tlast = 1'b0;
    tx_done = 1'b0;
    if (state == SEND) begin
        m_tvalid = 1'b1;
        if (is_scalar) begin
            m_tdata = scalar_in;
            m_tlast = 1'b1;
            if (m_tvalid && m_tready) begin
                tx_done = 1'b1;
            end
        end else begin
            m_tlast = (elem_cnt == TOTAL - 1);
            m_tdata = mat_in[row_idx][col_idx];
            if (m_tvalid && m_tready && m_tlast) begin
                tx_done = 1'b1;
            end
        end
    end
end
endmodule