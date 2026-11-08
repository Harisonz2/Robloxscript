-- =======================================================
-- 🏎️ RAYCITY RB - ULTIMATE HUB v7.3 (MOBILE OPTIMIZED 📱)
-- Features: UI Scaling, Purple Default, Fixed Drag Engine
-- =======================================================

local parentGui = (gethui and gethui()) or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("RaycitySpeedGui") then parentGui.RaycitySpeedGui:Destroy() end
if _G.RCSpeedDisconnect then pcall(_G.RCSpeedDisconnect) end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 🧊 DYNAMIC THEME CONFIG (เปลี่ยนค่าเริ่มต้นตามที่ขอ)
local THEME_CONFIG = {
    showHud = true,
    uiColor = Color3.fromRGB(180, 100, 255), -- สีม่วง (Purple)
    pillColor = Color3.fromRGB(180, 100, 255), -- สีม่วง (Purple)
    opacity = 30,  -- ความทึบเริ่มต้น 30%
    darkness = 20, -- ความมืดเริ่มต้น 20%
    uiScale = 85   -- ขนาดหน้าต่างเริ่มต้น 85% ให้พอดีกับจอมือถือ
}

local THEME = {
    GLASS_BG = Color3.fromRGB(255, 255, 255),
    GLASS_TRANS = 1 - (THEME_CONFIG.opacity / 100), 
    GLASS_CARD = (1 - (THEME_CONFIG.opacity / 100)) + 0.1,  
    STROKE_LIGHT = Color3.fromRGB(255, 255, 255),
    STROKE_DARK = Color3.fromRGB(150, 200, 255),
    TEXT_MAIN = Color3.fromRGB(255, 255, 255), 
    TEXT_SUB = Color3.fromRGB(200, 215, 230),
    ON_BG = THEME_CONFIG.uiColor,
    OFF_BG = Color3.fromRGB(255, 80, 100),
    ACCENT = THEME_CONFIG.uiColor
}

local THEME_UPDATES = {}

-- ปิด ไนโตร (infiniteSP) เป็นค่าเริ่มต้น
local config = { speedEnabled = true, ghostNpc = true, infiniteJump = true, antiAfk = true, vmaxKmh = 300, accelRate = 1.0, infiniteSP = false }
local stockValues = { vmax = 100, torqueBonus = 0, btPower = 2.6, btDuration = 3.5, btNeedSP = 50 }

-- =======================================================
-- 🎮 GAME LOGIC 
-- =======================================================
local renv = getrenv()
local rShared = renv and renv.shared
local rHooks = rShared and rShared.RCDrivePairHooks
if rHooks then
    if not renv._origTrafficHook and rHooks.traffic then renv._origTrafficHook = rHooks.traffic end
    if not renv._origMovHook and rHooks.mov then renv._origMovHook = rHooks.mov end
end

local function applyGhostMode(enable)
    LocalPlayer:SetAttribute("RaycityGM", true)
    LocalPlayer:SetAttribute("GmCheatOn", true)
    LocalPlayer:SetAttribute("GmCheatGhost", enable)
    if rHooks then
        if enable then
            rHooks.traffic = function() return nil end
            rHooks.mov = function() return nil end
        else
            if renv._origTrafficHook then rHooks.traffic = renv._origTrafficHook end
            if renv._origMovHook then rHooks.mov = renv._origMovHook end
        end
    end
    local trafficCars = workspace:FindFirstChild("RBRCTrafficCars")
    if trafficCars then
        for _, car in ipairs(trafficCars:GetChildren()) do
            for _, part in ipairs(car:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end
applyGhostMode(config.ghostNpc)

local afkConn, afkLoopActive = nil, true
if LocalPlayer.Idled then
    afkConn = LocalPlayer.Idled:Connect(function()
        if config.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(100, 100)) end
    end)
end
task.spawn(function()
    while afkLoopActive do
        task.wait(60)
        if config.antiAfk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(50, 50)) end) end
    end
end)

local activePhys = nil
local function getPhysics()
    if activePhys and activePhys.p and activePhys.wheels then return activePhys end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "wheels") and rawget(v, "p") and rawget(v, "rpm") then
            activePhys = v
            if v.p then
                stockValues.vmax = v.p.vmax or 100; stockValues.btPower = v.p.btPower or 2.6
                stockValues.btDuration = v.p.btDuration or 3.5; stockValues.btNeedSP = v.p.btNeedSP or 50
            end
            return activePhys
        end
    end
    return nil
end
getPhysics()

local jumpReqConn = UserInputService.JumpRequest:Connect(function()
    if config.infiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and not hum.Sit then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
local jumpKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Space and config.infiniteJump then
        local car = workspace:FindFirstChild("MyCar")
        local root = car and (car:FindFirstChild("Root") or car:FindFirstChild("Hull"))
        local phys = getPhysics()
        if root and phys then
            phys.jumpPending = false
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 45, root.AssemblyLinearVelocity.Z)
            if phys.v then phys.v = Vector3.new(phys.v.X, 22.5, phys.v.Z) end
        end
    end
end)

-- =======================================================
-- 🧊 UI UTILITIES & THEME ENGINE
-- =======================================================
local function addTextStroke(label, transparency)
    local tStroke = Instance.new("UIStroke", label)
    tStroke.Color = Color3.fromRGB(0, 0, 0)
    tStroke.Transparency = transparency or 0.6
    tStroke.Thickness = 1.2
end

local function applyGlassStyle(guiObject, radius, transOffset, isPill)
    Instance.new("UICorner", guiObject).CornerRadius = UDim.new(0, radius)
    local stroke = Instance.new("UIStroke", guiObject)
    stroke.Thickness = 1.2; stroke.Transparency = 0.3
    local grad = Instance.new("UIGradient", stroke)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.STROKE_LIGHT),
        ColorSequenceKeypoint.new(0.5, THEME.STROKE_DARK),
        ColorSequenceKeypoint.new(1, THEME.STROKE_LIGHT)
    })
    grad.Rotation = 45

    table.insert(THEME_UPDATES, function()
        if isPill then
            guiObject.BackgroundColor3 = THEME_CONFIG.pillColor
            guiObject.BackgroundTransparency = THEME.GLASS_TRANS
        else
            guiObject.BackgroundColor3 = THEME.GLASS_BG
            guiObject.BackgroundTransparency = math.clamp(THEME.GLASS_TRANS + (transOffset or 0), 0, 1)
        end
    end)
    return stroke
end

-- =======================================================
-- 🪟 MAIN UI CONSTRUCTION & SCALING
-- =======================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RaycitySpeedGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- 1. HUD BANNER
local HudBanner = Instance.new("Frame")
HudBanner.AutomaticSize = Enum.AutomaticSize.X
HudBanner.Size = UDim2.new(0, 0, 0, 34); HudBanner.Position = UDim2.new(0.5, -150, 0, 16)
HudBanner.Active = true; HudBanner.Parent = ScreenGui
local HudScale = Instance.new("UIScale", HudBanner)
applyGlassStyle(HudBanner, 17, 0)

local BannerPadding = Instance.new("UIPadding")
BannerPadding.PaddingLeft, BannerPadding.PaddingRight = UDim.new(0, 20), UDim.new(0, 20); BannerPadding.Parent = HudBanner
local BannerLabel = Instance.new("TextLabel")
BannerLabel.AutomaticSize = Enum.AutomaticSize.X
BannerLabel.Size = UDim2.new(0, 0, 1, 0); BannerLabel.BackgroundTransparency = 1
BannerLabel.Text = "🏎️ SPEED: 300km/h (x1.0) | 👻 GHOST: ON | 🦘 JUMP: ON"
BannerLabel.TextColor3 = THEME.TEXT_MAIN
BannerLabel.Font = Enum.Font.GothamBlack; BannerLabel.TextSize = 11; BannerLabel.Parent = HudBanner
addTextStroke(BannerLabel, 0.4)

table.insert(THEME_UPDATES, function() HudBanner.Visible = THEME_CONFIG.showHud end)

-- 2. FLOATING PILL (RayTools)
local FloatingPill = Instance.new("TextButton")
FloatingPill.Size = UDim2.new(0, 140, 0, 42); FloatingPill.Position = UDim2.new(0.02, 0, 0.25, 0)
FloatingPill.Text = "🧊 RayTools"
FloatingPill.TextColor3 = THEME.TEXT_MAIN
FloatingPill.Font = Enum.Font.GothamBlack; FloatingPill.TextSize = 13
FloatingPill.Active = true; FloatingPill.Parent = ScreenGui
local PillScale = Instance.new("UIScale", FloatingPill)
applyGlassStyle(FloatingPill, 21, 0, true)
addTextStroke(FloatingPill, 0.5)

-- 3. MAIN FRAME (ย่อขนาดเริ่มต้นให้เหมาะกับมือถือ)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 360) -- เล็กลง เพื่อไม่ให้ล้นจอมือถือแนวนอน
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -180)
MainFrame.Active = true; MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true
local MainScale = Instance.new("UIScale", MainFrame)
applyGlassStyle(MainFrame, 16, -0.1)

local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Size = UDim2.new(0, 24, 0, 24); ResizeGrip.Position = UDim2.new(1, -24, 1, -24)
ResizeGrip.Text = "◢"; ResizeGrip.ZIndex = 10
ResizeGrip.BackgroundTransparency = 1; ResizeGrip.TextColor3 = Color3.fromRGB(200, 200, 200)
ResizeGrip.Font = Enum.Font.GothamBlack; ResizeGrip.TextSize = 16; ResizeGrip.Parent = MainFrame

-- 4. TOPBAR & TITLE
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50); TopBar.BackgroundTransparency = 1; TopBar.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -120, 1, 0); TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "🧊 RayTools By Phumipad"
TitleLabel.TextColor3 = THEME.TEXT_MAIN
TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.Parent = TopBar
addTextStroke(TitleLabel, 0.4)

local function createWinBtn(xOffset, text, isCloseBtn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30); btn.Position = UDim2.new(1, xOffset, 0, 10)
    btn.Text = text; btn.Font = Enum.Font.GothamBlack; btn.TextSize = 14; btn.Parent = TopBar
    btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn); stroke.Thickness = 1; stroke.Transparency = 0.4
    
    table.insert(THEME_UPDATES, function()
        btn.BackgroundColor3 = isCloseBtn and THEME.OFF_BG or THEME.GLASS_BG
        btn.BackgroundTransparency = isCloseBtn and 0.4 or THEME.GLASS_TRANS + 0.1
        btn.TextColor3 = isCloseBtn and Color3.fromRGB(255,255,255) or THEME.TEXT_MAIN
    end)
    return btn
end
local SetBtn = createWinBtn(-112, "⚙️", false)
local MinBtn = createWinBtn(-76, "—", false)
local CloseBtn = createWinBtn(-40, "✕", true)

-- 5. SCROLLING CONTAINERS
local function createScrollContainer(name, isVisible)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name; scroll.Size = UDim2.new(1, -20, 1, -112); scroll.Position = UDim2.new(0, 10, 0, 55)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = Color3.fromRGB(255,255,255)
    scroll.BorderSizePixel = 0; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Visible = isVisible; scroll.Parent = MainFrame
    Instance.new("UIListLayout", scroll).SortOrder = Enum.SortOrder.LayoutOrder; scroll.UIListLayout.Padding = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", scroll); pad.PaddingLeft = UDim.new(0, 2); pad.PaddingRight = UDim.new(0, 6)
    return scroll
end

local Container = createScrollContainer("Container", true)
local SettingsFrame = createScrollContainer("SettingsFrame", false)

-- =======================================================
-- 🪟 COMPONENTS BUILDER
-- =======================================================
local function createToggleRow(parent, order, icon, title, initialVal, onClick)
    local card = Instance.new("Frame")
    card.LayoutOrder = order; card.Size = UDim2.new(1, 0, 0, 44); card.Parent = parent
    applyGlassStyle(card, 12, 0.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0); label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1; label.Text = icon .. "  " .. title
    label.TextColor3 = THEME.TEXT_MAIN; label.Font = Enum.Font.GothamBlack
    label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = card
    addTextStroke(label, 0.5)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 26); toggleBtn.Position = UDim2.new(1, -74, 0.5, -13)
    toggleBtn.Text = initialVal and "ON" or "OFF"; toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBlack; toggleBtn.TextSize = 11; toggleBtn.Parent = card
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0); addTextStroke(toggleBtn, 0.5)

    table.insert(THEME_UPDATES, function()
        local state = onClick(true)
        toggleBtn.BackgroundColor3 = state and THEME.ON_BG or THEME.OFF_BG
        toggleBtn.BackgroundTransparency = 0.4
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        local state = onClick(false)
        toggleBtn.Text = state and "ON" or "OFF"
        for _, func in ipairs(THEME_UPDATES) do pcall(func) end
    end)
end

local function createInputSection(parent, order, icon, title, confKey, presets, stepVal, secHeight, formatStr)
    local sec = Instance.new("Frame")
    sec.LayoutOrder = order; sec.Size = UDim2.new(1, 0, 0, secHeight); sec.Parent = parent
    applyGlassStyle(sec, 12, 0.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 22); label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3 = THEME.TEXT_MAIN; label.Font = Enum.Font.GothamBlack
    label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = sec
    addTextStroke(label, 0.5)

    local btnTable = {}
    local cols = #presets == 4 and 4 or 3
    local width = cols == 4 and 0.22 or 0.3
    for i, p in ipairs(presets) do
        local b = Instance.new("TextButton")
        local r, c = math.floor((i - 1) / cols), (i - 1) % cols
        b.Size = UDim2.new(width, 0, 0, 24); b.Position = UDim2.new(c * (width + 0.02) + 0.03, 0, 0, 32 + r * 28)
        b.Text = p[1]; b.Font = Enum.Font.GothamMedium; b.TextSize = 11; b.Parent = sec
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        table.insert(btnTable, {btn = b, val = p[2]})
    end

    local bottomY = secHeight - 34
    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0, 32, 0, 26); minusBtn.Position = UDim2.new(0, 12, 0, bottomY); minusBtn.Text = "-"
    minusBtn.TextColor3 = THEME.TEXT_MAIN; minusBtn.Font = Enum.Font.GothamBlack; minusBtn.TextSize = 16; minusBtn.Parent = sec
    applyGlassStyle(minusBtn, 6, 0.8); addTextStroke(minusBtn, 0.5)

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0, 32, 0, 26); plusBtn.Position = UDim2.new(1, -44, 0, bottomY); plusBtn.Text = "+"
    plusBtn.TextColor3 = THEME.TEXT_MAIN; plusBtn.Font = Enum.Font.GothamBlack; plusBtn.TextSize = 16; plusBtn.Parent = sec
    applyGlassStyle(plusBtn, 6, 0.8); addTextStroke(plusBtn, 0.5)

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -112, 0, 26); inputBox.Position = UDim2.new(0, 50, 0, bottomY)
    inputBox.PlaceholderText = "ระบุค่า..."; inputBox.TextColor3 = THEME.TEXT_MAIN; inputBox.Font = Enum.Font.GothamMedium
    inputBox.TextSize = 11; inputBox.Parent = sec
    applyGlassStyle(inputBox, 6, 0.8); addTextStroke(inputBox, 0.7)

    table.insert(THEME_UPDATES, function()
        label.Text = icon .. " " .. title .. ": " .. string.format(formatStr, config[confKey])
        inputBox.Text = tostring(config[confKey])
        for _, item in ipairs(btnTable) do
            local active = (item.val == config[confKey])
            item.btn.BackgroundColor3 = THEME.ACCENT 
            item.btn.BackgroundTransparency = active and 0.3 or 0.8
            item.btn.TextColor3 = active and Color3.fromRGB(255,255,255) or THEME.TEXT_SUB
        end
    end)

    local function updateValue(val)
        val = (stepVal == 0.1) and (math.floor(val * 10 + 0.5) / 10) or math.floor(val)
        if val < 0 then val = 0 end
        config[confKey] = val
        for _, func in ipairs(THEME_UPDATES) do pcall(func) end
    end

    minusBtn.MouseButton1Click:Connect(function() updateValue(config[confKey] - stepVal) end)
    plusBtn.MouseButton1Click:Connect(function() updateValue(config[confKey] + stepVal) end)
    for _, item in ipairs(btnTable) do item.btn.MouseButton1Click:Connect(function() updateValue(item.val) end) end
    
    inputBox.FocusLost:Connect(function()
        local val = tonumber(string.match(inputBox.Text, "%-?%d+%.?%d*"))
        if val and val > 0 then updateValue(val) else for _, func in ipairs(THEME_UPDATES) do pcall(func) end end
    end)
end

-- =======================================================
-- ⚙️ SETTINGS UI BUILDER 
-- =======================================================
local PRESET_COLORS = {
    Color3.fromRGB(0, 220, 255),   -- Cyan
    Color3.fromRGB(255, 100, 150), -- Pink
    Color3.fromRGB(0, 255, 120),   -- Mint
    Color3.fromRGB(180, 100, 255), -- Purple
    Color3.fromRGB(255, 200, 50),  -- Yellow
    Color3.fromRGB(255, 80, 80),   -- Red
    Color3.fromRGB(255, 255, 255), -- White
    Color3.fromRGB(40, 40, 40)     -- Dark
}

local function SyncTheme()
    local dFac = 1 - (THEME_CONFIG.darkness / 100)
    THEME.GLASS_BG = Color3.fromRGB(255 * dFac, 255 * dFac, 255 * dFac)
    THEME.GLASS_TRANS = 1 - (THEME_CONFIG.opacity / 100)
    THEME.ACCENT = THEME_CONFIG.uiColor
    THEME.ON_BG = THEME_CONFIG.uiColor
    MainScale.Scale = THEME_CONFIG.uiScale / 100
    PillScale.Scale = THEME_CONFIG.uiScale / 100
    HudScale.Scale = THEME_CONFIG.uiScale / 100
    for _, func in ipairs(THEME_UPDATES) do pcall(func) end
end

local function createSettingsColorPalette(order, icon, title, confKey)
    local card = Instance.new("Frame")
    card.LayoutOrder = order; card.Size = UDim2.new(1, 0, 0, 44); card.Parent = SettingsFrame
    applyGlassStyle(card, 12, 0.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 140, 1, 0); label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1; label.Text = icon .. "  " .. title
    label.TextColor3 = THEME.TEXT_MAIN; label.Font = Enum.Font.GothamBlack; label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = card
    addTextStroke(label, 0.5)

    local colorContainer = Instance.new("Frame")
    colorContainer.Size = UDim2.new(1, -160, 1, -14); colorContainer.Position = UDim2.new(0, 150, 0.5, -15)
    colorContainer.BackgroundTransparency = 1; colorContainer.Parent = card

    local layout = Instance.new("UIListLayout", colorContainer)
    layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 6)

    for _, col in ipairs(PRESET_COLORS) do
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0, 24, 0, 24); cBtn.BackgroundColor3 = col; cBtn.Text = ""; cBtn.Parent = colorContainer
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", cBtn); stroke.Thickness = 1.5

        table.insert(THEME_UPDATES, function()
            if THEME_CONFIG[confKey] == col then stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Transparency = 0
            else stroke.Color = Color3.fromRGB(0, 0, 0); stroke.Transparency = 0.5 end
        end)
        cBtn.MouseButton1Click:Connect(function() THEME_CONFIG[confKey] = col; SyncTheme() end)
    end
end

local function createSettingsStepper(order, icon, title, confKey, step, min, max, formatStr)
    local card = Instance.new("Frame")
    card.LayoutOrder = order; card.Size = UDim2.new(1, 0, 0, 44); card.Parent = SettingsFrame
    applyGlassStyle(card, 12, 0.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 160, 1, 0); label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1; label.Text = icon .. "  " .. title
    label.TextColor3 = THEME.TEXT_MAIN; label.Font = Enum.Font.GothamBlack; label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = card
    addTextStroke(label, 0.5)

    local mBtn = Instance.new("TextButton")
    mBtn.Size = UDim2.new(0, 26, 0, 26); mBtn.Position = UDim2.new(1, -110, 0.5, -13); mBtn.Text = "-"; mBtn.Parent = card
    mBtn.TextColor3 = THEME.TEXT_MAIN; mBtn.Font = Enum.Font.GothamBlack; mBtn.TextSize = 14
    applyGlassStyle(mBtn, 6, 0.8)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 44, 0, 26); valLabel.Position = UDim2.new(1, -80, 0.5, -13)
    valLabel.BackgroundTransparency = 1; valLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    valLabel.Font = Enum.Font.GothamBlack; valLabel.TextSize = 12; valLabel.Parent = card
    local stroke = Instance.new("UIStroke", valLabel); stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 1.2

    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 26, 0, 26); pBtn.Position = UDim2.new(1, -32, 0.5, -13); pBtn.Text = "+"; pBtn.Parent = card
    pBtn.TextColor3 = THEME.TEXT_MAIN; pBtn.Font = Enum.Font.GothamBlack; pBtn.TextSize = 14
    applyGlassStyle(pBtn, 6, 0.8)

    table.insert(THEME_UPDATES, function() valLabel.Text = string.format(formatStr, THEME_CONFIG[confKey]) end)

    local function apply(diff) THEME_CONFIG[confKey] = math.clamp(THEME_CONFIG[confKey] + diff, min, max); SyncTheme() end
    mBtn.MouseButton1Click:Connect(function() apply(-step) end)
    pBtn.MouseButton1Click:Connect(function() apply(step) end)
end

-- เพิ่ม Preset ปุ่มสำหรับปรับขนาด UI Scale (25%, 50%, 75%, 100%)
local function createSettingsScalePresets(order, icon, title, confKey, presets)
    local card = Instance.new("Frame")
    card.LayoutOrder = order; card.Size = UDim2.new(1, 0, 0, 72); card.Parent = SettingsFrame
    applyGlassStyle(card, 12, 0.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 22); label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1; label.TextColor3 = THEME.TEXT_MAIN
    label.Font = Enum.Font.GothamBlack; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = card
    addTextStroke(label, 0.5)

    local btnTable = {}
    local cols = #presets; local width = (1 / cols) - 0.04
    for i, p in ipairs(presets) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(width, 0, 0, 24); b.Position = UDim2.new((i - 1) * (width + 0.02) + 0.03, 0, 0, 36)
        b.Text = p[1]; b.Font = Enum.Font.GothamMedium; b.TextSize = 11; b.Parent = card
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        table.insert(btnTable, {btn = b, val = p[2]})
        b.MouseButton1Click:Connect(function() THEME_CONFIG[confKey] = p[2]; SyncTheme() end)
    end

    table.insert(THEME_UPDATES, function()
        label.Text = icon .. " " .. title .. ": " .. THEME_CONFIG[confKey] .. "%"
        for _, item in ipairs(btnTable) do
            local active = (item.val == THEME_CONFIG[confKey])
            item.btn.BackgroundColor3 = THEME.ACCENT
            item.btn.BackgroundTransparency = active and 0.3 or 0.8
            item.btn.TextColor3 = active and Color3.fromRGB(255,255,255) or THEME.TEXT_SUB
        end
    end)
end

-- 📌 POPULATE MAIN MENU
createToggleRow(Container, 1, "⚡", "สปีดแฮก (Speed Boost)", config.speedEnabled, function(check) if not check then config.speedEnabled = not config.speedEnabled end; return config.speedEnabled end)
createToggleRow(Container, 2, "👻", "ทะลุรถ (Ghost Mode)", config.ghostNpc, function(check) if not check then config.ghostNpc = not config.ghostNpc; applyGhostMode(config.ghostNpc) end; return config.ghostNpc end)
createToggleRow(Container, 3, "🦘", "กระโดด (Infinite Jump)", config.infiniteJump, function(check) if not check then config.infiniteJump = not config.infiniteJump end; return config.infiniteJump end)
createToggleRow(Container, 4, "✨", "ไนโตร (Infinite SP)", config.infiniteSP, function(check) if not check then config.infiniteSP = not config.infiniteSP end; return config.infiniteSP end)
createInputSection(Container, 5, "🏁", "ความเร็ว (VMAX)", "vmaxKmh", {{"300", 300}, {"450", 450}, {"600", 600}, {"1200", 1200}}, 50, 102, "%d km/h")
createInputSection(Container, 6, "🚀", "อัตราเร่ง (Accel)", "accelRate", {{"x0.5", 0.5}, {"x1.0", 1.0}, {"x2.5", 2.5}, {"x4.0", 4.0}, {"x8.0", 8.0}, {"x12.0", 12.0}}, 0.1, 130, "x%.1f")

-- 📌 POPULATE SETTINGS MENU
createToggleRow(SettingsFrame, 1, "👁️", "แสดงสถานะ HUD ด้านบน", THEME_CONFIG.showHud, function(check) if not check then THEME_CONFIG.showHud = not THEME_CONFIG.showHud end; return THEME_CONFIG.showHud end)
createSettingsScalePresets(2, "🔍", "ขนาด UI (Panel Size)", "uiScale", {{"25%", 25}, {"50%", 50}, {"75%", 75}, {"100%", 100}})
createSettingsColorPalette(3, "🎨", "สีธีมหลัก (Theme)", "uiColor") 
createSettingsColorPalette(4, "💊", "สีปุ่ม (RayTools)", "pillColor") 
createSettingsStepper(5, "🪟", "ความทึบพาเนล (Opacity)", "opacity", 10, 10, 100, "%d%%")
createSettingsStepper(6, "🌙", "ความมืดพาเนล (Darkness)", "darkness", 10, 0, 100, "%d%%")

-- 6. STATUS DASHBOARD
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -30, 0, 36); StatusBox.Position = UDim2.new(0, 15, 1, -46)
StatusBox.Parent = MainFrame
applyGlassStyle(StatusBox, 10, 0.1)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 1, 0); StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "ความเร็ว: 0 km/h | กด Spacebar เพื่อกระโดด"
StatusLabel.TextColor3 = THEME.TEXT_MAIN; StatusLabel.Font = Enum.Font.GothamBlack
StatusLabel.TextSize = 11; StatusLabel.Parent = StatusBox
addTextStroke(StatusLabel, 0.5)

-- =======================================================
-- 🖱️ INTERACTION & PHYSICS LOOP (Fixed for UIScale Dragging)
-- =======================================================
local function makeDraggable(handle, target, scaleObj)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = target.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local currentScale = scaleObj and scaleObj.Scale or 1
            local delta = input.Position - dragStart
            -- แก้บัคเวลา Scale ลดลง แล้วเมาส์ลากไม่ตรงกับจอ (คำนวณผ่าน Scale factor)
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (delta.X / currentScale), startPos.Y.Scale, startPos.Y.Offset + (delta.Y / currentScale))
        end
    end)
end

makeDraggable(TopBar, MainFrame, MainScale)
makeDraggable(HudBanner, HudBanner, HudScale)
makeDraggable(FloatingPill, FloatingPill, PillScale)

-- แก้บัคลากย่อขยายคู่กับ UIScale
local resDrag, resStart, frameStart = false, nil, nil
ResizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        resDrag = true; resStart = input.Position; frameStart = MainFrame.Size 
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resStart
        local cScale = MainScale.Scale
        MainFrame.Size = UDim2.new(0, math.max(340, frameStart.X.Offset + (delta.X / cScale)), 0, math.max(260, frameStart.Y.Offset + (delta.Y / cScale)))
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resDrag = false end
end)

local isVisible = true
MinBtn.MouseButton1Click:Connect(function() isVisible = false; MainFrame.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() isVisible = false; MainFrame.Visible = false end)
FloatingPill.MouseButton1Click:Connect(function() isVisible = not isVisible; MainFrame.Visible = isVisible end)
SetBtn.MouseButton1Click:Connect(function() 
    SettingsFrame.Visible = not SettingsFrame.Visible
    Container.Visible = not SettingsFrame.Visible
    SetBtn.BackgroundColor3 = SettingsFrame.Visible and THEME.ACCENT or THEME.GLASS_BG
end)

local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(function(dt)
    if not ScreenGui or not ScreenGui.Parent then if heartbeatConn then heartbeatConn:Disconnect() end; return end
    
    local sTag = config.speedEnabled and string.format("%dkm/h", config.vmaxKmh) or "OFF"
    BannerLabel.Text = string.format("🏎️ SPEED: %s (x%.1f) | 👻 GHOST: %s | 🦘 JUMP: %s", sTag, config.accelRate, config.ghostNpc and "ON" or "OFF", config.infiniteJump and "ON" or "OFF")

    if config.ghostNpc then applyGhostMode(true) end
    local phys = getPhysics()
    local car = workspace:FindFirstChild("MyCar")
    local root = car and (car:FindFirstChild("Root") or car:FindFirstChild("Hull"))
    
    if not phys or not phys.p or not root then
        StatusLabel.Text = "กำลังรอข้อมูลรถ... (กรุณาขึ้นขับรถ)"
        return
    end

    local currentKmh = phys.v and (phys.v.Magnitude * 3.6) or 0
    if config.speedEnabled then
        phys.p.vmax = config.vmaxKmh / 3.6
        phys.torqueBonus = 500; phys.p.btPower = 8.0
        if config.infiniteSP then phys.p.btNeedSP = 1; phys.p.btDuration = 10 end

        local isAccelerating = (phys.throttle and phys.throttle > 0) or UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
        local isBraking = (phys.brake and phys.brake > 0) or UserInputService:IsKeyDown(Enum.KeyCode.S)
        
        if isAccelerating and not isBraking and currentKmh < config.vmaxKmh then
            phys.v = phys.v + root.CFrame.LookVector * (config.accelRate * 25.0 * dt)
            root.AssemblyLinearVelocity = phys.v * 2
        end
    else
        if phys.p.vmax ~= stockValues.vmax then
            phys.p.vmax = stockValues.vmax; phys.torqueBonus = 0
            phys.p.btPower = stockValues.btPower; phys.p.btDuration = stockValues.btDuration
            phys.p.btNeedSP = stockValues.btNeedSP
        end
    end
    StatusLabel.Text = string.format("🧊 ความเร็ว: %d km/h | เกียร์: %s | RPM: %d", math.floor(currentKmh), tostring(phys.gear or 0), math.floor(phys.rpm or 0))
end)

_G.RCSpeedDisconnect = function()
    if heartbeatConn then heartbeatConn:Disconnect() end
    if afkConn then afkConn:Disconnect() end
    if jumpReqConn then jumpReqConn:Disconnect() end
    if jumpKeyConn then jumpKeyConn:Disconnect() end
    afkLoopActive = false; applyGhostMode(false)
end

-- อัปเดตสีและขนาดครั้งแรกเมื่อรัน
SyncTheme()

print("[Raycity Hub v7.3] 📱 Mobile Scalable Edition Loaded!")
return true
