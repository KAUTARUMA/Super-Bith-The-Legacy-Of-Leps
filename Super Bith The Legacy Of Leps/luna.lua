local ct = require("coyotetime")
local cp = require("customPowerups")
local ld = require("littleDialogue")

ct.frames = 7

function onStart()
    Misc.setWindowTitle("Bith Boy")
    player.character = CHARACTER_MARIO
end

function onKeyboardPress(vkey)
    if vkey == 0x74 then
        Level.load()
    end
end