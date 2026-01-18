(* top *) module led_bilnk(
    (* iopad_external_pin, clkbuf_inhibit *) input clk,
    (* iopad_external_pin *) output led,
    (* iopad_external_pin *) output led_en,
    (* iopad_external_pin *) output clk_en
    );

    // レジスタ
    reg[31:0] cnt_reg; // (32bit)カウンタ
    reg pin_state_bit; // (1bit)ピン状態ビット

    assign led_en = 1'b1; // LEDを有効化
    assign clk_en = 1'b1; // クロック入力を有効化

    // カウンタ処理
    always @(posedge clk) begin // クロック立ち上がりで動作
        cnt_reg <= cnt_reg + 1'b1; // カウントアップ
        // カウント = 50,000,000 のとき、ピン状態を反転
        if(cnt_reg == 50_000_000) begin
            cnt_reg <= 32'b0; // カウンタリセット
            pin_state_bit <= !pin_state_bit; // ピン状態反転
        end
    end

    assign led = pin_state_bit; // ピンにピン状態ビットを出力
endmodule