KH1FM FIVE-BLOCK LIMIT GAUGE v1
Native-geometry OpenKH edition

TARGET
  Kingdom Hearts Final Mix, Steam Global 1.0.0.2
  LuaBackendHook v1.9.1-hook / LuaEngine v5.0
  LIMIT System v1.6

WHAT THIS BUILD DOES
  - Adds only the supplied five-chunk LIMIT gauge.
  - Draws a complete teal-and-pink chunk at:
      20 LIMIT = 1 block
      40 LIMIT = 2 blocks
      60 LIMIT = 3 blocks
      80 LIMIT = 4 blocks
     100 LIMIT = 5 blocks
  - Leaves Sora's native portrait, HP, MP, labels, and textures untouched.
  - Uses KH1's native solid HUD renderer after the complete player-HUD loop.
  - Reconstructs the rising teal outline and pink/deep-red center directly as
    geometry. There is no DDS replacement, UV remap, resource capture, or
    native gauge suppression.

CONTENTS INSTALLED BY OPENKH
  scripts/ZZZ_KH1FM_LIMIT_Gauge_v1_NativeGeometry.lua

INSTALL
  1. Disable every earlier Sora HUD controller/package:
       ZZZ_KH1FM_Numeric_HP_MP_HUD_v1_9.lua
       ZZZ_KH1FM_Graphic_Sora_HP_MP_LIMIT_HUD_*.lua
       ZZZ_KH1FM_Texture_Sora_HP_MP_LIMIT_HUD_*.lua
       KH1FM_Sora_HUD_Resource_Probe_*.lua
  2. Remove manually copied older Sora HUD Lua files from:
       openkh/mod/kh1/scripts
  3. Keep ZZZ_KH1FM_LIMIT_System_v1_6_EnemyBoundsOrder.lua enabled.
  4. Enemy HP HUD v4.1 may remain enabled.
  5. Add this ZIP as a Kingdom Hearts 1 mod in OpenKH Mod Manager.
  6. Enable the mod, then use Build and Run.
  7. Completely close and restart KH1FM. Do not switch from an older HUD
     controller with F1.

EXPECTED CONSOLE
  [LimitGaugeV1] READY: five-block native-geometry LIMIT gauge; new installation.
  [LimitGaugeV1] NATIVE HUD PRESERVED: portrait, HP, MP, labels, and textures are untouched.
  [LimitGaugeV1] THRESHOLDS: 20, 40, 60, 80, and 100 LIMIT.

VISUAL TEST
  In the Lua CONFIG block, temporarily change:
      PREVIEW_LIMIT = -1
  to:
      PREVIEW_LIMIT = 100
  This forces all five displayed blocks but does not change gameplay LIMIT.
  Return PREVIEW_LIMIT to -1 after confirming the layout.

POSITION
  CONFIG.GAUGE defaults to:
      X = 480
      Y = 367
      SCALE = 1.0
  These are the native 640x448 coordinates reconstructed from the supplied
  "Limit Fill 5 Blocks(3).png".

KEEP ENABLED
  EnemyConfig, LIMIT v1.6, MP Haste/Rage v6, Equipment Bonus, Enemy Animation
  Logger, and Enemy HP HUD v4.1 can remain enabled.

ROLLBACK
  Disable/remove this mod, use Build and Run again, and fully restart KH1FM.
  Because the package replaces no game texture or model asset, there is no
  remastered asset to restore.
