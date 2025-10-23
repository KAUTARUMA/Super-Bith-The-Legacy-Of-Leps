local turingblock = {}

local blockmanager = require("blockmanager")
local turingmanager = require("turingmanager")

local turingBlockMap = {}
local turingBlockTexMap = {}

local tubeTexture = Graphics.loadImage("repeat-tubes.png")

local timeRestrictions = false

turingblock.KINDS = {"BIT", "MOVE_UP", "MOVE_DOWN", "MOVE_SIDE", "REPEAT", "WAIT"}

local function getMaxState(v)
    local kind = turingBlockMap[v.id]

    if kind == "REPEAT" then
        return v.data._settings.maxRepeat + 1
    elseif kind == "WAIT" then
        return 1
    elseif kind == "MOVE_SIDE" then
        return 2
    elseif kind == "MOVE_UP" or kind == "MOVE_DOWN" then
        return 4
    else
        return 3
    end
end

function turingblock.register(id, kind)
    blockmanager.registerEvent(id, turingblock, "onDrawBlock")
    turingBlockMap[id] = kind
end

local MOVE = {
    SIDE = {x = 32, y = 0},
    VERT = {x = 0, y = 32}
}

function turingblock.readInputs(v)
    if turingmanager.running then
        SFX.play(38)
        return
    end

    turingmanager.running = true
    SFX.play(32)
    SFX.play(51)

    local currentBlock = v
    local loopCount, lastLoopBlock, instructionCount = 0, nil, 0

    local function execute(block)
        local state, kind = block.data.state, block.data.kind
        local sfx = nil

        if kind == "MOVE_SIDE" then
            turingmanager.currentPos = turingmanager.currentPos + (state == 1 and 1 or -1)
            sfx = 9
        elseif kind == "BIT" then
            turingmanager.currentBitString[turingmanager.currentPos + 1] = state
            sfx = 18
        elseif kind == "REPEAT" then
            sfx = (state == 0 and 38 or 17)
        end

        block.data.bumpTimer = 0
        turingmanager.currentPos = turingmanager.currentPos % #turingmanager.currentBitString

        local waitTime = 0.75

        if timeRestrictions then
            if instructionCount > 100 then waitTime = 0
            elseif instructionCount > 50 then waitTime = 0.1
            elseif instructionCount > 15 then waitTime = 0.25 end
        end

        waitTime = 0.1

        if sfx then SFX.play(sfx, 1 * (waitTime + 0.05)) end

        instructionCount = instructionCount + 1
        return waitTime
    end

    local function findNextBlock(x, y)
        for _, b in ipairs(Block.getIntersecting(x, y, x + 1, y + 1)) do
            if turingBlockMap[b.id] then return b end
        end
    end

    local function process()
        local wait = 1
        while true do
            local kind = turingBlockMap[currentBlock.id]
            local move = table.clone(MOVE.SIDE)
            local isMove = (kind == "MOVE_DOWN" or kind == "MOVE_UP")

            if isMove then
                local checkState = currentBlock.data.state ~= 3
                if not checkState or turingmanager.currentBitString[turingmanager.currentPos + 1] == currentBlock.data.state then
                    move = table.clone(MOVE.VERT)
                    if kind == "MOVE_UP" then move.y = -move.y end

                    SFX.play(33)
                else
                    SFX.play(38)
                end
            end

            Routine.wait(wait)

            local nextBlock = nil
            if isMove then
                for i = 1, 3 do
                    nextBlock = findNextBlock(currentBlock.x + move.x, currentBlock.y + move.y * i)
                    if nextBlock then break end
                end
            else
                nextBlock = findNextBlock(currentBlock.x + move.x, currentBlock.y + move.y)
            end

            if not nextBlock then break end

            currentBlock = nextBlock
            wait = execute(currentBlock)

            if currentBlock.data.kind == "REPEAT" and currentBlock.data.state > 0 and (loopCount < 50 or not timeRestrictions) then
                loopCount = (lastLoopBlock == currentBlock) and (loopCount + 1) or 0
                lastLoopBlock = currentBlock

                local backX = currentBlock.x - MOVE.SIDE.x * currentBlock.data.state
                local backBlock = findNextBlock(backX, currentBlock.y)
                if backBlock then
                    Routine.wait(wait)
                    wait = execute(backBlock)

                    currentBlock = backBlock
                end
            end
        end
        turingmanager.resetBits()
    end

    Routine.run(process)
end

function turingblock.onInitAPI()
    registerEvent(turingblock, "onPostBlockHit")
end

function turingblock.onPostBlockHit(v, fromUpper, playerOrNil)
    local kind = turingBlockMap[v.id]
    if not kind then return end

    if turingmanager.running then return end
    if kind == "WAIT" then return end

    local data = v.data
    data.state = ((data.state or 0) + 1) % getMaxState(v)
    data.bumpTimer = 0

    SFX.play(32)
end

function turingblock.onDrawBlock(v)
    local kind = turingBlockMap[v.id]
    if not kind then return end

    local cfg = Block.config[v.id]
    local data = v.data

    if not data._init then
        data._init = true
        data.state = data._settings.startingState
        data.kind = kind
        data.bumpTimer = nil

        if turingBlockTexMap[v.id] == nil then
            turingBlockTexMap[v.id] = Graphics.sprites.block[v.id].img
        end

        Graphics.sprites.block[v.id].img = Graphics.loadImage("empty.png")
    end

    local texture = turingBlockTexMap[v.id]
    local frameHeight = cfg.height
    local frameIndex = data.state or 0

    if kind == "REPEAT" then frameIndex = 0 end

    local yOffset = 0
    if data.bumpTimer then
        data.bumpTimer = data.bumpTimer + 1

        if data.bumpTimer <= 6 then
            yOffset = -data.bumpTimer * 1.5
        elseif data.bumpTimer <= 12 then
            yOffset = -(12 - data.bumpTimer) * 1.5
        else
            data.bumpTimer = nil
        end
    end

    Graphics.drawImageToSceneWP(
        texture,
        v.x,
        v.y + yOffset,
        0,
        frameHeight * frameIndex,
        cfg.width,
        frameHeight,
        -25
    )

    if kind == "REPEAT" then
        local length = data.state

        Graphics.drawImageToSceneWP(
            tubeTexture,
            v.x,
            v.y + yOffset - 32,
            0,
            32 * (length > 0 and 1 or 0),
            cfg.width,
            frameHeight,
            -25
        )

        for i=1,length do
            Graphics.drawImageToSceneWP(
                tubeTexture,
                v.x - (32 * i),
                v.y + yOffset - 32,
                0,
                32 * (i == length and 3 or 2),
                cfg.width,
                frameHeight,
                -25
            )
        end
    end
end

return turingblock
