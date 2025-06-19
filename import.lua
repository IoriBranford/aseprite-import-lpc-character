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
            local celImage = fromCel.image
            if celImage and not celImage:isEmpty() then
                toSprite:newCel(toLayer, toF1 + i, celImage, fromCel.position)
            end
        end
    end
end

---@param animSprite Sprite
---@param parts AnimationParts
---@param f1 integer
---@param suffix string
local function tagPartAnimations(animSprite, parts, f1, suffix)
    for _, partname in ipairs(parts) do
        local part = parts[partname]
        local partfrom = f1 + part[1]
        local partto = f1 + part[2]
        local aniDir = AniDir.FORWARD
        if partto < partfrom then
            aniDir = AniDir.REVERSE
            partto, partfrom = partfrom, partto
        end
        local parttag = animSprite:newTag(partfrom, partto)
        parttag.name = partname..suffix
        parttag.aniDir = aniDir
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

            tagPartAnimations(animSprite, parts, from, tag.name)
        end
    else
        local from, to = 1, columns
        local tag = animSprite:newTag(from, to)
        tag.name = ""

        tagPartAnimations(animSprite, parts, from, tag.name)
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

---@param sheet Image
local function extractExtraSheet(sheet)
    local extraheight = sheet.height - StandardSheetHeight
    if extraheight <= 0 then return end

    local rect = Rectangle(0, StandardSheetHeight, sheet.width, extraheight)
    local image = Image(sheet, rect)
    return not image:isEmpty() and image
end

---@param sprite Sprite
---@param layer Layer|integer
---@param sheet Image
---@param animationSet AnimationSet
---@param args ImportLPCCharacterArgs
local function importStandardSheet(sprite, layer, sheet, animationSet, animationrects, args)
    local enabledAnimations = args.animationsExportEnabled

    local f1 = 1
    for _, basename in ipairs(animationSet) do
        local animation = enabledAnimations[basename] and animationSet[basename]
        local srcrect = animationrects and animationrects[basename]
        if animation and srcrect then
            local animSprite = animationSpriteFromSheetRect(sheet, srcrect, animation, sprite.height)
            importAnimationSprite(sprite, layer, f1, animSprite, basename)
            f1 = f1 + #animSprite.frames
            animSprite:close()
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
        importStandardSheet(sprite, 1, sheet, StandardAnimations, StandardSheetRects, args)
        local extrasheet = extractExtraSheet(sheet)
        if extrasheet then
            local extraSprite = Sprite(extrasheet.width, extrasheet.height)
            extraSprite:newCel(extraSprite.layers[1], 1, extrasheet)
        end
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

    local animationSet = LPCAnimations
    for _, animName in ipairs(animationSet) do
        if enabledAnimations[animName] ~= false then
            local animation = animationSet[animName]

            local animPath = app.fs.joinPath(packdir, animation.folder, animName)
            if app.fs.isDirectory(animPath) then
                -- TODO animation's item sheets
            else
                local animSprite = animationSpriteFromFile(animPath..".png", animation, size)
                if animSprite then
                    importAnimationSprite(sprite, 1, #sprite.frames, animSprite, animName)

                    local inpalette = animSprite.palettes[1]
                    for i = 0, #inpalette-1 do
                        local rgba = inpalette:getColor(i).rgbaPixel
                        if not paletteMap[rgba] then
                            paletteMap[rgba] = true
                            paletteArray[#paletteArray+1] = rgba
                        end
                    end

                    animSprite:close()
                end
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
    for _, name in ipairs(LPCAnimations) do
        animationsExportEnabled[name] = true
        local animation = LPCAnimations[name]
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