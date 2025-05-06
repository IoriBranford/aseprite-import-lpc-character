---@class LPCAnimation
---@field s 64|128|192
---@field x integer? default to 0
---@field y integer? default to 0
---@field w integer? default to image width
---@field h integer? default to image height
---@field file string
---@field columns integer?
---@field rows integer?
---@field parts {[string]: integer[]}?
---@field [integer] LPCAnimation

---@alias AnimationSet {[string]:LPCAnimation,[integer]:string}

local StandardAnimationSheetRects = {
    "stand", "walk", "hurt", "slash", "thrust", "shoot", "spellcast",
    "idle", "run", "climb", "jump", "sit", "emote",
    "combat_idle", "backslash", "halfslash",
    spellcast = { x = 0, y = 0, w = 448, h = 256 },
    thrust = { x = 0, y = 256, w = 512, h = 256 },
    stand = { x = 0, y = 512, w = 64, h = 256 },
    walk = { x = 64, y = 512, w = 512, h = 256 },
    slash = { x = 0, y = 768, w = 384, h = 256 },
    shoot = { x = 0, y = 1024, w = 832, h = 256 },
    hurt = { x = 0, y = 1280, w = 384, h = 64 },
    climb = { x = 0, y = 1344, w = 384, h = 64 },
    idle = { x = 0, y = 1408, w = 128, h = 256 },
    jump = { x = 0, y = 1664, w = 320, h = 256 },
    sit = { x = 0, y = 1920, w = 192, h = 256 },
    emote = { x = 0, y = 2176, w = 192, h = 256 },
    run = { x = 0, y = 2432, w = 512, h = 256 },
    combat_idle = { x = 0, y = 2688, w = 128, h = 256 },
    backslash = { x = 0, y = 2944, w = 832, h = 256 },
    halfslash = { x = 0, y = 3200, w = 384, h = 256 },
}

---@type AnimationSet
local StandardAnimations = {
    "stand", "walk", "hurt", "slash", "thrust", "shoot", "spellcast",
    "idle", "run", "climb", "jump", "sit", "emote",
    "combat_idle", "backslash", "halfslash",

    spellcast = { file = "standard/spellcast.png", s = 64, x = 0, y = 0, w = 448, h = 256 },
    thrust = { file = "standard/thrust.png", s = 64, x = 0, y = 256, w = 512, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 3 },
            Attack = { 4, 7 }
        },
        [192] = { file = "custom/thrust_oversize.png" }
    },
    stand = {
        file = "standard/walk.png", s = 64, x = 0, y = 512, w = 64, h = 256,
        [128] = { file = "custom/walk_128.png", s = 128, x = 0, y = 0, w = 128, h = 512 },
    },
    walk = {
        file = "standard/walk.png", s = 64, x = 64, y = 512, w = 512, h = 256,
        [128] = { file = "custom/walk_128.png", s = 128, x = 128, y = 0, w = 1024, h = 512 },
    },
    slash = { file = "standard/slash.png", s = 64, x = 0, y = 768, w = 384, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 2 }, Attack = { 3, 5 }
        }
    },
    shoot = { file = "standard/shoot.png", s = 64, x = 0, y = 1024, w = 832, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 8 }, Attack = { 9, 11 }
        }
    },
    hurt = { file = "standard/hurt.png", s = 64, x = 0, y = 1280, w = 384, h = 64,
        parts = {
            "Knees", "Flat", "RiseToKnees", "RiseToFeet",
            Knees = { 0, 2 }, Flat = { 3, 5 }, RiseToFeet = { 5, 0 }, RiseToKnees = { 5, 3 }
        }
    },

    climb = { file = "standard/climb.png", s = 64, x = 0, y = 1344, w = 384, h = 64},
    idle = { file = "standard/idle.png", s = 64, x = 0, y = 1408, w = 128, h = 256 },
    jump = { file = "standard/jump.png", s = 64, x = 0, y = 1664, w = 320, h = 256},
    sit = { file = "standard/sit.png", s = 64, x = 0, y = 1920, w = 192, h = 256,
        parts = {
            "GroundMasc", "GroundFem", "Chair",
            GroundMasc = {0, 0},
            GroundFem = {1, 1},
            Chair = {2, 2}
        }
    },
    emote = { file = "standard/emote.png", s = 64, x = 0, y = 2176, w = 192, h = 256,
        parts = {
            "HandsOnHips", "HandsBehindBack", "Surprised",
            HandsOnHips = {0, 0},
            HandsBehindBack = {1, 1},
            Surprised = {2, 2}
        }
    },
    run = { file = "standard/run.png", s = 64, x = 0, y = 2432, w = 512, h = 256 },
    combat_idle = { file = "standard/combat_idle.png", s = 64, x = 0, y = 2688, w = 128, h = 256 },
    backslash = { file = "standard/backslash.png", s = 64, x = 0, y = 2944, w = 832, h = 256,
        parts = {
            "Windup", "Attack", "BackWindup", "BackAttack",
            Windup = { 0, 0 },
            Attack = { 1, 5 },
            BackWindup = { 6, 7 },
            BackAttack = { 8, 12 }
        },
        [192] = { file = "custom/slash_reverse_oversize.png" }
    },
    halfslash = { file = "standard/halfslash.png", s = 64, x = 0, y = 3200, w = 384, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 0 },
            Attack = { 1, 5 }
        }
    },
}

local StandardSheetHeight = 3456

local function animationRowFramesInSheet(animation, row, sheet)
    local sourceFrameSize = animation.s

    local sourceY = animation.y + row*sourceFrameSize
    local maxY = sheet.height - sourceFrameSize
    if sourceY > maxY then
        return 0
    end

    local width = math.min(animation.w, sheet.width - animation.x)
    return math.floor(width / sourceFrameSize)
end

---@param sprite Sprite
---@param sheet Image
---@param animation LPCAnimation
---@param name string
---@param row integer
---@param dir integer|string
---@param args ImportLPCCharacterArgs
local function importAnimation(sprite, sheet, animation, name, row, dir, args)
    local frameDuration = args.frametime
    local outputFrameSize = sprite.width
    local layer = sprite.layers[1]
    local frames = sprite.frames
    local sourceFrameSize = animation.s
    local columns = animation.columns
    local maxX = sheet.width - sourceFrameSize
    local maxY = sheet.height - sourceFrameSize
    local sourceRect = Rectangle(animation.x, animation.y + row*sourceFrameSize, sourceFrameSize, sourceFrameSize)
    local dest = Point(outputFrameSize/2 - sourceFrameSize/2, outputFrameSize/2 - sourceFrameSize/2)
    local fromFrameNumber = #frames
    local toFrameNumber = #frames + columns - 1
    for _ = 1, columns do
        if sourceRect.x <= maxX and sourceRect.y <= maxY then
            local frame = frames[#frames]
            frame.duration = frameDuration
            local image = Image(sheet, sourceRect)
            sprite:newCel(layer, frame, image, dest)
        end
        sourceRect.x = sourceRect.x + sourceFrameSize
        sprite:newEmptyFrame()
    end

    local tag = sprite:newTag(fromFrameNumber, toFrameNumber)
    tag.name = name..dir

    local parts = animation.parts
    if parts then
        local enabledAnimations = args.animationsExportEnabled
        for _, part in ipairs(parts) do
            if not enabledAnimations or enabledAnimations[name..part] then
                local range = parts[part]
                local from, to = range[1], range[2]
                local direction
                if to < from then
                    direction = AniDir.REVERSE
                    from, to = to, from
                end
                tag = sprite:newTag(fromFrameNumber + range[1], fromFrameNumber + range[2])
                tag.aniDir = direction
                tag.name = name..part..dir
            end
        end
    end
end

---comment
---@param sprite Sprite
---@param sheet Image
---@param args ImportLPCCharacterArgs
local function importExtraAnimations(sprite, sheet, args)
    local outputFrameSize = sprite.height
    local extraheight = sheet.height - StandardSheetHeight
    if extraheight < outputFrameSize then return end

    local extrarows = math.floor(extraheight / outputFrameSize)
    local extracolumns = math.floor(sheet.width / outputFrameSize)

    ---@type LPCAnimation
    local extraAnimation = {
        file = "",
        s = outputFrameSize,
        x = 0,
        y = StandardSheetHeight,
        w = extracolumns*outputFrameSize,
        h = extrarows*outputFrameSize,
        rows = extrarows,
        columns = extracolumns
    }
    for i = 0, extrarows-1 do
        importAnimation(sprite, sheet, extraAnimation, "extra", i, i, args)
    end
end

---comment
---@param sprite Sprite
---@param sheet Image
---@param animationSet AnimationSet
---@param args ImportLPCCharacterArgs
local function importAnimationSet(sprite, sheet, animationSet, args)
    local enabledAnimations = args.animationsExportEnabled

    for _, basename in ipairs(animationSet) do
        if enabledAnimations[basename] then
            local animation = animationSet[basename]
            animation.columns = math.floor(animation.w / animation.s)
            animation.rows = math.floor(animation.h / animation.s)

            if animationRowFramesInSheet(animation, 0, sheet) > 0 then
                local rows = animation.rows
                if rows <= 1 then
                    importAnimation(sprite, sheet, animation, basename, 0, "", args)
                else
                    for r = rows, 1, -1 do
                        importAnimation(sprite, sheet, animation, basename, r-1, rows-r, args)
                    end
                end
            end
        end
    end
end

local import = {
    StandardAnimations = StandardAnimations
}

function import.sheetHasAnimationRow(animation, row, sheet)
    return animationRowFramesInSheet(animation, row, sheet) > 0
end

---@param sheetsprite Sprite
---@param args ImportLPCCharacterArgs
function import.FromSheet(sheetsprite, args)
    local sprite = Sprite(args.size, args.size)
    sprite.filename = args.outputFile
    app.transaction("Import LPC Character Sheet", function()
        local sheet = Image(sheetsprite)
        importAnimationSet(sprite, sheet, StandardAnimations, args)
        importExtraAnimations(sprite, sheet, args)
    end)
    return sprite
end


---@class ImportLPCCharacterArgs
---@field inputFile string
---@field outputFile string
---@field frametime number in seconds
---@field size integer
---@field animationsExportEnabled {[string]:boolean}

---@return ImportLPCCharacterArgs
function import.NewArgs()
    local animationsExportEnabled = {}
    for _, name in ipairs(StandardAnimations) do
        animationsExportEnabled[name] = true
        local animation = StandardAnimations[name]
        local parts = animation.parts
        if parts then
            for _, part in ipairs(parts) do
                animationsExportEnabled[name..part] = true
            end
        end
    end

    return {
        frametime = .05,
        size = 64,
        animationsExportEnabled = animationsExportEnabled
    }
end

return import