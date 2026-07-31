LUAGUI_NAME = "KH1FM Custom MP Bar + LIMIT Gauge v1.2"
LUAGUI_AUTH = "OpenAI"
LUAGUI_DESC = "Max-MP-scaled custom bar plus exact five-slot LIMIT gauge with synchronized outline/text pulsing."

--[[
    KH1FM CUSTOM MP BAR + LIMIT GAUGE v1.2
    Target: KINGDOM HEARTS FINAL MIX.exe, Steam Global 1.0.0.2
    SHA-256: d790746245d26159f3ee0e1060e33b2fa2de06941850a4ac724f598722884bac
    Runtime: LuaBackendHook v1.9.1-hook / LuaEngine v5.0

    PURPOSE
      * Removes Sora's native MP gauge, MP Charge strip, MP capacity packets,
        and native MP label.
      * Draws a separate proportional MP bar based on the supplied 10-MP and
        255-MP empty/full references.
      * The bar's right edge stays fixed. Capacity is exactly 7x7 at 10 maximum
        MP and exactly 179x7 at 255 maximum MP, with every intermediate maximum
        interpolated continuously. Capacity growth therefore extends left.
      * Current MP fills only the capacity that exists for Sora's live maximum.
        EMPTY_DIRECTION can make spent MP empty from left to right or from
        right to left.
      * The empty and filled interiors use separately editable five-stop
        top-to-bottom gradients sampled from the supplied references.
      * Position, scale, minimum/maximum length, height, colors, depletion
        direction, label text, label position, label color, and font size are
        editable in CONFIG.MP.
      * Keeps Sora's native portrait and main HP gauge.
      * Retains the five 20-point LIMIT thresholds and reconstructs the new
        supplied 0, 80, and 100 references exactly.
      * At 20..80, filled slots are red inside the normal gray/black backs.
        At 100, all five red slots switch to a teal outline.
      * While LIMIT remains at 100, the teal outline and the LIMIT text pulse
        together to white and back. Pulse enable, speed, steps, independent
        outline/text endpoint colors, and text inclusion are editable without
        changing LIMIT mechanics.
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
      * Replaces Custom MP Bar + LIMIT Gauge v1/v1.1 and LIMIT Gauge v2.2; do
        not enable any of those older scripts at the same time.
      * Provides the two pass-through signatures required by Enemy HP HUD v4.1.
      * Owns module+0x3AF300..0x3AF700, module+0x3AFE00..0x3AFE40,
        the proven post-loop hook, and MP-only suppression sites.
      * Leaves Enemy HP HUD v4.1's module+0x3AF700..0x3AFE00 region untouched.
      * Leaves LIMIT v1.6's module+0x3AFE40..0x3B0000 region untouched.
      * Does not touch EnemyConfig, MP Haste/Rage, equipment bonuses, damage,
        animation, movement, BGM, or enemy data.

    Disable Custom MP Bar + LIMIT Gauge v1/v1.1, LIMIT Gauge v2.2, and every
    older Numeric, Graphic, and Texture Sora HUD before using this file.
    Fully restart KH1FM; do not switch to it with F1.
]]

-- =========================================================================
-- EASY SETTINGS -- EDIT THIS BLOCK ONLY
-- =========================================================================

local CONFIG = {
    ENABLE = true,
    LOG_VALUE_CHANGES = false,

    -- Custom MP bar. Coordinates use KH1's native 640x448 HUD space.
    MP = {
        -- RIGHT_X is the fixed exclusive right edge. Capacity growth extends
        -- left from this point, matching all four supplied references.
        RIGHT_X = 208,
        Y = 149,
        SCALE = 1.00,

        -- Capacity interpolation endpoints. Defaults match the references:
        -- Max MP 10  -> outer width
        -- Max MP 255 -> outer width
        MINIMUM_MAX_MP = 10,
        MAXIMUM_MAX_MP = 255,
        MINIMUM_LENGTH = 10,
        MAXIMUM_LENGTH = 255,

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
            -- Kept to the right of the fixed bar endpoint.
            X = 464,
            Y = 340,
            COLOR = 0x80E41853,
            FONT_SIZE = 8,
        },

        -- Visual-only live-value override.
        -- PREVIEW_CURRENT=-1 uses live MP. Otherwise use 0..PREVIEW_MAXIMUM.
        PREVIEW_CURRENT = -1,
        PREVIEW_MAXIMUM = 255,
    },

    -- Exact base placement from the three supplied 640x448 references.
    ORIGIN = {
        X = 158,
        Y = 129,
        SCALE = 0.50,
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
        X = 30,
        Y = 144,
        COLOR = 0x800000FF,
        FONT_SIZE = 10,
    },

    COLORS = {
        -- KH1 HUD colors use AABBGGRR; 0x80 is full native HUD opacity.
        -- These are the exact RGB values sampled from the references.
        FILLED_EDGE = 0x800000B5,    -- RGB 181,0,0
        FILLED_CENTER = 0x802A14E2,  -- RGB 226,20,42
        EMPTY_OUTLINE = 0x804A4A4A,
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
        OUTLINE_PEAK_COLOR = 0x802A14E2,  -- RGB 226,20,42
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

local PREFIX = "[CustomMpLimitV1.2] "

local VERSION_SENTINEL_RVA = 0x3B2271
local VERSION_VALUE = 0x7265737563697065

local LIMIT_VALUE_RVA = 0x3AFEE0
local LIMIT_INTERFACE_SENTINEL_RVA = 0x3AFFC8
local LIMIT_INTERFACE_SENTINEL = 0x4C494D36

local SORA_BASE_RVA = 0x2DE9364
local CURRENT_MP_OFFSET = 0x03
local MAX_MP_OFFSET = 0x04

-- Always-live Sora object/stat-page path verified by MP Haste/Rage v6.
local SORA_POINTER_RVA = 0x2537E48
local POINTER_BANK_TABLE_RVA = 0x2EE3980
local SORA_STAT_PAGE_OFFSET = 0x6C
local STAT_CURRENT_HP_OFFSET = 0x3C
local STAT_CURRENT_MP_OFFSET = 0x44
local STAT_MAXIMUM_MP_OFFSET = 0x48

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

-- Sora base-sprite entry 1 is the remaining native MP layer and entry 5 is
-- the native MP label. All other Sora and non-Sora base sprites pass through.
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

local CAVE_RVA = 0x3AF300
local CODE_SIZE = 0x100
local DATA_RVA = 0x3AF400
local DATA_SIZE = 0x300
local AUX_RVA = 0x3AFE00
local AUX_SIZE = 0x40
local DATA_SENTINEL = 0x31504D43
local AUX_SENTINEL = 0x31585541
local RECTANGLE_RECORDS_OFFSET = 0x08
local RECTANGLE_RECORD_SIZE = 0x18
local MAX_RECTANGLES = 31
local EXACT_LIMIT_RECTANGLE_COUNT = 22
local EXACT_MP_RECTANGLE_COUNT = 9
local LABEL_RECORD_SIZE = 0x20
local CAPTURE_CURRENT_MP_RVA = CAVE_RVA + 0x78
local CAPTURE_MAXIMUM_MP_RVA = CAVE_RVA + 0x7C

-- Assembled for module+0x3AF300. It contains:
--   +0x000 equipment-adjusted live MP capture + player-HUD pass-through
--   +0x048 Sora-only native MP layer/label filter
--   +0x078 captured current/max MP dwords
--   +0x080 minimal final-render pass-through
--   +0x088 post-loop LIMIT/MP rectangle traversal and two-label loop
local CAVE_CODE = {
    0x53, 0x48, 0x83, 0xEC, 0x20, 0x48, 0x89, 0xCB, 0x48, 0x8B, 0x41, 0x08, 0x48, 0x85, 0xC0, 0x74,
    0x23, 0x8B, 0x48, 0x6C, 0x85, 0xC9, 0x74, 0x1C, 0xE8, 0xA3, 0xBA, 0xFD, 0xFF, 0x48, 0x85, 0xC0,
    0x74, 0x12, 0x8B, 0x48, 0x44, 0x89, 0x0D, 0x4D, 0x00, 0x00, 0x00, 0x8B, 0x48, 0x48, 0x89, 0x0D,
    0x48, 0x00, 0x00, 0x00, 0x48, 0x89, 0xD9, 0xE8, 0x54, 0xDC, 0xEB, 0xFF, 0x48, 0x83, 0xC4, 0x20,
    0x5B, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x83, 0x3E, 0x00, 0x75, 0x0C, 0x48, 0x83, 0xFB,
    0x01, 0x74, 0x0B, 0x48, 0x83, 0xFB, 0x05, 0x74, 0x05, 0xE9, 0x32, 0xDB, 0xEB, 0xFF, 0x4C, 0x89,
    0xF0, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xE9, 0xEB, 0x00, 0xED, 0xFF, 0x00, 0x00, 0x00, 0x53, 0x56, 0x48, 0x83, 0xEC, 0x30, 0x8B, 0x1D,
    0x6C, 0x00, 0x00, 0x00, 0x85, 0xDB, 0x74, 0x1E, 0x48, 0x8D, 0x35, 0x69, 0x00, 0x00, 0x00, 0x8B,
    0x0E, 0x48, 0x8B, 0x56, 0x08, 0x4C, 0x8B, 0x46, 0x10, 0xE8, 0xE2, 0x72, 0xD9, 0xFF, 0x48, 0x83,
    0xC6, 0x18, 0xFF, 0xCB, 0x75, 0xE9, 0xBB, 0x02, 0x00, 0x00, 0x00, 0x48, 0x8D, 0x35, 0x3E, 0x0A,
    0x00, 0x00, 0x83, 0x3E, 0x00, 0x74, 0x1A, 0x8B, 0x4E, 0x0C, 0x8B, 0x56, 0x04, 0x44, 0x8B, 0x46,
    0x08, 0x4C, 0x8D, 0x4E, 0x14, 0x8B, 0x46, 0x10, 0x89, 0x44, 0x24, 0x20, 0xE8, 0x0F, 0x07, 0xF2,
    0xFF, 0x48, 0x83, 0xC6, 0x20, 0xFF, 0xCB, 0x75, 0xD9, 0x48, 0x83, 0xC4, 0x30, 0x5E, 0x5B, 0x0F,
    0x28, 0xBC, 0x24, 0xA0, 0x00, 0x00, 0x00, 0xE9, 0x34, 0xEC, 0xEB, 0xFF, 0x00, 0x00, 0x00, 0x00,
}

local ZERO_CODE = {}
local ZERO_DATA = {}
local ZERO_AUX = {}
local zeroIndex
for zeroIndex = 1, CODE_SIZE do
    ZERO_CODE[zeroIndex] = 0
end
for zeroIndex = 1, DATA_SIZE do
    ZERO_DATA[zeroIndex] = 0
end
for zeroIndex = 1, AUX_SIZE do
    ZERO_AUX[zeroIndex] = 0
end

local runtime = {
    installed = false,
    stopped = false,
    waitingBuildLogged = false,
    waitingLimitLogged = false,
    lastBlocks = nil,
    lastCurrentMp = nil,
    lastMaximumMp = nil,
    lastFullOutlineColor = nil,
    lastFullLabelColor = nil,
    pulseFrame = 0,
    directMpLogged = false,
    effectiveMpLogged = false,
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
    for index = 1, #right do
        local offset = index - 1
        if (offset < 0x78 or offset > 0x7F)
            and left[index] ~= right[index]
        then
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
-- LIMIT BLOCK GEOMETRY
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

local function buildCombinedRectangles(
    blockCount,
    currentMp,
    maximumMp,
    completeOutlineColor
)
    local rectangles =
        buildLimitRectangles(blockCount, completeOutlineColor)
    local mpRectangles = buildMpRectangles(currentMp, maximumMp)
    local index
    for index = 1, #mpRectangles do
        rectangles[#rectangles + 1] = mpRectangles[index]
    end
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

local function auxiliaryBytes(limitLabelColor)
    local output = {}
    local limitLabel = labelBytes(
        CONFIG.LIMIT_LABEL,
        CONFIG.ORIGIN.X,
        CONFIG.ORIGIN.Y,
        CONFIG.ORIGIN.SCALE,
        AUX_SENTINEL,
        limitLabelColor
    )
    local mpLabel = labelBytes(
        CONFIG.MP.LABEL,
        0,
        0,
        1,
        AUX_SENTINEL
    )
    local index
    for index = 1, #limitLabel do
        output[#output + 1] = limitLabel[index]
    end
    for index = 1, #mpLabel do
        output[#output + 1] = mpLabel[index]
    end
    return output
end

local function publishRectangles(rectangles, limitLabelColor)
    local records, reason = serializeRectangles(rectangles)
    if records == nil then
        return false, reason
    end

    local image = {}
    local index
    for index = 1, DATA_SIZE do
        image[index] = 0
    end
    local header = {}
    appendU32(header, 0)
    appendU32(header, DATA_SENTINEL)
    for index = 1, #header do
        image[index] = header[index]
    end
    for index = 1, #records do
        image[RECTANGLE_RECORDS_OFFSET + index] = records[index]
    end
    local ok
    local writeReason
    ok, writeReason = safeWriteArray(DATA_RVA, { 0, 0, 0, 0 })
    if not ok then
        return false, "could not suspend traversal: " .. tostring(writeReason)
    end
    ok, writeReason =
        safeWriteArray(AUX_RVA, auxiliaryBytes(limitLabelColor))
    if not ok then
        return false, "could not publish labels: " .. tostring(writeReason)
    end
    ok, writeReason = safeWriteArray(DATA_RVA, image)
    if not ok then
        return false, "could not publish geometry: " .. tostring(writeReason)
    end
    local countBytes = {}
    appendU32(countBytes, #rectangles)
    ok, writeReason = safeWriteArray(DATA_RVA, countBytes)
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
    local labelOk, labelReason =
        validateLabel(mp.LABEL, "MP.LABEL")
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
    local combined =
        buildCombinedRectangles(
            5,
            mp.MINIMUM_MAX_MP,
            mp.MAXIMUM_MAX_MP,
            pulse.OUTLINE_START_COLOR
        )
    if #combined > MAX_RECTANGLES
        or RECTANGLE_RECORDS_OFFSET
            + #combined * RECTANGLE_RECORD_SIZE > DATA_SIZE
    then
        return false, "combined geometry exceeds the private data cache"
    end
    if LABEL_RECORD_SIZE * 2 ~= AUX_SIZE
        or #auxiliaryBytes(pulse.TEXT_START_COLOR) ~= AUX_SIZE
    then
        return false, "two-label auxiliary image is invalid"
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
            rva = 0x269190,
            name = "native base HUD sprite builder",
            bytes = {
                0x48, 0x8B, 0xC4, 0x56, 0x41, 0x56, 0x48, 0x81,
                0xEC, 0x88, 0x00, 0x00, 0x00, 0x48, 0x89, 0x58,
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
        local sentinel = safeReadInt(DATA_RVA + 4)
        local auxiliarySentinel = safeReadInt(AUX_RVA + 0x1C)
        local count = safeReadInt(DATA_RVA)
        if sentinel == DATA_SENTINEL
            and auxiliarySentinel == AUX_SENTINEL
            and count ~= nil
            and count <= MAX_RECTANGLES
        then
            return "owned"
        end
        return nil, "owned code exists, but its data sentinel is invalid"
    end
    if isZeroArray(code) then
        local data = safeReadArray(DATA_RVA, DATA_SIZE)
        local auxiliary = safeReadArray(AUX_RVA, AUX_SIZE)
        if isZeroArray(data) and isZeroArray(auxiliary) then
            return "empty"
        end
        return nil, "private data or label region is already in use"
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
            name = "native MP layer/label filter",
        },
        {
            address = SORA_HUD_CALL_RVA,
            custom = SORA_HUD_CALL_CUSTOM,
            original = SORA_HUD_CALL_ORIGINAL,
            name = "player-HUD MP capture bridge",
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
            name = "post-loop LIMIT/MP renderer",
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
    local dataOk, dataReason =
        publishRectangles(
            buildCombinedRectangles(
                0,
                0,
                CONFIG.MP.MINIMUM_MAX_MP,
                CONFIG.FULL_PULSE.OUTLINE_START_COLOR
            ),
            CONFIG.LIMIT_LABEL.COLOR
        )
    if not dataOk then
        safeWriteArray(AUX_RVA, ZERO_AUX)
        safeWriteArray(CAVE_RVA, ZERO_CODE)
        return false, dataReason
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
            safeWriteArray(DATA_RVA, ZERO_DATA)
            safeWriteArray(AUX_RVA, ZERO_AUX)
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

local function readAlwaysLiveMp()
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
    local currentMp =
        safeReadIntAbsolute(statPage + STAT_CURRENT_MP_OFFSET)
    local maximumMp =
        safeReadIntAbsolute(statPage + STAT_MAXIMUM_MP_OFFSET)
    if currentHp == nil or currentMp == nil or maximumMp == nil
        or currentHp < 1 or currentHp > 9999
        or maximumMp < 1 or maximumMp > 255
        or currentMp > maximumMp
    then
        return nil
    end

    return math.floor(currentMp), math.floor(maximumMp)
end

local function readMp()
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
    local current, maximum = readAlwaysLiveMp()
    if current ~= nil and maximum ~= nil then
        return current, maximum, "always-live Sora stat page"
    end

    -- First fallback: the native player-HUD capture retained for compatibility.
    current = safeReadInt(CAPTURE_CURRENT_MP_RVA)
    maximum = safeReadInt(CAPTURE_MAXIMUM_MP_RVA)
    if current ~= nil and maximum ~= nil
        and current >= 0 and current <= 999
        and maximum >= 1 and maximum <= 999
    then
        return clamp(math.floor(current), 0, math.floor(maximum)),
            math.floor(maximum),
            "equipment-adjusted runtime stats"
    end

    current = safeReadByte(SORA_BASE_RVA + CURRENT_MP_OFFSET)
    maximum = safeReadByte(SORA_BASE_RVA + MAX_MP_OFFSET)
    if current ~= nil and maximum ~= nil and maximum >= 1 then
        return clamp(math.floor(current), 0, math.floor(maximum)),
            math.floor(maximum),
            "saved-stat fallback"
    end
    return 0, 1, "waiting for Sora MP data"
end

local function updateGauge()
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
    local currentMp, maximumMp, mpSource = readMp()
    if mpSource == "always-live Sora stat page"
        and not runtime.directMpLogged
    then
        runtime.directMpLogged = true
        log("MP SOURCE: always-live Sora stat page is active; no combat gate.")
    elseif mpSource == "equipment-adjusted runtime stats"
        and not runtime.effectiveMpLogged
    then
        runtime.effectiveMpLogged = true
        log("MP FALLBACK: native HUD capture is active.")
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
            currentMp,
            maximumMp,
            completeOutlineColor
        )
    local ok, result =
        publishRectangles(rectangles, completeLabelColor)
    if not ok then
        return false, result
    end
    runtime.lastBlocks = blocks
    runtime.lastCurrentMp = currentMp
    runtime.lastMaximumMp = maximumMp
    runtime.lastFullOutlineColor = completeOutlineColor
    runtime.lastFullLabelColor = completeLabelColor
    if CONFIG.LOG_VALUE_CHANGES
        or limitSource == "preview"
        or mpSource == "preview"
    then
        log("DISPLAY: LIMIT=" .. tostring(limit)
            .. " blocks=" .. tostring(blocks)
            .. " MP=" .. tostring(currentMp)
            .. "/" .. tostring(maximumMp)
            .. " rectangles=" .. tostring(result)
            .. " limit_source=" .. tostring(limitSource)
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
        log("READY: always-live custom MP bar + exact pulsing five-slot LIMIT gauge; "
            .. tostring(installReason) .. ".")
        log("NATIVE MP REMOVED: outline, fill, charge strip, capacity caps, layer, and label.")
        log("NATIVE HUD PRESERVED: Sora portrait, main HP gauge, and all non-MP base sprites.")
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
    end

    local updateOk, updateReason = updateGauge()
    if not updateOk then
        runtime.stopped = true
        safeWriteArray(DATA_RVA, { 0, 0, 0, 0 })
        log("STOPPED: " .. tostring(updateReason)
            .. ". Rectangle traversal was suspended.")
    end
end
