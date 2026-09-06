local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local targetContainer = pcall(function() return CoreGui end) and CoreGui or playerGui

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

local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local hrp       = character:WaitForChild("HumanoidRootPart")

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
	closebutton.Font = Enum.Font.SourceSans
	closebutton.Size = UDim2.new(0, 45, 0, 28)
	closebutton.Text = "X"
	closebutton.TextSize = 30
	closebutton.Position = UDim2.new(0, 0, -1, 27)

	mini.Name = "minimize"
	mini.Parent = Frame
	mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini.Font = Enum.Font.SourceSans
	mini.Size = UDim2.new(0, 45, 0, 28)
	mini.Text = "-"
	mini.TextSize = 40
	mini.Position = UDim2.new(0, 44, -1, 27)

	mini2.Name = "minimize2"
	mini2.Parent = Frame
	mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini2.Font = Enum.Font.SourceSans
	mini2.Size = UDim2.new(0, 45, 0, 28)
	mini2.Text = "+"
	mini2.TextSize = 40
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
	local existing = targetContainer:FindFirstChild("TeleportUI")
	if existing then
		existing:Destroy()
		return
	end

	local teleportTarget = nil

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "TeleportUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = targetContainer

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 250, 0, 300)
	MainFrame.Position = UDim2.new(0.5, -125, 0.4, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.BorderSizePixel = 2
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 30)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -60, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Player Teleport GUI"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 14
	Title.Parent = TopBar

	local MinButton = Instance.new("TextButton")
	MinButton.Size = UDim2.new(0, 30, 0, 30)
	MinButton.Position = UDim2.new(1, -60, 0, 0)
	MinButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	MinButton.BorderSizePixel = 0
	MinButton.Text = "-"
	MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	MinButton.Font = Enum.Font.GothamBold
	MinButton.TextSize = 18
	MinButton.Parent = TopBar

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 30, 0, 30)
	CloseButton.Position = UDim2.new(1, -30, 0, 0)
	CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CloseButton.BorderSizePixel = 0
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 14
	CloseButton.Parent = TopBar

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1, 0, 0, 270)
	ContentFrame.Position = UDim2.new(0, 0, 0, 30)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainFrame

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.new(1, -10, 1, -45)
	ScrollingFrame.Position = UDim2.new(0, 5, 0, 5)
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.Parent = ContentFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = ScrollingFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 2)

	local TPButton = Instance.new("TextButton")
	TPButton.Size = UDim2.new(1, -10, 0, 30)
	TPButton.Position = UDim2.new(0, 5, 1, -35)
	TPButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	TPButton.BorderSizePixel = 0
	TPButton.Text = "Teleport"
	TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPButton.Font = Enum.Font.GothamBold
	TPButton.TextSize = 14
	TPButton.Parent = ContentFrame

	local function updatePlayerList()
		for _, child in pairs(ScrollingFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				local PlayerButton = Instance.new("TextButton")
				PlayerButton.Size = UDim2.new(1, 0, 0, 25)
				PlayerButton.Text = plr.Name
				PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				PlayerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				PlayerButton.Font = Enum.Font.Gotham
				PlayerButton.TextSize = 12
				PlayerButton.Parent = ScrollingFrame

				PlayerButton.MouseButton1Click:Connect(function()
					teleportTarget = plr.Character and (plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso") or plr.Character.PrimaryPart)
					TPButton.Text = "Teleport to: " .. plr.Name
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
			MainFrame:TweenSize(UDim2.new(0, 250, 0, 30), "Out", "Quart", 0.3, true)
		else
			MinButton.Text = "-"
			MainFrame:TweenSize(UDim2.new(0, 250, 0, 300), "Out", "Quart", 0.3, true)
		end
	end)

	local dragging, dragInput, dragStart, startPos
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

-- Full Potato FPS Booster with Clean Restore
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
	state.espFolder.Parent = targetContainer

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

-- ================== BOT ESP SYSTEM (NAME + DISTANCE) ==================
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
		if not usedBotColors[i] then
			table.insert(available, i)
		end
	end
	if #available == 0 then
		usedBotColors = {}
		for i = 1, #botColors do
			table.insert(available, i)
		end
	end
	local index = available[math.random(1, #available)]
	usedBotColors[index] = true
	return botColors[index]
end

local function isPlayerCharacter(model)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character == model then
			return true
		end
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
	if state._botEspConn then
		state._botEspConn:Disconnect()
		state._botEspConn = nil
	end
	if state._botDescConn then
		state._botDescConn:Disconnect()
		state._botDescConn = nil
	end
	for bot, _ in pairs(state.botEspCache) do
		cleanBotESP(bot)
	end
	state.botEspCache = {}
	if state.botEspFolder then
		pcall(function() state.botEspFolder:Destroy() end)
		state.botEspFolder = nil
	end
	usedBotColors = {}
end

local function applyBotESP(on)
	removeBotESP()
	if not on then return end

	state.botEspFolder = Instance.new("Folder")
	state.botEspFolder.Name = "Phumipad_BotESP_Storage"
	state.botEspFolder.Parent = targetContainer

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
			if not parent then
				cleanBotESP(bot)
			end
		end)
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isBot(obj) then
			registerBot(obj)
		end
	end

	state._botDescConn = Workspace.DescendantAdded:Connect(function(obj)
		task.wait(0.1)
		if state.botEsp and isBot(obj) then
			registerBot(obj)
		end
	end)

	-- Render Loop: อัปเดตระยะห่างแบบเรียลไทม์ และตรวจสอบสถานะบอท
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

-- ================== MODERN GRADIENT UI ==================
local sg = Instance.new("ScreenGui")
sg.Name = "PhumipadToolboxMinimalGui"
sg.ResetOnSpawn = false
sg.Parent = playerGui

-- Main Window
local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 260, 0, 435)
f.Position = UDim2.new(0.04, 0, 0.45, -215)
f.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
f.BorderSizePixel = 0
f.Active = true
f.ClipsDescendants = true
f.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = f

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(48, 54, 75)
stroke.Thickness = 1.2
stroke.Parent = f

-- Top-Left Pop-Up Dock Button
local openBtn = Instance.new("TextButton")
openBtn.Name = "TopLeftOpenButton"
openBtn.Size = UDim2.new(0, 105, 0, 32)
openBtn.Position = UDim2.new(0, 12, 0, 52)
openBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
openBtn.BorderSizePixel = 0
openBtn.Text = "⚡ Phumipad"
openBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Visible = false
openBtn.Active = true
openBtn.Parent = sg

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 180, 255)
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
bar.Size = UDim2.new(1, 0, 0, 38)
bar.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = f

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = bar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ Phumipad Toolbox v3.1 beta"
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 24, 0, 24)
miniBtn.Position = UDim2.new(1, -56, 0, 7)
miniBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 56)
miniBtn.BorderSizePixel = 0
miniBtn.Text = "—"
miniBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 12
miniBtn.Parent = bar
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 6)
miniCorner.Parent = miniBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 65)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = bar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

miniBtn.MouseButton1Click:Connect(function()
	f.Visible = false
	openBtn.Position = UDim2.new(0, 12, 0, 52)
	openBtn.Visible = true
end)

-- Scroll Container
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, 0, 1, -38)
scroll.Position = UDim2.new(0, 0, 0, 38)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 175, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = f

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingBottom = UDim.new(0, 14)
scrollPadding.PaddingLeft = UDim.new(0, 10)
scrollPadding.PaddingRight = UDim.new(0, 10)
scrollPadding.Parent = scroll

-- Resize Handle
local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 14, 0, 14)
resizeGrip.Position = UDim2.new(1, -14, 1, -14)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "◢"
resizeGrip.TextColor3 = Color3.fromRGB(90, 100, 130)
resizeGrip.TextSize = 11
resizeGrip.Font = Enum.Font.GothamBold
resizeGrip.ZIndex = 50
resizeGrip.Parent = f

-- Drag Window Logic
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
			local targetW = math.clamp(startSize.X + delta.X, 230, 500)
			local targetH = math.clamp(startSize.Y + delta.Y, 220, 700)
			f.Size = UDim2.new(0, targetW, 0, targetH)
		end
	end)
end

local currentOrder = 0
local function getOrder() currentOrder = currentOrder + 1; return currentOrder end

-- Collapsible Category Component with Smooth Slide Animation
local function addCollapsibleCategory(emoji, name, defaultOpen)
	local catFrame = Instance.new("Frame")
	catFrame.Name = name .. "Category"
	catFrame.Size = UDim2.new(1, 0, 0, 0)
	catFrame.AutomaticSize = Enum.AutomaticSize.Y
	catFrame.BackgroundTransparency = 1
	catFrame.LayoutOrder = getOrder()
	catFrame.Parent = scroll

	local catLayout = Instance.new("UIListLayout")
	catLayout.SortOrder = Enum.SortOrder.LayoutOrder
	catLayout.Padding = UDim.new(0, 3)
	catLayout.Parent = catFrame

	local headerBtn = Instance.new("TextButton")
	headerBtn.Name = "Header"
	headerBtn.Size = UDim2.new(1, 0, 0, 24)
	headerBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
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
	headerPadding.PaddingLeft = UDim.new(0, 8)
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

	local isOpen = (defaultOpen ~= false)

	local function updateHeader()
		local arrow = isOpen and "▾" or "▸"
		headerBtn.Text = string.format("%s  %s %s", arrow, emoji, name:upper())
		headerBtn.TextColor3 = isOpen and Color3.fromRGB(0, 195, 255) or Color3.fromRGB(130, 140, 165)
	end

	local function toggleAccordion()
		isOpen = not isOpen
		updateHeader()

		local targetH = isOpen and contentLayout.AbsoluteContentSize.Y or 0
		local tween = TweenService:Create(clipWrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, targetH)
		})
		tween:Play()
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

	return content
end

local function addActionButton(parent, name, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -6, 1, -6)
	btn.Position = UDim2.new(0, 3, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(33, 38, 54)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(225, 235, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function addToggleRow(parent, name, defaultOn, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -55, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 225, 240)
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
		btn.BackgroundColor3 = v and Color3.fromRGB(0, 195, 125) or Color3.fromRGB(48, 52, 68)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(155, 165, 185)
	end
	render(defaultOn)

	btn.MouseButton1Click:Connect(function()
		onClick(btn, render)
	end)
end

local function addInputToggleRow(parent, name, defaultVal, defaultOn, onToggle, onValChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.48, 0, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(215, 225, 240)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 38, 0, 20)
	box.Position = UDim2.new(1, -94, 0.5, -10)
	box.BackgroundColor3 = Color3.fromRGB(33, 38, 54)
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
		btn.BackgroundColor3 = v and Color3.fromRGB(0, 195, 125) or Color3.fromRGB(48, 52, 68)
		btn.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(155, 165, 185)
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

-- ================== POPULATE CATEGORIES ==================

-- [1] 🏃 MOVEMENT
local movementContent = addCollapsibleCategory("🏃", "Movement", true)

addInputToggleRow(movementContent, "Walk Speed", state.speedValue, state.speedEnabled, function(_, render)
	state.speedEnabled = not state.speedEnabled
	render(state.speedEnabled)
	if humanoid then
		humanoid.WalkSpeed = state.speedEnabled and (tonumber(state.speedValue) or 16) or state.baseWalkSpeed
	end
end, function(val)
	state.speedValue = val
	if state.speedEnabled and humanoid then humanoid.WalkSpeed = val end
end)

addInputToggleRow(movementContent, "TP Walk", state.tpWalkSpeed, state.tpWalkEnabled, function(_, render)
	state.tpWalkEnabled = not state.tpWalkEnabled
	render(state.tpWalkEnabled)
	applyTPWalk(state.tpWalkEnabled)
end, function(val)
	state.tpWalkSpeed = val
end)

-- [2] 🛠️ MORE TOOLS
local toolsContent = addCollapsibleCategory("🛠️", "More Tools", true)

addActionButton(toolsContent, "🎯 Aiming", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/DanielHubll/DanielHubll/refs/heads/main/Aimbot%20Mobile"))()
	end)
end)

addActionButton(toolsContent, "🕊️ Open Fly GUI (V3)", function()
	launchFlyScript()
end)

addActionButton(toolsContent, "⏱️ Anti AFK", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
	end)
end)

addActionButton(toolsContent, "👥 Player Teleport", function()
	launchPlayerTeleportScript()
end)

-- [3] 🧰 UTILITIES
local utilitiesContent = addCollapsibleCategory("🧰", "Utilities", true)

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

addToggleRow(utilitiesContent, "Full Bright", state.fullBright, function(_, render)
	state.fullBright = not state.fullBright
	render(state.fullBright)
	applyFullBright(state.fullBright)
end)

-- [4] 👁️ VISUAL (รวม Player ESP, Bot ESP + Distance และ FPS Booster)
local visualContent = addCollapsibleCategory("👁️", "Visual", true)

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

addToggleRow(visualContent, "FPS Booster (potato)", state.fpsBooster, function(_, render)
	state.fpsBooster = not state.fpsBooster
	render(state.fpsBooster)
	applyFPSBooster(state.fpsBooster)
end)

-- [5] 📍 WAYPOINTS
local waypointsContent = addCollapsibleCategory("📍", "Waypoints", true)

local spotGrid = Instance.new("Frame")
spotGrid.Size = UDim2.new(1, 0, 0, 26)
spotGrid.BackgroundTransparency = 1
spotGrid.LayoutOrder = getOrder()
spotGrid.Parent = waypointsContent

local clearGrid = Instance.new("Frame")
clearGrid.Size = UDim2.new(1, 0, 0, 24)
clearGrid.BackgroundTransparency = 1
clearGrid.LayoutOrder = getOrder()
clearGrid.Parent = waypointsContent

local spotButtons = {}

local function resetSpotUI(slot)
	state["savedPosition" .. slot] = nil
	if spotButtons[slot] then
		spotButtons[slot].Text = "📍 Spot " .. slot
		spotButtons[slot].BackgroundColor3 = Color3.fromRGB(33, 38, 54)
	end
end

local function makeGridSpotBtn(slot, posX, sizeX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(sizeX, -4, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(33, 38, 54)
	btn.BorderSizePixel = 0
	btn.Text = "📍 Spot " .. slot
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
				btn.Text = "🚀 Go " .. slot
				btn.BackgroundColor3 = Color3.fromRGB(0, 195, 125)
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
	btn.Text = "🗑️ Clear " .. slot
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
