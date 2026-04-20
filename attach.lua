-- =============================================
--   ULTIMATE PHYSICS BREAKER GUI v4.0
--   Standard Bypass | Ultimate Breaker | GOD MODE
--   For Roblox Experimentation Videos
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Bypass Levels
local BypassLevel = {
    STANDARD = 1,
    ULTIMATE = 2,
    GODMODE = 3
}

local currentLevel = BypassLevel.STANDARD
local isRunning = false
local connection = nil
local manualTarget = nil
local manualTargetName = nil
local offset = -0.5
local teleportCount = 0
local lastDistance = "N/A"

-- Remove old GUI
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("UltimateBypassGUI") then
    playerGui:FindFirstChild("UltimateBypassGUI"):Destroy()
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateBypassGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 650)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -325)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.08
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 16)

-- Shadow
local shadow = Instance.new("Frame", mainFrame)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = -1
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 20)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleGradient = Instance.new("UIGradient", titleBar)
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 45))
})

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ ULTIMATE PHYSICS BREAKER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}):Play()
end)

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(0.9, 0, 0, 55)
statusCard.Position = UDim2.new(0.05, 0, 0.12, 0)
statusCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statusCard.BorderSizePixel = 0
statusCard.Parent = mainFrame
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 12)

local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0, 30, 1, 0)
statusIcon.Position = UDim2.new(0, 15, 0, 0)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "●"
statusIcon.TextColor3 = Color3.fromRGB(0, 255, 100)
statusIcon.Font = Enum.Font.GothamBold
statusIcon.TextSize = 20
statusIcon.TextYAlignment = Enum.TextYAlignment.Center
statusIcon.Parent = statusCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -60, 0.6, 0)
statusLabel.Position = UDim2.new(0, 55, 0, 8)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "READY"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusCard

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, -60, 0.4, 0)
levelLabel.Position = UDim2.new(0, 55, 0, 32)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level: STANDARD BYPASS"
levelLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
levelLabel.Font = Enum.Font.Gotham
levelLabel.TextSize = 11
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = statusCard

-- Bypass Level Selector
local levelCard = Instance.new("Frame")
levelCard.Size = UDim2.new(0.9, 0, 0, 120)
levelCard.Position = UDim2.new(0.05, 0, 0.24, 0)
levelCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
levelCard.BorderSizePixel = 0
levelCard.Parent = mainFrame
Instance.new("UICorner", levelCard).CornerRadius = UDim.new(0, 12)

local levelTitle = Instance.new("TextLabel")
levelTitle.Size = UDim2.new(0.5, 0, 0, 20)
levelTitle.Position = UDim2.new(0.05, 0, 0, 8)
levelTitle.BackgroundTransparency = 1
levelTitle.Text = "🎚️ BYPASS LEVEL"
levelTitle.TextColor3 = Color3.fromRGB(150, 150, 180)
levelTitle.Font = Enum.Font.Gotham
levelTitle.TextSize = 11
levelTitle.TextXAlignment = Enum.TextXAlignment.Left
levelTitle.Parent = levelCard

-- Level Buttons
local standardBtn = Instance.new("TextButton")
standardBtn.Size = UDim2.new(0.28, 0, 0.35, 0)
standardBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
standardBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)
standardBtn.Text = "STANDARD"
standardBtn.TextColor3 = Color3.new(1,1,1)
standardBtn.Font = Enum.Font.GothamBold
standardBtn.TextSize = 12
standardBtn.Parent = levelCard
Instance.new("UICorner", standardBtn).CornerRadius = UDim.new(0, 8)

local ultimateBtn = Instance.new("TextButton")
ultimateBtn.Size = UDim2.new(0.28, 0, 0.35, 0)
ultimateBtn.Position = UDim2.new(0.36, 0, 0.4, 0)
ultimateBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
ultimateBtn.Text = "ULTIMATE"
ultimateBtn.TextColor3 = Color3.new(1,1,1)
ultimateBtn.Font = Enum.Font.GothamBold
ultimateBtn.TextSize = 12
ultimateBtn.Parent = levelCard
Instance.new("UICorner", ultimateBtn).CornerRadius = UDim.new(0, 8)

local godmodeBtn = Instance.new("TextButton")
godmodeBtn.Size = UDim2.new(0.28, 0, 0.35, 0)
godmodeBtn.Position = UDim2.new(0.67, 0, 0.4, 0)
godmodeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 200)
godmodeBtn.Text = "GOD MODE"
godmodeBtn.TextColor3 = Color3.new(1,1,1)
godmodeBtn.Font = Enum.Font.GothamBold
godmodeBtn.TextSize = 12
godmodeBtn.Parent = levelCard
Instance.new("UICorner", godmodeBtn).CornerRadius = UDim.new(0, 8)

-- Level Description
local levelDesc = Instance.new("TextLabel")
levelDesc.Size = UDim2.new(0.9, 0, 0, 25)
levelDesc.Position = UDim2.new(0.05, 0, 0.78, 0)
levelDesc.BackgroundTransparency = 1
levelDesc.Text = "Standard: Basic teleport, safe for most games"
levelDesc.TextColor3 = Color3.fromRGB(150, 150, 180)
levelDesc.Font = Enum.Font.Gotham
levelDesc.TextSize = 10
levelDesc.TextXAlignment = Enum.TextXAlignment.Center
levelDesc.Parent = levelCard

-- Target Card
local targetCard = Instance.new("Frame")
targetCard.Size = UDim2.new(0.9, 0, 0, 65)
targetCard.Position = UDim2.new(0.05, 0, 0.44, 0)
targetCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
targetCard.BorderSizePixel = 0
targetCard.Parent = mainFrame
Instance.new("UICorner", targetCard).CornerRadius = UDim.new(0, 12)

local targetTitle = Instance.new("TextLabel")
targetTitle.Size = UDim2.new(0.5, 0, 0, 20)
targetTitle.Position = UDim2.new(0.05, 0, 0, 8)
targetTitle.BackgroundTransparency = 1
targetTitle.Text = "🎯 TARGET"
targetTitle.TextColor3 = Color3.fromRGB(150, 150, 180)
targetTitle.Font = Enum.Font.Gotham
targetTitle.TextSize = 11
targetTitle.TextXAlignment = Enum.TextXAlignment.Left
targetTitle.Parent = targetCard

local targetValue = Instance.new("TextLabel")
targetValue.Size = UDim2.new(0.55, 0, 0, 25)
targetValue.Position = UDim2.new(0.05, 0, 0, 30)
targetValue.BackgroundTransparency = 1
targetValue.Text = "Auto Mode: Nearest"
targetValue.TextColor3 = Color3.fromRGB(255, 255, 255)
targetValue.Font = Enum.Font.GothamBold
targetValue.TextSize = 13
targetValue.TextXAlignment = Enum.TextXAlignment.Left
targetValue.Parent = targetCard

local selectBtn = Instance.new("TextButton")
selectBtn.Size = UDim2.new(0.28, 0, 0.55, 0)
selectBtn.Position = UDim2.new(0.67, 0, 0.25, 0)
selectBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
selectBtn.Text = "SELECT"
selectBtn.TextColor3 = Color3.new(1,1,1)
selectBtn.Font = Enum.Font.GothamSemibold
selectBtn.TextSize = 13
selectBtn.Parent = targetCard
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 8)

-- Offset Card
local offsetCard = Instance.new("Frame")
offsetCard.Size = UDim2.new(0.9, 0, 0, 65)
offsetCard.Position = UDim2.new(0.05, 0, 0.57, 0)
offsetCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
offsetCard.BorderSizePixel = 0
offsetCard.Parent = mainFrame
Instance.new("UICorner", offsetCard).CornerRadius = UDim.new(0, 12)

local offsetTitle = Instance.new("TextLabel")
offsetTitle.Size = UDim2.new(0.5, 0, 0, 20)
offsetTitle.Position = UDim2.new(0.05, 0, 0, 8)
offsetTitle.BackgroundTransparency = 1
offsetTitle.Text = "📍 OFFSET MODE"
offsetTitle.TextColor3 = Color3.fromRGB(150, 150, 180)
offsetTitle.Font = Enum.Font.Gotham
offsetTitle.TextSize = 11
offsetTitle.TextXAlignment = Enum.TextXAlignment.Left
offsetTitle.Parent = offsetCard

local offsetValue = Instance.new("TextLabel")
offsetValue.Size = UDim2.new(0.55, 0, 0, 25)
offsetValue.Position = UDim2.new(0.05, 0, 0, 30)
offsetValue.BackgroundTransparency = 1
offsetValue.Text = "Behind (0.5 studs)"
offsetValue.TextColor3 = Color3.fromRGB(255, 255, 255)
offsetValue.Font = Enum.Font.GothamBold
offsetValue.TextSize = 13
offsetValue.TextXAlignment = Enum.TextXAlignment.Left
offsetValue.Parent = offsetCard

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.28, 0, 0.55, 0)
modeBtn.Position = UDim2.new(0.67, 0, 0.25, 0)
modeBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
modeBtn.Text = "SWITCH"
modeBtn.TextColor3 = Color3.new(1,1,1)
modeBtn.Font = Enum.Font.GothamSemibold
modeBtn.TextSize = 13
modeBtn.Parent = offsetCard
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 8)

-- Stats Card
local statsCard = Instance.new("Frame")
statsCard.Size = UDim2.new(0.9, 0, 0, 70)
statsCard.Position = UDim2.new(0.05, 0, 0.7, 0)
statsCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statsCard.BorderSizePixel = 0
statsCard.Parent = mainFrame
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 12)

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(0.5, 0, 0, 20)
statsTitle.Position = UDim2.new(0.05, 0, 0, 8)
statsTitle.BackgroundTransparency = 1
statsTitle.Text = "📊 STATISTICS"
statsTitle.TextColor3 = Color3.fromRGB(150, 150, 180)
statsTitle.Font = Enum.Font.Gotham
statsTitle.TextSize = 11
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = statsCard

local targetDistanceLabel = Instance.new("TextLabel")
targetDistanceLabel.Size = UDim2.new(0.45, 0, 0, 25)
targetDistanceLabel.Position = UDim2.new(0.05, 0, 0, 30)
targetDistanceLabel.BackgroundTransparency = 1
targetDistanceLabel.Text = "Distance: N/A"
targetDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
targetDistanceLabel.Font = Enum.Font.Gotham
targetDistanceLabel.TextSize = 11
targetDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
targetDistanceLabel.Parent = statsCard

local teleportCountLabel = Instance.new("TextLabel")
teleportCountLabel.Size = UDim2.new(0.45, 0, 0, 25)
teleportCountLabel.Position = UDim2.new(0.05, 0, 0, 45)
teleportCountLabel.BackgroundTransparency = 1
teleportCountLabel.Text = "Teleports: 0"
teleportCountLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
teleportCountLabel.Font = Enum.Font.Gotham
teleportCountLabel.TextSize = 11
teleportCountLabel.TextXAlignment = Enum.TextXAlignment.Left
teleportCountLabel.Parent = statsCard

-- Main Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 55)
toggleBtn.Position = UDim2.new(0.05, 0, 0.86, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)
toggleBtn.Text = "▶ START BYPASS"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 17
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

-- =============================================
-- ULTIMATE PHYSICS BREAKER FUNCTIONS
-- =============================================

local function breakPhysicsConstraints(character)
    local constraints = {"Weld", "Glue", "Snap", "RigidConstraint", "BallSocketConstraint", 
                         "HingeConstraint", "SliderConstraint", "CylindricalConstraint", "RopeConstraint"}
    
    for _, constraintType in ipairs(constraints) do
        for _, constraint in ipairs(character:GetDescendants()) do
            if constraint:IsA(constraintType) then
                constraint:Destroy()
            end
        end
    end
end

local function manipulateMass(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                part.Massless = true
            end)
        end
    end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            root.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
            root.AssemblyMass = 0.001
        end)
    end
end

local function nullifyGravity(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Gravity = 0
        end
    end
end

local function breakNetworkLimits(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            root:SetNetworkOwner(player)
            root:SetAttribute("NetworkPriority", 1000)
        end)
    end
end

local function bypassCollisionGroups(character)
    local groupName = "BypassGroup_" .. math.random(99999)
    pcall(function()
        PhysicsService:CreateCollisionGroup(groupName)
        PhysicsService:CollisionGroupSetCollidable(groupName, "Default", false)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = groupName
            end
        end
    end)
end

local function corruptRegion3(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local region = Region3.new(root.Position - Vector3.new(5,5,5), root.Position + Vector3.new(5,5,5))
    local parts = Workspace:FindPartsInRegion3(region, character)
    
    for _, part in ipairs(parts) do
        pcall(function()
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part:BreakJoints()
        end)
    end
end

local function godModeBreak(character)
    -- EXTREME: Break everything
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Break all joints in character
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part:BreakJoints()
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
        end
    end
    
    -- Disable humanoid completely
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        hum.AutoRotate = false
        hum.PlatformStand = true
        hum.BreakJointsOnDeath = false
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end
    
    -- Remove from collision matrix
    Workspace:FindPartsInRegion3(Region3.new(root.Position - Vector3.new(10,10,10), root.Position + Vector3.new(10,10,10)), character)
end

local function applyUltimateBypass(character)
    if not character then return end
    
    breakPhysicsConstraints(character)
    manipulateMass(character)
    nullifyGravity(character)
    breakNetworkLimits(character)
    bypassCollisionGroups(character)
    corruptRegion3(character)
    
    if currentLevel == BypassLevel.GODMODE then
        godModeBreak(character)
    end
end

local function getNearestTarget()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = char.HumanoidRootPart.Position
    local best, bestDist = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = p.Character.HumanoidRootPart
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = obj.HumanoidRootPart
            end
        end
    end
    
    if bestDist ~= math.huge then
        lastDistance = string.format("%.1f", bestDist) .. " studs"
        targetDistanceLabel.Text = "Distance: " .. lastDistance
    end
    
    return best
end

-- Level selection
standardBtn.MouseButton1Click:Connect(function()
    currentLevel = BypassLevel.STANDARD
    levelLabel.Text = "Level: STANDARD BYPASS"
    levelDesc.Text = "Standard: Basic teleport, safe for most games"
    statusIcon.TextColor3 = Color3.fromRGB(0, 255, 100)
    TweenService:Create(standardBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 190, 100)}):Play()
    TweenService:Create(ultimateBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 140, 30)}):Play()
    TweenService:Create(godmodeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 40, 200)}):Play()
end)

ultimateBtn.MouseButton1Click:Connect(function()
    currentLevel = BypassLevel.ULTIMATE
    levelLabel.Text = "Level: ULTIMATE BREAKER"
    levelDesc.Text = "Ultimate: Breaks physics, constraints, and networks"
    statusIcon.TextColor3 = Color3.fromRGB(255, 140, 30)
    TweenService:Create(ultimateBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 100, 0)}):Play()
    TweenService:Create(standardBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 190, 100)}):Play()
    TweenService:Create(godmodeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 40, 200)}):Play()
end)

godmodeBtn.MouseButton1Click:Connect(function()
    currentLevel = BypassLevel.GODMODE
    levelLabel.Text = "Level: GOD MODE"
    levelDesc.Text = "GOD MODE: Destroys everything, pure chaos!"
    statusIcon.TextColor3 = Color3.fromRGB(200, 40, 200)
    TweenService:Create(godmodeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 0, 255)}):Play()
    TweenService:Create(standardBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 190, 100)}):Play()
    TweenService:Create(ultimateBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 140, 30)}):Play()
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
    if connection then connection:Disconnect() end
    screenGui:Destroy()
end)

-- Select Player
selectBtn.MouseButton1Click:Connect(function()
    if screenGui:FindFirstChild("DropdownMenu") then
        screenGui:FindFirstChild("DropdownMenu"):Destroy()
    end
    
    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Name = "DropdownMenu"
    dropdown.Size = UDim2.new(0, 250, 0, 300)
    dropdown.Position = UDim2.new(0.5, -125, 0.5, -150)
    dropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 6
    dropdown.Parent = screenGui
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 12)
    
    local titleDrop = Instance.new("TextLabel")
    titleDrop.Size = UDim2.new(1, 0, 0, 40)
    titleDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleDrop.Text = "SELECT TARGET"
    titleDrop.TextColor3 = Color3.new(1,1,1)
    titleDrop.Font = Enum.Font.GothamBold
    titleDrop.TextSize = 14
    titleDrop.Parent = dropdown
    Instance.new("UICorner", titleDrop).CornerRadius = UDim.new(0, 12)
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.Parent = dropdown
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 45)
            btn.Position = UDim2.new(0, 10, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn.Text = plr.Name .. (plr.Character and " ✓" or " ✗")
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 14
            btn.Parent = dropdown
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    manualTarget = plr.Character
                    manualTargetName = plr.Name
                    targetValue.Text = "Manual: " .. plr.Name
                    dropdown:Destroy()
                end
            end)
        end
    end
    
    dropdown.CanvasSize = UDim2.new(0, 0, 0, math.max(250, (#Players:GetPlayers() - 1) * 55 + 60))
end)

-- Toggle Mode
modeBtn.MouseButton1Click:Connect(function()
    if offset == -0.5 then
        offset = 0.3
        offsetValue.Text = "Front (0.3 studs)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
    else
        offset = -0.5
        offsetValue.Text = "Behind (0.5 studs)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    end
end)

-- Main Bypass Loop
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning

    if isRunning then
        toggleBtn.Text = "⏸ STOP BYPASS"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "ACTIVE - " .. (currentLevel == BypassLevel.STANDARD and "STANDARD" or currentLevel == BypassLevel.ULTIMATE and "ULTIMATE" or "GOD MODE")
        
        teleportCount = 0
        teleportCountLabel.Text = "Teleports: 0"

        connection = RunService.PostSimulation:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then 
                return 
            end

            local root = char.HumanoidRootPart
            
            local targetPart = nil
            if manualTarget and manualTarget.Parent and manualTarget:FindFirstChild("HumanoidRootPart") then
                targetPart = manualTarget.HumanoidRootPart
            else
                if manualTarget then
                    manualTarget = nil
                    manualTargetName = nil
                    targetValue.Text = "Auto Mode: Nearest"
                end
                targetPart = getNearestTarget()
            end
            
            if not targetPart or not targetPart.Parent then 
                statusLabel.Text = "No target found"
                return 
            end

            teleportCount = teleportCount + 1
            teleportCountLabel.Text = "Teleports: " .. teleportCount
            
            -- Apply bypass based on level
            if currentLevel == BypassLevel.ULTIMATE or currentLevel == BypassLevel.GODMODE then
                applyUltimateBypass(char)
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = true
                hum.AutoRotate = false
                if currentLevel == BypassLevel.GODMODE then
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                end
            end

            -- Disable collisions
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.CanCollide = false
                    if currentLevel == BypassLevel.GODMODE then
                        v.CanQuery = false
                        v.CanTouch = false
                    end
                end
            end

            -- Physics zeroing
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            
            -- Teleport
            local goal = targetPart.CFrame * CFrame.new(0, 0, offset)
            root.CFrame = goal
            
            -- Extra teleport for higher levels
            if currentLevel ~= BypassLevel.STANDARD then
                task.wait()
                root.CFrame = goal
            end
            
            task.spawn(function()
                wait(0.05)
                if root and root.Parent then
                    root.Anchored = false
                end
            end)
        end)

    else
        if connection then 
            connection:Disconnect() 
            connection = nil 
        end
        toggleBtn.Text = "▶ START BYPASS"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)
        statusLabel.Text = "READY"
        
        -- Reset character
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.PlatformStand = false
                hum.AutoRotate = true 
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.CanCollide = true
                    v.CanQuery = true
                    v.CanTouch = true
                end
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then 
                root.Anchored = false
            end
        end
    end
end)

-- Animate UI on load
mainFrame.BackgroundTransparency = 1
TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.08}):Play()

print("✅ Ultimate Physics Breaker v4.0 Loaded!")
print("Three bypass levels available: STANDARD | ULTIMATE | GOD MODE")