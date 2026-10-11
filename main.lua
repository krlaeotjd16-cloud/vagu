-- TTK Full | ESP + Fullbright + Silent + Aim + Kill Banner + Spin + Trigger + 3rd Person + GUI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Fullbright = true,
    ESP = true,
    SilentAim = true,
    CameraAim = true,
    Triggerbot = false,
    Spin = false,
    ThirdPerson = true,
    AimKey = Enum.UserInputType.MouseButton2,
    AimPart = "Head",
    FOV = 180,
    ShowFOV = true,
    Smooth = 0.35,
    TeamCheck = true,
    ShowAlly = true,
    MaxESPDistance = 5000,
    KillBanner = true,
    SpinSpeed = 25
}

-- Fullbright
local function applyFullbright()
    if not Config.Fullbright then return end
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
    Lighting.Ambient = Color3.fromRGB(150,150,150)
    Lighting.ExposureCompensation = 0.3
end
RunService.Heartbeat:Connect(applyFullbright)

-- 3rd Person Force
local function forceThirdPerson()
    if not Config.ThirdPerson then return end
    pcall(function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 10
    end)
end
RunService.Heartbeat:Connect(forceThirdPerson)

-- GunController Hook
local GunController
pcall(function() GunController = require(ReplicatedStorage.Modules.Client.Controllers.GunController) end)
local Orig_GetFireDir = GunController and GunController.GetFireDirection
local currentTarget = nil

if GunController then
    GunController.GetFireDirection = function(self, ...)
        if Config.SilentAim and currentTarget and currentTarget.Character then
            local part = currentTarget.Character:FindFirstChild(Config.AimPart) or currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local muzzle = Camera.CFrame.Position
                pcall(function()
                    local cf = self:GetActiveProjectileMuzzleWorldCFrame()
                    if cf then muzzle = cf.Position end
                end)
                return (part.Position - muzzle).Unit
            end
        end
        if Orig_GetFireDir then return Orig_GetFireDir(self, ...) end
    end
end

-- Helpers
local function isTeammate(p)
    if not Config.TeamCheck then return false end
    if p == LocalPlayer then return true end
    local a, b = LocalPlayer:GetAttribute("Team"), p:GetAttribute("Team")
    if a and b and a == b then return true end
    if LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return true end
    return false
end

local function isAlive(model)
    if not model or model.Name:find("_Corpse") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function isAllyModel(model)
    return model:FindFirstChild("AllyTeamHighlight") ~= nil
end

-- ESP
local highlights = {}
local drawings = {}

local function createDraw(cls)
    local d = Drawing.new(cls)
    d.Visible = false
    return d
end

local function clearESP(key)
    if highlights[key] then pcall(function() highlights[key]:Destroy() end) highlights[key] = nil end
    if drawings[key] then
        for _, v in pairs(drawings[key]) do pcall(function() v:Remove() end) end
        drawings[key] = nil
    end
end

local function updateESP()
    if not Config.ESP then
        for k in pairs(highlights) do clearESP(k) end
        for k in pairs(drawings) do clearESP(k) end
        return
    end

    local folder = Workspace:FindFirstChild("MercPlayers")
    if not folder then return end

    local seen = {}
    local bottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

    for _, model in pairs(folder:GetChildren()) do
        if model.Name:match("^MercHitboxes_") and not model.Name:find(LocalPlayer.Name) and isAlive(model) then
            local key = model.Name
            local ally = isAllyModel(model)
            if ally and not Config.ShowAlly then clearESP(key) continue end

            local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not root then clearESP(key) continue end

            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            if dist > Config.MaxESPDistance then clearESP(key) continue end

            local pos, on = Camera:WorldToViewportPoint(root.Position)
            if not on or pos.Z < 0 then
                if drawings[key] then for _, v in pairs(drawings[key]) do v.Visible = false end end
                continue
            end

            seen[key] = true
            local color = ally and Color3.fromRGB(80,230,110) or Color3.fromRGB(255,50,50)

            if not highlights[key] or not highlights[key].Parent then
                if highlights[key] then pcall(function() highlights[key]:Destroy() end) end
                local h = Instance.new("Highlight")
                h.FillTransparency = 0.7
                h.OutlineTransparency = 0.1
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = model
                highlights[key] = h
            end
            highlights[key].OutlineColor = color
            highlights[key].FillColor = color

            if not drawings[key] then
                drawings[key] = { Text = createDraw("Text"), Line = createDraw("Line") }
                drawings[key].Text.Size = 13
                drawings[key].Text.Center = true
                drawings[key].Text.Outline = true
            end

            local d = drawings[key]
            local txt = (hum and math.floor(hum.Health).." HP" or "") .. "\n" .. math.floor(dist) .. "m"
            d.Text.Text = txt
            d.Text.Color = color
            d.Text.Position = Vector2.new(pos.X, pos.Y + 28)
            d.Text.Visible = true

            d.Line.From = bottom
            d.Line.To = Vector2.new(pos.X, pos.Y)
            d.Line.Color = color
            d.Line.Thickness = 1.2
            d.Line.Visible = true
        else
            clearESP(model.Name)
        end
    end

    for k in pairs(highlights) do if not seen[k] then clearESP(k) end end
    for k in pairs(drawings) do if not seen[k] then clearESP(k) end end
end

-- Aim Target
local function getTarget()
    local closest, best = nil, Config.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isTeammate(p) and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = p.Character:FindFirstChild(Config.AimPart) or p.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screen, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local mag = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if mag < best then
                            best = mag
                            closest = p
                        end
                    end
                end
            end
        end
    end
    return closest
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0,230,180)
fovCircle.Transparency = 0.7
fovCircle.Visible = false

-- Kill Banner
local BannerGui = Instance.new("ScreenGui")
BannerGui.Name = "KillBanner"
BannerGui.ResetOnSpawn = false
BannerGui.Parent = game:GetService("CoreGui")

local Banner = Instance.new("Frame")
Banner.Size = UDim2.new(0, 380, 0, 46)
Banner.Position = UDim2.new(0.5, -190, 0, -60)
Banner.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Banner.BackgroundTransparency = 0.15
Banner.BorderSizePixel = 0
Banner.Visible = false
Banner.Parent = BannerGui

Instance.new("UICorner", Banner).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", Banner)
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Thickness = 1.5

local BannerText = Instance.new("TextLabel", Banner)
BannerText.Size = UDim2.new(1, -16, 1, 0)
BannerText.Position = UDim2.new(0, 8, 0, 0)
BannerText.BackgroundTransparency = 1
BannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerText.Font = Enum.Font.GothamBold
BannerText.TextSize = 16
BannerText.TextXAlignment = Enum.TextXAlignment.Center
BannerText.Text = ""

local lastKills = {}

local function showKillBanner(killer, victim)
    if not Config.KillBanner then return end
    BannerText.Text = killer .. "  →  " .. victim
    Banner.Visible = true
    Banner.Position = UDim2.new(0.5, -190, 0, -60)
    local tw = TweenService:Create(Banner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -190, 0, 18)
    })
    tw:Play()
    task.delay(2.2, function()
        local hide = TweenService:Create(Banner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -190, 0, -60)
        })
        hide:Play()
        hide.Completed:Wait()
        Banner.Visible = false
    end)
end

local function setupKillTrack(plr)
    if plr == LocalPlayer then return end
    lastKills[plr] = plr:GetAttribute("Kills") or 0
    plr:GetAttributeChangedSignal("Kills"):Connect(function()
        local new = plr:GetAttribute("Kills") or 0
        if new > (lastKills[plr] or 0) then
            showKillBanner(plr.Name, "Player")
        end
        lastKills[plr] = new
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupKillTrack(p) end
Players.PlayerAdded:Connect(setupKillTrack)

-- Spin
local spinAngle = 0
local function doSpin()
    if not Config.Spin then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    spinAngle = spinAngle + Config.SpinSpeed
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
end

-- GUI
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "TTKMenu"
local f = Instance.new("Frame", gui)
f.Size = UDim2.new(0, 210, 0, 320)
f.Position = UDim2.new(0, 10, 0.5, -160)
f.BackgroundColor3 = Color3.fromRGB(18,18,24)
f.Active = true
f.Draggable = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)

local function makeToggle(name, key)
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(1, -12, 0, 28)
    b.Position = UDim2.new(0, 6, 0, (#f:GetChildren()-1)*30 + 6)
    b.BackgroundColor3 = Color3.fromRGB(32,32,42)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.Text = name .. ": " .. (Config[key] and "ON" or "OFF")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    b.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        b.Text = name .. ": " .. (Config[key] and "ON" or "OFF")
    end)
end

makeToggle("Fullbright", "Fullbright")
makeToggle("ESP", "ESP")
makeToggle("Silent Aim", "SilentAim")
makeToggle("Camera Aim", "CameraAim")
makeToggle("Triggerbot", "Triggerbot")
makeToggle("Spin", "Spin")
makeToggle("3rd Person", "ThirdPerson")
makeToggle("Show FOV", "ShowFOV")
makeToggle("Show Ally", "ShowAlly")
makeToggle("Kill Banner", "KillBanner")

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        f.Visible = not f.Visible
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    updateESP()
    doSpin()
    currentTarget = getTarget()

    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Position = center
    fovCircle.Radius = Config.FOV
    fovCircle.Visible = Config.ShowFOV

    -- Camera Aim
    if Config.CameraAim and UserInputService:IsMouseButtonPressed(Config.AimKey) and currentTarget and currentTarget.Character then
        local part = currentTarget.Character:FindFirstChild(Config.AimPart) or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local screen = Camera:WorldToViewportPoint(part.Position)
            local delta = Vector2.new(screen.X - center.X, screen.Y - center.Y)
            mousemoverel(delta.X * Config.Smooth, delta.Y * Config.Smooth)
        end
    end

    -- Triggerbot
    if Config.Triggerbot and currentTarget and currentTarget.Character then
        local part = currentTarget.Character:FindFirstChild(Config.AimPart) or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local screen, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local mag = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if mag < 40 then
                    mouse1click()
                end
            end
        end
    end
end)

print("[TTK] Full + Spin + Trigger + 3rd Person Loaded")
