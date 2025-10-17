local cp = require("customPowerups")

local incredibleSuit = {}

incredibleSuit.forcedStateType = 2 -- 0 for instant, 1 for normal/flickering, 2 for poof/raccoon
incredibleSuit.basePowerup = PLAYER_BIG
incredibleSuit.cheats = {"glaby"}
incredibleSuit.collectSounds = {
    upgrade = 34,
    reserve = 12,
}

-- runs when the powerup is active, passes the player
local wasDashing = false
local lastDashInput = false
local normalMaxSpeed = 15
function incredibleSuit.onTickPowerup(p)
	if p == nil then return end
	
	local data = p.data.incredibleSuit

	if p:isOnGround() then
		data.canDash = true
	end

	local dashInput = (p.keys.altRun == KEYS_PRESSED or p.keys.run == KEYS_PRESSED or p:mem(0x50, FIELD_BOOL)) 
	
	if dashInput and lastDashInput ~= dashInput and data.canDash and data.dashTimer <= 0 then
		data.canDash = false

		data.dashTimer = 5
		data.dashHitboxTimer = 15
	end

	if data.dashTimer > 0 then
		wasDashing = true
		Defines.player_runspeed = 20

		p.keys.run = KEYS_PRESSED
		p.keys.left = false
		p.keys.right = false

		p.speedX = 20 * p.direction
		p.speedY = 0

		data.dashTimer = data.dashTimer - 1
	elseif wasDashing then
		wasDashing = false
		Defines.player_runspeed = normalMaxSpeed
	end

	if data.dashHitboxTimer > 0 then
		data.breakCollider.x = (p.x + p.width * 0.5) + (30 * p.direction)
		data.breakCollider.y = (p.y + p.height * 0.5) + 5

		-- yoinked from the rock mushroom
		for c, n in ipairs(Colliders.getColliding{a = data.breakCollider, btype = Colliders.BLOCK}) do
			if Block.MEGA_SMASH_MAP[n.id] and n.contentID == 0 then
				n:remove(true)
			end
			n:hit(2)
		end

		for c, n in ipairs(Colliders.getColliding{a = data.breakCollider, btype = Colliders.NPC, filter = function(o) if not o.isFriendly and not o.isHidden and NPC.HITTABLE_MAP[o.id] then return true end end}) do
			n:harm(3)
			p:mem(0x140, FIELD_WORD, 4)
			p:mem(0x142, FIELD_BOOL, true)
		end

		data.dashHitboxTimer = data.dashHitboxTimer - 1
	end
	
	local cam = Camera.get()[1]

	Text.print(tostring(data.canDash), player.x - cam.x, player.y - cam.y)
	-- Text.print(tostring(data.canDash), 100, 100)
	-- Text.print(tostring(data.dashTimer), 100, 150)
	-- Text.print(tostring(p:isOnGround()), 100, 200)
	-- Text.print(tostring(p.speedX), 100, 250)
	-- p.data.incredibleSuit.breakCollider:debug(true)

	lastDashInput = dashInput
end

function incredibleSuit.onEnable(p, noEffects)
	p.data.incredibleSuit = {
		canDash = true,
		dashTimer = 0,
		dashHitboxTimer = 0,
		breakCollider = Colliders.Rect(0,0,50,40,0)
	}

	normalMaxSpeed = Defines.player_runspeed
end

function incredibleSuit.onInitAPI()
    registerEvent(incredibleSuit, "onNPCCollect")
end

return incredibleSuit