local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local isCollecting = false
local myTycoonPlot = nil
local activeButtons = {} -- Stores part, original CFrame, and original collision state

-- ==============================
-- 1. Create the UI
-- ==============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalAutoCollectUI"
screenGui.Parent = pcall(function() return CoreGui.Name end) and CoreGui or player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0.5, -110, 0.8, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Universal auto collect"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local foldButton = Instance.new("TextButton")
foldButton.Size = UDim2.new(0, 30, 0, 30)
foldButton.Position = UDim2.new(1, -30, 0, 0)
foldButton.BackgroundTransparency = 1
foldButton.Text = "-"
foldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
foldButton.Font = Enum.Font.GothamBold
foldButton.TextSize = 18
foldButton.Parent = topBar

-- Single Toggle Button for Both
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

-- Returns buttons to their original spots and restores collision
local function resetButtons()
    for _, data in pairs(activeButtons) do
        if data.part and data.part.Parent then
            data.part.CFrame = data.originalCFrame
            data.part.CanCollide = data.originalCanCollide 
        end
    end
    table.clear(activeButtons)
end

-- Identifies your plot by finding the highest grouping folder you are standing in
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
    resetButtons() -- Always reset old buttons before scanning for new ones

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

            -- If it is Cash OR a Gem, collect it
            if isCash or isGem then
                table.insert(activeButtons, {
                    part = obj,
                    originalCFrame = obj.CFrame,
                    originalCanCollide = obj.CanCollide 
                })
                
                -- Turn off collision so the player doesn't float
                obj.CanCollide = false 
            end
        end
    end
end

-- ==============================
-- 3. UI Interactions
-- ==============================
local isFolded = false
foldButton.MouseButton1Click:Connect(function()
    isFolded = not isFolded
    if isFolded then
        mainFrame:TweenSize(UDim2.new(0, 220, 0, 30), "Out", "Quad", 0.2, true)
        foldButton.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 220, 0, 100), "Out", "Quad", 0.2, true)
        foldButton.Text = "-"
    end
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

-- ==============================
-- 4. Foot-Level Snapping Loop (3-Second Interval)
-- ==============================
task.spawn(function()
    while true do
        -- Loops exactly every 3 seconds
        task.wait(3)
        
        if isCollecting then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local rootPos = character.HumanoidRootPart.Position
                local footCFrame = CFrame.new(rootPos.X, rootPos.Y - 2.5, rootPos.Z)
                
                for _, data in pairs(activeButtons) do
                    if data.part and data.part.Parent then
                        -- Snap to feet every 3 seconds
                        data.part.CFrame = footCFrame
                    end
                end
            end
        end
    end
end)
