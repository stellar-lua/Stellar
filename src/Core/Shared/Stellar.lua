--[=[
    @class Stellar

    Game Framework
]=]

local Stellar = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = {}
local Initialised = {}
local LoadedAssets = {}
local CachedPackages = {}
local PackageLocations

--- Retrieves a singular file loaded with Stellar by its name
function Stellar.Get(name: string, dontInit: boolean?): any
    assert(typeof(name) == "string", `[Stellar] Attempted to get module with type '{typeof(name)}', string expected!`)

    if LoadedAssets[name] ~= nil then
        return LoadedAssets[name]
    end

    if Assets[name] == nil then
        local yieldDuration: number = tick()
        warn(`[Stellar] Yielding for unimported module '{name}'`)
        repeat
            task.wait()
        until Assets[name] or tick() >= yieldDuration + 5
    end

    if Assets[name] ~= nil then
        local start: number = tick()
        local success: boolean, result: any = Stellar._Import(Assets[name])
        local duration: string = string.format("%.2f", tick() - start)

        if tick() - start > 1 then
            warn(`[Stellar] '{name}' has finished requiring. Took {duration}s!`)
        end

        if success then
            LoadedAssets[name] = result
            print(`[Stellar] '{name}' successfully imported [{duration}s]`)

            if not dontInit then
                Stellar._Initialise(name, LoadedAssets[name])
            end

            return result
        else
            warn(`[Stellar] Failed to import module '{name}' due to: {result}`)
        end
    end
end

--- Retrieves multiple loaded with Stellar by its name.
--- Useful for starting services when the client/server first runs
function Stellar.BulkGet(...: string): { ModuleScript }
    local modules: { [number]: ModuleScript } = {}
    local raw: { [number]: string } = { ... }

    for _, module in pairs(raw) do
        local start: number = tick()
        modules[module] = Stellar.Get(module)

        if tick() - start > 2 then
            warn(string.format("[Stellar] '%s' took %.2fs!", module, tick() - start))
        end
    end

    return modules
end

--- Loads a singular file into Stellar
function Stellar.Load(module: ModuleScript)
    assert(
        typeof(module) == "Instance" and module:IsA("ModuleScript"),
        `[Stellar] Attempted to load a '{typeof(module)}', ModuleScript expected!`
    )
    assert(Assets[module.Name] == nil, `[Stellar] Attempted to load duplicate named module '{module.Name}'`)

    if module ~= script then
        Assets[module.Name] = module
    end
end

--- Loads multiple files into Stellar at once
function Stellar.BulkLoad(...: Folder)
    local function recurseAsset(asset: Instance)
        if asset:IsA("ModuleScript") then
            Stellar.Load(asset)
        else
            for _, item: Instance in asset:GetChildren() do
                recurseAsset(item)
            end
        end
    end

    for _, directory: Folder in { ... } do
        assert(
            typeof(directory) == "Instance" and directory:IsA("Folder"),
            `[Stellar] Attempted to bulk load a '{typeof(directory)}', Folder expected!`
        )

        print(`[Stellar] Loading modules in directory '{directory.Name}'`)
        recurseAsset(directory)
    end
end

function Stellar._Initialise(name: string, module: any)
    if module.Init ~= nil and Initialised[name] == nil then
        local success: boolean, result: any = nil, nil
        local hasWarned: boolean = false
        local start: number = tick()

        task.spawn(function()
            success, result = pcall(module.Init, module)
        end)

        while success == nil do
            if tick() - start > 15 and not hasWarned then
                warn(`[Stellar::Danger] '{name}' is taking a long time to initialise!`)
                hasWarned = true
            end
            task.wait()
        end

        if hasWarned then
            warn(string.format("[Stellar::Resolved] '%s' has finished initialising. Took %.2fs!", name, tick() - start))
        end

        if not success then
            warn(`[Stellar] Failed to initialise '{name}' due to: {result}`)
        end

        Initialised[name] = true
    end
end

function Stellar._Import(module: ModuleScript): (boolean, any)
    if module:IsA("ModuleScript") then
        local start: number = tick()
        local result: {} = nil
        local hasLogged: boolean = false

        task.spawn(function()
            result = table.pack(pcall(require, module))
        end)

        while result == nil do
            if tick() - start > 15 and not hasLogged then
                warn(`[Stellar::Danger] '{module.Name}' is taking a long time to require!`)
                hasLogged = true
            end
            task.wait()
        end

        if hasLogged then
            warn(
                string.format(
                    "[Stellar::Resolved] '%s' has finished requiring. Took %.2fs!",
                    module.Name,
                    tick() - start
                )
            )
        end

        return table.unpack(result)
    end
end

--- Retrieves a wally package by name
function Stellar.Library(name: string): any
    if CachedPackages[name] ~= nil then
        return CachedPackages[name]
    end

    if PackageLocations == nil then
        local packages: Folder? = ReplicatedStorage:FindFirstChild("Packages")
        PackageLocations = {}

        if packages ~= nil then
            table.insert(PackageLocations, packages)
        end

        if RunService:IsServer() then
            local serverPackages: Folder? = ServerStorage:FindFirstChild("ServerPackages")

            if serverPackages ~= nil then
                table.insert(serverPackages, serverPackages)
            end
        end
    end

    for _, location: Folder in PackageLocations do
        local module: Instance = location:FindFirstChild(name)

        if module ~= nil and module:IsA("ModuleScript") then
            local success: boolean, result: any = Stellar._Import(module)

            if success then
                print(`[Stellar] Successfully imported package '{name}'`)
                CachedPackages[name] = result
                return result
            end
        end
    end

    warn(`[Stellar] Package with name {name} not found!`)
end

--- @deprecated v2 -- Function will not error so existing code still works. Please implement your own solution
function Stellar.MarkAsLoaded()
    warn("[Stellar] MarkAsLoaded is deprecated in Stellar V2")
end

--- @deprecated v2 -- Function will be called so existing code still works. Please implement your own solution
function Stellar.OnLoadingCompletion(func: () -> ())
    warn("[Stellar] OnLoadingCompletion is deprecated in Stellar V2: Function run now")
    task.spawn(func)
end

return Stellar
