// 16x oversampling
`default_nettype none
module uart_rx_16x(
  input  logic clk,
  input  logic reset,
  input  logic ce_16x, // 16 ticks per bit
  input  logic rx_in, // raw serial in, idle high
  output logic [7:0] data_out, // recovered byte
  output logic valid, // 1-cycle pulse
  output logic framing_err // 1-cycle pulse if bad stop
);
  // sync rx
  logic rx_meta,rx_sync;
  always_ff@(posedge clk) begin
    rx_meta<=rx_in;
    rx_sync<=rx_meta;
  end

  // state
  typedef enum logic[1:0]{R_IDLE,R_START,R_DATA,R_STOP} st_t;
  st_t st,st_n;

  // datapath
  logic[3:0] os, os_n; // oversample countdown
  logic[2:0] bitc, bitc_n; // bit counter
  logic[7:0] sh, sh_n; // shift register

  // outputs (registered)
  logic[7:0] data_out_n;
  logic valid_n;
  logic framing_err_n;

  // next-state and next-data (combinational)
  always_comb begin
    st_n=st;
    os_n=os;
    bitc_n=bitc;
    sh_n=sh;
    data_out_n=data_out;
    valid_n=0;
    framing_err_n=0;

    if(ce_16x) begin
      unique case(st)
        R_IDLE: begin
          if(rx_sync==0) begin
            st_n=R_START;
            os_n=4'd7; // to center of start bit
          end
        end
        R_START: begin
          if(os==0) begin
            if(rx_sync==0) begin
              st_n=R_DATA;
              os_n=4'd15;
              bitc_n=3'd0;
            end else begin
              st_n=R_IDLE; // false start
            end
          end else os_n=os-4'd1;
        end
        R_DATA: begin
          if(os==0) begin
            sh_n={rx_sync,sh[7:1]}; // sample at center
            os_n=4'd15;
            if(bitc==3'd7) st_n=R_STOP;
            else bitc_n=bitc+3'd1;
          end else os_n=os-4'd1;
        end
        R_STOP: begin
          if(os==0) begin
            data_out_n=sh;
            valid_n=1;
            framing_err_n=(rx_sync==0);
            st_n=R_IDLE;
          end else os_n=os-4'd1;
        end
      endcase
    end
  end

  // registers (sequential)
  always_ff@(posedge clk) begin
    if(reset) begin
      st<=R_IDLE;
      os<=4'd0;
      bitc<=3'd0;
      sh<=8'h00;
      data_out<=8'h00;
      valid<=0;
      framing_err<=0;
    end else begin
      st<=st_n;
      os<=os_n;
      bitc<=bitc_n;
      sh<=sh_n;
      data_out<=data_out_n;
      valid<=valid_n;
      framing_err<=framing_err_n;
    end
  end
endmodule
