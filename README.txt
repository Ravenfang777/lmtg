KH1FM MAX-MP-SCALED BAR + PULSING LIMIT GAUGE v1.2

INSTALLATION
1. Disable Custom MP Bar + LIMIT Gauge v1 and v1.1.
2. Disable KH1FM Exact Five-Slot LIMIT Gauge v2.2.
3. Disable every older Numeric, Graphic, Texture Sora HUD, and Resource Probe.
4. Keep LIMIT System v1.6 enabled.
5. Install this ZIP through OpenKH Mod Manager.
6. Completely close KH1FM, then use Build and Run. Do not switch HUD scripts
   with F1.

EXPECTED CONSOLE PREFIX
[CustomMpLimitV1.2]

EASY MP SETTINGS
Open:
scripts/ZZZ_KH1FM_Custom_MP_Bar_LIMIT_Gauge_v1_2.lua

Edit only CONFIG.MP near the top:

RIGHT_X / Y
    Fixed exclusive right edge and vertical position in KH1's native 640x448
    HUD space. Capacity growth always extends left from RIGHT_X.

SCALE
    Master size multiplier for the MP bar. RIGHT_X remains fixed.

MINIMUM_MAX_MP / MAXIMUM_MAX_MP
    Maximum-MP endpoints used for capacity interpolation. Defaults: 10..255.

MINIMUM_LENGTH / MAXIMUM_LENGTH
    Outer widths at those endpoints. Defaults reproduce the references exactly:
    7 pixels at 10 maximum MP and 179 pixels at 255 maximum MP.

HEIGHT / BORDER
    Vertical size and border thickness. Defaults reproduce the 7-pixel height.

EMPTY_DIRECTION
    "LEFT_TO_RIGHT" makes spent MP disappear from the left while remaining MP
    stays anchored on the right.
    "RIGHT_TO_LEFT" makes spent MP disappear from the right while remaining MP
    stays anchored on the left.

FILL_GRADIENT
    TOP_COLOR / UPPER_COLOR / MIDDLE_COLOR / LOWER_COLOR / BOTTOM_COLOR are the
    five independently editable AABBGGRR purple gradient rows.

EMPTY_GRADIENT
    The same five adjustable stops for the gray empty-capacity background.

BORDER_COLOR
    Adjustable AABBGGRR outer-border color.

LABEL.TEXT
    Custom label text, up to seven ASCII characters.

LABEL.X / LABEL.Y / LABEL.COLOR / LABEL.FONT_SIZE
    Independent MP label controls.

PREVIEW_CURRENT / PREVIEW_MAXIMUM
    Set PREVIEW_CURRENT to 0..PREVIEW_MAXIMUM for a visual test. Return it to
    -1 for live MP.

BEHAVIOR
- The fixed right endpoint is X=210 by default.
- Maximum MP 10 produces the supplied 7x7 bar at X=203..209.
- Maximum MP 255 produces the supplied 179x7 bar at X=31..209.
- Intermediate maximums smoothly interpolate between those exact endpoints.
- The purple fill is proportional to current MP inside the current capacity.
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
- At 100 only, the outline and LIMIT text pulse together. This is visual only
  and never changes LIMIT gain, spending, thresholds, or maximum.
- No DDS or MDLS replacement is used.

FULL-LIMIT PULSE SETTINGS
Edit CONFIG.FULL_PULSE near the top of the Lua:

ENABLE
    true enables the full-state flash; false keeps the start colors solid.

INCLUDE_LIMIT_TEXT
    true pulses the LIMIT text with the outline; false leaves the text red.

CYCLE_SECONDS
    Seconds for one complete start -> peak -> start cycle. Default: 3.00.

COLOR_STEPS
    Number of interpolation steps. Default: 30.

OUTLINE_START_COLOR / OUTLINE_PEAK_COLOR
    Editable AABBGGRR outline endpoints.

TEXT_START_COLOR / TEXT_PEAK_COLOR
    Independently editable AABBGGRR LIMIT-text endpoints.
