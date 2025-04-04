---@class LPCAnimation
---@field s integer
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field columns integer?
---@field rows integer?
---@field parts {[string]: integer[]}?

---@type {[string]:LPCAnimation,[integer]:string}
local Animations = {
    "Stand", "Walk", "Fall", "Swing", "Thrust", "Shoot", "Cast",
    "IdleCalm", "Run", "Climb", "Jump", "Sit", "Emote",
    "IdleCombat", "Swing1Hand", "Thrust1Hand",

    Cast = { s = 64, x = 0, y = 0, w = 448, h = 256 },
    Thrust = { s = 64, x = 0, y = 256, w = 512, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 3 },
            Attack = { 4, 7 }
        }
    },
    Stand = { s = 64, x = 0, y = 512, w = 64, h = 256 },
    Walk = { s = 64, x = 64, y = 512, w = 512, h = 256 },
    Swing = { s = 64, x = 0, y = 768, w = 384, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 2 }, Attack = { 3, 5 }
        }
    },
    Shoot = { s = 64, x = 0, y = 1024, w = 832, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 8 }, Attack = { 9, 11 }
        }
    },
    Fall = { s = 64, x = 0, y = 1280, w = 384, h = 64,
        parts = {
            "Knees", "Flat", "RiseToKnees", "RiseToFeet",
            Knees = { 0, 2 }, Flat = { 3, 5 }, RiseToFeet = { 5, 0 }, RiseToKnees = { 5, 3 }
        }
    },

    Climb = { s = 64, x = 0, y = 1344, w = 384, h = 64},
    IdleCalm = { s = 64, x = 0, y = 1408, w = 128, h = 256 },
    Jump = { s = 64, x = 0, y = 1664, w = 320, h = 256},
    Sit = { s = 64, x = 0, y = 1920, w = 192, h = 256,
        parts = {
            "GroundMasc", "GroundFem", "Chair",
            GroundMasc = {0, 0},
            GroundFem = {1, 1},
            Chair = {2, 2}
        }
    },
    Emote = { s = 64, x = 0, y = 2176, w = 192, h = 256,
        parts = {
            "HandsOnHips", "HandsBehindBack", "Surprised",
            HandsOnHips = {0, 0},
            HandsBehindBack = {1, 1},
            Surprised = {2, 2}
        }
    },
    Run = { s = 64, x = 0, y = 2432, w = 512, h = 256 },
    IdleCombat = { s = 64, x = 0, y = 2688, w = 128, h = 256 },
    Swing1Hand = { s = 64, x = 0, y = 2944, w = 832, h = 256,
        parts = {
            "Windup", "Attack", "BackWindup", "BackAttack",
            Windup = { 0, 0 },
            Attack = { 1, 5 },
            BackWindup = { 6, 7 },
            BackAttack = { 8, 12 }
        }
    },
    Thrust1Hand = { s = 64, x = 0, y = 3200, w = 384, h = 256,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 0 },
            Attack = { 1, 5 }
        }
    },
}

for _, name in ipairs(Animations) do
    local animation = Animations[name]
    animation.columns = math.floor(animation.w / animation.s)
    animation.rows = math.floor(animation.h / animation.s)
end

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

---@class ImportLPCCharacterArgs
---@field sheet Image
---@field filename string
---@field frametime number in seconds
---@field size integer
---@field animationsExportEnabled {[string]:boolean}

local NormalSheetWidth = 832
local NormalSheetHeight = 3456

---@param t ImportLPCCharacterArgs
function ImportLPCCharacter(t)
    local sheet = t.sheet
    -- local BigSpriteSize = 128
    -- local BigWalkWidth = 1152
    -- local BigSheetHeight = 1856
    -- local HugeSpriteSize = 192
    -- local HugeSheetHeight = 3648

    local outputFrameSize = t.size

    -- if sheet.height >= HugeSheetHeight then
    --     spriteSize = HugeSpriteSize
    --     Animations.Swing = { s = 192, x = 0, y = 1344, w = 1152, h = 768, parts = { Windup = { 0, 2 }, Attack = { 3, 5 } } }
    --     Animations.RevSwing = { s = 192, x = 0, y = 2112, w = 1152, h = 768, parts = { Windup = { 0, 2 }, Attack = { 3, 5 } } }
    --     Animations.Thrust = { s = 192, x = 0, y = 2880, w = 1536, h = 768, parts = { Windup = { 0, 3 }, Attack = { 4, 7 } } }
    --     Animations[#Animations+1] = "RevSwing"
    -- elseif sheet.height >= BigSheetHeight then
    --     spriteSize = BigSpriteSize

    --     if sheet.width >= BigWalkWidth then
    --         Animations.Stand = { s = 128, x = 0, y = 1344, w = 128, h = 512 }
    --         Animations.Walk = { s = 128, x = 128, y = 1344, w = 1024, h = 512 }
    --     else
    --         Animations.Swing = { s = 128, x = 0, y = 1344, w = 768, h = 512, parts = { Windup = { 0, 2 }, Attack = { 3, 5 } } }
    --     end
    -- end

    local frameDuration = t.frametime
    local enabled = t.animationsExportEnabled
    local sprite = Sprite(outputFrameSize, outputFrameSize)
    sprite.filename = t.filename
    local layer = sprite.layers[1]
    local frames = sprite.frames

    ---@param animation LPCAnimation
    local function importAnimation(name, animation, row, dir)
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
            for _, part in ipairs(parts) do
                if enabled[name..part] then
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

    app.transaction("Import LPC Character", function()
        for _, basename in ipairs(Animations) do
            local animation = Animations[basename]
            if enabled[basename] and animationRowFramesInSheet(animation, 0, sheet) > 0 then
                local rows = animation.rows
                if rows <= 1 then
                    importAnimation(basename, animation, 0, "")
                else
                    for r = rows, 1, -1 do
                        importAnimation(basename, animation, r-1, rows-r)
                    end
                end
            end
        end

        local extraheight = sheet.height - NormalSheetHeight
        if extraheight >= outputFrameSize then
            local extrarows = math.floor(extraheight / outputFrameSize)
            local extracolumns = math.floor(sheet.width / outputFrameSize)

            ---@type LPCAnimation
            local extraAnimation = {
                s = outputFrameSize,
                x = 0,
                y = NormalSheetHeight,
                w = extracolumns*outputFrameSize,
                h = extrarows*outputFrameSize,
                rows = extrarows,
                columns = extracolumns
            }
            for i = 0, extrarows-1 do
                importAnimation("extra", extraAnimation, i, i)
            end
        end
    end)
end

function ImportLPCCharacterDialog(args)
    local sheet = app.sprite
    if not sheet then
        app.alert("No file open.")
        return
    end
    if sheet.height < 64 or sheet.width < 64 then
        app.alert("File too small to hold any frames (min 64x64).")
        return
    end

    local filename = app.fs.filePathAndTitle(app.sprite.filename)..".ase"

    args.sheet = Image(sheet)
    args.filename = filename

    local dialog = Dialog("Import LPC Character")
    dialog:combobox({
        id = "comboboxSpriteSize",
        label = "Sprite size",
        options = {"64", "128", "192"},
        option = tostring(args.size),
        onchange = function()
            args.size = tonumber(dialog.data.comboboxSpriteSize)
        end
    })
    dialog:number({
        id = "numberFrameTime",
        label = "Frame time (ms)",
        text = tostring(math.floor(args.frametime * 1000)),
        decimals = 0,
        onchange = function()
            args.frametime = dialog.data.numberFrameTime / 1000
        end
    })
    dialog:separator({
        text = "Animations"
    })

    local function setAnimationPartsCheckboxesEnabled(name, enabled)
        local animation = Animations[name]
        local parts = animation and animation.parts
        if parts then
            for _, part in ipairs(parts) do
                dialog:modify({
                    id = "check"..name..part,
                    enabled = enabled
                })
            end
        end
    end

    local function setAnimationExportEnabled(name, enabled)
        args.animationsExportEnabled[name] = enabled
        setAnimationPartsCheckboxesEnabled(name, enabled)
    end

    local function animationCheckbox(name)
        dialog:check({
            id = "check"..name,
            text = name,
            selected = args.animationsExportEnabled[name],
            onclick = function()
                setAnimationExportEnabled(name, dialog.data["check"..name])
            end
        })
    end

    for _, name in ipairs(Animations) do
        animationCheckbox(name)

        local animation = Animations[name]
        local parts = animation.parts
        if parts then
            for _, part in ipairs(parts) do
                animationCheckbox(name..part)
            end
        end
        dialog:newrow()
    end
    dialog:button({
        text = "Import",
        onclick = function()
            ImportLPCCharacter(args)
            dialog:close()
        end
    })

    for _, name in ipairs(Animations) do
        local exportEnabled = args.animationsExportEnabled[name]
        setAnimationExportEnabled(name, exportEnabled)
        local checkboxEnabled = animationRowFramesInSheet(Animations[name], 0, sheet) > 0
        dialog:modify({
            id = "check"..name,
            enabled = checkboxEnabled
        })
        setAnimationPartsCheckboxesEnabled(name, exportEnabled and checkboxEnabled)
    end

    dialog:show({wait = true})
end

function ImportLPCCharacterNewArgs()
    local animationsExportEnabled = {}
    for _, name in ipairs(Animations) do
        animationsExportEnabled[name] = true
        local animation = Animations[name]
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

---@param plugin Plugin
function init(plugin)
    local args = plugin.preferences.lastargs
    if not args then
        args = ImportLPCCharacterNewArgs()
        plugin.preferences.lastargs = args
    end

    plugin:newCommand({
        id="ImportLPCCharacter",
        title="Import LPC Character",
        group="file_import_1",
        onclick=function()
            ImportLPCCharacterDialog(args)
        end
    })
end