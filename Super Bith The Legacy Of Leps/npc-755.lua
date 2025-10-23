local npcManager = require("npcManager")

local trigger = {}
local npcID = NPC_ID

local settings = npcManager.setNpcSettings({
	id = npcID,
	width = 32,
	height = 32,
	frames = 0,
	framestyle = 0,
	framespeed = 8,
	score = 2,
	speed = 0,

	playerblock = false,
	playerblocktop = false,
	npcblock = false,
	npcblocktop = false,
	spinjumpsafe = false,
	nowaterphysics = false,
	noblockcollision = true,
	cliffturn = false,
	nogravity = true,
	nofireball = false,
	noiceball = true,
	noyoshi = false,
	iswaternpc = false,
	iscollectablegoal = false,
	isvegetable = false,
	isvine = false,
	isbot = false,
	iswalker = false,
	grabtop = false,
	grabside = false,
	foreground = false,
	isflying = false,
	iscoin = false,
	isshoe = false,
	nohurt = false,
	jumphurt = false,
	isinteractable = true,
	notcointransformable = true,

	waitForLeave = false,
})

local function isPlayerInsideNPC(p, n)
	return (
		p.x + p.width  > n.x and
		p.x            < n.x + n.width and
		p.y + p.height > n.y and
		p.y            < n.y + n.height
	)
end

function trigger.onNPCCollect(event, npc, player)
	if npc.id ~= npcID then return end
	local data = npc.data
	local cfg = data._settings

	event.cancelled = true

	if cfg.waitForLeave then
		if not data._playerWasInside then
			triggerEvent(npc.deathEventName)
			data._playerWasInside = true
		end
	else
		triggerEvent(npc.deathEventName)
	end
end

function trigger.onTickEndNPC(v)
	if v.id ~= npcID then return end
	local data = v.data
	local cfg = data._settings

	if not cfg.waitForLeave then return end

	local inside = false
	for _, p in ipairs(Player.get()) do
		if isPlayerInsideNPC(p, v) then
			inside = true
			break
		end
	end

	if not inside then
		data._playerWasInside = false
	end
end

function trigger.onInitAPI()
	registerEvent(trigger, "onNPCCollect")
	npcManager.registerEvent(npcID, trigger, "onTickEndNPC")
end

return trigger
