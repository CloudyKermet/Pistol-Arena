-- Silent Aim Remote Interceptor - FIXED
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Get closest player's Head
local function getClosestPlayerHead()
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, nil, nil end
    local myPos = myChar.HumanoidRootPart.Position
    local closestDist = math.huge
    local closestPlayer = nil
    local closestHead = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local dist = (head.Position - myPos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestPlayer = player
            closestHead = head
        end
    end
    return closestHead, closestPlayer, closestDist
end

local remote = game:GetService("ReplicatedStorage").SystemResources.BufferCache.RequestActionSync

-- Store original
local oldFireServer = remote.FireServer

-- Hook via __namecall
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and self == remote then
        local args = {...}
        local data = args[1]
        
        if type(data) == "table" then
            local head, player, dist = getClosestPlayerHead()
            if head and player then
                local headPos = head.Position
                local origin = data.origin
                if not origin and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    origin = LP.Character.HumanoidRootPart.Position
                end
                local newDirection = origin and ((headPos - origin).Unit) or data.direction
                
                data.direction = newDirection
                data.hitPosition = headPos
                data.origin = origin or data.origin
                data.hitInstance = head
                data.hitHumanoid = head.Parent:FindFirstChildOfClass("Humanoid") or head.Parent:FindFirstChild("Humanoid")
                data.IsHeadshot = true
            end
        end
        
        return oldFireServer(self, data or args[1])
    end
    
    return __namecall(self, ...)
end)
