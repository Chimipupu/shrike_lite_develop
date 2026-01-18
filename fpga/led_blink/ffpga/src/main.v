(* top *) module led_bilnk(
    (* iopad_external_pin, clkbuf_inhibit *) input clk, // クロック = 50MHz
    (* iopad_external_pin *) output led,                // LEDピン
    (* iopad_external_pin *) output led_en,             // LEDピンの有効化ピン
    (* iopad_external_pin *) output clk_en              // クロック入力の有効化ピン
    );

    // レジスタ
    reg[31:0] cnt_reg; // (32bit)カウンタ
    reg pin_state_bit; // (1bit)ピン状態ビット

    assign led_en = 1'b1; // LEDを有効化
    assign clk_en = 1'b1; // クロック入力を有効化

    // カウンタ処理
    always @(posedge clk) begin    // クロック立ち上がりで動作
        cnt_reg <= cnt_reg + 1'b1; // カウントアップ

        // NOTE: カウント = 50_000_000 回、周期=1秒
        // NOTE: カウント = 25_000_000 回、周期=500ms
        // NOTE: カウント = 12_500_000 回、周期=250ms
        // NOTE: カウント =  6_250_000 回、周期=125ms
        // NOTE: カウント =  3_125_000 回、周期=62.5ms
        if(cnt_reg == 50_000_000) begin
            cnt_reg <= 32'b0; // カウンタリセット
            pin_state_bit <= !pin_state_bit; // ピン状態反転
        end
    end

    assign led = pin_state_bit; // ピンにピン状態ビットを出力
endmodule