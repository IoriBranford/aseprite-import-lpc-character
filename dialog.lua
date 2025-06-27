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

    dialog:tab({
        id = "tabAnimations",
        text = "Animations"
    })

    local function updateAnimationOptions()
        local animationArgs = args.animations
        for name, animArgs in pairs(animationArgs) do
            local checkboxId = "checkEnable"..name
            local renameId = "entryRename"..name
            local frametimeId = "numberFrameTime"..name
            local frametime = animArgs.frametime
            if dialog.data[checkboxId] ~= animArgs.enabled then
                dialog:modify {
                    id = checkboxId,
                    selected = animArgs.enabled
                }
                dialog:modify {
                    id = renameId,
                    enabled = animArgs.enabled
                }
                if frametime then
                    dialog:modify {
                        id = frametimeId,
                        enabled = animArgs.enabled
                    }
                end
            end
            if dialog.data[renameId] ~= animArgs.rename then
                dialog:modify {
                    id = renameId,
                    text = animArgs.rename
                }
            end
            if frametime and dialog.data[frametimeId] ~= frametime then
                dialog:modify {
                    id = frametimeId,
                    text = tostring(animArgs.frametime)
                }
            end
        end
    end

    dialog:file {
        id = "fileNewAnimationCsv",
        title = "Create new CSV",
        label = "New CSV",
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
        label = "Load CSV",
        filetypes = {"csv"},
        open = true,
        onchange = function ()
            local path = dialog.data.fileLoadAnimationCsv
            ---@cast path string
            if app.fs.isFile(path) then
                args:loadAnimationOptionsCsv(path)
                updateAnimationOptions()
            end
        end
    }

    local function setAllAnimationFrameTimes(frametime)
        args:setGlobalFrameTime(frametime)
        for _, name in ipairs(LPCAnimations) do
            dialog:modify({
                id = "numberFrameTime"..name,
                text = tostring(frametime),
            })
        end
    end

    dialog:number({
        id = "numberGlobalFrameTime",
        label = "All frame ms",
        text = tostring(args.globalframetime),
        decimals = 0,
        onchange = function()
            args.globalframetime = math.max(0, dialog.data.numberGlobalFrameTime)
            setAllAnimationFrameTimes(args.globalframetime)
        end
    })

    local function setAnimationPartsCheckboxesEnabled(name, enabled)
        local animation = LPCAnimations[name]
        local parts = animation and animation.parts
        if parts then
            for _, part in ipairs(parts) do
                dialog:modify({
                    id = "checkEnable"..name..part,
                    enabled = enabled
                })
                dialog:modify({
                    id = "entryRename"..name..part,
                    enabled = enabled
                })
            end
        end
    end

    local function setAnimationExportEnabled(name, enabled)
        args.animations[name].enabled = enabled
        dialog:modify({
            id = "entryRename"..name,
            enabled = enabled,
        })
        dialog:modify({
            id = "numberFrameTime"..name,
            enabled = enabled,
        })
        setAnimationPartsCheckboxesEnabled(name, enabled)
    end

    local function animationCheckbox(name)
        local id = "checkEnable"..name
        dialog:check({
            id = id,
            hexpand = false,
            label = "Import",
            selected = args.animations[name].enabled,
            onclick = function()
                setAnimationExportEnabled(name, dialog.data[id])
            end,
        })
    end

    local function animationRenameField(name, hasframetimeafter)
        local id = "entryRename"..name
        local label = hasframetimeafter and "Name & ms" or "Name"
        dialog:entry({
            id = id,
            label = label,
            text = args.animations[name].rename,
            onchange = function()
                local rename = dialog.data[id]
                if #rename < 1 then
                    rename = name
                    -- dialog:modify {
                    --     id = id,
                    --     text = name,
                    -- }
                end
                args.animations[name].rename = rename
            end
        })
    end

    local function animationFrameTimeField(name)
        local id = "numberFrameTime"..name
        dialog:number({
            id = id,
            hexpand = false,
            text = tostring(args.animations[name].frametime),
            decimals = 0,
            onchange = function()
                local frametime = dialog.data[id]
                ---@cast frametime number
                if frametime < 0 then
                    frametime = 0
                    -- dialog:modify {
                    --     id = id,
                    --     text = "0",
                    -- }
                end
                args.animations[name].frametime = frametime
            end
        })
    end

    for _, name in ipairs(LPCAnimations) do
        dialog:separator({text = name})
        animationCheckbox(name)
        animationRenameField(name, true)
        animationFrameTimeField(name)

        local animation = LPCAnimations[name]
        local parts = animation and animation.parts
        if parts then
            for _, part in ipairs(parts) do
                dialog:separator({text = name..part})
                animationCheckbox(name..part)
                animationRenameField(name..part)
            end
        end
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
        local exportEnabled = args.animations[name].enabled
        setAnimationExportEnabled(name, exportEnabled)
        local checkboxEnabled = true --import.sheetHasAnimationRow(LPCAnimations[name], 0, inputSprite)
        dialog:modify({
            id = "checkEnable"..name,
            enabled = checkboxEnabled
        })
        setAnimationPartsCheckboxesEnabled(name, exportEnabled and checkboxEnabled)
    end

    dialog:show({
        wait = true, autoscrollbars = true,
    })
end
