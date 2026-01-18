module led_blink(
    input clk,     // クロック = 50MHz
    output led,    // LEDピン
    output led_en, // LEDピンの有効化ピン
    output clk_en, // クロック入力の有効化ピン

    // SPIスレーブからの書き換え信号線とデータ
    input o_spi_s_rx_done,
    input [7:0] r_spi_s_rx_data
    );

    // レジスタ
    reg [31:0] cnt_reg;    // (32bit)カウンタ
    reg [31:0] cnt_up_reg; // (32bit)カウンタアップ値レジスタ
    reg pin_state_bit;     // (1bit)ピン状態ビット

    assign led_en = 1'b1; // LEDを有効化
    assign clk_en = 1'b1; // クロック入力を有効化

    // カウンタ処理
    always @(posedge clk) begin    // クロック立ち上がりで動作
        cnt_reg <= cnt_reg + 1'b1; // カウントアップ

        // SPIで外部から書き換えられる
        if (o_spi_s_rx_done) begin
            cnt_up_reg <= {r_spi_s_rx_data, 24'd0};
            if(cnt_reg == cnt_up_reg) begin
                cnt_reg <= 32'b0; // カウンタリセット
                pin_state_bit <= ~pin_state_bit; // ピン状態反転
            end
        end else if(cnt_reg == 50_000_000) begin
            cnt_reg <= 32'b0; // カウンタリセット
            pin_state_bit <= ~pin_state_bit; // ピン状態反転
        end
    end

    assign led = pin_state_bit; // LEDピンにピン状態ビットを出力
endmodule