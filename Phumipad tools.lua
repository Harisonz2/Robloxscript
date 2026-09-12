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

-- ================== STALKER SCRIPT ==================
local function launchStalkerScript()
	if _G.StalkConnection then _G.StalkConnection:Disconnect() end
	
	local existing = (targetContainer and targetContainer:FindFirstChild("StalkerUI")) 
		or playerGui:FindFirstChild("StalkerUI") 
		or (CoreGui and CoreGui:FindFirstChild("StalkerUI"))
	if existing then
		existing:Destroy()
		return
	end

	_G.user = ""
	_G.active = false

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "StalkerUI"
	ScreenGui.ResetOnSpawn = false
	safeParentGui(ScreenGui)

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 230, 0, 305)
	MainFrame.Position = UDim2.new(0.5, -115, 0.4, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui

	local mfCorner = Instance.new("UICorner")
	mfCorner.CornerRadius = UDim.new(0, 10)
	mfCorner.Parent = MainFrame

	local mfStroke = Instance.new("UIStroke")
	mfStroke.Color = Color3.fromRGB(45, 52, 70)
	mfStroke.Thickness = 1.2
	mfStroke.Parent = MainFrame

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(220, 25, 35)
	TopBar.BorderSizePixel = 0
	TopBar.Active = true
	TopBar.Parent = MainFrame

	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 10)
	tbCorner.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Stalker Toolbox"
	Title.TextColor3 = Color3.fromRGB(240, 245, 255)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 12
	Title.Parent = TopBar

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 24, 0, 24)
	CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 11
	CloseBtn.Parent = TopBar
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = CloseBtn

	local TargetLabel = Instance.new("TextLabel")
	TargetLabel.Size = UDim2.new(1, -16, 0, 26)
	TargetLabel.Position = UDim2.new(0, 8, 0, 42)
	TargetLabel.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	TargetLabel.BorderSizePixel = 0
	TargetLabel.Text = "Target: None"
	TargetLabel.TextColor3 = Color3.fromRGB(0, 215, 255)
	TargetLabel.TextSize = 11
	TargetLabel.Font = Enum.Font.GothamBold
	TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
	TargetLabel.Parent = MainFrame
	local tlCorner = Instance.new("UICorner")
	tlCorner.CornerRadius = UDim.new(0, 6)
	tlCorner.Parent = TargetLabel

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Size = UDim2.new(1, -16, 0, 130)
	ScrollFrame.Position = UDim2.new(0, 8, 0, 74)
	ScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 3
	ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 185, 255)
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollFrame.Parent = MainFrame
	local sfCorner = Instance.new("UICorner")
	sfCorner.CornerRadius = UDim.new(0, 6)
	sfCorner.Parent = ScrollFrame

	local sPadding = Instance.new("UIPadding")
	sPadding.PaddingTop = UDim.new(0, 4)
	sPadding.PaddingBottom = UDim.new(0, 4)
	sPadding.PaddingLeft = UDim.new(0, 4)
	sPadding.PaddingRight = UDim.new(0, 4)
	sPadding.Parent = ScrollFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 4)
	UIListLayout.Parent = ScrollFrame

	local function RefreshPlayerList()
		for _, child in pairs(ScrollFrame:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then
				local pBtn = Instance.new("TextButton")
				pBtn.Size = UDim2.new(1, 0, 0, 24)
				pBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
				pBtn.BorderSizePixel = 0
				pBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
				pBtn.TextColor3 = Color3.fromRGB(225, 235, 255)
				pBtn.TextSize = 10
				pBtn.Font = Enum.Font.GothamMedium
				pBtn.TextTruncate = Enum.TextTruncate.AtEnd
				pBtn.Parent = ScrollFrame

				local pbCorner = Instance.new("UICorner")
				pbCorner.CornerRadius = UDim.new(0, 5)
				pbCorner.Parent = pBtn

				pBtn.MouseButton1Click:Connect(function()
					_G.user = p.Name
					TargetLabel.Text = "Target: " .. p.DisplayName
				end)
			end
		end
	end
	RefreshPlayerList()

	local RefreshBtn = Instance.new("TextButton")
	RefreshBtn.Size = UDim2.new(1, -16, 0, 24)
	RefreshBtn.Position = UDim2.new(0, 8, 0, 210)
	RefreshBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
	RefreshBtn.BorderSizePixel = 0
	RefreshBtn.Text = "Refresh Players"
	RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	RefreshBtn.Font = Enum.Font.GothamBold
	RefreshBtn.TextSize = 10
	RefreshBtn.Parent = MainFrame
	local rfCorner = Instance.new("UICorner")
	rfCorner.CornerRadius = UDim.new(0, 6)
	rfCorner.Parent = RefreshBtn
	RefreshBtn.MouseButton1Click:Connect(RefreshPlayerList)

	local StalkBtn = Instance.new("TextButton")
	StalkBtn.Size = UDim2.new(0.5, -12, 0, 28)
	StalkBtn.Position = UDim2.new(0, 8, 0, 240)
	StalkBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
	StalkBtn.BorderSizePixel = 0
	StalkBtn.Text = "START"
	StalkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	StalkBtn.Font = Enum.Font.GothamBold
	StalkBtn.TextSize = 11
	StalkBtn.Parent = MainFrame
	local stCorner = Instance.new("UICorner")
	stCorner.CornerRadius = UDim.new(0, 6)
	stCorner.Parent = StalkBtn

	local StopBtn = Instance.new("TextButton")
	StopBtn.Size = UDim2.new(0.5, -12, 0, 28)
	StopBtn.Position = UDim2.new(0.5, 4, 0, 240)
	StopBtn.BackgroundColor3 = Color3.fromRGB(200, 35, 45)
	StopBtn.BorderSizePixel = 0
	StopBtn.Text = "STOP"
	StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	StopBtn.Font = Enum.Font.GothamBold
	StopBtn.TextSize = 11
	StopBtn.Parent = MainFrame
	local spCorner = Instance.new("UICorner")
	spCorner.CornerRadius = UDim.new(0, 6)
	spCorner.Parent = StopBtn

	do
		local dragging, dragStart, startPos = false, nil, nil
		TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = MainFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		TopBar.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	StalkBtn.MouseButton1Click:Connect(function()
		if _G.user ~= "" then
			_G.active = true
			StalkBtn.Text = "STALKING"
			StalkBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 95)
		end
	end)

	StopBtn.MouseButton1Click:Connect(function()
		_G.active = false
		StalkBtn.Text = "START"
		StalkBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
	end)

	local function cleanupStalker()
		_G.active = false
		if _G.StalkConnection then _G.StalkConnection:Disconnect() end
		ScreenGui:Destroy()
	end

	CloseBtn.MouseButton1Click:Connect(cleanupStalker)
	ScreenGui.Destroying:Connect(function()
		_G.active = false
		if _G.StalkConnection then _G.StalkConnection:Disconnect() end
	end)

	_G.StalkConnection = RunService.Heartbeat:Connect(function()
		pcall(function()
			if _G.active and _G.user ~= "" then
				local target = Players:FindFirstChild(_G.user)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
					end
				end
			end
		end)
	end)
end

-- ================== AUTO CLICKER PANEL (COMPACT + POPUP DOCK) ==================
local function launchAutoClickerScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("Phumipad_AutoClicker_UI")) 
		or playerGui:FindFirstChild("Phumipad_AutoClicker_UI") 
		or (CoreGui and CoreGui:FindFirstChild("Phumipad_AutoClicker_UI"))
	if existing then
		existing:Destroy()
		return
	end

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

	local mfCorner = Instance.new("UICorner")
	mfCorner.CornerRadius = UDim.new(0, 10)
	mfCorner.Parent = MainFrame

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
		local dragging, dragStart, startPos = false, nil, nil
		local hasMoved = false
		miniCircle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				hasMoved = false
				dragStart = input.Position
				startPos = miniCircle.Position
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
				if not hasMoved then
					miniCircle.Visible = false
					MainFrame.Visible = true
				end
				dragging = false
				hasMoved = false
			end
		end)
	end

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
	TopBar.BorderSizePixel = 0
	TopBar.Active = true
	TopBar.Parent = MainFrame

	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 10)
	tbCorner.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -70, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Auto Clicker"
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
	local mnCorner = Instance.new("UICorner")
	mnCorner.CornerRadius = UDim.new(0, 6)
	mnCorner.Parent = MiniButton

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
	local clsCorner = Instance.new("UICorner")
	clsCorner.CornerRadius = UDim.new(0, 6)
	clsCorner.Parent = CloseButton

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

	local markerStroke = Instance.new("UIStroke")
	markerStroke.Color = Color3.fromRGB(255, 255, 255)
	markerStroke.Thickness = 1.5
	markerStroke.Parent = marker

	local isClicking = false
	local turboMode = false
	local cpsValue = 10
	local clickPosition = nil
	local settingPosConn = nil

	local function releaseMouse()
		local pos = clickPosition or UserInputService:GetMouseLocation()
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
		end)
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
		if val and val > 0 then
			cpsValue = val
			speedBox.Text = tostring(val)
		else
			speedBox.Text = tostring(cpsValue)
		end
	end)

	local exampleLabel = Instance.new("TextLabel")
	exampleLabel.Size = UDim2.new(1, 0, 0, 18)
	exampleLabel.BackgroundTransparency = 1
	exampleLabel.Text = "Ex: 1 = 1 CPS | 10 = 10 CPS | 50 = 50 CPS"
	exampleLabel.TextColor3 = Color3.fromRGB(120, 135, 160)
	exampleLabel.Font = Enum.Font.Gotham
	exampleLabel.TextSize = 9
	exampleLabel.TextXAlignment = Enum.TextXAlignment.Center
	exampleLabel.LayoutOrder = 2
	exampleLabel.Parent = Content

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
				local posX, posY
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local mousePos = UserInputService:GetMouseLocation()
					posX = mousePos.X
					posY = mousePos.Y
				else
					posX = input.Position.X
					posY = input.Position.Y
				end

				clickPosition = Vector2.new(posX, posY)
				marker.Position = UDim2.new(0, posX, 0, posY)
				marker.Visible = true

				posBtn.Text = string.format("Pos: (%d, %d)", posX, posY)
				posBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 48)

				settingPosConn:Disconnect()
				settingPosConn = nil
			end
		end)
	end)

	local turboRow = Instance.new("Frame")
	turboRow.Size = UDim2.new(1, 0, 0, 28)
	turboRow.BackgroundColor3 = Color3.fromRGB(60, 28, 16)
	turboRow.BorderSizePixel = 0
	turboRow.LayoutOrder = 4
	turboRow.Parent = Content
	Instance.new("UICorner", turboRow).CornerRadius = UDim.new(0, 6)

	local fireGrad = Instance.new("UIGradient")
	fireGrad.Rotation = 45
	fireGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 35, 15)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 55, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 25, 12))
	})
	fireGrad.Parent = turboRow

	local fireStroke = Instance.new("UIStroke")
	fireStroke.Color = Color3.fromRGB(255, 135, 45)
	fireStroke.Thickness = 1
	fireStroke.Parent = turboRow

	local turboLabel = Instance.new("TextLabel")
	turboLabel.Size = UDim2.new(1, -55, 1, 0)
	turboLabel.Position = UDim2.new(0, 8, 0, 0)
	turboLabel.BackgroundTransparency = 1
	turboLabel.Text = "🔥 Turbo Mode"
	turboLabel.TextColor3 = Color3.fromRGB(255, 220, 185)
	turboLabel.Font = Enum.Font.GothamBold
	turboLabel.TextSize = 11
	turboLabel.TextXAlignment = Enum.TextXAlignment.Left
	turboLabel.Parent = turboRow

	local turboToggleBtn = Instance.new("TextButton")
	turboToggleBtn.Size = UDim2.new(0, 42, 0, 20)
	turboToggleBtn.Position = UDim2.new(1, -48, 0.5, -10)
	turboToggleBtn.BorderSizePixel = 0
	turboToggleBtn.Font = Enum.Font.GothamBold
	turboToggleBtn.TextSize = 10
	turboToggleBtn.Text = "OFF"
	turboToggleBtn.BackgroundColor3 = Color3.fromRGB(38, 25, 20)
	turboToggleBtn.TextColor3 = Color3.fromRGB(180, 150, 140)
	turboToggleBtn.Parent = turboRow
	Instance.new("UICorner", turboToggleBtn).CornerRadius = UDim.new(0, 5)

	turboToggleBtn.MouseButton1Click:Connect(function()
		turboMode = not turboMode
		turboToggleBtn.Text = turboMode and "ON" or "OFF"
		turboToggleBtn.BackgroundColor3 = turboMode and Color3.fromRGB(215, 60, 0) or Color3.fromRGB(38, 25, 20)
		turboToggleBtn.TextColor3 = turboMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 150, 140)
	end)

	local toggleClickBtn = Instance.new("TextButton")
	toggleClickBtn.Size = UDim2.new(1, 0, 0, 28)
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
					if turboMode then
						RunService.RenderStepped:Wait()
					else
						local delayTime = 1 / math.clamp(cpsValue, 0.001, 1000)
						task.wait(delayTime)
					end
				end
				releaseMouse()
			end)
		else
			stopClicking()
		end
	end)

	local forceStopBtn = Instance.new("TextButton")
	forceStopBtn.Size = UDim2.new(1, 0, 0, 26)
	forceStopBtn.BackgroundColor3 = Color3.fromRGB(200, 35, 45)
	forceStopBtn.BorderSizePixel = 0
	forceStopBtn.Text = "FORCE STOP (EMERGENCY)"
	forceStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	forceStopBtn.Font = Enum.Font.GothamBold
	forceStopBtn.TextSize = 10
	forceStopBtn.LayoutOrder = 6
	forceStopBtn.Parent = Content
	Instance.new("UICorner", forceStopBtn).CornerRadius = UDim.new(0, 6)

	forceStopBtn.MouseButton1Click:Connect(function()
		stopClicking()
	end)

	do
		local dragging, dragStart, startPos = false, nil, nil
		TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = MainFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		TopBar.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				MainFrame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	CloseButton.MouseButton1Click:Connect(function()
		stopClicking()
		if settingPosConn then settingPosConn:Disconnect() end
		ScreenGui:Destroy()
	end)

	ScreenGui.Destroying:Connect(function()
		stopClicking()
		if settingPosConn then settingPosConn:Disconnect() end
	end)
end

-- ================== FLY SCRIPT FUNCTION ==================
local function launchFlyScript()
	local existing = playerGui:FindFirstChild("FlyGuiV3_Main")
	if existing then
		existing:Destroy()
		return
	end

	local main = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local up = Instance.new("TextButton")
	local down = Instance.new("TextButton")
	local onof = Instance.new("TextButton")
	local TextLabel = Instance.new("TextLabel")
	local plus = Instance.new("TextButton")
	local speed = Instance.new("TextLabel")
	local mine = Instance.new("TextButton")
	local closebutton = Instance.new("TextButton")
	local mini = Instance.new("TextButton")
	local mini2 = Instance.new("TextButton")

	main.Name = "FlyGuiV3_Main"
	main.Parent = playerGui
	main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	main.ResetOnSpawn = false

	Frame.Parent = main
	Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
	Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
	Frame.Position = UDim2.new(0.1, 0, 0.38, 0)
	Frame.Size = UDim2.new(0, 190, 0, 57)
	Frame.Active = true
	Frame.Draggable = true

	up.Name = "up"
	up.Parent = Frame
	up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
	up.Size = UDim2.new(0, 44, 0, 28)
	up.Font = Enum.Font.SourceSans
	up.Text = "UP"
	up.TextColor3 = Color3.fromRGB(0, 0, 0)
	up.TextSize = 14

	down.Name = "down"
	down.Parent = Frame
	down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
	down.Position = UDim2.new(0, 0, 0.491, 0)
	down.Size = UDim2.new(0, 44, 0, 28)
	down.Font = Enum.Font.SourceSans
	down.Text = "DOWN"
	down.TextColor3 = Color3.fromRGB(0, 0, 0)
	down.TextSize = 14

	onof.Name = "onof"
	onof.Parent = Frame
	onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
	onof.Position = UDim2.new(0.702, 0, 0.491, 0)
	onof.Size = UDim2.new(0, 56, 0, 28)
	onof.Font = Enum.Font.SourceSans
	onof.Text = "fly"
	onof.TextColor3 = Color3.fromRGB(0, 0, 0)
	onof.TextSize = 14

	TextLabel.Parent = Frame
	TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
	TextLabel.Position = UDim2.new(0.469, 0, 0, 0)
	TextLabel.Size = UDim2.new(0, 100, 0, 28)
	TextLabel.Font = Enum.Font.SourceSans
	TextLabel.Text = "FLY GUI V3"
	TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.TextScaled = true
	TextLabel.TextSize = 14
	TextLabel.TextWrapped = true

	plus.Name = "plus"
	plus.Parent = Frame
	plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
	plus.Position = UDim2.new(0.231, 0, 0, 0)
	plus.Size = UDim2.new(0, 45, 0, 28)
	plus.Font = Enum.Font.SourceSans
	plus.Text = "+"
	plus.TextColor3 = Color3.fromRGB(0, 0, 0)
	plus.TextScaled = true
	plus.TextSize = 14
	plus.TextWrapped = true

	speed.Name = "speed"
	speed.Parent = Frame
	speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
	speed.Position = UDim2.new(0.468, 0, 0.491, 0)
	speed.Size = UDim2.new(0, 44, 0, 28)
	speed.Font = Enum.Font.SourceSans
	speed.Text = "1"
	speed.TextColor3 = Color3.fromRGB(0, 0, 0)
	speed.TextScaled = true
	speed.TextSize = 14
	speed.TextWrapped = true

	mine.Name = "mine"
	mine.Parent = Frame
	mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
	mine.Position = UDim2.new(0.231, 0, 0.491, 0)
	mine.Size = UDim2.new(0, 45, 0, 29)
	mine.Font = Enum.Font.SourceSans
	mine.Text = "-"
	mine.TextColor3 = Color3.fromRGB(0, 0, 0)
	mine.TextScaled = true
	mine.TextSize = 14
	mine.TextWrapped = true

	closebutton.Name = "Close"
	closebutton.Parent = Frame
	closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
	closebutton.Font = Enum.Font.GothamBold
	closebutton.Size = UDim2.new(0, 45, 0, 28)
	closebutton.Text = "X"
	closebutton.TextSize = 18
	closebutton.Position = UDim2.new(0, 0, -1, 27)

	mini.Name = "minimize"
	mini.Parent = Frame
	mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini.Font = Enum.Font.GothamBold
	mini.Size = UDim2.new(0, 45, 0, 28)
	mini.Text = "-"
	mini.TextSize = 20
	mini.Position = UDim2.new(0, 44, -1, 27)

	mini2.Name = "minimize2"
	mini2.Parent = Frame
	mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini2.Font = Enum.Font.GothamBold
	mini2.Size = UDim2.new(0, 45, 0, 28)
	mini2.Text = "+"
	mini2.TextSize = 20
	mini2.Position = UDim2.new(0, 44, -1, 57)
	mini2.Visible = false

	local speeds = 1
	local speaker = player
	local nowe = false
	local tpwalking = false

	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", { 
			Title = "FLY GUI V3",
			Text = "BY XNEO",
			Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
			Duration = 5
		})
	end)

	onof.MouseButton1Down:Connect(function()
		if nowe == true then
			nowe = false
			local char = speaker.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
				hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
			end
		else 
			nowe = true
			for i = 1, speeds do
				task.spawn(function()
					local hb = game:GetService("RunService").Heartbeat	
					tpwalking = true
					local c = speaker.Character
					local h = c and c:FindFirstChildWhichIsA("Humanoid")
					while tpwalking and hb:Wait() and c and h and h.Parent do
						if h.MoveDirection.Magnitude > 0 then
							c:TranslateBy(h.MoveDirection)
						end
					end
				end)
			end

			local char = speaker.Character
			if char and char:FindFirstChild("Animate") then
				char.Animate.Disabled = true
			end
			local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController"))
			if hum then
				for _, v in next, hum:GetPlayingAnimationTracks() do
					v:AdjustSpeed(0)
				end
				hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
				hum:ChangeState(Enum.HumanoidStateType.Swimming)
			end
		end

		local char = speaker.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		if hum.RigType == Enum.HumanoidRigType.R6 then
			local torso = char:FindFirstChild("Torso")
			if not torso then return end
			local ctrl = {f = 0, b = 0, l = 0, r = 0}
			local lastctrl = {f = 0, b = 0, l = 0, r = 0}
			local maxspeed = 50
			local currentSpd = 0

			local bg = Instance.new("BodyGyro", torso)
			bg.P = 9e4
			bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.cframe = torso.CFrame
			local bv = Instance.new("BodyVelocity", torso)
			bv.velocity = Vector3.new(0, 0.1, 0)
			bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

			if nowe == true then hum.PlatformStand = true end

			while nowe == true or hum.Health == 0 do
				RunService.RenderStepped:Wait()
				if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
					currentSpd = currentSpd + 0.5 + (currentSpd / maxspeed)
					if currentSpd > maxspeed then currentSpd = maxspeed end
				elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and currentSpd ~= 0 then
					currentSpd = currentSpd - 1
					if currentSpd < 0 then currentSpd = 0 end
				end
				if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
					bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * currentSpd
					lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
				elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and currentSpd ~= 0 then
					bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * currentSpd
				else
					bv.velocity = Vector3.new(0, 0, 0)
				end
				bg.cframe = Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * currentSpd / maxspeed), 0, 0)
			end
			bg:Destroy()
			bv:Destroy()
			hum.PlatformStand = false
			if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
			tpwalking = false
		else
			local upperTorso = char:FindFirstChild("UpperTorso")
			if not upperTorso then return end
			local ctrl = {f = 0, b = 0, l = 0, r = 0}
			local lastctrl = {f = 0, b = 0, l = 0, r = 0}
			local maxspeed = 50
			local currentSpd = 0

			local bg = Instance.new("BodyGyro", upperTorso)
			bg.P = 9e4
			bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.cframe = upperTorso.CFrame
			local bv = Instance.new("BodyVelocity", upperTorso)
			bv.velocity = Vector3.new(0, 0.1, 0)
			bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

			if nowe == true then hum.PlatformStand = true end

			while nowe == true or hum.Health == 0 do
				task.wait()
				if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
					currentSpd = currentSpd + 0.5 + (currentSpd / maxspeed)
					if currentSpd > maxspeed then currentSpd = maxspeed end
				elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and currentSpd ~= 0 then
					currentSpd = currentSpd - 1
					if currentSpd < 0 then currentSpd = 0 end
				end
				if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
					bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * currentSpd
					lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
				elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and currentSpd ~= 0 then
					bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * currentSpd
				else
					bv.velocity = Vector3.new(0, 0, 0)
				end
				bg.cframe = Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * currentSpd / maxspeed), 0, 0)
			end
			bg:Destroy()
			bv:Destroy()
			hum.PlatformStand = false
			if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
			tpwalking = false
		end
	end)

	local tis
	up.MouseButton1Down:Connect(function()
		tis = up.MouseEnter:Connect(function()
			while tis do
				task.wait()
				local root = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
				if root then root.CFrame = root.CFrame * CFrame.new(0, 1, 0) end
			end
		end)
	end)
	up.MouseLeave:Connect(function()
		if tis then tis:Disconnect(); tis = nil end
	end)

	local dis
	down.MouseButton1Down:Connect(function()
		dis = down.MouseEnter:Connect(function()
			while dis do
				task.wait()
				local root = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
				if root then root.CFrame = root.CFrame * CFrame.new(0, -1, 0) end
			end
		end)
	end)
	down.MouseLeave:Connect(function()
		if dis then dis:Disconnect(); dis = nil end
	end)

	plus.MouseButton1Down:Connect(function()
		speeds = speeds + 1
		speed.Text = tostring(speeds)
		if nowe == true then
			tpwalking = false
			for i = 1, speeds do
				task.spawn(function()
					local hb = game:GetService("RunService").Heartbeat	
					tpwalking = true
					local c = speaker.Character
					local h = c and c:FindFirstChildWhichIsA("Humanoid")
					while tpwalking and hb:Wait() and c and h and h.Parent do
						if h.MoveDirection.Magnitude > 0 then
							c:TranslateBy(h.MoveDirection)
						end
					end
				end)
			end
		end
	end)

	mine.MouseButton1Down:Connect(function()
		if speeds == 1 then
			speed.Text = "cannot be less than 1"
			task.wait(1)
			speed.Text = tostring(speeds)
		else
			speeds = speeds - 1
			speed.Text = tostring(speeds)
			if nowe == true then
				tpwalking = false
				for i = 1, speeds do
					task.spawn(function()
						local hb = game:GetService("RunService").Heartbeat	
						tpwalking = true
						local c = speaker.Character
						local h = c and c:FindFirstChildWhichIsA("Humanoid")
						while tpwalking and hb:Wait() and c and h and h.Parent do
							if h.MoveDirection.Magnitude > 0 then
								c:TranslateBy(h.MoveDirection)
							end
						end
					end)
				end
			end
		end
	end)

	closebutton.MouseButton1Click:Connect(function() main:Destroy() end)

	mini.MouseButton1Click:Connect(function()
		up.Visible = false
		down.Visible = false
		onof.Visible = false
		plus.Visible = false
		speed.Visible = false
		mine.Visible = false
		mini.Visible = false
		mini2.Visible = true
		Frame.BackgroundTransparency = 1
		closebutton.Position = UDim2.new(0, 0, -1, 57)
	end)

	mini2.MouseButton1Click:Connect(function()
		up.Visible = true
		down.Visible = true
		onof.Visible = true
		plus.Visible = true
		speed.Visible = true
		mine.Visible = true
		mini.Visible = true
		mini2.Visible = false
		Frame.BackgroundTransparency = 0 
		closebutton.Position = UDim2.new(0, 0, -1, 27)
	end)
end

-- ================== PLAYER TELEPORT SCRIPT FUNCTION ==================
local function launchPlayerTeleportScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("TeleportUI")) 
		or playerGui:FindFirstChild("TeleportUI") 
		or (CoreGui and CoreGui:FindFirstChild("TeleportUI"))
	if existing then
		existing:Destroy()
		return
	end

	local teleportTarget = nil

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "TeleportUI"
	ScreenGui.ResetOnSpawn = false
	safeParentGui(ScreenGui)

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 250, 0, 300)
	MainFrame.Position = UDim2.new(0.5, -125, 0.4, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui

	local mfCorner = Instance.new("UICorner")
	mfCorner.CornerRadius = UDim.new(0, 10)
	mfCorner.Parent = MainFrame

	local mfStroke = Instance.new("UIStroke")
	mfStroke.Color = Color3.fromRGB(45, 52, 70)
	mfStroke.Thickness = 1.2
	mfStroke.Parent = MainFrame

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
	TopBar.BorderSizePixel = 0
	TopBar.Active = true
	TopBar.Parent = MainFrame

	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 10)
	tbCorner.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -70, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Player Teleport"
	Title.TextColor3 = Color3.fromRGB(240, 245, 255)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 13
	Title.Parent = TopBar

	local MinButton = Instance.new("TextButton")
	MinButton.Size = UDim2.new(0, 24, 0, 24)
	MinButton.Position = UDim2.new(1, -56, 0.5, -12)
	MinButton.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
	MinButton.BorderSizePixel = 0
	MinButton.Text = "-"
	MinButton.TextColor3 = Color3.fromRGB(200, 210, 230)
	MinButton.Font = Enum.Font.GothamBold
	MinButton.TextSize = 16
	MinButton.Parent = TopBar
	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(0, 6)
	minCorner.Parent = MinButton

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 24, 0, 24)
	CloseButton.Position = UDim2.new(1, -28, 0.5, -12)
	CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
	CloseButton.BorderSizePixel = 0
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 12
	CloseButton.Parent = TopBar
	local clsCorner = Instance.new("UICorner")
	clsCorner.CornerRadius = UDim.new(0, 6)
	clsCorner.Parent = CloseButton

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1, 0, 1, -34)
	ContentFrame.Position = UDim2.new(0, 0, 0, 34)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainFrame

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.new(1, -16, 1, -48)
	ScrollingFrame.Position = UDim2.new(0, 8, 0, 8)
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.ScrollBarThickness = 3
	ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
	ScrollingFrame.Parent = ContentFrame
	local sfCorner = Instance.new("UICorner")
	sfCorner.CornerRadius = UDim.new(0, 6)
	sfCorner.Parent = ScrollingFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = ScrollingFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 4)

	local sfPadding = Instance.new("UIPadding")
	sfPadding.PaddingTop = UDim.new(0, 4)
	sfPadding.PaddingBottom = UDim.new(0, 4)
	sfPadding.PaddingLeft = UDim.new(0, 4)
	sfPadding.PaddingRight = UDim.new(0, 4)
	sfPadding.Parent = ScrollingFrame

	local TPButton = Instance.new("TextButton")
	TPButton.Size = UDim2.new(1, -16, 0, 28)
	TPButton.Position = UDim2.new(0, 8, 1, -34)
	TPButton.BackgroundColor3 = Color3.fromRGB(0, 175, 115)
	TPButton.BorderSizePixel = 0
	TPButton.Text = "Teleport"
	TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPButton.Font = Enum.Font.GothamBold
	TPButton.TextSize = 12
	TPButton.Parent = ContentFrame
	local tpbCorner = Instance.new("UICorner")
	tpbCorner.CornerRadius = UDim.new(0, 6)
	tpbCorner.Parent = TPButton

	local function updatePlayerList()
		for _, child in pairs(ScrollingFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				local PlayerButton = Instance.new("TextButton")
				PlayerButton.Size = UDim2.new(1, 0, 0, 26)
				PlayerButton.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
				PlayerButton.TextColor3 = Color3.fromRGB(220, 230, 245)
				PlayerButton.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
				PlayerButton.BorderSizePixel = 0
				PlayerButton.Font = Enum.Font.GothamMedium
				PlayerButton.TextSize = 11
				PlayerButton.Parent = ScrollingFrame

				local pbCorner = Instance.new("UICorner")
				pbCorner.CornerRadius = UDim.new(0, 5)
				pbCorner.Parent = PlayerButton

				PlayerButton.MouseButton1Click:Connect(function()
					teleportTarget = plr.Character and (plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso") or plr.Character.PrimaryPart)
					TPButton.Text = "Teleport to: " .. plr.DisplayName
				end)
			end
		end
	end

	TPButton.MouseButton1Click:Connect(function()
		if teleportTarget and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = teleportTarget.CFrame + Vector3.new(0, 3, 0)
		end
	end)

	local pAdded = Players.PlayerAdded:Connect(updatePlayerList)
	local pRemoved = Players.PlayerRemoving:Connect(updatePlayerList)
	updatePlayerList()

	CloseButton.MouseButton1Click:Connect(function()
		pAdded:Disconnect()
		pRemoved:Disconnect()
		ScreenGui:Destroy()
	end)

	local tpMinimized = false
	MinButton.MouseButton1Click:Connect(function()
		tpMinimized = not tpMinimized
		if tpMinimized then
			MinButton.Text = "+"
			MainFrame:TweenSize(UDim2.new(0, 250, 0, 34), "Out", "Quart", 0.3, true)
		else
			MinButton.Text = "-"
			MainFrame:TweenSize(UDim2.new(0, 250, 0, 300), "Out", "Quart", 0.3, true)
		end
	end)

	local dragging, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
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

-- ================== MODERN COMPACT UI ==================
local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadToolboxMinimalGui"
sg.ResetOnSpawn = false
safeParentGui(sg)

local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 230, 0, 300)
f.Position = UDim2.new(0.04, 0, 0.45, -150)
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

-- Top-Left Pop-Up Dock Button
local openBtn = Instance.new("TextButton")
openBtn.Name = "TopLeftOpenButton"
openBtn.Size = UDim2.new(0, 115, 0, 32)
openBtn.Position = UDim2.new(0, 14, 0, 52)
openBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
openBtn.BorderSizePixel = 0
openBtn.Text = "PHUMIPAD"
openBtn.TextColor3 = Color3.fromRGB(0, 225, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 11
openBtn.Visible = false
openBtn.Active = true
openBtn.Parent = sg

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 190, 255)
openStroke.Thickness = 1
openStroke.Parent = openBtn

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
bar.Size = UDim2.new(1, 0, 0, 40)
bar.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = bar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -75, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PHUMIPAD TOOLBOX v3.1"
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
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

-- Scroll Container
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, 0, 1, -40)
scroll.Position = UDim2.new(0, 0, 0, 40)
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
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingBottom = UDim.new(0, 18)
scrollPadding.PaddingLeft = UDim.new(0, 10)
scrollPadding.PaddingRight = UDim.new(0, 10)
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
			local targetH = math.clamp(startSize.Y + delta.Y, 150, 800)
			f.Size = UDim2.new(0, targetW, 0, targetH)
		end
	end)
end

local currentOrder = 1
local function getOrder() currentOrder = currentOrder + 1; return currentOrder end

-- ================== DYNAMIC AUTO-RESIZING SYSTEM ==================
local categories = {}

local function adjustPanelHeight(animate)
	task.defer(function()
		local totalContentHeight = statusCard.Size.Y.Offset + scrollPadding.PaddingTop.Offset + scrollPadding.PaddingBottom.Offset
		
		for _, cat in ipairs(categories) do
			totalContentHeight = totalContentHeight + 26
			if cat.isOpen() then
				totalContentHeight = totalContentHeight + cat.contentLayout.AbsoluteContentSize.Y + 4
			end
			totalContentHeight = totalContentHeight + layout.Padding.Offset
		end

		local totalPanelHeight = totalContentHeight + 40
		local cam = Workspace.CurrentCamera
		local maxAllowedHeight = cam and (cam.ViewportSize.Y * 0.85) or 600
		local finalHeight = math.clamp(totalPanelHeight, 150, maxAllowedHeight)

		if animate then
			TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
			}):Play()
		else
			f.Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
		end
	end)
end

local function addCollapsibleCategory(name, emoji, defaultOpen)
	local catFrame = Instance.new("Frame")
	catFrame.Name = name .. "Category"
	catFrame.Size = UDim2.new(1, 0, 0, 0)
	catFrame.AutomaticSize = Enum.AutomaticSize.Y
	catFrame.BackgroundTransparency = 1
	catFrame.LayoutOrder = getOrder()
	catFrame.Parent = scroll

	local catLayout = Instance.new("UIListLayout")
	catLayout.SortOrder = Enum.SortOrder.LayoutOrder
	catLayout.Padding = UDim.new(0, 4)
	catLayout.Parent = catFrame

	local headerBtn = Instance.new("TextButton")
	headerBtn.Name = "Header"
	headerBtn.Size = UDim2.new(1, 0, 0, 26)
	headerBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	headerBtn.BorderSizePixel = 0
	headerBtn.Font = Enum.Font.GothamBold
	headerBtn.TextSize = 11
	headerBtn.TextColor3 = Color3.fromRGB(150, 165, 195)
	headerBtn.TextXAlignment = Enum.TextXAlignment.Left
	headerBtn.LayoutOrder = 1
	headerBtn.Parent = catFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = headerBtn

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 10)
	headerPadding.Parent = headerBtn

	local clipWrapper = Instance.new("Frame")
	clipWrapper.Name = "ClipWrapper"
	clipWrapper.Size = UDim2.new(1, 0, 0, 0)
	clipWrapper.ClipsDescendants = true
	clipWrapper.BackgroundTransparency = 1
	clipWrapper.LayoutOrder = 2
	clipWrapper.Parent = catFrame

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Parent = clipWrapper

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 4)
	contentLayout.Parent = content

	local isOpen = (defaultOpen == true)

	local function updateHeader()
		local arrow = isOpen and "[-] " or "[+] "
		local emojiSuffix = (emoji and emoji ~= "") and (" " .. emoji) or ""
		headerBtn.Text = arrow .. name:upper() .. emojiSuffix
		headerBtn.TextColor3 = isOpen and Color3.fromRGB(0, 215, 255) or Color3.fromRGB(120, 135, 160)
	end

	local function toggleAccordion()
		isOpen = not isOpen
		updateHeader()

		local targetH = isOpen and contentLayout.AbsoluteContentSize.Y or 0
		TweenService:Create(clipWrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, targetH)
		}):Play()

		adjustPanelHeight(true)
	end

	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if isOpen then
			clipWrapper.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y)
		end
	end)

	if isOpen then
		task.defer(function()
			clipWrapper.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y)
		end)
	else
		clipWrapper.Size = UDim2.new(1, 0, 0, 0)
	end
	updateHeader()

	headerBtn.MouseButton1Click:Connect(toggleAccordion)

	table.insert(categories, {
		isOpen = function() return isOpen end,
		contentLayout = contentLayout
	})

	return content
end

local function addActionButton(parent, name, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -6, 1, -6)
	btn.Position = UDim2.new(0, 3, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(225, 235, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local ok, err = pcall(onClick)
		if not ok then warn("[Phumipad Tool Error]: " .. tostring(err)) end
	end)
	return btn
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

-- ฟังก์ชันสร้างชุดปุ่ม Preset ขนาดกะทัดรัด (Modern Quick Preset Chips)
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

-- ================== POPULATE CATEGORIES ==================

-- [1] MOVEMENT 🏃 (พร้อมปุ่ม Quick Preset 5 ระดับ)
local movementContent = addCollapsibleCategory("Movement", "🏃", false)

local walkControl = addInputToggleRow(movementContent, "Walk Speed", state.speedValue, state.speedEnabled, function(_, render)
	state.speedEnabled = not state.speedEnabled
	render(state.speedEnabled)
	if humanoid then
		humanoid.WalkSpeed = state.speedEnabled and (tonumber(state.speedValue) or 16) or state.baseWalkSpeed
	end
end, function(val)
	state.speedValue = val
	if state.speedEnabled and humanoid then humanoid.WalkSpeed = val end
end)

-- ปุ่ม Preset ใต้ Walk Speed: 20, 40, 60, 80, 100
addPresetChips(movementContent, {20, 40, 60, 80, 100}, function(val)
	walkControl.setVal(val)
end)

local tpControl = addInputToggleRow(movementContent, "TP Walk", state.tpWalkSpeed, state.tpWalkEnabled, function(_, render)
	state.tpWalkEnabled = not state.tpWalkEnabled
	render(state.tpWalkEnabled)
	applyTPWalk(state.tpWalkEnabled)
end, function(val)
	state.tpWalkSpeed = val
end)

-- ปุ่ม Preset ใต้ TP Walk: 1, 2, 3, 4, 5
addPresetChips(movementContent, {1, 2, 3, 4, 5}, function(val)
	tpControl.setVal(val)
end)

-- [2] UTILITIES ⚙️
local utilitiesContent = addCollapsibleCategory("Utilities", "⚙️", false)

addToggleRow(utilitiesContent, "Instant Interact", state.instantInteract, function(_, render)
	state.instantInteract = not state.instantInteract
	render(state.instantInteract)
end)

addToggleRow(utilitiesContent, "Infinite Jump", state.infiniteJump, function(_, render)
	state.infiniteJump = not state.infiniteJump
	render(state.infiniteJump)
end)

addToggleRow(utilitiesContent, "God Mode", state.godMode, function(_, render)
	state.godMode = not state.godMode
	render(state.godMode)
	applyGodMode(state.godMode)
end)

addToggleRow(utilitiesContent, "Noclip", state.noclip, function(_, render)
	state.noclip = not state.noclip
	render(state.noclip)
	applyNoclip(state.noclip)
end)

addToggleRow(utilitiesContent, "Anti Ragdoll", state.antiRagdoll, function(_, render)
	state.antiRagdoll = not state.antiRagdoll
	render(state.antiRagdoll)
	applyAntiRagdoll(state.antiRagdoll)
end)

-- [3] VISUAL 👁️
local visualContent = addCollapsibleCategory("Visual", "👁️", false)

addToggleRow(visualContent, "Player ESP", state.esp, function(_, render)
	state.esp = not state.esp
	render(state.esp)
	applyESP(state.esp)
end)

addToggleRow(visualContent, "ESP Team Colors", state.espTeamMode, function(_, render)
	state.espTeamMode = not state.espTeamMode
	render(state.espTeamMode)
end)

addToggleRow(visualContent, "Bot ESP", state.botEsp, function(_, render)
	state.botEsp = not state.botEsp
	render(state.botEsp)
	applyBotESP(state.botEsp)
end)

addToggleRow(visualContent, "FPS Booster (Potato)", state.fpsBooster, function(_, render)
	state.fpsBooster = not state.fpsBooster
	render(state.fpsBooster)
	applyFPSBooster(state.fpsBooster)
end)

addToggleRow(visualContent, "Full Bright", state.fullBright, function(_, render)
	state.fullBright = not state.fullBright
	render(state.fullBright)
	applyFullBright(state.fullBright)
end)

-- [ GLOSSY BLACK BATTERY SAVER BUTTON ]
local stSpecialRow = Instance.new("Frame")
stSpecialRow.Size = UDim2.new(1, 0, 0, 40) 
stSpecialRow.BackgroundTransparency = 1 
stSpecialRow.LayoutOrder = getOrder()
stSpecialRow.Parent = visualContent

local stBtnWrapper = Instance.new("Frame")
stBtnWrapper.Size = UDim2.new(1, -6, 1, -4)
stBtnWrapper.Position = UDim2.new(0, 3, 0, 2)
stBtnWrapper.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
stBtnWrapper.BorderSizePixel = 0
stBtnWrapper.Parent = stSpecialRow
Instance.new("UICorner", stBtnWrapper).CornerRadius = UDim.new(1, 0)

local wrapperStroke = Instance.new("UIStroke")
wrapperStroke.Color = Color3.fromRGB(0, 0, 0)
wrapperStroke.Thickness = 2
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
	NumberSequenceKeypoint.new(0, 0.7),
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
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 15)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
innerShadow.Parent = innerGlow

local stText = Instance.new("TextLabel")
stText.Size = UDim2.new(1, 0, 1, 0)
stText.BackgroundTransparency = 1
stText.Text = "BATTERY SAVER"
stText.TextColor3 = Color3.fromRGB(255, 255, 255)
stText.Font = Enum.Font.GothamBold
stText.TextSize = 11
stText.ZIndex = 2
stText.Parent = stBtnWrapper

stBtn.MouseEnter:Connect(function()
	TweenService:Create(innerShadow, TweenInfo.new(0.2), {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 45)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 25)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 5))
		})
	}):Play()
end)

stBtn.MouseLeave:Connect(function()
	TweenService:Create(innerShadow, TweenInfo.new(0.2), {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 15)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
		})
	}):Play()
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
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.5
	flash.ZIndex = 5
	flash.Parent = stBtnWrapper
	Instance.new("UICorner", flash).CornerRadius = UDim.new(1, 0)
	
	TweenService:Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	task.delay(0.35, function() flash:Destroy() end)

	applyScreenTime(true)
end)

-- [4] WAYPOINTS 📍
local waypointsContent = addCollapsibleCategory("Waypoints", "📍", false)

local spotGrid = Instance.new("Frame")
spotGrid.Size = UDim2.new(1, 0, 0, 28)
spotGrid.BackgroundTransparency = 1
spotGrid.LayoutOrder = getOrder()
spotGrid.Parent = waypointsContent

local clearGrid = Instance.new("Frame")
clearGrid.Size = UDim2.new(1, 0, 0, 26)
clearGrid.BackgroundTransparency = 1
clearGrid.LayoutOrder = getOrder()
clearGrid.Parent = waypointsContent

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

-- [5] MORE TOOLS 🧰
local toolsContent = addCollapsibleCategory("More Tools", "🧰", false)

addActionButton(toolsContent, "Auto Clicker", function()
	launchAutoClickerScript()
end)

addActionButton(toolsContent, "Stalker", function()
	launchStalkerScript()
end)

addActionButton(toolsContent, "Aiming (Aimbot)", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/DanielHubll/DanielHubll/refs/heads/main/Aimbot%20Mobile"))()
	end)
end)

addActionButton(toolsContent, "Open Fly GUI (V3)", function()
	launchFlyScript()
end)

addActionButton(toolsContent, "Anti AFK", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
	end)
end)

addActionButton(toolsContent, "Player Teleport", function()
	launchPlayerTeleportScript()
end)

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
	openBtn.Position = UDim2.new(0, 14, 0, 52)
	openBtn.Visible = true
end)
