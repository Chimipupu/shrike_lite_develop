/**
 * @file sr_l_fpga_dev.ino
 * @author Chimi(https://github.com/Chimipupu)
 * @brief Shrike-lite用 RP2040側のF/W
 * @version 0.1
 * @date 2026-01-18
 * @copyright Copyright (c) 2026 Chimipupu All Rights Reserved.
 * @license MIT License
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

// *************************************************************
// [CPU コア関連、マルチコア関連]
#define CPU_CORE_0_INIT    setup
#define CPU_CORE_0_MAIN    loop
#define CPU_CORE_1_INIT    setup1
#define CPU_CORE_1_MAIN    loop1

#define MAIN_DELAY_MS      1000

// *************************************************************
// [FPGA関連]
#include "Shrike.h"
#define FPGA_BITSTREAM_PATH    "/FPGA_bitstream_MCU.bin"
#define FPGA_RSTn_PIN          14 // FPGAリセットピン(Lowアクティブ)

#define FPGA_LED_ON_DATA       0xAA
#define FPGA_LED_OFF_DATA      0x55
#define FPGA_WHO_AM_I_REG      0xF8
#define FPGA_WHO_AM_I_REG_VAL  0x8F

ShrikeFlash shrike;
static bool s_fw_led_state = false;
static bool s_fpga_led_state = false;
static bool s_led_state_print_req = false;
// static uint8_t s_fpga_rx_data = 0;
static uint8_t s_fpga_dbg_reg = 0;
static uint8_t s_fpga_who_am_i_reg = 0;

static void fpga_init(const char* bitstream_path);
static void fpga_rst_n_pin_ctrl(bool val);
static void fpga_reg_write(uint8_t reg_addr, uint8_t data);
static void fpga_led_ctrl(bool val);

// (DEBUG) FPGAテスト関連
// #define DEBUG_FPGA_TEST

#ifdef DEBUG_FPGA_TEST
#define FPGA_SPI_SCK_TEST_CNT       1000000
#define FPGA_TEST_RET_EXEC          0x00
#define FPGA_TEST_RET_OK            0x01
#define FPGA_TEST_RET_ERR           0xFF
static uint8_t fpga_spi_test(void);
#endif // DEBUG_FPGA_TEST
// *************************************************************
// [SPI関連]
#include <SPI.h>
#define SPI_MISO_PIN       0
#define SPI_CS_PIN         1
#define SPI_SCK_PIN        2
#define SPI_MOSI_PIN       3

// NOTE: FPGA側(OSC=50MHz)のSPIスレーブのSCKは 10MHz が限界？
#define SPI_SCK_5MHZ       5000000
#define SPI_SCK_10MHZ      10000000
#define SPI_SCK_11MHZ      11000000
#define SPI_SCK_12MHZ      12000000
#define SPI_SCK_13MHZ      13000000
// #define SPI_SCK_12_5MHZ    12500000
// #define SPI_SCK_15MHZ      15000000
// #define SPI_SCK_20MHZ      20000000
// #define SPI_SCK_25MHZ      25000000
// #define SPI_SCK_30MHZ      30000000
// #define SPI_SCK_40MHZ      40000000
// #define SPI_SCK_50MHZ      50000000

#define SPI_SCK_VAL           SPI_SCK_10MHZ
SPISettings g_spi_setting(SPI_SCK_VAL, MSBFIRST, SPI_MODE0);

// *************************************************************
volatile bool s_is_fpga_err = false;

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
    delay(500); // 書き込み完了待ち

    // FPGAをリセット
    pinMode(FPGA_RSTn_PIN, OUTPUT);
    fpga_rst_n_pin_ctrl(true);
    delay(100);
    fpga_rst_n_pin_ctrl(false);
}

static void fpga_reg_write(uint8_t reg_addr, uint8_t data)
{
    SPI.beginTransaction(g_spi_setting);
    digitalWrite(SPI_CS_PIN, LOW);  // CSアサート
    // SPI.transfer(reg_addr);          // TODO: レジスタアドレス送信
    SPI.transfer(data); // データ送信
    digitalWrite(SPI_CS_PIN, HIGH); // CSデアサート
    SPI.endTransaction();
}

static void fpga_reg_read(uint8_t reg_addr, uint8_t *p_data)
{
    // コマンド送信
    fpga_reg_write(0x00, reg_addr);

    SPI.beginTransaction(g_spi_setting);
    digitalWrite(SPI_CS_PIN, LOW);  // CSアサート
    *p_data = SPI.transfer(0x00);   // ダミーを送って受信
    digitalWrite(SPI_CS_PIN, HIGH); // CSデアサート
    SPI.endTransaction();
}

// FPGAのLED点滅制御
static void fpga_led_ctrl(bool val)
{
    if(val) {
        fpga_reg_write(0x00, FPGA_LED_ON_DATA);
        fpga_reg_read(FPGA_LED_ON_DATA, &s_fpga_dbg_reg);
    } else {
        fpga_reg_write(0x00, FPGA_LED_OFF_DATA);
        fpga_reg_read(FPGA_LED_OFF_DATA, &s_fpga_dbg_reg);
    }
}

#ifdef DEBUG_FPGA_TEST
static uint8_t fpga_spi_test(void)
{
    volatile uint8_t ret = FPGA_TEST_RET_EXEC;
    volatile uint8_t tmp = 0;
    static uint32_t s_test_cnt = 0;
    static uint32_t s_err_cnt = 0;

    if(s_test_cnt < FPGA_SPI_SCK_TEST_CNT) {
        tmp = 0;
        fpga_reg_write(0x00, FPGA_WHO_AM_I_REG);
        fpga_reg_read(FPGA_WHO_AM_I_REG, (uint8_t *)&tmp);
        if(tmp != FPGA_WHO_AM_I_REG_VAL) {
            s_err_cnt++;
        }
        s_test_cnt++;
    } else {
        if(s_err_cnt >= 0) {
            ret = FPGA_TEST_RET_ERR;
        } else {
            ret = FPGA_TEST_RET_OK;
        }
        Serial.printf("[DEBUG] FPGA TEST...SCK: %d MHz, Check: %d, Err: %d\n",SPI_SCK_VAL / 1000000, s_test_cnt, s_err_cnt);
    }

    return ret;
}
#endif
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
    SPI.setMISO(SPI_MISO_PIN);
    SPI.setSCK(SPI_SCK_PIN);
    SPI.setMOSI(SPI_MOSI_PIN);
    pinMode(SPI_CS_PIN, OUTPUT);
    digitalWrite(SPI_CS_PIN, HIGH);
    SPI.begin();

    // シリアル初期化
    Serial.begin(115200);
    while (!Serial && millis() < 3000);

#ifdef DEBUG_FPGA_TEST
    // (DEBUG)FPGAテスト
    static uint8_t s_ret = FPGA_TEST_RET_EXEC;
    while (s_ret == FPGA_TEST_RET_EXEC)
    {
        s_ret = fpga_spi_test();
    }

    if(s_ret == FPGA_TEST_RET_ERR) {
        s_is_fpga_err = true;
    }
#endif
}

void CPU_CORE_0_MAIN()
{
    if(s_is_fpga_err != true) {
        if(s_led_state_print_req == false) {
            digitalWrite(LED_BUILTIN, s_fw_led_state ? HIGH : LOW);
            fpga_led_ctrl(s_fpga_led_state);
            s_fw_led_state = !s_fw_led_state;
            s_fpga_led_state = !s_fw_led_state;

            // CPU Core 1へLEDの状態をprintf()要求
            s_led_state_print_req = true;
        }
        delay(MAIN_DELAY_MS);
    }
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
    // CPU Core 0からLEDの状態をprintf()要求があれば
    if(s_is_fpga_err != true) {
        if(s_led_state_print_req == true) {
            // WHO AM Iレジスタ
            Serial.printf("[FPGA] WHO_AM_I Reg(Addr:0x%02X) = 0x%02X\n", FPGA_WHO_AM_I_REG, s_fpga_who_am_i_reg);
            // NOTE: FPGAのLEDはマイコンのLEDの逆状態
            // NOTE: Reqが来る時点で状態は反転済みなのでLED状態はその反転
            Serial.printf("[MCU] LED: %s", !s_fw_led_state ? "ON\r\n" : "OFF\r\n");
            Serial.printf("[FPGA] LED: %s (FPGA Reg Read: 0x%02X)\r\n", !s_fpga_led_state ? "ON" : "OFF", s_fpga_dbg_reg);
            s_led_state_print_req = false;
        }
    }
}