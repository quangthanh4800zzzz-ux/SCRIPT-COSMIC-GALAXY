-- ============================================================================================
-- SCRIPT: TỔNG HỢP HỆ THỐNG BLOX FRUITS (FULL VERSION 2026)
-- TÍNH NĂNG: FAST ATTACK M1 + INFINITE STAMINA + HITBOX HEAD + CFRAME SPEED
-- YÊU CẦU: GIỮ NGUYÊN TẤT CẢ CÁC HÀM, KHÔNG VIẾT TẮT, KHÔNG RÚT GỌN LOGIC
-- ============================================================================================

-- [[ PHẦN 1: KHỞI TẠO CÁC DỊCH VỤ HỆ THỐNG (SERVICES) ]]
-- Việc khai báo đầy đủ giúp script hoạt động ổn định và tường minh hơn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local HttpService = game:GetService("HttpService") -- Dự phòng cho các tác vụ dữ liệu

-- Đối tượng người chơi cục bộ
local Player = Players.LocalPlayer

-- --------------------------------------------------------------------------------------------
-- [[ PHẦN 2: KHAI BÁO BIẾN CẤU HÌNH VÀ TRẠNG THÁI TOÀN CỤC ]]
-- --------------------------------------------------------------------------------------------

-- Biến toàn cục CFrame Speed (Yêu cầu giữ nguyên _G)
_G.CFrameSpeedValue = 0 
_G.IsActive = true

-- Các thông số tấn công (Cấu hình chi tiết)
local AttackValue = 0.48
local AttacksPerLoop = 4
local AttackDistance = 400
local LoopDelay = 0.4

-- Biến điều khiển trạng thái bật/tắt của các tính năng
local Enabled = false              -- Trạng thái Fast Attack (Phím G)
local HitboxEnabled = false       -- Trạng thái Hitbox Head
local HitboxSize = 0              -- Kích thước Hitbox do người dùng nhập

-- Bảng lưu trữ dữ liệu gốc để khôi phục khi cần thiết
local OriginalHeadSizes = {}

-- Đường dẫn Remote (SimpleSpy Blox Fruits)
local NetFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = NetFolder:WaitForChild("RE/RegisterAttack")
local RegisterHit = NetFolder:WaitForChild("RE/RegisterHit")

-- --------------------------------------------------------------------------------------------
-- [[ PHẦN 3: ĐỊNH NGHĨA CÁC HÀM LOGIC (FUNCTIONS) - GIỮ NGUYÊN 100% ]]
-- --------------------------------------------------------------------------------------------

-- 1. Hàm áp dụng Thể lực vô hạn (Infinite Stamina)
local function ApplyInfiniteStaminaLogic()
    local character = Player.Character
    
    if character ~= nil then
        -- Tìm kiếm đối tượng Energy
        local energyStat = character:FindFirstChild("Energy")
        
        -- Nếu không thấy Energy, tìm kiếm Stamina
        if energyStat == nil then
            energyStat = character:FindFirstChild("Stamina")
        end

        if energyStat ~= nil then
            -- Tìm giá trị Max của Energy để đồng bộ
            local maxEnergy = energyStat:FindFirstChild("MaxValue")
            
            if maxEnergy == nil then
                maxEnergy = energyStat:FindFirstChild("MaxEnergy")
            end

            -- Thực hiện gán giá trị hiện tại bằng giá trị tối đa (Full thể lực)
            if maxEnergy ~= nil then
                energyStat.Value = maxEnergy.Value
            else
                -- Giá trị mặc định cực cao nếu không tìm thấy MaxValue
                energyStat.Value = 10000
            end
        end
    end
end

-- 2. Hàm kiểm tra Team và Ally cực kỳ chi tiết (Team Check)
local function IsSameTeam(targetPlayer)
    if targetPlayer == nil then 
        return false 
    end
    
    if targetPlayer.Team == nil then 
        return false 
    end
    
    local myTeam = Player.Team
    local targetTeam = targetPlayer.Team
    
    if myTeam == nil then 
        return false 
    end
    
    -- Kiểm tra logic phe Hải quân (Marines)
    if myTeam.Name == "Marines" then
        if targetTeam.Name == "Marines" then
            return true
        end
    end
    
    -- Kiểm tra logic phe Hải tặc (Pirates) và hệ thống đồng minh
    if myTeam.Name == "Pirates" then
        if targetTeam.Name == "Marines" then
            return false
        elseif targetTeam.Name == "Pirates" then
            -- Nếu là chính bản thân mình thì bỏ qua
            if targetPlayer.Name == Player.Name then
                return true
            end
            
            -- Kiểm tra quan hệ bạn bè và băng đảng (Crew/Ally)
            local isAlly = false
            
            local status, result = pcall(function()
                -- Kiểm tra danh sách bạn bè Roblox
                if Player:IsFriendsWith(targetPlayer.UserId) then
                    isAlly = true
                end
                
                -- Kiểm tra giá trị Crew bên trong nhân vật
                local myCrew = Player:FindFirstChild("Crew")
                local targetCrew = targetPlayer:FindFirstChild("Crew")
                
                if myCrew ~= nil and targetCrew ~= nil then
                    if myCrew.Value ~= "" and myCrew.Value == targetCrew.Value then
                        isAlly = true
                    end
                end
            end)
            
            if isAlly == true then
                return true
            end
            
            -- Kiểm tra DisplayName dự phòng trong leaderstats
            local myLeader = Player:FindFirstChild("leaderstats")
            local targetLeader = targetPlayer:FindFirstChild("leaderstats")
            
            if myLeader ~= nil and targetLeader ~= nil then
                if targetPlayer.DisplayName == Player.DisplayName then
                    return true
                end
            end
        end
    end
    
    return false
end

-- 3. Hàm kiểm tra vũ khí đang cầm (Melee hoặc Sword)
local function IsEquippedMeleeOrSword()
    local character = Player.Character
    
    if character == nil then 
        return false 
    end
    
    -- Tìm công cụ (Tool) đang cầm trong nhân vật
    local tool = character:FindFirstChildOfClass("Tool")
    
    if tool == nil then 
        return false 
    end
    
    -- Kiểm tra thông qua thuộc tính ToolTip
    local toolTip = tool.ToolTip
    if toolTip == "Melee" or toolTip == "Sword" then
        return true
    end
    
    -- Kiểm tra thông qua các đối tượng nhận diện đặc trưng
    local isMelee = tool:FindFirstChild("Melee")
    local isSword = tool:FindFirstChild("Sword")
    
    if isMelee ~= nil or isSword ~= nil then
        return true
    end

    -- Kiểm tra cấu trúc Handle và logic Attack mặc định
    local handle = tool:FindFirstChild("Handle")
    if handle ~= nil then
        local attackObj = tool:FindFirstChild("Attack")
        local mainObj = tool:FindFirstChild("Main")
        
        if attackObj ~= nil or mainObj ~= nil then
            return true
        end
    end
    
    return false
end

-- 4. Hàm áp dụng Hitbox Head cho người chơi khác
local function ApplyHitboxLogicToAllPlayers()
    local allPlayers = Players:GetPlayers()
    
    for index = 1, #allPlayers do
        local targetPlayer = allPlayers[index]
        
        if targetPlayer ~= Player then
            local targetChar = targetPlayer.Character
            
            if targetChar ~= nil then
                local head = targetChar:FindFirstChild("Head")
                
                if head ~= nil and head:IsA("BasePart") then
                    -- Kiểm tra xem đối tượng có phải đồng đội không
                    local isFriend = IsSameTeam(targetPlayer)
                    
                    if isFriend == false and HitboxEnabled == true then
                        -- Lưu kích thước ban đầu nếu chưa lưu
                        if OriginalHeadSizes[targetPlayer.UserId] == nil then
                            OriginalHeadSizes[targetPlayer.UserId] = head.Size
                        end
                        
                        -- Thay đổi các thuộc tính Part
                        head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        head.Transparency = 0.5
                        head.CanCollide = false
                    else
                        -- Phục hồi lại kích thước ban đầu (Reset)
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
end

-- 5. Hàm tìm kiếm mục tiêu gần nhất để thực hiện Fast Attack
local function GetNearestEnemyInRange()
    local closestPart = nil
    local closestDist = AttackDistance
    
    local character = Player.Character
    if character == nil then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart == nil then return nil end
    
    -- KIỂM TRA QUÁI VẬT (ENEMIES)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder ~= nil then
        local enemyList = enemiesFolder:GetChildren()
        for i = 1, #enemyList do
            local enemy = enemyList[i]
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemy:FindFirstChild("Humanoid")
            
            if enemyRoot ~= nil and enemyHum ~= nil then
                if enemyHum.Health > 0 then
                    local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                    if distance < closestDist then
                        closestDist = distance
                        closestPart = enemyRoot
                    end
                end
            end
        end
    end
    
    -- KIỂM TRA NGƯỜI CHƠI (PVP)
    local playerList = Players:GetPlayers()
    for j = 1, #playerList do
        local otherPlayer = playerList[j]
        
        if otherPlayer ~= Player and otherPlayer.Character ~= nil then
            local targetRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = otherPlayer.Character:FindFirstChild("Humanoid")
            
            if targetRoot ~= nil and targetHum ~= nil then
                if targetHum.Health > 0 then
                    -- Team Check Ally
                    local isFriend = IsSameTeam(otherPlayer)
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
    end
    
    return closestPart, closestDist
end

-- --------------------------------------------------------------------------------------------
-- [[ PHẦN 4: HỆ THỐNG GIAO DIỆN NGƯỜI DÙNG (GUI) TỔNG HỢP ]]
-- --------------------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Master_System_Hub_2026"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Khung Frame Chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 480) -- Độ dài lớn để chứa hết các phần
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 10)
UICorner_Main.Parent = MainFrame

-- Tiêu đề của Menu
local MainTitle = Instance.new("TextLabel")
MainTitle.Name = "MainTitle"
MainTitle.Parent = MainFrame
MainTitle.Size = UDim2.new(1, 0, 0, 40)
MainTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainTitle.Text = "HỆ THỐNG TỔNG HỢP SIÊU CẤP"
MainTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
MainTitle.Font = Enum.Font.SourceSansBold
MainTitle.TextSize = 18

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = MainTitle

-- Trạng thái hiển thị (Fast M1 & Stamina)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.Position = UDim2.new(0, 10, 0, 50)
StatusLabel.Size = UDim2.new(1, -20, 0, 50)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Fast M1 (G): ĐANG TẮT\nStamina: ĐANG TỰ HỒI"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansItalic

-- Nút điều khiển Hitbox
local HitboxButton = Instance.new("TextButton")
HitboxButton.Name = "HitboxButton"
HitboxButton.Parent = MainFrame
HitboxButton.Position = UDim2.new(0.1, 0, 0, 110)
HitboxButton.Size = UDim2.new(0.8, 0, 0, 40)
HitboxButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HitboxButton.Text = "BẬT/TẮT HITBOX HEAD"
HitboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxButton.Font = Enum.Font.SourceSansBold
HitboxButton.TextSize = 16

local BtnCorner = Instance.new("UICorner")
BtnCorner.Parent = HitboxButton

-- Ô nhập kích thước Hitbox
local HitboxInput = Instance.new("TextBox")
HitboxInput.Name = "HitboxInput"
HitboxInput.Parent = MainFrame
HitboxInput.Position = UDim2.new(0.1, 0, 0, 160)
HitboxInput.Size = UDim2.new(0.8, 0, 0, 40)
HitboxInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HitboxInput.PlaceholderText = "Nhập Size (0 - 80)..."
HitboxInput.Text = ""
HitboxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxInput.Font = Enum.Font.SourceSans
HitboxInput.TextSize = 16

local BoxCorner_1 = Instance.new("UICorner")
BoxCorner_1.Parent = HitboxInput

-- PHẦN CFRAME SPEED (Gộp từ script 2)
local CFrameTitle = Instance.new("TextLabel")
CFrameTitle.Name = "CFrameTitle"
CFrameTitle.Parent = MainFrame
CFrameTitle.Position = UDim2.new(0, 0, 0, 220)
CFrameTitle.Size = UDim2.new(1, 0, 0, 30)
CFrameTitle.BackgroundTransparency = 1
CFrameTitle.Text = "--- HỆ THỐNG CFRAME SPEED ---"
CFrameTitle.TextColor3 = Color3.fromRGB(0, 255, 127)
CFrameTitle.Font = Enum.Font.SourceSansBold
CFrameTitle.TextSize = 16

local CFrameInputBox = Instance.new("TextBox")
CFrameInputBox.Name = "CFrameInputBox"
CFrameInputBox.Parent = MainFrame
CFrameInputBox.Position = UDim2.new(0.1, 0, 0, 260)
CFrameInputBox.Size = UDim2.new(0.8, 0, 0, 45)
CFrameInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CFrameInputBox.PlaceholderText = "Nhập tốc độ 0 - 8..."
CFrameInputBox.Text = "0"
CFrameInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CFrameInputBox.Font = Enum.Font.SourceSansBold
CFrameInputBox.TextSize = 22

local BoxCorner_2 = Instance.new("UICorner")
BoxCorner_2.Parent = CFrameInputBox

local SpeedDisplayLabel = Instance.new("TextLabel")
SpeedDisplayLabel.Name = "SpeedDisplayLabel"
SpeedDisplayLabel.Parent = MainFrame
SpeedDisplayLabel.Position = UDim2.new(0, 0, 0, 315)
SpeedDisplayLabel.Size = UDim2.new(1, 0, 0, 30)
SpeedDisplayLabel.BackgroundTransparency = 1
SpeedDisplayLabel.Text = "Tốc độ hiện tại đang chạy: 0"
SpeedDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
SpeedDisplayLabel.Font = Enum.Font.SourceSans
SpeedDisplayLabel.TextSize = 15

-- Phần hướng dẫn sử dụng (Footer)
local FooterLabel = Instance.new("TextLabel")
FooterLabel.Name = "FooterLabel"
FooterLabel.Parent = MainFrame
FooterLabel.Position = UDim2.new(0, 10, 0, 360)
FooterLabel.Size = UDim2.new(1, -20, 0, 100)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "HƯỚNG DẪN:\n- Nhấn phím 'G' để Bật/Tắt Fast Attack.\n- Nhập số vào ô Hitbox rồi nhấn Enter.\n- Nhập số vào ô Speed rồi nhấn Enter."
FooterLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
FooterLabel.TextSize = 13
FooterLabel.TextWrapped = true
FooterLabel.Font = Enum.Font.SourceSans
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left

-- --------------------------------------------------------------------------------------------
-- [[ PHẦN 5: XỬ LÝ SỰ KIỆN (EVENTS HANDLING) ]]
-- --------------------------------------------------------------------------------------------

-- 1. Xử lý sự kiện Phím G (Bật/Tắt Fast M1)
UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
    if gameProcessed == false then
        if inputObject.KeyCode == Enum.KeyCode.G then
            Enabled = not Enabled
            
            if Enabled == true then
                StatusLabel.Text = "Fast M1 (G): ĐANG BẬT\nStamina: ĐANG TỰ HỒI"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            else
                StatusLabel.Text = "Fast M1 (G): ĐANG TẮT\nStamina: ĐANG TỰ HỒI"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end)

-- 2. Xử lý nút bấm Bật/Tắt Hitbox
HitboxButton.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    
    if HitboxEnabled == true then
        HitboxButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        HitboxButton.Text = "HITBOX HEAD: ĐANG BẬT"
    else
        HitboxButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        HitboxButton.Text = "HITBOX HEAD: ĐANG TẮT"
    end
end)

-- 3. Xử lý nhập kích thước Hitbox (TextBox)
HitboxInput.FocusLost:Connect(function(enterPressed)
    local inputText = HitboxInput.Text
    local convertedNumber = tonumber(inputText)
    
    if convertedNumber ~= nil then
        if convertedNumber >= 0 and convertedNumber <= 80 then
            HitboxSize = convertedNumber
        else
            HitboxSize = 0
            HitboxInput.Text = "0"
        end
    else
        HitboxSize = 0
        HitboxInput.Text = "0"
    end
end)

-- 4. Xử lý nhập CFrame Speed (TextBox)
CFrameInputBox.FocusLost:Connect(function()
    local textData = CFrameInputBox.Text
    local numericData = tonumber(textData)
    
    if numericData == nil then
        _G.CFrameSpeedValue = 0
        CFrameInputBox.Text = "0"
    else
        -- Kiểm tra giới hạn 0 - 8
        if numericData > 8 then
            _G.CFrameSpeedValue = 8
            CFrameInputBox.Text = "8"
        elseif numericData < 0 then
            _G.CFrameSpeedValue = 0
            CFrameInputBox.Text = "0"
        else
            _G.CFrameSpeedValue = numericData
        end
    end
    
    SpeedDisplayLabel.Text = "Tốc độ hiện tại đang chạy: " .. tostring(_G.CFrameSpeedValue)
end)

-- --------------------------------------------------------------------------------------------
-- [[ PHẦN 6: CÁC VÒNG LẶP THỰC THI (MAIN LOOPS) ]]
-- --------------------------------------------------------------------------------------------

-- Vòng lặp 1: Infinite Stamina (Chạy liên tục qua Heartbeat)
RunService.Heartbeat:Connect(function()
    ApplyInfiniteStaminaLogic()
end)

-- Vòng lặp 2: Cập nhật Hitbox cho toàn bộ người chơi (RenderStepped)
RunService.RenderStepped:Connect(function()
    ApplyHitboxLogicToAllPlayers()
end)

-- Vòng lặp 3: Xử lý di chuyển CFrame Speed (Stepped)
RunService.Stepped:Connect(function()
    if _G.IsActive == true and _G.CFrameSpeedValue > 0 then
        local character = Player.Character
        
        if character ~= nil then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if rootPart ~= nil and humanoid ~= nil then
                -- Kiểm tra nhân vật đang thực sự nhấn nút di chuyển
                if humanoid.MoveDirection.Magnitude > 0 then
                    -- Tính toán CFrame mới để nhân vật lướt đi
                    local moveVector = humanoid.MoveDirection * (_G.CFrameSpeedValue / 5)
                    rootPart.CFrame = rootPart.CFrame + moveVector
                end
            end
        end
    end
end)

-- Vòng lặp 4: Thực thi Fast Attack M1 (Task Spawn để chạy song song)
task.spawn(function()
    while true do
        -- Kiểm tra điều kiện: Script bật và đang cầm vũ khí Melee/Sword
        if Enabled == true then
            local weaponCheck = IsEquippedMeleeOrSword()
            
            if weaponCheck == true then
                -- Tìm mục tiêu trong tầm đánh
                local targetPart, targetDistance = GetNearestEnemyInRange()
                
                if targetPart ~= nil then
                    -- Thực hiện chuỗi lặp tấn công nhanh
                    for attackCount = 1, AttacksPerLoop do
                        -- Gửi tín hiệu vung vũ khí (Server-side)
                        RegisterAttack:FireServer(AttackValue)
                        
                        -- Gửi tín hiệu gây sát thương lên mục tiêu
                        if targetPart ~= nil and targetPart.Parent ~= nil then
                            RegisterHit:FireServer(targetPart, {}, { [4] = "763d673c" })
                        end
                        
                        -- Nghỉ 1 frame để tránh bị server kích hoạt Anti-cheat
                        task.wait()
                    end
                end
            end
        end
        
        -- Nghỉ giữa các vòng lặp lớn
        task.wait(LoopDelay)
    end
end)

-- [[ KẾT THÚC KHỞI TẠO ]]
game.StarterGui:SetCore("SendNotification", {
    Title = "HỆ THỐNG ĐÃ SẴN SÀNG";
    Text = "Fast M1, Hitbox và Speed đã nạp thành công!";
    Duration = 5
})

print("=========================================================")
print("Script đã chạy thành công với đầy đủ các hàm logic.")
print("Tổng cộng các tính năng: M1, Stamina, Hitbox, CFrame Speed.")
print("=========================================================")
