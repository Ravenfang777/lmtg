KH1FM ADJUSTABLE FIVE-SLOT LIMIT GAUGE v2
Native-geometry OpenKH edition

TARGET
  Kingdom Hearts Final Mix, Steam Global 1.0.0.2
  LuaBackendHook v1.9.1-hook / LuaEngine v5.0
  LIMIT System v1.6

WHAT THIS BUILD DOES
  - Adds the red LIMIT label and five persistent shaped gauge slots.
  - Keeps unfilled slots black with a dark-gray outline.
  - Changes one complete slot to red with a cyan-teal outline at:
      20 LIMIT = slot 1
      40 LIMIT = slots 1-2
      60 LIMIT = slots 1-3
      80 LIMIT = slots 1-4
     100 LIMIT = slots 1-5
  - Leaves Sora's native portrait, HP, MP, labels, and textures untouched.
  - Replaces no DDS or MDLS asset.

ADJUSTABLE BASE LAYOUT
  Open:
    scripts/ZZZ_KH1FM_LIMIT_Gauge_v2_AdjustableSlots.lua

  The complete layout starts at the requested base location:
    ORIGIN = {
        X = 0,
        Y = 0,
        SCALE = 1.0,
    }

  X moves everything horizontally.
  Y moves everything vertically.
  SCALE resizes the label and all five slots together.

  LAYOUT.BLOCKS keeps each slot independently adjustable. The default
  positions, widths, rising tops, common baseline, and right-side notches are
  reconstructed from the bottom composite in "LIMIT V2.png".

COLORS
  The editable COLORS table uses KH1's AABBGGRR order:
    FILLED_OUTLINE = cyan-teal
    FILLED_RED     = red
    EMPTY_OUTLINE  = dark gray
    EMPTY_BACK     = black
    NOTCH_BACK     = black

INSTALL
  1. Disable/remove KH1FM Five-Block LIMIT Gauge v1.
  2. Disable every older Numeric, Graphic, Texture, and Resource Probe Sora
     HUD controller.
  3. Keep ZZZ_KH1FM_LIMIT_System_v1_6_EnemyBoundsOrder.lua enabled.
  4. Enemy HP HUD v4.1 may remain enabled.
  5. Add this ZIP as a Kingdom Hearts 1 mod in OpenKH Mod Manager.
  6. Enable it, then use Build and Run.
  7. Completely close and restart KH1FM. Do not switch from v1 with F1.

EXPECTED CONSOLE
  [LimitGaugeV2] READY: adjustable five-slot LIMIT gauge; new installation.
  [LimitGaugeV2] LAYOUT: base origin X=0 Y=0 SCALE=1.
  [LimitGaugeV2] THRESHOLDS: 20, 40, 60, 80, and 100 LIMIT.

VISUAL TEST
  In the Lua CONFIG block, temporarily change:
    PREVIEW_LIMIT = -1
  to:
    PREVIEW_LIMIT = 100

  This displays all five red/teal slots without changing gameplay LIMIT.
  Return PREVIEW_LIMIT to -1 after positioning the gauge.

PREVIEWS
  Preview_LIMIT_0_Origin_0_0.png shows all five black backs.
  Preview_LIMIT_100_Origin_0_0.png shows all five filled slots.

ROLLBACK
  Disable/remove this mod, use Build and Run again, and fully restart KH1FM.
  No remastered asset needs restoration.
