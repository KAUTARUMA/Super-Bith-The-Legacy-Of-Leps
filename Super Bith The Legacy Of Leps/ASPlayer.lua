-- by KAUTARUMA and the power of the internet

local json = require("json")
local ASPlayer = {}
ASPlayer.__index = ASPlayer

function ASPlayer.new(jsonPath, texturePath)
    local f = assert(io.open(Misc.resolveFile(jsonPath), "r"))
    local data = json.parse(f:read("*a"))
    f:close()

    local self = setmetatable({}, ASPlayer)
    self.frames = data.frames

    self.tags = {}

    for _, tag in ipairs(data.meta.frameTags or {}) do
        self.tags[tag.name] = tag
    end

    self.texture = Graphics.loadImageResolved(texturePath or data.meta.image)
    self.width = data.meta.size.w
    self.height = data.meta.size.h

    self.scale = 1
    self.rotation = 0
    self.flipX = false
    self.flipY = false
    self.anchorX = 0.5
    self.anchorY = 0.5

    self.speed = 1

    self.playing = false
    self.currentTime = 0
    self.currentFrame = 1
    self.currentTag = nil
    self.loop = true

    return self
end

function ASPlayer:play(tagName, force)
    if force == nil then force = false end

    if (self.currentTag ~= nil and
        self.currentTag.name == tagName and
        self.playing == true and
        force == false
    ) then return end

    local tag = self.tags[tagName]
    if not tag then
        error("ASPlayer: tag '" .. tostring(tagName) .. "' not found.")
    end
    
    self.currentTag = tag
    self.currentFrame = tag.from + 1
    self.currentTime = 0
    self.playing = true
end

function ASPlayer:stop()
    self.playing = false
end

function ASPlayer:update(dt)
    if not self.playing or self.currentTag == nil then return end
    
    self.currentTime = self.currentTime + (dt * 1000 * self.speed) -- convert to ms
    local frame = self.frames[self.currentFrame]
    
    if self.currentTime >= frame.duration then
        self.currentTime = self.currentTime - frame.duration
        self.currentFrame = self.currentFrame + 1

        if self.currentFrame > self.currentTag.to + 1 then
            if self.currentTag["repeat"] ~= "1" then
                self.currentFrame = self.currentTag.from + 1
            else
                self.playing = false
                self.currentFrame = self.currentTag.to + 1
            end
        end
    end
end

function ASPlayer:draw(x, y, scale, rotation)
    local frame = self.frames[self.currentFrame]
    if not frame then return end
    
    local tex = self.texture
    local fx, fy, fw, fh = frame.frame.x, frame.frame.y, frame.frame.w, frame.frame.h
    local ssx, ssy = frame.spriteSourceSize.x, frame.spriteSourceSize.y
    local sw, sh = frame.sourceSize.w, frame.sourceSize.h

    scale = scale or self.scale
    rotation = rotation or self.rotation

    local sx = self.flipX and -scale or scale
    local sy = self.flipY and -scale or scale

    -- anchor point
    local originX = x - sw * self.anchorX * scale
    local originY = y - sh * self.anchorY * scale
    
    local drawX = originX + ssx * scale
    local drawY = originY + ssy * scale

    if self.flipX then 
        drawX = originX + sw + (sw - ssx - fw) * scale 
    end

    if self.flipY then 
        drawY = originY + sh + (sh - ssy - fh) * scale 
    end

    local drawW = fw * sx
    local drawH = fh * sy

    -- rotation center
    local cx = x
    local cy = y
    local cosr = math.cos(rotation)
    local sinr = math.sin(rotation)

    local function rotate(px, py)
        local dx, dy = px - cx, py - cy
        return cx + dx * cosr - dy * sinr, cy + dx * sinr + dy * cosr
    end

    local v1x, v1y = rotate(drawX, drawY)
    local v2x, v2y = rotate(drawX + drawW, drawY)
    local v3x, v3y = rotate(drawX + drawW, drawY + drawH)
    local v4x, v4y = rotate(drawX, drawY + drawH)

    local tw, th = self.width, self.height

    Graphics.glDraw{
        texture = tex,
        primitive = Graphics.GL_TRIANGLE_FAN,
        sceneCoords = true,
        priority = -50,
        vertexCoords = {
            v1x, v1y,
            v2x, v2y,
            v3x, v3y,
            v4x, v4y
        },
        textureCoords = {
            fx / tw,        fy / th,
            (fx + fw) / tw, fy / th,
            (fx + fw) / tw, (fy + fh) / th,
            fx / tw,        (fy + fh) / th
        }
    }
end

return ASPlayer
