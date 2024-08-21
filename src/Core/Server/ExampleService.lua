local ExampleService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")

function ExampleService:Init()
    Network:OnInvoke("ExampleFunction", function(player: Player, message: string)
        local playerName: string = player.Name

        return `Hello, {playerName}, you said '{message}!`
    end)

    print("[ExampleService] Hello, world!")
end

return ExampleService
