local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

Stellar.BulkLoad(ServerStorage.ServerModules, ReplicatedStorage.SharedModules)
Stellar.BulkGet("ExampleService")
