local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local guiName = "CurrentGameInfoUI"
local gameNameText = "กำลังโหลดข้อมูล..." -- ตัวแปรสำหรับเก็บชื่อเกมไว้รอตอนกด Copy

-- เลือกตำแหน่งวาง UI (ซ่อนจากเกม)
local targetGui = (gethui and gethui()) or game:GetService("CoreGui")
if not targetGui then
	targetGui = player:WaitForChild("PlayerGui")
end

-- ลบ UI เก่าทิ้ง
if targetGui:FindFirstChild(guiName) then
	targetGui[guiName]:Destroy()
end

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = targetGui

-- สร้างกรอบหน้าต่างหลัก (Frame) ปรับขนาดให้เล็กกะทัดรัดลง
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 65) 
mainFrame.Position = UDim2.new(0.5, -110, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = mainFrame

-- ปุ่มปิด (X) ขยับและย่อขนาดให้พอดีมุมขวาบน
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- ข้อความบอกชื่อเกม
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -30, 0, 35)
infoLabel.Position = UDim2.new(0, 10, 0, 5)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "กำลังโหลด..."
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Font = Enum.Font.GothamMedium
infoLabel.TextSize = 13
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextWrapped = true
infoLabel.Parent = mainFrame

-- สร้างปุ่ม Copy (มุมขวาล่าง)
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 50, 0, 20)
copyBtn.Position = UDim2.new(1, -55, 1, -25) -- ตั้งให้อยู่มุมขวาล่าง
copyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
copyBtn.Text = "Copy"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.Parent = mainFrame

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 4)
copyCorner.Parent = copyBtn

-- ฟังก์ชันดึงข้อมูลชื่อเกม
local function updateGameName()
	if placeId > 0 then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(placeId)
		end)
		
		if success and info then
			gameNameText = info.Name
		else
			gameNameText = "Place ID: " .. tostring(placeId)
		end
		infoLabel.Text = "กำลังเล่น:\n" .. gameNameText
	end
end

-- รันการดึงข้อมูล
task.spawn(updateGameName)

-- โค้ดเมื่อกดปุ่มปิด (X)
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- โค้ดเมื่อกดปุ่ม Copy
copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(gameNameText) -- ก๊อปปี้ชื่อเกมลง Clipboard ของ Windows/มือถือ
		
		-- เปลี่ยนข้อความชั่วคราวให้รู้ว่าก๊อปปี้แล้ว
		copyBtn.Text = "Copied!"
		copyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- เปลี่ยนเป็นสีเขียว
		task.wait(1.5)
		copyBtn.Text = "Copy"
		copyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220) -- กลับมาเป็นสีฟ้า
	else
		-- กรณี Executor ไม่รองรับ setclipboard
		copyBtn.Text = "Error"
		copyBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	end
end)
