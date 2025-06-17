---@class LPCAnimation
---@field s 64|128|192
---@field x integer? default to 0
---@field y integer? default to 0
---@field w integer? default to image width
---@field h integer? default to image height
---@field file string
---@field columns integer?
---@field rows integer?
---@field parts {[string]: integer[]}?
---@field [integer] LPCAnimation

---@alias AnimationSet {[string]:LPCAnimation,[integer]:string}

require "lpc.standardanimations"
require "lpc.customanimations"