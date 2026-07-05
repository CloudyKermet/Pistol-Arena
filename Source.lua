local speed = false
local guncham = false
local silentaim = false
local MasterToggle = false
local SkeletonToggle = false
local NameToggle = false

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local NameCache = {}

local function createNameESP()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Font = 3
    text.Size = 16
    text.Color = Color3.new(1, 1, 1)
    return text
end

local function updateNameESP(player)
    if player == LocalPlayer then return end
    if not MasterToggle or not NameToggle then
        if NameCache[player] then
            NameCache[player].Visible = false
        end
        return
    end

    local character = player.Character
    if not character then
        if NameCache[player] then
            NameCache[player].Visible = false
        end
        return
    end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not head or not humanoid or humanoid.Health <= 0 then
        if NameCache[player] then
            NameCache[player].Visible = false
        end
        return
    end

    if not NameCache[player] then
        NameCache[player] = createNameESP()
    end

    local text = NameCache[player]
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)

    if onScreen then
        text.Position = Vector2.new(headPos.X, headPos.Y - 30)
        text.Text = player.Name
        text.Visible = true
    else
        text.Visible = false
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        updateNameESP(player)
    end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(plr)
    if NameCache[plr] then
        NameCache[plr]:Remove()
        NameCache[plr] = nil
    end
end)

local Settings = {
    Color = Color3.fromRGB(0, 255, 100),
    Thickness = 2,
    Transparency = 1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local SkeletonCache = {}

local function createSkeleton()
    local lines = {}
    for i = 1, 18 do
        local line = Drawing.new("Line")
        line.Color = Settings.Color
        line.Thickness = Settings.Thickness
        line.Transparency = Settings.Transparency
        line.Visible = false
        table.insert(lines, line)
    end
    return lines
end

local function updateSkeleton(player)
    if player == LocalPlayer then return end
    if not MasterToggle or not SkeletonToggle then 
        if SkeletonCache[player] then
            for _, line in ipairs(SkeletonCache[player]) do line.Visible = false end
        end
        return 
    end

    local character = player.Character
    if not character then
        if SkeletonCache[player] then
            for _, line in ipairs(SkeletonCache[player]) do line.Visible = false end
        end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    if not SkeletonCache[player] then
        SkeletonCache[player] = createSkeleton()
    end

    local lines = SkeletonCache[player]
    local index = 1

    local function connect(p1, p2)
        if not p1 or not p2 then return end
        local v1 = Camera:WorldToViewportPoint(p1.Position)
        local v2 = Camera:WorldToViewportPoint(p2.Position)

        if v1.Z < 0 or v2.Z < 0 then return end

        local line = lines[index]
        line.From = Vector2.new(v1.X, v1.Y)
        line.To = Vector2.new(v2.X, v2.Y)
        line.Visible = true
        index += 1
    end

    local head   = character:FindFirstChild("Head")
    local utorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local ltorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
    local hrp    = character:FindFirstChild("HumanoidRootPart")

    local lua = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
    local lla = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
    local lhand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")

    local rua = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    local rla = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm")
    local rhand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")

    local lul = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
    local lll = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg")
    local lfoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")

    local rul = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    local rll = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg")
    local rfoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")

    connect(head, utorso)
    connect(utorso, ltorso)
    connect(utorso, hrp)

    connect(utorso, lua)  connect(lua, lla)  connect(lla, lhand)
    connect(utorso, rua)  connect(rua, rla)  connect(rla, rhand)

    connect(ltorso or hrp, lul)  connect(lul, lll)  connect(lll, lfoot)
    connect(ltorso or hrp, rul)  connect(rul, rll)  connect(rll, rfoot)

    for i = index, #lines do
        lines[i].Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        updateSkeleton(player)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if SkeletonCache[plr] then
        for _, line in ipairs(SkeletonCache[plr]) do
            line:Remove()
        end
        SkeletonCache[plr] = nil
    end
end)

print("Skeleton ESP Loaded | Master:", MasterToggle, "| Skeleton:", SkeletonToggle)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local EXPAND_SIZE = 45
local MAX_DISTANCE = 800

RunService.RenderStepped:Connect(function()
	if not silentaim then return end
	
	local center = camera.ViewportSize / 2
	local closest = nil
	local closestDist = math.huge
	
	for _, v in ipairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			local root = v.Character.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
			
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				local realDist = (root.Position - camera.CFrame.Position).Magnitude
				
				if dist < closestDist and realDist < MAX_DISTANCE then
					closestDist = dist
					closest = root
				end
			end
		end
	end
	
	-- Apply expansion only to closest
	for _, v in ipairs(Players:GetPlayers()) do
		if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			local root = v.Character.HumanoidRootPart
			
			if root == closest then
				root.Size = Vector3.new(EXPAND_SIZE, EXPAND_SIZE, EXPAND_SIZE)
				root.Transparency = 1
				root.CanCollide = false
			else
				-- Reset others
				if root.Size.X > 5 then
					root.Size = Vector3.new(2, 2, 1)
					root.Transparency = 0
				end
			end
		end
	end
end)

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local MULT, STEP = 3, 0.5
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local conn

local function setup(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	params.FilterDescendantsInstances = {char}
	
	local last = hrp.Position
	if conn then conn:Disconnect() end
	
	conn = RunService.Heartbeat:Connect(function(dt)
		if not speed or hum.Health <= 0 then return end
		local dir = hum.MoveDirection
		if dir.Magnitude < 0.1 then last = hrp.Position return end
		
		local vel = dir * hum.WalkSpeed * MULT * dt
		local steps = math.ceil(vel.Magnitude / STEP)
		local stepv = vel / steps
		local pos = hrp.Position
		
		for i = 1, steps do
			local nxt = pos + stepv
			local res = workspace:Raycast(pos, nxt-pos, params)
			if res and res.Distance < (nxt-pos).Magnitude then
				hrp.CFrame = CFrame.new(res.Position - (nxt-pos).Unit*0.1) * hrp.CFrame.Rotation
				last = hrp.Position
				return
			end
			pos = nxt
		end
		
		hrp.CFrame = CFrame.new(pos) * hrp.CFrame.Rotation
		last = pos
	end)
end

player.CharacterAdded:Connect(setup)
if player.Character then setup(player.Character) end

local hl = Instance.new("Highlight")
hl.Name = "hl1"
hl.FillColor = Color3.fromRGB(255, 0, 255)     -- Inside color
hl.OutlineColor = Color3.fromRGB(255, 255, 255) -- Border color
hl.FillTransparency = 0.3                       -- 0 = solid, 1 = invisible
hl.OutlineTransparency = 1                       -- 0 = solid outline
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- Or Occluded



local cam = workspace.Camera
RunService.Heartbeat:Connect(function(dt)
if guncham and cam:FindFirstChild("Viewmodel") then
for _, gun in ipairs(cam:FindFirstChild("Viewmodel"):FindFirstChild("Parts"):GetChildren()) do
if gun:IsA("MeshPart") and not gun:FindFirstChild("hl1") then
gun.Transparency = 0.9
local h9 = hl:Clone()
h9.Parent = gun		
                end
            end
        end
    end)

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gustaslaoq/ui-library/refs/heads/main/library.lua"))()

local ui = Lib.new({
    AppName     = "Pistol Arena",
    AppSubtitle = "KermetDevelopment",
    AppVersion  = "1.0",
    Pages = {
        { Name = "Main" },
        { Name = "Visuals" },
    },
})

-- Add a toggle to page 1 (Main)
ui:AddToggle(1, "Silent Aim", false, function(value)
  silentaim = value
end)

ui:AddToggle(1, "Speed", false, function(value)
  speed = value
end)

ui:AddToggle(2, "Master Esp", false, function(value)
  MasterToggle = value
end)

ui:AddCheckbox(2, "Skeleton", false, function(value)
    SkeletonToggle = value
end)

ui:AddCheckbox(2, "Name", false, function(value)
    NameToggle = value
end)

ui:AddToggle(2, "Gun RGB", false, function(value)
  guncham = value

if not value and workspace.Camera:FindFirstChild("Viewmodel") then
for _, gun in ipairs(cam:FindFirstChild("Viewmodel"):FindFirstChild("Parts"):GetChildren()) do
if gun:IsA("MeshPart") then
gun.Transparency = 0	
gun:FindFirstChild("hl1"):Destroy()
                end
            end
        end		
end)

local hue = 0

RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.50) % 1
    local color = Color3.fromHSV(hue, 1, 1)

    local vm = workspace.CurrentCamera:FindFirstChild("Viewmodel")
    if not vm then return end

    local parts = vm:FindFirstChild("Parts")
    if not parts then return end

    for _, gun in ipairs(parts:GetChildren()) do
        local h = gun:FindFirstChild("hl1")
        if h then
            h.FillColor = color
            h.OutlineColor = color
        end
    end
end)




