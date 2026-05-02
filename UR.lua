local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local ConfigFile = "PunConfig_V9.json"
local State = {
    SelectionActive = false, ShowFriendName = true, FriendColor = {255, 255, 255}, FriendTextSize = 14,
    ClickSelected = {}, AdvSelected = {}, AdvHighlightEnabled = false, EveryoneEnabled = false,
    ShowEveryoneName = false, EveryoneColor = {150, 150, 150}, EveryoneTextSize = 14,
    CustomNames = {}, CustomNameEnabled = {}, CustomColors = {}, CustomColorEnabled = {},
    CustomTextSizes = {}, CustomTextSizeEnabled = {}, MultiTargetNames = {},
    AimEnabled = false, AimFOV = 150, AimColor = {48, 255, 106}, RainbowAim = false,
    AimThroughWall = false, -- เพิ่มสถานะปุ่มเล็งทะลุกำแพง
    WalkSpeed = 16, JumpPower = 50, InfJump = false, Fling = false, Noclip = false
}

local function Save() pcall(function() writefile(ConfigFile, HttpService:JSONEncode(State)) end) end
local function Load() if isfile(ConfigFile) then pcall(function() local d = HttpService:JSONDecode(readfile(ConfigFile)) for k, v in pairs(d) do State[k] = v end end) end end
Load()

local RainbowColor = Color3.new(1,1,1)
task.spawn(function()
    local h = 0
    while true do
        h = h + (1/400)
        if h > 1 then h = 0 end
        RainbowColor = Color3.fromHSV(h, 0.8, 1)
        task.wait()
    end
end)

local function GetC3(t) return Color3.fromRGB(unpack(t)) end
local function GetPlrs()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end
    return t
end

local function IsVisible(part, character)
    if State.AimThroughWall then return true end -- ถ้าเปิดปุ่มเล็งทะลุกำแพง ให้คืนค่า true ทันที
    
    local origin = Camera.CFrame.Position
    local destination = part.Position
    local direction = (destination - origin).Unit * (destination - origin).Magnitude
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function ApplyVisuals(plr)
    local char = plr.Character
    if not char then return end
    local hl = char:FindFirstChild("PunHL") or Instance.new("Highlight", char)
    hl.Name = "PunHL"
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    local bgui = char:FindFirstChild("PunTag") or Instance.new("BillboardGui", char)
    bgui.Name = "PunTag"
    bgui.Adornee = head
    bgui.Size = UDim2.new(0, 200, 0, 50)
    bgui.AlwaysOnTop = true
    local lbl = bgui:FindFirstChild("Text") or Instance.new("TextLabel", bgui)
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold

    local color, size, vis, show = GetC3(State.EveryoneColor), State.EveryoneTextSize, State.EveryoneEnabled, State.ShowEveryoneName
    if State.ClickSelected[plr.Name] or (State.AdvSelected[plr.Name] and State.AdvHighlightEnabled) then
        color, size, vis, show = GetC3(State.FriendColor), State.FriendTextSize, true, State.ShowFriendName
    end
    if State.CustomColorEnabled[plr.Name] then color = GetC3(State.CustomColors[plr.Name]) vis = true end
    if State.CustomTextSizeEnabled[plr.Name] then size = State.CustomTextSizes[plr.Name] end

    hl.Enabled, hl.FillColor, hl.OutlineColor = vis, color, color
    bgui.Enabled, lbl.TextColor3, lbl.TextSize, lbl.Text = show, color, size, (State.CustomNameEnabled[plr.Name] and State.CustomNames[plr.Name]) or plr.Name
end

local Window = WindUI:CreateWindow({ Title = "ไฮไลท์เพื่อน", Icon = "shield-check", Author = "by Pun" })

local T1 = Window:Tab({ Title = "เพื่อน", Icon = "users" })
T1:Toggle({ Title = "โหมดคลิกเลือก", Value = State.SelectionActive, Callback = function(v) State.SelectionActive = v Save() end })
T1:Toggle({ Title = "แสดงชื่อ", Value = State.ShowFriendName, Callback = function(v) State.ShowFriendName = v Save() end })
T1:Dropdown({ Title = "รายชื่อเพื่อน", Values = GetPlrs(), Multi = true, Callback = function(v) State.AdvSelected = {} for _, n in pairs(v) do State.AdvSelected[n] = true end Save() end })
T1:Toggle({ Title = "เปิดไฮไลท์จากรายชื่อ", Value = State.AdvHighlightEnabled, Callback = function(v) State.AdvHighlightEnabled = v Save() end })
T1:Colorpicker({ Title = "สีเพื่อน", Default = GetC3(State.FriendColor), Callback = function(v) State.FriendColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T1:Slider({ Title = "ขนาดข้อความเพื่อน", Step = 1, Value = { Min = 10, Max = 100, Default = State.FriendTextSize }, Callback = function(v) State.FriendTextSize = v Save() end })

local T2 = Window:Tab({ Title = "ทุกคน", Icon = "globe" })
T2:Toggle({ Title = "ดูทุกคน", Value = State.EveryoneEnabled, Callback = function(v) State.EveryoneEnabled = v Save() end })
T2:Toggle({ Title = "แสดงชื่อทุกคน", Value = State.ShowEveryoneName, Callback = function(v) State.ShowEveryoneName = v Save() end })
T2:Colorpicker({ Title = "สีทุกคน", Default = GetC3(State.EveryoneColor), Callback = function(v) State.EveryoneColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T2:Slider({ Title = "ขนาดข้อความทุกคน", Step = 1, Value = { Min = 10, Max = 100, Default = State.EveryoneTextSize }, Callback = function(v) State.EveryoneTextSize = v Save() end })

local T3 = Window:Tab({ Title = "ขั้นสูง", Icon = "zap" })
T3:Dropdown({ Title = "เลือกเป้าหมาย", Values = GetPlrs(), Multi = true, Callback = function(v) State.MultiTargetNames = v end })
T3:Input({ Title = "เปลี่ยนชื่อ", Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomNames[n] = v end Save() end })
T3:Toggle({ Title = "ยืนยันการเปลี่ยนชื่อ", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomNameEnabled[n] = v end Save() end })
T3:Colorpicker({ Title = "สีเฉพาะตัว", Default = Color3.new(1,1,1), Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomColors[n] = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} end Save() end })
T3:Toggle({ Title = "ยืนยันสีพิเศษ", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomColorEnabled[n] = v end Save() end })
T3:Slider({ Title = "ขยายข้อความเฉพาะคน", Step = 1, Value = { Min = 10, Max = 150, Default = 14 }, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomTextSizes[n] = v end Save() end })
T3:Toggle({ Title = "ยืนยันการขยาย", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomTextSizeEnabled[n] = v end Save() end })

local T4 = Window:Tab({ Title = "เล็งเป้าหมาย", Icon = "crosshair" })
T4:Toggle({ Title = "ปุ่มเล็งหัว", Value = State.AimEnabled, Callback = function(v) State.AimEnabled = v Save() end })
T4:Toggle({ Title = "เล็งทะลุกำแพง", Value = State.AimThroughWall, Callback = function(v) State.AimThroughWall = v Save() end })
T4:Toggle({ Title = "โหมดสายรุ้งสมูท", Value = State.RainbowAim, Callback = function(v) State.RainbowAim = v Save() end })
T4:Colorpicker({ Title = "สีเป้าหมาย", Default = GetC3(State.AimColor), Callback = function(v) State.AimColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} Save() end })
T4:Slider({ Title = "ระยะการเล็ง", Step = 1, Value = { Min = 10, Max = 800, Default = State.AimFOV }, Callback = function(v) State.AimFOV = v Save() end })

local T5 = Window:Tab({ Title = "ตั้งค่าตัวเรา", Icon = "settings" })
T5:Slider({ Title = "ความเร็วการเดิน", Step = 1, Value = { Min = 16, Max = 200, Default = State.WalkSpeed }, Callback = function(v) State.WalkSpeed = v Save() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
T5:Slider({ Title = "พลังการกระโดด", Step = 1, Value = { Min = 50, Max = 300, Default = State.JumpPower }, Callback = function(v) State.JumpPower = v Save() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = v end end })
T5:Toggle({ Title = "กระโดดไม่จำกัด", Value = State.InfJump, Callback = function(v) State.InfJump = v Save() end })
T5:Toggle({ Title = "ดีดผู้เล่น", Value = State.Fling, Callback = function(v) State.Fling = v Save() if v then task.spawn(function() local hrp, vel, movel = nil, nil, 0.1 while State.Fling do RS.Heartbeat:Wait() local char = LocalPlayer.Character hrp = char and char:FindFirstChild("HumanoidRootPart") if hrp then vel = hrp.Velocity hrp.Velocity = vel * 15000 + Vector3.new(0, 15000, 0) RS.RenderStepped:Wait() hrp.Velocity = vel RS.Stepped:Wait() hrp.Velocity = vel + Vector3.new(0, movel, 0) movel = -movel end end end) end end })
T5:Toggle({ Title = "ทะลุกำแพง", Value = State.Noclip, Callback = function(v) State.Noclip = v Save() if not v and LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end end })
T5:Button({ Title = "บิน", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end })

local fovGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
fovGui.IgnoreGuiInset = true
local circ = Instance.new("Frame", fovGui)
circ.AnchorPoint, circ.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
local stroke = Instance.new("UIStroke", circ)
stroke.Thickness = 2
Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

Mouse.Button1Down:Connect(function()
    if not State.SelectionActive then return end
    local t = Mouse.Target
    if t and t.Parent:FindFirstChild("Humanoid") then
        local p = Players:GetPlayerFromCharacter(t.Parent)
        if p and p ~= LocalPlayer then State.ClickSelected[p.Name] = not State.ClickSelected[p.Name] Save() end
    end
end)

UIS.JumpRequest:Connect(function()
    if State.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RS.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

RS.RenderStepped:Connect(function()
    local mid = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local activeCol = State.RainbowAim and RainbowColor or GetC3(State.AimColor)
    
    circ.Visible = State.AimEnabled
    if circ.Visible then
        circ.Size = UDim2.fromOffset(State.AimFOV * 2, State.AimFOV * 2)
        circ.Position, stroke.Color = UDim2.fromOffset(mid.X, mid.Y), activeCol
    end
    
    if State.AimEnabled then
        local target, close = nil, State.AimFOV
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
                local head = v.Character.Head
                local p, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local mag = (Vector2.new(p.X, p.Y) - mid).Magnitude
                    if mag < close and IsVisible(head, v.Character) then 
                        close, target = mag, v 
                    end
                end
            end
        end
        if target then 
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position) 
        end
    end
    
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyVisuals(p) end end
end)

WindUI:Notify({ Title = "โหลดสำเร็จ", Content = "" })
