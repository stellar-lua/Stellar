local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

Stellar.BulkLoad(ReplicatedStorage.ClientModules, ReplicatedStorage.SharedModules)
Stellar.BulkGet("ExampleClient")
