--[[
Volleyball Legends Full Hub v2
by Onyx
- 자동 최강 스파이크
- 자동 풀파워 서브
- 공 스킨 체인저
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Volleyball Legends | Onyx Hub",
    LoadingTitle = "Volleyball Legends",
    LoadingSubtitle = "Max Spike + Serve + Skin",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "VolleyballLegends",
        FileName = "OnyxConfig"
    },
    KeySystem = false
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Character, Humanoid, Root

local function refreshChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
refreshChar()
LocalPlayer.CharacterAdded:Connect(refreshChar)

-- Config
local Config = {
    AutoMaxSpike = false,
    AutoMaxServe = false,
    HitboxExpand = false,
    SpeedEnabled = false,
    JumpEnabled = false,
    BallESP = false,
    AntiAFK = true,

    WalkSpeed = 28,
    JumpPower = 70,
    HitboxSize = 9,
    HitRange = 14,
    SpikeDelay = 0.06
}

-- 공 찾기
local function getBall()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (string.lower(v.Name):find("ball") or v.Name == "Ball" or v.Name == "Volleyball") then
            return v
        end
    end
    return nil
end

-- 탭
local AutoTab = Window:CreateTab("자동 최강", 4483362458)
local CombatTab = Window:CreateTab("전투", 4483362458)
local SkinTab = Window:CreateTab("공 스킨", 4483362458)
local MoveTab = Window:CreateTab("이동", 4483362458)
local VisualTab = Window:CreateTab("시각", 4483362458)
local MiscTab = Window:CreateTab("기타", 4483362458)

-- ==================== 자동 최강 스파이크 ====================
AutoTab:CreateToggle({
    Name = "자동 최강 스파이크",
    CurrentValue = false,
    Flag = "AutoMaxSpike",
    Callback = function(v)
        Config.AutoMaxSpike = v
        if v then
            task.spawn(function()
                while Config.AutoMaxSpike do
                    pcall(function()
                        local ball = getBall()
                        if ball and Root then
                            local dist = (Root.Position - ball.Position).Magnitude
                            if dist <= Config.HitRange then
                                -- 점프 + 강한 클릭 (스파이크 타이밍)
                                if Humanoid and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                                    Humanoid.Jump = true
                                end
                                -- 빠르게 두 번 클릭해서 풀파워 스파이크 유도
                                VirtualUser:Button1Down(Vector2.new(0,0))
                                task.wait(0.02)
                                VirtualUser:Button1Up(Vector2.new(0,0))
                                task.wait(0.01)
                                VirtualUser:Button1Down(Vector2.new(0,0))
                                task.wait(0.02)
                                VirtualUser:Button1Up(Vector2.new(0,0))
                            end
                        end
                    end)
                    task.wait(Config.SpikeDelay)
                end
            end)
        end
    end
})

AutoTab:CreateSlider({
    Name = "스파이크 범위",
    Range = {6, 25},
    Increment = 1,
    CurrentValue = 14,
    Flag = "HitRange",
    Callback = function(v) Config.HitRange = v end
})

AutoTab:CreateSlider({
    Name = "스파이크 딜레이",
    Range = {0.03, 0.2},
    Increment = 0.01,
    CurrentValue = 0.06,
    Flag = "SpikeDelay",
    Callback = function(v) Config.SpikeDelay = v end
})

-- ==================== 자동 풀파워 서브 ====================
AutoTab:CreateToggle({
    Name = "자동 풀파워 서브",
    CurrentValue = false,
    Flag = "AutoMaxServe",
    Callback = function(v)
        Config.AutoMaxServe = v
        if v then
            task.spawn(function()
                while Config.AutoMaxServe do
                    pcall(function()
                        -- 서브 차례일 때 빠르게 더블클릭으로 풀파워
                        -- (게임이 서브 모드일 때 클릭 감지)
                        VirtualUser:Button1Down(Vector2.new(0,0))
                        task.wait(0.015)
                        VirtualUser:Button1Up(Vector2.new(0,0))
                        task.wait(0.01)
                        VirtualUser:Button1Down(Vector2.new(0,0))
                        task.wait(0.015)
                        VirtualUser:Button1Up(Vector2.new(0,0))
                    end)
                    task.wait(0.4) -- 서브 쿨타임 비슷하게
                end
            end)
        end
    end
})

-- ==================== 히트박스 ====================
CombatTab:CreateToggle({
    Name = "히트박스 확장",
    CurrentValue = false,
    Flag = "HitboxExpand",
    Callback = function(v)
        Config.HitboxExpand = v
        if v then
            task.spawn(function()
                while Config.HitboxExpand do
                    pcall(function()
                        local ball = getBall()
                        if ball then
                            ball.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                            ball.Transparency = 0.55
                            ball.CanCollide = false
                        end
                    end)
                    task.wait(0.08)
                end
            end)
        else
            local ball = getBall()
            if ball then
                ball.Size = Vector3.new(1.2, 1.2, 1.2)
                ball.Transparency = 0
            end
        end
    end
})

CombatTab:CreateSlider({
    Name = "히트박스 크기",
    Range = {2, 18},
    Increment = 0.5,
    CurrentValue = 9,
    Flag = "HitboxSize",
    Callback = function(v) Config.HitboxSize = v end
})

-- ==================== 공 스킨 체인저 ====================
local SkinColors = {
    ["기본 흰색"] = Color3.fromRGB(255, 255, 255),
    ["네온 초록"] = Color3.fromRGB(0, 255, 100),
    ["네온 핑크"] = Color3.fromRGB(255, 0, 150),
    ["네온 파랑"] = Color3.fromRGB(0, 150, 255),
    ["네온 노랑"] = Color3.fromRGB(255, 255, 0),
    ["네온 보라"] = Color3.fromRGB(180, 0, 255),
    ["블랙"] = Color3.fromRGB(20, 20, 20),
    ["레드 글로우"] = Color3.fromRGB(255, 40, 40),
    ["골드"] = Color3.fromRGB(255, 200, 50),
    ["레인보우"] = "rainbow"
}

local CurrentSkin = "네온 초록"
local RainbowConnection = nil

local function applyBallSkin(colorName)
    local ball = getBall()
    if not ball then return end

    if RainbowConnection then
        RainbowConnection:Disconnect()
        RainbowConnection = nil
    end

    if colorName == "레인보우" then
        local hue = 0
        RainbowConnection = RunService.RenderStepped:Connect(function()
            hue = (hue + 0.005) % 1
            if ball and ball.Parent then
                ball.Color = Color3.fromHSV(hue, 1, 1)
                ball.Material = Enum.Material.Neon
            end
        end)
    else
        local col = SkinColors[colorName]
        if col then
            ball.Color = col
            ball.Material = Enum.Material.Neon
            ball.Reflectance = 0.3
        end
    end
end

SkinTab:CreateDropdown({
    Name = "공 스킨 선택",
    Options = {"기본 흰색", "네온 초록", "네온 핑크", "네온 파랑", "네온 노랑", "네온 보라", "블랙", "레드 글로우", "골드", "레인보우"},
    CurrentOption = {"네온 초록"},
    Flag = "BallSkin",
    Callback = function(opt)
        CurrentSkin = opt[1] or opt
        applyBallSkin(CurrentSkin)
    end
})

SkinTab:CreateButton({
    Name = "지금 공에 스킨 적용",
    Callback = function()
        applyBallSkin(CurrentSkin)
        Rayfield:Notify({Title = "스킨", Content = CurrentSkin .. " 적용됨", Duration = 3})
    end
})

SkinTab:CreateToggle({
    Name = "스킨 자동 유지 (공 바뀔 때마다)",
    CurrentValue = true,
    Flag = "KeepSkin",
    Callback = function(v)
        if v then
            task.spawn(function()
                while true do
                    applyBallSkin(CurrentSkin)
                    task.wait(1.5)
                end
            end)
        end
    end
})

-- ==================== 이동 ====================
MoveTab:CreateToggle({
    Name = "스피드",
    CurrentValue = false,
    Flag = "Speed",
    Callback = function(v)
        Config.SpeedEnabled = v
        if Humanoid then
            Humanoid.WalkSpeed = v and Config.WalkSpeed or 16
        end
    end
})

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 45},
    Increment = 1,
    CurrentValue = 28,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        if Config.SpeedEnabled and Humanoid then
            Humanoid.WalkSpeed = v
        end
    end
})

MoveTab:CreateToggle({
    Name = "점프 부스트",
    CurrentValue = false,
    Flag = "Jump",
    Callback = function(v)
        Config.JumpEnabled = v
        if Humanoid then
            Humanoid.JumpPower = v and Config.JumpPower or 50
        end
    end
})

MoveTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 110},
    Increment = 5,
    CurrentValue = 70,
    Flag = "JumpPower",
    Callback = function(v)
        Config.JumpPower = v
        if Config.JumpEnabled and Humanoid then
            Humanoid.JumpPower = v
        end
    end
})

-- ==================== 시각 ====================
local BallHighlight = nil

VisualTab:CreateToggle({
    Name = "공 하이라이트 ESP",
    CurrentValue = false,
    Flag = "BallESP",
    Callback = function(v)
        Config.BallESP = v
        if not v and BallHighlight then
            BallHighlight:Destroy()
            BallHighlight = nil
        end
        if v then
            task.spawn(function()
                while Config.BallESP do
                    pcall(function()
                        local ball = getBall()
                        if ball then
                            if not BallHighlight or BallHighlight.Adornee ~= ball then
                                if BallHighlight then BallHighlight:Destroy() end
                                BallHighlight = Instance.new("Highlight")
                                BallHighlight.FillColor = Color3.fromRGB(0, 255, 120)
                                BallHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                BallHighlight.FillTransparency = 0.35
                                BallHighlight.Adornee = ball
                                BallHighlight.Parent = ball
                            end
                        end
                    end)
                    task.wait(0.15)
                end
            end)
        end
    end
})

-- ==================== 기타 ====================
MiscTab:CreateToggle({
    Name = "안티 AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) Config.AntiAFK = v end
})

task.spawn(function()
    while true do
        if Config.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        task.wait(35)
    end
end)

MiscTab:CreateButton({
    Name = "캐릭터 리스폰",
    Callback = function()
        if Humanoid then Humanoid.Health = 0 end
    end
})

Rayfield:Notify({
    Title = "Onyx Hub",
    Content = "최강 스파이크 + 풀파워 서브 + 스킨 준비 완료",
    Duration = 5
})
