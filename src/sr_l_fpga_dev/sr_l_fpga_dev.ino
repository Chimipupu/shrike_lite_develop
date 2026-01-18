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

#define CPU_CORE_0_INIT    setup
#define CPU_CORE_0_MAIN    loop
#define CPU_CORE_1_INIT    setup1
#define CPU_CORE_1_MAIN    loop1

// *************************************************************
// [FPGA関連設定]

// コンパイルスイッチ[FPGAへのビットストリーム書き込み有無]
#define SR_L_FPGA_BITSTREAM_WRITE

#ifdef SR_L_FPGA_BITSTREAM_WRITE
#include "Shrike.h"
ShrikeFlash shrike;
#define FPGA_BITSTREAM_PATH    "/led_blink.bin"
static void fpga_init(const char* bitstream_path);
#endif // SR_L_FPGA_BITSTREAM_WRITE

// *************************************************************
// [Static関数]
// *************************************************************

#ifdef SR_L_FPGA_BITSTREAM_WRITE
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

    // TODO: FPGAの初期化完了確認
}
#endif // SR_L_FPGA_USE_BITSTREAM_WRITE

// *************************************************************
// [CPU Core 0]
// *************************************************************

void CPU_CORE_0_INIT()
{
#ifdef SR_L_FPGA_BITSTREAM_WRITE
    // FPGA初期化
    fpga_init(FPGA_BITSTREAM_PATH);
#endif // SR_L_FPGA_BITSTREAM_WRITE

    // シリアル初期化
    Serial.begin(115200);
    while (!Serial && millis() < 3000);
}

void CPU_CORE_0_MAIN()
{
  // TODO: メインループ処理
}

// *************************************************************
// [CPU Core 1]
// *************************************************************

void CPU_CORE_1_INIT()
{
    // TODO: CPU コア1の初期化処理
}

void CPU_CORE_1_MAIN()
{
    // TODO: CPU コア1のメインループ処理
}