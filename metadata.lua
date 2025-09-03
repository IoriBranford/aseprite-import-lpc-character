---@class PointMetadata
---@field x integer
---@field y integer

---@class SizeMetadata
---@field w integer
---@field h integer

---@class RectMetadata:PointMetadata,SizeMetadata

---@class Metadata
---@field frameTags TagMetadata[]?
---@field slices SliceMetadata[]?
local Metadata = {}

---@class TagMetadata
---@field name string
---@field from integer
---@field to integer
---@field direction "forward"|"reverse"|"pingpong"|"pingpong_reverse"
---@field repeat integer|0
---@field data string?

---@class SliceMetadata
---@field name string
---@field keys SliceKeyMetadata[]?

---@class SliceKeyMetadata
---@field frame integer
---@field bounds RectMetadata
---@field center RectMetadata?
---@field pivot {x:integer, y:integer}?

---@return Metadata?
---@return string?
function Metadata.New(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, err
    end
    local content = file:read("a")
    file:close()
    return json.decode(content)
end

---@param sprite Sprite
function Metadata.apply(meta, sprite)
    local AniDirMap = {
        forward = AniDir.FORWARD,
        reverse = AniDir.REVERSE,
        pingpong = AniDir.PING_PONG,
        pingpong_reverse = AniDir.PING_PONG_REVERSE,
    }
    if meta.frameTags then
        for _, tagMeta in ipairs(meta.frameTags) do
            for _, tag in ipairs(sprite.tags) do
                if tag.name == tagMeta.name then
                    if tagMeta.data then
                        tag.data = tagMeta.data
                    end
                    local dir = tagMeta.direction
                        and AniDirMap[tagMeta.direction]
                    if dir then
                        tag.aniDir = dir
                    end
                    if tagMeta["repeat"] then
                        tag.repeats = tagMeta["repeat"]
                    end
                end
            end
        end
    end
    if meta.slices then
        for _, sliceMeta in ipairs(meta.slices) do
            local slice = sprite:newSlice()
            slice.name = sliceMeta.name
            for _, key in ipairs(sliceMeta.keys) do
                app.frame = key.frame
                local bounds, center, pivot = key.bounds, key.center, key.pivot
                slice.bounds = Rectangle(bounds.x, bounds.y, bounds.w, bounds.h)
                if center then
                    slice.center = Rectangle(center.x, center.y, center.w, center.h)
                end
                if pivot then
                    slice.pivot = Point(pivot.x, pivot.y)
                end
            end
        end
    end
end

return Metadata