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
    function [9:0] get_cmd_info(input [7:0] cmd);
        begin
            case (cmd)
                // コマンド            {Valid, LED, TX_DATA}

                // デバッグ用のレジスタ
                8'hAA:get_cmd_info = {1'b1,  1'b1, 8'h55}; // RO, LED点灯, レジスタ値:0x55固定
                8'h55:get_cmd_info = {1'b1,  1'b0, 8'hAA}; // RO, LED消灯, レジスタ値:0xAA固定

                // WHO_AM_Iレジスタ
                8'hF8:get_cmd_info = {1'b1,  1'b0, 8'h8F}; // RO, LED消灯, レジスタ値:0x8F固定

                default: get_cmd_info = {1'b0, 1'b0, 8'h00};
            endcase
        end
    endfunction

    wire [9:0]  w_cmd_lut_tbl; // コマンドのルックアップテーブル
    assign w_cmd_lut_tbl = get_cmd_info(w_rx_data); // テーブル検索

    wire       w_cmd_valid = w_cmd_lut_tbl[9];   // 有効フラグ
    wire       w_cmd_led   = w_cmd_lut_tbl[8];   // LED値
    wire [7:0] w_cmd_tx    = w_cmd_lut_tbl[7:0]; // 送信データ

    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_led     <= 1'b0;
            r_tx_data <= 8'd0;
        end else if(w_rx_done) begin
            if (w_cmd_valid) begin
                o_led     <= w_cmd_led;
                r_tx_data <= w_cmd_tx;
            end else begin
                r_tx_data <= w_rx_data;
            end
        end
    end

endmodule