module apb_csr (
    input logic clk,
    input logic rst_n,
    
    input logic done_i, // Result ready flag
    input logic busy_i, // Block busy flag
    input logic overflow_i, // Overflow flag
    input logic singular_i, // Singular matrix flag for OP=11

    input logic psel, // APB slave select
    input logic penable, // APB enable phase
    input logic pwrite, // APB direction (1 = write, 0 = read)
    input logic [7:0] paddr, // Register address
    input logic [31:0] pwdata, // Write data

    output logic [31:0] prdata, // Read data

    output logic pready, // Slave ready signal
    output logic pslverr, // APB error signal

    output logic [1:0] op_o, 
    output logic start_pulse_o // One-cycle start pulse
);
    localparam logic [7:0] REG_OP_ADDR = 8'h00; // OP register address
    localparam logic [7:0] REG_CTRL_ADDR = 8'h04; // Control register address
    localparam logic [7:0] REG_STATUS_ADDR = 8'h08; // Status register address

    assign pready = 1'b1; // Always ready
    assign pslverr = 1'b0; // No APB errors
   
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        op_o <= 2'b00;
        start_pulse_o <= 1'b0;
    end else begin
        start_pulse_o <= 1'b0;
        if (psel && penable && pwrite) begin
            if (paddr == REG_OP_ADDR) begin
                op_o <= pwdata[1:0];
            end
            if (paddr == REG_CTRL_ADDR && pwdata[0]) begin
                start_pulse_o <= 1'b1;
            end
        end
    end
end

always_comb begin
    prdata[31:0] = {32{1'b0}};
    if (penable && !pwrite && psel) begin
        if (paddr == REG_OP_ADDR) begin
            prdata[31:0] = {{30{1'b0}}, op_o};
        end else if (paddr == REG_CTRL_ADDR) begin
            prdata[31:0] = {32{1'b0}};
        end else if (paddr == REG_STATUS_ADDR) begin
            prdata[31:0] = {{28{1'b0}}, singular_i, overflow_i, busy_i, done_i};
        end
    end 
end

endmodule