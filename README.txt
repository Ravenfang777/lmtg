KH1FM CURVED HP + CUSTOM MP + PULSING LIMIT HUD v1.3

INSTALLATION
1. Disable Custom MP Bar + LIMIT Gauge v1/v1.1/v1.2.
2. Disable standalone LIMIT Gauge v2.2.
3. Disable every older Numeric, Graphic, Texture Sora HUD, and Resource Probe.
4. Keep LIMIT System v1.6 enabled.
5. Install this ZIP through OpenKH Mod Manager.
6. Completely close KH1FM, then use Build and Run. Do not change HUD scripts
   with F1.

EXPECTED CONSOLE PREFIX
[CurvedHpMpLimitV1.3]

WHAT v1.3 CHANGES
- Preserves Sora's native -a3290.dds face image.
- Removes the native HP outline, capacity, fill, circular backing, and HP label.
- Removes the native MP outline, fill, charge strip, capacity caps, layer, and
  MP label.
- Adds the supplied curved/straight gray and gradient-green HP design.
- Retains the v1.2 scalable MP bar and exact pulsing five-slot LIMIT design.
- Replaces no DDS or MDLS file.

HP CAPACITY AND FILL
- 25 maximum HP reaches 90 degrees around the curve.
- 37 maximum HP reaches the supplied intermediate upper-right point.
- 50 maximum HP reaches 180 degrees.
- 75 maximum HP completes the 270-degree curve.
- 76..255 maximum HP extends continuously left from the curve's lower endpoint.
- 255 maximum HP reaches X=3, matching the supplied full-length reference.
- Current HP fills that same path in exact integer-HP steps. Maximum HP changes
  only the available gray capacity; damage and healing change only green fill.
- HP reads the equipment-adjusted always-live Sora stat page in and out of
  combat, with the saved stat bytes retained only as startup fallback.

EASY HP SETTINGS
Open:
scripts/ZZZ_KH1FM_Curved_HP_Custom_MP_LIMIT_HUD_v1_3.lua

Edit CONFIG.HP near the top:

CENTER_X / CENTER_Y / SCALE
    Move or resize the entire HP path.

CURVE_RADIUS_X / CURVE_RADIUS_Y
    Horizontal and vertical curve radii.

STRAIGHT_MAX_LENGTH
    Straight-section length at 255 maximum HP.

OUTLINE_SIZE / INTERIOR_SIZE / MIDDLE_SIZE / INNER_SIZE
    Thickness of the black outline and gradient layers.

OUTLINE_COLOR
EMPTY_OUTER_COLOR / EMPTY_MIDDLE_COLOR / EMPTY_INNER_COLOR
FILL_OUTER_COLOR / FILL_MIDDLE_COLOR / FILL_INNER_COLOR
    Adjustable AABBGGRR colors. Defaults reconstruct the supplied black,
    gray, dark-green, middle-green, and yellow-green appearance.

PREVIEW_CURRENT / PREVIEW_MAXIMUM
    Set PREVIEW_CURRENT to 0..PREVIEW_MAXIMUM for a visual test. Return it to
    -1 for live HP.

MP SETTINGS RETAINED FROM v1.2
- RIGHT_X remains the fixed exclusive right edge.
- Maximum MP 10 produces a 7x7 bar; maximum MP 255 produces a 179x7 bar.
- Capacity growth extends left.
- EMPTY_DIRECTION selects left-to-right or right-to-left depletion.
- FILL_GRADIENT and EMPTY_GRADIENT expose five vertical color stops.
- LABEL exposes editable MP text, position, color, and size.
- MP reads continuously outside combat.

LIMIT SETTINGS RETAINED FROM v1.2
- Slots fill at 20/40/60/80/100.
- At 100, the teal outline and LIMIT text pulse together.
- FULL_PULSE controls enable, cycle speed, color steps, outline endpoints, and
  text endpoints.
- LIMIT gameplay mechanics are unchanged.

COMPATIBILITY
- The renderer keeps Enemy HP HUD v4.1's module+0x3AF700..0x3AFE00 region free.
- It keeps LIMIT System v1.6's module+0x3AFE40..0x3B0000 region free.
- One 0x4000-byte aligned geometry buffer is allocated once after the player
  HUD loads; there is no per-frame allocation.
