local import = require "import"

---comment
---@param args ImportLPCCharacterArgs
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
    args.outputFile = filename

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
            import.FromSheet(args)
            dialog:close()
        end
    })

    for _, name in ipairs(import.StandardAnimations) do
        local exportEnabled = args.animationsExportEnabled[name]
        setAnimationExportEnabled(name, exportEnabled)
        local checkboxEnabled = import.sheetHasAnimationRow(import.StandardAnimations[name], 0, sheet)
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
        title="Import LPC Character",
        group="file_import_1",
        onclick=function()
            ImportLPCCharacterDialog(args)
        end
    })
end