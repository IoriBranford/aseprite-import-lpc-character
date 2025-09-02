require "import"
require "dialog_animations"

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

    dialog:label {
        text = "Supports ZIP file, character.json, or PNG sheet",
    }

    dialog:file({
        id = "fileInput",
        label = "Input",
        filename = args.inputFile,
        filetypes = {
            "png", "json", "zip"
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
            dialog:close()
            assert(ImportLPCCharacter(args))
        end
    })

    dialog:show({
        wait = true, autoscrollbars = true,
    })
end
