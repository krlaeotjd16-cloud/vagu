--[[
Volleyball Legends Silent Hub v3
by Onyx
- Silent Aim 스타일 자동 스파이크
- 풀파워 서브
- 제대로 작동하는 히트박스
- 심플 UI
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Volleyball Legends | Onyx", "DarkTheme")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Character, Humanoid, Root

local function refresh()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
refresh()
LocalPlayer.CharacterAdded:Connect(refresh)

-- Config
local Config = {
    SilentSpike = false,
    AutoServe = false,
    Hitbox = false,
    Speed = false,
    Jump = false,
    ESP = false,

    Range = 18,
    HitboxSize = 12,
    WalkSpeed = 26,
    JumpPower = 65
}

-- 공 찾기 (더 정확하게)
local function getBall()
    local best = nil
    local bestDist = 999
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local name = string.lower(v.Name)
            if name:find("ball") or name == "volleyball" or name == "ball" then
                if Root then
                    local d = (Root.Position - v.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = v
                    end
                else
                    return v
                end
            end
        end
    end
    return best
end

-- 탭
local Main = Window:NewTab("메인")
local MainSec = Main:NewSection("자동")

local MoveTab = Window:NewTab("이동")
local MoveSec = MoveTab:NewSection("이동")

local VisualTab = Window:NewTab("시각")
local VisualSec = VisualTab:NewSection("ESP")

-- ==================== Silent Spike ====================
MainSec:NewToggle("사일런트 스파이크 (자동)", "공 근처 오면 자동으로 최강 스파이크", function(v)
    Config.SilentSpike = v
    if v then
        task.spawn(function()
            while Config.SilentSpike do
                pcall(function()
                    local ball = getBall()
                    if ball and Root and Humanoid then
                        local dist = (Root.Position - ball.Position).Magnitude
                        if dist <= Config.Range then
                            -- 공 쪽으로 살짝 이동
                            local targetPos = ball.Position + Vector3.new(0, 2, 0)
                            Root.CFrame = CFrame.new(Root.Position:Lerp(targetPos, 0.4))
                            
                            -- 점프
                            Humanoid.Jump = true
                            
                            -- 강제 클릭 (스파이크)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                            task.wait(0.03)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        end
                    end
                end)
                task.wait(0.05)
            end
        end)
    end
end)

MainSec:NewSlider("스파이크 범위", "얼마나 멀리 있는 공까지 칠지", 6, 30, 18, function(v)
    Config.Range = v
end)

-- ==================== Auto Serve ====================
MainSec:NewToggle("자동 풀파워 서브", "서브 차례에 최대 파워로 때림", function(v)
    Config.AutoServe = v
    if v then
        task.spawn(function()
            while Config.AutoServe do
                pcall(function()
                    -- 서브 시작 + 풀파워
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    task.wait(0.08)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
                task.wait(0.5)
            end
        end)
    end
end)

-- ==================== Hitbox ====================
MainSec:NewToggle("히트박스 확장", "공을 크게 만듦", function(v)
    Config.Hitbox = v
    if v then
        task.spawn(function()
            while Config.Hitbox do
                pcall(function()
                    local ball = getBall()
                    if ball then
                        ball.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        ball.Transparency = 0.5
                        ball.CanCollide = true
                        ball.Material = Enum.Material.ForceField
                    end
                end)
                task.wait(0.07)
            end
        end)
    else
        local ball = getBall()
        if ball then
            ball.Size = Vector3.new(1.5, 1.5, 1.5)
            ball.Transparency = 0
            ball.Material = Enum.Material.Plastic
        end
    end
end)

MainSec:NewSlider("히트박스 크기", "", 3, 20, 12, function(v)
    Config.HitboxSize = v
end)

-- ==================== 이동 ====================
MoveSec:NewToggle("스피드", "", function(v)
    Config.Speed = v
    if Humanoid then
        Humanoid.WalkSpeed = v and Config.WalkSpeed or 16
    end
end)

MoveSec:NewSlider("WalkSpeed", "", 16, 40, 26, function(v)
    Config.WalkSpeed = v
    if Config.Speed and Humanoid then
        Humanoid.WalkSpeed = v
    end
end)

MoveSec:NewToggle("점프 부스트", "", function(v)
    Config.Jump = v
    if Humanoid then
        Humanoid.JumpPower = v and Config.JumpPower or 50
    end
end)

MoveSec:NewSlider("JumpPower", "", 50, 100, 65, function(v)
    Config.JumpPower = v
    if Config.Jump and Humanoid then
        Humanoid.JumpPower = v
    end
end)

-- ==================== ESP ====================
local highlight = nil

VisualSec:NewToggle("공 ESP", "", function(v)
    Config.ESP = v
    if not v and highlight then
        highlight:Destroy()
        highlight = nil
    end
    if v then
        task.spawn(function()
            while Config.ESP do
                pcall(function()
                    local ball = getBall()
                    if ball then
                        if not highlight or highlight.Adornee ~= ball then
                            if highlight then highlight:Destroy() end
                            highlight = Instance.new("Highlight")
                            highlight.FillColor = Color3.fromRGB(0, 255, 100)
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.3
                            highlight.Adornee = ball
                            highlight.Parent = ball
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

print("Onyx Silent Hub 로드 완료")
