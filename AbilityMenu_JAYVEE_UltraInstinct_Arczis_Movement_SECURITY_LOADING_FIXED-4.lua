-- ABILITY MENU • JAYVEE
-- Own-game LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
--
-- Includes:
-- • Security password screen
-- • Home / Power / Player pages
-- • Goku > Ultra Instinct ability (OFF by default, manual ON/OFF toggle)
-- • Chat intro "ULTRA INSTINCT!!!" when turned ON (no outro)
-- • White aura + white body outline (sabay, fade in / fade out)
-- • Player-radius visual circle
-- • Radius 1+ / 1- controls
-- • Auto-dodge / camera / follow controls
-- • Mobile-friendly dragging
-- • UI sounds and animations
--
-- ================================================================
-- QUICK EDIT GUIDE
-- ================================================================
-- Most user-editable values are inside the Settings table below.
--
-- UltraActive = Ultra Instinct ON/OFF (default OFF, ikaw mag-on sa Power tab).
-- FollowDuration = follow time after a dodge (seconds).
-- FollowDistance = distance kept from the target.
-- FollowSpeed = smooth follow response speed.
-- FollowMode = "Behind" or "Side".
-- Radius = large purple detection circle size.
-- ContactTriggerDistance = close/contact dodge distance.
-- DodgeChance = dodge chance from 1 to 100.
-- PerfectDodgeWindow = attack timing window in seconds.
-- WhiteAura / Afterimage = visual effects ON/OFF.
-- UIScale / MenuScale = UI size.
-- IntroAnimation / OpenCloseAnimation = UI animation style.
--
-- IMPORTANT: being inside Radius alone does NOT cause a dodge.
-- An attack, real damage, or configured close-contact condition
-- must be detected first.
-- ================================================================

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
	-- Master switches
	Enabled = true,                 -- Master ON/OFF.
	AutoDodge = true,               -- Automatic dodge detection.
	CameraLock = true,              -- Camera reaction during combat.
	UltraActive = false,            -- Ultra Instinct OFF by default.
	RedLingerTime = 2,              -- Seconds na nananatiling pula ang enemy pagkalabas sa radius.
	RedFadeIn = 0.2,                -- Fade in ng red mark.
	RedFadeOut = 0.35,              -- Fade out ng red mark.

	-- Follow system
	FollowAfterDodge = true,        -- Follow target after dodge.
	FollowDuration = 5,             -- Seconds of follow time.
	FollowDistance = 3,             -- Distance from target.
	FollowSpeed = 0.14,             -- Follow smoothing/response.
	FollowMode = "Behind",          -- "Behind" or "Side".
	StopEffect = true,              -- Stop follow/effects when finished.

	-- UI appearance
	MenuScale = 1.0,                -- Main menu size multiplier.
	UIScale = 1.0,                  -- Global UI scale.
	IntroAnimation = "Back",        -- Intro/entrance style.
	OpenCloseAnimation = "Smooth",  -- Open/close style.

	-- Detection radius
	Radius = 12,                    -- Purple detection radius.
	MinRadius = 3,                  -- Minimum radius.
	MaxRadius = 50,                 -- Maximum radius.
	RadiusStep = 1,                 -- Amount changed by +/- buttons.
	ContactTriggerDistance = 3.2,   -- Close/contact trigger distance.

	-- Ability / dodge
	Ability = "Ultra Instinct",     -- Current ability name.
	DodgeChance = 100,              -- Chance from 1 to 100.
	DodgeAnimation = "Side Burst",  -- Dodge animation preset.
	PerfectDodgeWindow = 0.30,      -- Attack timing window.
	DodgeActivity = "High",         -- Dodge speed: "Low" / "Normal" / "High" / "Max" (does NOT change triggers).

	-- Visual effects
	WhiteAura = true,               -- White aura ON/OFF.
	Afterimage = true,              -- Afterimage ON/OFF.
	DodgeCount = 0,
	UIVolume = 0.45,
	UITransparency = 0.04,
	AnimationSpeed = 0.45,
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
local cameraTarget = nil
local cameraManualLock = false
local menuOpen = false
local refreshBodyAura -- forward declaration (defined further down, used by button handlers)

local function refreshCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	lastHealth = humanoid.Health
end

-- Do not block UI creation waiting for the character.
-- The UI must appear even while the character is still loading.
if player.Character then
	task.spawn(function()
		local ok = pcall(refreshCharacter)
		if not ok then
			character, humanoid, root = nil, nil, nil
		end
	end)
end

local function makeSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 0.45
	s.Parent = SoundService
	return s
end

local clickSound = makeSound(9118828568, 0.4)
local openSound = makeSound(9118823107, 0.45)
local dodgeSoundIds = {
	"rbxassetid://87566211283329",
	"rbxassetid://81857580097150",
	"rbxassetid://129561737395908",
	"rbxassetid://122312400582724",
	"rbxassetid://136080815136211"
}

local dodgeSounds = {}
for _, soundId in ipairs(dodgeSoundIds) do
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 0.65
	s.Parent = SoundService
	table.insert(dodgeSounds, s)
end

local stopSound = makeSound(9118828568, 0.3)

local function playRandomDodgeSound()
	if #dodgeSounds == 0 then return end
	local sound = dodgeSounds[math.random(1, #dodgeSounds)]
	pcall(function()
		sound:Play()
	end)
end

local uiSoundsEnabled = true
local function play(sound)
	if not uiSoundsEnabled then return end
	pcall(function()
		sound.Volume = Settings.UIVolume
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
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = player:WaitForChild("PlayerGui")

local security
local main
local minimized
local secScale

--==================================================
-- SECURITY
--==================================================

security = Instance.new("Frame")
security.Size = UDim2.fromOffset(410, 275)
security.Position = UDim2.new(0.5, -205, 0.5, -138)
security.BackgroundColor3 = Color3.fromRGB(12, 11, 17)
security.BackgroundTransparency = 0.04
security.Parent = gui
security.Visible = false
security.ZIndex = 100
corner(security, 22)
addStroke(security, 0.1)
draggable(security)

secScale = Instance.new("UIScale")
secScale.Scale = 0.84
secScale.Parent = security

local secTitle = Instance.new("TextLabel")
secTitle.BackgroundTransparency = 1
secTitle.Size = UDim2.new(1, -30, 0, 42)
secTitle.Position = UDim2.fromOffset(15, 13)
secTitle.Text = "SECURITY"
secTitle.Font = Enum.Font.GothamBlack
secTitle.TextSize = 28
secTitle.TextColor3 = Color3.new(1, 1, 1)
secTitle.Parent = security

local secSub = Instance.new("TextLabel")
secSub.BackgroundTransparency = 1
secSub.Size = UDim2.new(1, -30, 0, 24)
secSub.Position = UDim2.fromOffset(15, 53)
secSub.Text = "ACCESS KEY REQUIRED  •  JAYVEE"
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

-- =========================
-- ARCZIS MOVEMENT ADAPTER
-- =========================
-- Adapted from the uploaded Arczis Movement System model.
-- The model exposes this explicit AnimationId:
-- 117414822036545

local ArczisMovement = {}
ArczisMovement.Enabled = true
ArczisMovement.WalkSpeed = 10
ArczisMovement.RunSpeed = 18
ArczisMovement.RunThreshold = 14
ArczisMovement.FadeTime = 0.16

-- The uploaded RBXM contains one explicit AnimationId. Keep the other
-- slots configurable so additional state IDs can be dropped in later
-- without changing the movement controller.
ArczisMovement.AnimationIds = {
	Walk = "rbxassetid://117414822036545",
	Run = "rbxassetid://117414822036545",
	Idle = nil,
	Jump = nil,
	Fall = nil,
	Climb = nil,
	Crouch = nil,
}

local arczisCharacter
local arczisHumanoid
local arczisAnimator
local arczisTracks = {}
local arczisConnections = {}
local arczisAnimateScript

local function arczisDisconnect()
	for _, c in ipairs(arczisConnections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(arczisConnections)
end

local function arczisStopAll(exceptName)
	for name, track in pairs(arczisTracks) do
		if name ~= exceptName and track and track.IsPlaying then
			pcall(function() track:Stop(ArczisMovement.FadeTime) end)
		end
	end
end

-- ================================================================
-- ARCZIS MOVEMENT ADAPTER
-- Movement/animation state integration from the RBXM system.
-- ================================================================
local function arczisLoad(name)
	if not arczisAnimator then return nil end
	local id = ArczisMovement.AnimationIds[name]
	if not id or id == "" then return nil end
	if arczisTracks[name] then return arczisTracks[name] end

	local animation = Instance.new("Animation")
	animation.Name = "Arczis_" .. name
	animation.AnimationId = id

	local ok, track = pcall(function()
		return arczisAnimator:LoadAnimation(animation)
	end)
	if not ok or not track then
		animation:Destroy()
		return nil
	end

	if name == "Idle" then
		track.Priority = Enum.AnimationPriority.Idle
	elseif name == "Walk" or name == "Run" then
		track.Priority = Enum.AnimationPriority.Movement
	else
		track.Priority = Enum.AnimationPriority.Action
	end
	track.Looped = true
	arczisTracks[name] = track
	return track
end

local function arczisPlay(name)
	local track = arczisLoad(name)
	if not track then return false end
	arczisStopAll(name)
	if not track.IsPlaying then
		pcall(function() track:Play(ArczisMovement.FadeTime, 1, 1) end)
	end
	return true
end

local function arczisState()
	if not ArczisMovement.Enabled or not arczisHumanoid then return end
	local state = arczisHumanoid:GetState()

	if state == Enum.HumanoidStateType.Jumping then
		if not arczisPlay("Jump") then
			arczisStopAll()
		end
		return
	elseif state == Enum.HumanoidStateType.Freefall then
		if not arczisPlay("Fall") then
			arczisStopAll()
		end
		return
	elseif state == Enum.HumanoidStateType.Climbing then
		if not arczisPlay("Climb") then
			arczisStopAll()
		end
		return
	end

	local speed = arczisHumanoid.MoveDirection.Magnitude * arczisHumanoid.WalkSpeed
	if speed > 0.05 then
		if speed >= ArczisMovement.RunThreshold then
			arczisPlay("Run")
		else
			arczisPlay("Walk")
		end
	else
		if not arczisPlay("Idle") then
			arczisStopAll()
		end
	end
end

local function arczisSetup(character)
	arczisDisconnect()
	for _, track in pairs(arczisTracks) do
		pcall(function() track:Stop(0) end)
		pcall(function() track:Destroy() end)
	end
	table.clear(arczisTracks)

	arczisCharacter = character
	arczisHumanoid = character:WaitForChild("Humanoid", 8)
	if not arczisHumanoid then return end

	arczisAnimator = arczisHumanoid:FindFirstChildOfClass("Animator")
	if not arczisAnimator then
		arczisAnimator = Instance.new("Animator")
		arczisAnimator.Parent = arczisHumanoid
	end

	-- Disable Roblox's default Animate controller only when this adapter
	-- has a usable custom movement animation. This prevents double playback.
	arczisAnimateScript = character:FindFirstChild("Animate")
	if arczisAnimateScript and arczisAnimateScript:IsA("LocalScript") then
		local hasCustom = true
		for _, stateName in ipairs({"Idle","Walk","Run","Jump","Fall"}) do
			local id = ArczisMovement.AnimationIds[stateName]
			if not id or id == "" then hasCustom = false break end
		end
		if hasCustom then
			arczisAnimateScript.Enabled = false
		end
	end

	arczisHumanoid.WalkSpeed = math.max(ArczisMovement.WalkSpeed, arczisHumanoid.WalkSpeed)
	arczisConnections[#arczisConnections+1] = arczisHumanoid.Running:Connect(function()
		arczisState()
	end)
	arczisConnections[#arczisConnections+1] = arczisHumanoid.StateChanged:Connect(function()
		arczisState()
	end)
	arczisConnections[#arczisConnections+1] = RunService.RenderStepped:Connect(function()
		if arczisHumanoid and arczisHumanoid.Parent then
			arczisState()
		end
	end)

	task.defer(arczisState)
end

if character then
	task.spawn(function()
		arczisSetup(character)
	end)
end

player.CharacterAdded:Connect(function(char)
	task.wait(0.15)
	arczisSetup(char)
end)

-- =========================
-- END ARCZIS MOVEMENT ADAPTER
-- =========================


main = Instance.new("Frame")
main.Size = UDim2.fromOffset(570, 390)
main.Position = UDim2.new(0.5, -285, 0.5, -195)
main.BackgroundColor3 = Color3.fromRGB(11, 10, 16)
main.BackgroundTransparency = 0.04
main.Visible = false
main.Parent = gui
main.Visible = false
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

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -36, 1, -145)
content.Position = UDim2.fromOffset(18, 78)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageTransparency = 0.35
content.ScrollBarImageColor3 = Color3.fromRGB(118, 82, 175)
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.ElasticBehavior = Enum.ElasticBehavior.Always
content.Parent = main

--==================================================
-- PAGE HELPERS
--==================================================

local pages = {}

-- ================================================================
-- UI BUILDERS
-- Page/card/label/toggle/tab helper functions.
-- ================================================================
local function newPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.new(1, -8, 0, 1100)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

local homePage = newPage("Home")
homePage.Size = UDim2.new(1, -8, 0, 560)
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
	"System: " .. (Settings.Enabled and "READY" or "OFF")
	.. "\nAbility: " .. Settings.Ability
	.. "\nRadius: " .. Settings.Radius,
	UDim2.fromOffset(18, 38), UDim2.new(1,-36,0,65), 11
)

local homeHint = card(homePage, UDim2.fromOffset(0, 236), UDim2.new(1, 0, 0, 65))
label(homeHint,
	"Tip: Open POWER to select Goku abilities.\nPLAYER shows your live character information.",
	UDim2.fromOffset(18, 12), UDim2.new(1,-36,1,-24), 10
)


-- CONFIGURATION
--==================================================

local configCard = card(homePage, UDim2.fromOffset(0, 314), UDim2.new(1, 0, 0, 225))
label(configCard, "CONFIGURATION", UDim2.fromOffset(18, 10), UDim2.new(1,-36,0,22), 12)
label(configCard, "Player radius and detection settings", UDim2.fromOffset(18, 32), UDim2.new(1,-36,0,18), 9)

local configRadiusText = label(configCard, "RADIUS  " .. Settings.Radius, UDim2.fromOffset(18, 64), UDim2.new(0,180,0,30), 13)
local configMinus = Instance.new("TextButton")
configMinus.Size = UDim2.fromOffset(82,34)
configMinus.Position = UDim2.new(1,-174,0,62)
configMinus.Text = "1 −"
configMinus.Font = Enum.Font.GothamBlack
configMinus.TextSize = 12
configMinus.TextColor3 = Color3.new(1,1,1)
configMinus.BackgroundColor3 = Color3.fromRGB(47,42,59)
configMinus.AutoButtonColor = false
configMinus.Parent = configCard
corner(configMinus,10)
local configPlus = Instance.new("TextButton")
configPlus.Size = UDim2.fromOffset(82,34)
configPlus.Position = UDim2.new(1,-84,0,62)
configPlus.Text = "1 +"
configPlus.Font = Enum.Font.GothamBlack
configPlus.TextSize = 12
configPlus.TextColor3 = Color3.new(1,1,1)
configPlus.BackgroundColor3 = Color3.fromRGB(104,72,158)
configPlus.AutoButtonColor = false
configPlus.Parent = configCard
corner(configPlus,10)

local radiusToggle = Instance.new("TextButton")
radiusToggle.Size = UDim2.new(1,-36,0,34)
radiusToggle.Position = UDim2.fromOffset(18,106)
radiusToggle.Text = "RADIUS CIRCLE • ON"
radiusToggle.Font = Enum.Font.GothamBold
radiusToggle.TextSize = 10
radiusToggle.TextColor3 = Color3.new(1,1,1)
radiusToggle.BackgroundColor3 = Color3.fromRGB(65,55,88)
radiusToggle.AutoButtonColor = false
radiusToggle.Parent = configCard
corner(radiusToggle,10)

local targetInfo = label(configCard, "Detection: enemies inside radius only\nRange: 3–50 • Step: 1", UDim2.fromOffset(18, 148), UDim2.new(1,-36,0,48), 9)
--==================================================
-- POWER
--==================================================

local gokuCard = card(powerPage, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 520))
label(gokuCard, "GOKU", UDim2.fromOffset(18, 10), UDim2.new(1,-36,0,22), 14)
label(gokuCard, "Dragon Ball ability set", UDim2.fromOffset(18, 34), UDim2.new(1,-36,0,18), 10)

local ultra = Instance.new("TextButton")
ultra.Size = UDim2.new(1, -28, 0, 410)
ultra.Position = UDim2.fromOffset(14, 72)
ultra.Text = ""
ultra.BackgroundColor3 = Color3.fromRGB(104, 72, 158)
ultra.AutoButtonColor = false
ultra.Parent = gokuCard
corner(ultra, 15)

local ultraTitle = label(ultra, "ULTRA INSTINCT", UDim2.fromOffset(18, 9), UDim2.new(1,-36,0,24), 14)
ultraTitle.TextColor3 = Color3.new(1,1,1)
local ultraDesc = label(ultra, "Auto dodge • sense • camera lock • aura", UDim2.fromOffset(18, 36), UDim2.new(1,-36,0,20), 10)
ultraDesc.TextColor3 = Color3.fromRGB(235,230,245)

-- ULTRA INSTINCT ON/OFF toggle (OFF by default)
local ultraToggle = Instance.new("TextButton")
ultraToggle.Size = UDim2.fromOffset(130, 26)
ultraToggle.Position = UDim2.new(1, -148, 0, 10)
ultraToggle.Text = "ULTRA • OFF"
ultraToggle.Font = Enum.Font.GothamBlack
ultraToggle.TextSize = 10
ultraToggle.TextColor3 = Color3.new(1,1,1)
ultraToggle.BackgroundColor3 = Color3.fromRGB(55,38,43)
ultraToggle.AutoButtonColor = false
ultraToggle.Parent = ultra
corner(ultraToggle, 9)

local followCard = card(powerPage, UDim2.fromOffset(0, 538), UDim2.new(1, 0, 0, 270))
label(followCard, "FOLLOW SYSTEM", UDim2.fromOffset(18, 10), UDim2.new(1,-36,0,20), 12)
label(followCard, "Edit what happens after a successful dodge.", UDim2.fromOffset(18, 32), UDim2.new(1,-36,0,18), 9)

local followCardToggle = Instance.new("TextButton")
followCardToggle.Size = UDim2.fromOffset(120,26)
followCardToggle.Position = UDim2.new(1,-138,0,8)
followCardToggle.Text = "FOLLOW • ON"
followCardToggle.Font = Enum.Font.GothamBlack
followCardToggle.TextSize = 10
followCardToggle.TextColor3 = Color3.new(1,1,1)
followCardToggle.BackgroundColor3 = Color3.fromRGB(65,55,88)
followCardToggle.AutoButtonColor = false
followCardToggle.Parent = followCard
corner(followCardToggle,9)

local followDurationText = label(followCard, "DURATION  " .. Settings.FollowDuration .. "s", UDim2.fromOffset(18, 60), UDim2.new(0,170,0,30), 11)
local followDurationMinus = Instance.new("TextButton")
followDurationMinus.Size = UDim2.fromOffset(70, 32)
followDurationMinus.Position = UDim2.new(1,-150,0,58)
followDurationMinus.Text = "−"
followDurationMinus.Font = Enum.Font.GothamBlack
followDurationMinus.TextSize = 16
followDurationMinus.TextColor3 = Color3.new(1,1,1)
followDurationMinus.BackgroundColor3 = Color3.fromRGB(47,42,59)
followDurationMinus.AutoButtonColor = false
followDurationMinus.Parent = followCard
corner(followDurationMinus, 10)

local followDurationPlus = Instance.new("TextButton")
followDurationPlus.Size = UDim2.fromOffset(70, 32)
followDurationPlus.Position = UDim2.new(1,-74,0,58)
followDurationPlus.Text = "+"
followDurationPlus.Font = Enum.Font.GothamBlack
followDurationPlus.TextSize = 16
followDurationPlus.TextColor3 = Color3.new(1,1,1)
followDurationPlus.BackgroundColor3 = Color3.fromRGB(104,72,158)
followDurationPlus.AutoButtonColor = false
followDurationPlus.Parent = followCard
corner(followDurationPlus, 10)

local followDistanceText = label(followCard, "DISTANCE  " .. Settings.FollowDistance, UDim2.fromOffset(18, 102), UDim2.new(0,170,0,30), 11)
local followDistanceMinus = Instance.new("TextButton")
followDistanceMinus.Size = UDim2.fromOffset(70, 32)
followDistanceMinus.Position = UDim2.new(1,-150,0,100)
followDistanceMinus.Text = "−"
followDistanceMinus.Font = Enum.Font.GothamBlack
followDistanceMinus.TextSize = 16
followDistanceMinus.TextColor3 = Color3.new(1,1,1)
followDistanceMinus.BackgroundColor3 = Color3.fromRGB(47,42,59)
followDistanceMinus.AutoButtonColor = false
followDistanceMinus.Parent = followCard
corner(followDistanceMinus, 10)

local followDistancePlus = Instance.new("TextButton")
followDistancePlus.Size = UDim2.fromOffset(70, 32)
followDistancePlus.Position = UDim2.new(1,-74,0,100)
followDistancePlus.Text = "+"
followDistancePlus.Font = Enum.Font.GothamBlack
followDistancePlus.TextSize = 16
followDistancePlus.TextColor3 = Color3.new(1,1,1)
followDistancePlus.BackgroundColor3 = Color3.fromRGB(104,72,158)
followDistancePlus.AutoButtonColor = false
followDistancePlus.Parent = followCard
corner(followDistancePlus, 10)

local followSpeedText = label(followCard, "FOLLOW SPEED  " .. math.floor(Settings.FollowSpeed*100), UDim2.fromOffset(18, 144), UDim2.new(0,200,0,30), 11)
local followSpeedMinus = Instance.new("TextButton")
followSpeedMinus.Size = UDim2.fromOffset(70, 32)
followSpeedMinus.Position = UDim2.new(1,-150,0,142)
followSpeedMinus.Text = "−"
followSpeedMinus.Font = Enum.Font.GothamBlack
followSpeedMinus.TextSize = 16
followSpeedMinus.TextColor3 = Color3.new(1,1,1)
followSpeedMinus.BackgroundColor3 = Color3.fromRGB(47,42,59)
followSpeedMinus.AutoButtonColor = false
followSpeedMinus.Parent = followCard
corner(followSpeedMinus, 10)

local followSpeedPlus = Instance.new("TextButton")
followSpeedPlus.Size = UDim2.fromOffset(70, 32)
followSpeedPlus.Position = UDim2.new(1,-74,0,142)
followSpeedPlus.Text = "+"
followSpeedPlus.Font = Enum.Font.GothamBlack
followSpeedPlus.TextSize = 16
followSpeedPlus.TextColor3 = Color3.new(1,1,1)
followSpeedPlus.BackgroundColor3 = Color3.fromRGB(104,72,158)
followSpeedPlus.AutoButtonColor = false
followSpeedPlus.Parent = followCard
corner(followSpeedPlus, 10)

local followMode = Instance.new("TextButton")
followMode.Size = UDim2.new(1,-36,0,34)
followMode.Position = UDim2.fromOffset(18,184)
followMode.Text = "MODE  •  " .. Settings.FollowMode
followMode.Font = Enum.Font.GothamBold
followMode.TextSize = 10
followMode.TextColor3 = Color3.new(1,1,1)
followMode.BackgroundColor3 = Color3.fromRGB(65,55,88)
followMode.AutoButtonColor = false
followMode.Parent = followCard
corner(followMode, 10)

local stopToggle = Instance.new("TextButton")
stopToggle.Size = UDim2.new(1,-36,0,34)
stopToggle.Position = UDim2.fromOffset(18,224)
stopToggle.Text = "STOP EFFECT  •  ON"
stopToggle.Font = Enum.Font.GothamBold
stopToggle.TextSize = 10
stopToggle.TextColor3 = Color3.new(1,1,1)
stopToggle.BackgroundColor3 = Color3.fromRGB(65,55,88)
stopToggle.AutoButtonColor = false
stopToggle.Parent = followCard
corner(stopToggle, 10)

local settingsCard = card(powerPage, UDim2.fromOffset(0, 820), UDim2.new(1, 0, 0, 132))
label(settingsCard, "ABILITY SETTINGS", UDim2.fromOffset(18, 9), UDim2.new(1,-36,0,20), 11)

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

-- ================================================================
-- UI REFRESH FUNCTIONS
-- Updates visible settings after the user changes them.
-- ================================================================
local function refreshPower()
	systemToggle.Text = Settings.Enabled and "SYSTEM • ON" or "SYSTEM • OFF"
	dodgeToggle.Text = Settings.AutoDodge and "AUTO DODGE • ON" or "AUTO DODGE • OFF"
	cameraToggle.Text = Settings.CameraLock and "CAMERA LOCK • ON" or "CAMERA LOCK • OFF"
	followToggle.Text = Settings.FollowAfterDodge and "FOLLOW • ON" or "FOLLOW • OFF"

	systemToggle.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	dodgeToggle.BackgroundColor3 = Settings.AutoDodge and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	cameraToggle.BackgroundColor3 = Settings.CameraLock and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	followToggle.BackgroundColor3 = Settings.FollowAfterDodge and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
	followCardToggle.Text = Settings.FollowAfterDodge and "FOLLOW • ON" or "FOLLOW • OFF"
	followCardToggle.BackgroundColor3 = Settings.FollowAfterDodge and Color3.fromRGB(104,72,158) or Color3.fromRGB(55,38,43)

	ultra.BackgroundColor3 = Settings.Ability == "Ultra Instinct"
		and Color3.fromRGB(104,72,158)
		or Color3.fromRGB(46,41,58)

	ultraToggle.Text = Settings.UltraActive and "ULTRA • ON" or "ULTRA • OFF"
	ultraToggle.BackgroundColor3 = Settings.UltraActive and Color3.fromRGB(235,235,245) or Color3.fromRGB(55,38,43)
	ultraToggle.TextColor3 = Settings.UltraActive and Color3.fromRGB(20,18,30) or Color3.new(1,1,1)

	followDurationText.Text = "DURATION  " .. Settings.FollowDuration .. "s"
	followDistanceText.Text = "DISTANCE  " .. Settings.FollowDistance
	followSpeedText.Text = "FOLLOW SPEED  " .. math.floor(Settings.FollowSpeed*100)
	followMode.Text = "MODE  •  " .. Settings.FollowMode
	stopToggle.Text = Settings.StopEffect and "STOP EFFECT  •  ON" or "STOP EFFECT  •  OFF"
	stopToggle.BackgroundColor3 = Settings.StopEffect and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
end

local function refreshFollowConfig()
    followDurationText.Text = "DURATION  " .. tostring(Settings.FollowDuration) .. "s"
    followDistanceText.Text = "DISTANCE  " .. tostring(Settings.FollowDistance)
    followSpeedText.Text = "FOLLOW SPEED  " .. math.floor(Settings.FollowSpeed * 100)
    followMode.Text = "MODE  •  " .. Settings.FollowMode
    stopToggle.Text = Settings.StopEffect and "STOP EFFECT  •  ON" or "STOP EFFECT  •  OFF"
    stopToggle.BackgroundColor3 = Settings.StopEffect and Color3.fromRGB(65,55,88) or Color3.fromRGB(55,38,43)
end

--==================================================
-- ULTRA INSTINCT CONFIGURATION
--==================================================

local ultraConfig = card(ultra, UDim2.fromOffset(12, 62), UDim2.new(1,-24,0,330))
label(ultraConfig, "ULTRA INSTINCT", UDim2.fromOffset(18,10), UDim2.new(1,-36,0,22), 13)
label(ultraConfig, "---", UDim2.fromOffset(18,32), UDim2.new(1,-36,0,16), 9)

local dodgeChanceButton = Instance.new("TextButton")
dodgeChanceButton.Size = UDim2.new(1,-36,0,36)
dodgeChanceButton.Position = UDim2.fromOffset(18,56)
dodgeChanceButton.Text = "DODGE CHANCE • 100%"
dodgeChanceButton.Font = Enum.Font.GothamBold
dodgeChanceButton.TextSize = 10
dodgeChanceButton.TextColor3 = Color3.new(1,1,1)
dodgeChanceButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
dodgeChanceButton.AutoButtonColor = false
dodgeChanceButton.Parent = ultraConfig
corner(dodgeChanceButton,10)

local dodgeAnimButton = Instance.new("TextButton")
dodgeAnimButton.Size = UDim2.new(1,-36,0,36)
dodgeAnimButton.Position = UDim2.fromOffset(18,100)
dodgeAnimButton.Text = "DODGE ANIMATION • SIDE BURST"
dodgeAnimButton.Font = Enum.Font.GothamBold
dodgeAnimButton.TextSize = 10
dodgeAnimButton.TextColor3 = Color3.new(1,1,1)
dodgeAnimButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
dodgeAnimButton.AutoButtonColor = false
dodgeAnimButton.Parent = ultraConfig
corner(dodgeAnimButton,10)

local perfectButton = Instance.new("TextButton")
perfectButton.Size = UDim2.new(1,-36,0,36)
perfectButton.Position = UDim2.fromOffset(18,144)
perfectButton.Text = "PERFECT DODGE • 0.30s"
perfectButton.Font = Enum.Font.GothamBold
perfectButton.TextSize = 10
perfectButton.TextColor3 = Color3.new(1,1,1)
perfectButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
perfectButton.AutoButtonColor = false
perfectButton.Parent = ultraConfig
corner(perfectButton,10)

local auraButton = Instance.new("TextButton")
auraButton.Size = UDim2.new(0.48,-10,0,36)
auraButton.Position = UDim2.fromOffset(18,188)
auraButton.Text = "WHITE AURA • ON"
auraButton.Font = Enum.Font.GothamBold
auraButton.TextSize = 10
auraButton.TextColor3 = Color3.new(1,1,1)
auraButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
auraButton.AutoButtonColor = false
auraButton.Parent = ultraConfig
corner(auraButton,10)

local afterButton = Instance.new("TextButton")
afterButton.Size = UDim2.new(0.48,-10,0,36)
afterButton.Position = UDim2.new(0.52,0,0,188)
afterButton.Text = "WHITE AFTERIMAGE • ON"
afterButton.Font = Enum.Font.GothamBold
afterButton.TextSize = 10
afterButton.TextColor3 = Color3.new(1,1,1)
afterButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
afterButton.AutoButtonColor = false
afterButton.Parent = ultraConfig
corner(afterButton,10)

local dodgeCountText = label(ultraConfig, "DODGE STREAK  •  0x", UDim2.fromOffset(18,240), UDim2.new(1,-36,0,30), 12)
local resetDodge = Instance.new("TextButton")
resetDodge.Size = UDim2.fromOffset(110,32)
resetDodge.Position = UDim2.new(1,-128,0,236)
resetDodge.Text = "RESET"
resetDodge.Font = Enum.Font.GothamBlack
resetDodge.TextSize = 10
resetDodge.TextColor3 = Color3.new(1,1,1)
resetDodge.BackgroundColor3 = Color3.fromRGB(47,42,59)
resetDodge.AutoButtonColor = false
resetDodge.Parent = ultraConfig
corner(resetDodge,10)

local activityButton = Instance.new("TextButton")
activityButton.Size = UDim2.new(1,-36,0,36)
activityButton.Position = UDim2.fromOffset(18,280)
activityButton.Text = "DODGE ACTIVITY • HIGH"
activityButton.Font = Enum.Font.GothamBold
activityButton.TextSize = 10
activityButton.TextColor3 = Color3.new(1,1,1)
activityButton.BackgroundColor3 = Color3.fromRGB(65,55,88)
activityButton.AutoButtonColor = false
activityButton.Parent = ultraConfig
corner(activityButton,10)

local function refreshUltraConfig()
	dodgeChanceButton.Text = "DODGE CHANCE • " .. Settings.DodgeChance .. "%"
	dodgeAnimButton.Text = "DODGE ANIMATION • " .. string.upper(Settings.DodgeAnimation)
	perfectButton.Text = string.format("PERFECT DODGE • %.2fs", Settings.PerfectDodgeWindow)
	auraButton.Text = Settings.WhiteAura and "WHITE AURA • ON" or "WHITE AURA • OFF"
	afterButton.Text = Settings.Afterimage and "WHITE AFTERIMAGE • ON" or "WHITE AFTERIMAGE • OFF"
	dodgeCountText.Text = "DODGE STREAK  •  " .. Settings.DodgeCount .. "x"
	activityButton.Text = "DODGE ACTIVITY • " .. string.upper(Settings.DodgeActivity)
end

dodgeChanceButton.MouseButton1Click:Connect(function()
	Settings.DodgeChance = Settings.DodgeChance >= 100 and 10 or Settings.DodgeChance + 10
	refreshUltraConfig()
end)
dodgeAnimButton.MouseButton1Click:Connect(function()
	local modes={"Side Burst","Backstep","Blink"}
	local i=table.find(modes,Settings.DodgeAnimation) or 1
	Settings.DodgeAnimation=modes[(i%#modes)+1]
	refreshUltraConfig()
end)
perfectButton.MouseButton1Click:Connect(function()
	local vals={0.15,0.25,0.30,0.40,0.50}
	local i=table.find(vals,Settings.PerfectDodgeWindow) or 3
	Settings.PerfectDodgeWindow=vals[(i%#vals)+1]
	refreshUltraConfig()
end)
auraButton.MouseButton1Click:Connect(function()
	Settings.WhiteAura = not Settings.WhiteAura
	refreshUltraConfig()
	refreshBodyAura()
end)
afterButton.MouseButton1Click:Connect(function()
	Settings.Afterimage = not Settings.Afterimage
	refreshUltraConfig()
end)
resetDodge.MouseButton1Click:Connect(function()
	Settings.DodgeCount = 0
	refreshUltraConfig()
end)
activityButton.MouseButton1Click:Connect(function()
	local modes = {"Low","Normal","High","Max"}
	local i = table.find(modes, Settings.DodgeActivity) or 3
	Settings.DodgeActivity = modes[(i % #modes) + 1]
	refreshUltraConfig()
end)

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
local radiusCircleEnabled = true
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

-- ================================================================
-- RADIUS VISUAL
-- Updates the purple detection circle around the player.
-- ================================================================
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

		p.Transparency = (Settings.Enabled and radiusCircleEnabled) and 0.15 or 1
	end
end

--==================================================
-- MENU / FOLLOW CONFIGURATION
--==================================================

local function refreshMenuSize()
	mainScale.Scale = math.clamp(Settings.MenuScale*Settings.UIScale,0.65,1.35)
	main.BackgroundTransparency = Settings.UITransparency
	clickSound.Volume = Settings.UIVolume
	openSound.Volume = Settings.UIVolume
end

followDurationMinus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowDuration = math.max(1, Settings.FollowDuration - 1)
	refreshFollowConfig()
end)

followDurationPlus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowDuration = math.min(15, Settings.FollowDuration + 1)
	refreshFollowConfig()
end)

followDistanceMinus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowDistance = math.max(1, Settings.FollowDistance - 1)
	refreshFollowConfig()
end)

followDistancePlus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowDistance = math.min(10, Settings.FollowDistance + 1)
	refreshFollowConfig()
end)

followSpeedMinus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowSpeed = math.max(0.06, math.floor((Settings.FollowSpeed - 0.02) * 100 + 0.5) / 100)
	refreshFollowConfig()
end)

followSpeedPlus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowSpeed = math.min(0.30, math.floor((Settings.FollowSpeed + 0.02) * 100 + 0.5) / 100)
	refreshFollowConfig()
end)

followMode.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowMode = Settings.FollowMode == "Behind" and "Side" or "Behind"
	refreshFollowConfig()
end)

stopToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.StopEffect = not Settings.StopEffect
	refreshFollowConfig()
end)

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

configMinus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Radius = math.max(Settings.MinRadius, Settings.Radius - Settings.RadiusStep)
	refreshRadius()
	configRadiusText.Text = "RADIUS  " .. Settings.Radius
end)

configPlus.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Radius = math.min(Settings.MaxRadius, Settings.Radius + Settings.RadiusStep)
	refreshRadius()
	configRadiusText.Text = "RADIUS  " .. Settings.Radius
end)

radiusToggle.MouseButton1Click:Connect(function()
	radiusCircleEnabled = not radiusCircleEnabled
	radiusToggle.Text = radiusCircleEnabled and "RADIUS CIRCLE • ON" or "RADIUS CIRCLE • OFF"
end)

--==================================================
-- POWER BUTTONS
--==================================================

ultra.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Ability = "Ultra Instinct"
	refreshPower()
	refreshBodyAura()
end)

systemToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.Enabled = not Settings.Enabled
	refreshPower()
	refreshRadius()
	refreshBodyAura()
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

followCardToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	Settings.FollowAfterDodge = not Settings.FollowAfterDodge
	if not Settings.FollowAfterDodge then following = false; followToken += 1 end
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

-- Tracks ALL humanoid models in workspace (players + bots/NPCs, kahit nasa loob ng folder).
local targetModels = {}
local function trackHumanoid(h)
	if h:IsA("Humanoid") then
		local m = h.Parent
		if m and m:IsA("Model") then targetModels[m] = true end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do trackHumanoid(d) end
workspace.DescendantAdded:Connect(function(d) task.defer(trackHumanoid, d) end)

local function eachTarget(fn)
	for m in pairs(targetModels) do
		if not m.Parent or not m:IsDescendantOf(workspace) then
			targetModels[m] = nil
		elseif m ~= character then
			fn(m)
		end
	end
end

-- ================================================================
-- TARGET / ATTACK DETECTION
-- Radius alone is NOT a dodge trigger. Attack/contact/damage is.
-- ================================================================
local function getEnemyInsideRadius()
	if not root then return nil, math.huge end

	local nearest
	local best = math.huge

	local function consider(model)
		if not model or model == character then return end
		if Players:GetPlayerFromCharacter(model) == player then return end
		local hum = getHum(model)
		local r = getRoot(model)
		if hum and r and hum.Health > 0 then
			local d = (r.Position - root.Position).Magnitude
			if d <= Settings.Radius and d < best then
				best = d
				nearest = model
			end
		end
	end

	eachTarget(consider)

	return nearest, best
end

-- Targeting for the actual dodge is deliberately limited to enemies
-- currently inside the player's configured radius.
local nearestEnemy = getEnemyInsideRadius

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

	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		local p = input.Position
		if Vector2.new(p.X, p.Y).Magnitude > 0.12 then
			releaseCamera()
			return
		end
	end
end)

--==================================================
-- ULTRA INSTINCT BODY SENSE VISUALS
-- White aura + white body outline: sabay, walang delay,
-- may fade in / fade out.
--==================================================

local uiHighlight, auraPulseConnection = nil, nil
local auraEmitters, auraObjects = {}, {}
local visualCharacter = nil

local auraAlpha = Instance.new("NumberValue")
auraAlpha.Value = 0
local auraTween
local function setAuraAlpha(target, t)
	if auraTween then auraTween:Cancel() end
	auraTween = tween(auraAlpha, t, {Value = target}, Enum.EasingStyle.Quad)
	auraTween:Play()
end

local function clearBodyAura()
	for _, obj in ipairs(auraObjects) do
		if obj and obj.Parent then obj:Destroy() end
	end
	auraObjects, auraEmitters = {}, {}
end

local function buildBodyAura()
	clearBodyAura()
	if not character then return end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local a = Instance.new("Attachment")
			a.Name = "UI_AuraAttachment"
			a.Parent = part
			local e = Instance.new("ParticleEmitter")
			e.Name = "UI_WhiteAura"
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Color = ColorSequence.new(Color3.new(1,1,1))
			e.LightEmission = 1
			e.Rate = 0
			e.Lifetime = NumberRange.new(0.22,0.5)
			e.Speed = NumberRange.new(0.15,1.3)
			e.SpreadAngle = Vector2.new(360,360)
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0,0.32),
				NumberSequenceKeypoint.new(0.55,0.16),
				NumberSequenceKeypoint.new(1,0)
			})
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0,0.18),
				NumberSequenceKeypoint.new(0.7,0.45),
				NumberSequenceKeypoint.new(1,1)
			})
			e.Parent = a
			table.insert(auraObjects, a)
			table.insert(auraEmitters, e)
		end
	end

	if uiHighlight then uiHighlight:Destroy() end
	uiHighlight = Instance.new("Highlight")
	uiHighlight.Name = "UI_WhiteOutline"
	uiHighlight.Adornee = character
	uiHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	uiHighlight.FillColor = Color3.new(1,1,1)
	uiHighlight.OutlineColor = Color3.new(1,1,1)
	uiHighlight.FillTransparency = 1
	uiHighlight.OutlineTransparency = 1
	uiHighlight.Parent = character
	visualCharacter = character
end

function refreshBodyAura()
	local shouldShow = Settings.Enabled and Settings.UltraActive and Settings.WhiteAura
	if shouldShow then
		-- aura + outline sabay, walang delay
		if not (uiHighlight and uiHighlight.Parent) or visualCharacter ~= character then
			buildBodyAura()
		end
		if not auraPulseConnection then
			auraPulseConnection = RunService.RenderStepped:Connect(function()
				if not uiHighlight or not uiHighlight.Parent then return end
				local a = auraAlpha.Value
				local pulse = (math.sin(os.clock() * 5.5) + 1) * 0.5
				local outlineBase = 0.04 + pulse * 0.28
				local fillBase = 0.90 - pulse * 0.07
				uiHighlight.OutlineTransparency = 1 - a * (1 - outlineBase)
				uiHighlight.FillTransparency = 1 - a * (1 - fillBase)
				for _, em in ipairs(auraEmitters) do
					if em.Parent then em.Rate = a * (5 + pulse * 9) end
				end
			end)
		end
		setAuraAlpha(1, 0.25) -- fade in
	else
		setAuraAlpha(0, 0.35) -- fade out
		task.delay(0.4, function()
			if auraAlpha.Value <= 0.01 then
				if auraPulseConnection then auraPulseConnection:Disconnect(); auraPulseConnection = nil end
				if uiHighlight then uiHighlight:Destroy(); uiHighlight = nil end
				clearBodyAura()
				visualCharacter = nil
			end
		end)
	end
end

--==================================================
-- VISUAL EFFECTS
--==================================================

local function flash()
	-- Simple white Ultra Instinct aura effect.
	if not root then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "UI_WhiteAura"
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.18, 0.34)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.45, 0.42),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.7, 0.25),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Parent = attachment
	if Settings.WhiteAura then
		emitter:Emit(24)
	else
		emitter.Enabled = false
	end

	local highlight = Instance.new("Highlight")
	if not Settings.WhiteAura then
		highlight:Destroy()
		Debris:AddItem(attachment, 0.1)
		return
	end
	highlight.Name = "UI_WhiteFlash"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255,255,255)
	highlight.OutlineColor = Color3.fromRGB(255,255,255)
	highlight.FillTransparency = 0.72
	highlight.OutlineTransparency = 0.2
	highlight.Parent = character

	tween(highlight, 0.28, {
		FillTransparency = 1,
		OutlineTransparency = 1
	}):Play()

	Debris:AddItem(attachment, 0.5)
	Debris:AddItem(highlight, 0.35)
end

local function createAfterimage(fade)
	fade = fade or 0.45
	if not Settings.Afterimage or not character then return end
	local ok, clone = pcall(function() return character:Clone() end)
	if not ok or not clone then return end
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Tool")
			or obj:IsA("Humanoid") or obj:IsA("Decal") or obj:IsA("Shirt") or obj:IsA("Pants")
			or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or obj:IsA("ParticleEmitter")
			or obj:IsA("Highlight") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("BillboardGui")
			or obj:IsA("Sound") then
			obj:Destroy()
		end
	end
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.CastShadow = false
			obj.Material = Enum.Material.Neon
			obj.Color = Color3.new(1, 1, 1)
			if obj:IsA("MeshPart") then obj.TextureID = "" end
			obj.Transparency = (obj.Transparency >= 0.95) and 1 or 0.08
		elseif obj:IsA("SpecialMesh") then
			obj.TextureId = ""
		end
	end
	clone.Name = "UI_Afterimage"
	clone.Parent = workspace
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Transparency < 1 then
			tween(obj, fade, {Transparency = 1}, Enum.EasingStyle.Quad):Play()
		end
	end
	Debris:AddItem(clone, fade + 0.1)
end

local function createTrail(a, b)
	local dist = (b - a).Magnitude
	if not Settings.Afterimage or dist < 1 then return end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.new(1, 1, 1)
	p.Transparency = 0.1
	p.Size = Vector3.new(0.55, 0.55, dist)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	p.Parent = workspace
	tween(p, 0.4, {Transparency = 1, Size = Vector3.new(0.05, 0.05, dist)}):Play()
	Debris:AddItem(p, 0.45)
end

local function smokePuff(pos)
	if not Settings.WhiteAura then return end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Position = pos
	part.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.8
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.3, 0.55)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(360, 360)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.2)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	e.Parent = part
	e:Emit(14)
	Debris:AddItem(part, 0.8)
end

local counterGui = Instance.new("TextLabel")
counterGui.Size = UDim2.fromOffset(190,48)
counterGui.Position = UDim2.new(0.5,-95,0.72,0)
counterGui.BackgroundTransparency = 1
counterGui.Text = ""
counterGui.Font = Enum.Font.GothamBlack
counterGui.TextSize = 25
counterGui.TextColor3 = Color3.new(1,1,1)
counterGui.TextStrokeTransparency = 0.35
counterGui.Visible = false
counterGui.ZIndex = 200
counterGui.Parent = gui

local function showDodgeIndicator()
	counterGui.Text = "DODGE  " .. tostring(Settings.DodgeCount) .. "x"
	counterGui.Visible = true
	counterGui.TextTransparency = 0
	tween(counterGui,0.18,{Position=UDim2.new(0.5,-95,0.67,0)}):Play()
	task.delay(0.55,function()
		if counterGui.Parent then
			tween(counterGui,0.25,{TextTransparency=1}):Play()
			task.wait(0.25)
			counterGui.Visible=false
			counterGui.Position=UDim2.new(0.5,-95,0.72,0)
		end
	end)
end

-- RED MARK: pumupula ang enemy kapag nasa loob ng radius circle.
-- Pag nasa labas na, 2 seconds (RedLingerTime) bago mawala. May fade in/out.
local redMarks = setmetatable({}, {__mode = "k"})

local function redFadeIn(entry)
	entry.state = "shown"
	if entry.tw then entry.tw:Cancel() end
	entry.tw = tween(entry.h, Settings.RedFadeIn, {
		FillTransparency = 0.45,
		OutlineTransparency = 0
	}, Enum.EasingStyle.Quad)
	entry.tw:Play()
end

local function redFadeOut(model, entry)
	if entry.state == "fading" then return end
	entry.state = "fading"
	if entry.tw then entry.tw:Cancel() end
	local tw = tween(entry.h, Settings.RedFadeOut, {
		FillTransparency = 1,
		OutlineTransparency = 1
	}, Enum.EasingStyle.Quad)
	entry.tw = tw
	tw.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and entry.state == "fading" then
			if entry.h then entry.h:Destroy() end
			redMarks[model] = nil
		end
	end)
	tw:Play()
end

local lastRedUpdate = 0
local function updateRedMarks()
	local now = os.clock()
	if now - lastRedUpdate < 0.08 then return end
	lastRedUpdate = now

	local active = Settings.Enabled and Settings.UltraActive and root ~= nil and root.Parent ~= nil

	if active then
		eachTarget(function(model)
			local hum, r = getHum(model), getRoot(model)
			if not hum or not r or hum.Health <= 0 then return end
			local inside = (r.Position - root.Position).Magnitude <= Settings.Radius
			local entry = redMarks[model]
			if inside then
				if not entry or not entry.h or not entry.h.Parent then
					local h = Instance.new("Highlight")
					h.Name = "UI_RedMark"
					h.Adornee = model
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					h.FillColor = Color3.fromRGB(255, 30, 30)
					h.OutlineColor = Color3.fromRGB(255, 70, 70)
					h.FillTransparency = 1
					h.OutlineTransparency = 1
					h.Parent = model
					entry = {h = h, lastInside = now, state = "new"}
					redMarks[model] = entry
					redFadeIn(entry)
				else
					entry.lastInside = now
					if entry.state ~= "shown" then redFadeIn(entry) end
				end
			elseif entry and entry.state == "shown" and now - entry.lastInside >= Settings.RedLingerTime then
				redFadeOut(model, entry)
			end
		end)
	end

	-- cleanup: patay / nawala / Ultra OFF -> fade out
	for model, entry in pairs(redMarks) do
		if not entry.h or not entry.h.Parent or not model.Parent then
			if entry.h then entry.h:Destroy() end
			redMarks[model] = nil
		elseif entry.state == "shown" then
			local hum = getHum(model)
			if not active or not hum or hum.Health <= 0 then
				redFadeOut(model, entry)
			end
		end
	end
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

local function lockCameraToTarget(target)
	if not Settings.CameraLock or not Settings.UltraActive or not target then return end
	if humanoid and humanoid.MoveDirection.Magnitude > 0.12 then return end -- joystick = no lock
	local hum = getHum(target)
	local tr = getRoot(target)
	if not hum or not tr or hum.Health <= 0 then return end
	cameraTarget = target
	cameraLocked = true
	cameraManualLock = true
end

local function cancelCameraLock()
	cameraLocked = false
	cameraTarget = nil
	cameraManualLock = false
end

--==================================================
-- ULTRA INSTINCT ON/OFF + CHAT INTRO
-- Chat intro lang pag ON. Walang outro pag OFF.
--==================================================

local function ultraChatIntro()
	local text = "ULTRA INSTINCT!!!"
	local sent = false

	-- New TextChatService
	pcall(function()
		local TCS = game:GetService("TextChatService")
		if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
			local channels = TCS:FindFirstChild("TextChannels")
			local ch = channels and channels:FindFirstChild("RBXGeneral")
			if ch then
				ch:SendAsync(text)
				sent = true
			end
		end
	end)
	if sent then return end

	-- Legacy chat
	pcall(function()
		local RS = game:GetService("ReplicatedStorage")
		local events = RS:FindFirstChild("DefaultChatSystemChatEvents")
		local say = events and events:FindFirstChild("SayMessageRequest")
		if say then
			say:FireServer(text, "All")
			sent = true
		end
	end)
	if sent then return end

	-- Fallback bubble kung hindi gumana ang chat
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1,1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.new(1,1,1)
	t.TextStrokeTransparency = 0.3
	t.Parent = bb
	Debris:AddItem(bb, 3)
end

local function setUltra(on)
	if Settings.UltraActive == on then return end
	Settings.UltraActive = on
	if on then
		ultraChatIntro()
	else
		following = false
		followToken += 1
		cancelCameraLock()
	end
	refreshBodyAura() -- aura + outline sabay, fade in/out
	refreshPower()
end

ultraToggle.MouseButton1Click:Connect(function()
	play(clickSound)
	setUltra(not Settings.UltraActive)
end)

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

			local offset
			if Settings.FollowMode == "Side" then
				offset = targetRoot.CFrame.RightVector * Settings.FollowDistance
			else
				offset = -targetRoot.CFrame.LookVector * Settings.FollowDistance
			end

			local desired = targetRoot.Position + offset
			local flat = Vector3.new(desired.X, root.Position.Y, desired.Z)

			root.CFrame = root.CFrame:Lerp(
				CFrame.lookAt(
					flat,
					Vector3.new(targetRoot.Position.X, flat.Y, targetRoot.Position.Z)
				),
				Settings.FollowSpeed
			)

			task.wait()
		end

		if token == followToken then
			following = false
			followTarget = nil
			if Settings.StopEffect then
				stopEffect()
			end
		end
	end)
end

-- ================================================================
-- DODGE CORE
-- Executes the dodge animation, effects, camera and follow logic.
-- ================================================================
local ACTIVITY = {
	Low    = {dur = 0.22, lock = 0.12},
	Normal = {dur = 0.16, lock = 0.08},
	High   = {dur = 0.12, lock = 0.04},
	Max    = {dur = 0.08, lock = 0.02},
}

-- Where the dodge dash ends. Side Burst = slips around the side of the enemy,
-- Blink = behind the enemy, Backstep = away from the enemy.
local function dodgeDestination(targetRoot)
	local origin = root.Position
	local dest
	if targetRoot then
		local tp = targetRoot.Position
		local look = Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
		look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
		local right = Vector3.new(-look.Z, 0, look.X)
		local dist = math.max(Settings.FollowDistance, 3.5)
		local mode = Settings.DodgeAnimation
		if mode == "Backstep" then
			local away = Vector3.new(origin.X - tp.X, 0, origin.Z - tp.Z)
			away = away.Magnitude > 0.05 and away.Unit or -look
			dest = origin + away * 8
		elseif mode == "Blink" then
			dest = tp - look * dist
		else
			local side = ((origin - tp):Dot(right) >= 0) and -1 or 1
			dest = tp + right * side * dist - look * (dist * 0.4)
		end
	else
		local side = math.random(1, 2) == 1 and 1 or -1
		dest = origin + root.CFrame.RightVector * side * 8
	end
	dest = Vector3.new(dest.X, origin.Y, dest.Z)

	-- never dash through walls
	local ignore = {character}
	if targetRoot and targetRoot.Parent then table.insert(ignore, targetRoot.Parent) end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local dir = dest - origin
	if dir.Magnitude > 0.1 then
		local hit = workspace:Raycast(origin, dir, params)
		if hit then
			dest = hit.Position - dir.Unit * 2
		end
	end
	return dest
end

local function runDodge()
	if dodging then return end
	if not Settings.Enabled or not Settings.AutoDodge or not Settings.UltraActive then return end
	if not humanoid or humanoid.Health <= 0 or not root then return end
	if math.random(1,100) > Settings.DodgeChance then return end

	dodging = true
	followToken += 1
	following = false

	local target = getEnemyInsideRadius()
	local targetRoot = target and getRoot(target)

	playRandomDodgeSound()
	flash()
	Settings.DodgeCount += 1
	refreshUltraConfig()
	showDodgeIndicator()

	if targetRoot then
		lockCameraToTarget(target)
	end

	local act = ACTIVITY[Settings.DodgeActivity] or ACTIVITY.High
	local startPos = root.Position
	local destination = dodgeDestination(targetRoot)
	local startCF = root.CFrame
	local endCF
	if targetRoot then
		local faceFlat = Vector3.new(targetRoot.Position.X, destination.Y, targetRoot.Position.Z)
		if (faceFlat - destination).Magnitude > 0.1 then
			endCF = CFrame.lookAt(destination, faceFlat)
		end
	end
	endCF = endCF or (CFrame.new(destination) * startCF.Rotation)

	-- white ghost where you were + smoke
	createAfterimage(0.45)
	smokePuff(startPos)

	local ghosts = 0
	local start = os.clock()
	while true do
		local a = math.clamp((os.clock() - start) / act.dur, 0, 1)
		local e = 1 - (1 - a) ^ 3
		if root and root.Parent then
			root.CFrame = startCF:Lerp(endCF, e)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		-- extra ghosts along the path
		if ghosts < 2 and a >= (ghosts + 1) / 3 then
			ghosts += 1
			createAfterimage(0.35)
		end
		if a >= 1 then break end
		RunService.RenderStepped:Wait()
	end

	createTrail(startPos + Vector3.new(0, 1, 0), destination + Vector3.new(0, 1, 0))
	smokePuff(destination)

	if target then
		followForFiveSeconds(target)
	end

	task.delay(act.lock, function()
		dodging = false
	end)
end

local function dodge()
	local ok, err = pcall(runDodge)
	if not ok then
		warn("[JAYVEE UI] Dodge error:", err)
		dodging = false
	end
end

--==================================================
-- CAMERA FOLLOW
--==================================================

RunService.RenderStepped:Connect(function()
	if humanoid and humanoid.MoveDirection.Magnitude > 0.12 then
		-- moving the joystick releases the lock (and the follow)
		if cameraLocked then cancelCameraLock() end
		if following then
			following = false
			followToken += 1
		end
	end
	updateRing()
	updatePlayerInfo()
	updateRedMarks()

	if character and character ~= visualCharacter
		and Settings.Enabled and Settings.UltraActive and Settings.WhiteAura then
		refreshBodyAura()
	end

end)

local bodyLocked = false
RunService:BindToRenderStep("JAYVEE_CameraLock", Enum.RenderPriority.Camera.Value + 1, function()
	local target = cameraTarget or followTarget
	if not (cameraLocked and target) then
		if bodyLocked then
			bodyLocked = false
			if humanoid then humanoid.AutoRotate = true end
		end
		return
	end
	local cam = workspace.CurrentCamera
	local targetRoot = getRoot(target)
	local targetHum = getHum(target)
	if not cam or not targetRoot or not targetHum or targetHum.Health <= 0 then
		cancelCameraLock()
		return
	end
	if root and (targetRoot.Position - root.Position).Magnitude > Settings.Radius * 2.5 then
		cancelCameraLock()
		return
	end

	-- camera locks on the enemy
	local point = targetRoot.Position + Vector3.new(0, 2, 0)
	cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, point), 0.4)

	-- body locks on the enemy too
	if root and humanoid and humanoid.Health > 0 then
		bodyLocked = true
		humanoid.AutoRotate = false
		local flat = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
		if (flat - root.Position).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end
end)

--==================================================
-- ULTRA INSTINCT SENSE
--==================================================

local senseCooldown = 0
local trackedTargetHealth = setmetatable({}, {__mode = "k"})
local trackedTargetStamp = setmetatable({}, {__mode = "k"})
local lastSenseTarget = nil
local lastTargetPositions = setmetatable({}, {__mode = "k"})
local lastAttackStamp = setmetatable({}, {__mode = "k"})

local function isValidTarget(model)
	if not model or model == character then return false end
	local hum = getHum(model)
	local tr = getRoot(model)
	return hum and tr and hum.Health > 0 and Players:GetPlayerFromCharacter(model) ~= player
end

local function getAllNearbyTargets()
	local list = {}
	local seen = {}
	local function add(model)
		if seen[model] or not isValidTarget(model) then return end
		local tr = getRoot(model)
		if tr and root and (tr.Position - root.Position).Magnitude <= Settings.Radius then
			seen[model] = true
			table.insert(list, model)
		end
	end
	eachTarget(add)
	return list
end

local function detectEnemyHit(target)
	if not target then return false end
	local hum = getHum(target)
	if not hum then return false end
	local old = trackedTargetHealth[target]
	trackedTargetHealth[target] = hum.Health
	if old and hum.Health < old then
		local stamp = trackedTargetStamp[target] or 0
		if os.clock() - stamp > 0.12 then
			trackedTargetStamp[target] = os.clock()
			return true
		end
	end
	return false
end

local function detectAnyEnemyHit()
	if not root then return nil end
	local found
	eachTarget(function(m)
		if found or not isValidTarget(m) then return end
		local tr = getRoot(m)
		if (tr.Position - root.Position).Magnitude <= Settings.Radius then
			if detectEnemyHit(m) then found = m end
		end
	end)
	return found
end

local ATTACK_WORDS = {"attack","punch","kick","swing","slash","hit","strike","stab","bite","claw","smash","combo","melee","m1","skill","slam","shoot","fire"}
local MOVE_WORDS = {"idle","walk","run","jump","fall","climb","swim","sit","emote","dance","wave","point","cheer","laugh"}

local function hasWord(str, list)
	for _, w in ipairs(list) do
		if str:find(w, 1, true) then return true end
	end
	return false
end

local function enemyLooksLikeAttacking(model)
	local hum = getHum(model)
	if not hum then return false end

	-- Works sa players at bots (Animator / AnimationController / Humanoid).
	local animator = hum:FindFirstChildOfClass("Animator")
		or model:FindFirstChildWhichIsA("Animator", true)
	local ok, tracks = pcall(function()
		if animator then return animator:GetPlayingAnimationTracks() end
		return hum:GetPlayingAnimationTracks()
	end)
	if ok and tracks then
		for _, track in ipairs(tracks) do
			local a = track.Animation
			local n = string.lower(track.Name .. " " .. (a and a.Name or ""))
			if hasWord(n, ATTACK_WORDS) then
				return true
			end
			-- Bots na iba ang pangalan ng animation: non-looping action animation = attack.
			if not track.Looped and track.Priority.Value >= Enum.AnimationPriority.Action.Value
				and not hasWord(n, MOVE_WORDS) then
				return true
			end
		end
	end

	local tr = getRoot(model)
	if tr and root then
		local toPlayer = root.Position - tr.Position
		local dist = toPlayer.Magnitude
		if dist > 0.1 then
			-- rumaragasa palapit sa'yo
			local closing = tr.AssemblyLinearVelocity:Dot(toPlayer.Unit)
			if closing > 8 then return true end
			-- bot na malapit, nakaharap sa'yo, at gumagalaw papunta sa'yo (melee bot)
			if dist <= Settings.ContactTriggerDistance + 3 then
				local facing = tr.CFrame.LookVector:Dot(toPlayer.Unit)
				if facing > 0.6 and closing > 3 then return true end
			end
		end
	end

	return false
end

RunService.Heartbeat:Connect(function()
	if not Settings.Enabled or not Settings.AutoDodge or not Settings.UltraActive or dodging or not root then return end
	if os.clock() < senseCooldown then return end

	local nearby = getAllNearbyTargets()
	if #nearby == 0 then
		lastSenseTarget = nil
		return
	end

	-- Ultra Instinct Sense does NOT trigger just because a target is inside the radius.
	-- A dodge is triggered by an attack start, actual damage, or very close contact.
	local target = getEnemyInsideRadius()
	local hitTarget = detectAnyEnemyHit()
	if hitTarget and isValidTarget(hitTarget) then target = hitTarget end

	local trigger = false
	local attack = false
	local enemyHit = hitTarget ~= nil
	local contact = false
	local nearest = target

	for _, model in ipairs(nearby) do
		local tr = getRoot(model)
		if tr then
			local d = (tr.Position - root.Position).Magnitude
			if d <= Settings.ContactTriggerDistance then contact = true end
			if enemyLooksLikeAttacking(model) then
				attack = true
				nearest = nearest or model
			end
			lastTargetPositions[model] = d
		end
	end

	if enemyHit or contact or attack then
		trigger = true
	end

	local chosen = hitTarget or target or nearby[1]
	if chosen and trigger then
		lockCameraToTarget(chosen)
		senseCooldown = os.clock() + (attack and 0.16 or contact and 0.22 or 0.38)
		dodge()
	end
end)

--==================================================
-- COMBAT CAMERA LOCK + JOYSTICK CANCEL
--==================================================

local function nearestEnemy()
	local best, bestDist
	if not root then return nil end
	eachTarget(function(m)
		local hum, tr = getHum(m), getRoot(m)
		if hum and tr and hum.Health > 0 then
			local d = (tr.Position - root.Position).Magnitude
			if d <= Settings.Radius and (not bestDist or d < bestDist) then best, bestDist = m, d end
		end
	end)
	return best
end

local function hookTool(tool)
	if not tool:IsA("Tool") then return end
	tool.Activated:Connect(function()
		local target = nearestEnemy()
		if target then
			-- Lock immediately when the player attacks a nearby enemy.
			lockCameraToTarget(target)
		end
	end)
end

local function hookCharacterTools(char)
	if not char then return end
	for _,obj in ipairs(char:GetChildren()) do hookTool(obj) end
	char.ChildAdded:Connect(hookTool)
end
hookCharacterTools(character)

--==================================================
-- DAMAGE DETECTION
--==================================================

-- ================================================================
-- DAMAGE DETECTION
-- Fallback for real damage received by the local character.
-- ================================================================
local function hookDamage()
	if damageConnection then
		damageConnection:Disconnect()
	end

	if not humanoid then return end

	lastHealth = humanoid.Health

	damageConnection = humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth and Settings.Enabled and Settings.AutoDodge and Settings.UltraActive then
			-- Only trigger Ultra Instinct when an enemy is actually inside
			-- the configured player circle at the moment damage is received.
			local enemyInside = getEnemyInsideRadius()
			if enemyInside then
				lockCameraToTarget(enemyInside)
				task.defer(dodge)
			end
		end

		lastHealth = newHealth
	end)
end

--==================================================
-- MENU ANIMATION
--==================================================

minimized = Instance.new("TextButton")
minimized.Size = UDim2.fromOffset(65,65)
minimized.Position = UDim2.new(0,18,0.5,-32)
minimized.Text = "UI"
minimized.Font = Enum.Font.GothamBlack
minimized.TextSize = 16
minimized.TextColor3 = Color3.new(1,1,1)
minimized.BackgroundColor3 = Color3.fromRGB(104,72,158)
minimized.Visible = false
minimized.Parent = gui
minimized.Visible = false
corner(minimized,20)
addStroke(minimized,0.15)
draggable(minimized)

-- ================================================================
-- MAIN MENU ANIMATIONS
-- Menu entrance and UI interaction animation logic.
-- ================================================================
local function runIntroAnimations()
	local targetPosition=UDim2.new(0.5,-285,0.5,-195)
	local startPosition=UDim2.new(0.5,-285,0.4,-120)
	main.Position=startPosition
	main.Size=UDim2.fromOffset(500,350)
	local styles={Back=Enum.EasingStyle.Back,Quint=Enum.EasingStyle.Quint,Elastic=Enum.EasingStyle.Elastic,Linear=Enum.EasingStyle.Linear}
	local style=styles[Settings.IntroAnimation] or Enum.EasingStyle.Back
	local duration=math.clamp(Settings.AnimationSpeed,0.20,0.90)
	local positionTween=TweenService:Create(main,TweenInfo.new(duration,style,Enum.EasingDirection.Out),{Position=targetPosition})
	local sizeTween=TweenService:Create(main,TweenInfo.new(duration,style,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(570,390)})

	positionTween:Play()
	sizeTween:Play()
end

local function openMenu()
	menuOpen = true
	minimized.Visible = false
	main.Visible = true
	mainScale.Scale = math.clamp(Settings.MenuScale * Settings.UIScale, 0.65, 1.35)
	play(openSound)
	task.spawn(runIntroAnimations)
end

local function minimizeMenu()
	menuOpen = false

	local targetPosition = UDim2.new(0.5, -285, 0.4, -120)

	local positionTween = TweenService:Create(
		main,
		TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{Position = targetPosition}
	)

	local sizeTween = TweenService:Create(
		main,
		TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{Size = UDim2.fromOffset(500, 350)}
	)

	positionTween:Play()
	sizeTween:Play()

	task.wait(0.18)
	main.Visible = false
	minimized.Visible = true
	play(clickSound)
end

minimize.MouseButton1Click:Connect(minimizeMenu)
close.MouseButton1Click:Connect(minimizeMenu)
minimized.MouseButton1Click:Connect(openMenu)

--==================================================
-- MAIN UI CLICK ANIMATIONS
--==================================================

-- Button click feedback: pulse/tween used when a UI setting changes.
local function addClickAnimation(button)
    if not button:IsA("TextButton") then return end
    if button:GetAttribute("JAYVEE_ClickFX") then return end
    button:SetAttribute("JAYVEE_ClickFX", true)

    local scale = button:FindFirstChild("ClickScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "ClickScale"
        scale.Scale = 1
        scale.Parent = button
    end

    button.Activated:Connect(function()
        if not button.Visible then return end
        scale.Scale = 0.94
        tween(scale, 0.12, {Scale = 1.06}, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        task.delay(0.12, function()
            if scale.Parent then
                tween(scale, 0.10, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            end
        end)
    end)
end

for _, obj in ipairs(main:GetDescendants()) do
    addClickAnimation(obj)
end
main.DescendantAdded:Connect(addClickAnimation)

--==================================================
-- INITIALIZE
--==================================================

-- Ultra Instinct starts OFF (security screen AND main menu).
Settings.UltraActive = false

showPage("Home")
refreshPower()
refreshRadius()
refreshMenuSize()
refreshUltraConfig()
refreshFollowConfig()
hookDamage()
refreshBodyAura() -- no aura while OFF

security.Visible = false
main.Visible = false
minimized.Visible = false

-- Startup order is intentionally: Security -> Password -> Loading -> Ability Menu.
-- Show Security immediately so character/movement loading can never hide the UI.
security.Visible = true
security.ZIndex = 200
main.Visible = false
minimized.Visible = false
secScale.Scale = 1

player.CharacterAdded:Connect(function(char)
	character = char
	-- reset combat state so nothing stays stuck after respawn
	dodging = false
	following = false
	followToken += 1
	cameraLocked = false
	cameraTarget = nil
	hookCharacterTools(char)
	task.spawn(function()
		humanoid = char:WaitForChild("Humanoid", 10)
		root = char:WaitForChild("HumanoidRootPart", 10)
		if humanoid then lastHealth = humanoid.Health end
		if humanoid and root then hookDamage() end
	end)
end)

unlock.MouseButton1Click:Connect(function()
	play(clickSound)

	if passBox.Text == PASSWORD then
		securityStatus.Text = "ACCESS GRANTED"
		securityStatus.TextColor3 = Color3.fromRGB(175,255,195)
		play(openSound)

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
