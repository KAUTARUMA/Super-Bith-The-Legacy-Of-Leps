local blockmanager = require("blockmanager")
local turingblock = require("turingblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = false,
	frames = 1,

	framespeed = 8000000
})

function block.onInitAPI()
	turingblock.register(blockID, "WAIT")
	registerEvent(block, "onPostBlockHit")
end

return block