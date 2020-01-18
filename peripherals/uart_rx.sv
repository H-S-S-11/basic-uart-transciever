//UART RX peripheral for CPU
//By default has a baud rate of 12207, or a period of 8.19202e-5s = 81920ns

module uart_rx #(parameter WORD_W = 8, OP_W = 3)
  (input logic clock, clock_50M, n_reset, MDR_bus,
  CS, R_NW, load_MAR, uart_rx_pin,
  inout wire [WORD_W-1:0] sysbus);

logic [WORD_W-1:0] mdr, sipo_out, sipo_out_buffer;
logic rx_status, sipo_ready;
logic [1:0] sipo_ready_sync;
logic [WORD_W-OP_W-1:0] mar;

assign sysbus = (MDR_bus && (mar==5'd28 || mar==5'd29)) ? mdr : {WORD_W{1'bZ}};

//rx status needs to be set high on a rising edge detect of data_ready
//so it can keep track of whether the current char has been read

sipo #(.DIVIDER(4096), .CHAR_W(WORD_W)) uart_sipo 
  (.uart_rx_pin(uart_rx_pin),
  .clock_50M(clock_50M), .n_reset(n_reset),
  .data_ready(sipo_ready), .rx_data(sipo_out));

always_ff @(posedge clock, negedge n_reset)
  begin
  if (~n_reset)
    begin 
    mdr <= 0;
    mar <= 0;
    sipo_out_buffer <= 0;
    rx_status <= 0;
    sipo_ready_sync[1:0] <= 0;
    end
  else
    begin
    sipo_ready_sync[1] <= sipo_ready;
    sipo_ready_sync[0] <= sipo_ready_sync[1];
    if (sipo_ready_sync[1] & (~sipo_ready_sync[0])) //rising edge
    begin
      sipo_out_buffer <= sipo_out;
      rx_status <= 1;
    end

    if (load_MAR)
      mar <= sysbus[WORD_W-OP_W-1:0]; 
    else if (CS && R_NW && (mar==5'd28))
    begin
      mdr <= sipo_out_buffer;
      rx_status <= 0;
    end
    else if (CS && R_NW && (mar==5'd29))
       mdr <= { {(WORD_W-1){1'b0}}, ~rx_status};  //~rx_status makes it easier to do a loop if not ready
    end 
  end

endmodule