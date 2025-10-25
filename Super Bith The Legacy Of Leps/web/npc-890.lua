-- NPC Configuration (for SMBX2 Editor)
-- NPC-XXX: Nuko Boss
-- Settings: Don't interact with other NPCs, Don't move when hit, Don't use NPC collision

local npcManager = require("npcManager")
local projectiles = require("projectiles")
local ASPlayer = require("ASPlayer")
local StateMachine = require("statemachine")

local nuko = {}

local nukoSettings = {
    id = NPC_ID,
    gfxheight = 50,
    gfxwidth = 40,
    width = 30,
    height = 32,
    nohurt = true,
    noyoshi = true,
    nofireball = true,
    noiceball = true,
    nopowblock = true,
    notcointransformable = true,
}

npcManager.setNpcSettings(nukoSettings)
local empty = Graphics.loadImage(Misc.resolveFile("empty.png"))

function initializeNPCData(nukoNPC)
    local spriteInstance = ASPlayer.new("nuko/nuko.json", "nuko/nuko.png")
    
    local stateMachineInstance = StateMachine.new("INTRO")

    nukoNPC.data._bossdata = {
        sprite = spriteInstance,
        stateMachine = stateMachineInstance,
        lastTime = lunatime.time(),

        targetSpeedX = 0,
        lerpSpeedX = 0,
        direction = -1
    }

    local bossdata = nukoNPC.data._bossdata
    
    stateMachineInstance:addState("INTRO", {
        enter = function(state)
            spriteInstance:play("intro")
        end,

        update = function(state, dt)
            if spriteInstance.playing == false then
                stateMachineInstance:transition("WANDER")
            end
        end
    })

    stateMachineInstance:addState("WANDER", {
        enter = function(state, lastState)
            spriteInstance:play("walk")

            state.runTime = 0
            state.turnTimer = 0
        end,

        update = function(state, dt)
            state.runTime = state.runTime + dt

            local dist = player.x - nukoNPC.x
            local facingPlayer = (dist > 0 and bossdata.direction == 1) or (dist < 0 and nukoNPC.direction == -1)

            if facingPlayer and math.abs(dist) < 128 and nukoNPC.collidesBlockBottom then
                nukoNPC.speedY = -8
            end

            if nukoNPC.collidesBlockLeft or nukoNPC.collidesBlockRight then
                bossdata.direction = -bossdata.direction
                nukoNPC.speedX = -3 * bossdata.direction
            end

            if (stateMachineInstance.stateTimer - state.turnTimer) > 0.5 and not facingPlayer and math.abs(dist) > 400 then
                bossdata.direction = -bossdata.direction
                state.turnTimer = stateMachineInstance.stateTimer
            end

            bossdata.targetSpeedX = 7 * bossdata.direction
            bossdata.lerpSpeedX = 2

            if nukoNPC.y > -200000 then
                nukoNPC.speedY = -10
            end

            spriteInstance.speed = math.abs(nukoNPC.speedX) / 3.0
        end,

        exit = function(state, nextState)
            spriteInstance.speed = 1
        end
    })

    stateMachineInstance:addState("HURT", {
        enter = function(state)
            spriteInstance:play("hurt")
        end,

        update = function(state, dt)
            if stateMachineInstance.stateTimer > 0.3 then
                stateMachineInstance:transition("WANDER")
            end
        end
    })

    stateMachineInstance:transition("INTRO")
end

function updateBoss(nukoNPC)
    local data = nukoNPC.data._bossdata
    if not data then return end
    
    local sprite = data.sprite
    local stateMachine = data.stateMachine
    
    local dt = lunatime.time() - data.lastTime
    
    stateMachine:update(dt)

    local target = data.targetSpeedX
    local speed = data.lerpSpeedX

    local isTurning = (nukoNPC.speedX * target < 0)

    local lerpFactor = dt * speed
    if isTurning then
        lerpFactor = lerpFactor * 0.9
    end
    lerpFactor = math.max(math.min(lerpFactor, 1), 0)

    nukoNPC.speedX = math.lerp(nukoNPC.speedX, target, lerpFactor)
    
    sprite:update(dt)

    data.lastTime = lunatime.time()
end

function drawBoss(nukoNPC)
    local data = nukoNPC.data._bossdata
    if not data then return end
    
    local sprite = data.sprite

    sprite.flipX = nukoNPC.direction == 1
    sprite:draw(nukoNPC.x + (7.5 * 2), nukoNPC.y + (1 * 2), 2.0, 0)

    Graphics.drawBox {
        x = nukoNPC.x - camera.x,
        y = nukoNPC.y - camera.y,
        width = nukoNPC.width,
        height = nukoNPC.height,
        color = Color(1, 0, 0, 0.5)
    }
end

function nuko.onInitAPI()
    npcManager.registerEvent(NPC_ID, nuko, "onTickNPC")
    npcManager.registerEvent(NPC_ID, nuko, "onDrawNPC")
end

function nuko.onTickNPC(nukoNPC)
    if not nukoNPC.data._bossdata then
        initializeNPCData(nukoNPC)
    end
    
    updateBoss(nukoNPC)
end

function nuko.onDrawNPC(nukoNPC)
    drawBoss(nukoNPC)
end

return nuko