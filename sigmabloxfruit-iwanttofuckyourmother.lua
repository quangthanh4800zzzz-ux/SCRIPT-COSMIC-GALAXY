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

local Player = Players.LocalPlayer

-- [[ BIẾN CẤU HÌNH TOÀN CỤC ]]
_G.CFrameSpeedValue = 0 
_G.MaxLimit = 4800 
_G.JumpPowerValue = 0
_G.MaxJumpLimit = 480
_G.IsActive = true

local FastAttackEnabled = false
local HitboxActive = false
local HitboxValue = 0
local AttackValue = 0 -- Giá trị này giờ có thể thay đổi qua GUI

-- Remote chuẩn của Blox Fruits
local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
local RegisterHit = ReplicatedStorage.Modules.Net["RE/RegisterHit"]

-- SETTINGS TỐI ƯU
local AttackDistance = 400

-- [[ 1. TẠO GUI HIỂN THỊ FPS & PING ]]
local InfoGui = Instance.new("ScreenGui", CoreGui)
InfoGui.Name = "THANH_DB4800_INFO"

local InfoFrame = Instance.new("Frame", InfoGui)
InfoFrame.Size = UDim2.new(0, 120, 0, 50)
InfoFrame.Position = UDim2.new(0, 10, 0, 10)
InfoFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
InfoFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 6)
local InfoStroke = Instance.new("UIStroke", InfoFrame)
InfoStroke.Color = Color3.fromRGB(0, 255, 255)
InfoStroke.Thickness = 1.5

local FPSLabel = Instance.new("TextLabel", InfoFrame)
FPSLabel.Size = UDim2.new(1, 0, 0.5, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 60"
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 12

local PingLabel = Instance.new("TextLabel", InfoFrame)
PingLabel.Size = UDim2.new(1, 0, 0.5, 0)
PingLabel.Position = UDim2.new(0, 0, 0.5, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: 0 ms"
PingLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 12

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
    FPSLabel.Text = string.format("FPS: %d", math.floor(avgFps))
    PingLabel.Text = string.format("Ping: %d ms", math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
end)

-- [[ 2. TẠO GIAO DIỆN NGƯỜI DÙNG CHÍNH ]]
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "THANH_DB4800_HUB_PRO"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.4, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 750) -- Tăng thêm chiều cao để chứa Attack Value
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 255, 255)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Text = "PREMIUM BLOX HUB V3"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18 

local TargetLabel = Instance.new("TextLabel", MainFrame)
TargetLabel.Position = UDim2.new(0.05, 0, 0.07, 0)
TargetLabel.Size = UDim2.new(0.9, 0, 0, 40)
TargetLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
TargetLabel.Text = "TARGET: FAST M1 OFF"
TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 14 
Instance.new("UICorner", TargetLabel)

local FastBtn = Instance.new("TextButton", MainFrame)
FastBtn.Position = UDim2.new(0.05, 0, 0.13, 0)
FastBtn.Size = UDim2.new(0.9, 0, 0, 40)
FastBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
FastBtn.Text = "FAST ATTACK: OFF (G)"
FastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FastBtn.Font = Enum.Font.GothamBold
FastBtn.TextSize = 14 
Instance.new("UICorner", FastBtn)

-- PHẦN ATTACK VALUE (MỚI)
local AttackValueInput = Instance.new("TextBox", MainFrame)
AttackValueInput.Position = UDim2.new(0.05, 0, 0.20, 0)
AttackValueInput.Size = UDim2.new(0.9, 0, 0, 40)
AttackValueInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
AttackValueInput.PlaceholderText = "ATTACK VALUE (0 - 100)"
AttackValueInput.Text = ""
AttackValueInput.TextColor3 = Color3.fromRGB(255, 255, 255)
AttackValueInput.Font = Enum.Font.GothamBold
AttackValueInput.TextSize = 14 
Instance.new("UICorner", AttackValueInput)

local AttackStatus = Instance.new("TextLabel", MainFrame)
AttackStatus.Position = UDim2.new(0, 0, 0.26, 0)
AttackStatus.Size = UDim2.new(1, 0, 0, 20)
AttackStatus.BackgroundTransparency = 1
AttackStatus.Text = "Attack Value hiện tại: 0"
AttackStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
AttackStatus.TextSize = 14 

-- PHẦN SPEED
local SpeedInput = Instance.new("TextBox", MainFrame)
SpeedInput.Position = UDim2.new(0.05, 0, 0.31, 0)
SpeedInput.Size = UDim2.new(0.9, 0, 0, 40)
SpeedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SpeedInput.PlaceholderText = "NHẬP SPEED (0 - 4800)"
SpeedInput.Text = ""
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.TextSize = 14 
Instance.new("UICorner", SpeedInput)

local SpeedStatus = Instance.new("TextLabel", MainFrame)
SpeedStatus.Position = UDim2.new(0, 0, 0.37, 0)
SpeedStatus.Size = UDim2.new(1, 0, 0, 20)
SpeedStatus.BackgroundTransparency = 1
SpeedStatus.Text = "Tốc độ hiện tại: 0"
SpeedStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedStatus.TextSize = 14 

-- PHẦN JUMP
local JumpInput = Instance.new("TextBox", MainFrame)
JumpInput.Position = UDim2.new(0.05, 0, 0.42, 0)
JumpInput.Size = UDim2.new(0.9, 0, 0, 40)
JumpInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
JumpInput.PlaceholderText = "NHẬP NHẢY CAO (0 - 480)"
JumpInput.Text = ""
JumpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpInput.Font = Enum.Font.GothamBold
JumpInput.TextSize = 14 
Instance.new("UICorner", JumpInput)

local JumpStatus = Instance.new("TextLabel", MainFrame)
JumpStatus.Position = UDim2.new(0, 0, 0.48, 0)
JumpStatus.Size = UDim2.new(1, 0, 0, 20)
JumpStatus.BackgroundTransparency = 1
JumpStatus.Text = "Sức nhảy hiện tại: 0"
JumpStatus.TextColor3 = Color3.fromRGB(0, 255, 255)
JumpStatus.TextSize = 14 

-- PHẦN HITBOX
local HitboxBtn = Instance.new("TextButton", MainFrame)
HitboxBtn.Position = UDim2.new(0.05, 0, 0.54, 0)
HitboxBtn.Size = UDim2.new(0.9, 0, 0, 40)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
HitboxBtn.Text = "HITBOX BODY: OFF"
HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextSize = 14 
Instance.new("UICorner", HitboxBtn)

local HitboxInput = Instance.new("TextBox", MainFrame)
HitboxInput.Position = UDim2.new(0.05, 0, 0.64, 0)
HitboxInput.Size = UDim2.new(0.9, 0, 0, 40)
HitboxInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
HitboxInput.PlaceholderText = "HITBOX SIZE (0 - 80)"
HitboxInput.Text = ""
HitboxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxInput.Font = Enum.Font.GothamBold
HitboxInput.TextSize = 14 
Instance.new("UICorner", HitboxInput)

local FPSBoostBtn = Instance.new("TextButton", MainFrame)
FPSBoostBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
FPSBoostBtn.Size = UDim2.new(0.9, 0, 0, 45)
FPSBoostBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
FPSBoostBtn.Text = "ULTRA FPS BOOST: OFF"
FPSBoostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSBoostBtn.Font = Enum.Font.GothamBold
FPSBoostBtn.TextSize = 16 
Instance.new("UICorner", FPSBoostBtn)

-- [[ PHẦN: ULTRA FPS BOOST ]]
local function UltraFPSBoost()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 2 
    local function Clean(v)
        if v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            if v:IsA("MeshPart") then v.TextureID = "" end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") then
            v.Enabled = false
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.Visible = false
        elseif v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
            v:Destroy()
        elseif v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
            v.Enabled = false
        end
    end
    for _, v in pairs(game:GetDescendants()) do Clean(v) end
    game.DescendantAdded:Connect(Clean)
end

-- [[ LOGIC HỆ THỐNG ]]

local function ApplyInfiniteStaminaLogic()
    local character = Player.Character
    if character then
        local energyStat = character:FindFirstChild("Energy") or character:FindFirstChild("Stamina")
        if energyStat then
            local maxEnergy = energyStat:FindFirstChild("MaxValue") or energyStat:FindFirstChild("MaxEnergy")
            if maxEnergy then energyStat.Value = maxEnergy.Value else energyStat.Value = 10000000 end
        end
    end
end

local function IsSameTeam(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    local myTeam = Player.Team
    if not myTeam then return false end
    if myTeam.Name == "Marines" then return targetPlayer.Team.Name == "Marines" end
    if myTeam.Name == "Pirates" then
        if targetPlayer.Team.Name == "Marines" then return false end
        if targetPlayer.Team.Name == "Pirates" then
            if targetPlayer == Player then return true end
            local status, isAlly = pcall(function()
                return Player:IsFriendsWith(targetPlayer.UserId) or 
                       (Player:FindFirstChild("Crew") and targetPlayer:FindFirstChild("Crew") and 
                        Player.Crew.Value ~= "" and Player.Crew.Value == targetPlayer.Crew.Value)
            end)
            return status and isAlly or targetPlayer.DisplayName == Player.DisplayName
        end
    end
    return false
end

local function IsEquippedMeleeOrSword()
    if not Player.Character then return false end
    local tool = Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword")
end

local function GetNearestTargetInRange()
    local closestPart, closestDist = nil, AttackDistance
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in pairs(enemies:GetChildren()) do
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < closestDist then closestDist = dist; closestPart = hrp end
            end
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            if p.Character.Humanoid.Health > 0 and not IsSameTeam(p) and not Player:IsFriendsWith(p.UserId) then
                local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < closestDist then closestDist = dist; closestPart = p.Character.HumanoidRootPart end
            end
        end
    end
    return closestPart
end

-- [[ LOGIC SPAM LỆNH ĐÁNH ]]
task.spawn(function()
    while true do
        if FastAttackEnabled and IsEquippedMeleeOrSword() then
            RegisterAttack:FireServer(AttackValue)
        end
        task.wait() 
    end
end)

task.spawn(function()
    while true do
        if FastAttackEnabled and IsEquippedMeleeOrSword() then
            local target = GetNearestTargetInRange()
            if target then RegisterHit:FireServer(target, {}, { [4] = "763d673c" }) end
        end
        task.wait() 
    end
end)

-- VÒNG LẶP HEARTBEAT
RunService.Heartbeat:Connect(function()
    ApplyInfiniteStaminaLogic()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local hum = Player.Character.Humanoid
        if _G.JumpPowerValue > 0 then
            hum.UseJumpPower = true
            hum.JumpPower = _G.JumpPowerValue
        else
            hum.UseJumpPower = false 
        end
    end
    if FastAttackEnabled then
        local target = GetNearestTargetInRange()
        if target then
            TargetLabel.Text = "TARGET: " .. target.Parent.Name:upper()
            TargetLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
        else
            TargetLabel.Text = "ĐANG ĐỢI MỤC TIÊU..."
            TargetLabel.TextColor3 = Color3.fromRGB(0, 191, 255)
        end
    end
end)

-- LOGIC NHẬP ATTACK VALUE (MỚI)
AttackValueInput.FocusLost:Connect(function()
    local num = tonumber(AttackValueInput.Text)
    if num then AttackValue = math.max(0, num) else AttackValue = 0 end
    AttackValueInput.Text = tostring(AttackValue)
    AttackStatus.Text = "Attack Value hiện tại: " .. tostring(AttackValue)
end)

-- LOGIC SPEED
SpeedInput.FocusLost:Connect(function()
    local num = tonumber(SpeedInput.Text)
    if num then _G.CFrameSpeedValue = math.clamp(num, 0, _G.MaxLimit) else _G.CFrameSpeedValue = 0 end
    SpeedInput.Text = tostring(_G.CFrameSpeedValue)
    SpeedStatus.Text = "Tốc độ hiện tại: " .. tostring(_G.CFrameSpeedValue)
end)

RunService.Stepped:Connect(function()
    if _G.IsActive and _G.CFrameSpeedValue > 0 and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid") then
        local root = Player.Character.HumanoidRootPart
        local hum = Player.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (_G.CFrameSpeedValue / 10))
        end
    end
end)

-- LOGIC JUMP POWER
JumpInput.FocusLost:Connect(function()
    local num = tonumber(JumpInput.Text)
    if num then _G.JumpPowerValue = math.clamp(num, 0, _G.MaxJumpLimit) else _G.JumpPowerValue = 0 end
    JumpInput.Text = tostring(_G.JumpPowerValue)
    JumpStatus.Text = "Sức nhảy hiện tại: " .. tostring(_G.JumpPowerValue)
end)

-- LOGIC HITBOX
HitboxInput.FocusLost:Connect(function()
    local num = tonumber(HitboxInput.Text)
    HitboxValue = (num and num >= 0 and num <= 80) and num or 0
    HitboxInput.Text = tostring(HitboxValue)
end)

RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            if not Player:IsFriendsWith(p.UserId) then
                if HitboxActive and HitboxValue > 0 then
                    hrp.Size = Vector3.new(HitboxValue, HitboxValue, HitboxValue)
                    hrp.Transparency = 0.6
                    hrp.Color = Color3.fromRGB(255, 0, 0)
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
    end
end)

-- [[ ĐIỀU KHIỂN GUI & PHÍM TẮT ]]

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

FPSBoostBtn.MouseButton1Click:Connect(function()
    FPSBoostBtn.Text = "ULTRA BOOST ACTIVE!"
    FPSBoostBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    UltraFPSBoost()
end)

local function ToggleFast()
    FastAttackEnabled = not FastAttackEnabled
    FastBtn.Text = FastAttackEnabled and "FAST ATTACK: ON (G)" or "FAST ATTACK: OFF (G)"
    FastBtn.BackgroundColor3 = FastAttackEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(35, 35, 35)
end

FastBtn.MouseButton1Click:Connect(ToggleFast)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.G then ToggleFast() end
end)

HitboxBtn.MouseButton1Click:Connect(function()
    HitboxActive = not HitboxActive
    HitboxBtn.Text = HitboxActive and "HITBOX: BẬT" or "HITBOX: TẮT"
    HitboxBtn.BackgroundColor3 = HitboxActive and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)
