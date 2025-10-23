local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true
})

function block.onInitAPI()
	registerEvent(block,"onPostBlockHit")
end

function block.onPostBlockHit(block, fromUpper, player)
	if block.id ~= BLOCK_ID then return end
	if player == nil then return end 
	
	NPC.spawn(806, player.x, player.y, player.section)
end

return block