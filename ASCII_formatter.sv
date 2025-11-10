module ascii_hex8_str (
  input  logic [7:0] val,
  input  logic       uppercase,
  output logic [7:0] str [0:2]   // str[0]=hi, str[1]=lo, str[2]=0
);
  logic [7:0] hi, lo;
  ascii_hex8 u(.val(val), .uppercase(uppercase), .ascii_hi(hi), .ascii_lo(lo));

  always_comb begin
    str[0] = hi;
    str[1] = lo;
    str[2] = 8'd0;  // null
  end
endmodule

module ascii_dec8_str (
  input  logic [7:0] val,
  output logic [7:0] str [0:3]   // "XYZ\0"
);
  logic [7:0] d2, d1, d0;
  ascii_dec8 u(.val(val), .ascii_hund(d2), .ascii_tens(d1), .ascii_ones(d0));
  always_comb begin
    str[0] = d2;
    str[1] = d1;
    str[2] = d0;
    str[3] = 8'd0;  // null
  end
endmodule
