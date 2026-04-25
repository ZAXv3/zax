-- Product Purchase Faker (Improved)
-- v2 - Added scanner, clear logs, bulk fix, safe zone, floating mode

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- ─────────────────────────────────────────────
-- SCREEN SIZE HELPERS
-- ─────────────────────────────────────────────
local Camera = workspace.CurrentCamera
local function getScreenSize()
    return Camera.ViewportSize
end

local function isMobile()
    return UIS.TouchEnabled and not UIS.MouseEnabled
end

-- ─────────────────────────────────────────────
-- CONSTANTS with Safe Zone
-- ─────────────────────────────────────────────
local SAFE_INSET = isMobile() and getScreenSize().X * 0.02 or 0
local GUI_WIDTH  = isMobile() and math.min(getScreenSize().X - SAFE_INSET*2, 380) or 520
local GUI_HEIGHT = isMobile() and math.min(getScreenSize().Y - SAFE_INSET*2, 460) or 390

local COLOR_BG        = Color3.fromRGB(22, 23, 30)
local COLOR_HEADER    = Color3.fromRGB(30, 32, 42)
local COLOR_ACTIVE    = Color3.fromRGB(104, 123, 165)
local COLOR_INACTIVE  = Color3.fromRGB(58, 63, 75)
local COLOR_CARD      = Color3.fromRGB(38, 41, 54)
local COLOR_STROKE    = Color3.fromRGB(80, 85, 100)
local COLOR_WHITE     = Color3.fromRGB(255, 255, 255)
local COLOR_YELLOW    = Color3.fromRGB(255, 201, 37)
local COLOR_RED       = Color3.fromRGB(255, 80, 80)
local COLOR_GREEN     = Color3.fromRGB(80, 220, 120)
local COLOR_TEXT_DIM  = Color3.fromRGB(160, 165, 185)

-- ─────────────────────────────────────────────
-- ROOT GUI
-- ─────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "ProductFakerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- ─────────────────────────────────────────────
-- HELPER: make a rounded corner + stroke frame/button
-- ─────────────────────────────────────────────
local function applyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function applyStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLOR_STROKE
    s.Thickness = thickness or 1
    s.Parent = parent
end

local function makePadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top or 6)
    p.PaddingBottom = UDim.new(0, bottom or 6)
    p.PaddingLeft   = UDim.new(0, left or 8)
    p.PaddingRight  = UDim.new(0, right or 8)
    p.Parent = parent
end

local function makeLabel(parent, text, size, color, xAlign, bold)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.TextSize = size or 14
    lbl.TextColor3 = color or COLOR_WHITE
    lbl.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.TextScaled = false
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel = 0
    lbl.Size = UDim2.new(1, 0, 0, size and size + 6 or 20)
    lbl.FontFace = Font.new(
        "rbxasset://fonts/families/SourceSansPro.json",
        bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular,
        Enum.FontStyle.Normal
    )
    lbl.Parent = parent
    return lbl
end

-- ─────────────────────────────────────────────
-- MAIN WINDOW
-- ─────────────────────────────────────────────
local mainbg = Instance.new("Frame")
mainbg.Name = "MainWindow"
mainbg.AnchorPoint = Vector2.new(0.5, 0.5)
mainbg.Position = UDim2.new(0.5, 0, 0.5, 0)
mainbg.Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT)
mainbg.BackgroundColor3 = COLOR_BG
mainbg.BorderSizePixel = 0
mainbg.ClipsDescendants = true
mainbg.Parent = ScreenGui
applyCorner(mainbg, 10)
applyStroke(mainbg, COLOR_STROKE, 1)

-- ─────────────────────────────────────────────
-- TITLE BAR (draggable, holds minimize + destroy)
-- ─────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = COLOR_HEADER
titleBar.BorderSizePixel = 0
titleBar.Parent = mainbg

-- bottom separator line
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 1)
sep.Position = UDim2.new(0, 0, 1, 0)
sep.BackgroundColor3 = COLOR_STROKE
sep.BorderSizePixel = 0
sep.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "  🛒  Product Faker"
titleLabel.TextColor3 = COLOR_WHITE
titleLabel.TextSize = isMobile() and 15 or 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
titleLabel.BackgroundTransparency = 1
titleLabel.BorderSizePixel = 0
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 4, 0, 0)
titleLabel.Parent = titleBar

-- Window control buttons container
local winControls = Instance.new("Frame")
winControls.Name = "WinControls"
winControls.Size = UDim2.new(0, 72, 0, 28)
winControls.Position = UDim2.new(1, -76, 0.5, -14)
winControls.BackgroundTransparency = 1
winControls.BorderSizePixel = 0
winControls.Parent = titleBar

local winLayout = Instance.new("UIListLayout")
winLayout.FillDirection = Enum.FillDirection.Horizontal
winLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
winLayout.VerticalAlignment = Enum.VerticalAlignment.Center
winLayout.Padding = UDim.new(0, 6)
winLayout.Parent = winControls

local function makeWinBtn(symbol, bgColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Text = symbol
    btn.TextSize = 14
    btn.TextColor3 = COLOR_WHITE
    btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    btn.AutoButtonColor = false
    btn.Parent = winControls
    applyCorner(btn, 6)
    return btn
end

local minimizeBtn = makeWinBtn("─", Color3.fromRGB(80, 160, 100))
local destroyBtn  = makeWinBtn("✕", Color3.fromRGB(200, 65, 65))

-- ─────────────────────────────────────────────
-- CONTENT AREA (below title bar)
-- ─────────────────────────────────────────────
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, 0, 1, -36)
contentArea.Position = UDim2.new(0, 0, 0, 36)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = mainbg

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 8)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.Parent = contentArea

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabBar

local function makeTabBtn(label)
    local btn = Instance.new("TextButton")
    btn.Text = label
    btn.Size = UDim2.new(0, isMobile() and 100 or 110, 0, 30)
    btn.BackgroundColor3 = COLOR_INACTIVE
    btn.TextColor3 = COLOR_WHITE
    btn.TextSize = isMobile() and 13 or 13
    btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    applyCorner(btn, 7)
    return btn
end

local scanTabBtn     = makeTabBtn("🔍  Scanner")
local listenerTabBtn = makeTabBtn("📡  Listener")
local actionTabBtn   = makeTabBtn("⚡  Action")

-- Tab pages container
local pagesContainer = Instance.new("Frame")
pagesContainer.Name = "Pages"
pagesContainer.Size = UDim2.new(1, -16, 1, -52)
pagesContainer.Position = UDim2.new(0, 8, 0, 48)
pagesContainer.BackgroundTransparency = 1
pagesContainer.BorderSizePixel = 0
pagesContainer.Parent = contentArea

-- ─────────────────────────────────────────────
-- IMPROVED SCANNER TAB (real product scanner)
-- ─────────────────────────────────────────────
local scanPage = Instance.new("ScrollingFrame")
scanPage.Name = "ScanPage"
scanPage.Size = UDim2.new(1, 0, 1, 0)
scanPage.BackgroundTransparency = 1
scanPage.BorderSizePixel = 0
scanPage.ScrollBarThickness = 4
scanPage.ScrollBarImageColor3 = COLOR_STROKE
scanPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
scanPage.CanvasSize = UDim2.new(0, 0, 0, 0)
scanPage.Visible = true
scanPage.Parent = pagesContainer

local scanLayout = Instance.new("UIListLayout")
scanLayout.Padding = UDim.new(0, 6)
scanLayout.SortOrder = Enum.SortOrder.LayoutOrder
scanLayout.Parent = scanPage

-- Clear button for scanner
local clearScanBtn = Instance.new("TextButton")
clearScanBtn.Text = "🗑 Clear Logs"
clearScanBtn.Size = UDim2.new(1, 0, 0, 32)
clearScanBtn.BackgroundColor3 = COLOR_INACTIVE
clearScanBtn.TextColor3 = COLOR_WHITE
clearScanBtn.BorderSizePixel = 0
clearScanBtn.Parent = scanPage
applyCorner(clearScanBtn, 8)
clearScanBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(scanPage:GetChildren()) do
        if child:IsA("Frame") and child ~= clearScanBtn then 
            child:Destroy() 
        end
    end
end)

local scanInfo = makeLabel(scanPage, "🔎  Products detected in this session will appear here.", 13, COLOR_TEXT_DIM, Enum.TextXAlignment.Left, false)
scanInfo.Size = UDim2.new(1, 0, 0, 40)
scanInfo.TextWrapped = true

-- ─────────────────────────────────────────────
-- IMPROVED LISTENER TAB (with clear button)
-- ─────────────────────────────────────────────
local listenerPage = Instance.new("ScrollingFrame")
listenerPage.Name = "ListenerPage"
listenerPage.Size = UDim2.new(1, 0, 1, 0)
listenerPage.BackgroundTransparency = 1
listenerPage.BorderSizePixel = 0
listenerPage.ScrollBarThickness = 4
listenerPage.ScrollBarImageColor3 = COLOR_STROKE
listenerPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
listenerPage.CanvasSize = UDim2.new(0, 0, 0, 0)
listenerPage.Visible = false
listenerPage.Parent = pagesContainer

local listenerLayout = Instance.new("UIListLayout")
listenerLayout.Padding = UDim.new(0, 6)
listenerLayout.SortOrder = Enum.SortOrder.LayoutOrder
listenerLayout.Parent = listenerPage

-- Clear button for listener
local clearListenerBtn = Instance.new("TextButton")
clearListenerBtn.Text = "🗑 Clear Logs"
clearListenerBtn.Size = UDim2.new(1, 0, 0, 32)
clearListenerBtn.BackgroundColor3 = COLOR_INACTIVE
clearListenerBtn.TextColor3 = COLOR_WHITE
clearListenerBtn.BorderSizePixel = 0
clearListenerBtn.Parent = listenerPage
applyCorner(clearListenerBtn, 8)
clearListenerBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(listenerPage:GetChildren()) do
        if child:IsA("Frame") and child ~= clearListenerBtn and child ~= listenerInfo then
            child:Destroy()
        end
    end
end)

local listenerInfo = makeLabel(listenerPage, "📡  Purchase signals fired this session will be logged here.", 13, COLOR_TEXT_DIM, Enum.TextXAlignment.Left, false)
listenerInfo.Size = UDim2.new(1, 0, 0, 40)
listenerInfo.TextWrapped = true

-- ─────────────────────────────────────────────
-- ACTION TAB (improved)
-- ─────────────────────────────────────────────
local actionPage = Instance.new("Frame")
actionPage.Name = "ActionPage"
actionPage.Size = UDim2.new(1, 0, 1, 0)
actionPage.BackgroundTransparency = 1
actionPage.BorderSizePixel = 0
actionPage.Visible = false
actionPage.Parent = pagesContainer

local actionLayout = Instance.new("UIListLayout")
actionLayout.Padding = UDim.new(0, 8)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = actionPage

-- Warning banner
local warnFrame = Instance.new("Frame")
warnFrame.Name = "WarnFrame"
warnFrame.Size = UDim2.new(1, 0, 0, 32)
warnFrame.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
warnFrame.BorderSizePixel = 0
warnFrame.LayoutOrder = 1
warnFrame.Parent = actionPage
applyCorner(warnFrame, 7)
applyStroke(warnFrame, COLOR_RED, 1)

local warnLabel = makeLabel(warnFrame, "⚠  This does NOT actually purchase anything — it only fakes the signal.", 12, COLOR_RED, Enum.TextXAlignment.Left, true)
warnLabel.Size = UDim2.new(1, 0, 1, 0)
warnLabel.TextWrapped = true
warnLabel.TextScaled = false
makePadding(warnFrame, 4, 4, 8, 8)

-- Product ID input card
local inputCard = Instance.new("Frame")
inputCard.Name = "InputCard"
inputCard.Size = UDim2.new(1, 0, 0, 44)
inputCard.BackgroundColor3 = COLOR_CARD
inputCard.BorderSizePixel = 0
inputCard.LayoutOrder = 2
inputCard.Parent = actionPage
applyCorner(inputCard, 8)
applyStroke(inputCard, COLOR_STROKE, 1)

local idIcon = Instance.new("TextLabel")
idIcon.Text = "🆔"
idIcon.Size = UDim2.new(0, 30, 1, 0)
idIcon.Position = UDim2.new(0, 6, 0, 0)
idIcon.TextSize = 18
idIcon.BackgroundTransparency = 1
idIcon.BorderSizePixel = 0
idIcon.Parent = inputCard

local ProductIDInput = Instance.new("TextBox")
ProductIDInput.Name = "ProductIDInput"
ProductIDInput.PlaceholderText = "Enter Product ID (or 123,456 for bulk)..."
ProductIDInput.Text = ""
ProductIDInput.TextSize = isMobile() and 15 or 14
ProductIDInput.TextColor3 = COLOR_YELLOW
ProductIDInput.PlaceholderColor3 = COLOR_TEXT_DIM
ProductIDInput.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
ProductIDInput.BackgroundTransparency = 1
ProductIDInput.BorderSizePixel = 0
ProductIDInput.TextXAlignment = Enum.TextXAlignment.Left
ProductIDInput.ClearTextOnFocus = false
ProductIDInput.TextWrapped = false
ProductIDInput.Size = UDim2.new(1, -44, 1, 0)
ProductIDInput.Position = UDim2.new(0, 40, 0, 0)
ProductIDInput.Parent = inputCard

-- Numeric validation on ProductIDInput
ProductIDInput:GetPropertyChangedSignal("Text"):Connect(function()
    if ProductIDInput.Text ~= "" and not ProductIDInput.Text:find(",") then
        local num = tonumber(ProductIDInput.Text:match("%d+"))
        if not num then
            ProductIDInput.Text = ProductIDInput.Text:gsub("%D", "")
        end
    end
end)

-- Action buttons grid
local btnGrid = Instance.new("Frame")
btnGrid.Name = "BtnGrid"
btnGrid.Size = UDim2.new(1, 0, 0, isMobile() and 120 or 70)
btnGrid.BackgroundTransparency = 1
btnGrid.BorderSizePixel = 0
btnGrid.LayoutOrder = 3
btnGrid.Parent = actionPage

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -4, 0, isMobile() and 52 or 30)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = btnGrid

local function makeActionBtn(label, icon, order)
    local btn = Instance.new("TextButton")
    btn.Text = icon .. "  " .. label
    btn.TextSize = isMobile() and 14 or 13
    btn.TextColor3 = COLOR_WHITE
    btn.BackgroundColor3 = COLOR_ACTIVE
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    btn.Parent = btnGrid
    applyCorner(btn, 8)
    applyStroke(btn, COLOR_STROKE, 1)

    -- hover/press effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(130, 150, 200)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = COLOR_ACTIVE}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(80, 100, 145)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = COLOR_ACTIVE}):Play()
    end)

    return btn
end

local HookBtn     = makeActionBtn("Signal Product",  "📦", 1)
local GamepassBtn = makeActionBtn("Signal Gamepass", "🎮", 2)
local BulkBtn     = makeActionBtn("Signal Bulk",     "📚", 3)
local PurchaseBtn = makeActionBtn("Signal Purchase", "💰", 4)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Text = ""
statusLabel.TextSize = 13
statusLabel.TextColor3 = COLOR_GREEN
statusLabel.BackgroundTransparency = 1
statusLabel.BorderSizePixel = 0
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Size = UDim2.new(1, 0, 0, 22)
statusLabel.LayoutOrder = 4
statusLabel.Parent = actionPage

-- Last fired label
local lastFiredLabel = makeLabel(actionPage, "Last fired: none", 12, COLOR_YELLOW, Enum.TextXAlignment.Left, false)
lastFiredLabel.LayoutOrder = 5
lastFiredLabel.Size = UDim2.new(1, 0, 0, 18)

local function showStatus(msg, isError)
    statusLabel.TextColor3 = isError and COLOR_RED or COLOR_GREEN
    statusLabel.Text = msg
    task.delay(3, function()
        if statusLabel.Text == msg then
            statusLabel.Text = ""
        end
    end)
end

-- ─────────────────────────────────────────────
-- TAB SWITCHING
-- ─────────────────────────────────────────────
local pages = {scanPage, listenerPage, actionPage}
local tabBtns = {scanTabBtn, listenerTabBtn, actionTabBtn}

local function switchTab(index)
    for i, page in ipairs(pages) do
        page.Visible = (i == index)
        tabBtns[i].BackgroundColor3 = (i == index) and COLOR_ACTIVE or COLOR_INACTIVE
        tabBtns[i].TextColor3 = COLOR_WHITE
    end
end

switchTab(1)

scanTabBtn.MouseButton1Click:Connect(function() switchTab(1) end)
listenerTabBtn.MouseButton1Click:Connect(function() switchTab(2) end)
actionTabBtn.MouseButton1Click:Connect(function() switchTab(3) end)

-- ─────────────────────────────────────────────
-- LOG CARD (Listener + Scanner tabs)
-- ─────────────────────────────────────────────
local function addLog(parentFrame, productName, productId, signalType, wasPurchased)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = COLOR_CARD
    card.BorderSizePixel = 0
    card.Parent = parentFrame
    applyCorner(card, 8)
    applyStroke(card, COLOR_STROKE, 1)

    makePadding(card, 6, 6, 10, 10)

    local inner = Instance.new("UIListLayout")
    inner.Padding = UDim.new(0, 2)
    inner.SortOrder = Enum.SortOrder.LayoutOrder
    inner.Parent = card

    local nameLbl = makeLabel(card, "📦  " .. (productName or "Unknown Product"), 13, COLOR_WHITE, Enum.TextXAlignment.Left, true)
    nameLbl.LayoutOrder = 1
    nameLbl.Size = UDim2.new(1, -70, 0, 18)

    local idLbl = makeLabel(card, "ID: " .. tostring(productId) .. "  |  " .. (signalType or "?") .. "  |  " .. (wasPurchased ~= nil and (wasPurchased and "✅ true" or "❌ false") or "🔍 scanned"), 11, COLOR_YELLOW, Enum.TextXAlignment.Left, false)
    idLbl.LayoutOrder = 2
    idLbl.Size = UDim2.new(1, -70, 0, 16)

    -- Copy button (top-right of card)
    local copyBtn = Instance.new("TextButton")
    copyBtn.Text = "📋"
    copyBtn.TextSize = 16
    copyBtn.Size = UDim2.new(0, 34, 0, 34)
    copyBtn.Position = UDim2.new(1, -40, 0, 8)
    copyBtn.AnchorPoint = Vector2.new(0, 0)
    copyBtn.BackgroundColor3 = COLOR_INACTIVE
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = card
    applyCorner(copyBtn, 7)

    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(tostring(productId))
            copyBtn.Text = "✅"
            task.delay(1.2, function() copyBtn.Text = "📋" end)
        end
    end)

    return card
end

-- ─────────────────────────────────────────────
-- ACTION BUTTON LOGIC (improved bulk)
-- ─────────────────────────────────────────────
local function getProductID()
    local text = ProductIDInput.Text
    if text:find(",") then
        return text  -- Return raw string for bulk processing
    end
    local id = tonumber(text:match("%d+"))
    if not id then
        showStatus("✕  Invalid Product ID — enter a number or comma-separated list.", true)
        return nil
    end
    return id
end

local function fireSignal(signalType, rawId)
    if not rawId then 
        rawId = getProductID()
        if not rawId then return end
    end

    local player = Players.LocalPlayer
    local successCount = 0
    local totalCount = 0

    local ids = {}
    if signalType == "Bulk" and type(rawId) == "string" and rawId:find(",") then
        for id in rawId:gmatch("%d+") do 
            table.insert(ids, tonumber(id))
        end
    else
        local num = tonumber(rawId)
        if num then
            ids = {num}
        end
    end
    
    totalCount = #ids
    if totalCount == 0 then
        showStatus("✕  No valid product IDs found.", true)
        return
    end

    for _, pid in ipairs(ids) do
        local ok, err = pcall(function()
            if signalType == "Product" then
                MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, pid, true)
            elseif signalType == "Gamepass" then
                MarketplaceService:SignalPromptGamePassPurchaseFinished(player, pid, true)
            elseif signalType == "Bulk" then
                MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, {pid}, true)
            elseif signalType == "Purchase" then
                MarketplaceService:SignalPromptPurchaseFinished(player.UserId, pid, true)
            end
        end)
        
        if ok then 
            successCount = successCount + 1
            addLog(listenerPage, "Manual "..signalType, pid, signalType, true)
        end
    end

    if successCount > 0 then
        local msg = string.format("✓ Fired %s for %d/%d product(s)", signalType, successCount, totalCount)
        showStatus(msg, false)
        lastFiredLabel.Text = string.format("Last fired: %s (IDs: %s) at %s", signalType, tostring(rawId), os.date("%H:%M:%S"))
    else
        showStatus("✕ Failed to fire "..signalType, true)
    end
end

HookBtn.MouseButton1Click:Connect(function() 
    local id = getProductID()
    if id then fireSignal("Product", id) end
end)

GamepassBtn.MouseButton1Click:Connect(function() 
    local id = getProductID()
    if id then fireSignal("Gamepass", id) end
end)

BulkBtn.MouseButton1Click:Connect(function() 
    local input = ProductIDInput.Text
    if input and input ~= "" then
        fireSignal("Bulk", input)
    else
        showStatus("✕ Enter product IDs separated by commas for bulk (e.g., 123,456,789)", true)
    end
end)

PurchaseBtn.MouseButton1Click:Connect(function() 
    local id = getProductID()
    if id then fireSignal("Purchase", id) end
end)

-- ─────────────────────────────────────────────
-- FLOATING MODE ON MINIMIZE (improved)
-- ─────────────────────────────────────────────
local isMinimized = false
local normalHeight = GUI_HEIGHT
local normalWidth = GUI_WIDTH

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentArea.Visible = not isMinimized
    minimizeBtn.Text = isMinimized and "□" or "─"
    
    local targetHeight = isMinimized and 36 or normalHeight
    local targetWidth = isMinimized and 120 or normalWidth
    
    if isMinimized then
        -- Become a small floating pill
        titleLabel.Text = "  🛒 Faker"
    else
        titleLabel.Text = "  🛒  Product Faker"
    end
    
    TweenService:Create(mainbg, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, targetWidth, 0, targetHeight)
    }):Play()
end)

-- ─────────────────────────────────────────────
-- MINIMIZE / DESTROY (continued)
-- ─────────────────────────────────────────────
destroyBtn.MouseButton1Click:Connect(function()
    TweenService:Create(mainbg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, GUI_WIDTH, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function()
        ScreenGui:Destroy()
    end)
end)

-- Hover effects for window buttons
for _, btn in ipairs({minimizeBtn, destroyBtn}) do
    local origColor = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = btn.BackgroundColor3:Lerp(COLOR_WHITE, 0.3)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = origColor}):Play()
    end)
end

-- ─────────────────────────────────────────────
-- DRAGGING (title bar only — safe for mobile)
-- ─────────────────────────────────────────────
do
    local dragging = false
    local dragStart, startPos

    local function onInputBegan(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) and
            UIS:GetFocusedTextBox() == nil then
            dragging = true
            dragStart = input.Position
            startPos = mainbg.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            TweenService:Create(mainbg, TweenInfo.new(0.1), {Position = newPos}):Play()
        end
    end

    titleBar.InputBegan:Connect(onInputBegan)
    UIS.InputChanged:Connect(onInputChanged)
end

-- ─────────────────────────────────────────────
-- MARKETPLACE LISTENER (auto-log real purchases)
-- ─────────────────────────────────────────────
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
    local name = "DevProduct"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
        name = info.Name or name
    end)
    addLog(listenerPage, name, productId, "Product", wasPurchased)
    addLog(scanPage, name, productId, "Product", wasPurchased)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    local name = "GamePass"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(gamePassId, Enum.InfoType.GamePass)
        name = info.Name or name
    end)
    addLog(listenerPage, name, gamePassId, "Gamepass", wasPurchased)
    addLog(scanPage, name, gamePassId, "Gamepass", wasPurchased)
end)

MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, isPurchased)
    local name = "Asset"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
        name = info.Name or name
    end)
    addLog(listenerPage, name, assetId, "Purchase", isPurchased)
    addLog(scanPage, name, assetId, "Purchase", isPurchased)
end)

-- Auto-scan for existing products (dev products in game)
task.spawn(function()
    task.wait(1)
    local localPlayer = Players.LocalPlayer
    pcall(function()
        local products = MarketplaceService:GetDeveloperProductsAsync(localPlayer.UserId)
        for _, product in products do
            addLog(scanPage, product.Name, product.AssetId, "DevProduct", nil)
        end
    end)
end)

print("[ProductFaker v2] Loaded — Improved scanner, bulk fix, floating mode, safe zones.")