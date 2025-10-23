local blockmanager = require("blockmanager")
local turingblock = require("turingblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 3,

	framespeed = 8000000
})

turingblock.register(blockID, "BIT")

return block