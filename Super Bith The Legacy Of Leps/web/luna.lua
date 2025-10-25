local pinkBumperIDs = {582, 584, 594, 596}

function onStart()
    for _, ID in ipairs(pinkBumperIDs) do
        NPC.config[ID].bouncenpc = true
    end
end