local blockmanager = require("blockmanager")
local sync = require("blocks/ai/synced")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	customhurt = true,
	passthrough = true,
	frames = 2,
	framespeed = 80000
})

function block.onCollideBlock(v,n)
	if (n.__type == "Player") and Block.config[blockID].passthrough == false then
		if n:mem(0x140, FIELD_WORD) == 0 and n:mem(0x13E, FIELD_WORD) == 0 then
			n:harm()
		end
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

sync.registerBlinkingBlock(blockID, 2)

return block