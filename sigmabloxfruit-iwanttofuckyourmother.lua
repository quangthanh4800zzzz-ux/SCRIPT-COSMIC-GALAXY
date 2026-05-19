-- [[ COSMIC HUB ULTIMATE - MERGED EDITION ]]
-- [[ KẾT HỢP: COSMIC HUB + FARM MOB TỐI ƯU + ULTRA FPS BOOST ]]
-- [[ PHIÊN BẢN REMASTERED: GALAXY UI & LOGIC UPGRADE ]]
-- [[ FAST ATTACK UPGRADE: MULTI-TARGET (2 CLOSEST) + COOLDOWN SYSTEM ]]
-- Updated: 2026-02-21

-- [[ KHỞI TẠO DỊCH VỤ HỆ THỐNG ]]
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")

local Player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [[ BIẾN CẤU HÌNH TOÀN CỤC (GLOBAL SETTINGS - COSMIC HUB) ]]
_G.CFrameSpeedValue = 0 
_G.MaxLimit = 5000 
_G.JumpPowerValue = 0
_G.MaxJumpLimit = 500
_G.IsActive = true

-- Teleport Settings
_G.TweenSpeedValue = 350
_G.IsTweenMode = false

-- Combat Logic Variables
local FastAttackEnabled = false
local HitboxActive = false
local HitboxValue = 0
local AttackCooldown = 0.01 -- UPDATE: Thay AttackValue thành Cooldown cho Fast Attack mới
local AttackDistance = 400

-- Target Priority & Filters
local PrioritizePlayer = false -- Mặc định ưu tiên Quái (False)
local AttackPlayersEnabled = true
local AttackNPCsEnabled = true
local AttackFriendsEnabled = false

-- Aura / Bypass Logic
_G.AuraEnabled = false -- Đổi tên biến cho M1 Fruits Aura

-- Remotes
local RegisterAttack = ReplicatedStorage.Modules.Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = ReplicatedStorage.Modules.Net:FindFirstChild("RE/RegisterHit")

-- [[ BIẾN CẤU HÌNH TOÀN CỤC (FARM MOB SETTINGS) ]]
_G.FarmSettings = {
    FarmStatus = false,
    FarmDistance = 1000, -- Tầm tìm quái
    BringMob = true,
    BringRadius = 400,   -- Tầm gom quái
    TweenSpeed = 65,     -- Tốc độ lướt farm
    OffsetY = 10,        -- Độ cao so với quái
}

local currentFarmTween = nil
local targetFarmMob = nil
local mobToBringList = {} -- Danh sách quái cùng loại đã lọc

-- [[ HÀM TIỆN ÍCH HỆ THỐNG ]]

-- 1. Hàm Gradient Galaxy (Nâng cấp)
local function AddGalaxyGradient(instance)
    local gradient = instance:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
    })
    gradient.Rotation = 45
    gradient.Parent = instance
    
    -- Animation xoay vòng nhẹ nhàng
    task.spawn(function()
        local rotation = 0
        while instance and instance.Parent do
            rotation = rotation + 1
            if rotation > 360 then rotation = 0 end
            gradient.Rotation = rotation
            task.wait(0.02)
        end
    end)
    return gradient
end

-- 1.1 Hàm Hiệu Ứng UI (Modern Transitions)
local function AnimateButtonHover(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(60, 20, 90),
            BackgroundTransparency = 0.2
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20), -- Màu gốc hoặc reset theo logic
            BackgroundTransparency = 0
        }):Play()
    end)
end

-- 2. Hàm Kiểm Tra Quái Hợp Lệ (Từ Farm Mob script)
local function isValidMob(mob)
    if mob and mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
        local head = mob:FindFirstChild("Head")
        if mob.Humanoid.Health > 0 and head and head.Transparency < 1 then
            return true
        end
    end
    return false
end

-- 3. Hàm Lấy Folder Quái (Từ Farm Mob script)
local function getMobFolder()
    local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("NPCs")
    return folder or workspace
end

-- 4. Xử lý Physics/Anchor (Từ Farm Mob script)
local function clearForces(hrp)
    if not hrp then return end
    for _, v in pairs(hrp:GetChildren()) do
        if v.Name == "FarmForce" or v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            v:Destroy()
        end
    end
end

local function applyAnchor(status)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    clearForces(hrp)
    if status then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FarmForce"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "FarmForce"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    end
end

-- 5. Hàm Kiểm Tra Bạn Bè / Đồng Minh (Từ Cosmic Hub)
local function IsFriendOrAlly(targetPlayer)
    if not targetPlayer then return false end
    if Player:IsFriendsWith(targetPlayer.UserId) then return true end
    local myTeam = Player.Team
    local targetTeam = targetPlayer.Team
    if myTeam and targetTeam then
        if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then return true end
        if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
             local myCrew = Player:FindFirstChild("Crew") and Player.Crew.Value
             local targetCrew = targetPlayer:FindFirstChild("Crew") and targetPlayer.Crew.Value
             if myCrew and targetCrew and myCrew ~= "" and myCrew == targetCrew then
                 return true
             end
             if targetPlayer == Player then return true end
        end
    end
    return false
end

-- 6. HÀM TÌM 1 MỤC TIÊU (GIỮ NGUYÊN CHO AURA & UI TRACKER)
local function GetCosmicTarget()
    local closestPart, closestDist = nil, AttackDistance
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local foundTarget = false

    -- 1. QUÉT PLAYER
    if AttackPlayersEnabled and (PrioritizePlayer or not foundTarget) then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    local isFriend = IsFriendOrAlly(p)
                    local shouldAttack = true
                    if isFriend and not AttackFriendsEnabled then shouldAttack = false end

                    if shouldAttack and dist < closestDist then
                        closestDist = dist
                        closestPart = p.Character.HumanoidRootPart
                        if PrioritizePlayer then foundTarget = true end
                    end
                end
            end
        end
    end

    -- 2. QUÉT NPC
    if AttackNPCsEnabled and not foundTarget then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, v in pairs(enemies:GetChildren()) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hrp and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPart = hrp
                        foundTarget = true
                    end
                end
            end
        end
    end
    
    return closestPart
end

-- 7. HÀM TÌM ĐA MỤC TIÊU (UPDATE CHO FAST ATTACK MỚI - LẤY 2 MỤC TIÊU GẦN NHẤT)
local function GetCosmicMultiTargets()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, {} end

    local validTargets = {}

    -- 1. QUÉT PLAYER
    if AttackPlayersEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    local isFriend = IsFriendOrAlly(p)
                    local shouldAttack = true
                    if isFriend and not AttackFriendsEnabled then shouldAttack = false end

                    if shouldAttack and dist <= AttackDistance then
                        table.insert(validTargets, {
                            model = p.Character,
                            hrp = p.Character.HumanoidRootPart,
                            distance = dist,
                            isPlayer = true
                        })
                    end
                end
            end
        end
    end

    -- 2. QUÉT NPC
    if AttackNPCsEnabled then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, v in pairs(enemies:GetChildren()) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist <= AttackDistance then
                        table.insert(validTargets, {
                            model = v,
                            hrp = hrp,
                            distance = dist,
                            isPlayer = false
                        })
                    end
                end
            end
        end
    end

    -- Nếu không có mục tiêu nào
    if #validTargets == 0 then return nil, {} end

    -- Sắp xếp mục tiêu (Ưu tiên Player nếu bật, sau đó ưu tiên khoảng cách gần nhất)
    table.sort(validTargets, function(a, b)
        if PrioritizePlayer then
            if a.isPlayer and not b.isPlayer then return true end
            if not a.isPlayer and b.isPlayer then return false end
        end
        return a.distance < b.distance
    end)

    -- Lấy Main Target (Gần nhất số 1)
    local mainTarget = validTargets[1].hrp
    local multiTargets = {}
    
    -- Lấy Secondary Target (Gần nhất số 2) - Chỉ lấy tối đa 2 mục tiêu như yêu cầu
    if #validTargets >= 2 then
        table.insert(multiTargets, {
            [1] = validTargets[2].model,
            [2] = validTargets[2].hrp
        })
    end

    return mainTarget, multiTargets
end

-- [[ GUI SYSTEM ]]

if CoreGui:FindFirstChild("COSMIC_INFO_PANEL") then CoreGui:FindFirstChild("COSMIC_INFO_PANEL"):Destroy() end
if CoreGui:FindFirstChild("COSMIC_HUB_MAIN") then CoreGui:FindFirstChild("COSMIC_HUB_MAIN"):Destroy() end

-- 1. Info Panel
local InfoGui = Instance.new("ScreenGui", CoreGui)
InfoGui.Name = "COSMIC_INFO_PANEL"
local InfoFrame = Instance.new("Frame", InfoGui)
InfoFrame.Size = UDim2.new(0, 200, 0, 75) -- Size lớn hơn chút
InfoFrame.Position = UDim2.new(0, 15, 0, 15)
InfoFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
InfoFrame.BackgroundTransparency = 0.2
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 12)
local InfoStroke = Instance.new("UIStroke", InfoFrame)
InfoStroke.Color = Color3.fromRGB(130, 0, 255)
InfoStroke.Thickness = 2
AddGalaxyGradient(InfoStroke) -- Gradient cho viền Info

local FPSLabel = Instance.new("TextLabel", InfoFrame)
FPSLabel.Size = UDim2.new(1, 0, 0.5, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: ..."
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 16

local PingLabel = Instance.new("TextLabel", InfoFrame)
PingLabel.Size = UDim2.new(1, 0, 0.5, 0)
PingLabel.Position = UDim2.new(0, 0, 0.5, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: ..."
PingLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 16

-- Info Logic
local lastIteration = tick()
local frameHistory = {}
RunService.RenderStepped:Connect(function()
    local now = tick()
    local fps = 1 / (now - lastIteration)
    lastIteration = now
    table.insert(frameHistory, fps)
    if #frameHistory > 60 then table.remove(frameHistory, 1) end
    local avgFps = 0
    for _, v in pairs(frameHistory) do avgFps += v end
    avgFps /= #frameHistory
    FPSLabel.Text = string.format("COSMIC FPS: %d", math.floor(avgFps))
    local pingVal = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    PingLabel.Text = string.format("PING: %d ms", math.floor(pingVal))
end)

-- 2. Main GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "COSMIC_HUB_MAIN"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
MainFrame.Position = UDim2.new(0.35, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 680) -- Rộng hơn chút
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
MainFrame.ClipsDescendants = true -- Để hiệu ứng trượt không bị lòi ra ngoài

-- Galaxy Stroke
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 3
AddGalaxyGradient(MainStroke) -- Xoay màu viền

-- Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Text = "COSMIC HUB - REMASTERED"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 16)
local TitleGradient = AddGalaxyGradient(Title)

-- Separator
local Separator = Instance.new("Frame", MainFrame)
Separator.Size = UDim2.new(1, 0, 0, 2)
Separator.Position = UDim2.new(0, 0, 0, 60)
Separator.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
Separator.BorderSizePixel = 0

-- Tab Container (4 Tabs)
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Position = UDim2.new(0, 10, 0, 70)
TabContainer.Size = UDim2.new(1, -20, 0, 45)
TabContainer.BackgroundTransparency = 1

local function createTabButton(text, order)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Size = UDim2.new(0.23, 0, 1, 0) -- Chia đều 4 nút có khoảng cách
    btn.Position = UDim2.new((order-1)*0.255, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local CombatTabBtn = createTabButton("COMBAT", 1)
local FarmTabBtn = createTabButton("AUTO FARM", 2)
local MovementTabBtn = createTabButton("MOVE", 3)
local FPSTabBtn = createTabButton("MISC/FPS", 4)

-- Content Pages Container
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Position = UDim2.new(0, 0, 0, 125)
ContentContainer.Size = UDim2.new(1, 0, 1, -125)
ContentContainer.BackgroundTransparency = 1

-- Hàm tạo trang (Page)
local function createPage(name)
    local page = Instance.new("ScrollingFrame", ContentContainer)
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(170, 0, 255)
    page.CanvasSize = UDim2.new(0, 0, 2.0, 0) -- Auto adjust sau
    page.Visible = false -- Mặc định ẩn
    page.Position = UDim2.new(1, 0, 0, 0) -- Để ở ngoài bên phải để chuẩn bị slide vào
    
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 12)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 10)
    
    return page
end

local CombatPage = createPage("CombatPage")
local FarmPage = createPage("FarmPage")
local MovementPage = createPage("MovementPage")
local FPSPage = createPage("FPSPage")

-- Setup Default View
CombatPage.Visible = true
CombatPage.Position = UDim2.new(0, 0, 0, 0)
CombatTabBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 80)
CombatTabBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
AddGalaxyGradient(CombatTabBtn) -- Gradient cho tab đang chọn

-- [[ UI TRANSITION LOGIC (MODERN SLIDE) ]]
local currentPage = CombatPage
local currentTabBtn = CombatTabBtn

local function SwitchTab(targetPage, targetBtn)
    if currentPage == targetPage then return end
    
    -- Animation Button Cũ
    TweenService:Create(currentTabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    -- Xóa Gradient cũ nếu có (bằng cách destroy con của nó nếu cần, nhưng ở đây ta chỉ đổi màu nền)
    local oldGrad = currentTabBtn:FindFirstChildOfClass("UIGradient")
    if oldGrad then oldGrad:Destroy() end

    -- Animation Button Mới
    TweenService:Create(targetBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 10, 80), TextColor3 = Color3.fromRGB(0, 255, 255)}):Play()
    AddGalaxyGradient(targetBtn)

    -- Animation Slide Page
    -- 1. Slide Current Page ra bên trái
    targetPage.Position = UDim2.new(1, 0, 0, 0) -- Đặt trang mới ở bên phải
    targetPage.Visible = true
    
    local tweenOut = TweenService:Create(currentPage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(-1, 0, 0, 0)})
    local tweenIn = TweenService:Create(targetPage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
    
    tweenOut:Play()
    tweenIn:Play()
    
    -- Cleanup sau khi animation xong
    task.delay(0.4, function()
        currentPage.Visible = false
        currentPage = targetPage
        currentTabBtn = targetBtn
    end)
end

-- Connect Tab Events
CombatTabBtn.MouseButton1Click:Connect(function() SwitchTab(CombatPage, CombatTabBtn) end)
FarmTabBtn.MouseButton1Click:Connect(function() SwitchTab(FarmPage, FarmTabBtn) end)
MovementTabBtn.MouseButton1Click:Connect(function() SwitchTab(MovementPage, MovementTabBtn) end)
FPSTabBtn.MouseButton1Click:Connect(function() SwitchTab(FPSPage, FPSTabBtn) end)

-- [[ TAB 1: COMBAT ]]

-- Target Info
local TargetLabel = Instance.new("TextLabel", CombatPage)
TargetLabel.Size = UDim2.new(0.9, 0, 0, 50)
TargetLabel.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 14
Instance.new("UICorner", TargetLabel).CornerRadius = UDim.new(0, 10)
local TargetStroke = Instance.new("UIStroke", TargetLabel)
TargetStroke.Color = Color3.fromRGB(255, 0, 0)
TargetStroke.Thickness = 1.5

-- Fast Attack
local FastBtn = Instance.new("TextButton", CombatPage)
FastBtn.Size = UDim2.new(0.9, 0, 0, 50)
FastBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FastBtn.Text = "FAST ATTACK (MELEE/SWORD/ICE/LIGHT): OFF (G)"
FastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FastBtn.Font = Enum.Font.GothamBold
FastBtn.TextSize = 12
Instance.new("UICorner", FastBtn).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(FastBtn)

-- Priority Toggle
local PriorityBtn = Instance.new("TextButton", CombatPage)
PriorityBtn.Size = UDim2.new(0.9, 0, 0, 45)
PriorityBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
PriorityBtn.Text = "PRIORITY: MOBS (DEFAULT)"
PriorityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PriorityBtn.Font = Enum.Font.GothamBold
PriorityBtn.TextSize = 13
Instance.new("UICorner", PriorityBtn).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(PriorityBtn)

PriorityBtn.MouseButton1Click:Connect(function()
    PrioritizePlayer = not PrioritizePlayer
    if PrioritizePlayer then
        PriorityBtn.Text = "PRIORITY: PLAYERS"
        TweenService:Create(PriorityBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
    else
        PriorityBtn.Text = "PRIORITY: MOBS (DEFAULT)"
        TweenService:Create(PriorityBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 100, 200)}):Play()
    end
end)

-- Settings Cooldown (UPDATE TỪ ATTACK VALUE)
local AttackCooldownInput = Instance.new("TextBox", CombatPage)
AttackCooldownInput.Size = UDim2.new(0.9, 0, 0, 40)
AttackCooldownInput.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
AttackCooldownInput.PlaceholderText = "NHẬP COOLDOWN M1 (VD: 0.01)"
AttackCooldownInput.Text = "0.01"
AttackCooldownInput.TextColor3 = Color3.fromRGB(0, 255, 255)
AttackCooldownInput.Font = Enum.Font.GothamBold
AttackCooldownInput.TextSize = 14
Instance.new("UICorner", AttackCooldownInput).CornerRadius = UDim.new(0, 8)

-- Settings Distance
local DistanceInput = Instance.new("TextBox", CombatPage)
DistanceInput.Size = UDim2.new(0.9, 0, 0, 40)
DistanceInput.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
DistanceInput.PlaceholderText = "NHẬP KHOẢNG CÁCH (DEF: 400)"
DistanceInput.Text = "400"
DistanceInput.TextColor3 = Color3.fromRGB(0, 255, 255)
DistanceInput.Font = Enum.Font.GothamBold
DistanceInput.TextSize = 14
Instance.new("UICorner", DistanceInput).CornerRadius = UDim.new(0, 8)

-- Filters
local FilterContainer = Instance.new("Frame", CombatPage)
FilterContainer.Size = UDim2.new(0.9, 0, 0, 40)
FilterContainer.BackgroundTransparency = 1
local FilterLayout = Instance.new("UIListLayout", FilterContainer)
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 5)

local FilterPlayerBtn = Instance.new("TextButton", FilterContainer)
FilterPlayerBtn.Size = UDim2.new(0.32, 0, 1, 0)
FilterPlayerBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
FilterPlayerBtn.Text = "PLRS: ON"
FilterPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterPlayerBtn.Font = Enum.Font.GothamBold
FilterPlayerBtn.TextSize = 11
Instance.new("UICorner", FilterPlayerBtn).CornerRadius = UDim.new(0, 8)

local FilterNPCBtn = Instance.new("TextButton", FilterContainer)
FilterNPCBtn.Size = UDim2.new(0.32, 0, 1, 0)
FilterNPCBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
FilterNPCBtn.Text = "NPCs: ON"
FilterNPCBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterNPCBtn.Font = Enum.Font.GothamBold
FilterNPCBtn.TextSize = 11
Instance.new("UICorner", FilterNPCBtn).CornerRadius = UDim.new(0, 8)

local FilterFriendBtn = Instance.new("TextButton", FilterContainer)
FilterFriendBtn.Size = UDim2.new(0.32, 0, 1, 0)
FilterFriendBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
FilterFriendBtn.Text = "FRND: OFF"
FilterFriendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterFriendBtn.Font = Enum.Font.GothamBold
FilterFriendBtn.TextSize = 11
Instance.new("UICorner", FilterFriendBtn).CornerRadius = UDim.new(0, 8)

-- M1 Fruits Aura
local AuraBtn = Instance.new("TextButton", CombatPage)
AuraBtn.Size = UDim2.new(0.9, 0, 0, 50)
AuraBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
AuraBtn.Text = "M1 FRUITS AURA: OFF"
AuraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AuraBtn.Font = Enum.Font.GothamBold
AuraBtn.TextSize = 13
Instance.new("UICorner", AuraBtn).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(AuraBtn)

local AuraStatus = Instance.new("TextLabel", CombatPage)
AuraStatus.Size = UDim2.new(0.9, 0, 0, 20)
AuraStatus.BackgroundTransparency = 1
AuraStatus.Text = "Supports: Pain, Control, Yeti, Blade"
AuraStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
AuraStatus.Font = Enum.Font.Gotham
AuraStatus.TextSize = 11

-- Hitbox
local HitboxBtn = Instance.new("TextButton", CombatPage)
HitboxBtn.Size = UDim2.new(0.9, 0, 0, 45)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
HitboxBtn.Text = "HITBOX: OFF"
HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextSize = 14
Instance.new("UICorner", HitboxBtn).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(HitboxBtn)

local HitboxInput = Instance.new("TextBox", CombatPage)
HitboxInput.Size = UDim2.new(0.9, 0, 0, 40)
HitboxInput.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
HitboxInput.PlaceholderText = "SIZE HITBOX (0-80)"
HitboxInput.Text = ""
HitboxInput.TextColor3 = Color3.fromRGB(0, 255, 255)
HitboxInput.Font = Enum.Font.GothamBold
HitboxInput.TextSize = 14
Instance.new("UICorner", HitboxInput).CornerRadius = UDim.new(0, 8)

-- [[ TAB 2: AUTO FARM (LOGIC TỪ FILE FARM MOB) ]]

-- Toggle Farm
local FarmToggle = Instance.new("TextButton", FarmPage)
FarmToggle.Size = UDim2.new(0.9, 0, 0, 55)
FarmToggle.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
FarmToggle.Text = "AUTO FARM: OFF"
FarmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmToggle.Font = Enum.Font.GothamBlack
FarmToggle.TextSize = 16
Instance.new("UICorner", FarmToggle).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(FarmToggle)

-- Toggle Bring Mob
local BringToggle = Instance.new("TextButton", FarmPage)
BringToggle.Size = UDim2.new(0.9, 0, 0, 45)
BringToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Default ON
BringToggle.Text = "BRING MOBS: ON"
BringToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
BringToggle.Font = Enum.Font.GothamBold
BringToggle.TextSize = 14
Instance.new("UICorner", BringToggle).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(BringToggle)

-- Settings Input Helper
local function addFarmInput(text, key, parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.9, 0, 0, 40)
    frame.BackgroundTransparency = 1
    
    local lab = Instance.new("TextLabel", frame)
    lab.Size = UDim2.new(0.5, 0, 1, 0)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = Color3.fromRGB(200, 200, 200)
    lab.Font = Enum.Font.Gotham
    lab.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.4, 0, 1, 0)
    box.Position = UDim2.new(0.6, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.TextColor3 = Color3.fromRGB(0, 255, 255)
    box.Text = tostring(_G.FarmSettings[key])
    box.Font = Enum.Font.GothamBold
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then _G.FarmSettings[key] = val end
    end)
    return frame
end

addFarmInput("Farm Distance:", "FarmDistance", FarmPage)
addFarmInput("Tween Speed:", "TweenSpeed", FarmPage)
addFarmInput("Offset Y (Height):", "OffsetY", FarmPage)
addFarmInput("Bring Radius:", "BringRadius", FarmPage)

-- [[ TAB 3: MOVEMENT ]]

-- Speed
local SpeedInput = Instance.new("TextBox", MovementPage)
SpeedInput.Size = UDim2.new(0.9, 0, 0, 45)
SpeedInput.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
SpeedInput.PlaceholderText = "SPEED VALUE (0 - 5000)"
SpeedInput.Text = ""
SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 255)
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.TextSize = 14
Instance.new("UICorner", SpeedInput).CornerRadius = UDim.new(0, 10)

-- Jump
local JumpInput = Instance.new("TextBox", MovementPage)
JumpInput.Size = UDim2.new(0.9, 0, 0, 45)
JumpInput.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
JumpInput.PlaceholderText = "JUMP VALUE (0 - 500)"
JumpInput.Text = ""
JumpInput.TextColor3 = Color3.fromRGB(0, 255, 255)
JumpInput.Font = Enum.Font.GothamBold
JumpInput.TextSize = 14
Instance.new("UICorner", JumpInput).CornerRadius = UDim.new(0, 10)

-- TP Section
local TPSectionTitle = Instance.new("TextLabel", MovementPage)
TPSectionTitle.Size = UDim2.new(0.9, 0, 0, 30)
TPSectionTitle.BackgroundColor3 = Color3.fromRGB(30, 0, 60)
TPSectionTitle.Text = "--- TELEPORT SYSTEM ---"
TPSectionTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
TPSectionTitle.Font = Enum.Font.GothamBlack
TPSectionTitle.TextSize = 14
Instance.new("UICorner", TPSectionTitle).CornerRadius = UDim.new(0, 8)

local TPModeBtn = Instance.new("TextButton", MovementPage)
TPModeBtn.Size = UDim2.new(0.9, 0, 0, 45)
TPModeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
TPModeBtn.Text = "MODE: INSTANT TP"
TPModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPModeBtn.Font = Enum.Font.GothamBold
TPModeBtn.TextSize = 14
Instance.new("UICorner", TPModeBtn).CornerRadius = UDim.new(0, 10)
AnimateButtonHover(TPModeBtn)

-- Tween Speed Input (With Slide Animation Logic)
local TweenSpeedInput = Instance.new("TextBox", MovementPage)
TweenSpeedInput.Size = UDim2.new(0.9, 0, 0, 0) -- Bắt đầu bằng 0 (ẩn)
TweenSpeedInput.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
TweenSpeedInput.PlaceholderText = "TP TWEEN SPEED (0-4800)"
TweenSpeedInput.Text = "350"
TweenSpeedInput.TextColor3 = Color3.fromRGB(255, 0, 255)
TweenSpeedInput.Font = Enum.Font.GothamBold
TweenSpeedInput.ClipsDescendants = true -- Để ẩn text khi thu nhỏ
TweenSpeedInput.Visible = true -- Luôn visible để animation chạy
Instance.new("UICorner", TweenSpeedInput).CornerRadius = UDim.new(0, 8)

local XYZContainer = Instance.new("Frame", MovementPage)
XYZContainer.Size = UDim2.new(0.9, 0, 0, 40)
XYZContainer.BackgroundTransparency = 1
local XYZLayout = Instance.new("UIListLayout", XYZContainer)
XYZLayout.FillDirection = Enum.FillDirection.Horizontal
XYZLayout.Padding = UDim.new(0, 5)
XYZLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local InputX = Instance.new("TextBox", XYZContainer)
InputX.Size = UDim2.new(0.31, 0, 1, 0)
InputX.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputX.PlaceholderText = "X (~)"
InputX.TextColor3 = Color3.fromRGB(255, 100, 100)
InputX.Font = Enum.Font.GothamBold
Instance.new("UICorner", InputX).CornerRadius = UDim.new(0, 6)

local InputY = Instance.new("TextBox", XYZContainer)
InputY.Size = UDim2.new(0.31, 0, 1, 0)
InputY.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputY.PlaceholderText = "Y (~)"
InputY.TextColor3 = Color3.fromRGB(100, 255, 100)
InputY.Font = Enum.Font.GothamBold
Instance.new("UICorner", InputY).CornerRadius = UDim.new(0, 6)

local InputZ = Instance.new("TextBox", XYZContainer)
InputZ.Size = UDim2.new(0.31, 0, 1, 0)
InputZ.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputZ.PlaceholderText = "Z (~)"
InputZ.TextColor3 = Color3.fromRGB(100, 100, 255)
InputZ.Font = Enum.Font.GothamBold
Instance.new("UICorner", InputZ).CornerRadius = UDim.new(0, 6)

local TeleportBtn = Instance.new("TextButton", MovementPage)
TeleportBtn.Size = UDim2.new(0.9, 0, 0, 45)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
TeleportBtn.Text = "TELEPORT TO XYZ"
TeleportBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
TeleportBtn.Font = Enum.Font.GothamBlack
TeleportBtn.TextSize = 15
Instance.new("UICorner", TeleportBtn).CornerRadius = UDim.new(0, 10)
local TeleBtnStroke = Instance.new("UIStroke", TeleportBtn)
TeleBtnStroke.Color = Color3.fromRGB(0, 255, 255)
TeleBtnStroke.Thickness = 1.5
AnimateButtonHover(TeleportBtn)

-- [[ TAB 4: FPS BOOST (ULTRA DEEP) ]]

local UltraBoostBtn = Instance.new("TextButton", FPSPage)
UltraBoostBtn.Size = UDim2.new(0.9, 0, 0, 60)
UltraBoostBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
UltraBoostBtn.Text = "ACTIVATE ULTRA FPS BOOST\n(NO FOG / NO EFFECTS / CLEAR)"
UltraBoostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UltraBoostBtn.Font = Enum.Font.GothamBlack
UltraBoostBtn.TextSize = 14
Instance.new("UICorner", UltraBoostBtn).CornerRadius = UDim.new(0, 10)
AddGalaxyGradient(UltraBoostBtn)

local FPSNote = Instance.new("TextLabel", FPSPage)
FPSNote.Size = UDim2.new(0.9, 0, 0, 40)
FPSNote.BackgroundTransparency = 1
FPSNote.Text = "Warning: Removes almost all visuals. Does NOT lower render distance. Keeps game play smooth."
FPSNote.TextColor3 = Color3.fromRGB(150, 150, 150)
FPSNote.Font = Enum.Font.Gotham
FPSNote.TextSize = 10
FPSNote.TextWrapped = true

-- [[ LOGIC HỆ THỐNG (SYSTEM LOGIC) ]]

-- 1. Xử lý Logic Movement Tween cho Farm (Từ Farm Mob script)
local function handleFarmMove(mob)
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not mob:FindFirstChild("HumanoidRootPart") then return end

    local mHRP = mob.HumanoidRootPart
    local targetPos = Vector3.new(mHRP.Position.X, mHRP.Position.Y + _G.FarmSettings.OffsetY, mHRP.Position.Z)
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
    
    if dist < 3 then
        hrp.CFrame = CFrame.new(targetPos)
        if currentFarmTween then currentFarmTween:Cancel() end
        return
    end

    if not currentFarmTween or currentFarmTween.PlaybackState ~= Enum.PlaybackState.Playing then
        currentFarmTween = TweenService:Create(hrp, TweenInfo.new(dist / _G.FarmSettings.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        currentFarmTween:Play()
    end
end

-- 2. Module: Tìm Mục Tiêu FARM (Logic Farm Mob)
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.FarmSettings.FarmStatus then
            local folder = getMobFolder()
            local closest = nil
            local dist = _G.FarmSettings.FarmDistance
            
            for _, v in pairs(folder:GetChildren()) do
                if isValidMob(v) then
                    local d = (Player.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        closest = v
                        dist = d
                    end
                end
            end
            targetFarmMob = closest
        else
            targetFarmMob = nil
        end
    end
end)

-- 3. Module: Lọc Bring Mob (Logic Farm Mob)
task.spawn(function()
    while true do
        task.wait(1)
        if _G.FarmSettings.FarmStatus and _G.FarmSettings.BringMob and targetFarmMob then
            local temp = {}
            local folder = getMobFolder()
            local tName = targetFarmMob.Name
            local tPos = targetFarmMob.HumanoidRootPart.Position
            
            for _, v in pairs(folder:GetChildren()) do
                if v ~= targetFarmMob and v.Name == tName and isValidMob(v) then
                    if (v.HumanoidRootPart.Position - tPos).Magnitude <= _G.FarmSettings.BringRadius then
                        table.insert(temp, v)
                    end
                end
            end
            mobToBringList = temp
        else
            mobToBringList = {}
        end
    end
end)

-- 4. Fast Attack Loop (UPDATE: MULTI-TARGET TỪ FAST ATTACK.LUA)
task.spawn(function()
    print("--- COSMIC HUB MULTI-TARGET M1 IS RUNNING ---")
    while true do
        -- Đổi RunService.Heartbeat thành task.wait(Cooldown) để kiểm soát tốc độ giống script mới
        task.wait(AttackCooldown) 
        
        if FastAttackEnabled then
            local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
            local isValidTool = false
            
            if tool then
                if tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword") then
                    isValidTool = true
                elseif tool.Name == "Ice-Ice" or tool.Name == "Light-Light" then
                    isValidTool = true
                end
            end

            if isValidTool then
                -- Dùng hàm mới trả về 2 mục tiêu thay vì 1
                local mainTarget, multiTargets = GetCosmicMultiTargets()
                
                if mainTarget then
                    pcall(function()
                        -- Báo server vung đòn với độ trễ 0
                        RegisterAttack:FireServer(0)
                        -- Gửi lệnh Hit trúng nhiều mục tiêu (tối đa 2 theo hàm GetCosmicMultiTargets)
                        RegisterHit:FireServer(mainTarget, multiTargets)
                    end)
                end
            end
        end
    end
end)

-- 5. M1 Fruits Aura Loop (Renamed & Logic Kept - Dùng hàm Target 1 mục tiêu cũ)
task.spawn(function()
    while true do
        if _G.AuraEnabled then
            pcall(function()
                local char = Player.Character
                local backpack = Player.Backpack
                
                local pain = char:FindFirstChild("Pain-Pain") or backpack:FindFirstChild("Pain-Pain")
                local control = char:FindFirstChild("Control-Control") or backpack:FindFirstChild("Control-Control")
                local yeti = char:FindFirstChild("Yeti-Yeti") or backpack:FindFirstChild("Yeti-Yeti")
                local blade = char:FindFirstChild("Blade-Blade") or backpack:FindFirstChild("Blade-Blade")
                
                local target = GetCosmicTarget() -- Vẫn dùng hàm quét 1 mục tiêu để lấy vector
                local vector = target and (target.Position - char.HumanoidRootPart.Position).Unit or char.HumanoidRootPart.CFrame.LookVector

                if pain then
                    local remote = pain:FindFirstChild("LeftClickRemote")
                    if remote then
                        remote:FireServer(vector, 1, false)
                        remote:FireServer(vector, 2, false)
                        remote:FireServer(vector, 3, false)
                    end
                elseif control then
                    local remote = control:FindFirstChild("LeftClickRemote")
                    if remote then
                        for i=1,4 do remote:FireServer(vector, i, true) end
                    end
                elseif yeti then
                    local remote = yeti:FindFirstChild("LeftClickRemote")
                    if remote then
                        for i=1,4 do remote:FireServer(vector, i, false) end
                    end
                elseif blade then
                    local remote = blade:FindFirstChild("LeftClickRemote")
                    if remote then
                        remote:FireServer(vector, 1, false)
                        remote:FireServer(vector, 2, false)
                    end
                end
            end)
        end
        task.wait(0) -- Spam max speed
    end
end)

-- 6. Heartbeat Loop Chính (Kết hợp Farm Mob + UI Updates)
RunService.Heartbeat:Connect(function()
    -- [[ LOGIC FARM MOB THỰC THI ]]
    if _G.FarmSettings.FarmStatus and Player.Character then
        -- NoClip
        for _, p in pairs(Player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        
        if targetFarmMob then
            handleFarmMove(targetFarmMob)
            
            -- Bring Logic
            if _G.FarmSettings.BringMob and #mobToBringList > 0 then
                local targetCF = targetFarmMob.HumanoidRootPart.CFrame
                for _, mob in pairs(mobToBringList) do
                    if mob:FindFirstChild("HumanoidRootPart") then
                        mob.HumanoidRootPart.CanCollide = false
                        mob.HumanoidRootPart.CFrame = targetCF
                        mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                        mob.Humanoid.PlatformStand = true
                    end
                end
            end
        end
    end

    -- [[ LOGIC COSMIC UI UPDATES ]]
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local hum = Player.Character.Humanoid
        if _G.JumpPowerValue > 0 then
            hum.UseJumpPower = true
            hum.JumpPower = _G.JumpPowerValue
        end
    end
    
    local currentTarget = GetCosmicTarget() -- UI vẫn hiển thị mục tiêu gần nhất
    if currentTarget then
        TargetLabel.Text = "LOCKED: " .. currentTarget.Parent.Name:upper()
        TargetLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        TargetStroke.Color = Color3.fromRGB(0, 255, 0)
    else
        TargetLabel.Text = "SCANNING..."
        TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        TargetStroke.Color = Color3.fromRGB(255, 0, 0)
    end
    
    if HitboxActive and HitboxValue > 0 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local isFriend = IsFriendOrAlly(p)
                local shouldExpand = true
                if isFriend and not AttackFriendsEnabled then shouldExpand = false end
                
                if shouldExpand then
                    local hrp = p.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(HitboxValue, HitboxValue, HitboxValue)
                    hrp.Transparency = 0.6
                    hrp.CanCollide = false
                    hrp.Material = Enum.Material.ForceField
                    hrp.Color = Color3.fromRGB(170, 0, 255)
                end
            end
        end
    end
end)

-- 7. Speed Logic (Stepped)
RunService.Stepped:Connect(function()
    if _G.IsActive and _G.CFrameSpeedValue > 0 and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local root = Player.Character.HumanoidRootPart
        local hum = Player.Character:FindFirstChild("Humanoid")
        -- Chỉ chạy Speed nếu KHÔNG Farm hoặc Farm đang tắt (để tránh xung đột Tween)
        if not _G.FarmSettings.FarmStatus and hum and hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (_G.CFrameSpeedValue / 10))
        end
    end
end)

-- [[ EVENTS HANDLERS ]]

-- Combat Buttons
FastBtn.MouseButton1Click:Connect(function()
    FastAttackEnabled = not FastAttackEnabled
    FastBtn.Text = FastAttackEnabled and "FAST ATTACK (ICE/LIGHT/SWORD): ON (G)" or "FAST ATTACK (ICE/LIGHT/SWORD): OFF (G)"
    if FastAttackEnabled then
        TweenService:Create(FastBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play()
    else
        TweenService:Create(FastBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
    end
end)

-- EVENT UPDATE CHO COOLDOWN M1
AttackCooldownInput.FocusLost:Connect(function()
    local val = tonumber(AttackCooldownInput.Text)
    AttackCooldown = val and math.max(0, val) or AttackCooldown
    AttackCooldownInput.Text = tostring(AttackCooldown)
end)

DistanceInput.FocusLost:Connect(function()
    local val = tonumber(DistanceInput.Text)
    if val then AttackDistance = val end
end)

FilterPlayerBtn.MouseButton1Click:Connect(function()
    AttackPlayersEnabled = not AttackPlayersEnabled
    FilterPlayerBtn.Text = AttackPlayersEnabled and "PLRS: ON" or "PLRS: OFF"
    FilterPlayerBtn.BackgroundColor3 = AttackPlayersEnabled and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(150, 0, 0)
end)

FilterNPCBtn.MouseButton1Click:Connect(function()
    AttackNPCsEnabled = not AttackNPCsEnabled
    FilterNPCBtn.Text = AttackNPCsEnabled and "NPCs: ON" or "NPCs: OFF"
    FilterNPCBtn.BackgroundColor3 = AttackNPCsEnabled and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(150, 0, 0)
end)

FilterFriendBtn.MouseButton1Click:Connect(function()
    AttackFriendsEnabled = not AttackFriendsEnabled
    FilterFriendBtn.Text = AttackFriendsEnabled and "FRND: ON" or "FRND: OFF"
    FilterFriendBtn.BackgroundColor3 = AttackFriendsEnabled and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(150, 0, 0)
end)

AuraBtn.MouseButton1Click:Connect(function()
    _G.AuraEnabled = not _G.AuraEnabled
    AuraBtn.Text = _G.AuraEnabled and "M1 FRUITS AURA: ON" or "M1 FRUITS AURA: OFF"
    AuraBtn.BackgroundColor3 = _G.AuraEnabled and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(150, 0, 0)
end)

HitboxBtn.MouseButton1Click:Connect(function()
    HitboxActive = not HitboxActive
    HitboxBtn.Text = HitboxActive and "HITBOX: ON" or "HITBOX: OFF"
    if HitboxActive then
        TweenService:Create(HitboxBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play()
    else
        TweenService:Create(HitboxBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end
end)

HitboxInput.FocusLost:Connect(function()
    local val = tonumber(HitboxInput.Text)
    if val then HitboxValue = val end
end)

-- Farm Buttons
FarmToggle.MouseButton1Click:Connect(function()
    _G.FarmSettings.FarmStatus = not _G.FarmSettings.FarmStatus
    FarmToggle.Text = _G.FarmSettings.FarmStatus and "AUTO FARM: ON" or "AUTO FARM: OFF"
    if _G.FarmSettings.FarmStatus then
        TweenService:Create(FarmToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 180, 0)}):Play()
    else
        TweenService:Create(FarmToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(180, 0, 0)}):Play()
    end
    applyAnchor(_G.FarmSettings.FarmStatus)
end)

BringToggle.MouseButton1Click:Connect(function()
    _G.FarmSettings.BringMob = not _G.FarmSettings.BringMob
    BringToggle.Text = _G.FarmSettings.BringMob and "BRING MOBS: ON" or "BRING MOBS: OFF"
    if _G.FarmSettings.BringMob then
        TweenService:Create(BringToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 180, 0)}):Play()
    else
        TweenService:Create(BringToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(180, 0, 0)}):Play()
    end
end)

-- Movement Buttons
SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val then _G.CFrameSpeedValue = math.clamp(val, 0, _G.MaxLimit) end
end)

JumpInput.FocusLost:Connect(function()
    local val = tonumber(JumpInput.Text)
    if val then _G.JumpPowerValue = math.clamp(val, 0, _G.MaxJumpLimit) end
end)

TPModeBtn.MouseButton1Click:Connect(function()
    _G.IsTweenMode = not _G.IsTweenMode
    TPModeBtn.Text = _G.IsTweenMode and "MODE: TWEEN (SMOOTH)" or "MODE: INSTANT TP"
    
    if _G.IsTweenMode then
        TweenService:Create(TPModeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(150, 0, 150)}):Play()
        -- SLIDE OUT TweenSpeedInput
        TweenService:Create(TweenSpeedInput, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.9, 0, 0, 40)
        }):Play()
    else
        TweenService:Create(TPModeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 150, 50)}):Play()
        -- SLIDE IN (HIDE) TweenSpeedInput
        TweenService:Create(TweenSpeedInput, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.9, 0, 0, 0)
        }):Play()
    end
end)

TweenSpeedInput.FocusLost:Connect(function()
    local val = tonumber(TweenSpeedInput.Text)
    if val then _G.TweenSpeedValue = math.clamp(val, 0, 4800) end
    TweenSpeedInput.Text = tostring(_G.TweenSpeedValue)
end)

TeleportBtn.MouseButton1Click:Connect(function()
    -- Logic Teleport merged
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Player.Character.HumanoidRootPart
    local cp = hrp.Position
    
    local function parse(txt, current)
        local c = string.gsub(txt, " ", "")
        if c == "" or c == "~" then return current end
        if string.sub(c, 1, 1) == "~" then
            local off = tonumber(string.sub(c, 2))
            return off and (current + off) or current
        end
        return tonumber(c) or current
    end
    
    local dx = parse(InputX.Text, cp.X)
    local dy = parse(InputY.Text, cp.Y)
    local dz = parse(InputZ.Text, cp.Z)
    local tCF = CFrame.new(dx, dy, dz)
    
    if _G.IsTweenMode then
        local dist = (tCF.Position - cp).Magnitude
        local speed = _G.TweenSpeedValue > 0 and _G.TweenSpeedValue or 100
        local ti = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
        local tw = TweenService:Create(hrp, ti, {CFrame = tCF})
        tw:Play()
        TeleportBtn.Text = "TWEENING..."
        tw.Completed:Connect(function() TeleportBtn.Text = "TELEPORT TO XYZ" end)
    else
        hrp.CFrame = tCF
        TeleportBtn.Text = "WARPED!"
        task.wait(0.5)
        TeleportBtn.Text = "TELEPORT TO XYZ"
    end
end)

-- ULTRA FPS BOOST BUTTON
UltraBoostBtn.MouseButton1Click:Connect(function()
    UltraBoostBtn.Text = "APPLYING NUCLEAR BOOST..."
    task.wait(0.5)
    
    local function NuclearBoost()
        -- 1. Lighting Clean (No fog, no shadow, bright)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9 -- Xóa sương mù nhưng giữ render distance
        Lighting.FogStart = 9e9
        Lighting.Brightness = 2
        Lighting.ClockTime = 14 -- Luôn sáng
        
        -- Xóa effects trong Lighting
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v:Destroy()
            end
        end

        -- 2. Terrain Clean
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
            -- Xóa cỏ
            sethiddenproperty(Terrain, "Decoration", false)
        end
        
        -- 3. Material Service Clean
        for _, v in pairs(MaterialService:GetChildren()) do
            v:Destroy()
        end

        -- 4. Workspace Clean (Iterate all)
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("MeshPart") then
                -- Làm mượt part, tắt bóng
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                -- Không đổi transparency để tránh lỗi nhìn xuyên
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy() -- Xóa texture
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Explosion") then
                v:Destroy() -- Xóa hiệu ứng
            end
            
            -- Tối ưu Accessories (nón, áo choàng...)
            if v:IsA("Accessory") then
                local h = v:FindFirstChild("Handle")
                if h then
                    h.Material = Enum.Material.SmoothPlastic
                    h.CastShadow = false
                    local m = h:FindFirstChildOfClass("SpecialMesh")
                    if m then m.TextureId = "" end
                end
            end
        end
    end
    
    NuclearBoost()
    
    -- Auto Clean New Objects
    game.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then
            v:Destroy()
        end
    end)
    
    UltraBoostBtn.Text = "ULTRA BOOST ACTIVE (CLEAR)"
    UltraBoostBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.K then
            ScreenGui.Enabled = not ScreenGui.Enabled
        elseif input.KeyCode == Enum.KeyCode.G then
            FastAttackEnabled = not FastAttackEnabled
            FastBtn.Text = FastAttackEnabled and "FAST ATTACK (ICE/LIGHT/SWORD): ON (G)" or "FAST ATTACK (ICE/LIGHT/SWORD): OFF (G)"
            if FastAttackEnabled then
                TweenService:Create(FastBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play()
            else
                TweenService:Create(FastBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
            end
        end
    end
end)

print("COSMIC HUB ULTIMATE REMASTERED LOADED. ALL SYSTEMS GO.")
