KH1FM CUSTOM MP BAR + EXACT LIMIT GAUGE v1.1

INSTALLATION
1. Disable Custom MP Bar + Exact LIMIT Gauge v1.
2. Disable KH1FM Exact Five-Slot LIMIT Gauge v2.2.
3. Disable every older Numeric, Graphic, Texture Sora HUD, and Resource Probe.
4. Keep LIMIT System v1.6 enabled.
5. Install this ZIP through OpenKH Mod Manager.
6. Completely close KH1FM, then use Build and Run. Do not switch HUD scripts
   with F1.

EXPECTED CONSOLE PREFIX
[CustomMpLimitV1.1]

EASY MP SETTINGS
Open:
scripts/ZZZ_KH1FM_Custom_MP_Bar_LIMIT_Gauge_v1_1.lua

Edit only CONFIG.MP near the top:

X / Y
    Position in KH1's native 640x448 HUD space.

SCALE
    Master size multiplier for the bar and MP label.

LENGTH / HEIGHT / BORDER
    Bar dimensions. Defaults reproduce the reference's 94x7 outer shape.

FILL_DIRECTION
    "LEFT_TO_RIGHT" or "RIGHT_TO_LEFT".

FILL_COLOR / EMPTY_COLOR / BORDER_COLOR
    AABBGGRR native HUD colors. The lower shading bands are generated from the
    selected top-row colors.

LABEL.TEXT
    Custom label text, up to seven ASCII characters.

LABEL.X / LABEL.Y / LABEL.COLOR / LABEL.FONT_SIZE
    Independent MP label controls.

PREVIEW_CURRENT / PREVIEW_MAXIMUM
    Set PREVIEW_CURRENT to 0..PREVIEW_MAXIMUM for a visual test. Return it to
    -1 for live MP.

BEHAVIOR
- The purple fill is continuous and proportional to current MP / maximum MP.
- Current and maximum MP are read directly from Sora's always-live stat page
  every frame. This uses the same compressed-pointer resolution as MP
  Haste/Rage v6 and has no combat gate, so the bar updates during exploration.
- The native-HUD capture and saved-stat bytes remain only as safe fallbacks.
- Native MP outline, fill, MP Charge strip, capacity-extension packets, base
  MP layer, and native MP label are removed.
- Sora's native portrait and main HP gauge remain.
- The LIMIT gauge exactly follows Reference_Exact_LIMIT_0.png,
  Reference_Exact_LIMIT_80.png, and Reference_Exact_LIMIT_100.png.
- Slots fill at 20/40/60/80/100. At 20..80, filled slots remain inside the
  normal gray/black backs. At 100, all five red slots receive the teal outline.
- At 100 only, the outline slowly pulses teal -> white -> teal. This is visual
  only and never changes LIMIT gain, spending, thresholds, or maximum.
- No DDS or MDLS replacement is used.

FULL-LIMIT PULSE SETTINGS
Edit CONFIG.FULL_PULSE near the top of the Lua:

ENABLE
    true enables the full-state flash; false keeps the outline solid teal.

CYCLE_SECONDS
    Seconds for one complete teal -> white -> teal cycle. Default: 3.00.

COLOR_STEPS
    Number of color steps from teal to white. Default: 30.

TEAL_COLOR / WHITE_COLOR
    Editable AABBGGRR endpoint colors.
