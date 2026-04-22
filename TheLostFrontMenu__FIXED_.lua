-- ============================================================
--  THE LOST FRONT EXPLOIT  v1.8  (Mobile + PC Revamp)
--  Original by ZAXV3  |  Revamped for full cross-platform support
-- ============================================================

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
--  SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera            = Workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
--  PLATFORM DETECTION
-- ============================================================
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
--  ESP / VISUAL FLAGS
-- ============================================================
local ESPEnabled          = false
local BoxESPEnabled       = true
local NameESPEnabled      = true
local HealthESPEnabled    = true
local DistanceESPEnabled  = true
local SkeletonESPEnabled  = false
local TeamCheck           = true

-- ============================================================
--  FPV DRONE ESP FLAGS
-- ============================================================
local FPVESPEnabled         = false
local FPVBoxESPEnabled      = true
local FPVDistanceESPEnabled = true

-- ============================================================
--  COMBAT FLAGS
-- ============================================================
local SilentAimEnabled    = false
local ShowFOV             = false
local WallCheck           = true
local FOVRadius           = 100
local AimPart             = "Head"
local AimOrigin           = "Center Screen"

local SilentAimStrength   = 1.0   -- 0.0 – 1.0
local SilentAimHitChance  = 100   -- percent
local SilentAimPrediction = false

local DisableFogEnabled   = false
local DesyncEnabled       = false
local TriggerbotEnabled   = false

-- ============================================================
--  AIMBOT
-- ============================================================
local AimbotEnabled   = false
local AimbotSmoothing = 0.3
local AimbotKey       = Enum.KeyCode.LeftAlt
local AimbotMode      = "Hold"   -- "Hold" | "Toggle"
local AimbotActive    = false

-- Mobile aimbot: fire a virtual tap at the target instead of mousemoverel
local MobileAimbotEnabled = false  -- toggled separately on mobile

-- ============================================================
--  SHARED STATE
-- ============================================================
local ESPData            = {}
local FPVData            = {}
local FPVDrones          = {}
local CurrentTarget      = nil
local LastTargetPosition = nil

-- ============================================================
--  SAVE ORIGINAL LIGHTING
-- ============================================================
local OriginalLighting = {
    FogEnd   = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    AtmosphereDensity = (Lighting:FindFirstChildOfClass("Atmosphere") and
                         Lighting:FindFirstChildOfClass("Atmosphere").Density) or 0
}

-- ============================================================
--  FOV CIRCLE  —  always centred on screen (mobile + PC fix)
-- ============================================================
local FOVCircle         = Drawing.new("Circle")
FOVCircle.Visible       = false
FOVCircle.Color         = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness     = 1.5
FOVCircle.Radius        = FOVRadius
FOVCircle.Filled        = false

-- Helper: returns the 2-D screen point that should be treated as the
-- aiming origin for both FOV culling and the circle drawing.
local function GetAimOriginPosition()
    -- On mobile (no physical mouse) we always use the screen centre.
    -- On PC we respect the user's dropdown choice.
    if IsMobile or AimOrigin == "Center Screen" then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

-- ============================================================
--  FPV DRONE DETECTION
-- ============================================================
local FPVPartNames = {
    "Explosive", "Explosive1", "Explosive2",
    "FPV", "DroneBody", "MainPart", "Body"
}
-- Build O(1) lookup table (BUG FIX: original used array indexing which
-- always returned nil for name-based lookups)
local FPVPartLookup = {}
for _, name in ipairs(FPVPartNames) do
    FPVPartLookup[name] = true
end

local function ScanForFPVDrones()
    if not FPVESPEnabled then return {} end

    local drones = {}
    local checkedModels = {}

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and FPVPartLookup[part.Name] then  -- FIXED lookup
            local model = part.Parent
            if model and model:IsA("Model") and not checkedModels[model] then
                checkedModels[model] = true

                local isCharacter = false
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character == model then
                        isCharacter = true
                        break
                    end
                end

                if not isCharacter then
                    -- Prefer known root parts
                    local trackPart = part
                    for _, altName in ipairs({"Explosive", "FPV", "MainPart", "Body"}) do
                        local found = model:FindFirstChild(altName)
                        if found then trackPart = found; break end
                    end
                    drones[model] = trackPart
                end
            end
        end
    end

    return drones
end

-- ============================================================
--  FPV DRONE ESP RENDERING
-- ============================================================
local function CreateFPVESP(drone)
    if FPVData[drone] then return end
    local esp = {}

    esp.Box           = Drawing.new("Square")
    esp.Box.Color     = Color3.fromRGB(255, 50, 255)
    esp.Box.Thickness = 2
    esp.Box.Filled    = false

    esp.Distance         = Drawing.new("Text")
    esp.Distance.Color   = Color3.fromRGB(255, 150, 255)
    esp.Distance.Outline = true
    esp.Distance.Center  = true
    esp.Distance.Size    = 13

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
        esp.Box.Visible      = false
        esp.Distance.Visible = false
    end
end

local function CleanupFPVESP()
    for drone in pairs(FPVData) do
        if not drone or not drone.Parent then
            DestroyFPVESP(drone)
        end
    end
end

local function RenderFPVDrones()
    if not ESPEnabled or not FPVESPEnabled then
        for _, esp in pairs(FPVData) do HideFPVESP(esp) end
        return
    end

    CleanupFPVESP()

    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end

    for drone, trackPart in pairs(FPVDrones) do
        if trackPart and trackPart.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(trackPart.Position)

            if onScreen and pos.Z > 0 then
                if not FPVData[drone] then CreateFPVESP(drone) end
                local esp = FPVData[drone]

                local distText = "?"
                if myPos then
                    distText = tostring(math.floor((trackPart.Position - myPos).Magnitude)) .. "m"
                end

                local scale   = 800 / pos.Z
                local boxSize = math.clamp(scale, 25, 120)

                if FPVBoxESPEnabled then
                    esp.Box.Size     = Vector2.new(boxSize, boxSize)
                    esp.Box.Position = Vector2.new(pos.X - boxSize / 2, pos.Y - boxSize / 2)
                    esp.Box.Visible  = true
                else
                    esp.Box.Visible = false
                end

                if FPVDistanceESPEnabled then
                    esp.Distance.Position = Vector2.new(pos.X, pos.Y + boxSize / 2 + 8)
                    esp.Distance.Text     = distText
                    esp.Distance.Visible  = true
                else
                    esp.Distance.Visible = false
                end
            else
                if FPVData[drone] then HideFPVESP(FPVData[drone]) end
            end
        end
    end
end

-- ============================================================
--  AIMBOT KEYBIND  (PC only — mobile uses MobileAimbotEnabled toggle)
-- ============================================================
if not IsMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if AimbotMode == "Toggle" and input.KeyCode == AimbotKey then
            AimbotActive = not AimbotActive
            Rayfield:Notify({
                Title   = "Aimbot",
                Content = AimbotActive and "Enabled (Toggle)" or "Disabled (Toggle)",
                Duration = 1
            })
        elseif AimbotMode == "Hold" and input.KeyCode == AimbotKey then
            AimbotActive = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if AimbotMode == "Hold" and input.KeyCode == AimbotKey then
            AimbotActive = false
        end
    end)
end

-- ============================================================
--  GAME-SPECIFIC HELPERS
-- ============================================================
local function IsSpectator(char)
    if not char or not char.Parent then return true end
    local pn = char.Parent.Name:lower()
    return pn:find("spectator") or pn:find("dead") or pn:find("observer")
end

local function IsTeammate(player)
    if not TeamCheck then return false end
    if player == LocalPlayer then return true end
    local myChar    = LocalPlayer.Character
    local theirChar = player.Character
    if not myChar or not myChar.Parent then return false end
    if not theirChar or not theirChar.Parent then return false end
    return myChar.Parent == theirChar.Parent
end

local function IsVisible(targetPart)
    if not WallCheck then return true end
    local origin    = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = {Camera}
    if LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    rayParams.FilterDescendantsInstances = filterList
    local dir    = targetPart.Position - origin
    local result = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, rayParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- ============================================================
--  TARGET ACQUISITION
-- ============================================================
-- Prediction helper (BUG FIX: guard nil LastTargetPosition)
local function GetPredictedPosition(targetPart)
    if not SilentAimPrediction or not LastTargetPosition then
        return targetPart.Position
    end
    -- Approximate velocity from last known position (60fps assumption)
    local velocity     = (targetPart.Position - LastTargetPosition) * 60
    local predTime     = math.clamp(0.07, 0, 0.15)
    return targetPart.Position + velocity * predTime
end

local function UpdateClosestTarget()
    if not SilentAimEnabled and not TriggerbotEnabled
       and not AimbotEnabled and not MobileAimbotEnabled then
        CurrentTarget = nil
        return
    end

    local closestPart = nil
    local shortest    = FOVRadius
    local originPos   = GetAimOriginPosition()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
           and player.Character
           and player.Character:FindFirstChild("Humanoid")
           and player.Character.Humanoid.Health > 0 then

            local char = player.Character
            if not IsSpectator(char) and not IsTeammate(player) then
                local targetPart = char:FindFirstChild(AimPart)
                if targetPart and IsVisible(targetPart) then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - originPos).Magnitude
                        if dist < shortest then
                            closest  = player
                            closestPart = targetPart
                            shortest = dist
                        end
                    end
                end
            end
        end
    end

    -- Keep prediction baseline in sync
    if closestPart then
        LastTargetPosition = CurrentTarget and CurrentTarget.Position or closestPart.Position
    else
        LastTargetPosition = nil
    end
    CurrentTarget = closestPart
end

-- ============================================================
--  AIMBOT MOVEMENT
-- ============================================================
local function DoAimbot()
    -- PC aimbot
    if AimbotEnabled and AimbotActive and CurrentTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
        if onScreen then
            local delta        = Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()
            local smoothed     = delta * math.clamp(AimbotSmoothing, 0.01, 1.0)
            pcall(mousemoverel, smoothed.X, smoothed.Y)
        end
    end

    -- Mobile aimbot: snap camera toward target via CFrame (no mousemoverel on mobile)
    if MobileAimbotEnabled and IsMobile and CurrentTarget then
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, CurrentTarget.Position)
        Camera.CFrame  = Camera.CFrame:Lerp(targetCF, math.clamp(AimbotSmoothing * 2, 0.05, 1.0))
    end
end

-- ============================================================
--  PLAYER ESP
-- ============================================================
local function CreateESP(player)
    local esp = {}

    esp.Box           = Drawing.new("Square")
    esp.Box.Color     = Color3.fromRGB(255, 0, 0)
    esp.Box.Thickness = 1
    esp.Box.Filled    = false

    esp.Name          = Drawing.new("Text")
    esp.Name.Color    = Color3.fromRGB(255, 255, 255)
    esp.Name.Outline  = true
    esp.Name.Center   = true
    esp.Name.Size     = 16

    esp.Distance         = Drawing.new("Text")
    esp.Distance.Color   = Color3.fromRGB(200, 200, 200)
    esp.Distance.Outline = true
    esp.Distance.Center  = true
    esp.Distance.Size    = 14

    esp.HealthBarBg        = Drawing.new("Square")
    esp.HealthBarBg.Color  = Color3.fromRGB(0, 0, 0)
    esp.HealthBarBg.Filled = true

    esp.HealthBar        = Drawing.new("Square")
    esp.HealthBar.Color  = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Filled = true

    -- Skeleton lines
    esp.Skeleton = {}
    local skeletonJoints = {
        {"Head","UpperTorso"},
        {"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    for i, joint in ipairs(skeletonJoints) do
        local line       = Drawing.new("Line")
        line.Color       = Color3.fromRGB(255, 255, 255)
        line.Thickness   = 1
        line.Joints      = joint   -- stored for reference
        esp.Skeleton[i]  = line
    end

    ESPData[player] = esp
end

local function HidePlayerESP(esp)
    esp.Box.Visible        = false
    esp.Name.Visible       = false
    esp.Distance.Visible   = false
    esp.HealthBar.Visible  = false
    esp.HealthBarBg.Visible = false
    for _, line in pairs(esp.Skeleton) do line.Visible = false end
end

local function RenderESP()
    if not ESPEnabled then
        for _, esp in pairs(ESPData) do HidePlayerESP(esp) end
        return
    end

    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end

    for player, esp in pairs(ESPData) do
        if player and player.Character
           and player.Character:FindFirstChild("HumanoidRootPart")
           and player.Character:FindFirstChild("Humanoid")
           and player.Character.Humanoid.Health > 0 then

            local char      = player.Character
            local hrp       = char.HumanoidRootPart
            local humanoid  = char.Humanoid
            local head      = char:FindFirstChild("Head")

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen and pos.Z > 0 and head then
                local headSP, _ = Camera:WorldToViewportPoint(head.Position)
                local scale     = math.abs(headSP.Y - pos.Y)
                local boxW      = scale * 1.4
                local boxH      = scale * 2.6
                local boxLeft   = pos.X - boxW / 2
                local boxTop    = pos.Y - boxH * 0.55

                -- Box
                if BoxESPEnabled then
                    esp.Box.Size     = Vector2.new(boxW, boxH)
                    esp.Box.Position = Vector2.new(boxLeft, boxTop)
                    esp.Box.Color    = IsTeammate(player)
                        and Color3.fromRGB(0, 255, 0)
                        or  Color3.fromRGB(255, 0, 0)
                    esp.Box.Visible  = true
                else
                    esp.Box.Visible = false
                end

                -- Name
                if NameESPEnabled then
                    esp.Name.Position = Vector2.new(pos.X, boxTop - 15)
                    esp.Name.Text     = player.Name
                    esp.Name.Visible  = true
                else
                    esp.Name.Visible = false
                end

                -- Distance
                if DistanceESPEnabled and myPos then
                    local d = math.floor((hrp.Position - myPos).Magnitude)
                    esp.Distance.Position = Vector2.new(pos.X, boxTop + boxH + 4)
                    esp.Distance.Text     = d .. "m"
                    esp.Distance.Visible  = true
                else
                    esp.Distance.Visible = false
                end

                -- Health bar (left side of box, scales with box — BUG FIX)
                if HealthESPEnabled then
                    local hp        = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barW      = 4
                    local barPadding = 3
                    local barX      = boxLeft - barW - barPadding
                    local barFullH  = boxH

                    esp.HealthBarBg.Size     = Vector2.new(barW, barFullH)
                    esp.HealthBarBg.Position = Vector2.new(barX, boxTop)
                    esp.HealthBarBg.Visible  = true

                    -- Fill from bottom so it depletes downward
                    local fillH  = barFullH * hp
                    esp.HealthBar.Size     = Vector2.new(barW, fillH)
                    esp.HealthBar.Position = Vector2.new(barX, boxTop + barFullH - fillH)
                    -- Green → Yellow → Red gradient
                    esp.HealthBar.Color    = Color3.fromRGB(
                        math.floor(255 * (1 - hp)),
                        math.floor(255 * hp),
                        0
                    )
                    esp.HealthBar.Visible  = true
                else
                    esp.HealthBar.Visible   = false
                    esp.HealthBarBg.Visible = false
                end

                -- Skeleton
                if SkeletonESPEnabled then
                    for _, line in pairs(esp.Skeleton) do
                        if line.Joints then
                            local p1 = char:FindFirstChild(line.Joints[1])
                            local p2 = char:FindFirstChild(line.Joints[2])
                            if p1 and p2 then
                                local sp1, os1 = Camera:WorldToViewportPoint(p1.Position)
                                local sp2, os2 = Camera:WorldToViewportPoint(p2.Position)
                                if os1 and os2 then
                                    line.From    = Vector2.new(sp1.X, sp1.Y)
                                    line.To      = Vector2.new(sp2.X, sp2.Y)
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
                    for _, line in pairs(esp.Skeleton) do line.Visible = false end
                end
            else
                HidePlayerESP(esp)
            end
        else
            if esp then HidePlayerESP(esp) end
        end
    end
end

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
    if ESPData[player] then
        for _, drawing in pairs(ESPData[player]) do
            if type(drawing) == "table" then
                for _, line in pairs(drawing) do pcall(function() line:Remove() end) end
            else
                pcall(function() drawing:Remove() end)
            end
        end
        ESPData[player] = nil
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end
Players.PlayerAdded:Connect(CreateESP)

-- ============================================================
--  BACKGROUND THREADS
-- ============================================================

-- Triggerbot  (cross-platform: VirtualInputManager works on both)
task.spawn(function()
    while task.wait(0.1) do
        if TriggerbotEnabled and CurrentTarget then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end
end)

-- Desync  (safe: only manipulate if we own the part)
task.spawn(function()
    while task.wait(0.05) do
        if DesyncEnabled and LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    local original = root.CFrame
                    local jitter   = CFrame.new(
                        math.random(-1, 1) * 0.15,
                        0,
                        math.random(-1, 1) * 0.15
                    )
                    root.CFrame = original * jitter
                    task.wait(0.02)
                    root.CFrame = original
                end)
            end
        end
    end
end)

-- FPV drone scan (every 1 s to stay light)
task.spawn(function()
    while task.wait(1.0) do
        if ESPEnabled and FPVESPEnabled then
            FPVDrones = ScanForFPVDrones()
        elseif not FPVESPEnabled then
            FPVDrones = {}
        end
    end
end)

-- ============================================================
--  SILENT AIM ENGINE HOOK
-- ============================================================
local mt           = getrawmetatable(game)
local oldNamecall  = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if SilentAimEnabled and CurrentTarget then
        if math.random(1, 100) <= SilentAimHitChance then
            local targetPos = GetPredictedPosition(CurrentTarget)

            if method == "Raycast" then
                local origin    = args[1]
                local origMag   = args[2].Magnitude
                local direction = (targetPos - origin).Unit * origMag * (0.8 + SilentAimStrength * 0.2)
                args[2] = direction
                return oldNamecall(self, table.unpack(args))

            elseif method == "FindPartOnRayWithIgnoreList"
                or method == "FindPartOnRayWithWhitelist"
                or method == "FindPartOnRay" then
                local ray       = args[1]
                local origMag   = ray.Direction.Magnitude
                local direction = (targetPos - ray.Origin).Unit * origMag
                args[1] = Ray.new(ray.Origin, direction)
                return oldNamecall(self, table.unpack(args))

            elseif method == "FireServer"
                and tostring(self) == "characterLookvector" then
                args[1] = (targetPos - Camera.CFrame.Position).Unit
                return oldNamecall(self, table.unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- ============================================================
--  RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name             = "The Lost Front Exploit 1.8",
    LoadingTitle     = "Loading Exploit...",
    LoadingSubtitle  = "Mobile & PC Ready  •  Made with ♥ by ZAXV3",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "Th3L0stFr0nt3xpl0!t",
        FileName   = "Config"
    },
})

local CombatTab  = Window:CreateTab("Combat",  nil)
local ESPTab     = Window:CreateTab("Visuals", nil)
local MiscTab    = Window:CreateTab("Misc",    nil)
local CreditsTab = Window:CreateTab("Credits", nil)

-- ============================================================
--  COMBAT TAB
-- ============================================================
CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
    Name         = "Enable Silent Aim",
    CurrentValue = false,
    Callback     = function(v) SilentAimEnabled = v end
})

CombatTab:CreateSlider({
    Name         = "Hit Chance (%)",
    Range        = {0, 100},
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = 100,
    Callback     = function(v) SilentAimHitChance = v end
})

CombatTab:CreateToggle({
    Name         = "Lead Target (Prediction)",
    CurrentValue = false,
    Callback     = function(v) SilentAimPrediction = v end
})

CombatTab:CreateSlider({
    Name         = "Aim Strength",
    Range        = {0, 100},
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = 100,
    Callback     = function(v) SilentAimStrength = v / 100 end
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name         = "Enable Aimbot (PC - Mouse Movement)",
    CurrentValue = false,
    Callback     = function(v) AimbotEnabled = v end
})

if IsMobile then
    CombatTab:CreateToggle({
        Name         = "Enable Aimbot (Mobile - Camera Snap)",
        CurrentValue = false,
        Callback     = function(v) MobileAimbotEnabled = v end
    })
end

CombatTab:CreateSlider({
    Name         = "Aimbot Smoothing",
    Range        = {1, 20},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 6,  -- maps to 0.3 internally
    Callback     = function(v) AimbotSmoothing = v / 20 end
})

if not IsMobile then
    CombatTab:CreateDropdown({
        Name          = "Aimbot Mode",
        Options       = {"Hold", "Toggle"},
        CurrentOption = {"Hold"},
        Callback      = function(v) AimbotMode = v[1] end
    })

    CombatTab:CreateKeybind({
        Name           = "Aimbot Keybind",
        CurrentKeybind = "LeftAlt",
        Callback       = function(key) AimbotKey = key end
    })
end

CombatTab:CreateSection("FOV & Targeting")

CombatTab:CreateToggle({
    Name         = "Show FOV Circle",
    CurrentValue = false,
    Callback     = function(v) ShowFOV = v end
})

CombatTab:CreateSlider({
    Name         = "FOV Radius",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = "px",
    CurrentValue = 100,
    Callback     = function(v)
        FOVRadius       = v
        FOVCircle.Radius = v
    end
})

CombatTab:CreateToggle({
    Name         = "Wall Check (Visible Targets Only)",
    CurrentValue = true,
    Callback     = function(v) WallCheck = v end
})

CombatTab:CreateDropdown({
    Name          = "Aim Target Part",
    Options       = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Callback      = function(v) AimPart = v[1] end
})

CombatTab:CreateDropdown({
    Name          = "Aim Origin",
    Options       = {"Center Screen", "Mouse"},
    CurrentOption = {"Center Screen"},
    Callback      = function(v)
        -- Mobile always uses Center Screen regardless
        if not IsMobile then AimOrigin = v[1] end
    end
})

CombatTab:CreateSection("Triggerbot")

CombatTab:CreateToggle({
    Name         = "Enable Triggerbot",
    CurrentValue = false,
    Callback     = function(v) TriggerbotEnabled = v end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================
ESPTab:CreateToggle({
    Name         = "Master ESP Enable",
    CurrentValue = false,
    Callback     = function(v) ESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "Hide Teammates / Spectators",
    CurrentValue = true,
    Callback     = function(v) TeamCheck = v end
})

ESPTab:CreateSection("FPV Drone ESP")

ESPTab:CreateToggle({
    Name         = "Enable FPV Drone ESP",
    CurrentValue = false,
    Callback     = function(v)
        FPVESPEnabled = v
        if not v then
            for drone in pairs(FPVData) do DestroyFPVESP(drone) end
            FPVDrones = {}
        end
    end
})

ESPTab:CreateToggle({
    Name         = "FPV Drone Hitbox",
    CurrentValue = true,
    Callback     = function(v) FPVBoxESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "FPV Drone Distance",
    CurrentValue = true,
    Callback     = function(v) FPVDistanceESPEnabled = v end
})

ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name         = "Box ESP",
    CurrentValue = true,
    Callback     = function(v) BoxESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "Name ESP",
    CurrentValue = true,
    Callback     = function(v) NameESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "Health Bar ESP",
    CurrentValue = true,
    Callback     = function(v) HealthESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "Distance ESP",
    CurrentValue = true,
    Callback     = function(v) DistanceESPEnabled = v end
})

ESPTab:CreateToggle({
    Name         = "Skeleton ESP",
    CurrentValue = false,
    Callback     = function(v) SkeletonESPEnabled = v end
})

-- ============================================================
--  MISC TAB
-- ============================================================
MiscTab:CreateToggle({
    Name         = "Desync (Anti-Aim Jitter)",
    CurrentValue = false,
    Callback     = function(v) DesyncEnabled = v end
})

MiscTab:CreateToggle({
    Name         = "Disable Fog / Clear Atmosphere",
    CurrentValue = false,
    Callback     = function(v)
        DisableFogEnabled = v
        if v then
            Lighting.FogEnd   = 10000
            Lighting.FogStart = 9000
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then atm.Density = 0.05 end
        else
            Lighting.FogEnd   = OriginalLighting.FogEnd
            Lighting.FogStart = OriginalLighting.FogStart
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then atm.Density = OriginalLighting.AtmosphereDensity end
        end
    end
})

-- ============================================================
--  CREDITS TAB
-- ============================================================
CreditsTab:CreateSection("Information")
CreditsTab:CreateLabel("Script Developer: ZAXV3")
CreditsTab:CreateLabel("Revamped for Mobile + PC cross-platform support (v1.8)")
CreditsTab:CreateLabel("This script is open-source. Feel free to add your own features — all I ask is that you credit me in any fork. Thank you and have a nice day! ♥")
CreditsTab:CreateLabel("UI Library: Rayfield by Sirius")

-- ============================================================
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- Target acquisition
    UpdateClosestTarget()

    -- Aimbot (PC mouse or mobile camera snap)
    DoAimbot()

    -- Player ESP
    RenderESP()

    -- FPV Drone ESP
    RenderFPVDrones()

    -- FOV Circle  —  ALWAYS anchored to the aim origin (screen centre on mobile)
    if ShowFOV then
        local origin         = GetAimOriginPosition()
        FOVCircle.Position   = origin   -- BUG FIX: was using raw mouse pos (off-centre on mobile)
        FOVCircle.Radius     = FOVRadius
        FOVCircle.Visible    = true
    else
        FOVCircle.Visible = false
    end

    -- Sustain fog suppression each frame to fight engine resets
    if DisableFogEnabled then
        Lighting.FogEnd   = 10000
        Lighting.FogStart = 9000
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0.05 end
    end
end)

-- ============================================================
--  LOAD NOTIFICATION
-- ============================================================
Rayfield:Notify({
    Title    = "Loaded  ✓",
    Content  = "v1.8 — Mobile + PC revamp ready!",
    Duration = 4
})
