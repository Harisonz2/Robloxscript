-- =========================================================================
--   PHUMIPAD TOOLBOX [v2.9 PRO EDITION] - NEO-GLASS UI
--   Neo-Glass Redesign + Theme Studio (Accent / Opacity / Base / Pattern)
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
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

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
	fpsBoostLevel = 0,
	tracersEnabled = false,
	screenTime = false,
	fpsHudEnabled = false,
	baseMaxHealth = 100,

	-- v2.7 New Systems
	flyEnabled = false,
	flySpeed = 2,
	freecamEnabled = false,
	freecamSpeed = 1,
	autoRejoin = false,
	joinLeaveNotify = false,
	afkWarnNotify = true,
	wpTween = false,
	wpTweenSpeed = 120,
	saverFpsCap = 15,
	saverStop3D = true,
	uiScale = 1,
	menuKey = "RightControl",
	-- v2.8: จำสถานะหน้าต่างเมนู
	uiActiveTab = "move",
	uiMenuVisible = true,
	uiFolded = false,
	uiPos = {},
	uiDockPos = {},
	uiWidth = 300,
	-- v2.9: ธีม UI
	themeAccent = {0, 200, 255},
	themeBase = "Dark",
	uiTransparency = 0.06,
	uiPattern = "Dots",
	themeAnimBorder = true,
	themePerTab = false,
	_fpsCullRunning = false,
	_tracerConn = nil,
	_tracerGui = nil,
	_tracerCache = {},
	_flyConn = nil,
	_flyBV = nil,
	_flyBG = nil,
	_freecamConn = nil,
	_freecamInputConn = nil,
	_tapTpGui = nil,
	_tapTpArmed = false,
	waypointSlots = {},

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
	_spectateConn = nil,

	-- Backups & Dynamic Waypoints Storage
	fbBackup = nil,
	potatoBackup = nil,
	waypointCount = 0,
	savedPositions = {},
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
local scriptAlive = true

-- ================== CONFIG SAVE / LOAD SYSTEM (v2.7) ==================
-- บันทึกค่าลงไฟล์แยกตามเกม (PlaceId) ผ่าน writefile/readfile ของ executor
local CONFIG_FOLDER = "PhumipadPro"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. tostring(game.PlaceId) .. ".json"
local canFileIO = (type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function")

local SAVE_KEYS = {
	"speedEnabled", "speedValue", "tpWalkEnabled", "tpWalkSpeed", "jumpEnabled", "jumpValue",
	"gravityEnabled", "gravityValue", "instantInteract", "infiniteJump", "godMode", "noclip",
	"antiRagdoll", "spinBotEnabled", "spinSpeed", "clickTpEnabled", "builtInAntiAfk", "fullBright",
	"timeLockEnabled", "timeLockValue", "fovEnabled", "fovValue", "esp", "espTeamMode", "botEsp",
	"fpsBooster", "fpsHudEnabled", "flyEnabled", "flySpeed", "freecamSpeed", "autoRejoin",
	"joinLeaveNotify", "afkWarnNotify", "wpTween", "wpTweenSpeed", "saverFpsCap", "saverStop3D",
	"uiScale", "menuKey", "fpsBoostLevel", "tracersEnabled",
	"uiActiveTab", "uiMenuVisible", "uiFolded", "uiPos", "uiDockPos", "uiWidth",
	"themeAccent", "themeBase", "uiTransparency", "uiPattern", "themeAnimBorder", "themePerTab"
}

local loadedWaypoints = nil -- {{name=..., cf={12 numbers} or nil}, ...}

local function serializeWaypoints()
	local list = {}
	local indices = {}
	for idx, _ in pairs(state.waypointSlots) do table.insert(indices, idx) end
	table.sort(indices)
	for _, idx in ipairs(indices) do
		local cf = state.savedPositions[idx]
		local entry = {name = state.savedNames[idx] or ("Spot " .. idx)}
		if typeof(cf) == "CFrame" then
			entry.cf = {cf:GetComponents()}
		end
		table.insert(list, entry)
	end
	return list
end

local function buildConfigTable()
	-- v2.8: ดึงสถานะหน้าต่างล่าสุด (ตำแหน่ง/แท็บ/พับ/ซ่อน) ก่อนบันทึก
	if state._collectUi then pcall(state._collectUi) end
	local data = {version = "2.7", values = {}, waypoints = serializeWaypoints()}
	for _, k in ipairs(SAVE_KEYS) do
		data.values[k] = state[k]
	end
	return data
end

local lastSavedJson = nil
local autoSavePaused = false
local function saveConfig(silent)
	if not canFileIO then return false end
	local ok = pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then
			makefolder(CONFIG_FOLDER)
		end
		local json = HttpService:JSONEncode(buildConfigTable())
		if json ~= lastSavedJson then
			writefile(CONFIG_FILE, json)
			lastSavedJson = json
		end
	end)
	return ok
end

local function loadConfig()
	if not canFileIO then return false end
	local ok = pcall(function()
		if not isfile(CONFIG_FILE) then error("no file") end
		local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
		if type(data) ~= "table" then error("bad data") end
		for _, k in ipairs(SAVE_KEYS) do
			local v = data.values and data.values[k]
			if v ~= nil and type(v) == type(state[k]) then
				state[k] = v
			end
		end
		if type(data.waypoints) == "table" then
			loadedWaypoints = data.waypoints
		end
	end)
	return ok
end

local function deleteConfig()
	if not canFileIO then return false end
	return pcall(function()
		if isfile(CONFIG_FILE) and type(delfile) == "function" then delfile(CONFIG_FILE) end
		lastSavedJson = nil
	end)
end

local configLoaded = loadConfig()
-- v2.8: รองรับ config เก่า (fpsBooster แบบเปิด/ปิด) -> ระดับ 1
if state.fpsBooster and (tonumber(state.fpsBoostLevel) or 0) == 0 then state.fpsBoostLevel = 1 end
state.fpsBoostLevel = math.clamp(math.floor(tonumber(state.fpsBoostLevel) or 0), 0, 3)
state.fpsBooster = state.fpsBoostLevel > 0
-- ไม่โหลดสถานะ Freecam ค้างไว้ (ปลอดภัยกว่า)
state.freecamEnabled = false

-- ================== MODERN TOAST NOTIFICATION SYSTEM ==================
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

local function getLeaderstatsString(elapsedSec)
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
					-- v2.7: แสดงอัตราได้ต่อชั่วโมง (หลังผ่านไป 1 นาทีขึ้นไป)
					if elapsedSec and elapsedSec >= 60 then
						diffText = string.format(" (+%s • %s/h)", formatStatDiff(diff), formatStatDiff(diff / elapsedSec * 3600))
					end
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
	if not on then
		-- v2.7: คืนค่าการเรนเดอร์ 3D และ FPS cap
		pcall(function() RunService:Set3dRenderingEnabled(true) end)
		if type(setfpscap) == "function" then pcall(setfpscap, 60) end
		return
	end

	recordInitialStats()
	-- v2.7: ประหยัดแบตจริงจัง - ปิดเรนเดอร์ 3D และจำกัด FPS ระหว่างเปิด Overlay
	if state.saverStop3D then
		pcall(function() RunService:Set3dRenderingEnabled(false) end)
	end
	if type(setfpscap) == "function" and (tonumber(state.saverFpsCap) or 0) > 0 then
		pcall(setfpscap, tonumber(state.saverFpsCap))
	end

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
			statsLabel.Text = getLeaderstatsString(diff)
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

-- =========================================================================
-- ============ FPS BOOSTER 3 LEVELS (v2.8) ================================
--  Lv1 FPS Booster     : Quality 1, ปิดเงา/Post FX, วัสดุเรียบ, ซ่อน Decal/Texture, ปิด Particle
--  Lv2 Super Booster   : + ปิดน้ำ/หญ้า/เมฆ/Atmosphere, ปิดไฟ (Light), ลบ Texture ของ Mesh, SurfaceAppearance
--  Lv3 Extreme Booster : + ลบท้องฟ้า, ซ่อนชุด/เครื่องประดับผู้เล่น, ลดแสงเงาทั้งหมด, ซ่อนวัตถุไกลเกิน 300 studs
-- =========================================================================
local function applyFPSBooster(level)
	if level == true then level = 1 elseif not level then level = 0 end
	level = math.clamp(tonumber(level) or 0, 0, 3)

	-- 1) ล้างระดับเดิมทั้งหมดก่อน (คืนค่าเดิมจาก backup)
	if state._fpsConn then state._fpsConn:Disconnect(); state._fpsConn = nil end
	state._fpsCullRunning = false
	local bk = state.potatoBackup
	if bk then
		pcall(function()
			if bk.quality then settings().Rendering.QualityLevel = bk.quality end
		end)
		for inst, props in pairs(bk.props) do
			if inst and inst.Parent then
				for prop, val in pairs(props) do
					pcall(function() inst[prop] = val end)
				end
			end
		end
		for inst, oldParent in pairs(bk.reparented) do
			pcall(function()
				if oldParent and oldParent.Parent then inst.Parent = oldParent end
			end)
		end
		for _, part in ipairs(bk.cullParts) do
			pcall(function() part.LocalTransparencyModifier = 0 end)
		end
		state.potatoBackup = nil
	end

	state.fpsBoostLevel = level
	state.fpsBooster = level > 0
	if level == 0 then return end

	-- 2) สร้าง backup ใหม่
	bk = {props = {}, reparented = {}, cullParts = {}, cullSet = {}, quality = nil}
	state.potatoBackup = bk
	pcall(function() bk.quality = settings().Rendering.QualityLevel end)

	local function set(inst, prop, value)
		pcall(function()
			local p = bk.props[inst]
			if not p then p = {}; bk.props[inst] = p end
			if p[prop] == nil then p[prop] = inst[prop] end
			inst[prop] = value
		end)
	end

	local function stash(inst)
		pcall(function()
			if bk.reparented[inst] == nil then
				bk.reparented[inst] = inst.Parent
				inst.Parent = nil
			end
		end)
	end

	pcall(function() settings().Rendering.QualityLevel = 1 end)
	set(Lighting, "GlobalShadows", false)
	set(Lighting, "FogEnd", 9e9)
	set(Lighting, "ShadowSoftness", 0)
	for _, fx in ipairs(Lighting:GetChildren()) do
		if fx:IsA("PostEffect") then
			set(fx, "Enabled", false)
		elseif level >= 2 and fx:IsA("Atmosphere") then
			set(fx, "Density", 0)
			set(fx, "Haze", 0)
			set(fx, "Glare", 0)
		elseif level >= 2 and fx:IsA("Clouds") then
			set(fx, "Enabled", false)
		elseif level >= 3 and fx:IsA("Sky") then
			stash(fx)
		end
	end

	if level >= 2 then
		set(Lighting, "EnvironmentDiffuseScale", 0)
		set(Lighting, "EnvironmentSpecularScale", 0)
		local terrain = Workspace:FindFirstChildOfClass("Terrain")
		if terrain then
			set(terrain, "WaterWaveSize", 0)
			set(terrain, "WaterWaveSpeed", 0)
			set(terrain, "WaterReflectance", 0)
			set(terrain, "WaterTransparency", 0)
			pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
			for _, c in ipairs(terrain:GetChildren()) do
				if c:IsA("Clouds") then set(c, "Enabled", false) end
			end
		end
	end
	if level >= 3 then
		set(Lighting, "Brightness", 1)
		set(Lighting, "OutdoorAmbient", Color3.fromRGB(150, 150, 150))
		set(Lighting, "Ambient", Color3.fromRGB(150, 150, 150))
		set(Lighting, "FogEnd", 400)
		set(Lighting, "FogStart", 200)
	end

	local function isInCharacter(obj)
		local model = obj:FindFirstAncestorOfClass("Model")
		while model do
			if model:FindFirstChildOfClass("Humanoid") then return model end
			model = model:FindFirstAncestorOfClass("Model")
		end
		return nil
	end

	local function potatoify(obj)
		pcall(function()
			if obj:IsA("BasePart") then
				local charModel = isInCharacter(obj)
				if not charModel then
					set(obj, "Material", Enum.Material.SmoothPlastic)
					set(obj, "Reflectance", 0)
					if obj:IsA("MeshPart") and level >= 2 then
						set(obj, "TextureID", "")
					end
					if level >= 3 and not bk.cullSet[obj] then
						bk.cullSet[obj] = true
						table.insert(bk.cullParts, obj)
					end
				elseif level >= 3 then
					-- ซ่อนเครื่องประดับผู้เล่นคนอื่น (ไม่ใช่ตัวเรา)
					local acc = obj:FindFirstAncestorOfClass("Accessory")
					if acc and charModel ~= player.Character then
						set(obj, "Transparency", 1)
					end
				end
				set(obj, "CastShadow", false)
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				set(obj, "Transparency", 1)
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
				or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
				set(obj, "Enabled", false)
			elseif level >= 2 and (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) then
				set(obj, "Enabled", false)
			elseif level >= 2 and obj:IsA("SpecialMesh") then
				set(obj, "TextureId", "")
			elseif level >= 2 and obj:IsA("SurfaceAppearance") then
				stash(obj)
			elseif level >= 3 and (obj:IsA("Shirt") or obj:IsA("Pants")) then
				set(obj, obj:IsA("Shirt") and "ShirtTemplate" or "PantsTemplate", "")
			elseif level >= 3 and obj:IsA("ShirtGraphic") then
				set(obj, "Graphic", "")
			end
		end)
	end

	local all = Workspace:GetDescendants()
	for i, item in ipairs(all) do
		potatoify(item)
		if i % 4000 == 0 then
			task.wait() -- กันเกมค้างในแมพใหญ่
			if state.potatoBackup ~= bk then return end -- ถูกเปลี่ยนระดับระหว่างสแกน
		end
	end
	state._fpsConn = Workspace.DescendantAdded:Connect(function(obj)
		task.defer(potatoify, obj)
	end)

	-- 3) Extreme: ซ่อนวัตถุที่อยู่ไกลเกิน 300 studs (ประมวลผลทีละชุด ไม่กระตุก)
	if level >= 3 then
		state._fpsCullRunning = true
		local myBk = bk
		task.spawn(function()
			local CULL_DIST = 300
			while state._fpsCullRunning and state.potatoBackup == myBk and scriptAlive do
				local cam = Workspace.CurrentCamera
				local origin = cam and cam.CFrame.Position
				if origin then
					local list = myBk.cullParts
					for i = #list, 1, -1 do
						local part = list[i]
						if not part.Parent then
							myBk.cullSet[part] = nil
							table.remove(list, i)
						else
							local far = (part.Position - origin).Magnitude > CULL_DIST
							part.LocalTransparencyModifier = far and 1 or 0
						end
						if i % 3000 == 0 then task.wait() end
					end
				end
				task.wait(0.75)
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

-- ================== ULTRA-RELIABLE ESP ENGINE (WITH HP%) ==================
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

-- ================== PLAYER TRACERS (v2.8) ==================
-- ลากเส้นจากตัวละครเราไปยังผู้เล่นอื่นแบบเรียลไทม์ (ใช้ GUI Frame จึงรองรับทุก executor)
local function applyTracers(on)
	if state._tracerConn then state._tracerConn:Disconnect(); state._tracerConn = nil end
	if state._tracerGui then pcall(function() state._tracerGui:Destroy() end); state._tracerGui = nil end
	state._tracerCache = {}
	if not on then return end

	local tg = Instance.new("ScreenGui")
	tg.Name = "Phumipad_Tracers"
	tg.ResetOnSpawn = false
	tg.IgnoreGuiInset = true
	tg.DisplayOrder = 5
	safeParentGui(tg)
	state._tracerGui = tg

	local function getLine(plr)
		local ln = state._tracerCache[plr]
		if ln and ln.Parent then return ln end
		ln = Instance.new("Frame")
		ln.Name = plr.Name .. "_Tracer"
		ln.AnchorPoint = Vector2.new(0.5, 0.5)
		ln.BorderSizePixel = 0
		ln.BackgroundTransparency = 0.15
		ln.Parent = tg
		state._tracerCache[plr] = ln
		return ln
	end

	state._tracerConn = RunService.RenderStepped:Connect(function()
		if not state.tracersEnabled then return end
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local center = Vector2.new(vp.X / 2, vp.Y / 2)

		-- จุดเริ่ม: ตัวละครเรา (ถ้าอยู่นอกจอใช้ขอบล่างกลางจอ)
		local myChar = player.Character
		local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
		local origin = Vector2.new(vp.X / 2, vp.Y - 4)
		if myRoot then
			local p, onScreen = cam:WorldToViewportPoint(myRoot.Position)
			if onScreen and p.Z > 0 then origin = Vector2.new(p.X, p.Y) end
		end

		local seen = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
				if root and hum and hum.Health > 0 then
					seen[plr] = true
					local ln = getLine(plr)
					local p = cam:WorldToViewportPoint(root.Position)
					local target = Vector2.new(p.X, p.Y)
					if p.Z < 0 then
						-- อยู่ด้านหลังกล้อง: กลับทิศแล้วดันไปที่ขอบจอ
						local dir = center - target
						if dir.Magnitude < 1 then dir = Vector2.new(0, 1) end
						target = center + dir.Unit * math.max(vp.X, vp.Y)
					end
					local delta = target - origin
					local len = delta.Magnitude
					local mid = (origin + target) / 2
					ln.Position = UDim2.new(0, mid.X, 0, mid.Y)
					ln.Size = UDim2.new(0, len, 0, 1.6)
					ln.Rotation = math.deg(math.atan2(delta.Y, delta.X))
					ln.BackgroundColor3 = getTeamOrPlayerColor(plr)
					ln.Visible = true
				end
			end
		end
		for plr, ln in pairs(state._tracerCache) do
			if not seen[plr] then
				if plr.Parent then
					ln.Visible = false
				else
					pcall(function() ln:Destroy() end)
					state._tracerCache[plr] = nil
				end
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
	-- v2.7: ใช้ GetPlayerFromCharacter แทนการวนลูปผู้เล่นทุกคน (เร็วกว่ามาก)
	return Players:GetPlayerFromCharacter(model) ~= nil
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
		if data.AncestryConn then pcall(function() data.AncestryConn:Disconnect() end) end
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

		local data = {
			Highlight = hl, Billboard = bb, Label = label,
			Root = root, Head = head, Color = col
		}
		state.botEspCache[bot] = data

		-- v2.7: เก็บ connection ไว้เพื่อ Disconnect ตอนล้าง (กัน memory leak)
		data.AncestryConn = bot.AncestryChanged:Connect(function(_, parent)
			if not parent then cleanBotESP(bot) end
		end)
	end

	-- v2.7: สแกนเฉพาะ Humanoid แล้วเช็ค Model แม่ (เบากว่าการเช็คทุก Descendant)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent then
			registerBot(obj.Parent)
		end
	end

	state._botDescConn = Workspace.DescendantAdded:Connect(function(obj)
		if not obj:IsA("Humanoid") then return end
		task.delay(0.15, function()
			if state.botEsp and obj.Parent then registerBot(obj.Parent) end
		end)
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

-- ================== BUILT-IN FLY (v2.7 - แทน Fly GUI ภายนอก) ==================
local function getFlatAxes(camCF)
	local look = camCF.LookVector
	local right = camCF.RightVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatRight = Vector3.new(right.X, 0, right.Z)
	if flatLook.Magnitude < 1e-3 then flatLook = Vector3.new(0, 0, -1) end
	if flatRight.Magnitude < 1e-3 then flatRight = Vector3.new(1, 0, 0) end
	return flatLook.Unit, flatRight.Unit
end

local function getVerticalInput()
	if UserInputService:GetFocusedTextBox() then return 0 end
	local up = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then up = up - 1 end
	return up
end

local function applyFly(on)
	if state._flyConn then state._flyConn:Disconnect(); state._flyConn = nil end
	if state._flyBV then pcall(function() state._flyBV:Destroy() end); state._flyBV = nil end
	if state._flyBG then pcall(function() state._flyBG:Destroy() end); state._flyBG = nil end
	if not on then
		if humanoid then pcall(function() humanoid.PlatformStand = false end) end
		return
	end
	if not hrp or not humanoid then return end

	local bv = Instance.new("BodyVelocity")
	bv.Name = "PhumipadFlyBV"
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = hrp
	state._flyBV = bv

	local bg = Instance.new("BodyGyro")
	bg.Name = "PhumipadFlyBG"
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.P = 9e4
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp
	state._flyBG = bg

	state._flyConn = RunService.RenderStepped:Connect(function()
		if not state.flyEnabled or not hrp or not hrp.Parent or not humanoid then return end
		local cam = Workspace.CurrentCamera
		if not cam then return end
		humanoid.PlatformStand = true
		local camCF = cam.CFrame
		local flatLook, flatRight = getFlatAxes(camCF)
		local md = humanoid.MoveDirection
		local dir = Vector3.new(0, 0, 0)
		if md.Magnitude > 0 then
			-- เดินหน้าตามทิศกล้อง (รวมก้ม/เงย) จึงบินขึ้นลงบนมือถือได้ด้วยการหมุนกล้อง
			dir = camCF.LookVector * md:Dot(flatLook) + flatRight * md:Dot(flatRight)
		end
		local up = getVerticalInput()
		if humanoid.Jump then up = up + 1 end -- ปุ่มกระโดดบนมือถือ = บินขึ้น
		dir = dir + Vector3.new(0, up, 0)
		if dir.Magnitude > 1 then dir = dir.Unit end
		bv.Velocity = dir * ((tonumber(state.flySpeed) or 2) * 25)
		bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
	end)
end

-- ================== FREECAM (v2.7) ==================
local fcCF, fcYaw, fcPitch = nil, 0, 0

local function applyFreecam(on)
	if state._freecamConn then state._freecamConn:Disconnect(); state._freecamConn = nil end
	if state._freecamInputConn then state._freecamInputConn:Disconnect(); state._freecamInputConn = nil end
	local cam = Workspace.CurrentCamera
	if not on then
		if hrp then pcall(function() hrp.Anchored = false end) end
		pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			if humanoid then cam.CameraSubject = humanoid end
		end
		return
	end
	if not cam then return end
	if state._spectateConn then state._spectateConn:Disconnect(); state._spectateConn = nil end

	fcCF = cam.CFrame
	local rx, ry = fcCF:ToEulerAnglesYXZ()
	fcPitch, fcYaw = rx, ry
	cam.CameraType = Enum.CameraType.Scriptable
	if hrp then hrp.Anchored = true end

	state._freecamInputConn = UserInputService.InputChanged:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				fcYaw = fcYaw - input.Delta.X * 0.004
				fcPitch = math.clamp(fcPitch - input.Delta.Y * 0.004, -1.45, 1.45)
			end
		elseif input.UserInputType == Enum.UserInputType.Touch and not gpe then
			-- ลากนิ้วครึ่งขวาของจอเพื่อหมุนกล้อง (ครึ่งซ้ายเป็นจอยเดิน)
			if input.Position.X > cam.ViewportSize.X * 0.4 then
				fcYaw = fcYaw - input.Delta.X * 0.006
				fcPitch = math.clamp(fcPitch - input.Delta.Y * 0.006, -1.45, 1.45)
			end
		end
	end)

	state._freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not state.freecamEnabled then return end
		local c = Workspace.CurrentCamera
		if not c then return end
		c.CameraType = Enum.CameraType.Scriptable
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		local rot = CFrame.fromEulerAnglesYXZ(fcPitch, fcYaw, 0)
		local flatLook, flatRight = getFlatAxes(rot)
		local md = humanoid and humanoid.MoveDirection or Vector3.new(0, 0, 0)
		local move = rot.LookVector * md:Dot(flatLook) + rot.RightVector * md:Dot(flatRight)
		move = move + Vector3.new(0, getVerticalInput(), 0)
		local speed = (tonumber(state.freecamSpeed) or 1) * 40
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 3 end
		fcCF = CFrame.new(fcCF.Position + move * speed * dt) * rot
		c.CFrame = fcCF
	end)
end

-- ================== CLICK / TAP TELEPORT (v2.7 รองรับมือถือ) ==================
local tpRayParams = RaycastParams.new()
tpRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function teleportToScreenPoint(x, y, isViewportPoint)
	local cam = Workspace.CurrentCamera
	if not cam or not hrp then return false end
	local ray = isViewportPoint and cam:ViewportPointToRay(x, y) or cam:ScreenPointToRay(x, y)
	tpRayParams.FilterDescendantsInstances = {player.Character}
	local res = Workspace:Raycast(ray.Origin, ray.Direction * 5000, tpRayParams)
	if res then
		local look = hrp.CFrame.LookVector
		local pos = res.Position + Vector3.new(0, 3.2, 0)
		hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
		return true
	end
	return false
end

local function updateTapTpButton()
	if state._tapTpGui then pcall(function() state._tapTpGui:Destroy() end); state._tapTpGui = nil end
	state._tapTpArmed = false
	if not (state.clickTpEnabled and UserInputService.TouchEnabled) then return end

	local g = Instance.new("ScreenGui")
	g.Name = "Phumipad_TapTP"
	g.ResetOnSpawn = false
	safeParentGui(g)
	state._tapTpGui = g

	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 84, 0, 34)
	b.Position = UDim2.new(1, -100, 0.5, -60)
	b.BackgroundColor3 = Color3.fromRGB(14, 22, 38)
	b.BorderSizePixel = 0
	b.Text = "📍 TAP TP"
	b.TextColor3 = Color3.fromRGB(240, 250, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.AutoButtonColor = false
	b.Parent = g
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 210, 255)
	s.Thickness = 1.6
	s.Parent = b

	b.MouseButton1Click:Connect(function()
		state._tapTpArmed = not state._tapTpArmed
		b.Text = state._tapTpArmed and "แตะจุดที่จะไป" or "📍 TAP TP"
		b.BackgroundColor3 = state._tapTpArmed and Color3.fromRGB(0, 150, 95) or Color3.fromRGB(14, 22, 38)
	end)
	state._tapTpButton = b
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
	if state.flyEnabled     then applyFly(true) end
	if state.spinBotEnabled then applySpinBot(true) end
	if state.freecamEnabled then
		state.freecamEnabled = false
		applyFreecam(false)
	end
end))

-- =========================================================================
-- ============ v2.9 NEO-GLASS UI ENGINE (THEME • PATTERN • FX) ============
--  ทุกองค์ประกอบผูกกับ "บทบาทสี" (role) จึงเปลี่ยนสี/ความใส/ลวดลายได้แบบสด
-- =========================================================================
local UI = {reg = {}, onApply = {}, patternToken = 0, hideToken = 0}

UI.BASES = {
	Dark     = {bg = {11, 14, 22}, surface = {19, 23, 35}, surface2 = {29, 35, 52}, stroke = {44, 52, 76}},
	Midnight = {bg = {6, 10, 26},  surface = {13, 19, 42}, surface2 = {22, 31, 64}, stroke = {40, 54, 100}},
	AMOLED   = {bg = {0, 0, 0},    surface = {11, 11, 14}, surface2 = {22, 22, 27}, stroke = {44, 44, 52}},
	Violet   = {bg = {15, 9, 26},  surface = {25, 16, 40}, surface2 = {38, 25, 60}, stroke = {66, 46, 102}},
	Forest   = {bg = {6, 15, 13},  surface = {12, 26, 23}, surface2 = {20, 40, 35}, stroke = {38, 68, 60}},
}
UI.BASE_ORDER = {"Dark", "Midnight", "AMOLED", "Violet", "Forest"}
UI.PATTERNS = {"None", "Grid", "Dots", "Diagonal", "Aurora", "Stars"}
UI.ACCENTS = {
	{0, 200, 255}, {125, 95, 255}, {255, 70, 170}, {0, 225, 140},
	{255, 150, 35}, {255, 65, 85}, {255, 210, 60}, {230, 236, 248}
}

function UI.rgb(t) return Color3.fromRGB(t[1], t[2], t[3]) end
function UI.base() return UI.BASES[state.themeBase] or UI.BASES.Dark end
function UI.accent()
	local a = state.themeAccent
	if type(a) == "table" and #a == 3 then return Color3.fromRGB(a[1], a[2], a[3]) end
	return Color3.fromRGB(0, 200, 255)
end
function UI.accent2()
	local h, s, v = UI.accent():ToHSV()
	if s < 0.15 then return Color3.fromRGB(140, 150, 175) end
	return Color3.fromHSV((h + 0.12) % 1, math.clamp(s, 0.55, 1), math.max(v, 0.85))
end
function UI.color(role)
	if role == "accent" then return UI.accent() end
	if role == "accent2" then return UI.accent2() end
	if role == "accentSoft" then return UI.accent():Lerp(UI.rgb(UI.base().surface), 0.7) end
	if role == "text" then return Color3.fromRGB(240, 244, 252) end
	if role == "sub" then return Color3.fromRGB(150, 162, 188) end
	local b = UI.base()
	return UI.rgb(b[role] or b.surface)
end
function UI.trans(kind)
	local t = math.clamp(tonumber(state.uiTransparency) or 0, 0, 0.85)
	if kind == "bg" then return t end
	if kind == "glass" then return math.clamp(t * 0.8, 0, 0.82) end
	if kind == "soft" then return math.clamp(0.45 + t * 0.45, 0, 0.92) end
	return 0
end
function UI.gradSeq()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.accent()),
		ColorSequenceKeypoint.new(0.5, UI.accent2()),
		ColorSequenceKeypoint.new(1, UI.accent())
	})
end
function UI.applyOne(e)
	local inst, prop, role = e[1], e[2], e[3]
	pcall(function()
		if role == "grad" then
			inst.Color = UI.gradSeq()
		elseif string.sub(role, 1, 2) == "T:" then
			inst[prop] = UI.trans(string.sub(role, 3))
		else
			inst[prop] = UI.color(role)
		end
	end)
end
-- ผูกคุณสมบัติกับบทบาทสี (เรียกหลังตั้ง Parent แล้ว)
function UI.bind(inst, prop, role)
	local e = {inst, prop, role, inst.Parent ~= nil}
	table.insert(UI.reg, e)
	pcall(function() inst:SetAttribute("PPT_" .. prop, true) end)
	UI.applyOne(e)
	return inst
end
function UI.apply(skipPattern)
	local keep = {}
	for _, e in ipairs(UI.reg) do
		local inst = e[1]
		if inst and inst.Parent then
			e[4] = true
			UI.applyOne(e)
			table.insert(keep, e)
		elseif inst and not e[4] then
			table.insert(keep, e)
		end
	end
	UI.reg = keep
	for _, fn in ipairs(UI.onApply) do pcall(fn) end
	if not skipPattern and UI.buildPattern then UI.buildPattern() end
end

-- จัดสีให้ส่วนที่สร้างด้วยสีตายตัว (หน้าแท็บต่างๆ) อัตโนมัติ
function UI.classify(c)
	local h, s, v = c:ToHSV()
	if v < 0.3 and s < 0.68 then
		if v < 0.095 then return "bg" elseif v < 0.165 then return "surface" else return "surface2" end
	end
	if h > 0.5 and h < 0.57 and s > 0.75 and v > 0.85 then return "accent" end
	return nil
end
function UI.autoBindOne(obj)
	if obj:GetAttribute("PPNoTheme") then return end
	if UI.patternLayer and (obj == UI.patternLayer or obj:IsDescendantOf(UI.patternLayer)) then return end
	if obj:IsA("GuiObject") and not obj:GetAttribute("PPT_BackgroundColor3") and obj.BackgroundTransparency < 1 then
		local role = UI.classify(obj.BackgroundColor3)
		if role then
			UI.bind(obj, "BackgroundColor3", role)
			if role ~= "accent" and not obj:GetAttribute("PPT_BackgroundTransparency") and obj.BackgroundTransparency < 0.05 then
				UI.bind(obj, "BackgroundTransparency", "T:glass")
			end
		end
	end
	if (obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton")) and not obj:GetAttribute("PPT_TextColor3") then
		if UI.classify(obj.TextColor3) == "accent" then UI.bind(obj, "TextColor3", "accent") end
	end
	if obj:IsA("UIStroke") and not obj:GetAttribute("PPT_Color") then
		local role = UI.classify(obj.Color)
		if role == "accent" then
			UI.bind(obj, "Color", "accent")
		elseif role then
			UI.bind(obj, "Color", "stroke")
		end
	end
end
function UI.autoBind(root)
	pcall(UI.autoBindOne, root)
	for _, d in ipairs(root:GetDescendants()) do pcall(UI.autoBindOne, d) end
end

-- เอฟเฟกต์ระลอกน้ำเมื่อแตะ
function UI.ripple(holder, input)
	pcall(function()
		local s = math.max(UI.mainScale and UI.mainScale.Scale or 1, 0.1)
		local rel = (Vector2.new(input.Position.X, input.Position.Y) - holder.AbsolutePosition) / s
		local size = math.max(holder.AbsoluteSize.X, holder.AbsoluteSize.Y) / s * 2.2
		local c = Instance.new("Frame")
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.new(0, rel.X, 0, rel.Y)
		c.Size = UDim2.new(0, 0, 0, 0)
		c.BackgroundColor3 = UI.accent()
		c.BackgroundTransparency = 0.72
		c.BorderSizePixel = 0
		c.ZIndex = holder.ZIndex + 1
		c:SetAttribute("PPNoTheme", true)
		c.Parent = holder
		Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)
		TweenService:Create(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1}):Play()
		task.delay(0.5, function() pcall(function() c:Destroy() end) end)
	end)
end

function UI.corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r or 10)
	c.Parent = inst
	return c
end
function UI.stroke(inst, role, thick, trans)
	local s = Instance.new("UIStroke")
	s.Thickness = thick or 1
	s.Transparency = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	UI.bind(s, "Color", role or "stroke")
	return s
end

-- =========================================================================
-- ============ NEO-GLASS MAIN PANEL =======================================
-- =========================================================================
local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadToolboxMinimalGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParentGui(sg)

local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 300, 0, 380)
f.Position = UDim2.new(0.04, 0, 0.45, -190)
f.BorderSizePixel = 0
f.Active = true
f.ClipsDescendants = true
f.Parent = sg
UI.bind(f, "BackgroundColor3", "bg")
UI.bind(f, "BackgroundTransparency", "T:bg")
UI.corner(f, 18)

local mainUIScale = Instance.new("UIScale")
mainUIScale.Scale = math.clamp(tonumber(state.uiScale) or 1, 0.6, 1.6)
mainUIScale.Parent = f
UI.mainScale = mainUIScale

-- ขอบเรืองแสงไล่สี (หมุนได้)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1.6
stroke.Transparency = 0.1
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = f
UI.borderGrad = Instance.new("UIGradient")
UI.borderGrad.Parent = stroke
UI.bind(UI.borderGrad, "Color", "grad")

-- ไล่เฉดพื้นหลังเบาๆ ให้มีมิติ
do
	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.Size = UDim2.new(1, 0, 0, 160)
	sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 0
	sheen.Parent = f
	UI.corner(sheen, 18)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.82),
		NumberSequenceKeypoint.new(1, 1)
	})
	g.Parent = sheen
	UI.bind(g, "Color", "grad")
end

-- ================== BACKGROUND PATTERN LAYER ==================
function UI.buildPattern()
	if UI.patternLayer then pcall(function() UI.patternLayer:Destroy() end) end
	UI.patternToken = UI.patternToken + 1
	local token = UI.patternToken
	local layer = Instance.new("Frame")
	layer.Name = "PatternLayer"
	layer.Size = UDim2.new(1, -14, 1, -14)
	layer.Position = UDim2.new(0, 7, 0, 7)
	layer.BackgroundTransparency = 1
	layer.ClipsDescendants = true
	layer.ZIndex = 0
	layer.Parent = f
	UI.patternLayer = layer
	local acc, acc2 = UI.accent(), UI.accent2()
	local p = state.uiPattern

	if p == "Grid" then
		for i = 0, 30 do
			local l = Instance.new("Frame")
			l.Size = UDim2.new(0, 1, 1, 0)
			l.Position = UDim2.new(0, i * 22, 0, 0)
			l.BackgroundColor3 = acc
			l.BackgroundTransparency = 0.9
			l.BorderSizePixel = 0
			l.Parent = layer
		end
		for j = 0, 40 do
			local l = Instance.new("Frame")
			l.Size = UDim2.new(1, 0, 0, 1)
			l.Position = UDim2.new(0, 0, 0, j * 22)
			l.BackgroundColor3 = acc
			l.BackgroundTransparency = 0.9
			l.BorderSizePixel = 0
			l.Parent = layer
		end
	elseif p == "Dots" then
		local rows = {}
		for r = 1, 70 do
			rows[r] = ((r % 2 == 0) and "   " or "") .. string.rep("•     ", 30)
		end
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(0, 1000, 0, 1400)
		t.Position = UDim2.new(0, -6, 0, -4)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.Code
		t.TextSize = 9
		t.LineHeight = 1.9
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextYAlignment = Enum.TextYAlignment.Top
		t.TextColor3 = acc
		t.TextTransparency = 0.72
		t.Text = table.concat(rows, "\n")
		t.Parent = layer
	elseif p == "Diagonal" then
		for i = -30, 40 do
			local l = Instance.new("Frame")
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.Size = UDim2.new(0, 1, 0, 2200)
			l.Position = UDim2.new(0, i * 18, 0.5, 0)
			l.Rotation = 35
			l.BackgroundColor3 = acc
			l.BackgroundTransparency = 0.9
			l.BorderSizePixel = 0
			l.Parent = layer
		end
	elseif p == "Aurora" then
		local blobs = {}
		for i, col in ipairs({acc, acc2}) do
			local b = Instance.new("Frame")
			b.AnchorPoint = Vector2.new(0.5, 0.5)
			b.Size = UDim2.new(1.3, 0, 0.75, 0)
			b.BackgroundColor3 = col
			b.BorderSizePixel = 0
			b.Parent = layer
			UI.corner(b, "full")
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.72),
				NumberSequenceKeypoint.new(1, 1)
			})
			g.Parent = b
			blobs[i] = {b, g}
		end
		task.spawn(function()
			local t0 = os.clock()
			while scriptAlive and token == UI.patternToken and layer.Parent do
				if f.Visible then
					local t = os.clock() - t0
					blobs[1][1].Position = UDim2.new(0.3 + math.sin(t * 0.5) * 0.2, 0, 0.25 + math.cos(t * 0.4) * 0.15, 0)
					blobs[2][1].Position = UDim2.new(0.7 + math.cos(t * 0.45) * 0.2, 0, 0.75 + math.sin(t * 0.35) * 0.15, 0)
					blobs[1][2].Rotation = (t * 20) % 360
					blobs[2][2].Rotation = (-t * 16) % 360
				end
				task.wait(0.05)
			end
		end)
	elseif p == "Stars" then
		local rnd = Random.new(7)
		for _ = 1, 46 do
			local d = Instance.new("Frame")
			local sz = rnd:NextInteger(2, 4)
			d.Size = UDim2.new(0, sz, 0, sz)
			d.Position = UDim2.new(rnd:NextNumber(), 0, rnd:NextNumber(), 0)
			d.BackgroundColor3 = (rnd:NextNumber() > 0.5) and acc or Color3.fromRGB(255, 255, 255)
			d.BackgroundTransparency = rnd:NextNumber(0.3, 0.7)
			d.BorderSizePixel = 0
			d.Parent = layer
			UI.corner(d, "full")
			TweenService:Create(d, TweenInfo.new(rnd:NextNumber(0.8, 2.4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.95}):Play()
		end
	end
end

-- ================== FLOATING DOCK BUTTON (ธีมตามสีที่เลือก) ==================
local openBtn = Instance.new("TextButton")
openBtn.Name = "HighTechFloatingDock"
openBtn.Size = UDim2.new(0, 158, 0, 46)
openBtn.Position = UDim2.new(0, 18, 0, 55)
openBtn.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
openBtn.BorderSizePixel = 0
openBtn.Text = ""
openBtn.Visible = false
openBtn.Active = true
openBtn.AutoButtonColor = false
openBtn.ZIndex = 250
openBtn.Parent = sg
UI.corner(openBtn, "full")
UI.bind(openBtn, "BackgroundColor3", "bg")

do
	local glow = Instance.new("UIStroke")
	glow.Thickness = 2
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = openBtn
	local glowGrad = Instance.new("UIGradient")
	glowGrad.Parent = glow
	UI.bind(glowGrad, "Color", "grad")

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.ZIndex = 250
	fill.Parent = openBtn
	UI.corner(fill, "full")
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Rotation = 90
	fillGrad.Parent = fill
	local function paintFill()
		fillGrad.Color = ColorSequence.new(UI.color("surface2"), UI.color("bg"))
	end
	paintFill()
	table.insert(UI.onApply, paintFill)

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 34, 0, 34)
	badge.Position = UDim2.new(0, 6, 0.5, -17)
	badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	badge.BorderSizePixel = 0
	badge.ZIndex = 251
	badge.Parent = openBtn
	UI.corner(badge, "full")
	local badgeGrad = Instance.new("UIGradient")
	badgeGrad.Rotation = 45
	badgeGrad.Parent = badge
	UI.bind(badgeGrad, "Color", "grad")

	local badgeTxt = Instance.new("TextLabel")
	badgeTxt.Size = UDim2.new(1, 0, 1, 0)
	badgeTxt.BackgroundTransparency = 1
	badgeTxt.Text = "P"
	badgeTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeTxt.TextStrokeTransparency = 0.6
	badgeTxt.Font = Enum.Font.GothamBlack
	badgeTxt.TextSize = 18
	badgeTxt.ZIndex = 252
	badgeTxt.Parent = badge

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.Position = UDim2.new(1, -9, 1, -9)
	dot.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
	dot.BorderSizePixel = 0
	dot.ZIndex = 253
	dot.Parent = badge
	UI.corner(dot, "full")
	local dotStroke = Instance.new("UIStroke")
	dotStroke.Thickness = 2
	dotStroke.Parent = dot
	UI.bind(dotStroke, "Color", "bg")
	TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundTransparency = 0.65}):Play()

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -54, 0, 18)
	nameLbl.Position = UDim2.new(0, 48, 0, 6)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = "PHUMIPAD"
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 252
	nameLbl.Parent = openBtn

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, -54, 0, 14)
	subLbl.Position = UDim2.new(0, 48, 0, 24)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = "แตะเพื่อเปิดเมนู"
	subLbl.Font = Enum.Font.GothamMedium
	subLbl.TextSize = 11
	subLbl.TextXAlignment = Enum.TextXAlignment.Left
	subLbl.ZIndex = 252
	subLbl.Parent = openBtn
	UI.bind(subLbl, "TextColor3", "accent")

	local pressScale = Instance.new("UIScale")
	pressScale.Parent = openBtn
	openBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(pressScale, TweenInfo.new(0.08), {Scale = 0.93}):Play()
		end
	end)
	openBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(pressScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end
	end)

	-- หมุนขอบเรืองแสงของปุ่มลอย + ขอบหน้าต่างหลัก
	task.spawn(function()
		while scriptAlive and openBtn.Parent do
			if openBtn.Visible then
				glowGrad.Rotation = (glowGrad.Rotation + 3) % 360
			end
			if f.Visible and state.themeAnimBorder then
				UI.borderGrad.Rotation = (UI.borderGrad.Rotation + 2) % 360
			end
			task.wait(0.03)
		end
	end)
end

-- เปิด/ปิดหน้าต่างพร้อมแอนิเมชันเด้ง
function UI.showPanel()
	UI.hideToken = UI.hideToken + 1
	local s = math.clamp(tonumber(state.uiScale) or 1, 0.6, 1.6)
	openBtn.Visible = false
	f.Visible = true
	mainUIScale.Scale = s * 0.86
	TweenService:Create(mainUIScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = s}):Play()
end
function UI.hidePanel()
	UI.hideToken = UI.hideToken + 1
	local token = UI.hideToken
	local s = math.clamp(tonumber(state.uiScale) or 1, 0.6, 1.6)
	TweenService:Create(mainUIScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = s * 0.86}):Play()
	task.delay(0.14, function()
		if token ~= UI.hideToken then return end
		f.Visible = false
		mainUIScale.Scale = s
		openBtn.Visible = true
	end)
end
function UI.togglePanel()
	if f.Visible then UI.hidePanel() else UI.showPanel() end
end

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
				UI.showPanel()
			end
			dragging = false
			hasMoved = false
		end
	end)
end

-- ================== HEADER ==================
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 54)
bar.BackgroundTransparency = 1
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f

local title, subTitle
do
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 32, 0, 32)
	badge.Position = UDim2.new(0, 12, 0.5, -16)
	badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	badge.BorderSizePixel = 0
	badge.Parent = bar
	UI.corner(badge, 10)
	local bg = Instance.new("UIGradient")
	bg.Rotation = 45
	bg.Parent = badge
	UI.bind(bg, "Color", "grad")
	local bt = Instance.new("TextLabel")
	bt.Size = UDim2.new(1, 0, 1, 0)
	bt.BackgroundTransparency = 1
	bt.Text = "P"
	bt.TextColor3 = Color3.fromRGB(255, 255, 255)
	bt.TextStrokeTransparency = 0.6
	bt.Font = Enum.Font.GothamBlack
	bt.TextSize = 17
	bt.Parent = badge

	title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -160, 0, 18)
	title.Position = UDim2.new(0, 52, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "PHUMIPAD PRO"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bar
	-- ตัวอักษรไล่สีเงาวิ่ง (shimmer)
	local tg = Instance.new("UIGradient")
	tg.Parent = title
	local function paintTitle()
		local a = UI.accent()
		tg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, a),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		})
	end
	paintTitle()
	table.insert(UI.onApply, paintTitle)
	task.spawn(function()
		while scriptAlive and title.Parent do
			if f.Visible then
				tg.Offset = Vector2.new(-1, 0)
				TweenService:Create(tg, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Offset = Vector2.new(1, 0)}):Play()
			end
			task.wait(3.2)
		end
	end)

	subTitle = Instance.new("TextLabel")
	subTitle.Size = UDim2.new(1, -160, 0, 12)
	subTitle.Position = UDim2.new(0, 52, 0, 29)
	subTitle.BackgroundTransparency = 1
	subTitle.Text = "v2.9 Neo Glass • " .. tostring(state.menuKey)
	subTitle.Font = Enum.Font.GothamMedium
	subTitle.TextSize = 10
	subTitle.TextXAlignment = Enum.TextXAlignment.Left
	subTitle.Parent = bar
	UI.bind(subTitle, "TextColor3", "sub")

	-- เส้นเรืองแสงวิ่งใต้ Header
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -24, 0, 1)
	line.Position = UDim2.new(0, 12, 1, -1)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.Parent = bar
	local lg = Instance.new("UIGradient")
	lg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})
	lg.Parent = line
	UI.bind(lg, "Color", "grad")
	TweenService:Create(lg, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Offset = Vector2.new(0.35, 0)}):Play()
	lg.Offset = Vector2.new(-0.35, 0)
end

local function makeHeaderButton(name, text, xOffset, isDanger)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.new(0, 28, 0, 28)
	b.Position = UDim2.new(1, xOffset, 0.5, -14)
	b.BorderSizePixel = 0
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = false
	b.Parent = bar
	UI.corner(b, "full")
	if isDanger then
		b.BackgroundColor3 = Color3.fromRGB(235, 65, 85)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		UI.bind(b, "BackgroundColor3", "surface2")
		UI.bind(b, "TextColor3", "text")
		UI.stroke(b, "stroke", 1, 0.2)
	end
	local sc = Instance.new("UIScale")
	sc.Parent = b
	b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 1.12}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 1}):Play() end)
	b.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.08), {Scale = 0.85}):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play() end)
	return b
end

local dockHideBtn = makeHeaderButton("DockHideButton", "⚡", -104, false)
local miniBtn = makeHeaderButton("CollapseButton", "–", -70, false)
local closeBtn = makeHeaderButton("CloseButton", "✕", -36, true)

-- ================== SEGMENTED TAB BAR ==================
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TopTabBar"
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 60)
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.ClipsDescendants = true
tabBar.Parent = f
UI.bind(tabBar, "BackgroundColor3", "surface")
UI.bind(tabBar, "BackgroundTransparency", "T:glass")
UI.corner(tabBar, 12)
UI.stroke(tabBar, "stroke", 1, 0.35)

do
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
end

-- ================== CONTENT SCROLL ==================
local CONTENT_TOP = 102
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, 0, 1, -CONTENT_TOP)
scroll.Position = UDim2.new(0, 0, 0, CONTENT_TOP)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = f
UI.bind(scroll, "ScrollBarImageColor3", "accent")

local scrollPadding = Instance.new("UIPadding")
do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll
	scrollPadding.PaddingTop = UDim.new(0, 2)
	scrollPadding.PaddingBottom = UDim.new(0, 18)
	scrollPadding.PaddingLeft = UDim.new(0, 10)
	scrollPadding.PaddingRight = UDim.new(0, 10)
	scrollPadding.Parent = scroll
end

-- ================== HERO STATUS CARD ==================
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 74)
statusCard.BorderSizePixel = 0
statusCard.LayoutOrder = 0
statusCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
statusCard.Parent = scroll
UI.bind(statusCard, "BackgroundTransparency", "T:glass")
UI.corner(statusCard, 14)
UI.stroke(statusCard, "stroke", 1, 0.3)

local gameNameLabel, copyHeaderBtn, timeLabel, kickWarningLabel
do
	local cg = Instance.new("UIGradient")
	cg.Rotation = 20
	cg.Parent = statusCard
	local function paintCard()
		cg.Color = ColorSequence.new(UI.color("accentSoft"), UI.color("surface"))
	end
	paintCard()
	table.insert(UI.onApply, paintCard)

	gameNameLabel = Instance.new("TextLabel")
	gameNameLabel.Size = UDim2.new(1, -78, 0, 18)
	gameNameLabel.Position = UDim2.new(0, 12, 0, 9)
	gameNameLabel.BackgroundTransparency = 1
	gameNameLabel.Text = "Loading Game Info..."
	gameNameLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	gameNameLabel.Font = Enum.Font.GothamBold
	gameNameLabel.TextSize = 12
	gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	gameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	gameNameLabel.Parent = statusCard

	copyHeaderBtn = Instance.new("TextButton")
	copyHeaderBtn.Name = "CopyHeaderButton"
	copyHeaderBtn.Size = UDim2.new(0, 56, 0, 22)
	copyHeaderBtn.Position = UDim2.new(1, -66, 0, 8)
	copyHeaderBtn.BorderSizePixel = 0
	copyHeaderBtn.Font = Enum.Font.GothamBold
	copyHeaderBtn.TextSize = 10
	copyHeaderBtn.Text = "⧉ COPY"
	copyHeaderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyHeaderBtn.AutoButtonColor = false
	copyHeaderBtn.Parent = statusCard
	UI.corner(copyHeaderBtn, "full")
	UI.bind(copyHeaderBtn, "BackgroundColor3", "accent")

	local function chip(xScale, xOff, w, wOff)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(w, wOff, 0, 24)
		c.Position = UDim2.new(xScale, xOff, 0, 40)
		c.BorderSizePixel = 0
		c.Parent = statusCard
		UI.bind(c, "BackgroundColor3", "bg")
		UI.bind(c, "BackgroundTransparency", "T:soft")
		UI.corner(c, "full")
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -12, 1, 0)
		l.Position = UDim2.new(0, 6, 0, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextSize = 10
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Parent = c
		return l
	end
	timeLabel = chip(0, 10, 0.6, -16)
	timeLabel.Text = "Play: 00:00 | Idle: 00:00"
	timeLabel.TextColor3 = Color3.fromRGB(210, 220, 240)
	kickWarningLabel = chip(0.6, 0, 0.4, -10)
	kickWarningLabel.Text = "DC in 20:00"
	kickWarningLabel.TextColor3 = Color3.fromRGB(0, 220, 130)
end

do
	local copyBusy = false
	copyHeaderBtn.MouseButton1Click:Connect(function()
		if copyBusy then return end
		copyBusy = true
		local success, gName = copyGameName()
		if success then
			copyHeaderBtn.Text = "✓ DONE"
			sendNotification("Copied Game Name", gName, Color3.fromRGB(0, 200, 125))
		else
			copyHeaderBtn.Text = "FAIL"
		end
		task.wait(1.5)
		copyHeaderBtn.Text = "⧉ COPY"
		copyBusy = false
	end)
end

-- ================== STATUS LOOP (เวลาเล่น / AFK) ==================
do
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

local afkWarned5, afkWarned1 = false, false
task.spawn(function()
	while scriptAlive do
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
		-- v2.7: แจ้งเตือนก่อนโดนเตะ AFK (เฉพาะตอนปิด Built-in Anti-AFK)
		if state.afkWarnNotify and not state.builtInAntiAfk then
			if kickTime <= 300 and not afkWarned5 then
				afkWarned5 = true
				sendNotification("⚠ AFK Warning", "จะโดนเตะใน 5 นาที - ขยับตัวหรือเปิด Anti-AFK", Color3.fromRGB(255, 160, 0))
			end
			if kickTime <= 60 and not afkWarned1 then
				afkWarned1 = true
				sendNotification("⚠ AFK Warning", "จะโดนเตะใน 1 นาที!", Color3.fromRGB(255, 60, 60))
			end
		end
		if kickTime > 300 then afkWarned5, afkWarned1 = false, false end
		if kickTime <= 300 then
			kickWarningLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		elseif kickTime <= 600 then
			kickWarningLabel.TextColor3 = Color3.fromRGB(255, 160, 0)
		else
			kickWarningLabel.TextColor3 = Color3.fromRGB(0, 200, 125)
		end
	end
end)
end

-- ================== RESIZE GRIP ==================
local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 20, 0, 20)
resizeGrip.Position = UDim2.new(1, -20, 1, -20)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "◢"
resizeGrip.Font = Enum.Font.GothamBold
resizeGrip.TextSize = 12
resizeGrip.AutoButtonColor = false
resizeGrip.ZIndex = 60
resizeGrip.Parent = f
UI.bind(resizeGrip, "TextColor3", "accent")

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
			startSize = Vector2.new(f.Size.X.Offset, f.Size.Y.Offset)
			resizeGrip.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				resizing = false
				resizeGrip.TextColor3 = UI.accent()
			end
		end
	end))
	table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = (input.Position - resizeStart) / math.max(mainUIScale.Scale, 0.1)
			local targetW = math.clamp(startSize.X + delta.X, 260, 620)
			local targetH = math.clamp(startSize.Y + delta.Y, 200, 800)
			state.savedExpandedHeight = targetH
			f.Size = UDim2.new(0, targetW, 0, targetH)
		end
	end))
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
	server = Color3.fromRGB(60, 140, 255),
	settings = Color3.fromRGB(190, 200, 220),
	logs   = Color3.fromRGB(0, 240, 200)
}

function UI.tabAccent(id)
	if state.themePerTab and tabColors[id] then return tabColors[id] end
	return UI.accent()
end

local function adjustPanelHeight(animate)
	if state.isFolded then return end
	task.defer(function()
		local activeData = tabItems[activeTabId]
		local pageHeight = activeData and activeData.contentLayout.AbsoluteContentSize.Y or 0
		local totalHeight = CONTENT_TOP + scrollPadding.PaddingTop.Offset + statusCard.Size.Y.Offset + 8
			+ pageHeight + scrollPadding.PaddingBottom.Offset + 4
		local cam = Workspace.CurrentCamera
		local maxAllowedHeight = (cam and (cam.ViewportSize.Y * 0.85) or 600) / math.max(mainUIScale.Scale, 0.1)
		local finalHeight = math.clamp(totalHeight, 200, maxAllowedHeight)
		state.savedExpandedHeight = finalHeight
		if animate then
			TweenService:Create(f, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
			}):Play()
		else
			f.Size = UDim2.new(0, f.Size.X.Offset, 0, finalHeight)
		end
	end)
end

local function paintTabs(instant)
	for tabId, data in pairs(tabItems) do
		local isCurrent = (tabId == activeTabId)
		local accent = UI.tabAccent(tabId)
		local ti = TweenInfo.new(instant and 0 or 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		if isCurrent then
			TweenService:Create(data.button, ti, {
				BackgroundColor3 = accent:Lerp(UI.color("surface"), 0.68),
				BackgroundTransparency = 0,
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			TweenService:Create(data.underline, ti, {Size = UDim2.new(1, -14, 0, 2), BackgroundColor3 = accent}):Play()
			TweenService:Create(data.tstroke, ti, {Transparency = 0.2, Color = accent}):Play()
		else
			TweenService:Create(data.button, ti, {
				BackgroundTransparency = 1,
				TextColor3 = UI.color("sub")
			}):Play()
			TweenService:Create(data.underline, ti, {Size = UDim2.new(0, 0, 0, 2)}):Play()
			TweenService:Create(data.tstroke, ti, {Transparency = 1}):Play()
		end
	end
	if state.themePerTab and activeTabId then
		UI.borderGrad.Color = ColorSequence.new(UI.tabAccent(activeTabId), UI.accent2())
	end
end
table.insert(UI.onApply, function() paintTabs(true) end)

local function switchTab(id)
	local changed = activeTabId ~= id
	activeTabId = id
	for tabId, data in pairs(tabItems) do
		local isCurrent = (tabId == id)
		data.page.Visible = isCurrent
		if isCurrent and changed then
			-- แอนิเมชันเลื่อนเข้า
			data.pagePad.PaddingTop = UDim.new(0, 16)
			TweenService:Create(data.pagePad, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{PaddingTop = UDim.new(0, 0)}):Play()
		end
	end
	paintTabs(false)
	-- เลื่อนแถบแท็บให้เห็นแท็บที่เลือก
	local data = tabItems[id]
	if data then
		task.defer(function()
			local btn = data.button
			local rel = btn.AbsolutePosition.X - tabBar.AbsolutePosition.X + tabBar.CanvasPosition.X
			local target = math.max(0, rel - tabBar.AbsoluteSize.X / 2 + btn.AbsoluteSize.X / 2)
			TweenService:Create(tabBar, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {CanvasPosition = Vector2.new(target, 0)}):Play()
		end)
	end
	adjustPanelHeight(true)
end

local function registerTab(id, name, emoji, isDefault)
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = id .. "TabButton"
	tabBtn.Size = UDim2.new(0, 0, 1, -8)
	tabBtn.AutomaticSize = Enum.AutomaticSize.X
	tabBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
	tabBtn.BackgroundTransparency = 1
	tabBtn.BorderSizePixel = 0
	tabBtn.Text = (emoji and (emoji .. " ") or "") .. name:upper()
	tabBtn.TextColor3 = Color3.fromRGB(150, 162, 188)
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = 10.5
	tabBtn.AutoButtonColor = false
	tabBtn.LayoutOrder = getOrder()
	tabBtn.Parent = tabBar
	UI.corner(tabBtn, 9)

	local tStroke = Instance.new("UIStroke")
	tStroke.Thickness = 1
	tStroke.Transparency = 1
	tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tStroke.Parent = tabBtn

	local tPadding = Instance.new("UIPadding")
	tPadding.PaddingLeft = UDim.new(0, 10)
	tPadding.PaddingRight = UDim.new(0, 10)
	tPadding.Parent = tabBtn

	local underline = Instance.new("Frame")
	underline.AnchorPoint = Vector2.new(0.5, 1)
	underline.Position = UDim2.new(0.5, 0, 1, 0)
	underline.Size = UDim2.new(0, 0, 0, 2)
	underline.BorderSizePixel = 0
	underline.Parent = tabBtn
	UI.corner(underline, "full")

	local tabScale = Instance.new("UIScale")
	tabScale.Parent = tabBtn

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
	pageLayout.Padding = UDim.new(0, 7)
	pageLayout.Parent = page

	local pagePad = Instance.new("UIPadding")
	pagePad.Parent = page

	pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if activeTabId == id then
			adjustPanelHeight(false)
		end
	end)

	tabItems[id] = {
		button = tabBtn,
		stroke = tStroke,
		tstroke = tStroke,
		underline = underline,
		page = page,
		pagePad = pagePad,
		contentLayout = pageLayout
	}

	tabBtn.MouseButton1Click:Connect(function()
		tabScale.Scale = 0.9
		TweenService:Create(tabScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		switchTab(id)
	end)

	if isDefault then
		activeTabId = id
	end
	return page
end

-- ================== NEO COMPONENT BUILDERS ==================
-- การ์ดพื้นฐาน (พื้นกระจก + ขอบ + hover)
function UI.card(parent, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height)
	row.BorderSizePixel = 0
	row.ClipsDescendants = true
	row.LayoutOrder = getOrder()
	row.Parent = parent
	UI.bind(row, "BackgroundColor3", "surface")
	UI.bind(row, "BackgroundTransparency", "T:glass")
	UI.corner(row, 12)
	local rStroke = Instance.new("UIStroke")
	rStroke.Thickness = 1
	rStroke.Transparency = 0.35
	rStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rStroke.Parent = row
	rStroke.Color = UI.color("stroke")
	return row, rStroke
end

-- ปุ่มสวิตช์แบบเม็ดยา (ใช้ร่วมกันทั้ง toggle row และ input row)
function UI.makeSwitch(row, rStroke, xOffset)
	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 46, 0, 24)
	pill.Position = UDim2.new(1, xOffset, 0.5, -12)
	pill.BorderSizePixel = 0
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.ZIndex = 3
	pill.Parent = row
	UI.corner(pill, "full")
	local pg = Instance.new("UIGradient")
	pg.Parent = pill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 4
	knob.Parent = pill
	UI.corner(knob, "full")
	local ks = Instance.new("UIStroke")
	ks.Color = Color3.fromRGB(0, 0, 0)
	ks.Transparency = 0.75
	ks.Thickness = 1
	ks.Parent = knob

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 0.5, 0)
	bar.Position = UDim2.new(0, 0, 0.25, 0)
	bar.BorderSizePixel = 0
	bar.Parent = row
	UI.corner(bar, "full")

	local cur = false
	local function render(v, instant)
		cur = v and true or false
		local ti = TweenInfo.new(instant and 0 or 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tiK = TweenInfo.new(instant and 0 or 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		pg.Enabled = cur
		pg.Color = ColorSequence.new(UI.accent(), UI.accent2())
		TweenService:Create(pill, ti, {BackgroundColor3 = cur and Color3.fromRGB(255, 255, 255) or UI.color("surface2")}):Play()
		TweenService:Create(knob, tiK, {Position = cur and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
		TweenService:Create(rStroke, ti, {Color = cur and UI.accent() or UI.color("stroke"), Transparency = cur and 0.15 or 0.35}):Play()
		bar.BackgroundColor3 = UI.accent()
		TweenService:Create(bar, ti, {Size = cur and UDim2.new(0, 3, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)}):Play()
	end
	table.insert(UI.onApply, function() render(cur, true) end)
	return pill, render
end

function UI.hookRowFx(row, clickBtn, onClick)
	clickBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			UI.ripple(row, input)
		end
	end)
	clickBtn.MouseEnter:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = UI.color("surface2")}):Play()
	end)
	clickBtn.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = UI.color("surface")}):Play()
	end)
	clickBtn.MouseButton1Click:Connect(onClick)
end

local function addRefinedToolButton(parent, name, iconSymbol, accentColor, onClick)
	local row, rStroke = UI.card(parent, 42)
	table.insert(UI.onApply, function() rStroke.Color = UI.color("stroke") end)

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 28, 0, 28)
	badge.Position = UDim2.new(0, 8, 0.5, -14)
	badge.BackgroundColor3 = accentColor
	badge.BackgroundTransparency = 0.78
	badge.BorderSizePixel = 0
	badge.Parent = row
	UI.corner(badge, 9)
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accentColor
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 0.4
	badgeStroke.Parent = badge

	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = iconSymbol or "•"
	badgeText.TextColor3 = accentColor
	badgeText.Font = Enum.Font.GothamBold
	badgeText.TextSize = 13
	badgeText.Parent = badge

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -74, 1, 0)
	lbl.Position = UDim2.new(0, 44, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row
	UI.bind(lbl, "TextColor3", "text")

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -26, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "›"
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 18
	arrow.Parent = row
	UI.bind(arrow, "TextColor3", "sub")

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 5
	btn.Parent = row

	btn.MouseEnter:Connect(function()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = accentColor, Transparency = 0.1}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = accentColor, Position = UDim2.new(1, -20, 0, 0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(rStroke, TweenInfo.new(0.18), {Color = UI.color("stroke"), Transparency = 0.35}):Play()
		TweenService:Create(arrow, TweenInfo.new(0.18), {TextColor3 = UI.color("sub"), Position = UDim2.new(1, -26, 0, 0)}):Play()
	end)
	UI.hookRowFx(row, btn, function()
		local bs = badge:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", badge)
		bs.Scale = 0.75
		TweenService:Create(bs, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		sendNotification("Tool Launched", name, accentColor)
		local ok, err = pcall(onClick)
		if not ok then warn("[Phumipad Tool Error]: " .. tostring(err)) end
	end)

	return row
end

-- แถวสวิตช์เปิด/ปิด (แตะได้ทั้งแถว)
local function addToggleRow(parent, name, defaultOn, onClick)
	local row, rStroke = UI.card(parent, 40)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -74, 1, 0)
	lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row
	UI.bind(lbl, "TextColor3", "text")

	local pill, render = UI.makeSwitch(row, rStroke, -56)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 2
	clickBtn.Parent = row

	render(defaultOn, true)
	UI.hookRowFx(row, clickBtn, function() onClick(pill, render) end)
	pill.MouseButton1Click:Connect(function() onClick(pill, render) end)
	return render
end

-- แถวกรอกค่า + สวิตช์
local function addInputToggleRow(parent, name, defaultVal, defaultOn, onToggle, onValChange)
	local row, rStroke = UI.card(parent, 42)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -140, 1, 0)
	lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row
	UI.bind(lbl, "TextColor3", "text")

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 60, 0, 24)
	box.Position = UDim2.new(1, -124, 0.5, -12)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultVal)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11.5
	box.ClearTextOnFocus = false
	box.ZIndex = 3
	box.Parent = row
	UI.bind(box, "BackgroundColor3", "bg")
	UI.bind(box, "BackgroundTransparency", "T:soft")
	UI.bind(box, "TextColor3", "accent")
	UI.corner(box, "full")
	local bStroke = UI.stroke(box, "stroke", 1, 0.3)
	box.Focused:Connect(function()
		TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = UI.accent(), Transparency = 0}):Play()
	end)

	local pill, render = UI.makeSwitch(row, rStroke, -56)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, -130, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 2
	clickBtn.Parent = row

	render(defaultOn, true)

	box.FocusLost:Connect(function()
		TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = UI.color("stroke"), Transparency = 0.3}):Play()
		local n = tonumber(box.Text)
		if n and n >= 0 then
			onValChange(n)
		else
			box.Text = tostring(defaultVal)
		end
	end)

	UI.hookRowFx(row, clickBtn, function() onToggle(pill, render) end)
	pill.MouseButton1Click:Connect(function() onToggle(pill, render) end)

	return {
		box = box,
		btn = pill,
		render = render,
		row = row,
		setVal = function(v)
			box.Text = tostring(v)
			onValChange(v)
		end
	}
end

-- ปุ่มค่าลัด (chips) เด้งได้ - จำนวนปุ่มเท่าไหร่ก็แบ่งความกว้างอัตโนมัติ
local function addPresetChips(parent, values, onSelect)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local pLayout = Instance.new("UIListLayout")
	pLayout.FillDirection = Enum.FillDirection.Horizontal
	pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pLayout.Padding = UDim.new(0, 5)
	pLayout.Parent = row

	local n = math.max(#values, 1)
	for i, val in ipairs(values) do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.new(1 / n, -5, 1, 0)
		chip.BorderSizePixel = 0
		chip.Text = tostring(val)
		chip.Font = Enum.Font.GothamBold
		chip.TextSize = (type(val) == "string") and 9.5 or 10.5
		chip.TextTruncate = Enum.TextTruncate.AtEnd
		chip.AutoButtonColor = false
		chip.LayoutOrder = i
		chip.Parent = row
		UI.bind(chip, "BackgroundColor3", "surface")
		UI.bind(chip, "BackgroundTransparency", "T:glass")
		UI.bind(chip, "TextColor3", "sub")
		UI.corner(chip, "full")
		local cStroke = UI.stroke(chip, "stroke", 1, 0.4)
		local cScale = Instance.new("UIScale")
		cScale.Parent = chip

		chip.MouseEnter:Connect(function()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = UI.accent(), Transparency = 0}):Play()
		end)
		chip.MouseLeave:Connect(function()
			TweenService:Create(cStroke, TweenInfo.new(0.15), {Color = UI.color("stroke"), Transparency = 0.4}):Play()
		end)
		chip.MouseButton1Click:Connect(function()
			cScale.Scale = 0.82
			TweenService:Create(cScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			chip.BackgroundColor3 = UI.accent()
			chip.TextColor3 = Color3.fromRGB(255, 255, 255)
			TweenService:Create(chip, TweenInfo.new(0.45), {BackgroundColor3 = UI.color("surface"), TextColor3 = UI.color("sub")}):Play()
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

local gravControl = addInputToggleRow(movePage, "Gravity Control", state.gravityValue, state.gravityEnabled, function(_, render)
	state.gravityEnabled = not state.gravityEnabled
	render(state.gravityEnabled)
	applyGravity(state.gravityEnabled)
end, function(val)
	state.gravityValue = val
	if state.gravityEnabled then applyGravity(true) end
end)
addPresetChips(movePage, {30, 60, 100, 150, 196}, function(val) gravControl.setVal(val) end)

-- v2.7 NEW: Built-in Fly (PC: WASD + E/Space ขึ้น, Q/Ctrl ลง | มือถือ: จอย + ปุ่มกระโดดขึ้น, ก้มกล้องเพื่อลง)
do -- FLY CONTROL (v2.7 FIX: แยก scope ลดจำนวน local ไม่ให้เกินลิมิต 200 ของ Luau)
local flyControl = addInputToggleRow(movePage, "Fly (Built-in)", state.flySpeed, state.flyEnabled, function(_, render)
	state.flyEnabled = not state.flyEnabled
	render(state.flyEnabled)
	applyFly(state.flyEnabled)
end, function(val)
	state.flySpeed = val
end)
addPresetChips(movePage, {1, 2, 4, 6, 10}, function(val) flyControl.setVal(val) end)
end

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

addToggleRow(utilPage, "Click TP (Ctrl+Click / Tap TP)", state.clickTpEnabled, function(_, render)
	state.clickTpEnabled = not state.clickTpEnabled
	render(state.clickTpEnabled)
	updateTapTpButton()
	if state.clickTpEnabled then
		if UserInputService.TouchEnabled then
			sendNotification("Tap TP Enabled", "กดปุ่ม 📍 TAP TP แล้วแตะจุดที่ต้องการวาร์ป", Color3.fromRGB(0, 210, 255))
		else
			sendNotification("Click TP Enabled", "Hold Ctrl + Left Click to teleport", Color3.fromRGB(0, 210, 255))
		end
	end
end)

addToggleRow(utilPage, "Built-in Anti-AFK", state.builtInAntiAfk, function(_, render)
	state.builtInAntiAfk = not state.builtInAntiAfk
	render(state.builtInAntiAfk)
end)

-- v2.7 NEW: Auto Rejoin เมื่อหลุด/โดนเตะ
addToggleRow(utilPage, "Auto Rejoin (on Disconnect)", state.autoRejoin, function(_, render)
	state.autoRejoin = not state.autoRejoin
	render(state.autoRejoin)
end)

-- v2.7 NEW: แจ้งเตือนผู้เล่นเข้า/ออก
addToggleRow(utilPage, "Notify Player Join / Leave", state.joinLeaveNotify, function(_, render)
	state.joinLeaveNotify = not state.joinLeaveNotify
	render(state.joinLeaveNotify)
end)

-- v2.7 NEW: แจ้งเตือนก่อนโดนเตะ AFK
addToggleRow(utilPage, "AFK Kick Warning", state.afkWarnNotify, function(_, render)
	state.afkWarnNotify = not state.afkWarnNotify
	render(state.afkWarnNotify)
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

-- v2.8 NEW: Tracer เส้นจากตัวเราไปหาผู้เล่นอื่นแบบเรียลไทม์ (สีตามทีม)
addToggleRow(visualPage, "Player Tracers (เส้นชี้ผู้เล่น)", state.tracersEnabled, function(_, render)
	state.tracersEnabled = not state.tracersEnabled
	render(state.tracersEnabled)
	applyTracers(state.tracersEnabled)
end)

addToggleRow(visualPage, "Bot ESP (with HP%)", state.botEsp, function(_, render)
	state.botEsp = not state.botEsp
	render(state.botEsp)
	applyBotESP(state.botEsp)
end)

-- MOVED FROM TOOLS: FPS / Ping Monitor
addToggleRow(visualPage, "FPS / Ping Monitor", state.fpsHudEnabled, function(_, render)
	state.fpsHudEnabled = not state.fpsHudEnabled
	render(state.fpsHudEnabled)
	toggleFpsHud(state.fpsHudEnabled)
end)

-- v2.8: FPS Booster 3 ระดับ (เลือกได้ทีละระดับ - เปิดอันใหม่จะปิดอันเดิมให้อัตโนมัติ)
do
	local boostRenders = {}
	local boostNames = {"FPS Booster", "Super FPS Booster", "Extreme FPS Booster"}
	local boostColors = {Color3.fromRGB(0, 210, 255), Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 60, 80)}
	local boostDesc = {
		"ภาพเรียบ ปิดเงา/เอฟเฟกต์/อนุภาค",
		"+ ปิดน้ำ หญ้า เมฆ ไฟ และ Texture ทั้งหมด",
		"+ ลบท้องฟ้า ซ่อนชุดผู้เล่น ซ่อนวัตถุไกล 300+"
	}
	for lv = 1, 3 do
		boostRenders[lv] = addToggleRow(visualPage, boostNames[lv], state.fpsBoostLevel == lv, function()
			local newLevel = (state.fpsBoostLevel == lv) and 0 or lv
			for i = 1, 3 do boostRenders[i](i == newLevel) end
			task.spawn(function()
				applyFPSBooster(newLevel)
				if newLevel > 0 then
					sendNotification(boostNames[newLevel] .. " ON", boostDesc[newLevel], boostColors[newLevel])
				else
					sendNotification("FPS Booster OFF", "คืนค่ากราฟิกเดิมแล้ว", Color3.fromRGB(150, 165, 190))
				end
			end)
		end)
	end
end

addToggleRow(visualPage, "Full Bright", state.fullBright, function(_, render)
	state.fullBright = not state.fullBright
	render(state.fullBright)
	applyFullBright(state.fullBright)
end)

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

-- v2.7 NEW: Freecam (PC: คลิกขวาค้างหมุนกล้อง, WASD/E/Q, Shift เร่ง | มือถือ: ลากครึ่งขวาจอ + จอยซ้าย)
local freecamControl = addInputToggleRow(visualPage, "Freecam", state.freecamSpeed, state.freecamEnabled, function(_, render)
	state.freecamEnabled = not state.freecamEnabled
	render(state.freecamEnabled)
	applyFreecam(state.freecamEnabled)
end, function(val)
	state.freecamSpeed = val
end)
table.insert(globalConns, player.CharacterAdded:Connect(function()
	task.defer(function() freecamControl.render(false) end)
end))

-- v2.7 NEW: ตั้งค่า Battery Saver
addInputToggleRow(visualPage, "Saver: Stop 3D + FPS Cap", state.saverFpsCap, state.saverStop3D, function(_, render)
	state.saverStop3D = not state.saverStop3D
	render(state.saverStop3D)
end, function(val)
	state.saverFpsCap = math.clamp(math.floor(val), 0, 240)
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

do -- WAYPOINTS TAB (v2.7 FIX: แยก scope ลดจำนวน local ไม่ให้เกินลิมิต 200 ของ Luau)
-- [TAB 4] WAYPOINTS 📍 (UPGRADED WITH DYNAMIC '+' ADD BUTTON)
local waypointsPage = registerTab("points", "Point", "📍", false)

local waypointsListContainer = Instance.new("Frame")
waypointsListContainer.Name = "WaypointsListContainer"
waypointsListContainer.Size = UDim2.new(1, 0, 0, 0)
waypointsListContainer.AutomaticSize = Enum.AutomaticSize.Y
waypointsListContainer.BackgroundTransparency = 1
waypointsListContainer.LayoutOrder = 1
waypointsListContainer.Parent = waypointsPage

local wpListLayout = Instance.new("UIListLayout")
wpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
wpListLayout.Padding = UDim.new(0, 6)
wpListLayout.Parent = waypointsListContainer

wpListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	if activeTabId == "points" then
		adjustPanelHeight(true)
	end
end)

-- v2.7: ระบบวาร์ปแบบ Tween (เลื่อนนุ่ม) หรือวาร์ปทันที + เก็บทิศที่หันด้วย CFrame
local wpUpdaters = {}

local function goToWaypointCF(cf)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or typeof(cf) ~= "CFrame" then return false end
	if state.wpTween then
		local dist = (root.Position - cf.Position).Magnitude
		local dur = math.clamp(dist / math.max(tonumber(state.wpTweenSpeed) or 120, 1), 0.1, 15)
		local tw = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = cf})
		tw:Play()
	else
		root.CFrame = cf
	end
	return true
end

local function createWaypointSlot(slotIndex, isRemovable)
	state.savedNames[slotIndex] = state.savedNames[slotIndex] or ("Spot " .. slotIndex)
	state.waypointSlots[slotIndex] = true

	local row = Instance.new("Frame")
	row.Name = "WaypointSlot_" .. slotIndex
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	row.BorderSizePixel = 0
	row.LayoutOrder = slotIndex
	row.Parent = waypointsListContainer
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(36, 44, 64)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local nameBox = Instance.new("TextBox")
	nameBox.Size = isRemovable and UDim2.new(0.34, -6, 1, -6) or UDim2.new(0.38, -6, 1, -6)
	nameBox.Position = UDim2.new(0, 4, 0, 3)
	nameBox.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
	nameBox.BorderSizePixel = 0
	nameBox.Text = state.savedNames[slotIndex]
	nameBox.TextColor3 = Color3.fromRGB(230, 240, 255)
	nameBox.Font = Enum.Font.GothamMedium
	nameBox.TextSize = 10.5
	nameBox.TextTruncate = Enum.TextTruncate.AtEnd
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = row
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 5)

	nameBox.FocusLost:Connect(function()
		if nameBox.Text == "" or string.gsub(nameBox.Text, "%s+", "") == "" then
			nameBox.Text = "Spot " .. slotIndex
		end
		state.savedNames[slotIndex] = nameBox.Text
	end)

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = isRemovable and UDim2.new(0.36, -4, 1, -6) or UDim2.new(0.42, -4, 1, -6)
	actionBtn.Position = isRemovable and UDim2.new(0.34, 2, 0, 3) or UDim2.new(0.38, 2, 0, 3)
	actionBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
	actionBtn.BorderSizePixel = 0
	actionBtn.Text = "Set " .. slotIndex
	actionBtn.TextColor3 = Color3.fromRGB(225, 235, 255)
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.TextSize = 10
	actionBtn.TextTruncate = Enum.TextTruncate.AtEnd
	actionBtn.Parent = row
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 5)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = isRemovable and UDim2.new(0.18, -4, 1, -6) or UDim2.new(0.2, -4, 1, -6)
	clearBtn.Position = isRemovable and UDim2.new(0.70, 0, 0, 3) or UDim2.new(0.8, 0, 0, 3)
	clearBtn.BackgroundColor3 = Color3.fromRGB(185, 45, 55)
	clearBtn.BorderSizePixel = 0
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 10
	clearBtn.Parent = row
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

	if isRemovable then
		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0.12, -4, 1, -6)
		delBtn.Position = UDim2.new(0.88, 0, 0, 3)
		delBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 32)
		delBtn.BorderSizePixel = 0
		delBtn.Text = "✕"
		delBtn.TextColor3 = Color3.fromRGB(255, 90, 105)
		delBtn.Font = Enum.Font.GothamBold
		delBtn.TextSize = 10
		delBtn.Parent = row
		Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 5)

		delBtn.MouseButton1Click:Connect(function()
			state.savedPositions[slotIndex] = nil
			state.savedNames[slotIndex] = nil
			state.waypointSlots[slotIndex] = nil
			wpUpdaters[slotIndex] = nil
			row:Destroy()
			adjustPanelHeight(true)
		end)
	end

	-- v2.7: ปุ่ม Go แสดงระยะห่างจากจุดนั้นแบบเรียลไทม์
	local function updateVisual()
		local cf = state.savedPositions[slotIndex]
		if cf then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				actionBtn.Text = string.format("Go • %sm", formatStatDiff(math.floor((root.Position - cf.Position).Magnitude)))
			else
				actionBtn.Text = "Go " .. slotIndex
			end
			actionBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 125)
		else
			actionBtn.Text = "Set " .. slotIndex
			actionBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 48)
		end
	end
	wpUpdaters[slotIndex] = updateVisual
	updateVisual()

	actionBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		if state.savedPositions[slotIndex] then
			if goToWaypointCF(state.savedPositions[slotIndex]) then
				sendNotification("Teleported", "Warped to " .. (state.savedNames[slotIndex] or ("Spot " .. slotIndex)), Color3.fromRGB(255, 175, 25))
			end
		else
			state.savedPositions[slotIndex] = root.CFrame
			updateVisual()
			sendNotification("Waypoint Saved", "Saved " .. (state.savedNames[slotIndex] or ("Spot " .. slotIndex)), Color3.fromRGB(0, 210, 130))
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		state.savedPositions[slotIndex] = nil
		updateVisual()
	end)
end

-- v2.7: โหลด Waypoint จาก Config (ถ้ามี) ไม่งั้นสร้าง 4 จุดเริ่มต้น
local initialSlots = 4
if type(loadedWaypoints) == "table" and #loadedWaypoints > 0 then
	initialSlots = math.max(4, #loadedWaypoints)
	for i, entry in ipairs(loadedWaypoints) do
		if type(entry) == "table" then
			if type(entry.name) == "string" and entry.name ~= "" then
				state.savedNames[i] = entry.name
			end
			if type(entry.cf) == "table" and #entry.cf == 12 then
				local ok, cf = pcall(function() return CFrame.new((table.unpack or unpack)(entry.cf)) end)
				if ok then state.savedPositions[i] = cf end
			end
		end
	end
end
for i = 1, initialSlots do
	state.waypointCount = i
	createWaypointSlot(i, i > 4)
end

-- อัปเดตระยะห่างทุก 0.5 วินาที เฉพาะตอนเปิดแท็บ Point
task.spawn(function()
	while scriptAlive do
		task.wait(0.5)
		if activeTabId == "points" and f.Visible and not state.isFolded then
			for _, fn in pairs(wpUpdaters) do pcall(fn) end
		end
	end
end)

-- v2.7: ตัวเลือก Tween วาร์ปแบบนุ่ม (ค่า = ความเร็ว studs/วินาที)
local wpTweenControl = addInputToggleRow(waypointsPage, "Smooth Tween TP (speed)", state.wpTweenSpeed, state.wpTween, function(_, render)
	state.wpTween = not state.wpTween
	render(state.wpTween)
end, function(val)
	state.wpTweenSpeed = math.max(val, 1)
end)
wpTweenControl.row.LayoutOrder = 0

-- ปุ่ม '+' สำหรับเพิ่มจุด Waypoint ใหม่ได้ไม่จำกัด
local addWaypointBtn = Instance.new("TextButton")
addWaypointBtn.Name = "AddWaypointButton"
addWaypointBtn.Size = UDim2.new(1, 0, 0, 32)
addWaypointBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
addWaypointBtn.BorderSizePixel = 0
addWaypointBtn.Text = "+  Add New Waypoint"
addWaypointBtn.TextColor3 = Color3.fromRGB(255, 190, 45)
addWaypointBtn.Font = Enum.Font.GothamBold
addWaypointBtn.TextSize = 11
addWaypointBtn.AutoButtonColor = false
addWaypointBtn.LayoutOrder = 9999
addWaypointBtn.Parent = waypointsPage
Instance.new("UICorner", addWaypointBtn).CornerRadius = UDim.new(0, 7)

local addWpStroke = Instance.new("UIStroke")
addWpStroke.Color = Color3.fromRGB(255, 175, 25)
addWpStroke.Thickness = 1.2
addWpStroke.Transparency = 0.35
addWpStroke.Parent = addWaypointBtn

addWaypointBtn.MouseEnter:Connect(function()
	TweenService:Create(addWaypointBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(32, 40, 62)}):Play()
	TweenService:Create(addWpStroke, TweenInfo.new(0.18), {Transparency = 0}):Play()
end)

addWaypointBtn.MouseLeave:Connect(function()
	TweenService:Create(addWaypointBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(22, 28, 44)}):Play()
	TweenService:Create(addWpStroke, TweenInfo.new(0.18), {Transparency = 0.35}):Play()
end)

addWaypointBtn.MouseButton1Click:Connect(function()
	state.waypointCount = state.waypointCount + 1
	createWaypointSlot(state.waypointCount, true)
	sendNotification("Waypoint Added", "Created Spot " .. tostring(state.waypointCount), Color3.fromRGB(255, 175, 25))
	adjustPanelHeight(true)
end)
end

-- =========================================================================
-- ============ TOOL SUB-PANELS (ORIGINAL + NEW SPECTATE) ==================
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
	intensBox.Text = "350" -- v2.7 FIX: ให้ตรงกับค่าจริงของตัวแปร intens
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

	local intens = tonumber(intensBox.Text) or 350
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
	-- v2.7 FIX: เก็บ connection แล้วตัดทิ้งเมื่อปิดหน้าต่าง (เดิมค้างสะสมทุกครั้งที่เปิด)
	local tpAddConn = Players.PlayerAdded:Connect(refreshTeleportList)
	local tpRemConn = Players.PlayerRemoving:Connect(function(leaving)
		if targetPlr == leaving then targetPlr = nil end
		task.defer(refreshTeleportList)
	end)
	tpGui.Destroying:Connect(function()
		pcall(function() tpAddConn:Disconnect() end)
		pcall(function() tpRemConn:Disconnect() end)
	end)

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

-- 5. NEW: SPECTATE PLAYER PANEL (WITH SEARCH BAR & SCROLLING LIST)
local function resetCameraToSelf()
	if state._spectateConn then
		state._spectateConn:Disconnect()
		state._spectateConn = nil
	end
	local cam = Workspace.CurrentCamera
	local myChar = player.Character
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if cam and myHum then
		cam.CameraSubject = myHum
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function launchSpectateScript()
	local existing = (targetContainer and targetContainer:FindFirstChild("SpectateUI")) or playerGui:FindFirstChild("SpectateUI")
	if existing then
		existing.Enabled = not existing.Enabled
		return
	end

	local specGui = Instance.new("ScreenGui")
	specGui.Name = "SpectateUI"
	specGui.ResetOnSpawn = false
	safeParentGui(specGui)

	local spFrame = Instance.new("Frame")
	spFrame.Name = "Main"
	spFrame.Size = UDim2.new(0, 290, 0, 365)
	spFrame.Position = UDim2.new(0.5, -145, 0.3, 0)
	spFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
	spFrame.BorderSizePixel = 0
	spFrame.ClipsDescendants = true
	spFrame.Parent = specGui
	Instance.new("UICorner", spFrame).CornerRadius = UDim.new(0, 14)

	local spStroke = Instance.new("UIStroke")
	spStroke.Color = Color3.fromRGB(0, 210, 255)
	spStroke.Thickness = 1.4
	spStroke.Transparency = 0.25
	spStroke.Parent = spFrame

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
	topBar.BorderSizePixel = 0
	topBar.Parent = spFrame
	Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)
	makeDraggable(topBar, spFrame)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -90, 1, 0)
	titleLbl.Position = UDim2.new(0, 14, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "🎥 Spectate Player"
	titleLbl.TextColor3 = Color3.fromRGB(245, 250, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = topBar

	local subMiniBtn = Instance.new("TextButton")
	subMiniBtn.Size = UDim2.new(0, 26, 0, 24)
	subMiniBtn.Position = UDim2.new(1, -66, 0.5, -12)
	subMiniBtn.BackgroundColor3 = Color3.fromRGB(34, 42, 60)
	subMiniBtn.BorderSizePixel = 0
	subMiniBtn.Text = "-"
	subMiniBtn.TextColor3 = Color3.fromRGB(220, 230, 250)
	subMiniBtn.Font = Enum.Font.GothamBold
	subMiniBtn.TextSize = 15
	subMiniBtn.Parent = topBar
	Instance.new("UICorner", subMiniBtn).CornerRadius = UDim.new(0, 6)

	local subCloseBtn = Instance.new("TextButton")
	subCloseBtn.Size = UDim2.new(0, 26, 0, 24)
	subCloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
	subCloseBtn.BackgroundColor3 = Color3.fromRGB(225, 55, 70)
	subCloseBtn.BorderSizePixel = 0
	subCloseBtn.Text = "X"
	subCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	subCloseBtn.Font = Enum.Font.GothamBold
	subCloseBtn.TextSize = 11
	subCloseBtn.Parent = topBar
	Instance.new("UICorner", subCloseBtn).CornerRadius = UDim.new(0, 6)

	local contentBox = Instance.new("Frame")
	contentBox.Size = UDim2.new(1, 0, 1, -42)
	contentBox.Position = UDim2.new(0, 0, 0, 42)
	contentBox.BackgroundTransparency = 1
	contentBox.Parent = spFrame

	-- Status Banner
	local statusBanner = Instance.new("Frame")
	statusBanner.Size = UDim2.new(1, -24, 0, 30)
	statusBanner.Position = UDim2.new(0, 12, 0, 8)
	statusBanner.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
	statusBanner.BorderSizePixel = 0
	statusBanner.Parent = contentBox
	Instance.new("UICorner", statusBanner).CornerRadius = UDim.new(0, 7)

	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(1, -12, 1, 0)
	statusText.Position = UDim2.new(0, 6, 0, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Viewing: Yourself (Default)"
	statusText.TextColor3 = Color3.fromRGB(0, 225, 255)
	statusText.Font = Enum.Font.GothamBold
	statusText.TextSize = 11.5
	statusText.TextTruncate = Enum.TextTruncate.AtEnd
	statusText.Parent = statusBanner

	-- Search Bar Input
	local searchContainer = Instance.new("Frame")
	searchContainer.Size = UDim2.new(1, -24, 0, 32)
	searchContainer.Position = UDim2.new(0, 12, 0, 44)
	searchContainer.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
	searchContainer.BorderSizePixel = 0
	searchContainer.Parent = contentBox
	Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 7)

	local searchStroke = Instance.new("UIStroke")
	searchStroke.Color = Color3.fromRGB(42, 54, 80)
	searchStroke.Thickness = 1
	searchStroke.Parent = searchContainer

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -20, 1, 0)
	searchBox.Position = UDim2.new(0, 10, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "🔍 Search player name or @username..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
	searchBox.Text = ""
	searchBox.TextColor3 = Color3.fromRGB(240, 248, 255)
	searchBox.Font = Enum.Font.GothamMedium
	searchBox.TextSize = 11
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchContainer

	-- Scrolling Player List
	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, -24, 0, 182)
	listScroll.Position = UDim2.new(0, 12, 0, 82)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 3
	listScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 210, 255)
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.Parent = contentBox

	local spListLayout = Instance.new("UIListLayout")
	spListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	spListLayout.Padding = UDim.new(0, 6)
	spListLayout.Parent = listScroll

	local selectedTargetPlr = nil
	local isSpectating = false
	local playerButtons = {}

	local function startSpectatingTarget(targetPlr)
		if not targetPlr then return end
		selectedTargetPlr = targetPlr
		isSpectating = true

		if state._spectateConn then
			state._spectateConn:Disconnect()
			state._spectateConn = nil
		end

		statusText.Text = "👁️ Spectating: " .. (targetPlr.DisplayName or targetPlr.Name)
		statusText.TextColor3 = Color3.fromRGB(0, 245, 150)

		state._spectateConn = RunService.RenderStepped:Connect(function()
			if not isSpectating or not selectedTargetPlr or not selectedTargetPlr.Parent then
				isSpectating = false
				resetCameraToSelf()
				statusText.Text = "Viewing: Yourself (Target Left)"
				statusText.TextColor3 = Color3.fromRGB(255, 180, 50)
				return
			end
			local tChar = selectedTargetPlr.Character
			local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
			local cam = Workspace.CurrentCamera
			if cam and tHum then
				cam.CameraSubject = tHum
			end
		end)
	end

	local function populateSpectateList()
		for _, item in ipairs(playerButtons) do
			if item.btn and item.btn.Parent then item.btn:Destroy() end
		end
		playerButtons = {}

		local query = string.lower(searchBox.Text or "")

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local disp = p.DisplayName or p.Name
				local uname = p.Name
				local combined = string.lower(disp .. " " .. uname)

				if query == "" or string.find(combined, query, 1, true) then
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, -4, 0, 34)
					btn.BackgroundColor3 = (selectedTargetPlr == p) and Color3.fromRGB(0, 115, 185) or Color3.fromRGB(24, 30, 46)
					btn.BorderSizePixel = 0
					btn.Text = string.format("  %s (@%s)", disp, uname)
					btn.TextColor3 = Color3.fromRGB(240, 245, 255)
					btn.Font = Enum.Font.GothamMedium
					btn.TextSize = 11.5
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.TextTruncate = Enum.TextTruncate.AtEnd
					btn.Parent = listScroll
					Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

					table.insert(playerButtons, {plr = p, btn = btn})

					btn.MouseButton1Click:Connect(function()
						selectedTargetPlr = p
						for _, bData in ipairs(playerButtons) do
							if bData.btn and bData.btn.Parent then
								bData.btn.BackgroundColor3 = (bData.plr == p) and Color3.fromRGB(0, 115, 185) or Color3.fromRGB(24, 30, 46)
							end
						end
						startSpectatingTarget(p)
					end)
				end
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(populateSpectateList)
	populateSpectateList()

	local pAddConn = Players.PlayerAdded:Connect(populateSpectateList)
	local pRemConn = Players.PlayerRemoving:Connect(function(leavingPlr)
		if selectedTargetPlr == leavingPlr then
			selectedTargetPlr = nil
			isSpectating = false
			resetCameraToSelf()
			statusText.Text = "Viewing: Yourself (Default)"
			statusText.TextColor3 = Color3.fromRGB(0, 225, 255)
		end
		task.defer(populateSpectateList)
	end)
	specGui.Destroying:Connect(function()
		pcall(function() pAddConn:Disconnect() end)
		pcall(function() pRemConn:Disconnect() end)
	end)

	-- Action Buttons Row (SPECTATE / STOP VIEWING)
	local watchBtn = Instance.new("TextButton")
	watchBtn.Size = UDim2.new(0.5, -16, 0, 38)
	watchBtn.Position = UDim2.new(0, 12, 1, -48)
	watchBtn.BackgroundColor3 = Color3.fromRGB(0, 185, 125)
	watchBtn.BorderSizePixel = 0
	watchBtn.Text = "👁️ SPECTATE"
	watchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	watchBtn.Font = Enum.Font.GothamBold
	watchBtn.TextSize = 11.5
	watchBtn.Parent = contentBox
	Instance.new("UICorner", watchBtn).CornerRadius = UDim.new(0, 8)

	local stopWatchBtn = Instance.new("TextButton")
	stopWatchBtn.Size = UDim2.new(0.5, -16, 0, 38)
	stopWatchBtn.Position = UDim2.new(0.5, 4, 1, -48)
	stopWatchBtn.BackgroundColor3 = Color3.fromRGB(225, 55, 70)
	stopWatchBtn.BorderSizePixel = 0
	stopWatchBtn.Text = "🔄 STOP / ME"
	stopWatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopWatchBtn.Font = Enum.Font.GothamBold
	stopWatchBtn.TextSize = 11.5
	stopWatchBtn.Parent = contentBox
	Instance.new("UICorner", stopWatchBtn).CornerRadius = UDim.new(0, 8)

	watchBtn.MouseButton1Click:Connect(function()
		if selectedTargetPlr then
			startSpectatingTarget(selectedTargetPlr)
		else
			sendNotification("Spectate", "Please select a player from the list first", Color3.fromRGB(255, 175, 25))
		end
	end)

	stopWatchBtn.MouseButton1Click:Connect(function()
		isSpectating = false
		resetCameraToSelf()
		statusText.Text = "Viewing: Yourself (Default)"
		statusText.TextColor3 = Color3.fromRGB(0, 225, 255)
	end)

	local minimized = false
	subMiniBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		contentBox.Visible = not minimized
		spFrame.Size = minimized and UDim2.new(0, 290, 0, 42) or UDim2.new(0, 290, 0, 365)
		subMiniBtn.Text = minimized and "+" or "-"
	end)

	subCloseBtn.MouseButton1Click:Connect(function()
		isSpectating = false
		resetCameraToSelf()
		if pAddConn then pAddConn:Disconnect() end
		if pRemConn then pRemConn:Disconnect() end
		specGui:Destroy()
	end)
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

-- (v2.7: ลบ Anti AFK ภายนอกออก - ใช้ Built-in Anti-AFK ในแท็บ Util แทน)

-- 3. Auto Clicker
addRefinedToolButton(toolsPage, "Auto Clicker", "⚡", Color3.fromRGB(255, 150, 0), function()
	launchAutoClickerScript()
end)

-- 4. Fly GUI (V3) - นำกลับมาตามคำขอ (ยังมี Fly Built-in ในแท็บ Move ให้เลือกใช้ด้วย)
addRefinedToolButton(toolsPage, "Fly GUI (V3)", "🚀", Color3.fromRGB(0, 195, 255), function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
	end)
end)

-- 5. Player Teleport
addRefinedToolButton(toolsPage, "Player Teleport", "📍", Color3.fromRGB(100, 140, 255), function()
	launchPlayerTeleportScript()
end)

-- (v2.7: ย้าย Rejoin / Server Hop ไปแท็บ Server และเขียนใหม่แบบ Built-in)

-- 8. NEW: Spectate Player (With Search & Scroll List)
addRefinedToolButton(toolsPage, "Spectate Player", "🎥", Color3.fromRGB(0, 225, 255), function()
	launchSpectateScript()
end)

-- 9. Stalker
addRefinedToolButton(toolsPage, "Stalker", "🎯", Color3.fromRGB(255, 65, 80), function()
	launchStalkerScript()
end)

-- 10. Vehicle Speed Adjust
addRefinedToolButton(toolsPage, "Vehicle Speed Adjust", "🏎️", Color3.fromRGB(0, 230, 140), function()
	launchVehicleSpeedAdjustScript()
end)

do -- SERVER + SETTINGS TABS (v2.7 FIX: แยก scope ลดจำนวน local ไม่ให้เกินลิมิต 200 ของ Luau)
-- =========================================================================
-- ================== [TAB 6] SERVER 🌐 (v2.7 NEW) =========================
-- =========================================================================
local serverPage = registerTab("server", "Server", "🌐", false)

local function setClipboardSafe(text)
	if setclipboard then setclipboard(text) return true end
	if toclipboard then toclipboard(text) return true end
	if syn and syn.write_clipboard then syn.write_clipboard(text) return true end
	return false
end

local function formatDuration(sec)
	sec = math.floor(sec)
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if h > 0 then return string.format("%dh %02dm", h, m) end
	return string.format("%02d:%02d", m, s)
end

local function rejoinServer()
	if #Players:GetPlayers() <= 1 then
		TeleportService:Teleport(game.PlaceId, player)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end
end

local function fetchServers()
	local list, cursor = {}, nil
	for _ = 1, 3 do
		local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
			game.PlaceId, cursor and ("&cursor=" .. cursor) or "")
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if not ok or type(body) ~= "string" then break end
		local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then break end
		for _, sv in ipairs(data.data) do
			local playing, maxP = tonumber(sv.playing), tonumber(sv.maxPlayers)
			if sv.id ~= game.JobId and playing and maxP and playing < maxP then
				table.insert(list, sv)
			end
		end
		cursor = data.nextPageCursor
		if not cursor then break end
	end
	return list
end

local hopBusy = false
local function serverHop(mode)
	if hopBusy then return end
	hopBusy = true
	task.spawn(function()
		sendNotification("Server Hop", "กำลังค้นหาเซิร์ฟเวอร์...", Color3.fromRGB(60, 140, 255))
		local servers = fetchServers()
		if #servers == 0 then
			sendNotification("Server Hop", "ไม่พบเซิร์ฟเวอร์อื่นที่ว่าง", Color3.fromRGB(255, 80, 80))
			hopBusy = false
			return
		end
		local pick
		if mode == "smallest" then
			table.sort(servers, function(a, b) return a.playing < b.playing end)
			pick = servers[1]
		else
			pick = servers[math.random(1, #servers)]
		end
		sendNotification("Server Hop", string.format("กำลังย้ายไปเซิร์ฟ %d/%d คน", pick.playing, pick.maxPlayers), Color3.fromRGB(0, 210, 130))
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, player)
		end)
		if not ok then
			sendNotification("Server Hop", "ย้ายเซิร์ฟไม่สำเร็จ ลองอีกครั้ง", Color3.fromRGB(255, 80, 80))
		end
		task.wait(5)
		hopBusy = false
	end)
end

-- Server Info Card
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 74)
infoCard.BackgroundColor3 = Color3.fromRGB(18, 23, 35)
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = getOrder()
infoCard.Parent = serverPage
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 8)
local icStroke = Instance.new("UIStroke")
icStroke.Color = Color3.fromRGB(40, 60, 100)
icStroke.Thickness = 1
icStroke.Parent = infoCard

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -10)
infoLabel.Position = UDim2.new(0, 10, 0, 5)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Loading..."
infoLabel.TextColor3 = Color3.fromRGB(200, 215, 240)
infoLabel.Font = Enum.Font.GothamMedium
infoLabel.TextSize = 10.5
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextWrapped = true
infoLabel.Parent = infoCard

task.spawn(function()
	while scriptAlive and infoLabel.Parent do
		if activeTabId == "server" then
			local ping = 0
			pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
			local jid = game.JobId ~= "" and game.JobId or "Studio / Unknown"
			infoLabel.Text = string.format("👥 Players: %d / %d\n⏱ Server Age: %s\n📶 Ping: %d ms\n🆔 %s",
				#Players:GetPlayers(), Players.MaxPlayers, formatDuration(Workspace.DistributedGameTime), ping,
				string.sub(jid, 1, 18) .. (#jid > 18 and "..." or ""))
		end
		task.wait(1)
	end
end)

addRefinedToolButton(serverPage, "Copy Job ID", "🆔", Color3.fromRGB(60, 140, 255), function()
	if setClipboardSafe(game.JobId) then
		sendNotification("Copied", "คัดลอก Job ID แล้ว", Color3.fromRGB(0, 200, 125))
	end
end)

addRefinedToolButton(serverPage, "Copy Join Script (ชวนเพื่อนเข้าเซิร์ฟนี้)", "📋", Color3.fromRGB(0, 200, 220), function()
	local code = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)', game.PlaceId, game.JobId)
	if setClipboardSafe(code) then
		sendNotification("Copied", "คัดลอกสคริปต์เข้าเซิร์ฟนี้แล้ว", Color3.fromRGB(0, 200, 125))
	end
end)

addRefinedToolButton(serverPage, "Rejoin Server", "🔄", Color3.fromRGB(0, 210, 220), function()
	rejoinServer()
end)

addRefinedToolButton(serverPage, "Server Hop (Random)", "🌐", Color3.fromRGB(60, 130, 255), function()
	serverHop("random")
end)

addRefinedToolButton(serverPage, "Join Smallest Server", "🔻", Color3.fromRGB(150, 110, 255), function()
	serverHop("smallest")
end)

-- =========================================================================
-- ================== [TAB 7] SETTINGS 🛠 (v2.7 + Theme Studio v2.9) =====
-- =========================================================================
local settingsPage = registerTab("settings", "Set", "🛠", false)

local function addSectionLabel(parent, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 18)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 10
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = getOrder()
	l.Parent = parent
	UI.bind(l, "TextColor3", "sub")
	return l
end

local function addActionButton(parent, text, color, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 36)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11.5
	b.AutoButtonColor = false
	b.ClipsDescendants = true
	b.LayoutOrder = getOrder()
	b.Parent = parent
	UI.bind(b, "BackgroundColor3", "surface")
	UI.bind(b, "BackgroundTransparency", "T:glass")
	UI.corner(b, 12)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 1
	s.Transparency = 0.45
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = b
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			UI.ripple(b, input)
		end
	end)
	b.MouseButton1Click:Connect(function() onClick(b) end)
	return b
end

-- ================== 🎨 THEME STUDIO (v2.9) ==================
local function addSlider(parent, titleText, minV, maxV, getV, setV, fmt, rainbow, onRelease)
	local row, rStroke = UI.card(parent, 56)
	table.insert(UI.onApply, function() rStroke.Color = UI.color("stroke") end)

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, -96, 0, 18)
	tl.Position = UDim2.new(0, 14, 0, 7)
	tl.BackgroundTransparency = 1
	tl.Text = titleText
	tl.Font = Enum.Font.GothamMedium
	tl.TextSize = 11.5
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Parent = row
	UI.bind(tl, "TextColor3", "text")

	local vl = Instance.new("TextLabel")
	vl.Size = UDim2.new(0, 70, 0, 18)
	vl.Position = UDim2.new(1, -84, 0, 7)
	vl.BackgroundTransparency = 1
	vl.Font = Enum.Font.GothamBold
	vl.TextSize = 11.5
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.Parent = row
	UI.bind(vl, "TextColor3", "accent")

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -32, 0, 8)
	track.Position = UDim2.new(0, 16, 0, 36)
	track.BorderSizePixel = 0
	track.Parent = row
	UI.corner(track, "full")
	if rainbow then
		track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		local kps = {}
		for i = 0, 6 do
			table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 0.82, 1)))
		end
		local rg = Instance.new("UIGradient")
		rg.Color = ColorSequence.new(kps)
		rg.Parent = track
	else
		UI.bind(track, "BackgroundColor3", "surface2")
	end

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BackgroundTransparency = rainbow and 1 or 0
	fill.BorderSizePixel = 0
	fill.Parent = track
	UI.corner(fill, "full")
	local fg = Instance.new("UIGradient")
	fg.Parent = fill
	UI.bind(fg, "Color", "grad")

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 3
	knob.Parent = track
	UI.corner(knob, "full")
	UI.stroke(knob, "accent", 2, 0)
	local kScale = Instance.new("UIScale")
	kScale.Parent = knob

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 0, 30)
	hit.Position = UDim2.new(0, 0, 0, 25)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 5
	hit.Parent = row

	local dragging = false
	local function refresh()
		local v = getV()
		local a = math.clamp((v - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		vl.Text = fmt(v)
		if rainbow then knob.BackgroundColor3 = UI.accent() end
	end
	local function updateFromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setV(minV + a * (maxV - minV))
		refresh()
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			scroll.ScrollingEnabled = false
			TweenService:Create(kScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Scale = 1.3}):Play()
			updateFromX(input.Position.X)
		end
	end)
	table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))
	table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			scroll.ScrollingEnabled = true
			TweenService:Create(kScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
			if onRelease then pcall(onRelease) end
		end
	end))
	refresh()
	table.insert(UI.onApply, refresh)
	return refresh
end

addSectionLabel(settingsPage, "🎨  ACCENT COLOR  •  สีหลักของ UI")
do
	local swRow = Instance.new("Frame")
	swRow.Size = UDim2.new(1, 0, 0, 36)
	swRow.BackgroundTransparency = 1
	swRow.LayoutOrder = getOrder()
	swRow.Parent = settingsPage
	local swLayout = Instance.new("UIListLayout")
	swLayout.FillDirection = Enum.FillDirection.Horizontal
	swLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	swLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	swLayout.SortOrder = Enum.SortOrder.LayoutOrder
	swLayout.Padding = UDim.new(0, 7)
	swLayout.Parent = swRow

	local swatches = {}
	local function refreshSw()
		local a = state.themeAccent
		for _, sw in ipairs(swatches) do
			local c = sw.col
			local sel = type(a) == "table" and a[1] == c[1] and a[2] == c[2] and a[3] == c[3]
			sw.stroke.Transparency = sel and 0 or 1
			TweenService:Create(sw.scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = sel and 1.15 or 1}):Play()
		end
	end
	for i, col in ipairs(UI.ACCENTS) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 26, 0, 26)
		b.BackgroundColor3 = UI.rgb(col)
		b.BorderSizePixel = 0
		b.Text = ""
		b.AutoButtonColor = false
		b.LayoutOrder = i
		b:SetAttribute("PPNoTheme", true)
		b.Parent = swRow
		UI.corner(b, "full")
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(255, 255, 255)
		st.Thickness = 2
		st.Transparency = 1
		st.Parent = b
		local sc = Instance.new("UIScale")
		sc.Parent = b
		table.insert(swatches, {col = col, stroke = st, scale = sc})
		b.MouseButton1Click:Connect(function()
			state.themeAccent = {col[1], col[2], col[3]}
			UI.apply()
		end)
	end
	table.insert(UI.onApply, refreshSw)
	refreshSw()
end

addSlider(settingsPage, "🌈 Custom Hue (ลากเลือกสีเอง)", 0, 1, function()
	local h = UI.accent():ToHSV()
	return h
end, function(h)
	local c = Color3.fromHSV(math.clamp(h, 0, 0.999), 0.8, 1)
	state.themeAccent = {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
	UI.apply(true)
end, function(h) return string.format("%d°", math.floor(h * 360)) end, true, function()
	UI.buildPattern()
end)

addSlider(settingsPage, "💧 ความเข้มพื้นหลัง (Opacity)", 15, 100, function()
	return math.floor((1 - (tonumber(state.uiTransparency) or 0)) * 100 + 0.5)
end, function(v)
	state.uiTransparency = math.clamp(1 - v / 100, 0, 0.85)
	UI.apply(true)
end, function(v) return string.format("%d%%", math.floor(v + 0.5)) end, false)

local baseLabel = addSectionLabel(settingsPage, "🌓  BASE THEME  •  " .. tostring(state.themeBase))
addPresetChips(settingsPage, UI.BASE_ORDER, function(v)
	state.themeBase = v
	baseLabel.Text = "🌓  BASE THEME  •  " .. v
	UI.apply()
end)

local patternLabel = addSectionLabel(settingsPage, "🔳  BACKGROUND PATTERN  •  " .. tostring(state.uiPattern))
addPresetChips(settingsPage, UI.PATTERNS, function(v)
	state.uiPattern = v
	patternLabel.Text = "🔳  BACKGROUND PATTERN  •  " .. v
	UI.buildPattern()
end)

addSectionLabel(settingsPage, "✨  EFFECTS")
addToggleRow(settingsPage, "ขอบเรืองแสงหมุน (Animated Border)", state.themeAnimBorder, function(_, render)
	state.themeAnimBorder = not state.themeAnimBorder
	render(state.themeAnimBorder)
	if not state.themeAnimBorder then UI.borderGrad.Rotation = 0 end
end)
addToggleRow(settingsPage, "สีเปลี่ยนตามแท็บ (Per-tab Color)", state.themePerTab, function(_, render)
	state.themePerTab = not state.themePerTab
	render(state.themePerTab)
	UI.apply(true)
end)
addActionButton(settingsPage, "↺ คืนค่าธีมเริ่มต้น (Reset Theme)", Color3.fromRGB(255, 175, 60), function()
	state.themeAccent = {0, 200, 255}
	state.themeBase = "Dark"
	state.uiTransparency = 0.06
	state.uiPattern = "Dots"
	state.themePerTab = false
	baseLabel.Text = "🌓  BASE THEME  •  Dark"
	patternLabel.Text = "🔳  BACKGROUND PATTERN  •  Dots"
	UI.apply()
	sendNotification("Theme Reset", "คืนค่าธีมเริ่มต้นแล้ว", UI.accent())
end)

-- UI Scale
local scaleLabel = addSectionLabel(settingsPage, string.format("UI SCALE  •  ตอนนี้ %.2fx", mainUIScale.Scale))
addPresetChips(settingsPage, {0.8, 0.9, 1, 1.1, 1.25}, function(val)
	state.uiScale = val
	mainUIScale.Scale = val
	scaleLabel.Text = string.format("UI SCALE  •  ตอนนี้ %.2fx", val)
	adjustPanelHeight(true)
end)

-- Menu Hotkey
addSectionLabel(settingsPage, "MENU HOTKEY (PC)")
state._capturingKey = false
local keyBtn
keyBtn = addActionButton(settingsPage, "⌨ ปุ่มเปิด/ปิดเมนู: " .. tostring(state.menuKey), Color3.fromRGB(0, 210, 255), function()
	if state._capturingKey then return end
	state._capturingKey = true
	keyBtn.Text = "กดปุ่มบนคีย์บอร์ดที่ต้องการ... (Esc = ยกเลิก)"
	local conn
	conn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		conn:Disconnect()
		if input.KeyCode ~= Enum.KeyCode.Escape then
			state.menuKey = input.KeyCode.Name
		end
		keyBtn.Text = "⌨ ปุ่มเปิด/ปิดเมนู: " .. tostring(state.menuKey)
		subTitle.Text = "v2.9 Neo Glass • " .. tostring(state.menuKey)
		task.defer(function() state._capturingKey = false end)
	end)
end)

-- Config
addSectionLabel(settingsPage, canFileIO and ("CONFIG  •  บันทึกอัตโนมัติทุก 3 วิ (เฉพาะเกมนี้)")
	or "CONFIG  •  Executor นี้ไม่รองรับ writefile")

addActionButton(settingsPage, "💾 Save Config Now", Color3.fromRGB(0, 220, 140), function()
	autoSavePaused = false
	if saveConfig() then
		sendNotification("Config Saved", CONFIG_FILE, Color3.fromRGB(0, 210, 130))
	else
		sendNotification("Config", "บันทึกไม่สำเร็จ (executor ไม่รองรับ?)", Color3.fromRGB(255, 80, 80))
	end
end)

addActionButton(settingsPage, "🗑 Reset Config (ลบไฟล์ของเกมนี้)", Color3.fromRGB(255, 90, 105), function(b)
	if b:GetAttribute("Confirm") then
		b:SetAttribute("Confirm", nil)
		autoSavePaused = true
		if deleteConfig() then
			sendNotification("Config Reset", "ลบแล้ว - รันสคริปต์ใหม่เพื่อเริ่มค่าเริ่มต้น", Color3.fromRGB(255, 175, 25))
		end
		b.Text = "🗑 Reset Config (ลบไฟล์ของเกมนี้)"
	else
		b:SetAttribute("Confirm", true)
		b.Text = "⚠ กดอีกครั้งเพื่อยืนยันการลบ"
		task.delay(3, function()
			if b.Parent and b:GetAttribute("Confirm") then
				b:SetAttribute("Confirm", nil)
				b.Text = "🗑 Reset Config (ลบไฟล์ของเกมนี้)"
			end
		end)
	end
end)
end

-- =========================================================================
-- ================== [TAB 8] PATCH UPDATE LOG 📜 ==========================
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
	pad.PaddingRight = UDim.new(0, 10)
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

addPatchLogCard("v2.9 PRO", "Latest Update", "NEW", Color3.fromRGB(0, 240, 200), {
	"[UI] ออกแบบ Panel ใหม่ทั้งหมดสไตล์ Neo-Glass: การ์ดโค้งมน, ขอบเรืองแสงไล่สีหมุนได้, หัวข้อตัวอักษรเงาวิ่ง",
	"[UI] แท็บแบบ Segmented พร้อมขีดใต้เรืองแสง เลื่อนตามแท็บที่เลือก และหน้าเลื่อนเข้าแบบนุ่ม",
	"[FX] เอฟเฟกต์ระลอกน้ำเมื่อแตะ, สวิตช์ไล่สีพร้อมแถบไฟด้านซ้ายเมื่อเปิด, ปุ่มลัดเด้งได้, หน้าต่างเปิด/ปิดแบบเด้ง",
	"[NEW] Theme Studio ในแท็บ SET: สีหลัก 8 สี + แถบเลือกสีเอง, ความเข้ม-จางพื้นหลัง, Base Theme 5 แบบ",
	"[NEW] Background Pattern 6 แบบ: None / Grid / Dots / Diagonal / Aurora (เคลื่อนไหว) / Stars (กระพริบ)",
	"[UX] แตะได้ทั้งแถวเพื่อเปิด/ปิด (ไม่ต้องเล็งที่สวิตช์) และทุกการตั้งค่าธีมถูกบันทึกอัตโนมัติ"
})

addPatchLogCard("v2.8 PRO", "Previous Update", "UPDATE", Color3.fromRGB(0, 195, 255), {
	"[UI] ออกแบบปุ่มลอยใหม่: โลโก้ P ไล่สี, ขอบเรืองแสงหมุนได้, ชื่อสีขาวชัดเจน (เดิมข้อความโดน UIGradient ย้อมจนมองไม่เห็น)",
	"[NEW] FPS Booster 3 ระดับ: FPS Booster / Super / Extreme เลือกได้ทีละระดับ คืนค่าเดิมได้ครบ",
	"[NEW] Player Tracers ในแท็บ Visual: เส้นจากตัวเราไปผู้เล่นอื่นแบบเรียลไทม์ สีตามทีม",
	"[NEW] จดจำแท็บล่าสุด, ตำแหน่งหน้าต่าง/ปุ่มลอย, ความกว้าง, สถานะพับ/ซ่อน และบันทึกอัตโนมัติทุก 3 วินาที"
})

addPatchLogCard("v2.7 PRO", "Older Update", "UPDATE", Color3.fromRGB(110, 140, 200), {
	"[NEW] Config Save/Load: บันทึกค่าทุกอย่าง + Waypoint ลงไฟล์แยกตามเกม และบันทึกอัตโนมัติทุก 10 วินาที",
	"[NEW] แท็บ 🌐 Server: ข้อมูลเซิร์ฟ, Copy Job ID / Join Script, Rejoin, Server Hop และ Join Smallest Server (Built-in)",
	"[NEW] แท็บ 🛠 Set: ปรับขนาด UI, ตั้งปุ่มลัดเปิดเมนูเอง, Save / Reset Config",
	"[NEW] Fly (Built-in) ในแท็บ Move และ Freecam ในแท็บ Visual รองรับทั้ง PC และมือถือ",
	"[NEW] Waypoint เก็บทิศที่หัน, แสดงระยะห่าง, ตัวเลือก Smooth Tween TP",
	"[NEW] Auto Rejoin, แจ้งเตือนผู้เล่นเข้า/ออก, แจ้งเตือนก่อนโดนเตะ AFK, ปุ่ม 📍 TAP TP สำหรับมือถือ",
	"[NEW] Battery Saver ปิดเรนเดอร์ 3D + จำกัด FPS และแสดงอัตราได้ Stats ต่อชั่วโมง",
	"[FIX] Vehicle Speed: ช่องกรอกแสดง 10 แต่ค่าจริงคือ 350 / Memory leak ของ Resize, Player Teleport, Spectate, Bot ESP",
	"[OPT] Bot ESP สแกนเฉพาะ Humanoid ลดอาการกระตุกในแมพใหญ่",
	"[SAFE] ลบ Anti AFK / Server Hop ที่โหลดโค้ดจากเว็บภายนอก แทนด้วยระบบในตัว (Fly GUI V3 ยังอยู่ในแท็บ Tools)",
	"[FIX] แก้สคริปต์รันไม่ติดบน Delta: จำนวน local เกินลิมิต 200 ของ Luau (แยก scope ด้วย do...end)"
})

addPatchLogCard("v2.6 PRO", "Older Update", "UPDATE", Color3.fromRGB(110, 140, 200), {
	"[NEW] เพิ่มปุ่ม '+ Add New Waypoint' ในหมวด Point สำหรับเพิ่มจุดวาร์ปได้ไม่จำกัดพร้อมปุ่มลบแยกแต่ละจุด",
	"[NEW] เพิ่มเครื่องมือ 🎥 Spectate Player ในหมวด Tools พร้อมช่อง Search ค้นหาชื่อผู้เล่นและรายการเลื่อนดู",
	"[UI] ย้ายสวิตช์ FPS / Ping Monitor จากหมวด Tools ไปยังหมวด Visual เพื่อความสะดวกในการใช้งาน"
})

addPatchLogCard("v2.5 PRO", "Older Update", "MAJOR", Color3.fromRGB(110, 140, 200), {
	"[UI] อัปเกรดดีไซน์ใหม่เป็น Cyber-Glassmorphism พร้อมกรอบสีเปลี่ยนตามหมวดหมู่แท็บ",
	"[UI] เปลี่ยนปุ่ม ON/OFF แบบเดิมเป็น Animated Pill Switches เลื่อนซ้าย-ขวาอย่างนุ่มนวล",
	"[UI] เพิ่มปุ่มลอย '⚡ Show Menu' ดีไซน์แคปซูลเรืองแสง และแยกปุ่มพับหน้าต่าง '-' ออกจากปุ่มซ่อนเมนู",
	"[NEW] เพิ่มระบบ Toast Notification มุมขวาล่าง แจ้งเตือนสถานะการทำงานแบบเรียลไทม์",
	"[NEW] เพิ่มระบบ Gravity Control (ปรับแรงโน้มถ่วง), Click TP (Ctrl+Click) และ Time of Day Changer",
	"[OPT] อัปเกรดระบบ Player ESP และ Bot ESP ให้แสดงเปอร์เซ็นต์เลือด [HP%] บนหัวเป้าหมาย"
})

addPatchLogCard("v2.0", "Core Build", "CORE", Color3.fromRGB(160, 175, 200), {
	"[NEW] ระบบ Battery Saver Overlay พร้อมตัวจับเวลาและคำนวณส่วนต่าง Leaderstats อัตโนมัติ",
	"[NEW] เพิ่มระบบ Bot ESP แยกสีอัตโนมัติ และ Raycast Occlusion เช็ควัตถุบังสายตา"
})

-- สลับไปยังแท็บแรกเริ่ม
switchTab("move")
task.spawn(function()
	task.wait(0.08)
	adjustPanelHeight(false)
	sendNotification("Phumipad Pro v2.9", "Neo-Glass UI • ปรับธีมได้ที่แท็บ SET", Color3.fromRGB(0, 225, 255))
	if configLoaded then
		sendNotification("Config Loaded", "โหลดค่าที่บันทึกไว้ของเกมนี้แล้ว", Color3.fromRGB(0, 210, 130))
	end
end)

-- v2.7: เปิดระบบที่ถูกบันทึกไว้ว่า "เปิด" ใน Config ให้ทำงานจริง
do
	local function try(fn, ...)
		local ok, err = pcall(fn, ...)
		if not ok then warn("[Phumipad Config Apply]: " .. tostring(err)) end
	end
	if state.speedEnabled and humanoid then humanoid.WalkSpeed = tonumber(state.speedValue) or 16 end
	if state.tpWalkEnabled  then try(applyTPWalk, true) end
	if state.jumpEnabled    then try(applyJumpPower, true) end
	if state.gravityEnabled then try(applyGravity, true) end
	if state.flyEnabled     then try(applyFly, true) end
	if state.godMode        then try(applyGodMode, true) end
	if state.noclip         then try(applyNoclip, true) end
	if state.antiRagdoll    then try(applyAntiRagdoll, true) end
	if state.spinBotEnabled then try(applySpinBot, true) end
	if state.clickTpEnabled then try(updateTapTpButton) end
	if state.esp            then try(applyESP, true) end
	if state.botEsp         then try(applyBotESP, true) end
	if state.fpsHudEnabled  then try(toggleFpsHud, true) end
	if state.fpsBoostLevel > 0 then task.spawn(applyFPSBooster, state.fpsBoostLevel) end
	if state.tracersEnabled then try(applyTracers, true) end
	if state.fullBright     then try(applyFullBright, true) end
	if state.timeLockEnabled then try(applyTimeLock, true) end
	if state.fovEnabled     then try(applyFOV, true) end
end

-- v2.8: Auto-save ทุก 3 วินาที (เขียนไฟล์เฉพาะตอนค่ามีการเปลี่ยนแปลง)
task.spawn(function()
	while scriptAlive do
		task.wait(3)
		if scriptAlive and not autoSavePaused then saveConfig(true) end
	end
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

-- Built-in Anti-AFK Connection
table.insert(globalConns, player.Idled:Connect(function()
	if state.builtInAntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

-- Click Teleport (Ctrl + Left Click), Tap TP (มือถือ) & Menu Hotkey (ตั้งค่าได้ในแท็บ Set)
local function getMenuKeyCode()
	local ok, kc = pcall(function() return Enum.KeyCode[state.menuKey] end)
	return (ok and kc) or Enum.KeyCode.RightControl
end

table.insert(globalConns, UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and not state._capturingKey and input.KeyCode == getMenuKeyCode() then
		UI.togglePanel()
	end
	if not gpe and state.clickTpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local mPos = UserInputService:GetMouseLocation()
			teleportToScreenPoint(mPos.X, mPos.Y, true)
		end
	end
	-- v2.7: Tap TP บนมือถือ (กดปุ่ม 📍 TAP TP ก่อน แล้วแตะจุดที่ต้องการ)
	if not gpe and state.clickTpEnabled and state._tapTpArmed and input.UserInputType == Enum.UserInputType.Touch then
		state._tapTpArmed = false
		local ok = teleportToScreenPoint(input.Position.X, input.Position.Y, false)
		local b = state._tapTpButton
		if b and b.Parent then
			b.Text = "📍 TAP TP"
			b.BackgroundColor3 = Color3.fromRGB(14, 22, 38)
		end
		if not ok then
			sendNotification("Tap TP", "ไม่พบพื้นผิวตรงจุดที่แตะ", Color3.fromRGB(255, 160, 0))
		end
	end
end))

-- v2.7: แจ้งเตือนผู้เล่นเข้า/ออก
table.insert(globalConns, Players.PlayerAdded:Connect(function(p)
	if state.joinLeaveNotify then
		sendNotification("➕ Player Joined", string.format("%s (@%s)", p.DisplayName, p.Name), Color3.fromRGB(0, 210, 130))
	end
end))
table.insert(globalConns, Players.PlayerRemoving:Connect(function(p)
	if state.joinLeaveNotify and p ~= player then
		sendNotification("➖ Player Left", string.format("%s (@%s)", p.DisplayName, p.Name), Color3.fromRGB(255, 90, 105))
	end
end))

-- v2.7: Auto Rejoin เมื่อเจอหน้าต่าง Disconnect / Kick
local rejoinInProgress = false
table.insert(globalConns, GuiService.ErrorMessageChanged:Connect(function(msg)
	if not state.autoRejoin or rejoinInProgress then return end
	if type(msg) ~= "string" or msg == "" then return end
	rejoinInProgress = true
	saveConfig(true)
	task.spawn(function()
		for attempt = 1, 5 do
			task.wait(3)
			pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
			task.wait(7)
		end
		rejoinInProgress = false
	end)
end))

state.baseWalkSpeed = humanoid and humanoid.WalkSpeed or 16
state.baseMaxHealth = humanoid and humanoid.MaxHealth or 100
state.baseJumpPower = humanoid and humanoid.JumpPower or 50
state.baseJumpHeight = humanoid and humanoid.JumpHeight or 7.2

-- ================== COMPLETE GLOBAL CLEANUP FUNCTION ==================
local function fullCleanup()
	-- v2.7: บันทึก Config ครั้งสุดท้าย (ก่อนที่ระบบต่างๆ จะถูกปิดและค่าเปลี่ยน)
	if not autoSavePaused then pcall(saveConfig, true) end
	pcall(function()
		UserInputService.MouseIconEnabled = true
	end)

	resetCameraToSelf()

	if state.godMode        then applyGodMode(false) end
	if state.noclip         then applyNoclip(false) end
	if state.tpWalkEnabled  then applyTPWalk(false) end
	if state.fpsBoostLevel > 0 then applyFPSBooster(0) end
	if state.tracersEnabled then applyTracers(false) end
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
	if state.flyEnabled     then applyFly(false) end
	if state.freecamEnabled then state.freecamEnabled = false; applyFreecam(false) end
	if state._tapTpGui then pcall(function() state._tapTpGui:Destroy() end); state._tapTpGui = nil end

	scriptAlive = false -- v2.7: หยุดลูปพื้นหลังทั้งหมด

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
		"SpectateUI",
		"Phumipad_AutoClicker_UI",
		"UniversalSpeedAdjustGui",
		"TeleportUI",
		"PhumipadToolboxMinimalGui",
		"Phumipad_ESP_Storage",
		"Phumipad_BotESP_Storage",
		"Phumipad_FPS_Ping_Monitor",
		"Phumipad_Toast_Notifications",
		"Phumipad_TapTP",
		"Phumipad_Tracers"
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
local function toggleFold()
	state.isFolded = not state.isFolded
	if state.isFolded then
		tabBar.Visible = false
		scroll.Visible = false
		resizeGrip.Visible = false
		miniBtn.Text = "+"
		TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, f.Size.X.Offset, 0, 56)
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
end
miniBtn.MouseButton1Click:Connect(toggleFold)

-- ปุ่ม '⚡': ซ่อนหน้าต่างหลักแล้วย่อเป็นปุ่มลอย 'Show Menu'
dockHideBtn.MouseButton1Click:Connect(function()
	UI.hidePanel()
end)

-- =========================================================================
-- ============ v2.8: จดจำสถานะหน้าต่างเมนู (แท็บ/ตำแหน่ง/พับ/ซ่อน) ========
-- =========================================================================
state._collectUi = function()
	if not f or not f.Parent then return end
	state.uiActiveTab = activeTabId or "move"
	state.uiMenuVisible = f.Visible
	state.uiFolded = state.isFolded and true or false
	local p = f.Position
	state.uiPos = {p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset}
	local d = openBtn.Position
	state.uiDockPos = {d.X.Scale, d.X.Offset, d.Y.Scale, d.Y.Offset}
	state.uiWidth = f.Size.X.Offset
end

do
	local unpackFn = table.unpack or unpack
	local function validPos(t)
		if type(t) ~= "table" or #t ~= 4 then return false end
		for i = 1, 4 do if type(t[i]) ~= "number" then return false end end
		return true
	end
	if validPos(state.uiPos) then f.Position = UDim2.new(unpackFn(state.uiPos)) end
	if validPos(state.uiDockPos) then openBtn.Position = UDim2.new(unpackFn(state.uiDockPos)) end
	local w = tonumber(state.uiWidth)
	if w then f.Size = UDim2.new(0, math.clamp(w, 250, 620), 0, f.Size.Y.Offset) end
	if type(state.uiActiveTab) == "string" and tabItems[state.uiActiveTab] then
		switchTab(state.uiActiveTab)
	end
	if state.uiMenuVisible == false then
		f.Visible = false
		openBtn.Visible = true
	end
	if state.uiFolded then
		task.delay(0.35, function()
			if not state.isFolded then toggleFold() end
		end)
	end

	-- กันหน้าต่าง/ปุ่มลอยหลุดออกนอกจอ (เช่นเปลี่ยนจากแนวนอนเป็นแนวตั้ง)
	task.delay(0.5, function()
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local function keepOnScreen(g, default)
			local ap, as = g.AbsolutePosition, g.AbsoluteSize
			if ap.X < -as.X * 0.5 or ap.Y < -10 or ap.X > vp.X - 40 or ap.Y > vp.Y - 30 then
				g.Position = default
			end
		end
		keepOnScreen(f, UDim2.new(0.04, 0, 0.45, -180))
		keepOnScreen(openBtn, UDim2.new(0, 18, 0, 55))
	end)
end

-- =========================================================================
-- ============ v2.9: เปิดใช้ธีมกับทุกส่วนของหน้าต่าง =======================
-- =========================================================================
UI.autoBind(f)
table.insert(globalConns, f.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if obj.Parent then pcall(UI.autoBindOne, obj) end
	end)
end))
UI.apply()

