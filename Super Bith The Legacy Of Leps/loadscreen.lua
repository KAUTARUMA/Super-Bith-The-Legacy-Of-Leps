do -- i dont really know what this does but its from betterified and it needs to be here to work so um lol
    function table.clone(t)
        local rt = {};
        for k,v in pairs(t) do
            rt[k] = v;
        end
        setmetatable(rt, getmetatable(t));
        return rt;
    end
    
    local function exists(path)
        local f = io.open(path,"r")

        if f ~= nil then
            f:close()
            return true
        else
            return false
        end
    end

    Misc.resolveFile = (function(path)
        local inScriptPath = getSMBXPath().. "\\scripts\\".. path
        local inEpisodePath = _episodePath.. path

        return (exists(path) and path) or (exists(inEpisodePath) and inEpisodePath) or (exists(inScriptPath) and inScriptPath) or nil
    end)

    Misc.resolveGraphicsFile = Misc.resolveFile

    -- Make require work better
    local oldRequire = require

    function require(path)
        local inScriptPath = getSMBXPath().. "\\scripts\\".. path.. ".lua"
        local inScriptBasePath = getSMBXPath().. "\\scripts\\base\\".. path.. ".lua"
        local inEpisodePath = _episodePath.. path.. ".lua"

        local path = (exists(inEpisodePath) and inEpisodePath) or (exists(inScriptPath) and inScriptPath) or (exists(inScriptBasePath) and inScriptBasePath)
        assert(path ~= nil,"module '".. path.. "' not found.")

        return oldRequire(path)
    end

    -- lunatime
    _G.lunatime = require("engine/lunatime")

    -- Color
    _G.Color = require("engine/color")
end

-- fix for wave

_G.elapsedFrames = 0
function lunatime.drawtime()
    return _G.elapsedFrames / 300.0
end

package.path = package.path .. ";./scripts/?.lua"

local loadScreenPath = mem(0x00B2C61C, FIELD_STRING) .. "loadScreen/"

local bgImage = Graphics.loadImage(loadScreenPath .. "bg.png")
local bithImage = Graphics.loadImage(loadScreenPath .. "bith.png")
local gradientImage = Graphics.loadImage(loadScreenPath .. "gradientcircle.png")

local outlineColor = Color.fromHexRGB(0x79b1d7)

local rng = require("base/rng")
local textplus = require("textplus")

local fortuneFile = io.open(loadScreenPath .. "fortunes.txt", "r")
local fortunes = {}
local fortuneNum = 1

local bithPos = {
    x = 140, y = 300
}

local bigBubblePos = {
    x = bithPos.x + 250,
    y = bithPos.y - 110
}


for line in fortuneFile:lines() do
    table.insert(fortunes, line)
end

local hasInit = false
function init()
    hasInit = true
    
    fortuneNum = rng.randomInt(1, #fortunes)
    _G.elapsedFrames = 0
end

function onDraw()
    if not hasInit then init() end

    _G.elapsedFrames = _G.elapsedFrames + 1

    Graphics.drawImageWP(bithImage, bithPos.x, bithPos.y, 1)
    Graphics.drawBox {
        x = 0,
        y = 0,
        width = 800,
        height = 600,
        texture = bgImage,
        priority = -99
    }

    drawBubble()

    textplus.print {
        x = bigBubblePos.x + 100,
        y = bigBubblePos.y + 55,
        xscale = 2,
        yscale = 2,
        text = "<align center><i>\""..fortunes[fortuneNum].."\"</i></align>",
        pivot = {0.5, 0.5},
        maxWidth = 200,
        priority = 1,
        color = outlineColor
    }

    textplus.print {
        x = 400,
        y = 60,
        xscale = 4,
        yscale = 4,
        text = "<wave 5>LOADING...</wave>",
        pivot = {0.5, 0.5},
        maxWidth = 200,
        priority = 1,
        color = outlineColor
    }

    if _G.elapsedFrames < 30 then
        Graphics.drawBox {
            x = 0,
            y = 0,
            width = 800,
            height = 600,
            color = Color(0, 0, 0, remap(_G.elapsedFrames, 0, 30, 1, 0)),
            priority = 99
        }
    end
end

function drawGradientCircle(x, y, radius, sinOffset, usetex)
    if usetex == nil then usetex = true end

    x = x + (math.sin((_G.elapsedFrames / 50) + sinOffset) * (radius / 20))
    y = y + (math.cos((_G.elapsedFrames / 50) + (sinOffset * 2)) * (radius / 20))

    if usetex then
        Graphics.drawBox {
            x = x,
            y = y,
            width = radius * 2,
            height = radius * 2,
            texture = gradientImage,
            centered = true
        }
    else
        Graphics.drawCircle {
            x = x,
            y = y,
            radius = radius,
            color = Color.white
        }
    end

    Graphics.drawCircle {
        x = x,
        y = y,
        radius = radius + 4,
        color = outlineColor,
        priority = -20
    }
end

function drawBubble()
    drawGradientCircle (
        bithPos.x + 180,
        bithPos.y + 70,
        5,
        50
    )

    drawGradientCircle (
        bithPos.x + 180 + 30,
        bithPos.y + 70 - 20,
        10,
        1
    )

    for j=0, 2 do
        local amount = (j == 1 and 4 or 3)
        for i=0, amount do
            local offsetIDX = (j + i) * 500

            local offset = {
                x = 0,
                y = 0
            }

            offset.x = offset.x + (amount == 3 and 25 or 0)

            if j ~= 1 then
                local mid1 = math.floor(amount / 2)
                if i == mid1 or i == mid1 + 1 then
                    offset.y = -10 * (j > 1 and -1 or 1)
                end
            end

            drawGradientCircle (
                bigBubblePos.x + (i * 50) + offset.x,
                bigBubblePos.y + (j * 50) + offset.y,
                50,
                offsetIDX,
                j == 2
            )
        end
    end
end

function remap(n, oldMin, oldMax, min, max)
  return (min + ((max - min) * ((n - oldMin) / (oldMax - oldMin))))
end