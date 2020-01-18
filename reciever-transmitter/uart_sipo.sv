//Serial in, parallel out for deserialising UART
//By default has a baud rate of 12207, or a period of 8.19202e-5s = 81920ns

module sipo #(
    parameter DIVIDER = 4096,
    parameter CHAR_W=8,
    parameter COUNTER_W = $clog2(DIVIDER),
    parameter COUNTER_OUTPUT_W = $clog2(CHAR_W)+1
)(
    input logic uart_rx_pin, clock_50M, n_reset,
    output logic [CHAR_W-1:0] rx_data,
    output logic data_ready
);

logic [COUNTER_OUTPUT_W:0] rx_clock;
logic n_counter_reset;
logic not_recieving;
logic start_condition;
logic rx_done;
logic [COUNTER_OUTPUT_W-1:0] pulses_since_reset;
logic prev_start_condition;

assign data_ready = rx_done;

//Probably needs an extra layer of buffer

counternbit_enable
    #(.OUTPUTWIDTH(COUNTER_OUTPUT_W+1), .DIVISIONBITS(COUNTER_W-1)) uart_clock
    (.clk(clock_50M), .n_reset(n_counter_reset),
    .enable(1'b1), .value(rx_clock));

always_comb begin
    n_counter_reset = (n_reset & (~start_condition | ~ prev_start_condition) );
    pulses_since_reset = rx_clock[COUNTER_OUTPUT_W:1];
end

//shift register for rx data
always_ff @(posedge rx_clock[0], negedge n_reset)
begin
    if(~n_reset)
        rx_data <= 0;
    else
    begin
        if (~not_recieving)
        begin
            rx_data = {uart_rx_pin, rx_data[CHAR_W-1:1]};
        end
    end
end

//flip flop for start condition
always_ff @(posedge clock_50M, negedge n_reset ) 
begin
    if (~n_reset)
        start_condition <= 1'b0;
    else 
    begin
        prev_start_condition <= (not_recieving & ~uart_rx_pin);
        if(~prev_start_condition & (not_recieving & ~uart_rx_pin))
            start_condition <= 1'b1;
        else if (start_condition)
            start_condition <= 1'b0;
    end    
end

//flip flop for rx_done, data_ready
always_ff @(posedge rx_clock[0], negedge (n_counter_reset) ) 
begin
    if (~n_counter_reset)
        rx_done <= 1'b0;
    else if ((pulses_since_reset == CHAR_W) & ~not_recieving) begin
        rx_done <= 1'b1;
    end
end

always_ff @(posedge rx_clock[0] or negedge (n_reset & ~start_condition) )
begin
    if (~(n_reset & ~start_condition))
        not_recieving <=1'b0;
    else if (rx_done)
        not_recieving <= 1'b1;
end

endmodule