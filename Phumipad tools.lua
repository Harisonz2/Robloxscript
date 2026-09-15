-- ================== AUTO CLEANUP PREVIOUS INSTANCE ==================
if _G.PhumipadCleanup then
	pcall(_G.PhumipadCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ตรวจสอบ Container ที่ปลอดภัยที่สุดเพื่อป้องกัน Permission Error
local targetContainer = playerGui
pcall(function()
	if gethui then
		targetContainer = gethui()
	elseif CoreGui then
		local test = Instance.new("Folder")
		test.Parent = CoreGui
		test:Destroy()
		targetContainer = CoreGui
	end
end)

local function safeParentGui(gui)
	local success = pcall(function()
		gui.Parent = targetContainer
	end)
	if not success or not gui.Parent then
		gui.Parent = playerGui
	end
end

-- ================== STATE ==================
local state = {
	ui = nil,
	frame = nil,

	-- Movement
	speedEnabled = false,
	speedValue = 16,
	baseWalkSpeed = 16,

	tpWalkEnabled = false,
	tpWalkSpeed = 1,

	-- Utilities & Visual
	instantInteract = false,
	infiniteJump = false,
	godMode = false,
	noclip = false,
	antiRagdoll = false,
	fullBright = false,
	esp = false,
	espTeamMode = true,
	botEsp = false,
	fpsBooster = false,
	screenTime = false,

	baseMaxHealth = 100,

	-- Runtime connections
	_noclipConn = nil,
	_antiRDConns = {},
	_fbConn = nil,
	_espConn = nil,
	_botEspConn = nil,
	_botDescConn = nil,
	_tpWalkConn = nil,
	_fpsConn = nil,

	-- Backups & ESP Storage
	fbBackup = nil,
	potatoBackup = nil,
	savedPosition1 = nil,
	savedPosition2 = nil,
	espFolder = nil,
	espCache = {},
	botEspFolder = nil,
	botEspCache = {}
}

local globalConns = {}

local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ================== UTILITY FUNCTIONS ==================
local function copyGameName()
	local gameName = "Unknown Game"
	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)

	if success and result and result.Name then
		gameName = result.Name
	else
		gameName = "Place " .. tostring(game.PlaceId)
	end

	local copied = false
	if setclipboard then
		setclipboard(gameName)
	elseif toclipboard then
		toclipboard(gameName)
	elseif syn and syn.write_clipboard then
		syn.write_clipboard(gameName)
	end

	return copied, gameName
end

-- ================== STATS PARSER & TRACKER ==================
local initialLeaderstats = {}

local function parseStatNumber(val)
	if type(val) == "number" then return val end
	if type(val) ~= "string" then return nil end
	local clean = string.gsub(val, "[,%$]", "")
	local numStr, suffix = string.match(clean, "([%d%.]+)%s*([kKmMbBtT]?)")
	local num = tonumber(numStr)
	if not num then return nil end
	suffix = string.lower(suffix or "")
	if suffix == "k" then
		num = num * 1e3
	elseif suffix == "m" then
		num = num * 1e6
	elseif suffix == "b" then
		num = num * 1e9
	elseif suffix == "t" then
		num = num * 1e12
	end
	return num
end

local function formatStatDiff(n)
	if not n then return "0" end
	local absN = math.abs(n)
	if absN >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif absN >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif absN >= 1e3 then
		return string.format("%.2fK", n / 1e3)
	else
		return tostring(math.floor(n))
	end
end

local function recordInitialStats()
	initialLeaderstats = {}
	local lstats = player:FindFirstChild("leaderstats")
	if not lstats then return end
	for _, v in ipairs(lstats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
			local num = parseStatNumber(v.Value)
			if num then
				initialLeaderstats[v.Name] = num
			end
		end
	end
end

local function getLeaderstatsString()
	local lstats = player:FindFirstChild("leaderstats")
	if not lstats then return "No active stats" end

	local parts = {}
	local count = 0
	for _, v in ipairs(lstats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
			local currentStr = tostring(v.Value)
			local currentNum = parseStatNumber(v.Value)
			local initNum = initialLeaderstats[v.Name]
			local diffText = ""

			if currentNum and initNum then
				local diff = currentNum - initNum
				if diff > 0 then
					diffText = string.format(" (+%s)", formatStatDiff(diff))
				elseif diff < 0 then
					diffText = string.format(" (-%s)", formatStatDiff(math.abs(diff)))
				else
					diffText = " (+0)"
				end
			end

			table.insert(parts, string.format("%s: %s%s", v.Name, currentStr, diffText))
			count = count + 1
			if count >= 3 then break end
		end
	end

	if #parts > 0 then
		return table.concat(parts, "  |  ")
	end
	return "No active stats"
end

local function getBatteryPercentage()
	local level = 1
	pcall(function()
		local bat = UserInputService:GetBatteryLevel()
		if bat and bat > 0 then
			level = bat
		end
	end)
	return level
end

-- ================== BATTERY SAVER OVERLAY ==================
local screenTimeGui = nil

local function applyScreenTime(on)
	state.screenTime = on

	if screenTimeGui then
		screenTimeGui:Destroy()
		screenTimeGui = nil
	end

	if not on then return end

	recordInitialStats()

	local sgST = Instance.new("ScreenGui")
	sgST.Name = "Phumipad_BatterySaver_Overlay"
	sgST.ResetOnSpawn = false
	sgST.IgnoreGuiInset = true
	sgST.DisplayOrder = 999999
	safeParentGui(sgST)
	screenTimeGui = sgST

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BorderSizePixel = 0
	bg.Active = true
	bg.Parent = sgST

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, -50, 0, 50)
	topBar.Position = UDim2.new(0, 25, 0, 25)
	topBar.BackgroundTransparency = 1
	topBar.Parent = bg

	local batContainer = Instance.new("Frame")
	batContainer.Size = UDim2.new(0, 130, 0, 32)
	batContainer.AnchorPoint = Vector2.new(1, 0)
	batContainer.Position = UDim2.new(1, 0, 0, 0)
	batContainer.BackgroundTransparency = 1
	batContainer.Parent = topBar

	local batLabel = Instance.new("TextLabel")
	batLabel.Size = UDim2.new(1, -50, 1, 0)
	batLabel.Position = UDim2.new(0, 0, 0, 0)
	batLabel.BackgroundTransparency = 1
	batLabel.Text = "100%"
	batLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	batLabel.Font = Enum.Font.GothamBold
	batLabel.TextSize = 18
	batLabel.TextXAlignment = Enum.TextXAlignment.Right
	batLabel.Parent = batContainer

	local batOutline = Instance.new("Frame")
	batOutline.Size = UDim2.new(0, 36, 0, 18)
	batOutline.Position = UDim2.new(1, -40, 0.5, -9)
	batOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	batOutline.BorderColor3 = Color3.fromRGB(180, 190, 210)
	batOutline.BorderSizePixel = 1.5
	batOutline.Parent = batContainer
	Instance.new("UICorner", batOutline).CornerRadius = UDim.new(0, 4)

	local batNub = Instance.new("Frame")
	batNub.Size = UDim2.new(0, 3, 0, 8)
	batNub.Position = UDim2.new(1, 1.5, 0.5, -4)
	batNub.BackgroundColor3 = Color3.fromRGB(180, 190, 210)
	batNub.BorderSizePixel = 0
	batNub.Parent = batOutline

	local batFill = Instance.new("Frame")
	batFill.Size = UDim2.new(1, -4, 1, -4)
	batFill.Position = UDim2.new(0, 2, 0, 2)
	batFill.BackgroundColor3 = Color3.fromRGB(0, 255, 125)
	batFill.BorderSizePixel = 0
	batFill.Parent = batOutline
	Instance.new("UICorner", batFill).CornerRadius = UDim.new(0, 2)

	local centerBox = Instance.new("Frame")
	centerBox.Size = UDim2.new(0, 560, 0, 360)
	centerBox.Position = UDim2.new(0.5, -280, 0.5, -180)
	centerBox.BackgroundTransparency = 1
	centerBox.Parent = bg

	local clockLabel = Instance.new("TextLabel")
	clockLabel.Size = UDim2.new(1, 0, 0, 90)
	clockLabel.Position = UDim2.new(0, 0, 0, 0)
	clockLabel.BackgroundTransparency = 1
	clockLabel.Text = os.date("%H:%M:%S")
	clockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	clockLabel.Font = Enum.Font.Gotham
	clockLabel.TextSize = 82
	clockLabel.Parent = centerBox

	local elapsedLabel = Instance.new("TextLabel")
	elapsedLabel.Size = UDim2.new(1, 0, 0, 34)
	elapsedLabel.Position = UDim2.new(0, 0, 0, 96)
	elapsedLabel.BackgroundTransparency = 1
	elapsedLabel.Text = "Saving Battery • 00:00"
	elapsedLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	elapsedLabel.Font = Enum.Font.GothamBold
	elapsedLabel.TextSize = 22
	elapsedLabel.Parent = centerBox

	local statsCard = Instance.new("Frame")
	statsCard.Size = UDim2.new(0, 520, 0, 60)
	statsCard.Position = UDim2.new(0.5, -260, 0, 142)
	statsCard.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	statsCard.BorderSizePixel = 0
	statsCard.Parent = centerBox
	Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 10)
	
	local scStroke = Instance.new("UIStroke")
	scStroke.Color = Color3.fromRGB(45, 55, 75)
	scStroke.Thickness = 1.2
	scStroke.Parent = statsCard

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -28, 1, 0)
	statsLabel.Position = UDim2.new(0, 14, 0, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Loading stats..."
	statsLabel.TextColor3 = Color3.fromRGB(255, 225, 50)
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextSize = 22
	statsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	statsLabel.Parent = statsCard

	local slideTrack = Instance.new("Frame")
	slideTrack.Size = UDim2.new(0, 350, 0, 64)
	slideTrack.Position = UDim2.new(0.5, -175, 0, 230)
	slideTrack.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
	slideTrack.BorderSizePixel = 0
	slideTrack.Parent = centerBox
	Instance.new("UICorner", slideTrack).CornerRadius = UDim.new(0, 16)

	local sTStroke = Instance.new("UIStroke")
	sTStroke.Color = Color3.fromRGB(48, 52, 64)
	sTStroke.Thickness = 1.5
	sTStroke.Parent = slideTrack

	local slideText = Instance.new("TextLabel")
	slideText.Size = UDim2.new(1, -80, 1, 0)
	slideText.Position = UDim2.new(0, 80, 0, 0)
	slideText.BackgroundTransparency = 1
	slideText.Text = "slide to unlock"
	slideText.TextColor3 = Color3.fromRGB(185, 190, 205)
	slideText.Font = Enum.Font.Gotham
	slideText.TextSize = 20
	slideText.Parent = slideTrack

	local slideKnob = Instance.new("TextButton")
	slideKnob.Size = UDim2.new(0, 76, 0, 52)
	slideKnob.Position = UDim2.new(0, 6, 0.5, 0)
	slideKnob.AnchorPoint = Vector2.new(0, 0.5)
	slideKnob.BackgroundColor3 = Color3.fromRGB(235, 238, 245)
	slideKnob.Text = ""
	slideKnob.AutoButtonColor = false
	slideKnob.Parent = slideTrack

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 11)
	knobCorner.Parent = slideKnob

	local knobStroke = Instance.new("UIStroke")
	knobStroke.Color = Color3.fromRGB(100, 104, 115)
	knobStroke.Thickness = 1.2
	knobStroke.Parent = slideKnob

	local knobGrad = Instance.new("UIGradient")
	knobGrad.Rotation = 90
	knobGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(235, 238, 244)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 170, 180))
	})
	knobGrad.Parent = slideKnob

	local arrowShadow = Instance.new("ImageLabel")
	arrowShadow.Size = UDim2.new(0, 26, 0, 26)
	arrowShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
	arrowShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrowShadow.BackgroundTransparency = 1
	arrowShadow.Image = "rbxassetid://6034818379"
	arrowShadow.ImageColor3 = Color3.fromRGB(255, 255, 255)
	arrowShadow.ImageTransparency = 0.4
	arrowShadow.Parent = slideKnob

	local arrowIcon = Instance.new("ImageLabel")
	arrowIcon.Size = UDim2.new(0, 26, 0, 26)
	arrowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	arrowIcon.BackgroundTransparency = 1
	arrowIcon.Image = "rbxassetid://6034818379"
	arrowIcon.ImageColor3 = Color3.fromRGB(100, 105, 115)
	arrowIcon.Parent = slideKnob

	local dragging = false
	slideKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	local dragConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local trackStart = slideTrack.AbsolutePosition.X
			local trackWidth = slideTrack.AbsoluteSize.X
			local knobWidth = slideKnob.AbsoluteSize.X

			local relativeX = input.Position.X - trackStart - (knobWidth / 2)
			local clampedX = math.clamp(relativeX, 6, trackWidth - knobWidth - 6)

			slideKnob.Position = UDim2.new(0, clampedX, 0.5, 0)
			slideText.TextTransparency = clampedX / (trackWidth - knobWidth)

			if clampedX >= trackWidth - knobWidth - 8 then
				dragging = false
				applyScreenTime(false)
			end
		end
	end)

	local endConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				TweenService:Create(slideKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 6, 0.5, 0)
				}):Play()
				TweenService:Create(slideText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			end
		end
	end)

	sgST.Destroying:Connect(function()
		if dragConn then dragConn:Disconnect() end
		if endConn then endConn:Disconnect() end
	end)

	local startTime = os.time()
	task.spawn(function()
		while state.screenTime and screenTimeGui == sgST do
			local now = os.time()
			local diff = now - startTime
			local hrs = math.floor(diff / 3600)
			local mins = math.floor((diff % 3600) / 60)
			local secs = diff % 60

			clockLabel.Text = os.date("%H:%M:%S")
			if hrs > 0 then
				elapsedLabel.Text = string.format("Saving Battery • %02d:%02d:%02d", hrs, mins, secs)
			else
				elapsedLabel.Text = string.format("Saving Battery • %02d:%02d", mins, secs)
			end

			statsLabel.Text = getLeaderstatsString()

			local bl = getBatteryPercentage()
			batLabel.Text = tostring(math.floor(bl * 100)) .. "%"
			batFill.Size = UDim2.new(bl, -4, 1, -4)
			if bl <= 0.2 then
				batFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
			elseif bl <= 0.4 then
				batFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			else
				batFill.BackgroundColor3 = Color3.fromRGB(0, 255, 125)
			end

			task.wait(1)
		end
	end)
end

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
	else
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
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
					local mult = tonumber(state.tpWalkSpeed) or 1
					hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (mult * 15 * delta))
				end
			end
		end)
	end
end

local function applyFPSBooster(on)
	if on then
		state.potatoBackup = {
			parts = {},
			decals = {},
			effects = {},
			lighting = {
				GlobalShadows = Lighting.GlobalShadows,
				FogEnd = Lighting.FogEnd,
				ShadowSoftness = Lighting.ShadowSoftness,
				Brightness = Lighting.Brightness,
				effects = {}
			},
			quality = settings().Rendering.QualityLevel
		}

		pcall(function()
			settings().Rendering.QualityLevel = 1
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.ShadowSoftness = 0

			for _, fx in ipairs(Lighting:GetChildren()) do
				if fx:IsA("PostEffect") or fx:IsA("BloomEffect") or fx:IsA("ColorCorrectionEffect")
					or fx:IsA("SunRaysEffect") or fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") then
					state.potatoBackup.lighting.effects[fx] = fx.Enabled
					fx.Enabled = false
				end
			end
		end)

		local function potatoify(part)
			pcall(function()
				if part.Name == "DracoESPHighlight" or part.Name == "DracoESPName" 
					or part:IsDescendantOf(playerGui) or (CoreGui and part:IsDescendantOf(CoreGui)) then
					return
				end

				if part:IsA("BasePart") then
					local isChar = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
					if not isChar then
						if not state.potatoBackup.parts[part] then
							state.potatoBackup.parts[part] = {
								Material = part.Material,
								Reflectance = part.Reflectance,
								CastShadow = part.CastShadow
							}
						end
						part.Material = Enum.Material.SmoothPlastic
						part.Reflectance = 0
						part.CastShadow = false
					end
				elseif part:IsA("Decal") or part:IsA("Texture") then
					if not state.potatoBackup.decals[part] then
						state.potatoBackup.decals[part] = {
							Transparency = part.Transparency
						}
					end
					part.Transparency = 1
				elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Smoke") 
					or part:IsA("Fire") or part:IsA("Sparkles") or part:IsA("Beam") then
					if not state.potatoBackup.effects[part] then
						state.potatoBackup.effects[part] = {
							Enabled = part.Enabled
						}
					end
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

		if state.potatoBackup then
			pcall(function()
				if state.potatoBackup.quality then
					settings().Rendering.QualityLevel = state.potatoBackup.quality
				end
				if state.potatoBackup.lighting then
					local l = state.potatoBackup.lighting
					Lighting.GlobalShadows = l.GlobalShadows
					Lighting.FogEnd = l.FogEnd
					Lighting.ShadowSoftness = l.ShadowSoftness
					Lighting.Brightness = l.Brightness
					for fx, enabled in pairs(l.effects or {}) do
						if fx and fx.Parent then
							fx.Enabled = enabled
						end
					end
				end

				for part, props in pairs(state.potatoBackup.parts or {}) do
					if part and part.Parent then
						part.Material = props.Material
						part.Reflectance = props.Reflectance
						part.CastShadow = props.CastShadow
					end
				end

				for decal, props in pairs(state.potatoBackup.decals or {}) do
					if decal and decal.Parent then
						decal.Transparency = props.Transparency
					end
				end

				for eff, props in pairs(state.potatoBackup.effects or {}) do
					if eff and eff.Parent then
						eff.Enabled = props.Enabled
					end
				end
			end)
			state.potatoBackup = nil
		end
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

-- ================== ULTRA-RELIABLE ESP ENGINE ==================
local espRayParams = RaycastParams.new()
espRayParams.FilterType = Enum.RaycastFilterType.Exclude
espRayParams.IgnoreWater = true

local function isPlayerOccluded(targetChar, targetPart)
	local cam = Workspace.CurrentCamera
	if not cam or not targetPart then return false end

	local myChar = player.Character
	espRayParams.FilterDescendantsInstances = {myChar, targetChar}

	local origin = cam.CFrame.Position
	local direction = targetPart.Position - origin
	local result = Workspace:Raycast(origin, direction, espRayParams)

	return result ~= nil
end

local function getTeamOrPlayerColor(plr)
	local myTeam = player.Team
	local targetTeam = plr.Team

	if myTeam and targetTeam and myTeam == targetTeam then
		return Color3.fromRGB(0, 185, 255)
	end

	if state.espTeamMode then
		if targetTeam and targetTeam.TeamColor then
			return targetTeam.TeamColor.Color
		else
			local seedString = (targetTeam and targetTeam.Name) or plr.Name
			local hash = 0
			for i = 1, #seedString do
				hash = (hash * 33 + string.byte(seedString, i)) % 360
			end
			return Color3.fromHSV(hash / 360, 0.85, 1)
		end
	else
		return Color3.fromRGB(255, 45, 45)
	end
end

local function getCharacterParts(char)
	if not char then return nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char.PrimaryPart

	local head = char:FindFirstChild("Head") or root

	if not root then
		root = char:FindFirstChildWhichIsA("BasePart")
	end
	if not head then
		head = root
	end
	return root, head
end

local function cleanESPForPlayer(plr)
	local data = state.espCache[plr]
	if data then
		if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
		if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
		state.espCache[plr] = nil
	end
end

local function removeESP()
	if state._espConn then
		state._espConn:Disconnect()
		state._espConn = nil
	end
	for plr, _ in pairs(state.espCache) do
		cleanESPForPlayer(plr)
	end
	state.espCache = {}
	if state.espFolder then
		pcall(function() state.espFolder:Destroy() end)
		state.espFolder = nil
	end
end

local function applyESP(on)
	removeESP()
	if not on then return end

	state.espFolder = Instance.new("Folder")
	state.espFolder.Name = "Phumipad_ESP_Storage"
	safeParentGui(state.espFolder)

	state._espConn = RunService.RenderStepped:Connect(function()
		if not state.esp then return end
		local myChar = player.Character
		local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)

		local activePlayers = {}

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				activePlayers[plr] = true
				local char = plr.Character or Workspace:FindFirstChild(plr.Name)
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root, head = getCharacterParts(char)

				local isAlive = char and char.Parent and hum and (hum.Health > 0) and root and head

				if isAlive then
					local data = state.espCache[plr]
					if not data or not data.Highlight or not data.Highlight.Parent or not data.Billboard or not data.Billboard.Parent then
						local hl = Instance.new("Highlight")
						hl.Name = plr.Name .. "_HL"
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.FillTransparency = 0.35
						hl.OutlineTransparency = 0
						hl.Parent = state.espFolder

						local bb = Instance.new("BillboardGui")
						bb.Name = plr.Name .. "_BB"
						bb.Size = UDim2.new(0, 260, 0, 52)
						bb.StudsOffset = Vector3.new(0, 4.4, 0)
						bb.AlwaysOnTop = true
						bb.LightInfluence = 0
						bb.MaxDistance = 10000
						bb.Parent = state.espFolder

						local label = Instance.new("TextLabel")
						label.Name = "ESPLabel"
						label.Size = UDim2.new(1, 0, 1, 0)
						label.BackgroundTransparency = 1
						label.TextColor3 = Color3.fromRGB(255, 255, 255)
						label.TextStrokeTransparency = 0
						label.Font = Enum.Font.GothamBold
						label.TextSize = 16
						label.Parent = bb

						data = {Highlight = hl, Billboard = bb, Label = label}
						state.espCache[plr] = data
					end

					data.Highlight.Adornee = char
					data.Billboard.Adornee = head
					data.Billboard.Enabled = true

					local col = getTeamOrPlayerColor(plr)
					local occluded = isPlayerOccluded(char, head or root)

					data.Highlight.FillColor = col
					data.Highlight.OutlineColor = col
					data.Highlight.Enabled = occluded

					data.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
					data.Label.TextStrokeColor3 = col

					if myRoot then
						local dist = math.floor((myRoot.Position - root.Position).Magnitude)
						data.Label.Text = string.format("%s\n[%d studs]", plr.DisplayName or plr.Name, dist)
					else
						data.Label.Text = plr.DisplayName or plr.Name
					end
				else
					local data = state.espCache[plr]
					if data then
						if data.Highlight then data.Highlight.Enabled = false end
						if data.Billboard then data.Billboard.Enabled = false end
					end
				end
			end
		end

		for cachedPlr, _ in pairs(state.espCache) do
			if not activePlayers[cachedPlr] then
				cleanESPForPlayer(cachedPlr)
			end
		end
	end)
end

-- ================== BOT ESP SYSTEM ==================
local botColors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(255, 128, 0),
	Color3.fromRGB(128, 0, 255),
	Color3.fromRGB(255, 80, 150),
	Color3.fromRGB(80, 255, 120),
	Color3.fromRGB(180, 255, 0),
	Color3.fromRGB(255, 180, 0),
	Color3.fromRGB(100, 180, 255),
	Color3.fromRGB(200, 100, 255),
	Color3.fromRGB(255, 100, 100),
}
local usedBotColors = {}

local function getUniqueBotColor()
	local available = {}
	for i = 1, #botColors do
		if not usedBotColors[i] then table.insert(available, i) end
	end
	if #available == 0 then
		usedBotColors = {}
		for i = 1, #botColors do table.insert(available, i) end
	end
	local index = available[math.random(1, #available)]
	usedBotColors[index] = true
	return botColors[index]
end

local function isPlayerCharacter(model)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character == model then return true end
	end
	return false
end

local function isBot(model)
	if not model or not model:IsA("Model") then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if isPlayerCharacter(model) then return false end
	if not model:FindFirstChild("HumanoidRootPart") and not model:FindFirstChild("Head") and not model:FindFirstChildWhichIsA("BasePart") then
		return false
	end
	return true
end

local function cleanBotESP(bot)
	local data = state.botEspCache[bot]
	if data then
		if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
		if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
		state.botEspCache[bot] = nil
	end
end

local function removeBotESP()
	if state._botEspConn then state._botEspConn:Disconnect(); state._botEspConn = nil end
	if state._botDescConn then state._botDescConn:Disconnect(); state._botDescConn = nil end
	for bot, _ in pairs(state.botEspCache) do cleanBotESP(bot) end
	state.botEspCache = {}
	if state.botEspFolder then pcall(function() state.botEspFolder:Destroy() end); state.botEspFolder = nil end
	usedBotColors = {}
end

local function applyBotESP(on)
	removeBotESP()
	if not on then return end

	state.botEspFolder = Instance.new("Folder")
	state.botEspFolder.Name = "Phumipad_BotESP_Storage"
	safeParentGui(state.botEspFolder)

	local function registerBot(bot)
		if not isBot(bot) then return end
		if state.botEspCache[bot] then return end

		local root, head = getCharacterParts(bot)
		if not root or not head then return end

		local col = getUniqueBotColor()

		local hl = Instance.new("Highlight")
		hl.Name = bot.Name .. "_BotHL"
		hl.Adornee = bot
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor = col
		hl.OutlineColor = col
		hl.FillTransparency = 0.45
		hl.OutlineTransparency = 0
		hl.Parent = state.botEspFolder

		local bb = Instance.new("BillboardGui")
		bb.Name = bot.Name .. "_BotBB"
		bb.Adornee = head
		bb.Size = UDim2.new(0, 260, 0, 52)
		bb.StudsOffset = Vector3.new(0, 4.4, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 10000
		bb.Parent = state.botEspFolder

		local label = Instance.new("TextLabel")
		label.Name = "BotESPLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = col
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.Text = bot.Name
		label.Parent = bb

		state.botEspCache[bot] = {
			Highlight = hl,
			Billboard = bb,
			Label = label,
			Root = root,
			Head = head,
			Color = col
		}

		bot.AncestryChanged:Connect(function(_, parent)
			if not parent then cleanBotESP(bot) end
		end)
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isBot(obj) then registerBot(obj) end
	end

	state._botDescConn = Workspace.DescendantAdded:Connect(function(obj)
		task.wait(0.1)
		if state.botEsp and isBot(obj) then registerBot(obj) end
	end)

	state._botEspConn = RunService.RenderStepped:Connect(function()
		if not state.botEsp then return end
		local myChar = player.Character
		local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)

		for bot, data in pairs(state.botEspCache) do
			if not bot or not bot.Parent then
				cleanBotESP(bot)
			else
				local hum = bot:FindFirstChildOfClass("Humanoid")
				local isAlive = hum and (hum.Health > 0)

				if isAlive and data.Root and data.Head then
					data.Highlight.Enabled = true
					data.Billboard.Enabled = true

					if myRoot then
						local dist = math.floor((myRoot.Position - data.Root.Position).Magnitude)
						data.Label.Text = string.format("%s\n[%d studs]", bot.Name, dist)
					else
						data.Label.Text = bot.Name
					end
				else
					data.Highlight.Enabled = false
					data.Billboard.Enabled = false
				end
			end
		end
	end)
end

table.insert(globalConns, player.CharacterAdded:Connect(function(char)
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
end))

-- ================== MAIN GUI & CONTAINER CREATION ==================
local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadToolboxMinimalGui"
sg.ResetOnSpawn = false
safeParentGui(sg)

local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 248, 0, 310)
f.Position = UDim2.new(0.04, 0, 0.45, -155)
f.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
f.BorderSizePixel = 0
f.Active = true
f.ClipsDescendants = true
f.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = f

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(35, 42, 60)
stroke.Thickness = 1.2
stroke.Parent = f

-- ================== BRIGHT HIGH-TECH POP-UP BUTTON (GLOWING 'P') ==================
local openBtn = Instance.new("TextButton")
openBtn.Name = "HighTechFloatingDock"
openBtn.Size = UDim2.new(0, 52, 0, 52)
openBtn.Position = UDim2.new(0, 16, 0, 50)
openBtn.BackgroundColor3 = Color3.fromRGB(10, 32, 60)
openBtn.BorderSizePixel = 0
openBtn.Text = "P"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextStrokeColor3 = Color3.fromRGB(0, 215, 255)
openBtn.TextStrokeTransparency = 0
openBtn.Font = Enum.Font.GothamBlack
openBtn.TextSize = 30
openBtn.Visible = false
openBtn.Active = true
openBtn.ZIndex = 250
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 225, 255)
openStroke.Thickness = 2.4
openStroke.Parent = openBtn

local dockGrad = Instance.new("UIGradient")
dockGrad.Rotation = 45
dockGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 60, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 30, 65)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 50, 100))
})
dockGrad.Parent = openBtn

local innerRing = Instance.new("Frame")
innerRing.Size = UDim2.new(1, -6, 1, -6)
innerRing.Position = UDim2.new(0, 3, 0, 3)
innerRing.BackgroundTransparency = 1
innerRing.BorderSizePixel = 0
innerRing.Parent = openBtn
Instance.new("UICorner", innerRing).CornerRadius = UDim.new(1, 0)

local innerRingStroke = Instance.new("UIStroke")
innerRingStroke.Color = Color3.fromRGB(100, 235, 255)
innerRingStroke.Thickness = 1.2
innerRingStroke.Transparency = 0.2
innerRingStroke.Parent = innerRing

do
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local hasMoved = false
	local DRAG_THRESHOLD = 6

	openBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			hasMoved = false
			dragStart = input.Position
			startPos = openBtn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	openBtn.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > DRAG_THRESHOLD then
				hasMoved = true
			end
			if hasMoved then
				openBtn.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	openBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not hasMoved then
				openBtn.Visible = false
				f.Visible = true
			end
			dragging = false
			hasMoved = false
		end
	end)
end

-- Top Bar
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 38)
bar.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = bar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -75, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PHUMIPAD TOOLS"
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 10.5
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 24, 0, 24)
miniBtn.Position = UDim2.new(1, -58, 0.5, -12)
miniBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
miniBtn.BorderSizePixel = 0
miniBtn.Text = "-"
miniBtn.TextColor3 = Color3.fromRGB(180, 195, 220)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 14
miniBtn.Parent = bar
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 6)
miniCorner.Parent = miniBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = bar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- ================== HIGH-TECH TOP TAB BAR ==================
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TopTabBar"
tabBar.Size = UDim2.new(1, -14, 0, 32)
tabBar.Position = UDim2.new(0, 7, 0, 42)
tabBar.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.ClipsDescendants = true
tabBar.Parent = f
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 7)

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(32, 38, 54)
tbStroke.Thickness = 1
tbStroke.Parent = tabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 4)
tabPadding.PaddingRight = UDim.new(0, 4)
tabPadding.Parent = tabBar

-- Main Content Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, 0, 1, -78)
scroll.Position = UDim2.new(0, 0, 0, 78)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 185, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = f

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 4)
scrollPadding.PaddingBottom = UDim.new(0, 18)
scrollPadding.PaddingLeft = UDim.new(0, 8)
scrollPadding.PaddingRight = UDim.new(0, 8)
scrollPadding.Parent = scroll

-- ================== STATUS PANEL ==================
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 56)
statusCard.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
statusCard.BorderSizePixel = 0
statusCard.LayoutOrder = 0
statusCard.Parent = scroll

local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 8)
scCorner.Parent = statusCard

local scStroke = Instance.new("UIStroke")
scStroke.Color = Color3.fromRGB(45, 55, 75)
scStroke.Thickness = 1
scStroke.Parent = statusCard

local gameNameLabel = Instance.new("TextLabel")
gameNameLabel.Size = UDim2.new(1, -64, 0, 18)
gameNameLabel.Position = UDim2.new(0, 8, 0, 6)
gameNameLabel.BackgroundTransparency = 1
gameNameLabel.Text = "Loading Game Info..."
gameNameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
gameNameLabel.Font = Enum.Font.GothamBold
gameNameLabel.TextSize = 11
gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
gameNameLabel.Parent = statusCard

local copyHeaderBtn = Instance.new("TextButton")
copyHeaderBtn.Name = "CopyHeaderButton"
copyHeaderBtn.Size = UDim2.new(0, 46, 0, 18)
copyHeaderBtn.Position = UDim2.new(1, -54, 0, 6)
copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
copyHeaderBtn.BorderSizePixel = 0
copyHeaderBtn.Font = Enum.Font.GothamBold
copyHeaderBtn.TextSize = 9
copyHeaderBtn.Text = "COPY"
copyHeaderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyHeaderBtn.Parent = statusCard

local chbCorner = Instance.new("UICorner")
chbCorner.CornerRadius = UDim.new(0, 4)
chbCorner.Parent = copyHeaderBtn

local copyBusy = false
copyHeaderBtn.MouseButton1Click:Connect(function()
	if copyBusy then return end
	copyBusy = true

	local success, _ = copyGameName()
	if success then
		copyHeaderBtn.Text = "DONE"
		copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
	else
		copyHeaderBtn.Text = "FAIL"
		copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
	end

	task.wait(1.5)
	copyHeaderBtn.Text = "COPY"
	copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	copyBusy = false
end)

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -95, 0, 14)
timeLabel.Position = UDim2.new(0, 8, 0, 30)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Play: 00:00 | Idle: 00:00"
timeLabel.TextColor3 = Color3.fromRGB(150, 165, 190)
timeLabel.Font = Enum.Font.GothamMedium
timeLabel.TextSize = 9
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.TextTruncate = Enum.TextTruncate.AtEnd
timeLabel.Parent = statusCard

local kickWarningLabel = Instance.new("TextLabel")
kickWarningLabel.Size = UDim2.new(0, 80, 0, 14)
kickWarningLabel.Position = UDim2.new(1, -88, 0, 30)
kickWarningLabel.BackgroundTransparency = 1
kickWarningLabel.Text = "DC in 20:00"
kickWarningLabel.TextColor3 = Color3.fromRGB(0, 200, 125)
kickWarningLabel.Font = Enum.Font.GothamBold
kickWarningLabel.TextSize = 10
kickWarningLabel.TextXAlignment = Enum.TextXAlignment.Right
kickWarningLabel.Parent = statusCard

local sessionStart = os.time()
local lastInput = os.time()
local cachedGameName = "Unknown Game"

task.spawn(function()
	local s, r = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	if s and r and r.Name then
		cachedGameName = r.Name
	else
		cachedGameName = "Place ID: " .. tostring(game.PlaceId)
	end
	gameNameLabel.Text = cachedGameName
end)

table.insert(globalConns, UserInputService.InputBegan:Connect(function() lastInput = os.time() end))
table.insert(globalConns, UserInputService.InputChanged:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
		lastInput = os.time()
	end
end))

task.spawn(function()
	while true do
		task.wait(1)
		if not statusCard or not statusCard.Parent then break end

		local now = os.time()
		local played = now - sessionStart

		if humanoid and humanoid.MoveDirection.Magnitude > 0 then
			lastInput = now
		end

		local idle = now - lastInput
		local kickTime = math.max(0, 1200 - idle)

		local pM = math.floor(played / 60)
		local pS = played % 60
		local iM = math.floor(idle / 60)
		local iS = idle % 60
		local kM = math.floor(kickTime / 60)
		local kS = kickTime % 60

		timeLabel.Text = string.format("Play: %02d:%02d | Idle: %02d:%02d", pM, pS, iM, iS)
		kickWarningLabel.Text = string.format("DC in %02d:%02d", kM, kS)

		if kickTime <= 300 then
			kickWarningLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		elseif kickTime <= 600 then
			kickWarningLabel.TextColor3 = Color3.fromRGB(255, 160, 0)
		else
			kickWarningLabel.TextColor3 = Color3.fromRGB(0, 200, 125)
		end
	end
end)

-- ================== CORNER RESIZE HANDLE ==================
local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 18, 0, 18)
resizeGrip.Position = UDim2.new(1, -18, 1, -18)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = ""
resizeGrip.AutoButtonColor = false
resizeGrip.ZIndex = 60
resizeGrip.Parent = f

local gripLine1 = Instance.new("Frame")
gripLine1.Size = UDim2.new(0, 10, 0, 2)
gripLine1.Position = UDim2.new(0, 5, 0, 11)
gripLine1.Rotation = -45
gripLine1.BackgroundColor3 = Color3.fromRGB(0, 185, 255)
gripLine1.BorderSizePixel = 0
gripLine1.ZIndex = 61
gripLine1.Parent = resizeGrip

local gripLine2 = Instance.new("Frame")
gripLine2.Size = UDim2.new(0, 5, 0, 2)
gripLine2.Position = UDim2.new(0, 10, 0, 14)
gripLine2.Rotation = -45
gripLine2.BackgroundColor3 = Color3.fromRGB(0, 185, 255)
gripLine2.BorderSizePixel = 0
gripLine2.ZIndex = 61
gripLine2.Parent = resizeGrip

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

do
	local resizing = false
	local resizeStart = nil
	local startSize = nil

	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = f.AbsoluteSize
			gripLine1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			gripLine2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				resizing = false
				gripLine1.BackgroundColor3 = Color3.fromRGB(0, 185, 255)
				gripLine2.BackgroundColor3 = Color3.fromRGB(0, 185, 255)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local targetW = math.clamp(startSize.X + delta.X, 230, 600)
			local targetH = math.clamp(startSize.Y + delta.Y, 160, 800)
			f.Size = UDim2.new(0, targetW, 0, targetH)
		end
	end)
end

local currentOrder = 1
local function getOrder() currentOrder = currentOrder + 1; return currentOrder end

-- ================== TAB NAVIGATION SYSTEM ==================
local tabItems = {}
local activeTabId = nil

local tabColors = {
	move   = Color3.fromRGB(0, 230, 130),   -- Emerald Neon
	util   = Color3.fromRGB(0, 195, 255),   -- Electric Cyan
	visual = Color3.fromRGB(210, 70, 255),  -- Cyber Magenta
	points = Color3.fromRGB(255, 175, 25),  -- Solar Amber
	tools  = Color3.fromRGB(255, 60, 95)    -- Neon Crimson
}

local function adjustPanelHeight(animate)
	task.defer(function()
		local activeData = tabItems[activeTabId]
		local pageHeight = activeData and activeData.contentLayout.AbsoluteContentSize.Y or 0
		local totalHeight = 40 + 34 + statusCard.Size.Y.Offset + scrollPadding.PaddingTop.Offset + scrollPadding.PaddingBottom.Offset + pageHeight + 14

		local cam = Workspace.CurrentCamera
		local maxAllowedHeight = cam and (cam.ViewportSize.Y * 0.85) or 600
		local finalHeight = math.clamp(totalHeight, 180, maxAllowedHeight)

		if animate then
			TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
			}):Play()
		else
			f.Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
		end
	end)
end

local function switchTab(id)
	activeTabId = id
	for tabId, data in pairs(tabItems) do
		local isCurrent = (tabId == id)
		data.page.Visible = isCurrent
		local accent = tabColors[tabId] or Color3.fromRGB(0, 200, 255)
		
		if isCurrent then
			local darkTint = accent:Lerp(Color3.fromRGB(15, 18, 26), 0.72)
			TweenService:Create(data.button, TweenInfo.new(0.18), {
				BackgroundColor3 = darkTint
			}):Play()
			TweenService:Create(data.stroke, TweenInfo.new(0.18), {
				Color = accent
			}):Play()
			data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			TweenService:Create(data.button, TweenInfo.new(0.18), {
				BackgroundColor3 = Color3.fromRGB(18, 22, 32)
			}):Play()
			TweenService:Create(data.stroke, TweenInfo.new(0.18), {
				Color = Color3.fromRGB(35, 42, 60)
			}):Play()
			data.button.TextColor3 = Color3.fromRGB(130, 145, 170)
		end
	end
	adjustPanelHeight(true)
end

local function registerTab(id, name, emoji, isDefault)
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = id .. "TabButton"
	tabBtn.Size = UDim2.new(0, 0, 1, -4)
	tabBtn.AutomaticSize = Enum.AutomaticSize.X
	tabBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	tabBtn.BorderSizePixel = 0
	tabBtn.Text = (emoji and (emoji .. " ") or "") .. name:upper()
	tabBtn.TextColor3 = Color3.fromRGB(130, 145, 170)
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = 10
	tabBtn.AutoButtonColor = false
	tabBtn.Parent = tabBar

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 5)
	tCorner.Parent = tabBtn

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(35, 42, 60)
	tStroke.Thickness = 1
	tStroke.Parent = tabBtn

	local tPadding = Instance.new("UIPadding")
	tPadding.PaddingLeft = UDim.new(0, 7)
	tPadding.PaddingRight = UDim.new(0, 7)
	tPadding.Parent = tabBtn

	local page = Instance.new("Frame")
	page.Name = id .. "Page"
	page.Size = UDim2.new(1, 0, 0, 0)
	page.AutomaticSize = Enum.AutomaticSize.Y
	page.BackgroundTransparency = 1
	page.LayoutOrder = getOrder()
	page.Visible = false
	page.Parent = scroll

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Padding = UDim.new(0, 5)
	pageLayout.Parent = page

	pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if activeTabId == id then
			adjustPanelHeight(false)
		end
	end)

	tabItems[id] = {
		button = tabBtn,
		stroke = tStroke,
		page = page,
		contentLayout = pageLayout
	}

	tabBtn.MouseButton1Click:Connect(function()
		switchTab(id)
	end)

	if isDefault then
		activeTabId = id
	end

	return page
end

-- ================== COMPONENT BUILDER FUNCTIONS ==================
local function addRefinedToolButton(parent, name, iconSymbol, accentColor, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(38, 46, 64)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 22, 0, 22)
	badge.Position = UDim2.new(0, 5, 0.5, -11)
	badge.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
	badge.BorderSizePixel = 0
	badge.Parent = row
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accentColor
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 0.3
	badgeStroke.Parent = badge

	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = iconSymbol or "•"
	badgeText.TextColor3 = accentColor
	badgeText.Font = Enum.Font.GothamBold
	badgeText.TextSize = 11
	badgeText.Parent = badge

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -62, 1, 0)
	lbl.Position = UDim2.new(0, 34, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(230, 238, 250)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -24, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "›"
	arrow.TextColor3 = Color3.fromRGB(110, 125, 150)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 16
	arrow.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row

	btn.MouseEnter:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(26, 32, 46)}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = accentColor}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = accentColor, Position = UDim2.new(1, -22, 0, 0)}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(38, 46, 64)}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(110, 125, 150), Position = UDim2.new(1, -24, 0, 0)}):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(18, 20, 28)}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 32, 46)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		local ok, err = pcall(onClick)
		if not ok then warn("[Phumipad Tool Error]: " .. tostring(err)) end
	end)

	return row
end

local function addToggleRow(parent, name, defaultOn, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 225, 240)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 44, 0, 20)
	btn.Position = UDim2.new(1, -50, 0.5, -10)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	local function render(v)
		btn.Text = v and "ON" or "OFF"
		btn.BackgroundColor3 = v and Color3.fromRGB(0, 200, 125) or Color3.fromRGB(38, 44, 60)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 180)
	end
	render(defaultOn)

	btn.MouseButton1Click:Connect(function()
		onClick(btn, render)
	end)
end

local function addInputToggleRow(parent, name, defaultVal, defaultOn, onToggle, onValChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.48, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 225, 240)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 42, 0, 20)
	box.Position = UDim2.new(1, -98, 0.5, -10)
	box.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(240, 245, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.Parent = row

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 5)
	boxCorner.Parent = box

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 44, 0, 20)
	btn.Position = UDim2.new(1, -50, 0.5, -10)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	local function render(v)
		btn.Text = v and "ON" or "OFF"
		btn.BackgroundColor3 = v and Color3.fromRGB(0, 200, 125) or Color3.fromRGB(38, 44, 60)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 180)
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

	return {
		box = box,
		btn = btn,
		setVal = function(v)
			box.Text = tostring(v)
			onValChange(v)
		end
	}
end

local function addPresetChips(parent, values, onSelect)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local pLayout = Instance.new("UIListLayout")
	pLayout.FillDirection = Enum.FillDirection.Horizontal
	pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pLayout.Padding = UDim.new(0, 4)
	pLayout.Parent = row

	for i, val in ipairs(values) do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.new(0.2, -4, 1, 0)
		chip.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
		chip.BorderSizePixel = 0
		chip.Text = tostring(val)
		chip.TextColor3 = Color3.fromRGB(185, 205, 235)
		chip.Font = Enum.Font.GothamBold
		chip.TextSize = 10
		chip.AutoButtonColor = false
		chip.LayoutOrder = i
		chip.Parent = row

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 5)
		cCorner.Parent = chip

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(38, 48, 68)
		cStroke.Thickness = 1
		cStroke.Parent = chip

		chip.MouseEnter:Connect(function()
			TweenService:Create(chip, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 40, 58)}):Play()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(0, 200, 255)}):Play()
		end)
		chip.MouseLeave:Connect(function()
			TweenService:Create(chip, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 25, 36)}):Play()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(38, 48, 68)}):Play()
		end)

		chip.MouseButton1Click:Connect(function()
			local flash = TweenService:Create(chip, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(0, 185, 255)
			})
			local reset = TweenService:Create(chip, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(20, 25, 36)
			})
			flash:Play()
			flash.Completed:Connect(function() reset:Play() end)

			onSelect(val)
		end)
	end
	return row
end

-- ================== INITIALIZE TABS & PAGES ==================

-- [TAB 1] MOVEMENT 🏃 (Default)
local movePage = registerTab("move", "Move", "🏃", true)

local walkControl = addInputToggleRow(movePage, "Walk Speed", state.speedValue, state.speedEnabled, function(_, render)
	state.speedEnabled = not state.speedEnabled
	render(state.speedEnabled)
	if humanoid then
		humanoid.WalkSpeed = state.speedEnabled and (tonumber(state.speedValue) or 16) or state.baseWalkSpeed
	end
end, function(val)
	state.speedValue = val
	if state.speedEnabled and humanoid then humanoid.WalkSpeed = val end
end)

addPresetChips(movePage, {20, 40, 60, 80, 100}, function(val)
	walkControl.setVal(val)
end)

local tpControl = addInputToggleRow(movePage, "TP Walk", state.tpWalkSpeed, state.tpWalkEnabled, function(_, render)
	state.tpWalkEnabled = not state.tpWalkEnabled
	render(state.tpWalkEnabled)
	applyTPWalk(state.tpWalkEnabled)
end, function(val)
	state.tpWalkSpeed = val
end)

addPresetChips(movePage, {1, 2, 3, 4, 5}, function(val)
	tpControl.setVal(val)
end)

-- [TAB 2] UTILITIES ⚙️
local utilPage = registerTab("util", "Util", "⚙️", false)

addToggleRow(utilPage, "Instant Interact", state.instantInteract, function(_, render)
	state.instantInteract = not state.instantInteract
	render(state.instantInteract)
end)

addToggleRow(utilPage, "Infinite Jump", state.infiniteJump, function(_, render)
	state.infiniteJump = not state.infiniteJump
	render(state.infiniteJump)
end)

addToggleRow(utilPage, "God Mode", state.godMode, function(_, render)
	state.godMode = not state.godMode
	render(state.godMode)
	applyGodMode(state.godMode)
end)

addToggleRow(utilPage, "Noclip", state.noclip, function(_, render)
	state.noclip = not state.noclip
	render(state.noclip)
	applyNoclip(state.noclip)
end)

addToggleRow(utilPage, "Anti Ragdoll", state.antiRagdoll, function(_, render)
	state.antiRagdoll = not state.antiRagdoll
	render(state.antiRagdoll)
	applyAntiRagdoll(state.antiRagdoll)
end)

-- [TAB 3] VISUAL 👁️
local visualPage = registerTab("visual", "Visual", "👁️", false)

addToggleRow(visualPage, "Player ESP", state.esp, function(_, render)
	state.esp = not state.esp
	render(state.esp)
	applyESP(state.esp)
end)

addToggleRow(visualPage, "ESP Team Colors", state.espTeamMode, function(_, render)
	state.espTeamMode = not state.espTeamMode
	render(state.espTeamMode)
end)

addToggleRow(visualPage, "Bot ESP", state.botEsp, function(_, render)
	state.botEsp = not state.botEsp
	render(state.botEsp)
	applyBotESP(state.botEsp)
end)

addToggleRow(visualPage, "FPS Booster", state.fpsBooster, function(_, render)
	state.fpsBooster = not state.fpsBooster
	render(state.fpsBooster)
	applyFPSBooster(state.fpsBooster)
end)

addToggleRow(visualPage, "Full Bright", state.fullBright, function(_, render)
	state.fullBright = not state.fullBright
	render(state.fullBright)
	applyFullBright(state.fullBright)
end)

-- Glossy Blue Battery Saver Button with Lightning
local stSpecialRow = Instance.new("Frame")
stSpecialRow.Size = UDim2.new(1, 0, 0, 40)
stSpecialRow.BackgroundTransparency = 1
stSpecialRow.LayoutOrder = getOrder()
stSpecialRow.Parent = visualPage

local stBtnWrapper = Instance.new("Frame")
stBtnWrapper.Size = UDim2.new(1, -6, 1, -4)
stBtnWrapper.Position = UDim2.new(0, 3, 0, 2)
stBtnWrapper.BackgroundColor3 = Color3.fromRGB(6, 25, 48)
stBtnWrapper.BorderSizePixel = 0
stBtnWrapper.Parent = stSpecialRow
Instance.new("UICorner", stBtnWrapper).CornerRadius = UDim.new(1, 0)

local wrapperStroke = Instance.new("UIStroke")
wrapperStroke.Color = Color3.fromRGB(0, 175, 255)
wrapperStroke.Thickness = 1.8
wrapperStroke.Parent = stBtnWrapper

local stBtn = Instance.new("TextButton")
stBtn.Size = UDim2.new(1, 0, 1, 0)
stBtn.BackgroundTransparency = 1
stBtn.Text = ""
stBtn.Parent = stBtnWrapper

local highlight = Instance.new("Frame")
highlight.Size = UDim2.new(1, -8, 0.45, 0)
highlight.Position = UDim2.new(0, 4, 0, 2)
highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
highlight.BorderSizePixel = 0
highlight.Parent = stBtnWrapper

local hlCorner = Instance.new("UICorner")
hlCorner.CornerRadius = UDim.new(1, 0)
hlCorner.Parent = highlight

local hlGradient = Instance.new("UIGradient")
hlGradient.Rotation = 90
hlGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.45),
	NumberSequenceKeypoint.new(1, 1.0)
})
hlGradient.Parent = highlight

local innerGlow = Instance.new("Frame")
innerGlow.Size = UDim2.new(1, 0, 1, 0)
innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
innerGlow.BackgroundTransparency = 0
innerGlow.ZIndex = 0
innerGlow.Parent = stBtnWrapper
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(1, 0)

local innerShadow = Instance.new("UIGradient")
innerShadow.Rotation = 90
innerShadow.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 130, 235)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 70, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 60))
})
innerShadow.Parent = innerGlow

local stText = Instance.new("TextLabel")
stText.Size = UDim2.new(1, 0, 1, 0)
stText.BackgroundTransparency = 1
stText.Text = "⚡ BATTERY SAVER"
stText.TextColor3 = Color3.fromRGB(240, 250, 255)
stText.Font = Enum.Font.GothamBold
stText.TextSize = 11.5
stText.ZIndex = 2
stText.Parent = stBtnWrapper

stBtn.MouseEnter:Connect(function()
	TweenService:Create(innerShadow, TweenInfo.new(0.2), {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 165, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 95, 185)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 35, 90))
		})
	}):Play()
	TweenService:Create(wrapperStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 230, 255)}):Play()
end)

stBtn.MouseLeave:Connect(function()
	TweenService:Create(innerShadow, TweenInfo.new(0.2), {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 130, 235)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 70, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 60))
		})
	}):Play()
	TweenService:Create(wrapperStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 175, 255)}):Play()
end)

stBtn.MouseButton1Down:Connect(function()
	TweenService:Create(stBtnWrapper, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -12, 1, -8),
		Position = UDim2.new(0, 6, 0, 4)
	}):Play()
end)

stBtn.MouseButton1Up:Connect(function()
	TweenService:Create(stBtnWrapper, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -6, 1, -4),
		Position = UDim2.new(0, 3, 0, 2)
	}):Play()
end)

stBtn.MouseButton1Click:Connect(function()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(150, 230, 255)
	flash.BackgroundTransparency = 0.4
	flash.ZIndex = 5
	flash.Parent = stBtnWrapper
	Instance.new("UICorner", flash).CornerRadius = UDim.new(1, 0)
	
	TweenService:Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	task.delay(0.35, function() flash:Destroy() end)

	applyScreenTime(true)
end)

-- [TAB 4] WAYPOINTS 📍
local waypointsPage = registerTab("points", "Point", "📍", false)

local spotGrid = Instance.new("Frame")
spotGrid.Size = UDim2.new(1, 0, 0, 28)
spotGrid.BackgroundTransparency = 1
spotGrid.LayoutOrder = getOrder()
spotGrid.Parent = waypointsPage

local clearGrid = Instance.new("Frame")
clearGrid.Size = UDim2.new(1, 0, 0, 26)
clearGrid.BackgroundTransparency = 1
clearGrid.LayoutOrder = getOrder()
clearGrid.Parent = waypointsPage

local spotButtons = {}

local function resetSpotUI(slot)
	state["savedPosition" .. slot] = nil
	if spotButtons[slot] then
		spotButtons[slot].Text = "Spot " .. slot
		spotButtons[slot].BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	end
end

local function makeGridSpotBtn(slot, posX, sizeX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(sizeX, -4, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	btn.BorderSizePixel = 0
	btn.Text = "Spot " .. slot
	btn.TextColor3 = Color3.fromRGB(225, 235, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = spotGrid

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	spotButtons[slot] = btn

	btn.MouseButton1Click:Connect(function()
		local key = "savedPosition" .. slot
		if state[key] then
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then root.CFrame = CFrame.new(state[key]) end
			resetSpotUI(slot)
		else
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				state[key] = root.Position
				btn.Text = "Go " .. slot
				btn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
			end
		end
	end)
end

local function makeGridClearBtn(slot, posX, sizeX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(sizeX, -4, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(185, 45, 55)
	btn.BorderSizePixel = 0
	btn.Text = "Clear " .. slot
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = clearGrid

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		resetSpotUI(slot)
	end)
end

makeGridSpotBtn(1, 0, 0.5)
makeGridSpotBtn(2, 0.5, 0.5)

makeGridClearBtn(1, 0, 0.5)
makeGridClearBtn(2, 0.5, 0.5)

-- [TAB 5] MORE TOOLS 🧰
local toolsPage = registerTab("tools", "Tools", "🧰", false)

-- 1. Auto Clicker
addRefinedToolButton(toolsPage, "Auto Clicker", "⚡", Color3.fromRGB(255, 150, 0), function()
	launchAutoClickerScript()
end)

-- 2. Stalker
addRefinedToolButton(toolsPage, "Stalker", "🎯", Color3.fromRGB(255, 65, 80), function()
	launchStalkerScript()
end)

-- 3. Aiming (Aimbot)
addRefinedToolButton(toolsPage, "Aiming (Aimbot)", "👁", Color3.fromRGB(170, 85, 255), function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/DanielHubll/DanielHubll/refs/heads/main/Aimbot%20Mobile"))()
	end)
end)

-- 4. Fly GUI (V3)
addRefinedToolButton(toolsPage, "Fly GUI (V3)", "🚀", Color3.fromRGB(0, 195, 255), function()
	launchFlyScript()
end)

-- 5. Anti AFK
addRefinedToolButton(toolsPage, "Anti AFK", "🛡", Color3.fromRGB(0, 215, 125), function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
	end)
end)

-- 6. Player Teleport
addRefinedToolButton(toolsPage, "Player Teleport", "📍", Color3.fromRGB(100, 140, 255), function()
	launchPlayerTeleportScript()
end)

-- 7. Rejoin Place
addRefinedToolButton(toolsPage, "Rejoin Place", "🔄", Color3.fromRGB(0, 210, 220), function()
	pcall(function()
		if #Players:GetPlayers() <= 1 then
			TeleportService:Teleport(game.PlaceId, player)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		end
	end)
end)

-- 8. Server Hop
addRefinedToolButton(toolsPage, "Server Hop", "🌐", Color3.fromRGB(60, 130, 255), function()
	pcall(function()
		local module = loadstring(game:HttpGet("https://raw.githubusercontent.com/LeoKholYt/roblox/main/lk_serverhop.lua"))()
		module:Teleport(game.PlaceId)
	end)
end)

-- สลับไปยังแท็บแรกเริ่ม
switchTab("move")

task.spawn(function()
	task.wait(0.08)
	adjustPanelHeight(false)
end)

-- ================== HOOKS & SYSTEM CONNECTIONS ==================
table.insert(globalConns, UserInputService.JumpRequest:Connect(function()
	if state.infiniteJump and humanoid and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

table.insert(globalConns, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if state.instantInteract then
		pcall(function() fireproximityprompt(prompt) end)
	end
end))

table.insert(globalConns, RunService.Heartbeat:Connect(function()
	if state.speedEnabled and humanoid then
		humanoid.WalkSpeed = tonumber(state.speedValue) or 16
	end
end))

state.baseWalkSpeed = humanoid and humanoid.WalkSpeed or 16
state.baseMaxHealth = humanoid and humanoid.MaxHealth or 100

-- ================== COMPLETE GLOBAL CLEANUP FUNCTION ==================
local function fullCleanup()
	if state.godMode then applyGodMode(false) end
	if state.noclip then applyNoclip(false) end
	if state.tpWalkEnabled then applyTPWalk(false) end
	if state.fpsBooster then applyFPSBooster(false) end
	if state.fullBright then applyFullBright(false) end
	if state.antiRagdoll then applyAntiRagdoll(false) end
	if state.esp then applyESP(false) end
	if state.botEsp then applyBotESP(false) end
	if state.screenTime then applyScreenTime(false) end

	if humanoid and state.baseWalkSpeed then
		humanoid.WalkSpeed = state.baseWalkSpeed
	end

	for _, c in ipairs(globalConns) do
		pcall(function() c:Disconnect() end)
	end

	if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end) end
	_G.active = false
	_G.user = ""

	local subUIs = {
		"Phumipad_ScreenTime_Overlay",
		"Phumipad_BatterySaver_Overlay",
		"StalkerUI",
		"Phumipad_AutoClicker_UI",
		"FlyGuiV3_Main",
		"TeleportUI",
		"PhumipadToolboxMinimalGui",
		"Phumipad_ESP_Storage",
		"Phumipad_BotESP_Storage"
	}
	for _, uiName in ipairs(subUIs) do
		pcall(function()
			local u = (targetContainer and targetContainer:FindFirstChild(uiName))
				or playerGui:FindFirstChild(uiName)
				or (CoreGui and CoreGui:FindFirstChild(uiName))
			if u then u:Destroy() end
		end)
	end

	_G.PhumipadCleanup = nil
end

_G.PhumipadCleanup = fullCleanup

closeBtn.MouseButton1Click:Connect(function()
	fullCleanup()
end)

miniBtn.MouseButton1Click:Connect(function()
	f.Visible = false
	openBtn.Position = UDim2.new(0, 16, 0, 50)
	openBtn.Visible = true
end)
