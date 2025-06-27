local import = require "import"
require "dialog_animations"

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
---@param args CharacterOptions
function ImportLPCCharacterDialog(args)
    local dialog = Dialog("Import LPC Character")

    local function updateImportButtonEnabled()
        dialog:modify({
            id = "buttonImport",
            enabled = (args.inputFile or "") ~= ""
                and (args.outputFile or "") ~= ""
        })
    end

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
            local path = dialog.data.fileInput
            ---@cast path string
            if app.fs.isFile(path) then
                args.inputFile = path
                updateImportButtonEnabled()
            end
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
            local path = dialog.data.fileOutput
            ---@cast path string
            if not app.fs.isDirectory(path)
            and app.fs.isDirectory(app.fs.filePath(path))
            then
                args.outputFile = path
                updateImportButtonEnabled()
            end
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

    dialog:file {
        id = "fileNewAnimationCsv",
        title = "Create new animation CSV",
        label = "New animation CSV",
        save = true,
        filetypes = {"csv"},
        onchange = function (t)
            local path = dialog.data.fileNewAnimationCsv
            ---@cast path string
            if app.fs.isDirectory(path)
            or not app.fs.isDirectory(app.fs.filePath(path)) then
                return
            end

            local ok, err = args:newAnimationOptionsCsv(path)
            if ok then
                -- TODO open folder or file in system app
                -- app.command.OpenBrowser({filename = fileName})
                -- app.command.OpenInFolder()
                -- app.command.OpenWithApp()
            else
                print(err)
            end
        end
    }

    dialog:file {
        id = "fileLoadAnimationCsv",
        title = "Load from CSV",
        label = "Load animation CSV",
        filename = args.animationCsvFile,
        filetypes = {"csv"},
        open = true,
        onchange = function ()
            local path = dialog.data.fileLoadAnimationCsv
            ---@cast path string
            if app.fs.isFile(path) then
                args:loadAnimationOptionsCsv(path)
                args.animationCsvFile = path
            end
        end
    }

    dialog:button {
        text = "Animation settings...",
        onclick = function()
            ImportAnimationsDialog(args)
        end
    }

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

    dialog:show({
        wait = true, autoscrollbars = true,
    })
end
