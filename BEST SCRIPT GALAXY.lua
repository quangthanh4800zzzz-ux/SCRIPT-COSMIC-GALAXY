-- [[ ====================================================================================== ]]
-- [[ SCRIPT: GALAXYAPEX_V27 - PHIÊN BẢN CẤU TRÚC MỞ RỘNG TOÀN DIỆN & SIÊU CẤP             ]]
-- [[ TÁC GIẢ: THÀNH_ĐB                                                                   ]]
-- [[ NGÀY CẬP NHẬT: 21/05/2026                                                           ]]
-- [[ MÔ TẢ: BỔ SUNG 4 SPEED, 2 FLY, DYNAMIC BLACKLIST GUI, AIMBOT BEHIND, KILASIK FLING ]]
-- [[ CAM KẾT: TUÂN THỦ QUY TẮC KHÔNG RÚT GỌN - MÃ NGUỒN CHI TIẾT ĐẾN TỪNG DÒNG          ]]
-- [[ ====================================================================================== ]]

-- [PHẦN 1: KHỞI TẠO CÁC DỊCH VỤ HỆ THỐNG CỐ ĐỊNH]
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- [PHẦN 2: KHAI BÁO BIẾN NGƯỜI CHƠI VÀ CAMERA]
local LocalPlayer = Players.LocalPlayer
local PlayerMouse = LocalPlayer:GetMouse()
local CurrentCamera = Workspace.CurrentCamera

-- [PHẦN 3: CẤU HÌNH HỆ THỐNG (SETTINGS DATA)]
_G.GalaxySettings = {
    -- Trạng thái Combat
    AimbotPovEnabled = false,
    AimBodyEnabled = false,
    FollowEnabled = false,
    HitboxEnabled = false,
    FlingTargetEnabled = false,
    
    -- Trạng thái Visuals
    EspGlobalEnabled = false,
    EspShowTeam = false,
    FovCircleVisible = false,
    
    -- Trạng thái Movement
    NoclipEnabled = false,
    TpMode = "Instant", 
    TweenSpeed = 480,
    
    -- Trạng thái Speed & Fly (NÂNG CẤP)
    SpeedTypes = {Type1_Walk = false, Type2_CFrame = false, Type3_Velocity = false, Type4_Vector = false},
    SpeedValue = 16.00000000,
    FlyTypes = {Type1_BodyVel = false, Type2_CFrame = false},
    FlyValue = 50.00000000,
    
    -- Danh sách đen đa mục tiêu
    Blacklist = {}, 
    
    -- Thông số kỹ thuật
    PovRadius = 40,
    HitboxSizeHead = 5,
    HitboxSizeBody = 5,
    FollowOffset = Vector3.new(0, 7, 0)
}

-- [PHẦN 4: HỆ THỐNG QUẢN LÝ MỤC TIÊU VÀ BLACKLIST]
local Target_List = nil     
local Target_Pov = nil      
local CurrentIndex = 1
local ValidPlayers = {}     

local function UpdateValidPlayerList()
    local newList = {}
    local allPlayers = Players:GetPlayers()
    
    for i = 1, #allPlayers do
        local p = allPlayers[i]
        if p ~= LocalPlayer and not _G.GalaxySettings.Blacklist[p.UserId] then
            table.insert(newList, p)
        end
    end
    
    ValidPlayers = newList
    
    if Target_List and _G.GalaxySettings.Blacklist[Target_List.UserId] then Target_List = nil end
    if Target_Pov and _G.GalaxySettings.Blacklist[Target_Pov.UserId] then Target_Pov = nil end
end

-- [PHẦN 5: HIỆU ỨNG INTRO THÀNH_ĐB (BẢN ĐẦY ĐỦ)]
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
    MainTitle.Font = Enum.Font.GothamBlack
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

-- [PHẦN 6: GIAO DIỆN NGƯỜI DÙNG TỐI ƯU HÓA (4 CỘT - GÓC PHẢI)]
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "GalaxyApex_V27_Core"
MainGui.ResetOnSpawn = false
MainGui.Enabled = false
MainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
task.delay(5, function() MainGui.Enabled = true end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "ControlPanel"
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.BackgroundTransparency = 0.05
MainFrame.Size = UDim2.new(0, 1320, 0, 680) -- Mở rộng 4 cột
MainFrame.AnchorPoint = Vector2.new(1, 0)
MainFrame.Position = UDim2.new(1, -20, 0, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = MainGui

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 15)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 3
MainStroke.Color = Color3.fromRGB(255, 0, 255)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Transparency = 0.1

local TitleGradient = Instance.new("UIGradient", MainStroke)
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
}

local function CreateCategoryColumn(title, position)
    local Container = Instance.new("Frame", MainFrame)
    Container.Size = UDim2.new(0, 310, 0, 560)
    Container.Position = position
    Container.BackgroundTransparency = 1
    
    local Header = Instance.new("TextLabel", Container)
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.Text = title
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.Font = Enum.Font.GothamBlack
    Header.TextSize = 20
    Header.BackgroundTransparency = 1
    
    local HdrGradient = Instance.new("UIGradient", Header)
    HdrGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))
    }
    
    local Divider = Instance.new("Frame", Header)
    Divider.Size = UDim2.new(0.9, 0, 0, 3)
    Divider.Position = UDim2.new(0.05, 0, 1, -5)
    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Divider.BorderSizePixel = 0
    
    local DivGradient = Instance.new("UIGradient", Divider)
    DivGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    }
    
    local Scroll = Instance.new("ScrollingFrame", Container)
    Scroll.Size = UDim2.new(1, 0, 1, -55)
    Scroll.Position = UDim2.new(0, 0, 0, 55)
    Scroll.BackgroundTransparency = 1
    Scroll.CanvasSize = UDim2.new(0, 0, 5, 0)
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 255)
    Scroll.BorderSizePixel = 0
    
    local List = Instance.new("UIListLayout", Scroll)
    List.Padding = UDim.new(0, 12)
    List.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    return Scroll
end

-- Bố trí 4 cột logic
local CombatCol = CreateCategoryColumn("COMBAT SYSTEMS", UDim2.new(0, 15, 0, 100))
local MovementCol = CreateCategoryColumn("MOVEMENT SYSTEMS", UDim2.new(0, 340, 0, 100))
local SpeedFlyCol = CreateCategoryColumn("SPEED & FLY HACKS", UDim2.new(0, 665, 0, 100))
local UtilityCol = CreateCategoryColumn("DYNAMIC BLACKLIST", UDim2.new(0, 990, 0, 100))

local function NewButton(text, parent, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 290, 0, 45)
    b.BackgroundColor3 = color or Color3.fromRGB(30, 30, 45)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = parent
    
    local btnCorner = Instance.new("UICorner", b)
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    local btnStroke = Instance.new("UIStroke", b)
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Color = Color3.fromRGB(80, 80, 110)
    btnStroke.Thickness = 1.5
    return b
end

local function NewTextBox(placeholder, parent)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(0, 290, 0, 45)
    t.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    t.PlaceholderText = placeholder
    t.Text = ""
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamMedium
    t.TextSize = 14
    t.Parent = parent
    t.ClearTextOnFocus = false
    
    local txtCorner = Instance.new("UICorner", t)
    txtCorner.CornerRadius = UDim.new(0, 8)
    
    local txtStroke = Instance.new("UIStroke", t)
    txtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    txtStroke.Color = Color3.fromRGB(100, 100, 150)
    txtStroke.Thickness = 1.5
    return t
end

-- [PHẦN 7: KHỞI TẠO CÁC NÚT ĐIỀU KHIỂN & HUD]
local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, -30, 0, 80)
InfoLabel.Position = UDim2.new(0, 15, 0, 10)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.Font = Enum.Font.GothamBlack
InfoLabel.TextSize = 16
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Cột 1: Combat
local boxHbHead = NewTextBox("Hitbox Head Size (Default: 5)", CombatCol); boxHbHead.Text = "5"
local boxHbBody = NewTextBox("Hitbox Body Size (Default: 5)", CombatCol); boxHbBody.Text = "5"
local btnHitbox = NewButton("Enable Hitbox: OFF", CombatCol, Color3.fromRGB(150, 40, 40))
local btnAimBody = NewButton("AimBody Behind (Press E): OFF", CombatCol, Color3.fromRGB(180, 120, 0))
local btnAimbot = NewButton("Aimbot POV (Mouse): OFF", CombatCol, Color3.fromRGB(200, 70, 0))
local boxPovRad = NewTextBox("POV Circle Radius (40)", CombatCol); boxPovRad.Text = "40"
local btnEspToggle = NewButton("ESP Auto-Refresh: OFF", CombatCol, Color3.fromRGB(100, 40, 180))

-- Cột 2: Movement
local btnNoclip = NewButton("Noclip (Press N): OFF", MovementCol)
local boxTpX = NewTextBox("Target X Coordinate", MovementCol)
local boxTpY = NewTextBox("Target Y Coordinate", MovementCol)
local boxTpZ = NewTextBox("Target Z Coordinate", MovementCol)
local btnTpType = NewButton("TP Mode: INSTANT", MovementCol, Color3.fromRGB(50, 70, 120))
local boxTpSpeed = NewTextBox("Tween Speed (480)", MovementCol); boxTpSpeed.Text = "480"
local btnExecuteTp = NewButton("Execute Teleport", MovementCol, Color3.fromRGB(0, 140, 140))
local boxOffX = NewTextBox("Follow Offset X (0)", MovementCol); boxOffX.Text = "0"
local boxOffY = NewTextBox("Follow Offset Y (7)", MovementCol); boxOffY.Text = "7"
local boxOffZ = NewTextBox("Follow Offset Z (0)", MovementCol); boxOffZ.Text = "0"
local btnFollow = NewButton("Follow (List Target): OFF", MovementCol, Color3.fromRGB(180, 0, 180))

-- Cột 3: Speed & Fly (NÂNG CẤP MỚI)
local boxSpeedVal = NewTextBox("Speed Value (Max 8 Decimals)", SpeedFlyCol)
boxSpeedVal.Text = string.format("%.8f", _G.GalaxySettings.SpeedValue)
local btnSpeed1 = NewButton("Speed Type 1 (WalkSpeed): OFF", SpeedFlyCol, Color3.fromRGB(40, 100, 40))
local btnSpeed2 = NewButton("Speed Type 2 (CFrame): OFF", SpeedFlyCol, Color3.fromRGB(40, 100, 40))
local btnSpeed3 = NewButton("Speed Type 3 (Velocity): OFF", SpeedFlyCol, Color3.fromRGB(40, 100, 40))
local btnSpeed4 = NewButton("Speed Type 4 (Vector3): OFF", SpeedFlyCol, Color3.fromRGB(40, 100, 40))

local boxFlyVal = NewTextBox("Fly Speed (Max 8 Decimals)", SpeedFlyCol)
boxFlyVal.Text = string.format("%.8f", _G.GalaxySettings.FlyValue)
local btnFly1 = NewButton("Fly Type 1 (BodyVelocity): OFF", SpeedFlyCol, Color3.fromRGB(40, 80, 120))
local btnFly2 = NewButton("Fly Type 2 (CFrame Noclip): OFF", SpeedFlyCol, Color3.fromRGB(40, 80, 120))

-- Cột 4: Utility & Bảng Blacklist Động & Fling Mới
local btnSwitchList = NewButton("Next List Target (Gold ESP)", UtilityCol, Color3.fromRGB(200, 160, 0))
local btnFling = NewButton("KILASIK Fling Target: OFF", UtilityCol, Color3.fromRGB(180, 20, 20))

local BlacklistHeader = Instance.new("TextLabel", UtilityCol)
BlacklistHeader.Size = UDim2.new(0, 290, 0, 30)
BlacklistHeader.BackgroundTransparency = 1
BlacklistHeader.Text = "CLICK PLAYER TO BLACKLIST"
BlacklistHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
BlacklistHeader.Font = Enum.Font.GothamBold
BlacklistHeader.TextSize = 14

local BlacklistContainer = Instance.new("Frame", UtilityCol)
BlacklistContainer.Size = UDim2.new(0, 290, 0, 250)
BlacklistContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
local BlcCorner = Instance.new("UICorner", BlacklistContainer); BlcCorner.CornerRadius = UDim.new(0, 8)
local BlcStroke = Instance.new("UIStroke", BlacklistContainer); BlcStroke.Color = Color3.fromRGB(100, 100, 150); BlcStroke.Thickness = 1.5

local BlacklistScroll = Instance.new("ScrollingFrame", BlacklistContainer)
BlacklistScroll.Size = UDim2.new(1, -10, 1, -10)
BlacklistScroll.Position = UDim2.new(0, 5, 0, 5)
BlacklistScroll.BackgroundTransparency = 1
BlacklistScroll.ScrollBarThickness = 4
BlacklistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local BlcListLayout = Instance.new("UIListLayout", BlacklistScroll)
BlcListLayout.Padding = UDim.new(0, 5)

-- Logic Bảng Blacklist Động (Cập nhật liên tục)
local function RefreshBlacklistUI()
    for _, child in pairs(BlacklistScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local allPlayers = Players:GetPlayers()
    table.sort(allPlayers, function(a, b) return a.Name:lower() < b.Name:lower() end)
    
    local ySize = 0
    for _, p in ipairs(allPlayers) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, 0, 0, 30)
            pBtn.Font = Enum.Font.GothamSemibold
            pBtn.TextSize = 14
            pBtn.Parent = BlacklistScroll
            
            local isBlacklisted = _G.GalaxySettings.Blacklist[p.UserId]
            if isBlacklisted then
                pBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
                pBtn.Text = "⛔ " .. p.Name
            else
                pBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                pBtn.Text = p.Name
            end
            pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            local pBtnCorner = Instance.new("UICorner", pBtn)
            pBtnCorner.CornerRadius = UDim.new(0, 4)
            
            pBtn.MouseButton1Click:Connect(function()
                if _G.GalaxySettings.Blacklist[p.UserId] then
                    _G.GalaxySettings.Blacklist[p.UserId] = nil
                else
                    _G.GalaxySettings.Blacklist[p.UserId] = true
                    if Target_List == p then Target_List = nil end
                    if Target_Pov == p then Target_Pov = nil end
                end
                RefreshBlacklistUI()
                UpdateValidPlayerList()
            end)
            ySize = ySize + 35
        end
    end
    BlacklistScroll.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

Players.PlayerAdded:Connect(RefreshBlacklistUI)
Players.PlayerRemoving:Connect(RefreshBlacklistUI)
RefreshBlacklistUI()

-- [PHẦN 8: HỆ THỐNG ESP DUAL-COLOR VÀ BLACKLIST VISUALS]
local function UpdateEspVisuals()
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local p = allPlayers[i]
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local highlight = char:FindFirstChild("Galaxy_Highlight")
            
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "Galaxy_Highlight"
                highlight.Parent = char
            end
            
            if _G.GalaxySettings.Blacklist[p.UserId] then
                highlight.Enabled = false
            elseif p == Target_List then
                highlight.Enabled = true
                highlight.FillColor = Color3.fromRGB(255, 255, 0) 
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.2
                highlight.OutlineTransparency = 0
            elseif p == Target_Pov then
                highlight.Enabled = true
                highlight.FillColor = Color3.fromRGB(255, 255, 255) 
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.FillTransparency = 0.2
                highlight.OutlineTransparency = 0
            elseif _G.GalaxySettings.EspGlobalEnabled then
                highlight.Enabled = true
                if p.Team == LocalPlayer.Team then
                    highlight.FillColor = Color3.fromRGB(0, 255, 0) 
                else
                    highlight.FillColor = Color3.fromRGB(255, 0, 0) 
                end
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0.5
            else
                highlight.Enabled = false
            end
        end
    end
end

task.spawn(function()
    while true do
        UpdateValidPlayerList()
        UpdateEspVisuals()
        task.wait(0.5)
    end
end)

-- [PHẦN 9: AUTO-SWITCH TARGET & LOGIC AIMBOT POV]
RunService.Heartbeat:Connect(function()
    if Target_List and Target_List.Character then
        local hum = Target_List.Character:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then
            UpdateValidPlayerList()
            if #ValidPlayers > 0 then
                CurrentIndex = (CurrentIndex % #ValidPlayers) + 1
                Target_List = ValidPlayers[CurrentIndex]
            else
                Target_List = nil
            end
        end
    end
end)

local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 2
FovCircle.Color = Color3.new(1, 1, 1)
FovCircle.Filled = false
FovCircle.Transparency = 0.7
FovCircle.Visible = false

local function FetchPovTarget()
    local closestTarget = nil
    local shortestDistance = (tonumber(boxPovRad.Text) or 40) * 5
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not _G.GalaxySettings.Blacklist[p.UserId] and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(PlayerMouse.X, PlayerMouse.Y)).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = p
                end
            end
        end
    end
    return closestTarget
end

RunService.RenderStepped:Connect(function()
    FovCircle.Radius = (tonumber(boxPovRad.Text) or 40) * 5
    FovCircle.Position = Vector2.new(PlayerMouse.X, PlayerMouse.Y + 36)
    FovCircle.Visible = _G.GalaxySettings.AimbotPovEnabled
    
    if _G.GalaxySettings.AimbotPovEnabled then
        Target_Pov = FetchPovTarget()
        if Target_Pov and Target_Pov.Character and Target_Pov.Character:FindFirstChild("Head") then
            local hum = Target_Pov.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, Target_Pov.Character.Head.Position)
            end
        end
    else
        Target_Pov = nil
    end
end)

-- [PHẦN 10: LOGIC LIST TARGET & AIMBODY BEHIND SIÊU TỐC]
-- Nâng cấp: Luôn Aimbot ra sau lưng mục tiêu (cách 3 studs) và áp đặt ngay lập tức
RunService.RenderStepped:Connect(function()
    if _G.GalaxySettings.AimBodyEnabled and Target_List and Target_List.Character then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tarRoot = Target_List.Character:FindFirstChild("HumanoidRootPart")
        local hum = Target_List.Character:FindFirstChild("Humanoid")
        
        if myRoot and tarRoot and hum and hum.Health > 0 then
            -- Tính toán CFrame sau lưng mục tiêu (hướng dương Z trong Object Space)
            local behindCFrame = tarRoot.CFrame * CFrame.new(0, 0, 3)
            -- Hướng mặt về phía mục tiêu
            myRoot.CFrame = CFrame.new(behindCFrame.Position, tarRoot.Position)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if _G.GalaxySettings.FollowEnabled and Target_List and Target_List.Character then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tarRoot = Target_List.Character:FindFirstChild("HumanoidRootPart")
        local hum = Target_List.Character:FindFirstChild("Humanoid")
        
        if myRoot and tarRoot and hum and hum.Health > 0 then
            local offset = Vector3.new(tonumber(boxOffX.Text) or 0, tonumber(boxOffY.Text) or 7, tonumber(boxOffZ.Text) or 0)
            local destination = tarRoot.CFrame * CFrame.new(offset)
            
            if _G.GalaxySettings.TpMode == "Instant" then
                myRoot.CFrame = destination
            else
                local s = (tonumber(boxTpSpeed.Text) or 480) / 1000
                myRoot.CFrame = myRoot.CFrame:Lerp(destination, s)
            end
        end
    end
end)

-- [PHẦN 11: LOGIC KILASIK FLING (THAY THẾ FLING CŨ)]
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local function SkidFlingTarget(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THumanoid and THumanoid.Sit then return end
        
        if THead then workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then workspace.CurrentCamera.CameraSubject = THumanoid end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not _G.GalaxySettings.FlingTargetEnabled or Target_List ~= TargetPlayer
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart then SFBasePart(TRootPart)
        elseif THead then SFBasePart(THead)
        elseif Handle then SFBasePart(Handle) end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end
end

-- Tiến trình chạy Fling độc lập
task.spawn(function()
    while true do
        if _G.GalaxySettings.FlingTargetEnabled and Target_List then
            SkidFlingTarget(Target_List)
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- [PHẦN 12: LOGIC SPEED HACK (4 LOẠI) VÀ FLY HACK (2 LOẠI)]
local FlyBodyVel = nil
local FlyGyro = nil
local isFlyingType2 = false

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    
    -- Xử lý Speed Hacks
    local speedVal = tonumber(boxSpeedVal.Text) or 16.00000000
    
    if _G.GalaxySettings.SpeedTypes.Type1_Walk then
        hum.WalkSpeed = speedVal
    end
    
    if hum.MoveDirection.Magnitude > 0 then
        if _G.GalaxySettings.SpeedTypes.Type2_CFrame then
            root.CFrame = root.CFrame + (hum.MoveDirection * (speedVal * 0.01))
        end
        if _G.GalaxySettings.SpeedTypes.Type3_Velocity then
            root.Velocity = Vector3.new(hum.MoveDirection.X * speedVal, root.Velocity.Y, hum.MoveDirection.Z * speedVal)
        end
        if _G.GalaxySettings.SpeedTypes.Type4_Vector then
            root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * speedVal, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * speedVal)
        end
    end
    
    -- Xử lý Fly Hacks
    local flyVal = tonumber(boxFlyVal.Text) or 50.00000000
    local camCFrame = CurrentCamera.CFrame
    local moveDir = Vector3.new(0,0,0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
    
    if _G.GalaxySettings.FlyTypes.Type1_BodyVel then
        if not FlyBodyVel then
            FlyBodyVel = Instance.new("BodyVelocity", root)
            FlyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyGyro = Instance.new("BodyGyro", root)
            FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyGyro.P = 9e4
        end
        hum.PlatformStand = true
        FlyBodyVel.Velocity = moveDir * flyVal
        FlyGyro.CFrame = camCFrame
    else
        if FlyBodyVel then
            FlyBodyVel:Destroy(); FlyBodyVel = nil
            FlyGyro:Destroy(); FlyGyro = nil
            hum.PlatformStand = false
        end
    end
    
    if _G.GalaxySettings.FlyTypes.Type2_CFrame then
        hum.PlatformStand = true
        root.Anchored = true
        root.CFrame = root.CFrame + (moveDir * (flyVal * 0.02))
        root.CFrame = CFrame.new(root.Position, root.Position + camCFrame.LookVector)
        isFlyingType2 = true
    elseif isFlyingType2 then
        root.Anchored = false
        hum.PlatformStand = false
        isFlyingType2 = false
    end
end)

-- [PHẦN 13: XỬ LÝ SỰ KIỆN NÚT BẤM (BUTTON EVENTS)]
boxSpeedVal.FocusLost:Connect(function()
    local val = tonumber(boxSpeedVal.Text)
    if val then
        boxSpeedVal.Text = string.format("%.8f", val)
        _G.GalaxySettings.SpeedValue = val
    end
end)

boxFlyVal.FocusLost:Connect(function()
    local val = tonumber(boxFlyVal.Text)
    if val then
        boxFlyVal.Text = string.format("%.8f", val)
        _G.GalaxySettings.FlyValue = val
    end
end)

btnSpeed1.MouseButton1Click:Connect(function()
    _G.GalaxySettings.SpeedTypes.Type1_Walk = not _G.GalaxySettings.SpeedTypes.Type1_Walk
    btnSpeed1.Text = "Speed Type 1 (WalkSpeed): " .. (_G.GalaxySettings.SpeedTypes.Type1_Walk and "ON" or "OFF")
end)
btnSpeed2.MouseButton1Click:Connect(function()
    _G.GalaxySettings.SpeedTypes.Type2_CFrame = not _G.GalaxySettings.SpeedTypes.Type2_CFrame
    btnSpeed2.Text = "Speed Type 2 (CFrame): " .. (_G.GalaxySettings.SpeedTypes.Type2_CFrame and "ON" or "OFF")
end)
btnSpeed3.MouseButton1Click:Connect(function()
    _G.GalaxySettings.SpeedTypes.Type3_Velocity = not _G.GalaxySettings.SpeedTypes.Type3_Velocity
    btnSpeed3.Text = "Speed Type 3 (Velocity): " .. (_G.GalaxySettings.SpeedTypes.Type3_Velocity and "ON" or "OFF")
end)
btnSpeed4.MouseButton1Click:Connect(function()
    _G.GalaxySettings.SpeedTypes.Type4_Vector = not _G.GalaxySettings.SpeedTypes.Type4_Vector
    btnSpeed4.Text = "Speed Type 4 (Vector3): " .. (_G.GalaxySettings.SpeedTypes.Type4_Vector and "ON" or "OFF")
end)
btnFly1.MouseButton1Click:Connect(function()
    _G.GalaxySettings.FlyTypes.Type1_BodyVel = not _G.GalaxySettings.FlyTypes.Type1_BodyVel
    btnFly1.Text = "Fly Type 1 (BodyVelocity): " .. (_G.GalaxySettings.FlyTypes.Type1_BodyVel and "ON" or "OFF")
end)
btnFly2.MouseButton1Click:Connect(function()
    _G.GalaxySettings.FlyTypes.Type2_CFrame = not _G.GalaxySettings.FlyTypes.Type2_CFrame
    btnFly2.Text = "Fly Type 2 (CFrame Noclip): " .. (_G.GalaxySettings.FlyTypes.Type2_CFrame and "ON" or "OFF")
end)

btnSwitchList.MouseButton1Click:Connect(function()
    UpdateValidPlayerList()
    if #ValidPlayers > 0 then
        CurrentIndex = (CurrentIndex % #ValidPlayers) + 1
        Target_List = ValidPlayers[CurrentIndex]
    end
end)

btnAimbot.MouseButton1Click:Connect(function()
    _G.GalaxySettings.AimbotPovEnabled = not _G.GalaxySettings.AimbotPovEnabled
    btnAimbot.Text = "Aimbot POV (Mouse): " .. (_G.GalaxySettings.AimbotPovEnabled and "ON" or "OFF")
end)

btnAimBody.MouseButton1Click:Connect(function()
    _G.GalaxySettings.AimBodyEnabled = not _G.GalaxySettings.AimBodyEnabled
    btnAimBody.Text = "AimBody Behind (Press E): " .. (_G.GalaxySettings.AimBodyEnabled and "ON" or "OFF")
end)

btnFollow.MouseButton1Click:Connect(function()
    _G.GalaxySettings.FollowEnabled = not _G.GalaxySettings.FollowEnabled
    btnFollow.Text = "Follow (List): " .. (_G.GalaxySettings.FollowEnabled and "ON" or "OFF")
end)

btnEspToggle.MouseButton1Click:Connect(function()
    _G.GalaxySettings.EspGlobalEnabled = not _G.GalaxySettings.EspGlobalEnabled
    btnEspToggle.Text = "ESP Auto-Refresh: " .. (_G.GalaxySettings.EspGlobalEnabled and "ON" or "OFF")
end)

btnHitbox.MouseButton1Click:Connect(function()
    _G.GalaxySettings.HitboxEnabled = not _G.GalaxySettings.HitboxEnabled
    btnHitbox.Text = "Enable Hitbox: " .. (_G.GalaxySettings.HitboxEnabled and "ON" or "OFF")
end)

btnNoclip.MouseButton1Click:Connect(function()
    _G.GalaxySettings.NoclipEnabled = not _G.GalaxySettings.NoclipEnabled
    btnNoclip.Text = "Noclip (Press N): " .. (_G.GalaxySettings.NoclipEnabled and "ON" or "OFF")
end)

btnTpType.MouseButton1Click:Connect(function()
    if _G.GalaxySettings.TpMode == "Instant" then _G.GalaxySettings.TpMode = "Tween" else _G.GalaxySettings.TpMode = "Instant" end
    btnTpType.Text = "TP Mode: " .. _G.GalaxySettings.TpMode:upper()
end)

btnFling.MouseButton1Click:Connect(function()
    _G.GalaxySettings.FlingTargetEnabled = not _G.GalaxySettings.FlingTargetEnabled
    btnFling.Text = "KILASIK Fling Target: " .. (_G.GalaxySettings.FlingTargetEnabled and "ON" or "OFF")
end)

btnExecuteTp.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local function parse(val, current)
        if val == "" then return current end
        if val:sub(1,1) == "~" then return current + (tonumber(val:sub(2)) or 0) end
        return tonumber(val) or current
    end
    
    local targetPos = Vector3.new(parse(boxTpX.Text, root.Position.X), parse(boxTpY.Text, root.Position.Y), parse(boxTpZ.Text, root.Position.Z))
    
    if _G.GalaxySettings.TpMode == "Instant" then
        root.CFrame = CFrame.new(targetPos)
    else
        local distance = (root.Position - targetPos).Magnitude
        local speed = tonumber(boxTpSpeed.Text) or 480
        local info = TweenInfo.new(distance/speed, Enum.EasingStyle.Linear)
        TweenService:Create(root, info, {CFrame = CFrame.new(targetPos)}):Play()
    end
end)

-- [PHẦN 14: INPUT TỔ HỢP PHÍM (N, K, E) VÀ TIỆN ÍCH]
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.K then 
            MainFrame.Visible = not MainFrame.Visible 
        end
        if input.KeyCode == Enum.KeyCode.N then 
            _G.GalaxySettings.NoclipEnabled = not _G.GalaxySettings.NoclipEnabled
            btnNoclip.Text = "Noclip (Press N): " .. (_G.GalaxySettings.NoclipEnabled and "ON" or "OFF")
        end
        if input.KeyCode == Enum.KeyCode.E then
            _G.GalaxySettings.AimBodyEnabled = not _G.GalaxySettings.AimBodyEnabled
            btnAimBody.Text = "AimBody Behind (Press E): " .. (_G.GalaxySettings.AimBodyEnabled and "ON" or "OFF")
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if _G.GalaxySettings.HitboxEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not _G.GalaxySettings.Blacklist[p.UserId] and p.Character then
                pcall(function()
                    local head = p.Character:FindFirstChild("Head")
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    local hS = tonumber(boxHbHead.Text) or 5
                    local bS = tonumber(boxHbBody.Text) or 5
                    
                    if head then head.Size = Vector3.new(hS, hS, hS); head.Transparency = 0.7; head.CanCollide = false end
                    if root then root.Size = Vector3.new(bS, bS, bS); root.Transparency = 0.7; root.CanCollide = false end
                end)
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G.GalaxySettings.NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- [PHẦN CUỐI: CẬP NHẬT HUD TỐI ƯU VÀ KHỞI CHẠY]
RunService.RenderStepped:Connect(function(deltaTime)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local listName = (Target_List and Target_List.Name) or "NONE"
        local povName = (Target_Pov and Target_Pov.Name) or "NONE"
        
        InfoLabel.Text = string.format(
            "GALAXY APEX V27 | FPS: %d\nPOS: X:%.1f Y:%.1f Z:%.1f\n[GOLD] LIST TARGET: %s\n[WHITE] POV TARGET: %s",
            1/deltaTime, root.Position.X, root.Position.Y, root.Position.Z, listName, povName
        )
    end
end)

UpdateValidPlayerList()
