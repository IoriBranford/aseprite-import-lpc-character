require "lpc"
local zzlib = require "zzlib"

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
local function processAnimationSprite(animSprite, animation, targetFrameSize, withTags)
    local sheetFrameSize = animation.s or StandardFrameSize
    local columns = math.floor(animSprite.width / sheetFrameSize)
    local rows = math.floor(animSprite.height / sheetFrameSize)

    app.sprite = animSprite
    app.command.ImportSpriteSheet {
        ui = false,
        type = SpriteSheetType.ROWS,
        frameBounds = Rectangle(0, 0, sheetFrameSize, sheetFrameSize),
    }

    growSprite(animSprite, targetFrameSize)

    if withTags then
        tagAnimationSprite(animSprite, animation, columns, rows)
    end
end

---@param animFile string
---@param animation LPCAnimation
---@param targetFrameSize integer
---@return Sprite?
local function animationSpriteFromFile(animFile, animation, targetFrameSize, withTags)
    local animSprite = app.fs.isFile(animFile) and app.open(animFile)
    if not animSprite then return end
    processAnimationSprite(animSprite, animation, targetFrameSize, withTags)
    return animSprite
end

---@param sheet Image
---@param rect RectangleArg
---@param animation LPCAnimation
---@param targetFrameSize integer
---@return Sprite
local function animationSpriteFromSheetRect(sheet, rect, animation, targetFrameSize, withTags)
    local animImage = Image(sheet, Rectangle(rect))
    local animSprite = Sprite(animImage.width, animImage.height)
    animSprite:newCel(animSprite.layers[1], 1, animImage)
    processAnimationSprite(animSprite, animation, targetFrameSize, withTags)
    return animSprite
end

---@param charSprite Sprite
---@param charLayer Layer|integer
---@param charF1 integer
---@param animSprite Sprite
---@return Sprite?
local function importAnimationSpriteCels(charSprite, charLayer, charF1, animSprite)
    growSprite(charSprite, animSprite.height)
    copyCels(#animSprite.frames,
        charSprite, charLayer, charF1,
        animSprite, 1, 1)
end

---@param charSprite Sprite
---@param charF1 integer
---@param animSprite Sprite
---@param animName string
---@param animationArgs {[string]: AnimationOptions}
local function importAnimationSpriteTags(charSprite, charF1, animSprite, animName, animationArgs)
    if #animSprite.tags <= 0 then
        return
    end

    -- Avoid creating a tag that goes to the last frame.
    -- If you add a new frame with any tags going to the last frame,
    -- Aseprite extends those tags to the new frame.
    charSprite:newEmptyFrame()

    for _, animTag in ipairs(animSprite.tags) do
        local from = charF1 + animTag.fromFrame.frameNumber - 1
        local to = charF1 + animTag.toFrame.frameNumber - 1
        local tag = charSprite:newTag(from, to)
        local partname, suffix = animTag.name:match("^(.-)([0123]?)$")
        local animArgs = animationArgs[animName..partname]
        tag.name = animArgs.rename..suffix
        tag.aniDir = animTag.aniDir
        local frametime = animArgs.frametime
        if frametime then
            frametime = frametime / 1000
            for f = from, to do
                local frame = charSprite.frames[f]
                frame.duration = frametime
            end
        end
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
---@param args CharacterOptions
local function importStandardSheet(sprite, layer, sheet, animationSet, animationrects, args, withTags)
    local animationArgs = args.animations

    local f1 = 1
    for _, basename in ipairs(animationSet) do
        local animation = animationArgs[basename].enabled and animationSet[basename]
        local srcrect = animationrects and animationrects[basename]
        if animation and srcrect then
            local animSprite = animationSpriteFromSheetRect(sheet, srcrect, animation, sprite.height, withTags)
            importAnimationSpriteCels(sprite, layer, f1, animSprite)
            importAnimationSpriteTags(sprite, f1, animSprite, basename, animationArgs)
            f1 = f1 + #animSprite.frames
            animSprite:close()
        end
    end
end

---@param sprite Sprite
---@param animpaths string[]
---@return table
local function makeItemLayers(sprite, animpaths)
    local layers = {}
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
---@param args CharacterOptions
local function importFromSheet(sheetsprite, args)
    local sprite = Sprite(args.size, args.size)
    sprite:setPalette(sheetsprite.palettes[1])
    sprite.filename = args.outputFile
    app.transaction("Import LPC Character Sheet", function()
        local sheet = Image(sheetsprite)
        importStandardSheet(sprite, 1, sheet, StandardAnimations, StandardSheetRects, args, true)
        local extrasheet = extractExtraSheet(sheet)
        if extrasheet then
            local extraSprite = Sprite(extrasheet.width, extrasheet.height)
            extraSprite:newCel(extraSprite.layers[1], 1, extrasheet)
            extraSprite:saveAs(app.fs.filePathAndTitle(sprite.filename)..".extra.ase")
        end
    end)
    return sprite
end

---@param paletteColors {[string]:boolean}|integer[]
---@param fromSprite Sprite
local function gatherPaletteColors(paletteColors, fromSprite)
    local inpalette = fromSprite.palettes[1]
    for i = 0, #inpalette-1 do
        local rgba = inpalette:getColor(i).rgbaPixel
        local rgbaKey = tostring(rgba)
        if not paletteColors[rgbaKey] then
            paletteColors[rgbaKey] = true
            paletteColors[#paletteColors+1] = rgba
        end
    end
end

---@param sprite Sprite
---@param paletteColors {[string]:boolean}|integer[]
local function usePaletteColors(sprite, paletteColors)
    local palette = Palette(#paletteColors)
    for i = 1, #paletteColors do
        palette:setColor(i-1, paletteColors[i])
    end
    sprite:setPalette(palette)
end

---@param sprite Sprite
---@param itemsdir string
---@param args CharacterOptions
---@return Sprite
---@return Sprite?
local function importItemSheets(sprite, itemsdir, args)
    local paletteColors = {}
    local files = app.fs.listFiles(itemsdir)
    table.sort(files)

    sprite:deleteLayer(sprite.layers[1])
    makeItemLayers(sprite, {itemsdir})

    local extrasprite
    local withTags = true
    for i, file in ipairs(files) do
        file = app.fs.joinPath(itemsdir, file)
        local sheetsprite = app.fs.isFile(file) and app.open(file)
        if sheetsprite then
            local sheet = Image(sheetsprite)
            gatherPaletteColors(paletteColors, sheetsprite)
            sheetsprite:close()

            local layer = sprite.layers[i]

            importStandardSheet(sprite, layer, sheet,
                StandardAnimations, StandardSheetRects, args, withTags)

            withTags = false

            local extrasheet = extractExtraSheet(sheet)
            if extrasheet and not extrasprite then
                extrasprite = Sprite(extrasheet.width, extrasheet.height)
                extrasprite:deleteLayer(extrasprite.layers[1])
            end
            if extrasprite then
                local extralayer = extrasprite:newLayer()
                extralayer.name = layer.name
                if extrasheet then
                    extrasprite:newCel(extralayer, 1, extrasheet)
                end
            end
        end
    end
    if extrasprite then
        extrasprite:saveAs(app.fs.filePathAndTitle(sprite.filename)..".extra.ase")
    end
    usePaletteColors(sprite, paletteColors)
    return sprite, extrasprite
end

---@param sprite Sprite
---@param packdir string
---@param animationSet AnimationSet
---@param args CharacterOptions
---@return Sprite
local function importAnimations(sprite, packdir, animationSet, args)
    local animationArgs = args.animations
    local paletteColors = {}
    for _, animName in ipairs(animationSet) do
        local animArgs = animationArgs[animName]
        if animArgs.enabled ~= false then
            local animation = animationSet[animName]

            local file = app.fs.joinPath(packdir, animation.folder, animName..".png")
            local animSprite = animationSpriteFromFile(file, animation, sprite.height, true)
            if animSprite then
                local f1 = #sprite.frames
                importAnimationSpriteCels(sprite, 1, f1, animSprite)
                importAnimationSpriteTags(sprite, f1, animSprite, animName, animationArgs)
                gatherPaletteColors(paletteColors, animSprite)
                animSprite:close()
            end
        end
    end
    usePaletteColors(sprite, paletteColors)
    return sprite
end

---@param sprite Sprite
---@param packdir string
---@param animationSet AnimationSet
---@param args CharacterOptions
---@return Sprite
local function importItemAnimations(sprite, packdir, animationSet, args)
    sprite:deleteLayer(sprite.layers[1])

    local animationFolders = {}
    for _, animName in ipairs(animationSet) do
        local animation = animationSet[animName]
        local folder = app.fs.joinPath(packdir, animation.folder, animName)
        if app.fs.isDirectory(folder) then
            animationFolders[#animationFolders+1] = folder
        end
    end

    local layerIdxs = makeItemLayers(sprite, animationFolders)

    local paletteColors = {}
    local f1 = 1
    local animationArgs = args.animations
    for _, animName in ipairs(animationSet) do
        local animArgs = animationArgs[animName]
        if animArgs.enabled ~= false then
            local animation = animationSet[animName]

            local folder = app.fs.joinPath(packdir, animation.folder, animName)
            local withTags = true

            for _, file in ipairs(app.fs.listFiles(folder)) do
                file = app.fs.joinPath(folder, file)
                local animSprite = animationSpriteFromFile(file, animation, sprite.height, withTags)
                if animSprite then
                    local i = layerIdxs[app.fs.fileTitle(file)]
                    importAnimationSpriteCels(sprite, i, f1, animSprite)
                    importAnimationSpriteTags(sprite, f1, animSprite, animName, animationArgs)
                    gatherPaletteColors(paletteColors, animSprite)
                    animSprite:close()
                    withTags = false
                    app.frame = f1
                end
            end
            f1 = #sprite.frames
        end
    end
    usePaletteColors(sprite, paletteColors)
    return sprite
end

---@param args CharacterOptions
---@return Sprite
local function importFromPack(args)
    local size = args.size
    local sprite = Sprite(size, size)
    sprite.filename = args.outputFile

    local packdir = app.fs.filePath(args.inputFile)

    local itemsdir = app.fs.joinPath(packdir, "items")
    if app.fs.isDirectory(itemsdir) then
        return importItemSheets(sprite, itemsdir, args)
    end

    local standarddir = app.fs.joinPath(packdir, "standard")
    assert(app.fs.isDirectory(standarddir), "missing standard folder")

    local standardanim1 = app.fs.listFiles(standarddir)[1]
    assert(standardanim1, "empty standard folder")

    standardanim1 = app.fs.joinPath(standarddir, standardanim1)
    if app.fs.isDirectory(standardanim1) then
        return importItemAnimations(sprite, packdir, LPCAnimations, args)
    elseif app.fs.isFile(standardanim1) then
        return importAnimations(sprite, packdir, LPCAnimations, args)
    end
    error("unknown pack structure")
end

local function openInputFile(inputFile)
    if not inputFile then
        return false, "No input file"
    end
    if not app.fs.isFile(inputFile) then
        return false, "Not a file: "..inputFile
    end
    if app.fs.fileExtension(inputFile) == "png" then
        local sprite = app.open(inputFile)
        if sprite then
            if sprite.height < 64 or sprite.width < 64 then
                sprite:close()
                return false, "File too small to hold any frames (min 64x64)."
            end
            return sprite
        end
        return false, "Not a valid png file"
    elseif app.fs.fileName(inputFile) == "character.json" then
        return "character.json"
    end
    return false, "Not a png file"
        .." or a character.json file"
end

local function unzipPack(zipPath)
    local zipFile, zipErr = io.open(zipPath,"rb")
    if not zipFile then
        return nil, zipErr
    end

    local zipContent = zipFile:read("*a")
    zipFile:close()

    local outDir = app.fs.filePathAndTitle(zipPath)
    app.fs.makeDirectory(outDir)

    for _,path,offset,size,packed,crc in zzlib.files(zipContent) do
        local fileContent = packed and zzlib.unzip(zipContent,offset,crc)
            or zipContent:sub(offset,offset+size-1)

        path = app.fs.joinPath(outDir, path)
        -- print(path)
        if path:sub(-1) == "/" then
            app.fs.makeAllDirectories(app.fs.filePath(path))
        else
            local file, fileErr = io.open(path, "w")
            if file then
                file:write(fileContent)
                file:close()
            else
                return nil, fileErr
            end
        end
    end
    return outDir
end

---@param args CharacterOptions
function ImportLPCCharacter(args)
    if app.fs.fileExtension(args.inputFile) == "zip" then
        local outDir, err = unzipPack(args.inputFile)
        if not outDir then
            return nil, err
        end
        args.inputFile = outDir
    end
    if app.fs.isDirectory(args.inputFile) then
        args.inputFile = app.fs.joinPath(args.inputFile, "character.json")
    end
    local inputSprite, whyNot = openInputFile(args.inputFile)
    if type(inputSprite) == "string"
    and app.fs.fileName(inputSprite) == "character.json" then
        local outputSprite = importFromPack(args)
        outputSprite:saveAs(args.outputFile)
        return outputSprite
    elseif inputSprite then
        ---@cast inputSprite Sprite
        local outputSprite = importFromSheet(inputSprite, args)
        inputSprite:close()
        outputSprite:saveAs(args.outputFile)
        return outputSprite
    end
    return nil, whyNot
end
