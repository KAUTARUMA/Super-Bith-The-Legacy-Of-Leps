local littleDialogue = require("littleDialogue")
local cutscenes = require("cutscenes")

littleDialogue.registerAnswer("okaypim", {text = "", chosenFunction = function() 
    local sec = Section(0)
    sec.musicID = 1
end})