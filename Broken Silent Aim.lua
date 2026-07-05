-- FOV-Based Silent Aim Remote Interceptor - Mobile Friendly (Drawing API)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ===== CONFIGURATION / TOGGLES =====
local Settings = {
    SilentAim = true,
    WallCheck = true,
    FOVRadius = 80,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVLockedColor = Color3.fromRGB(255, 50, 50),
    FOVThickness = 1.5,
    FOVTransparency = 0.3,
}

-- ===== DRAWING OBJECTS =====
local fovOutline = Drawing.new("Circle")
fovOutline.Visible = true
fovOutline.Radius = Settings.FOVRadius
fovOutline.Thickness = Settings.FOVThickness
fovOutline.Color = Settings.FOVColor
fovOutline.Filled = false
fovOutline.NumSides = 64

local fovFill = Drawing.new("Circle")
fovFill.Visible = true
fovFill.Radius = Settings.FOVRadius
fovFill.Thickness = 0
fovFill.Color = Settings.FOVColor
fovFill.Filled = true
fovFill.Transparency = Settings.FOVTransparency
fovFill.NumSides = 64

local centerDot = Drawing.new("Circle")
centerDot.Visible = true
centerDot.Radius = 2
centerDot.Thickness = 0
centerDot.Color = Color3.fromRGB(255, 255, 255)
centerDot.Filled = true
centerDot.Transparency = 0.3
centerDot.NumSides = 16

-- ===== TEXT TOGGLES (top of screen) =====
local silentText = Drawing.new("Text")
silentText.Visible = true
silentText.Text = "[SilentAim: ON]"
silentText.Size = 16
silentText.Color = Color3.fromRGB(0, 255, 100)
silentText.Center = true
silentText.Outline = true
silentText.Font = Drawing.Fonts.UI

local wallText = Drawing.new("Text")
wallText.Visible = true
wallText.Text = "[WallCheck: ON]"
wallText.Size = 16
wallText.Color = Color3.fromRGB(0, 255, 100)
wallText.Center = true
wallText.Outline = true
wallText.Font = Drawing.Fonts.UI

local fovText = Drawing.new("Text")
fovText.Visible = true
fovText.Text = "[FOV: " .. Settings.FOVRadius .. "]"
fovText.Size = 16
fovText.Color = Color3.fromRGB(255, 255, 255)
fovText.Center = true
fovText.Outline = true
fovText.Font = Drawing.Fonts.UI

-- Refresh text state
local function refreshToggles()
    silentText.Text = "[SilentAim: " .. (Settings.SilentAim and "ON" or "OFF") .. "]"
    silentText.Color = Settings.SilentAim and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    wallText.Text = "[WallCheck: " .. (Settings.WallCheck and "ON" or "OFF") .. "]"
    wallText.Color = Settings.WallCheck and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    fovText.Text = "[FOV: " .. Settings.FOVRadius .. "]"
end

-- ===== UTILITY FUNCTIONS =====
-- Get exact center of screen using viewport size directly
local function getScreenCenter()
    local camera = Workspace.CurrentCamera
    if camera and camera.ViewportSize then
        local vs = camera.ViewportSize
        return Vector2.new(vs.X / 2, vs.Y / 2)
    end
    local res = UserInputService:GetScreenResolution()
    return Vector2.new(res.X / 2, res.Y / 2)
end

-- Center all circles to exact middle of screen and update radius
local function centerCircles()
    local center = getScreenCenter()
    fovOutline.Position = center
    fovFill.Position = center
    centerDot.Position = center
    fovOutline.Radius = Settings.FOVRadius
    fovFill.Radius = Settings.FOVRadius
end

-- Do it immediately
centerCircles()

-- And also after a short delay in case camera wasn't ready
task.delay(1, centerCircles)

-- Wall check using raycast
local function isVisible(targetPosition)
    if not Settings.WallCheck then return true end
    
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetPosition - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LP.Character, camera}
    
    local result = Workspace:Raycast(origin, direction * (targetPosition - origin).Magnitude, raycastParams)
    return result == nil
end

-- Check if a world position is within the FOV circle on screen
local function isInFOV(worldPosition)
    local camera = Workspace.CurrentCamera
    if not camera then return false, nil end
    
    local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
    if not onScreen then return false, nil end
    
    local screenCenter = getScreenCenter()
    local point2D = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (point2D - screenCenter).Magnitude
    
    return distanceFromCenter <= Settings.FOVRadius, distanceFromCenter
end

-- Get the closest visible player whose Head is inside the FOV
local function getFOVTarget()
    if not Settings.SilentAim then return nil, nil end
    
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, nil end
    
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
        if not inRange then continue end
        
        if Settings.WallCheck and not isVisible(head.Position) then continue end
        
        if dist < closestDist then
            closestDist = dist
            closestPlayer = player
            closestHead = head
        end
    end
    
    return closestHead, closestPlayer
end

-- ===== KEYBIND TOGGLES =====
local KEY_SILENT = Enum.KeyCode.Q
local KEY_WALL = Enum.KeyCode.E
local KEY_FOV_UP = Enum.KeyCode.Z
local KEY_FOV_DOWN = Enum.KeyCode.X
local FOV_STEP = 10

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == KEY_SILENT then
        Settings.SilentAim = not Settings.SilentAim
        refreshToggles()
    
    elseif input.KeyCode == KEY_WALL then
        Settings.WallCheck = not Settings.WallCheck
        refreshToggles()
    
    elseif input.KeyCode == KEY_FOV_UP then
        Settings.FOVRadius = math.min(Settings.FOVRadius + FOV_STEP, 500)
        centerCircles()
        refreshToggles()
    
    elseif input.KeyCode == KEY_FOV_DOWN then
        Settings.FOVRadius = math.max(Settings.FOVRadius - FOV_STEP, 10)
        centerCircles()
        refreshToggles()
    end
end)

-- ===== RENDER LOOP =====
RunService:BindToRenderStep("FOVCheck", Enum.RenderPriority.Camera.Value, function()
    local camera = Workspace.CurrentCamera
    local center
    
    if camera and camera.ViewportSize then
        local vs = camera.ViewportSize
        center = Vector2.new(vs.X / 2, vs.Y / 2)
    else
        local res = UserInputService:GetScreenResolution()
        center = Vector2.new(res.X / 2, res.Y / 2)
    end
    
    -- Hard-set positions every frame
    fovOutline.Position = center
    fovFill.Position = center
    centerDot.Position = center
    fovOutline.Radius = Settings.FOVRadius
    fovFill.Radius = Settings.FOVRadius
    
    -- Update text positions to center
    if camera and camera.ViewportSize then
        local centerX = camera.ViewportSize.X / 2
        silentText.Position = Vector2.new(centerX, 20)
        wallText.Position = Vector2.new(centerX, 40)
        fovText.Position = Vector2.new(centerX, 60)
    else
        local centerX = UserInputService:GetScreenResolution().X / 2
        silentText.Position = Vector2.new(centerX, 20)
        wallText.Position = Vector2.new(centerX, 40)
        fovText.Position = Vector2.new(centerX, 60)
    end
    
    -- Check for target
    local head, _ = getFOVTarget()
    local hasTarget = head ~= nil
    
    -- Update colors
    local targetColor = hasTarget and Settings.FOVLockedColor or Settings.FOVColor
    fovOutline.Color = targetColor
    fovFill.Color = targetColor
    
    -- Toggle visibility of FOV based on silent aim state
    fovOutline.Visible = Settings.SilentAim
    fovFill.Visible = Settings.SilentAim
    centerDot.Visible = Settings.SilentAim
end)

-- ===== REMOTE HOOK =====
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
