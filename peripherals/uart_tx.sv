//UART TX peripheral for CPU
//By default has a baud rate of 12207, or a period of 8.19202e-5s = 81920ns

module uart_tx #(parameter WORD_W = 8, OP_W = 3)
    (input logic clock, clock_50M, n_reset, MDR_bus,
    CS, R_NW, load_MAR, load_MDR,
    output logic uart_tx_pin,
    inout wire [WORD_W-1:0] sysbus);

logic [WORD_W-1:0] mdr, piso_in;
logic tx_status, piso_busy, data_ready;
logic [1:0] piso_busy_sync;
logic [WORD_W-OP_W-1:0] mar;


assign sysbus = (MDR_bus && (mar==5'd27)) ? mdr : {WORD_W{1'bZ}};
assign tx_status = data_ready;

piso #(.DIVIDER(4096), .CHAR_W(WORD_W)) uart_piso
    (.uart_tx_pin(uart_tx_pin),
    .clock_50M(clock_50M), .n_reset(n_reset),
    .data_ready(data_ready), .tx_busy(piso_busy),
    .tx_data(piso_in));

always_ff @(posedge clock, negedge n_reset) begin
    if(~n_reset) begin
        mdr <= 0;
        mar <= 0;
        piso_in <= 0;
        piso_busy_sync[1:0] <= 0;
        data_ready <= 0;
    end
    else begin
        piso_busy_sync[1] <= piso_busy;
        piso_busy_sync[0] <= piso_busy_sync[1];
        if ((~piso_busy_sync[0]) & piso_busy_sync[1]) //rising edge
            data_ready <= 0;

        if (load_MAR)
            mar <= sysbus[WORD_W-OP_W-1:0]; 
        else if (load_MDR && (mar == 5'd26)) begin
            piso_in <= sysbus;
            data_ready <= 1;
        end
        else if (CS && R_NW && (mar == 5'd27))
            mdr <= { {(WORD_W-1){1'b0}}, tx_status};  
    end    
end

endmodule