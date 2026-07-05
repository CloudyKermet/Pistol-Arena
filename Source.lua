local speed = false
local guncham = false
local silentaim = false

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

game:GetService("RunService").Heartbeat:Connect(function()
	hl.FillColor = Color3.fromHSV((tick() % 6) / 6, 1, 1)
end)

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
  
end)

ui:AddCheckbox(2, "Skeleton", false, function(value)
    
end)

ui:AddCheckbox(2, "Name", false, function(value)
    
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




