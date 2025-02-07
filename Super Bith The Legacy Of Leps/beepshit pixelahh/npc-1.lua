local npcManager = require("npcManager")
local whistle = require("npcs/ai/whistle")
local friendlyNPC = require("npcs/ai/friendlies")

local friendlies = {}
local npcID = NPC_ID

local defaults = {frames = 181, 
				  framespeed = 11,
				  framestyle = 1, 
				  jumphurt = 1,
				  ignorethrownnpcs = 1,
				  nofireball=1,
				  noiceball=1,
				  noyoshi=1,
				  grabside=0,
				  grabtop=0,
				  isshoe=0,
				  isyoshi=0,
				  isstationary = true,
				  nowalldeath = true,
				  nohurt=1,
				  nogravity = true,
				  score = 0,
				  spinjumpsafe=0}

local megan = npcManager.setNpcSettings(table.join(
				 {id = npcID,
				  gfxwidth = 320,
				  gfxheight = 180,
				  ignorethrownnpcs = 0,
				  width = 320,
				  height = 180, },
				  defaults))

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

friendlyNPC.register(npcID)

function friendlies.onInitAPI()
	npcManager.registerEvent(npcID, friendlies, "onTickEndNPC")
end

function friendlies.onTickEndNPC(v)
	if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if (whistle.getActive()) then
		local x = v.x+v.width*0.5
		local y = v.y+v.height
		v:kill(9)
		Explosion.spawn(x,y,4)
	end
end

return friendlies