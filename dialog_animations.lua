---@param args CharacterOptions
function ImportAnimationsDialog(args)
    local dialog = Dialog("Animation import settings")

    local function setAllAnimationFrameTimes(frametime)
        args:setGlobalFrameTime(frametime)
        for _, name in ipairs(LPCAnimations) do
            dialog:modify({
                id = "numberFrameTime"..name,
                text = tostring(frametime),
            })
        end
    end

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
        local animOptions = args.animations[name]
        animOptions.enabled = enabled
        dialog:modify({
            id = "entryRename"..name,
            enabled = enabled,
        })
        if animOptions.frametime then
            dialog:modify({
                id = "numberFrameTime"..name,
                enabled = enabled,
            })
        end
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

    dialog:separator { text = "All animations" }

    dialog:button {
        label = "Import",
        text = "All",
        hexpand = false,
        onclick = function()
            for name in pairs(args.animations) do
                local enabled = true
                setAnimationExportEnabled(name, enabled)
                dialog:modify {
                    id = "checkEnable"..name,
                    selected = enabled
                }
            end
        end
    }

    dialog:button {
        text = "No sub",
        hexpand = false,
        onclick = function()
            for name, animOptions in pairs(args.animations) do
                local enabled = animOptions.frametime ~= nil
                setAnimationExportEnabled(name, enabled)
                dialog:modify {
                    id = "checkEnable"..name,
                    selected = enabled
                }
            end
        end
    }

    dialog:button {
        text = "None",
        hexpand = false,
        onclick = function()
            for name in pairs(args.animations) do
                local enabled = false
                setAnimationExportEnabled(name, enabled)
                dialog:modify {
                    id = "checkEnable"..name,
                    selected = enabled
                }
            end
        end
    }

    dialog:number({
        id = "numberGlobalFrameTime",
        label = "Frame ms",
        text = tostring(args.globalframetime),
        decimals = 0,
        onchange = function()
            args.globalframetime = math.max(0, dialog.data.numberGlobalFrameTime)
            setAllAnimationFrameTimes(args.globalframetime)
        end
    })

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

    for name, animOptions in pairs(args.animations) do
        setAnimationExportEnabled(name, animOptions.enabled)
    end

    dialog:show {wait = true, autoscrollbars = true}
end