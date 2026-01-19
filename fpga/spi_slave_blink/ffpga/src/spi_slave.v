/**
 * @file spi_slave.v
 * @author Chimi(https://github.com/Chimipupu)
 * @brief SPIスレーブモジュール
 * @note SPIモード0(CPOL=0, CPHA=0)、MSBファースト
 * @version 0.1
 * @date 2026-01-18
 * @copyright Copyright (c) 2026 Chimipupu All Rights Reserved.
 * @license MIT License
*/

module spi_slave(
    // クロック・リセット入力ピン
    input i_clk,              // クロック = 50MHz
    input i_rst_n,            // リセット入力(RSTn = アクティブLOW)

    // SPIスレーブピン
    input i_spi_s_sck,        // SPI SCKピン
    input i_spi_s_cs_n,       // SPI CSnピン(アクティブLOW)
    input i_spi_s_mosi,       // SPI MOSIピン
    output o_spi_s_miso_oe,   // SPI MISOピンのOEピン
    output reg o_spi_s_miso,  // SPI MISOピン

    // LEDピン
    output reg o_led,
    output o_led_en
    );

    // LEDを有効化
    assign o_led_en = 1'b1;

    // ビットカウンタ(RX, TX)
    reg [2:0] r_rx_bit_cnt;
    reg [2:0] r_tx_bit_cnt;

    // 送受信FIFO
    reg r_rx_done;
    reg [7:0] r_rx_data;
    reg [7:0] r_tx_data;
    reg [7:0] r_tx_shift;

    // ----------------------------------------------------------------
    // メタスタビリティ対策用 2段FFシンクロナイザ
    reg [1:0] r_sck_sync;  // SCK同期用2段FF
    reg [1:0] r_cs_sync;   // CSn同期用2段FF
    reg [1:0] r_mosi_sync; // MOSI同期用2段FF
    reg [1:0] r_miso_sync; // MISO同期用2段FF

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_sck_sync  <= 2'b11; // NOTE: SCKの初期値  0b11 ... 0->1で立ち上がりエッジなので0b11にして謝エッジ検出を防止
            r_cs_sync   <= 2'b11; // NOTE: CSnの初期値  0b11 ... CSnがLowでアサートされていない状態
            r_mosi_sync <= 2'b00; // NOTE: MOSIの初期値 0b00 ... リセット時はデータ線はLow
            r_miso_sync <= 2'b00; // NOTE: MISOの初期値 0b00 ... リセット時はデータ線はLow
        end else begin
            r_sck_sync  <= {r_sck_sync[0],  i_spi_s_sck};  // SCK同期
            r_cs_sync   <= {r_cs_sync[0],   i_spi_s_cs_n}; // CSn同期
            r_mosi_sync <= {r_mosi_sync[0], i_spi_s_mosi}; // MOSI同期
            r_miso_sync <= {r_miso_sync[0], o_spi_s_miso}; // MISO同期
        end
    end

    wire w_sck_sync  = r_sck_sync[1];  // SCK同期
    wire w_cs_sync   = r_cs_sync[1];   // CSn同期
    wire w_mosi_sync = r_mosi_sync[1]; // MOSI同期
    wire w_miso_sync = r_miso_sync[1]; // MISO同期

    // SCKエッジ検出(立ち上がり/立ち下がり)
    wire w_sck_posedge = (r_sck_sync[1:0] == 2'b01); // SCK ↑ 立ち上がりエッジ(0 -> 1)
    wire w_sck_negedge = (r_sck_sync[1:0] == 2'b10); // SCK ↓ 立ち下がりエッジ(1 -> 0)

    // MISOピンはCSnがLowでアサートされているときだけ有効
    assign o_spi_s_miso_oe = ~w_cs_sync;
    // ----------------------------------------------------------------
    // SPI受信処理
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_rx_data <= 8'd0;
            r_rx_bit_cnt <= 3'd0;
            r_rx_done <= 1'b0;
        end else begin
            r_rx_done <= 1'b0;

            // CSn = Low のときSPI通信有効
            if (w_cs_sync == 1'b0) begin
                // SCKの立ち上がりエッジのみで動作
                if (w_sck_posedge) begin
                    // シフトイン (MSBファースト)
                    r_rx_data <= {r_rx_data[6:0], w_mosi_sync};
                    // ビットカウントアップ
                    r_rx_bit_cnt <= r_rx_bit_cnt + 1'b1;
                    // 8ビット受信完了判定
                    if (r_rx_bit_cnt == 3'd7) begin
                        r_rx_done <= 1'b1; // 1クロックだけHigh
                    end
                end
            end else begin
                // CSn = Highになったらカウンタをリセット
                r_rx_bit_cnt <= 3'd0;
            end
        end
    end

    // ----------------------------------------------------------------
    // SPI送信処理
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_bit_cnt <= 3'd0;
            o_spi_s_miso <= 1'b0;
        end else begin
            // CSn = Low のときSPI通信有効
            if (w_cs_sync == 1'b0) begin
                // SCKの立ち上がりエッジ && 最初のビット(MSB)
                if (r_tx_bit_cnt == 3'd0 && !w_sck_negedge) begin
                    o_spi_s_miso <= r_tx_data[7]; // MSBをセット
                end

                // SCKの立ち下がりエッジ
                if (w_sck_negedge) begin
                    o_spi_s_miso <= r_tx_data[6];           // 次のビットをセット
                    r_tx_data    <= {r_tx_data[6:0], 1'b0}; // 次のビットへシフト
                    r_tx_bit_cnt <= r_tx_bit_cnt + 1'b1;    // 送信ビットをカウントアップ
                end
            end else begin
                o_spi_s_miso <= 1'b0;    // CSn = HighのときはMISOをLowに
                r_tx_bit_cnt <= 3'd0;    // CSn = Highになったらカウンタをリセット
                r_tx_data <= r_tx_shift; // 送信データをセット
            end
        end
    end

    // ----------------------------------------------------------------
    // 送信データ準備
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_led <= 1'b0;
            r_tx_shift <= 8'd0;
        end else if(r_rx_done) begin
            // 受信データ = 0xAAならLEDをON
            if(r_rx_data == 8'hAA) begin
                o_led <= 1'b1;
                r_tx_shift <= 8'h55;
            // 受信データ = 0x55ならLEDをOFF
            end else if(r_rx_data == 8'h55) begin
                o_led <= 1'b0;
                r_tx_shift <= 8'hAA;
            end else begin
                r_tx_shift <= 8'd0;
            end
        end
    end
    // ----------------------------------------------------------------

endmodule