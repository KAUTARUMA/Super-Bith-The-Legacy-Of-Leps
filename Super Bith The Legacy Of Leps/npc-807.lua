local npcManager = require("npcManager")

local crystal = {}

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
	iscoin = false,
	notcointransformable = true
})

function crystal.onTickNPC(npc)
	if Defines.levelFreeze then return end
	
	local data = npc.data

	if not data.initialized then
		data.collectTimer = 0
		data.initialized = true
	end

	if data.collectTimer > 0 then
		data.collectTimer = data.collectTimer - 1
	end

	npc.isHidden = data.collectTimer > 0
end

function crystal.onNPCCollect(event, npc, player)
	if not npc or type(npc) ~= "NPC" or npc.id ~= npcID then return end

	event.cancelled = true

	if npc.data.collectTimer > 0 then return end
	if player.data.incredibleSuit == nil then return end
	if player.data.incredibleSuit.canDash then return end

	-- do collect effects here

	player.data.incredibleSuit.canDash = true
	npc.data.collectTimer = 180
end

function crystal.onInitAPI()
	npcManager.registerEvent(npcID, crystal, "onTickNPC")
	registerEvent(crystal, "onNPCCollect")
end

return crystal