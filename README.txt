KH1FM SMOOTH CIRCULAR HP + CUSTOM MP + PULSING LIMIT HUD v1.7

INSTALLATION
1. Disable Smooth Circular HP + Custom MP + Pulsing LIMIT HUD v1.6, v1.5,
   and v1.4.
2. Disable Curved HP HUD v1.3.
3. Disable Custom MP Bar + LIMIT Gauge v1/v1.1/v1.2.
4. Disable standalone LIMIT Gauge v2.2.
5. Disable every older Numeric, Graphic, Texture Sora HUD, and Resource Probe.
6. Keep LIMIT System v1.6 enabled.
7. Install this ZIP through OpenKH Mod Manager.
8. Completely close KH1FM, then use Build and Run. Do not switch HUD scripts
   with F1.

EXPECTED CONSOLE PREFIX
[SmoothCircularHpMpLimitV1.7]

WHAT v1.7 ADDS
- Retains every HP, MP, LIMIT, label, pulse, position, scale, color, and
  pre-existing box value from the supplied edited v1.6 Lua.
- Adds box 4 as an independent fixed 12x12 black rectangle at X=0, Y=0.
- Adds box 5 as a 12x12 black maximum-HP end cap.
- The end cap stays centered on the live maximum-HP endpoint.
- At maximum HP 1..75, it follows the circular endpoint and rotates to the
  curve tangent. At 76..255, it stays horizontal and follows the straight
  extension left.
- The end cap is rasterized as compact scanlines because the native renderer
  has no rotated-rectangle primitive.
- A conservative maximum-load check uses 595 of the private 678 rectangles.

STABLE-FRAME BEHAVIOR RETAINED
- Every render refresh now starts with a fresh frame list.
- The cached HP table remains HP-only; MP changes and LIMIT pulse updates can
  no longer append themselves repeatedly until the rectangle guard stops.
- HP, MP, LIMIT, and all five black boxes use Sora's private heap allocation.
- Enemy HP HUD v4.1 keeps its separate module region and render records.
- Full-LIMIT pulse refreshes no longer set the shared rectangle count to zero.
- HP, MP, and LIMIT remain continuously visible while the outline and LIMIT
  text change color.
- The renderer commits each refreshed record set before publishing its count.
- Every v1.6 gameplay behavior is preserved.

NEW HP TEXT
Edit CONFIG.HP.LABEL:

ENABLE
TEXT
X / Y
COLOR
FONT_SIZE

The default text is "HP". HP, MP, and LIMIT each use one native font record.
These text records do not count against the rectangle capacity.

FIVE ADJUSTABLE BLACK BOXES
Edit CONFIG.BOXES. The original three entries are unchanged. Box 4 starts with:

WIDTH = 12
HEIGHT = 12
COLOR = 0x80000000

X = 0
Y = 0

The first four boxes have independent ENABLE, X, Y, WIDTH, HEIGHT, and COLOR
settings. They render first, allowing them to be used as independent shapes or
as backing pieces beneath the gauges.

Box 5 is the HP end cap. It has independent:

ENABLE
WIDTH / HEIGHT
COLOR
ALONG_OFFSET / NORMAL_OFFSET
X_OFFSET / Y_OFFSET
ROTATION_OFFSET_DEGREES

The offsets fine-tune its placement without disconnecting it from maximum HP.
The end cap renders over the HP path so it functions as a true terminal cap.

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

UPDATED SETTINGS PRESERVED FROM THE ATTACHED v1.6 LUA
- HP center: X=256, Y=122
- HP scale: 1.20
- HP straight maximum length: 354
- MP fixed right edge: X=223
- MP Y position: 142
- MP maximum range: 5 / 99
- MP minimum/maximum lengths: 20 / 396
- MP label: X=478, Y=333
- LIMIT origin: X=136, Y=123, scale=0.30
- LIMIT label: X=802, Y=679, font size 23
- Empty LIMIT outline: black
- Full-pulse outline peak: black
- Full-pulse text peak: red

EASY HP SETTINGS
Open:
scripts/ZZZ_KH1FM_Smooth_Circular_HP_Custom_MP_LIMIT_HUD_v1_7.lua

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
- It keeps module+0x3AFE00..0x3B0000 free, including LIMIT System v1.6.
- One 0x4000-byte aligned geometry buffer is allocated once after the player
  HUD loads; there is no per-frame allocation.
- Three label records are stored at the reserved tail of that same allocation.
- Text does not count as geometry rectangles.
- Pulse updates keep the previous valid rectangle list active until the new
  list has been copied, preventing whole-HUD disappearance between writes.
