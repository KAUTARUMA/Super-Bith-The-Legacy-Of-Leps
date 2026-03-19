local turingmanager = {}

local puzzles = {
    {
        starting = {0, 0, 0, 1, 0},
        startingPos = 2,
        goal = {0, 1, 0, 1, 1}
    },
    {
        starting = {0, 2, 0, 1, 1},
        startingPos = 2,
        goal = {0, 0, 0, 1, 1}
    }
}


turingmanager.running = false
turingmanager.currentPuzzle = 0
turingmanager.currentPuzzleTable = nil
turingmanager.currentBitString = {}
turingmanager.currentPos = 0
turingmanager.currentPosAnim = 0
turingmanager.currentLayer = nil

local pageImage = Graphics.loadImage("page.png")
local num0Image = Graphics.loadImage("num0.png")
local num1Image = Graphics.loadImage("num1.png")
local selectBoxImage = Graphics.loadImage("selectbox.png")

local tweenDuration = 0.2
local tweenElapsed = 0
local isTweening = false
local startPos = 0
local targetPos = 0

function turingmanager.onInitAPI()
    registerEvent(turingmanager, "onPostBlockHit")
    registerEvent(turingmanager, "onDraw")
    registerEvent(turingmanager, "onTick")
    registerEvent(turingmanager, "onStart")
end

function turingmanager.onStart()
    turingmanager.nextPuzzle()
end

function turingmanager.nextPuzzle()
    turingmanager.currentPuzzle = turingmanager.currentPuzzle + 1
    turingmanager.currentPuzzleTable = puzzles[turingmanager.currentPuzzle]

    if turingmanager.currentLayer then
        turingmanager.currentLayer:hide(true)
    end

    turingmanager.currentLayer = Layer.get("Puzzle"..tostring(turingmanager.currentPuzzle))
    turingmanager.currentLayer:show(true)

    turingmanager.resetBits()
end

function turingmanager.verifyBits()
    turingmanager.moveTo(0, 0.5)
    Routine.wait(0.75)

    for i,v in ipairs(turingmanager.currentBitString) do
        if v ~= turingmanager.currentPuzzleTable.goal[i] then
            SFX.play(38)
            Routine.wait(1)
            SFX.play(18)
            turingmanager.resetBits()
            return
        else
            turingmanager.moveTo(math.min(i, #turingmanager.currentBitString - 1), 0.25)
            SFX.play(29)
            Routine.wait(0.75)
        end
    end

    SFX.play(12)
    turingmanager.nextPuzzle()
end

local function drawBitString(posX, posY, bitString, scale, drawSelect, drawSelectShift)
    local cam = Camera.get()[1]

    if drawSelectShift == nil then drawSelectShift = 0 end

    local function drawImage(img, idx, priority) 
        Graphics.drawBox {
            x = posX + ((64 * scale) * (idx - 1 - drawSelectShift) - cam.x),
            y = posY - cam.y,
            width = 64 * scale,
            height = 64 * scale,
            texture = img,
            priority = priority
        }
    end

    for i,v in ipairs(bitString) do
        drawImage (
            pageImage,
            i,
            -50
        )

        local imgToDraw
        if v == 1 then
            imgToDraw = num1Image
        elseif v == 0 then
            imgToDraw = num0Image
        end

        if imgToDraw then
            drawImage (
                imgToDraw,
                i,
                -49
            )
        end

        if drawSelect then
            drawImage (
                selectBoxImage,
                0 + drawSelectShift,
                -48
            )
        end
    end
end

function turingmanager.onTick()
    local dt = Routine.deltaTime
    
    if isTweening then
        tweenElapsed = tweenElapsed + dt
        local t = math.min(tweenElapsed / tweenDuration, 1)

        turingmanager.currentPosAnim = math.lerp(startPos, targetPos, t)

        if t >= 1 then
            isTweening = false
            turingmanager.currentPosAnim = targetPos
        end
    else
        turingmanager.currentPosAnim = turingmanager.currentPos
    end
end

function turingmanager.onDraw()
    if not turingmanager.currentPuzzleTable then return end

    for k,bgo in ipairs(BGO.get(931)) do
        drawBitString(bgo.x, bgo.y, turingmanager.currentBitString, 1, true, turingmanager.currentPosAnim + 1)
        drawBitString(bgo.x + 50, bgo.y - 50, turingmanager.currentPuzzleTable.goal, 0.5)
    end
end

function turingmanager.moveTo(newPos, duration)
    if newPos == turingmanager.currentPos then return end

    startPos = turingmanager.currentPos
    targetPos = newPos

    tweenDuration = duration

    turingmanager.currentPos = newPos

    tweenElapsed = 0
    isTweening = true
end

function turingmanager.resetBits()
    turingmanager.moveTo(turingmanager.currentPuzzleTable.startingPos, 0.25)

    turingmanager.running = false

    for k,v in pairs(turingmanager.currentPuzzleTable.starting) do
        turingmanager.currentBitString[k] = v
    end
end

return turingmanager
