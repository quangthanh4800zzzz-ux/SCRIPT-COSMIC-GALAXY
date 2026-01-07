-- Fast Attack + Hit AUTO (NÂNG CẤP TẤT CẢ VŨ KHÍ)
-- Áp dụng MỌI Melee/Kiếm | Đánh quái + người chơi | Check team thông minh
-- Setting chính thức: Value 0.48 | 4 hit | Tầm 60 | Delay 0.4s

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Player = Players.LocalPlayer

-- Remote đúng SimpleSpy cho Blox Fruits
local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
local RegisterHit = ReplicatedStorage.Modules.Net["RE/RegisterHit"]

-- SETTING CHÍNH THỨC
local AttackValue = 0.48
local AttacksPerLoop = 4
local AttackDistance = 60
local LoopDelay = 0.4
local Enabled = false

-- HÀM KIỂM TRA TEAM
local function IsSameTeam(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    
    local myTeam = Player.Team
    local targetTeam = targetPlayer.Team
    
    if not myTeam then return false end
    
    if myTeam.Name == "Marines" then
        return targetTeam.Name == "Marines"
    end
    
    if myTeam.Name == "Pirates" then
        if targetTeam.Name == "Marines" then
            return false
        elseif targetTeam.Name == "Pirates" then
            local myLeaderstats = Player:FindFirstChild("leaderstats")
            local targetLeaderstats = targetPlayer:FindFirstChild("leaderstats")
            if myLeaderstats and targetLeaderstats then
                return targetPlayer.DisplayName == Player.DisplayName or 
                       targetPlayer.Name == Player.Name
            end
            return false
        end
    end
    
    return false
end

-- HÀM NÂNG CẤP: KIỂM TRA MỌI MELEE VÀ KIẾM
-- Không dùng list tên, dùng ToolTip và Class để nhận diện tuyệt đối
local function IsEquippedMeleeOrSword()
    if not Player.Character then return false end
    
    -- Tìm Tool đang cầm trên tay
    local tool = Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    -- Cách 1: Kiểm tra ToolTip
    local toolTip = tool.ToolTip
    if toolTip == "Melee" or toolTip == "Sword" then
        return true
    end
    
    -- Cách 2: Kiểm tra các đặc điểm kỹ thuật bên trong Tool
    -- Hầu hết các vũ khí đều có Animation hoặc cấu trúc riêng
    if tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword") then
        return true
    end

    -- Cách 3: Kiểm tra dựa trên thư mục chứa (Backpack/Character) 
    -- Nếu vẫn không tìm thấy bằng các cách trên
    if tool:FindFirstChild("Handle") and (tool:FindFirstChild("Attack") or tool:FindFirstChild("Main")) then
        return true
    end
    
    return false
end

-- HÀM TÌM TARGET (QUÁI + NGƯỜI CHƠI)
local function GetNearestTargetInRange()
    local closestPart = nil
    local closestDist = AttackDistance
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    -- 1. Tìm Quái
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, enemy in pairs(enemiesFolder:GetChildren()) do
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                local dist = (hrp.Position - rootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPart = hrp
                end
            end
        end
    end
    
    -- 2. Tìm Người chơi (PVP)
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
            if targetHRP and targetHum and targetHum.Health > 0 then
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

-- GIAO DIỆN (GUI)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 180)
Frame.Position = UDim2.new(0.02, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 255)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "FAST ATTACK ALL WEAPONS"
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", Frame)
Status.Position = UDim2.new(0, 10, 0, 50)
Status.Size = UDim2.new(1, -20, 0, 70)
Status.BackgroundTransparency = 1
Status.Text = "Trạng thái: ĐANG TẮT\nVui lòng cầm vũ khí bất kỳ"
Status.TextColor3 = Color3.fromRGB(255, 100, 100)
Status.TextSize = 14
Status.TextWrapped = true

local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
ToggleBtn.Text = "BẬT SCRIPT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16

-- VÒNG LẶP THỰC THI (MAIN LOOP)
local AutoConnection

local function StartAuto()
    if AutoConnection then AutoConnection:Disconnect() end
    
    AutoConnection = RunService.Heartbeat:Connect(function()
        if not Enabled then return end
        
        -- Kiểm tra điều kiện cầm vũ khí
        if not IsEquippedMeleeOrSword() then
            Status.Text = "CHƯA CẦM VŨ KHÍ\n(Hãy cầm Kiếm hoặc Melee bất kỳ)"
            Status.TextColor3 = Color3.fromRGB(255, 200, 0)
            return
        end
        
        local hitPart, distance = GetNearestTargetInRange()
        
        if hitPart then
            Status.Text = string.format("ĐANG TẤN CÔNG: %s\nKhoảng cách: %.1f studs", hitPart.Parent.Name, distance)
            Status.TextColor3 = Color3.fromRGB(0, 255, 127)
            
            -- Thực hiện chuỗi đánh nhanh
            for i = 1, AttacksPerLoop do
                -- Gửi tín hiệu vung vũ khí
                RegisterAttack:FireServer(AttackValue)
                
                -- Gửi tín hiệu gây sát thương
                if hitPart and hitPart.Parent then
                    RegisterHit:FireServer(hitPart, {}, { [4] = "763d673c" })
                end
                
                -- Đợi 1 frame để tránh crash hoặc bị kích bởi anti-cheat quá nhanh
                task.wait()
            end
        else
            Status.Text = "ĐANG ĐỢI MỤC TIÊU...\n(Quái hoặc Người chơi khác team)"
            Status.TextColor3 = Color3.fromRGB(0, 191, 255)
        end
        
        -- Delay giữa các đợt đánh để an toàn cho tài khoản
        task.wait(LoopDelay)
    end)
end

-- SỰ KIỆN BẤM NÚT
ToggleBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    if Enabled then
        ToggleBtn.Text = "TẮT SCRIPT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        StartAuto()
    else
        ToggleBtn.Text = "BẬT SCRIPT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Status.Text = "Trạng thái: ĐANG TẮT"
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        if AutoConnection then AutoConnection:Disconnect() end
    end
end)

-- THÔNG BÁO KHI LOAD XONG
game.StarterGui:SetCore("SendNotification", {
    Title = "Universal Fast Attack";
    Text = "Đã nhận diện: Mọi Melee & Sword!";
    Duration = 5
})