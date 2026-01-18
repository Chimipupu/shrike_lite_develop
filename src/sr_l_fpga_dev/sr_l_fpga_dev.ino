/**
 * @file sr_l_fpga_dev.ino
 * @author Chimi(https://github.com/Chimipupu)
 * @brief Shrike-lite用 RP2040側のF/W
 * @version 0.1
 * @date 2026-10-18
 * 
 * @copyright Copyright (c) 2026 Chimipupu All Rights Reserved.
 * 
 */
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#define CPU_CORE_0_INIT    setup
#define CPU_CORE_0_MAIN    loop
#define CPU_CORE_1_INIT    setup1
#define CPU_CORE_1_MAIN    loop1

#include <SPI.h>
#define SPI_MISO_PIN       0
#define SPI_CS_PIN         1
#define SPI_SCK_PIN        2
#define SPI_MOSI_PIN       3

#define FPGA_RSTn_PIN      14 // FPGAリセットピン(Lowアクティブ)
// *************************************************************
// [FPGA関連設定]
#include "Shrike.h"
ShrikeFlash shrike;
#define FPGA_BITSTREAM_PATH    "/FPGA_bitstream_MCU.bin"
static void fpga_init(const char* bitstream_path);
static void fpga_reset(void);
static void fpga_reg_write(uint8_t reg_addr, uint8_t data);

// *************************************************************
// [Static関数]
// *************************************************************
static void fpga_reset(void)
{
    digitalWrite(FPGA_RSTn_PIN, LOW);
}

/**
 * @brief FPGA初期化(ビットストリーム書き込み)
 * 
 * @param bitstream_path ビットストリームのパス
 */
static void fpga_init(const char* bitstream_path)
{
    pinMode(FPGA_RSTn_PIN, OUTPUT);

    // ビットストリームをSPIで書き込み
    shrike.begin();
    shrike.flash(bitstream_path);

    // TODO: FPGAの初期化完了確認
}

static void fpga_reg_write(uint8_t reg_addr, uint8_t data)
{
    digitalWrite(SPI_CS_PIN, LOW);  // CSアサート
    // SPI.transfer(reg_addr);          // レジスタアドレス送信
    SPI.transfer(data);              // データ送信
    digitalWrite(SPI_CS_PIN, HIGH); // CSデアサート
}
// *************************************************************
// [CPU Core 0]
// *************************************************************

void CPU_CORE_0_INIT()
{
    // FPGA初期化
    fpga_init(FPGA_BITSTREAM_PATH);

    // GPIO初期化
    pinMode(LED_BUILTIN, OUTPUT);

    // シリアル初期化
    Serial.begin(115200);
    while (!Serial && millis() < 3000);
}

void CPU_CORE_0_MAIN()
{
    // LED点滅
    static bool led_state = false;
    led_state = !led_state;
    digitalWrite(LED_BUILTIN, led_state ? HIGH : LOW);
    if(led_state) {
        Serial.println("[RP2040] LED: ON");
    } else {
        Serial.println("[RP2040] LED: OFF");
    }
    delay(1000);
}

// *************************************************************
// [CPU Core 1]
// *************************************************************

void CPU_CORE_1_INIT()
{
    // SPI初期化
    SPI.setMISO(SPI_MISO_PIN);
    SPI.setSCK(SPI_SCK_PIN);
    SPI.setMOSI(SPI_MOSI_PIN);
    digitalWrite(SPI_CS_PIN, HIGH);
    SPI.begin();
}

void CPU_CORE_1_MAIN()
{
    static uint8_t s_cnt = 0;
    fpga_reg_write(0x00, s_cnt);
    s_cnt = (s_cnt + 1) % 0xFF;
    delay(100);
}