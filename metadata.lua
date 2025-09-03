---@class PointMetadata
---@field x integer
---@field y integer

---@class SizeMetadata
---@field w integer
---@field h integer

---@class RectMetadata:PointMetadata,SizeMetadata

---@class Metadata
---@field frameTags TagMetadata[]?
---@field layers LayerMetadata[]?
---@field slices SliceMetadata[]?
local Metadata = {}

---@class TagMetadata
---@field name string
---@field from integer
---@field to integer
---@field direction "forward"|"reverse"|"pingpong"|"pingpong_reverse"
---@field repeat integer|0
---@field data string?

---@class LayerMetadata
---@field name string
---@field data string?
---@field cels CelMetadata[]?

---@class CelMetadata
---@field frame integer
---@field data string?

---@class SliceMetadata
---@field name string
---@field keys SliceKeyMetadata[]?
---@field data string?

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
    return json.decode(content).meta
end

---@param meta Metadata
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
            if sliceMeta.data then
                slice.data = sliceMeta.data
            end
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
    if meta.layers then
        for _, layerMeta in ipairs(meta.layers) do
            local celsMeta ---@type {[integer]:CelMetadata}?
            if layerMeta.cels then
                celsMeta = {}
                for _, celMeta in ipairs(layerMeta.cels) do
                    celsMeta[celMeta.frame] = celMeta
                end
            end

            for _, layer in ipairs(sprite.layers) do
                if layer.name == layerMeta.name then
                    if layerMeta.data then
                        layer.data = layerMeta.data
                    end
                    if celsMeta then
                        local cels = layer.cels
                        for f, celMeta in pairs(celsMeta) do
                            local cel = cels[f+1]
                            if cel then
                                if celMeta.data then
                                    cel.data = celMeta.data
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return Metadata