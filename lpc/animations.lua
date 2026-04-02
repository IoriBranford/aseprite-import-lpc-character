---@class LPCAnimation
---@field name string
---@field base string?
---@field s 64|128|192
---@field rect Rectangle
---@field folder string
---@field parts AnimationParts?

---@alias AnimationSet {[string]:LPCAnimation,[integer]:string}
---@alias AnimationParts {[integer]:string, [string]: integer[]}

StandardFrameSize = 64

---@type AnimationSet
StandardAnimations = {
    "spellcast",
    "thrust",
    "walk",
    "slash",
    "shoot",
    "hurt",
    "climb",
    "idle",
    "jump",
    "sit",
    "emote",
    "run",
    "combat_idle",
    "backslash",
    "halfslash",

    thrust = {
        name = "thrust",
        s = StandardFrameSize,
        rect = StandardSheetRects.thrust,
        folder = "standard",
        parts = {
            "Windup", "Attack",
            Windup = { 0, 3 }, Attack = { 4, 7 }
        },
    },
    walk = {
        name = "walk",
        s = StandardFrameSize,
        rect = StandardSheetRects.walk,
        folder = "standard",
        parts = {
            "Stand", "Move",
            Stand = { 0, 0 }, Move = { 1, 8 }
        }
    },
    slash = {
        name = "slash",
        s = StandardFrameSize,
        rect = StandardSheetRects.slash,
        folder = "standard",
        parts = {
            "Windup", "Attack",
            Windup = { 0, 2 }, Attack = { 3, 5 }
        }
    },
    shoot = {
        name = "shoot",
        s = StandardFrameSize,
        rect = StandardSheetRects.shoot,
        folder = "standard",
        parts = {
            "Windup", "Attack",
            Windup = { 0, 8 }, Attack = { 9, 11 }
        }
    },
    hurt = {
        name = "hurt",
        s = StandardFrameSize,
        rect = StandardSheetRects.hurt,
        folder = "standard",
        parts = {
            "Knees", "Flat", "RiseToKnees", "RiseToFeet",
            Knees = { 0, 2 }, Flat = { 3, 5 }, RiseToFeet = { 5, 0 }, RiseToKnees = { 5, 3 }
        }
    },
    sit = {
        name = "sit",
        s = StandardFrameSize,
        rect = StandardSheetRects.sit,
        folder = "standard",
        parts = {
            "GroundMasc", "GroundFem", "Chair",
            GroundMasc = {0, 0},
            GroundFem = {1, 1},
            Chair = {2, 2}
        }
    },
    emote = {
        name = "emote",
        s = StandardFrameSize,
        rect = StandardSheetRects.emote,
        folder = "standard",
        parts = {
            "HandsOnHips", "HandsBehindBack", "Surprised",
            HandsOnHips = {0, 0},
            HandsBehindBack = {1, 1},
            Surprised = {2, 2}
        }
    },
    backslash = {
        name = "backslash",
        s = StandardFrameSize,
        rect = StandardSheetRects.backslash,
        folder = "standard",
        parts = {
            "Windup", "Attack", "BackWindup", "BackAttack",
            Windup = { 0, 0 },
            Attack = { 1, 5 },
            BackWindup = { 6, 7 },
            BackAttack = { 8, 12 }
        },
    },
    halfslash = {
        name = "halfslash",
        s = StandardFrameSize,
        rect = StandardSheetRects.halfslash,
        folder = "standard",
        parts = {
            "Windup", "Attack",
            Windup = { 0, 0 },
            Attack = { 1, 5 }
        }
    },
}

---@type AnimationSet
CustomAnimations = {
    "wheelchair",
    "tool_rod",
    "slash_128",
    "backslash_128",
    "halfslash_128",
    "thrust_oversize",
    "slash_oversize",
    "walk_128",
    "thrust_128",
    "slash_reverse_oversize",
    "whip_oversize",
    "tool_whip",

    wheelchair = {
        name = "wheelchair",
        rect = CustomSheetRects.wheelchair,
        folder = "custom",
        s = 64
    },
    tool_rod = {
        name = "tool_rod",
        rect = CustomSheetRects.tool_rod,
        folder = "custom",
        s = 128,
    },
    slash_128 = {
        name = "slash_128",
        rect = CustomSheetRects.slash_128,
        folder = "custom",
        s = 128,
        base = "slash",
        parts = StandardAnimations.slash.parts
    },
    backslash_128 = {
        name = "backslash_128",
        rect = CustomSheetRects.backslash_128,
        folder = "custom",
        s = 128,
        base = "backslash",
        parts = StandardAnimations.backslash.parts
    },
    halfslash_128 = {
        name = "halfslash_128",
        rect = CustomSheetRects.halfslash_128,
        folder = "custom",
        s = 128,
        base = "halfslash",
        parts = StandardAnimations.halfslash.parts
    },
    thrust_oversize = {
        name = "thrust_oversize",
        rect = CustomSheetRects.thrust_oversize,
        folder = "custom",
        s = 192,
        base = "thrust",
        parts = StandardAnimations.thrust.parts
    },
    slash_oversize = {
        name = "slash_oversize",
        rect = CustomSheetRects.slash_oversize,
        folder = "custom",
        s = 192,
        base = "slash",
        parts = StandardAnimations.slash.parts
    },
    walk_128 = {
        name = "walk_128",
        rect = CustomSheetRects.walk_128,
        folder = "custom",
        s = 128,
        base = "walk",
        parts = StandardAnimations.walk.parts
    },
    thrust_128 = {
        name = "thrust_128",
        rect = CustomSheetRects.thrust_128,
        folder = "custom",
        s = 128,
        base = "thrust",
        parts = StandardAnimations.thrust.parts
    },
    slash_reverse_oversize = {
        name = "slash_reverse_oversize",
        rect = CustomSheetRects.slash_reverse_oversize,
        folder = "custom",
        s = 192,
    },
    whip_oversize = {
        name = "whip_oversize",
        rect = CustomSheetRects.whip_oversize,
        folder = "custom",
        s = 192,
    },
    tool_whip = {
        name = "tool_whip",
        rect = CustomSheetRects.tool_whip,
        folder = "custom",
        s = 192,
    },
}

---@type AnimationSet
LPCAnimations = {}

for _, name in ipairs(StandardAnimations) do
    local anim = StandardAnimations[name] or {
        name = name,
        s = StandardFrameSize,
        folder = "standard",
        rect = StandardSheetRects[name]
    }
    StandardAnimations[name] = anim
    LPCAnimations[#LPCAnimations+1] = name
    LPCAnimations[name] = anim
end
for _, name in ipairs(CustomAnimations) do
    local anim = CustomAnimations[name]
    LPCAnimations[#LPCAnimations+1] = name
    LPCAnimations[name] = anim
end