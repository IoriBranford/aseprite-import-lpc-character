require "lpc"

---@param n integer
---@param toSprite Sprite
---@param toLayer Layer|integer
---@param toF1 integer
---@param fromSprite Sprite
---@param fromLayer Layer|integer
---@param fromF1 integer
local function copyCels(n, toSprite, toLayer, toF1, fromSprite, fromLayer, fromF1)
    if type(fromLayer) == "number" then
        fromLayer = fromSprite.layers[fromLayer]
    end
    if type(toLayer) == "number" then
        toLayer = toSprite.layers[toLayer]
    end
    ---@cast fromLayer Layer
    ---@cast toLayer Layer

    local fromFrames = fromSprite.frames
    n = math.min(n, 1 + #fromFrames - fromF1)
    if n < 1 then return end

    local toFrames = toSprite.frames
    for i = #toFrames + 1, toF1 + n - 1 do
        toSprite:newEmptyFrame()
    end

    for i = 0, n-1 do
        local fromCel = fromLayer:cel(fromF1 + i)
        if fromCel then
            toSprite:newCel(toLayer, toF1 + i, fromCel.image, fromCel.position)
        end
    end
end

---@param animSprite Sprite
---@param animation LPCAnimation
---@param columns integer
---@param rows integer
local function tagAnimationSprite(animSprite, animation, columns, rows)
    local parts = animation.parts or {}
    if rows > 1 then
        for i = 0, rows-1 do
            local dir = tostring(rows-i-1)
            local from, to = i*columns + 1, (i+1)*columns
            local tag = animSprite:newTag(from, to)
            tag.name = dir

            for _, partname in ipairs(parts) do
                local part = parts[partname]
                local partfrom = from + part[1]
                local partto = from + part[2]
                local aniDir = AniDir.FORWARD
                if partto < partfrom then
                    aniDir = AniDir.REVERSE
                    partto, partfrom = partfrom, partto
                end
                local parttag = animSprite:newTag(partfrom, partto)
                parttag.name = partname..dir
                parttag.aniDir = aniDir
            end
        end
    else
        local from, to = 1, columns
        local tag = animSprite:newTag(from, to)
        tag.name = ""

        for _, partname in ipairs(parts) do
            local part = parts[partname]
            local partfrom = from + part[1]
            local partto = from + part[2]
            local parttag = animSprite:newTag(partfrom, partto)
            parttag.name = partname
        end
    end
end

---@param sprite Sprite
---@param targetSize integer
local function growSprite(sprite, targetSize)
    local diff = (targetSize - sprite.height) / 2
    if diff >= 1 then
        app.sprite = sprite
        app.command.CanvasSize {
            ui = false,
            left = diff, right = diff,
            top = diff, bottom = diff
        }
    end
end

---@param animSprite Sprite
---@param animation LPCAnimation
---@param targetFrameSize integer
local function processAnimationSprite(animSprite, animation, targetFrameSize)
    local sheetFrameSize = animation.s or StandardFrameSize
    local columns = math.floor(animSprite.width / sheetFrameSize)
    local rows = math.floor(animSprite.height / sheetFrameSize)

    app.sprite = animSprite
    app.command.ImportSpriteSheet {
        ui = false,
        type = SpriteSheetType.ROWS,
        frameBounds = Rectangle(0, 0, sheetFrameSize, sheetFrameSize),
    }

    tagAnimationSprite(animSprite, animation, columns, rows)
    growSprite(animSprite, targetFrameSize)
end

---@param animFile string
---@param animation LPCAnimation
---@param targetFrameSize integer
---@return Sprite?
local function animationSpriteFromFile(animFile, animation, targetFrameSize)
    local animSprite = app.fs.isFile(animFile) and app.open(animFile)
    if not animSprite then return end
    processAnimationSprite(animSprite, animation, targetFrameSize)
    return animSprite
end

---@param sheet Image
---@param rect RectangleArg
---@param animation LPCAnimation
---@param targetFrameSize integer
---@return Sprite
local function animationSpriteFromSheetRect(sheet, rect, animation, targetFrameSize)
    local animImage = Image(sheet, rect)
    local animSprite = Sprite(rect.width, rect.height)
    animSprite:newCel(animSprite.layers[1], 1, animImage, {-rect.x, -rect.y})
    processAnimationSprite(animSprite, animation, targetFrameSize)
    return animSprite
end

---@param charSprite Sprite
---@param charLayer Layer|integer
---@param charF1 integer
---@param animSprite Sprite
---@param animName string
---@return Sprite?
local function importAnimationSprite(charSprite, charLayer, charF1, animSprite, animName)
    growSprite(charSprite, animSprite.height)
    copyCels(#animSprite.frames,
        charSprite, charLayer, charF1,
        animSprite, 1, 1)

    -- Avoid creating a tag that goes to the last frame.
    -- If you add a new frame with any tags going to the last frame,
    -- Aseprite extends those tags to the new frame.
    charSprite:newEmptyFrame()

    for _, animTag in ipairs(animSprite.tags) do
        local from = charF1 + animTag.fromFrame.frameNumber - 1
        local to = charF1 + animTag.toFrame.frameNumber - 1
        local tag = charSprite:newTag(from, to)
        tag.name = animName..animTag.name
        tag.aniDir = animTag.aniDir
    end
end

---@param sprite Sprite
---@param layer Layer|integer
---@param sheet Image
---@param rowrect Rectangle
---@param animation LPCAnimation
---@param animname string
---@param rowname integer|string
---@param args ImportLPCCharacterArgs
local function importAnimationRow(sprite, layer, sheet, rowrect, animation, animname, rowname, args)
    local frameDuration = args.frametime
    local outputFrameSize = sprite.width
    local frames = sprite.frames
    local sourceFrameSize = rowrect.h or rowrect.height
    local columns = math.floor((rowrect.w or rowrect.width) / sourceFrameSize)
    local maxX = sheet.width - sourceFrameSize
    local maxY = sheet.height - sourceFrameSize
    local sourceRect = Rectangle(rowrect.x, rowrect.y, sourceFrameSize, sourceFrameSize)
    local dest = Point(outputFrameSize/2 - sourceFrameSize/2, outputFrameSize/2 - sourceFrameSize/2)
    local fromFrameNumber = #frames
    local toFrameNumber = #frames + columns - 1
    if type(layer) == "number" then
        layer = sprite.layers[layer]
    end
    ---@cast layer Layer
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
local function importExtraAnimations(sprite, layer, sheet, args)
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
        importAnimationRow(sprite, layer, sheet, dirrect, extraAnimation, "extra", i, args)
        dirrect.y = dirrect.y + outputFrameSize
    end
end

local function importAnimation(sprite, layer, sheet, animrect, animation, basename, args)
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
        importAnimationRow(sprite, layer, sheet, rowrect, animation, basename, "", args)
    elseif rows > 1 then
        rowrect.y = rowrect.y + rows*animation.s
        for r = rows, 1, -1 do
            rowrect.y = rowrect.y - animation.s
            importAnimationRow(sprite, layer, sheet, rowrect, animation, basename, rows-r, args)
        end
    end
end

---@param sprite Sprite
---@param layer Layer|integer
---@param sheet Image
---@param animationSet AnimationSet
---@param args ImportLPCCharacterArgs
local function importAnimationSet(sprite, layer, sheet, animationSet, animationrects, args)
    local enabledAnimations = args.animationsExportEnabled

    for _, basename in ipairs(animationSet) do
        if enabledAnimations[basename] then
            local animation = animationSet[basename]
            local srcrect = animationrects and animationrects[basename]
            importAnimation(sprite, layer, sheet, srcrect, animation, basename, args)
        end
    end
end

local function makeItemLayers(sprite, animpaths)
    local layers = {}
    sprite:deleteLayer(sprite.layers[1])
    for _, animpath in ipairs(animpaths) do
        for _, layerfile in ipairs(app.fs.listFiles(animpath)) do
            local layername = app.fs.fileTitle(layerfile)
            if not layers[layername] then
                layers[#layers+1] = layername
                layers[layername] = true
            end
        end
    end
    table.sort(layers)
    for _, layername in ipairs(layers) do
        local layer = sprite:newLayer()
        layer.name = layername
        layers[layername] = layer
    end
    return layers
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
        importAnimationSet(sprite, 1, sheet, StandardAnimations, StandardSheetRects, args)
        importExtraAnimations(sprite, 1, sheet, args)
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
                importAnimation(sprite, 1, Image(insprite), nil, animation, basename, args)
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