-- ============================================================================================
-- SCRIPT: TỔNG HỢP HỆ THỐNG BLOX FRUITS (MODERN UI EDITION 2026)
-- TÍNH NĂNG: FAST ATTACK M1 + INFINITE STAMINA + HITBOX BODY + CFRAME SPEED (MAX 40)
-- GIAO DIỆN: CHỮ TO, DỄ NHÌN, PHONG CÁCH NEON DARK
-- ============================================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local function ExecuteGalaxyIntro()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "IntroSystem"
    IntroGui.DisplayOrder = 999
    IntroGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BorderSizePixel = 0
    Background.Parent = IntroGui
    
    local MainTitle = Instance.new("TextLabel")
    MainTitle.Size = UDim2.new(1, 0, 0, 150)
    MainTitle.Position = UDim2.new(0, 0, 0.5, -75)
    MainTitle.BackgroundTransparency = 1
    MainTitle.Text = "THÀNH_ĐB"
    MainTitle.Font = Enum.Font.GothamBold
    MainTitle.TextSize = 120
    MainTitle.TextTransparency = 1
    MainTitle.Parent = Background
    
    task.spawn(function()
        local Hue = 0
        local TweenIn = TweenService:Create(MainTitle, TweenInfo.new(2, Enum.EasingStyle.Quart), {TextTransparency = 0})
        TweenIn:Play()
        
        local RainbowEffect = RunService.RenderStepped:Connect(function() 
            Hue = (Hue + 0.005) % 1
            MainTitle.TextColor3 = Color3.fromHSV(Hue, 0.8, 1) 
        end)
        
        task.wait(4)
        
        local TweenOutBg = TweenService:Create(Background, TweenInfo.new(1.5), {BackgroundTransparency = 1})
        local TweenOutTxt = TweenService:Create(MainTitle, TweenInfo.new(1.5), {TextTransparency = 1})
        TweenOutBg:Play()
        TweenOutTxt:Play()
        
        task.wait(1.5)
        RainbowEffect:Disconnect()
        IntroGui:Destroy()
    end)
end
ExecuteGalaxyIntro()
-- [[ BIẾN CẤU HÌNH ]]
_G.CFrameSpeedValue = 0 
_G.IsActive = true
local Enabled = false              
local HitboxEnabled = false        
local HitboxSize = 0               
local CurrentTargetName = "None"   
local OriginalBodySizes = {}

-- Remote Paths
local NetFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = NetFolder:WaitForChild("RE/RegisterAttack")
local RegisterHit = NetFolder:WaitForChild("RE/RegisterHit")

-- --------------------------------------------------------------------------------------------
-- [[ CÁC HÀM LOGIC - GIỮ NGUYÊN ]]
-- --------------------------------------------------------------------------------------------

local function ApplyInfiniteStaminaLogic()
    local character = Player.Character
    if character then
        local energy = character:FindFirstChild("Energy") or character:FindFirstChild("Stamina")
        if energy then
            local max = energy:FindFirstChild("MaxValue") or energy:FindFirstChild("MaxEnergy")
            energy.Value = max and max.Value or 10000
        end
    end
end

local function IsSameTeam(targetPlayer)
    if not targetPlayer or not targetPlayer.Team or not Player.Team then return false end
    if Player.Team.Name == "Marines" and targetPlayer.Team.Name == "Marines" then return true end
    if Player.Team.Name == "Pirates" and targetPlayer.Team.Name == "Pirates" then
        if targetPlayer.Name == Player.Name then return true end
        local isAlly = false
        pcall(function()
            if Player:IsFriendsWith(targetPlayer.UserId) then isAlly = true end
            local myCrew = Player:FindFirstChild("Crew")
            local tCrew = targetPlayer:FindFirstChild("Crew")
            if myCrew and tCrew and myCrew.Value ~= "" and myCrew.Value == tCrew.Value then isAlly = true end
        end)
        return isAlly
    end
    return false
end

local function IsEquippedMeleeOrSword()
    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword")
end

local function GetNearestEnemyInRange()
    local closestPart, closestDist, foundName = nil, 400, "None"
    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, 0, "None" end

    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, enemy in pairs(enemies:GetChildren()) do
            local eRoot = enemy:FindFirstChild("HumanoidRootPart")
            if eRoot and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                local dist = (eRoot.Position - myRoot.Position).Magnitude
                if dist < closestDist then closestDist, closestPart, foundName = dist, eRoot, enemy.Name end
            end
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 and not IsSameTeam(p) then
                local dist = (pRoot.Position - myRoot.Position).Magnitude
                if dist < closestDist then closestDist, closestPart, foundName = dist, pRoot, p.DisplayName or p.Name end
            end
        end
    end
    return closestPart, closestDist, foundName
end

-- --------------------------------------------------------------------------------------------
-- [[ GIAO DIỆN NGƯỜI DÙNG (MODERN UI) ]]
-- --------------------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeonHub_2026"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.35, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 580) -- Rộng hơn để chữ to hơn
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Parent = MainFrame

-- Tiêu đề (To, Đậm)
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.Text = "THANH_DB4800____HUB"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 15)
TitleCorner.Parent = Title

-- Nhãn Hiển Thị Target (Nổi bật)
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Parent = MainFrame
TargetLabel.Position = UDim2.new(0.05, 0, 0, 75)
TargetLabel.Size = UDim2.new(0.9, 0, 0, 50)
TargetLabel.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
TargetLabel.TextSize = 18
TargetLabel.Font = Enum.Font.GothamBold

local TargetCorner = Instance.new("UICorner")
TargetCorner.Parent = TargetLabel

-- Nút Fast Attack
local AttackBtn = Instance.new("TextButton")
AttackBtn.Parent = MainFrame
AttackBtn.Position = UDim2.new(0.05, 0, 0, 140)
AttackBtn.Size = UDim2.new(0.9, 0, 0, 50)
AttackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
AttackBtn.Text = "FAST ATTACK: OFF (G)"
AttackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AttackBtn.TextSize = 18
AttackBtn.Font = Enum.Font.GothamMedium

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.Parent = AttackBtn

-- Phần Speed
local SpeedBox = Instance.new("TextBox")
SpeedBox.Parent = MainFrame
SpeedBox.Position = UDim2.new(0.05, 0, 0, 210)
SpeedBox.Size = UDim2.new(0.9, 0, 0, 50)
SpeedBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
SpeedBox.PlaceholderText = "NHẬP SPEED (0 - 40)"
SpeedBox.Text = ""
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 0)
SpeedBox.TextSize = 20
SpeedBox.Font = Enum.Font.GothamBold

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.Parent = SpeedBox

local SpeedInfo = Instance.new("TextLabel")
SpeedInfo.Parent = MainFrame
SpeedInfo.Position = UDim2.new(0, 0, 0, 265)
SpeedInfo.Size = UDim2.new(1, 0, 0, 20)
SpeedInfo.BackgroundTransparency = 1
SpeedInfo.Text = "Current Speed: 0"
SpeedInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedInfo.TextSize = 14

-- Phần Hitbox
local HitboxBtn = Instance.new("TextButton")
HitboxBtn.Parent = MainFrame
HitboxBtn.Position = UDim2.new(0.05, 0, 0, 300)
HitboxBtn.Size = UDim2.new(0.9, 0, 0, 50)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
HitboxBtn.Text = "HITBOX BODY: OFF"
HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxBtn.TextSize = 18
HitboxBtn.Font = Enum.Font.GothamMedium

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.Parent = HitboxBtn

local HitboxSizeInp = Instance.new("TextBox")
HitboxSizeInp.Parent = MainFrame
HitboxSizeInp.Position = UDim2.new(0.05, 0, 0, 370)
HitboxSizeInp.Size = UDim2.new(0.9, 0, 0, 50)
HitboxSizeInp.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
HitboxSizeInp.PlaceholderText = "HITBOX SIZE (0-80)"
HitboxSizeInp.Text = ""
HitboxSizeInp.TextColor3 = Color3.fromRGB(0, 255, 100)
HitboxSizeInp.TextSize = 20

local HitCorner = Instance.new("UICorner")
HitCorner.Parent = HitboxSizeInp

-- Chú thích dưới cùng
local Footer = Instance.new("TextLabel")
Footer.Parent = MainFrame
Footer.Position = UDim2.new(0.05, 0, 0, 440)
Footer.Size = UDim2.new(0.9, 0, 0, 120)
Footer.BackgroundTransparency = 1
Footer.Text = "HƯỚNG DẪN:\n1. Phím nóng Fast Attack bằng phím G.\n2. Speed tối đa 40.\n3. Hitbox Body:Giúp tăng HITBOX Player "
Footer.TextColor3 = Color3.fromRGB(150, 150, 150)
Footer.TextSize = 16
Footer.TextWrapped = true
Footer.TextXAlignment = Enum.TextXAlignment.Left

-- --------------------------------------------------------------------------------------------
-- [[ XỬ LÝ SỰ KIỆN & VÒNG LẶP ]]
-- --------------------------------------------------------------------------------------------

SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    _G.CFrameSpeedValue = (val and math.clamp(val, 0, 40)) or 0
    SpeedBox.Text = tostring(_G.CFrameSpeedValue)
    SpeedInfo.Text = "Current Speed: " .. SpeedBox.Text
end)

UserInputService.InputBegan:Connect(function(io, p)
    if not p and io.KeyCode == Enum.KeyCode.G then
        Enabled = not Enabled
        AttackBtn.Text = Enabled and "FAST ATTACK: ON (G)" or "FAST ATTACK: OFF (G)"
        AttackBtn.BackgroundColor3 = Enabled and Color3.fromRGB(0, 100, 50) or Color3.fromRGB(40, 40, 45)
    end
end)

HitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    HitboxBtn.Text = HitboxEnabled and "HITBOX BODY: ON" or "HITBOX BODY: OFF"
    HitboxBtn.BackgroundColor3 = HitboxEnabled and Color3.fromRGB(0, 80, 150) or Color3.fromRGB(40, 40, 45)
end)

HitboxSizeInp.FocusLost:Connect(function()
    local n = tonumber(HitboxSizeInp.Text)
    HitboxSize = (n and math.clamp(n, 0, 80)) or 0
    HitboxSizeInp.Text = tostring(HitboxSize)
end)

-- Loops
RunService.Heartbeat:Connect(ApplyInfiniteStaminaLogic)

RunService.RenderStepped:Connect(function()
    for _, tp in pairs(Players:GetPlayers()) do
        if tp ~= Player and tp.Character then
            local root = tp.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if not IsSameTeam(tp) and HitboxEnabled then
                    if not OriginalBodySizes[tp.UserId] then OriginalBodySizes[tp.UserId] = root.Size end
                    root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    root.Transparency = 0.7
                    root.CanCollide = false
                elseif OriginalBodySizes[tp.UserId] then
                    root.Size = OriginalBodySizes[tp.UserId]
                    root.Transparency = 1
                    root.CanCollide = true
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G.IsActive and _G.CFrameSpeedValue > 0 then
        local c = Player.Character
        if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
            if c.Humanoid.MoveDirection.Magnitude > 0 then
                c.HumanoidRootPart.CFrame = c.HumanoidRootPart.CFrame + (c.Humanoid.MoveDirection * (_G.CFrameSpeedValue / 4))
            end
        end
    end
end)

task.spawn(function()
    while true do
        if Enabled then
            if IsEquippedMeleeOrSword() then
                local part, dist, name = GetNearestEnemyInRange()
                TargetLabel.Text = "TARGET: " .. string.upper(name)
                if part then
                    for i = 1, 4 do
                        RegisterAttack:FireServer(0.48)
                        if part and part.Parent then RegisterHit:FireServer(part, {}, { [4] = "763d673c" }) end
                        task.wait()
                    end
                end
            else TargetLabel.Text = "TARGET: NEED WEAPON" end
        else TargetLabel.Text = "TARGET: FAST M1 OFF" end
        task.wait(0.4)
    end
end)

print("LETHOSO.NET")
