local import = require "import"

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
        else
            return false, "Not a valid png file"
        end
    -- elseif inputFile == "character.json" then
    -- return inputFile
    else
        return false, "Not a png file"
            -- .." or a character.json file"
    end
end

---comment
---@param args ImportLPCCharacterArgs
function ImportLPCCharacterDialog(args)
    local inputSprite, whyNot = openInputFile(args.inputFile)
    if not inputSprite then
        app.alert(whyNot)
        return
    end

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
        local animation = import.StandardAnimations[name]
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

    for _, name in ipairs(import.StandardAnimations) do
        animationCheckbox(name)

        local animation = import.StandardAnimations[name]
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
            import.FromSheet(inputSprite, args)
            inputSprite:close()
            dialog:close()
        end
    })

    for _, name in ipairs(import.StandardAnimations) do
        local exportEnabled = args.animationsExportEnabled[name]
        setAnimationExportEnabled(name, exportEnabled)
        local checkboxEnabled = import.sheetHasAnimationRow(import.StandardAnimations[name], 0, inputSprite)
        dialog:modify({
            id = "check"..name,
            enabled = checkboxEnabled
        })
        setAnimationPartsCheckboxesEnabled(name, exportEnabled and checkboxEnabled)
    end

    dialog:show({wait = true})
end

---@param plugin Plugin
function init(plugin)
    local args = plugin.preferences.lastargs
    if not args then
        args = import.NewArgs()
        plugin.preferences.lastargs = args
    end

    plugin:newCommand({
        id="ImportLPCCharacter",
        title="Import current LPC character sheet",
        group="file_import_1",
        onclick=function()
            local sprite = app.sprite
            if not sprite then
                app.alert("No file open.")
                return
            end
            args.inputFile = app.sprite.filename
            args.outputFile = app.fs.filePathAndTitle(app.sprite.filename)..".ase"
            ImportLPCCharacterDialog(args)
        end
    })
end