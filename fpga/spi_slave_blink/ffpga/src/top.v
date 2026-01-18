(* top *) module top(
    // クロック入力
    (* iopad_external_pin, clkbuf_inhibit *) input clk,
    (* iopad_external_pin *) output clk_en,
    // SPIスレーブピン
    (* iopad_external_pin *) input i_spi_s_sck,
    (* iopad_external_pin *) input i_spi_s_mosi,
    (* iopad_external_pin *) input i_spi_s_cs_n,
    (* iopad_external_pin *) output o_spi_s_miso,
    (* iopad_external_pin *) output o_spi_s_miso_oe,
    // LEDピン
    (* iopad_external_pin *) output led,
    (* iopad_external_pin *) output led_en
    );

    wire o_spi_s_rx_done;
    wire [7:0] r_spi_s_rx_data;

    // SPIスレーブ
    spi_slave u_spi_slave (
        .i_spi_s_sck(i_spi_s_sck),
        .i_spi_s_mosi(i_spi_s_mosi),
        .i_spi_s_cs_n(i_spi_s_cs_n),
        .o_spi_s_miso(o_spi_s_miso),
        .o_spi_s_miso_oe(o_spi_s_miso_oe),
        .o_spi_s_rx_done(o_spi_s_rx_done),
        .r_spi_s_rx_data(r_spi_s_rx_data)
    );

    // Lチカ回路
    led_blink u_led_blink (
        .clk(clk),
        .led(led),
        .led_en(led_en),
        .clk_en(clk_en),
        .o_spi_s_rx_done(o_spi_s_rx_done),
        .r_spi_s_rx_data(r_spi_s_rx_data)
    );

endmodule
