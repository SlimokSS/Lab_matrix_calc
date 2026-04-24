module tb_apb_csr;

   logic clk;
   logic rst_n;
   logic psel;
   logic penable;
   logic pwrite;
   logic [7:0] paddr;
   logic [31:0] pwdata;
   logic done_i;
   logic busy_i;
   logic overflow_i;
   logic singular_i;

   logic [31:0] prdata;
   logic pready; 
   logic pslverr;
   logic [1:0] op_o;
   logic start_pulse_o;

apb_csr dut (
    .clk(clk),
    .rst_n(rst_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .done_i(done_i),
    .busy_i(busy_i),
    .overflow_i(overflow_i),
    .singular_i(singular_i),
    .op_o(op_o),
    .start_pulse_o(start_pulse_o),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
);

initial clk = 1'b0;

always begin
    #5;
    clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    psel = 1'b0;
    penable = 1'b0;
    pwrite = 1'b0;
    paddr = 8'b0;
    pwdata = 32'b0;
    done_i = 1'b0;
    busy_i = 1'b0;
    overflow_i = 1'b0;
    singular_i = 1'b0;
    #7;
    rst_n = 1'b1;
    #7;

    paddr = 8'h00;
    pwdata = {{30{1'b0}}, {1'b1}, {1'b0}};
    psel = 1'b1;
    penable = 1'b1;
    pwrite = 1'b1;
    #7;
    psel = 1'b0;
    penable = 1'b0;
    pwrite = 1'b0;
    #7;
    if (op_o == 2'b10) begin // Check OP write
        $display("REG_OP write passed");
    end else begin
        $display("REG_OP write failed");
    end

    paddr = 8'h00;
    psel = 1'b1;
    penable = 1'b1;
    pwrite = 1'b0;
    #7;
    if (prdata[1:0] == 2'b10) begin // Check OP read
        $display("REG_OP read passed");
    end else begin
        $display("REG_OP read failed");
    end
    psel = 1'b0;
    penable = 1'b0;
    pwrite = 1'b0;
    #7;
    
    paddr = 8'h04;
    psel = 1'b1;
    penable = 1'b1;
    pwrite = 1'b1;
    pwdata = {{31{1'b0}}, {1'b1}};
    #7;
    if (start_pulse_o == 1'b1) begin // Check start_pulse_o assertion
        $display("REG_CTRL on passed");
    end else begin
        $display("REG_CTRL on failed");
    end

    psel = 1'b0;
    penable = 1'b0;
    pwrite = 1'b0;
    pwdata = {32{1'b0}};
    #7;
    if (start_pulse_o == 1'b0) begin // Check start_pulse_o deassertion
        $display("REG_CTRL off passed");
    end else begin
        $display("REG_CTRL off failed");
    end

    paddr = 8'h08;
    done_i = 1'b1;
    busy_i = 1'b0;
    overflow_i = 1'b1;
    singular_i = 1'b0;
    psel = 1'b1;
    penable = 1'b1;
    pwrite = 1'b0;
    #7;
    if (prdata[3:0] == 4'b0101) begin // Check status flags
        $display("REG_STATUS read passed");
    end else begin
        $display("REG_STATUS read failed");
    end

    psel = 1'b0;
    penable = 1'b0;
    #7;
    $finish;
end

endmodule