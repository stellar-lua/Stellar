--[=[
    @class SoundFX
    A simplistic way to store and play sound effects
    Sounds must be stored in ReplicatedStorage inside a folder called "SoundFXs"
    You can (and advised) to store sounds in subfolders if you have a large amount
]=]

local SoundFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = {}

--[[function SoundFX:Play(name: string, part: BasePart?, duplicate: boolean?) end

function SoundFX:GetSound(name: string) end--]]

function SoundFX:Init()
    local soundFolder: Folder? = ReplicatedStorage:FindFirstChild("SoundFXs")

    if soundFolder ~= nil then
        for _, asset in pairs(soundFolder:GetDescendants()) do
            if asset:IsA("Sound") then
                if Sounds[asset.Name] ~= nil then
                    warn(`[SoundFX] Duplicate sound with name '{asset.Name}' sound. Ignored.`)
                else
                    Sounds[asset.Name] = asset
                end
            end
        end
    end
end

return SoundFX
