-- =========================================================================
--   PHUMIPAD TOOLBOX [v3.1 PRO EDITION] - UNIVERSAL NEO-GLASS
--   Automation Tab, Custom Script Menus, Theme Tint, Glyph Fixes
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
	uiWidth = 330,
	-- v2.9: ธีม UI
	themeAccent = {0, 200, 255},
	themeBase = "Dark",
	uiTransparency = 0.06,
	uiPattern = "Dots",
	themeAnimBorder = true,
	themePerTab = false,
	themeTint = 0.0,
	-- v3.1: Universal / Automation
	autoInteract = false,
	autoInteractRange = 20,
	autoInteractFilter = "",
	autoInteractDelay = 0.35,
	autoCollect = false,
	autoCollectRange = 30,
	autoCollectFilter = "",
	autoCollectMagnet = false,
	autoCollectDelay = 0.4,
	autoEquip = false,
	autoUseTool = false,
	autoUseRate = 3,
	routeRunning = false,
	routeDelay = 2,
	macroFrames = {},
	macroRecording = false,
	macroPlaying = false,
	macroLoop = true,
	adminDetect = false,
	adminAutoHop = false,
	antiKick = false,
	objEsp = false,
	objEspFilter = "",
	clickDelete = false,
	deletedParts = {},
	chatLog = {},
	chatLogging = true,
	customTools = {},
	_objEspConn = nil,
	_objEspFolder = nil,
	_objEspCache = {},
	_delConn = nil,
	themeRainbow = false,
	themeKnobGlow = true,
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
local UI -- v3.1: ประกาศไว้ก่อน เพื่อให้ส่วนที่อยู่ด้านบนเรียกใช้ได้

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
	"themeAccent", "themeBase", "uiTransparency", "uiPattern", "themeAnimBorder", "themePerTab", "themeTint", "themeRainbow", "themeKnobGlow",
	"autoInteractRange", "autoInteractFilter", "autoCollectRange", "autoCollectFilter", "autoCollectMagnet",
	"autoUseRate", "routeDelay", "macroLoop", "adminDetect", "adminAutoHop", "objEspFilter",
	"chatLogging", "customTools"
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

-- v3.1: ธีมเริ่มต้นสำหรับทุกเกม (เก็บแยกจาก config ของแต่ละเกม)
local DEFAULT_THEME_FILE = CONFIG_FOLDER .. "/default_theme.json"
local THEME_KEYS = {"themeAccent", "themeBase", "uiTransparency", "uiPattern", "themeTint", "themeAnimBorder", "themePerTab", "themeRainbow", "themeKnobGlow", "uiScale", "menuKey"}

local function saveDefaultThemeFile()
	if not canFileIO then return false end
	return pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
		local t = {}
		for _, k in ipairs(THEME_KEYS) do t[k] = state[k] end
		writefile(DEFAULT_THEME_FILE, HttpService:JSONEncode(t))
	end)
end

local function loadDefaultThemeInto()
	if not canFileIO then return false end
	return pcall(function()
		if not isfile(DEFAULT_THEME_FILE) then error("no default") end
		local t = HttpService:JSONDecode(readfile(DEFAULT_THEME_FILE))
		if type(t) ~= "table" then error("bad") end
		for _, k in ipairs(THEME_KEYS) do
			if t[k] ~= nil and type(t[k]) == type(state[k]) then state[k] = t[k] end
		end
	end)
end

local configLoaded = loadConfig()
-- ถ้าเกมนี้ยังไม่มี config ให้ใช้ธีมเริ่มต้นที่ตั้งไว้ (ถ้ามี)
if not configLoaded then loadDefaultThemeInto() end
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

	local accent = (UI and UI.accent and UI.accent()) or Color3.fromRGB(0, 210, 255)
	local accent2 = (UI and UI.accent2 and UI.accent2()) or Color3.fromRGB(120, 90, 255)

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
	-- ไล่เฉดมืดบางๆ ให้ดูมีมิติ (ไม่กินแบตเพราะเป็น static)
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Rotation = 115
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(0, 0, 0), 0.9)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1, accent2:Lerp(Color3.fromRGB(0, 0, 0), 0.92))
	})
	bgGrad.Parent = bg

	-- แถบบน: โลโก้ + แบตเตอรี่
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, -60, 0, 44)
	topBar.Position = UDim2.new(0, 30, 0, 28)
	topBar.BackgroundTransparency = 1
	topBar.Parent = bg

	local brand = Instance.new("TextLabel")
	brand.Size = UDim2.new(0, 220, 1, 0)
	brand.BackgroundTransparency = 1
	brand.Text = "PHUMIPAD  •  Battery Saver"
	brand.TextColor3 = Color3.fromRGB(150, 160, 185)
	brand.Font = Enum.Font.GothamBold
	brand.TextSize = 13
	brand.TextXAlignment = Enum.TextXAlignment.Left
	brand.Parent = topBar

	local batContainer = Instance.new("Frame")
	batContainer.Size = UDim2.new(0, 150, 1, 0)
	batContainer.AnchorPoint = Vector2.new(1, 0)
	batContainer.Position = UDim2.new(1, 0, 0, 0)
	batContainer.BackgroundTransparency = 1
	batContainer.Parent = topBar

	local batLabel = Instance.new("TextLabel")
	batLabel.Size = UDim2.new(1, -52, 1, 0)
	batLabel.BackgroundTransparency = 1
	batLabel.Text = "100%"
	batLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	batLabel.Font = Enum.Font.GothamBold
	batLabel.TextSize = 18
	batLabel.TextXAlignment = Enum.TextXAlignment.Right
	batLabel.Parent = batContainer

	local batOutline = Instance.new("Frame")
	batOutline.Size = UDim2.new(0, 38, 0, 18)
	batOutline.AnchorPoint = Vector2.new(1, 0.5)
	batOutline.Position = UDim2.new(1, -8, 0.5, 0)
	batOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	batOutline.BackgroundTransparency = 1
	batOutline.Parent = batContainer
	local boStroke = Instance.new("UIStroke")
	boStroke.Color = Color3.fromRGB(150, 160, 185)
	boStroke.Thickness = 1.5
	boStroke.Parent = batOutline
	Instance.new("UICorner", batOutline).CornerRadius = UDim.new(0, 4)

	local batNub = Instance.new("Frame")
	batNub.Size = UDim2.new(0, 3, 0, 8)
	batNub.Position = UDim2.new(1, 0, 0.5, -4)
	batNub.BackgroundColor3 = Color3.fromRGB(150, 160, 185)
	batNub.BorderSizePixel = 0
	batNub.Parent = batOutline

	local batFill = Instance.new("Frame")
	batFill.Size = UDim2.new(1, -4, 1, -4)
	batFill.Position = UDim2.new(0, 2, 0, 2)
	batFill.BackgroundColor3 = Color3.fromRGB(0, 255, 125)
	batFill.BorderSizePixel = 0
	batFill.Parent = batOutline
	Instance.new("UICorner", batFill).CornerRadius = UDim.new(0, 2)

	-- กล่องกลางจอ
	local centerBox = Instance.new("Frame")
	centerBox.Size = UDim2.new(0, 560, 0, 400)
	centerBox.AnchorPoint = Vector2.new(0.5, 0.5)
	centerBox.Position = UDim2.new(0.5, 0, 0.46, 0)
	centerBox.BackgroundTransparency = 1
	centerBox.Parent = bg

	local clockLabel = Instance.new("TextLabel")
	clockLabel.Size = UDim2.new(1, 0, 0, 96)
	clockLabel.Position = UDim2.new(0, 0, 0, 0)
	clockLabel.BackgroundTransparency = 1
	clockLabel.Text = os.date("%H:%M:%S")
	clockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	clockLabel.Font = Enum.Font.GothamBlack
	clockLabel.TextSize = 86
	clockLabel.Parent = centerBox
	local clockGrad = Instance.new("UIGradient")
	clockGrad.Rotation = 25
	clockGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), accent:Lerp(Color3.fromRGB(255, 255, 255), 0.35))
	clockGrad.Parent = clockLabel

	local dateLabel = Instance.new("TextLabel")
	dateLabel.Size = UDim2.new(1, 0, 0, 22)
	dateLabel.Position = UDim2.new(0, 0, 0, 96)
	dateLabel.BackgroundTransparency = 1
	dateLabel.Text = os.date("%A, %d %B")
	dateLabel.TextColor3 = Color3.fromRGB(150, 160, 185)
	dateLabel.Font = Enum.Font.GothamMedium
	dateLabel.TextSize = 15
	dateLabel.Parent = centerBox

	local elapsedPill = Instance.new("Frame")
	elapsedPill.Size = UDim2.new(0, 260, 0, 36)
	elapsedPill.AnchorPoint = Vector2.new(0.5, 0)
	elapsedPill.Position = UDim2.new(0.5, 0, 0, 132)
	elapsedPill.BackgroundColor3 = accent
	elapsedPill.BackgroundTransparency = 0.85
	elapsedPill.Parent = centerBox
	Instance.new("UICorner", elapsedPill).CornerRadius = UDim.new(1, 0)
	local epStroke = Instance.new("UIStroke")
	epStroke.Color = accent
	epStroke.Transparency = 0.4
	epStroke.Parent = elapsedPill
	local elapsedLabel = Instance.new("TextLabel")
	elapsedLabel.Size = UDim2.new(1, 0, 1, 0)
	elapsedLabel.BackgroundTransparency = 1
	elapsedLabel.Text = "Saving Battery • 00:00"
	elapsedLabel.TextColor3 = accent
	elapsedLabel.Font = Enum.Font.GothamBold
	elapsedLabel.TextSize = 15
	elapsedLabel.Parent = elapsedPill

	local statsCard = Instance.new("Frame")
	statsCard.Size = UDim2.new(0, 480, 0, 56)
	statsCard.AnchorPoint = Vector2.new(0.5, 0)
	statsCard.Position = UDim2.new(0.5, 0, 0, 186)
	statsCard.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	statsCard.BackgroundTransparency = 0.15
	statsCard.Parent = centerBox
	Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 12)
	local scStroke2 = Instance.new("UIStroke")
	scStroke2.Color = Color3.fromRGB(45, 52, 72)
	scStroke2.Thickness = 1
	scStroke2.Parent = statsCard
	local statsIcon = Instance.new("TextLabel")
	statsIcon.Size = UDim2.new(0, 30, 1, 0)
	statsIcon.Position = UDim2.new(0, 10, 0, 0)
	statsIcon.BackgroundTransparency = 1
	statsIcon.Text = "📊"
	statsIcon.TextSize = 18
	statsIcon.Parent = statsCard
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -52, 1, 0)
	statsLabel.Position = UDim2.new(0, 44, 0, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Loading stats..."
	statsLabel.TextColor3 = Color3.fromRGB(255, 225, 90)
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextSize = 15
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	statsLabel.Parent = statsCard

	-- Slide to unlock
	local slideTrack = Instance.new("Frame")
	slideTrack.Size = UDim2.new(0, 360, 0, 62)
	slideTrack.AnchorPoint = Vector2.new(0.5, 0)
	slideTrack.Position = UDim2.new(0.5, 0, 0, 272)
	slideTrack.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	slideTrack.BackgroundTransparency = 0.1
	slideTrack.Parent = centerBox
	Instance.new("UICorner", slideTrack).CornerRadius = UDim.new(1, 0)
	local stStroke = Instance.new("UIStroke")
	stStroke.Color = accent
	stStroke.Transparency = 0.5
	stStroke.Thickness = 1.5
	stStroke.Parent = slideTrack

	local slideText = Instance.new("TextLabel")
	slideText.Size = UDim2.new(1, -80, 1, 0)
	slideText.Position = UDim2.new(0, 70, 0, 0)
	slideText.BackgroundTransparency = 1
	slideText.Text = "เลื่อนเพื่อปลดล็อก"
	slideText.TextColor3 = Color3.fromRGB(150, 160, 185)
	slideText.Font = Enum.Font.GothamMedium
	slideText.TextSize = 16
	slideText.Parent = slideTrack
	local shimmer = Instance.new("UIGradient")
	shimmer.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 120, 140)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 245, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 120, 140))
	})
	shimmer.Parent = slideText

	local slideKnob = Instance.new("TextButton")
	slideKnob.Size = UDim2.new(0, 54, 0, 54)
	slideKnob.Position = UDim2.new(0, 4, 0.5, 0)
	slideKnob.AnchorPoint = Vector2.new(0, 0.5)
	slideKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	slideKnob.Text = ">"
	slideKnob.TextColor3 = Color3.fromRGB(20, 22, 30)
	slideKnob.Font = Enum.Font.GothamBlack
	slideKnob.TextSize = 22
	slideKnob.AutoButtonColor = false
	slideKnob.Parent = slideTrack
	Instance.new("UICorner", slideKnob).CornerRadius = UDim.new(1, 0)
	local knobGrad = Instance.new("UIGradient")
	knobGrad.Rotation = 90
	knobGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), accent:Lerp(Color3.fromRGB(255, 255, 255), 0.4))
	knobGrad.Parent = slideKnob

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
			local clampedX = math.clamp(relativeX, 4, trackWidth - knobWidth - 4)
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
				TweenService:Create(slideKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 4, 0.5, 0)}):Play()
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
UI = {reg = {}, onApply = {}, patternToken = 0, hideToken = 0}
UI.saveDefaultTheme = saveDefaultThemeFile

UI.BASES = {
	Dark     = {bg = {11, 14, 22}, surface = {19, 23, 35}, surface2 = {29, 35, 52}, stroke = {44, 52, 76}},
	Midnight = {bg = {6, 10, 26},  surface = {13, 19, 42}, surface2 = {22, 31, 64}, stroke = {40, 54, 100}},
	AMOLED   = {bg = {0, 0, 0},    surface = {11, 11, 14}, surface2 = {22, 22, 27}, stroke = {44, 44, 52}},
	Violet   = {bg = {15, 9, 26},  surface = {25, 16, 40}, surface2 = {38, 25, 60}, stroke = {66, 46, 102}},
	Forest   = {bg = {6, 15, 13},  surface = {12, 26, 23}, surface2 = {20, 40, 35}, stroke = {38, 68, 60}},
}
UI.BASE_ORDER = {"Dark", "Midnight", "AMOLED", "Violet", "Forest"}
UI.ACCENTS = {
	{0, 200, 255}, {0, 150, 255}, {40, 110, 255}, {125, 95, 255}, {165, 80, 255}, {210, 70, 255},
	{255, 70, 170}, {255, 90, 120}, {255, 65, 85}, {255, 120, 40}, {255, 150, 35}, {255, 190, 30},
	{255, 210, 60}, {200, 230, 40}, {120, 225, 60}, {0, 225, 140}, {0, 220, 190}, {0, 210, 230},
	{120, 200, 255}, {255, 160, 200}, {180, 170, 255}, {230, 236, 248}
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
	local c = UI.rgb(b[role] or b.surface)
	local tint = tonumber(state.themeTint) or 0
	if tint > 0 and (role == "bg" or role == "surface" or role == "surface2" or role == "stroke") then
		c = c:Lerp(UI.accent(), tint * (role == "stroke" and 0.55 or 0.3))
	end
	return c
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
	local keepFns = {}
	for _, h in ipairs(UI.onApply) do
		if type(h) == "function" then
			pcall(h)
			table.insert(keepFns, h)
		elseif type(h) == "table" and h.owner then
			if h.owner.Parent then
				h.seen = true
				pcall(h.fn)
				table.insert(keepFns, h)
			elseif not h.seen then
				table.insert(keepFns, h)
			end
		end
	end
	UI.onApply = keepFns
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
f.Size = UDim2.new(0, 330, 0, 380)
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

-- ================== BACKGROUND PATTERN ENGINE (v3.0 - 20 แบบ, เคลื่อนไหวได้ 15 แบบ) ==================
-- แต่ละ pattern สร้างชิ้นส่วนในเลเยอร์ แล้วคืนฟังก์ชัน update(t, dt) สำหรับขยับทุกเฟรม (ถ้ามี)
UI.PATTERNS = {
	"None", "Grid", "Dots", "Diagonal",
	"Aurora", "Nebula", "Stars", "Snow", "Bubbles", "Fireflies",
	"Matrix", "Waves", "Rings", "Scanline", "Grid Flow", "Meteor",
	"Equalizer", "Orbit", "Sakura", "Rainbow"
}
UI.ANIMATED_PATTERNS = {
	Aurora = true, Nebula = true, Stars = true, Snow = true, Bubbles = true, Fireflies = true,
	Matrix = true, Waves = true, Rings = true, Scanline = true, ["Grid Flow"] = true, Meteor = true,
	Equalizer = true, Orbit = true, Sakura = true, Rainbow = true
}

function UI.pDot(layer, size, color, transp)
	local d = Instance.new("Frame")
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Size = UDim2.new(0, size, 0, size)
	d.BackgroundColor3 = color
	d.BackgroundTransparency = transp
	d.BorderSizePixel = 0
	d.Parent = layer
	UI.corner(d, "full")
	return d
end
function UI.pLine(layer, size, pos, color, transp)
	local l = Instance.new("Frame")
	l.Size = size
	l.Position = pos
	l.BackgroundColor3 = color
	l.BackgroundTransparency = transp
	l.BorderSizePixel = 0
	l.Parent = layer
	return l
end
function UI.pSoftGrad(inst, mid)
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, mid or 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	g.Parent = inst
	return g
end
function UI.pBlobs(layer, cols, size, trans)
	local blobs = {}
	for i, col in ipairs(cols) do
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Size = size
		b.BackgroundColor3 = col
		b.BorderSizePixel = 0
		b.Parent = layer
		UI.corner(b, "full")
		blobs[i] = {b, UI.pSoftGrad(b, trans)}
	end
	return blobs
end

UI.PATTERN_FX = {
	Grid = function(layer, acc)
		for i = 0, 34 do UI.pLine(layer, UDim2.new(0, 1, 1, 0), UDim2.new(0, i * 22, 0, 0), acc, 0.9) end
		for j = 0, 42 do UI.pLine(layer, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, j * 22), acc, 0.9) end
	end,
	Dots = function(layer, acc)
		local rows = {}
		for r = 1, 70 do rows[r] = ((r % 2 == 0) and "   " or "") .. string.rep("•     ", 30) end
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
	end,
	Diagonal = function(layer, acc)
		for i = -30, 40 do
			local l = UI.pLine(layer, UDim2.new(0, 1, 0, 2200), UDim2.new(0, i * 18, 0.5, 0), acc, 0.9)
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.Rotation = 35
		end
	end,
	Aurora = function(layer, acc, acc2)
		local blobs = UI.pBlobs(layer, {acc, acc2}, UDim2.new(1.3, 0, 0.75, 0), 0.72)
		return function(t)
			blobs[1][1].Position = UDim2.new(0.3 + math.sin(t * 0.5) * 0.2, 0, 0.25 + math.cos(t * 0.4) * 0.15, 0)
			blobs[2][1].Position = UDim2.new(0.7 + math.cos(t * 0.45) * 0.2, 0, 0.75 + math.sin(t * 0.35) * 0.15, 0)
			blobs[1][2].Rotation = (t * 20) % 360
			blobs[2][2].Rotation = (-t * 16) % 360
		end
	end,
	Nebula = function(layer, acc, acc2)
		local h = acc:ToHSV()
		local c3 = Color3.fromHSV((h + 0.5) % 1, 0.6, 1)
		local blobs = UI.pBlobs(layer, {acc, acc2, c3}, UDim2.new(1.1, 0, 0.6, 0), 0.78)
		return function(t)
			for i, b in ipairs(blobs) do
				local k = i * 2.1
				b[1].Position = UDim2.new(0.5 + math.sin(t * 0.22 + k) * 0.35, 0, 0.5 + math.cos(t * 0.18 + k) * 0.35, 0)
				b[1].Rotation = (t * 8 * (i % 2 == 0 and -1 or 1)) % 360
				b[2].Rotation = (t * 25 + k * 40) % 360
			end
		end
	end,
	Stars = function(layer, acc, _, rnd)
		for _ = 1, 46 do
			local d = UI.pDot(layer, rnd:NextInteger(2, 4), (rnd:NextNumber() > 0.5) and acc or Color3.fromRGB(255, 255, 255), rnd:NextNumber(0.3, 0.7))
			d.Position = UDim2.new(rnd:NextNumber(), 0, rnd:NextNumber(), 0)
			TweenService:Create(d, TweenInfo.new(rnd:NextNumber(0.8, 2.4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.95}):Play()
		end
	end,
	Snow = function(layer, _, _, rnd)
		local flakes = {}
		for i = 1, 40 do
			local d = UI.pDot(layer, rnd:NextInteger(2, 5), Color3.fromRGB(255, 255, 255), rnd:NextNumber(0.2, 0.6))
			flakes[i] = {d = d, x = rnd:NextNumber(), y = rnd:NextNumber(), sp = rnd:NextNumber(0.04, 0.12), ph = rnd:NextNumber(0, 6)}
		end
		return function(t, dt)
			for _, fl in ipairs(flakes) do
				fl.y = fl.y + fl.sp * dt
				if fl.y > 1.05 then fl.y = -0.05; fl.x = rnd:NextNumber() end
				fl.d.Position = UDim2.new(fl.x + math.sin(t * 1.2 + fl.ph) * 0.03, 0, fl.y, 0)
			end
		end
	end,
	Bubbles = function(layer, acc, acc2, rnd)
		local bubs = {}
		for i = 1, 18 do
			local sz = rnd:NextInteger(8, 26)
			local b = UI.pDot(layer, sz, (i % 2 == 0) and acc or acc2, 0.88)
			local s = Instance.new("UIStroke")
			s.Color = (i % 2 == 0) and acc or acc2
			s.Transparency = 0.35
			s.Thickness = 1.2
			s.Parent = b
			bubs[i] = {b = b, x = rnd:NextNumber(), y = rnd:NextNumber(0, 1.2), sp = rnd:NextNumber(0.05, 0.14), ph = rnd:NextNumber(0, 6)}
		end
		return function(t, dt)
			for _, bb in ipairs(bubs) do
				bb.y = bb.y - bb.sp * dt
				if bb.y < -0.08 then bb.y = 1.08; bb.x = rnd:NextNumber() end
				bb.b.Position = UDim2.new(bb.x + math.sin(t * 1.5 + bb.ph) * 0.025, 0, bb.y, 0)
			end
		end
	end,
	Fireflies = function(layer, acc, acc2, rnd)
		local flies = {}
		for i = 1, 24 do
			local d = UI.pDot(layer, rnd:NextInteger(3, 6), (i % 3 == 0) and acc2 or acc, 0.3)
			flies[i] = {d = d, x = rnd:NextNumber(), y = rnd:NextNumber(), a = rnd:NextNumber(0, 6.28), ph = rnd:NextNumber(0, 6)}
		end
		return function(t, dt)
			for _, fl in ipairs(flies) do
				fl.a = fl.a + (math.noise(fl.ph, t * 0.4) * 3) * dt
				fl.x = (fl.x + math.cos(fl.a) * 0.05 * dt) % 1
				fl.y = (fl.y + math.sin(fl.a) * 0.05 * dt) % 1
				fl.d.Position = UDim2.new(fl.x, 0, fl.y, 0)
				fl.d.BackgroundTransparency = 0.25 + (math.sin(t * 2.5 + fl.ph) + 1) * 0.33
			end
		end
	end,
	Matrix = function(layer, acc, _, rnd)
		local function col()
			local out = {}
			for i = 1, 22 do
				local k = rnd:NextInteger(1, 16)
				out[i] = string.sub("01010110<>/*#$+=", k, k)
			end
			return table.concat(out, "\n")
		end
		local cols = {}
		for i = 1, 16 do
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.new(0, 12, 0, 380)
			tl.AnchorPoint = Vector2.new(0.5, 0)
			tl.BackgroundTransparency = 1
			tl.Font = Enum.Font.Code
			tl.TextSize = 12
			tl.TextColor3 = acc
			tl.TextTransparency = rnd:NextNumber(0.45, 0.75)
			tl.TextYAlignment = Enum.TextYAlignment.Top
			tl.Text = col()
			tl.Parent = layer
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
			g.Parent = tl
			cols[i] = {tl = tl, x = (i - 0.5) / 16, y = rnd:NextNumber(-1.2, 1), sp = rnd:NextNumber(0.15, 0.4)}
		end
		return function(_, dt)
			for _, c in ipairs(cols) do
				c.y = c.y + c.sp * dt
				if c.y > 1.05 then c.y = -1.1; c.tl.Text = col() end
				c.tl.Position = UDim2.new(c.x, 0, c.y, 0)
			end
		end
	end,
	Waves = function(layer, acc, acc2)
		local lines = {}
		for i = 1, 8 do
			local l = UI.pLine(layer, UDim2.new(1.3, 0, 0, 2), UDim2.new(-0.15, 0, i / 9, 0), (i % 2 == 0) and acc or acc2, 0.35)
			l.AnchorPoint = Vector2.new(0, 0.5)
			local g = UI.pSoftGrad(l, 0)
			lines[i] = {l = l, g = g, base = i / 9}
		end
		return function(t)
			for i, w in ipairs(lines) do
				w.l.Position = UDim2.new(-0.15, 0, w.base + math.sin(t * 1.1 + i * 0.7) * 0.03, 0)
				w.l.Rotation = math.sin(t * 0.7 + i) * 3
				w.g.Offset = Vector2.new(math.sin(t * 0.6 + i) * 0.3, 0)
			end
		end
	end,
	Rings = function(layer, acc, acc2)
		local rings = {}
		for i = 1, 5 do
			local r = Instance.new("Frame")
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.new(0.5, 0, 0.45, 0)
			r.BackgroundTransparency = 1
			r.Parent = layer
			UI.corner(r, "full")
			local ar = Instance.new("UIAspectRatioConstraint")
			ar.AspectRatio = 1
			ar.DominantAxis = Enum.DominantAxis.Width
			ar.Parent = r
			local s = Instance.new("UIStroke")
			s.Color = (i % 2 == 0) and acc2 or acc
			s.Thickness = 1.6
			s.Parent = r
			rings[i] = {r = r, s = s}
		end
		return function(t)
			for i, rg in ipairs(rings) do
				local p = (t * 0.22 + i / #rings) % 1
				rg.r.Size = UDim2.new(p * 1.7, 0, p * 1.7, 0)
				rg.s.Transparency = 0.25 + p * 0.75
			end
		end
	end,
	Scanline = function(layer, acc)
		for j = 0, 90 do UI.pLine(layer, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, j * 9), acc, 0.94) end
		local band = UI.pLine(layer, UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), acc, 0.55)
		band.AnchorPoint = Vector2.new(0, 0.5)
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.85, 0.4), NumberSequenceKeypoint.new(1, 1)
		})
		g.Parent = band
		return function(t)
			band.Position = UDim2.new(0, 0, (t * 0.22) % 1.3 - 0.15, 0)
		end
	end,
	["Grid Flow"] = function(layer, acc)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 44, 1, 44)
		holder.BackgroundTransparency = 1
		holder.Parent = layer
		for i = 0, 36 do UI.pLine(holder, UDim2.new(0, 1, 1, 0), UDim2.new(0, i * 22, 0, 0), acc, 0.88) end
		for j = 0, 44 do UI.pLine(holder, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, j * 22), acc, 0.88) end
		local glow = UI.pDot(layer, 220, acc, 0.85)
		UI.pSoftGrad(glow, 0.7)
		return function(t)
			local o = (t * 14) % 22
			holder.Position = UDim2.new(0, -o, 0, -o)
			glow.Position = UDim2.new(0.5 + math.sin(t * 0.5) * 0.35, 0, 0.5 + math.cos(t * 0.4) * 0.35, 0)
		end
	end,
	Meteor = function(layer, acc, _, rnd)
		local ms = {}
		for i = 1, 7 do
			local m = UI.pLine(layer, UDim2.new(0, rnd:NextInteger(50, 110), 0, 2), UDim2.new(0, 0, 0, 0), (i % 2 == 0) and acc or Color3.fromRGB(255, 255, 255), 0)
			m.AnchorPoint = Vector2.new(1, 0.5)
			m.Rotation = 35
			UI.corner(m, "full")
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1)})
			g.Parent = m
			ms[i] = {m = m, x = rnd:NextNumber(-0.5, 1), y = rnd:NextNumber(-0.6, 0.6), sp = rnd:NextNumber(0.35, 0.7)}
		end
		local dir = Vector2.new(math.cos(math.rad(35)), math.sin(math.rad(35)))
		for _ = 1, 25 do
			local d = UI.pDot(layer, 2, Color3.fromRGB(255, 255, 255), rnd:NextNumber(0.4, 0.8))
			d.Position = UDim2.new(rnd:NextNumber(), 0, rnd:NextNumber(), 0)
		end
		return function(_, dt)
			for _, m in ipairs(ms) do
				m.x = m.x + dir.X * m.sp * dt
				m.y = m.y + dir.Y * m.sp * dt * 0.6
				if m.x > 1.3 or m.y > 1.3 then
					m.x = rnd:NextNumber(-0.6, 0.6); m.y = rnd:NextNumber(-0.7, -0.1); m.sp = rnd:NextNumber(0.35, 0.7)
				end
				m.m.Position = UDim2.new(m.x, 0, m.y, 0)
			end
		end
	end,
	Equalizer = function(layer, acc, acc2)
		local bars = {}
		local n = 18
		for i = 1, n do
			local b = UI.pLine(layer, UDim2.new(1 / n, -4, 0.1, 0), UDim2.new((i - 1) / n, 2, 1, 0), Color3.fromRGB(255, 255, 255), 0.55)
			b.AnchorPoint = Vector2.new(0, 1)
			UI.corner(b, 4)
			local g = Instance.new("UIGradient")
			g.Rotation = -90
			g.Color = ColorSequence.new(acc, acc2)
			g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
			g.Parent = b
			bars[i] = b
		end
		return function(t)
			for i, b in ipairs(bars) do
				local h = 0.06 + math.abs(math.noise(t * 1.6, i * 0.35)) * 0.55 + (math.sin(t * 3 + i * 0.5) + 1) * 0.04
				b.Size = UDim2.new(1 / n, -4, h, 0)
			end
		end
	end,
	Orbit = function(layer, acc, acc2)
		local orbits = {}
		for i = 1, 3 do
			local r = Instance.new("Frame")
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.new(0.5, 0, 0.42, 0)
			r.Size = UDim2.new(0, 70 * i, 0, 70 * i)
			r.BackgroundTransparency = 1
			r.Parent = layer
			UI.corner(r, "full")
			local s = Instance.new("UIStroke")
			s.Color = acc
			s.Transparency = 0.8
			s.Parent = r
			local dot = UI.pDot(layer, 7 - i, (i % 2 == 0) and acc2 or acc, 0.1)
			orbits[i] = {dot = dot, rad = 35 * i, sp = 1.4 / i, ph = i * 2}
		end
		local core = UI.pDot(layer, 14, acc, 0.3)
		core.Position = UDim2.new(0.5, 0, 0.42, 0)
		return function(t)
			for _, o in ipairs(orbits) do
				local a = t * o.sp + o.ph
				o.dot.Position = UDim2.new(0.5, math.cos(a) * o.rad, 0.42, math.sin(a) * o.rad)
			end
			core.BackgroundTransparency = 0.3 + (math.sin(t * 2) + 1) * 0.2
		end
	end,
	Sakura = function(layer, _, _, rnd)
		local petals = {}
		for i = 1, 16 do
			local p = Instance.new("TextLabel")
			p.AnchorPoint = Vector2.new(0.5, 0.5)
			p.Size = UDim2.new(0, 22, 0, 22)
			p.BackgroundTransparency = 1
			p.Text = (i % 4 == 0) and "🌸" or "❀"
			p.TextColor3 = Color3.fromRGB(255, 170, 205)
			p.TextTransparency = 0.25
			p.TextSize = rnd:NextInteger(12, 20)
			p.Parent = layer
			petals[i] = {p = p, x = rnd:NextNumber(), y = rnd:NextNumber(), sp = rnd:NextNumber(0.05, 0.12), ph = rnd:NextNumber(0, 6), rs = rnd:NextNumber(-90, 90)}
		end
		return function(t, dt)
			for _, pt in ipairs(petals) do
				pt.y = pt.y + pt.sp * dt
				pt.x = pt.x + 0.02 * dt
				if pt.y > 1.08 then pt.y = -0.08; pt.x = rnd:NextNumber() end
				pt.p.Position = UDim2.new((pt.x + math.sin(t + pt.ph) * 0.04) % 1, 0, pt.y, 0)
				pt.p.Rotation = (t * pt.rs) % 360
			end
		end
	end,
	Rainbow = function(layer)
		local w = UI.pLine(layer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 255, 255), 0)
		local kps = {}
		for i = 0, 6 do table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 0.75, 1))) end
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(kps)
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(1, 0.86)})
		g.Rotation = 30
		g.Parent = w
		return function(t)
			g.Rotation = (30 + t * 15) % 360
			g.Offset = Vector2.new(math.sin(t * 0.4) * 0.3, 0)
		end
	end,
}

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
	layer:SetAttribute("PPNoTheme", true)
	layer.Parent = f
	UI.patternLayer = layer

	local fx = UI.PATTERN_FX[state.uiPattern]
	if not fx then return end
	local ok, update = pcall(fx, layer, UI.accent(), UI.accent2(), Random.new(7))
	if not ok then
		warn("[Phumipad Pattern]: " .. tostring(update))
		return
	end
	if type(update) == "function" then
		task.spawn(function()
			local t0 = os.clock()
			local last = t0
			while scriptAlive and token == UI.patternToken and layer.Parent do
				local now = os.clock()
				local dt = math.min(now - last, 0.1)
				last = now
				if f.Visible and not state.isFolded then
					pcall(update, now - t0, dt)
				end
				task.wait(0.033)
			end
		end)
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
			-- v3.1: สีรุ้งวิ่ง (เปลี่ยนสีหลักเรื่อยๆ)
			if state.themeRainbow and f.Visible then
				UI._rainbowH = ((UI._rainbowH or 0) + 0.0025) % 1
				UI._rainbowAcc = (UI._rainbowAcc or 0) + 1
				if UI._rainbowAcc >= 4 then
					UI._rainbowAcc = 0
					local c = Color3.fromHSV(UI._rainbowH, 0.78, 1)
					state.themeAccent = {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
					pcall(UI.apply, true)
				end
			end
			if UI.windowGrads and #UI.windowGrads > 0 then
				local alive = {}
				for _, g in ipairs(UI.windowGrads) do
					if g.Parent and g.Parent.Parent then
						if state.themeAnimBorder then g.Rotation = (g.Rotation + 2) % 360 end
						table.insert(alive, g)
					end
				end
				UI.windowGrads = alive
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
	mainUIScale.Scale = s * 0.8
	f.Position = f.Position
	TweenService:Create(mainUIScale, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = s}):Play()
end
function UI.hidePanel()
	UI.hideToken = UI.hideToken + 1
	local token = UI.hideToken
	local s = math.clamp(tonumber(state.uiScale) or 1, 0.6, 1.6)
	TweenService:Create(mainUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = s * 0.8}):Play()
	task.delay(0.2, function()
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
	subTitle.Text = "v3.1 Universal • " .. tostring(state.menuKey)
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
local miniBtn = makeHeaderButton("CollapseButton", "-", -70, false)
local closeBtn = makeHeaderButton("CloseButton", "X", -36, true)

-- ================== SEGMENTED TAB BAR ==================
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TopTabBar"
tabBar.Size = UDim2.new(1, -20, 0, 38)
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
local CONTENT_TOP = 104
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
	gameNameLabel.Size = UDim2.new(1, -78, 0, 20)
	gameNameLabel.Position = UDim2.new(0, 12, 0, 8)
	gameNameLabel.BackgroundTransparency = 1
	gameNameLabel.Text = "Loading Game Info..."
	gameNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	gameNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	gameNameLabel.TextStrokeTransparency = 0.45
	gameNameLabel.Font = Enum.Font.GothamBold
	gameNameLabel.TextSize = 14
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
	copyHeaderBtn.Text = "COPY"
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
			copyHeaderBtn.Text = "DONE"
			sendNotification("Copied Game Name", gName, Color3.fromRGB(0, 200, 125))
		else
			copyHeaderBtn.Text = "FAIL"
		end
		task.wait(1.5)
		copyHeaderBtn.Text = "COPY"
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
	auto   = Color3.fromRGB(120, 230, 90),
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
	tabBtn.TextSize = 12
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
	-- v3.1: ไฟเรืองรอบหัวสวิตช์ตอนเปิด
	local knobGlow = Instance.new("UIStroke")
	knobGlow.Thickness = 0
	knobGlow.Transparency = 1
	knobGlow.Parent = knob

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
		local glowOn = cur and state.themeKnobGlow
		knobGlow.Color = UI.accent()
		TweenService:Create(knobGlow, ti, {Thickness = glowOn and 4 or 0, Transparency = glowOn and 0.35 or 1}):Play()
	end
	table.insert(UI.onApply, {owner = row, fn = function() render(cur, true) end})
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

local function addSectionLabel(parent, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 11.5
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = getOrder()
	l.Parent = parent
	UI.bind(l, "TextColor3", "sub")
	return l
end

local function addRefinedToolButton(parent, name, iconSymbol, accentColor, onClick)
	local row, rStroke = UI.card(parent, 48)
	table.insert(UI.onApply, {owner = row, fn = function() rStroke.Color = UI.color("stroke") end})

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 32, 0, 32)
	badge.Position = UDim2.new(0, 8, 0.5, -16)
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
	badgeText.TextSize = 15
	badgeText.Parent = badge

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -74, 1, 0)
	lbl.Position = UDim2.new(0, 50, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row
	UI.bind(lbl, "TextColor3", "text")

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -26, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = ">"
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
	UI.attachInfo(row, lbl, name, 34)

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
	local row, rStroke = UI.card(parent, 46)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -74, 1, 0)
	lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13.5
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
	UI.attachInfo(row, lbl, name, 64)
	UI.hookRowFx(row, clickBtn, function() onClick(pill, render) end)
	pill.MouseButton1Click:Connect(function() onClick(pill, render) end)
	return render
end

-- แถวกรอกค่า + สวิตช์
local function addInputToggleRow(parent, name, defaultVal, defaultOn, onToggle, onValChange)
	local row, rStroke = UI.card(parent, 48)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -136, 1, 0)
	lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row
	UI.bind(lbl, "TextColor3", "text")

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 56, 0, 26)
	box.Position = UDim2.new(1, -118, 0.5, -13)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultVal)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 13
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
	clickBtn.Size = UDim2.new(1, -124, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 2
	clickBtn.Parent = row

	render(defaultOn, true)
	UI.attachInfo(row, lbl, name, 124)

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
	row.Size = UDim2.new(1, 0, 0, 30)
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
		chip.TextSize = (type(val) == "string") and 10.5 or 12
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


-- =========================================================================
-- ============ v3.0: ระบบปุ่ม ⓘ อธิบายเมนู (วิธีใช้ + หลักการทำงาน) =========
-- =========================================================================
UI.INFO = {
	-- MOVE
	["Walk Speed"] = {use = "พิมพ์ความเร็วในช่อง หรือกดปุ่มตัวเลขลัดด้านล่าง แล้วเปิดสวิตช์ (ค่าปกติของเกม = 16)",
		how = "ตั้งค่า Humanoid.WalkSpeed ของตัวเราทุกเฟรม ถ้าเกมพยายามรีเซ็ตกลับ ระบบจะตั้งค่าซ้ำให้ทันที และเกิดใหม่ก็ยังทำงานต่อ",
		note = "บางเกมมีระบบตรวจความเร็วฝั่งเซิร์ฟเวอร์ อาจดึงตัวกลับหรือเตะออกได้"},
	["TP Walk"] = {use = "เปิดสวิตช์แล้วเดินตามปกติ ค่ายิ่งมากยิ่งเร็ว (เริ่มที่ 1-3 จะเนียนกว่า)",
		how = "ทุกเฟรมจะขยับตำแหน่งตัวละคร (CFrame) ไปตามทิศที่เดินเพิ่มอีกนิด จึงเร็วขึ้นโดยไม่แตะค่า WalkSpeed",
		note = "หลบระบบตรวจ WalkSpeed ได้ในหลายเกม แต่ถ้าตั้งสูงเกินไปจะดูวาร์ปกระตุก"},
	["Jump Power"] = {use = "ใส่ค่าแรงกระโดดแล้วเปิดสวิตช์ (ค่าปกติ = 50)",
		how = "ตั้ง JumpPower หรือ JumpHeight ของ Humanoid ตามที่เกมใช้อยู่ ปิดแล้วคืนค่าเดิมให้อัตโนมัติ"},
	["Gravity Control"] = {use = "ใส่ค่าแรงโน้มถ่วงแล้วเปิดสวิตช์ ค่าน้อย = ลอยนาน กระโดดสูง (ค่าปกติ 196.2)",
		how = "เปลี่ยน Workspace.Gravity ฝั่งเครื่องเรา มีผลกับตัวเราและวัตถุที่เราควบคุมฟิสิกส์อยู่"},
	["Fly (Built-in)"] = {use = "เปิดสวิตช์แล้วบิน • PC: WASD บังคับ, E/Space ขึ้น, Q/Ctrl ลง • มือถือ: ใช้จอยเดิน กดปุ่มกระโดดเพื่อบินขึ้น และก้ม/เงยกล้องเพื่อบินลง/ขึ้น ค่าในช่อง = ความเร็ว",
		how = "ใส่ BodyVelocity + BodyGyro ไว้ที่ HumanoidRootPart แล้วอัปเดตทิศทางตามกล้องทุกเฟรม ทำงานในตัวสคริปต์ ไม่ต้องโหลดจากเว็บ"},
	-- UTIL
	["Instant Interact"] = {use = "เปิดสวิตช์แล้วกดปุ่มโต้ตอบ (ProximityPrompt) ตามปกติ ไม่ต้องกดค้าง",
		how = "เมื่อเริ่มกดค้างจะเรียก fireproximityprompt ให้ทำงานทันที",
		note = "ต้องใช้ executor ที่รองรับ fireproximityprompt"},
	["Infinite Jump"] = {use = "เปิดสวิตช์ แล้วกดกระโดดกลางอากาศได้เรื่อยๆ",
		how = "ทุกครั้งที่กดกระโดด จะสั่ง Humanoid เข้าสถานะ Jumping ทันที แม้ยังไม่แตะพื้น"},
	["God Mode"] = {use = "เปิดสวิตช์เพื่อพยายามไม่ให้ตาย",
		how = "ตั้งเลือดสูงสุดเป็นอนันต์และปิดสถานะ Dead ของ Humanoid ฝั่งเครื่องเรา",
		note = "เลือดส่วนใหญ่ถูกคำนวณฝั่งเซิร์ฟเวอร์ ในหลายเกมจึงอาจใช้ไม่ได้ผล"},
	["Noclip"] = {use = "เปิดสวิตช์แล้วเดินทะลุกำแพงได้",
		how = "ทุกเฟรมปิด CanCollide ของชิ้นส่วนตัวละครทั้งหมด ปิดสวิตช์แล้วคืนการชนให้"},
	["Anti Ragdoll"] = {use = "เปิดไว้กันตัวละครล้ม/สลบ/ถูกบังคับนั่ง",
		how = "ดักการเปลี่ยนสถานะ Humanoid ถ้าเข้า Ragdoll, FallingDown, PlatformStand หรือ Seated จะสั่งลุกขึ้นทันที"},
	["Click TP (Ctrl+Click / Tap TP)"] = {use = "PC: กด Ctrl ค้างแล้วคลิกซ้ายตรงจุดที่ต้องการ • มือถือ: กดปุ่ม 📍 TAP TP ที่ขึ้นขวาจอ แล้วแตะจุดที่ต้องการวาร์ป",
		how = "ยิง Raycast จากกล้องไปยังจุดที่คลิก/แตะ ถ้าเจอพื้นผิวจะย้ายตัวไปยืนเหนือจุดนั้น โดยคงทิศที่หันอยู่"},
	["Built-in Anti-AFK"] = {use = "เปิดค้างไว้ตอนยืน AFK นานๆ (เปิดเป็นค่าเริ่มต้น)",
		how = "เมื่อ Roblox ส่งสัญญาณว่าเราไม่ขยับ (Idled) ระบบจะจำลองการคลิกเมาส์ จึงไม่โดนเตะหลัง 20 นาที"},
	["Auto Rejoin (on Disconnect)"] = {use = "เปิดไว้ ถ้าหลุดหรือโดนเตะ ระบบจะพาเข้าเกมเดิมใหม่ให้",
		how = "ดักข้อความ error ของ Roblox (GuiService) แล้วสั่ง Teleport กลับ PlaceId เดิม ลองซ้ำได้สูงสุด 5 ครั้ง",
		note = "ถ้าเซิร์ฟเวอร์ปิดหรือโดนแบน จะเข้าเซิร์ฟใหม่แทน"},
	["Notify Player Join / Leave"] = {use = "เปิดไว้เพื่อให้แจ้งเตือนมุมขวาเมื่อมีคนเข้าหรือออกเซิร์ฟ",
		how = "ฟังเหตุการณ์ PlayerAdded / PlayerRemoving แล้วแสดง Toast พร้อมชื่อผู้เล่น"},
	["AFK Kick Warning"] = {use = "เปิดไว้ จะเตือนก่อนโดนเตะเพราะ AFK ที่ 5 นาทีและ 1 นาที",
		how = "นับเวลาที่ไม่ได้ขยับ/แตะจอ เทียบกับเวลา 20 นาทีของ Roblox",
		note = "เตือนเฉพาะตอนปิด Built-in Anti-AFK"},
	["SpinBot"] = {use = "ใส่ความเร็วการหมุน (องศาต่อเฟรม) แล้วเปิดสวิตช์",
		how = "หมุน HumanoidRootPart รอบแกนตั้งทุกเฟรม"},
	-- VISUAL
	["Player ESP (with HP%)"] = {use = "เปิดสวิตช์เพื่อเห็นผู้เล่นทะลุกำแพง พร้อมชื่อ ระยะทาง และ % เลือด",
		how = "สร้าง Highlight และป้ายชื่อ (BillboardGui) ที่ตัวผู้เล่นทุกคน อัปเดตทุกเฟรม กรอบสีจะขึ้นเมื่อมีวัตถุบัง (เช็คด้วย Raycast)"},
	["ESP Team Colors"] = {use = "เปิด = ESP ใช้สีตามทีม • ปิด = ศัตรูเป็นสีแดงทั้งหมด",
		how = "ใช้ TeamColor ของแต่ละทีม ถ้าเกมไม่มีทีมจะสุ่มสีจากชื่อผู้เล่น เพื่อนร่วมทีมเป็นสีฟ้าเสมอ"},
	["Player Tracers (เส้นชี้ผู้เล่น)"] = {use = "เปิดสวิตช์เพื่อเห็นเส้นจากตัวเราไปหาผู้เล่นทุกคน",
		how = "แปลงตำแหน่ง 3D ของผู้เล่นเป็นตำแหน่งบนจอทุกเฟรม แล้ววาดเส้นด้วย GUI Frame ที่หมุนตามมุม ถ้าผู้เล่นอยู่ข้างหลัง เส้นจะชี้ไปขอบจอฝั่งนั้น"},
	["Bot ESP (with HP%)"] = {use = "เปิดเพื่อเห็น NPC/บอท/มอนสเตอร์ทะลุกำแพง พร้อม % เลือด",
		how = "สแกนหา Model ที่มี Humanoid แต่ไม่ใช่ผู้เล่น แล้วใส่ Highlight สีไม่ซ้ำกันให้แต่ละตัว"},
	["FPS / Ping Monitor"] = {use = "เปิดเพื่อแสดงกล่อง FPS และ Ping ด้านบนจอ ลากย้ายได้",
		how = "นับจำนวนเฟรมต่อวินาที และอ่านค่า Data Ping จาก Stats ของ Roblox ทุก 1 วินาที"},
	["FPS Booster"] = {use = "เปิดเมื่อเกมกระตุก (ภาพจะเรียบขึ้นแต่ยังดูออก)",
		how = "ตั้ง Quality ต่ำสุด ปิดเงา/Post FX วัสดุทุกชิ้นเป็นพลาสติกเรียบ ซ่อน Decal/Texture และปิด Particle",
		note = "เปิดได้ทีละระดับ ปิดแล้วคืนกราฟิกเดิมครบ"},
	["Super FPS Booster"] = {use = "ใช้เมื่อ FPS Booster ธรรมดายังไม่พอ",
		how = "ทำทุกอย่างของระดับ 1 + ปิดคลื่นน้ำ หญ้า เมฆ Atmosphere แสงไฟทุกดวง และลบ Texture ของ Mesh / SurfaceAppearance"},
	["Extreme FPS Booster"] = {use = "ใช้กับเครื่องสเปกต่ำมาก หรือต้องการประหยัดแบตสุดๆ",
		how = "ทำทุกอย่างของ Super + ลบท้องฟ้า ซ่อนชุด/เครื่องประดับผู้เล่นอื่น และซ่อนวัตถุที่อยู่ไกลกว่า 300 studs (อัปเดตทุก 0.75 วิ)",
		note = "ภาพจะดูเละที่สุด แต่เบาเครื่องที่สุด"},
	["Full Bright"] = {use = "เปิดเพื่อให้แมพสว่างตลอด เห็นชัดในที่มืด",
		how = "ตั้งแสง Ambient เป็นสีขาวเต็ม และล็อกไว้ไม่ให้เกมปรับกลับ"},
	["Time of Day (0-24)"] = {use = "ใส่ชั่วโมง (เช่น 12 = เที่ยง, 0 = เที่ยงคืน) หรือกดปุ่มลัด แล้วเปิดสวิตช์",
		how = "ล็อกค่า Lighting.ClockTime ฝั่งเครื่องเรา ถ้าเกมเปลี่ยนเวลาจะตั้งกลับให้ทันที"},
	["Camera FOV"] = {use = "ใส่มุมมองกล้อง (ปกติ 70) ค่ามาก = มองเห็นกว้างขึ้น แล้วเปิดสวิตช์",
		how = "ตั้ง FieldOfView ของกล้องปัจจุบัน"},
	["Freecam"] = {use = "เปิดเพื่อบินกล้องอิสระ ตัวละครจะหยุดอยู่กับที่ • PC: คลิกขวาค้างหมุนกล้อง, WASD/E/Q เคลื่อนที่, Shift เร่ง • มือถือ: ลากนิ้วครึ่งขวาจอหมุน, จอยซ้ายเคลื่อนที่",
		how = "เปลี่ยนกล้องเป็นโหมด Scriptable และยึด HumanoidRootPart ไว้ (Anchored) ระหว่างใช้งาน",
		note = "เกิดใหม่แล้ว Freecam จะปิดเองเพื่อความปลอดภัย"},
	["Saver: Stop 3D + FPS Cap"] = {use = "ตั้งค่าสำหรับปุ่ม Battery Saver: ช่องตัวเลข = FPS ที่จำกัด, สวิตช์ = ปิดการเรนเดอร์ 3D",
		how = "ตอนเปิด Battery Saver Overlay จะสั่ง setfpscap และ Set3dRenderingEnabled(false) แล้วคืนค่าเมื่อปลดล็อก"},
	-- POINT
	["Smooth Tween TP (speed)"] = {use = "เปิดสวิตช์เพื่อให้การวาร์ป Waypoint เป็นแบบเลื่อนนุ่มๆ ค่าในช่อง = ความเร็ว (studs/วินาที)",
		how = "ใช้ TweenService เลื่อน CFrame ของตัวละครไปยังจุดหมาย แทนการวาร์ปทันที",
		note = "เลื่อนช้าดูเนียนกว่า บางเกมตรวจจับการวาร์ปทันทีได้"},
	-- TOOLS
	["Aiming (Aimbot)"] = {use = "แตะเพื่อโหลดสคริปต์ Aimbot ภายนอก",
		how = "ดาวน์โหลดโค้ดจากเว็บของผู้สร้างแล้วรันทันที",
		note = "โค้ดอยู่นอกการควบคุมของ Phumipad ผู้สร้างแก้ไขได้ตลอด ใช้ด้วยความระวัง"},
	["Auto Clicker"] = {use = "แตะเพื่อเปิดหน้าต่าง Auto Clicker ตั้ง CPS เลือกจุดคลิก แล้วกด START",
		how = "จำลองการคลิกเมาส์ด้วย VirtualInputManager ตามความเร็วที่ตั้ง โหมด Turbo จะคลิกทุกเฟรม"},
	["Fly GUI (V3)"] = {use = "แตะเพื่อโหลดหน้าต่าง Fly GUI V3",
		how = "ดาวน์โหลดสคริปต์ Fly GUI V3 จาก GitHub แล้วรัน",
		note = "เป็นโค้ดภายนอก ถ้าอยากได้ตัวที่ปลอดภัยกว่าให้ใช้ Fly (Built-in) ในแท็บ Move"},
	["Player Teleport"] = {use = "แตะเพื่อเปิดรายชื่อผู้เล่น ค้นหา/เลือกคน แล้วกด Teleport",
		how = "ย้ายตัวเราไปด้านหลังผู้เล่นเป้าหมาย 3 studs ครั้งเดียว"},
	["Spectate Player"] = {use = "แตะเพื่อเปิดหน้าต่างส่องผู้เล่น เลือกชื่อหรือกดปุ่มสลับคน กด STOP เพื่อกลับมาดูตัวเอง",
		how = "เปลี่ยน CameraSubject ของกล้องไปที่ตัวผู้เล่นเป้าหมาย ตัวเราไม่ได้ขยับไปไหน"},
	["Stalker"] = {use = "แตะเพื่อเปิดหน้าต่าง เลือกผู้เล่นแล้วกด START เพื่อเกาะติดด้านหลัง กด STOP เพื่อหยุด",
		how = "ย้ายตัวเราไปด้านหลังผู้เล่นเป้าหมาย 3 studs ทุกเฟรมจนกว่าจะหยุด"},
	["Vehicle Speed Adjust"] = {use = "นั่งรถก่อน แล้วเปิดหน้าต่างนี้ ตั้งแรงผลัก กด F หรือปุ่มเริ่มเพื่อเร่ง",
		how = "ใส่แรงผลัก (ApplyImpulse) ไปทางด้านหน้าของเบาะที่นั่งอยู่ทุกเฟรม ค่ามาก = เร่งแรง"},
	-- SERVER
	["Copy Job ID"] = {use = "แตะเพื่อคัดลอกรหัสเซิร์ฟเวอร์ที่อยู่ตอนนี้",
		how = "คัดลอก game.JobId ไปยังคลิปบอร์ด"},
	["Copy Join Script (ชวนเพื่อนเข้าเซิร์ฟนี้)"] = {use = "แตะแล้วส่งข้อความที่คัดลอกให้เพื่อน ให้เพื่อนรันใน executor",
		how = "สร้างโค้ด TeleportToPlaceInstance พร้อม PlaceId และ JobId ของเซิร์ฟนี้ เพื่อนจะเข้าเซิร์ฟเดียวกับเรา"},
	["Rejoin Server"] = {use = "แตะเพื่อออกแล้วเข้าเซิร์ฟเดิมใหม่ (แก้อาการแลค/บั๊ก)",
		how = "Teleport กลับ JobId เดิม ถ้าอยู่คนเดียวจะเข้าเซิร์ฟใหม่แทน"},
	["Server Hop (Random)"] = {use = "แตะเพื่อย้ายไปเซิร์ฟอื่นแบบสุ่ม",
		how = "ดึงรายชื่อเซิร์ฟสาธารณะจาก API ของ Roblox (สูงสุด 300 เซิร์ฟ) เลือกเซิร์ฟที่ยังไม่เต็มแบบสุ่ม แล้ว Teleport"},
	["Join Smallest Server"] = {use = "แตะเพื่อย้ายไปเซิร์ฟที่คนน้อยที่สุด เหมาะกับการฟาร์มเงียบๆ",
		how = "ดึงรายชื่อเซิร์ฟแล้วเรียงตามจำนวนคน เลือกเซิร์ฟที่คนน้อยที่สุดที่ไม่ใช่เซิร์ฟปัจจุบัน"},
	-- AUTOMATION (v3.1)
	["Auto Interact (ระยะ studs)"] = {use = "ใส่ระยะ (studs) แล้วเปิดสวิตช์ ถ้าอยากกดเฉพาะบางปุ่มให้พิมพ์คำในช่องกรองด้านล่าง เช่น Collect, Claim",
		how = "วนหา ProximityPrompt ทุกอันใน Workspace ที่อยู่ในระยะ แล้วสั่ง fireproximityprompt ให้ทำงานทุกๆ 0.35 วินาที",
		note = "ต้องใช้ executor ที่รองรับ fireproximityprompt"},
	["กรองชื่อปุ่ม (เว้นว่าง = ทุกปุ่ม)"] = {use = "พิมพ์คำที่ต้องการ คั่นด้วยจุลภาค เช่น Collect, Claim, Buy เว้นว่างไว้ = กดทุกปุ่ม",
		how = "เทียบคำที่พิมพ์กับชื่อปุ่ม ActionText และชื่อวัตถุ แบบไม่สนตัวพิมพ์เล็กใหญ่"},
	["Auto Collect (ระยะ studs)"] = {use = "ใส่ระยะแล้วเปิดสวิตช์ จะเก็บ Tool ที่ตกอยู่บนพื้นอัตโนมัติ ถ้าของไม่ใช่ Tool ให้พิมพ์ชื่อในช่องกรอง",
		how = "ยิง firetouchinterest ไปที่ของทุกชิ้นในระยะ เหมือนเราเดินไปชนเอง ถ้าเปิดโหมด Magnet จะย้ายของมาที่ตัวเราก่อน",
		note = "เกมที่ตรวจตำแหน่งของฝั่งเซิร์ฟเวอร์อาจไม่นับให้"},
	["ดูดของมาหาตัว (Magnet) แทนการเดินไปเก็บ"] = {use = "เปิดเมื่อการแตะเฉยๆ ไม่ติด จะย้ายของมาที่ตัวเราเลย",
		how = "ตั้ง CFrame ของชิ้นนั้นให้มาอยู่ตำแหน่งเดียวกับตัวเรา แล้วค่อยสั่งแตะ",
		note = "เห็นชัดกว่าปกติ เสี่ยงโดนตรวจจับมากกว่าโหมดธรรมดา"},
	["Auto Equip (หยิบเครื่องมือชิ้นแรกมาถือ)"] = {use = "เปิดไว้ ถ้ามือว่างจะหยิบเครื่องมือชิ้นแรกจากกระเป๋ามาถือให้",
		how = "เช็คทุก 0.6 วินาทีว่าตัวละครถือ Tool อยู่หรือยัง ถ้ายังจะสั่ง Humanoid:EquipTool"},
	["Auto Use Tool (ครั้ง/วินาที)"] = {use = "ถือเครื่องมือไว้แล้วเปิดสวิตช์ ใส่จำนวนครั้งต่อวินาทีที่ต้องการ",
		how = "เรียก Tool:Activate() ซ้ำตามอัตราที่ตั้ง เหมือนกดคลิกใช้เครื่องมือเอง"},
	["Run Route (พักจุดละ ? วิ)"] = {use = "บันทึกจุดในแท็บ Point ก่อน แล้วเปิดสวิตช์นี้ ตัวละครจะวนวาร์ปตามจุดเรียงตามลำดับ",
		how = "วนลูปรายการ Waypoint ที่บันทึกไว้ ย้าย CFrame ไปทีละจุด แล้วรอตามเวลาที่ตั้งก่อนไปจุดถัดไป"},
	["เล่นซ้ำแบบวนลูป (Loop)"] = {use = "เปิดไว้ มาโครจะเล่นซ้ำไม่หยุดจนกว่าจะกดหยุดเอง",
		how = "เมื่อเล่นจบเฟรมสุดท้ายจะวนกลับไปเฟรมแรกใหม่"},
	["แจ้งเตือนเมื่อมีแอดมิน/ทีมงานเข้าเซิร์ฟ"] = {use = "เปิดไว้ จะเตือนเมื่อมีคนที่น่าจะเป็นทีมงานเข้าเซิร์ฟ",
		how = "เช็คว่าผู้เล่นอยู่ในกลุ่มเจ้าของเกม เป็นเจ้าของเกม หรือมีคำว่า admin/mod/staff ในชื่อ",
		note = "เป็นการเดาเบื้องต้น ไม่แม่นยำ 100%"},
	["ย้ายเซิร์ฟอัตโนมัติเมื่อเจอแอดมิน"] = {use = "เปิดคู่กับระบบด้านบน ถ้าเจอทีมงานจะ Server Hop หนีให้ทันที",
		how = "เมื่อการตรวจพบทำงาน จะเรียก Server Hop แบบสุ่มหลังจากนั้น 1 วินาที"},
	["Anti-Kick (กัน Kick ฝั่งเครื่องเรา)"] = {use = "เปิดไว้เพื่อพยายามบล็อกคำสั่งเตะออกจากเกม",
		how = "ดักเมธอด Kick ผ่าน hookmetamethod ถ้าเป็นคำสั่งจากเกม (ไม่ใช่จากสคริปต์เรา) จะไม่ให้ทำงาน",
		note = "ใช้ได้เฉพาะ executor ที่มี hookmetamethod และกันได้เฉพาะ Kick ฝั่งเครื่องเราเท่านั้น ไม่กันการปิดเซิร์ฟหรือแบน"},
	["Object ESP (หาของตามชื่อ)"] = {use = "พิมพ์ชื่อของในช่องด้านล่าง เช่น Chest, Coin แล้วเปิดสวิตช์ จะขึ้นไฮไลต์ทะลุกำแพงพร้อมระยะทาง",
		how = "สแกน Workspace ทุก 2 วินาทีหาวัตถุที่ชื่อตรงกับคำค้น แล้วใส่ Highlight และป้ายชื่อให้ (จำกัดไม่เกิน 120 ชิ้นเพื่อไม่ให้กระตุก)"},
	["ชื่อของที่จะหา"] = {use = "พิมพ์คำค้น คั่นหลายคำด้วยจุลภาค เช่น Chest, Crate, Box",
		how = "เทียบคำที่พิมพ์กับชื่อวัตถุใน Workspace แบบไม่สนตัวพิมพ์เล็กใหญ่"},
	["Click Delete (Alt+คลิก / แตะ บนมือถือ)"] = {use = "PC: กด Alt ค้างแล้วคลิกวัตถุที่ต้องการลบ • มือถือ: แตะวัตถุได้เลย ใช้ลบกำแพงหรือสิ่งที่บังทางได้",
		how = "ยิง Raycast จากจุดที่คลิก แล้วย้ายวัตถุนั้นออกจากเกมฝั่งเครื่องเรา (เก็บไว้กู้คืนได้)",
		note = "ลบเฉพาะบนจอเราเท่านั้น ผู้เล่นคนอื่นยังเห็นปกติ และระบบจะไม่ลบตัวผู้เล่น"},
	["กู้คืนวัตถุที่ลบไปทั้งหมด"] = {use = "แตะเพื่อเอาวัตถุที่ลบด้วย Click Delete กลับมาทั้งหมด",
		how = "นำวัตถุที่เก็บไว้กลับไปใส่ที่ Parent เดิม"},
	["Chat Logger"] = {use = "แตะเพื่อเปิดหน้าต่างดูแชตย้อนหลัง มีปุ่มคัดลอกทั้งหมด",
		how = "ดักเหตุการณ์ Chatted ของผู้เล่นทุกคน เก็บไว้สูงสุด 400 ข้อความ จึงยังเห็นข้อความที่ถูกลบไปแล้ว"},
	-- SETTINGS
	["🎨 ระดับการผสมสีลงพาแนล (Tint)"] = {use = "ลากเพื่อผสมสีหลักลงไปในพื้นหลังและขอบของพาแนล ค่ามาก = พาแนลติดสีมาก",
		how = "ผสมสีหลักเข้ากับสีพื้นของธีมตามเปอร์เซ็นต์ที่ตั้ง แล้วทาใหม่ทั้ง UI"},
	["สีรุ้งวิ่ง (Rainbow Accent)"] = {use = "เปิดแล้วสีหลักจะไล่เปลี่ยนสีไปเรื่อยๆ เอง",
		how = "ค่อยๆ เลื่อนค่า Hue ของสีหลักแล้วทาสี UI ใหม่ประมาณ 8 ครั้งต่อวินาที",
		note = "กินเครื่องมากกว่าปกติเล็กน้อย ถ้าเกมกระตุกให้ปิด"},
	["ไฟเรืองที่หัวสวิตช์ (Knob Glow)"] = {use = "เปิด/ปิดไฟเรืองรอบหัวสวิตช์เวลาเปิดเมนูนั้นๆ",
		how = "เพิ่ม UIStroke เรืองแสงสีหลักรอบหัวสวิตช์เมื่ออยู่สถานะเปิด"},
	["🌈 Custom Hue (ลากเลือกสีเอง)"] = {use = "ลากปุ่มกลมบนแถบสีรุ้งเพื่อเลือกสีหลักแบบอิสระ",
		how = "แปลงตำแหน่งบนแถบเป็นค่า Hue (0-360°) แล้วเปลี่ยนสีทุกส่วนของ UI ทันที ลวดลายพื้นหลังจะอัปเดตเมื่อปล่อยนิ้ว"},
	["💧 ความเข้มพื้นหลัง (Opacity)"] = {use = "ลากซ้าย = หน้าต่างใสมองทะลุเห็นเกม • ลากขวา = ทึบเข้ม",
		how = "ปรับ BackgroundTransparency ของพื้นหน้าต่างและการ์ดทุกใบพร้อมกัน"},
	["ขอบเรืองแสงหมุน (Animated Border)"] = {use = "เปิด/ปิดแอนิเมชันขอบเรืองแสงที่หมุนรอบหน้าต่าง",
		how = "หมุน UIGradient บนขอบหน้าต่างทุกเฟรม ปิดไว้จะประหยัดเครื่องลงเล็กน้อย"},
	["สีเปลี่ยนตามแท็บ (Per-tab Color)"] = {use = "เปิด = แต่ละแท็บมีสีประจำของตัวเอง • ปิด = ใช้สีหลักสีเดียวทั้งหน้าต่าง",
		how = "เมื่อเปลี่ยนแท็บ จะเปลี่ยนสีไฮไลต์แท็บและขอบหน้าต่างเป็นสีประจำแท็บนั้น"},
}

-- ปุ่มวงกลม "i" วางต่อท้ายชื่อเมนู
function UI.attachInfo(row, lbl, name, rightReserve)
	if not UI.INFO[name] then return end
	local info = Instance.new("TextButton")
	info.Name = "InfoButton"
	info.Size = UDim2.new(0, 20, 0, 20)
	info.AnchorPoint = Vector2.new(0, 0.5)
	info.BorderSizePixel = 0
	info.Text = "i"
	info.Font = Enum.Font.GothamBlack
	info.TextSize = 12
	info.AutoButtonColor = false
	info.ZIndex = 7
	info.Parent = row
	UI.corner(info, "full")
	UI.bind(info, "BackgroundColor3", "accentSoft")
	UI.bind(info, "TextColor3", "accent")
	UI.stroke(info, "accent", 1, 0.35)
	local sc = Instance.new("UIScale")
	sc.Parent = info

	local baseX = lbl.Position.X.Offset
	local function place()
		local maxW = math.max(row.AbsoluteSize.X / math.max(UI.mainScale.Scale, 0.1) - baseX - rightReserve - 30, 20)
		local ys, yo = lbl.Size.Y.Scale, lbl.Size.Y.Offset
		lbl.Size = UDim2.new(0, maxW, ys, yo)
		local tw = math.min(lbl.TextBounds.X, maxW)
		info.Position = UDim2.new(0, baseX + tw + 7, lbl.Position.Y.Scale + ys * 0.5, lbl.Position.Y.Offset + yo * 0.5)
	end
	place()
	lbl:GetPropertyChangedSignal("TextBounds"):Connect(place)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	info.MouseButton1Click:Connect(function()
		sc.Scale = 0.7
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		UI.showInfo(name)
	end)
end

-- หน้าต่างอธิบาย (ซ้อนบนหน้าต่างหลัก แตะพื้นที่มืดหรือปุ่ม "เข้าใจแล้ว" เพื่อปิด)
function UI.showInfo(name)
	local data = UI.INFO[name]
	if not data then return end
	if UI.infoOverlay then pcall(function() UI.infoOverlay:Destroy() end) end

	local overlay = Instance.new("TextButton")
	overlay.Name = "InfoOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.ZIndex = 300
	overlay:SetAttribute("PPNoTheme", true)
	overlay.Parent = f
	UI.infoOverlay = overlay
	UI.corner(overlay, 18)
	TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(1, -28, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BorderSizePixel = 0
	card.Active = true
	card.ZIndex = 301
	card.Parent = overlay
	UI.bind(card, "BackgroundColor3", "surface")
	UI.corner(card, 16)
	local cst = Instance.new("UIStroke")
	cst.Color = Color3.fromRGB(255, 255, 255)
	cst.Thickness = 1.6
	cst.Parent = card
	local cg = Instance.new("UIGradient")
	cg.Parent = cst
	UI.bind(cg, "Color", "grad")
	local pop = Instance.new("UIScale")
	pop.Scale = 0.85
	pop.Parent = card
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 8)
	lay.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card

	local order = 0
	local function text(t, size, font, role, wrapped)
		order = order + 1
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.BackgroundTransparency = 1
		l.Text = t
		l.Font = font
		l.TextSize = size
		l.TextWrapped = wrapped ~= false
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.LayoutOrder = order
		l.ZIndex = 302
		l.Parent = card
		UI.bind(l, "TextColor3", role)
		return l
	end

	text("ⓘ  " .. name, 15, Enum.Font.GothamBlack, "text")
	text("📖  วิธีใช้งาน", 12.5, Enum.Font.GothamBold, "accent")
	text(data.use or "-", 13, Enum.Font.GothamMedium, "text")
	text("⚙️  ทำงานยังไง", 12.5, Enum.Font.GothamBold, "accent")
	text(data.how or "-", 13, Enum.Font.GothamMedium, "sub")
	if data.note then
		local n = text("⚠️  " .. data.note, 12, Enum.Font.GothamMedium, "text")
		n.TextColor3 = Color3.fromRGB(255, 195, 90)
	end

	order = order + 1
	local ok = Instance.new("TextButton")
	ok.Size = UDim2.new(1, 0, 0, 38)
	ok.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ok.BorderSizePixel = 0
	ok.Text = "เข้าใจแล้ว"
	ok.TextColor3 = Color3.fromRGB(255, 255, 255)
	ok.TextStrokeTransparency = 0.7
	ok.Font = Enum.Font.GothamBold
	ok.TextSize = 13.5
	ok.AutoButtonColor = false
	ok.LayoutOrder = order
	ok.ZIndex = 302
	ok.Parent = card
	UI.corner(ok, 12)
	local og = Instance.new("UIGradient")
	og.Parent = ok
	UI.bind(og, "Color", "grad")

	local closing = false
	local function close()
		if closing then return end
		closing = true
		TweenService:Create(pop, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.85}):Play()
		TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
		task.delay(0.16, function() pcall(function() overlay:Destroy() end) end)
	end
	ok.MouseButton1Click:Connect(close)
	overlay.MouseButton1Click:Connect(close)
end

-- =========================================================================
-- ============ v3.0: NEO WINDOW KIT (หน้าต่างย่อยของเครื่องมือ) ============
-- =========================================================================
UI.windowGrads = {}

function UI.window(guiName, titleText, icon, width)
	local gui = Instance.new("ScreenGui")
	gui.Name = guiName
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 20
	safeParentGui(gui)

	local win = Instance.new("Frame")
	win.Name = "Main"
	win.Size = UDim2.new(0, width, 0, 0)
	win.AutomaticSize = Enum.AutomaticSize.Y
	win.Position = UDim2.new(0.5, -width / 2, 0.22, 0)
	win.BorderSizePixel = 0
	win.Active = true
	win.Parent = gui
	UI.bind(win, "BackgroundColor3", "bg")
	UI.bind(win, "BackgroundTransparency", "T:bg")
	UI.corner(win, 16)

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 255, 255)
	st.Thickness = 1.6
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = win
	local sg2 = Instance.new("UIGradient")
	sg2.Parent = st
	UI.bind(sg2, "Color", "grad")
	table.insert(UI.windowGrads, sg2)

	local wScale = Instance.new("UIScale")
	local baseScale = math.clamp(tonumber(state.uiScale) or 1, 0.6, 1.6)
	wScale.Scale = baseScale * 0.85
	wScale.Parent = win
	TweenService:Create(wScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = baseScale}):Play()

	local wl = Instance.new("UIListLayout")
	wl.SortOrder = Enum.SortOrder.LayoutOrder
	wl.Parent = win

	-- หัวหน้าต่าง
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	header.Active = true
	header.LayoutOrder = 1
	header.Parent = win
	local hb = Instance.new("Frame")
	hb.Size = UDim2.new(0, 32, 0, 32)
	hb.Position = UDim2.new(0, 12, 0.5, -16)
	hb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hb.BorderSizePixel = 0
	hb.Parent = header
	UI.corner(hb, 10)
	local hbg = Instance.new("UIGradient")
	hbg.Rotation = 45
	hbg.Parent = hb
	UI.bind(hbg, "Color", "grad")
	local hi = Instance.new("TextLabel")
	hi.Size = UDim2.new(1, 0, 1, 0)
	hi.BackgroundTransparency = 1
	hi.Text = icon
	hi.TextSize = 16
	hi.Font = Enum.Font.GothamBold
	hi.TextColor3 = Color3.fromRGB(255, 255, 255)
	hi.Parent = hb
	local ht = Instance.new("TextLabel")
	ht.Size = UDim2.new(1, -130, 1, 0)
	ht.Position = UDim2.new(0, 52, 0, 0)
	ht.BackgroundTransparency = 1
	ht.Text = titleText
	ht.Font = Enum.Font.GothamBlack
	ht.TextSize = 14.5
	ht.TextXAlignment = Enum.TextXAlignment.Left
	ht.TextTruncate = Enum.TextTruncate.AtEnd
	ht.Parent = header
	UI.bind(ht, "TextColor3", "text")

	local function hBtn(text, xOff, danger)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 28, 0, 28)
		b.Position = UDim2.new(1, xOff, 0.5, -14)
		b.BorderSizePixel = 0
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.AutoButtonColor = false
		b.Parent = header
		UI.corner(b, "full")
		if danger then
			b.BackgroundColor3 = Color3.fromRGB(235, 65, 85)
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			UI.bind(b, "BackgroundColor3", "surface2")
			UI.bind(b, "TextColor3", "text")
		end
		local sc = Instance.new("UIScale")
		sc.Parent = b
		b.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.08), {Scale = 0.85}):Play() end)
		b.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 1}):Play() end)
		return b
	end
	local minB = hBtn("-", -72, false)
	local closeB = hBtn("X", -38, true)

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -24, 0, 1)
	line.Position = UDim2.new(0, 12, 1, -1)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.Parent = header
	local lg = UI.pSoftGrad(line, 0.1)
	UI.bind(lg, "Color", "grad")

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.LayoutOrder = 2
	content.Parent = win
	local cl = Instance.new("UIListLayout")
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.Padding = UDim.new(0, 8)
	cl.Parent = content
	local cp = Instance.new("UIPadding")
	cp.PaddingTop = UDim.new(0, 10)
	cp.PaddingBottom = UDim.new(0, 14)
	cp.PaddingLeft = UDim.new(0, 12)
	cp.PaddingRight = UDim.new(0, 12)
	cp.Parent = content

	makeDraggable(header, win)

	local minimized = false
	minB.MouseButton1Click:Connect(function()
		minimized = not minimized
		content.Visible = not minimized
		minB.Text = minimized and "+" or "-"
	end)

	local w = {gui = gui, win = win, content = content, header = header}
	function w.close()
		TweenService:Create(wScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = baseScale * 0.85}):Play()
		task.delay(0.14, function() pcall(function() gui:Destroy() end) end)
	end
	closeB.MouseButton1Click:Connect(w.close)
	return w
end

-- ปุ่มใหญ่ 3 สไตล์: primary (ไล่สี) / danger (แดง) / ghost (กระจก)
function UI.button(parent, text, style, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 42)
	b.BorderSizePixel = 0
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13.5
	b.AutoButtonColor = false
	b.ClipsDescendants = true
	b.LayoutOrder = getOrder()
	b.Parent = parent
	UI.corner(b, 12)
	local g = Instance.new("UIGradient")
	g.Parent = b
	local st = Instance.new("UIStroke")
	st.Thickness = 1
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = b
	local sc = Instance.new("UIScale")
	sc.Parent = b

	local curStyle = style
	local function paint()
		if curStyle == "primary" then
			b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			b.BackgroundTransparency = 0
			g.Enabled = true
			g.Color = UI.gradSeq()
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.TextStrokeTransparency = 0.7
			st.Transparency = 1
		elseif curStyle == "danger" then
			b.BackgroundColor3 = Color3.fromRGB(235, 65, 85)
			b.BackgroundTransparency = 0
			g.Enabled = false
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.TextStrokeTransparency = 1
			st.Transparency = 1
		else
			b.BackgroundColor3 = UI.color("surface")
			b.BackgroundTransparency = UI.trans("glass")
			g.Enabled = false
			b.TextColor3 = UI.color("text")
			b.TextStrokeTransparency = 1
			st.Color = UI.color("stroke")
			st.Transparency = 0.3
		end
	end
	paint()
	b:SetAttribute("PPNoTheme", true)
	table.insert(UI.onApply, {owner = b, fn = paint})

	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			UI.ripple(b, input)
			TweenService:Create(sc, TweenInfo.new(0.08), {Scale = 0.95}):Play()
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end
	end)
	if onClick then b.MouseButton1Click:Connect(onClick) end
	local function setStyle(newStyle, newText)
		curStyle = newStyle
		if newText then b.Text = newText end
		paint()
	end
	return b, setStyle
end

-- แถวปุ่มคู่ซ้าย-ขวา
function UI.buttonPair(parent, leftText, leftStyle, leftFn, rightText, rightStyle, rightFn)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundTransparency = 1
	row.LayoutOrder = getOrder()
	row.Parent = parent
	local l1, s1 = UI.button(row, leftText, leftStyle, leftFn)
	l1.Size = UDim2.new(0.5, -4, 1, 0)
	l1.Position = UDim2.new(0, 0, 0, 0)
	local r1, s2 = UI.button(row, rightText, rightStyle, rightFn)
	r1.Size = UDim2.new(0.5, -4, 1, 0)
	r1.Position = UDim2.new(0.5, 4, 0, 0)
	return l1, r1, s1, s2
end

-- แบนเนอร์สถานะ (ไอคอน + ข้อความ)
function UI.banner(parent, icon, text)
	local row = UI.card(parent, 44)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 14, 0.5, -4)
	dot.BorderSizePixel = 0
	dot.Parent = row
	UI.corner(dot, "full")
	UI.bind(dot, "BackgroundColor3", "accent")
	TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}):Play()
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -40, 1, 0)
	l.Position = UDim2.new(0, 30, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = (icon and (icon .. "  ") or "") .. text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = row
	UI.bind(l, "TextColor3", "text")
	return l, row, dot
end

-- แถวกรอกตัวเลข
function UI.inputRow(parent, labelText, default, onChange)
	local row = UI.card(parent, 46)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -110, 1, 0)
	l.Position = UDim2.new(0, 14, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = labelText
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = row
	UI.bind(l, "TextColor3", "text")
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 84, 0, 28)
	box.Position = UDim2.new(1, -96, 0.5, -14)
	box.BorderSizePixel = 0
	box.Text = tostring(default)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 13.5
	box.ClearTextOnFocus = false
	box.Parent = row
	UI.bind(box, "BackgroundColor3", "bg")
	UI.bind(box, "BackgroundTransparency", "T:soft")
	UI.bind(box, "TextColor3", "accent")
	UI.corner(box, "full")
	UI.stroke(box, "stroke", 1, 0.3)
	local last = tostring(default)
	box.FocusLost:Connect(function()
		local v = tonumber(box.Text)
		if v and v > 0 then
			last = box.Text
			onChange(v)
		else
			box.Text = last
		end
	end)
	return box
end

-- รายชื่อผู้เล่นพร้อมรูปโปรไฟล์ + ช่องค้นหา + ระยะทาง
function UI.playerList(parent, gui, listHeight, onSelect)
	local searchRow = UI.card(parent, 40)
	local sb = Instance.new("TextBox")
	sb.Size = UDim2.new(1, -24, 1, 0)
	sb.Position = UDim2.new(0, 12, 0, 0)
	sb.BackgroundTransparency = 1
	sb.PlaceholderText = "🔍  ค้นหาชื่อ หรือ @username..."
	sb.Text = ""
	sb.Font = Enum.Font.GothamMedium
	sb.TextSize = 13
	sb.TextXAlignment = Enum.TextXAlignment.Left
	sb.ClearTextOnFocus = false
	sb.Parent = searchRow
	UI.bind(sb, "TextColor3", "text")
	UI.bind(sb, "PlaceholderColor3", "sub")

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, 0, 0, listHeight)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.LayoutOrder = getOrder()
	list.Parent = parent
	UI.bind(list, "ScrollBarImageColor3", "accent")
	local ll = Instance.new("UIListLayout")
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding = UDim.new(0, 6)
	ll.Parent = list
	local lp = Instance.new("UIPadding")
	lp.PaddingRight = UDim.new(0, 6)
	lp.PaddingTop = UDim.new(0, 1)
	lp.PaddingBottom = UDim.new(0, 1)
	lp.Parent = list

	local selected = nil
	local rows = {}
	local emptyLabel = nil
	local api = {}

	local function paint()
		for p, r in pairs(rows) do
			local sel = (p == selected)
			TweenService:Create(r.row, TweenInfo.new(0.18), {BackgroundColor3 = sel and UI.color("accentSoft") or UI.color("surface")}):Play()
			TweenService:Create(r.stroke, TweenInfo.new(0.18), {Color = sel and UI.accent() or UI.color("stroke"), Transparency = sel and 0 or 0.35}):Play()
			r.check.Visible = sel
		end
	end

	function api.refresh()
		for _, r in pairs(rows) do pcall(function() r.row:Destroy() end) end
		rows = {}
		if emptyLabel then pcall(function() emptyLabel:Destroy() end); emptyLabel = nil end
		local q = string.lower(sb.Text or "")
		local count = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local combined = string.lower((p.DisplayName or p.Name) .. " " .. p.Name)
				if q == "" or string.find(combined, q, 1, true) then
					count = count + 1
					local row, rStroke = UI.card(list, 54)
					local av = Instance.new("ImageLabel")
					av.Size = UDim2.new(0, 38, 0, 38)
					av.Position = UDim2.new(0, 8, 0.5, -19)
					av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=48&h=48"
					av.BorderSizePixel = 0
					av.Parent = row
					UI.bind(av, "BackgroundColor3", "surface2")
					UI.corner(av, "full")
					UI.stroke(av, "accent", 1.5, 0.3)
					local n = Instance.new("TextLabel")
					n.Size = UDim2.new(1, -120, 0, 18)
					n.Position = UDim2.new(0, 54, 0, 9)
					n.BackgroundTransparency = 1
					n.Text = p.DisplayName or p.Name
					n.Font = Enum.Font.GothamBold
					n.TextSize = 13.5
					n.TextXAlignment = Enum.TextXAlignment.Left
					n.TextTruncate = Enum.TextTruncate.AtEnd
					n.Parent = row
					UI.bind(n, "TextColor3", "text")
					local u = Instance.new("TextLabel")
					u.Size = UDim2.new(1, -120, 0, 14)
					u.Position = UDim2.new(0, 54, 0, 28)
					u.BackgroundTransparency = 1
					u.Text = "@" .. p.Name
					u.Font = Enum.Font.GothamMedium
					u.TextSize = 11.5
					u.TextXAlignment = Enum.TextXAlignment.Left
					u.TextTruncate = Enum.TextTruncate.AtEnd
					u.Parent = row
					UI.bind(u, "TextColor3", "sub")
					local d = Instance.new("TextLabel")
					d.Size = UDim2.new(0, 60, 0, 16)
					d.Position = UDim2.new(1, -68, 0.5, -8)
					d.BackgroundTransparency = 1
					d.Text = "-"
					d.Font = Enum.Font.GothamBold
					d.TextSize = 11.5
					d.TextXAlignment = Enum.TextXAlignment.Right
					d.Parent = row
					UI.bind(d, "TextColor3", "accent")
					local check = Instance.new("TextLabel")
					check.Size = UDim2.new(0, 18, 0, 18)
					check.Position = UDim2.new(0, 36, 0, 30)
					check.BackgroundColor3 = Color3.fromRGB(0, 210, 120)
					check.Text = ""
					check.TextColor3 = Color3.fromRGB(255, 255, 255)
					check.Font = Enum.Font.GothamBlack
					check.TextSize = 11
					check.Visible = false
					check.ZIndex = 3
					check:SetAttribute("PPNoTheme", true)
					check.Parent = row
					UI.corner(check, "full")
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, 0, 1, 0)
					btn.BackgroundTransparency = 1
					btn.Text = ""
					btn.ZIndex = 4
					btn.Parent = row
					UI.hookRowFx(row, btn, function()
						selected = p
						paint()
						if onSelect then onSelect(p) end
					end)
					rows[p] = {row = row, stroke = rStroke, dist = d, check = check}
				end
			end
		end
		if count == 0 then
			local e = Instance.new("TextLabel")
			e.Size = UDim2.new(1, 0, 0, 40)
			e.BackgroundTransparency = 1
			e.Text = (q == "") and "ยังไม่มีผู้เล่นคนอื่นในเซิร์ฟ" or "ไม่พบผู้เล่นที่ค้นหา"
			e.Font = Enum.Font.GothamMedium
			e.TextSize = 12.5
			e.Parent = list
			UI.bind(e, "TextColor3", "sub")
			emptyLabel = e
		end
		paint()
	end

	function api.getSelected() return selected end
	function api.setSelected(p)
		selected = p
		paint()
	end

	sb:GetPropertyChangedSignal("Text"):Connect(api.refresh)
	local c1 = Players.PlayerAdded:Connect(function() task.defer(api.refresh) end)
	local c2 = Players.PlayerRemoving:Connect(function(p)
		if p == selected then
			selected = nil
			if onSelect then pcall(onSelect, nil) end
		end
		task.defer(api.refresh)
	end)
	gui.Destroying:Connect(function()
		pcall(function() c1:Disconnect() end)
		pcall(function() c2:Disconnect() end)
	end)
	-- อัปเดตระยะทางทุก 1 วินาที
	task.spawn(function()
		while scriptAlive and gui.Parent do
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			for p, r in pairs(rows) do
				do
					local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if myRoot and tr then
						r.dist.Text = formatStatDiff(math.floor((myRoot.Position - tr.Position).Magnitude)) .. " m"
					else
						r.dist.Text = "-"
					end
				end
			end
			task.wait(1)
		end
	end)
	api.refresh()
	return api
end


-- v3.1: แถวช่องกรอกข้อความ (ใช้เป็นตัวกรองชื่อ)
function UI.filterRow(parent, labelText, defaultText, placeholder, onChange)
	local row = UI.card(parent, 44)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0.44, -14, 1, 0)
	l.Position = UDim2.new(0, 14, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = labelText
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = row
	UI.bind(l, "TextColor3", "text")

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.56, -22, 0, 28)
	box.Position = UDim2.new(0.44, 4, 0.5, -14)
	box.BorderSizePixel = 0
	box.Text = tostring(defaultText or "")
	box.PlaceholderText = placeholder or ""
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.Parent = row
	UI.bind(box, "BackgroundColor3", "bg")
	UI.bind(box, "BackgroundTransparency", "T:soft")
	UI.bind(box, "TextColor3", "accent")
	UI.bind(box, "PlaceholderColor3", "sub")
	UI.corner(box, "full")
	local bs = UI.stroke(box, "stroke", 1, 0.3)
	box.Focused:Connect(function()
		TweenService:Create(bs, TweenInfo.new(0.15), {Color = UI.accent(), Transparency = 0}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(bs, TweenInfo.new(0.15), {Color = UI.color("stroke"), Transparency = 0.3}):Play()
		onChange(box.Text)
	end)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = box
	return box
end

-- v3.1: ตรวจแอดมิน/ทีมงานในเซิร์ฟ
UI.adminWarned = {}
function UI.isLikelyStaff(p)
	local ok, inGroup = pcall(function()
		local creator = game.CreatorType == Enum.CreatorType.Group and game.CreatorId or nil
		if creator then return p:IsInGroup(creator) end
		return false
	end)
	if ok and inGroup then return true, "อยู่ในกลุ่มเจ้าของเกม" end
	if game.CreatorType == Enum.CreatorType.User and p.UserId == game.CreatorId then
		return true, "เจ้าของเกม"
	end
	local n = string.lower(p.Name .. " " .. (p.DisplayName or ""))
	for _, word in ipairs({"admin", "mod ", "moderator", "staff", "owner", "dev "}) do
		if string.find(n, word, 1, true) then return true, "ชื่อมีคำว่า staff/admin" end
	end
	return false
end
function UI.scanAdmins()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and not UI.adminWarned[p.UserId] then
			local isStaff, why = UI.isLikelyStaff(p)
			if isStaff then
				UI.adminWarned[p.UserId] = true
				sendNotification("⚠ พบแอดมิน/ทีมงาน", string.format("%s (%s)", p.DisplayName or p.Name, why), Color3.fromRGB(255, 80, 80))
				if state.adminAutoHop and UI.serverHop then
					task.delay(1, function() pcall(UI.serverHop, "random") end)
				end
			end
		end
	end
end

-- v3.1: Anti-Kick ฝั่งเครื่องเรา (ใช้ได้เฉพาะ executor ที่รองรับ hookmetamethod)
UI.antiKickReady = false
function UI.enableAntiKick()
	if UI.antiKickReady then return true end
	local ok = pcall(function()
		local hook = hookmetamethod
		local check = checkcaller
		if type(hook) ~= "function" or type(check) ~= "function" then error("unsupported") end
		local old
		old = hook(game, "__namecall", function(selfObj, ...)
			local method = getnamecallmethod and getnamecallmethod() or ""
			if not check() and string.lower(tostring(method)) == "kick" and selfObj == player then
				sendNotification("Anti-Kick", "บล็อกการ Kick ไว้แล้ว", Color3.fromRGB(0, 210, 130))
				return nil
			end
			return old(selfObj, ...)
		end)
	end)
	UI.antiKickReady = ok
	if not ok then
		state.antiKick = false
		sendNotification("Anti-Kick", "executor นี้ไม่รองรับ (ต้องมี hookmetamethod)", Color3.fromRGB(255, 80, 80))
	end
	return ok
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

-- v3.1: Click to Delete
addToggleRow(utilPage, "Click Delete (Alt+คลิก / แตะ บนมือถือ)", state.clickDelete, function(_, render)
	state.clickDelete = not state.clickDelete
	render(state.clickDelete)
	UI.applyClickDelete(state.clickDelete)
	if state.clickDelete then
		sendNotification("Click Delete", UserInputService.TouchEnabled and "แตะวัตถุเพื่อลบ (ฝั่งเครื่องเราเท่านั้น)" or "กด Alt ค้างแล้วคลิกวัตถุเพื่อลบ", UI.accent())
	end
end)
addRefinedToolButton(utilPage, "กู้คืนวัตถุที่ลบไปทั้งหมด", "♻", Color3.fromRGB(0, 210, 140), function()
	local n = UI.restoreDeleted()
	sendNotification("Restore", string.format("กู้คืนแล้ว %d ชิ้น", n), UI.accent())
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
-- v3.1: Object / Item ESP
do
	local objBox
	addToggleRow(visualPage, "Object ESP (หาของตามชื่อ)", state.objEsp, function(_, render)
		state.objEsp = not state.objEsp
		render(state.objEsp)
		UI.applyObjectESP(state.objEsp)
		render(state.objEsp)
	end)
	objBox = UI.filterRow(visualPage, "ชื่อของที่จะหา", state.objEspFilter, "เช่น Chest, Coin, Door", function(v)
		state.objEspFilter = v
		if state.objEsp then UI.applyObjectESP(true) end
	end)
end

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
		delBtn.Text = "X"
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

-- =========================================================================
-- ============ v3.1: OBJECT ESP / CLICK-DELETE / CHAT LOG =================
-- =========================================================================
-- ---------- OBJECT ESP ----------
local function removeObjectESP()
	if state._objEspConn then state._objEspConn:Disconnect(); state._objEspConn = nil end
	if state._objEspFolder then pcall(function() state._objEspFolder:Destroy() end); state._objEspFolder = nil end
	state._objEspCache = {}
end

local function applyObjectESP(on)
	removeObjectESP()
	if not on then return end
	if not state.objEspFilter or state.objEspFilter == "" then
		state.objEsp = false
		sendNotification("Object ESP", "ใส่ชื่อของที่ต้องการหาก่อน เช่น Chest", Color3.fromRGB(255, 160, 0))
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Phumipad_ObjectESP"
	safeParentGui(folder)
	state._objEspFolder = folder
	state._objEspCache = {}

	local lastScan = 0
	state._objEspConn = RunService.Heartbeat:Connect(function()
		if not state.objEsp then return end
		local now = os.clock()
		local myChar = player.Character
		local root = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)

		-- สแกนหาวัตถุใหม่ทุก 2 วินาที (ไม่สแกนทุกเฟรม เพื่อไม่ให้กระตุก)
		if now - lastScan > 2 then
			lastScan = now
			local found = 0
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if found > 120 then break end
				if (obj:IsA("BasePart") or obj:IsA("Model")) and UI.nameMatches(obj.Name, state.objEspFilter) then
					local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
					if part and not state._objEspCache[obj] and not Players:GetPlayerFromCharacter(obj) then
						found = found + 1
						local bb = Instance.new("BillboardGui")
						bb.Name = obj.Name .. "_OBJ"
						bb.Adornee = part
						bb.Size = UDim2.new(0, 190, 0, 34)
						bb.StudsOffset = Vector3.new(0, 2.4, 0)
						bb.AlwaysOnTop = true
						bb.LightInfluence = 0
						bb.MaxDistance = 5000
						bb.Parent = folder
						local lb = Instance.new("TextLabel")
						lb.Size = UDim2.new(1, 0, 1, 0)
						lb.BackgroundTransparency = 1
						lb.TextColor3 = Color3.fromRGB(255, 255, 255)
						lb.TextStrokeTransparency = 0
						lb.TextStrokeColor3 = UI.accent()
						lb.Font = Enum.Font.GothamBold
						lb.TextSize = 13
						lb.Text = obj.Name
						lb.Parent = bb
						local hl = Instance.new("Highlight")
						hl.Adornee = obj
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.FillColor = UI.accent()
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.6
						hl.Parent = folder
						state._objEspCache[obj] = {bb = bb, lb = lb, hl = hl, part = part}
					end
				end
			end
		end

		for obj, data in pairs(state._objEspCache) do
			if not obj.Parent or not data.part or not data.part.Parent then
				pcall(function() data.bb:Destroy() end)
				pcall(function() data.hl:Destroy() end)
				state._objEspCache[obj] = nil
			elseif root then
				local d = math.floor((data.part.Position - root.Position).Magnitude)
				data.lb.Text = string.format("%s  [%d m]", obj.Name, d)
				data.lb.TextStrokeColor3 = UI.accent()
				data.hl.FillColor = UI.accent()
			end
		end
	end)
end
UI.applyObjectESP = applyObjectESP
UI.removeObjectESP = removeObjectESP

-- ---------- CLICK TO DELETE ----------
local function applyClickDelete(on)
	if state._delConn then state._delConn:Disconnect(); state._delConn = nil end
	if not on then return end
	state._delConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not state.clickDelete then return end
		local isClick = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		if not isClick then return end
		if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and not UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) and not UserInputService.TouchEnabled then
			return
		end
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local pos = (input.UserInputType == Enum.UserInputType.Touch) and input.Position or UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {player.Character}
		local res = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
		if res and res.Instance then
			local target = res.Instance
			if Players:GetPlayerFromCharacter(target.Parent) then
				sendNotification("Click Delete", "ไม่ลบตัวผู้เล่น", Color3.fromRGB(255, 160, 0))
				return
			end
			table.insert(state.deletedParts, {inst = target, parent = target.Parent})
			target.Parent = nil
			sendNotification("Deleted", target.Name .. "  (กู้คืนได้ในแท็บ Util)", UI.accent())
		end
	end)
end

local function restoreDeleted()
	local n = 0
	for i = #state.deletedParts, 1, -1 do
		local d = state.deletedParts[i]
		if d.inst and d.parent then
			pcall(function() d.inst.Parent = d.parent end)
			n = n + 1
		end
		table.remove(state.deletedParts, i)
	end
	return n
end
UI.applyClickDelete = applyClickDelete
UI.restoreDeleted = restoreDeleted

-- ---------- CHAT LOGGER ----------
local function launchChatLogger()
	local existing = (targetContainer and targetContainer:FindFirstChild("Phumipad_ChatLog")) or playerGui:FindFirstChild("Phumipad_ChatLog")
	if existing then existing.Enabled = not existing.Enabled; return end

	local w = UI.window("Phumipad_ChatLog", "Chat Logger", "💬", 330)
	local count = UI.banner(w.content, nil, string.format("เก็บข้อความไว้ %d รายการ", #state.chatLog))

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, 0, 0, 260)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.LayoutOrder = getOrder()
	list.Parent = w.content
	UI.bind(list, "ScrollBarImageColor3", "accent")
	local ll = Instance.new("UIListLayout")
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding = UDim.new(0, 5)
	ll.Parent = list

	local function redraw()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
		end
		count.Text = string.format("เก็บข้อความไว้ %d รายการ", #state.chatLog)
		local start = math.max(1, #state.chatLog - 80)
		for i = start, #state.chatLog do
			local entry = state.chatLog[i]
			local row = UI.card(list, 0)
			row.Size = UDim2.new(1, -6, 0, 0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			local who = Instance.new("TextLabel")
			who.Size = UDim2.new(1, -20, 0, 16)
			who.Position = UDim2.new(0, 10, 0, 6)
			who.BackgroundTransparency = 1
			who.Text = string.format("[%s]  %s", entry.time, entry.who)
			who.Font = Enum.Font.GothamBold
			who.TextSize = 11.5
			who.TextXAlignment = Enum.TextXAlignment.Left
			who.Parent = row
			UI.bind(who, "TextColor3", "accent")
			local msg = Instance.new("TextLabel")
			msg.Size = UDim2.new(1, -20, 0, 0)
			msg.AutomaticSize = Enum.AutomaticSize.Y
			msg.Position = UDim2.new(0, 10, 0, 23)
			msg.BackgroundTransparency = 1
			msg.Text = entry.msg
			msg.Font = Enum.Font.GothamMedium
			msg.TextSize = 12.5
			msg.TextWrapped = true
			msg.TextXAlignment = Enum.TextXAlignment.Left
			msg.Parent = row
			UI.bind(msg, "TextColor3", "text")
			local pad = Instance.new("UIPadding")
			pad.PaddingBottom = UDim.new(0, 8)
			pad.Parent = row
		end
		task.defer(function()
			list.CanvasPosition = Vector2.new(0, list.AbsoluteCanvasSize.Y)
		end)
	end

	UI.buttonPair(w.content, "รีเฟรช", "ghost", redraw, "ล้างบันทึก", "danger", function()
		state.chatLog = {}
		redraw()
	end)
	UI.button(w.content, "คัดลอกทั้งหมด", "primary", function()
		local parts = {}
		for _, e in ipairs(state.chatLog) do
			table.insert(parts, string.format("[%s] %s: %s", e.time, e.who, e.msg))
		end
		local text = table.concat(parts, "\n")
		if setclipboard then
			setclipboard(text)
			sendNotification("Chat Log", "คัดลอกแชตทั้งหมดแล้ว", UI.accent())
		elseif toclipboard then
			toclipboard(text)
			sendNotification("Chat Log", "คัดลอกแชตทั้งหมดแล้ว", UI.accent())
		end
	end)
	redraw()
end
UI.launchChatLogger = launchChatLogger

-- ============ TOOL WINDOWS (v3.0 Neo Window Kit - เปลี่ยนตามธีม) ==========
-- =========================================================================
local function findToolGui(name)
	local found = (targetContainer and targetContainer:FindFirstChild(name)) or playerGui:FindFirstChild(name)
	if not found then pcall(function() found = CoreGui:FindFirstChild(name) end) end
	return found
end

-- 1. VEHICLE SPEED ADJUST
local function launchVehicleSpeedAdjustScript()
	local existing = findToolGui("UniversalSpeedAdjustGui")
	if existing then existing:Destroy(); return end

	local w = UI.window("UniversalSpeedAdjustGui", "Vehicle Speed Adjust", "🏎️", 290)
	local intens = 350
	local isEnabled = false

	local status = UI.banner(w.content, nil, "นั่งรถก่อน แล้วกด F หรือปุ่มด้านล่าง")
	local box = UI.inputRow(w.content, "แรงผลัก (Impulse)", intens, function(v) intens = v end)
	addPresetChips(w.content, {50, 150, 350, 600, 1000}, function(v)
		intens = v
		box.Text = tostring(v)
	end)

	local toggleBtn, setStyle
	local function toggleState()
		isEnabled = not isEnabled
		if isEnabled then
			setStyle("danger", "หยุดเร่ง  (F)")
			status.Text = "🟢  กำลังเร่งความเร็ว • แรง " .. tostring(intens)
		else
			setStyle("primary", "เริ่มเร่งความเร็ว  (F)")
			status.Text = "นั่งรถก่อน แล้วกด F หรือปุ่มด้านล่าง"
		end
	end
	toggleBtn, setStyle = UI.button(w.content, "เริ่มเร่งความเร็ว  (F)", "primary", toggleState)

	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.F then toggleState() end
	end)
	local stepConnection = RunService.Stepped:Connect(function()
		if isEnabled then
			local subject = Workspace.CurrentCamera and Workspace.CurrentCamera.CameraSubject
			if subject and subject:IsA("Humanoid") then
				if subject.SeatPart then
					subject.SeatPart:ApplyImpulse(subject.SeatPart.CFrame.LookVector * Vector3.new(intens, intens, intens))
				end
			elseif subject and subject:IsA("BasePart") then
				subject:ApplyImpulse(subject.CFrame.LookVector * Vector3.new(intens, intens, intens))
			end
		end
	end)
	w.gui.Destroying:Connect(function()
		isEnabled = false
		pcall(function() stepConnection:Disconnect() end)
		pcall(function() keyConn:Disconnect() end)
	end)
end

-- 2. AUTO CLICKER
local function launchAutoClickerScript()
	local existing = findToolGui("Phumipad_AutoClicker_UI")
	if existing then existing:Destroy(); return end

	local w = UI.window("Phumipad_AutoClicker_UI", "Auto Clicker", "⚡", 290)
	w.gui.IgnoreGuiInset = true

	local marker = Instance.new("Frame")
	marker.Name = "ClickIndicatorMarker"
	marker.Size = UDim2.new(0, 18, 0, 18)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.BackgroundColor3 = UI.accent()
	marker.BackgroundTransparency = 0.2
	marker.BorderSizePixel = 0
	marker.Visible = false
	marker.ZIndex = 100
	marker.Parent = w.gui
	UI.corner(marker, "full")
	local ms = Instance.new("UIStroke")
	ms.Color = Color3.fromRGB(255, 255, 255)
	ms.Thickness = 2
	ms.Parent = marker
	TweenService:Create(marker, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}):Play()

	local isClicking, turboMode, cpsValue, clickPosition, settingPosConn = false, false, 10, nil, nil
	local clickCount = 0

	local status = UI.banner(w.content, nil, "พร้อมใช้งาน • 0 คลิก")
	local cpsBox = UI.inputRow(w.content, "คลิกต่อวินาที (CPS)", cpsValue, function(v) cpsValue = v end)
	addPresetChips(w.content, {5, 10, 20, 50, 100}, function(v)
		cpsValue = v
		cpsBox.Text = tostring(v)
	end)

	local function releaseMouse()
		local pos = clickPosition or UserInputService:GetMouseLocation()
		pcall(function() VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end)
	end
	local function triggerClick(pos)
		local cam = Workspace.CurrentCamera
		local x = pos and pos.X or (cam.ViewportSize.X / 2)
		local y = pos and pos.Y or (cam.ViewportSize.Y / 2)
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
			task.wait(0.001)
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		end)
		clickCount = clickCount + 1
	end

	local posBtn, setPosStyle
	posBtn, setPosStyle = UI.button(w.content, "🎯  ตั้งจุดคลิก  (ตอนนี้: กลางจอ)", "ghost", function()
		if settingPosConn then return end
		setPosStyle("primary", "👆  แตะจุดบนจอที่ต้องการ...")
		task.wait(0.15)
		settingPosConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos = UserInputService:GetMouseLocation()
				local posX = (input.UserInputType == Enum.UserInputType.MouseButton1) and mousePos.X or input.Position.X
				local posY = (input.UserInputType == Enum.UserInputType.MouseButton1) and mousePos.Y or input.Position.Y
				clickPosition = Vector2.new(posX, posY)
				marker.Position = UDim2.new(0, posX, 0, posY)
				marker.Visible = true
				setPosStyle("ghost", string.format("🎯  จุดคลิก: (%d, %d)  • แตะเพื่อเปลี่ยน", posX, posY))
				settingPosConn:Disconnect()
				settingPosConn = nil
			end
		end)
	end)

	addToggleRow(w.content, "🔥 Turbo Mode (คลิกทุกเฟรม)", false, function(_, render)
		turboMode = not turboMode
		render(turboMode)
	end)

	local startBtn, setStartStyle
	local function stopClicking()
		isClicking = false
		releaseMouse()
		setStartStyle("primary", "START AUTO CLICK")
	end
	startBtn, setStartStyle = UI.button(w.content, "START AUTO CLICK", "primary", function()
		if not isClicking then
			isClicking = true
			clickCount = 0
			setStartStyle("danger", "STOP AUTO CLICK")
			task.spawn(function()
				while isClicking and w.gui.Parent do
					triggerClick(clickPosition)
					if turboMode then RunService.RenderStepped:Wait() else task.wait(1 / math.clamp(cpsValue, 0.001, 1000)) end
				end
				releaseMouse()
			end)
			task.spawn(function()
				while isClicking and w.gui.Parent do
					status.Text = string.format("🟢  กำลังคลิก • %s คลิก", formatStatDiff(clickCount))
					task.wait(0.25)
				end
				if w.gui.Parent then
					status.Text = string.format("หยุดแล้ว • รวม %s คลิก", formatStatDiff(clickCount))
				end
			end)
		else
			stopClicking()
		end
	end)

	w.gui.Destroying:Connect(function()
		isClicking = false
		if settingPosConn then pcall(function() settingPosConn:Disconnect() end) end
	end)
end

-- 3. STALKER
local function launchStalkerScript()
	local existing = findToolGui("StalkerUI")
	if existing then existing.Enabled = not existing.Enabled; return end

	local w = UI.window("StalkerUI", "Stalker", "🎯", 300)
	local selectedUser = nil
	local status = UI.banner(w.content, nil, "เป้าหมาย: ยังไม่ได้เลือก")
	UI.playerList(w.content, w.gui, 190, function(p)
		selectedUser = p and p.Name or nil
		if not _G.active then
			status.Text = p and ("เป้าหมาย: " .. (p.DisplayName or p.Name)) or "เป้าหมาย: ยังไม่ได้เลือก"
		end
	end)

	local function stopStalk()
		_G.active = false
		_G.user = ""
		if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end); _G.StalkConnection = nil end
	end

	UI.buttonPair(w.content, "START", "primary", function()
		if not selectedUser then
			sendNotification("Stalker", "เลือกผู้เล่นจากรายชื่อก่อน", Color3.fromRGB(255, 175, 25))
			return
		end
		if _G.StalkConnection then pcall(function() _G.StalkConnection:Disconnect() end); _G.StalkConnection = nil end
		_G.active = true
		_G.user = selectedUser
		status.Text = "🟢  กำลังตาม: " .. selectedUser
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
	end, "STOP", "danger", function()
		stopStalk()
		status.Text = selectedUser and ("หยุดแล้ว • เป้าหมาย: " .. selectedUser) or "เป้าหมาย: ยังไม่ได้เลือก"
	end)

	w.gui.Destroying:Connect(stopStalk)
end

-- 4. PLAYER TELEPORT
local function launchPlayerTeleportScript()
	local existing = findToolGui("TeleportUI")
	if existing then existing.Enabled = not existing.Enabled; return end

	local w = UI.window("TeleportUI", "Player Teleport", "📍", 300)
	local targetPlr = nil
	local status = UI.banner(w.content, nil, "เลือกผู้เล่นแล้วกด Teleport")
	UI.playerList(w.content, w.gui, 210, function(p)
		targetPlr = p
		status.Text = p and ("ปลายทาง: " .. (p.DisplayName or p.Name)) or "เลือกผู้เล่นแล้วกด Teleport"
	end)
	UI.button(w.content, "⚡  TELEPORT ไปหาผู้เล่น", "primary", function()
		if not targetPlr then
			sendNotification("Teleport", "เลือกผู้เล่นจากรายชื่อก่อน", Color3.fromRGB(255, 175, 25))
			return
		end
		local tRoot = targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if tRoot and myRoot then
			myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
			sendNotification("Teleported", "วาร์ปไปหา " .. (targetPlr.DisplayName or targetPlr.Name), UI.accent())
		else
			sendNotification("Teleport", "ผู้เล่นยังไม่เกิด / ไม่มีตัวละคร", Color3.fromRGB(255, 90, 105))
		end
	end)
end

-- 5. SPECTATE PLAYER
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
	local existing = findToolGui("SpectateUI")
	if existing then existing.Enabled = not existing.Enabled; return end

	local w = UI.window("SpectateUI", "Spectate Player", "🎥", 300)
	local selectedTargetPlr = nil
	local isSpectating = false
	local status = UI.banner(w.content, nil, "กำลังดู: ตัวเอง")
	local plist

	local function startSpectatingTarget(targetPlr)
		if not targetPlr then return end
		selectedTargetPlr = targetPlr
		isSpectating = true
		if state._spectateConn then state._spectateConn:Disconnect(); state._spectateConn = nil end
		status.Text = "👁  กำลังส่อง: " .. (targetPlr.DisplayName or targetPlr.Name)
		state._spectateConn = RunService.RenderStepped:Connect(function()
			if not isSpectating or not selectedTargetPlr or not selectedTargetPlr.Parent then
				isSpectating = false
				resetCameraToSelf()
				status.Text = "กำลังดู: ตัวเอง (เป้าหมายออกไปแล้ว)"
				return
			end
			local tHum = selectedTargetPlr.Character and selectedTargetPlr.Character:FindFirstChildOfClass("Humanoid")
			local cam = Workspace.CurrentCamera
			if cam and tHum then cam.CameraSubject = tHum end
		end)
	end

	local function stopSpectate()
		isSpectating = false
		resetCameraToSelf()
		status.Text = "กำลังดู: ตัวเอง"
	end

	plist = UI.playerList(w.content, w.gui, 180, function(p)
		if p then
			startSpectatingTarget(p)
		elseif isSpectating then
			stopSpectate()
		end
	end)

	local function cycle(dir)
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then table.insert(others, p) end
		end
		if #others == 0 then
			sendNotification("Spectate", "ไม่มีผู้เล่นคนอื่นในเซิร์ฟ", Color3.fromRGB(255, 175, 25))
			return
		end
		local idx = 0
		for i, p in ipairs(others) do
			if p == selectedTargetPlr then idx = i end
		end
		idx = ((idx - 1 + dir) % #others) + 1
		plist.setSelected(others[idx])
		startSpectatingTarget(others[idx])
	end

	UI.buttonPair(w.content, "<  ก่อนหน้า", "ghost", function() cycle(-1) end, "ถัดไป  >", "ghost", function() cycle(1) end)
	UI.buttonPair(w.content, "👁  SPECTATE", "primary", function()
		if selectedTargetPlr then
			startSpectatingTarget(selectedTargetPlr)
		else
			sendNotification("Spectate", "เลือกผู้เล่นจากรายชื่อก่อน", Color3.fromRGB(255, 175, 25))
		end
	end, "🔄  STOP / ME", "danger", stopSpectate)

	w.gui.Destroying:Connect(function()
		isSpectating = false
		resetCameraToSelf()
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

-- 11. Chat Logger (v3.1)
addRefinedToolButton(toolsPage, "Chat Logger", "💬", Color3.fromRGB(0, 200, 220), function()
	UI.launchChatLogger()
end)

-- =========================================================================
-- ============ v3.1: CUSTOM SCRIPT BUTTONS (ผู้ใช้เพิ่มเมนูเอง) ===========
-- =========================================================================
do
	local ICONS = {"🚀", "⚡", "🎯", "🔥", "💎", "⭐", "🛠", "🎮", "👁", "🧲", "🗝", "💰",
		"🐾", "🍀", "🧊", "🌙", "☀", "🎲", "🏆", "🔔", "📦", "🧪", "🩸", "🕹"}

	local customHolder = Instance.new("Frame")
	customHolder.Name = "CustomToolsHolder"
	customHolder.Size = UDim2.new(1, 0, 0, 0)
	customHolder.AutomaticSize = Enum.AutomaticSize.Y
	customHolder.BackgroundTransparency = 1
	customHolder.LayoutOrder = getOrder()
	customHolder.Parent = toolsPage
	local chLayout = Instance.new("UIListLayout")
	chLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chLayout.Padding = UDim.new(0, 7)
	chLayout.Parent = customHolder

	local rebuildCustom

	local function runCustom(entry)
		local code = entry.code or ""
		if code == "" then
			sendNotification("Custom Script", "ยังไม่ได้ใส่ลิงก์หรือโค้ด", Color3.fromRGB(255, 160, 0))
			return
		end
		task.spawn(function()
			local ok, err = pcall(function()
				local trimmed = string.match(code, "^%s*(.-)%s*$")
				if string.match(trimmed, "^https?://") then
					-- เป็นลิงก์: ดึงมารันให้อัตโนมัติ
					loadstring(game:HttpGet(trimmed))()
				else
					loadstring(trimmed)()
				end
			end)
			if not ok then
				sendNotification("Custom Script Error", tostring(err), Color3.fromRGB(255, 70, 90))
				warn("[Phumipad Custom]: " .. tostring(err))
			end
		end)
	end

	-- หน้าต่างตั้งค่า (เพิ่ม / แก้ไข)
	local function openEditor(index)
		local entry = index and state.customTools[index] or {name = "", icon = "🚀", code = ""}
		local isNew = index == nil
		local w = UI.window("Phumipad_CustomEditor", isNew and "เพิ่มเมนูของคุณ" or "แก้ไขเมนู", "➕", 330)

		local draftIcon = entry.icon or "🚀"
		local draftName = entry.name or ""
		local draftCode = entry.code or ""

		UI.banner(w.content, nil, "ตั้งชื่อ เลือกไอคอน แล้วใส่ลิงก์สคริปต์")

		local nameBox = UI.filterRow(w.content, "ชื่อเมนู", draftName, "เช่น Infinite Yield", function(v)
			draftName = v
		end)

		local iconLabel = addSectionLabel(w.content, "เลือกไอคอน  •  " .. draftIcon)
		local iconGrid = Instance.new("Frame")
		iconGrid.Size = UDim2.new(1, 0, 0, 0)
		iconGrid.AutomaticSize = Enum.AutomaticSize.Y
		iconGrid.BackgroundTransparency = 1
		iconGrid.LayoutOrder = getOrder()
		iconGrid.Parent = w.content
		local ig = Instance.new("UIGridLayout")
		ig.CellSize = UDim2.new(0, 38, 0, 38)
		ig.CellPadding = UDim2.new(0, 6, 0, 6)
		ig.SortOrder = Enum.SortOrder.LayoutOrder
		ig.Parent = iconGrid

		local iconCells = {}
		local function paintIcons()
			for ic, cell in pairs(iconCells) do
				local sel = (ic == draftIcon)
				cell.btn.BackgroundColor3 = sel and UI.color("accentSoft") or UI.color("surface")
				cell.st.Color = sel and UI.accent() or UI.color("stroke")
				cell.st.Transparency = sel and 0 or 0.45
			end
			iconLabel.Text = "เลือกไอคอน  •  " .. draftIcon
		end
		for i, ic in ipairs(ICONS) do
			local b = Instance.new("TextButton")
			b.Text = ic
			b.TextSize = 18
			b.Font = Enum.Font.GothamBold
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.LayoutOrder = i
			b:SetAttribute("PPNoTheme", true)
			b.Parent = iconGrid
			UI.corner(b, 10)
			local st = Instance.new("UIStroke")
			st.Thickness = 1
			st.Parent = b
			local sc = Instance.new("UIScale")
			sc.Parent = b
			iconCells[ic] = {btn = b, st = st}
			b.MouseButton1Click:Connect(function()
				sc.Scale = 0.8
				TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
				draftIcon = ic
				paintIcons()
			end)
		end
		paintIcons()

		addSectionLabel(w.content, "ลิงก์สคริปต์ หรือโค้ด loadstring")
		local codeCard = UI.card(w.content, 92)
		local codeBox = Instance.new("TextBox")
		codeBox.Size = UDim2.new(1, -20, 1, -16)
		codeBox.Position = UDim2.new(0, 10, 0, 8)
		codeBox.BackgroundTransparency = 1
		codeBox.Text = draftCode
		codeBox.PlaceholderText = "วางลิงก์ raw ได้เลย เช่น https://raw.githubusercontent.com/.../script.lua"
		codeBox.Font = Enum.Font.Code
		codeBox.TextSize = 12
		codeBox.TextXAlignment = Enum.TextXAlignment.Left
		codeBox.TextYAlignment = Enum.TextYAlignment.Top
		codeBox.TextWrapped = true
		codeBox.MultiLine = true
		codeBox.ClearTextOnFocus = false
		codeBox.Parent = codeCard
		UI.bind(codeBox, "TextColor3", "text")
		UI.bind(codeBox, "PlaceholderColor3", "sub")
		codeBox.FocusLost:Connect(function() draftCode = codeBox.Text end)

		UI.button(w.content, "วางจากคลิปบอร์ด", "ghost", function()
			local ok, txt = pcall(function()
				if getclipboard then return getclipboard() end
				if syn and syn.get_clipboard then return syn.get_clipboard() end
				return nil
			end)
			if ok and type(txt) == "string" and txt ~= "" then
				codeBox.Text = txt
				draftCode = txt
				sendNotification("Custom Script", "วางจากคลิปบอร์ดแล้ว", UI.accent())
			else
				sendNotification("Custom Script", "executor นี้อ่านคลิปบอร์ดไม่ได้ ให้วางเองในช่อง", Color3.fromRGB(255, 160, 0))
			end
		end)

		UI.buttonPair(w.content, "บันทึก", "primary", function()
			draftName = nameBox.Text
			draftCode = codeBox.Text
			if string.match(draftName or "", "^%s*$") then
				sendNotification("Custom Script", "ตั้งชื่อเมนูก่อน", Color3.fromRGB(255, 160, 0))
				return
			end
			local data = {name = draftName, icon = draftIcon, code = draftCode}
			if isNew then
				table.insert(state.customTools, data)
			else
				state.customTools[index] = data
			end
			rebuildCustom()
			saveConfig(true)
			w.close()
			sendNotification("Custom Script", "บันทึกเมนู \"" .. draftName .. "\" แล้ว", UI.accent())
		end, isNew and "ยกเลิก" or "ลบเมนูนี้", isNew and "ghost" or "danger", function()
			if not isNew then
				table.remove(state.customTools, index)
				rebuildCustom()
				saveConfig(true)
			end
			w.close()
		end)
	end

	rebuildCustom = function()
		for _, c in ipairs(customHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		for i, entry in ipairs(state.customTools) do
			local row = addRefinedToolButton(customHolder, entry.name, entry.icon or "🚀", UI.accent(), function()
				runCustom(entry)
			end)
			-- ปุ่มแก้ไข (เฟือง) มุมขวา
			local gear = Instance.new("TextButton")
			gear.Size = UDim2.new(0, 26, 0, 26)
			gear.Position = UDim2.new(1, -56, 0.5, -13)
			gear.BackgroundTransparency = 1
			gear.Text = "⚙"
			gear.Font = Enum.Font.GothamBold
			gear.TextSize = 15
			gear.AutoButtonColor = false
			gear.ZIndex = 8
			gear.Parent = row
			UI.bind(gear, "TextColor3", "sub")
			gear.MouseButton1Click:Connect(function() openEditor(i) end)
		end
		adjustPanelHeight(true)
	end

	local addBtn = UI.button(toolsPage, "+   เพิ่มเมนูสคริปต์ของคุณเอง", "primary", function()
		openEditor(nil)
	end)
	addBtn.LayoutOrder = getOrder()
	rebuildCustom()
end


do -- SERVER + SETTINGS TABS (v2.7 FIX: แยก scope ลดจำนวน local ไม่ให้เกินลิมิต 200 ของ Luau)
-- =========================================================================
-- =========================================================================
-- ============ [TAB] AUTOMATION 🤖 (v3.1 Universal Tools) =================
-- =========================================================================
local autoPage = registerTab("auto", "Auto", "🤖", false)

do
	local function nameMatches(objName, filterText)
		if not filterText or filterText == "" then return true end
		local lowered = string.lower(objName)
		for word in string.gmatch(string.lower(filterText), "[^,]+") do
			word = string.match(word, "^%s*(.-)%s*$")
			if word ~= "" and string.find(lowered, word, 1, true) then return true end
		end
		return false
	end
	UI.nameMatches = nameMatches

	local function myRoot()
		local c = player.Character
		return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
	end

	-- ---------- AUTO INTERACT ----------
	addSectionLabel(autoPage, "🤝  AUTO INTERACT  •  กดปุ่มโต้ตอบรอบตัวอัตโนมัติ")
	local interactFilterBox
	local interactCtl = addInputToggleRow(autoPage, "Auto Interact (ระยะ studs)", state.autoInteractRange, state.autoInteract, function(_, render)
		state.autoInteract = not state.autoInteract
		render(state.autoInteract)
		if state.autoInteract then
			sendNotification("Auto Interact", "กำลังกดปุ่มโต้ตอบรอบตัวอัตโนมัติ", UI.accent())
		end
	end, function(v) state.autoInteractRange = math.clamp(v, 1, 500) end)
	addPresetChips(autoPage, {10, 20, 40, 80, 150}, function(v) interactCtl.setVal(v) end)
	interactFilterBox = UI.filterRow(autoPage, "กรองชื่อปุ่ม (เว้นว่าง = ทุกปุ่ม)", state.autoInteractFilter, "เช่น Collect, Claim, Buy", function(v)
		state.autoInteractFilter = v
	end)

	task.spawn(function()
		while scriptAlive do
			if state.autoInteract then
				local root = myRoot()
				if root then
					local range = tonumber(state.autoInteractRange) or 20
					for _, pr in ipairs(Workspace:GetDescendants()) do
						if not state.autoInteract then break end
						if pr:IsA("ProximityPrompt") and pr.Enabled then
							local part = pr.Parent
							if part and part:IsA("BasePart") and (part.Position - root.Position).Magnitude <= range then
								if nameMatches(pr.ObjectText .. " " .. pr.ActionText .. " " .. part.Name, state.autoInteractFilter) then
									pcall(function() fireproximityprompt(pr) end)
								end
							end
						end
					end
				end
			end
			task.wait(math.max(tonumber(state.autoInteractDelay) or 0.35, 0.1))
		end
	end)

	-- ---------- AUTO COLLECT (MAGNET) ----------
	addSectionLabel(autoPage, "🧲  AUTO COLLECT  •  ดูด/เก็บของรอบตัว")
	local collectCtl = addInputToggleRow(autoPage, "Auto Collect (ระยะ studs)", state.autoCollectRange, state.autoCollect, function(_, render)
		state.autoCollect = not state.autoCollect
		render(state.autoCollect)
		if state.autoCollect then
			sendNotification("Auto Collect", "กำลังเก็บของรอบตัวอัตโนมัติ", UI.accent())
		end
	end, function(v) state.autoCollectRange = math.clamp(v, 1, 500) end)
	addPresetChips(autoPage, {15, 30, 60, 100, 200}, function(v) collectCtl.setVal(v) end)
	UI.filterRow(autoPage, "กรองชื่อของ (เว้นว่าง = Tool ทุกชิ้น)", state.autoCollectFilter, "เช่น Coin, Gem, Egg", function(v)
		state.autoCollectFilter = v
	end)
	addToggleRow(autoPage, "ดูดของมาหาตัว (Magnet) แทนการเดินไปเก็บ", state.autoCollectMagnet, function(_, render)
		state.autoCollectMagnet = not state.autoCollectMagnet
		render(state.autoCollectMagnet)
	end)

	task.spawn(function()
		while scriptAlive do
			if state.autoCollect then
				local root = myRoot()
				if root then
					local range = tonumber(state.autoCollectRange) or 30
					local filter = state.autoCollectFilter
					local count = 0
					for _, obj in ipairs(Workspace:GetDescendants()) do
						if not state.autoCollect or count > 60 then break end
						local target = nil
						if obj:IsA("Tool") and obj:FindFirstChildWhichIsA("BasePart") then
							target = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
						elseif filter ~= "" and obj:IsA("BasePart") and obj.CanTouch then
							if nameMatches(obj.Name, filter) then target = obj end
						end
						if target and nameMatches(obj.Name, filter) then
							local d = (target.Position - root.Position).Magnitude
							if d <= range and d > 0.5 then
								count = count + 1
								if state.autoCollectMagnet then
									pcall(function()
										target.CFrame = root.CFrame
										if obj:IsA("Tool") then
											firetouchinterest(target, root, 0)
											firetouchinterest(target, root, 1)
										end
									end)
								else
									pcall(function()
										firetouchinterest(target, root, 0)
										firetouchinterest(target, root, 1)
									end)
								end
							end
						end
					end
				end
			end
			task.wait(math.max(tonumber(state.autoCollectDelay) or 0.4, 0.15))
		end
	end)

	-- ---------- AUTO EQUIP / USE TOOL ----------
	addSectionLabel(autoPage, "⛏️  AUTO TOOL  •  ถือและใช้เครื่องมืออัตโนมัติ")
	addToggleRow(autoPage, "Auto Equip (หยิบเครื่องมือชิ้นแรกมาถือ)", state.autoEquip, function(_, render)
		state.autoEquip = not state.autoEquip
		render(state.autoEquip)
	end)
	local useCtl = addInputToggleRow(autoPage, "Auto Use Tool (ครั้ง/วินาที)", state.autoUseRate, state.autoUseTool, function(_, render)
		state.autoUseTool = not state.autoUseTool
		render(state.autoUseTool)
	end, function(v) state.autoUseRate = math.clamp(v, 0.2, 60) end)
	addPresetChips(autoPage, {1, 3, 5, 10, 20}, function(v) useCtl.setVal(v) end)

	task.spawn(function()
		while scriptAlive do
			if state.autoEquip then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and char and not char:FindFirstChildOfClass("Tool") then
					local bp = player:FindFirstChildOfClass("Backpack")
					local tool = bp and bp:FindFirstChildOfClass("Tool")
					if tool then pcall(function() hum:EquipTool(tool) end) end
				end
			end
			task.wait(0.6)
		end
	end)
	task.spawn(function()
		while scriptAlive do
			if state.autoUseTool then
				local char = player.Character
				local tool = char and char:FindFirstChildOfClass("Tool")
				if tool then pcall(function() tool:Activate() end) end
				task.wait(1 / math.clamp(tonumber(state.autoUseRate) or 3, 0.2, 60))
			else
				task.wait(0.3)
			end
		end
	end)

	-- ---------- WAYPOINT ROUTE ----------
	addSectionLabel(autoPage, "🗺️  WAYPOINT ROUTE  •  วนตามจุดที่บันทึกไว้ในแท็บ Point")
	local routeCtl = addInputToggleRow(autoPage, "Run Route (พักจุดละ ? วิ)", state.routeDelay, state.routeRunning, function(_, render)
		state.routeRunning = not state.routeRunning
		render(state.routeRunning)
		if state.routeRunning then
			sendNotification("Waypoint Route", "เริ่มวนตามจุด Waypoint", UI.accent())
		end
	end, function(v) state.routeDelay = math.clamp(v, 0.2, 600) end)
	addPresetChips(autoPage, {1, 2, 5, 10, 30}, function(v) routeCtl.setVal(v) end)

	task.spawn(function()
		while scriptAlive do
			if state.routeRunning then
				local idx = {}
				for i in pairs(state.savedPositions) do table.insert(idx, i) end
				table.sort(idx)
				if #idx == 0 then
					sendNotification("Waypoint Route", "ยังไม่มีจุดที่บันทึกไว้ในแท็บ Point", Color3.fromRGB(255, 160, 0))
					state.routeRunning = false
				else
					for _, i in ipairs(idx) do
						if not state.routeRunning then break end
						local cf = state.savedPositions[i]
						local root = myRoot()
						if cf and root then root.CFrame = cf end
						task.wait(math.clamp(tonumber(state.routeDelay) or 2, 0.2, 600))
					end
				end
			end
			task.wait(0.3)
		end
	end)

	-- ---------- MACRO RECORDER ----------
	addSectionLabel(autoPage, "🎬  MACRO  •  อัดการเดินแล้วเล่นซ้ำ")
	local macroStatus = UI.banner(autoPage, nil, "ยังไม่มีมาโคร")
	local recConn = nil

	local function updateMacroStatus()
		local n = #state.macroFrames
		if state.macroRecording then
			macroStatus.Text = string.format("🔴  กำลังอัด... %d เฟรม", n)
		elseif state.macroPlaying then
			macroStatus.Text = string.format("กำลังเล่นซ้ำ (%d เฟรม)", n)
		elseif n > 0 then
			macroStatus.Text = string.format("มีมาโคร %d เฟรม (~%.1f วิ)", n, n * 0.1)
		else
			macroStatus.Text = "ยังไม่มีมาโคร"
		end
	end

	local function stopRecord()
		state.macroRecording = false
		if recConn then pcall(function() recConn:Disconnect() end); recConn = nil end
		updateMacroStatus()
	end

	local recBtn, setRecStyle
	recBtn, setRecStyle = UI.button(autoPage, "เริ่มอัดมาโคร", "primary", function()
		if state.macroRecording then
			stopRecord()
			setRecStyle("primary", "เริ่มอัดมาโคร")
			sendNotification("Macro", string.format("อัดเสร็จ %d เฟรม", #state.macroFrames), UI.accent())
		else
			state.macroPlaying = false
			state.macroFrames = {}
			state.macroRecording = true
			setRecStyle("danger", "หยุดอัด")
			task.spawn(function()
				while state.macroRecording and scriptAlive do
					local root = myRoot()
					if root then
						local x, y, z = root.Position.X, root.Position.Y, root.Position.Z
						local _, ry = root.CFrame:ToEulerAnglesYXZ()
						table.insert(state.macroFrames, {x, y, z, ry})
						if #state.macroFrames >= 6000 then
							stopRecord()
							setRecStyle("primary", "เริ่มอัดมาโคร")
							sendNotification("Macro", "อัดครบ 10 นาที หยุดอัตโนมัติ", Color3.fromRGB(255, 160, 0))
						end
					end
					updateMacroStatus()
					task.wait(0.1)
				end
			end)
		end
	end)

	UI.buttonPair(autoPage, "เล่นซ้ำ (Play)", "primary", function()
		if state.macroPlaying then
			state.macroPlaying = false
			updateMacroStatus()
			return
		end
		if #state.macroFrames < 2 then
			sendNotification("Macro", "ยังไม่มีมาโคร กดอัดก่อน", Color3.fromRGB(255, 160, 0))
			return
		end
		stopRecord()
		state.macroPlaying = true
		updateMacroStatus()
		task.spawn(function()
			while state.macroPlaying and scriptAlive do
				for _, fr in ipairs(state.macroFrames) do
					if not state.macroPlaying then break end
					local root = myRoot()
					if root then
						root.CFrame = CFrame.new(fr[1], fr[2], fr[3]) * CFrame.Angles(0, fr[4] or 0, 0)
					end
					task.wait(0.1)
				end
				if not state.macroLoop then state.macroPlaying = false end
			end
			updateMacroStatus()
		end)
	end, "ล้างมาโคร", "ghost", function()
		state.macroPlaying = false
		state.macroFrames = {}
		stopRecord()
		updateMacroStatus()
	end)
	addToggleRow(autoPage, "เล่นซ้ำแบบวนลูป (Loop)", state.macroLoop, function(_, render)
		state.macroLoop = not state.macroLoop
		render(state.macroLoop)
	end)
	updateMacroStatus()

	-- ---------- ADMIN DETECTOR ----------
	addSectionLabel(autoPage, "🛡️  SAFETY")
	addToggleRow(autoPage, "แจ้งเตือนเมื่อมีแอดมิน/ทีมงานเข้าเซิร์ฟ", state.adminDetect, function(_, render)
		state.adminDetect = not state.adminDetect
		render(state.adminDetect)
		if state.adminDetect then UI.scanAdmins() end
	end)
	addToggleRow(autoPage, "ย้ายเซิร์ฟอัตโนมัติเมื่อเจอแอดมิน", state.adminAutoHop, function(_, render)
		state.adminAutoHop = not state.adminAutoHop
		render(state.adminAutoHop)
	end)
	addToggleRow(autoPage, "Anti-Kick (กัน Kick ฝั่งเครื่องเรา)", state.antiKick, function(_, render)
		state.antiKick = not state.antiKick
		render(state.antiKick)
		if state.antiKick then UI.enableAntiKick() end
	end)
end

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
UI.serverHop = serverHop

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

local function addActionButton(parent, text, color, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
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
	local row, rStroke = UI.card(parent, 60)
	table.insert(UI.onApply, {owner = row, fn = function() rStroke.Color = UI.color("stroke") end})

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, -96, 0, 18)
	tl.Position = UDim2.new(0, 14, 0, 7)
	tl.BackgroundTransparency = 1
	tl.Text = titleText
	tl.Font = Enum.Font.GothamMedium
	tl.TextSize = 13
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Parent = row
	UI.bind(tl, "TextColor3", "text")

	local vl = Instance.new("TextLabel")
	vl.Size = UDim2.new(0, 70, 0, 18)
	vl.Position = UDim2.new(1, -84, 0, 7)
	vl.BackgroundTransparency = 1
	vl.Font = Enum.Font.GothamBold
	vl.TextSize = 13
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.Parent = row
	UI.bind(vl, "TextColor3", "accent")

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -32, 0, 8)
	track.Position = UDim2.new(0, 16, 0, 40)
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
	hit.Position = UDim2.new(0, 0, 0, 29)
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
	table.insert(UI.onApply, {owner = row, fn = refresh})
	UI.attachInfo(row, tl, titleText, 96)
	return refresh
end

addSectionLabel(settingsPage, "🎨  ACCENT COLOR  •  สีหลักของ UI")
do
	local swRow = Instance.new("ScrollingFrame")
	swRow.Size = UDim2.new(1, 0, 0, 40)
	swRow.BackgroundTransparency = 1
	swRow.BorderSizePixel = 0
	swRow.ScrollingDirection = Enum.ScrollingDirection.X
	swRow.ScrollBarThickness = 3
	swRow.CanvasSize = UDim2.new(0, 0, 0, 0)
	swRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	swRow.LayoutOrder = getOrder()
	swRow.Parent = settingsPage
	UI.bind(swRow, "ScrollBarImageColor3", "accent")
	local swLayout = Instance.new("UIListLayout")
	swLayout.FillDirection = Enum.FillDirection.Horizontal
	swLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	swLayout.SortOrder = Enum.SortOrder.LayoutOrder
	swLayout.Padding = UDim.new(0, 8)
	swLayout.Parent = swRow
	local swPad = Instance.new("UIPadding")
	swPad.PaddingLeft = UDim.new(0, 4)
	swPad.PaddingRight = UDim.new(0, 4)
	swPad.Parent = swRow

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
		b.Size = UDim2.new(0, 30, 0, 30)
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

addSlider(settingsPage, "🎨 ระดับการผสมสีลงพาแนล (Tint)", 0, 100, function()
	return math.floor((tonumber(state.themeTint) or 0) * 100 + 0.5)
end, function(v)
	state.themeTint = math.clamp(v / 100, 0, 1)
	UI.apply(true)
end, function(v) return string.format("%d%%", math.floor(v + 0.5)) end, false)

local baseLabel = addSectionLabel(settingsPage, "🌓  BASE THEME  •  " .. tostring(state.themeBase))
addPresetChips(settingsPage, UI.BASE_ORDER, function(v)
	state.themeBase = v
	baseLabel.Text = "🌓  BASE THEME  •  " .. v
	UI.apply()
end)

local patternLabel = addSectionLabel(settingsPage, "🔳  PATTERN  •  " .. tostring(state.uiPattern) .. "   (สีฟ้า = เคลื่อนไหว)")
do
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	grid.LayoutOrder = getOrder()
	grid.Parent = settingsPage
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.new(1 / 3, -5, 0, 36)
	gl.CellPadding = UDim2.new(0, 6, 0, 6)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid

	local cells = {}
	local function paintCells()
		for name, c in pairs(cells) do
			local sel = (state.uiPattern == name)
			c.btn.BackgroundColor3 = sel and UI.color("accentSoft") or UI.color("surface")
			c.btn.BackgroundTransparency = sel and 0 or UI.trans("glass")
			c.btn.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or (UI.ANIMATED_PATTERNS[name] and UI.accent() or UI.color("sub"))
			c.stroke.Color = sel and UI.accent() or UI.color("stroke")
			c.stroke.Transparency = sel and 0 or 0.4
		end
	end
	for i, name in ipairs(UI.PATTERNS) do
		local b = Instance.new("TextButton")
		b.BorderSizePixel = 0
		b.Text = name
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11.5
		b.TextTruncate = Enum.TextTruncate.AtEnd
		b.AutoButtonColor = false
		b.LayoutOrder = i
		b:SetAttribute("PPNoTheme", true)
		b.Parent = grid
		UI.corner(b, 10)
		local st = Instance.new("UIStroke")
		st.Thickness = 1
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = b
		local sc = Instance.new("UIScale")
		sc.Parent = b
		cells[name] = {btn = b, stroke = st}
		b.MouseButton1Click:Connect(function()
			sc.Scale = 0.85
			TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			state.uiPattern = name
			patternLabel.Text = "🔳  PATTERN  •  " .. name .. "   (สีฟ้า = เคลื่อนไหว)"
			paintCells()
			UI.buildPattern()
		end)
	end
	paintCells()
	table.insert(UI.onApply, paintCells)
end

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
addToggleRow(settingsPage, "สีรุ้งวิ่ง (Rainbow Accent)", state.themeRainbow, function(_, render)
	state.themeRainbow = not state.themeRainbow
	render(state.themeRainbow)
	if not state.themeRainbow then UI.apply() end
end)
addToggleRow(settingsPage, "ไฟเรืองที่หัวสวิตช์ (Knob Glow)", state.themeKnobGlow, function(_, render)
	state.themeKnobGlow = not state.themeKnobGlow
	render(state.themeKnobGlow)
end)

addActionButton(settingsPage, "⭐ ตั้งธีมนี้เป็นค่าเริ่มต้น (ทุกเกม)", Color3.fromRGB(255, 215, 70), function(b)
	if UI.saveDefaultTheme() then
		sendNotification("Default Theme", "ตั้งธีมนี้เป็นค่าเริ่มต้นของทุกเกมแล้ว", UI.accent())
	else
		sendNotification("Default Theme", "executor ไม่รองรับการบันทึกไฟล์", Color3.fromRGB(255, 80, 80))
	end
end)
addActionButton(settingsPage, "↺ คืนค่าธีมเริ่มต้น (Reset Theme)", Color3.fromRGB(255, 175, 60), function()
	state.themeAccent = {0, 200, 255}
	state.themeBase = "Dark"
	state.uiTransparency = 0.06
	state.uiPattern = "Dots"
	state.themeTint = 0
	state.themePerTab = false
	state.themeRainbow = false
	baseLabel.Text = "🌓  BASE THEME  •  Dark"
	patternLabel.Text = "🔳  PATTERN  •  Dots   (สีฟ้า = เคลื่อนไหว)"
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

-- v3.1: ตรวจความเข้ากันได้ของ Executor
addSectionLabel(settingsPage, "🧪  EXECUTOR COMPATIBILITY")
do
	local checks = {
		{"writefile / readfile", "บันทึกค่าและธีม", function() return type(writefile) == "function" and type(readfile) == "function" end},
		{"game:HttpGet", "Server Hop / สคริปต์ภายนอก", function() local ok = pcall(function() return game.HttpGet end) return ok end},
		{"fireproximityprompt", "Instant / Auto Interact", function() return type(fireproximityprompt) == "function" end},
		{"firetouchinterest", "Auto Collect", function() return type(firetouchinterest) == "function" end},
		{"setfpscap", "จำกัด FPS ตอนประหยัดแบต", function() return type(setfpscap) == "function" end},
		{"hookmetamethod", "Anti-Kick", function() return type(hookmetamethod) == "function" end},
		{"setclipboard", "ปุ่มคัดลอกต่างๆ", function() return type(setclipboard) == "function" or type(toclipboard) == "function" end},
		{"gethui", "ซ่อน UI จากเกม", function() return type(gethui) == "function" end},
	}
	local okCount = 0
	for _, c in ipairs(checks) do
		local pass = false
		pcall(function() pass = c[3]() and true or false end)
		if pass then okCount = okCount + 1 end
		local row = UI.card(settingsPage, 40)
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.Position = UDim2.new(0, 14, 0.5, -5)
		dot.BackgroundColor3 = pass and Color3.fromRGB(0, 220, 130) or Color3.fromRGB(255, 80, 95)
		dot.BorderSizePixel = 0
		dot:SetAttribute("PPNoTheme", true)
		dot.Parent = row
		UI.corner(dot, "full")
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -46, 0, 16)
		l.Position = UDim2.new(0, 32, 0, 5)
		l.BackgroundTransparency = 1
		l.Text = c[1]
		l.Font = Enum.Font.GothamBold
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = row
		UI.bind(l, "TextColor3", pass and "text" or "sub")
		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, -46, 0, 14)
		d.Position = UDim2.new(0, 32, 0, 21)
		d.BackgroundTransparency = 1
		d.Text = (pass and "ใช้ได้ • " or "ไม่รองรับ • ") .. c[2]
		d.Font = Enum.Font.GothamMedium
		d.TextSize = 10.5
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextTruncate = Enum.TextTruncate.AtEnd
		d.Parent = row
		UI.bind(d, "TextColor3", "sub")
	end
	local sum = addSectionLabel(settingsPage, string.format("รองรับ %d / %d อย่าง", okCount, #checks))
	sum.TextSize = 12
end

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
		subTitle.Text = "v3.1 Universal • " .. tostring(state.menuKey)
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

addPatchLogCard("v3.1 PRO", "Latest Update", "NEW", Color3.fromRGB(0, 240, 200), {
	"[NEW] แท็บ 🤖 Auto: Auto Interact, Auto Collect (Magnet), Auto Equip/Use Tool, Waypoint Route, Macro Recorder",
	"[NEW] ปุ่ม '+ เพิ่มเมนูสคริปต์ของคุณเอง' ในแท็บ Tools - ตั้งชื่อ เลือกไอคอน ใส่ลิงก์ loadstring เองได้ ไม่ต้องแก้สคริปต์",
	"[NEW] Object ESP หาของตามชื่อ, Click Delete ลบสิ่งกีดขวาง (กู้คืนได้), Chat Logger, Admin Detector, Anti-Kick",
	"[NEW] ตรวจความเข้ากันได้ของ executor ในแท็บ Set บอกว่าฟีเจอร์ไหนใช้ได้หรือไม่ได้",
	"[NEW] ธีม: แถบสีเลื่อนได้ 22 สี, สไลเดอร์ผสมสีลงพาแนล (Tint), สีรุ้งวิ่ง, ไฟเรืองหัวสวิตช์, ปุ่มตั้งเป็นค่าเริ่มต้นทุกเกม",
	"[UI] ออกแบบหน้า Battery Saver ใหม่ และทำให้การพับ/กางหน้าต่างลื่นขึ้น",
	"[FIX] แก้สัญลักษณ์ที่ขึ้นเป็นสี่เหลี่ยม (ปุ่ม X, ปุ่ม COPY, ปุ่มลบ Waypoint, ไอคอนใน Pattern) และชื่อเกมอ่านชัดขึ้น"
})

addPatchLogCard("v3.0 PRO", "Previous Update", "UPDATE", Color3.fromRGB(0, 195, 255), {
	"[UI] หน้าต่างเครื่องมือทั้ง 5 ออกแบบใหม่ + เปลี่ยนตามธีม: Auto Clicker, Spectate, Stalker, Player Teleport, Vehicle Speed",
	"[UI] รายชื่อผู้เล่นมีรูปโปรไฟล์ ระยะทาง ช่องค้นหา และเครื่องหมายเลือก / Spectate มีปุ่ม ◀ ▶ สลับคน / Auto Clicker นับจำนวนคลิก",
	"[NEW] ลวดลายพื้นหลังเพิ่มเป็น 20 แบบ (เคลื่อนไหว 16 แบบ) เช่น Matrix, Snow, Bubbles, Sakura, Equalizer, Meteor, Orbit",
	"[NEW] ปุ่ม ⓘ ข้างชื่อเมนู แตะเพื่อดูวิธีใช้งานและหลักการทำงานของแต่ละเมนู",
	"[UI] ตัวอักษรชื่อเมนูใหญ่ขึ้น อ่านง่ายขึ้น และหน้าต่างกว้างขึ้นเป็น 330"
})

addPatchLogCard("v2.9 PRO", "Older Update", "UPDATE", Color3.fromRGB(110, 140, 200), {
	"[UI] ออกแบบ Panel ใหม่ทั้งหมดสไตล์ Neo-Glass: การ์ดโค้งมน, ขอบเรืองแสงไล่สีหมุนได้, หัวข้อตัวอักษรเงาวิ่ง",
	"[UI] แท็บแบบ Segmented พร้อมขีดใต้เรืองแสง เลื่อนตามแท็บที่เลือก และหน้าเลื่อนเข้าแบบนุ่ม",
	"[FX] เอฟเฟกต์ระลอกน้ำเมื่อแตะ, สวิตช์ไล่สีพร้อมแถบไฟด้านซ้ายเมื่อเปิด, ปุ่มลัดเด้งได้, หน้าต่างเปิด/ปิดแบบเด้ง",
	"[NEW] Theme Studio ในแท็บ SET: สีหลัก 8 สี + แถบเลือกสีเอง, ความเข้ม-จางพื้นหลัง, Base Theme 5 แบบ",
	"[NEW] Background Pattern 6 แบบ: None / Grid / Dots / Diagonal / Aurora (เคลื่อนไหว) / Stars (กระพริบ)",
	"[UX] แตะได้ทั้งแถวเพื่อเปิด/ปิด (ไม่ต้องเล็งที่สวิตช์) และทุกการตั้งค่าธีมถูกบันทึกอัตโนมัติ"
})

addPatchLogCard("v2.8 PRO", "Older Update", "UPDATE", Color3.fromRGB(110, 140, 200), {
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
	sendNotification("Phumipad Pro v3.1", "เพิ่มแท็บ Auto และปุ่มสคริปต์ของคุณเอง", Color3.fromRGB(0, 225, 255))
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
	if state.objEsp then try(UI.applyObjectESP, true) end
	if state.clickDelete then try(UI.applyClickDelete, true) end
	if state.antiKick then try(UI.enableAntiKick) end
	if state.adminDetect then try(UI.scanAdmins) end
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

-- v2.7: แจ้งเตือนผู้เล่นเข้า/ออก + v3.1 ตรวจแอดมิน
table.insert(globalConns, Players.PlayerAdded:Connect(function(p)
	if state.joinLeaveNotify then
		sendNotification("Player Joined", string.format("%s (@%s)", p.DisplayName, p.Name), Color3.fromRGB(0, 210, 130))
	end
	if state.adminDetect then
		task.delay(1, function() pcall(UI.scanAdmins) end)
	end
end))

-- v3.1: Chat Logger - เก็บข้อความแชตทุกคน (รวมที่ถูกลบภายหลัง)
do
	local function logChat(who, msg)
		if not state.chatLogging then return end
		table.insert(state.chatLog, {time = os.date("%H:%M:%S"), who = who, msg = msg})
		if #state.chatLog > 400 then table.remove(state.chatLog, 1) end
	end
	local function hookPlayerChat(p)
		table.insert(globalConns, p.Chatted:Connect(function(msg)
			logChat(p.DisplayName or p.Name, msg)
		end))
	end
	for _, p in ipairs(Players:GetPlayers()) do pcall(hookPlayerChat, p) end
	table.insert(globalConns, Players.PlayerAdded:Connect(function(p) pcall(hookPlayerChat, p) end))
	-- รองรับ TextChatService ของเกมรุ่นใหม่
	pcall(function()
		local TCS = game:GetService("TextChatService")
		if TCS and TCS.OnIncomingMessage ~= nil then
			table.insert(globalConns, TCS.MessageReceived:Connect(function(m)
				local who = (m.TextSource and Players:GetPlayerByUserId(m.TextSource.UserId)) or nil
				if not who then logChat("System", m.Text or "") end
			end))
		end
	end)
end
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
	if state.objEsp then UI.removeObjectESP() end
	if state._delConn then pcall(function() state._delConn:Disconnect() end) end
	pcall(UI.restoreDeleted) -- คืนวัตถุที่ลบด้วย Click Delete ก่อนปิดสคริปต์
	state.autoInteract = false
	state.autoCollect = false
	state.autoEquip = false
	state.autoUseTool = false
	state.routeRunning = false
	state.macroRecording = false
	state.macroPlaying = false
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
		"Phumipad_Tracers",
		"Phumipad_ObjectESP",
		"Phumipad_ChatLog",
		"Phumipad_CustomEditor"
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

-- ปุ่ม '-': พับเก็บ/กางหน้าต่าง (Collapse/Fold Panel) - v3.1 ลื่นขึ้น
local foldTween = nil
local function toggleFold()
	state.isFolded = not state.isFolded
	if foldTween then foldTween:Cancel() end
	local ti = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	if state.isFolded then
		miniBtn.Text = "+"
		-- ค่อยๆ จางเนื้อหาออกก่อน แล้วย่อ (f มี ClipsDescendants จึงไม่กระตุก)
		TweenService:Create(tabBar, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
		resizeGrip.Visible = false
		foldTween = TweenService:Create(f, ti, {Size = UDim2.new(0, f.Size.X.Offset, 0, 56)})
		foldTween:Play()
		foldTween.Completed:Connect(function()
			if state.isFolded then
				tabBar.Visible = false
				scroll.Visible = false
			end
		end)
	else
		miniBtn.Text = "-"
		tabBar.Visible = true
		scroll.Visible = true
		resizeGrip.Visible = true
		local restoreH = state.savedExpandedHeight or 360
		foldTween = TweenService:Create(f, ti, {Size = UDim2.new(0, f.Size.X.Offset, 0, restoreH)})
		foldTween:Play()
		TweenService:Create(tabBar, TweenInfo.new(0.3), {BackgroundTransparency = UI.trans("glass")}):Play()
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
	if w then
		-- v3.0: ตัวอักษรใหญ่ขึ้น จึงขยายความกว้างขั้นต่ำเป็น 330
		f.Size = UDim2.new(0, math.clamp(math.max(w, 330), 260, 620), 0, f.Size.Y.Offset)
	end
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

