local blockmanager = require("blockmanager")
local turingblock = require("turingblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 1,

	framespeed = 8000000
})

function block.onInitAPI()
	registerEvent(block, "onPostBlockHit")
end

function block.onPostBlockHit(v, fromUpper, playerOrNil)
    if v.id ~= BLOCK_ID then return end

    turingblock.readInputs(v)
end

return block