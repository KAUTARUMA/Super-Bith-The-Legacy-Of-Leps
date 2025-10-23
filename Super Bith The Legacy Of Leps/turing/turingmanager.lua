local turingmanager = {}

turingmanager.running = false
turingmanager.defaultBitString = {2, 2, 2, 2, 2, 2, 2, 2, 2, 2}
turingmanager.currentBitString = {}
turingmanager.currentPos = currentPos

function turingmanager.onInitAPI()
    registerEvent(turingmanager, "onPostBlockHit")
    registerEvent(turingmanager, "onDraw")

    turingmanager.resetBits()
end

function turingmanager.onDraw()
    for i,v in ipairs(turingmanager.currentBitString) do
        local textToPrint = tostring(v)

        if v == 2 then
            textToPrint = "."
        end

        Text.print(textToPrint, 100 + (20 * i), 100)

        if (turingmanager.currentPos + 1) == i then
            Text.print("V", 100 + (20 * i), 80)
        end
    end
end

function turingmanager.resetBits()
    turingmanager.currentPos = 0
    turingmanager.running = false
    turingmanager.currentBitString = table.clone(turingmanager.defaultBitString)
end

return turingmanager
