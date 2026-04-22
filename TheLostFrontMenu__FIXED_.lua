-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Variables
local ESPEnabled = false
local BoxESPEnabled = true
local NameESPEnabled = true
local HealthESPEnabled = true
local DistanceESPEnabled = true
local SkeletonESPEnabled = false
local TeamCheck = true

-- ========== FPV DRONE ESP VARIABLES (OPTIMIZED - NO LAG) ==========
local FPVESPEnabled = false
local FPVBoxESPEnabled = true
local FPVDistanceESPEnabled = true
-- Name ESP removed for performance

local SilentAimEnabled = false
local ShowFOV = false
local WallCheck = true
local FOVRadius = 100
local AimPart = "Head"
local AimOrigin = "Center Screen"

-- ========== SILENT AIM IMPROVEMENTS ==========
local SilentAimStrength = 1.0  -- Full redirection
local SilentAimHitChance = 100  -- Percentage chance to hit (100 = always)
local SilentAimPrediction = false  -- Predict target movement

local DisableFogEnabled = false
local DesyncEnabled = false
local TriggerbotEnabled = false

-- ========== AIMBOT VARIABLES ==========
local AimbotEnabled = false
local AimbotSmoothing = 0.3
local AimbotKey = Enum.KeyCode.LeftAlt
local AimbotMode = "Hold"
local AimbotActive = false

local ESPData = {}
local FPVData = {}  -- Store FPV drone ESP elements (optimized)
local CurrentTarget = nil
local LastTargetPosition = nil
local TargetVelocity = Vector3.new(0, 0, 0)

-- Save Original Lighting
local OriginalLighting = {
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    AtmosphereDensity = Lighting:FindFirstChildOfClass("Atmosphere") and Lighting:FindFirstChildOfClass("Atmosphere").Density or 0
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Radius = FOVRadius
FOVCircle.Filled = false

-- ========== FPV DRONE DETECTION (OPTIMIZED) ==========
local FPVDrones = {}  -- Cache of detected drones
local FPVPartNames = {
    "Explosive", "Explosive1", "Explosive2",
    "FPV", "DroneBody", "MainPart", "Body"
}

-- Optimized scan - only runs every 1 second, only checks specific parts
local function ScanForFPVDrones()
    if not FPVESPEnabled then return {} end
    
    local drones = {}
    local checkedModels = {}
    
    -- Only check specific part types, not all descendants
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name and FPVPartNames[part.Name] then
            local model = part.Parent
            if model and model:IsA("Model") and not checkedModels[model] then
                checkedModels[model] = true
                
                -- Skip player characters
                local isCharacter = false
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character == model then
                        isCharacter = true
                        break
                    end
                end
                
                if not isCharacter then
                    -- Find the main body part (Explosive or FPV)
                    local trackPart = part
                    for _, altName in ipairs({"Explosive", "FPV", "MainPart", "Body"}) do
                        local found = model:FindFirstChild(altName)
                        if found then
                            trackPart = found
                            break
                        end
                    end
                    drones[model] = trackPart
                end
            end
        end
    end
    
    return drones
end

-- Convert to lookup table for performance
local FPVPartLookup = {}
for _, name in ipairs(FPVPartNames) do
    FPVPartLookup[name] = true
end

-- ========== FPV DRONE ESP SYSTEM (OPTIMIZED - NO NAME, ONLY HITBOX + DISTANCE) ==========
local function CreateFPVESP(drone)
    if FPVData[drone] then return end
    
    local esp = {}
    
    -- Only Box (hitbox) and Distance - NO NAME for performance
    esp.Box = Drawing.new("Square")
    esp.Box.Color = Color3.fromRGB(255, 50, 255)  -- Bright magenta
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    
    esp.Distance = Drawing.new("Text")
    esp.Distance.Color = Color3.fromRGB(255, 100, 255)
    esp.Distance.Outline = true
    esp.Distance.Center = true
    esp.Distance.Size = 12
    
    FPVData[drone] = esp
end

local function DestroyFPVESP(drone)
    if FPVData[drone] then
        pcall(function()
            FPVData[drone].Box:Remove()
            FPVData[drone].Distance:Remove()
        end)
        FPVData[drone] = nil
    end
end

local function HideFPVESP(esp)
    if esp then
        esp.Box.Visible = false
        esp.Distance.Visible = false
    end
end

-- Clean up destroyed drones
local function CleanupFPVESP()
    for drone, esp in pairs(FPVData) do
        if not drone or not drone.Parent then
            DestroyFPVESP(drone)
        end
    end
end

-- Optimized FPV drone rendering (no name label)
local function RenderFPVDrones()
    if not ESPEnabled or not FPVESPEnabled then
        for _, esp in pairs(FPVData) do
            HideFPVESP(esp)
        end
        return
    end
    
    CleanupFPVESP()
    
    local myPosition = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPosition = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    for drone, trackPart in pairs(FPVDrones) do
        if trackPart and trackPart.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(trackPart.Position)
            
            if onScreen and pos.Z > 0 then
                if not FPVData[drone] then
                    CreateFPVESP(drone)
                end
                
                local esp = FPVData[drone]
                
                -- Calculate distance (optimized)
                local distance = "?"
                if myPosition then
                    local dist = math.floor((trackPart.Position - myPosition).Magnitude)
                    distance = tostring(dist) .. "m"
                end
                
                -- Calculate box size based on distance
                local scale = 800 / pos.Z
                local boxSize = math.clamp(scale, 25, 120)
                
                -- Render Box (hitbox) - always visible when enabled
                if FPVBoxESPEnabled then
                    esp.Box.Size = Vector2.new(boxSize, boxSize)
                    esp.Box.Position = Vector2.new(pos.X - boxSize / 2, pos.Y - boxSize / 2)
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end
                
                -- Render Distance only
                if FPVDistanceESPEnabled then
                    esp.Distance.Position = Vector2.new(pos.X, pos.Y + boxSize / 2 + 8)
                    esp.Distance.Text = distance
                    esp.Distance.Visible = true
                else
                    esp.Distance.Visible = false
                end
            else
                if FPVData[drone] then
                    HideFPVESP(FPVData[drone])
                end
            end
        end
    end
end

-- ========== AIMBOT KEYBIND HANDLING ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if AimbotMode == "Toggle" and input.KeyCode == AimbotKey then
        AimbotActive = not AimbotActive
        if AimbotActive then
            Rayfield:Notify({Title = "Aimbot", Content = "Enabled (Toggle Mode)", Duration = 1})
        else
            Rayfield:Notify({Title = "Aimbot", Content = "Disabled (Toggle Mode)", Duration = 1})
        end
    elseif AimbotMode == "Hold" and input.KeyCode == AimbotKey then
        AimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if AimbotMode == "Hold" and input.KeyCode == AimbotKey then
        AimbotActive = false
    end
end)

-- --- THE LOST FRONT SPECIFIC ENGINE CHECKS ---

local function IsSpectator(char)
    if not char or not char.Parent then return true end
    local parentName = char.Parent.Name:lower()
    return parentName:find("spectator") or parentName:find("dead") or parentName:find("observer")
end

local function IsTeammate(player)
    if not TeamCheck then return false end
    if player == LocalPlayer then return true end
    
    local myChar = LocalPlayer.Character
    local theirChar = player.Character
    
    if not myChar or not myChar.Parent then return false end
    if not theirChar or not theirChar.Parent then return false end
    
    if myChar.Parent == theirChar.Parent then return true end
    
    return false
end

local function IsVisible(targetPart)
    if not WallCheck then return true end
    local origin = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local filterList = {Camera}
    if LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    rayParams.FilterDescendantsInstances = filterList
    
    local dir = (targetPart.Position - origin)
    local result = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, rayParams)
    
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- --- IMPROVED AIMING & MATH LOGIC (WITH PREDICTION) ---

local function GetAimOriginPosition()
    if AimOrigin == "Center Screen" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

-- Calculate predicted target position for silent aim
local function GetPredictedPosition(targetPart, bulletSpeed)
    if not SilentAimPrediction then return targetPart.Position end
    
    local currentPos = targetPart.Position
    local velocity = (currentPos - LastTargetPosition) / (1/60)  -- Approximate velocity
    LastTargetPosition = currentPos
    
    -- Simple prediction for moving targets
    local predictionTime = 0.1  -- 100ms prediction
    return currentPos + (velocity * predictionTime)
end

local function UpdateClosestTarget()
    if not SilentAimEnabled and not TriggerbotEnabled and not AimbotEnabled then 
        CurrentTarget = nil
        return 
    end

    local closestPlayer = nil
    local shortestDistance = FOVRadius
    local originPos = GetAimOriginPosition()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local char = player.Character
            
            if not IsSpectator(char) and not IsTeammate(player) then
                local targetPart = char:FindFirstChild(AimPart)
                if targetPart and IsVisible(targetPart) then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - originPos).Magnitude
                        if distance < shortestDistance then
                            closestPlayer = targetPart
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    CurrentTarget = closestPlayer
    if CurrentTarget then
        LastTargetPosition = CurrentTarget.Position
    end
end

-- ========== AIMBOT MOVEMENT FUNCTION ==========
local function DoAimbot()
    if not AimbotEnabled or not AimbotActive then return end
    if not CurrentTarget then return end
    
    local targetPos = CurrentTarget.Position
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    
    if not onScreen then return end
    
    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
    local currentMouse = UserInputService:GetMouseLocation()
    local delta = targetScreen - currentMouse
    
    local smoothedDelta = delta * AimbotSmoothing
    
    pcall(function()
        mousemoverel(smoothedDelta.X, smoothedDelta.Y)
    end)
end

-- --- ESP SYSTEM (PLAYERS) ---

local function CreateESP(player)
    local esp = {}
    esp.Box = Drawing.new("Square")
    esp.Box.Color = Color3.fromRGB(255, 0, 0)
    esp.Box.Thickness = 1
    esp.Box.Filled = false

    esp.Name = Drawing.new("Text")
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Outline = true
    esp.Name.Center = true
    esp.Name.Size = 16

    esp.Distance = Drawing.new("Text")
    esp.Distance.Color = Color3.fromRGB(200, 200, 200)
    esp.Distance.Outline = true
    esp.Distance.Center = true
    esp.Distance.Size = 14

    esp.HealthBarBg = Drawing.new("Square")
    esp.HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthBarBg.Filled = true

    esp.HealthBar = Drawing.new("Square")
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Filled = true

    esp.Skeleton = {}
    local skeletonJoints = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }

    for i, joint in ipairs(skeletonJoints) do
        esp.Skeleton[i] = Drawing.new("Line")
        esp.Skeleton[i].Color = Color3.fromRGB(255, 255, 255)
        esp.Skeleton[i].Thickness = 1
        esp.Skeleton[i].Joints = joint
    end
    ESPData[player] = esp
end

-- --- RENDER ESP FUNCTION (MISSING IN ORIGINAL!) ---
local function RenderESP()
    if not ESPEnabled then
        for _, esp in pairs(ESPData) do
            if esp.Box then esp.Box.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
            if esp.HealthBarBg then esp.HealthBarBg.Visible = false end
            if esp.Skeleton then
                for _, line in pairs(esp.Skeleton) do
                    if line then line.Visible = false end
                end
            end
        end
        return
    end
    
    local myPosition = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPosition = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    for player, esp in pairs(ESPData) do
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local character = player.Character
            local hrp = character.HumanoidRootPart
            local humanoid = character.Humanoid
            
            if humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen and pos.Z > 0 then
                    -- Calculate box size
                    local head = character:FindFirstChild("Head")
                    if head then
                        local headScreenPos, _ = Camera:WorldToViewportPoint(head.Position)
                        local scale = math.abs(headScreenPos.Y - pos.Y)
                        local boxSize = scale * 2.5
                        
                        -- Render Box
                        if BoxESPEnabled then
                            esp.Box.Size = Vector2.new(boxSize, boxSize * 1.2)
                            esp.Box.Position = Vector2.new(pos.X - boxSize / 2, pos.Y - boxSize / 1.2 / 2)
                            esp.Box.Color = IsTeammate(player) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                            esp.Box.Visible = true
                        else
                            esp.Box.Visible = false
                        end
                        
                        -- Render Name
                        if NameESPEnabled then
                            esp.Name.Position = Vector2.new(pos.X, pos.Y - boxSize / 1.2 / 2 - 15)
                            esp.Name.Text = player.Name
                            esp.Name.Visible = true
                        else
                            esp.Name.Visible = false
                        end
                        
                        -- Render Distance
                        if DistanceESPEnabled and myPosition then
                            local distance = math.floor((hrp.Position - myPosition).Magnitude)
                            esp.Distance.Position = Vector2.new(pos.X, pos.Y + boxSize / 1.2 / 2 + 5)
                            esp.Distance.Text = distance .. "m"
                            esp.Distance.Visible = true
                        else
                            esp.Distance.Visible = false
                        end
                        
                        -- Render Health Bar
                        if HealthESPEnabled then
                            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barWidth = 50
                            local barHeight = 4
                            local barX = pos.X - boxSize / 2 - 10
                            local barY = pos.Y
                            
                            esp.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
                            esp.HealthBarBg.Position = Vector2.new(barX, barY)
                            esp.HealthBarBg.Visible = true
                            
                            esp.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
                            esp.HealthBar.Position = Vector2.new(barX, barY)
                            esp.HealthBar.Color = Color3.fromRGB(0 + (255 * (1 - healthPercent)), 255 * healthPercent, 0)
                            esp.HealthBar.Visible = true
                        else
                            esp.HealthBar.Visible = false
                            esp.HealthBarBg.Visible = false
                        end
                        
                        -- Render Skeleton
                        if SkeletonESPEnabled then
                            for _, line in pairs(esp.Skeleton) do
                                if line.Joints then
                                    local part1 = character:FindFirstChild(line.Joints[1])
                                    local part2 = character:FindFirstChild(line.Joints[2])
                                    
                                    if part1 and part2 then
                                        local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                                        local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                                        
                                        if onScreen1 and onScreen2 then
                                            line.From = Vector2.new(pos1.X, pos1.Y)
                                            line.To = Vector2.new(pos2.X, pos2.Y)
                                            line.Visible = true
                                        else
                                            line.Visible = false
                                        end
                                    else
                                        line.Visible = false
                                    end
                                end
                            end
                        else
                            for _, line in pairs(esp.Skeleton) do
                                line.Visible = false
                            end
                        end
                    end
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Distance.Visible = false
                    esp.HealthBar.Visible = false
                    esp.HealthBarBg.Visible = false
                    for _, line in pairs(esp.Skeleton) do
                        line.Visible = false
                    end
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if ESPData[player] then
        for _, drawing in pairs(ESPData[player]) do
            if type(drawing) == "table" then
                for _, line in pairs(drawing) do line:Remove() end
            else drawing:Remove() end
        end
        ESPData[player] = nil
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end
Players.PlayerAdded:Connect(CreateESP)

-- --- INDEPENDENT THREADS ---

-- Triggerbot thread
task.spawn(function()
    while task.wait(0.1) do
        if TriggerbotEnabled and CurrentTarget then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end
end)

-- Desync thread
task.spawn(function()
    while task.wait(0.05) do
        if DesyncEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local root = LocalPlayer.Character.HumanoidRootPart
                local cf = root.CFrame
                root.CFrame = cf * CFrame.new(math.random(-2,2)*0.1, 0, math.random(-2,2)*0.1)
                task.wait(0.01)
                root.CFrame = cf
            end)
        end
    end
end)

-- FPV Drone scan thread (runs every 1 second - REDUCED LAG)
task.spawn(function()
    while task.wait(1.0) do
        if ESPEnabled and FPVESPEnabled then
            FPVDrones = ScanForFPVDrones()
        elseif not FPVESPEnabled then
            FPVDrones = {}
        end
    end
end)

-- --- IMPROVED SILENT AIM ENGINE HOOK ---

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if SilentAimEnabled and CurrentTarget then
        -- Random hit chance
        local hitRoll = math.random(1, 100)
        if hitRoll <= SilentAimHitChance then
            local targetPos = CurrentTarget.Position
            
            -- Apply prediction if enabled
            if SilentAimPrediction then
                targetPos = GetPredictedPosition(CurrentTarget, nil)
            end
            
            if method == "Raycast" then
                local origin = args[1]
                local originalMagnitude = args[2].Magnitude
                local direction = (targetPos - origin).unit * originalMagnitude
                -- Apply strength modifier (0.8-1.0 for slight spread)
                local strengthMod = 0.8 + (SilentAimStrength * 0.2)
                direction = direction * strengthMod
                args[2] = direction
                return oldNamecall(self, unpack(args))
                
            elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
                local ray = args[1]
                local originalMagnitude = ray.Direction.Magnitude
                local direction = (targetPos - ray.Origin).unit * originalMagnitude
                args[1] = Ray.new(ray.Origin, direction)
                return oldNamecall(self, unpack(args))
                
            elseif method == "FireServer" and tostring(self) == "characterLookvector" then
                local direction = (targetPos - Camera.CFrame.Position).unit
                args[1] = direction
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- --- RAYFIELD UI MENU ---

local Window = Rayfield:CreateWindow({
    Name = "The Lost Front Exploit 1.7",
    LoadingTitle = "Loading Exploit...",
    LoadingSubtitle = "Mobile & PC Supported • Made with ♥ by ZAXV3",
    ConfigurationSaving = {Enabled = true, FolderName = "Th3L0stFr0nt3xpl0!t", FileName = "Config"},
})

local CombatTab = Window:CreateTab("Combat", nil)
local ESPTab = Window:CreateTab("Visuals", nil)
local MiscTab = Window:CreateTab("Misc", nil)
local CreditsTab = Window:CreateTab("Credits", nil)

-- ========== COMBAT TAB ==========
CombatTab:CreateToggle({
    Name = "Enable Silent Aim",
    CurrentValue = false,
    Callback = function(v) SilentAimEnabled = v end
})

CombatTab:CreateSlider({
    Name = "Silent Aim Hit Chance (%)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Callback = function(v) SilentAimHitChance = v end
})

CombatTab:CreateToggle({
    Name = "Silent Aim Prediction (Lead Target)",
    CurrentValue = false,
    Callback = function(v) SilentAimPrediction = v end
})

CombatTab:CreateSlider({
    Name = "Silent Aim Strength",
    Range = {0.5, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 1.0,
    Callback = function(v) SilentAimStrength = v end
})

CombatTab:CreateToggle({
    Name = "Enable Aimbot (Mouse Movement)",
    CurrentValue = false,
    Callback = function(v) AimbotEnabled = v end
})

CombatTab:CreateToggle({
    Name = "Enable Triggerbot (Auto Shoot)",
    CurrentValue = false,
    Callback = function(v) TriggerbotEnabled = v end
})

CombatTab:CreateToggle({
    Name = "Wall Check (Visible Only)",
    CurrentValue = true,
    Callback = function(v) WallCheck = v end
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Callback = function(v) ShowFOV = v end
})

CombatTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 100,
    Callback = function(v) FOVRadius = v end
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothing",
    Range = {0.05, 0.95},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.3,
    Callback = function(v) AimbotSmoothing = v end
})

CombatTab:CreateDropdown({
    Name = "Aim Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Callback = function(v) AimPart = v[1] end
})

CombatTab:CreateDropdown({
    Name = "Aim Origin (Center is best for Mobile)",
    Options = {"Center Screen", "Mouse"},
    CurrentOption = {"Center Screen"},
    Callback = function(v) AimOrigin = v[1] end
})

CombatTab:CreateDropdown({
    Name = "Aimbot Activation Mode",
    Options = {"Hold", "Toggle"},
    CurrentOption = {"Hold"},
    Callback = function(v) AimbotMode = v[1] end
})

CombatTab:CreateKeybind({
    Name = "Aimbot Keybind",
    CurrentKeybind = "LeftAlt",
    Callback = function(key) AimbotKey = key end
})

-- ========== ESP TAB ==========
ESPTab:CreateToggle({
    Name = "Master ESP Enable",
    CurrentValue = false,
    Callback = function(v) ESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Hide Teammates / Spectators",
    CurrentValue = true,
    Callback = function(v) TeamCheck = v end
})

-- ========== FPV DRONE ESP SECTION (OPTIMIZED) ==========
ESPTab:CreateSection("FPV Drone ESP")

ESPTab:CreateToggle({
    Name = "Enable FPV Drone ESP",
    CurrentValue = false,
    Callback = function(v) 
        FPVESPEnabled = v
        if not v then
            for drone, esp in pairs(FPVData) do
                DestroyFPVESP(drone)
            end
            FPVDrones = {}
        end
    end
})

ESPTab:CreateToggle({
    Name = "FPV Drone Hitbox (Box)",
    CurrentValue = true,
    Callback = function(v) FPVBoxESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "FPV Drone Distance",
    CurrentValue = true,
    Callback = function(v) FPVDistanceESPEnabled = v end
})

ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = true,
    Callback = function(v) BoxESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = true,
    Callback = function(v) NameESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Health Bar ESP",
    CurrentValue = true,
    Callback = function(v) HealthESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = true,
    Callback = function(v) DistanceESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = false,
    Callback = function(v) SkeletonESPEnabled = v end
})

-- ========== MISC TAB ==========
MiscTab:CreateToggle({
    Name = "Desync (Anti-Aim / Dodge Bullets)",
    CurrentValue = false,
    Callback = function(v) DesyncEnabled = v end
})

MiscTab:CreateToggle({
    Name = "Disable Fog / Clear Atmosphere",
    CurrentValue = false,
    Callback = function(v)
        DisableFogEnabled = v
        if v then
            Lighting.FogEnd = 10000
            Lighting.FogStart = 9000
            if Lighting:FindFirstChildOfClass("Atmosphere") then
                Lighting:FindFirstChildOfClass("Atmosphere").Density = 0.3
            end
        else
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.FogStart = OriginalLighting.FogStart
            if Lighting:FindFirstChildOfClass("Atmosphere") then
                Lighting:FindFirstChildOfClass("Atmosphere").Density = OriginalLighting.AtmosphereDensity
            end
        end
    end
})

-- ========== CREDITS TAB ==========
CreditsTab:CreateSection("Information")
CreditsTab:CreateLabel("Script Developer: ZAXV3")
CreditsTab:CreateLabel("Hello there! I would like to say that this script is entirely open-source! Feel free to add your own features to this script. All I ask is your support for this open-source script and to also credit me in your modified fork of this script. Thank you for understanding and I hope you have a nice day! ♥")
CreditsTab:CreateLabel("UI Library: Rayfield")

-- ========== MAIN RENDER LOOP (THE MISSING PIECE!) ==========
RunService.RenderStepped:Connect(function()
    -- Update closest target
    UpdateClosestTarget()
    
    -- Do aimbot
    DoAimbot()
    
    -- Render player ESP
    RenderESP()
    
    -- Render FPV drone ESP
    RenderFPVDrones()
    
    -- Update FOV circle
    if ShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Radius = FOVRadius
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
    else
        FOVCircle.Visible = false
    end
    
    -- Update fog/atmosphere if enabled
    if DisableFogEnabled then
        Lighting.FogEnd = 10000
        Lighting.FogStart = 9000
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0.3
        end
    end
end)

-- Final notification
Rayfield:Notify({
    Title = "Loaded Successfully",
    Content = "V1.7 - Optimized FPV ESP + Improved Silent Aim! [FIXED]",
    Duration = 4
})
