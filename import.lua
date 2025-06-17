require "lpc"

---@param sprite Sprite
---@param sheet Image
---@param rowrect Rectangle
---@param animation LPCAnimation
---@param animname string
---@param rowname integer|string
---@param args ImportLPCCharacterArgs
local function importAnimationRow(sprite, sheet, rowrect, animation, animname, rowname, args)
    local frameDuration = args.frametime
    local outputFrameSize = sprite.width
    local layer = sprite.layers[1]
    local frames = sprite.frames
    local sourceFrameSize = rowrect.h or rowrect.height
    local columns = math.floor((rowrect.w or rowrect.width) / sourceFrameSize)
    local maxX = sheet.width - sourceFrameSize
    local maxY = sheet.height - sourceFrameSize
    local sourceRect = Rectangle(rowrect.x, rowrect.y, sourceFrameSize, sourceFrameSize)
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
    tag.name = animname..rowname

    local parts = animation.parts
    if parts then
        local enabledAnimations = args.animationsExportEnabled
        for _, part in ipairs(parts) do
            if not enabledAnimations or enabledAnimations[animname..part] then
                local range = parts[part]
                local from, to = range[1], range[2]
                local direction
                if to < from then
                    direction = AniDir.REVERSE
                    from, to = to, from
                end
                tag = sprite:newTag(fromFrameNumber + range[1], fromFrameNumber + range[2])
                tag.aniDir = direction
                tag.name = animname..part..rowname
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
    }
    local dirrect = {
        x = 0, y = StandardSheetHeight, w = extracolumns*outputFrameSize, h = outputFrameSize
    }
    for i = 0, extrarows-1 do
        importAnimationRow(sprite, sheet, dirrect, extraAnimation, "extra", i, args)
        dirrect.y = dirrect.y + outputFrameSize
    end
end

local function importAnimation(sprite, sheet, animrect, animation, basename, args)
    local animh = animation.h or sheet.height
    local rowrect = {
        x = animation.x or 0,
        y = animation.y or 0,
        w = animation.w or sheet.width,
        h = animation.s
    }
    if animrect then
        rowrect.x = animrect.x or rowrect.x
        rowrect.y = animrect.y or rowrect.y
        rowrect.w = animrect.w or rowrect.w
        animh = animrect.h or animh
    end

    local rows = math.floor(animh / animation.s)
    if rows == 1 then
        importAnimationRow(sprite, sheet, rowrect, animation, basename, "", args)
    elseif rows > 1 then
        rowrect.y = rowrect.y + rows*animation.s
        for r = rows, 1, -1 do
            rowrect.y = rowrect.y - animation.s
            importAnimationRow(sprite, sheet, rowrect, animation, basename, rows-r, args)
        end
    end
end

---@param sprite Sprite
---@param sheet Image
---@param animationSet AnimationSet
---@param args ImportLPCCharacterArgs
local function importAnimationSet(sprite, sheet, animationSet, animationrects, args)
    local enabledAnimations = args.animationsExportEnabled

    for _, basename in ipairs(animationSet) do
        if enabledAnimations[basename] then
            local animation = animationSet[basename]
            local srcrect = animationrects and animationrects[basename]
            importAnimation(sprite, sheet, srcrect, animation, basename, args)
        end
    end
end

local import = {}

---@param sheetsprite Sprite
---@param args ImportLPCCharacterArgs
function import.FromSheet(sheetsprite, args)
    local sprite = Sprite(args.size, args.size)
    sprite:setPalette(sheetsprite.palettes[1])
    sprite.filename = args.outputFile
    app.transaction("Import LPC Character Sheet", function()
        local sheet = Image(sheetsprite)
        importAnimationSet(sprite, sheet, StandardAnimations, StandardAnimationSheetRects, args)
        importExtraAnimations(sprite, sheet, args)
    end)
    return sprite
end

function import.FromPack(args)
    local size = args.size
    local sprite = Sprite(size, size)
    sprite.filename = args.outputFile

    local packdir = app.fs.filePath(args.inputFile)
    local enabledAnimations = args.animationsExportEnabled
    local paletteMap = {}
    local paletteArray = {}

    local animationSet = StandardAnimations
    for _, basename in ipairs(animationSet) do
        if enabledAnimations[basename] then
            local animation = animationSet[basename]
            animation = animation[size] or animation

            local file = app.fs.joinPath(packdir, animation.file)
            local insprite = app.fs.isFile(file) and app.open(file)
            if insprite then
                local inpalette = insprite.palettes[1]
                for i = 0, #inpalette-1 do
                    local rgba = inpalette:getColor(i).rgbaPixel
                    if not paletteMap[rgba] then
                        paletteMap[rgba] = true
                        paletteArray[#paletteArray+1] = rgba
                    end
                end
                importAnimation(sprite, Image(insprite), nil, animation, basename, args)
                insprite:close()
            end
        end
    end

    local palette = Palette(#paletteArray)
    for i = 1, #paletteArray do
        palette:setColor(i-1, paletteArray[i])
    end
    sprite:setPalette(palette)

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