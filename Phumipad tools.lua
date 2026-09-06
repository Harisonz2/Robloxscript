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

	-- Speed & Movement
	speedEnabled = false,
	speedValue = 16,
	baseWalkSpeed = 16,

	tpWalkEnabled = false,
	tpWalkSpeed = 1,

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
	local targetContainer = pcall(function() return CoreGui end) and CoreGui or playerGui
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
					teleportTarget = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
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
				if fx:IsA("PostEffect") then fx.Enabled = true end
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

-- ================== ADVANCED PLAYER ESP SYSTEM ==================
local function isTeammate(plr)
	if not player.Team or not plr.Team then
		return false
	end
	return player.Team == plr.Team
end

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

local function createESP(plr)
	if plr == player then return end

	local function addESPToChar(char)
		pcall(function()
			if char:FindFirstChild("DracoESPHighlight") then return end

			local root = char:WaitForChild("HumanoidRootPart", 5)
			local head = char:WaitForChild("Head", 5)
			if not root or not head then return end

			local isAlly = isTeammate(plr)
			local teamCol = isAlly and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(255, 35, 35)

			-- Highlight: เรนเดอร์ทะลุกำแพงเฉพาะเมื่ออยู่นอกสายตา
			local hl = Instance.new("Highlight")
			hl.Name = "DracoESPHighlight"
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillColor = teamCol
			hl.FillTransparency = 0.35
			hl.OutlineColor = teamCol
			hl.OutlineTransparency = 0
			hl.Enabled = false
			hl.Adornee = char
			hl.Parent = char

			-- BillboardGui: ยกสูงจากศีรษะ 4.2 Studs เพื่อไม่ให้บังตัวละคร
			local bb = Instance.new("BillboardGui")
			bb.Name = "DracoESPName"
			bb.Adornee = head
			bb.Size = UDim2.new(0, 260, 0, 52)
			bb.StudsOffset = Vector3.new(0, 4.2, 0)
			bb.AlwaysOnTop = true
			bb.LightInfluence = 0
			bb.MaxDistance = 10000
			bb.Parent = head

			-- ป้ายชื่อ + ระยะห่าง (ตัวอักษรสีขาว ขอบ Stroke สีแดงหนาชัดเจน)
			local label = Instance.new("TextLabel")
			label.Name = "ESPLabel"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = plr.DisplayName or plr.Name
			label.TextColor3 = Color3.fromRGB(255, 255, 255) -- อักษรสีขาว
			label.TextStrokeTransparency = 0 -- ขอบทึบชัดเจน
			label.TextStrokeColor3 = isAlly and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(255, 25, 25) -- ขอบสีแดง (ทีมตัวเองขอบฟ้า)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 16 -- ขนาดตัวอักษรใหญ่ชัดเจน
			label.Parent = bb
		end)
	end

	if plr.Character then addESPToChar(plr.Character) end
	local charConn = plr.CharacterAdded:Connect(function(char)
		if state.esp then addESPToChar(char) end
	end)
	table.insert(state._espConns, charConn)
end

local function removeESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			pcall(function()
				local hl = plr.Character:FindFirstChild("DracoESPHighlight")
				if hl then hl:Destroy() end

				local head = plr.Character:FindFirstChild("Head")
				if head then
					local bb = head:FindFirstChild("DracoESPName")
					if bb then bb:Destroy() end
				end
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

		-- Render Loop: Raycast อัปเดตการแสดงผลและคำนวณระยะห่าง
		table.insert(state._espConns, RunService.RenderStepped:Connect(function()
			if not state.esp then return end
			local myChar = player.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player and plr.Character then
					local root = plr.Character:FindFirstChild("HumanoidRootPart")
					local head = plr.Character:FindFirstChild("Head")
					local targetPart = head or root
					local isAlly = isTeammate(plr)
					local strokeCol = isAlly and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(255, 25, 25)

					-- เช็คกำแพงบัง
					local occluded = isPlayerOccluded(plr.Character, targetPart)

					local hl = plr.Character:FindFirstChild("DracoESPHighlight")
					if hl then
						hl.FillColor = strokeCol
						hl.OutlineColor = strokeCol
						hl.Enabled = occluded
					end

					if head then
						local bb = head:FindFirstChild("DracoESPName")
						if bb then
							local label = bb:FindFirstChild("ESPLabel")
							if label then
								label.TextColor3 = Color3.fromRGB(255, 255, 255)
								label.TextStrokeColor3 = strokeCol
								if myHrp and root then
									local dist = math.floor((myHrp.Position - root.Position).Magnitude)
									label.Text = string.format("%s\n[%d studs]", plr.DisplayName or plr.Name, dist)
								else
									label.Text = plr.DisplayName or plr.Name
								end
							end
						end
					end
				end
			end
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

-- ================== MODERN MINIMAL UI (ItsDraco) ==================
local sg = Instance.new("ScreenGui")
sg.Name = "ItsDracoMinimalToolbox"
sg.ResetOnSpawn = false
sg.Parent = playerGui

-- Main Window
local f = Instance.new("Frame")
f.Name = "MainFrame"
f.Size = UDim2.new(0, 250, 0, 420)
f.Position = UDim2.new(0.04, 0, 0.45, -210)
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

-- Floating Dock Button
local openBtn = Instance.new("TextButton")
openBtn.Name = "SideOpenButton"
openBtn.Size = UDim2.new(0, 95, 0, 32)
openBtn.Position = UDim2.new(0, 10, 0.5, -16)
openBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
openBtn.BorderSizePixel = 0
openBtn.Text = "⚡ ItsDraco"
openBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Visible = false
openBtn.Active = true
openBtn.Parent = sg

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(50, 55, 75)
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
title.Text = "ItsDraco  •  v3.1"
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

miniBtn.MouseButton1Click:Connect(function()
	f.Visible = false
	openBtn.Visible = true
end)

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

-- Resize Handle
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

-- UI Generators
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

local function addActionButton(name, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 25, 33)
	row.BorderSizePixel = 0
	row.LayoutOrder = getOrder()
	row.Parent = scroll

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 1, -6)
	btn.Position = UDim2.new(0, 4, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(220, 225, 235)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = row

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(onClick)
	return btn
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

addActionButton("🕊️ Open Fly GUI (V3)", function()
	launchFlyScript()
end)

addActionButton("⏱️ Anti AFK", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
	end)
end)

addActionButton("👥 Player Teleport", function()
	launchPlayerTeleportScript()
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

-- [3] Save Spots & Clear Buttons
addCategory("Waypoints")

local spotGrid = Instance.new("Frame")
spotGrid.Size = UDim2.new(1, 0, 0, 26)
spotGrid.BackgroundTransparency = 1
spotGrid.LayoutOrder = getOrder()
spotGrid.Parent = scroll

local clearGrid = Instance.new("Frame")
clearGrid.Size = UDim2.new(1, 0, 0, 24)
clearGrid.BackgroundTransparency = 1
clearGrid.LayoutOrder = getOrder()
clearGrid.Parent = scroll

local spotButtons = {}

local function resetSpotUI(slot)
	state["savedPosition" .. slot] = nil
	if spotButtons[slot] then
		spotButtons[slot].Text = "📍 Spot " .. slot
		spotButtons[slot].BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	end
end

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
				btn.BackgroundColor3 = Color3.fromRGB(46, 175, 100)
			end
		end
	end)
end

local function makeGridClearBtn(slot, posX, sizeX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(sizeX, -4, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(160, 40, 45)
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
