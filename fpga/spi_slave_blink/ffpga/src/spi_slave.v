module spi_slave(
    input i_spi_s_sck,        // SPI SCKピン
    input i_spi_s_mosi,       // SPI MOSIピン
    input i_spi_s_cs_n,       // SPI CSnピン(アクティブLOW)
    output o_spi_s_miso_oe,   // SPI MISOピンのOEピン
    output reg o_spi_s_miso,  // SPI MISOピン
    output reg o_spi_s_rx_done,
    output reg [7:0] r_spi_s_rx_data
    );

    reg [7:0] r_shift;   // (8bit)シフトレジスタ
    reg [2:0] r_bit_cnt; // (3bit)受信データカウントレジスタ

    assign o_spi_s_miso_oe = ~i_spi_s_cs_n;

    always @(posedge i_spi_s_sck or posedge i_spi_s_cs_n) begin
        // CS_n = High ならリセット
        if (i_spi_s_cs_n) begin
            r_bit_cnt       <= 3'd0;    // 8'd0 -> 3'd0 に修正
            r_shift         <= 8'd0;
            o_spi_s_miso    <= 1'b0;
            o_spi_s_rx_done <= 1'b0;    // これもリセットが必要
        end
        // CS_n が Low なら SCK に合わせて動作
        else begin
            r_bit_cnt <= r_bit_cnt + 1'b1;
            r_shift   <= {r_shift[6:0], i_spi_s_mosi};
            // 8bit受信完了判定
            if (r_bit_cnt == 3'd7) begin
                r_bit_cnt       <= 3'd0; // カウントリセット
                o_spi_s_rx_done <= 1'b1; // 受信完了フラグセット
                // 受信データを格納
                r_spi_s_rx_data <= {r_shift[6:0], i_spi_s_mosi};
            end else begin
                o_spi_s_rx_done <= 1'b0;
            end
        end
    end

endmodule
