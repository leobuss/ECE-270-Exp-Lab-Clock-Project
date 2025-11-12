
`default_nettype none
module uart_tx(
  input  logic clk,
  input  logic reset,
  input  logic ce_bit, // 1 tick per bit
  input  logic [7:0] data_in, // byte to send
  input  logic valid, // strobe when ready=1
  output logic ready, // high in IDLE
  output logic tx, // serial out, idle high
  output logic busy // high when not IDLE
);
  // state
  typedef enum logic[1:0]{IDLE,START,DATA,STOP} st_t;
  st_t st,st_n;

  // data path
  logic[7:0] sh,sh_n; // shift register
  logic[2:0] bitc,bitc_n; // bit counter
  logic tx_n; // next tx line

  // status
  assign ready=(st==IDLE);
  assign busy=(st!=IDLE);

  // next-state and next-data (combinational)
  always_comb begin
    st_n=st;
    sh_n=sh;
    bitc_n=bitc;
    tx_n=tx;

    if(ce_bit) begin
      unique case(st)
        IDLE: begin
          tx_n=1;
          if(valid) begin
            sh_n=data_in;
            tx_n=0; // start bit
            st_n=START;
          end
        end
        START: begin
          st_n=DATA;
          bitc_n=3'd0;
        end
        DATA: begin
          tx_n=sh[0];
          sh_n={1'b0,sh[7:1]};
          if(bitc==3'd7) st_n=STOP;
          else bitc_n=bitc+3'd1;
        end
        STOP: begin
          tx_n=1; // stop bit
          st_n=IDLE;
        end
      endcase
    end
  end

  // registers (sequential)
  always_ff@(posedge clk) begin
    if(reset) begin
      st<=IDLE;
      sh<=8'h00;
      bitc<=3'd0;
      tx<=1;
    end else begin
      st<=st_n;
      sh<=sh_n;
      bitc<=bitc_n;
      tx<=tx_n;
    end
  end
endmodule
