LUAGUI_NAME = "KH1FM LIMIT Gauge v1 Native Geometry"
LUAGUI_AUTH = "OpenAI"
LUAGUI_DESC = "Adds five discrete teal-and-pink LIMIT chunks without replacing Sora's native HUD or any texture."

--[[
    KH1FM LIMIT GAUGE v1 -- NATIVE GEOMETRY
    Target: KINGDOM HEARTS FINAL MIX.exe, Steam Global 1.0.0.2
    SHA-256: d790746245d26159f3ee0e1060e33b2fa2de06941850a4ac724f598722884bac
    Runtime: LuaBackendHook v1.9.1-hook / LuaEngine v5.0

    PURPOSE
      * Adds only the five-block LIMIT gauge.
      * Leaves Sora's native portrait, HP gauge, MP gauge, labels, textures,
        and all native player-HUD packets untouched.
      * Uses KH1's native solid-rectangle renderer after the complete player
        HUD loop. No DDS replacement, UV remap, resource capture, or sprite
        suppression is involved.
      * Reads the published LIMIT v1.6 interface without changing LIMIT.

    DISCRETE FILL
          0..19   = no blocks
         20..39   = block 1
         40..59   = blocks 1-2
         60..79   = blocks 1-3
         80..99   = blocks 1-4
        100       = blocks 1-5

    COMPATIBILITY
      * Provides the two minimal pass-through signatures required by Enemy HP
        HUD v4.1, but does not draw numeric Sora HP/MP.
      * Owns module+0x3AF300..0x3AF700 and module+0x26E028 only.
      * Leaves Enemy HP HUD v4.1's module+0x3AF700..0x3AFE00 region untouched.
      * Leaves LIMIT v1.6's module+0x3AFEE0 interface untouched.
      * Does not touch EnemyConfig, MP Haste/Rage, equipment bonuses, damage,
        animation, movement, BGM, or enemy data.

    Disable every older Numeric, Graphic, and Texture Sora HUD before using
    this file. Fully restart KH1FM; do not switch to it with F1.
]]

-- =========================================================================
-- EASY SETTINGS -- EDIT THIS BLOCK ONLY
-- =========================================================================

local CONFIG = {
    ENABLE = true,
    LOG_VALUE_CHANGES = false,

    -- Exact native 640x448 coordinates reconstructed from
    -- "Limit Fill 5 Blocks(3).png".
    GAUGE = {
        X = 0,
        Y = 0,
        SCALE = 1.0,
    },

    -- KH1 HUD colors are AABBGGRR; 0x80 is full native HUD opacity.
    OUTLINE_COLOR = 0x80F4FF7E,
    FILL_EDGE_COLOR = 0x80C200EE,
    FILL_CENTER_COLOR = 0x803F00EE,

    POINTS_PER_BLOCK = 20,
    MAX_BLOCKS = 5,

    -- Visual-only test. -1 uses live LIMIT. Set to 100 to force all five
    -- blocks without changing gameplay LIMIT, then return it to -1.
    PREVIEW_LIMIT = -1,
}

-- =========================================================================
-- VERIFIED BUILD CONSTANTS -- DO NOT EDIT
-- =========================================================================

local PREFIX = "[LimitGaugeV1] "

local VERSION_SENTINEL_RVA = 0x3B2271
local VERSION_VALUE = 0x7265737563697065

local LIMIT_VALUE_RVA = 0x3AFEE0
local LIMIT_INTERFACE_SENTINEL_RVA = 0x3AFFC8
local LIMIT_INTERFACE_SENTINEL = 0x4C494D36

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
local DATA_SENTINEL = 0x314D494C
local RECTANGLE_RECORDS_OFFSET = 0x08
local RECTANGLE_RECORD_SIZE = 0x18
local MAX_RECTANGLES = 31

-- Assembled for module+0x3AF300. It contains:
--   +0x000 minimal native player-HUD pass-through
--   +0x080 minimal final-render pass-through
--   +0x088 post-loop LIMIT rectangle traversal
local CAVE_CODE = {
    0x53, 0x48, 0x83, 0xEC, 0x20, 0x48, 0x89, 0xCB, 0x48, 0x8B, 0x41, 0x08, 0x48, 0x85, 0xC0, 0x74,
    0x00, 0x48, 0x89, 0xD9, 0xE8, 0x77, 0xDC, 0xEB, 0xFF, 0x48, 0x83, 0xC4, 0x20, 0x5B, 0xC3, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xE9, 0xEB, 0x00, 0xED, 0xFF, 0x00, 0x00, 0x00, 0x53, 0x56, 0x48, 0x83, 0xEC, 0x30, 0x8B, 0x1D,
    0x6C, 0x00, 0x00, 0x00, 0x85, 0xDB, 0x74, 0x1E, 0x48, 0x8D, 0x35, 0x69, 0x00, 0x00, 0x00, 0x8B,
    0x0E, 0x48, 0x8B, 0x56, 0x08, 0x4C, 0x8B, 0x46, 0x10, 0xE8, 0xE2, 0x72, 0xD9, 0xFF, 0x48, 0x83,
    0xC6, 0x18, 0xFF, 0xCB, 0x75, 0xE9, 0x48, 0x83, 0xC4, 0x30, 0x5E, 0x5B, 0x0F, 0x28, 0xBC, 0x24,
    0xA0, 0x00, 0x00, 0x00, 0xE9, 0x67, 0xEC, 0xEB, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
}

local ZERO_CODE = {}
local ZERO_DATA = {}
local zeroIndex
for zeroIndex = 1, CODE_SIZE do
    ZERO_CODE[zeroIndex] = 0
end
for zeroIndex = 1, DATA_SIZE do
    ZERO_DATA[zeroIndex] = 0
end

local BLOCKS = {
    { X = 0,  Y = 19, WIDTH = 10, HEIGHT = 8,  CAP_ROWS = 3 },
    { X = 11, Y = 15, WIDTH = 10, HEIGHT = 12, CAP_ROWS = 3 },
    { X = 22, Y = 11, WIDTH = 10, HEIGHT = 16, CAP_ROWS = 3 },
    { X = 33, Y = 7,  WIDTH = 10, HEIGHT = 20, CAP_ROWS = 3 },
    { X = 44, Y = 0,  WIDTH = 14, HEIGHT = 27, CAP_ROWS = 4 },
}

local runtime = {
    installed = false,
    stopped = false,
    waitingBuildLogged = false,
    waitingLimitLogged = false,
    lastBlocks = nil,
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

local function addBlock(rectangles, block)
    local scale = CONFIG.GAUGE.SCALE
    local x = CONFIG.GAUGE.X + block.X * scale
    local y = CONFIG.GAUGE.Y + block.Y * scale
    local width = block.WIDTH * scale
    local height = block.HEIGHT * scale
    local unit = math.max(1, round(scale))
    local capRows = block.CAP_ROWS

    -- Teal outer silhouette. The cap rows create the rising diagonal top;
    -- the body supplies both sides and the bottom edge.
    addRectangle(
        rectangles,
        x,
        y + capRows * unit,
        width,
        height - capRows * unit,
        CONFIG.OUTLINE_COLOR
    )

    if capRows == 4 then
        addRectangle(rectangles, x + width - 2 * unit, y,
            2 * unit, unit, CONFIG.OUTLINE_COLOR)
        addRectangle(rectangles, x + width - 4 * unit, y + unit,
            4 * unit, unit, CONFIG.OUTLINE_COLOR)
        addRectangle(rectangles, x + width - 7 * unit, y + 2 * unit,
            7 * unit, unit, CONFIG.OUTLINE_COLOR)
        addRectangle(rectangles, x + width - 10 * unit, y + 3 * unit,
            10 * unit, unit, CONFIG.OUTLINE_COLOR)
    else
        addRectangle(rectangles, x + width - 3 * unit, y,
            3 * unit, unit, CONFIG.OUTLINE_COLOR)
        addRectangle(rectangles, x + width - 6 * unit, y + unit,
            6 * unit, unit, CONFIG.OUTLINE_COLOR)
        addRectangle(rectangles, x + width - 8 * unit, y + 2 * unit,
            8 * unit, unit, CONFIG.OUTLINE_COLOR)
    end

    -- Pink outer fill with the deep red center visible in the supplied art.
    addRectangle(
        rectangles,
        x + 2 * unit,
        y + capRows * unit,
        width - 4 * unit,
        height - (capRows + 2) * unit,
        CONFIG.FILL_EDGE_COLOR
    )
    local centerHeight = height - (capRows + 7) * unit
    if centerHeight > 0 then
        addRectangle(
            rectangles,
            x + 2 * unit,
            y + (capRows + 3) * unit,
            width - 4 * unit,
            centerHeight,
            CONFIG.FILL_CENTER_COLOR
        )
    end
end

local function buildRectangles(blockCount)
    local rectangles = {}
    local index
    for index = 1, blockCount do
        addBlock(rectangles, BLOCKS[index])
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

local function publishRectangles(rectangles)
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

local function validateConfiguration()
    if type(CONFIG.GAUGE) ~= "table"
        or type(CONFIG.GAUGE.X) ~= "number"
        or type(CONFIG.GAUGE.Y) ~= "number"
        or type(CONFIG.GAUGE.SCALE) ~= "number"
        or CONFIG.GAUGE.SCALE <= 0
        or CONFIG.GAUGE.SCALE > 4
    then
        return false, "GAUGE X/Y/SCALE is invalid"
    end
    if CONFIG.POINTS_PER_BLOCK ~= 20 or CONFIG.MAX_BLOCKS ~= 5 then
        return false, "this exact gauge requires 20 points and five blocks"
    end
    local colors = {
        CONFIG.OUTLINE_COLOR,
        CONFIG.FILL_EDGE_COLOR,
        CONFIG.FILL_CENTER_COLOR,
    }
    local index
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
    local rectangles = buildRectangles(5)
    if #rectangles > MAX_RECTANGLES then
        return false, "full gauge exceeds the verified rectangle cache"
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
    if arraysEqual(code, CAVE_CODE) then
        local sentinel = safeReadInt(DATA_RVA + 4)
        local count = safeReadInt(DATA_RVA)
        if sentinel == DATA_SENTINEL
            and count ~= nil
            and count <= MAX_RECTANGLES
        then
            return "owned"
        end
        return nil, "owned code exists, but its data sentinel is invalid"
    end
    if isZeroArray(code) then
        local data = safeReadArray(DATA_RVA, DATA_SIZE)
        if isZeroArray(data) then
            return "empty"
        end
        return nil, "private data region is already in use"
    end
    return nil, "private Sora HUD bridge region is already in use"
end

local function install()
    local signaturesOk, signaturesReason = verifyNativeSignatures()
    if not signaturesOk then
        return false, signaturesReason
    end

    local soraState, soraReason = patchState(
        SORA_HUD_CALL_RVA,
        SORA_HUD_CALL_ORIGINAL,
        SORA_HUD_CALL_CUSTOM,
        "player-HUD call"
    )
    if soraState == nil then
        return false, soraReason
    end
    local finalState, finalReason = patchState(
        FINAL_RENDER_CALL_RVA,
        FINAL_RENDER_CALL_ORIGINAL,
        FINAL_RENDER_CALL_CUSTOM,
        "final-render call"
    )
    if finalState == nil then
        return false, finalReason
    end
    local postState, postReason = patchState(
        POST_LOOP_HOOK_RVA,
        POST_LOOP_HOOK_ORIGINAL,
        POST_LOOP_HOOK_CUSTOM,
        "post-loop instruction"
    )
    if postState == nil then
        return false, postReason
    end

    local private, privateReason = privateState()
    if private == nil then
        return false, privateReason
    end
    if private == "empty"
        and (soraState ~= "native"
            or finalState ~= "native"
            or postState ~= "native")
    then
        return false, "HUD patches exist without this controller's code image; fully restart KH1FM"
    end
    if private == "owned"
        and (soraState == "native"
            or finalState == "native"
            or postState == "native")
    then
        return false, "controller code exists with a partially restored hook; fully restart KH1FM"
    end

    if private == "owned" then
        return true, "verified reload"
    end

    local codeOk, codeReason = safeWriteArray(CAVE_RVA, CAVE_CODE)
    if not codeOk then
        return false, "could not write private code: " .. tostring(codeReason)
    end
    local dataOk, dataReason = publishRectangles({})
    if not dataOk then
        safeWriteArray(CAVE_RVA, ZERO_CODE)
        return false, dataReason
    end

    local written = {}
    local patches = {
        {
            address = SORA_HUD_CALL_RVA,
            custom = SORA_HUD_CALL_CUSTOM,
            original = SORA_HUD_CALL_ORIGINAL,
            name = "player-HUD bridge",
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
            name = "post-loop gauge",
        },
    }
    local index
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

local function updateGauge()
    local limit, source = readLimit()
    if limit == nil then
        if runtime.lastBlocks ~= 0 then
            local hiddenOk, hiddenReason = publishRectangles({})
            if not hiddenOk then
                return false, hiddenReason
            end
            runtime.lastBlocks = 0
        end
        if not runtime.waitingLimitLogged then
            runtime.waitingLimitLogged = true
            log("WAITING: LIMIT v1.6 published interface is not active yet.")
        end
        return true
    end

    runtime.waitingLimitLogged = false
    local blocks = math.floor(limit / CONFIG.POINTS_PER_BLOCK)
    blocks = clamp(blocks, 0, CONFIG.MAX_BLOCKS)
    if blocks == runtime.lastBlocks then
        return true
    end

    local rectangles = buildRectangles(blocks)
    local ok, result = publishRectangles(rectangles)
    if not ok then
        return false, result
    end
    runtime.lastBlocks = blocks
    if CONFIG.LOG_VALUE_CHANGES or source == "preview" then
        log("DISPLAY: LIMIT=" .. tostring(limit)
            .. " blocks=" .. tostring(blocks)
            .. " rectangles=" .. tostring(result)
            .. " source=" .. tostring(source) .. ".")
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
        log("READY: five-block native-geometry LIMIT gauge; "
            .. tostring(installReason) .. ".")
        log("NATIVE HUD PRESERVED: portrait, HP, MP, labels, and textures are untouched.")
        log("THRESHOLDS: 20, 40, 60, 80, and 100 LIMIT.")
    end

    local updateOk, updateReason = updateGauge()
    if not updateOk then
        runtime.stopped = true
        safeWriteArray(DATA_RVA, { 0, 0, 0, 0 })
        log("STOPPED: " .. tostring(updateReason)
            .. ". Rectangle traversal was suspended.")
    end
end
