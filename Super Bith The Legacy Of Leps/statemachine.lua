-- by KAUTARUMA and the power of the internet

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
    local self = setmetatable({}, StateMachine)

    self.states = {}
    self.stateTimer = 0

    return self
end

function StateMachine:addState(name, callbacks)
    callbacks.name = name
    self.states[name] = callbacks
end

function StateMachine:update(dt)
    local current = self.currentState
    if current then
        self.stateTimer = self.stateTimer + dt

        if current.update then current.update(current, dt) end
    end
end

function StateMachine:transition(newStateName)
    local lastState = self.currentState
    
    if lastState and lastState.exit then
        lastState.exit(lastState, newStateName)
    end
    
    local nextState = self.states[newStateName]
    self.currentState = nextState
    self.stateTimer = 0

    if nextState == nil then
        error("No state named " .. newStateName .. " found!")
    end
    
    if nextState.enter then
        nextState.enter(self.currentState, lastState)
    end
end

return StateMachine