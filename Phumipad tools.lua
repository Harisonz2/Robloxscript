-- =========================================================================
--   PHUMIPAD TOOLBOX [v2.5 PRO EDITION] - MODERN CYBER-GLASS UI
--   Retains 100% Original Features + Upgraded UX/UI, New Utilities & Patch Log
-- =========================================================================

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
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	UserInputService.MouseIconEnabled = true
end)

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

-- ฟังก์ชันช่วยระบบลากหน้าต่าง (Universal Smooth Draggable Helper)
local function makeDraggable(dragHandle, targetFrame)
	local dragging, dragStart, startPos = false, nil, nil
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ================== STATE ==================
local state = {
	ui = nil,
	frame = nil,
	isFolded = false,
	savedExpandedHeight = 360,
	-- Movement (Original + Upgraded)
	speedEnabled = false,
	speedValue = 16,
	baseWalkSpeed = 16,
	tpWalkEnabled = false,
	tpWalkSpeed = 1,
	jumpEnabled = false,
	jumpValue = 50,
	baseJumpPower = 50,
	baseJumpHeight = 7.2,
	gravityEnabled = false,
	gravityValue = 196.2,
	baseGravity = Workspace.Gravity,
	-- Utilities & Visual (Original + Upgraded)
	instantInteract = false,
	infiniteJump = false,
	godMode = false,
	noclip = false,
	antiRagdoll = false,
	spinBotEnabled = false,
	spinSpeed = 20,
	clickTpEnabled = false,
	builtInAntiAfk = true,
	fullBright = false,
	timeLockEnabled = false,
	timeLockValue = 14,
	baseClockTime = Lighting.ClockTime,
	fovEnabled = false,
	fovValue = 70,
	baseFov = 70,
	esp = false,
	espTeamMode = true,
	botEsp = false,
	fpsBooster = false,
	screenTime = false,
	fpsHudEnabled = false,
	baseMaxHealth = 100,
	-- Runtime connections
	_noclipConn = nil,
	_antiRDConns = {},
	_fbConn = nil,
	_timeConn = nil,
	_espConn = nil,
	_botEspConn = nil,
	_botDescConn = nil,
	_tpWalkConn = nil,
	_fpsConn = nil,
	_spinConn = nil,
	-- Backups & ESP Storage
	fbBackup = nil,
	potatoBackup = nil,
	savedPosition1 = nil,
	savedPosition2 = nil,
	savedPosition3 = nil,
	savedPosition4 = nil,
	savedNames = {"Spot 1", "Spot 2", "Spot 3", "Spot 4"},
	espFolder = nil,
	espCache = {},
	botEspFolder = nil,
	botEspCache = {}
}

local globalConns = {}
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ================== MODERN TOAST NOTIFICATION SYSTEM (NEW) ==================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "Phumipad_Toast_Notifications"
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 999990
safeParentGui(notifGui)

local notifContainer = Instance.new("Frame")
notifContainer.Size = UDim2.new(0, 250, 1, -30)
notifContainer.Position = UDim2.new(1, -262, 0, 15)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = notifGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notifContainer

local function sendNotification(titleText, msgText, accentColor)
	accentColor = accentColor or Color3.fromRGB(0, 210, 255)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 52)
	card.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = notifContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = accentColor
	cStroke.Thickness = 1.2
	cStroke.Transparency = 1
	cStroke.Parent = card

	local sideBar = Instance.new("Frame")
	sideBar.Size = UDim2.new(0, 4, 1, 0)
	sideBar.BackgroundColor3 = accentColor
	sideBar.BorderSizePixel = 0
	sideBar.Parent = card

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.new(1, -20, 0, 18)
	tLbl.Position = UDim2.new(0, 12, 0, 6)
	tLbl.BackgroundTransparency = 1
	tLbl.Text = titleText
	tLbl.TextColor3 = Color3.fromRGB(245, 250, 255)
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 11
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.TextTransparency = 1
	tLbl.Parent = card

	local mLbl = Instance.new("TextLabel")
	mLbl.Size = UDim2.new(1, -20, 0, 18)
	mLbl.Position = UDim2.new(0, 12, 0, 24)
	mLbl.BackgroundTransparency = 1
	mLbl.Text = msgText
	mLbl.TextColor3 = Color3.fromRGB(165, 180, 205)
	mLbl.Font = Enum.Font.GothamMedium
	mLbl.TextSize = 10
	mLbl.TextXAlignment = Enum.TextXAlignment.Left
	mLbl.TextTruncate = Enum.TextTruncate.AtEnd
	mLbl.TextTransparency = 1
	mLbl.Parent = card

	local progBar = Instance.new("Frame")
	progBar.Size = UDim2.new(1, 0, 0, 2)
	progBar.Position = UDim2.new(0, 0, 1, -2)
	progBar.BackgroundColor3 = accentColor
	progBar.BorderSizePixel = 0
	progBar.Parent = card

	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(cStroke, TweenInfo.new(0.25), {Transparency = 0.2}):Play()
	TweenService:Create(tLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
	TweenService:Create(mLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
	TweenService:Create(progBar, TweenInfo.new(2.6, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

	task.delay(2.6, function()
		if card and card.Parent then
			TweenService:Create(card, TweenInfo.new(0.25), {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}):Play()
			TweenService:Create(cStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
			TweenService:Create(tLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			TweenService:Create(mLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			task.wait(0.26)
			pcall(function() card:Destroy() end)
		end
	end)
end

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
		copied = true
	elseif toclipboard then
		toclipboard(gameName)
		copied = true
	elseif syn and syn.write_clipboard then
		syn.write_clipboard(gameName)
		copied = true
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
	slideText.Position = UDim2.new(0, 8, 0, 0)
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
	Instance.new("UICorner", slideKnob).CornerRadius = UDim.new(0, 11)

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

-- ================== CORE LOGIC & FUNCTIONS ==================
local function applyJumpPower(on)
	if not humanoid then return end
	if on then
		if humanoid.UseJumpPower then
			humanoid.JumpPower = tonumber(state.jumpValue) or 50
		else
			humanoid.JumpHeight = tonumber(state.jumpValue) or 7.2
		end
	else
		if humanoid.UseJumpPower then
			humanoid.JumpPower = state.baseJumpPower
		else
			humanoid.JumpHeight = state.baseJumpHeight
		end
	end
end

local function applyGravity(on)
	if on then
		Workspace.Gravity = tonumber(state.gravityValue) or 196.2
	else
		Workspace.Gravity = state.baseGravity or 196.2
	end
end

local function applySpinBot(on)
	if state._spinConn then
		state._spinConn:Disconnect()
		state._spinConn = nil
	end
	if on then
		state._spinConn = RunService.RenderStepped:Connect(function()
			if state.spinBotEnabled and hrp then
				local speed = tonumber(state.spinSpeed) or 20
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed), 0)
			end
		end)
	end
end

local function applyFOV(on)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if on then
		cam.FieldOfView = tonumber(state.fovValue) or 70
	else
		cam.FieldOfView = state.baseFov
	end
end

local function applyTimeLock(on)
	if state._timeConn then
		state._timeConn:Disconnect()
		state._timeConn = nil
	end
	if on then
		Lighting.ClockTime = tonumber(state.timeLockValue) or 14
		state._timeConn = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
			if state.timeLockEnabled then
				Lighting.ClockTime = tonumber(state.timeLockValue) or 14
			end
		end)
	else
		Lighting.ClockTime = state.baseClockTime or 14
	end
end

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

-- ================== ULTRA-RELIABLE ESP ENGINE (UPGRADED WITH HP%) ==================
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
						bb.Size = UDim2.new(0, 260, 0, 56)
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
						label.TextSize = 15
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

					local hpPercent = math.clamp(math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100), 0, 100)
					if myRoot then
						local dist = math.floor((myRoot.Position - root.Position).Magnitude)
						data.Label.Text = string.format("%s\n[%d studs | %d%% HP]", plr.DisplayName or plr.Name, dist, hpPercent)
					else
						data.Label.Text = string.format("%s [%d%% HP]", plr.DisplayName or plr.Name, hpPercent)
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
	Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(255, 128, 0), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 80, 150),
	Color3.fromRGB(80, 255, 120), Color3.fromRGB(180, 255, 0), Color3.fromRGB(255, 180, 0),
	Color3.fromRGB(100, 180, 255), Color3.fromRGB(200, 100, 255), Color3.fromRGB(255, 100, 100),
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
		label.TextSize = 15
		label.Text = bot.Name
		label.Parent = bb

		state.botEspCache[bot] = {
			Highlight = hl, Billboard = bb, Label = label,
			Root = root, Head = head, Color = col
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
					local hpPercent = math.clamp(math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100), 0, 100)
					if myRoot then
						local dist = math.floor((myRoot.Position - data.Root.Position).Magnitude)
						data.Label.Text = string.format("%s\n[%d studs | %d%% HP]", bot.Name, dist, hpPercent)
					else
						data.Label.Text = string.format("%s [%d%% HP]", bot.Name, hpPercent)
					end
				else
					data.Highlight.Enabled = false
					data.Billboard.Enabled = false
				end
			end
		end
	end)
end

-- ================== FPS / PING MONITOR WIDGET ==================
local fpsHudGui = nil
local function toggleFpsHud(on)
	state.fpsHudEnabled = on
	if fpsHudGui then
		fpsHudGui:Destroy()
		fpsHudGui = nil
	end
	if not on then return end

	local sgHud = Instance.new("ScreenGui")
	sgHud.Name = "Phumipad_FPS_Ping_Monitor"
	sgHud.ResetOnSpawn = false
	safeParentGui(sgHud)
	fpsHudGui = sgHud

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 165, 0, 36)
	frame.Position = UDim2.new(0.5, -82, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Parent = sgHud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = Color3.fromRGB(0, 210, 255)
	fStroke.Thickness = 1.2
	fStroke.Parent = frame
	makeDraggable(frame, frame)

	local hudText = Instance.new("TextLabel")
	hudText.Size = UDim2.new(1, 0, 1, 0)
	hudText.BackgroundTransparency = 1
	hudText.Text = "FPS: -- | Ping: -- ms"
	hudText.TextColor3 = Color3.fromRGB(240, 245, 255)
	hudText.Font = Enum.Font.GothamBold
	hudText.TextSize = 11
	hudText.Parent = frame

	task.spawn(function()
		local lastTime = os.clock()
		local frameCount = 0
		while state.fpsHudEnabled and fpsHudGui == sgHud do
			frameCount = frameCount + 1
			local currentTime = os.clock()
			if currentTime - lastTime >= 1 then
				local fps = frameCount
				frameCount = 0
				lastTime = currentTime
				local ping = 0
				pcall(function()
					ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				hudText.Text = string.format("⚡ FPS: %d  |  📶 %d ms", fps, ping)
			end
			RunService.RenderStepped:Wait()
		end
	end)
end

table.insert(globalConns, player.CharacterAdded:Connect(function(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	hrp       = char:WaitForChild("HumanoidRootPart")

	state.baseWalkSpeed = humanoid.WalkSpeed
	state.baseMaxHealth = humanoid.MaxHealth
	state.baseJumpPower = humanoid.JumpPower
	state.baseJumpHeight = humanoid.JumpHeight

	if state.speedEnabled   then humanoid.WalkSpeed = tonumber(state.speedValue) or 16 end
	if state.jumpEnabled    then applyJumpPower(true) end
	if state.gravityEnabled then applyGravity(true) end
	if state.tpWalkEnabled  then applyTPWalk(true) end
	if state.godMode        then applyGodMode(true) end
	if state.noclip         then applyNoclip(true) end
	if state.antiRagdoll    then applyAntiRagdoll(true) end
	if state.fullBright     then applyFullBright(true) end
	if state.fovEnabled     then applyFOV(true) end
end))

-- =========================================================================
-- ============ SLEEK MODERN CYBER-GLASS MAIN GUI PANEL ====================
-- =========================================================================

local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadToolboxMinimalGui"
sg.ResetOnSpawn = false
safeParentGui(sg)

local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 286, 0, 360)
f.Position = UDim2.new(0.04, 0, 0.45, -180)
f.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
f.BorderSizePixel = 0
f.Active = true
f.ClipsDescendants = true
f.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = f

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 195, 255)
stroke.Thickness = 1.4
stroke.Transparency = 0.25
stroke.Parent = f

local bgGrad = Instance.new("UIGradient")
bgGrad.Rotation = 135
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 21, 34)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(11, 14, 22)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 16))
})
bgGrad.Parent = f

-- ================== (1) DRAGGABLE FLOATING 'SHOW MENU' BUTTON ==================
local openBtn = Instance.new("TextButton")
openBtn.Name = "HighTechFloatingDock"
openBtn.Size = UDim2.new(0, 128, 0, 38)
openBtn.Position = UDim2.new(0, 18, 0, 55)
openBtn.BackgroundColor3 = Color3.fromRGB(12, 22, 38)
openBtn.BorderSizePixel = 0
openBtn.Text = "  ⚡ Show Menu"
openBtn.TextColor3 = Color3.fromRGB(240, 250, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Visible = false
openBtn.Active = true
openBtn.AutoButtonColor = false
openBtn.ZIndex = 250
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 225, 255)
openStroke.Thickness = 1.8
openStroke.Parent = openBtn

local dockGrad = Instance.new("UIGradient")
dockGrad.Rotation = 45
dockGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 45, 85)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 24, 48)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 55, 105))
})
dockGrad.Parent = openBtn

local pulseDot = Instance.new("Frame")
pulseDot.Size = UDim2.new(0, 8, 0, 8)
pulseDot.Position = UDim2.new(0, 12, 0.5, -4)
pulseDot.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
pulseDot.BorderSizePixel = 0
pulseDot.ZIndex = 251
pulseDot.Parent = openBtn
Instance.new("UICorner", pulseDot).CornerRadius = UDim.new(1, 0)

do
	local dragging, dragStart, startPos, hasMoved = false, nil, nil, false
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

-- ================== SLEEK HEADER BAR (WITH '-' FOLD & 'X' CLOSE) ==================
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 42)
bar.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 14)

local barLine = Instance.new("Frame")
barLine.Size = UDim2.new(1, 0, 0, 1)
barLine.Position = UDim2.new(0, 0, 1, -1)
barLine.BackgroundColor3 = Color3.fromRGB(35, 45, 68)
barLine.BorderSizePixel = 0
barLine.Parent = bar

local brandBadge = Instance.new("Frame")
brandBadge.Size = UDim2.new(0, 24, 0, 24)
brandBadge.Position = UDim2.new(0, 10, 0.5, -12)
brandBadge.BackgroundColor3 = Color3.fromRGB(0, 185, 255)
brandBadge.BorderSizePixel = 0
brandBadge.Parent = bar
Instance.new("UICorner", brandBadge).CornerRadius = UDim.new(0, 6)

local brandIcon = Instance.new("TextLabel")
brandIcon.Size = UDim2.new(1, 0, 1, 0)
brandIcon.BackgroundTransparency = 1
brandIcon.Text = "P"
brandIcon.TextColor3 = Color3.fromRGB(10, 14, 22)
brandIcon.Font = Enum.Font.GothamBlack
brandIcon.TextSize = 14
brandIcon.Parent = brandBadge

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -135, 0, 16)
title.Position = UDim2.new(0, 40, 0, 6)
title.BackgroundTransparency = 1
title.Text = "PHUMIPAD PRO"
title.TextColor3 = Color3.fromRGB(245, 250, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 11.5
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, -135, 0, 12)
subTitle.Position = UDim2.new(0, 40, 0, 22)
subTitle.BackgroundTransparency = 1
subTitle.Text = "v2.5 Cyber Edition • R-Ctrl"
subTitle.TextColor3 = Color3.fromRGB(0, 205, 255)
subTitle.Font = Enum.Font.GothamMedium
subTitle.TextSize = 8.5
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Parent = bar

-- ปุ่มย่อเป็น Floating Show Menu Button ('•')
local dockHideBtn = Instance.new("TextButton")
dockHideBtn.Name = "DockHideButton"
dockHideBtn.Size = UDim2.new(0, 24, 0, 24)
dockHideBtn.Position = UDim2.new(1, -88, 0.5, -12)
dockHideBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
dockHideBtn.BorderSizePixel = 0
dockHideBtn.Text = "⚡"
dockHideBtn.TextColor3 = Color3.fromRGB(0, 215, 255)
dockHideBtn.Font = Enum.Font.GothamBold
dockHideBtn.TextSize = 11
dockHideBtn.Parent = bar
Instance.new("UICorner", dockHideBtn).CornerRadius = UDim.new(0, 6)

-- (2) ปุ่มพับ/ย่อหน้าต่าง Collapse/Minimize ('-')
local miniBtn = Instance.new("TextButton")
miniBtn.Name = "CollapseButton"
miniBtn.Size = UDim2.new(0, 24, 0, 24)
miniBtn.Position = UDim2.new(1, -60, 0.5, -12)
miniBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
miniBtn.BorderSizePixel = 0
miniBtn.Text = "-"
miniBtn.TextColor3 = Color3.fromRGB(200, 215, 240)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 15
miniBtn.Parent = bar
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 6)

-- (3) ปุ่มปิดหน้าต่าง Close ('X')
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(225, 50, 70)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ================== HIGH-TECH TOP TAB BAR ==================
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TopTabBar"
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(15, 19, 29)
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.ClipsDescendants = true
tabBar.Parent = f
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(34, 42, 62)
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
scroll.Size = UDim2.new(1, 0, 1, -86)
scroll.Position = UDim2.new(0, 0, 0, 86)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
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
statusCard.BackgroundColor3 = Color3.fromRGB(18, 23, 35)
statusCard.BorderSizePixel = 0
statusCard.LayoutOrder = 0
statusCard.Parent = scroll
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)

local scStroke = Instance.new("UIStroke")
scStroke.Color = Color3.fromRGB(40, 52, 78)
scStroke.Thickness = 1
scStroke.Parent = statusCard

local gameNameLabel = Instance.new("TextLabel")
gameNameLabel.Size = UDim2.new(1, -64, 0, 18)
gameNameLabel.Position = UDim2.new(0, 10, 0, 7)
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
copyHeaderBtn.Position = UDim2.new(1, -54, 0, 7)
copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
copyHeaderBtn.BorderSizePixel = 0
copyHeaderBtn.Font = Enum.Font.GothamBold
copyHeaderBtn.TextSize = 9
copyHeaderBtn.Text = "COPY"
copyHeaderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyHeaderBtn.Parent = statusCard
Instance.new("UICorner", copyHeaderBtn).CornerRadius = UDim.new(0, 4)

local copyBusy = false
copyHeaderBtn.MouseButton1Click:Connect(function()
	if copyBusy then return end
	copyBusy = true
	local success, gName = copyGameName()
	if success then
		copyHeaderBtn.Text = "DONE"
		copyHeaderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
		sendNotification("Copied Game Name", gName, Color3.fromRGB(0, 200, 125))
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
timeLabel.Position = UDim2.new(0, 10, 0, 31)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Play: 00:00 | Idle: 00:00"
timeLabel.TextColor3 = Color3.fromRGB(150, 165, 190)
timeLabel.Font = Enum.Font.GothamMedium
timeLabel.TextSize = 9.5
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.TextTruncate = Enum.TextTruncate.AtEnd
timeLabel.Parent = statusCard

local kickWarningLabel = Instance.new("TextLabel")
kickWarningLabel.Size = UDim2.new(0, 80, 0, 14)
kickWarningLabel.Position = UDim2.new(1, -88, 0, 31)
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
	gameNameLabel.Text = "🎮 " .. cachedGameName
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

makeDraggable(bar, f)

do
	local resizing = false
	local resizeStart = nil
	local startSize = nil
	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if state.isFolded then return end
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
			local targetW = math.clamp(startSize.X + delta.X, 250, 620)
			local targetH = math.clamp(startSize.Y + delta.Y, 180, 800)
			state.savedExpandedHeight = targetH
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
	move   = Color3.fromRGB(0, 230, 130),
	util   = Color3.fromRGB(0, 195, 255),
	visual = Color3.fromRGB(210, 70, 255),
	points = Color3.fromRGB(255, 175, 25),
	tools  = Color3.fromRGB(255, 60, 95),
	logs   = Color3.fromRGB(0, 240, 200)
}

local function adjustPanelHeight(animate)
	if state.isFolded then return end
	task.defer(function()
		local activeData = tabItems[activeTabId]
		local pageHeight = activeData and activeData.contentLayout.AbsoluteContentSize.Y or 0
		local totalHeight = 48 + 38 + statusCard.Size.Y.Offset + scrollPadding.PaddingTop.Offset + scrollPadding.PaddingBottom.Offset + pageHeight + 16
		local cam = Workspace.CurrentCamera
		local maxAllowedHeight = cam and (cam.ViewportSize.Y * 0.85) or 600
		local finalHeight = math.clamp(totalHeight, 200, maxAllowedHeight)
		state.savedExpandedHeight = finalHeight

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
			TweenService:Create(data.button, TweenInfo.new(0.18), {BackgroundColor3 = darkTint}):Play()
			TweenService:Create(data.stroke, TweenInfo.new(0.18), {Color = accent}):Play()
			TweenService:Create( stroke, TweenInfo.new(0.25), {Color = accent}):Play()
			data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			TweenService:Create(data.button, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(18, 22, 32)}):Play()
			TweenService:Create(data.stroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(35, 42, 60)}):Play()
			data.button.TextColor3 = Color3.fromRGB(130, 145, 170)
		end
	end
	adjustPanelHeight(true)
end

local function registerTab(id, name, emoji, isDefault)
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = id .. "TabButton"
	tabBtn.Size = UDim2.new(0, 0, 1, -6)
	tabBtn.AutomaticSize = Enum.AutomaticSize.X
	tabBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	tabBtn.BorderSizePixel = 0
	tabBtn.Text = (emoji and (emoji .. " ") or "") .. name:upper()
	tabBtn.TextColor3 = Color3.fromRGB(130, 145, 170)
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = 10
	tabBtn.AutoButtonColor = false
	tabBtn.Parent = tabBar
	Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(35, 42, 60)
	tStroke.Thickness = 1
	tStroke.Parent = tabBtn

	local tPadding = Instance.new("UIPadding")
	tPadding.PaddingLeft = UDim.new(0, 8)
	tPadding.PaddingRight = UDim.new(0, 8)
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
	pageLayout.Padding = UDim.new(0, 6)
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

-- ================== UPGRADED COMPONENT BUILDER FUNCTIONS ==================
local function addRefinedToolButton(parent, name, iconSymbol, accentColor, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(36, 44, 64)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 22, 0, 22)
	badge.Position = UDim2.new(0, 5, 0.5, -11)
	badge.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
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
		TweenService:Create(row, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(26, 32, 48)}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = accentColor}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = accentColor, Position = UDim2.new(1, -20, 0, 0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(18, 22, 34)}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(36, 44, 64)}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(110, 125, 150), Position = UDim2.new(1, -24, 0, 0)}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		sendNotification("Tool Launched", name, accentColor)
		local ok, err = pcall(onClick)
		if not ok then warn("[Phumipad Tool Error]: " .. tostring(err)) end
	end)
	return row
end

-- UPGRADED: Animated Pill Switch Toggle Row
local function addToggleRow(parent, name, defaultOn, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(34, 42, 60)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -64, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(220, 230, 245)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 42, 0, 20)
	pill.Position = UDim2.new(1, -50, 0.5, -10)
	pill.BorderSizePixel = 0
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.Parent = row
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = pill
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function render(v)
		local targetBg = v and Color3.fromRGB(0, 210, 130) or Color3.fromRGB(38, 45, 64)
		local targetPos = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		local targetStroke = v and Color3.fromRGB(0, 180, 115) or Color3.fromRGB(34, 42, 60)
		TweenService:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetBg}):Play()
		TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = targetStroke}):Play()
	end
	render(defaultOn)

	pill.MouseButton1Click:Connect(function()
		onClick(pill, render)
	end)
end

-- UPGRADED: Animated Input + Pill Switch Row
local function addInputToggleRow(parent, name, defaultVal, defaultOn, onToggle, onValChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(34, 42, 60)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.48, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(220, 230, 245)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 44, 0, 20)
	box.Position = UDim2.new(1, -100, 0.5, -10)
	box.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(0, 225, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.Parent = row
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 42, 0, 20)
	pill.Position = UDim2.new(1, -50, 0.5, -10)
	pill.BorderSizePixel = 0
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.Parent = row
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = pill
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function render(v)
		local targetBg = v and Color3.fromRGB(0, 210, 130) or Color3.fromRGB(38, 45, 64)
		local targetPos = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		local targetStroke = v and Color3.fromRGB(0, 180, 115) or Color3.fromRGB(34, 42, 60)
		TweenService:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetBg}):Play()
		TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = targetStroke}):Play()
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

	pill.MouseButton1Click:Connect(function()
		onToggle(pill, render)
	end)

	return {
		box = box,
		btn = pill,
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
		chip.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
		chip.BorderSizePixel = 0
		chip.Text = tostring(val)
		chip.TextColor3 = Color3.fromRGB(185, 205, 235)
		chip.Font = Enum.Font.GothamBold
		chip.TextSize = 10
		chip.AutoButtonColor = false
		chip.LayoutOrder = i
		chip.Parent = row
		Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(38, 48, 68)
		cStroke.Thickness = 1
		cStroke.Parent = chip

		chip.MouseEnter:Connect(function()
			TweenService:Create(chip, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 40, 58)}):Play()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(0, 200, 255)}):Play()
		end)
		chip.MouseLeave:Connect(function()
			TweenService:Create(chip, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 25, 38)}):Play()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(38, 48, 68)}):Play()
		end)
		chip.MouseButton1Click:Connect(function()
			local flash = TweenService:Create(chip, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(0, 185, 255)})
			local reset = TweenService:Create(chip, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 25, 38)})
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
addPresetChips(movePage, {20, 40, 60, 80, 100}, function(val) walkControl.setVal(val) end)

local tpControl = addInputToggleRow(movePage, "TP Walk", state.tpWalkSpeed, state.tpWalkEnabled, function(_, render)
	state.tpWalkEnabled = not state.tpWalkEnabled
	render(state.tpWalkEnabled)
	applyTPWalk(state.tpWalkEnabled)
end, function(val)
	state.tpWalkSpeed = val
end)
addPresetChips(movePage, {1, 2, 3, 4, 5}, function(val) tpControl.setVal(val) end)

local jumpControl = addInputToggleRow(movePage, "Jump Power", state.jumpValue, state.jumpEnabled, function(_, render)
	state.jumpEnabled = not state.jumpEnabled
	render(state.jumpEnabled)
	applyJumpPower(state.jumpEnabled)
end, function(val)
	state.jumpValue = val
	if state.jumpEnabled then applyJumpPower(true) end
end)
addPresetChips(movePage, {20, 40, 60, 80, 100}, function(val) jumpControl.setVal(val) end)

-- NEW: Gravity Control in Move Tab
local gravControl = addInputToggleRow(movePage, "Gravity Control", 196, state.gravityEnabled, function(_, render)
	state.gravityEnabled = not state.gravityEnabled
	render(state.gravityEnabled)
	applyGravity(state.gravityEnabled)
end, function(val)
	state.gravityValue = val
	if state.gravityEnabled then applyGravity(true) end
end)
addPresetChips(movePage, {30, 60, 100, 150, 196}, function(val) gravControl.setVal(val) end)

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

-- NEW: Click Teleport (Ctrl + Click)
addToggleRow(utilPage, "Click TP (Ctrl + Click)", state.clickTpEnabled, function(_, render)
	state.clickTpEnabled = not state.clickTpEnabled
	render(state.clickTpEnabled)
	if state.clickTpEnabled then
		sendNotification("Click TP Enabled", "Hold Ctrl + Left Click to teleport", Color3.fromRGB(0, 210, 255))
	end
end)

-- NEW: Built-in Anti-AFK
addToggleRow(utilPage, "Built-in Anti-AFK", state.builtInAntiAfk, function(_, render)
	state.builtInAntiAfk = not state.builtInAntiAfk
	render(state.builtInAntiAfk)
end)

local spinControl = addInputToggleRow(utilPage, "SpinBot", state.spinSpeed, state.spinBotEnabled, function(_, render)
	state.spinBotEnabled = not state.spinBotEnabled
	render(state.spinBotEnabled)
	applySpinBot(state.spinBotEnabled)
end, function(val)
	state.spinSpeed = val
end)

-- [TAB 3] VISUAL 👁️
local visualPage = registerTab("visual", "Visual", "👁️", false)

addToggleRow(visualPage, "Player ESP (with HP%)", state.esp, function(_, render)
	state.esp = not state.esp
	render(state.esp)
	applyESP(state.esp)
end)

addToggleRow(visualPage, "ESP Team Colors", state.espTeamMode, function(_, render)
	state.espTeamMode = not state.espTeamMode
	render(state.espTeamMode)
end)

addToggleRow(visualPage, "Bot ESP (with HP%)", state.botEsp, function(_, render)
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

-- NEW: Time of Day Changer
local timeControl = addInputToggleRow(visualPage, "Time of Day (0-24)", state.timeLockValue, state.timeLockEnabled, function(_, render)
	state.timeLockEnabled = not state.timeLockEnabled
	render(state.timeLockEnabled)
	applyTimeLock(state.timeLockEnabled)
end, function(val)
	state.timeLockValue = math.clamp(val, 0, 24)
	if state.timeLockEnabled then applyTimeLock(true) end
end)
addPresetChips(visualPage, {0, 6, 12, 18, 21}, function(val) timeControl.setVal(val) end)

local fovControl = addInputToggleRow(visualPage, "Camera FOV", state.fovValue, state.fovEnabled, function(_, render)
	state.fovEnabled = not state.fovEnabled
	render(state.fovEnabled)
	applyFOV(state.fovEnabled)
end, function(val)
	state.fovValue = val
	if state.fovEnabled then applyFOV(true) end
end)
addPresetChips(visualPage, {70, 80, 90, 100, 120}, function(val) fovControl.setVal(val) end)

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
stText.Text = "⚡ BATTERY SAVER OVERLAY"
stText.TextColor3 = Color3.fromRGB(240, 250, 255)
stText.Font = Enum.Font.GothamBold
stText.TextSize = 11.5
stText.ZIndex = 2
stText.Parent = stBtnWrapper

stBtn.MouseButton1Click:Connect(function()
	applyScreenTime(true)
end)

-- [TAB 4] WAYPOINTS 📍
local waypointsPage = registerTab("points", "Point", "📍", false)

for i = 1, 4 do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = waypointsPage
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(36, 44, 64)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(0.42, -6, 1, -6)
	nameBox.Position = UDim2.new(0, 4, 0, 3)
	nameBox.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
	nameBox.BorderSizePixel = 0
	nameBox.Text = state.savedNames[i] or ("Spot " .. i)
	nameBox.TextColor3 = Color3.fromRGB(230, 240, 255)
	nameBox.Font = Enum.Font.GothamMedium
	nameBox.TextSize = 10.5
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = row
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 5)

	nameBox.FocusLost:Connect(function()
		if nameBox.Text == "" or string.gsub(nameBox.Text, "%s+", "") == "" then
			nameBox.Text = "Spot " .. i
		end
		state.savedNames[i] = nameBox.Text
	end)

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0.38, -4, 1, -6)
	actionBtn.Position = UDim2.new(0.42, 2, 0, 3)
	actionBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
	actionBtn.BorderSizePixel = 0
	actionBtn.Text = "Set " .. i
	actionBtn.TextColor3 = Color3.fromRGB(225, 235, 255)
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.TextSize = 10.5
	actionBtn.Parent = row
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 5)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0.2, -4, 1, -6)
	clearBtn.Position = UDim2.new(0.8, 0, 0, 3)
	clearBtn.BackgroundColor3 = Color3.fromRGB(185, 45, 55)
	clearBtn.BorderSizePixel = 0
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 10
	clearBtn.Parent = row
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

	local function updateVisual()
		local key = "savedPosition" .. i
		if state[key] then
			actionBtn.Text = "Go " .. i
			actionBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
		else
			actionBtn.Text = "Set " .. i
			actionBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
		end
	end
	updateVisual()

	actionBtn.MouseButton1Click:Connect(function()
		local key = "savedPosition" .. i
		if state[key] then
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(state[key])
				sendNotification("Teleported", "Warped to " .. (state.savedNames[i] or ("Spot " .. i)), Color3.fromRGB(255, 175, 25))
			end
		else
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				state[key] = root.Position
				updateVisual()
				sendNotification("Waypoint Saved", "Saved " .. (state.savedNames[i] or ("Spot " .. i)), Color3.fromRGB(0, 210, 130))
			end
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		state["savedPosition" .. i] = nil
		updateVisual()
	end)
end

-- =========================================================================
-- ============ ORIGINAL TOOL SUB-PANELS (100% RETAINED) ===================
-- =========================================================================

-- 1. VEHICLE SPEED ADJUST SCRIPT LAUNCHER
local function launchVehicleSpeedAdjustScript()
	local parentContainer = targetContainer or (gethui and gethui()) or game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
	if parentContainer:FindFirstChild("UniversalSpeedAdjustGui") then
		parentContainer:FindFirstChild("UniversalSpeedAdjustGui"):Destroy()
		return
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UniversalSpeedAdjustGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parentContainer

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 190, 0, 150)
	mainFrame.Position = UDim2.new(0.5, -95, 0.4, -75)
	mainFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -50, 1, 0)
	titleText.Position = UDim2.new(0, 8, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "🏎️ Speed Adjust"
	titleText.TextColor3 = Color3.fromRGB(240, 245, 255)
	titleText.TextSize = 11.5
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 20, 0, 20)
	minBtn.Position = UDim2.new(1, -44, 0, 5)
	minBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
	minBtn.Text = "-"
	minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minBtn.TextSize = 14
	minBtn.Font = Enum.Font.GothamBold
	minBtn.Parent = titleBar
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

	local closeSubBtn = Instance.new("TextButton")
	closeSubBtn.Size = UDim2.new(0, 20, 0, 20)
	closeSubBtn.Position = UDim2.new(1, -22, 0, 5)
	closeSubBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 65)
	closeSubBtn.Text = "X"
	closeSubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeSubBtn.TextSize = 11
	closeSubBtn.Font = Enum.Font.GothamBold
	closeSubBtn.Parent = titleBar
	Instance.new("UICorner", closeSubBtn).CornerRadius = UDim.new(0, 4)

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, 0, 1, -30)
	contentFrame.Position = UDim2.new(0, 0, 0, 30)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, -16, 0, 18)
	speedLabel.Position = UDim2.new(0, 8, 0, 6)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Impulse Force (Key: F):"
	speedLabel.TextColor3 = Color3.fromRGB(190, 205, 230)
	speedLabel.TextSize = 11
	speedLabel.Font = Enum.Font.GothamMedium
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = contentFrame

	local intensBox = Instance.new("TextBox")
	intensBox.Size = UDim2.new(1, -16, 0, 26)
	intensBox.Position = UDim2.new(0, 8, 0, 26)
	intensBox.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
	intensBox.Text = "10"
	intensBox.TextColor3 = Color3.fromRGB(0, 230, 140)
	intensBox.TextSize = 13
	intensBox.Font = Enum.Font.GothamBold
	intensBox.Parent = contentFrame
	Instance.new("UICorner", intensBox).CornerRadius = UDim.new(0, 5)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, -16, 0, 35)
	toggleBtn.Position = UDim2.new(0, 8, 0, 60)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	toggleBtn.Text = "OFF"
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.TextSize = 14
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Parent = contentFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

	makeDraggable(titleBar, mainFrame)

	local intens = 350
	local isEnabled = false
	intensBox:GetPropertyChangedSignal("Text"):Connect(function()
		local val = tonumber(intensBox.Text)
		if val then intens = val end
	end)

	local function toggleState()
		isEnabled = not isEnabled
		toggleBtn.Text = isEnabled and "ON" or "OFF"
		toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 200, 125) or Color3.fromRGB(180, 50, 50)
	end
	toggleBtn.MouseButton1Click:Connect(toggleState)

	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.F then toggleState() end
	end)

	local minimized = false
	local lastSize = mainFrame.Size
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			lastSize = mainFrame.Size
			contentFrame.Visible = false
			mainFrame:TweenSize(UDim2.new(lastSize.X.Scale, lastSize.X.Offset, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
			minBtn.Text = "+"
		else
			mainFrame:TweenSize(lastSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true, function()
				contentFrame.Visible = true
			end)
			minBtn.Text = "-"
		end
	end)

	local stepConnection = RunService.Stepped:Connect(function()
		if isEnabled then
			local HumanoidSubject = workspace.CurrentCamera.CameraSubject
			if HumanoidSubject and HumanoidSubject:IsA("Humanoid") then
				if HumanoidSubject.SeatPart then
					HumanoidSubject.SeatPart:ApplyImpulse(HumanoidSubject.SeatPart.CFrame.LookVector * Vector3.new(intens, intens, intens))
				end
			elseif HumanoidSubject and HumanoidSubject:IsA("BasePart") then
				HumanoidSubject:ApplyImpulse(HumanoidSubject.CFrame.LookVector * Vector3.new(intens, intens, intens))
			end
		end
	end)

	closeSubBtn.MouseButton1Click:Connect(function()
		if stepConnection then stepConnection:Disconnect() end
		if keyConn then keyConn:Disconnect() end
		screenGui:Destroy()
	end)
end

-- 2. AUTO CLICKER
local function launchAutoClickerScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("Phumipad_AutoClicker_UI")) 
		or playerGui:FindFirstChild("Phumipad_AutoClicker_UI") 
		or (CoreGui and CoreGui:FindFirstChild("Phumipad_AutoClicker_UI"))
	if existing then existing:Destroy(); return end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Phumipad_AutoClicker_UI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true 
	safeParentGui(ScreenGui)

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 230, 0, 244)
	MainFrame.Position = UDim2.new(0.5, -115, 0.38, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

	local mfStroke = Instance.new("UIStroke")
	mfStroke.Color = Color3.fromRGB(45, 52, 70)
	mfStroke.Thickness = 1.2
	mfStroke.Parent = MainFrame

	local miniCircle = Instance.new("TextButton")
	miniCircle.Name = "AutoClicker_MiniCircle"
	miniCircle.Size = UDim2.new(0, 44, 0, 44)
	miniCircle.Position = UDim2.new(0.85, 0, 0.45, 0)
	miniCircle.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
	miniCircle.BorderSizePixel = 0
	miniCircle.Text = "⚡"
	miniCircle.TextColor3 = Color3.fromRGB(255, 140, 40)
	miniCircle.Font = Enum.Font.GothamBold
	miniCircle.TextSize = 20
	miniCircle.Visible = false
	miniCircle.Active = true
	miniCircle.ZIndex = 200
	miniCircle.Parent = ScreenGui
	Instance.new("UICorner", miniCircle).CornerRadius = UDim.new(1, 0)

	local mcStroke = Instance.new("UIStroke")
	mcStroke.Color = Color3.fromRGB(255, 120, 30)
	mcStroke.Thickness = 1.8
	mcStroke.Parent = miniCircle

	do
		local dragging, dragStart, startPos, hasMoved = false, nil, nil, false
		miniCircle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; hasMoved = false; dragStart = input.Position; startPos = miniCircle.Position
			end
		end)
		miniCircle.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				if delta.Magnitude > 6 then hasMoved = true end
				if hasMoved then
					miniCircle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end
		end)
		miniCircle.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if not hasMoved then miniCircle.Visible = false; MainFrame.Visible = true end
				dragging = false; hasMoved = false
			end
		end)
	end

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
	TopBar.BorderSizePixel = 0
	TopBar.Active = true
	TopBar.Parent = MainFrame
	Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
	makeDraggable(TopBar, MainFrame)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -70, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "⚡ Auto Clicker"
	Title.TextColor3 = Color3.fromRGB(240, 245, 255)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 12
	Title.Parent = TopBar

	local MiniButton = Instance.new("TextButton")
	MiniButton.Size = UDim2.new(0, 22, 0, 22)
	MiniButton.Position = UDim2.new(1, -52, 0.5, -11)
	MiniButton.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
	MiniButton.BorderSizePixel = 0
	MiniButton.Text = "-"
	MiniButton.TextColor3 = Color3.fromRGB(180, 195, 220)
	MiniButton.Font = Enum.Font.GothamBold
	MiniButton.TextSize = 14
	MiniButton.Parent = TopBar
	Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(0, 6)

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 22, 0, 22)
	CloseButton.Position = UDim2.new(1, -26, 0.5, -11)
	CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
	CloseButton.BorderSizePixel = 0
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 11
	CloseButton.Parent = TopBar
	Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

	MiniButton.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
		miniCircle.Visible = true
	end)

	local Content = Instance.new("Frame")
	Content.Size = UDim2.new(1, -16, 0, 196)
	Content.Position = UDim2.new(0, 8, 0, 40)
	Content.BackgroundTransparency = 1
	Content.Parent = MainFrame

	local cLayout = Instance.new("UIListLayout")
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Padding = UDim.new(0, 5)
	cLayout.Parent = Content

	local marker = Instance.new("Frame")
	marker.Name = "ClickIndicatorMarker"
	marker.Size = UDim2.new(0, 14, 0, 14)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	marker.BorderSizePixel = 0
	marker.Visible = false
	marker.ZIndex = 100
	marker.Parent = ScreenGui
	Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

	local isClicking, turboMode, cpsValue, clickPosition, settingPosConn = false, false, 10, nil, nil

	local function releaseMouse()
		local pos = clickPosition or UserInputService:GetMouseLocation()
		pcall(function() VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end)
	end

	local function triggerClick(pos)
		local x = pos and pos.X or (Workspace.CurrentCamera.ViewportSize.X / 2)
		local y = pos and pos.Y or (Workspace.CurrentCamera.ViewportSize.Y / 2)
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
			task.wait(0.001)
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		end)
	end

	local speedRow = Instance.new("Frame")
	speedRow.Size = UDim2.new(1, 0, 0, 26)
	speedRow.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	speedRow.BorderSizePixel = 0
	speedRow.LayoutOrder = 1
	speedRow.Parent = Content
	Instance.new("UICorner", speedRow).CornerRadius = UDim.new(0, 6)

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(0.65, 0, 1, 0)
	speedLabel.Position = UDim2.new(0, 8, 0, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Clicks / Sec (CPS):"
	speedLabel.TextColor3 = Color3.fromRGB(215, 225, 240)
	speedLabel.Font = Enum.Font.GothamMedium
	speedLabel.TextSize = 11
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = speedRow

	local speedBox = Instance.new("TextBox")
	speedBox.Size = UDim2.new(0.3, -4, 1, -6)
	speedBox.Position = UDim2.new(0.7, 0, 0, 3)
	speedBox.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	speedBox.BorderSizePixel = 0
	speedBox.Text = tostring(cpsValue)
	speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedBox.Font = Enum.Font.GothamBold
	speedBox.TextSize = 11
	speedBox.ClearTextOnFocus = false
	speedBox.Parent = speedRow
	Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 5)

	speedBox.FocusLost:Connect(function()
		local val = tonumber(speedBox.Text)
		if val and val > 0 then cpsValue = val; speedBox.Text = tostring(val) else speedBox.Text = tostring(cpsValue) end
	end)

	local posBtn = Instance.new("TextButton")
	posBtn.Size = UDim2.new(1, 0, 0, 26)
	posBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	posBtn.BorderSizePixel = 0
	posBtn.Text = "Set Tap Position (Center)"
	posBtn.TextColor3 = Color3.fromRGB(225, 235, 255)
	posBtn.Font = Enum.Font.GothamBold
	posBtn.TextSize = 10
	posBtn.LayoutOrder = 3
	posBtn.Parent = Content
	Instance.new("UICorner", posBtn).CornerRadius = UDim.new(0, 6)

	posBtn.MouseButton1Click:Connect(function()
		if settingPosConn then return end
		posBtn.Text = "Tap Screen to Set..."
		posBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		task.wait(0.1)
		settingPosConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos = UserInputService:GetMouseLocation()
				local posX = (input.UserInputType == Enum.UserInputType.MouseButton1) and mousePos.X or input.Position.X
				local posY = (input.UserInputType == Enum.UserInputType.MouseButton1) and mousePos.Y or input.Position.Y
				clickPosition = Vector2.new(posX, posY)
				marker.Position = UDim2.new(0, posX, 0, posY)
				marker.Visible = true
				posBtn.Text = string.format("Pos: (%d, %d)", posX, posY)
				posBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
				settingPosConn:Disconnect(); settingPosConn = nil
			end
		end)
	end)

	local turboToggleBtn = Instance.new("TextButton")
	turboToggleBtn.Size = UDim2.new(1, 0, 0, 28)
	turboToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 28, 16)
	turboToggleBtn.BorderSizePixel = 0
	turboToggleBtn.Font = Enum.Font.GothamBold
	turboToggleBtn.TextSize = 11
	turboToggleBtn.Text = "🔥 Turbo Mode: OFF"
	turboToggleBtn.TextColor3 = Color3.fromRGB(255, 220, 185)
	turboToggleBtn.LayoutOrder = 4
	turboToggleBtn.Parent = Content
	Instance.new("UICorner", turboToggleBtn).CornerRadius = UDim.new(0, 6)

	turboToggleBtn.MouseButton1Click:Connect(function()
		turboMode = not turboMode
		turboToggleBtn.Text = turboMode and "🔥 Turbo Mode: ON" or "🔥 Turbo Mode: OFF"
		turboToggleBtn.BackgroundColor3 = turboMode and Color3.fromRGB(215, 60, 0) or Color3.fromRGB(60, 28, 16)
	end)

	local toggleClickBtn = Instance.new("TextButton")
	toggleClickBtn.Size = UDim2.new(1, 0, 0, 30)
	toggleClickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
	toggleClickBtn.BorderSizePixel = 0
	toggleClickBtn.Text = "START AUTO CLICK"
	toggleClickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleClickBtn.Font = Enum.Font.GothamBold
	toggleClickBtn.TextSize = 11
	toggleClickBtn.LayoutOrder = 5
	toggleClickBtn.Parent = Content
	Instance.new("UICorner", toggleClickBtn).CornerRadius = UDim.new(0, 6)

	local function stopClicking()
		isClicking = false
		releaseMouse()
		toggleClickBtn.Text = "START AUTO CLICK"
		toggleClickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
	end

	toggleClickBtn.MouseButton1Click:Connect(function()
		if not isClicking then
			isClicking = true
			toggleClickBtn.Text = "STOP AUTO CLICK"
			toggleClickBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
			task.spawn(function()
				while isClicking do
					triggerClick(clickPosition)
					if turboMode then RunService.RenderStepped:Wait() else task.wait(1 / math.clamp(cpsValue, 0.001, 1000)) end
				end
				releaseMouse()
			end)
		else
			stopClicking()
		end
	end)

	CloseButton.MouseButton1Click:Connect(function()
		stopClicking()
		if settingPosConn then settingPosConn:Disconnect() end
		ScreenGui:Destroy()
	end)
end

-- 3. STALKER TOOLBOX
local function launchStalkerScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("StalkerUI")) or playerGui:FindFirstChild("StalkerUI")
	if existing then existing.Enabled = not existing.Enabled; return end

	local stGui = Instance.new("ScreenGui")
	stGui.Name = "StalkerUI"
	stGui.ResetOnSpawn = false
	safeParentGui(stGui)

	local sFrame = Instance.new("Frame")
	sFrame.Name = "Main"
	sFrame.Size = UDim2.new(0, 280, 0, 330)
	sFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
	sFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	sFrame.BorderSizePixel = 0
	sFrame.Parent = stGui
	Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 14)

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 44)
	topBar.BackgroundTransparency = 1
	topBar.Parent = sFrame
	makeDraggable(topBar, sFrame)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -60, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "🎯 Stalker Toolbox"
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 15
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = topBar

	local closeSubBtn = Instance.new("TextButton")
	closeSubBtn.Size = UDim2.new(0, 30, 0, 26)
	closeSubBtn.Position = UDim2.new(1, -38, 0.5, -13)
	closeSubBtn.BackgroundColor3 = Color3.fromRGB(235, 75, 90)
	closeSubBtn.BorderSizePixel = 0
	closeSubBtn.Text = "X"
	closeSubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeSubBtn.Font = Enum.Font.GothamBold
	closeSubBtn.TextSize = 12
	closeSubBtn.Parent = topBar
	Instance.new("UICorner", closeSubBtn).CornerRadius = UDim.new(0, 6)

	local targetBanner = Instance.new("Frame")
	targetBanner.Size = UDim2.new(1, -32, 0, 34)
	targetBanner.Position = UDim2.new(0, 16, 0, 46)
	targetBanner.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
	targetBanner.BorderSizePixel = 0
	targetBanner.Parent = sFrame
	Instance.new("UICorner", targetBanner).CornerRadius = UDim.new(0, 8)

	local targetText = Instance.new("TextLabel")
	targetText.Size = UDim2.new(1, 0, 1, 0)
	targetText.BackgroundTransparency = 1
	targetText.Text = "Target: None"
	targetText.TextColor3 = Color3.fromRGB(0, 220, 255)
	targetText.Font = Enum.Font.GothamBold
	targetText.TextSize = 13
	targetText.Parent = targetBanner

	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, -32, 0, 120)
	listScroll.Position = UDim2.new(0, 16, 0, 88)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 3
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.Parent = sFrame

	local sLayout = Instance.new("UIListLayout")
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Padding = UDim.new(0, 6)
	sLayout.Parent = listScroll

	local selectedUser, selectedBtn = nil, nil
	local function populateList()
		for _, child in ipairs(listScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local pBtn = Instance.new("TextButton")
				pBtn.Size = UDim2.new(1, 0, 0, 34)
				pBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
				pBtn.BorderSizePixel = 0
				pBtn.Text = string.format("%s (@%s)", p.DisplayName or p.Name, p.Name)
				pBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
				pBtn.Font = Enum.Font.GothamMedium
				pBtn.TextSize = 12
				pBtn.Parent = listScroll
				Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 7)

				pBtn.MouseButton1Click:Connect(function()
					selectedUser = p.Name
					targetText.Text = "Target: " .. p.DisplayName
					if selectedBtn and selectedBtn.Parent then
						selectedBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
					end
					selectedBtn = pBtn
					pBtn.BackgroundColor3 = Color3.fromRGB(38, 50, 72)
				end)
			end
		end
	end
	populateList()

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(1, -32, 0, 36)
	refreshBtn.Position = UDim2.new(0, 16, 0, 222)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(30, 125, 245)
	refreshBtn.BorderSizePixel = 0
	refreshBtn.Text = "Refresh Players"
	refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshBtn.Font = Enum.Font.GothamBold
	refreshBtn.TextSize = 12
	refreshBtn.Parent = sFrame
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)
	refreshBtn.MouseButton1Click:Connect(populateList)

	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0.5, -20, 0, 40)
	startBtn.Position = UDim2.new(0, 16, 0, 268)
	startBtn.BackgroundColor3 = Color3.fromRGB(85, 215, 115)
	startBtn.BorderSizePixel = 0
	startBtn.Text = "START"
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 12.5
	startBtn.Parent = sFrame
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.new(0.5, -20, 0, 40)
	stopBtn.Position = UDim2.new(0.5, 4, 0, 268)
	stopBtn.BackgroundColor3 = Color3.fromRGB(235, 60, 65)
	stopBtn.BorderSizePixel = 0
	stopBtn.Text = "STOP"
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.Font = Enum.Font.GothamBold
	stopBtn.TextSize = 12.5
	stopBtn.Parent = sFrame
	Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

	startBtn.MouseButton1Click:Connect(function()
		if not selectedUser then return end
		if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end); _G.StalkConnection = nil end
		_G.active = true
		_G.user = selectedUser
		_G.StalkConnection = RunService.RenderStepped:Connect(function()
			if not _G.active then return end
			local tPlr = Players:FindFirstChild(_G.user)
			local tChar = tPlr and tPlr.Character
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			local myChar = player.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if tRoot and myRoot then
				myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
			end
		end)
	end)

	stopBtn.MouseButton1Click:Connect(function()
		_G.active = false; _G.user = ""
		if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end); _G.StalkConnection = nil end
	end)

	closeSubBtn.MouseButton1Click:Connect(function()
		_G.active = false
		if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end); _G.StalkConnection = nil end
		stGui:Destroy()
	end)
end

-- 4. PLAYER TELEPORT
local function launchPlayerTeleportScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("TeleportUI")) or playerGui:FindFirstChild("TeleportUI")
	if existing then existing.Enabled = not existing.Enabled; return end

	local tpGui = Instance.new("ScreenGui")
	tpGui.Name = "TeleportUI"
	tpGui.ResetOnSpawn = false
	safeParentGui(tpGui)

	local tpFrame = Instance.new("Frame")
	tpFrame.Name = "Main"
	tpFrame.Size = UDim2.new(0, 280, 0, 330)
	tpFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
	tpFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	tpFrame.BorderSizePixel = 0
	tpFrame.Parent = tpGui
	Instance.new("UICorner", tpFrame).CornerRadius = UDim.new(0, 14)

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 44)
	topBar.BackgroundTransparency = 1
	topBar.Parent = tpFrame
	makeDraggable(topBar, tpFrame)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -90, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "📍 Player Teleport"
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 15
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = topBar

	local subMiniBtn = Instance.new("TextButton")
	subMiniBtn.Size = UDim2.new(0, 30, 0, 26)
	subMiniBtn.Position = UDim2.new(1, -74, 0.5, -13)
	subMiniBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
	subMiniBtn.BorderSizePixel = 0
	subMiniBtn.Text = "-"
	subMiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	subMiniBtn.Font = Enum.Font.GothamBold
	subMiniBtn.TextSize = 15
	subMiniBtn.Parent = topBar
	Instance.new("UICorner", subMiniBtn).CornerRadius = UDim.new(0, 6)

	local subCloseBtn = Instance.new("TextButton")
	subCloseBtn.Size = UDim2.new(0, 30, 0, 26)
	subCloseBtn.Position = UDim2.new(1, -38, 0.5, -13)
	subCloseBtn.BackgroundColor3 = Color3.fromRGB(235, 75, 90)
	subCloseBtn.BorderSizePixel = 0
	subCloseBtn.Text = "X"
	subCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	subCloseBtn.Font = Enum.Font.GothamBold
	subCloseBtn.TextSize = 12
	subCloseBtn.Parent = topBar
	Instance.new("UICorner", subCloseBtn).CornerRadius = UDim.new(0, 6)

	local contentBox = Instance.new("Frame")
	contentBox.Size = UDim2.new(1, 0, 1, -44)
	contentBox.Position = UDim2.new(0, 0, 0, 44)
	contentBox.BackgroundTransparency = 1
	contentBox.Parent = tpFrame

	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, -32, 1, -66)
	listScroll.Position = UDim2.new(0, 16, 0, 6)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 3
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.Parent = contentBox

	local tpListLayout = Instance.new("UIListLayout")
	tpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tpListLayout.Padding = UDim.new(0, 8)
	tpListLayout.Parent = listScroll

	local targetPlr, currentSelectedBtn = nil, nil
	local function refreshTeleportList()
		for _, v in ipairs(listScroll:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 36)
				btn.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
				btn.BorderSizePixel = 0
				btn.Text = string.format("%s (@%s)", p.DisplayName or p.Name, p.Name)
				btn.TextColor3 = Color3.fromRGB(240, 245, 255)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 12.5
				btn.Parent = listScroll
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

				btn.MouseButton1Click:Connect(function()
					targetPlr = p
					if currentSelectedBtn and currentSelectedBtn.Parent then
						currentSelectedBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
					end
					currentSelectedBtn = btn
					btn.BackgroundColor3 = Color3.fromRGB(40, 56, 84)
				end)
			end
		end
	end
	refreshTeleportList()
	Players.PlayerAdded:Connect(refreshTeleportList)
	Players.PlayerRemoving:Connect(refreshTeleportList)

	local tpActionBtn = Instance.new("TextButton")
	tpActionBtn.Size = UDim2.new(1, -32, 0, 42)
	tpActionBtn.Position = UDim2.new(0, 16, 1, -52)
	tpActionBtn.BackgroundColor3 = Color3.fromRGB(85, 215, 115)
	tpActionBtn.BorderSizePixel = 0
	tpActionBtn.Text = "Teleport"
	tpActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tpActionBtn.Font = Enum.Font.GothamBold
	tpActionBtn.TextSize = 14
	tpActionBtn.Parent = contentBox
	Instance.new("UICorner", tpActionBtn).CornerRadius = UDim.new(0, 8)

	tpActionBtn.MouseButton1Click:Connect(function()
		if targetPlr and targetPlr.Character then
			local tRoot = targetPlr.Character:FindFirstChild("HumanoidRootPart")
			local myChar = player.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if tRoot and myRoot then
				myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
			end
		end
	end)

	local minimized = false
	subMiniBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		contentBox.Visible = not minimized
		tpFrame.Size = minimized and UDim2.new(0, 280, 0, 44) or UDim2.new(0, 280, 0, 330)
	end)
	subCloseBtn.MouseButton1Click:Connect(function() tpGui:Destroy() end)
end

-- ================== [TAB 5] MORE TOOLS 🧰 (SORTED A - Z) ==================
local toolsPage = registerTab("tools", "Tools", "🧰", false)

-- 1. Aiming (Aimbot)
addRefinedToolButton(toolsPage, "Aiming (Aimbot)", "👁", Color3.fromRGB(170, 85, 255), function()
	pcall(function()
		getgenv().SCRIPT_KEY = "KEYLESS"
		loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/82b850540226f85fb5fa2ed6406f8649dabbffd0907865e1c8c62d203faa7959/download"))()
	end)
end)

-- 2. Anti AFK
addRefinedToolButton(toolsPage, "Anti AFK (External)", "🛡", Color3.fromRGB(0, 215, 125), function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
	end)
end)

-- 3. Auto Clicker
addRefinedToolButton(toolsPage, "Auto Clicker", "⚡", Color3.fromRGB(255, 150, 0), function()
	launchAutoClickerScript()
end)

-- 4. Fly GUI (V3)
addRefinedToolButton(toolsPage, "Fly GUI (V3)", "🚀", Color3.fromRGB(0, 195, 255), function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
	end)
end)

-- 5. FPS / Ping Monitor
addToggleRow(toolsPage, "FPS / Ping Monitor", state.fpsHudEnabled, function(_, render)
	state.fpsHudEnabled = not state.fpsHudEnabled
	render(state.fpsHudEnabled)
	toggleFpsHud(state.fpsHudEnabled)
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

-- 9. Stalker
addRefinedToolButton(toolsPage, "Stalker", "🎯", Color3.fromRGB(255, 65, 80), function()
	launchStalkerScript()
end)

-- 10. Vehicle Speed Adjust
addRefinedToolButton(toolsPage, "Vehicle Speed Adjust", "🏎️", Color3.fromRGB(0, 230, 140), function()
	launchVehicleSpeedAdjustScript()
end)

-- =========================================================================
-- ================== [TAB 6] PATCH UPDATE LOG 📜 (NEW) ====================
-- =========================================================================
local logPage = registerTab("logs", "Log", "📜", false)

local function addPatchLogCard(versionStr, dateStr, badgeType, badgeColor, bulletItems)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Color3.fromRGB(17, 21, 33)
	card.BorderSizePixel = 0
	card.LayoutOrder = getOrder()
	card.Parent = logPage
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = badgeColor
	cStroke.Thickness = 1
	cStroke.Transparency = 0.45
	cStroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim2.new(0, 10).X
	pad.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = card

	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 20)
	headerRow.BackgroundTransparency = 1
	headerRow.LayoutOrder = 1
	headerRow.Parent = card

	local verLbl = Instance.new("TextLabel")
	verLbl.Size = UDim2.new(1, -65, 1, 0)
	verLbl.BackgroundTransparency = 1
	verLbl.Text = versionStr .. "  •  " .. dateStr
	verLbl.TextColor3 = Color3.fromRGB(245, 250, 255)
	verLbl.Font = Enum.Font.GothamBold
	verLbl.TextSize = 11
	verLbl.TextXAlignment = Enum.TextXAlignment.Left
	verLbl.Parent = headerRow

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 52, 0, 16)
	badge.Position = UDim2.new(1, -52, 0.5, -8)
	badge.BackgroundColor3 = badgeColor:Lerp(Color3.fromRGB(12, 14, 20), 0.7)
	badge.BorderSizePixel = 0
	badge.Text = badgeType
	badge.TextColor3 = badgeColor
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 8.5
	badge.Parent = headerRow
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = badgeColor
	bStroke.Thickness = 1
	bStroke.Transparency = 0.3
	bStroke.Parent = badge

	for idx, itemText in ipairs(bulletItems) do
		local itemLbl = Instance.new("TextLabel")
		itemLbl.Size = UDim2.new(1, 0, 0, 0)
		itemLbl.AutomaticSize = Enum.AutomaticSize.Y
		itemLbl.BackgroundTransparency = 1
		itemLbl.Text = "• " .. itemText
		itemLbl.TextColor3 = Color3.fromRGB(185, 200, 225)
		itemLbl.Font = Enum.Font.GothamMedium
		itemLbl.TextSize = 10
		itemLbl.TextWrapped = true
		itemLbl.TextXAlignment = Enum.TextXAlignment.Left
		itemLbl.LayoutOrder = idx + 1
		itemLbl.Parent = card
	end
end

addPatchLogCard("v2.5 PRO", "Latest Update", "MAJOR", Color3.fromRGB(0, 240, 200), {
	"[UI] อัปเกรดดีไซน์ใหม่เป็น Cyber-Glassmorphism พร้อมกรอบสีเปลี่ยนตามหมวดหมู่แท็บ",
	"[UI] เปลี่ยนปุ่ม ON/OFF แบบเดิมเป็น Animated Pill Switches เลื่อนซ้าย-ขวาอย่างนุ่มนวล",
	"[UI] เพิ่มปุ่มลอย '⚡ Show Menu' ดีไซน์แคปซูลเรืองแสง และแยกปุ่มพับหน้าต่าง '-' ออกจากปุ่มซ่อนเมนู",
	"[NEW] เพิ่มระบบ Toast Notification มุมขวาล่าง แจ้งเตือนสถานะการทำงานแบบเรียลไทม์",
	"[NEW] เพิ่มหมวดหมู่ 📜 Log สำหรับตรวจสอบรายละเอียด Patch Update ย้อนหลัง",
	"[NEW] เพิ่มระบบ Gravity Control (ปรับแรงโน้มถ่วง), Click TP (Ctrl+Click) และ Time of Day Changer",
	"[OPT] อัปเกรดระบบ Player ESP และ Bot ESP ให้แสดงเปอร์เซ็นต์เลือด [HP%] บนหัวเป้าหมาย"
})

addPatchLogCard("v2.0", "Previous Build", "CORE", Color3.fromRGB(0, 195, 255), {
	"[NEW] ระบบ Battery Saver Overlay พร้อมตัวจับเวลาและคำนวณส่วนต่าง Leaderstats อัตโนมัติ",
	"[NEW] เพิ่มระบบ Bot ESP แยกสีอัตโนมัติ และ Raycast Occlusion เช็ควัตถุบังสายตา",
	"[NEW] รวม Sub-Tools ครบชุด: Auto Clicker (Turbo), Stalker, Player TP และ Vehicle Speed"
})

addPatchLogCard("v1.0", "Initial Release", "BASE", Color3.fromRGB(160, 175, 200), {
	"[INIT] เปิดตัวระบบหลัก: Movement (WalkSpeed, TP Walk, JumpPower), God Mode, Noclip, Anti-Ragdoll, FullBright และ 4 Waypoints"
})

-- สลับไปยังแท็บแรกเริ่ม
switchTab("move")
task.spawn(function()
	task.wait(0.08)
	adjustPanelHeight(false)
	sendNotification("Phumipad Pro v2.5", "Loaded successfully! Press R-Ctrl to toggle.", Color3.fromRGB(0, 225, 255))
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

-- NEW: Built-in Anti-AFK Connection
table.insert(globalConns, player.Idled:Connect(function()
	if state.builtInAntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

-- NEW: Click Teleport (Ctrl + Left Click) & Hotkey (RightControl)
table.insert(globalConns, UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
		if f.Visible then
			f.Visible = false
			openBtn.Visible = true
		else
			openBtn.Visible = false
			f.Visible = true
		end
	end

	if not gpe and state.clickTpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local mouse = player:GetMouse()
			if mouse and mouse.Hit and hrp then
				hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3.2, 0))
			end
		end
	end
end))

state.baseWalkSpeed = humanoid and humanoid.WalkSpeed or 16
state.baseMaxHealth = humanoid and humanoid.MaxHealth or 100
state.baseJumpPower = humanoid and humanoid.JumpPower or 50
state.baseJumpHeight = humanoid and humanoid.JumpHeight or 7.2

-- ================== COMPLETE GLOBAL CLEANUP FUNCTION ==================
local function fullCleanup()
	pcall(function()
		UserInputService.MouseIconEnabled = true
	end)

	if state.godMode        then applyGodMode(false) end
	if state.noclip         then applyNoclip(false) end
	if state.tpWalkEnabled  then applyTPWalk(false) end
	if state.fpsBooster     then applyFPSBooster(false) end
	if state.fullBright     then applyFullBright(false) end
	if state.timeLockEnabled then applyTimeLock(false) end
	if state.antiRagdoll    then applyAntiRagdoll(false) end
	if state.esp            then applyESP(false) end
	if state.botEsp         then applyBotESP(false) end
	if state.screenTime     then applyScreenTime(false) end
	if state.jumpEnabled    then applyJumpPower(false) end
	if state.gravityEnabled then applyGravity(false) end
	if state.spinBotEnabled then applySpinBot(false) end
	if state.fovEnabled     then applyFOV(false) end
	if state.fpsHudEnabled  then toggleFpsHud(false) end

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
		"UniversalSpeedAdjustGui",
		"TeleportUI",
		"PhumipadToolboxMinimalGui",
		"Phumipad_ESP_Storage",
		"Phumipad_BotESP_Storage",
		"Phumipad_FPS_Ping_Monitor",
		"Phumipad_Toast_Notifications"
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

-- ปุ่ม X: ปิดและล้างค่าทั้งหมด
closeBtn.MouseButton1Click:Connect(function()
	fullCleanup()
end)

-- ปุ่ม '-': พับเก็บ/กางหน้าต่าง (Collapse/Fold Panel)
miniBtn.MouseButton1Click:Connect(function()
	state.isFolded = not state.isFolded
	if state.isFolded then
		tabBar.Visible = false
		scroll.Visible = false
		resizeGrip.Visible = false
		miniBtn.Text = "+"
		TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, f.Size.X.Offset, 0, 42)
		}):Play()
	else
		miniBtn.Text = "-"
		local restoreH = state.savedExpandedHeight or 360
		TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, f.Size.X.Offset, 0, restoreH)
		}):Play()
		task.delay(0.12, function()
			if not state.isFolded then
				tabBar.Visible = true
				scroll.Visible = true
				resizeGrip.Visible = true
			end
		end)
	end
end)

-- ปุ่ม '⚡': ซ่อนหน้าต่างหลักแล้วย่อเป็นปุ่มลอย 'Show Menu'
dockHideBtn.MouseButton1Click:Connect(function()
	f.Visible = false
	openBtn.Visible = true
end)
