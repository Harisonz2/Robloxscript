local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== STATE ==================
local state = {
	ui = nil,
	frame = nil,

	-- Speed
	speedEnabled = false,
	speedValue = 16,
	baseWalkSpeed = 16,

	-- TP Walk
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

	-- runtime conns
	_noclipConn = nil,
	_antiRDConns = {},
	_fbConn = nil,
	_espConns = {},
	_tpWalkConn = nil,
	_fpsConn = nil,

	-- Full Bright backup
	fbBackup = nil,

	-- save spot
	savedPosition = nil,
	
	-- ESP
	espFolder = nil
}

local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ================== HELPERS ==================
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

-- TP Walk
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

-- FPS Booster (Potato PC)
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

-- AntiRagdoll helpers
local function clearAntiRDConns()
	for _, c in ipairs(state._antiRDConns) do
		pcall(function() c:Disconnect() end)
	end
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

	table.insert(state._antiRDConns, hum.Died:Connect(function()
		clearAntiRDConns()
	end))
end

-- Full Bright
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

	if state._fbConn then
		state._fbConn:Disconnect()
		state._fbConn = nil
	end

	if on then
		_setFullBrightColors()
		state._fbConn = Lighting.Changed:Connect(function()
			if state.fullBright then
				_setFullBrightColors()
			end
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

-- ================== ESP SYSTEM ==================
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
			box.Color3 = Color3.fromRGB(255, 0, 0)
			box.Transparency = 0.7
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Adornee = root
			box.Parent = root

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "ESPName"
			billboard.Adornee = char:WaitForChild("Head", 5)
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = char:WaitForChild("Head", 5)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = plr.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextStrokeTransparency = 0.5
			nameLabel.Font = Enum.Font.SourceSansBold
			nameLabel.TextSize = 16
			nameLabel.Parent = billboard
		end)
	end

	if plr.Character then
		addESPToChar(plr.Character)
	end
	
	local conn = plr.CharacterAdded:Connect(function(char)
		if state.esp then
			addESPToChar(char)
		end
	end)
	
	table.insert(state._espConns, conn)
end

local function removeESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			pcall(function()
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root and root:FindFirstChild("ESPBox") then
					root.ESPBox:Destroy()
				end
				local head = plr.Character:FindFirstChild("Head")
				if head and head:FindFirstChild("ESPName") then
					head.ESPName:Destroy()
				end
			end)
		end
	end
end

local function applyESP(on)
	for _, conn in ipairs(state._espConns) do
		pcall(function() conn:Disconnect() end)
	end
	state._espConns = {}
	
	if on then
		for _, plr in ipairs(Players:GetPlayers()) do
			createESP(plr)
		end
		table.insert(state._espConns, Players.PlayerAdded:Connect(function(plr)
			if state.esp then
				createESP(plr)
			end
		end))
	else
		removeESP()
	end
end

-- ================== CHARACTER REFRESH ==================
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	hrp       = char:WaitForChild("HumanoidRootPart")

	state.baseWalkSpeed = humanoid.WalkSpeed
	state.baseMaxHealth = humanoid.MaxHealth

	if state.speedEnabled then
		humanoid.WalkSpeed = tonumber(state.speedValue) or 16
	end
	if state.tpWalkEnabled then applyTPWalk(true) end
	if state.godMode      then applyGodMode(true) end
	if state.noclip       then applyNoclip(true) end
	if state.antiRagdoll  then applyAntiRagdoll(true) end
	if state.fullBright   then applyFullBright(true) end
end)

-- ================== UI BUILDERS ==================
local function makeScreenGui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "PhumipadToolboxGui"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui
	return sg
end

local function makeFrame(parent)
	local FRAME_HEIGHT = 440 
    
	local f = Instance.new("Frame")
	f.Name = "Container"
	f.Size = UDim2.new(0, 240, 0, FRAME_HEIGHT)
	f.Position = UDim2.new(0.03, 0, 0.5, -FRAME_HEIGHT / 2)
	f.BackgroundColor3 = Color3.fromRGB(25,25,30)
	f.BorderSizePixel = 0
	f.Active = true
	f.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = f

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = f

	-- Title bar
	local bar = Instance.new("Frame")
	bar.Name = "TitleBar"
	bar.Size = UDim2.new(1, -20, 0, 32)
	bar.Position = UDim2.new(0, 10, 0, 8)
	bar.BackgroundColor3 = Color3.fromRGB(35,35,42)
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = f

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = bar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.new(0, 8, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "⚡ Phumipad Toolbox"
	title.TextColor3 = Color3.fromRGB(100,200,255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13 
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bar

	local miniBtn = Instance.new("TextButton")
	miniBtn.Size = UDim2.new(0, 26, 0, 24)
	miniBtn.Position = UDim2.new(1, -62, 0, 4)
	miniBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
	miniBtn.BorderSizePixel = 0
	miniBtn.Text = "−"
	miniBtn.TextColor3 = Color3.fromRGB(255,255,255)
	miniBtn.Font = Enum.Font.GothamBold
	miniBtn.TextSize = 18
	miniBtn.Parent = bar

	local miniBtnCorner = Instance.new("UICorner")
	miniBtnCorner.CornerRadius = UDim.new(0, 4)
	miniBtnCorner.Parent = miniBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 26, 0, 24)
	closeBtn.Position = UDim2.new(1, -32, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Parent = bar

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 4)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function() parent:Destroy() end)

	-- minimize
	local function setContentVisible(v)
		for _, child in ipairs(f:GetChildren()) do
			if child:IsA("GuiObject") and child ~= bar and child ~= padding and child ~= corner then
				child.Visible = v
			end
		end
	end
	local minimized = false
	local originalSize = f.Size
	miniBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			originalSize = f.Size
			setContentVisible(false)
			f.Size = UDim2.new(f.Size.X.Scale, f.Size.X.Offset, 0, 52)
			miniBtn.Text = "+"
		else
			setContentVisible(true)
			f.Size = originalSize
			miniBtn.Text = "−"
		end
	end)

	-- drag
	do
		local dragging, dragStart, startPos = false, nil, nil
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = f.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		bar.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				f.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- Footer
	local signature = Instance.new("TextLabel")
	signature.Name = "signature"
	signature.Size = UDim2.new(0, 150, 0, 18)
	signature.Position = UDim2.new(0, 10, 1, -24)
	signature.BackgroundTransparency = 1
	signature.Text = "Made by Phumipad"
	signature.TextColor3 = Color3.fromRGB(150,150,150)
	signature.Font = Enum.Font.GothamSemibold
	signature.TextSize = 12
	signature.TextXAlignment = Enum.TextXAlignment.Left
	signature.Parent = f

	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "versionLabel"
	versionLabel.Size = UDim2.new(0, 60, 0, 18)
	versionLabel.Position = UDim2.new(1, -70, 1, -24)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v2.2"
	versionLabel.TextColor3 = Color3.fromRGB(100,200,255)
	versionLabel.Font = Enum.Font.GothamBold
	versionLabel.TextSize = 12
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Parent = f

	return f
end

local function makeToggle(parent, y, labelText, defaultOn)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 0, 22)
	lbl.Position = UDim2.new(0, 10, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 60, 0, 22)
	btn.Position = UDim2.new(1, -70, 0, y)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local function apply(v)
		btn.Text = v and "ON" or "OFF"
		btn.BackgroundColor3 = v and Color3.fromRGB(50,180,50) or Color3.fromRGB(80,80,90)
		btn.TextColor3 = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
	end
	apply(defaultOn)

	return lbl, btn, apply
end

-- WalkSpeed Section (ช่องกรอกตัวเลข + เปิด/ปิด)
local function makeSpeedSection(parent, y)
	local _, onOffBtn, onOffApply = makeToggle(parent, y, "🏃 Speed Control", false)

	local inputLbl = Instance.new("TextLabel")
	inputLbl.Size = UDim2.new(0.55, 0, 0, 22)
	inputLbl.Position = UDim2.new(0, 10, 0, y + 25)
	inputLbl.BackgroundTransparency = 1
	inputLbl.Text = "WalkSpeed:"
	inputLbl.TextColor3 = Color3.fromRGB(180,180,180)
	inputLbl.Font = Enum.Font.Gotham
	inputLbl.TextSize = 12
	inputLbl.TextXAlignment = Enum.TextXAlignment.Left
	inputLbl.Parent = parent

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 60, 0, 22)
	box.Position = UDim2.new(1, -70, 0, y + 25)
	box.BackgroundColor3 = Color3.fromRGB(45,45,55)
	box.BorderSizePixel = 0
	box.Text = tostring(state.speedValue)
	box.TextColor3 = Color3.fromRGB(255,255,255)
	box.PlaceholderText = "16"
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.Parent = parent

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 6)
	boxCorner.Parent = box

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num and num >= 0 then
			state.speedValue = num
			if state.speedEnabled and humanoid then
				humanoid.WalkSpeed = num
			end
		else
			box.Text = tostring(state.speedValue)
		end
	end)

	onOffBtn.MouseButton1Click:Connect(function()
		state.speedEnabled = not state.speedEnabled
		onOffApply(state.speedEnabled)
		if humanoid then
			if state.speedEnabled then
				humanoid.WalkSpeed = tonumber(state.speedValue) or 16
			else
				humanoid.WalkSpeed = state.baseWalkSpeed
			end
		end
	end)
end

-- TP Walk Section (ช่องกรอกตัวเลข + เปิด/ปิด)
local function makeTPWalkSection(parent, y)
	local _, onOffBtn, onOffApply = makeToggle(parent, y, "🚶 TP Walk", false)

	local inputLbl = Instance.new("TextLabel")
	inputLbl.Size = UDim2.new(0.55, 0, 0, 22)
	inputLbl.Position = UDim2.new(0, 10, 0, y + 25)
	inputLbl.BackgroundTransparency = 1
	inputLbl.Text = "TP Multiplier:"
	inputLbl.TextColor3 = Color3.fromRGB(180,180,180)
	inputLbl.Font = Enum.Font.Gotham
	inputLbl.TextSize = 12
	inputLbl.TextXAlignment = Enum.TextXAlignment.Left
	inputLbl.Parent = parent

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 60, 0, 22)
	box.Position = UDim2.new(1, -70, 0, y + 25)
	box.BackgroundColor3 = Color3.fromRGB(45,45,55)
	box.BorderSizePixel = 0
	box.Text = tostring(state.tpWalkSpeed)
	box.TextColor3 = Color3.fromRGB(255,255,255)
	box.PlaceholderText = "2"
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.Parent = parent

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 6)
	boxCorner.Parent = box

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num and num > 0 then
			state.tpWalkSpeed = num
		else
			box.Text = tostring(state.tpWalkSpeed)
		end
	end)

	onOffBtn.MouseButton1Click:Connect(function()
		state.tpWalkEnabled = not state.tpWalkEnabled
		onOffApply(state.tpWalkEnabled)
		applyTPWalk(state.tpWalkEnabled)
	end)
end

-- ================== BUILD UI ==================
state.ui = makeScreenGui()
state.frame = makeFrame(state.ui)

-- Speed section (y = 44)
makeSpeedSection(state.frame, 44)

-- TP Walk section (y = 96)
makeTPWalkSection(state.frame, 96)

-- Toggles section (y0 = 150)
local y0 = 150
local _, btnInstant, applyInstant  = makeToggle(state.frame, y0,        "⚡ Instant Interact", false)
local _, btnInfJump, applyInf      = makeToggle(state.frame, y0+25,     "🦘 Infinite Jump",    false)
local _, btnGod, applyGodBtn       = makeToggle(state.frame, y0+50,     "🛡️ God Mode",         false)
local _, btnNoclip, applyNC        = makeToggle(state.frame, y0+75,     "👻 Noclip",           false)
local _, btnAntiRD, applyAntiRDBtn = makeToggle(state.frame, y0+100,    "🚫 Anti Ragdoll",     false)
local _, btnFullB, applyFullBBtn   = makeToggle(state.frame, y0+125,    "💡 Full Bright",      false)
local _, btnESP, applyESPBtn       = makeToggle(state.frame, y0+150,    "👁️ ESP",              false)
local _, btnFPS, applyFPSBtn       = makeToggle(state.frame, y0+175,    "🥔 FPS Booster",      false)

btnInstant.MouseButton1Click:Connect(function()
	state.instantInteract = not state.instantInteract
	applyInstant(state.instantInteract)
end)
btnInfJump.MouseButton1Click:Connect(function()
	state.infiniteJump = not state.infiniteJump
	applyInf(state.infiniteJump)
end)
btnGod.MouseButton1Click:Connect(function()
	state.godMode = not state.godMode
	applyGodBtn(state.godMode)
	applyGodMode(state.godMode)
end)
btnNoclip.MouseButton1Click:Connect(function()
	state.noclip = not state.noclip
	applyNC(state.noclip)
	applyNoclip(state.noclip)
end)
btnAntiRD.MouseButton1Click:Connect(function()
	state.antiRagdoll = not state.antiRagdoll
	applyAntiRDBtn(state.antiRagdoll)
	applyAntiRagdoll(state.antiRagdoll)
end)
btnFullB.MouseButton1Click:Connect(function()
	state.fullBright = not state.fullBright
	applyFullBBtn(state.fullBright)
	applyFullBright(state.fullBright)
end)
btnESP.MouseButton1Click:Connect(function()
	state.esp = not state.esp
	applyESPBtn(state.esp)
	applyESP(state.esp)
end)
btnFPS.MouseButton1Click:Connect(function()
	state.fpsBooster = not state.fpsBooster
	applyFPSBtn(state.fpsBooster)
	applyFPSBooster(state.fpsBooster)
end)

-- ================== SAVE SPOT BUTTON ==================
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -20, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, y0 + 205) 
saveBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 13
saveBtn.Text = "📍 Save Spot"
saveBtn.Parent = state.frame

local saveBtnCorner = Instance.new("UICorner")
saveBtnCorner.CornerRadius = UDim.new(0, 6)
saveBtnCorner.Parent = saveBtn

local function savePosition()
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	state.savedPosition = root.Position
	saveBtn.Text = "🚀 Teleport to Saved Spot"
	saveBtn.BackgroundColor3 = Color3.fromRGB(50,150,50)
end

local function teleportToSavedSpot()
	if state.savedPosition then
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(state.savedPosition)
		state.savedPosition = nil
		saveBtn.Text = "📍 Save Spot"
		saveBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
	end
end

saveBtn.MouseButton1Click:Connect(function()
	if state.savedPosition then
		teleportToSavedSpot()
	else
		savePosition()
	end
end)

-- ================== FEATURES ==================
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

print("✅ Phumipad Toolbox v2.2 loaded successfully!")
print("📝 Features: Custom WalkSpeed Box, TP Walk, Potato FPS Booster")
