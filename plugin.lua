---@class LPCAnimation
---@field s integer
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field parts {[string]: integer[]}?

---@type {[string]:LPCAnimation,[integer]:string}
local Animations = {
    "Stand", "Walk", "Fall", "Swing", "Thrust", "Shoot", "Cast",
    Cast = { s = 64, x = 0, y = 0, w = 448, h = 256 },
    Thrust = { s = 64, x = 0, y = 256, w = 512, h = 256, parts = { Windup = { 0, 3 }, Attack = { 4, 7 } } },
    Stand = { s = 64, x = 0, y = 512, w = 64, h = 256 },
    Walk = { s = 64, x = 64, y = 512, w = 512, h = 256 },
    Swing = { s = 64, x = 0, y = 768, w = 384, h = 256, parts = { Windup = { 0, 2 }, Attack = { 3, 5 } } },
    Shoot = { s = 64, x = 0, y = 1024, w = 832, h = 256, parts = { Windup = { 0, 8 }, Attack = { 9, 11 } } },
    Fall = { s = 64, x = 0, y = 1280, w = 384, h = 64, parts = { Knees = { 0, 2 }, Flat = { 3, 5 } } },
}

---@class ImportLPCCharacterArgs
---@field sheet Image
---@field filename string
---@field frametime number in seconds
---@field size integer
---@field animationsEnabled {[string]:boolean}

local NormalSheetWidth = 832
local NormalSheetHeight = 1344

---@param t ImportLPCCharacterArgs
function ImportLPCCharacter(t)
    local sheet = t.sheet
    -- local BigSpriteSize = 128
    -- local BigWalkWidth = 1152
    -- local BigSheetHeight = 1856
    -- local HugeSpriteSize = 192
    -- local HugeSheetHeight = 3648

    local spriteSize = t.size

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
    local enabled = t.animationsEnabled
    local sprite = Sprite(spriteSize, spriteSize)
    sprite.filename = t.filename
    local layer = sprite.layers[1]
    local frames = sprite.frames

    local function importAnimation(name, animation, row, dir)
        local columns = math.floor(animation.w / animation.s)
        local sourceRect = Rectangle(animation.x, animation.y + row*animation.s, animation.s, animation.s)
        local dest = Point(spriteSize/2 - animation.s/2, spriteSize/2 - animation.s/2)
        local fromFrameNumber = #frames
        local toFrameNumber = #frames + columns - 1
        for _ = 1, columns do
            local frame = frames[#frames]
            frame.duration = frameDuration
            local image = Image(sheet, sourceRect)
            sprite:newCel(layer, frame, image, dest)

            sourceRect.x = sourceRect.x + animation.s
            sprite:newEmptyFrame()
        end

        local tag = sprite:newTag(fromFrameNumber, toFrameNumber)
        tag.name = name..dir

        local parts = animation.parts
        if parts then
            for part, range in pairs(parts) do
                if enabled[name..part] then
                    tag = sprite:newTag(fromFrameNumber + range[1], fromFrameNumber + range[2])
                    tag.name = name..part..dir
                end
            end
        end
    end

    app.transaction("Import LPC Character", function()
        for _, basename in ipairs(Animations) do
            local animation = Animations[basename]
            if enabled[basename] then
                local rows = math.floor(animation.h / animation.s)
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
        if extraheight >= spriteSize then
            ---@type LPCAnimation
            local extraAnimation = {
                s = spriteSize,
                x = 0,
                y = NormalSheetHeight,
                w = sheet.width,
                h = extraheight
            }
            local extrarows = math.floor(extraheight / spriteSize)
            for i = 0, extrarows-1 do
                importAnimation("extra", extraAnimation, i, i)
            end
        end
    end)
end

function ImportLPCCharacterDialog(args)
    local sheet = app.image
    if sheet.height < NormalSheetHeight or sheet.width < NormalSheetWidth then
        app.alert("Too small.")
        return
    end

    local filename = app.fs.filePathAndTitle(app.sprite.filename)..".ase"

    args.sheet = app.image
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
    local function enableAnimation(name)
        dialog:check({
            id = "check"..name,
            text = name,
            selected = args.animationsEnabled[name],
            onclick = function()
                args.animationsEnabled[name] = dialog.data["check"..name]
            end
        })
    end
    for _, name in ipairs(Animations) do
        enableAnimation(name)

        local animation = Animations[name]
        local parts = animation.parts
        if parts then
            for part in pairs(parts) do
                enableAnimation(name..part)
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
    dialog:show()
end

function ImportLPCCharacterNewArgs()
    local animationsEnabled = {}
    for _, name in ipairs(Animations) do
        animationsEnabled[name] = true
        local animation = Animations[name]
        local parts = animation.parts
        if parts then
            for part in pairs(parts) do
                animationsEnabled[name..part] = true
            end
        end
    end
    return {
        frametime = .05,
        size = 64,
        animationsEnabled = animationsEnabled
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
        group="file_import",
        onclick=function()
            ImportLPCCharacterDialog(args)
        end
    })
end