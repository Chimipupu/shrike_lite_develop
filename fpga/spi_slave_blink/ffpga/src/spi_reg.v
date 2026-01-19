/**
 * @file spi_reg.v
 * @author Chimi(https://github.com/Chimipupu)
 * @brief SPI レジスタモジュール
 * @note SPIモード0(CPOL=0, CPHA=0)、MSBファースト
 * @version 0.1
 * @date 2026-01-20
 * @copyright Copyright (c) 2026 Chimipupu All Rights Reserved.
 * @license MIT License
*/

module spi_reg(
    input  wire i_clk,
    input  wire i_rst_n,

    // SPI物理インターフェース
    input  wire i_spi_s_sck,
    input  wire i_spi_s_cs_n,
    input  wire i_spi_s_mosi,
    output wire o_spi_s_miso_oe,
    output wire o_spi_s_miso,

    // LEDピン
    output reg o_led,
    output o_led_en
);

    // ----------------------------------------------------------------
    wire       w_rx_done;
    wire [7:0] w_rx_data;
    reg  [7:0] r_tx_data;

    // LED出力イネーブル
    assign o_led_en = 1'b1;

    // ----------------------------------------------------------------
    // SPIスレーブモジュールのインスタンス化
    spi_slave u_spi_slave (
        // SPIの物理信号を接続
        .i_clk           (i_clk),
        .i_rst_n         (i_rst_n),
        .i_spi_s_sck     (i_spi_s_sck),
        .i_spi_s_cs_n    (i_spi_s_cs_n),
        .i_spi_s_mosi    (i_spi_s_mosi),
        .o_spi_s_miso_oe (o_spi_s_miso_oe),
        .o_spi_s_miso    (o_spi_s_miso),

        // 内部接続
        .o_rx_done       (w_rx_done),
        .o_rx_data       (w_rx_data),
        .i_tx_data       (r_tx_data)
    );

    // ----------------------------------------------------------------
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_led     <= 1'b0;
            r_tx_data <= 8'd0;
        end else if(w_rx_done) begin
            if(w_rx_data == 8'hAA) begin
                o_led     <= 1'b1;       // LED点灯
                r_tx_data <= 8'h55;
            end else if(w_rx_data == 8'h55) begin
                o_led     <= 1'b0;       // LED消灯
                r_tx_data <= 8'hAA;
            end else begin
                // 受信データをエコーバック
                r_tx_data <= w_rx_data;
            end
        end
    end

endmodule