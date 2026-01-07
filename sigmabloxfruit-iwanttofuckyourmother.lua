-- =========================================================
-- SCRIPT: FAST ATTACK M1 + INF STAMINA + HITBOX HEAD (FULL VERSION)
-- ĐỘ DÀI: Đầy đủ các bước kiểm tra, không rút gọn, không viết tắt.
-- TÍNH NĂNG: Phím G (Fast Attack) | Hitbox Head 0-80 | Team Check Ally
-- =========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- ---------------------------------------------------------
-- PHẦN 1: INFINITE STAMINA (GIỮ NGUYÊN PHONG CÁCH CHI TIẾT)
-- ---------------------------------------------------------
local function ApplyInfiniteStaminaLogic()
    local character = Player.Character
    
    if character ~= nil then
        -- Tìm kiếm thuộc tính Energy hoặc Stamina một cách chi tiết
        local energyStat = character:FindFirstChild("Energy")
        
        if energyStat == nil then
            energyStat = character:FindFirstChild("Stamina")
        end

        if energyStat ~= nil then
            -- Tìm kiếm giá trị giới hạn tối đa của thể lực
            local maxEnergy = energyStat:FindFirstChild("MaxValue")
            
            if maxEnergy == nil then
                maxEnergy = energyStat:FindFirstChild("MaxEnergy")
            end

            -- Thực hiện gán giá trị hiện tại bằng giá trị tối đa
            if maxEnergy ~= nil then
                energyStat.Value = maxEnergy.Value
            else
                -- Giá trị dự phòng nếu không tìm thấy MaxValue trong hệ thống
                energyStat.Value = 10000
            end
        end
    end
end

-- Kết nối với Heartbeat để đảm bảo thể lực luôn đầy mỗi khung hình
RunService.Heartbeat:Connect(function()
    ApplyInfiniteStaminaLogic()
end)

-- ---------------------------------------------------------
-- PHẦN 2: CÁC BIẾN CẤU CẤU HÌNH VÀ REMOTE (GIỮ NGUYÊN GỐC)
-- ---------------------------------------------------------

-- Remote đúng SimpleSpy cho Blox Fruits
local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
local RegisterHit = ReplicatedStorage.Modules.Net["RE/RegisterHit"]

-- SETTING CHÍNH THỨC CỦA NGƯỜI DÙNG
local AttackValue = 0.48
local AttacksPerLoop = 4
local AttackDistance = 400
local LoopDelay = 0.4

-- Biến điều khiển trạng thái
local Enabled = false -- Trạng thái của Fast Attack (Bật/Tắt bằng phím G)
local HitboxEnabled = false -- Trạng thái của Hitbox Head
local HitboxSize = 0 -- Kích thước mặc định của Hitbox

-- Bảng lưu trữ kích thước gốc để khôi phục khi tắt script
local OriginalHeadSizes = {}

-- ---------------------------------------------------------
-- PHẦN 3: HÀM KIỂM TRA TEAM VÀ ALLY (NÂNG CẤP)
-- ---------------------------------------------------------
local function IsSameTeam(targetPlayer)
    if targetPlayer == nil then return false end
    if targetPlayer.Team == nil then return false end
    
    local myTeam = Player.Team
    local targetTeam = targetPlayer.Team
    
    if myTeam == nil then return false end
    
    -- Kiểm tra phe Hải quân (Marines)
    if myTeam.Name == "Marines" then
        if targetTeam.Name == "Marines" then
            return true
        end
    end
    
    -- Kiểm tra phe Hải tặc (Pirates) và hệ thống đồng minh (Ally/Crew)
    if myTeam.Name == "Pirates" then
        if targetTeam.Name == "Marines" then
            return false
        elseif targetTeam.Name == "Pirates" then
            -- Kiểm tra nếu là chính bản thân mình
            if targetPlayer.Name == Player.Name then
                return true
            end
            
            -- Kiểm tra hệ thống Ally và Crew của Blox Fruits
            local isAlly = false
            local success, err = pcall(function()
                -- Check bạn bè
                if Player:IsFriendsWith(targetPlayer.UserId) then
                    isAlly = true
                end
                -- Check Crew (Băng hải tặc)
                local myCrew = Player:FindFirstChild("Crew")
                local targetCrew = targetPlayer:FindFirstChild("Crew")
                if myCrew and targetCrew and myCrew.Value ~= "" and myCrew.Value == targetCrew.Value then
                    isAlly = true
                end
            end)
            
            if isAlly == true then
                return true
            end
            
            -- Kiểm tra leaderstats dự phòng
            local myLeaderstats = Player:FindFirstChild("leaderstats")
            local targetLeaderstats = targetPlayer:FindFirstChild("leaderstats")
            if myLeaderstats and targetLeaderstats then
                if targetPlayer.DisplayName == Player.DisplayName then
                    return true
                end
            end
        end
    end
    
    return false
end

-- ---------------------------------------------------------
-- PHẦN 4: HÀM NÂNG CẤP KIỂM TRA VŨ KHÍ (GIỮ NGUYÊN)
-- ---------------------------------------------------------
local function IsEquippedMeleeOrSword()
    local character = Player.Character
    if character == nil then return false end
    
    -- Tìm Tool đang cầm trên tay
    local tool = character:FindFirstChildOfClass("Tool")
    if tool == nil then return false end
    
    -- Cách 1: Kiểm tra ToolTip
    local toolTip = tool.ToolTip
    if toolTip == "Melee" or toolTip == "Sword" then
        return true
    end
    
    -- Cách 2: Kiểm tra các đối tượng nhận diện bên trong Tool
    if tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword") then
        return true
    end

    -- Cách 3: Kiểm tra cấu trúc Handle và Attack
    if tool:FindFirstChild("Handle") then
        if tool:FindFirstChild("Attack") or tool:FindFirstChild("Main") then
            return true
        end
    end
    
    return false
end

-- ---------------------------------------------------------
-- PHẦN 5: LOGIC HITBOX HEAD (KHÔNG RÚT GỌN)
-- ---------------------------------------------------------
local function ApplyHitboxToPlayers()
    -- Duyệt qua tất cả người chơi trong Server
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Character ~= nil then
            local head = targetPlayer.Character:FindFirstChild("Head")
            
            if head ~= nil and head:IsA("BasePart") then
                -- Kiểm tra xem có phải kẻ địch không
                local isFriend = IsSameTeam(targetPlayer)
                
                if isFriend == false and HitboxEnabled == true then
                    -- Lưu kích cỡ gốc trước khi thay đổi để có thể phục hồi
                    if OriginalHeadSizes[targetPlayer.UserId] == nil then
                        OriginalHeadSizes[targetPlayer.UserId] = head.Size
                    end
                    
                    -- Thực hiện thay đổi kích thước đầu
                    head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    head.Transparency = 0.5
                    head.CanCollide = false
                else
                    -- Phục hồi về trạng thái ban đầu nếu tắt hoặc là đồng đội
                    if OriginalHeadSizes[targetPlayer.UserId] ~= nil then
                        head.Size = OriginalHeadSizes[targetPlayer.UserId]
                        head.Transparency = 0
                        head.CanCollide = true
                    end
                end
            end
        end
    end
end

-- Chạy cập nhật Hitbox liên tục
RunService.RenderStepped:Connect(function()
    ApplyHitboxToPlayers()
end)

-- ---------------------------------------------------------
-- PHẦN 6: HÀM TÌM KIẾM MỤC TIÊU (GIỮ NGUYÊN CHI TIẾT)
-- ---------------------------------------------------------
local function GetNearestTargetInRange()
    local closestPart = nil
    local closestDist = AttackDistance
    local character = Player.Character
    
    if character == nil then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart == nil then return nil end
    
    -- 1. Tìm mục tiêu trong thư mục Enemies (Quái vật)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder ~= nil then
        for _, enemy in pairs(enemiesFolder:GetChildren()) do
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemy:FindFirstChild("Humanoid")
            
            if enemyRoot and enemyHum and enemyHum.Health > 0 then
                local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                if distance < closestDist then
                    closestDist = distance
                    closestPart = enemyRoot
                end
            end
        end
    end
    
    -- 2. Tìm mục tiêu là Người chơi khác (PVP)
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Character ~= nil then
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
            
            if targetRoot and targetHum and targetHum.Health > 0 then
                -- Áp dụng Team Check Ally
                local isFriend = IsSameTeam(targetPlayer)
                if isFriend == false then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance < closestDist then
                        closestDist = distance
                        closestPart = targetRoot
                    end
                end
            end
        end
    end
    
    return closestPart, closestDist
end

-- ---------------------------------------------------------
-- PHẦN 7: GIAO DIỆN ĐIỀU KHIỂN (GUI)
-- ---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 260)
MainFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "FAST M1 + INF STAMINA + HITBOX"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold

local StatusDisplay = Instance.new("TextLabel", MainFrame)
StatusDisplay.Position = UDim2.new(0, 10, 0, 45)
StatusDisplay.Size = UDim2.new(1, -20, 0, 50)
StatusDisplay.Text = "Fast M1 (Phím G): ĐANG TẮT\nStamina: ĐANG TỰ HỒI"
StatusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusDisplay.BackgroundTransparency = 1
StatusDisplay.TextSize = 13

local HitboxBtn = Instance.new("TextButton", MainFrame)
HitboxBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
HitboxBtn.Size = UDim2.new(0.8, 0, 0, 35)
HitboxBtn.Text = "BẬT/TẮT HITBOX HEAD"
HitboxBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HitboxBtn.TextColor3 = Color3.new(1, 1, 1)

local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Position = UDim2.new(0.1, 0, 0.65, 0)
InputBox.Size = UDim2.new(0.8, 0, 0, 35)
InputBox.PlaceholderText = "Nhập Size Hitbox (0-80)..."
InputBox.Text = ""
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
InputBox.TextColor3 = Color3.new(1, 1, 1)

-- ---------------------------------------------------------
-- PHẦN 8: XỬ LÝ SỰ KIỆN (EVENTS)
-- ---------------------------------------------------------

-- 1. Phím tắt G để bật/tắt Fast Attack
UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
    if gameProcessed == false then
        if inputObject.KeyCode == Enum.KeyCode.G then
            Enabled = not Enabled
            if Enabled == true then
                StatusDisplay.Text = "Fast M1 (Phím G): ĐANG BẬT\nStamina: ĐANG TỰ HỒI"
                StatusDisplay.TextColor3 = Color3.fromRGB(0, 255, 150)
            else
                StatusDisplay.Text = "Fast M1 (Phím G): ĐANG TẮT\nStamina: ĐANG TỰ HỒI"
                StatusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end)

-- 2. Bật tắt Hitbox Head
HitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    if HitboxEnabled == true then
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    else
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end
end)

-- 3. Xử lý nhập kích thước Hitbox
InputBox.FocusLost:Connect(function(enterPressed)
    local inputText = InputBox.Text
    local convertedNumber = tonumber(inputText)
    
    if convertedNumber ~= nil then
        if convertedNumber >= 0 and convertedNumber <= 80 then
            HitboxSize = convertedNumber
        else
            HitboxSize = 0
            InputBox.Text = "0"
        end
    else
        HitboxSize = 0
        InputBox.Text = "0"
    end
end)

-- ---------------------------------------------------------
-- PHẦN 9: VÒNG LẶP THỰC THI CHÍNH (MAIN LOOP)
-- ---------------------------------------------------------
task.spawn(function()
    while true do
        -- Kiểm tra trạng thái Enabled (từ phím G) và vũ khí
        if Enabled == true then
            if IsEquippedMeleeOrSword() == true then
                
                local targetPart, distance = GetNearestTargetInRange()
                
                if targetPart ~= nil then
                    -- Thực hiện chuỗi tấn công nhanh
                    for i = 1, AttacksPerLoop do
                        -- Gửi tín hiệu vung vũ khí (RegisterAttack)
                        RegisterAttack:FireServer(AttackValue)
                        
                        -- Gửi tín hiệu sát thương (RegisterHit)
                        if targetPart ~= nil and targetPart.Parent ~= nil then
                            RegisterHit:FireServer(targetPart, {}, { [4] = "763d673c" })
                        end
                        
                        -- Đợi 1 frame để ổn định
                        task.wait()
                    end
                end
            end
        end
        
        -- Delay vòng lặp chính theo cấu hình
        task.wait(LoopDelay)
    end
end)

-- Thông báo khởi tạo thành công
game.StarterGui:SetCore("SendNotification", {
    Title = "Hệ Thống Tổng Hợp";
    Text = "Đã load xong Fast M1, Stamina và Hitbox!";
    Duration = 5
})