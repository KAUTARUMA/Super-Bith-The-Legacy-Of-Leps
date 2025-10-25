local adversary = require("adversary")
local projectiles = require("projectiles")
local ASPlayer = require("ASPlayer")
local StateMachine = require("statemachine")

local nuko = {
    boss = adversary.createBoss(
        empty,
        {
            x = -199392,
            y = -200408,
            width = 15 * 2,
            height = 16 * 2,
            gfxwidth = 40,
            gfxheight = 50,
            gfxOffsetX = 7.5 * 2,
            gfxOffsetY = 1 * 2,
            direction = 0,
            hp = 20,
            name = "Nuko",

            speedX = 0,
            speedY = 0,

            targetSpeedX = 0,
            xLerpSpeed = 25,

            gravity = 1,

            touchingLeft = false,
            touchingRight = false,
            touchingUp = false,
            touchingDown = false,
        }
    ),
    nukoSprite = ASPlayer.new("nuko/nuko.json", "nuko/nuko.png"),
    stateMachine = StateMachine.new("INTRO")
}

local boss = nuko.boss
local sprite = nuko.nukoSprite
local stateMachine = nuko.stateMachine

local empty = Graphics.loadImage(Misc.resolveFile("empty.png"))


stateMachine:addState("INTRO", {
    enter = function(state)
        sprite:play("intro")
    end,

    update = function(state, dt, context)
        if sprite.playing == false then
            stateMachine:transition("WANDER")
        end
    end
})

stateMachine:addState("WANDER", {
    enter = function(state, lastState)
        sprite:play("walk")
    end,

    update = function(state, dt, context)
        boss.targetSpeedX = -10
        boss.xLerpSpeed = 2

        sprite.speed = math.abs(boss.speedX) / 5.0

        Text.print(boss.speedX, 100, 100)
    end,

    exit = function(state, nextState)
        sprite.speed = 1
    end
})

stateMachine:addState("HURT", {
    enter = function(state)
        sprite:play("hurt")
    end,

    update = function(state, dt, context)
        if stateMachine.stateTimer > 0.3 then
            stateMachine:transition("WANDER")
        end
    end
})

function nuko.spawn()
    boss.active = true

    boss:registerHarmSource(adversary.HARM_JUMP, 1)
    boss:registerHarmSource(adversary.HARM_SLASH, 1.5)
    boss:registerHarmSource(adversary.HARM_DOWNSLASH, 1.5)
    boss:registerHarmSource(adversary.HARM_TAIL, 0.75)
    boss:registerHarmSource(adversary.HARM_TONGUE, 3)
    boss:registerHarmSource(adversary.HARM_FIREBALL, 0.5)
    boss:registerHarmSource(adversary.HARM_HAMMER, 0.75)
    boss:registerHarmSource(adversary.HARM_ICEBALL, 0.5)
    boss:registerHarmSource(adversary.HARM_LASER, 0.75)

    boss:registerStateHarm({
        ["INTRO"] = 0,
        ["WANDER"] = 1,
        ["HURT"] = 0.1,
    })

    boss:registerCollider(boss.collider, 1)
    boss.collider:Debug(true)

    boss:initHP()
    stateMachine:transition("INTRO")

    registerEvent(boss, "onDraw")

    return boss
end

local function bossCollision(dt)
    boss.speedX = math.lerp(boss.speedX, boss.targetSpeedX, boss.xLerpSpeed * dt)

    boss.x = boss.x + boss.speedX
    boss.speedY = boss.speedY + boss.gravity
    boss.y = boss.y + boss.speedY

    boss.collider.x = boss.x
    boss.collider.y = boss.y
end

local lastTime = 0
function boss.onTick()
    local dt = lunatime.time() - lastTime

    sprite:update(dt)

    stateMachine:update(dt, boss)
    boss.state = stateMachine.currentState -- needed for da state harm stuff

    bossCollision(dt)

    lastTime = lunatime.time()
end

function boss.onDraw()
    sprite:draw(boss.x + boss.gfxOffsetX, boss.y + boss.gfxOffsetY, 2.0, 0)
end

function boss.onHarm(v, source, damage, culprit)
    if damage < 0 then return 0 end
    if boss.state == "INTRO" then return 0 end

    if culprit ~= nil then
        if culprit.__type == "NPC" then
            culprit:kill(3)
        end

        if source == adversary.HARM_JUMP or source == adversary.HARM_DOWNSLASH then
            Colliders.bounceResponse(culprit)
        end
    end

    stateMachine:transition("HURT")
    return damage
end

return nuko