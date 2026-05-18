local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local isCollecting = false
local isScriptActive = true -- Controls the background loop
local myTycoonPlot = nil
local activeButtons = {} 

-- ==============================
-- 1. Create the UI
-- ==============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalAutoCollectUI"
screenGui.Parent = pcall(function() return CoreGui.Name end) and CoreGui or player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 100) -- Slightly wider to fit everything nicely
mainFrame.Position = UDim2.new(0.5, -120, 0.8, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Adds the zooming capability
local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 130, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Universal auto collect"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Added Credits
local credits = Instance.new("TextLabel")
credits.Size = UDim2.new(0, 60, 1, 0)
credits.Position = UDim2.new(0, 130, 0, 0)
credits.BackgroundTransparency = 1
credits.Text = "By Phumipad"
credits.TextColor3 = Color3.fromRGB(150, 150, 150) -- Subtle gray
credits.Font = Enum.Font.Gotham
credits.TextSize = 9
credits.TextXAlignment = Enum.TextXAlignment.Left
credits.Parent = topBar

local foldButton = Instance.new("TextButton")
foldButton.Size = UDim2.new(0, 25, 0, 30)
foldButton.Position = UDim2.new(1, -50, 0, 0)
foldButton.BackgroundTransparency = 1
foldButton.Text = "-"
foldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
foldButton.Font = Enum.Font.GothamBold
foldButton.TextSize = 18
foldButton.Parent = topBar

-- Added Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 25, 0, 30)
closeButton.Position = UDim2.new(1, -25, 0, 0)
closeButton.BackgroundTransparency = 1
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 80, 80) -- Red close button
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = topBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.Text = "Auto Collect: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- ==============================
-- 2. Smart Zone & Reset Logic
-- ==============================
local function resetButtons()
    for _, data in pairs(activeButtons) do
        if data.part and data.part.Parent then
            data.part.CFrame = data.originalCFrame
            data.part.CanCollide = data.originalCanCollide 
        end
    end
    table.clear(activeButtons)
end

local function establishMyPlot()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
            if (obj.Position - myPos).Magnitude < 40 then
                local ancestor = obj
                while ancestor and ancestor.Parent and ancestor.Parent ~= workspace do
                    if ancestor.Parent.Name:lower():match("tycoon") or ancestor.Parent.Name:lower():match("plot") then
                        return ancestor
                    end
                    ancestor = ancestor.Parent
                end
                return ancestor 
            end
        end
    end
    return nil
end

local function updateCollection()
    resetButtons()

    if not isCollecting then return end

    if not myTycoonPlot then
        myTycoonPlot = establishMyPlot()
        if not myTycoonPlot then return end
    end

    for _, obj in pairs(myTycoonPlot:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
            local color = obj.BrickColor.Name:lower()
            local isCash = color:match("green") or color:match("lime")
            local isGem = color:match("pink") or color:match("magenta")

            if isCash or isGem then
                table.insert(activeButtons, {
                    part = obj,
                    originalCFrame = obj.CFrame,
                    originalCanCollide = obj.CanCollide 
                })
                obj.CanCollide = false 
            end
        end
    end
end

-- ==============================
-- 3. UI Interactions (Fold, Close, Zoom)
-- ==============================
local isFolded = false
foldButton.MouseButton1Click:Connect(function()
    isFolded = not isFolded
    if isFolded then
        mainFrame:TweenSize(UDim2.new(0, 240, 0, 30), "Out", "Quad", 0.2, true)
        foldButton.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 240, 0, 100), "Out", "Quad", 0.2, true)
        foldButton.Text = "-"
    end
end)

closeButton.MouseButton1Click:Connect(function()
    isScriptActive = false -- Breaks the while loop
    isCollecting = false
    resetButtons() -- Return buttons to original state
    screenGui:Destroy() -- Delete the UI
end)

toggleBtn.MouseButton1Click:Connect(function()
    isCollecting = not isCollecting
    if isCollecting then
        toggleBtn.Text = "Auto Collect: ON"
        toggleBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        toggleBtn.Text = "Auto Collect: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
    updateCollection()
end)

-- Zoom in and out using Mouse Scroll Wheel
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        -- Zoom by 10% per scroll tick, clamp it between 0.5x (half size) and 2.0x (double size)
        local newScale = uiScale.Scale + (input.Position.Z * 0.1)
        uiScale.Scale = math.clamp(newScale, 0.5, 2.0)
    end
end)

-- ==============================
-- 4. Foot-Level Snapping Loop (3-Second Interval)
-- ==============================
task.spawn(function()
    while isScriptActive do
        task.wait(3)
        
        if isCollecting then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local rootPos = character.HumanoidRootPart.Position
                local footCFrame = CFrame.new(rootPos.X, rootPos.Y - 2.5, rootPos.Z)
                
                for _, data in pairs(activeButtons) do
                    if data.part and data.part.Parent then
                        data.part.CFrame = footCFrame
                    end
                end
            end
        end
    end
end)
