-- ABILITY MENU • JAYVEE
-- Own-game LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
--
-- Style inspired by the user's reference image:
-- dark translucent panel, purple active tab, rounded controls,
-- bottom navigation, draggable window.
--
-- Includes:
-- • Security password screen
-- • Home / Power / Player pages
-- • Goku > Ultra Instinct ability
-- • Player-radius visual circle
-- • Radius 1+ / 1- controls
-- • Radius display
-- • Auto-dodge / camera / follow controls
-- • Mobile-friendly dragging
-- • UI sounds and animations

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PASSWORD = "ULTRAINSTINCTBYJAYVEEV2"

local Settings = {
	Enabled = true,
	AutoDodge = true,
	CameraLock = true,
	FollowAfterDodge = true,
	FollowDuration = 5,
	Radius = 12,
	MinRadius = 3,
	MaxRadius = 50,
	RadiusStep = 1,
	Ability = "Ultra Instinct",
}

local character
local humanoid
local root
local lastHealth
local damageConnection

local dodging = false
local cameraLocked = false
local following = false
local followTarget
local followToken = 0
local menuOpen = false

local function refreshCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	lastHealth = humanoid.Health
end

refreshCharacter()

local function makeSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 0.45
	s.Parent = SoundService
	return s
end

local clickSound = makeSound(9118828568, 0.4)
local openSound = makeSound(9118823107, 0.45)
local dodgeSound = makeSound(138186576, 0.5)
local stopSound = makeSound(9118828568, 0.3)

local function play(sound)
	pcall(function()
		sound:Play()
	end)
end

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function addStroke(obj, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = 1.4
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end

local function tween(obj, time, props, style, direction)
	return TweenService:Create(
		obj,
		TweenInfo.new(
			time,
			style or Enum.EasingStyle.Quint,
			direction or Enum.EasingDirection.Out
		),
		props
	)
end

local function draggable(frame, handle)
	local dragging = false
	local dragStart
	local startPos
	handle = handle or frame

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)
end

--==================================================
-- ScreenGui
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "AbilityMenu_JAYVEE"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

--==================================================
-- SECURITY
--==================================================

local security = Instance.new("Frame")
security.Size = UDim2.fromOffset(410, 275)
security.Position = UDim2.new(0.5, -205, 0.5, -138)
security.BackgroundColor3 = Color3.fromRGB(12, 11, 17)
security.BackgroundTransparency = 0.04
security.Parent = gui
corner(security, 22)
addStroke(security, 0.1)
draggable(security)

local secScale = Instance.new("UIScale")
secScale.Scale = 0.84
secScale.Parent = security

local secTitle = Instance.new("TextLabel")
secTitle.BackgroundTransparency = 1
secTitle.Size = UDim2.new(1, -30, 0, 42)
secTitle.Position = UDim2.fromOffset(15, 13)
secTitle.Text = "ABILITY MENU"
secTitle.Font = Enum.Font.GothamBlack
secTitle.TextSize = 28
secTitle.TextColor3 = Color3.new(1, 1, 1)
secTitle.Parent = security

local secSub = Instance.new("TextLabel")
secSub.BackgroundTransparency = 1
secSub.Size = UDim2.new(1, -30, 0, 24)
secSub.Position = UDim2.fromOffset(15, 53)
secSub.Text = "SECURITY ACCESS  •  JAYVEE"
secSub.Font = Enum.Font.GothamBold
secSub.TextSize = 11
secSub.TextColor3 = Color3.fromRGB(155, 150, 175)
secSub.Parent = security

local passBox = Instance.new("TextBox")
passBox.Size = UDim2.new(1, -40, 0, 48)
passBox.Position = UDim2.fromOffset(20, 91)
passBox.PlaceholderText = "ENTER ACCESS KEY"
passBox.Text = ""
passBox.ClearTextOnFocus = false
passBox.Font = Enum.Font.GothamBold
passBox.TextSize = 13
passBox.TextColor3 = Color3.new(1, 1, 1)
passBox.PlaceholderColor3 = Color3.fromRGB(120, 115, 135)
passBox.BackgroundColor3 = Color3.fromRGB(25, 23, 34)
passBox.Parent = security
corner(passBox, 13)

local unlock = Instance.new("TextButton")
unlock.Size = UDim2.new(1, -40, 0, 47)
unlock.Position = UDim2.fromOffset(20, 151)
unlock.Text = "UNLOCK"
unlock.Font = Enum.Font.GothamBlack
unlock.TextSize = 13
unlock.TextColor3 = Color3.new(1, 1, 1)
unlock.BackgroundColor3 = Color3.fromRGB(104, 72, 158)
unlock.AutoButtonColor = false
unlock.Parent = security
corner(unlock, 13)

local securityStatus = Instance.new("TextLabel")
securityStatus.BackgroundTransparency = 1
securityStatus.Size = UDim2.new(1, -40, 0, 30)
securityStatus.Position = UDim2.fromOffset(20, 207)
securityStatus.Text = "SECURE • WAITING FOR ACCESS"
securityStatus.Font = Enum.Font.GothamBold
securityStatus.TextSize = 10
securityStatus.TextColor3 = Color3.fromRGB(145, 140, 165)
securityStatus.Parent = security

--==================================================
-- MAIN MENU
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(570, 390)
main.Position = UDim2.new(0.5, -285, 0.5, -195)
main.BackgroundColor3 = Color3.fromRGB(11, 10, 16)
main.BackgroundTransparency = 0.04
main.Visible = false
main.Parent = gui
corner(main, 24)
addStroke(main, 0.12)
draggable(main)

local mainScale = Instance.new("UIScale")
mainScale.Scale = 0.86
mainScale.Parent = main

-- top/header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 76)
header.BackgroundTransparency = 1
header.Parent = main

local menuTitle = Instance.new("TextLabel")
menuTitle.BackgroundTransparency = 1
menuTitle.Size = UDim2.new(1, -120, 0, 39)
menuTitle.Position = UDim2.fromOffset(24, 10)
menuTitle.Text = "ABILITY MENU"
menuTitle.Font = Enum.Font.GothamBlack
menuTitle.TextSize = 29
menuTitle.TextXAlignment = Enum.TextXAlignment.Left
menuTitle.TextColor3 = Color3.new(1, 1, 1)
menuTitle.Parent = header

local menuSub = Instance.new("TextLabel")
menuSub.BackgroundTransparency = 1
menuSub.Size = UDim2.new(1, -120, 0, 20)
menuSub.Position = UDim2.fromOffset(26, 48)
menuSub.Text = "JAYVEE  •  POWER SYSTEM"
menuSub.Font = Enum.Font.GothamBold
menuSub.TextSize = 10
menuSub.TextXAlignment = Enum.TextXAlignment.Left
menuSub.TextColor3 = Color3.fromRGB(145, 140, 165)
menuSub.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38, 34)
minimize.Position = UDim2.new(1, -90, 0, 18)
minimize.Text = "—"
minimize.Font = Enum.Font.GothamBlack
minimize.TextSize = 21
minimize.TextColor3 = Color3.fromRGB(220, 218, 230)
minimize.BackgroundColor3 = Color3.fromRGB(25, 23, 34)
minimize.AutoButtonColor = false
minimize.Parent = header
corner(minimize, 11)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(38, 34)
close.Position = UDim2.new(1, -46, 0, 18)
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextSize = 22
close.TextColor3 = Color3.fromRGB(220, 218, 230)
close.BackgroundColor3 = Color3.fromRGB(25, 23, 34)
close.AutoButtonColor = false
close.Parent = header
corner(close, 11)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -36, 1, -145)
content.Position = UDim2.fromOffset(18, 78)
content.BackgroundTransparency = 1
content.Parent = main

--==================================================
-- PAGE HELPERS
--==================================================

local pages = {}

local function newPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

local homePage = newPage("Home")
local powerPage = newPage("Power")
local playerPage = newPage("Player")

local function label(parent, text, pos, size, fontSize)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = fontSize or 12
	l.TextColor3 = Color3.fromRGB(205, 202, 220)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function card(parent, pos, size)
	local c = Instance.new("Frame")
	c.Position = pos
	c.Size = size
	c.BackgroundColor3 = Color3.fromRGB(24, 22, 33)
	c.BackgroundTransparency = 0.06
	c.Parent = parent
	corner(c, 15)
	addStroke(c, 0.7)
	return c
end

--==================================================
-- HOME
--==================================================

local homeCard = card(homePage, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 105))
label(homeCard, "SCRIPT INFO", UDim2.fromOffset(18, 12), UDim2.new(1,-36,0,22), 12)
label(homeCard,
	"Created for your own Roblox experience\nCreator: JAYVEE\nStatus: ONLINE • Ability System Ready",
	UDim2.fromOffset(18, 37), UDim2.new(1,-36,0,62), 11
)

local statusCard = card(homePage, UDim2.fromOffset(0, 118), UDim2.new(1, 0, 0, 105))
label(statusCard, "STATUS", UDim2.fromOffset(18, 12), UDim2.new(1,-36,0,22), 12)
local statusText = label(statusCard,
	"System: READY\nAbility: Ultra Instinct\nRadius: " .. Settings.Radius,
	UDim2.fromOffset(18, 38), UDim2.new(1,-36,0,65), 11
)

local homeHint = card(homePage, UDim2.fromOffset(0, 236), UDim2.new(1, 0, 0, 65))
label(homeHint,
	"Tip: Open POWER to select Goku abilities.\nPLAYER shows your live character information.",
	UDim2.fromOffset(18, 12), UDim2.new(1,-36,1,-24), 10
)

--==================================================
-- POWER
--==================================================

local gokuCard = card(powerPage, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 80))
label(gokuCard, "GOKU", UDim2.fromOffset(18, 10), UDim2.new(1,-36,0,22), 14)
label(gokuCard, "Dragon Ball ability set", UDim2.fromOffset(18, 34), UDim2.new(1,-36,0,18), 10)

local ultra = Instance.new("TextButton")
ultra.Size = UDim2.new(1, 0, 0, 62)
ultra.Position = UDim2.fromOffset(0, 92)
ultra.Text = ""
ultra.BackgroundColor3 = Color3.fromRGB(104, 72, 158)
ultra.AutoButtonColor = false
ultra.Parent = powerPage
corner(ultra, 15)

local ultraTitle = label(ultra, "ULTRA INSTINCT", UDim2.fromOffset(18, 8), UDim2.new(1,-36,0,24), 14)
ultraTitle.TextColor3 = Color3.new(1,1,1)
local ultraDesc = label(ultra, "Auto dodge • camera lock • 5s follow", UDim2.fromOffset(18, 33), UDim2.new(1,-36,0,18), 10)
ultraDesc.TextColor3 = Color3.fromRGB(235,230,245)

local settingsCard = card(powerPage, UDim2.fromOffset(0, 170), UDim2.new(1, 0, 0, 132))
label(settingsCard, "ULTRA INSTINCT SETTINGS", UDim2.fromOffset(18, 9), UDim2.new(1,-36,0,20), 11)

local function makeToggle(parent, text, pos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(245, 39)
	b.Position = pos
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(52, 46, 68)
	b.AutoButtonColor = false
	b.Parent = parent
	corner(b, 11)
	return b
end

local systemToggle = makeToggle(settingsCard, "SYSTEM • ON", UDim2.fromOffset(14, 36))
local dodgeToggle = makeToggle(settingsCard, "AUTO DODGE • ON", UDim2.fromOffset(269, 36))
local cameraToggle = makeToggle(settingsCard, "CAMERA LOCK • ON", UDim2.fromOffset(14, 82))
local followToggle = makeToggle(settingsCard, "5S FOLLOW • ON", UDim2.fromOffset(269, 82))

local function refreshPower()
	systemToggle.Text = Settings.Enabled and "SYSTEM • ON" or "SYSTEM • OFF"
	dodgeToggle.Text = Settings.AutoDodge and "AUTO DODGE • ON" or "AUTO DODGE • OFF"
	cameraToggle.Text = Settings.CameraLock and "CAMERA LOCK • ON" or "CAMERA LOCK • OFF"
	followToggle.Text = Settings.FollowAfterDodge and "5S FOLLOW • ON" or "5S FOLLOW • OFF"

	systemToggle.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	dodgeToggle.BackgroundColor3 = Settings.AutoDodge and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	cameraToggle.BackgroundColor3 = Settings.CameraLock and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	followToggle.BackgroundColor3 = Settings.FollowAfterDodge and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)

	ultra.BackgroundColor3 = Settings.Ability == "Ultra Instinct"
		and Color3.fromRGB(104,72,158)
		or Color3.fromRGB(46,41,58)
end

--==================================================
-- PLAYER PAGE
--==================================================

local playerCard = card(playerPage, UDim2.fromOffset(0,0), UDim2.new(1,0,0,128))
label(playerCard, "PLAYER INFO", UDim2.fromOffset(18,12), UDim2.new(1,-36,0,22), 13)

local playerInfo = label(playerCard, "", UDim2.fromOffset(18,39), UDim2.new(1,-36,0,78), 11)

local radiusCard = card(playerPage, UDim2.fromOffset(0,142), UDim2.new(1,0,0,135))
label(radiusCard, "PLAYER RADIUS", UDim2.fromOffset(18,10), UDim2.new(1,-36,0,22), 12)

local radiusValue = label(radiusCard, "RADIUS  " .. Settings.Radius, UDim2.fromOffset(18,40), UDim2.new(0.45,0,0,35), 15)
radiusValue.TextColor3 = Color3.fromRGB(230,225,240)

local minus = Instance.new("TextButton")
minus.Size = UDim2.fromOffset(92,42)
minus.Position = UDim2.new(1,-205,0,38)
minus.Text = "1 −"
minus.Font = Enum.Font.GothamBlack
minus.TextSize = 14
minus.TextColor3 = Color3.new(1,1,1)
minus.BackgroundColor3 = Color3.fromRGB(47,42,59)
minus.AutoButtonColor = false
minus.Parent = radiusCard
corner(minus, 12)

local plus = Instance.new("TextButton")
plus.Size = UDim2.fromOffset(92,42)
plus.Position = UDim2.new(1,-103,0,38)
plus.Text = "1 +"
plus.Font = Enum.Font.GothamBlack
plus.TextSize = 14
plus.TextColor3 = Color3.new(1,1,1)
plus.BackgroundColor3 = Color3.fromRGB(104,72,158)
plus.AutoButtonColor = false
plus.Parent = radiusCard
corner(plus, 12)

label(radiusCard,
	"Adjust the visible circle around your character.",
	UDim2.fromOffset(18,84), UDim2.new(1,-36,0,20), 9
)

--==================================================
-- BOTTOM NAV
--==================================================

local nav = Instance.new("Frame")
nav.Size = UDim2.new(1,-30,0,65)
nav.Position = UDim2.new(0,15,1,-78)
nav.BackgroundTransparency = 1
nav.Parent = main

local tabButtons = {}

local function makeTab(name, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(165,56)
	b.Position = UDim2.fromOffset(x,0)
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = Color3.fromRGB(215,210,225)
	b.BackgroundColor3 = Color3.fromRGB(15,14,21)
	b.BackgroundTransparency = 0.15
	b.AutoButtonColor = false
	b.Parent = nav
	corner(b, 18)
	tabButtons[name] = b
	return b
end

local homeTab = makeTab("Home", 0)
local powerTab = makeTab("Power", 170)
local playerTab = makeTab("Player", 340)

local currentPage = "Home"

local function showPage(name)
	currentPage = name

	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
	end

	for tabName, b in pairs(tabButtons) do
		if tabName == name then
			b.BackgroundColor3 = Color3.fromRGB(104,72,158)
			b.TextColor3 = Color3.new(1,1,1)
		else
			b.BackgroundColor3 = Color3.fromRGB(15,14,21)
			b.TextColor3 = Color3.fromRGB(190,185,205)
		end
	end

	if name == "Home" then
		statusText.Text = "System: " .. (Settings.Enabled and "READY" or "OFF")
			.. "\nAbility: " .. Settings.Ability
			.. "\nRadius: " .. Settings.Radius
	end
end

homeTab.MouseButton1Click:Connect(function()
	play(clickSound)
	showPage("Home")
end)

powerTab.MouseButton1Click:Connect(function()
	play(clickSound)
	showPage("Power")
end)

playerTab.MouseButton1Click:Connect(function()
	play(clickSound)
	showPage("Player")
end)

--==================================================
-- RADIUS RING
--==================================================

local ringFolder = Instance.new("Folder")
ringFolder.Name = "AbilityRadiusRing"
ringFolder.Parent = workspace

local ringParts = {}
local RING_SEGMENTS = 48

for i = 1, RING_SEGMENTS do
	local p = Instance.new("Part")
	p.Name = "RadiusSegment"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(150, 95, 235)
	p.Transparency = 0.15
	p.Size = Vector3.new(0.18, 0.05, 0.65)
	p.Parent = ringFolder
	ringParts[i] = p
end

local function updateRing()
	if not root or not root.Parent then
		for _, p in ipairs(ringParts) do
			p.Transparency = 1
		end
		return
	end

	for i, p in ipairs(ringParts) do
		local angle = ((i - 1) / RING_SEGMENTS) * math.pi * 2
		local pos = root.Position + Vector3.new(
			math.cos(angle) * Settings.Radius,
			-2.65,
			math.sin(angle) * Settings.Radius
		)

		p.CFrame = CFrame.new(pos)
			* CFrame.Angles(0, -angle, 0)

		p.Transparency = Settings.Enabled and 0.15 or 1
	end
end

--==================================================
-- RADIUS CONTROLS
--==================================================

local function refreshRadius()
	radiusValue.Text = "RADIUS  " .. tostring(Settings.Radius)

	statusText.Text = "System: " .. (Settings.Enabled and "READY" or "OFF")
		.. "\nAbility: " .. Settings.Ability
		.. "\nRadius: " .. Settings.Radius
end

minus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Radius = math.max(
		Settings.MinRadius,
		Settings.Radius - Settings.RadiusStep
	)
	refreshRadius()
end)

plus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Radius = math.min(
		Settings.MaxRadius,
		Settings.Radius + Settings.RadiusStep
	)
	refreshRadius()
end)

--==================================================
-- POWER BUTTONS
--==================================================

ultra.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Ability = "Ultra Instinct"
	refreshPower()
end)

systemToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Enabled = not Settings.Enabled
	refreshPower()
	refreshRadius()
end)

dodgeToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.AutoDodge = not Settings.AutoDodge
	refreshPower()
end)

cameraToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.CameraLock = not Settings.CameraLock
	if not Settings.CameraLock then
		cameraLocked = false
	end
	refreshPower()
end)

followToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowAfterDodge = not Settings.FollowAfterDodge
	refreshPower()
end)

--==================================================
-- PLAYER INFO UPDATE
--==================================================

local function updatePlayerInfo()
	if not humanoid or not root then return end

	local hp = math.floor(humanoid.Health)
	local maxHp = math.floor(humanoid.MaxHealth)

	playerInfo.Text =
		"Name: " .. player.Name
		.. "\nDisplay Name: " .. player.DisplayName
		.. "\nHealth: " .. hp .. " / " .. maxHp
		.. "\nAbility: " .. Settings.Ability
		.. "\nRadius: " .. Settings.Radius
end

--==================================================
-- TARGETING
--==================================================

local function getHum(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function nearestEnemy()
	if not root then return nil end

	local nearest
	local best = Settings.Radius

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local hum = getHum(other.Character)
			local r = getRoot(other.Character)

			if hum and r and hum.Health > 0 then
				local d = (r.Position - root.Position).Magnitude
				if d <= best then
					best = d
					nearest = other.Character
				end
			end
		end
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) then
			local hum = getHum(obj)
			local r = getRoot(obj)

			if hum and r and hum.Health > 0 then
				local d = (r.Position - root.Position).Magnitude
				if d <= best then
					best = d
					nearest = obj
				end
			end
		end
	end

	return nearest
end

--==================================================
-- CAMERA / JOYSTICK
--==================================================

local function releaseCamera()
	cameraLocked = false
end

UIS.InputBegan:Connect(function(input)
	if not cameraLocked then return end

	if input.KeyCode == Enum.KeyCode.W
		or input.KeyCode == Enum.KeyCode.A
		or input.KeyCode == Enum.KeyCode.S
		or input.KeyCode == Enum.KeyCode.D
		or input.KeyCode == Enum.KeyCode.Thumbstick1 then
		releaseCamera()
	end
end)

UIS.InputChanged:Connect(function(input)
	if not cameraLocked then return end

	if input.UserInputType == Enum.UserInputType.Touch then
		if input.Delta.Magnitude > 2 then
			releaseCamera()
		end
	end
end)

--==================================================
-- VISUAL EFFECTS
--==================================================

local function flash()
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1,1)
	f.BackgroundColor3 = Color3.fromRGB(210,190,255)
	f.BackgroundTransparency = 0.84
	f.BorderSizePixel = 0
	f.ZIndex = 100
	f.Parent = gui

	tween(f,0.28,{BackgroundTransparency=1}):Play()
	Debris:AddItem(f,0.35)
end

local function stopEffect()
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(25,25)
	ring.Position = UDim2.new(0.5,-12.5,0.5,-12.5)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 101
	ring.Parent = gui
	corner(ring,50)

	local s = addStroke(ring,0)
	s.Thickness = 3

	tween(ring,0.45,{
		Size=UDim2.fromOffset(230,230),
		Position=UDim2.new(0.5,-115,0.5,-115)
	}):Play()

	tween(s,0.45,{Transparency=1}):Play()
	Debris:AddItem(ring,0.55)
	play(stopSound)
end

--==================================================
-- ULTRA INSTINCT DODGE
--==================================================

local function followForFiveSeconds(target)
	if not Settings.FollowAfterDodge then return end
	if not target then return end

	local targetRoot = getRoot(target)
	local targetHum = getHum(target)

	if not targetRoot or not targetHum then return end

	following = true
	followTarget = target
	followToken += 1
	local token = followToken

	task.spawn(function()
		local start = os.clock()

		while following
			and token == followToken
			and os.clock() - start < Settings.FollowDuration do

			if not root or not root.Parent then break end
			if not targetRoot.Parent or targetHum.Health <= 0 then break end

			local desired = targetRoot.Position - targetRoot.CFrame.LookVector * 3
			local flat = Vector3.new(desired.X, root.Position.Y, desired.Z)

			root.CFrame = root.CFrame:Lerp(
				CFrame.lookAt(
					flat,
					Vector3.new(targetRoot.Position.X, flat.Y, targetRoot.Position.Z)
				),
				0.12
			)

			task.wait()
		end

		if token == followToken then
			following = false
			followTarget = nil
			stopEffect()
		end
	end)
end

local function dodge()
	if dodging then return end
	if not Settings.Enabled or not Settings.AutoDodge then return end
	if not humanoid or humanoid.Health <= 0 or not root then return end

	dodging = true
	followToken += 1
	following = false

	local target = nearestEnemy()
	local targetRoot = target and getRoot(target)

	play(dodgeSound)
	flash()

	if targetRoot then
		cameraLocked = Settings.CameraLock
	end

	local direction

	if targetRoot then
		local away = root.Position - targetRoot.Position
		away = Vector3.new(away.X,0,away.Z)

		if away.Magnitude > 0.1 then
			direction = away.Unit
		end
	end

	if not direction then
		direction = Vector3.new(
			-root.CFrame.LookVector.X,
			0,
			-root.CFrame.LookVector.Z
		).Unit
	end

	local startCF = root.CFrame
	local destination = root.Position + direction * 8
	local endCF = CFrame.lookAt(destination, destination + root.CFrame.LookVector)

	local start = os.clock()

	while os.clock() - start < 0.22 do
		local a = math.clamp((os.clock() - start) / 0.22,0,1)
		a = 1 - (1-a)^3

		if root and root.Parent then
			root.CFrame = startCF:Lerp(endCF,a)
		end

		RunService.RenderStepped:Wait()
	end

	if target then
		followForFiveSeconds(target)
	end

	task.delay(0.12,function()
		dodging = false
	end)
end

--==================================================
-- CAMERA FOLLOW
--==================================================

RunService.RenderStepped:Connect(function()
	updateRing()
	updatePlayerInfo()

	if cameraLocked and followTarget then
		local targetRoot = getRoot(followTarget)
		local targetHum = getHum(followTarget)

		if not targetRoot or not targetHum or targetHum.Health <= 0 then
			releaseCamera()
		else
			local point = targetRoot.Position + Vector3.new(0,2,0)
			local desired = CFrame.lookAt(camera.CFrame.Position,point)
			camera.CFrame = camera.CFrame:Lerp(desired,0.16)
		end
	end
end)

--==================================================
-- DAMAGE DETECTION
--==================================================

local function hookDamage()
	if damageConnection then
		damageConnection:Disconnect()
	end

	if not humanoid then return end

	lastHealth = humanoid.Health

	damageConnection = humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			task.defer(dodge)
		end

		lastHealth = newHealth
	end)
end

--==================================================
-- MENU ANIMATION
--==================================================

local minimized = Instance.new("TextButton")
minimized.Size = UDim2.fromOffset(65,65)
minimized.Position = UDim2.new(0,18,0.5,-32)
minimized.Text = "UI"
minimized.Font = Enum.Font.GothamBlack
minimized.TextSize = 16
minimized.TextColor3 = Color3.new(1,1,1)
minimized.BackgroundColor3 = Color3.fromRGB(104,72,158)
minimized.Visible = false
minimized.Parent = gui
corner(minimized,20)
addStroke(minimized,0.15)
draggable(minimized)

local function openMenu()
	menuOpen = true
	minimized.Visible = false
	main.Visible = true
	mainScale.Scale = 0.82
	tween(mainScale,0.35,{Scale=1},Enum.EasingStyle.Back):Play()
	play(openSound)
end

local function minimizeMenu()
	menuOpen = false
	tween(mainScale,0.2,{Scale=0.82},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()
	task.wait(0.18)
	main.Visible = false
	minimized.Visible = true
	play(clickSound)
end

minimize.MouseButton1Click:Connect(minimizeMenu)
close.MouseButton1Click:Connect(minimizeMenu)
minimized.MouseButton1Click:Connect(openMenu)

--==================================================
-- INITIALIZE
--==================================================

showPage("Home")
refreshPower()
refreshRadius()
hookDamage()

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	refreshCharacter()
	hookDamage()
end)

unlock.MouseButton1Click:Connect(function()
	play(clickSound)

	if passBox.Text == PASSWORD then
		securityStatus.Text = "ACCESS GRANTED • ABILITY MENU READY"
		securityStatus.TextColor3 = Color3.fromRGB(175,255,195)
		play(openSound)

		tween(secScale,0.25,{Scale=0.7},Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
		task.wait(0.2)

		security.Visible = false
		openMenu()
	else
		securityStatus.Text = "ACCESS DENIED • INVALID KEY"
		securityStatus.TextColor3 = Color3.fromRGB(255,120,130)

		local old = security.Position
		tween(security,0.07,{Position=old + UDim2.fromOffset(8,0)},Enum.EasingStyle.Linear):Play()
		task.wait(0.07)
		tween(security,0.07,{Position=old - UDim2.fromOffset(8,0)},Enum.EasingStyle.Linear):Play()
		task.wait(0.07)
		tween(security,0.07,{Position=old},Enum.EasingStyle.Linear):Play()
	end
end)
