(* top *) module top(
    // リセット入力(RSTn = アクティブLOW)
    (* iopad_external_pin *) input i_rst_n,
    // クロック入力
    (* iopad_external_pin, clkbuf_inhibit *) input i_clk,
    (* iopad_external_pin *) output o_clk_en,
    // SPIスレーブピン
    (* iopad_external_pin *) input i_spi_s_sck,
    (* iopad_external_pin *) input i_spi_s_mosi,
    (* iopad_external_pin *) input i_spi_s_cs_n,
    (* iopad_external_pin *) output o_spi_s_miso,
    (* iopad_external_pin *) output o_spi_s_miso_oe,
    // LEDピン
    (* iopad_external_pin *) output reg o_led,
    (* iopad_external_pin *) output o_led_en
    );

    wire w_spi_s_rx_done;
    wire [7:0] w_spi_s_rx_data;

    assign o_led_en = 1'b1; // LEDを有効化
    assign o_clk_en = 1'b1; // クロックを有効化

    // SPIの受信したデータ解析
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_led <= 1'b0;
        end else if(w_spi_s_rx_done) begin
            // 受信データ = 0xAAならLEDをON
            if(w_spi_s_rx_data == 8'hAA) begin
                o_led <= 1'b1;
            // 受信データ = 0x55ならLEDをOFF
            end else if(w_spi_s_rx_data == 8'h55) begin
                o_led <= 1'b0;
            end
        end
    end

    // SPIスレーブ
    spi_slave u_spi_slave (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_spi_s_sck(i_spi_s_sck),
        .i_spi_s_mosi(i_spi_s_mosi),
        .i_spi_s_cs_n(i_spi_s_cs_n),
        .o_spi_s_miso(o_spi_s_miso),
        .o_spi_s_miso_oe(o_spi_s_miso_oe),
        .o_spi_s_rx_done(w_spi_s_rx_done),
        .o_spi_s_rx_data(w_spi_s_rx_data)
    );

endmodule
