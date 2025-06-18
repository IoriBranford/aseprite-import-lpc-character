require "lpc"
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
    elseif app.fs.fileName(inputFile) == "character.json" then
        return "character.json"
    else
        return false, "Not a png file"
            .." or a character.json file"
    end
end

---comment
---@param args ImportLPCCharacterArgs
function ImportLPCCharacterDialog(args)
    local dialog = Dialog("Import LPC Character")

    local function updateImportButtonEnabled()
        dialog:modify({
            id = "buttonImport",
            enabled = (args.inputFile or "") ~= ""
                and (args.outputFile or "") ~= ""
        })
    end

    dialog:tab({
        id = "tabImport",
        text = "Import",
    })
    dialog:file({
        id = "fileInput",
        label = "Input",
        filename = args.inputFile,
        filetypes = {
            "png", "json"
        },
        open = true,
        save = false,
        onchange = function()
            args.inputFile = dialog.data.fileInput
            updateImportButtonEnabled()
        end
    })
    dialog:file({
        id = "fileOutput",
        label = "Output",
        filename = args.outputFile,
        filetypes = { "ase", "aseprite" },
        open = false,
        save = true,
        onchange = function()
            args.outputFile = dialog.data.fileOutput
            updateImportButtonEnabled()
        end
    })

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

    dialog:tab({
        id = "tabAnimations",
        text = "Animations"
    })

    local function setAnimationPartsCheckboxesEnabled(name, enabled)
        local animation = LPCAnimations[name]
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

    for _, name in ipairs(LPCAnimations) do
        animationCheckbox(name)

        local animation = LPCAnimations[name]
        local parts = animation and animation.parts
        if parts then
            for _, part in ipairs(parts) do
                animationCheckbox(name..part)
            end
        end
        dialog:newrow()
    end

    dialog:endtabs({})

    dialog:button({
        id = "buttonImport",
        text = "Import",
        enabled = (args.inputFile or "") ~= "" and (args.outputFile or "") ~= "",
        onclick = function()
            local inputSprite, whyNot = openInputFile(args.inputFile)
            if inputSprite == "character.json" then
                local outputSprite = import.FromPack(args)
                outputSprite:saveAs(args.outputFile)
            elseif inputSprite then
                local outputSprite = import.FromSheet(inputSprite, args)
                inputSprite:close()
                outputSprite:saveAs(args.outputFile)
            else
                app.alert(whyNot)
            end
            dialog:close()
        end
    })

    for _, name in ipairs(LPCAnimations) do
        local exportEnabled = args.animationsExportEnabled[name]
        setAnimationExportEnabled(name, exportEnabled)
        local checkboxEnabled = true --import.sheetHasAnimationRow(LPCAnimations[name], 0, inputSprite)
        dialog:modify({
            id = "check"..name,
            enabled = checkboxEnabled
        })
        setAnimationPartsCheckboxesEnabled(name, exportEnabled and checkboxEnabled)
    end

    dialog:show({wait = true, autoscrollbars = true})
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
        title="Import LPC character",
        group="file_import_1",
        onclick=function()
            ImportLPCCharacterDialog(args)
        end
    })

    plugin:newCommand({
        id="ImportCurrentLPCCharacter",
        title="Import current LPC character",
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