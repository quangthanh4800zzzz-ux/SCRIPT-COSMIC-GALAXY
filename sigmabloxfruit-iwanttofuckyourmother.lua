-- [[ KHỞI TẠO DỊCH VỤ HỆ THỐNG ]]
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer

-- [[ BIẾN CẤU HÌNH TOÀN CỤC ]]
_G.CFrameSpeedValue = 0 
_G.MaxLimit = 40
_G.IsActive = true

local FastAttackEnabled = false
local HitboxActive = false
local HitboxValue = 0

-- Remote chuẩn của Blox Fruits
local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
local RegisterHit = ReplicatedStorage.Modules.Net["RE/RegisterHit"]

-- SETTINGS GỐC
local AttackValue = 0.1 
local AttacksPerLoop = 4 
local AttackDistance = 400

-- [[ 1. TẠO GUI HIỂN THỊ FPS & PING (TÁCH BIỆT) ]]
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

-- [[ 2. TẠO GIAO DIỆN NGƯỜI DÙNG CHÍNH (MAIN GUI) ]]
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "THANH_DB4800_HUB_PRO"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.4, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 450)
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
TargetLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
TargetLabel.Size = UDim2.new(0.9, 0, 0, 40)
TargetLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
TargetLabel.Text = "TARGET: FAST M1 OFF"
TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 14 
Instance.new("UICorner", TargetLabel)

local FastBtn = Instance.new("TextButton", MainFrame)
FastBtn.Position = UDim2.new(0.05, 0, 0.27, 0)
FastBtn.Size = UDim2.new(0.9, 0, 0, 40)
FastBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
FastBtn.Text = "FAST ATTACK: OFF (G)"
FastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FastBtn.Font = Enum.Font.GothamBold
FastBtn.TextSize = 14 
Instance.new("UICorner", FastBtn)

local SpeedInput = Instance.new("TextBox", MainFrame)
SpeedInput.Position = UDim2.new(0.05, 0, 0.39, 0)
SpeedInput.Size = UDim2.new(0.9, 0, 0, 40)
SpeedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SpeedInput.PlaceholderText = "NHẬP SPEED (0 - 40)"
SpeedInput.Text = ""
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.TextSize = 14 
Instance.new("UICorner", SpeedInput)

local SpeedStatus = Instance.new("TextLabel", MainFrame)
SpeedStatus.Position = UDim2.new(0, 0, 0.5, 0)
SpeedStatus.Size = UDim2.new(1, 0, 0, 20)
SpeedStatus.BackgroundTransparency = 1
SpeedStatus.Text = "Tốc độ hiện tại: 0"
SpeedStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedStatus.TextSize = 14 

local HitboxBtn = Instance.new("TextButton", MainFrame)
HitboxBtn.Position = UDim2.new(0.05, 0, 0.58, 0)
HitboxBtn.Size = UDim2.new(0.9, 0, 0, 40)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
HitboxBtn.Text = "HITBOX BODY: OFF"
HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextSize = 14 
Instance.new("UICorner", HitboxBtn)

local HitboxInput = Instance.new("TextBox", MainFrame)
HitboxInput.Position = UDim2.new(0.05, 0, 0.7, 0)
HitboxInput.Size = UDim2.new(0.9, 0, 0, 40)
HitboxInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
HitboxInput.PlaceholderText = "HITBOX SIZE (0 - 80)"
HitboxInput.Text = ""
HitboxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxInput.Font = Enum.Font.GothamBold
HitboxInput.TextSize = 14 
Instance.new("UICorner", HitboxInput)

-- [[ PHẦN: INFINITE STAMINA ]]
local function ApplyInfiniteStaminaLogic()
    local character = Player.Character
    if character then
        local energyStat = character:FindFirstChild("Energy") or character:FindFirstChild("Stamina")
        if energyStat then
            local maxEnergy = energyStat:FindFirstChild("MaxValue") or energyStat:FindFirstChild("MaxEnergy")
            if maxEnergy then
                energyStat.Value = maxEnergy.Value
            else
                energyStat.Value = 10000000
            end
        end
    end
end

-- [[ LOGIC HỆ THỐNG ]]

local function IsSameTeam(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    local myTeam = Player.Team
    if not myTeam then return false end
    
    if myTeam.Name == "Marines" then 
        return targetPlayer.Team.Name == "Marines" 
    end
    
    if myTeam.Name == "Pirates" then
        if targetPlayer.Team.Name == "Marines" then return false end
        if targetPlayer.Team.Name == "Pirates" then
            if targetPlayer == Player then return true end
            local status, isAlly = pcall(function()
                return Player:IsFriendsWith(targetPlayer.UserId) or 
                       (Player:FindFirstChild("Crew") and targetPlayer:FindFirstChild("Crew") and 
                        Player.Crew.Value ~= "" and Player.Crew.Value == targetPlayer.Crew.Value)
            end)
            if status and isAlly then return true end
            if targetPlayer.DisplayName == Player.DisplayName then return true end
        end
    end
    return false
end

local function IsEquippedMeleeOrSword()
    if not Player.Character then return false end
    local tool = Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or 
           tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword") or 
           (tool:FindFirstChild("Handle") and (tool:FindFirstChild("Attack") or tool:FindFirstChild("Main")))
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
                if dist < closestDist then 
                    closestDist = dist
                    closestPart = hrp 
                end
            end
        end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            -- Thêm kiểm tra IsFriendsWith để Fast Attack không tự động nhắm vào bạn bè
            if p.Character.Humanoid.Health > 0 and not IsSameTeam(p) and not Player:IsFriendsWith(p.UserId) then
                local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < closestDist then 
                    closestDist = dist
                    closestPart = p.Character.HumanoidRootPart 
                end
            end
        end
    end
    return closestPart
end

-- [[ VÒNG LẶP FAST ATTACK TỐC ĐỘ CAO ]]
task.spawn(function()
    while true do
        if FastAttackEnabled and IsEquippedMeleeOrSword() then
            local target = GetNearestTargetInRange()
            if target then
                for i = 1, AttacksPerLoop do
                    RegisterAttack:FireServer(AttackValue)
                    if target and target.Parent then 
                        RegisterHit:FireServer(target, {}, { [4] = "763d673c" }) 
                    end
                end
            end
        end
        task.wait() 
    end
end)

-- VÒNG LẶP HEARTBEAT
RunService.Heartbeat:Connect(function()
    ApplyInfiniteStaminaLogic()
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

-- Logic Speed CFrame
SpeedInput.FocusLost:Connect(function()
    local num = tonumber(SpeedInput.Text)
    if num then _G.CFrameSpeedValue = math.clamp(num, 0, _G.MaxLimit) else _G.CFrameSpeedValue = 0 end
    SpeedInput.Text = tostring(_G.CFrameSpeedValue)
    SpeedStatus.Text = "Tốc độ hiện tại: " .. tostring(_G.CFrameSpeedValue)
end)

RunService.Stepped:Connect(function()
    if _G.IsActive and _G.CFrameSpeedValue > 0 and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid") then
        if Player.Character.Humanoid.MoveDirection.Magnitude > 0 then
            Player.Character.HumanoidRootPart.CFrame += (Player.Character.Humanoid.MoveDirection * (_G.CFrameSpeedValue / 10))
        end
    end
end)

-- Logic Hitbox Body (Đã chặn áp dụng lên Bạn bè)
HitboxInput.FocusLost:Connect(function()
    local num = tonumber(HitboxInput.Text)
    HitboxValue = (num and num >= 0 and num <= 80) and num or 0
    HitboxInput.Text = tostring(HitboxValue)
end)

RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            
            -- KIỂM TRA ĐIỀU KIỆN HITBOX: Bật + Có giá trị + Không phải bạn bè
            local isFriend = Player:IsFriendsWith(p.UserId)
            
            if HitboxActive and HitboxValue > 0 and not isFriend then
                hrp.Size = Vector3.new(HitboxValue, HitboxValue, HitboxValue)
                hrp.Transparency = 0.6
                hrp.Color = Color3.fromRGB(255, 0, 0)
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            else
                -- Nếu là bạn bè hoặc tắt Hitbox, trả về kích thước gốc
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end)

-- Điều khiển GUI
local function ToggleFast()
    FastAttackEnabled = not FastAttackEnabled
    FastBtn.Text = FastAttackEnabled and "FAST ATTACK: ON (G)" or "FAST ATTACK: OFF (G)"
    FastBtn.BackgroundColor3 = FastAttackEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(35, 35, 35)
    if not FastAttackEnabled then 
        TargetLabel.Text = "TARGET: FAST M1 OFF" 
        TargetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
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
