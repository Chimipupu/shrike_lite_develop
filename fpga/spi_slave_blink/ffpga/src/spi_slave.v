module spi_slave(
    input i_clk,              // クロック = 50MHz
    input i_rst_n,            // リセット入力(RSTn = アクティブLOW)

    input i_spi_s_sck,        // SPI SCKピン
    input i_spi_s_cs_n,       // SPI CSnピン(アクティブLOW)

    input i_spi_s_mosi,       // SPI MOSIピン
    output reg o_spi_s_rx_done,
    output reg [7:0] o_spi_s_rx_data,

    output o_spi_s_miso_oe,   // SPI MISOピンのOEピン
    output reg o_spi_s_miso,  // SPI MISOピン
    output reg o_spi_s_tx_done,
    output reg [7:0] o_spi_s_tx_data
    );

    // MISOピンは常に出力有効
    assign o_spi_s_miso_oe = 1'b1;

    // ビットカウンタ(RX, TX)
    reg [2:0] r_rx_bit_cnt;
    reg [2:0] r_tx_bit_cnt;

    // --- シンクロナイザ（外部信号を内部クロックに同期） ---
    reg [1:0] r_sck_sync;
    reg [1:0] r_cs_sync;
    reg [1:0] r_mosi_sync;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_sck_sync  <= 2'b11; // Idle High想定なら0b11, Lowなら0b00
            r_cs_sync   <= 2'b11; // Active Lowなので初期値High
            r_mosi_sync <= 2'b00;
        end else begin
            r_sck_sync  <= {r_sck_sync[0],  i_spi_s_sck};
            r_cs_sync   <= {r_cs_sync[0],   i_spi_s_cs_n};
            r_mosi_sync <= {r_mosi_sync[0], i_spi_s_mosi};
        end
    end

    wire w_sck_sync  = r_sck_sync[1];
    wire w_cs_sync   = r_cs_sync[1];
    wire w_mosi_sync = r_mosi_sync[1];

    wire w_sck_posedge = (r_sck_sync[1:0] == 2'b01);

    // SPI受信処理
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_rx_bit_cnt       <= 3'd0;
            o_spi_s_rx_data <= 8'd0;
            o_spi_s_miso    <= 1'b0;
            o_spi_s_rx_done <= 1'b0;
        end else begin
            o_spi_s_rx_done <= 1'b0;

            // CSn = Low のときSPI通信有効
            if (w_cs_sync == 1'b0) begin
                // SCKの立ち上がりエッジのみで動作
                if (w_sck_posedge) begin
                    // シフトイン (MSBファースト)
                    o_spi_s_rx_data <= {o_spi_s_rx_data[6:0], w_mosi_sync};
                    // ビットカウントアップ
                    r_rx_bit_cnt <= r_rx_bit_cnt + 1'b1;
                    // 8ビット受信完了判定
                    if (r_rx_bit_cnt == 3'd7) begin
                        o_spi_s_rx_done <= 1'b1; // 1クロックだけHighになる
                        // TODO: データのコピーやリセット
                    end
                end
            end else begin
                // CSn = Highになったらカウンタをリセット
                r_rx_bit_cnt <= 3'd0;
            end
        end
    end

    // SPI送信処理
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_bit_cnt <= 3'd0;
            o_spi_s_tx_data <= 8'd0;
            o_spi_s_tx_done <= 1'b0;
            o_spi_s_miso    <= 1'b0;
        end else begin
            o_spi_s_tx_done <= 1'b0;

            // CSn = Low のときSPI通信有効
            if (w_cs_sync == 1'b0) begin
                // SCKの立ち上がりエッジのみで動作
                if (w_sck_posedge) begin
                    // MISOピンにデータをセット (MSBファースト)
                    o_spi_s_miso <= o_spi_s_tx_data[7];

                    // シフトアウト
                    o_spi_s_tx_data <= {o_spi_s_tx_data[6:0], 1'b0};

                    // ビットカウントアップ
                    r_tx_bit_cnt <= r_tx_bit_cnt + 1'b1;

                    // 8ビット送信完了判定
                    if (r_tx_bit_cnt == 3'd7) begin
                        o_spi_s_tx_done <= 1'b1; // 1クロックだけHighになる
                    end
                end
            end else begin
                // CSn = Highになったらカウンタをリセット
                r_tx_bit_cnt <= 3'd0;
            end
        end
    end

endmodule