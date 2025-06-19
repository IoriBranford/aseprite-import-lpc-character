---@class LPCAnimation
---@field s 64|128|192?
---@field folder string?
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
        parts = {
            "Windup", "Attack",
            Windup = { 0, 3 }, Attack = { 4, 7 }
        },
    },
    walk = {
        parts = {
            "Stand", "Move",
            Stand = { 0, 0 }, Move = { 1, 8 }
        }
    },
    slash = {
        parts = {
            "Windup", "Attack",
            Windup = { 0, 2 }, Attack = { 3, 5 }
        }
    },
    shoot = {
        parts = {
            "Windup", "Attack",
            Windup = { 0, 8 }, Attack = { 9, 11 }
        }
    },
    hurt = {
        parts = {
            "Knees", "Flat", "RiseToKnees", "RiseToFeet",
            Knees = { 0, 2 }, Flat = { 3, 5 }, RiseToFeet = { 5, 0 }, RiseToKnees = { 5, 3 }
        }
    },
    sit = {
        parts = {
            "GroundMasc", "GroundFem", "Chair",
            GroundMasc = {0, 0},
            GroundFem = {1, 1},
            Chair = {2, 2}
        }
    },
    emote = {
        parts = {
            "HandsOnHips", "HandsBehindBack", "Surprised",
            HandsOnHips = {0, 0},
            HandsBehindBack = {1, 1},
            Surprised = {2, 2}
        }
    },
    backslash = {
        parts = {
            "Windup", "Attack", "BackWindup", "BackAttack",
            Windup = { 0, 0 },
            Attack = { 1, 5 },
            BackWindup = { 6, 7 },
            BackAttack = { 8, 12 }
        },
    },
    halfslash = {
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
        s = 64
    },
    tool_rod = {
        s = 128,
    },
    slash_128 = {
        s = 128,
        parts = StandardAnimations.slash.parts
    },
    backslash_128 = {
        s = 128,
        parts = StandardAnimations.backslash.parts
    },
    halfslash_128 = {
        s = 128,
        parts = StandardAnimations.halfslash.parts
    },
    thrust_oversize = {
        s = 192,
        parts = StandardAnimations.thrust.parts
    },
    slash_oversize = {
        s = 192,
        parts = StandardAnimations.slash.parts
    },
    walk_128 = {
        s = 128,
        parts = StandardAnimations.walk.parts
    },
    thrust_128 = {
        s = 128,
        parts = StandardAnimations.thrust.parts
    },
    slash_reverse_oversize = {
        s = 192,
    },
    whip_oversize = {
        s = 192,
    },
    tool_whip = {
        s = 192,
    },
}

---@type AnimationSet
LPCAnimations = {}

for _, name in ipairs(StandardAnimations) do
    local anim = StandardAnimations[name] or {}
    StandardAnimations[name] = anim
    anim.s = StandardFrameSize
    anim.folder = "standard"
    LPCAnimations[#LPCAnimations+1] = name
    LPCAnimations[name] = anim
end
for _, name in ipairs(CustomAnimations) do
    local anim = CustomAnimations[name]
    anim.folder = "custom"
    LPCAnimations[#LPCAnimations+1] = name
    LPCAnimations[name] = anim
end