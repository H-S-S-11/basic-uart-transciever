//Parallel in, Serial out for serialising UART
//By default has a baud rate of 12207, or a period of 8.19202e-5s = 81920ns

module piso #(
    parameter DIVIDER = 4096,
    parameter CHAR_W=8,
    parameter DIVISIONBITS = $clog2(DIVIDER)-1,
    parameter COUNTER_W = $clog2(CHAR_W)+1
)(
    input logic clock_50M, n_reset, data_ready,
    input logic [CHAR_W-1:0] tx_data,
    output logic tx_busy, uart_tx_pin
);

logic tx_clock;
logic [CHAR_W-1:0] tx_shift_reg;
logic busy;
logic [1:0] data_ready_sync;
logic [COUNTER_W-1:0] pulses_since_reset;

counternbit_enable
    #(.OUTPUTWIDTH(1), .DIVISIONBITS(DIVISIONBITS)) uart_clock
    (.clk(clock_50M), .n_reset(n_reset),
    .enable(1'b1), .value(tx_clock));

always_comb begin
    tx_busy = busy;
end

always_ff @(posedge tx_clock, negedge n_reset)
begin
    if (~n_reset) begin
        data_ready_sync[1:0] <= 0;
        busy <= 0;
        tx_shift_reg <= 0;
        uart_tx_pin <= 1;
        pulses_since_reset <= 0;
    end
    else begin
        data_ready_sync[1] <= data_ready;
        data_ready_sync[0] <= data_ready_sync[1];
        if (data_ready_sync[0] & ~busy)
        begin
            busy <= 1;
            tx_shift_reg <= tx_data;
            pulses_since_reset <= 0;
        end
        else begin
            if (busy) begin
                if (pulses_since_reset == 0)
                    uart_tx_pin <= 0; //start condition
                else if (pulses_since_reset == CHAR_W+1) begin
                    uart_tx_pin <= 1; //stop condition
                    busy <= 0;
                end else if (pulses_since_reset <= CHAR_W) begin
                    uart_tx_pin <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b0, tx_shift_reg[CHAR_W-1:1]};
                end
                pulses_since_reset <= pulses_since_reset + 1;
            end
        end
    end
end
    
endmodule