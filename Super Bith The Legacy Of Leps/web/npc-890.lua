local npcManager = require("npcManager")
local adversary = require("adversary")
local projectiles = require("projectiles")
local ASPlayer = require("ASPlayer")
local StateMachine = require("statemachine")
local easing = require("ext/easing")

local nuko = {}

local nukoSettings = {
    id = NPC_ID,
    gfxheight = 50,
    gfxwidth = 40,
    width = 30,
    height = 25,
    score = 0,
    jumphurt = true,
    nohurt = true,
    noyoshi = true,
    noiceball = true,
    nofireball = true,
    notcointransformable = true
}

npcManager.setNpcSettings(nukoSettings)

adversary.HARM_FALLOFFSCREEN = 269

local empty = Graphics.loadImage(Misc.resolveFile("empty.png"))

function initializeNPCData(nukoNPC)
    local nukoSprite = ASPlayer.new("nuko/nuko.json", "nuko/nuko.png")
    local stateMachine = StateMachine.new("INTRO")
    local advBoss = adversary.createBoss(empty, {
        useScreenCoords = true,
        hp = 40,
        name = "Nuko",
        
        npc = nukoNPC
    })

    advBoss.onHarm = onAdvHarm

    nukoNPC.data._bossdata = {
        nukoSprite = nukoSprite,
        stateMachine = stateMachine,
        advBoss = advBoss,

        lastTime = lunatime.time(),

        targetSpeedX = 0,
        lerpSpeedX = 0,
        direction = -1,

        dmgColliders = {},

        invTimer = 0,

        useGravity = true,

        canHurtState = true,
        canHurt = true,

        -- State Vars

        runTime = 0,

        pounceTarget = vector(0, 0)
    }

    local data = nukoNPC.data._bossdata

    advBoss.active = true

    advBoss:registerHarmSource(adversary.HARM_JUMP, 1)
    advBoss:registerHarmSource(adversary.HARM_SLASH, 1.5)
    advBoss:registerHarmSource(adversary.HARM_DOWNSLASH, 1.5)
    advBoss:registerHarmSource(adversary.HARM_TAIL, 0.75)
    advBoss:registerHarmSource(adversary.HARM_TONGUE, 3)
    advBoss:registerHarmSource(adversary.HARM_FIREBALL, 0.5)
    advBoss:registerHarmSource(adversary.HARM_HAMMER, 0.75)
    advBoss:registerHarmSource(adversary.HARM_ICEBALL, 0.5)
    advBoss:registerHarmSource(adversary.HARM_LASER, 0.75)
    advBoss:registerHarmSource("FallOffScreen", 2)

    advBoss:registerStateHarm({
        ["HURT"] = 0.2,
        ["TIRED"] = 0.5,
        ["POUNCE"] = 0.5
    })

    advBoss:registerCollider(advBoss.collider, 1)
    
    data.dmgColliders["runCollider"] = Colliders.Box(0, 0, 5, 1)
    local runCollider = data.dmgColliders["runCollider"]
    runCollider.offsetX = 0
    runCollider.offsetY = 6
    runCollider.enabled = false
    
    --advBoss.collider:Debug(true)
    --runCollider:Debug(true)

    stateMachine:addState("INTRO", {
        enter = function(state)
            nukoSprite:play("intro")
            
            data.canHurt = false
        end,

        update = function(state, dt)
            if nukoSprite.playing == false then
                stateMachine:transition("WANDER")
            end

            nukoNPC.speedX = 0
            nukoNPC.speedY = 0
        end,

        exit = function(state, nextState)
            advBoss:initHP()

            data.canHurt = true
        end
    })

    stateMachine:addState("WANDER", {
        enter = function(state, lastState)
            nukoSprite:play("walk")
            runCollider.enabled = true

            state.turnTimer = 0
        end,

        update = function(state, dt)
            data.runTime = data.runTime + dt
            
            local dist = player.x - nukoNPC.x
            local facingPlayer = (dist > 0 and data.direction == 1) or (dist < 0 and nukoNPC.direction == -1)

            if facingPlayer and math.abs(dist) < 128 and nukoNPC.collidesBlockBottom then
                nukoNPC.speedY = -8
            end

            if nukoNPC.collidesBlockLeft or nukoNPC.collidesBlockRight then
                data.direction = -data.direction
                nukoNPC.speedX = -3 * data.direction
            end

            if (stateMachine.stateTimer - state.turnTimer) > 0.5 and not facingPlayer and math.abs(dist) > 400 then
                data.direction = -data.direction
                state.turnTimer = stateMachine.stateTimer
            end

            data.targetSpeedX = 7 * data.direction
            data.lerpSpeedX = 2

            runCollider.offsetX = 15 * data.direction

            nukoSprite.speed = math.abs(nukoNPC.speedX) / 3.0

            if data.runTime > 5 then
                stateMachine:transition("TIRED")
            end
        end,

        exit = function(state, nextState)
            nukoSprite.speed = 1
            runCollider.enabled = false

            data.targetSpeedX = 0
        end
    })

    local tiredLength = 3
    stateMachine:addState("TIRED", {
        enter = function(state)
            nukoSprite:play("tired")
            data.canHurtState = false
        end,

        update = function(state, dt)
            if stateMachine.stateTimer > tiredLength then
                stateMachine:transition("POUNCE")
                data.pounceTarget = vector(-199616, -200416)
            elseif stateMachine.stateTimer > tiredLength - 0.5 then
                nukoSprite:play("shake")
            elseif stateMachine.stateTimer > tiredLength - 1 then
                nukoSprite:play("shock")
            end
        end,

        exit = function(state, nextState)
            data.canHurtState = true
            data.runTime = 0
        end
    })

    stateMachine:addState("POUNCE", {
        enter = function(state)
            nukoSprite:play("pounce-shake")
            data.canHurtState = false
            data.useGravity = false
            
            state.isPouncing = false
            state.pounceStart = 0
            state.startPos = {}
        end,

        update = function(state, dt)
            if data.pounceTarget.x > nukoNPC.x then
                nukoNPC.direction = 1
            end

            if stateMachine.stateTimer > 0.2 and state.isPouncing == false then
                nukoSprite:play("pounce-start")

                state.isPouncing = true
                state.pounceStart = stateMachine.stateTimer

                state.startPos = vector(nukoNPC.x, nukoNPC.y)
            elseif state.isPouncing == true then
                local t = stateMachine.stateTimer - state.pounceStart
                local jumpPeak = 80
                local length = 0.5
                local halfLength = length / 1.5

                if t < length then
                    nukoNPC.x = easing.linear(
                        t, 
                        state.startPos.x, 
                        data.pounceTarget.x - state.startPos.x, 
                        length)
                    
                    if t < halfLength then
                        nukoNPC.y = easing.outQuad(
                            t,
                            state.startPos.y,
                            (data.pounceTarget.y - jumpPeak) - state.startPos.y,
                            halfLength
                        )
                    else
                        nukoNPC.y = easing.inQuad(
                            t - halfLength,
                            data.pounceTarget.y - jumpPeak,
                            data.pounceTarget.y - (data.pounceTarget.y - jumpPeak),
                            halfLength
                        )
                    end
                else
                    -- stateMachine:transition("WANDER")
                end
            end
        end,

        exit = function(state, nextState)
            data.canHurtState = true
            data.useGravity = true
        end
    })

    stateMachine:addState("HURT", {
        enter = function(state)
            nukoSprite:play("hurt")
        end,

        update = function(state, dt)
            if stateMachine.stateTimer > 0.5 then
                stateMachine:transition("WANDER")
            end
        end
    })

    stateMachine:transition("INTRO")
end

function updateBoss(nukoNPC)
    local data = nukoNPC.data._bossdata
    if not data then return end
    
    local nukoSprite = data.nukoSprite
    local stateMachine = data.stateMachine
    local advBoss = data.advBoss
    
    local dt = lunatime.time() - data.lastTime
    
    stateMachine:update(dt)

    if data.useGravity then
        NPC.config[NPC_ID].nogravity = false

        if nukoNPC.y > -200000 then
            nukoNPC.speedY = -10
            advBoss:damage("FallOffScreen")
        end

        if data.invTimer > 0 then
            data.invTimer = data.invTimer - dt
        else
            data.invTimer = 0
        end

        local target = data.targetSpeedX
        local speed = data.lerpSpeedX

        local isTurning = (nukoNPC.speedX * target < 0)

        local lerpFactor = dt * speed

        if isTurning then
            lerpFactor = lerpFactor * 0.9
        end

        lerpFactor = math.max(math.min(lerpFactor, 1), 0)

        nukoNPC.speedX = math.lerp(nukoNPC.speedX, target, lerpFactor)
    else
        NPC.config[NPC_ID].nogravity = true

        nukoNPC.speedX = 0
        nukoNPC.speedY = 0
    end

    advBoss.x = nukoNPC.x
    advBoss.y = nukoNPC.y

    advBoss.collider.x = nukoNPC.x
    advBoss.collider.y = nukoNPC.y
    advBoss.collider.width = nukoNPC.width
    advBoss.collider.height = nukoNPC.height

    for _, collider in pairs(data.dmgColliders) do
        collider.x = nukoNPC.x + collider.offsetX + (nukoNPC.width / 2)
        collider.y = nukoNPC.y + collider.offsetY + (nukoNPC.height / 2)

        if collider.enabled and data.invTimer <= 0 and Colliders.collide(player, advBoss.collider) then
            player:harm()
        end
    end
    
    nukoSprite:update(dt)

    data.lastTime = lunatime.time()
end

function drawBoss(nukoNPC)
    local data = nukoNPC.data._bossdata
    if not data then return end
    
    local nukoSprite = data.nukoSprite

    nukoSprite.flipX = nukoNPC.direction == 1
    nukoSprite:draw(nukoNPC.x + (7.5 * 2), nukoNPC.y + (-2 * 2), 2.0, 0)
end

function nuko.onInitAPI()
    npcManager.registerEvent(NPC_ID, nuko, "onTickNPC")
    npcManager.registerEvent(NPC_ID, nuko, "onDrawNPC")
    registerEvent(nuko, "onNPCKill")
end

function nuko.onTickNPC(nukoNPC)
    if not nukoNPC.data._bossdata then
        initializeNPCData(nukoNPC)
    end
    
    updateBoss(nukoNPC)
end

function nuko.onDrawNPC(nukoNPC)
    drawBoss(nukoNPC)

    Text.print(nukoNPC.data._bossdata.stateMachine.currentState.name, 100, 100)
    Text.print(nukoNPC.data._bossdata.stateMachine.stateTimer, 100, 150)

    if nukoNPC.data._bossdata.nukoSprite ~= nil then
        Text.print(nukoNPC.data._bossdata.nukoSprite.speed, 100, 200)
    end
end

function onAdvHarm(advBoss, source, damage, culprit)
    if damage < 0 then return 0 end

    local data = advBoss.npc.data._bossdata
    local currentStateName = data.stateMachine.currentState.name

    if data.invTimer > 0 or not data.canHurt then return 0 end

    if culprit ~= nil then
        if culprit.__type == "NPC" then
            culprit:kill(3)
        end

        if source == adversary.HARM_JUMP or source == adversary.HARM_DOWNSLASH then
            Colliders.bounceResponse(culprit)
        end
    end

    if currentStateName ~= "HURT" and data.canHurtState then
        data.stateMachine:transition("HURT")
    end

    data.invTimer = .5
    SFX.play(39)
    return damage
end

return nuko