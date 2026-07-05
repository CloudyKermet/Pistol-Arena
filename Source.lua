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
  
end)

ui:AddToggle(1, "Speed", false, function(value)
  
end)

ui:AddToggle(2, "Master Esp", false, function(value)
  
end)

ui:AddCheckbox(2, "Skeleton", false, function(value)
    
end)

ui:AddCheckbox(2, "Name", false, function(value)
    
end)




