--[=[
    @class Scheduler
    Schedule tasks to be run in specified intervals

    Example Usage:
    Respawns the local player every 5 seconds
    ```lua
    local Players = game:GetPlayers("Players")
    local Scheduler = Stellar.Get("Scheduler")

    local spawnLoop = Scheduler.new(5)

    spawnLoop:Tick(function()
        Players.LocalPlayer:LoadCharacter()
    end)

    spawnLoop:Start()
    ```
]=]

local Scheduler = {}
Scheduler.__index = Scheduler

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Maid = Stellar.Library("Maid")
local Signal = Stellar.Library("Signal")

--- Create a new Scheduler object
--- @diagnostic disable-next-line: undefined-doc-name
--- @return Scheduler
function Scheduler.new(loopTime: number)
    local self = setmetatable({
        LoopTime = loopTime,
        _Signal = Signal.new(),
        _Elapsed = 0,
        _Maid = Maid.new(),
    }, Scheduler)

    self._Maid:GiveTask(self._Signal)

    return self
end

--- Begin running tasks
function Scheduler:Start()
    self._Maid:GiveTask(RunService.Heartbeat:Connect(function()
        if tick() - self._Elapsed > self.LoopTime then
            self._Elapsed = tick()
            self._Signal:Fire()
        end
    end))
end

--- Add a task to the Scheduler
function Scheduler:Tick(func: () -> ()): RBXScriptConnection
    return self._Signal:Connect(func)
end

--- Destory and disable the Scheduler
function Scheduler:Destroy()
    self._Maid:DoCleaning()
end

return Scheduler
