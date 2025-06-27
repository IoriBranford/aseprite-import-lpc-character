require "import"
local Options = require "options"

local options = Options.New(true)

---@class CLIParams
---@field help string?
---@field convert string?
---@field output string?
---@field framesize string?
---@field frametime string?
---@field loadanims string?
---@field saveanims string?

local params = app.params
---@cast params CLIParams

if params.help
or not params.convert and not params.saveanims and not params.loadanims
then
    print("Usage:")
    print("aseprite -b")
    print("  --script-param convert=inputpath         LPC spritesheet file, sprite pack directory,")
    print("                                           or sprite pack character.json to convert to ase")
    print("  --script-param saveanims=csvfile         save animation options to a csv file")
    print("  --script-param loadanims=csvfile         load csv file saved with saveanims")
    print("  --script-param output=outputfile         defaults to inputpath with extension replaced by .ase")
    print("  --script-param framesize=64|128|192      defaults to 64, loadanims can override")
    print("  --script-param frametime=#               in milliseconds, defaults to 100")
    print("  --script-param help                      show this help only")
    print("  --script cli.lua")
    print("Requires one of: convert, saveanims, loadanims")
    return
end

local size = tonumber(params.framesize)
if size then
    if size ~= 64 or size ~= 128 or size ~= 192 then
        print("size must be 64, 128, or 192")
        return
    end
    options.size = size
end

local globalframetime = tonumber(params.frametime)
if globalframetime then
    options:setGlobalFrameTime(globalframetime)
end

options.animationCsvFile = params.loadanims
if options.animationCsvFile then
    if options:loadAnimationOptionsCsv(options.animationCsvFile) then
        print("Loaded "..options.animationCsvFile)
    else
        return
    end
end

if params.saveanims then
    local savedAnims, saveAnimsError = options:saveAnimationOptionsCsv(params.saveanims)
    if savedAnims then
        print("Saved anims to "..params.saveanims)
    else
        print(saveAnimsError)
    end
end

if params.convert then
    options.inputFile = params.convert
    options.outputFile = params.output
        or app.fs.filePathAndTitle(options.inputFile)..".ase"

    local outputSprite, importError = ImportLPCCharacter(options)
    if outputSprite then
        print(string.format("Converted %s to %s", options.inputFile, options.outputFile))
    else
        print(importError)
    end
end
