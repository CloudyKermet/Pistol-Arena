-- FOV-Based Silent Aim Remote Interceptor - Mobile Friendly (Drawing API)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Configuration
local FOV_RADIUS = 80          -- Radius of the FOV circle (in screen pixels)
local FOV_COLOR_NORMAL = Color3.fromRGB(255, 255, 255)  -- White when no target
local FOV_COLOR_LOCKED = Color3.fromRGB(255, 50, 50)    -- Red when target in FOV
local FOV_THICKNESS = 1.5
local FOV_TRANSPARENCY = 0.3   -- Inner fill transparency (0 = opaque, 1 = invisible)

-- Create Drawing objects
local fovOutline = Drawing.new("Circle")
fovOutline.Visible = true
fovOutline.Radius = FOV_RADIUS
fovOutline.Thickness = FOV_THICKNESS
fovOutline.Color = FOV_COLOR_NORMAL
fovOutline.Filled = false
fovOutline.NumSides = 64

local fovFill = Drawing.new("Circle")
fovFill.Visible = true
fovFill.Radius = FOV_RADIUS
fovFill.Thickness = 0
fovFill.Color = FOV_COLOR_NORMAL
fovFill.Filled = true
fovFill.Transparency = FOV_TRANSPARENCY
fovFill.NumSides = 64

local centerDot = Drawing.new("Circle")
centerDot.Visible = true
centerDot.Radius = 2
centerDot.Thickness = 0
centerDot.Color = Color3.fromRGB(255, 255, 255)
centerDot.Filled = true
centerDot.Transparency = 0.3
centerDot.NumSides = 16

-- Get viewport size reliably (no camera dependency for positioning)
local function getScreenCenter()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
    or (UserInputService:GetScreenResolution())
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

-- Immediately center on start
local function centerCircles()
    local center = getScreenCenter()
    fovOutline.Position = center
    fovFill.Position = center
    centerDot.Position = center
end
centerCircles()

-- Check if a world position is within the FOV circle on screen
local function isInFOV(worldPosition)
    local camera = Workspace.CurrentCamera
    if not camera then return false, nil end
    
    local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
    if not onScreen then return false, nil end
    
    local screenCenter = getScreenCenter()
    local point2D = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (point2D - screenCenter).Magnitude
    
    return distanceFromCenter <= FOV_RADIUS, distanceFromCenter
end

-- === WALL CHECK ===
-- Returns true if there is a clear line of sight from the origin to the target position
local function hasLineOfSight(origin, targetPosition)
    if not origin then return false end
    
    -- Cast a ray from origin to target, ignoring the local player's character
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LP.Character}
    
    local direction = (targetPosition - origin).Unit
    local maxDistance = (targetPosition - origin).Magnitude
    
    local rayResult = Workspace:Raycast(origin, direction * maxDistance, rayParams)
    
    -- If nothing was hit, line of sight is clear
    if not rayResult then return true end
    
    -- Check if the hit was actually the target's character (ignore self, already filtered)
    local hitInstance = rayResult.Instance
    if hitInstance then
        local hitParent = hitInstance:FindFirstAncestorOfClass("Model") or hitInstance.Parent
        -- If we hit the target's character, that's fine — treat as LOS
        if hitParent and hitParent:FindFirstChild("Humanoid") then
            return true
        end
    end
    
    return false
end

-- Get the closest player whose Head is inside the FOV AND has line of sight
local function getFOVTarget()
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, nil end
    
    local origin = myChar.HumanoidRootPart.Position
    
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
        
        local inRange, dist = isInFOV(head.Position)
        if inRange and dist < closestDist then
            -- === WALL CHECK: only consider targets with clear line of sight ===
            if hasLineOfSight(origin, head.Position) then
                closestDist = dist
                closestPlayer = player
                closestHead = head
            end
        end
    end
    
    return closestHead, closestPlayer
end

-- Update FOV indicator each frame
RunService:BindToRenderStep("FOVCheck", Enum.RenderPriority.Camera.Value, function()
    -- Always keep centered (handles orientation changes, resizing, etc.)
    centerCircles()
    
    -- Check for target
    local head, _ = getFOVTarget()
    local hasTarget = head ~= nil
    
    -- Update colors
    local targetColor = hasTarget and FOV_COLOR_LOCKED or FOV_COLOR_NORMAL
    fovOutline.Color = targetColor
    fovFill.Color = targetColor
end)

-- Hook the remote via __namecall
local remote = game:GetService("ReplicatedStorage").SystemResources.BufferCache.RequestActionSync
local oldFireServer = remote.FireServer

local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and self == remote then
        local args = {...}
        local data = args[1]
        
        if type(data) == "table" then
            local head, player = getFOVTarget()
            
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
