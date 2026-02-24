-- [[ ====================================================================================== ]]
-- [[ SCRIPT: GALAXYAPEX_V25 - PHIÊN BẢN CẤU TRÚC MỞ RỘNG TOÀN DIỆN                      ]]
-- [[ TÁC GIẢ: THÀNH_ĐB                                                                   ]]
-- [[ NGÀY CẬP NHẬT: 07/01/2026                                                           ]]
-- [[ MÔ TẢ: PHÂN TÁCH MỤC TIÊU LIST (VÀNG) VÀ POV (TRẮNG), TỰ ĐỘNG CẬP NHẬT DANH SÁCH   ]]
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
-- Lưu trữ mọi trạng thái trong một bảng lớn để dễ dàng quản lý và truy xuất
local _G_GalaxySettings = {
    -- Trạng thái Combat
    AimbotPovEnabled = false,
    AimBodyEnabled = false,
    FollowEnabled = false,
    HitboxEnabled = false,
    
    -- Trạng thái Visuals
    EspGlobalEnabled = false,
    EspShowTeam = false,
    FovCircleVisible = false,
    
    -- Trạng thái Movement
    NoclipEnabled = false,
    TpMode = "Instant", -- "Instant" hoặc "Tween"
    TweenSpeed = 480,
    
    -- Thông số kỹ thuật
    PovRadius = 40,
    HitboxSizeHead = 5,
    HitboxSizeBody = 5,
    FollowOffset = Vector3.new(0, 7, 0)
}

-- [PHẦN 4: HỆ THỐNG QUẢN LÝ MỤC TIÊU (TARGET MANAGEMENT)]
-- Phân tách hoàn toàn hai loại mục tiêu theo yêu cầu của người dùng
local Target_List = nil     -- Dành cho AimBody và Follow (Màu Vàng)
local Target_Pov = nil      -- Dành cho Aimbot POV (Màu Trắng)
local CurrentIndex = 1
local ValidPlayers = {}     -- Danh sách người chơi hợp lệ cập nhật liên tục

-- Hàm cập nhật danh sách người chơi từ bảng xếp hạng (Players Service)
-- Được thiết kế để chạy liên tục nhằm phát hiện người mới vào hoặc người thoát
local function UpdateValidPlayerList()
    local newList = {}
    local allPlayers = Players:GetPlayers()
    
    for i = 1, #allPlayers do
        local p = allPlayers[i]
        if p ~= LocalPlayer then
            table.insert(newList, p)
        end
    end
    
    ValidPlayers = newList
    -- Debug: print("Hệ thống: Đã cập nhật danh sách người chơi. Tổng số: " .. #ValidPlayers)
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

-- [PHẦN 6: GIAO DIỆN NGƯỜI DÙNG (USER INTERFACE)]
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "GalaxyApex_V25_Core"
MainGui.ResetOnSpawn = false
MainGui.Enabled = false
MainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
task.delay(5, function() MainGui.Enabled = true end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "ControlPanel"
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
MainFrame.Size = UDim2.new(0, 680, 0, 620)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -310)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = MainGui

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 3
MainStroke.Color = Color3.fromRGB(255, 0, 100)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Hàm tạo các cột Scrolling Frame chi tiết
local function CreateCategoryColumn(title, position)
    local Container = Instance.new("Frame", MainFrame)
    Container.Size = UDim2.new(0, 320, 0, 500)
    Container.Position = position
    Container.BackgroundTransparency = 1
    
    local Header = Instance.new("TextLabel", Container)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.Text = ":: " .. title .. " ::"
    Header.TextColor3 = Color3.fromRGB(255, 0, 150)
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 20
    Header.BackgroundTransparency = 1
    
    local Scroll = Instance.new("ScrollingFrame", Container)
    Scroll.Size = UDim2.new(1, 0, 1, -50)
    Scroll.Position = UDim2.new(0, 0, 0, 50)
    Scroll.BackgroundTransparency = 1
    Scroll.CanvasSize = UDim2.new(0, 0, 3, 0)
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 100)
    
    local List = Instance.new("UIListLayout", Scroll)
    List.Padding = UDim.new(0, 10)
    List.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    return Scroll
end

local CombatCol = CreateCategoryColumn("COMBAT SYSTEMS", UDim2.new(0, 15, 0, 100))
local MovementCol = CreateCategoryColumn("MOVEMENT SYSTEMS", UDim2.new(0, 345, 0, 100))

-- Hàm tạo Button và TextBox chi tiết (Không rút gọn)
local function NewButton(text, parent, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 290, 0, 40)
    b.BackgroundColor3 = color or Color3.fromRGB(25, 25, 35)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local function NewTextBox(placeholder, parent)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(0, 290, 0, 35)
    t.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    t.PlaceholderText = placeholder
    t.Text = ""
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.Code
    t.TextSize = 14
    t.Parent = parent
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    return t
end

-- [PHẦN 7: KHỞI TẠO CÁC NÚT ĐIỀU KHIỂN]
local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 90)
InfoLabel.Position = UDim2.new(0, 0, 0, 5)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.new(1, 1, 1)
InfoLabel.Font = Enum.Font.GothamBold
InfoHudTextSize = 15

-- Cột Combat
local boxHbHead = NewTextBox("Hitbox Head Size (Default: 5)", CombatCol); boxHbHead.Text = "5"
local boxHbBody = NewTextBox("Hitbox Body Size (Default: 5)", CombatCol); boxHbBody.Text = "5"
local btnHitbox = NewButton("ENABLE HITBOX: OFF", CombatCol, Color3.fromRGB(150, 20, 20))
local btnAimBody = NewButton("AIMBODY (LIST TARGET): OFF", CombatCol, Color3.fromRGB(180, 120, 0))
local btnAimbot = NewButton("AIMBOT POV (MOUSE): OFF", CombatCol, Color3.fromRGB(220, 50, 0))
local boxPovRad = NewTextBox("POV Circle Radius (40)", CombatCol); boxPovRad.Text = "40"
local btnEspToggle = NewButton("ESP AUTO-REFRESH: OFF", CombatCol, Color3.fromRGB(80, 0, 180))

-- Cột Movement
local btnNoclip = NewButton("NOCLIP (Press N): OFF", MovementCol)
local boxTpX = NewTextBox("Target X Coordinate", MovementCol)
local boxTpY = NewTextBox("Target Y Coordinate", MovementCol)
local boxTpZ = NewTextBox("Target Z Coordinate", MovementCol)
local btnTpType = NewButton("TP MODE: INSTANT", MovementCol, Color3.fromRGB(50, 60, 100))
local boxTpSpeed = NewTextBox("Tween Speed (480)", MovementCol); boxTpSpeed.Text = "480"
local btnExecuteTp = NewButton("EXECUTE TELEPORT", MovementCol, Color3.fromRGB(0, 140, 140))
local boxOffX = NewTextBox("Follow Offset X (0)", MovementCol); boxOffX.Text = "0"
local boxOffY = NewTextBox("Follow Offset Y (7)", MovementCol); boxOffY.Text = "7"
local boxOffZ = NewTextBox("Follow Offset Z (0)", MovementCol); boxOffZ.Text = "0"
local btnFollow = NewButton("FOLLOW (LIST TARGET): OFF", MovementCol, Color3.fromRGB(180, 0, 180))
local btnSwitchList = NewButton("NEXT LIST TARGET (GOLD ESP)", MovementCol, Color3.fromRGB(200, 160, 0))

-- [PHẦN 8: HỆ THỐNG ESP DUAL-COLOR (VÀNG & TRẮNG)]
-- Đây là phần quan trọng nhất để giải quyết vấn đề "lỏ" của ESP
local function UpdateEspVisuals()
    local allPlayers = Players:GetPlayers()
    
    for i = 1, #allPlayers do
        local p = allPlayers[i]
        
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local highlight = char:FindFirstChild("Galaxy_Highlight")
            
            -- Nếu chưa có Highlight thì tạo mới
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "Galaxy_Highlight"
                highlight.Parent = char
            end
            
            -- LOGIC PHÂN TÁCH MÀU SẮC CHI TIẾT
            if p == Target_List then
                -- ƯU TIÊN 1: MỤC TIÊU BẢNG XẾP HẠNG -> MÀU VÀNG
                highlight.Enabled = true
                highlight.FillColor = Color3.fromRGB(255, 255, 0) -- Vàng nguyên bản
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.2
                highlight.OutlineTransparency = 0
                
            elseif p == Target_Pov then
                -- ƯU TIÊN 2: MỤC TIÊU POV CHUỘT -> MÀU TRẮNG
                highlight.Enabled = true
                highlight.FillColor = Color3.fromRGB(255, 255, 255) -- Trắng nguyên bản
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.FillTransparency = 0.2
                highlight.OutlineTransparency = 0
                
            elseif _G_GalaxySettings.EspGlobalEnabled then
                -- ƯU TIÊN 3: NGƯỜI CHƠI BÌNH THƯỜNG -> MÀU THEO TEAM
                highlight.Enabled = true
                if p.Team == LocalPlayer.Team then
                    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Xanh lá (Đồng đội)
                else
                    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Đỏ (Kẻ địch)
                end
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0.5
            else
                -- TẮT NẾU KHÔNG CÓ NHU CẦU
                highlight.Enabled = false
            end
        end
    end
end

-- Vòng lặp quét liên tục (Cập nhật danh sách + ESP)
task.spawn(function()
    while true do
        UpdateValidPlayerList()
        UpdateEspVisuals()
        task.wait(0.5) -- Tần suất 2 lần/giây để không gây lag nhưng vẫn đủ nhanh
    end
end)

-- [PHẦN 9: LOGIC AIMBOT POV ĐỘC LẬP (MÀU TRẮNG)]
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
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
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
    FovCircle.Visible = _G_GalaxySettings.AimbotPovEnabled
    
    if _G_GalaxySettings.AimbotPovEnabled then
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

-- [PHẦN 10: LOGIC LIST TARGET (MÀU VÀNG) - AIMBODY & FOLLOW]
-- Hai tính năng này dùng chung mục tiêu List

-- Xử lý AimBody (Xoay nhân vật về phía mục tiêu Vàng)
RunService.RenderStepped:Connect(function()
    if _G_GalaxySettings.AimBodyEnabled and Target_List and Target_List.Character then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tarRoot = Target_List.Character:FindFirstChild("HumanoidRootPart")
        local hum = Target_List.Character:FindFirstChild("Humanoid")
        
        if myRoot and tarRoot and hum and hum.Health > 0 then
            local direction = Vector3.new(tarRoot.Position.X, myRoot.Position.Y, tarRoot.Position.Z)
            myRoot.CFrame = CFrame.new(myRoot.Position, direction)
        end
    end
end)

-- Xử lý Follow (Bám sát mục tiêu Vàng)
RunService.Heartbeat:Connect(function()
    if _G_GalaxySettings.FollowEnabled and Target_List and Target_List.Character then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tarRoot = Target_List.Character:FindFirstChild("HumanoidRootPart")
        local hum = Target_List.Character:FindFirstChild("Humanoid")
        
        if myRoot and tarRoot and hum and hum.Health > 0 then
            local offset = Vector3.new(tonumber(boxOffX.Text) or 0, tonumber(boxOffY.Text) or 7, tonumber(boxOffZ.Text) or 0)
            local destination = tarRoot.CFrame * CFrame.new(offset)
            
            if _G_GalaxySettings.TpMode == "Instant" then
                myRoot.CFrame = destination
            else
                local s = (tonumber(boxTpSpeed.Text) or 480) / 1000
                myRoot.CFrame = myRoot.CFrame:Lerp(destination, s)
            end
        end
    end
end)

-- [PHẦN 11: XỬ LÝ SỰ KIỆN TƯƠNG TÁC (BUTTON EVENTS)]
btnSwitchList.MouseButton1Click:Connect(function()
    UpdateValidPlayerList()
    if #ValidPlayers > 0 then
        CurrentIndex = (CurrentIndex % #ValidPlayers) + 1
        Target_List = ValidPlayers[CurrentIndex]
    end
end)

btnAimbot.MouseButton1Click:Connect(function()
    _G_GalaxySettings.AimbotPovEnabled = not _G_GalaxySettings.AimbotPovEnabled
    btnAimbot.Text = "AIMBOT POV (MOUSE): " .. (_G_GalaxySettings.AimbotPovEnabled and "ON" or "OFF")
end)

btnAimBody.MouseButton1Click:Connect(function()
    _G_GalaxySettings.AimBodyEnabled = not _G_GalaxySettings.AimBodyEnabled
    btnAimBody.Text = "AIMBODY (LIST): " .. (_G_GalaxySettings.AimBodyEnabled and "ON" or "OFF")
end)

btnFollow.MouseButton1Click:Connect(function()
    _G_GalaxySettings.FollowEnabled = not _G_GalaxySettings.FollowEnabled
    btnFollow.Text = "FOLLOW (LIST): " .. (_G_GalaxySettings.FollowEnabled and "ON" or "OFF")
end)

btnEspToggle.MouseButton1Click:Connect(function()
    _G_GalaxySettings.EspGlobalEnabled = not _G_GalaxySettings.EspGlobalEnabled
    btnEspToggle.Text = "ESP AUTO-REFRESH: " .. (_G_GalaxySettings.EspGlobalEnabled and "ON" or "OFF")
end)

btnHitbox.MouseButton1Click:Connect(function()
    _G_GalaxySettings.HitboxEnabled = not _G_GalaxySettings.HitboxEnabled
    btnHitbox.Text = "ENABLE HITBOX: " .. (_G_GalaxySettings.HitboxEnabled and "ON" or "OFF")
end)

btnNoclip.MouseButton1Click:Connect(function()
    _G_GalaxySettings.NoclipEnabled = not _G_GalaxySettings.NoclipEnabled
    btnNoclip.Text = "NOCLIP (Press N): " .. (_G_GalaxySettings.NoclipEnabled and "ON" or "OFF")
end)

btnTpType.MouseButton1Click:Connect(function()
    if _G_GalaxySettings.TpMode == "Instant" then
        _G_GalaxySettings.TpMode = "Tween"
    else
        _G_GalaxySettings.TpMode = "Instant"
    end
    btnTpType.Text = "TP MODE: " .. _G_GalaxySettings.TpMode:upper()
end)

-- Xử lý Teleport To Coordinates
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
    
    if _G_GalaxySettings.TpMode == "Instant" then
        root.CFrame = CFrame.new(targetPos)
    else
        local distance = (root.Position - targetPos).Magnitude
        local speed = tonumber(boxTpSpeed.Text) or 480
        local info = TweenInfo.new(distance/speed, Enum.EasingStyle.Linear)
        TweenService:Create(root, info, {CFrame = CFrame.new(targetPos)}):Play()
    end
end)

-- [PHẦN 12: TIỆN ÍCH HITBOX & NOCLIP & FPS]
RunService.Heartbeat:Connect(function()
    if _G_GalaxySettings.HitboxEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
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

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.K then MainFrame.Visible = not MainFrame.Visible end
        if input.KeyCode == Enum.KeyCode.N then 
            _G_GalaxySettings.NoclipEnabled = not _G_GalaxySettings.NoclipEnabled
            btnNoclip.Text = "NOCLIP (Press N): " .. (_G_GalaxySettings.NoclipEnabled and "ON" or "OFF")
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G_GalaxySettings.NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- [PHẦN CUỐI: CẬP NHẬT HUD VÀ KHỞI CHẠY]
RunService.RenderStepped:Connect(function(deltaTime)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local listName = (Target_List and Target_List.Name) or "NONE"
        local povName = (Target_Pov and Target_Pov.Name) or "NONE"
        
        InfoLabel.Text = string.format(
            "GALAXY APEX V25 | FPS: %d | PING: %dms\nPOS: X:%.1f Y:%.1f Z:%.1f\n[GOLD] LIST TARGET: %s\n[WHITE] POV TARGET: %s",
            1/deltaTime, ping, root.Position.X, root.Position.Y, root.Position.Z, listName, povName
        )
    end
end)

-- Cập nhật danh sách lần đầu tiên để tránh lỗi ListTarget là nil
UpdateValidPlayerList()
