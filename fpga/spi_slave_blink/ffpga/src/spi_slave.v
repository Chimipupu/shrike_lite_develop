module spi_slave(
    input i_clk,              // クロック = 50MHz
    input i_rst_n,            // リセット入力(RSTn = アクティブLOW)

    input i_spi_s_sck,        // SPI SCKピン
    input i_spi_s_mosi,       // SPI MOSIピン
    input i_spi_s_cs_n,       // SPI CSnピン(アクティブLOW)
    output o_spi_s_miso_oe,   // SPI MISOピンのOEピン
    output reg o_spi_s_miso,  // SPI MISOピン

    output reg o_spi_s_rx_done,
    output reg [7:0] o_spi_s_rx_data
    );

    reg [2:0] r_bit_cnt; // (3bit)受信データカウントレジスタ

    assign o_spi_s_miso_oe = 1'b1; // MISOピンを常に有効化

    always @(posedge i_clk or negedge i_rst_n) begin
        // RST_n = High ならリセット
        if (!i_rst_n) begin
            r_bit_cnt       <= 3'd0;
            o_spi_s_rx_data <= 8'd0;
            o_spi_s_miso    <= 1'b0;
            o_spi_s_rx_done <= 1'b0;
        // CSn = Low のときSPI通信
        end else if (i_spi_s_cs_n == 1'b0) begin
            // SPI SCKの立ち上がりエッジでデータ受信
            if (i_spi_s_sck == 1'b1) begin
                // MOSIの受信データをシフトイン(MSBファースト)
                o_spi_s_rx_data <= {o_spi_s_rx_data[6:0], i_spi_s_mosi};
                r_bit_cnt <= r_bit_cnt + 1'b1;
                // 8ビット受信完了
                if (r_bit_cnt == 3'd7) begin
                    o_spi_s_rx_done <= 1'b1;
                end
            end
        end
    end
endmodule
