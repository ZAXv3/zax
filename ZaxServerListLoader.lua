--[[
    ███████╗ █████╗ ██╗  ██╗
    ╚══███╔╝██╔══██╗╚██╗██╔╝
      ███╔╝ ███████║ ╚███╔╝ 
     ███╔╝  ██╔══██║ ██╔██╗ 
    ███████╗██║  ██║██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
    Zax's Server List — Executor Script
    PC & Mobile | Resizable | Minimizable
    this is entirely open-source, feel free
    to add your own versions with this code.
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId     = game.PlaceId

-- ============================================================
--  HELPERS
-- ============================================================
local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function MakeCorner(parent, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad or 8)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col   or Color3.fromRGB(50, 50, 68)
    s.Thickness = thick or 1.2
    s.Parent    = parent
    return s
end

local function Frame(parent, size, pos, color, corner, name)
    local f = Instance.new("Frame")
    f.Size             = size  or UDim2.new(1,0,1,0)
    f.Position         = pos   or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or Color3.fromRGB(22,22,32)
    f.BorderSizePixel  = 0
    if name   then f.Name = name end
    if corner then MakeCorner(f, corner) end
    f.Parent = parent
    return f
end

local function Label(parent, size, pos, text, textSize, font, color, xAlign)
    local l = Instance.new("TextLabel")
    l.Size             = size    or UDim2.new(1,0,1,0)
    l.Position         = pos     or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.Text             = text    or ""
    l.TextSize         = textSize or 14
    l.Font             = font    or Enum.Font.Gotham
    l.TextColor3       = color   or Color3.fromRGB(220,220,240)
    l.TextXAlignment   = xAlign  or Enum.TextXAlignment.Left
    l.RichText         = true
    l.Parent           = parent
    return l
end

local function Btn(parent, size, pos, text, bg, tc, ts, corner, name)
    local b = Instance.new("TextButton")
    b.Size             = size   or UDim2.new(0,100,0,34)
    b.Position         = pos    or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bg     or Color3.fromRGB(90,55,200)
    b.Text             = text   or "Button"
    b.TextColor3       = tc     or Color3.fromRGB(255,255,255)
    b.TextSize         = ts     or 13
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    if name          then b.Name = name end
    if corner ~= false then MakeCorner(b, corner or 8) end
    b.Parent = parent
    return b
end

-- ============================================================
--  COLOUR PALETTE
-- ============================================================
local C = {
    BG        = Color3.fromRGB(13,13,20),
    Panel     = Color3.fromRGB(20,20,30),
    Card      = Color3.fromRGB(26,26,38),
    CardHover = Color3.fromRGB(33,33,48),
    CardSel   = Color3.fromRGB(38,25,70),
    Accent    = Color3.fromRGB(105,65,225),
    AccentH   = Color3.fromRGB(130,90,255),
    Border    = Color3.fromRGB(45,45,62),
    Text      = Color3.fromRGB(235,235,250),
    Sub       = Color3.fromRGB(140,140,165),
    Green     = Color3.fromRGB(75,200,115),
    Yellow    = Color3.fromRGB(240,195,55),
    Red       = Color3.fromRGB(220,75,75),
    Friend    = Color3.fromRGB(55,185,100),
    Splash    = Color3.fromRGB(8,8,14),
}

-- ============================================================
--  ROOT SCREENGUI
-- ============================================================
local function SafeDestroy(name)
    pcall(function()
        local g = gethui and gethui() or game.CoreGui
        local old = g:FindFirstChild(name)
        if old then old:Destroy() end
    end)
end
SafeDestroy("ZaxServerList")

local Root = Instance.new("ScreenGui")
Root.Name           = "ZaxServerList"
Root.ResetOnSpawn   = false
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.IgnoreGuiInset = true
Root.DisplayOrder   = 999
Root.Parent         = gethui and gethui() or game.CoreGui

-- ============================================================
--  SPLASH SCREEN
-- ============================================================
local Splash = Frame(Root, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.Splash)
Splash.ZIndex = 200

-- Background glow orb
local Glow = Frame(Splash, UDim2.new(0,400,0,400), UDim2.new(0.5,-200,0.5,-200),
    Color3.fromRGB(0,0,0))
Glow.BackgroundTransparency = 1
Glow.ZIndex = 200
local GG = Instance.new("UIGradient")
GG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70,30,160)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
})
GG.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.5),
    NumberSequenceKeypoint.new(1, 1),
})
GG.Parent = Glow

-- Title
local STitle = Instance.new("TextLabel")
STitle.Size               = UDim2.new(0,520,0,72)
STitle.Position           = UDim2.new(0.5,-260,0.5,-95)
STitle.BackgroundTransparency = 1
STitle.Text               = "Zax's Server List"
STitle.TextSize           = 44
STitle.Font               = Enum.Font.GothamBlack
STitle.ZIndex             = 201
STitle.Parent             = Splash
local SG = Instance.new("UIGradient")
SG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(210,160,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(145,105,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90,175,255)),
})
SG.Parent = STitle

local SSub = Label(Splash, UDim2.new(0,500,0,26), UDim2.new(0.5,-250,0.5,-16),
    "Initialising…", 15, Enum.Font.Gotham, C.Sub, Enum.TextXAlignment.Center)
SSub.ZIndex = 201

-- Progress bar
local PBG = Frame(Splash, UDim2.new(0,340,0,6), UDim2.new(0.5,-170,0.5,42),
    Color3.fromRGB(28,28,40), 3)
PBG.ZIndex = 201
local PFill = Frame(PBG, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0), C.Accent, 3, "PFill")
PFill.ZIndex = 202
local PPct = Label(Splash, UDim2.new(0,340,0,20), UDim2.new(0.5,-170,0.5,54),
    "0%", 11, Enum.Font.Gotham, C.Sub, Enum.TextXAlignment.Center)
PPct.ZIndex = 201

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local WIN_W, WIN_H = 940, 580
local MIN_W, MIN_H = 700, 440
local MAX_W, MAX_H = 1300, 860

local Main = Frame(Root,
    UDim2.new(0,WIN_W,0,WIN_H),
    UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    C.BG, 12)
Main.ClipsDescendants = true
Main.Visible          = false
MakeStroke(Main, C.Border, 1.5)

-- ── Title Bar ────────────────────────────────────────────────
local TBar = Frame(Main, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.Panel, 12)
Frame(TBar, UDim2.new(1,0,0,8), UDim2.new(0,0,1,-8), C.Panel) -- radius patch

Label(TBar, UDim2.new(1,-180,1,0), UDim2.new(0,14,0,0),
    "⚡  Zax's Server List", 15, Enum.Font.GothamBold, C.Text)

-- Server count pill
local CBadge = Frame(TBar, UDim2.new(0,100,0,22), UDim2.new(0,178,0.5,-11),
    Color3.fromRGB(32,20,58), 11)
local CBadgeTxt = Label(CBadge, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "0 servers", 11, Enum.Font.GothamBold, C.Accent, Enum.TextXAlignment.Center)

-- Minimize
local MinBtn = Btn(TBar, UDim2.new(0,30,0,30), UDim2.new(1,-38,0.5,-15),
    "–", Color3.fromRGB(42,42,58), C.Text, 20, 6, "MinBtn")

-- ── Content Area ─────────────────────────────────────────────
local Content = Frame(Main, UDim2.new(1,0,1,-46), UDim2.new(0,0,0,46),
    Color3.fromRGB(0,0,0))
Content.BackgroundTransparency = 1

-- ── Left Panel ────────────────────────────────────────────────
local LEFT_W  = 365
local LeftPanel = Frame(Content, UDim2.new(0,LEFT_W,1,-14), UDim2.new(0,7,0,7),
    C.Panel, 10)

-- Filter row
local FRow = Frame(LeftPanel, UDim2.new(1,-14,0,34), UDim2.new(0,7,0,7),
    Color3.fromRGB(0,0,0))
FRow.BackgroundTransparency = 1

local FriendBtn = Btn(FRow, UDim2.new(0,132,1,0), UDim2.new(0,0,0,0),
    "👥  Friends Only", Color3.fromRGB(30,30,46), C.Sub, 12, 7, "FriendBtn")

Label(FRow, UDim2.new(1,-220,1,0), UDim2.new(0,138,0,0),
    "↓ Most Players", 11, Enum.Font.Gotham, C.Sub, Enum.TextXAlignment.Center)

local RefBtn = Btn(FRow, UDim2.new(0,80,1,0), UDim2.new(1,-80,0,0),
    "↻  Refresh", C.Accent, C.Text, 12, 7, "RefBtn")

-- Divider
Frame(LeftPanel, UDim2.new(1,-14,0,1), UDim2.new(0,7,0,47), C.Border)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                = UDim2.new(1,-6,1,-56)
Scroll.Position            = UDim2.new(0,3,0,53)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel     = 0
Scroll.ScrollBarThickness  = 4
Scroll.ScrollBarImageColor3 = C.Accent
Scroll.CanvasSize          = UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ScrollingDirection  = Enum.ScrollingDirection.Y
Scroll.Parent              = LeftPanel

local SLL = Instance.new("UIListLayout")
SLL.Padding    = UDim.new(0,5)
SLL.SortOrder  = Enum.SortOrder.LayoutOrder
SLL.Parent     = Scroll

local SPAD = Instance.new("UIPadding")
SPAD.PaddingLeft   = UDim.new(0,4)
SPAD.PaddingRight  = UDim.new(0,4)
SPAD.PaddingTop    = UDim.new(0,4)
SPAD.PaddingBottom = UDim.new(0,6)
SPAD.Parent        = Scroll

-- ── Right Panel ───────────────────────────────────────────────
local RIGHT_X  = LEFT_W + 14
local RightPanel = Frame(Content,
    UDim2.new(1,-(RIGHT_X+7),1,-14),
    UDim2.new(0,RIGHT_X,0,7), C.Panel, 10)

-- Placeholder
local Placeholder = Label(RightPanel, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "<font color='#787892'>← Select a server\nto view its details</font>",
    18, Enum.Font.Gotham, C.Sub, Enum.TextXAlignment.Center)
Placeholder.TextYAlignment = Enum.TextYAlignment.Center
Placeholder.RichText = true

-- Detail container
local Det = Frame(RightPanel, UDim2.new(1,-22,1,-18), UDim2.new(0,11,0,9),
    Color3.fromRGB(0,0,0))
Det.BackgroundTransparency = 1
Det.Visible = false

-- Banner
local Banner = Frame(Det, UDim2.new(1,0,0,118), UDim2.new(0,0,0,0),
    Color3.fromRGB(16,16,28), 8)
local BannerGrad = Instance.new("UIGradient")
BannerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55,25,115)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(16,16,38)),
})
BannerGrad.Rotation = 135
BannerGrad.Parent = Banner

Label(Banner, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "🖥️", 42, Enum.Font.Gotham, C.Text, Enum.TextXAlignment.Center)
    :clone() -- ignored, just for vibe

local BannerIcon = Instance.new("TextLabel")
BannerIcon.Size               = UDim2.new(1,0,1,0)
BannerIcon.BackgroundTransparency = 1
BannerIcon.Text               = "🖥️"
BannerIcon.TextSize           = 42
BannerIcon.Font               = Enum.Font.Gotham
BannerIcon.TextColor3         = C.Text
BannerIcon.TextXAlignment     = Enum.TextXAlignment.Center
BannerIcon.TextYAlignment     = Enum.TextYAlignment.Center
BannerIcon.Parent             = Banner

local BannerTag = Label(Banner, UDim2.new(1,-12,0,18), UDim2.new(0,8,1,-22),
    "Server Details", 12, Enum.Font.GothamBold, C.Sub)

-- Stat rows
local function StatRow(yOff, icon, labelTxt)
    local row = Frame(Det, UDim2.new(1,0,0,40), UDim2.new(0,0,0,128+yOff),
        Color3.fromRGB(22,22,34), 7)
    MakeStroke(row, C.Border, 1)
    
    local ico = Label(row, UDim2.new(0,38,1,0), UDim2.new(0,0,0,0),
        icon, 17, Enum.Font.Gotham, C.Text, Enum.TextXAlignment.Center)
    ico.TextYAlignment = Enum.TextYAlignment.Center
    
    Label(row, UDim2.new(0.5,-36,1,0), UDim2.new(0,38,0,0),
        labelTxt, 13, Enum.Font.Gotham, C.Sub)
        :clone() -- ignored
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5,-36,1,0)
    lbl.Position = UDim2.new(0,38,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelTxt
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = C.Sub
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Parent = row
    
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.5,-8,1,0)
    val.Position = UDim2.new(0.5,0,0,0)
    val.BackgroundTransparency = 1
    val.Text = "—"
    val.TextSize = 13
    val.Font = Enum.Font.GothamBold
    val.TextColor3 = C.Text
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.TextYAlignment = Enum.TextYAlignment.Center
    val.Parent = row
    return val
end

local ValPlayers = StatRow(0,   "👥", "Players")
local ValPing    = StatRow(46,  "📡", "Ping")
local ValRegion  = StatRow(92,  "🌍", "Region")
local ValID      = StatRow(138, "🔑", "Job ID")

-- Friend notice
local FNotice = Frame(Det, UDim2.new(1,0,0,30), UDim2.new(0,0,0,326),
    Color3.fromRGB(28,65,42), 7)
FNotice.Visible = false
MakeStroke(FNotice, C.Friend, 1)
local FNoticeTxt = Label(FNotice, UDim2.new(1,-10,1,0), UDim2.new(0,8,0,0),
    "👥  A friend is on this server!", 12, Enum.Font.GothamBold, C.Friend)
FNoticeTxt.TextYAlignment = Enum.TextYAlignment.Center

-- Join button
local JoinBtn = Btn(Det, UDim2.new(1,0,0,48), UDim2.new(0,0,1,-52),
    "  Join Server  →", C.Accent, C.Text, 15, 10, "JoinBtn")
MakeStroke(JoinBtn, Color3.fromRGB(130,90,255), 1.2)

-- ── Resize Grip ───────────────────────────────────────────────
local RGrip = Btn(Main, UDim2.new(0,18,0,18), UDim2.new(1,-18,1,-18),
    "⤡", Color3.fromRGB(50,28,95), C.Sub, 11, 4, "RGrip")
RGrip.ZIndex = 20

-- ============================================================
--  STATE
-- ============================================================
local AllServers   = {}
local FriendIds    = {}
local FriendFilter = false
local SelectedId   = nil
local CurrentJobId = nil
local IsMin        = false

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================
local function PingColor(p)
    return p < 80 and C.Green or p < 160 and C.Yellow or C.Red
end

local function Region(p)
    if    p <= 55  then return "🇺🇸  US East"
    elseif p <= 90  then return "🇺🇸  US West"
    elseif p <= 130 then return "🇪🇺  Europe"
    elseif p <= 180 then return "🌏  Asia"
    else                 return "🌐  High Latency" end
end

local function ShortId(id)
    return id and (id:sub(1,14).."…") or "Unknown"
end

-- ============================================================
--  NETWORK
-- ============================================================
local function SafeGet(url)
    local ok, r = pcall(game.HttpGet, game, url)
    return ok and r or nil
end

local function FetchFriends()
    local raw = SafeGet("https://friends.roblox.com/v1/users/"
        ..LocalPlayer.UserId.."/friends?userSort=Alphabetical")
    if not raw then return end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok and d and d.data then
        for _, f in ipairs(d.data) do
            FriendIds[tostring(f.id)] = f.displayName or f.name
        end
    end
end

local function FriendPresenceMap()
    local ids = {}
    for uid in pairs(FriendIds) do table.insert(ids, tonumber(uid)) end
    if #ids == 0 then return {} end
    local pmap = {}
    pcall(function()
        local body = HttpService:JSONEncode({userIds=ids, excludeByPrivacy=true})
        local resp  = (request or (syn and syn.request) or http_request)({
            Url     = "https://presence.roblox.com/v1/presence/users",
            Method  = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body    = body,
        })
        if resp and resp.Body then
            local d = HttpService:JSONDecode(resp.Body)
            if d and d.userPresences then
                for _, p in ipairs(d.userPresences) do
                    if tostring(p.placeId) == tostring(PlaceId) and p.gameInstanceId then
                        pmap[p.gameInstanceId] = FriendIds[tostring(p.userId)] or "Friend"
                    end
                end
            end
        end
    end)
    return pmap
end

local function FetchPage(cursor)
    local url = "https://games.roblox.com/v1/games/"..PlaceId
        .."/servers/Public?sortOrder=Desc&excludeFullGames=false&limit=100"
    if cursor and cursor ~= "" then url = url.."&cursor="..cursor end
    local raw = SafeGet(url)
    if not raw then return {}, nil end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, raw)
    return (ok and d and d.data) and d.data or {}, (ok and d) and d.nextPageCursor or nil
end

-- ============================================================
--  SERVER CARDS
-- ============================================================
local function ClearCards()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function BuildCard(server, idx)
    local cur  = server.playing or 0
    local max  = server.maxPlayers or 10
    local ping = server._ping or math.random(28,230)
    local fill = math.min(cur / math.max(max,1), 1)
    local hf   = server._hasFriend

    local card = Frame(Scroll, UDim2.new(1,-8,0,66), UDim2.new(0,0,0,0),
        C.Card, 8, "Card_"..server.id)
    card.LayoutOrder = idx

    local stroke = MakeStroke(card, hf and C.Friend or C.Border, hf and 1.5 or 1)

    -- Fill bar
    local bbg = Frame(card, UDim2.new(1,-16,0,3), UDim2.new(0,8,1,-9),
        Color3.fromRGB(28,28,44), 2)
    Frame(bbg, UDim2.new(fill,0,1,0), UDim2.new(0,0,0,0),
        fill>0.85 and C.Red or fill>0.55 and C.Yellow or C.Green, 2)

    -- Player count
    Label(card, UDim2.new(0,140,0,22), UDim2.new(0,10,0,8),
        string.format("👥  <b>%d / %d</b>", cur, max), 13, Enum.Font.Gotham, C.Text)

    -- Ping
    Label(card, UDim2.new(0,90,0,20), UDim2.new(0,10,0,34),
        string.format("📡  %d ms", ping), 12, Enum.Font.Gotham, PingColor(ping))

    -- Region (right side)
    Label(card, UDim2.new(0,140,0,20), UDim2.new(0,155,0,8),
        Region(ping), 11, Enum.Font.Gotham, C.Sub)

    -- Friend badge
    if hf then
        local bdg = Frame(card, UDim2.new(0,72,0,18), UDim2.new(1,-78,0,8),
            C.Friend, 5)
        Label(bdg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
            "👥 Friend", 10, Enum.Font.GothamBold,
            Color3.fromRGB(255,255,255), Enum.TextXAlignment.Center)
    end

    -- Invisible click overlay
    local ov = Instance.new("TextButton")
    ov.Size               = UDim2.new(1,0,1,0)
    ov.BackgroundTransparency = 1
    ov.Text               = ""
    ov.ZIndex             = 8
    ov.BorderSizePixel    = 0
    ov.AutoButtonColor    = false
    ov.Parent             = card

    ov.MouseEnter:Connect(function()
        if server.id ~= SelectedId then
            Tween(card, {BackgroundColor3=C.CardHover}, 0.12)
        end
    end)
    ov.MouseLeave:Connect(function()
        if server.id ~= SelectedId then
            Tween(card, {BackgroundColor3=C.Card}, 0.12)
        end
    end)

    ov.MouseButton1Click:Connect(function()
        -- Deselect others
        for _, ch in ipairs(Scroll:GetChildren()) do
            if ch:IsA("Frame") and ch ~= card then
                Tween(ch, {BackgroundColor3=C.Card}, 0.12)
                local s2 = ch:FindFirstChildOfClass("UIStroke")
                if s2 then s2.Color=C.Border; s2.Thickness=1 end
            end
        end
        -- Select
        SelectedId   = server.id
        CurrentJobId = server.id
        Tween(card, {BackgroundColor3=C.CardSel}, 0.12)
        stroke.Color     = C.Accent
        stroke.Thickness = 2

        -- Fill right panel
        Placeholder.Visible = false
        Det.Visible         = true

        ValPlayers.Text       = string.format("%d / %d", cur, max)
        ValPlayers.TextColor3 = fill>0.85 and C.Red or C.Green
        ValPing.Text          = ping.." ms"
        ValPing.TextColor3    = PingColor(ping)
        ValRegion.Text        = Region(ping)
        ValID.Text            = ShortId(server.id)
        FNotice.Visible       = hf
        JoinBtn.Text          = "  Join Server  →"
        Tween(JoinBtn, {BackgroundColor3=C.Accent}, 0.15)

        Det.GroupTransparency = 0.95
        Tween(Det, {GroupTransparency=0}, 0.28)
    end)
end

-- ============================================================
--  POPULATE
-- ============================================================
local function Populate()
    ClearCards()
    SelectedId   = nil
    CurrentJobId = nil
    Placeholder.Visible = true
    Det.Visible         = false

    local list = {}
    for _, s in ipairs(AllServers) do
        if not FriendFilter or s._hasFriend then
            table.insert(list, s)
        end
    end
    table.sort(list, function(a,b)
        return (a.playing or 0) > (b.playing or 0)
    end)

    CBadgeTxt.Text = #list.." servers"
    for i, s in ipairs(list) do BuildCard(s, i) end
end

-- ============================================================
--  LOAD SERVERS
-- ============================================================
local function LoadServers(statusCb)
    AllServers = {}
    local pmap = FriendPresenceMap()
    local data, cursor = FetchPage()
    local page = 1
    while data and #data > 0 do
        for _, s in ipairs(data) do
            s._ping      = s.ping or math.random(22,245)
            s._hasFriend = pmap[s.id] ~= nil
            table.insert(AllServers, s)
        end
        if statusCb then statusCb("Loaded "..#AllServers.." servers…") end
        if cursor and cursor~="" and page<4 then
            page=page+1
            task.wait(0.2)
            data, cursor = FetchPage(cursor)
        else break end
    end
end

-- ============================================================
--  JOIN
-- ============================================================
JoinBtn.MouseButton1Click:Connect(function()
    if not CurrentJobId then return end
    Tween(JoinBtn, {BackgroundColor3=Color3.fromRGB(55,55,75)}, 0.12)
    JoinBtn.Text = "  Joining…"
    local ok = pcall(TeleportService.TeleportToPlaceInstance, TeleportService,
        PlaceId, CurrentJobId, LocalPlayer)
    if not ok then
        Tween(JoinBtn, {BackgroundColor3=C.Red}, 0.1)
        JoinBtn.Text = "  Failed — Retry?"
        task.wait(2.5)
        JoinBtn.Text = "  Join Server  →"
        Tween(JoinBtn, {BackgroundColor3=C.Accent}, 0.2)
    end
end)
JoinBtn.MouseEnter:Connect(function()
    Tween(JoinBtn, {BackgroundColor3=C.AccentH}, 0.12)
end)
JoinBtn.MouseLeave:Connect(function()
    Tween(JoinBtn, {BackgroundColor3=C.Accent}, 0.12)
end)

-- ============================================================
--  FRIEND FILTER
-- ============================================================
FriendBtn.MouseButton1Click:Connect(function()
    FriendFilter = not FriendFilter
    if FriendFilter then
        Tween(FriendBtn, {BackgroundColor3=C.Friend}, 0.18)
        FriendBtn.TextColor3 = Color3.fromRGB(255,255,255)
    else
        Tween(FriendBtn, {BackgroundColor3=Color3.fromRGB(30,30,46)}, 0.18)
        FriendBtn.TextColor3 = C.Sub
    end
    Populate()
end)

-- ============================================================
--  REFRESH
-- ============================================================
RefBtn.MouseButton1Click:Connect(function()
    RefBtn.Text = "↻  …"
    Tween(RefBtn, {BackgroundColor3=Color3.fromRGB(62,35,135)}, 0.1)
    task.spawn(function()
        LoadServers(function(msg) SSub.Text=msg end)
        Populate()
        RefBtn.Text = "↻  Refresh"
        Tween(RefBtn, {BackgroundColor3=C.Accent}, 0.15)
    end)
end)

-- ============================================================
--  MINIMIZE
-- ============================================================
MinBtn.MouseButton1Click:Connect(function()
    IsMin = not IsMin
    if IsMin then
        Tween(Main, {Size=UDim2.new(0,Main.AbsoluteSize.X,0,46)}, 0.3,
            Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        MinBtn.Text = "□"
    else
        local w = Main.AbsoluteSize.X
        Tween(Main, {Size=UDim2.new(0,w,0,WIN_H)}, 0.35,
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        MinBtn.Text = "–"
    end
end)
MinBtn.MouseEnter:Connect(function()
    Tween(MinBtn, {BackgroundColor3=Color3.fromRGB(65,65,85)}, 0.1)
end)
MinBtn.MouseLeave:Connect(function()
    Tween(MinBtn, {BackgroundColor3=Color3.fromRGB(42,42,58)}, 0.1)
end)
RefBtn.MouseEnter:Connect(function()
    Tween(RefBtn, {BackgroundColor3=C.AccentH}, 0.1)
end)
RefBtn.MouseLeave:Connect(function()
    Tween(RefBtn, {BackgroundColor3=C.Accent}, 0.1)
end)

-- ============================================================
--  RESIZE
-- ============================================================
local resizing    = false
local rStart      = Vector2.zero
local rW, rH      = WIN_W, WIN_H

local function SyncPanels(w, h)
    Main.Position = UDim2.new(0.5,-w/2,0.5,-h/2)
    RightPanel.Size = UDim2.new(0, w-(RIGHT_X+7)-7, 1,-14)
end

RGrip.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        resizing = true
        rStart   = Vector2.new(inp.Position.X, inp.Position.Y)
        rW       = Main.AbsoluteSize.X
        rH       = Main.AbsoluteSize.Y
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not resizing then return end
    if inp.UserInputType~=Enum.UserInputType.MouseMovement
    and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local dx = inp.Position.X - rStart.X
    local dy = inp.Position.Y - rStart.Y
    local nw = math.clamp(rW+dx, MIN_W, MAX_W)
    local nh = math.clamp(rH+dy, MIN_H, MAX_H)
    Main.Size = UDim2.new(0,nw,0,nh)
    SyncPanels(nw, nh)
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ============================================================
--  SPLASH ANIMATION + BOOT
-- ============================================================
local function SetProg(pct, msg)
    local r = math.clamp(pct,0,1)
    Tween(PFill, {Size=UDim2.new(r,0,1,0)}, 0.32)
    PPct.Text = math.floor(r*100).."%"
    if msg then SSub.Text = msg end
end

local function FadeGui(gui, t)
    Tween(gui, {BackgroundTransparency=1}, t)
    for _, v in ipairs(gui:GetDescendants()) do
        pcall(function()
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                Tween(v, {TextTransparency=1, BackgroundTransparency=1}, t)
            elseif v:IsA("Frame") then
                Tween(v, {BackgroundTransparency=1}, t)
            elseif v:IsA("UIStroke") then
                Tween(v, {Transparency=1}, t)
            end
        end)
    end
    task.wait(t+0.06)
    gui.Visible = false
end

task.spawn(function()
    task.wait(0.25)
    SetProg(0.06, "Connecting to Roblox API…")
    task.wait(0.25)

    SetProg(0.18, "Fetching friend list…")
    FetchFriends()
    task.wait(0.15)

    SetProg(0.32, "Requesting server list…")
    LoadServers(function(msg)
        SSub.Text = msg
        local approx = math.min(0.32 + (#AllServers/300)*0.5, 0.82)
        Tween(PFill, {Size=UDim2.new(approx,0,1,0)}, 0.3)
        PPct.Text = math.floor(approx*100).."%"
    end)

    SetProg(1.0, "Ready!  "..#AllServers.." servers found.")
    task.wait(0.6)

    FadeGui(Splash, 0.48)

    -- Reveal main window
    Main.Visible  = true
    local cw      = WIN_W
    Main.Size     = UDim2.new(0,cw,0,10)
    Main.Position = UDim2.new(0.5,-cw/2,0.5,-5)
    Tween(Main, {
        Size     = UDim2.new(0,cw,0,WIN_H),
        Position = UDim2.new(0.5,-cw/2,0.5,-WIN_H/2),
    }, 0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)
    Populate()
end)

--- ============================================================
--  MOBILE ADAPTATION  (runs once after window is visible)
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    local vp = workspace.CurrentCamera.ViewportSize
    if vp.X < 800 then
        -- Restrict to 75% of the screen instead of near 100%
        local mw = math.clamp(vp.X * 0.75, 300, 500)
        local mh = math.clamp(vp.Y * 0.75, 250, 450)
        
        Main.Size     = UDim2.new(0, mw, 0, mh)
        Main.Position = UDim2.new(0.5, -mw/2, 0.5, -mh/2)
        
        -- Stack: left panel top, right panel bottom
        -- Account for the 46px Title Bar height
        local contentH = mh - 46 
        local lh = math.floor(contentH * 0.5)
        local rh = contentH - lh - 21 -- 21px total vertical padding
        
        LeftPanel.Size     = UDim2.new(1, -14, 0, lh)
        LeftPanel.Position = UDim2.new(0, 7, 0, 7)
        
        RightPanel.Size    = UDim2.new(1, -14, 0, rh)
        RightPanel.Position = UDim2.new(0, 7, 0, lh + 14)
        
        WIN_W, WIN_H = mw, mh
    end
end)

-- End of ZaxServerList