local csv = require "ftcsv"

---@class AnimationOptions
---@field rename string
---@field enabled boolean
---@field frametime number? in msecs. parts inherit from their parents instead of having their own
local AnimationOptions = {}
AnimationOptions.__index = AnimationOptions

---@class CharacterOptions
---@field inputFile string
---@field outputFile string
---@field animationCsvFile string
---@field globalframetime number in msecs
---@field size 64|128|192
---@field animations {[string]: AnimationOptions}
local CharacterOptions = {}
CharacterOptions.__index = CharacterOptions

local DefaultFrameTime = 100

---@return CharacterOptions options
function CharacterOptions.New(animsEnabled)
    local options = CharacterOptions.Init({})
    options:reset(animsEnabled)
    return options
end

function CharacterOptions.Init(options)
    return setmetatable(options, CharacterOptions)
end

function CharacterOptions:reset(animsEnabled)
    self.globalframetime = DefaultFrameTime
    self.size = 64
    self:resetAnimationOptions(animsEnabled)
end

function CharacterOptions:resetAnimationOptions(animsEnabled)
    animsEnabled = animsEnabled ~= false
    local allAnimOptions = self.animations
    for _, name in ipairs(LPCAnimations) do
        local animOptions = allAnimOptions[name] or {}
        allAnimOptions[name] = animOptions
        animOptions.enabled = animsEnabled
        animOptions.rename = name
        animOptions.frametime = DefaultFrameTime

        local animation = LPCAnimations[name]
        local parts = animation.parts
        if parts then
            for _, part in ipairs(parts) do
                local partname = name..part
                local partOptions = allAnimOptions[partname] or {}
                allAnimOptions[partname] = partOptions
                partOptions.enabled = animsEnabled
                partOptions.rename = partname
            end
        end
    end
end

function CharacterOptions:setGlobalFrameTime(globalframetime)
    globalframetime = math.max(0, globalframetime)
    self.globalframetime = globalframetime
    for _, animOptions in pairs(self.animations) do
        animOptions.frametime = animOptions.frametime and globalframetime
    end
end

function CharacterOptions:newAnimationOptionsCsv(csvFileName)
    local csvFile, err = io.open(csvFileName, "w")
    if not csvFile then
        return false, err
    end

    csvFile:write("id,enabled,rename,frametime\n")
    for _, name in ipairs(LPCAnimations) do
        local row = string.format("%s,%s,%s,%s\n",
            name, true, name, DefaultFrameTime)
        csvFile:write(row)

        local animation = LPCAnimations[name]
        local parts = animation.parts
        if parts then
            for _, part in ipairs(parts) do
                local partname = name..part

                local partrow = string.format("%s,%s,%s,%s\n",
                    partname, true, partname, "n/a")
                csvFile:write(partrow)
            end
        end
    end
    csvFile:close()
    return true
end

---@param inputFile string
function CharacterOptions:loadAnimationOptionsCsv(inputFile)
    if not app.fs.isFile(inputFile) then
        print("No csv file ", inputFile)
        return
    end

    self:resetAnimationOptions(false)

    local inputTable = csv.parse(inputFile)
    local allAnimOptions = self.animations
    for _, inputOptions in ipairs(inputTable) do
        local animOptions = allAnimOptions[inputOptions.id]
        if animOptions then
            if animOptions.frametime then
                local frametime = tonumber(inputOptions.frametime)
                if frametime then
                    animOptions.frametime = frametime
                end
            end

            local enabled = inputOptions.enabled
            enabled = enabled and enabled:lower()
            animOptions.enabled = enabled ~= "false"

            local rename = inputOptions.rename or ""
            if rename ~= "" then
                animOptions.rename = rename
            end
        else
            print("Unknown animation "
                ..inputOptions.id
                .." referenced in "
                ..inputFile)
        end
    end

    return inputTable
end

return CharacterOptions