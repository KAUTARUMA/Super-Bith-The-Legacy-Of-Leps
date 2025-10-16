local littleDialogue = require("littleDialogue")
local disableInput = false

local section0
local oldBoundary = {}

local cutscenes = {}

local hasRecievedEvent = {}
local key = {}

function cutscenes.onInitAPI()
    registerEvent(cutscenes,"onStart")
    registerEvent(cutscenes,"onTick")
    registerEvent(cutscenes,"onEvent")
end

function cutscenes.onStart()
    section0 = Section(0)

    oldBoundary = section0.boundary

    oldBoundary.left = section0.boundary.left
    oldBoundary.right = section0.boundary.right
    oldBoundary.top = section0.boundary.top
    oldBoundary.bottom = section0.boundary.bottom

    local sectionBounds = section0.boundary
    sectionBounds.right = sectionBounds.left + 1000
    section0.boundary = sectionBounds

    key = NPC.get()[4]
end

function cutscenes.onTick()
    if disableInput then
        for k in pairs(player.keys) do
            player.keys[k] = false
        end
    end
end

function cutscenes.onEvent(eventName)
    if hasRecievedEvent[eventName] then return end
    hasRecievedEvent[eventName] = true
    
    if eventName == "Locked Cutscene" then Routine.run(cutscenes.lockedCutscene) end

    if eventName == "Key Cutscene" then
        if key.x > -199168 then
            hasRecievedEvent["Key Cutscene"] = false
            return
        end

        Routine.run(cutscenes.keyCutscene) 
    end

    -- have them react when you die
end 

function cutscenes.lockedCutscene()
    local charlie = NPC.get()[1]
    local pim = NPC.get()[2]

    charlie.msg = ""
    pim.msg = ""

    if true then
        disableInput = true
        player.speedX = math.min(math.abs(player.speedX), 2) * (player.speedX < 0 and -1 or 1)

        charlie.speedX = 0.001

        littleDialogue.create(
            {
                text = "<boxStyle dr>It's locked.<page>"..
                "<portrait charlie 4>Oh what? The door is locked?"
            , pauses = false}
        )

        Routine.waitSignal("dialogueFinished")

        pim.speedX = 0.001 -- lazy
        while charlie.x < -199420 do
            charlie.speedX = 5
            Routine.skip()
        end

        charlie.speedX = 0

        Routine.run(function()
            Routine.waitSignal("movePim")

            while pim.x < -199460 do
                pim.speedX = 5
                Routine.skip()
            end

            pim.speedX = 0
        end)

        Routine.wait(1)

        littleDialogue.create(
            {
                text = "<boxStyle dr><portrait charlie 4>Oh damn, it is.<page>"..
                "<portrait charlie 2>Well, I don't have a key on me. Pim, do you?<page>"..
                "<signal movePim><portrait pim2 1>No, I don't think so...<page>"..
                "<portrait charlie 4>Well, uh, <portrait charlie 2>okay then.<page>"..
                "<portrait pim2 1>I could try contacting the boss?<page>"..
                "<portrait charlie 1>No, no. Uh. I don't think thats a great idea to do today.<page>I think hes out like, with his son and stuff.<page>"..
                "<portrait pim2 1>The little homonculus one?<page>"..
                "<portrait charlie 1>Yeah, yeah.<page>"..
                "<portrait none>..."
            , pauses = false}
        )

        Routine.waitSignal("dialogueFinished")

        Routine.wait(2)
        charlie.speedX = -0.001
        Routine.wait(1)
        charlie.speedX = 0.001
        Routine.wait(1)

        littleDialogue.create(
            {
                text = "<boxStyle dr><portrait charlie 4>Well, okay. Uh. <portrait charlie 1>Heres what we can do.<page>"..
                "I think I left a spare key over to the right<page>"..
                "Across that conveniently placed obstacle course<page>"..
                "<portrait pim2 1>...<page>"..
                "Charlie, why is it over there again?<page>"..
                "<portrait charlie 2>Because of the whole glep thing, <portrait charlie 1>remember?<page>"..
                "<portrait pim2 1>Oh, oh, right.<page>"..
                "<portrait charlie 2>But yeah uh, if you could grab that for us that'd be great.<page>"..
                "<portrait charlie 4>I mean like, no pressure, I can just do it myself.<page>"..
                "<portrait none>You reassure Charlie that it's okay.<page>"..
                "<portrait charlie 4>Well, alright then! <portrait charlie 2>uh yeah.<page>"..
                "<portrait charlie 1>That'd be great."            
            , pauses = false}
        )

        Routine.waitSignal("dialogueFinished")
    end

    if player.powerup == 1 then
        littleDialogue.create({text = "<boxStyle dr><portrait charlie 4>Oh yeah, take this, it'll make your life easier and stuff.", pauses = false})
        Routine.waitSignal("dialogueFinished")

        NPC.spawn(9, player.x, player.y, player.section)
    end

    section0.boundary = oldBoundary

    disableInput = false

    for i, npc in ipairs({charlie, pim}) do
        npc.spawnX = npc.x
        npc.spawnY = npc.y
        npc.spawnDirection = npc.direction
    end
end

function cutscenes.keyCutscene()
    Routine.skip()

    disableInput = true
    player.speedX = math.min(math.abs(player.speedX), 2) * (player.speedX < 0 and -1 or 1)
    
    littleDialogue.create(
        {
            text = "<boxStyle dr><portrait charlie 4>Oh sweet, you got it!<page>"..
            "<portrait pim2 1>Horray! 3 cheers for our best friend Bith!<page>"..
            "<portrait charlie 1>Pim I really dont think thats necessary<page>"..
            "<portrait pim2 1>Hip, hip, horray!<page>"..
            "<portrait pim2 1>Hip, hip, horray!<page>"..
            "<portrait pim2 1>Hip, hip, horray!<page>"..
            "<portrait charlie 3>Okay Pim I think thats enough.<page>"..
            "<portrait pim2 1>Yeah no I was... I was done sorry"
        , pauses = false}
    )

    Routine.waitSignal("dialogueFinished")

    disableInput = false
end

return cutscenes