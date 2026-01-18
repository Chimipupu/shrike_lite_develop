(* top *) module top(
    // リセット入力(RSTn = アクティブLOW)
    (* iopad_external_pin *) input i_rst_n,
    // クロック入力
    (* iopad_external_pin, clkbuf_inhibit *) input i_clk,
    (* iopad_external_pin *) output o_clk_en,
    // SPIスレーブピン
    (* iopad_external_pin *) input i_spi_s_sck,
    (* iopad_external_pin *) input i_spi_s_cs_n,
    (* iopad_external_pin *) input i_spi_s_mosi,
    (* iopad_external_pin *) output o_spi_s_miso,
    (* iopad_external_pin *) output o_spi_s_miso_oe,
    // LEDピン
    (* iopad_external_pin *) output reg o_led,
    (* iopad_external_pin *) output o_led_en
    );

    assign o_clk_en = 1'b1; // クロックを有効化

    // SPIスレーブ
    spi_slave u_spi_slave (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_spi_s_sck(i_spi_s_sck),
        .i_spi_s_cs_n(i_spi_s_cs_n),
        .i_spi_s_mosi(i_spi_s_mosi),
        .o_spi_s_miso(o_spi_s_miso),
        .o_spi_s_miso_oe(o_spi_s_miso_oe),
        .o_led(o_led),
        .o_led_en(o_led_en)
    );

endmodule