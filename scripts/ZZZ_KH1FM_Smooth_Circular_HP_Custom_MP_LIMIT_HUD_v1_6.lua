LUAGUI_NAME = "KH1FM Smooth Circular HP + Custom MP + LIMIT HUD v1.6"
LUAGUI_AUTH = "OpenAI"
LUAGUI_DESC = "Stable-frame smooth circular HP gauge with HP text and three adjustable boxes, Max-MP-scaled custom bar, and exact pulsing five-slot LIMIT gauge."

--[[
    KH1FM SMOOTH CIRCULAR HP + CUSTOM MP + LIMIT HUD v1.6
    Target: KINGDOM HEARTS FINAL MIX.exe, Steam Global 1.0.0.2
    SHA-256: d790746245d26159f3ee0e1060e33b2fa2de06941850a4ac724f598722884bac
    Runtime: LuaBackendHook v1.9.1-hook / LuaEngine v5.0

    PURPOSE
      * Removes Sora's complete native HP gauge, HP capacity/outline, HP fill,
        native circular backing, and native HP label while preserving the
        -a3290.dds Sora face image.
      * Draws a black-outlined gray/green HP path using a true circular arc
        instead of the slightly elliptical, square-stamped v1.3 curve.
      * 1..75 maximum HP grows continuously around a 270-degree curve.
        76..255 maximum HP extends continuously left from the curve's lower
        endpoint. Current HP fills that exact same path point-for-point.
      * The curve advances once per integer HP point and the straight section
        interpolates to the configured 255-HP length.
      * Every arc layer is rasterized into exact one-pixel scanlines and then
        losslessly merged into rectangles. This removes the bulbous diagonal
        edges caused by v1.3's large overlapping square stamps.
      * Removes Sora's native MP gauge, MP Charge strip, MP capacity packets,
        and native MP label.
      * Draws a separate proportional MP bar with the user's revised position,
        length range, label placement, colors, and depletion direction.
      * The bar's right edge stays fixed. Capacity uses the configured length
        at 10 maximum MP and the configured length at 255 maximum MP, with
        every intermediate maximum interpolated continuously. Capacity growth
        therefore extends left.
      * Current MP fills only the capacity that exists for Sora's live maximum.
        EMPTY_DIRECTION can make spent MP empty from left to right or from
        right to left.
      * The empty and filled interiors use separately editable five-stop
        top-to-bottom gradients sampled from the supplied references.
      * Position, scale, minimum/maximum length, height, colors, depletion
        direction, label text, label position, label color, and font size are
        editable in CONFIG.MP.
      * Keeps only Sora's native face image from the original player HUD.
      * Retains the five 20-point LIMIT thresholds and reconstructs the new
        supplied 0, 80, and 100 references exactly.
      * At 20..80, filled slots are red inside the normal gray/black backs.
        At 100, all five red slots switch to a teal outline.
      * While LIMIT remains at 100, the teal outline and the LIMIT text pulse
        together to white and back. Pulse enable, speed, steps, independent
        outline/text endpoint colors, and text inclusion are editable without
        changing LIMIT mechanics.
      * Publishes pulse-color refreshes without setting the shared rectangle
        count to zero. HP, MP, and LIMIT therefore remain continuously visible
        while the full-LIMIT outline and text change color.
      * Copies the cached HP geometry into a fresh frame list before appending
        MP, LIMIT, and auxiliary boxes. Repeated MP or pulse updates therefore
        cannot enlarge or corrupt the cached HP rectangle list.
      * Adds independently adjustable native-font HP text and three adjustable
        black rectangles. Each rectangle begins at 12x12 and can be moved,
        resized, recolored, or disabled without changing gauge mechanics.
      * Reads current and maximum MP directly from Sora's live stat page every
        frame, using the same pointer resolution as MP Haste/Rage v6. This has
        no combat gate, so the custom MP bar updates during exploration too.
      * Uses KH1's native solid-rectangle and ASCII-font renderers after the
        complete player HUD loop. No DDS, MDLS, UV, or texture replacement is
        used.

    LIMIT FILL
          0..19   = five black backs
         20..39   = slot 1 filled
         40..59   = slots 1-2 filled
         60..79   = slots 1-3 filled
         80..99   = slots 1-4 filled
        100       = slots 1-5 filled

    COMPATIBILITY
      * Replaces this HUD's v1.5 and every earlier Curved HP HUD, Custom MP Bar
        + LIMIT Gauge, or standalone LIMIT Gauge version; do not enable any of
        those older scripts at the same time.
      * Provides the two pass-through signatures required by Enemy HP HUD v4.1.
      * Owns module+0x3AF300..0x3AF700, one 0x4000-byte aligned geometry
        allocation, the proven post-loop hook, and HP/MP-only suppression
        sites. All three text records live at the reserved tail of that private
        heap allocation rather than in another module data region.
      * Leaves Enemy HP HUD v4.1's module+0x3AF700..0x3AFE00 region untouched.
      * Leaves module+0x3AFE00..0x3B0000 untouched, including LIMIT v1.6.
      * Does not touch EnemyConfig, MP Haste/Rage, equipment bonuses, damage,
        animation, movement, BGM, or enemy data.

    Disable v1.5, v1.4, Curved HP HUD v1.3, Custom MP Bar + LIMIT Gauge
    v1/v1.1/v1.2, LIMIT Gauge v2.2, and every older Numeric, Graphic, and
    Texture Sora HUD before using this file. Fully restart KH1FM; do not
    switch to it with F1.
]]

-- =========================================================================
-- EASY SETTINGS -- EDIT THIS BLOCK ONLY
-- =========================================================================

local CONFIG = {
    ENABLE = true,
    LOG_VALUE_CHANGES = false,

    -- Custom HP path. Coordinates use KH1's native 640x448 HUD space.
    HP = {
        CENTER_X = 256,
        CENTER_Y = 122,
        SCALE = 1.20,

        -- The supplied references establish this capacity model exactly:
        -- 25 HP = 90 degrees, 50 HP = 180 degrees, 75 HP = 270 degrees.
        CURVE_HP = 75,
        CURVE_SWEEP_DEGREES = 270,
        -- A single radius guarantees a true circle. Increase or decrease this
        -- one value to resize the circular path without making it elliptical.
        CURVE_RADIUS = 30.00,

        -- At 255 HP the lower endpoint reaches X=3 in the supplied reference.
        MAXIMUM_HP = 255,
        STRAIGHT_MAX_LENGTH = 354,

        -- Layer sizes build the black outline and the inward-facing gradients.
        OUTLINE_SIZE = 14,
        INTERIOR_SIZE = 10,
        MIDDLE_SIZE = 7,
        INNER_SIZE = 4,
        MIDDLE_INSET = 1.75,
        INNER_INSET = 3.50,

        -- KH1 HUD colors use AABBGGRR; 0x80 is full native opacity.
        OUTLINE_COLOR = 0x80000000,
        EMPTY_OUTER_COLOR = 0x802D2D2D, -- RGB 45,45,45
        EMPTY_MIDDLE_COLOR = 0x803E3E3E,-- RGB 62,62,62
        EMPTY_INNER_COLOR = 0x80484848, -- RGB 72,72,72
        FILL_OUTER_COLOR = 0x802EA028,  -- RGB 40,160,46
        FILL_MIDDLE_COLOR = 0x8008D5AC, -- RGB 96,182,30
        FILL_INNER_COLOR = 0x8008D5AC,  -- RGB 172,213,8

        -- Independent native-font label. Position/color/size are adjustable.
        LABEL = {
            ENABLE = true,
            TEXT = "HP",
            X = 620,
            Y = 230,
            COLOR = 0x8008D5AC,
            FONT_SIZE = 8,
        },

        -- Visual-only test. -1 uses live HP.
        PREVIEW_CURRENT = -1,
        PREVIEW_MAXIMUM = 255,
    },

    -- Three independent black rectangles. Each begins at 12x12.
    -- They render behind HP, MP, and LIMIT so they can also be repositioned
    -- as backing pieces. X/Y/WIDTH/HEIGHT/COLOR/ENABLE are all adjustable.
    BOXES = {
        {
            ENABLE = true,
            X = 0, Y = 0,
            WIDTH = 12, HEIGHT = 12,
            COLOR = 0x80000000,
        },
        {
            ENABLE = true,
            X = 14, Y = 0,
            WIDTH = 12, HEIGHT = 12,
            COLOR = 0x80000000,
        },
        {
            ENABLE = true,
            X = 28, Y = 0,
            WIDTH = 12, HEIGHT = 12,
            COLOR = 0x80000000,
        },
    },

    -- Custom MP bar. Coordinates use KH1's native 640x448 HUD space.
    MP = {
        -- RIGHT_X is the fixed exclusive right edge. Capacity growth extends
        -- left from this point, matching all four supplied references.
        RIGHT_X = 207,
        Y = 146,
        SCALE = .90,

        -- Revised capacity interpolation endpoints supplied for this variant.
        -- Max MP 10  -> outer width 10
        -- Max MP 200 -> outer width 200
        MINIMUM_MAX_MP = 10,
        MAXIMUM_MAX_MP = 200,
        MINIMUM_LENGTH = 20,
        MAXIMUM_LENGTH = 400,

        HEIGHT = 7,
        BORDER = 1,

        -- Direction in which purple MP disappears as current MP is spent:
        -- "LEFT_TO_RIGHT" keeps the remaining fill anchored on the right.
        -- "RIGHT_TO_LEFT" keeps the remaining fill anchored on the left.
        EMPTY_DIRECTION = "LEFT_TO_RIGHT",

        -- KH1 HUD colors use AABBGGRR; 0x80 is full native opacity.
        -- Every vertical stop is directly adjustable. Defaults reproduce the
        -- reference's five purple rows and five gray rows.
        FILL_GRADIENT = {
            TOP_COLOR = 0x80E41853,          -- RGB 83,24,228
            UPPER_COLOR = 0x80CB164B,        -- RGB 75,22,203
            MIDDLE_COLOR = 0x80B11442,       -- RGB 66,20,177
            LOWER_COLOR = 0x80991239,        -- RGB 57,18,153
            BOTTOM_COLOR = 0x808C1135,       -- RGB 53,17,140
        },
        EMPTY_GRADIENT = {
            TOP_COLOR = 0x80565656,          -- RGB 86,86,86
            UPPER_COLOR = 0x80545454,        -- RGB 84,84,84
            MIDDLE_COLOR = 0x80525252,       -- RGB 82,82,82
            LOWER_COLOR = 0x80525252,        -- RGB 82,82,82
            BOTTOM_COLOR = 0x804F4F4F,       -- RGB 79,79,79
        },
        BORDER_COLOR = 0x80000000,

        LABEL = {
            ENABLE = true,
            TEXT = "MP",
            -- Revised independent label placement.
            X = 465,
            Y = 335,
            COLOR = 0x80E41853,
            FONT_SIZE = 8,
        },

        -- Visual-only live-value override.
        -- PREVIEW_CURRENT=-1 uses live MP. Otherwise use 0..PREVIEW_MAXIMUM.
        PREVIEW_CURRENT = -1,
        PREVIEW_MAXIMUM = 255,
    },

    -- Revised LIMIT placement supplied for this variant.
    ORIGIN = {
        X = 72,
        Y = 114,
        SCALE = 0.54,
    },

    -- Exact doubled-pixel bounds reconstructed from the supplied 0.50-scale
    -- images. Do not alter these values if an exact shape match is required.
    -- Coordinates are relative to ORIGIN and are multiplied by SCALE.
    LAYOUT = {
        BASELINE_Y = 64,
        OUTLINE = 1,
        INNER_EDGE = 1,

        BLOCKS = {
            {
                X = 62, Y = 44, WIDTH = 32,
                GAP_X = 94, GAP_Y = 44, GAP_WIDTH = 4,
            },
            {
                X = 98, Y = 34, WIDTH = 34,
                GAP_X = 132, GAP_Y = 34, GAP_WIDTH = 4,
            },
            {
                X = 136, Y = 24, WIDTH = 34,
                GAP_X = 170, GAP_Y = 24, GAP_WIDTH = 4,
            },
            {
                X = 174, Y = 14, WIDTH = 36,
                GAP_X = 210, GAP_Y = 14, GAP_WIDTH = 4,
            },
            {
                -- At SCALE=0.50 this slot is 20 pixels wide above Y=21
                -- and exactly 18 pixels wide below it.
                X = 214, Y = 4, WIDTH = 40,
                STEP_Y = 42, LOWER_WIDTH = 36,
            },
        },
    },

    LIMIT_LABEL = {
        ENABLE = true,
        TEXT = "LIMIT",
        X = 503,
        Y = 429,
        COLOR = 0x800000FF,
        FONT_SIZE = 12,
    },

    COLORS = {
        -- KH1 HUD colors use AABBGGRR; 0x80 is full native HUD opacity.
        -- These are the exact RGB values sampled from the references.
        FILLED_EDGE = 0x800000B5,    -- RGB 181,0,0
        FILLED_CENTER = 0x802A14E2,  -- RGB 226,20,42
        EMPTY_OUTLINE = 0x80000000,
        EMPTY_EDGE = 0x80272727,
        EMPTY_CENTER = 0x80555555,
        BLACK_BACK = 0x80000000,
    },

    -- Visual-only animation used strictly while LIMIT is exactly 100.
    -- One cycle travels START -> PEAK -> START for both the outline and text.
    FULL_PULSE = {
        ENABLE = true,
        INCLUDE_LIMIT_TEXT = true,
        CYCLE_SECONDS = 3.00,
        COLOR_STEPS = 30,
        OUTLINE_START_COLOR = 0x80FFEE00, -- RGB 0,238,255
        OUTLINE_PEAK_COLOR = 0x80000000,  -- RGB 0,0,0
        TEXT_START_COLOR = 0x80FFEE00,    -- RGB 0,238,255
        TEXT_PEAK_COLOR = 0x802A14E2,     -- RGB 226,20,42
    },

    -- Kept as a named setting so all threshold logic stays explicit.
    GAUGE = {
        POINTS_PER_BLOCK = 20,
        MAX_BLOCKS = 5,
    },

    -- Visual-only test. -1 uses live LIMIT. Set to 100 to force all five
    -- blocks without changing gameplay LIMIT, then return it to -1.
    PREVIEW_LIMIT = -1,
}

-- =========================================================================
-- VERIFIED BUILD CONSTANTS -- DO NOT EDIT
-- =========================================================================

local PREFIX = "[SmoothCircularHpMpLimitV1.6] "

local VERSION_SENTINEL_RVA = 0x3B2271
local VERSION_VALUE = 0x7265737563697065

local LIMIT_VALUE_RVA = 0x3AFEE0
local LIMIT_INTERFACE_SENTINEL_RVA = 0x3AFFC8
local LIMIT_INTERFACE_SENTINEL = 0x4C494D36

local SORA_BASE_RVA = 0x2DE9364
local CURRENT_HP_OFFSET = 0x01
local MAX_HP_OFFSET = 0x02
local CURRENT_MP_OFFSET = 0x03
local MAX_MP_OFFSET = 0x04

-- Always-live Sora object/stat-page path verified by MP Haste/Rage v6.
local SORA_POINTER_RVA = 0x2537E48
local POINTER_BANK_TABLE_RVA = 0x2EE3980
local SORA_STAT_PAGE_OFFSET = 0x6C
local STAT_CURRENT_HP_OFFSET = 0x3C
local STAT_MAXIMUM_HP_OFFSET = 0x40
local STAT_CURRENT_MP_OFFSET = 0x44
local STAT_MAXIMUM_MP_OFFSET = 0x48

local HP_GAUGE_BYPASS_RVA = 0x2698E8
local HP_GAUGE_ORIGINAL = {
    0x66, 0x0F, 0x6F, 0x05, 0xE0, 0x61, 0x1C, 0x00,
}
local HP_GAUGE_CUSTOM = {
    0x48, 0x8B, 0xC6, 0xE9, 0x40, 0x06, 0x00, 0x00,
}

local MP_GAUGE_BYPASS_RVA = 0x269F61
local MP_GAUGE_ORIGINAL = {
    0x66, 0x0F, 0x6F, 0x05, 0x67, 0x5B, 0x1C, 0x00,
}
local MP_GAUGE_CUSTOM = {
    0x48, 0x8B, 0xC6, 0xE9, 0x4D, 0x00, 0x00, 0x00,
}

local MP_FILL_CALL_RVA = 0x26D0A8
local MP_FILL_ORIGINAL = {
    0xE8, 0x33, 0xF6, 0xFF, 0xFF,
}
local MP_FILL_CUSTOM = {
    0x48, 0x8B, 0xC2, 0x90, 0x90,
}

local HP_FILL_CALL_RVA = 0x26D0C3
local HP_FILL_ORIGINAL = {
    0xE8, 0x28, 0xEC, 0xFF, 0xFF,
}
local HP_FILL_CUSTOM = {
    0x48, 0x8B, 0xC2, 0x90, 0x90,
}

local MP_CHARGE_FILL_CALL_RVA = 0x26D0FD
local MP_CHARGE_FILL_ORIGINAL = {
    0xE8, 0x6E, 0xD6, 0xFF, 0xFF,
}
local MP_CHARGE_FILL_CUSTOM = {
    0x48, 0x8B, 0xC2, 0x90, 0x90,
}

-- This shared helper emits the remaining native capacity-extension cap
-- packets. Suppressing it is required for complete native MP removal.
local CAPACITY_EXTENSION_CALL_RVA = 0x26D118
local CAPACITY_EXTENSION_ORIGINAL = {
    0xE8, 0xE3, 0xF8, 0xFF, 0xFF,
}
local CAPACITY_EXTENSION_CUSTOM = {
    0x48, 0x8B, 0xC2, 0x90, 0x90,
}

-- Sora draw-order entry 3 is the -a3290.dds face atlas. The cave filter
-- preserves only that entry for Sora HUD type 0 and passes every non-Sora
-- sprite through to the native emitter.
local BASE_SPRITE_CALL_RVA = 0x269332
local BASE_SPRITE_ORIGINAL = {
    0xE8, 0x59, 0x3B, 0x00, 0x00,
}
local BASE_SPRITE_CUSTOM = {
    0xE8, 0x11, 0x60, 0x14, 0x00,
}

local SORA_HUD_CALL_RVA = 0x26DFC9
local SORA_HUD_CALL_ORIGINAL = {
    0xE8, 0xC2, 0xEF, 0xFF, 0xFF,
}
local SORA_HUD_CALL_CUSTOM = {
    0xE8, 0x32, 0x13, 0x14, 0x00,
}

local FINAL_RENDER_CALL_RVA = 0x26E006
local FINAL_RENDER_CALL_ORIGINAL = {
    0xE8, 0x65, 0x14, 0x01, 0x00,
}
local FINAL_RENDER_CALL_CUSTOM = {
    0xE8, 0x75, 0x13, 0x14, 0x00,
}

local POST_LOOP_HOOK_RVA = 0x26E028
local POST_LOOP_HOOK_ORIGINAL = {
    0x0F, 0x28, 0xBC, 0x24, 0xA0, 0x00, 0x00, 0x00,
}
local POST_LOOP_HOOK_CUSTOM = {
    0xE9, 0x5B, 0x13, 0x14, 0x00, 0x90, 0x90, 0x90,
}

local DRAW_RECTANGLE_RVA = 0x146690
local DRAW_RECTANGLE_SIGNATURE = {
    0x4C, 0x89, 0x44, 0x24, 0x18, 0x48, 0x89, 0x54,
    0x24, 0x10, 0x53, 0x48, 0x83, 0xEC, 0x20, 0x48,
}

local PLAYER_HUD_RVA = 0x26CF90
local PLAYER_HUD_SIGNATURE = {
    0x48, 0x89, 0x5C, 0x24, 0x10, 0x57, 0x48, 0x83,
    0xEC, 0x60, 0x48, 0x8D, 0x05, 0xBF, 0xBF, 0xC7,
}

local ALIGNED_MALLOC_IAT_RVA = 0x3B0778
local ALIGNED_MALLOC_CALL_RVA = 0x0D582D

local CAVE_RVA = 0x3AF300
local CODE_SIZE = 0x400
local IMMUTABLE_CODE_SIZE = 0x3F0
local DATA_POINTER_RVA = CAVE_RVA + 0x3F0
local CAVE_SENTINEL_RVA = CAVE_RVA + 0x3F8
local CAVE_SENTINEL = 0x4D504843
local HEAP_DATA_SIZE = 0x4000
local DATA_SENTINEL = 0x31504D43
local LABEL_SENTINEL = 0x31585541
local RECTANGLE_RECORDS_OFFSET = 0x08
local RECTANGLE_RECORD_SIZE = 0x18
local LABEL_RECORD_SIZE = 0x20
local LABEL_RECORD_COUNT = 3
local LABEL_RECORDS_SIZE = LABEL_RECORD_SIZE * LABEL_RECORD_COUNT
local LABEL_RECORDS_OFFSET = HEAP_DATA_SIZE - LABEL_RECORDS_SIZE
local MAX_RECTANGLES =
    math.floor((LABEL_RECORDS_OFFSET - RECTANGLE_RECORDS_OFFSET)
        / RECTANGLE_RECORD_SIZE)
local EXACT_LIMIT_RECTANGLE_COUNT = 22
local EXACT_MP_RECTANGLE_COUNT = 9
local EXACT_BOX_RECTANGLE_COUNT = 3

-- Assembled for module+0x3AF300. It contains:
--   +0x000 player-HUD pass-through and one-time allocator call
--   +0x048 Sora face-only base-sprite filter
--   +0x080 minimal final-render pass-through
--   +0x088 post-loop HP/LIMIT/MP rectangle traversal and three-label loop
--   +0x180 verified aligned-allocator helper
--   +0x3F0 heap pointer
--   +0x3F8 cave sentinel
local CAVE_CODE = {
    0x53, 0x48, 0x83, 0xEC, 0x20, 0x48, 0x89, 0xCB, 0x48, 0x8B, 0x41, 0x08, 0x48, 0x85, 0xC0, 0x74,
    0x05, 0xE8, 0x6A, 0x01, 0x00, 0x00, 0x48, 0x89, 0xD9, 0xE8, 0x72, 0xDC, 0xEB, 0xFF, 0x48, 0x83,
    0xC4, 0x20, 0x5B, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x83, 0x3E, 0x00, 0x75, 0x06, 0x48, 0x83, 0xFB,
    0x03, 0x75, 0x05, 0xE9, 0x38, 0xDB, 0xEB, 0xFF, 0x4C, 0x89, 0xF0, 0xC3, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xE9, 0xEB, 0x00, 0xED, 0xFF, 0x00, 0x00, 0x00, 0x53, 0x56, 0x57, 0x48, 0x83, 0xEC, 0x38, 0xE8,
    0xEC, 0x00, 0x00, 0x00, 0x48, 0x85, 0xC0, 0x74, 0x57, 0x48, 0x89, 0xC7, 0x8B, 0x1F, 0x85, 0xDB,
    0x74, 0x1B, 0x48, 0x8D, 0x77, 0x08, 0x8B, 0x0E, 0x48, 0x8B, 0x56, 0x08, 0x4C, 0x8B, 0x46, 0x10,
    0xE8, 0xDB, 0x72, 0xD9, 0xFF, 0x48, 0x83, 0xC6, 0x18, 0xFF, 0xCB, 0x75, 0xE9, 0xBB, 0x03, 0x00,
    0x00, 0x00, 0x48, 0x8D, 0xB7, 0xA0, 0x3F, 0x00, 0x00, 0x83, 0x3E, 0x00, 0x74, 0x1A, 0x8B, 0x4E,
    0x0C, 0x8B, 0x56, 0x04, 0x44, 0x8B, 0x46, 0x08, 0x4C, 0x8D, 0x4E, 0x14, 0x8B, 0x46, 0x10, 0x89,
    0x44, 0x24, 0x20, 0xE8, 0x08, 0x07, 0xF2, 0xFF, 0x48, 0x83, 0xC6, 0x20, 0xFF, 0xCB, 0x75, 0xD9,
    0x48, 0x83, 0xC4, 0x38, 0x5F, 0x5E, 0x5B, 0x0F, 0x28, 0xBC, 0x24, 0xA0, 0x00, 0x00, 0x00, 0xE9,
    0x2C, 0xEC, 0xEB, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x48, 0x8B, 0x05, 0x69, 0x02, 0x00, 0x00, 0x48, 0x85, 0xC0, 0x75, 0x3A, 0x57, 0x48, 0x83, 0xEC,
    0x20, 0xB9, 0x00, 0x40, 0x00, 0x00, 0xBA, 0x10, 0x00, 0x00, 0x00, 0xFF, 0x15, 0xD7, 0x12, 0x00,
    0x00, 0x48, 0x85, 0xC0, 0x74, 0x1B, 0x48, 0x89, 0x05, 0x43, 0x02, 0x00, 0x00, 0x48, 0x89, 0xC7,
    0x31, 0xC0, 0xB9, 0x00, 0x08, 0x00, 0x00, 0xF3, 0x48, 0xAB, 0x48, 0x8B, 0x05, 0x2F, 0x02, 0x00,
    0x00, 0x48, 0x83, 0xC4, 0x20, 0x5F, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x43, 0x48, 0x50, 0x4D, 0x48, 0x50, 0x47, 0x31,
}

local ZERO_CODE = {}
local zeroIndex
for zeroIndex = 1, CODE_SIZE do
    ZERO_CODE[zeroIndex] = 0
end

local runtime = {
    installed = false,
    stopped = false,
    waitingBuildLogged = false,
    waitingLimitLogged = false,
    lastBlocks = nil,
    lastCurrentHp = nil,
    lastMaximumHp = nil,
    lastCurrentMp = nil,
    lastMaximumMp = nil,
    lastFullOutlineColor = nil,
    lastFullLabelColor = nil,
    pulseFrame = 0,
    directMpLogged = false,
    effectiveMpLogged = false,
    geometryWaitingLogged = false,
}

-- =========================================================================
-- SAFE MEMORY AND SERIALIZATION HELPERS
-- =========================================================================

local function log(message)
    ConsolePrint(PREFIX .. tostring(message))
end

local function unsigned32(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    if number < 0 then
        return number + 4294967296
    end
    return number
end

local function safeReadInt(address)
    local ok, value = pcall(ReadInt, address, false)
    if not ok or value == nil then
        return nil
    end
    return unsigned32(value)
end

local function safeReadLong(address)
    local ok, value = pcall(ReadLong, address, false)
    if not ok then
        return nil
    end
    return value
end

local function safeReadIntAbsolute(address)
    local ok, value = pcall(ReadInt, address, true)
    if not ok or value == nil then
        return nil
    end
    return unsigned32(value)
end

local function safeReadArray(address, length)
    local ok, value = pcall(ReadArray, address, length, false)
    if not ok or value == nil or #value < length then
        return nil
    end
    return value
end

local function arraysEqual(left, right)
    if left == nil or right == nil or #left ~= #right then
        return false
    end
    local index
    for index = 1, #right do
        if left[index] ~= right[index] then
            return false
        end
    end
    return true
end

local function codeImageMatches(left, right)
    if left == nil or right == nil or #left ~= #right then
        return false
    end
    local index
    for index = 1, IMMUTABLE_CODE_SIZE do
        if left[index] ~= right[index] then
            return false
        end
    end
    return true
end

local function isZeroArray(bytes)
    if bytes == nil then
        return false
    end
    local index
    for index = 1, #bytes do
        if bytes[index] ~= 0 then
            return false
        end
    end
    return true
end

local function safeWriteArray(address, bytes)
    local ok, reason = pcall(WriteArray, address, bytes, false)
    if not ok then
        return false, tostring(reason)
    end
    if not arraysEqual(safeReadArray(address, #bytes), bytes) then
        return false, "write did not verify"
    end
    return true
end

local function safeReadArrayAbsolute(address, length)
    local ok, value = pcall(ReadArray, address, length, true)
    if not ok or value == nil or #value < length then
        return nil
    end
    return value
end

local function safeWriteArrayAbsolute(address, bytes)
    local ok, reason = pcall(WriteArray, address, bytes, true)
    if not ok then
        return false, tostring(reason)
    end
    if not arraysEqual(
        safeReadArrayAbsolute(address, #bytes),
        bytes
    ) then
        return false, "absolute write did not verify"
    end
    return true
end

local function appendU32(output, value)
    local number = math.floor(tonumber(value) or 0) % 4294967296
    output[#output + 1] = number % 256
    number = math.floor(number / 256)
    output[#output + 1] = number % 256
    number = math.floor(number / 256)
    output[#output + 1] = number % 256
    number = math.floor(number / 256)
    output[#output + 1] = number % 256
end

local function appendU64Parts(output, low, high)
    appendU32(output, low)
    appendU32(output, high)
end

local function round(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function plausibleRuntimeAddress(address)
    return type(address) == "number"
        and address >= 0x10000
        and address < 0x0000800000000000
        and address % 4 == 0
end

local function resolveCompressedPointer(encoded)
    local value = unsigned32(encoded)
    if value == nil or value == 0 then
        return 0
    end
    if value < 0x80000000 then
        return value
    end

    local payload = value - 0x80000000
    local bankIndex = math.floor(payload / 0x2000000)
    local bankOffset = payload % 0x2000000
    local bankBase = safeReadLong(
        POINTER_BANK_TABLE_RVA + bankIndex * 8
    )
    if bankBase == nil or bankBase == 0 then
        return 0
    end
    return bankBase + bankOffset
end

local function readRuntimeHertz()
    local ok, value = pcall(GetHertz)
    local hertz = tonumber(value)
    if not ok or hertz == nil or hertz < 1 or hertz > 1000 then
        return 60
    end
    return math.max(1, math.floor(hertz + 0.5))
end

-- Encodes a KH1 GS-space point without bit libraries or imprecise packed
-- 64-bit integer arithmetic.
local function packedPointParts(x, y)
    local screenX = math.floor(x)
    local screenY = math.floor(y)
    local packedX = (0x8000 + screenX * 16) % 0x20000
    local packedY = (0x8000 + screenY * 16) % 0x20000
    local highSource = 0x1FFFFFC0000 + packedY
    local low = packedX + (highSource % 0x8000) * 0x20000
    local high = math.floor(highSource / 0x8000)
    return low, high
end

-- =========================================================================
-- SHARED AND CURVED HP GEOMETRY
-- =========================================================================

local function addRectangle(rectangles, x, y, width, height, color)
    local resolvedWidth = math.max(1, round(width))
    local resolvedHeight = math.max(1, round(height))
    rectangles[#rectangles + 1] = {
        x = round(x),
        y = round(y),
        width = resolvedWidth,
        height = resolvedHeight,
        color = color,
    }
end

local function addRectangleEdges(rectangles, left, top, right, bottom, color)
    local resolvedLeft = round(left)
    local resolvedTop = round(top)
    local resolvedRight = round(right)
    local resolvedBottom = round(bottom)
    addRectangle(
        rectangles,
        resolvedLeft,
        resolvedTop,
        math.max(1, resolvedRight - resolvedLeft),
        math.max(1, resolvedBottom - resolvedTop),
        color
    )
end

-- Lua 5.0 does not consistently expose math.atan2, so normalize atan(y/x)
-- explicitly. The returned angle follows the HP path's screen-space sweep:
-- 180 degrees at the left endpoint, 270 at the top, 360 at the right, and
-- 450 at the lower endpoint.
local function hpArcDegrees(deltaX, deltaY)
    local angle
    if deltaX > 0 then
        angle = math.atan(deltaY / deltaX)
    elseif deltaX < 0 then
        angle = math.atan(deltaY / deltaX)
        if deltaY >= 0 then
            angle = angle + math.pi
        else
            angle = angle - math.pi
        end
    elseif deltaY < 0 then
        angle = -math.pi / 2
    elseif deltaY > 0 then
        angle = math.pi / 2
    else
        return 180
    end

    local degrees = angle * 180 / math.pi
    if degrees < 180 then
        degrees = degrees + 360
    end
    return degrees
end

local function hpRunsEqual(left, right)
    if left == nil or right == nil or #left ~= #right then
        return false
    end
    local index
    for index = 1, #left do
        if left[index].x ~= right[index].x
            or left[index].width ~= right[index].width
        then
            return false
        end
    end
    return true
end

local function addHpPathLayer(
    rectangles,
    hpAmount,
    size,
    inwardInset,
    color
)
    local hp = CONFIG.HP
    local amount = clamp(
        math.floor(tonumber(hpAmount) or 0),
        0,
        hp.MAXIMUM_HP
    )
    if amount <= 0 then
        return
    end

    local scale = hp.SCALE
    local resolvedSize = math.max(1, round(size * scale))
    local halfSize = resolvedSize / 2
    local curveAmount = math.min(amount, hp.CURVE_HP)
    local radius = math.max(
        1,
        (hp.CURVE_RADIUS - inwardInset) * scale
    )
    local maximumArcDegrees =
        hp.CURVE_SWEEP_DEGREES * curveAmount / hp.CURVE_HP
    local straightLength = 0
    if amount > hp.CURVE_HP then
        local straightAmount =
            (amount - hp.CURVE_HP)
            / (hp.MAXIMUM_HP - hp.CURVE_HP)
        straightLength = math.max(
            1,
            round(hp.STRAIGHT_MAX_LENGTH * scale * straightAmount)
        )
    end

    -- Rasterize the circular stroke by testing pixel centers against a true
    -- annulus and the active angular sweep. This produces a circular outside
    -- edge at every diagonal instead of the swollen outline created by large
    -- overlapping square stamps. The straight section is unioned into the
    -- same rows so its tangent join remains seamless.
    local outerRadius = radius + halfSize
    local innerRadius = math.max(0, radius - halfSize)
    local outerSquared = outerRadius * outerRadius
    local innerSquared = innerRadius * innerRadius
    local straightCenterY = hp.CENTER_Y + radius
    local leftBound = math.floor(math.min(
        hp.CENTER_X - outerRadius,
        hp.CENTER_X - straightLength
    ) - 1)
    local rightBound = math.ceil(hp.CENTER_X + outerRadius + 1)
    local topBound = math.floor(hp.CENTER_Y - outerRadius - 1)
    local bottomBound = math.ceil(hp.CENTER_Y + outerRadius + 1)
    local previousRuns = nil
    local previousRectangleIndices = nil
    local y
    for y = topBound, bottomBound do
        local runs = {}
        local runStart = nil
        local x
        for x = leftBound, rightBound do
            local pixelX = x + 0.5
            local pixelY = y + 0.5
            local deltaX = pixelX - hp.CENTER_X
            local deltaY = pixelY - hp.CENTER_Y
            local distanceSquared =
                deltaX * deltaX + deltaY * deltaY
            local onStraight =
                straightLength > 0
                and pixelX >= hp.CENTER_X - straightLength
                and pixelX <= hp.CENTER_X
                and pixelY >= straightCenterY - halfSize
                and pixelY <= straightCenterY + halfSize
            local onArc = false
            if not onStraight
                and distanceSquared >= innerSquared
                and distanceSquared <= outerSquared
            then
                local degrees = hpArcDegrees(deltaX, deltaY)
                local arcProgress = degrees - 180
                onArc =
                    arcProgress >= 0
                    and arcProgress <= maximumArcDegrees
            end
            local active = onArc or onStraight
            if active and runStart == nil then
                runStart = x
            elseif not active and runStart ~= nil then
                runs[#runs + 1] = {
                    x = runStart,
                    width = x - runStart,
                }
                runStart = nil
            end
        end
        if runStart ~= nil then
            runs[#runs + 1] = {
                x = runStart,
                width = rightBound + 1 - runStart,
            }
        end

        -- Adjacent scanlines with identical spans are merged vertically.
        -- This is lossless and keeps the smooth curve comfortably inside the
        -- verified native geometry buffer even while LIMIT is pulsing.
        if #runs > 0 and hpRunsEqual(runs, previousRuns) then
            local runIndex
            for runIndex = 1, #runs do
                local rectangle =
                    rectangles[previousRectangleIndices[runIndex]]
                rectangle.height = rectangle.height + 1
            end
        else
            previousRuns = runs
            previousRectangleIndices = {}
            local runIndex
            for runIndex = 1, #runs do
                addRectangle(
                    rectangles,
                    runs[runIndex].x,
                    y,
                    runs[runIndex].width,
                    1,
                    color
                )
                previousRectangleIndices[runIndex] = #rectangles
            end
        end
        if #runs == 0 then
            previousRuns = nil
            previousRectangleIndices = nil
        end
    end
end

local hpGeometryCache = {
    current = nil,
    maximum = nil,
    rectangles = nil,
}

local function buildHpRectangles(currentHp, maximumHp)
    local hp = CONFIG.HP
    local maximum = clamp(
        math.floor(tonumber(maximumHp) or 1),
        1,
        hp.MAXIMUM_HP
    )
    local current = clamp(
        math.floor(tonumber(currentHp) or 0),
        0,
        maximum
    )
    if hpGeometryCache.current == current
        and hpGeometryCache.maximum == maximum
        and hpGeometryCache.rectangles ~= nil
    then
        return hpGeometryCache.rectangles
    end

    local rectangles = {}

    -- Capacity: black outline plus a three-stop inward gray gradient.
    addHpPathLayer(
        rectangles,
        maximum,
        hp.OUTLINE_SIZE,
        0,
        hp.OUTLINE_COLOR
    )
    addHpPathLayer(
        rectangles,
        maximum,
        hp.INTERIOR_SIZE,
        0,
        hp.EMPTY_OUTER_COLOR
    )
    addHpPathLayer(
        rectangles,
        maximum,
        hp.MIDDLE_SIZE,
        hp.MIDDLE_INSET,
        hp.EMPTY_MIDDLE_COLOR
    )
    addHpPathLayer(
        rectangles,
        maximum,
        hp.INNER_SIZE,
        hp.INNER_INSET,
        hp.EMPTY_INNER_COLOR
    )

    -- Current HP overlays only the exact path length represented by current.
    addHpPathLayer(
        rectangles,
        current,
        hp.INTERIOR_SIZE,
        0,
        hp.FILL_OUTER_COLOR
    )
    addHpPathLayer(
        rectangles,
        current,
        hp.MIDDLE_SIZE,
        hp.MIDDLE_INSET,
        hp.FILL_MIDDLE_COLOR
    )
    addHpPathLayer(
        rectangles,
        current,
        hp.INNER_SIZE,
        hp.INNER_INSET,
        hp.FILL_INNER_COLOR
    )
    hpGeometryCache.current = current
    hpGeometryCache.maximum = maximum
    hpGeometryCache.rectangles = rectangles
    return rectangles
end

-- =========================================================================
-- LIMIT BLOCK GEOMETRY
-- =========================================================================

local function addBlock(rectangles, block, filled, fullOutlineColor)
    local scale = CONFIG.ORIGIN.SCALE
    local layout = CONFIG.LAYOUT
    local colors = CONFIG.COLORS
    -- The 20/40/60/80 references retain the gray outer slot line. Only the
    -- complete 100-point state replaces it with the animated teal/white line.
    local outlineColor = fullOutlineColor or colors.EMPTY_OUTLINE
    local edgeColor = filled
        and colors.FILLED_EDGE
        or colors.EMPTY_EDGE
    local centerColor = filled
        and colors.FILLED_CENTER
        or colors.EMPTY_CENTER

    local left = round(CONFIG.ORIGIN.X + block.X * scale)
    local top = round(CONFIG.ORIGIN.Y + block.Y * scale)
    local right = round(
        CONFIG.ORIGIN.X + (block.X + block.WIDTH) * scale
    )
    local bottom = round(
        CONFIG.ORIGIN.Y + layout.BASELINE_Y * scale
    )
    local outline = math.max(1, round(layout.OUTLINE * scale))
    local innerEdge = math.max(1, round(layout.INNER_EDGE * scale))
    local innerLeft = left + outline
    local innerTop = top + outline
    local innerRight = math.max(innerLeft + 1, right - outline)
    local innerBottom = math.max(innerTop + 1, bottom - outline)

    if block.LOWER_WIDTH ~= nil then
        -- The supplied fifth slot has a two-pixel lower-right inset. The
        -- narrower lower outline overlaps the final upper row to form the
        -- exact horizontal cyan/gray step without drawing a black cutout.
        local stepTop = round(
            CONFIG.ORIGIN.Y + block.STEP_Y * scale
        )
        local lowerRight = round(
            CONFIG.ORIGIN.X
                + (block.X + block.LOWER_WIDTH) * scale
        )

        addRectangleEdges(
            rectangles,
            left,
            top,
            right,
            stepTop + outline,
            outlineColor
        )
        addRectangleEdges(
            rectangles,
            innerLeft,
            innerTop,
            innerRight,
            stepTop,
            edgeColor
        )
        addRectangleEdges(
            rectangles,
            innerLeft + innerEdge,
            innerTop,
            math.max(innerLeft + innerEdge + 1, innerRight - innerEdge),
            stepTop,
            centerColor
        )
        addRectangleEdges(
            rectangles,
            left,
            stepTop,
            lowerRight,
            bottom,
            outlineColor
        )
        addRectangleEdges(
            rectangles,
            innerLeft,
            stepTop,
            math.max(innerLeft + 1, lowerRight - outline),
            innerBottom,
            edgeColor
        )
        addRectangleEdges(
            rectangles,
            innerLeft + innerEdge,
            stepTop,
            math.max(
                innerLeft + innerEdge + 1,
                lowerRight - outline - innerEdge
            ),
            innerBottom,
            centerColor
        )
        return
    end

    -- Standard supplied slot: outer line, dark side edge, solid center.
    addRectangleEdges(
        rectangles,
        left,
        top,
        right,
        bottom,
        outlineColor
    )
    addRectangleEdges(
        rectangles,
        innerLeft,
        innerTop,
        innerRight,
        innerBottom,
        edgeColor
    )
    addRectangleEdges(
        rectangles,
        innerLeft + innerEdge,
        innerTop,
        math.max(innerLeft + innerEdge + 1, innerRight - innerEdge),
        innerBottom,
        centerColor
    )

    -- Exact opaque-black stair gap following slots 1-4.
    addRectangleEdges(
        rectangles,
        CONFIG.ORIGIN.X + block.GAP_X * scale,
        CONFIG.ORIGIN.Y + block.GAP_Y * scale,
        CONFIG.ORIGIN.X
            + (block.GAP_X + block.GAP_WIDTH) * scale,
        CONFIG.ORIGIN.Y + layout.BASELINE_Y * scale,
        colors.BLACK_BACK
    )
end

local function buildLimitRectangles(blockCount, fullOutlineColor)
    local rectangles = {}
    local index
    for index = 1, CONFIG.GAUGE.MAX_BLOCKS do
        addBlock(
            rectangles,
            CONFIG.LAYOUT.BLOCKS[index],
            index <= blockCount,
            blockCount >= CONFIG.GAUGE.MAX_BLOCKS
                and fullOutlineColor
                or nil
        )
    end
    return rectangles
end

local function colorChannels(color)
    local value = math.floor(tonumber(color) or 0) % 4294967296
    local red = value % 256
    local green = math.floor(value / 256) % 256
    local blue = math.floor(value / 65536) % 256
    local alpha = math.floor(value / 16777216) % 256
    return red, green, blue, alpha
end

local function blendedColor(first, second, amount)
    local firstRed, firstGreen, firstBlue, firstAlpha =
        colorChannels(first)
    local secondRed, secondGreen, secondBlue, secondAlpha =
        colorChannels(second)
    local factor = clamp(tonumber(amount) or 0, 0, 1)
    local red = round(firstRed + (secondRed - firstRed) * factor)
    local green =
        round(firstGreen + (secondGreen - firstGreen) * factor)
    local blue = round(firstBlue + (secondBlue - firstBlue) * factor)
    local alpha =
        round(firstAlpha + (secondAlpha - firstAlpha) * factor)
    return red + green * 256 + blue * 65536 + alpha * 16777216
end

local function fullPulseAmount()
    local pulse = CONFIG.FULL_PULSE
    if not pulse.ENABLE then
        return 0
    end
    local hertz = readRuntimeHertz()
    local cycleFrames = math.max(
        2,
        round(pulse.CYCLE_SECONDS * hertz)
    )
    local phase = (runtime.pulseFrame % cycleFrames) / cycleFrames
    local amount =
        (1 - math.cos(phase * 6.283185307179586)) / 2
    return round(amount * pulse.COLOR_STEPS) / pulse.COLOR_STEPS
end

local function fullPulseColors()
    local pulse = CONFIG.FULL_PULSE
    local amount = fullPulseAmount()
    local outlineColor = blendedColor(
        pulse.OUTLINE_START_COLOR,
        pulse.OUTLINE_PEAK_COLOR,
        amount
    )
    local labelColor = nil
    if pulse.INCLUDE_LIMIT_TEXT then
        labelColor = blendedColor(
            pulse.TEXT_START_COLOR,
            pulse.TEXT_PEAK_COLOR,
            amount
        )
    end
    return outlineColor, labelColor
end

local function mpBandColors()
    local mp = CONFIG.MP
    local emptyGradient = mp.EMPTY_GRADIENT
    local fillGradient = mp.FILL_GRADIENT
    local empty = {
        emptyGradient.TOP_COLOR,
        emptyGradient.UPPER_COLOR,
        emptyGradient.MIDDLE_COLOR,
        emptyGradient.BOTTOM_COLOR,
    }
    local filled = {
        fillGradient.TOP_COLOR,
        fillGradient.UPPER_COLOR,
        -- The four-band partial state combines the reference's middle and
        -- lower one-pixel rows into one two-pixel native rectangle.
        fillGradient.MIDDLE_COLOR,
        fillGradient.BOTTOM_COLOR,
    }
    local exactEmpty = {
        emptyGradient.TOP_COLOR,
        emptyGradient.UPPER_COLOR,
        emptyGradient.MIDDLE_COLOR,
        emptyGradient.LOWER_COLOR,
        emptyGradient.BOTTOM_COLOR,
    }
    local exactFull = {
        fillGradient.TOP_COLOR,
        fillGradient.UPPER_COLOR,
        fillGradient.MIDDLE_COLOR,
        fillGradient.LOWER_COLOR,
        fillGradient.BOTTOM_COLOR,
    }
    return empty, filled, exactEmpty, exactFull
end

local function buildMpRectangles(currentMp, maximumMp)
    local rectangles = {}
    local mp = CONFIG.MP
    local scale = mp.SCALE
    local resolvedMaximum = clamp(
        tonumber(maximumMp) or mp.MINIMUM_MAX_MP,
        mp.MINIMUM_MAX_MP,
        mp.MAXIMUM_MAX_MP
    )
    local capacityAmount =
        (resolvedMaximum - mp.MINIMUM_MAX_MP)
        / (mp.MAXIMUM_MAX_MP - mp.MINIMUM_MAX_MP)
    local unscaledWidth =
        mp.MINIMUM_LENGTH
        + (mp.MAXIMUM_LENGTH - mp.MINIMUM_LENGTH) * capacityAmount
    local width = math.max(3, round(unscaledWidth * scale))
    local right = round(mp.RIGHT_X)
    local x = right - width
    local y = round(mp.Y)
    local height = math.max(3, round(mp.HEIGHT * scale))
    local border = math.max(1, round(mp.BORDER * scale))
    local innerX = x + border
    local innerY = y + border
    local innerWidth = math.max(1, width - border * 2)
    local innerHeight = math.max(1, height - border * 2)
    local fraction = 0
    if maximumMp ~= nil and maximumMp > 0 then
        fraction = clamp((currentMp or 0) / maximumMp, 0, 1)
    end
    local fillWidth = clamp(round(innerWidth * fraction), 0, innerWidth)

    addRectangle(rectangles, x, y, width, height, mp.BORDER_COLOR)

    local emptyColors, fillColors, exactEmptyColors, exactFullColors =
        mpBandColors()
    local starts = { 0, 1, 2, 4 }
    local ends = { 1, 2, 4, 5 }
    local index
    if fillWidth == 0 then
        for index = 1, 5 do
            local top = round(innerY + innerHeight * (index - 1) / 5)
            local bottom = round(innerY + innerHeight * index / 5)
            addRectangle(
                rectangles,
                innerX,
                top,
                innerWidth,
                math.max(1, bottom - top),
                exactEmptyColors[index]
            )
        end
    elseif fillWidth < innerWidth then
        for index = 1, 4 do
            local top = round(innerY + innerHeight * starts[index] / 5)
            local bottom = round(innerY + innerHeight * ends[index] / 5)
            addRectangle(
                rectangles,
                innerX,
                top,
                innerWidth,
                math.max(1, bottom - top),
                emptyColors[index]
            )
        end
    end

    if fillWidth > 0 then
        local fillX = innerX
        if mp.EMPTY_DIRECTION == "LEFT_TO_RIGHT" then
            fillX = innerX + innerWidth - fillWidth
        end
        if fillWidth == innerWidth then
            for index = 1, 5 do
                local top = round(innerY + innerHeight * (index - 1) / 5)
                local bottom = round(innerY + innerHeight * index / 5)
                addRectangle(
                    rectangles,
                    fillX,
                    top,
                    fillWidth,
                    math.max(1, bottom - top),
                    exactFullColors[index]
                )
            end
        else
            for index = 1, 4 do
                local top = round(innerY + innerHeight * starts[index] / 5)
                local bottom = round(innerY + innerHeight * ends[index] / 5)
                addRectangle(
                    rectangles,
                    fillX,
                    top,
                    fillWidth,
                    math.max(1, bottom - top),
                    fillColors[index]
                )
            end
        end
    end
    return rectangles
end

local function appendRectangles(destination, source)
    local index
    for index = 1, #source do
        destination[#destination + 1] = source[index]
    end
end

local function buildBoxRectangles()
    local rectangles = {}
    local index
    for index = 1, #CONFIG.BOXES do
        local box = CONFIG.BOXES[index]
        if box.ENABLE then
            addRectangle(
                rectangles,
                box.X,
                box.Y,
                box.WIDTH,
                box.HEIGHT,
                box.COLOR
            )
        end
    end
    return rectangles
end

local function buildCombinedRectangles(
    blockCount,
    currentHp,
    maximumHp,
    currentMp,
    maximumMp,
    completeOutlineColor
)
    -- Never append to buildHpRectangles() directly. That table is the cached
    -- HP-only image. V1.5 reused it as the frame list, so every MP/LIMIT
    -- refresh permanently appended more records until the 682-record guard
    -- stopped traversal. Every frame now starts with a separate destination.
    local rectangles = {}
    local boxRectangles = buildBoxRectangles()
    local hpRectangles = buildHpRectangles(currentHp, maximumHp)
    local limitRectangles =
        buildLimitRectangles(blockCount, completeOutlineColor)
    local mpRectangles = buildMpRectangles(currentMp, maximumMp)
    appendRectangles(rectangles, boxRectangles)
    appendRectangles(rectangles, hpRectangles)
    appendRectangles(rectangles, limitRectangles)
    appendRectangles(rectangles, mpRectangles)
    return rectangles
end

local function serializeRectangles(rectangles)
    if #rectangles > MAX_RECTANGLES then
        return nil, "generated " .. tostring(#rectangles)
            .. " rectangles; maximum is " .. tostring(MAX_RECTANGLES)
    end

    local bytes = {}
    local index
    for index = 1, #rectangles do
        local rectangle = rectangles[index]
        local leftLow, leftHigh = packedPointParts(
            rectangle.x,
            rectangle.y
        )
        local rightLow, rightHigh = packedPointParts(
            rectangle.x + rectangle.width,
            rectangle.y + rectangle.height
        )
        appendU32(bytes, rectangle.color)
        appendU32(bytes, 0)
        appendU64Parts(bytes, leftLow, leftHigh)
        appendU64Parts(bytes, rightLow, rightHigh)
    end
    return bytes
end

local function labelBytes(
    label,
    originX,
    originY,
    scale,
    sentinel,
    colorOverride
)
    local bytes = {}
    appendU32(bytes, label.ENABLE and 1 or 0)
    appendU32(bytes, round(originX + label.X * scale))
    appendU32(bytes, round(originY + label.Y * scale))
    appendU32(bytes, colorOverride or label.COLOR)
    appendU32(bytes, clamp(round(label.FONT_SIZE * scale), 4, 32))
    local text = tostring(label.TEXT or "")
    local index
    for index = 1, 8 do
        if index <= #text then
            bytes[#bytes + 1] = string.byte(text, index)
        else
            bytes[#bytes + 1] = 0
        end
    end
    appendU32(bytes, sentinel or 0)
    return bytes
end

local function labelRecordsBytes(limitLabelColor)
    local output = {}
    local limitLabel = labelBytes(
        CONFIG.LIMIT_LABEL,
        CONFIG.ORIGIN.X,
        CONFIG.ORIGIN.Y,
        CONFIG.ORIGIN.SCALE,
        LABEL_SENTINEL,
        limitLabelColor
    )
    local mpLabel = labelBytes(
        CONFIG.MP.LABEL,
        0,
        0,
        1,
        LABEL_SENTINEL
    )
    local hpLabel = labelBytes(
        CONFIG.HP.LABEL,
        0,
        0,
        1,
        LABEL_SENTINEL
    )
    local index
    for index = 1, #limitLabel do
        output[#output + 1] = limitLabel[index]
    end
    for index = 1, #mpLabel do
        output[#output + 1] = mpLabel[index]
    end
    for index = 1, #hpLabel do
        output[#output + 1] = hpLabel[index]
    end
    return output
end

local function geometryPointer()
    local pointer = safeReadLong(DATA_POINTER_RVA)
    if not plausibleRuntimeAddress(pointer) then
        return nil
    end
    return pointer
end

local function publishRectangles(rectangles, limitLabelColor)
    local records, reason = serializeRectangles(rectangles)
    if records == nil then
        return false, reason
    end

    local pointer = geometryPointer()
    if pointer == nil then
        return nil, "waiting for the one-time geometry allocation"
    end

    local ok
    local writeReason

    -- FLICKER-SAFE PUBLICATION
    --
    -- v1.4 temporarily wrote a zero rectangle count before every refresh.
    -- At full LIMIT the pulse changes color repeatedly, so the render thread
    -- could observe that zero between LuaBackendHook memory writes and hide
    -- HP, MP, and LIMIT together for one presented frame.
    --
    -- Keep the previous valid count live while the next labels and records
    -- are copied. The new count is committed last. The first publication is
    -- also safe because the allocator initializes the header to zero.
    ok, writeReason =
        safeWriteArrayAbsolute(
            pointer + LABEL_RECORDS_OFFSET,
            labelRecordsBytes(limitLabelColor)
        )
    if not ok then
        return false, "could not publish labels: " .. tostring(writeReason)
    end
    local sentinelBytes = {}
    appendU32(sentinelBytes, DATA_SENTINEL)
    ok, writeReason =
        safeWriteArrayAbsolute(pointer + 4, sentinelBytes)
    if not ok then
        return false, "could not publish geometry sentinel: "
            .. tostring(writeReason)
    end
    ok, writeReason =
        safeWriteArrayAbsolute(
            pointer + RECTANGLE_RECORDS_OFFSET,
            records
        )
    if not ok then
        return false, "could not publish geometry: "
            .. tostring(writeReason)
    end
    local countBytes = {}
    appendU32(countBytes, #rectangles)
    ok, writeReason = safeWriteArrayAbsolute(pointer, countBytes)
    if not ok then
        return false, "could not activate geometry: " .. tostring(writeReason)
    end
    return true, #rectangles
end

-- =========================================================================
-- VALIDATION AND INSTALLATION
-- =========================================================================

local function buildIsExact()
    return safeReadLong(VERSION_SENTINEL_RVA) == VERSION_VALUE
end

local function validateLabel(label, name)
    if type(label) ~= "table"
        or type(label.TEXT) ~= "string"
        or #label.TEXT < 1
        or #label.TEXT > 7
        or string.find(label.TEXT, "[^ -~]") ~= nil
        or type(label.X) ~= "number"
        or type(label.Y) ~= "number"
        or type(label.FONT_SIZE) ~= "number"
        or label.FONT_SIZE < 4
        or label.FONT_SIZE > 32
    then
        return false, name .. " settings are invalid"
    end
    return true
end

local GRADIENT_COLOR_KEYS = {
    "TOP_COLOR",
    "UPPER_COLOR",
    "MIDDLE_COLOR",
    "LOWER_COLOR",
    "BOTTOM_COLOR",
}

local function validateGradient(gradient, name)
    if type(gradient) ~= "table" then
        return false, name .. " must be a five-color table"
    end
    local index
    for index = 1, #GRADIENT_COLOR_KEYS do
        local color = gradient[GRADIENT_COLOR_KEYS[index]]
        if type(color) ~= "number"
            or color < 0
            or color > 4294967295
        then
            return false, name .. "." .. GRADIENT_COLOR_KEYS[index]
                .. " is not a 32-bit AABBGGRR color"
        end
    end
    return true
end

local function validateConfiguration()
    local hp = CONFIG.HP
    if type(hp) ~= "table"
        or type(hp.CENTER_X) ~= "number"
        or type(hp.CENTER_Y) ~= "number"
        or type(hp.SCALE) ~= "number"
        or hp.SCALE <= 0
        or hp.SCALE > 4
        or hp.CURVE_HP ~= 75
        or hp.CURVE_SWEEP_DEGREES ~= 270
        or hp.MAXIMUM_HP ~= 255
        or type(hp.CURVE_RADIUS) ~= "number"
        or hp.CURVE_RADIUS < 4
        or type(hp.STRAIGHT_MAX_LENGTH) ~= "number"
        or hp.STRAIGHT_MAX_LENGTH < 1
        or type(hp.OUTLINE_SIZE) ~= "number"
        or type(hp.INTERIOR_SIZE) ~= "number"
        or type(hp.MIDDLE_SIZE) ~= "number"
        or type(hp.INNER_SIZE) ~= "number"
        or hp.OUTLINE_SIZE <= hp.INTERIOR_SIZE
        or hp.INTERIOR_SIZE <= hp.MIDDLE_SIZE
        or hp.MIDDLE_SIZE <= hp.INNER_SIZE
        or hp.INNER_SIZE < 1
        or type(hp.MIDDLE_INSET) ~= "number"
        or type(hp.INNER_INSET) ~= "number"
        or hp.MIDDLE_INSET < 0
        or hp.INNER_INSET <= hp.MIDDLE_INSET
        or hp.INNER_INSET >= hp.CURVE_RADIUS
    then
        return false, "HP path position/capacity/layer settings are invalid"
    end
    if type(hp.PREVIEW_CURRENT) ~= "number"
        or type(hp.PREVIEW_MAXIMUM) ~= "number"
        or hp.PREVIEW_CURRENT < -1
        or hp.PREVIEW_MAXIMUM < 1
        or hp.PREVIEW_MAXIMUM > hp.MAXIMUM_HP
        or (hp.PREVIEW_CURRENT >= 0
            and hp.PREVIEW_CURRENT > hp.PREVIEW_MAXIMUM)
    then
        return false, "HP preview values are invalid"
    end
    local labelOk, labelReason =
        validateLabel(hp.LABEL, "HP.LABEL")
    if not labelOk then
        return false, labelReason
    end

    local mp = CONFIG.MP
    if type(mp) ~= "table"
        or type(mp.RIGHT_X) ~= "number"
        or type(mp.Y) ~= "number"
        or type(mp.SCALE) ~= "number"
        or mp.SCALE <= 0
        or mp.SCALE > 4
        or type(mp.MINIMUM_MAX_MP) ~= "number"
        or type(mp.MAXIMUM_MAX_MP) ~= "number"
        or mp.MINIMUM_MAX_MP < 1
        or mp.MAXIMUM_MAX_MP > 255
        or mp.MINIMUM_MAX_MP >= mp.MAXIMUM_MAX_MP
        or type(mp.MINIMUM_LENGTH) ~= "number"
        or type(mp.MAXIMUM_LENGTH) ~= "number"
        or mp.MINIMUM_LENGTH < 3
        or mp.MINIMUM_LENGTH >= mp.MAXIMUM_LENGTH
        or type(mp.HEIGHT) ~= "number"
        or type(mp.BORDER) ~= "number"
        or mp.HEIGHT < 3
        or mp.BORDER < 1
        or (mp.EMPTY_DIRECTION ~= "LEFT_TO_RIGHT"
            and mp.EMPTY_DIRECTION ~= "RIGHT_TO_LEFT")
    then
        return false,
            "MP capacity/position/size/depletion settings are invalid"
    end
    local effectiveWidth = round(mp.MINIMUM_LENGTH * mp.SCALE)
    local effectiveHeight = round(mp.HEIGHT * mp.SCALE)
    local effectiveBorder = math.max(1, round(mp.BORDER * mp.SCALE))
    if effectiveWidth - effectiveBorder * 2 < 1
        or effectiveHeight - effectiveBorder * 2 < 5
    then
        return false, "MP bar scale/height must leave a five-pixel interior"
    end
    if type(mp.PREVIEW_CURRENT) ~= "number"
        or type(mp.PREVIEW_MAXIMUM) ~= "number"
        or mp.PREVIEW_CURRENT < -1
        or mp.PREVIEW_MAXIMUM < 1
        or mp.PREVIEW_MAXIMUM > 255
        or (mp.PREVIEW_CURRENT >= 0
            and mp.PREVIEW_CURRENT > mp.PREVIEW_MAXIMUM)
    then
        return false, "MP preview values are invalid"
    end
    labelOk, labelReason = validateLabel(mp.LABEL, "MP.LABEL")
    if not labelOk then
        return false, labelReason
    end
    local gradientOk, gradientReason =
        validateGradient(mp.FILL_GRADIENT, "MP.FILL_GRADIENT")
    if not gradientOk then
        return false, gradientReason
    end
    gradientOk, gradientReason =
        validateGradient(mp.EMPTY_GRADIENT, "MP.EMPTY_GRADIENT")
    if not gradientOk then
        return false, gradientReason
    end
    if type(CONFIG.ORIGIN) ~= "table"
        or type(CONFIG.ORIGIN.X) ~= "number"
        or type(CONFIG.ORIGIN.Y) ~= "number"
        or type(CONFIG.ORIGIN.SCALE) ~= "number"
        or CONFIG.ORIGIN.SCALE <= 0
        or CONFIG.ORIGIN.SCALE > 4
    then
        return false, "ORIGIN X/Y/SCALE is invalid"
    end
    if CONFIG.GAUGE.POINTS_PER_BLOCK ~= 20
        or CONFIG.GAUGE.MAX_BLOCKS ~= 5
    then
        return false, "this exact gauge requires 20 points and five blocks"
    end
    local pulse = CONFIG.FULL_PULSE
    if type(pulse) ~= "table"
        or type(pulse.ENABLE) ~= "boolean"
        or type(pulse.INCLUDE_LIMIT_TEXT) ~= "boolean"
        or type(pulse.CYCLE_SECONDS) ~= "number"
        or pulse.CYCLE_SECONDS < 0.5
        or pulse.CYCLE_SECONDS > 30
        or type(pulse.COLOR_STEPS) ~= "number"
        or pulse.COLOR_STEPS < 2
        or pulse.COLOR_STEPS > 255
        or pulse.COLOR_STEPS ~= math.floor(pulse.COLOR_STEPS)
    then
        return false, "FULL_PULSE settings are invalid"
    end
    if type(CONFIG.LAYOUT) ~= "table"
        or type(CONFIG.LAYOUT.BLOCKS) ~= "table"
        or #CONFIG.LAYOUT.BLOCKS ~= 5
        or type(CONFIG.LAYOUT.BASELINE_Y) ~= "number"
        or type(CONFIG.LAYOUT.OUTLINE) ~= "number"
        or type(CONFIG.LAYOUT.INNER_EDGE) ~= "number"
        or CONFIG.LAYOUT.OUTLINE < 1
        or CONFIG.LAYOUT.INNER_EDGE < 1
    then
        return false, "LAYOUT settings are invalid"
    end
    local index
    if type(CONFIG.BOXES) ~= "table"
        or #CONFIG.BOXES ~= EXACT_BOX_RECTANGLE_COUNT
    then
        return false, "BOXES must contain exactly three adjustable boxes"
    end
    for index = 1, #CONFIG.BOXES do
        local box = CONFIG.BOXES[index]
        if type(box) ~= "table"
            or type(box.ENABLE) ~= "boolean"
            or type(box.X) ~= "number"
            or type(box.Y) ~= "number"
            or type(box.WIDTH) ~= "number"
            or type(box.HEIGHT) ~= "number"
            or box.WIDTH < 1
            or box.HEIGHT < 1
            or box.WIDTH > 4096
            or box.HEIGHT > 4096
            or type(box.COLOR) ~= "number"
            or box.COLOR < 0
            or box.COLOR > 4294967295
        then
            return false, "BOXES[" .. tostring(index)
                .. "] settings are invalid"
        end
    end
    for index = 1, 5 do
        local block = CONFIG.LAYOUT.BLOCKS[index]
        local standardBlock = index < 5
        if type(block) ~= "table"
            or type(block.X) ~= "number"
            or type(block.Y) ~= "number"
            or type(block.WIDTH) ~= "number"
            or block.WIDTH < 8
            or block.Y >= CONFIG.LAYOUT.BASELINE_Y - 4
        then
            return false, "LAYOUT.BLOCKS[" .. tostring(index)
                .. "] is invalid"
        end
        if standardBlock and (
            type(block.GAP_X) ~= "number"
            or type(block.GAP_Y) ~= "number"
            or type(block.GAP_WIDTH) ~= "number"
            or block.GAP_WIDTH < 1
            or block.GAP_Y >= CONFIG.LAYOUT.BASELINE_Y
        ) then
            return false, "LAYOUT.BLOCKS[" .. tostring(index)
                .. "] gap is invalid"
        end
        if not standardBlock and (
            type(block.STEP_Y) ~= "number"
            or type(block.LOWER_WIDTH) ~= "number"
            or block.STEP_Y <= block.Y
            or block.STEP_Y >= CONFIG.LAYOUT.BASELINE_Y
            or block.LOWER_WIDTH < 8
            or block.LOWER_WIDTH >= block.WIDTH
        ) then
            return false, "LAYOUT.BLOCKS[5] step is invalid"
        end
    end
    labelOk, labelReason =
        validateLabel(CONFIG.LIMIT_LABEL, "LIMIT_LABEL")
    if not labelOk then
        return false, labelReason
    end
    local colors = {
        hp.OUTLINE_COLOR,
        hp.EMPTY_OUTER_COLOR,
        hp.EMPTY_MIDDLE_COLOR,
        hp.EMPTY_INNER_COLOR,
        hp.FILL_OUTER_COLOR,
        hp.FILL_MIDDLE_COLOR,
        hp.FILL_INNER_COLOR,
        hp.LABEL.COLOR,
        CONFIG.COLORS.FILLED_EDGE,
        CONFIG.COLORS.FILLED_CENTER,
        CONFIG.COLORS.EMPTY_OUTLINE,
        CONFIG.COLORS.EMPTY_EDGE,
        CONFIG.COLORS.EMPTY_CENTER,
        CONFIG.COLORS.BLACK_BACK,
        CONFIG.LIMIT_LABEL.COLOR,
        mp.BORDER_COLOR,
        mp.LABEL.COLOR,
        pulse.OUTLINE_START_COLOR,
        pulse.OUTLINE_PEAK_COLOR,
        pulse.TEXT_START_COLOR,
        pulse.TEXT_PEAK_COLOR,
    }
    for index = 1, #colors do
        if type(colors[index]) ~= "number"
            or colors[index] < 0
            or colors[index] > 4294967295
        then
            return false, "a gauge color is not a 32-bit AABBGGRR value"
        end
    end
    if type(CONFIG.PREVIEW_LIMIT) ~= "number"
        or CONFIG.PREVIEW_LIMIT < -1
        or CONFIG.PREVIEW_LIMIT > 100
    then
        return false, "PREVIEW_LIMIT must be -1 or 0..100"
    end
    local limitRectangles =
        buildLimitRectangles(5, pulse.OUTLINE_START_COLOR)
    if #limitRectangles ~= EXACT_LIMIT_RECTANGLE_COUNT then
        return false, "exact layout must generate "
            .. tostring(EXACT_LIMIT_RECTANGLE_COUNT)
            .. " LIMIT rectangles"
    end
    local mpRectangles = buildMpRectangles(1, 2)
    if #mpRectangles ~= EXACT_MP_RECTANGLE_COUNT then
        return false, "partial MP bar must generate "
            .. tostring(EXACT_MP_RECTANGLE_COUNT) .. " rectangles"
    end
    local boxRectangles = buildBoxRectangles()
    if #boxRectangles > EXACT_BOX_RECTANGLE_COUNT then
        return false, "adjustable boxes generated too many rectangles"
    end
    local hpRectangles =
        buildHpRectangles(hp.MAXIMUM_HP, hp.MAXIMUM_HP)
    local hpRectangleCount = #hpRectangles
    local combined =
        buildCombinedRectangles(
            5,
            hp.MAXIMUM_HP,
            hp.MAXIMUM_HP,
            1,
            2,
            pulse.OUTLINE_START_COLOR
        )
    local secondCombined =
        buildCombinedRectangles(
            0,
            hp.MAXIMUM_HP,
            hp.MAXIMUM_HP,
            2,
            3,
            nil
        )
    if #hpRectangles ~= hpRectangleCount
        or #combined ~= hpRectangleCount
            + #boxRectangles
            + EXACT_LIMIT_RECTANGLE_COUNT
            + EXACT_MP_RECTANGLE_COUNT
        or #secondCombined ~= #combined
    then
        return false, "fresh-frame assembly did not preserve the HP-only cache"
    end
    if #combined > MAX_RECTANGLES
        or RECTANGLE_RECORDS_OFFSET
            + #combined * RECTANGLE_RECORD_SIZE > LABEL_RECORDS_OFFSET
    then
        return false, "combined geometry exceeds the aligned data buffer"
    end
    if LABEL_RECORD_COUNT ~= 3
        or LABEL_RECORDS_OFFSET ~= 0x3FA0
        or #labelRecordsBytes(pulse.TEXT_START_COLOR)
            ~= LABEL_RECORDS_SIZE
    then
        return false, "three-label heap image is invalid"
    end
    return true
end

local function verifyNativeSignatures()
    if not arraysEqual(
        safeReadArray(DRAW_RECTANGLE_RVA, #DRAW_RECTANGLE_SIGNATURE),
        DRAW_RECTANGLE_SIGNATURE
    ) then
        return false, "native UI rectangle wrapper signature does not match"
    end
    if not arraysEqual(
        safeReadArray(PLAYER_HUD_RVA, #PLAYER_HUD_SIGNATURE),
        PLAYER_HUD_SIGNATURE
    ) then
        return false, "native player-HUD builder signature does not match"
    end
    local nativeSignatures = {
        {
            rva = ALIGNED_MALLOC_CALL_RVA,
            name = "native aligned-allocator call site",
            bytes = {
                0xFF, 0x15, 0x45, 0xAF, 0x2D, 0x00,
            },
        },
        {
            rva = 0x269190,
            name = "native base HUD sprite builder",
            bytes = {
                0x48, 0x8B, 0xC4, 0x56, 0x41, 0x56, 0x48, 0x81,
                0xEC, 0x88, 0x00, 0x00, 0x00, 0x48, 0x89, 0x58,
            },
        },
        {
            rva = 0x2698C0,
            name = "native player HP builder",
            bytes = {
                0x40, 0x53, 0x55, 0x56, 0x57, 0x41, 0x55, 0x41,
                0x56, 0x48, 0x81, 0xEC, 0x28, 0x02, 0x00, 0x00,
            },
        },
        {
            rva = 0x269F50,
            name = "native player MP builder",
            bytes = {
                0x40, 0x53, 0x56, 0x57, 0x48, 0x81, 0xEC, 0x90,
                0x00, 0x00, 0x00, 0x83, 0x39, 0x04, 0x48, 0x8B,
            },
        },
        {
            rva = 0x26A770,
            name = "native MP-charge builder",
            bytes = {
                0x48, 0x89, 0x5C, 0x24, 0x08, 0x48, 0x89, 0x6C,
                0x24, 0x10, 0x48, 0x89, 0x74, 0x24, 0x18, 0x48,
            },
        },
        {
            rva = 0x26CA00,
            name = "native capacity-extension builder",
            bytes = {
                0x48, 0x89, 0x5C, 0x24, 0x08, 0x48, 0x89, 0x6C,
                0x24, 0x10, 0x48, 0x89, 0x74, 0x24, 0x18, 0x57,
            },
        },
        {
            rva = 0x38ADC0,
            name = "native decoded-stat resolver",
            bytes = {
                0x85, 0xC9, 0x75, 0x03, 0x33, 0xC0, 0xC3, 0xE9,
                0x74, 0x01, 0x00, 0x00,
            },
        },
    }
    local signatureIndex
    for signatureIndex = 1, #nativeSignatures do
        local signature = nativeSignatures[signatureIndex]
        if not arraysEqual(
            safeReadArray(signature.rva, #signature.bytes),
            signature.bytes
        ) then
            return false, signature.name .. " signature does not match"
        end
    end
    local fontSignature = {
        0x48, 0x89, 0x5C, 0x24, 0x08, 0x48, 0x89, 0x6C,
        0x24, 0x10, 0x48, 0x89, 0x74, 0x24, 0x18, 0x48,
    }
    if not arraysEqual(
        safeReadArray(0x2CFAF0, #fontSignature),
        fontSignature
    ) then
        return false, "native ASCII font renderer signature does not match"
    end
    local allocator = safeReadLong(ALIGNED_MALLOC_IAT_RVA)
    if not plausibleRuntimeAddress(allocator) then
        return false, "verified aligned allocator import is unavailable"
    end
    return true
end

local function patchState(address, original, custom, name)
    local bytes = safeReadArray(address, #original)
    if arraysEqual(bytes, original) then
        return "native"
    end
    if arraysEqual(bytes, custom) then
        return "owned"
    end
    return nil, name .. " contains unknown bytes"
end

local function privateState()
    local code = safeReadArray(CAVE_RVA, CODE_SIZE)
    if codeImageMatches(code, CAVE_CODE) then
        local caveSentinel = safeReadInt(CAVE_SENTINEL_RVA)
        local pointer = safeReadLong(DATA_POINTER_RVA) or 0
        local pointerOk = pointer == 0 or plausibleRuntimeAddress(pointer)
        if caveSentinel == CAVE_SENTINEL
            and pointerOk then
            if pointer ~= 0 then
                local count = safeReadIntAbsolute(pointer)
                local sentinel = safeReadIntAbsolute(pointer + 4)
                if count == nil
                    or count > MAX_RECTANGLES
                    or (count > 0 and sentinel ~= DATA_SENTINEL)
                then
                    return nil,
                        "owned heap geometry header is invalid"
                end
                if count > 0 then
                    local labelIndex
                    for labelIndex = 0, LABEL_RECORD_COUNT - 1 do
                        local labelSentinel = safeReadIntAbsolute(
                            pointer
                                + LABEL_RECORDS_OFFSET
                                + labelIndex * LABEL_RECORD_SIZE
                                + 0x1C
                        )
                        if labelSentinel ~= LABEL_SENTINEL then
                            return nil,
                                "owned heap label image is invalid"
                        end
                    end
                end
            end
            return "owned"
        end
        return nil, "owned code exists, but its pointer/sentinel is invalid"
    end
    if isZeroArray(code) then
        return "empty"
    end
    return nil, "private Sora HUD bridge region is already in use"
end

local function install()
    local signaturesOk, signaturesReason = verifyNativeSignatures()
    if not signaturesOk then
        return false, signaturesReason
    end

    local patches = {
        {
            address = HP_GAUGE_BYPASS_RVA,
            custom = HP_GAUGE_CUSTOM,
            original = HP_GAUGE_ORIGINAL,
            name = "native HP outline/capacity bypass",
        },
        {
            address = MP_GAUGE_BYPASS_RVA,
            custom = MP_GAUGE_CUSTOM,
            original = MP_GAUGE_ORIGINAL,
            name = "native MP outline/capacity bypass",
        },
        {
            address = MP_FILL_CALL_RVA,
            custom = MP_FILL_CUSTOM,
            original = MP_FILL_ORIGINAL,
            name = "native MP fill bypass",
        },
        {
            address = HP_FILL_CALL_RVA,
            custom = HP_FILL_CUSTOM,
            original = HP_FILL_ORIGINAL,
            name = "native HP fill bypass",
        },
        {
            address = MP_CHARGE_FILL_CALL_RVA,
            custom = MP_CHARGE_FILL_CUSTOM,
            original = MP_CHARGE_FILL_ORIGINAL,
            name = "native MP Charge strip bypass",
        },
        {
            address = CAPACITY_EXTENSION_CALL_RVA,
            custom = CAPACITY_EXTENSION_CUSTOM,
            original = CAPACITY_EXTENSION_ORIGINAL,
            name = "native capacity-extension cap bypass",
        },
        {
            address = BASE_SPRITE_CALL_RVA,
            custom = BASE_SPRITE_CUSTOM,
            original = BASE_SPRITE_ORIGINAL,
            name = "Sora face-only native sprite filter",
        },
        {
            address = SORA_HUD_CALL_RVA,
            custom = SORA_HUD_CALL_CUSTOM,
            original = SORA_HUD_CALL_ORIGINAL,
            name = "player-HUD geometry allocation bridge",
        },
        {
            address = FINAL_RENDER_CALL_RVA,
            custom = FINAL_RENDER_CALL_CUSTOM,
            original = FINAL_RENDER_CALL_ORIGINAL,
            name = "final-render bridge",
        },
        {
            address = POST_LOOP_HOOK_RVA,
            custom = POST_LOOP_HOOK_CUSTOM,
            original = POST_LOOP_HOOK_ORIGINAL,
            name = "post-loop HP/LIMIT/MP renderer",
        },
    }

    local nativeCount = 0
    local ownedCount = 0
    local index
    for index = 1, #patches do
        local patch = patches[index]
        local state, reason = patchState(
            patch.address,
            patch.original,
            patch.custom,
            patch.name
        )
        if state == nil then
            return false, reason
        end
        patch.state = state
        if state == "native" then
            nativeCount = nativeCount + 1
        else
            ownedCount = ownedCount + 1
        end
    end

    local private, privateReason = privateState()
    if private == nil then
        return false, privateReason
    end
    if private == "empty" and nativeCount ~= #patches then
        return false, "HUD patches exist without this controller's code image; fully restart KH1FM"
    end
    if private == "owned" and ownedCount ~= #patches then
        return false, "controller code exists with a partially restored hook; fully restart KH1FM"
    end

    if private == "owned" then
        return true, "verified reload"
    end

    local codeOk, codeReason = safeWriteArray(CAVE_RVA, CAVE_CODE)
    if not codeOk then
        return false, "could not write private code: " .. tostring(codeReason)
    end

    local written = {}
    for index = 1, #patches do
        local patch = patches[index]
        local ok, reason = safeWriteArray(patch.address, patch.custom)
        if not ok then
            local restoreIndex
            for restoreIndex = #written, 1, -1 do
                safeWriteArray(
                    written[restoreIndex].address,
                    written[restoreIndex].original
                )
            end
            safeWriteArray(CAVE_RVA, ZERO_CODE)
            return false, "could not install " .. patch.name
                .. ": " .. tostring(reason)
        end
        written[#written + 1] = patch
    end
    return true, "new installation"
end

-- =========================================================================
-- FRAME UPDATE
-- =========================================================================

local function readLimit()
    if CONFIG.PREVIEW_LIMIT >= 0 then
        return clamp(math.floor(CONFIG.PREVIEW_LIMIT), 0, 100), "preview"
    end
    if safeReadInt(LIMIT_INTERFACE_SENTINEL_RVA)
        ~= LIMIT_INTERFACE_SENTINEL
    then
        return nil
    end
    local value = safeReadInt(LIMIT_VALUE_RVA)
    if value == nil then
        return nil
    end
    return clamp(math.floor(value), 0, 100), "live"
end

local function safeReadByte(address)
    local ok, value = pcall(ReadByte, address)
    if not ok or value == nil then
        return nil
    end
    return tonumber(value)
end

local function readAlwaysLiveStats()
    local sora = safeReadLong(SORA_POINTER_RVA) or 0
    if not plausibleRuntimeAddress(sora) then
        return nil
    end

    local encodedStatPage =
        safeReadIntAbsolute(sora + SORA_STAT_PAGE_OFFSET)
    if encodedStatPage == nil or encodedStatPage == 0 then
        return nil
    end

    local statPage = resolveCompressedPointer(encodedStatPage)
    if not plausibleRuntimeAddress(statPage) then
        return nil
    end

    local currentHp =
        safeReadIntAbsolute(statPage + STAT_CURRENT_HP_OFFSET)
    local maximumHp =
        safeReadIntAbsolute(statPage + STAT_MAXIMUM_HP_OFFSET)
    local currentMp =
        safeReadIntAbsolute(statPage + STAT_CURRENT_MP_OFFSET)
    local maximumMp =
        safeReadIntAbsolute(statPage + STAT_MAXIMUM_MP_OFFSET)
    if currentHp == nil or maximumHp == nil
        or currentMp == nil or maximumMp == nil
        or maximumHp < 1 or maximumHp > CONFIG.HP.MAXIMUM_HP
        or currentHp > maximumHp
        or maximumMp < 1 or maximumMp > 255
        or currentMp > maximumMp
    then
        return nil
    end

    return math.floor(currentHp),
        math.floor(maximumHp),
        math.floor(currentMp),
        math.floor(maximumMp)
end

local function readHp(directCurrent, directMaximum)
    local hp = CONFIG.HP
    if hp.PREVIEW_CURRENT >= 0 then
        return clamp(
            math.floor(hp.PREVIEW_CURRENT),
            0,
            math.floor(hp.PREVIEW_MAXIMUM)
        ), math.floor(hp.PREVIEW_MAXIMUM), "preview"
    end
    if directCurrent ~= nil and directMaximum ~= nil then
        return directCurrent,
            directMaximum,
            "always-live Sora stat page"
    end
    local current = safeReadByte(SORA_BASE_RVA + CURRENT_HP_OFFSET)
    local maximum = safeReadByte(SORA_BASE_RVA + MAX_HP_OFFSET)
    if current ~= nil and maximum ~= nil and maximum >= 1 then
        return clamp(math.floor(current), 0, math.floor(maximum)),
            math.floor(maximum),
            "saved-stat fallback"
    end
    return 0, 1, "waiting for Sora HP data"
end

local function readMp(directCurrent, directMaximum)
    local mp = CONFIG.MP
    if mp.PREVIEW_CURRENT >= 0 then
        return clamp(
            math.floor(mp.PREVIEW_CURRENT),
            0,
            math.floor(mp.PREVIEW_MAXIMUM)
        ), math.floor(mp.PREVIEW_MAXIMUM), "preview"
    end

    -- Primary source: the same live Sora stat page used by MP Haste/Rage v6.
    -- This path updates in exploration, combat, and every other active
    -- gameplay state; it does not depend on the native MP HUD builder running.
    if directCurrent ~= nil and directMaximum ~= nil then
        return directCurrent,
            directMaximum,
            "always-live Sora stat page"
    end

    local current = safeReadByte(SORA_BASE_RVA + CURRENT_MP_OFFSET)
    local maximum = safeReadByte(SORA_BASE_RVA + MAX_MP_OFFSET)
    if current ~= nil and maximum ~= nil and maximum >= 1 then
        return clamp(math.floor(current), 0, math.floor(maximum)),
            math.floor(maximum),
            "saved-stat fallback"
    end
    return 0, 1, "waiting for Sora MP data"
end

local function updateGauge()
    if geometryPointer() == nil then
        if not runtime.geometryWaitingLogged then
            runtime.geometryWaitingLogged = true
            log("WAITING: the player HUD has not allocated its geometry buffer yet.")
        end
        return true
    end
    if runtime.geometryWaitingLogged then
        runtime.geometryWaitingLogged = false
        log("ACTIVE: aligned HP/MP/LIMIT geometry buffer is ready.")
    end

    local limit, limitSource = readLimit()
    if limit == nil then
        limit = 0
        limitSource = "waiting"
        if not runtime.waitingLimitLogged then
            runtime.waitingLimitLogged = true
            log("WAITING: LIMIT v1.6 published interface is not active yet.")
        end
    else
        runtime.waitingLimitLogged = false
    end

    local blocks = math.floor(limit / CONFIG.GAUGE.POINTS_PER_BLOCK)
    blocks = clamp(blocks, 0, CONFIG.GAUGE.MAX_BLOCKS)
    local directCurrentHp, directMaximumHp, directCurrentMp, directMaximumMp =
        readAlwaysLiveStats()
    local currentHp, maximumHp, hpSource =
        readHp(directCurrentHp, directMaximumHp)
    local currentMp, maximumMp, mpSource =
        readMp(directCurrentMp, directMaximumMp)
    if mpSource == "always-live Sora stat page"
        and not runtime.directMpLogged
    then
        runtime.directMpLogged = true
        log("MP SOURCE: always-live Sora stat page is active; no combat gate.")
    end

    local completeOutlineColor = nil
    local completeLabelColor = nil
    if blocks >= CONFIG.GAUGE.MAX_BLOCKS then
        if runtime.lastBlocks ~= CONFIG.GAUGE.MAX_BLOCKS then
            runtime.pulseFrame = 0
        else
            runtime.pulseFrame = runtime.pulseFrame + 1
        end
        completeOutlineColor, completeLabelColor = fullPulseColors()
    else
        runtime.pulseFrame = 0
    end

    if blocks == runtime.lastBlocks
        and currentHp == runtime.lastCurrentHp
        and maximumHp == runtime.lastMaximumHp
        and currentMp == runtime.lastCurrentMp
        and maximumMp == runtime.lastMaximumMp
        and completeOutlineColor == runtime.lastFullOutlineColor
        and completeLabelColor == runtime.lastFullLabelColor
    then
        return true
    end

    local rectangles =
        buildCombinedRectangles(
            blocks,
            currentHp,
            maximumHp,
            currentMp,
            maximumMp,
            completeOutlineColor
        )
    local ok, result =
        publishRectangles(rectangles, completeLabelColor)
    if ok == nil then
        return true
    end
    if not ok then
        return false, result
    end
    runtime.lastBlocks = blocks
    runtime.lastCurrentHp = currentHp
    runtime.lastMaximumHp = maximumHp
    runtime.lastCurrentMp = currentMp
    runtime.lastMaximumMp = maximumMp
    runtime.lastFullOutlineColor = completeOutlineColor
    runtime.lastFullLabelColor = completeLabelColor
    if CONFIG.LOG_VALUE_CHANGES
        or limitSource == "preview"
        or hpSource == "preview"
        or mpSource == "preview"
    then
        log("DISPLAY: LIMIT=" .. tostring(limit)
            .. " blocks=" .. tostring(blocks)
            .. " HP=" .. tostring(currentHp)
            .. "/" .. tostring(maximumHp)
            .. " MP=" .. tostring(currentMp)
            .. "/" .. tostring(maximumMp)
            .. " rectangles=" .. tostring(result)
            .. " limit_source=" .. tostring(limitSource)
            .. " hp_source=" .. tostring(hpSource)
            .. " mp_source=" .. tostring(mpSource) .. ".")
    end
    return true
end

function _OnInit()
    if ENGINE_TYPE ~= "BACKEND" then
        runtime.stopped = true
        return
    end
    log("Initialization complete; waiting for the exact Steam Global build.")
end

function _OnFrame()
    if runtime.stopped then
        return
    end

    if not runtime.installed then
        if not CONFIG.ENABLE then
            runtime.stopped = true
            log("DISABLED: CONFIG.ENABLE is false; no executable byte was changed.")
            return
        end
        if not buildIsExact() then
            if not runtime.waitingBuildLogged then
                runtime.waitingBuildLogged = true
                log("WAITING: exact Steam Global build sentinel is not active.")
            end
            return
        end

        local configOk, configReason = validateConfiguration()
        if not configOk then
            runtime.stopped = true
            log("CONFIG REFUSED: " .. tostring(configReason)
                .. ". No executable byte was changed.")
            return
        end

        local installOk, installReason = install()
        if not installOk then
            runtime.stopped = true
            log("INSTALL REFUSED: " .. tostring(installReason)
                .. ". Unknown executable bytes were not overwritten.")
            return
        end

        runtime.installed = true
        log("READY: smooth circular HP + always-live custom MP + exact pulsing LIMIT HUD; "
            .. tostring(installReason) .. ".")
        log("NATIVE HP REMOVED: outline, capacity, fill, backing layer, and label.")
        log("NATIVE MP REMOVED: outline, fill, charge strip, capacity caps, layer, and label.")
        log("NATIVE HUD PRESERVED: Sora face image and every non-Sora HUD sprite.")
        log("HP LAYOUT: center X=" .. tostring(CONFIG.HP.CENTER_X)
            .. " Y=" .. tostring(CONFIG.HP.CENTER_Y)
            .. " radius=" .. tostring(CONFIG.HP.CURVE_RADIUS)
            .. " curve=1.." .. tostring(CONFIG.HP.CURVE_HP)
            .. " straight=" .. tostring(CONFIG.HP.CURVE_HP + 1)
            .. ".." .. tostring(CONFIG.HP.MAXIMUM_HP)
            .. " scale=" .. tostring(CONFIG.HP.SCALE)
            .. " LABEL=\"" .. tostring(CONFIG.HP.LABEL.TEXT) .. "\".")
        log("AUXILIARY BOXES: three independently adjustable 12x12 black boxes are enabled.")
        log("MP LAYOUT: RIGHT_X=" .. tostring(CONFIG.MP.RIGHT_X)
            .. " Y=" .. tostring(CONFIG.MP.Y)
            .. " LENGTH="
            .. tostring(CONFIG.MP.MINIMUM_LENGTH)
            .. ".." .. tostring(CONFIG.MP.MAXIMUM_LENGTH)
            .. " FOR MAX_MP="
            .. tostring(CONFIG.MP.MINIMUM_MAX_MP)
            .. ".." .. tostring(CONFIG.MP.MAXIMUM_MAX_MP)
            .. " HEIGHT=" .. tostring(CONFIG.MP.HEIGHT)
            .. " SCALE=" .. tostring(CONFIG.MP.SCALE)
            .. " EMPTY_DIRECTION="
            .. tostring(CONFIG.MP.EMPTY_DIRECTION)
            .. " LABEL=\"" .. tostring(CONFIG.MP.LABEL.TEXT) .. "\".")
        log("LIMIT LAYOUT: base origin X=" .. tostring(CONFIG.ORIGIN.X)
            .. " Y=" .. tostring(CONFIG.ORIGIN.Y)
            .. " SCALE=" .. tostring(CONFIG.ORIGIN.SCALE) .. ".")
        log("THRESHOLDS: 20, 40, 60, 80, and 100 LIMIT.")
        log("FULL LIMIT: outline and LIMIT text pulse together every "
            .. tostring(CONFIG.FULL_PULSE.CYCLE_SECONDS)
            .. " seconds; speed and colors are adjustable; mechanics are unchanged.")
        log("STABLE FRAME ASSEMBLY: cached HP geometry remains HP-only; "
            .. "frame capacity=" .. tostring(MAX_RECTANGLES)
            .. " rectangles and labels use separate heap records.")
    end

    local updateOk, updateReason = updateGauge()
    if not updateOk then
        runtime.stopped = true
        local pointer = geometryPointer()
        if pointer ~= nil then
            safeWriteArrayAbsolute(pointer, { 0, 0, 0, 0 })
        end
        log("STOPPED: " .. tostring(updateReason)
            .. ". Rectangle traversal was suspended.")
    end
end
