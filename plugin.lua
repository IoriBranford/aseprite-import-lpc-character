require "lpc"
require "dialog"
local options = require "options"

---@param plugin Plugin
function init(plugin)
    local args = plugin.preferences.lastargs
    if args then
        options.Init(args)
    else
        args = options.New()
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