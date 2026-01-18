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
static void fpga_rst_n_pin_ctrl(bool val);
static void fpga_reg_write(uint8_t reg_addr, uint8_t data);
static void fpga_led_ctrl(bool muc_val, bool fpga_val);

#define FPGA_LED_ON_DATA    0xAB
#define FPGA_LED_OFF_DATA   0xFF
static bool fw_led_state = false;
static bool fpga_led_state = false;
// *************************************************************
// [Static関数]
// *************************************************************
static void fpga_rst_n_pin_ctrl(bool val)
{
    // True = RSTn Low: リセット, False = RSTn High: リセット解除
    if(val) {
        digitalWrite(FPGA_RSTn_PIN, LOW);
    } else {
        digitalWrite(FPGA_RSTn_PIN, HIGH);
    }
}

/**
 * @brief FPGA初期化(ビットストリーム書き込み)
 * 
 * @param bitstream_path ビットストリームのパス
 */
static void fpga_init(const char* bitstream_path)
{
    // ビットストリームをSPIで書き込み
    shrike.begin();
    shrike.flash(bitstream_path);

    // FPGAをリセット
    pinMode(FPGA_RSTn_PIN, OUTPUT);
    fpga_rst_n_pin_ctrl(true);
    delay(100);
    fpga_rst_n_pin_ctrl(false);
}

static void fpga_reg_write(uint8_t reg_addr, uint8_t data)
{
    digitalWrite(SPI_CS_PIN, LOW);  // CSアサート
    // SPI.transfer(reg_addr);          // レジスタアドレス送信
    SPI.transfer(data);              // データ送信
    digitalWrite(SPI_CS_PIN, HIGH); // CSデアサート
}

// マイコンとFPGAのLED点滅制御
static void fpga_led_ctrl(bool muc_val, bool fpga_val)
{
    // マイコンLED制御
    digitalWrite(LED_BUILTIN, muc_val ? HIGH : LOW);
    fw_led_state = muc_val;

    // FPGA LED制御
    if(fpga_val) {
        fpga_reg_write(0x00, FPGA_LED_ON_DATA);
    } else {
        fpga_reg_write(0x00, FPGA_LED_OFF_DATA);
    }
    fpga_led_state = fpga_val;
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

    // SPI初期化
#if 0
    SPI.setMISO(SPI_MISO_PIN);
    SPI.setSCK(SPI_SCK_PIN);
    SPI.setMOSI(SPI_MOSI_PIN);
#endif
    pinMode(SPI_CS_PIN, OUTPUT);
    digitalWrite(SPI_CS_PIN, HIGH);
    SPI.begin();

    // シリアル初期化
    Serial.begin(115200);
    while (!Serial && millis() < 3000);
}

void CPU_CORE_0_MAIN()
{
    fpga_led_ctrl(fw_led_state, fpga_led_state);
    fw_led_state = !fw_led_state;
    fpga_led_state = !fw_led_state; // FPGA LEDはマイコンLEDの逆状態
    delay(100);
}

// *************************************************************
// [CPU Core 1]
// *************************************************************

void CPU_CORE_1_INIT()
{
    // NOP
}

void CPU_CORE_1_MAIN()
{
    Serial.printf("MCU LED: %s", fw_led_state ? "ON\r\n" : "OFF\r\n");
    Serial.printf("FPGA LED: %s", fpga_led_state ? "ON\r\n" : "OFF\r\n");
    delay(100);
}