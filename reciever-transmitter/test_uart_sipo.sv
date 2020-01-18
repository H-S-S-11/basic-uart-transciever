module test_uart_sipo;

logic uart_rx_pin, clock_50M, n_reset;
logic [7:0] rx_data;
logic data_ready;

sipo #(.DIVIDER(4096), .CHAR_W(8)) rx (.*);

initial begin
    n_reset = 1;
    #5ns n_reset = 0;
    #5ns n_reset = 1;
end

always begin
#10ns clock_50M = 1'b1;
#10ns clock_50M = 1'b0;
end

always begin
    uart_rx_pin = 1;
    #10000ns uart_rx_pin = 0;
    //send 0b11101011  or 0xeb
    #81920ns uart_rx_pin = 0;
    #81920ns uart_rx_pin = 1;
    #81920ns uart_rx_pin = 0;
    #81920ns uart_rx_pin = 1;
    #81920ns uart_rx_pin = 0;
    #81920ns uart_rx_pin = 1;
    #81920ns uart_rx_pin = 1;
    #81920ns uart_rx_pin = 1;
    //stop
    #81920ns uart_rx_pin = 1;
end



endmodule