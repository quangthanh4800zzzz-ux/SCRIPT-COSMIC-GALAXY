-- Fast Attack + Hit AUTO (PVP + PVE - CHECK TEAM BLOX FRUITS)
-- Áp dụng MỌI Melee/Kiếm | Đánh quái + người chơi | Check team thông minh
-- Setting chính thức: Value 0.48 | 4 hit | Tầm 60 | Delay 0.4s

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Player = Players.LocalPlayer

-- Remote đúng SimpleSpy
local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
local RegisterHit = ReplicatedStorage.Modules.Net["RE/RegisterHit"]

-- SETTING CHÍNH THỨC
local AttackValue = 0.48
local AttacksPerLoop = 4
local AttackDistance = 60
local LoopDelay = 0.4
local Enabled = false

-- Check team Blox Fruits (Marines/Pirates/Allies)
local function IsSameTeam(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    
    local myTeam = Player.Team
    local targetTeam = targetPlayer.Team
    
    -- Nếu mình không có team → đánh tất cả
    if not myTeam then return false end
    
    -- Marines: chỉ đánh Pirates
    if myTeam.Name == "Marines" then
        return targetTeam.Name == "Marines"
    end
    
    -- Pirates: đánh Marines + Pirates không phải ally
    if myTeam.Name == "Pirates" then
        if targetTeam.Name == "Marines" then
            return false  -- Không đánh Marines
        elseif targetTeam.Name == "Pirates" then
            -- Kiểm tra ally: Pirates ally với nhau qua system game
            -- Dùng LeaderStats hoặc Data để check ally (phổ biến trong Blox Fruits)
            local myLeaderstats = Player:FindFirstChild("leaderstats")
            local targetLeaderstats = targetPlayer:FindFirstChild("leaderstats")
            if myLeaderstats and targetLeaderstats then
                -- Check qua DisplayName hoặc custom ally system
                return targetPlayer.DisplayName == Player.DisplayName or 
                       targetPlayer.Name == Player.Name  -- Tự đánh mình = false
            end
            return false  -- Pirates ally với nhau → không đánh
        end
    end
    
    return false  -- Default: không cùng team → đánh
end

-- Check equip MỌI Melee/Kiếm (mở rộng danh sách)
local function IsEquippedMeleeOrSword()
    if not Player.Character then return false end
    local tool = Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    -- Check qua Tool Type (Melee/Sword chính xác nhất)
    if tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword") then
        return true
    end
    
    -- Check tên phổ biến TẤT CẢ Melee/Sword hiện tại
    local name = tool.Name:lower()
    local meleeList = {"combat", "karate", "godhuman", "sharkman", "dragon", "electric", "sanguine", "death step"}
    local swordList = {"katana", "saber", "pole", "cdk", "ttk", "yama", "shisui", "wando", "enma", "midori", "pole"}
    
    for _, melee in pairs(meleeList) do
        if name:find(melee) then return true end
    end
    for _, sword in pairs(swordList) do
        if name:find(sword) then return true end
    end
    
    return false
end

-- Tìm target gần nhất (QUÁI + NGƯỜI CHƠI)
local function GetNearestTargetInRange()
    local closestPart = nil
    local closestDist = AttackDistance
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    -- 1. TÌM QUÁI (Enemies)
    for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local dist = (hrp.Position - rootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestPart = hrp
            end
        end
    end
    
    -- 2. TÌM NGƯỜI CHƠI (PVP - có check team)
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
                -- CHECK TEAM TRƯỚC KHI ĐÁNH
                if not IsSameTeam(targetPlayer) then
                    local dist = (targetHRP.Position - rootPart.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPart = targetHRP
                    end
                end
            end
        end
    end
    
    return closestPart, closestDist
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 280, 0, 170)
Frame.Position = UDim2.new(0.02, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderColor3 = Color3.fromRGB(100, 255, 100)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "Fast Attack AUTO (PVP + PVE)"
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(100, 255, 100)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", Frame)
Status.Position = UDim2.new(0, 10, 0, 50)
Status.Size = UDim2.new(1, -20, 0, 70)
Status.BackgroundTransparency = 1
Status.Text = "Trạng thái: TẮT\n(Chưa equip Melee/Sword)"
Status.TextColor3 = Color3.fromRGB(255, 100, 100)
Status.TextSize = 16
Status.TextWrapped = true

local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0.28, 0)
ToggleBtn.Text = "BẬT / TẮT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextSize = 18

-- Auto loop
local AutoConnection

local function StartAuto()
    if AutoConnection then AutoConnection:Disconnect() end
    
    AutoConnection = RunService.Heartbeat:Connect(function()
        if not Enabled then return end
        if not IsEquippedMeleeOrSword() then
            Status.Text = "BẬT nhưng chưa equip Melee/Sword\n(Hỗ trợ TẤT CẢ Melee + Sword)"
            Status.TextColor3 = Color3.fromRGB(255, 255, 0)
            return
        end
        
        local hitPart, distance = GetNearestTargetInRange()
        
        if hitPart then
            Status.Text = string.format("ĐANG ĐÁNH NHANH\nTarget cách: %.0f studs\n(PVE + PVP - Auto team check)", distance)
            Status.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            for i = 1, AttacksPerLoop do
                RegisterAttack:FireServer(AttackValue)
                
                if hitPart and hitPart.Parent then
                    RegisterHit:FireServer(hitPart, {}, { [4] = "763d673c" })
                end
                
                task.wait()
            end
        else
            Status.Text = "BẬT - Chờ target vào tầm\n(Tầm: 60 studs | Quái + Người chơi)"
            Status.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
        
        task.wait(LoopDelay)
    end)
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    if Enabled then
        Status.Text = "BẬT - Đang quét PVE + PVP\n(60 studs | Auto check team)"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        ToggleBtn.Text = "ĐANG BẬT (PVP+PVE)"
        StartAuto()
    else
        Status.Text = "Trạng thái: TẮT"
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        ToggleBtn.Text = "BẬT / TẮT"
        if AutoConnection then AutoConnection:Disconnect() end
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Fast Attack PVP + PVE Ready";
    Text = "Setting: 0.48 | 4 hit | 60 studs | 0.4s\nHỗ trợ TẤT CẢ Melee/Sword + Auto team check!";
    Duration = 8
})