local littleDialogue = require("littleDialogue")

-- Register questions
littleDialogue.registerAnswer("testQuestion",{text = "Oh OK",addText = "That's the spirit!"})
littleDialogue.registerAnswer("testQuestion",{text = "Too much text for my liking",addText = "... I see..."})

littleDialogue.registerAnswer("testQuestion2",{text = "A Toad",addText = "<portrait exampleSusie 1>What's that, some sort of <color blue>dorky frog</color>?"})
littleDialogue.registerAnswer("testQuestion2",{text = "Luigi",addText = "<portrait exampleSusie 3><color green>He's</color> at my house."})