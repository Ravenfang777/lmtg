KH1FM SMOOTH CIRCULAR HP + CUSTOM MP + PULSING LIMIT HUD v1.5

INSTALLATION
1. Disable Smooth Circular HP + Custom MP + Pulsing LIMIT HUD v1.4.
2. Disable Curved HP HUD v1.3.
3. Disable Custom MP Bar + LIMIT Gauge v1/v1.1/v1.2.
4. Disable standalone LIMIT Gauge v2.2.
5. Disable every older Numeric, Graphic, Texture Sora HUD, and Resource Probe.
6. Keep LIMIT System v1.6 enabled.
7. Install this ZIP through OpenKH Mod Manager.
8. Completely close KH1FM, then use Build and Run. Do not switch HUD scripts
   with F1.

EXPECTED CONSOLE PREFIX
[SmoothCircularHpMpLimitV1.5]

WHAT v1.5 FIXES
- Full-LIMIT pulse refreshes no longer set the shared rectangle count to zero.
- HP, MP, and LIMIT remain continuously visible while the outline and LIMIT
  text change color.
- The renderer commits each refreshed record set before publishing its count.
- Every v1.4 visual setting and gameplay behavior is preserved.

RETAINED v1.4 DESIGN
- Preserves Sora's native -a3290.dds face image.
- Removes the native HP outline, capacity, fill, circular backing, and HP label.
- Removes the native MP outline, fill, charge strip, capacity caps, layer, and
  MP label.
- Replaces v1.3's slightly elliptical square-stamped HP curve with a true
  equal-radius circle.
- Rasterizes the circle into one-pixel native scanlines and losslessly merges
  matching rows. This creates the smoothest circular edge available through
  the proven native-rectangle renderer.
- Joins the 76..255 HP straight extension directly to the lower tangent.
- Retains the combined MP and pulsing five-slot LIMIT mechanics.
- Replaces no DDS or MDLS file.

HP CAPACITY AND FILL
- 25 maximum HP reaches 90 degrees around the circle.
- 50 maximum HP reaches 180 degrees.
- 75 maximum HP completes the 270-degree circular portion.
- 76..255 maximum HP extends continuously left from the lower tangent.
- Current HP fills that same path in exact integer-HP steps.
- Maximum HP changes only the available gray capacity.
- Damage and healing change only the green fill.
- HP reads the equipment-adjusted always-live Sora stat page in and out of
  combat, with the saved stat bytes retained only as a startup fallback.

REVISED SETTINGS PRESERVED FROM THE ATTACHED v1.3 LUA
- HP center: X=257, Y=99
- HP scale: 1.00
- HP straight maximum length: 354
- MP fixed right edge: X=207
- MP Y position: 147
- MP minimum/maximum lengths: 10 / 255
- MP label: X=465, Y=338
- LIMIT origin: X=72, Y=113, scale=0.54
- LIMIT label: X=503, Y=429, font size 12
- Empty LIMIT outline: black
- Full-pulse outline peak: black
- Full-pulse text peak: red

EASY HP SETTINGS
Open:
scripts/ZZZ_KH1FM_Smooth_Circular_HP_Custom_MP_LIMIT_HUD_v1_5.lua

Edit CONFIG.HP near the top:

CENTER_X / CENTER_Y / SCALE
    Move or resize the entire HP path.

CURVE_RADIUS
    Resize the circular path with one value. A single shared radius prevents
    horizontal or vertical distortion.

STRAIGHT_MAX_LENGTH
    Straight-section length at 255 maximum HP.

OUTLINE_SIZE / INTERIOR_SIZE / MIDDLE_SIZE / INNER_SIZE
    Thickness of the black outline and gradient layers.

OUTLINE_COLOR
EMPTY_OUTER_COLOR / EMPTY_MIDDLE_COLOR / EMPTY_INNER_COLOR
FILL_OUTER_COLOR / FILL_MIDDLE_COLOR / FILL_INNER_COLOR
    Adjustable AABBGGRR colors.

PREVIEW_CURRENT / PREVIEW_MAXIMUM
    Set PREVIEW_CURRENT to 0..PREVIEW_MAXIMUM for a visual test. Return it to
    -1 for live HP.

MP AND LIMIT
- MP maximum controls the capacity length; current MP controls its fill.
- EMPTY_DIRECTION selects left-to-right or right-to-left depletion.
- MP gradients, label text, label position, label color, and font size remain
  editable.
- LIMIT slots still fill at 20/40/60/80/100.
- At 100, the configured outline and LIMIT text pulse together.
- LIMIT gameplay mechanics are unchanged.

COMPATIBILITY
- The renderer keeps Enemy HP HUD v4.1's module+0x3AF700..0x3AFE00 region free.
- It keeps LIMIT System v1.6's module+0x3AFE40..0x3B0000 region free.
- One 0x4000-byte aligned geometry buffer is allocated once after the player
  HUD loads; there is no per-frame allocation.
- Pulse updates keep the previous valid rectangle list active until the new
  list has been copied, preventing whole-HUD disappearance between writes.
