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

            local ok, err = args:saveAnimationOptionsCsv(path)
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
            dialog:close()
            assert(ImportLPCCharacter(args))
        end
    })

    dialog:show({
        wait = true, autoscrollbars = true,
    })
end
