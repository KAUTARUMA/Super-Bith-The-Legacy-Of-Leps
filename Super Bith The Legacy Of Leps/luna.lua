local cp = require("customPowerups")
local ld = require("littleDialogue")

function onStart()
    Misc.setWindowTitle("Bith Boy")
    player.character = CHARACTER_MARIO
end

function onKeyboardPress(vkey)
    if vkey == 0x74 then
        Level.load()
    end
end

function onPlayerHarm(eventObj, player, harmType, culprit)
    if player.character == CHARACTER_MARIO then
        local oldPowerup = player.powerup
        
        Routine.run(function()
            Routine.wait(0.9)
            
            if oldPowerup ~= PLAYER_BIG and oldPowerup ~= PLAYER_SMALL then
                player.powerup = PLAYER_BIG
            end
        end)
    end
end