local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== STATE ==================
local state = {
	ui = nil,
	frame = nil,

	-- Speed & Movement
	speedEnabled = false,
	speedValue = 16,
	baseWalkSpeed = 16,

	tpWalkEnabled = false,
	tpWalkSpeed = 2,

	-- Toggles
	instantInteract = false,
	infiniteJump = false,
	godMode = false,
	noclip = false,
	antiRagdoll = false,
	fullBright = false,
	esp = false,
	fpsBooster = false,

	baseMaxHealth = 100,

	-- Runtime connections
	_noclipConn = nil,
	_antiRDConns = {},
	_fbConn = nil,
	_espConns = {},
	_tpWalkConn = nil,
	_fpsConn = nil,

	-- FullBright & Positions
	fbBackup = nil,
	savedPosition1 = nil,
	savedPosition2 = nil
}

local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ================== CORE LOGIC ==================
local function applyGodMode(on)
	if not humanoid then return end
	if on then
		if not state.baseMaxHealth or state.baseMaxHealth == 0 then
			state.baseMaxHealth = humanoid.MaxHealth
		end
		humanoid.MaxHealth = math.huge
		humanoid.Health    = math.huge
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.BreakJointsOnDeath = false
	else
		local base = (state.baseMaxHealth and state.baseMaxHealth > 0) and state.baseMaxHealth or 100
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		humanoid.BreakJointsOnDeath = true
		humanoid.MaxHealth = base
		humanoid.Health    = base
	end
end

local function applyNoclip(on)
	if state._noclipConn then
		state._noclipConn:Disconnect()
		state._noclipConn = nil
	end
	if on then
		state._noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	end
end

local function applyTPWalk(on)
	if state._tpWalkConn then
		state._tpWalkConn:Disconnect()
		state._tpWalkConn = nil
	end
	if on then
		state._tpWalkConn = RunService.Heartbeat:Connect(function(delta)
			if state.tpWalkEnabled and humanoid and hrp and humanoid.Health > 0 then
				if humanoid.MoveDirection.Magnitude > 0 then
					local mult = tonumber(state.tpWalkSpeed) or 2
					hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (mult * 15 * delta))
				end
			end
		end)
	end
end

local function applyFPSBooster(on)
	if on then
		pcall(function()
			settings().Rendering.QualityLevel = 1
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.ShadowSoftness = 0
			for _, fx in ipairs(Lighting:GetChildren()) do
				if fx:IsA("PostEffect") or fx:IsA("BloomEffect") or fx:IsA("ColorCorrectionEffect")
					or fx:IsA("SunRaysEffect") or fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") then
					fx.Enabled = false
				end
			end
		end)

		local function potatoify(part)
			pcall(function()
				if part:IsA("BasePart") and not part.Parent:FindFirstChildOfClass("Humanoid") then
					part.Material = Enum.Material.SmoothPlastic
					part.Reflectance = 0
					part.CastShadow = false
				elseif part:IsA("Decal") or part:IsA("Texture") then
					part.Transparency = 1
				elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Smoke") or part:IsA("Fire") or part:IsA("Sparkles") then
					part.Enabled = false
				end
			end)
		end

		for _, item in ipairs(Workspace:GetDescendants()) do
			potatoify(item)
		end
		state._fpsConn = Workspace.DescendantAdded:Connect(potatoify)
	else
		if state._fpsConn then
			state._fpsConn:Disconnect()
			state._fpsConn = nil
		end
		pcall(function()
			Lighting.GlobalShadows = true
			for _, fx in ipairs(Lighting:GetChildren()) do
				if fx:IsA("PostEffect") then
					fx.Enabled = true
				end
			end
		end)
	end
end

local function clearAntiRDConns()
	for _, c in ipairs(state._antiRDConns) do pcall(function() c:Disconnect() end) end
	state._antiRDConns = {}
end

local function handleBadState(hum, newState)
	if not hum or hum.Health <= 0 then return end
	if newState == Enum.HumanoidStateType.Ragdoll
		or newState == Enum.HumanoidStateType.FallingDown
		or newState == Enum.HumanoidStateType.PlatformStanding
		or newState == Enum.HumanoidStateType.Seated then
		hum.Sit = false
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		local root = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
		if root then root.Anchored = false end
	end
end

local function applyAntiRagdoll(on)
	clearAntiRDConns()
	if not on then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	handleBadState(hum, hum:GetState())
	table.insert(state._antiRDConns, hum.StateChanged:Connect(function(_, newState)
		handleBadState(hum, newState)
	end))
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("Seat") then
			table.insert(state._antiRDConns, d:GetPropertyChangedSignal("Occupant"):Connect(function()
				if d.Occupant == hum then
					task.wait(0.05)
					hum.Sit = false
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end))
		end
	end
	table.insert(state._antiRDConns, hum.Died:Connect(function() clearAntiRDConns() end))
end

local function _setFullBrightColors()
	Lighting.Ambient = Color3.new(1,1,1)
	Lighting.ColorShift_Bottom = Color3.new(1,1,1)
	Lighting.ColorShift_Top = Color3.new(1,1,1)
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

local function applyFullBright(on)
	if not state.fbBackup then
		state.fbBackup = {
			Ambient = Lighting.Ambient,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			ColorShift_Top = Lighting.ColorShift_Top,
			Brightness = Lighting.Brightness,
			OutdoorAmbient = Lighting.OutdoorAmbient
		}
	end
	if state._fbConn then state._fbConn:Disconnect(); state._fbConn = nil end

	if on then
		_setFullBrightColors()
		state._fbConn = Lighting.Changed:Connect(function()
			if state.fullBright then _setFullBrightColors() end
		end)
	else
		local b = state.fbBackup
		if b then
			Lighting.Ambient = b.Ambient
			Lighting.ColorShift_Bottom = b.ColorShift_Bottom
			Lighting.ColorShift_Top = b.ColorShift_Top
			Lighting.Brightness = b.Brightness
			Lighting.OutdoorAmbient = b.OutdoorAmbient
		end
	end
end

local function createESP(plr)
	if plr == player then return end
	local function addESPToChar(char)
		pcall(function()
			if char:FindFirstChild("ESPBox") then return end
			local root = char:WaitForChild("HumanoidRootPart", 5)
			if not root then return end

			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESPBox"
			box.Size = root.Size * 1.2
			box.Color3 = Color3.fromRGB(255, 75, 75)
			box.Transparency = 0.65
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Adornee = root
			box.Parent = root

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "ESPName"
			billboard.Adornee = char:WaitForChild("Head", 5)
			billboard.Size = UDim2.new(0, 160, 0, 30)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = char:WaitForChild("Head", 5)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = plr.DisplayName or plr.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextStrokeTransparency = 0.6
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 12
			nameLabel.Parent = billboard
		end)
	end

	if plr.Character then addESPToChar(plr.Character) end
	local conn = plr.CharacterAdded:Connect(function(char)
		if state.esp then addESPToChar(char) end
	end)
	table.insert(state._espConns, conn)
end

local function removeESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			pcall(function()
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root and root:FindFirstChild("ESPBox") then root.ESPBox:Destroy() end
				local head = plr.Character:FindFirstChild("Head")
				if head and head:FindFirstChild("ESPName") then head.ESPName:Destroy() end
			end)
		end
	end
end

local function applyESP(on)
	for _, conn in ipairs(state._espConns) do pcall(function() conn:Disconnect() end) end
	state._espConns = {}
	if on then
		for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
		table.insert(state._espConns, Players.PlayerAdded:Connect(function(plr)
			if state.esp then createESP(plr) end
		end))
	else
		removeESP()
	end
end

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	hrp       = char:WaitForChild("HumanoidRootPart")

	state.baseWalkSpeed = humanoid.WalkSpeed
	state.baseMaxHealth = humanoid.MaxHealth

	if state.speedEnabled  then humanoid.WalkSpeed = tonumber(state.speedValue) or 16 end
	if state.tpWalkEnabled then applyTPWalk(true) end
	if state.godMode       then applyGodMode(true) end
	if state.noclip        then applyNoclip(true) end
	if state.antiRagdoll   then applyAntiRagdoll(true) end
	if state.fullBright    then applyFullBright(true) end
end)

-- ================== MODERN MINIMAL UI ==================
local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadMinimalToolbox"
sg.ResetOnSpawn = false
sg.Parent = playerGui

-- Main Window
local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 250, 0, 380)
f.Position = UDim2.new(0.04, 0, 0.45, -190)
f.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
f.BorderSizePixel = 0
f.Active = true
f.ClipsDescendants = true
f.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = f

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 48, 60)
stroke.Thickness = 1
stroke.Parent = f

-- Top Bar
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = bar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Phumipad  •  v2.5"
title.TextColor3 = Color3.fromRGB(230, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 22, 0, 22)
miniBtn.Position = UDim2.new(1, -54, 0, 7)
miniBtn.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
miniBtn.BorderSizePixel = 0
miniBtn.Text = "—"
miniBtn.TextColor3 = Color3.fromRGB(180, 185, 200)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 11
miniBtn.Parent = bar
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 5)
miniCorner.Parent = miniBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 55)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = bar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Scroll Container
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, 0, 1, -36)
scroll.Position = UDim2.new(0, 0, 0, 36)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(65, 70, 90)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = f

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingBottom = UDim.new(0, 14)
scrollPadding.PaddingLeft = UDim.new(0, 10)
scrollPadding.PaddingRight = UDim.new(0, 10)
scrollPadding.Parent = scroll

-- Resize Handle (Bottom-Right Corner)
local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 14, 0, 14)
resizeGrip.Position = UDim2.new(1, -14, 1, -14)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "◢"
resizeGrip.TextColor3 = Color3.fromRGB(90, 95, 115)
resizeGrip.TextSize = 11
resizeGrip.Font = Enum.Font.GothamBold
resizeGrip.ZIndex = 50
resizeGrip.Parent = f

-- Drag Window
do
	local dragging, dragStart, startPos = false, nil, nil
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = f.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	bar.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			f.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Resize Window Logic
do
	local resizing, resizeStart, startSize = false, nil, nil
	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = f.AbsoluteSize
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then resizing = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local targetW = math.clamp(startSize.X + delta.X, 220, 500)
			local targetH = math.clamp(startSize.Y + delta.Y, 200, 700)
			f.Size = UDim2.new(0, targetW, 0, targetH)
		end
	end)
end

-- Minimize Logic
local minimized = false
local restoreSize = f.Size
miniBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		restoreSize = f.Size
		scroll.Visible = false
		resizeGrip.Visible = false
		f.Size = UDim2.new(f.Size.X.Scale, f.Size.X.Offset, 0, 36)
		miniBtn.Text = "+"
	else
		scroll.Visible = true
		resizeGrip.Visible = true
		f.Size = restoreSize
		miniBtn.Text = "—"
	end
end)

-- UI Generator Helpers
local currentOrder = 0
local function getOrder() currentOrder = currentOrder + 1; return currentOrder end

local function addCategory(name)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = name:upper()
	lbl.TextColor3 = Color3.fromRGB(100, 105, 125)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = getOrder()
	lbl.Parent = scroll
end

local function addToggleRow(name, defaultOn, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 25, 33)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = scroll

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -55, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 220, 230)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 42, 0, 20)
	btn.Position = UDim2.new(1, -48, 0.5, -10)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	local function render(v)
		btn.Text = v and "ON" or "OFF"
		btn.BackgroundColor3 = v and Color3.fromRGB(46, 175, 100) or Color3.fromRGB(45, 48, 60)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 180)
	end
	render(defaultOn)

	btn.MouseButton1Click:Connect(function()
		onClick(btn, render)
	end)
end

local function addInputToggleRow(name, defaultVal, defaultOn, onToggle, onValChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(24, 25, 33)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = scroll

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.48, 0, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 220, 230)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 38, 0, 20)
	box.Position = UDim2.new(1, -94, 0.5, -10)
	box.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(240, 240, 250)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.Parent = row

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 5)
	boxCorner.Parent = box

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 42, 0, 20)
	btn.Position = UDim2.new(1, -48, 0.5, -10)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	local function render(v)
		btn.Text = v and "ON" or "OFF"
		btn.BackgroundColor3 = v and Color3.fromRGB(46, 175, 100) or Color3.fromRGB(45, 48, 60)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 180)
	end
	render(defaultOn)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n and n >= 0 then
			onValChange(n)
		else
			box.Text = tostring(defaultVal)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		onToggle(btn, render)
	end)
end

-- ================== POPULATE ITEMS ==================

-- [1] Movement
addCategory("Movement")

addInputToggleRow("Walk Speed", state.speedValue, state.speedEnabled, function(_, render)
	state.speedEnabled = not state.speedEnabled
	render(state.speedEnabled)
	if humanoid then
		humanoid.WalkSpeed = state.speedEnabled and (tonumber(state.speedValue) or 16) or state.baseWalkSpeed
	end
end, function(val)
	state.speedValue = val
	if state.speedEnabled and humanoid then humanoid.WalkSpeed = val end
end)

addInputToggleRow("TP Walk", state.tpWalkSpeed, state.tpWalkEnabled, function(_, render)
	state.tpWalkEnabled = not state.tpWalkEnabled
	render(state.tpWalkEnabled)
	applyTPWalk(state.tpWalkEnabled)
end, function(val)
	state.tpWalkSpeed = val
end)

-- [2] Utilities
addCategory("Utilities")

addToggleRow("Instant Interact", state.instantInteract, function(_, render)
	state.instantInteract = not state.instantInteract
	render(state.instantInteract)
end)

addToggleRow("Infinite Jump", state.infiniteJump, function(_, render)
	state.infiniteJump = not state.infiniteJump
	render(state.infiniteJump)
end)

addToggleRow("God Mode", state.godMode, function(_, render)
	state.godMode = not state.godMode
	render(state.godMode)
	applyGodMode(state.godMode)
end)

addToggleRow("Noclip", state.noclip, function(_, render)
	state.noclip = not state.noclip
	render(state.noclip)
	applyNoclip(state.noclip)
end)

addToggleRow("Anti Ragdoll", state.antiRagdoll, function(_, render)
	state.antiRagdoll = not state.antiRagdoll
	render(state.antiRagdoll)
	applyAntiRagdoll(state.antiRagdoll)
end)

addToggleRow("Full Bright", state.fullBright, function(_, render)
	state.fullBright = not state.fullBright
	render(state.fullBright)
	applyFullBright(state.fullBright)
end)

addToggleRow("Player ESP", state.esp, function(_, render)
	state.esp = not state.esp
	render(state.esp)
	applyESP(state.esp)
end)

addToggleRow("Potato FPS", state.fpsBooster, function(_, render)
	state.fpsBooster = not state.fpsBooster
	render(state.fpsBooster)
	applyFPSBooster(state.fpsBooster)
end)

-- [3] Save Spots (2-Column Grid)
addCategory("Waypoints")

local spotGrid = Instance.new("Frame")
spotGrid.Size = UDim2.new(1, 0, 0, 28)
spotGrid.BackgroundTransparency = 1
spotGrid.LayoutOrder = getOrder()
spotGrid.Parent = scroll

local function makeGridSpotBtn(slot, posX, sizeX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(sizeX, -4, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	btn.BorderSizePixel = 0
	btn.Text = "📍 Spot " .. slot
	btn.TextColor3 = Color3.fromRGB(220, 225, 235)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = spotGrid

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local key = "savedPosition" .. slot
		if state[key] then
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then root.CFrame = CFrame.new(state[key]) end
			state[key] = nil
			btn.Text = "📍 Spot " .. slot
			btn.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
		else
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				state[key] = root.Position
				btn.Text = "🚀 Go " .. slot
				btn.BackgroundColor3 = Color3.fromRGB(46, 175, 100)
			end
		end
	end)
end

makeGridSpotBtn(1, 0, 0.5)
makeGridSpotBtn(2, 0.5, 0.5)

-- ================== HOOKS ==================
UserInputService.JumpRequest:Connect(function()
	if state.infiniteJump and humanoid and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if state.instantInteract then
		pcall(function() fireproximityprompt(prompt) end)
	end
end)

RunService.Heartbeat:Connect(function()
	if state.speedEnabled and humanoid then
		humanoid.WalkSpeed = tonumber(state.speedValue) or 16
	end
end)

state.baseWalkSpeed = humanoid and humanoid.WalkSpeed or 16
state.baseMaxHealth = humanoid and humanoid.MaxHealth or 100
