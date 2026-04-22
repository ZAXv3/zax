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

local SilentAimEnabled = false
local ShowFOV = false
local WallCheck = true
local FOVRadius = 100
local AimPart = "Head"
local AimOrigin = "Center Screen"

local DisableFogEnabled = false
local DesyncEnabled = false
local TriggerbotEnabled = false

local ESPData = {}
local CurrentTarget = nil

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

-- --- AIMING & MATH LOGIC ---

local function GetAimOriginPosition()
    if AimOrigin == "Center Screen" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

local function UpdateClosestTarget()
    if not SilentAimEnabled and not TriggerbotEnabled then 
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
end

-- --- ESP SYSTEM ---

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

-- --- MAIN RENDER LOOP ---

RunService.RenderStepped:Connect(function()
    pcall(function()
        UpdateClosestTarget()

        if ShowFOV then
            FOVCircle.Position = GetAimOriginPosition()
            FOVCircle.Radius = FOVRadius
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end

        if DisableFogEnabled then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 1000000
            if Lighting:FindFirstChildOfClass("Atmosphere") then
                Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
            end
        end

        for player, esp in pairs(ESPData) do
            local char = player.Character
            local isAlive = char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if ESPEnabled and isAlive and root and not IsSpectator(char) and not IsTeammate(player) then
                local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos

                if onScreen then
                    local boxHeight = math.abs(headPos.Y - rootPos.Y) * 2
                    local boxWidth = boxHeight * 0.6
                    local distance = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                    if BoxESPEnabled then
                        esp.Box.Size = Vector2.new(boxWidth, boxHeight)
                        esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
                        esp.Box.Visible = true
                    else esp.Box.Visible = false end

                    if NameESPEnabled then
                        esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 20)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else esp.Name.Visible = false end

                    if DistanceESPEnabled then
                        esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 5)
                        esp.Distance.Text = tostring(distance) .. "m"
                        esp.Distance.Visible = true
                    else esp.Distance.Visible = false end

                    if HealthESPEnabled then
                        local healthRatio = char.Humanoid.Health / char.Humanoid.MaxHealth
                        esp.HealthBarBg.Size = Vector2.new(4, boxHeight)
                        esp.HealthBarBg.Position = Vector2.new(rootPos.X - boxWidth / 2 - 6, rootPos.Y - boxHeight / 2)
                        esp.HealthBarBg.Visible = true

                        esp.HealthBar.Size = Vector2.new(2, boxHeight * healthRatio)
                        esp.HealthBar.Position = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y - boxHeight / 2 + (boxHeight - esp.HealthBar.Size.Y))
                        esp.HealthBar.Color = Color3.fromRGB(255 - (healthRatio * 255), healthRatio * 255, 0)
                        esp.HealthBar.Visible = true
                    else
                        esp.HealthBarBg.Visible = false; esp.HealthBar.Visible = false
                    end

                    if SkeletonESPEnabled then
                        for _, line in ipairs(esp.Skeleton) do
                            local part1 = char:FindFirstChild(line.Joints[1])
                            local part2 = char:FindFirstChild(line.Joints[2])
                            if part1 and part2 then
                                local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                                local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                                if vis1 and vis2 then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Visible = true
                                else line.Visible = false end
                            else line.Visible = false end
                        end
                    else
                        for _, line in ipairs(esp.Skeleton) do line.Visible = false end
                    end

                else
                    esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false
                    esp.HealthBarBg.Visible = false; esp.HealthBar.Visible = false
                    for _, line in ipairs(esp.Skeleton) do line.Visible = false end
                end
            else
                esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false
                esp.HealthBarBg.Visible = false; esp.HealthBar.Visible = false
                for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            end
        end
    end)
end)

-- --- ENGINE HOOKS (SILENT AIM / BULLET REDIRECTION) ---

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if SilentAimEnabled and CurrentTarget then
        if method == "Raycast" then
            local origin = args[1]
            local originalMagnitude = args[2].Magnitude
            local direction = (CurrentTarget.Position - origin).unit * originalMagnitude
            args[2] = direction
            return oldNamecall(self, unpack(args))
            
        elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
            local ray = args[1]
            local originalMagnitude = ray.Direction.Magnitude
            local direction = (CurrentTarget.Position - ray.Origin).unit * originalMagnitude
            args[1] = Ray.new(ray.Origin, direction)
            return oldNamecall(self, unpack(args))
            
        elseif method == "FireServer" and tostring(self) == "characterLookvector" then
            args[1] = (CurrentTarget.Position - Camera.CFrame.Position).unit
            return oldNamecall(self, unpack(args))
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

-- Combat
CombatTab:CreateToggle({Name = "Enable Silent Aim", CurrentValue = false, Callback = function(v) SilentAimEnabled = v end})
CombatTab:CreateToggle({Name = "Enable Triggerbot (Auto Shoot)", CurrentValue = false, Callback = function(v) TriggerbotEnabled = v end})
CombatTab:CreateToggle({Name = "Wall Check (Visible Only)", CurrentValue = true, Callback = function(v) WallCheck = v end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) ShowFOV = v end})
CombatTab:CreateSlider({Name = "FOV Radius", Range = {10, 500}, Increment = 1, Suffix = "px", CurrentValue = 100, Callback = function(v) FOVRadius = v end})
CombatTab:CreateDropdown({Name = "Aim Target Part", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, CurrentOption = {"Head"}, Callback = function(v) AimPart = v[1] end})
CombatTab:CreateDropdown({Name = "Aim Origin (Center is best for Mobile)", Options = {"Center Screen", "Mouse"}, CurrentOption = {"Center Screen"}, Callback = function(v) AimOrigin = v[1] end})

-- ESP
ESPTab:CreateToggle({Name = "Master ESP Enable", CurrentValue = false, Callback = function(v) ESPEnabled = v end})
ESPTab:CreateToggle({Name = "Hide Teammates / Spectators", CurrentValue = true, Callback = function(v) TeamCheck = v end})
ESPTab:CreateToggle({Name = "Box ESP", CurrentValue = true, Callback = function(v) BoxESPEnabled = v end})
ESPTab:CreateToggle({Name = "Name ESP", CurrentValue = true, Callback = function(v) NameESPEnabled = v end})
ESPTab:CreateToggle({Name = "Health Bar ESP", CurrentValue = true, Callback = function(v) HealthESPEnabled = v end})
ESPTab:CreateToggle({Name = "Distance ESP", CurrentValue = true, Callback = function(v) DistanceESPEnabled = v end})
ESPTab:CreateToggle({Name = "Skeleton ESP", CurrentValue = false, Callback = function(v) SkeletonESPEnabled = v end})

-- Misc
MiscTab:CreateToggle({Name = "Desync (Anti-Aim / Dodge Bullets)", CurrentValue = false, Callback = function(v) DesyncEnabled = v end})
MiscTab:CreateToggle({
    Name = "Disable Fog / Clear Atmosphere",
    CurrentValue = false,
    Callback = function(v)
        DisableFogEnabled = v
        if not v then
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.FogStart = OriginalLighting.FogStart
            if Lighting:FindFirstChildOfClass("Atmosphere") then
                Lighting:FindFirstChildOfClass("Atmosphere").Density = OriginalLighting.AtmosphereDensity
            end
        end
    end
})

-- Credits
CreditsTab:CreateSection("Information")
CreditsTab:CreateLabel("Script Developer: ZAXV3")
CreditsTab:CreateLabel("Hello there! i would like to say that this script is entirely open-source! feel free to add your own features to this script. All i ask is your support for this open-source script and to also credit me in your modified fork of this script. Thank you for understanding and i hope you have a nice day! ♥")
CreditsTab:CreateLabel("UI Library: Rayfield")

Rayfield:Notify({Title = "Loaded Successfully", Content = "V1.7 Loaded. Enjoy!", Duration = 4})