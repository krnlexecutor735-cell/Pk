local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local ConfigFile = "PunConfig_V17.json"
local State = {
    SelectionActive = false, ShowFriendName = true, FriendColor = {255, 255, 255}, FriendTextSize = 14,
    ClickSelected = {}, AdvSelected = {}, AdvHighlightEnabled = false, EveryoneEnabled = false,
    ShowEveryoneName = false, EveryoneColor = {150, 150, 150}, EveryoneTextSize = 14,
    CustomNames = {}, CustomNameEnabled = {}, CustomColors = {}, CustomColorEnabled = {},
    CustomTextSizes = {}, CustomTextSizeEnabled = {}, 
    TargetNamePlrs = {}, TargetColorPlrs = {}, TargetSizePlrs = {},
    AimEnabled = false, AimFOV = 150, AimColor = {48, 255, 106}, RainbowAim = false,
    RainbowSpeed = 400, AimThroughWall = false,
    WalkSpeed = 16, JumpPower = 50, InfJump = false, Fling = false, Noclip = false
}

local function Save() pcall(function() writefile(ConfigFile, HttpService:JSONEncode(State)) end) end
local function Load() if isfile(ConfigFile) then pcall(function() local d = HttpService:JSONDecode(readfile(ConfigFile)) for k, v in pairs(d) do State[k] = v end end) end end
Load()

local RainbowColor = Color3.new(1,1,1)
task.spawn(function()
    local h = 0
    while true do
        h = h + (1/math.max(State.RainbowSpeed, 1))
        if h > 1 then h = 0 end
        RainbowColor = Color3.fromHSV(h, 0.8, 1)
        task.wait()
    end
end)

local function GetPlrs()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end
    return t
end

local function GetCurrentTarget()
    if not State.AimEnabled then return nil end
    local target, close = nil, State.AimFOV
    local mid = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            local head = v.Character.Head
            local p, vis = Camera:WorldToViewportPoint(head.Position)
            if vis then
                local mag = (Vector2.new(p.X, p.Y) - mid).Magnitude
                local canSee = true
                if not State.AimThroughWall then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, v.Character, Camera}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local result = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * (head.Position - Camera.CFrame.Position).Magnitude, rayParams)
                    if result then canSee = false end
                end
                if mag < close and canSee then close = mag target = v end
            end
        end
    end
    return target
end

local CurrentLock = nil

local function ApplyVisuals(plr)
    local char = plr.Character
    if not char then return end
    local hl = char:FindFirstChild("PunHL") or Instance.new("Highlight", char)
    hl.Name = "PunHL"
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bgui = char:FindFirstChild("PunTag") or Instance.new("BillboardGui", char)
    bgui.Name, bgui.Adornee, bgui.Size, bgui.AlwaysOnTop = "PunTag", head, UDim2.new(0, 200, 0, 50), true
    local lbl = bgui:FindFirstChild("Text") or Instance.new("TextLabel", bgui)
    lbl.Name, lbl.BackgroundTransparency, lbl.Size, lbl.Font = "Text", 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold

    local color, size, vis, show = Color3.fromRGB(unpack(State.EveryoneColor)), State.EveryoneTextSize, State.EveryoneEnabled, State.ShowEveryoneName
    if State.ClickSelected[plr.Name] or (State.AdvSelected[plr.Name] and State.AdvHighlightEnabled) then
        color, size, vis, show = Color3.fromRGB(unpack(State.FriendColor)), State.FriendTextSize, true, State.ShowFriendName
    end
    if State.CustomColorEnabled[plr.Name] then color = Color3.fromRGB(unpack(State.CustomColors[plr.Name])) vis = true end
    if State.CustomTextSizeEnabled[plr.Name] then size = State.CustomTextSizes[plr.Name] end
    if CurrentLock == plr then color = RainbowColor vis = true end

    hl.Enabled, hl.FillColor, hl.OutlineColor = vis, color, color
    bgui.Enabled, lbl.TextColor3, lbl.TextSize, lbl.Text = show, color, size, (State.CustomNameEnabled[plr.Name] and State.CustomNames[plr.Name]) or plr.Name
end

if LocalPlayer.PlayerGui:FindFirstChild("PunFOV") then LocalPlayer.PlayerGui.PunFOV:Destroy() end
local fovGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
fovGui.Name, fovGui.IgnoreGuiInset, fovGui.DisplayOrder = "PunFOV", true, 999
local circ = Instance.new("Frame", fovGui)
circ.AnchorPoint, circ.BackgroundTransparency, circ.Visible = Vector2.new(0.5, 0.5), 1, false
local stroke = Instance.new("UIStroke", circ)
stroke.Thickness = 2
Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

local Window = WindUI:CreateWindow({ Title = "ไฮไลท์เพื่อน", Icon = "shield-check", Author = "by Pun" })

local T1 = Window:Tab({ Title = "เพื่อน", Icon = "users" })
T1:Toggle({ Title = "โหมดคลิกเลือก", Value = State.SelectionActive, Callback = function(v) State.SelectionActive = v Save() end })
T1:Toggle({ Title = "แสดงชื่อ", Value = State.ShowFriendName, Callback = function(v) State.ShowFriendName = v Save() end })
T1:Dropdown({ Title = "รายชื่อเพื่อน", Values = GetPlrs(), Multi = true, Callback = function(v) State.AdvSelected = {} for _, n in pairs(v) do State.AdvSelected[n] = true end Save() end })
T1:Toggle({ Title = "เปิดไฮไลท์จากรายชื่อ", Value = State.AdvHighlightEnabled, Callback = function(v) State.AdvHighlightEnabled = v Save() end })
T1:Colorpicker({ Title = "สีเพื่อน", Default = Color3.fromRGB(unpack(State.FriendColor)), Callback = function(v) State.FriendColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T1:Slider({ Title = "ขนาดข้อความเพื่อน", Step = 1, Value = { Min = 10, Max = 100, Default = State.FriendTextSize }, Callback = function(v) State.FriendTextSize = v Save() end })

local T2 = Window:Tab({ Title = "ทุกคน", Icon = "globe" })
T2:Toggle({ Title = "ดูทุกคน", Value = State.EveryoneEnabled, Callback = function(v) State.EveryoneEnabled = v Save() end })
T2:Toggle({ Title = "แสดงชื่อทุกคน", Value = State.ShowEveryoneName, Callback = function(v) State.ShowEveryoneName = v Save() end })
T2:Colorpicker({ Title = "สีทุกคน", Default = Color3.fromRGB(unpack(State.EveryoneColor)), Callback = function(v) State.EveryoneColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T2:Slider({ Title = "ขนาดข้อความทุกคน", Step = 1, Value = { Min = 10, Max = 100, Default = State.EveryoneTextSize }, Callback = function(v) State.EveryoneTextSize = v Save() end })

local T3 = Window:Tab({ Title = "ขั้นสูง", Icon = "zap" })
T3:Section({ Title = "ตั้งค่าชื่อเฉพาะ" })
T3:Dropdown({ Title = "เลือกคนที่จะเปลี่ยนชื่อ", Values = GetPlrs(), Multi = true, Callback = function(v) State.TargetNamePlrs = v end })
T3:Input({ Title = "พิมพ์ชื่อใหม่", Callback = function(v) for _, n in pairs(State.TargetNamePlrs) do State.CustomNames[n] = v end Save() end })
T3:Toggle({ Title = "เปิดใช้งานชื่อพิเศษ", Value = false, Callback = function(v) for _, n in pairs(State.TargetNamePlrs) do State.CustomNameEnabled[n] = v end Save() end })
T3:Divider()
T3:Section({ Title = "ตั้งค่าสีเฉพาะ" })
T3:Dropdown({ Title = "เลือกคนที่จะเปลี่ยนสี", Values = GetPlrs(), Multi = true, Callback = function(v) State.TargetColorPlrs = v end })
T3:Colorpicker({ Title = "เลือกสี", Default = Color3.new(1,1,1), Callback = function(v) for _, n in pairs(State.TargetColorPlrs) do State.CustomColors[n] = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} end Save() end })
T3:Toggle({ Title = "เปิดใช้งานสีพิเศษ", Value = false, Callback = function(v) for _, n in pairs(State.TargetColorPlrs) do State.CustomColorEnabled[n] = v end Save() end })
T3:Divider()
T3:Section({ Title = "ตั้งค่าขนาดข้อความเฉพาะ" })
T3:Dropdown({ Title = "เลือกคนที่จะปรับขนาด", Values = GetPlrs(), Multi = true, Callback = function(v) State.TargetSizePlrs = v end })
T3:Slider({ Title = "ขนาดข้อความ", Step = 1, Value = { Min = 10, Max = 150, Default = 14 }, Callback = function(v) for _, n in pairs(State.TargetSizePlrs) do State.CustomTextSizes[n] = v end Save() end })
T3:Toggle({ Title = "เปิดใช้งานขนาดพิเศษ", Value = false, Callback = function(v) for _, n in pairs(State.TargetSizePlrs) do State.CustomTextSizeEnabled[n] = v end Save() end })

local T4 = Window:Tab({ Title = "เล็งเป้าหมาย", Icon = "crosshair" })
T4:Toggle({ Title = "ปุ่มเล็งหัว", Value = State.AimEnabled, Callback = function(v) State.AimEnabled = v Save() end })
T4:Toggle({ Title = "เล็งทะลุกำแพง", Value = State.AimThroughWall, Callback = function(v) State.AimThroughWall = v Save() end })
T4:Toggle({ Title = "โหมดสายรุ้งสมูท", Value = State.RainbowAim, Callback = function(v) State.RainbowAim = v Save() end })
T4:Slider({ Title = "ความเร็วสายรุ้ง", Step = 1, Value = { Min = 50, Max = 1000, Default = 1050 - State.RainbowSpeed }, Callback = function(v) State.RainbowSpeed = 1050 - v Save() end })
T4:Colorpicker({ Title = "สีเป้าหมาย", Default = Color3.fromRGB(unpack(State.AimColor)), Callback = function(v) State.AimColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T4:Slider({ Title = "ระยะการเล็ง", Step = 1, Value = { Min = 10, Max = 800, Default = State.AimFOV }, Callback = function(v) State.AimFOV = v Save() end })

local T5 = Window:Tab({ Title = "ตั้งค่าตัวเรา", Icon = "settings" })
T5:Slider({ Title = "ความเร็วการเดิน", Step = 1, Value = { Min = 16, Max = 200, Default = State.WalkSpeed }, Callback = function(v) State.WalkSpeed = v Save() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
T5:Toggle({ Title = "กระโดดไม่จำกัด", Value = State.InfJump, Callback = function(v) State.InfJump = v Save() end })
T5:Toggle({ Title = "ดีดผู้เล่น", Value = State.Fling, Callback = function(v) State.Fling = v Save() end })
T5:Toggle({ Title = "ทะลุกำแพง", Value = State.Noclip, Callback = function(v) State.Noclip = v Save() end })
T5:Button({ Title = "เปิดระบบบิน", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end })

Mouse.Button1Down:Connect(function()
    if State.SelectionActive then
        local t = Mouse.Target
        local p = t and t.Parent and Players:GetPlayerFromCharacter(t.Parent)
        if p and p ~= LocalPlayer then State.ClickSelected[p.Name] = not State.ClickSelected[p.Name] Save() end
    end
end)

UIS.JumpRequest:Connect(function()
    if State.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RS.RenderStepped:Connect(function()
    local mid = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    CurrentLock = GetCurrentTarget()
    circ.Visible = State.AimEnabled
    if circ.Visible then
        circ.Size = UDim2.fromOffset(State.AimFOV * 2, State.AimFOV * 2)
        circ.Position = UDim2.fromOffset(mid.X, mid.Y)
        stroke.Color = State.RainbowAim and RainbowColor or Color3.fromRGB(unpack(State.AimColor))
    end
    if CurrentLock and CurrentLock.Character and CurrentLock.Character:FindFirstChild("Head") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentLock.Character.Head.Position)
    end
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyVisuals(p) end end
end)

RS.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end
    if State.Fling then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(0, 30000, 0) end
    end
end)

WindUI:Notify({ Title = "ระบบพร้อมใช้งาน", Content = "" })
