local ExampleClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")

function ExampleClient:Init()
    local welcomeMessage: string = Network:Invoke("ExampleFunction", "Test Message")
    print(welcomeMessage)
end

return ExampleClient
