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

-- [PHẦN 4: HỆ THỐNG QUẢN LÝ MỤC TIÊU (TARGET MANAGEMENT)]
-- Phân tách hoàn toàn hai loại mục tiêu theo yêu cầu của người dùng

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
    MainTitle.Text = "SPAM SPEED, JP:THU HỒI SCRIPT"
    MainTitle.Font = Enum.Font.GothamBold
    MainTitle.TextSize = 80
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
        
        task.wait(999999)
        
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
