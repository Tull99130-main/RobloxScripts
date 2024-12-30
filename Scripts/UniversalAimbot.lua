local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Create the main window
local Window = OrionLib:MakeWindow({
    Name = "Phantom Hub V 1.0",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AimbotConfig"
})

-- Create Main Tab
local MainTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variables for aimbot, team check, and target part
local EnableAimbot = false
local TeamCheck = false
local TargetPart = "HumanoidRootPart"
local ToggleAim = false
local IsAiming = false
local MaxDistance = 2000  -- Maximum distance for targeting

-- Add sections and toggles to Main Tab
local Section = MainTab:AddSection({Name = "Aimbot Settings"})
Section:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(Value)
        EnableAimbot = Value
    end
})

Section:AddToggle({
    Name = "Team Check",
    Default = false,
    Callback = function(Value)
        TeamCheck = Value
    end
})

Section:AddDropdown({
    Name = "Target Part",
    Default = "HumanoidRootPart",
    Options = {"Head", "HumanoidRootPart"},
    Callback = function(Value)
        TargetPart = Value
    end
})

Section:AddToggle({
    Name = "Toggle Aim (Hold Right Mouse)",
    Default = false,
    Callback = function(Value)
        ToggleAim = Value
    end
})

-- Create FOV Tab
local FOVTab = Window:MakeTab({
    Name = "Field Of View",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variables for FOV circle and rainbow effect
local FOVEnabled = false
local FOVSize = 20
local FOVVisible = false
local FOVColor = Color3.fromRGB(255, 0, 0)
local RainbowEnabled = false

-- Variables for camera aiming
local Camera = workspace.CurrentCamera
local fovCircle = nil  -- To store the FOV circle drawing object

-- Create sections and controls for FOV
local FOVSection = FOVTab:AddSection({Name = "FOV Settings"})
FOVSection:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(Value)
        FOVEnabled = Value
    end
})

FOVSection:AddSlider({
    Name = "FOV Size",
    Min = 10,
    Max = 85,
    Default = 20,
    Callback = function(Value)
        FOVSize = Value
    end
})

FOVSection:AddToggle({
    Name = "Visible",
    Default = false,
    Callback = function(Value)
        FOVVisible = Value
    end
})

FOVSection:AddColorpicker({
    Name = "Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        FOVColor = Value
    end
})

FOVSection:AddToggle({
    Name = "Rainbow",
    Default = false,
    Callback = function(Value)
        RainbowEnabled = Value
    end
})

-- Create ESP Tab
local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variables for ESP
local ESPEnabled = false
local ESPObjects = {}

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

-- Body parts to include in the skeleton
local BodyParts = {
    "Head",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

-- Skeleton connections
local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

-- Function to get the team color or default to white
local function getPlayerColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.new(1, 1, 1) -- Default to white if no team
end

-- Function to create skeletons for a player
local function createSkeleton(player)
    if player == localPlayer then return end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    ESPObjects[player] = {}
    for _, connection in ipairs(SkeletonConnections) do
        local fromPart = character:FindFirstChild(connection[1])
        local toPart = character:FindFirstChild(connection[2])
        if fromPart and toPart then
            local line = Drawing.new("Line")
            line.Color = getPlayerColor(player) -- Set color based on team
            line.Thickness = 2
            line.Visible = false
            ESPObjects[player][connection] = line
        end
    end
end

-- Function to update skeletons
local function updateSkeletons()
    for player, lines in pairs(ESPObjects) do
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            for _, line in pairs(lines) do
                line:Remove()
            end
            ESPObjects[player] = nil
        else
            for connection, line in pairs(lines) do
                local fromPart = character:FindFirstChild(connection[1])
                local toPart = character:FindFirstChild(connection[2])
                if fromPart and toPart then
                    local fromPos = camera:WorldToViewportPoint(fromPart.Position)
                    local toPos = camera:WorldToViewportPoint(toPart.Position)

                    if fromPos.Z > 0 and toPos.Z > 0 then
                        line.From = Vector2.new(fromPos.X, fromPos.Y)
                        line.To = Vector2.new(toPos.X, toPos.Y)
                        line.Color = getPlayerColor(player) -- Update color in case of team change
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        end
    end
end

-- Function to delete skeletons
local function deleteSkeletons()
    for _, lines in pairs(ESPObjects) do
        for _, line in pairs(lines) do
            line:Remove()
        end
    end
    ESPObjects = {}
end

-- Handle toggling ESP
ESPTab:AddToggle({
    Name = "Skeleton ESP",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
        if not ESPEnabled then
            deleteSkeletons()
        else
            for _, player in pairs(players:GetPlayers()) do
                createSkeleton(player)
            end
        end
    end
})

-- Handle player join
players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        createSkeleton(player)
    end
end)

-- Handle player leave
players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, line in pairs(ESPObjects[player]) do
            line:Remove()
        end
        ESPObjects[player] = nil
    end
end)

-- Constantly update skeletons
game:GetService("RunService").RenderStepped:Connect(function()
    if ESPEnabled then
        updateSkeletons()
    end
end)

-- Create Miscellaneous Tab
local MiscTab = Window:MakeTab({
    Name = "Misc Features",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddButton({
    Name = "Unload UI",
    Callback = function()
        OrionLib:Destroy()
    end
})

-- Aimbot Functionality
local function GetPlayerPartPosition(player)
    local character = player.Character
    if character and character:FindFirstChild(TargetPart) then
        return character[TargetPart].Position
    end
    return nil
end

-- Check if a player is alive
local function IsPlayerAlive(player)
    local character = player.Character
    return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end

-- Check if player is in FOV
local function IsPlayerInFOV(playerPosition)
    local screenPosition, onScreen = Camera:WorldToScreenPoint(playerPosition)
    local fovRadius = (FOVSize / 360) * Camera.ViewportSize.X
    local fovCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Check if the player is inside the FOV circle
    if (Vector2.new(screenPosition.X, screenPosition.Y) - fovCenter).Magnitude <= fovRadius then
        return true
    end
    return false
end

-- Smooth Mouse Movement (for aimbot)
local function SmoothAim(targetPosition, smoothness)
    local direction = (targetPosition - Camera.CFrame.p).unit
    local newPosition = Camera.CFrame.p + direction * smoothness
    Camera.CFrame = CFrame.new(newPosition, targetPosition)
end

-- Aimbot logic (when enabled and toggle is active)
local function LockAimbot()
    if EnableAimbot and (not ToggleAim or IsAiming) then
        local closestPlayer = nil
        local closestDistance = math.huge
        local closestPlayerPosition = nil
        
        -- Find the closest player within the FOV and 2000 studs
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer and IsPlayerAlive(player) then
                -- If there are no teams, or the player isn't on the same team, use the aimbot
                if not TeamCheck or (player.Team ~= game.Players.LocalPlayer.Team) then
                    local partPosition = GetPlayerPartPosition(player)
                    if partPosition then
                        -- Calculate the distance to the player
                        local distance = (partPosition - Camera.CFrame.p).magnitude
                        
                        -- Check if the player is within the distance limit and is in the FOV
                        if distance <= MaxDistance and IsPlayerInFOV(partPosition) then
                            -- Check if the player is closer than the previous closest one
                            if distance < closestDistance then
                                closestPlayer = player
                                closestDistance = distance
                                closestPlayerPosition = partPosition
                            end
                        end
                    end
                end
            end
        end
        
        -- Aim at the closest player if found
        if closestPlayerPosition then
            SmoothAim(closestPlayerPosition, 0.1)
        end
    end
end

-- FOV Circle handling using Drawing.new("Circle")
local function DrawFOVCircle()
    if FOVEnabled and FOVVisible then
        -- Remove any existing FOV circle if present
        if fovCircle then
            fovCircle:Remove()
        end
        
        -- Create a new circle for FOV
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = FOVColor
        fovCircle.Thickness = 3  -- Make it visible as a hollow circle
        fovCircle.Transparency = 1
        fovCircle.Filled = false
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        -- Adjust the size of the circle based on the FOV size
        local fovRadius = (FOVSize / 360) * Camera.ViewportSize.X
        fovCircle.Radius = fovRadius
        
        -- Make the circle visible
        fovCircle.Visible = true
    else
        -- Hide the circle when FOV is disabled or visibility is off
        if fovCircle then
            fovCircle.Visible = false
        end
    end
end

-- Rainbow effect for FOV
local function ApplyRainbowEffect()
    if RainbowEnabled then
        local time = tick()
        FOVColor = Color3.fromHSV(time % 5 / 5, 1, 1)  -- Gradually cycle through the color spectrum
    end
end

-- Mouse input listener for Toggle Aim
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = true
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = false
    end
end)

-- Main Update Loop
game:GetService("RunService").RenderStepped:Connect(function()
    if EnableAimbot then
        LockAimbot()
    end
    
    -- Update FOV circle
    DrawFOVCircle()
    
    -- Apply rainbow effect for FOV color
    ApplyRainbowEffect()
end)

-- Finalize the UI
OrionLib:Init()
