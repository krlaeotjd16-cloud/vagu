--[[
Volleyball Legends Silent Hub v4
by Onyx
- 필요할 때만 스파이크
- 자연스러운 이동
- 딜레이 최소화
- 숫자 직접 입력
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Volleyball Legends | Onyx v4", "DarkTheme")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

    Range = 16,          -- 최대 추천 25
    HitboxSize = 10,     -- 최대 추천 20
    WalkSpeed = 24,      -- 최대 추천 35
    JumpPower = 60,      -- 최대 추천 90
    SpikeCooldown = 0.001
}

local lastSpike = 0

-- 공 찾기
local function getBall()
    local best, bestDist = nil, 999
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = string.lower(v.Name)
            if n:find("ball") or n == "volleyball" then
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
local MainSec = Main:NewSection("자동 기능")

local Set = Window:NewTab("수치 설정")
local SetSec = Set:NewSection("직접 입력 (최대값 참고)")

local Move = Window:NewTab("이동")
local MoveSec = Move:NewSection("이동")

local Visual = Window:NewTab("시각")
local VisSec = Visual:NewSection("ESP")

-- ==================== 필요할 때만 스파이크 ====================
MainSec:NewToggle("사일런트 스파이크 (필요할 때만)", "공 가까이 + 공중일 때만 작동", function(v)
    Config.SilentSpike = v
    if v then
        task.spawn(function()
            while Config.SilentSpike do
                pcall(function()
                    local ball = getBall()
                    if ball and Root and Humanoid then
                        local dist = (Root.Position - ball.Position).Magnitude
                        local inAir = Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping
                        
                        -- 필요할 때만: 거리 안 + 공중이거나 점프 직전
                        if dist <= Config.Range and (inAir or dist < 8) then
                            if tick() - lastSpike > Config.SpikeCooldown then
                                lastSpike = tick()
                                
                                -- 자연스럽게 공 방향으로 살짝 이동 (텔레포트 아님)
                                local dir = (ball.Position - Root.Position).Unit
                                Root.AssemblyLinearVelocity = Vector3.new(dir.X * 18, Root.AssemblyLinearVelocity.Y, dir.Z * 18)
                                
                                -- 점프가 안 되어 있으면 점프
                                if not inAir then
                                    Humanoid.Jump = true
                                end
                                
                                -- 클릭
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                task.wait(0.008)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            end
                        end
                    end
                end)
                task.wait(0.001) -- 거의 0
            end
        end)
    end
end)

MainSec:NewToggle("자동 풀파워 서브", "서브 때 최대 파워", function(v)
    Config.AutoServe = v
    if v then
        task.spawn(function()
            while Config.AutoServe do
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
                task.wait(0.45)
            end
        end)
    end
end)

-- ==================== 히트박스 (제대로 붙게) ====================
local hitboxPart = nil

MainSec:NewToggle("히트박스 확장", "공에 강제 부착", function(v)
    Config.Hitbox = v
    if v then
        task.spawn(function()
            while Config.Hitbox do
                pcall(function()
                    local ball = getBall()
                    if ball then
                        if not hitboxPart or not hitboxPart.Parent then
                            hitboxPart = Instance.new("Part")
                            hitboxPart.Name = "OnyxHitbox"
                            hitboxPart.Anchored = true
                            hitboxPart.CanCollide = false
                            hitboxPart.Transparency = 0.6
                            hitboxPart.Material = Enum.Material.ForceField
                            hitboxPart.Color = Color3.fromRGB(0, 255, 100)
                            hitboxPart.Parent = workspace
                        end
                        hitboxPart.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        hitboxPart.CFrame = ball.CFrame
                    end
                end)
                task.wait(0.001)
            end
        end)
    else
        if hitboxPart then
            hitboxPart:Destroy()
            hitboxPart = nil
        end
    end
end)

-- ==================== 수치 직접 입력 ====================
SetSec:NewTextBox("스파이크 범위 (최대 25 추천)", "숫자 입력", function(txt)
    local n = tonumber(txt)
    if n then Config.Range = math.clamp(n, 1, 40) end
end)

SetSec:NewTextBox("히트박스 크기 (최대 20 추천)", "숫자 입력", function(txt)
    local n = tonumber(txt)
    if n then Config.HitboxSize = math.clamp(n, 1, 30) end
end)

SetSec:NewTextBox("WalkSpeed (최대 35 추천)", "숫자 입력", function(txt)
    local n = tonumber(txt)
    if n then
        Config.WalkSpeed = math.clamp(n, 16, 50)
        if Config.Speed and Humanoid then
            Humanoid.WalkSpeed = Config.WalkSpeed
        end
    end
end)

SetSec:NewTextBox("JumpPower (최대 90 추천)", "숫자 입력", function(txt)
    local n = tonumber(txt)
    if n then
        Config.JumpPower = math.clamp(n, 50, 120)
        if Config.Jump and Humanoid then
            Humanoid.JumpPower = Config.JumpPower
        end
    end
end)

SetSec:NewLabel("현재 값 확인은 토글 켠 뒤 직접 체감하면 됨")

-- ==================== 이동 ====================
MoveSec:NewToggle("스피드", "", function(v)
    Config.Speed = v
    if Humanoid then
        Humanoid.WalkSpeed = v and Config.WalkSpeed or 16
    end
end)

MoveSec:NewToggle("점프 부스트", "", function(v)
    Config.Jump = v
    if Humanoid then
        Humanoid.JumpPower = v and Config.JumpPower or 50
    end
end)

-- ==================== ESP ====================
local hl = nil

VisSec:NewToggle("공 ESP", "", function(v)
    Config.ESP = v
    if not v and hl then
        hl:Destroy()
        hl = nil
    end
    if v then
        task.spawn(function()
            while Config.ESP do
                pcall(function()
                    local ball = getBall()
                    if ball then
                        if not hl or hl.Adornee ~= ball then
                            if hl then hl:Destroy() end
                            hl = Instance.new("Highlight")
                            hl.FillColor = Color3.fromRGB(0, 255, 100)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.35
                            hl.Adornee = ball
                            hl.Parent = ball
                        end
                    end
                end)
                task.wait(0.05)
            end
        end)
    end
end)

print("[Onyx] v4 로드 완료 - 필요할 때만 스파이크 + 숫자 입력 지원")
