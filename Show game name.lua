local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local guiName = "CurrentGameInfoUI"

-- เลือกตำแหน่งวาง UI (ใช้ gethui() หรือ CoreGui เพื่อซ่อน UI จากเกม, ถ้าไม่มีให้ไปใส่ใน PlayerGui)
local targetGui = (gethui and gethui()) or game:GetService("CoreGui")
if not targetGui then
	targetGui = player:WaitForChild("PlayerGui")
end

-- ลบ UI เก่าทิ้งถ้ามีการกดรันซ้ำ
if targetGui:FindFirstChild(guiName) then
	targetGui[guiName]:Destroy()
end

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = targetGui

-- สร้างกรอบหน้าต่างหลัก (Frame)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 80)
mainFrame.Position = UDim2.new(0.5, -125, 0.1, 0) -- ไว้ด้านบนตรงกลาง เพื่อไม่ให้บัง UI หลักของเกม
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- ทำให้สามารถใช้เมาส์ลากหน้าต่างย้ายไปมาได้
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- สร้างปุ่มปิด (Close Button)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- สร้างข้อความบอกชื่อเกม (TextLabel)
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -50, 1, 0)
infoLabel.Position = UDim2.new(0, 10, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "กำลังโหลดชื่อเกม..."
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Font = Enum.Font.GothamMedium
infoLabel.TextSize = 14
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextWrapped = true
infoLabel.Parent = mainFrame

-- ฟังก์ชันดึงข้อมูลชื่อเกม
local function updateGameName()
	if placeId > 0 then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(placeId)
		end)
		
		if success and info then
			infoLabel.Text = "กำลังเล่น:\n" .. info.Name
		else
			infoLabel.Text = "กำลังเล่น:\nPlace ID " .. tostring(placeId)
		end
	end
end

-- เรียกใช้ฟังก์ชันดึงชื่อแบบไม่ให้สคริปต์ค้าง (spawn)
task.spawn(updateGameName)

-- ฟังก์ชันปิดหน้าต่าง
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)
