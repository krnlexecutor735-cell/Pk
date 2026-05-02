local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ConfigFile = "PunHighlightConfig_V2.json"

local State = {
	SelectionActive = false,
	ShowFriendName = true,
	FriendColor = {255, 255, 255},
	FriendTextSize = 14,
	ClickSelected = {},
	AdvSelected = {},
	AdvHighlightEnabled = false,
	
	EveryoneEnabled = false,
	ShowEveryoneName = false,
	EveryoneColor = {150, 150, 150},
	EveryoneTextSize = 14,
	
	CustomNames = {},
	CustomNameEnabled = {},
	CustomColors = {},
	CustomColorEnabled = {},
	CustomTextSizes = {}, -- เก็บขนาดแยกรายคน
	CustomTextSizeEnabled = {},
	
	MultiTargetNames = {} -- สำหรับ Dropdown ในหน้าขั้นสูง
}

local function SaveConfig()
	pcall(function() writefile(ConfigFile, HttpService:JSONEncode(State)) end)
end

local function LoadConfig()
	if isfile(ConfigFile) then
		pcall(function()
			local decoded = HttpService:JSONDecode(readfile(ConfigFile))
			for k, v in pairs(decoded) do State[k] = v end
		end)
	end
end

LoadConfig()

local function GetColor3(cTable) return Color3.fromRGB(unpack(cTable)) end

local function GetPlayerList()
	local list = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(list, p.Name) end
	end
	return list
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
	bgui.StudsOffset = Vector3.new(0, 3, 0)
	bgui.AlwaysOnTop = true
	
	local lbl = bgui:FindFirstChild("TextLabel") or Instance.new("TextLabel", bgui)
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.GothamBold

	-- Logic ลำดับความสำคัญ
	local finalColor = GetColor3(State.EveryoneColor)
	local finalSize = State.EveryoneTextSize
	local isVisible = State.EveryoneEnabled
	local showTag = State.ShowEveryoneName

	if State.ClickSelected[plr.Name] or (State.AdvSelected[plr.Name] and State.AdvHighlightEnabled) then
		finalColor = GetColor3(State.FriendColor)
		finalSize = State.FriendTextSize
		isVisible = true
		showTag = State.ShowFriendName
	end

	if State.CustomColorEnabled[plr.Name] then finalColor = GetColor3(State.CustomColors[plr.Name]) isVisible = true end
	if State.CustomTextSizeEnabled[plr.Name] then finalSize = State.CustomTextSizes[plr.Name] end

	hl.Enabled = isVisible
	hl.FillColor = finalColor
	hl.OutlineColor = finalColor
	bgui.Enabled = showTag
	lbl.TextColor3 = finalColor
	lbl.TextSize = finalSize
	lbl.Text = (State.CustomNameEnabled[plr.Name] and State.CustomNames[plr.Name]) or plr.Name
end

local Window = WindUI:CreateWindow({ Title = "ไฮไลท์เพื่อน Ultimate", Icon = "shield-check", Author = "by Pun" })

-- TAB 1: เพื่อน
local Tab1 = Window:Tab({ Title = "เพื่อน", Icon = "users" })
Tab1:Toggle({ Title = "โหมดคลิกเลือก", Value = State.SelectionActive, Callback = function(v) State.SelectionActive = v SaveConfig() end })
Tab1:Toggle({ Title = "แสดงชื่อ", Value = State.ShowFriendName, Callback = function(v) State.ShowFriendName = v SaveConfig() end })
Tab1:Dropdown({ Title = "รายชื่อเพื่อน (ขั้นสูง)", Values = GetPlayerList(), Multi = true, Callback = function(v) State.AdvSelected = {} for _, n in pairs(v) do State.AdvSelected[n] = true end SaveConfig() end })
Tab1:Toggle({ Title = "เปิดไฮไลท์จากรายชื่อ", Value = State.AdvHighlightEnabled, Callback = function(v) State.AdvHighlightEnabled = v SaveConfig() end })
Tab1:Colorpicker({ Title = "สีเพื่อน", Default = GetColor3(State.FriendColor), Callback = function(v) State.FriendColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} SaveConfig() end })
Tab1:Slider({ Title = "ขนาดข้อความเพื่อน", Step = 1, Value = { Min = 10, Max = 100, Default = State.FriendTextSize }, Callback = function(v) State.FriendTextSize = v SaveConfig() end })

-- TAB 2: ทุกคน
local Tab2 = Window:Tab({ Title = "ทุกคน", Icon = "globe" })
Tab2:Toggle({ Title = "ดูทุกคน", Value = State.EveryoneEnabled, Callback = function(v) State.EveryoneEnabled = v SaveConfig() end })
Tab2:Toggle({ Title = "แสดงชื่อทุกคน", Value = State.ShowEveryoneName, Callback = function(v) State.ShowEveryoneName = v SaveConfig() end })
Tab2:Colorpicker({ Title = "สีทุกคน", Default = GetColor3(State.EveryoneColor), Callback = function(v) State.EveryoneColor = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} SaveConfig() end })
Tab2:Slider({ Title = "ขนาดข้อความทุกคน", Step = 1, Value = { Min = 10, Max = 100, Default = State.EveryoneTextSize }, Callback = function(v) State.EveryoneTextSize = v SaveConfig() end })

-- TAB 3: ขั้นสูง
local Tab3 = Window:Tab({ Title = "ขั้นสูง", Icon = "zap" })
Tab3:Dropdown({ Title = "เลือกเป้าหมาย (หลายคน)", Values = GetPlayerList(), Multi = true, Callback = function(v) State.MultiTargetNames = v end })

Tab3:Input({ Title = "เปลี่ยนชื่อ", Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomNames[n] = v end SaveConfig() end })
Tab3:Toggle({ Title = "ยืนยันการเปลี่ยนชื่อ", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomNameEnabled[n] = v end SaveConfig() end })
Tab3:Divider()
Tab3:Colorpicker({ Title = "สีเฉพาะตัว", Default = Color3.new(1,1,1), Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomColors[n] = {math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)} end SaveConfig() end })
Tab3:Toggle({ Title = "ยืนยันการใช้สีพิเศษ", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomColorEnabled[n] = v end SaveConfig() end })
Tab3:Divider()
Tab3:Slider({ Title = "ขยายข้อความเฉพาะคน", Step = 1, Value = { Min = 10, Max = 150, Default = 14 }, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomTextSizes[n] = v end SaveConfig() end })
Tab3:Toggle({ Title = "ยืนยันการขยายข้อความ", Value = false, Callback = function(v) for _, n in pairs(State.MultiTargetNames) do State.CustomTextSizeEnabled[n] = v end SaveConfig() end })

Mouse.Button1Down:Connect(function()
	if not State.SelectionActive then return end
	local t = Mouse.Target
	if t and t.Parent:FindFirstChild("Humanoid") then
		local p = Players:GetPlayerFromCharacter(t.Parent)
		if p and p ~= LocalPlayer then State.ClickSelected[p.Name] = not State.ClickSelected[p.Name] SaveConfig() end
	end
end)

RunService.Heartbeat:Connect(function()
	for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyVisuals(p) end end
end)
