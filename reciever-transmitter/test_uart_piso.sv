module test_uart_piso;

logic clock_50M, n_reset, data_ready;
logic [7:0] tx_data;
logic tx_busy, uart_tx_pin;

piso #(.DIVIDER(4096), .CHAR_W(8)) tx (.*);

initial begin
    n_reset = 1;
    #5ns n_reset = 0;
    #5ns n_reset = 1;
end

always begin
#10ns clock_50M = 1'b1;
#10ns clock_50M = 1'b0;
end

initial begin
tx_data = 0;
data_ready = 0;
#10ns tx_data = 8'h1a; // 0b00011010
#10ns data_ready = 1'b1;
#200us data_ready = 1'b0;
#2ms data_ready = 1'b1;
end

endmodule