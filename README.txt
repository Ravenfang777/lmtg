KH1FM EXACT FIVE-SLOT LIMIT GAUGE v2.2
Exact-reference native-geometry OpenKH edition

TARGET
  Kingdom Hearts Final Mix, Steam Global 1.0.0.2
  LuaBackendHook v1.9.1-hook / LuaEngine v5.0
  LIMIT System v1.6

WHAT CHANGED FROM v2.1
  - Treats the two newly supplied PNGs as the exact visual specification.
  - Removes the four-band gradient approximation.
  - Uses exact sampled solid colors:
      filled outline  RGB 0,238,255
      filled edge     RGB 181,0,0
      filled center   RGB 226,20,42
      empty outline   RGB 74,74,74
      empty edge      RGB 39,39,39
      empty center    RGB 85,85,85
      slot gaps       RGB 0,0,0
  - Uses the exact rectangular widths, heights, gaps, common baseline, and
    two-pixel lower-right inset shown in the fifth slot.
  - Preserves the supplied red LIMIT label position and default 0.50 scale.

LIMIT BEHAVIOR
    0-19 LIMIT = all five redesigned empty slots
   20-39 LIMIT = slot 1 filled
   40-59 LIMIT = slots 1-2 filled
   60-79 LIMIT = slots 1-3 filled
   80-99 LIMIT = slots 1-4 filled
     100 LIMIT = slots 1-5 filled

SIZE AND POSITION
  Open:
    scripts/ZZZ_KH1FM_LIMIT_Gauge_v2_2_ExactReference.lua

  Edit only:
    ORIGIN = {
        X = 0,
        Y = 0,
        SCALE = 0.50,
    }

  X moves the complete layout horizontally.
  Y moves the complete layout vertically.
  SCALE resizes the label and all five slots together.

  Suggested SCALE values:
    0.40 = smaller
    0.50 = exact supplied-reference size
    0.60 = slightly larger
    1.00 = redesigned source size

  At X=0, Y=0, SCALE=0.50:
    complete visible footprint = X 15..126, Y 2..31
    five-slot footprint        = X 31..126, Y 2..31

REFERENCE AND PREVIEW IMAGES
  Reference_Exact_LIMIT_0.png and Reference_Exact_LIMIT_100.png are the two
  supplied authoritative images.

  Preview_LIMIT_0_DefaultScale_0_50.png and
  Preview_LIMIT_100_DefaultScale_0_50.png are generated from the exact
  geometry and colors encoded in the Lua. Their decoded RGBA pixels match the
  authoritative references exactly.

  The runtime renderer uses native HUD geometry, not PNG or DDS sampling.

INSTALL
  1. Disable/remove LIMIT Gauge v2.1 and every earlier LIMIT gauge.
  2. Disable every older Numeric, Graphic, Texture, and Resource Probe Sora
     HUD controller.
  3. Keep ZZZ_KH1FM_LIMIT_System_v1_6_EnemyBoundsOrder.lua enabled.
  4. Enemy HP HUD v4.1 may remain enabled.
  5. Add this ZIP as a Kingdom Hearts 1 mod in OpenKH Mod Manager.
  6. Enable it, then use Build and Run.
  7. Completely close and restart KH1FM. Do not switch from v2.1 with F1.

EXPECTED CONSOLE
  [LimitGaugeV2.2] READY: exact-reference five-slot LIMIT gauge; new installation.
  [LimitGaugeV2.2] LAYOUT: base origin X=0 Y=0 SCALE=0.5.
  [LimitGaugeV2.2] THRESHOLDS: 20, 40, 60, 80, and 100 LIMIT.

VISUAL TEST
  Temporarily change:
    PREVIEW_LIMIT = -1
  to:
    PREVIEW_LIMIT = 100

  This displays all five red/teal slots without changing gameplay LIMIT.
  Return PREVIEW_LIMIT to -1 after positioning the gauge.

ROLLBACK
  Disable/remove this mod, use Build and Run again, and fully restart KH1FM.
  No remastered asset needs restoration.
