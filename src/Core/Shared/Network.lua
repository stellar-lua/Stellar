--[=[
    @class Network

    Network handles the creation of RemoteEvents and RemoteFunctions.

    :::caution
    If the client attempts to connect to an endpoint which has not yet been referenced on the server, it will yield for 10 seconds and then drop the request.
    If the server does not reference the endpoint when the server starts, you must "Reserve" it on startup.
    :::
]=]

local Network = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Promise = Stellar.Library("Promise")
local IsServer = RunService:IsServer()
local Translation = {}

type Endpoint = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
type Remote = BaseRemoteEvent | RemoteFunction

--[=[
    Observes a RemoteEvent
    @return Promise
]=]
function Network:ObserveSignal(name: string, func: (player: Player, ...any) -> ())
    return Promise.try(function()
        return Network:GetEndpoint(name, "RemoteEvent")
    end):andThen(function(endpoint: Remote)
        assert(endpoint, `[Network] Another endpoint with name '{name}' exists of a different class`)

        if IsServer then
            return endpoint.OnServerEvent:Connect(func)
        else
            return endpoint.OnClientEvent:Connect(func)
        end
    end)
end

--- Signals the server if run on the client, and vice versa
function Network:Signal(name: string, ...: any)
    local endpoint: Remote = Network:GetEndpoint(name, "RemoteEvent")
    assert(endpoint, `[Network] Another endpoint with name '{name}' exists of a different class`)

    if IsServer then
        endpoint:FireClient(...)
    else
        endpoint:FireServer(...)
    end
end

--- Signals all clients
function Network:SignalAll(name: string, ...: any)
    local endpoint: Remote = Network:GetEndpoint(name, "RemoteEvent")
    assert(endpoint, `[Network] Another endpoint with name '{name}' exists of a different class`)
    assert(IsServer, `[Network] SignalAll cannot be run on the client`)

    endpoint:FireAllClients(...)
end

--- @yields
--- Signals and yields for response
function Network:SignalAsync(name: string, ...: any)
    return Promise.try(Network.Signal, Network, name, ...)
end

--- Sets the function for handling invoke requests
function Network:OnInvoke(name: string, func: (player: Player, ...any) -> ())
    local endpoint = Network:GetEndpoint(name, "RemoteFunction")
    assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
    assert(IsServer, `[Network] SignalAll cannot be run on the client`)

    endpoint.OnServerInvoke = func
end

--[=[
    Used internally for getting remotes.
    You should use this too if you need to use the physical remote as they are named GUIDs after first found on client.
    This practice, whilst not completely solving remote tampering, will make it slightly harder.
]=]
function Network:GetEndpoint(name: string, remote: Endpoint): Remote
    assert(typeof(name) == "string", `[Network] (Arg 1) '{typeof(name)}' passed, string expected!`)
    assert(
        typeof(remote) == "Instance" and (remote:IsA("BaseRemoteEvent") or remote:IsA("RemoteFunction")),
        `[Network] (Arg 2) '{typeof(name)}' passed, Remote expected!`
    )

    if Translation[name] ~= nil then
        return Translation[name]
    end

    local storageFolder: Folder = ReplicatedStorage:FindFirstChild("_NetworkingStorage")
    if storageFolder == nil and IsServer then
        storageFolder = Instance.new("Folder")
        storageFolder.Parent = ReplicatedStorage
        storageFolder.Name = "_NetworkingStorage"
    end

    if storageFolder ~= nil then
        local endpoint: Instance = storageFolder:FindFirstChild(name)

        if endpoint ~= nil then
            if endpoint:IsA(remote) then
                if not IsServer then
                    Translation[name] = endpoint
                    endpoint.Name = HttpService:GenerateGUID()
                end
                return endpoint
            end

            return false
        elseif IsServer then
            local newEndpoint: Remote = Instance.new(remote)
            newEndpoint.Name = name
            newEndpoint.Parent = storageFolder

            return newEndpoint
        else
            local duration: number = tick()
            local hasWarned: boolean = false

            while storageFolder:FindFirstChild(name) == nil do
                if tick() - duration > 10 and not hasWarned then
                    warn(`[Network::Danger] Endpoint '{name}' was not reserved on the server. Possible infinite yield!`)
                    hasWarned = true
                end
                task.wait()
            end

            if hasWarned then
                warn(`[Network::Resolved] Endpoint yieldf for '{name} has resolved`)
            end

            local newEndpoint: Instance = storageFolder:FindFirstChild(name)

            if newEndpoint:IsA(remote) then
                if not IsServer then
                    Translation[name] = newEndpoint
                    newEndpoint.Name = HttpService:GenerateGUID()
                end
                return newEndpoint
            end

            return false
        end
    end
end

return Network
