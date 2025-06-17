StandardAnimationSheetRects = {
    "stand", "walk", "hurt", "slash", "thrust", "shoot", "spellcast",
    "idle", "run", "climb", "jump", "sit", "emote",
    "combat_idle", "backslash", "halfslash",
    spellcast = { x = 0, y = 0, w = 448, h = 256 },
    thrust = { x = 0, y = 256, w = 512, h = 256 },
    stand = { x = 0, y = 512, w = 64, h = 256 },
    walk = { x = 64, y = 512, w = 512, h = 256 },
    slash = { x = 0, y = 768, w = 384, h = 256 },
    shoot = { x = 0, y = 1024, w = 832, h = 256 },
    hurt = { x = 0, y = 1280, w = 384, h = 64 },
    climb = { x = 0, y = 1344, w = 384, h = 64 },
    idle = { x = 0, y = 1408, w = 128, h = 256 },
    jump = { x = 0, y = 1664, w = 320, h = 256 },
    sit = { x = 0, y = 1920, w = 192, h = 256 },
    emote = { x = 0, y = 2176, w = 192, h = 256 },
    run = { x = 0, y = 2432, w = 512, h = 256 },
    combat_idle = { x = 0, y = 2688, w = 128, h = 256 },
    backslash = { x = 0, y = 2944, w = 832, h = 256 },
    halfslash = { x = 0, y = 3200, w = 384, h = 256 },
}

---@type AnimationSet
StandardAnimations = {
    "stand", "walk", "hurt", "slash", "thrust", "shoot", "spellcast",
    "idle", "run", "climb", "jump", "sit", "emote",
    "combat_idle", "backslash", "halfslash",

    spellcast = { file = "standard/spellcast.png", s = 64 },
    thrust = { file = "standard/thrust.png", s = 64,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 3 },
            Attack = { 4, 7 }
        },
        [192] = { file = "custom/thrust_oversize.png", s = 192 }
    },
    stand = {
        file = "standard/walk.png", s = 64, x = 0, y = 0, w = 64, h = 256,
        [128] = { file = "custom/walk_128.png", s = 128, x = 0, y = 0, w = 128, h = 512 },
        [192] = { file = "custom/walk_128.png", s = 128, x = 0, y = 0, w = 128, h = 512 },
    },
    walk = {
        file = "standard/walk.png", s = 64, x = 64, y = 0, w = 512, h = 256,
        [128] = { file = "custom/walk_128.png", s = 128, x = 128, y = 0, w = 1024, h = 512 },
        [192] = { file = "custom/walk_128.png", s = 128, x = 128, y = 0, w = 1024, h = 512 },
    },
    slash = { file = "standard/slash.png", s = 64,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 2 }, Attack = { 3, 5 }
        }
    },
    shoot = { file = "standard/shoot.png", s = 64,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 8 }, Attack = { 9, 11 }
        }
    },
    hurt = { file = "standard/hurt.png", s = 64,
        parts = {
            "Knees", "Flat", "RiseToKnees", "RiseToFeet",
            Knees = { 0, 2 }, Flat = { 3, 5 }, RiseToFeet = { 5, 0 }, RiseToKnees = { 5, 3 }
        }
    },

    climb = { file = "standard/climb.png", s = 64 },
    idle = { file = "standard/idle.png", s = 64 },
    jump = { file = "standard/jump.png", s = 64 },
    sit = { file = "standard/sit.png", s = 64,
        parts = {
            "GroundMasc", "GroundFem", "Chair",
            GroundMasc = {0, 0},
            GroundFem = {1, 1},
            Chair = {2, 2}
        }
    },
    emote = { file = "standard/emote.png", s = 64,
        parts = {
            "HandsOnHips", "HandsBehindBack", "Surprised",
            HandsOnHips = {0, 0},
            HandsBehindBack = {1, 1},
            Surprised = {2, 2}
        }
    },
    run = { file = "standard/run.png", s = 64 },
    combat_idle = { file = "standard/combat_idle.png", s = 64 },
    backslash = { file = "standard/backslash.png", s = 64,
        parts = {
            "Windup", "Attack", "BackWindup", "BackAttack",
            Windup = { 0, 0 },
            Attack = { 1, 5 },
            BackWindup = { 6, 7 },
            BackAttack = { 8, 12 }
        },
        [192] = { file = "custom/slash_reverse_oversize.png", s = 192 }
    },
    halfslash = { file = "standard/halfslash.png", s = 64, w = 384,
        parts = {
            "Windup", "Attack",
            Windup = { 0, 0 },
            Attack = { 1, 5 }
        }
    },
}

StandardSheetHeight = 3456