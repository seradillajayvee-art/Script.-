--[[
	ClothingHub  |  Delta / mobile friendly
	Client-side outfit changer (ikaw lang makakakita ng changes)

	Open / Hide : tap the floating icon (or press RightShift on PC)

	OUTFIT tab
	  Clothing  : Shirt Id + Pants Id
	  Accessory : default 7 slots (< > to switch, tap the number after "/" to set how many)

	CHARACTER tab
	  Head Id, Face Id, Hair Id
	  Hair Color (RGB sliders / hex / presets, solid color toggle)
	  Skin Color (RGB sliders / hex / presets)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local SCRIPT_VERSION = "1.0.0"

local CONFIG = {
	Title = "ClothingHub",
	Slots = 7, -- default lang, pwede mo palitan sa UI (tap yung number after "/")
	MaxSlots = 20,
	Accent = Color3.fromRGB(10, 132, 255),
	Accent2 = Color3.fromRGB(150, 80, 255),
	IconImage = "", -- optional: "rbxassetid://ID" para sa sarili mong icon (kung blangko, default na hanger icon)
	Volume = 0.6,
	ToggleKey = Enum.KeyCode.RightShift,
	Version = SCRIPT_VERSION,
	ShowLoading = true, -- false = skip yung loading screen
	-- Author card sa Home tab. Dagdagan / palitan mo dito (Discord, TikTok, etc.)
	AuthorInfo = {
		{ "Author", "JAYVEE" },
		{ "Script", "ClothingHub" },
		{ "Version", SCRIPT_VERSION },
	},
	AuthorExtra = {
		-- { "Discord", "yourname" },
	},
	-- { SoundId, PlaybackSpeed } -> palitan mo ng "rbxassetid://ID" kung gusto mo ibang sound
	Sounds = {
		Click   = { "rbxasset://sounds/button.wav", 1.2 },
		Open    = { "rbxasset://sounds/switch.wav", 1.1 },
		Close   = { "rbxasset://sounds/switch.wav", 0.85 },
		Success = { "rbxasset://sounds/electronicpingshort.wav", 1 },
		Error   = { "rbxasset://sounds/bass.wav", 1 },
	},
	HairPresets = {
		Color3.fromRGB(20, 20, 24), Color3.fromRGB(74, 48, 32), Color3.fromRGB(232, 200, 120),
		Color3.fromRGB(190, 85, 40), Color3.fromRGB(175, 40, 45), Color3.fromRGB(255, 130, 190),
		Color3.fromRGB(70, 130, 255), Color3.fromRGB(240, 240, 245),
	},
	SkinPresets = {
		Color3.fromRGB(255, 224, 189), Color3.fromRGB(241, 194, 150), Color3.fromRGB(224, 172, 105),
		Color3.fromRGB(198, 134, 66), Color3.fromRGB(141, 85, 36), Color3.fromRGB(90, 56, 37),
		Color3.fromRGB(130, 200, 130), Color3.fromRGB(160, 160, 170),
	},
}

------------------------------------------------------------
-- Cleanup old instance (re-execute safe)
------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.ClothingHub and env.ClothingHub.Destroy then
	pcall(env.ClothingHub.Destroy)
end

------------------------------------------------------------
-- Saved settings (UI customization) + theme registry
------------------------------------------------------------
local SET = {
	file = "ClothingHub_settings.json",
	themes = {
		{ "Ocean", Color3.fromRGB(10, 132, 255), Color3.fromRGB(150, 80, 255) },
		{ "Sunset", Color3.fromRGB(255, 120, 60), Color3.fromRGB(255, 60, 150) },
		{ "Mint", Color3.fromRGB(30, 215, 150), Color3.fromRGB(20, 150, 255) },
		{ "Rose", Color3.fromRGB(255, 80, 140), Color3.fromRGB(170, 80, 255) },
		{ "Gold", Color3.fromRGB(255, 190, 50), Color3.fromRGB(255, 110, 60) },
		{ "Crimson", Color3.fromRGB(255, 60, 80), Color3.fromRGB(150, 30, 90) },
	},
	keys = { "RightShift", "RightControl", "LeftAlt", "Insert", "Home", "K", "M" },
}

local S = {
	theme = 1,
	glass = 0.12,
	scale = 1,
	sounds = true,
	volume = 0.6,
	menuKey = "RightShift",
	showIcon = true,
	iconSize = 56,
	iconDocked = false,
	loading = true,
	autoReapply = true,
	autoApplySaved = false,
}
SET.defaults = {}
for k, v in pairs(S) do
	SET.defaults[k] = v
end

local savedData = nil
pcall(function()
	if isfile and readfile and isfile(SET.file) then
		savedData = game:GetService("HttpService"):JSONDecode(readfile(SET.file))
	end
end)
if type(savedData) == "table" and type(savedData.settings) == "table" then
	for k, v in pairs(savedData.settings) do
		if S[k] ~= nil and type(v) == type(S[k]) then
			S[k] = v
		end
	end
end
S.theme = math.clamp(math.floor(S.theme), 1, #SET.themes)
S.glass = math.clamp(S.glass, 0, 0.6)
S.scale = math.clamp(S.scale, 0.7, 1.2)
S.volume = math.clamp(S.volume, 0, 1)
S.iconSize = math.clamp(math.floor(S.iconSize), 40, 72)

CONFIG.Accent, CONFIG.Accent2 = SET.themes[S.theme][2], SET.themes[S.theme][3]
CONFIG.Volume = S.volume
CONFIG.ShowLoading = S.loading
pcall(function()
	CONFIG.ToggleKey = Enum.KeyCode[S.menuKey]
end)

-- lahat ng elements na gumagamit ng accent color (para sa live theme change)
local theme = { grads = {}, fills = {}, fills2 = {}, strokes = {}, switches = {} }
theme.apply = function()
	local seq = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2)
	for _, g in ipairs(theme.grads) do
		if g.Parent then
			g.Color = seq
		end
	end
	for _, f in ipairs(theme.fills) do
		if f.Parent then
			f.BackgroundColor3 = CONFIG.Accent
		end
	end
	for _, f in ipairs(theme.fills2) do
		if f.Parent then
			f.BackgroundColor3 = CONFIG.Accent2
		end
	end
	for _, st in ipairs(theme.strokes) do
		if st.Parent then
			st.Color = CONFIG.Accent
		end
	end
	for _, sw in ipairs(theme.switches) do
		sw.refresh()
	end
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local WHITE = Color3.new(1, 1, 1)
local MUTED = Color3.fromRGB(185, 192, 210)
local connections = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function tween(inst, props, t, style, dir)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function digits(s)
	return (tostring(s or ""):match("%d+")) or ""
end

-- yung character na talagang nakikita mo (minsan ibang model ang camera subject sa ibang games)
local function getChar()
	local own = LocalPlayer.Character
	local cam = workspace.CurrentCamera
	local subj = cam and cam.CameraSubject
	if subj and subj:IsA("Humanoid") then
		local m = subj.Parent
		if m and m ~= own and m:IsA("Model") and m:FindFirstChild("Head") then
			local pl = Players:GetPlayerFromCharacter(m)
			if pl == nil or pl == LocalPlayer then
				return m
			end
		end
	end
	return own
end

local function getGuiParent()
	if gethui then
		local ok, ui = pcall(gethui)
		if ok and ui then
			return ui
		end
	end
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and core then
		local probe = Instance.new("Folder")
		local good = pcall(function()
			probe.Parent = core
		end)
		probe:Destroy()
		if good then
			return core
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------
-- Sounds
------------------------------------------------------------
local sounds = {}
for name, data in pairs(CONFIG.Sounds) do
	sounds[name] = new("Sound", {
		Name = "ClothingHub_" .. name,
		SoundId = data[1],
		PlaybackSpeed = data[2] or 1,
		Volume = CONFIG.Volume,
	}, SoundService)
end

local function play(name)
	local s = sounds[name]
	if s and S.sounds then
		s.TimePosition = 0
		s:Play()
	end
end

------------------------------------------------------------
-- Liquid glass styling helpers
------------------------------------------------------------
local function glassFill(frame, transparency)
	frame.BackgroundColor3 = WHITE
	frame.BackgroundTransparency = transparency
	new("UIGradient", {
		Rotation = 55,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(92, 104, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 32, 88)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 40)),
		}),
	}, frame)
end

-- bright rim light on opposite corners (the "liquid glass" edge)
local function addRim(parent, thickness, baseTransparency)
	local stroke = new("UIStroke", {
		Color = WHITE,
		Thickness = thickness or 1.2,
		Transparency = baseTransparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	new("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
	}, stroke)
	return stroke
end

local function pressFX(btn)
	local s = new("UIScale", {}, btn)
	local function release()
		tween(s, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)
	end
	btn.MouseButton1Down:Connect(function()
		tween(s, { Scale = 0.94 }, 0.1)
	end)
	btn.MouseButton1Up:Connect(release)
	btn.MouseLeave:Connect(release)
end

local function glassButton(parent, text, size, position, accent)
	local b = new("TextButton", {
		AutoButtonColor = false,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = WHITE,
		Size = size,
		Position = position,
		BorderSizePixel = 0,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = accent and 0.08 or 0.86,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, b)
	addRim(b, 1, 0.3)
	if accent then
		table.insert(theme.grads, new("UIGradient", {
			Rotation = 20,
			Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
		}, b))
	end
	pressFX(b)
	return b
end

local function makeDraggable(handle, target, onTap, onDrop, onHold)
	local dragging, moved, held, dragStart, startPos, token = false, false, false, nil, nil, 0
	connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			held = false
			token = token + 1
			local myToken = token
			dragStart = input.Position
			startPos = target.Position
			if onHold then
				task.delay(0.5, function()
					if dragging and not moved and not held and token == myToken then
						held = true
						onHold()
					end
				end)
			end
			local con
			con = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					con:Disconnect()
					if held then
						return
					end
					if moved then
						if onDrop then
							onDrop()
						end
					elseif onTap then
						onTap()
					end
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 6 then
				moved = true
			end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end
	end)
end

-- iOS-style toggle switch
local function makeSwitch(parent, initial, onChange)
	local on = initial and true or false
	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(40, 24),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
	addRim(sw, 1, 0.3)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, sw)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local obj = {}
	local function render(animate)
		local t = animate and 0.2 or 0
		tween(knob, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, t)
		tween(sw, {
			BackgroundColor3 = on and CONFIG.Accent or WHITE,
			BackgroundTransparency = on and 0.15 or 0.82,
		}, t)
	end
	function obj.Get()
		return on
	end
	function obj.Set(v)
		v = v and true or false
		if v == on then
			return
		end
		on = v
		render(true)
	end
	sw.MouseButton1Click:Connect(function()
		on = not on
		render(true)
		play("Click")
		if onChange then
			onChange(on)
		end
	end)
	render(false)
	obj.refresh = function()
		render(false)
	end
	table.insert(theme.switches, obj)
	return obj
end

-- custom icons (drawn from shapes, walang emoji / asset)
local function iconLine(parent, x1, y1, x2, y2, th, color)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
		Size = UDim2.fromOffset(len + th * 0.6, th),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	return f
end

-- kind: "home" | "hanger" | "person"  -> returns { box, setColor }
local function makeIcon(kind, parent, size, color)
	local k = size / 16
	local th = 1.6 * k
	local box = new("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, parent)
	local fills, strokes = {}, {}
	local function L(x1, y1, x2, y2)
		table.insert(fills, iconLine(box, x1 * k, y1 * k, x2 * k, y2 * k, th, color))
	end
	if kind == "home" then
		L(8, 1.8, 1.4, 7.6)
		L(8, 1.8, 14.6, 7.6)
		L(3, 7.2, 3, 14)
		L(13, 7.2, 13, 14)
		L(3, 14, 13, 14)
	elseif kind == "hanger" then
		local ring = new("Frame", {
			Position = UDim2.fromOffset(5.6 * k, 0.4 * k),
			Size = UDim2.fromOffset(4.8 * k, 4.8 * k),
			BackgroundTransparency = 1,
		}, box)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		table.insert(strokes, new("UIStroke", { Color = color, Thickness = th }, ring))
		L(8, 5.2, 8, 7.4)
		L(8, 7.4, 1.2, 12.8)
		L(8, 7.4, 14.8, 12.8)
		L(1.2, 12.8, 14.8, 12.8)
	elseif kind == "sliders" then
		L(1.5, 3.5, 14.5, 3.5)
		L(1.5, 8, 14.5, 8)
		L(1.5, 12.5, 14.5, 12.5)
		for _, kn in ipairs({ { 10.5, 3.5 }, { 5, 8 }, { 11.5, 12.5 } }) do
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(kn[1] * k, kn[2] * k),
				Size = UDim2.fromOffset(4.6 * k, 4.6 * k),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
			}, box)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			table.insert(fills, dot)
		end
	else -- person
		local head = new("Frame", {
			Position = UDim2.fromOffset(4.6 * k, 0.8 * k),
			Size = UDim2.fromOffset(6.8 * k, 6.8 * k),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, box)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, head)
		table.insert(fills, head)
		local body = new("Frame", {
			Position = UDim2.fromOffset(2 * k, 9 * k),
			Size = UDim2.fromOffset(12 * k, 6.2 * k),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, box)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, body)
		table.insert(fills, body)
	end
	return {
		box = box,
		setColor = function(c)
			for _, f in ipairs(fills) do
				f.BackgroundColor3 = c
			end
			for _, st in ipairs(strokes) do
				st.Color = c
			end
		end,
	}
end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local WIN_W, WIN_H = 470, 336
local CONTENT_W = WIN_W - 72 - 28 -- usable width ng page content

local gui, window, winScale, glass, glassBg
local dragZone, minBtn, indicator
local tabButtons, tabLabels, tabIcons = {}, {}, {}
local pageHome, pageOutfit, pageChar, pageSet
local bar, status, applyBtn, resetBtn
local settingsBar, sStatus, saveBtn, unloadBtn
local statDot, statLabel

do
	local RAIL_W, BAR_H, PAGE_TOP, SHADOW = 72, 64, 56, 14

	gui = new("ScreenGui", {
		Name = "ClothingHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	gui.Parent = getGuiParent()

	-- Window: CanvasGroup (fade) -> shadow + glass (rounded clip)
	window = new("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(WIN_W + SHADOW * 2, WIN_H + SHADOW * 2),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
	}, gui)
	winScale = new("UIScale", { Scale = 1 }, window)

	-- soft shadow
	for i = 1, 6 do
		local g = i * 3
		local sh = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 5),
			Size = UDim2.fromOffset(WIN_W + g, WIN_H + g),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.84 + i * 0.025,
			BorderSizePixel = 0,
		}, window)
		new("UICorner", { CornerRadius = UDim.new(0, 30 + math.floor(g / 2)) }, sh)
	end

	glass = new("CanvasGroup", {
		Name = "Glass",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundTransparency = 1,
	}, window)
	new("UICorner", { CornerRadius = UDim.new(0, 30) }, glass)

	glassBg = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0 }, glass)
	glassFill(glassBg, S.glass)

	-- aurora glows (theme colors)
	local function aurora(second, size, cx, cy)
		local holder = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
		}, glass)
		for i = 1, 6 do
			local sc = 1 - (i - 1) * 0.17
			local layer = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(sc, 0, sc, 0),
				BackgroundColor3 = second and CONFIG.Accent2 or CONFIG.Accent,
				BackgroundTransparency = 0.95 - (i - 1) * 0.03,
				BorderSizePixel = 0,
			}, holder)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, layer)
			table.insert(second and theme.fills2 or theme.fills, layer)
		end
	end
	aurora(false, 300, 80, 30)
	aurora(true, 340, WIN_W - 50, WIN_H - 10)

	-- top shine
	local shine = new("Frame", {
		Position = UDim2.fromOffset(RAIL_W + 6, 4),
		Size = UDim2.new(1, -RAIL_W - 12, 0, 60),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, glass)
	new("UICorner", { CornerRadius = UDim.new(0, 22) }, shine)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.9, 1) }, shine)

	-- rim light (hiwalay na frame para hindi ma-clip ng canvas)
	local rim = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundTransparency = 1,
	}, window)
	new("UICorner", { CornerRadius = UDim.new(0, 30) }, rim)
	addRim(rim, 1.5, 0)

	-- Rail (kaliwa): logo + tabs
	local rail = new("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(0, RAIL_W - 8, 1, -16),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
	}, glass)
	new("UICorner", { CornerRadius = UDim.new(0, 22) }, rail)
	addRim(rail, 1, 0.5)

	local badge = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, rail)
	table.insert(theme.grads, new("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
	}, badge))
	new("UICorner", { CornerRadius = UDim.new(0, 13) }, badge)
	addRim(badge, 1, 0.3)
	local badgeIcon = makeIcon("hanger", badge, 22, WHITE)
	badgeIcon.box.AnchorPoint = Vector2.new(0.5, 0.5)
	badgeIcon.box.Position = UDim2.new(0.5, 0, 0.5, 1)

	indicator = new("Frame", {
		Position = UDim2.fromOffset(6, 64),
		Size = UDim2.fromOffset(52, 50),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, rail)
	table.insert(theme.grads, new("UIGradient", {
		Rotation = 35,
		Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
	}, indicator))
	new("UICorner", { CornerRadius = UDim.new(0, 16) }, indicator)
	addRim(indicator, 1, 0.35)

	for i, def in ipairs({ { "Home", "home" }, { "Outfit", "hanger" }, { "Character", "person" }, { "Settings", "sliders" } }) do
		local btn = new("TextButton", {
			Position = UDim2.fromOffset(6, 64 + (i - 1) * 56),
			Size = UDim2.fromOffset(52, 50),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
		}, rail)
		local ic = makeIcon(def[2], btn, 20, WHITE)
		ic.box.Position = UDim2.fromOffset(16, 6)
		local lab = new("TextLabel", {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.fromOffset(52, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = def[1],
			TextSize = 9,
			TextColor3 = WHITE,
		}, btn)
		tabButtons[i], tabLabels[i], tabIcons[i] = btn, lab, ic
	end

	-- Header (title + live stats + minimize)
	local header = new("Frame", {
		Position = UDim2.fromOffset(RAIL_W, 0),
		Size = UDim2.new(1, -RAIL_W, 0, 54),
		BackgroundTransparency = 1,
	}, glass)
	dragZone = new("Frame", {
		Size = UDim2.new(1, -170, 1, 0),
		BackgroundTransparency = 1,
		Active = true,
	}, header)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(6, 8),
		Size = UDim2.new(1, -6, 0, 22),
		Font = Enum.Font.GothamBlack,
		Text = CONFIG.Title,
		TextSize = 18,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, dragZone)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(6, 30),
		Size = UDim2.new(1, -6, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = "Wardrobe hub  ·  v" .. CONFIG.Version .. "  ·  by JAYVEE",
		TextSize = 10,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, dragZone)

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -50, 0.5, 0),
		Size = UDim2.fromOffset(118, 24),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
	}, header)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
	addRim(pill, 1, 0.5)
	statDot = new("Frame", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.fromRGB(120, 230, 150),
		BorderSizePixel = 0,
	}, pill)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, statDot)
	statLabel = new("TextLabel", {
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "-- fps  ·  -- ms",
		TextSize = 10,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, pill)

	minBtn = glassButton(header, "", UDim2.fromOffset(28, 28), UDim2.new(1, -40, 0.5, -14), false)
	minBtn.UICorner.CornerRadius = UDim.new(1, 0)
	local glyph = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 2),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, minBtn)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, glyph)

	-- Pages
	local function makePage(reserve)
		local pg = new("ScrollingFrame", {
			Position = UDim2.new(0, RAIL_W, 0, PAGE_TOP),
			Size = UDim2.new(1, -RAIL_W, 1, -(PAGE_TOP + reserve)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = WHITE,
			ScrollBarImageTransparency = 0.5,
			Visible = false,
		}, glass)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 10),
		}, pg)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }, pg)
		return pg
	end
	pageHome = makePage(8)
	pageOutfit = makePage(BAR_H)
	pageChar = makePage(BAR_H)
	pageSet = makePage(BAR_H)

	-- Action bars (Apply/Reset at Save/Unload)
	local function makeBar()
		local b = new("Frame", {
			Position = UDim2.new(0, RAIL_W, 1, -BAR_H),
			Size = UDim2.new(1, -RAIL_W, 0, BAR_H),
			BackgroundTransparency = 1,
			Visible = false,
		}, glass)
		new("Frame", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -28, 0, 1),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
		}, b)
		local row = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 1),
			Size = UDim2.fromOffset(240, 40),
			BackgroundTransparency = 1,
		}, b)
		local msg = new("TextLabel", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -272, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "Ready",
			TextSize = 11,
			TextColor3 = MUTED,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, b)
		return b, row, msg
	end
	local barRow, sBarRow
	bar, barRow, status = makeBar()
	applyBtn = glassButton(barRow, "Apply", UDim2.new(0.62, -4, 1, 0), UDim2.new(0.38, 4, 0, 0), true)
	resetBtn = glassButton(barRow, "Reset", UDim2.new(0.38, -4, 1, 0), UDim2.new(0, 0, 0, 0), false)

	settingsBar, sBarRow, sStatus = makeBar()
	saveBtn = glassButton(sBarRow, "Save", UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), true)
	unloadBtn = glassButton(sBarRow, "Unload", UDim2.new(0.5, -4, 1, 0), UDim2.new(0, 0, 0, 0), false)
	unloadBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 105)
	unloadBtn.BackgroundTransparency = 0.78
	unloadBtn.TextColor3 = Color3.fromRGB(255, 160, 170)
end

local function statusColor(kind)
	if kind == "ok" then
		return Color3.fromRGB(150, 230, 175)
	elseif kind == "err" then
		return Color3.fromRGB(255, 125, 125)
	end
	return MUTED
end

local function setStatus(text, kind)
	status.Text = text
	status.TextColor3 = statusColor(kind)
end

local function setSetStatus(text, kind)
	sStatus.Text = text
	sStatus.TextColor3 = statusColor(kind)
end

-- Row builders
local function sectionRow(parent, text, order, height)
	local row = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
	}, parent)
	local barMark = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 12),
		BackgroundColor3 = CONFIG.Accent,
		BorderSizePixel = 0,
	}, row)
	table.insert(theme.fills, barMark)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, barMark)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.6, -10, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(205, 212, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	return row
end

local function inputBox(parent, placeholder, order)
	local box = new("TextBox", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = placeholder,
		PlaceholderColor3 = MUTED,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, box)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, box)
	local stroke = addRim(box, 1, 0.35)
	box.Focused:Connect(function()
		play("Click")
		tween(box, { BackgroundTransparency = 0.78 }, 0.15)
		tween(stroke, { Color = CONFIG.Accent }, 0.15)
	end)
	box.FocusLost:Connect(function()
		tween(box, { BackgroundTransparency = 0.88 }, 0.2)
		tween(stroke, { Color = WHITE }, 0.2)
		box.Text = digits(box.Text)
	end)
	return box
end

-- RGB slider (0-255)
local function makeSlider(parent, y, labelText, channelColor, scroller, onChange)
	local row = new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
	}, parent)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 20),
		Font = Enum.Font.GothamBold,
		Text = labelText,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(205, 212, 230),
	}, row)
	local track = new("Frame", {
		Position = UDim2.new(0, 20, 0.5, -3),
		Size = UDim2.new(1, -64, 0, 6),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, row)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	new("UIGradient", { Color = ColorSequence.new(Color3.new(0, 0, 0), channelColor) }, track)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.7, Thickness = 1 }, knob)
	local valueLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -36, 0, 0),
		Size = UDim2.fromOffset(36, 20),
		Font = Enum.Font.GothamMedium,
		Text = "0",
		TextSize = 12,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local hit = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -8, 0.5, -12),
		Size = UDim2.new(1, 16, 0, 24),
	}, track)

	local value, dragging = 0, false
	local function setValue(v, fire)
		value = math.clamp(math.floor(v + 0.5), 0, 255)
		knob.Position = UDim2.new(value / 255, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		if fire and onChange then
			onChange(value)
		end
	end
	local function fromInput(pos)
		local a = (pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		setValue(math.clamp(a, 0, 1) * 255, true)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			if scroller then
				scroller.ScrollingEnabled = false -- para hindi mag-scroll habang nag-slide
			end
			fromInput(input.Position)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if scroller then
						scroller.ScrollingEnabled = true
					end
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input.Position)
		end
	end)

	return {
		Set = function(v)
			setValue(v, false)
		end,
	}
end

-- Color picker: presets + hex + R/G/B sliders
local function colorPicker(parent, order, presets, initial, scroller, onUserChange)
	local box = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 132),
		BackgroundTransparency = 1,
	}, parent)

	local cr = math.floor(initial.R * 255 + 0.5)
	local cg = math.floor(initial.G * 255 + 0.5)
	local cb = math.floor(initial.B * 255 + 0.5)
	local preview, hexBox, rS, gS, bS

	local function currentColor()
		return Color3.fromRGB(cr, cg, cb)
	end
	local function lightRender()
		preview.BackgroundColor3 = currentColor()
		hexBox.Text = string.format("#%02X%02X%02X", cr, cg, cb)
	end
	local function renderAll()
		lightRender()
		rS.Set(cr)
		gS.Set(cg)
		bS.Set(cb)
	end
	local function userSet(c)
		cr = math.floor(c.R * 255 + 0.5)
		cg = math.floor(c.G * 255 + 0.5)
		cb = math.floor(c.B * 255 + 0.5)
		renderAll()
		onUserChange(currentColor())
	end

	-- preset swatches
	for i, c in ipairs(presets) do
		local sw = new("TextButton", {
			Position = UDim2.fromOffset(math.floor((i - 1) * (CONTENT_W - 24 - 24) / (#presets - 1)), 0),
			Size = UDim2.fromOffset(24, 24),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = c,
			BorderSizePixel = 0,
		}, box)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
		addRim(sw, 1.5, 0.35)
		pressFX(sw)
		sw.MouseButton1Click:Connect(function()
			play("Click")
			userSet(c)
		end)
	end

	-- preview + hex
	preview = new("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = initial,
		BorderSizePixel = 0,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, preview)
	addRim(preview, 1.5, 0.3)

	hexBox = new("TextBox", {
		Position = UDim2.fromOffset(32, 32),
		Size = UDim2.fromOffset(92, 24),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = "#RRGGBB",
		PlaceholderColor3 = MUTED,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 13,
		ClearTextOnFocus = false,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, hexBox)
	addRim(hexBox, 1, 0.35)
	hexBox.Focused:Connect(function()
		play("Click")
	end)
	hexBox.FocusLost:Connect(function()
		local s = (hexBox.Text:gsub("[#%s]", ""))
		if #s == 6 and s:match("^%x+$") then
			cr = tonumber(s:sub(1, 2), 16)
			cg = tonumber(s:sub(3, 4), 16)
			cb = tonumber(s:sub(5, 6), 16)
			renderAll()
			onUserChange(currentColor())
		else
			renderAll()
		end
	end)

	-- sliders
	rS = makeSlider(box, 64, "R", Color3.fromRGB(255, 80, 80), scroller, function(v)
		cr = v
		lightRender()
		onUserChange(currentColor())
	end)
	gS = makeSlider(box, 88, "G", Color3.fromRGB(80, 230, 120), scroller, function(v)
		cg = v
		lightRender()
		onUserChange(currentColor())
	end)
	bS = makeSlider(box, 112, "B", Color3.fromRGB(80, 140, 255), scroller, function(v)
		cb = v
		lightRender()
		onUserChange(currentColor())
	end)
	renderAll()

	return {
		Get = currentColor,
		Set = function(c)
			cr = math.floor(c.R * 255 + 0.5)
			cg = math.floor(c.G * 255 + 0.5)
			cb = math.floor(c.B * 255 + 0.5)
			renderAll()
		end,
	}
end

------------------------------------------------------------
-- OUTFIT page
------------------------------------------------------------
local function groupCard(parent, order)
	local c = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 18) }, c)
	addRim(c, 1, 0.5)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}, c)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, c)
	return c
end
local cards = {}
local hooks = {} -- (live color preview, hooks para sa icon / settings)

cards.clothing = groupCard(pageOutfit, 1)
sectionRow(cards.clothing, "Clothing", 1, 16)
local shirtBox = inputBox(cards.clothing, "Shirt Id", 2)
local pantsBox = inputBox(cards.clothing, "Pants Id", 3)

cards.acc = groupCard(pageOutfit, 2)
local accRow = sectionRow(cards.acc, "Accessory", 1, 28)
local pager = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.fromOffset(112, 28),
	BackgroundTransparency = 1,
}, accRow)
local prevBtn = glassButton(pager, "<", UDim2.fromOffset(28, 28), UDim2.fromOffset(0, 0), false)
local curLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(28, 0),
	Size = UDim2.fromOffset(22, 28),
	Font = Enum.Font.GothamBold,
	Text = "1",
	TextSize = 14,
	TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Right,
}, pager)
new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(50, 0),
	Size = UDim2.fromOffset(8, 28),
	Font = Enum.Font.GothamBold,
	Text = "/",
	TextSize = 14,
	TextColor3 = MUTED,
}, pager)
local maxBox = new("TextBox", {
	Position = UDim2.fromOffset(58, 3),
	Size = UDim2.fromOffset(26, 22),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.82,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = tostring(CONFIG.Slots),
	TextColor3 = WHITE,
	TextSize = 13,
	ClearTextOnFocus = true,
}, pager)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, maxBox)
addRim(maxBox, 1, 0.3)
local nextBtn = glassButton(pager, ">", UDim2.fromOffset(28, 28), UDim2.fromOffset(84, 0), false)
prevBtn.UICorner.CornerRadius = UDim.new(1, 0)
nextBtn.UICorner.CornerRadius = UDim.new(1, 0)

local accBox = inputBox(cards.acc, "Accessory Id", 2)

------------------------------------------------------------
-- CHARACTER page
------------------------------------------------------------
cards.identity = groupCard(pageChar, 1)
cards.hair = groupCard(pageChar, 2)
cards.skin = groupCard(pageChar, 3)
sectionRow(cards.identity, "Character", 1, 16)
local headBox = inputBox(cards.identity, "Head Id", 2)
local faceBox = inputBox(cards.identity, "Face Id", 3)
local hairBox = inputBox(cards.identity, "Hair Id", 4)

local hairHdr = sectionRow(cards.hair, "Hair Color", 5, 24)
local hairSw = makeSwitch(hairHdr, false, function()
	if hooks.live then
		hooks.live("full")
	end
end)
local hairPicker = colorPicker(cards.hair, 6, CONFIG.HairPresets, Color3.fromRGB(74, 48, 32), pageChar, function()
	hairSw.Set(true) -- auto-on pag nag-edit ng kulay
	if hooks.live then
		hooks.live("color")
	end
end)

local solidRow = sectionRow(cards.hair, "Solid color", 7, 24)
local solidSw = makeSwitch(solidRow, true, function()
	if hooks.live then
		hooks.live("full")
	end
end)

local targetRow = sectionRow(cards.hair, "Hair target", 8, 28)
local tPager = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.fromOffset(160, 28),
	BackgroundTransparency = 1,
}, targetRow)
local tPrev = glassButton(tPager, "<", UDim2.fromOffset(28, 28), UDim2.fromOffset(0, 0), false)
local tLabel = new("TextLabel", {
	Position = UDim2.fromOffset(30, 0),
	Size = UDim2.fromOffset(100, 28),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Auto",
	TextSize = 12,
	TextColor3 = WHITE,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, tPager)
local tNext = glassButton(tPager, ">", UDim2.fromOffset(28, 28), UDim2.fromOffset(132, 0), false)
tPrev.UICorner.CornerRadius = UDim.new(1, 0)
tNext.UICorner.CornerRadius = UDim.new(1, 0)

-- Auto = hahanapin ng script ang buhok mo. Kung hindi nakita, pumili ka ng suot mong accessory.
local function cycleTarget(dir)
	local list, seen = { "Auto" }, {}
	local char = getChar()
	if char then
		for _, d in ipairs(char:GetChildren()) do
			if (d:IsA("Accessory") or d:IsA("Model")) and not d:GetAttribute("ClothingHub") and not seen[d.Name] then
				seen[d.Name] = true
				table.insert(list, d.Name)
			end
		end
	end
	local cur = 1
	for i, n in ipairs(list) do
		if n == (hooks.target or "Auto") then
			cur = i
		end
	end
	cur = ((cur - 1 + dir) % #list) + 1
	local name = list[cur]
	hooks.target = (name ~= "Auto") and name or nil
	tLabel.Text = name
	play("Click")
	if hooks.live then
		hooks.live("full")
	end
end
tPrev.MouseButton1Click:Connect(function()
	cycleTarget(-1)
end)
tNext.MouseButton1Click:Connect(function()
	cycleTarget(1)
end)

local skinHdr = sectionRow(cards.skin, "Skin Color", 9, 24)
local skinSw = makeSwitch(skinHdr, false, function()
	if hooks.live then
		hooks.live("full")
	end
end)
local skinPicker = colorPicker(cards.skin, 10, CONFIG.SkinPresets, Color3.fromRGB(255, 224, 189), pageChar, function()
	skinSw.Set(true)
	if hooks.live then
		hooks.live("color")
	end
end)

------------------------------------------------------------
-- HOME page (cards; live values are filled in later)
------------------------------------------------------------
local home = { v = {} }
do
	local GOOD = Color3.fromRGB(120, 230, 150)
	local TITLE = Color3.fromRGB(150, 200, 255)

	local function newCard(order, title)
		local c = new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
		}, pageHome)
		new("UICorner", { CornerRadius = UDim.new(0, 16) }, c)
		addRim(c, 1, 0.45)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, c)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, c)
		new("TextLabel", {
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = string.upper(title),
			TextSize = 11,
			TextColor3 = TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, c)
		return c
	end

	local function rowAdder(c, base)
		local n = base or 0
		return function(key, label)
			n = n + 1
			local row = new("Frame", {
				LayoutOrder = n,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
			}, c)
			new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.42, 0, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = label,
				TextSize = 12,
				TextColor3 = MUTED,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			local v = new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.42, 0, 0, 0),
				Size = UDim2.new(0.58, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "-",
				TextSize = 12,
				TextColor3 = WHITE,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
			home.v[key] = v
			return v, row
		end
	end

	-- hero (avatar + welcome)
	local hero = new("Frame", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	}, pageHome)
	new("UICorner", { CornerRadius = UDim.new(0, 18) }, hero)
	table.insert(theme.grads, new("UIGradient", {
		Rotation = 25,
		Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
	}, hero))
	addRim(hero, 1, 0.3)

	local av = new("Frame", {
		Position = UDim2.fromOffset(12, 13),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	}, hero)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	addRim(av, 1.5, 0.2)
	home.avatar = new("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
	}, av)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, home.avatar)

	new("TextLabel", {
		Position = UDim2.fromOffset(68, 10),
		Size = UDim2.new(1, -80, 0, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Welcome back,",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(225, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, hero)
	home.heroName = new("TextLabel", {
		Position = UDim2.fromOffset(68, 24),
		Size = UDim2.new(1, -80, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = LocalPlayer.DisplayName,
		TextSize = 17,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, hero)
	new("TextLabel", {
		Position = UDim2.fromOffset(68, 47),
		Size = UDim2.new(1, -80, 0, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "ClothingHub v" .. CONFIG.Version .. "  ·  by JAYVEE",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(225, 232, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, hero)

	-- FPS / PING tiles with mini graph
	local perf = new("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 88),
		BackgroundTransparency = 1,
	}, pageHome)
	local function tile(xScale, xOff, title)
		local t = new("Frame", {
			Position = UDim2.new(xScale, xOff, 0, 0),
			Size = UDim2.new(0.5, -4, 1, 0),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
		}, perf)
		new("UICorner", { CornerRadius = UDim.new(0, 16) }, t)
		addRim(t, 1, 0.45)
		new("TextLabel", {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.fromOffset(60, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = title,
			TextSize = 11,
			TextColor3 = TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, t)
		local stateLabel = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 8),
			Size = UDim2.fromOffset(60, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextSize = 11,
			TextColor3 = MUTED,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, t)
		local value = new("TextLabel", {
			Position = UDim2.fromOffset(12, 22),
			Size = UDim2.new(1, -24, 0, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "--",
			TextSize = 24,
			TextColor3 = WHITE,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, t)
		local holder = new("Frame", {
			Position = UDim2.new(0, 12, 0, 58),
			Size = UDim2.new(1, -24, 0, 22),
			BackgroundTransparency = 1,
		}, t)
		local bars = {}
		for i = 1, 20 do
			local bar = new("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, (i - 1) * 5, 1, 0),
				Size = UDim2.fromOffset(3, 2),
				BackgroundColor3 = WHITE,
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
			}, holder)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
			bars[i] = bar
		end
		return { value = value, state = stateLabel, bars = bars }
	end
	home.fps = tile(0, 0, "FPS")
	home.ping = tile(0.5, 4, "PING")

	-- script status
	local sc = newCard(3, "Script status")
	local addS = rowAdder(sc)
	local sv, srow = addS("status", "Status")
	sv.Size = UDim2.new(0.58, -14, 1, 0)
	home.dot = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = GOOD,
		BorderSizePixel = 0,
	}, srow)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, home.dot)
	TweenService:Create(
		home.dot,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundTransparency = 0.7 }
	):Play()
	addS("uptime", "Uptime")
	addS("outfit", "Outfit")
	addS("last", "Last action")
	addS("slots", "Accessories on")
	addS("key", "Menu key")

	-- player
	local pc = newCard(4, "Player")
	local addP = rowAdder(pc)
	for _, r in ipairs({
		{ "display", "Display name" }, { "user", "Username" }, { "uid", "User ID" },
		{ "age", "Account age" }, { "member", "Membership" }, { "rig", "Rig type" },
		{ "health", "Health" }, { "server", "Server" }, { "game", "Game" }, { "place", "Place ID" },
	}) do
		addP(r[1], r[2])
	end

	-- device
	local dc = newCard(5, "Device")
	local addD = rowAdder(dc)
	for _, r in ipairs({
		{ "device", "Device" }, { "os", "Platform" }, { "exec", "Executor" }, { "rbx", "Roblox" },
		{ "res", "Screen" }, { "input", "Input" }, { "mem", "Memory" }, { "gfx", "Graphics" },
	}) do
		addD(r[1], r[2])
	end

	-- author
	local ac = newCard(6, "Author")
	local big = new("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "JAYVEE",
		TextSize = 24,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ac)
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(10, 132, 255), Color3.fromRGB(255, 110, 200)),
	}, big)
	new("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Thanks for using ClothingHub!",
		TextSize = 11,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ac)
	local addA = rowAdder(ac, 2)
	local idx = 0
	for _, list in ipairs({ CONFIG.AuthorInfo or {}, CONFIG.AuthorExtra or {} }) do
		for _, r in ipairs(list) do
			idx = idx + 1
			addA("author" .. idx, tostring(r[1])).Text = tostring(r[2])
		end
	end

	-- debug scan (para makita kung ano talaga ang nakikita ng script)
	local dbg = newCard(7, "Debug scan")
	home.v.scan = new("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		Text = "...",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(205, 235, 255),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, dbg)
end

------------------------------------------------------------
-- SETTINGS page
------------------------------------------------------------
do
	local LABEL = Color3.fromRGB(205, 212, 230)
	local ctl = {}

	local function titledCard(order, title)
		local c = groupCard(pageSet, order)
		new("TextLabel", {
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = string.upper(title),
			TextSize = 10,
			TextColor3 = Color3.fromRGB(150, 200, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, c)
		return c
	end

	local function toggleRow(card, order, text, init, onChange)
		local row = new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, card)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.7, 0, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 12,
			TextColor3 = LABEL,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		return makeSwitch(row, init, onChange)
	end

	local function cycler(card, order, text, getText, onCycle)
		local row = new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, card)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, 0, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 12,
			TextColor3 = LABEL,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local pg = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(150, 28),
			BackgroundTransparency = 1,
		}, row)
		local prev = glassButton(pg, "<", UDim2.fromOffset(28, 28), UDim2.fromOffset(0, 0), false)
		local lab = new("TextLabel", {
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.fromOffset(90, 28),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = getText(),
			TextSize = 12,
			TextColor3 = WHITE,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, pg)
		local nxt = glassButton(pg, ">", UDim2.fromOffset(28, 28), UDim2.fromOffset(122, 0), false)
		prev.UICorner.CornerRadius = UDim.new(1, 0)
		nxt.UICorner.CornerRadius = UDim.new(1, 0)
		prev.MouseButton1Click:Connect(function()
			onCycle(-1)
			lab.Text = getText()
		end)
		nxt.MouseButton1Click:Connect(function()
			onCycle(1)
			lab.Text = getText()
		end)
		return lab
	end

	local function slider(card, order, text, minV, maxV, init, fmt, onChange, commitOnly)
		local row = new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, card)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.6, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 12,
			TextColor3 = LABEL,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local valLabel = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0.4, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "",
			TextSize = 12,
			TextColor3 = WHITE,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, row)
		local track = new("Frame", {
			Position = UDim2.new(0, 0, 0, 25),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
		}, row)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		table.insert(theme.grads, new("UIGradient", { Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2) }, fill))
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, track)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
		new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.7, Thickness = 1 }, knob)
		local hit = new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -8, 0.5, -14),
			Size = UDim2.new(1, 16, 0, 28),
		}, track)

		local value, dragging = init, false
		local function render(v)
			local a = (v - minV) / (maxV - minV)
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
			valLabel.Text = fmt(v)
		end
		local function fromInput(pos)
			local a = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			value = math.floor(minV + a * (maxV - minV) + 0.5)
			render(value)
			if not commitOnly then
				onChange(value)
			end
		end
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				pageSet.ScrollingEnabled = false
				fromInput(input.Position)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						pageSet.ScrollingEnabled = true
						if commitOnly then
							onChange(value)
						end
					end
				end)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				fromInput(input.Position)
			end
		end)
		render(init)
		return {
			Set = function(v)
				value = v
				render(v)
			end,
		}
	end

	local function pct(v)
		return v .. "%"
	end

	-- Appearance
	local cA = titledCard(1, "Appearance")
	local chipRow = new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, cA)
	local chips = {}
	local function refreshChips()
		for i, c in ipairs(chips) do
			c.Transparency = (i == S.theme) and 0 or 1
		end
	end
	local nThemes = #SET.themes
	for i, t in ipairs(SET.themes) do
		local chip = new("TextButton", {
			Position = UDim2.new((i - 1) / (nThemes - 1), -(i - 1) * 26 / (nThemes - 1), 0, 2),
			Size = UDim2.fromOffset(26, 26),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
		}, chipRow)
		new("UIGradient", { Rotation = 45, Color = ColorSequence.new(t[2], t[3]) }, chip)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
		chips[i] = new("UIStroke", { Color = WHITE, Thickness = 2, Transparency = 1 }, chip)
		pressFX(chip)
		chip.MouseButton1Click:Connect(function()
			S.theme = i
			play("Click")
			hooks.apply()
			refreshChips()
		end)
	end
	refreshChips()
	local sGlass = slider(cA, 2, "Glass opacity", 40, 100, math.floor((1 - S.glass) * 100 + 0.5), pct, function(v)
		S.glass = 1 - v / 100
		hooks.apply()
	end)
	local sScale = slider(cA, 3, "UI size", 70, 120, math.floor(S.scale * 100 + 0.5), pct, function(v)
		S.scale = v / 100
		hooks.apply()
	end, true)

	-- Sound
	local cS = titledCard(2, "Sound")
	local swSnd = toggleRow(cS, 1, "UI sounds", S.sounds, function(on)
		S.sounds = on
	end)
	local sVol = slider(cS, 2, "Volume", 0, 100, math.floor(S.volume * 100 + 0.5), pct, function(v)
		S.volume = v / 100
		hooks.apply()
	end)

	-- Icon & menu
	local cI = titledCard(3, "Icon and menu")
	local keyLabel = cycler(cI, 1, "Menu key", function()
		return S.menuKey
	end, function(dir)
		local idx = 1
		for i, k in ipairs(SET.keys) do
			if k == S.menuKey then
				idx = i
			end
		end
		idx = ((idx - 1 + dir) % #SET.keys) + 1
		S.menuKey = SET.keys[idx]
		play("Click")
		hooks.apply()
	end)
	local swIcon
	swIcon = toggleRow(cI, 2, "Floating icon", S.showIcon, function(on)
		if not on and not UserInputService.KeyboardEnabled then
			swIcon.Set(true)
			setSetStatus("Need a keyboard to reopen the menu", "err")
			play("Error")
			return
		end
		S.showIcon = on
		hooks.apply()
	end)
	local swDock = toggleRow(cI, 3, "Hide icon to edge", S.iconDocked, function(on)
		if on then
			hooks.dock()
		else
			hooks.undock()
		end
	end)
	local sIcon = slider(cI, 4, "Icon size", 40, 72, S.iconSize, function(v)
		return v .. " px"
	end, function(v)
		S.iconSize = v
		hooks.apply()
	end, true)

	-- Behavior
	local cB = titledCard(4, "Behavior")
	local swRe = toggleRow(cB, 1, "Re-apply after respawn", S.autoReapply, function(on)
		S.autoReapply = on
	end)
	local swAuto = toggleRow(cB, 2, "Auto-apply saved outfit", S.autoApplySaved, function(on)
		S.autoApplySaved = on
	end)
	local swLoad = toggleRow(cB, 3, "Show loading screen", S.loading, function(on)
		S.loading = on
	end)

	-- Actions
	local cX = groupCard(pageSet, 5)
	local resetS = glassButton(cX, "Reset to defaults", UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 0), false)
	resetS.LayoutOrder = 1
	new("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Save writes " .. SET.file .. " (outfit + settings) in your executor workspace.",
		TextSize = 10,
		TextColor3 = MUTED,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, cX)

	ctl.sync = function()
		refreshChips()
		sGlass.Set(math.floor((1 - S.glass) * 100 + 0.5))
		sScale.Set(math.floor(S.scale * 100 + 0.5))
		sVol.Set(math.floor(S.volume * 100 + 0.5))
		sIcon.Set(S.iconSize)
		keyLabel.Text = S.menuKey
		swSnd.Set(S.sounds)
		swIcon.Set(S.showIcon)
		swDock.Set(S.iconDocked)
		swRe.Set(S.autoReapply)
		swAuto.Set(S.autoApplySaved)
		swLoad.Set(S.loading)
	end
	resetS.MouseButton1Click:Connect(function()
		for k, v in pairs(SET.defaults) do
			S[k] = v
		end
		hooks.apply()
		ctl.sync()
		play("Click")
		setSetStatus("Defaults restored (press Save to keep)", "ok")
	end)

	saveBtn.MouseButton1Click:Connect(function()
		if hooks.save then
			hooks.save()
		end
	end)
	unloadBtn.MouseButton1Click:Connect(function()
		if hooks.unload then
			hooks.unload()
		end
	end)
end

------------------------------------------------------------
-- Floating icon
------------------------------------------------------------
local icon = new("TextButton", {
	Name = "Icon",
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.fromOffset(S.iconSize, S.iconSize),
	Position = UDim2.new(0, 10, 0.5, -math.floor(S.iconSize / 2)),
	BorderSizePixel = 0,
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.05,
	Visible = false,
}, gui)
do
	table.insert(theme.grads, new("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
	}, icon))
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, icon)
	addRim(icon, 1.5, 0)

	-- glossy highlight
	local gloss = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 3),
		Size = UDim2.new(0.78, 0, 0.45, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, icon)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, gloss)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.55, 1) }, gloss)

	-- pulsing glow ring
	local ring = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 8, 1, 8),
		BackgroundTransparency = 1,
	}, icon)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
	local ringStroke = new("UIStroke", { Color = CONFIG.Accent, Thickness = 2, Transparency = 0.4 }, ring)
	table.insert(theme.strokes, ringStroke)
	TweenService:Create(
		ringStroke,
		TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.92 }
	):Play()
	TweenService:Create(
		ring,
		TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = UDim2.new(1, 18, 1, 18) }
	):Play()

	-- logo: sarili mong image (CONFIG.IconImage) o default na hanger icon
	if CONFIG.IconImage and CONFIG.IconImage ~= "" then
		local img = new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.8, 0, 0.8, 0),
			BackgroundTransparency = 1,
			Image = CONFIG.IconImage,
			ScaleType = Enum.ScaleType.Fit,
		}, icon)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
	else
		local logo = makeIcon("hanger", icon, 30, WHITE)
		logo.box.AnchorPoint = Vector2.new(0.5, 0.5)
		logo.box.Position = UDim2.new(0.5, 0, 0.5, 1)
	end

	-- status dot: green kapag may naka-apply na outfit
	local dot = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = Color3.fromRGB(130, 140, 165),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, icon)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
	new("UIStroke", { Color = Color3.fromRGB(10, 14, 28), Thickness = 2 }, dot)
	hooks.iconDot = dot
	pressFX(icon)

	-- edge tab (lalabas kapag naka-hide yung icon; i-tap para ibalik)
	local edgeTab = new("TextButton", {
		Name = "IconTab",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(20, 68),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	table.insert(theme.grads, new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2),
	}, edgeTab))
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, edgeTab)
	addRim(edgeTab, 1, 0.3)
	local edgeArrow = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = ">",
		TextSize = 16,
		TextColor3 = WHITE,
	}, edgeTab)

	-- quick menu (long-press sa icon)
	local QW, QPAD, QBTN, QGAP = 160, 8, 30, 4
	local items = {
		{ "Hide icon", "hide" },
		{ "Apply outfit", "apply" },
		{ "Reset outfit", "reset" },
		{ "Open settings", "settings" },
	}
	local QH = QPAD * 2 + #items * QBTN + (#items - 1) * QGAP
	local catcher = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 20,
	}, gui)
	local quick = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(QW, QH),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 21,
	}, gui)
	glassFill(quick, 0.1)
	new("UICorner", { CornerRadius = UDim.new(0, 18) }, quick)
	addRim(quick, 1.2, 0.1)
	local qScale = new("UIScale", { Scale = 1 }, quick)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, QPAD),
		PaddingRight = UDim.new(0, QPAD),
		PaddingTop = UDim.new(0, QPAD),
		PaddingBottom = UDim.new(0, QPAD),
	}, quick)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, QGAP) }, quick)

	local function closeQuick()
		if not quick.Visible then
			return
		end
		tween(qScale, { Scale = 0.85 }, 0.12)
		task.delay(0.12, function()
			quick.Visible = false
			catcher.Visible = false
		end)
	end
	catcher.MouseButton1Click:Connect(closeQuick)

	for i, it in ipairs(items) do
		local b = glassButton(quick, it[1], UDim2.new(1, 0, 0, QBTN), UDim2.new(0, 0, 0, 0), it[2] == "apply")
		b.TextSize = 12
		b.LayoutOrder = i
		b.MouseButton1Click:Connect(function()
			closeQuick()
			if it[2] == "hide" then
				hooks.dock()
			elseif it[2] == "settings" then
				hooks.openTab(4)
			elseif hooks.act then
				hooks.act(it[2])
			end
		end)
	end

	hooks.quick = function()
		local ap, asz = icon.AbsolutePosition, icon.AbsoluteSize
		local vp = gui.AbsoluteSize
		local onLeft = (ap.X + asz.X / 2) < vp.X / 2
		local cx = onLeft and (ap.X + asz.X + 10 + QW / 2) or (ap.X - 10 - QW / 2)
		local cy = math.clamp(ap.Y + asz.Y / 2, QH / 2 + 8, math.max(QH / 2 + 8, vp.Y - QH / 2 - 8))
		quick.Position = UDim2.fromOffset(cx, cy)
		qScale.Scale = 0.85
		quick.Visible = true
		catcher.Visible = true
		tween(qScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		play("Open")
	end

	-- idikit sa pinakamalapit na gilid pagkatapos i-drag
	hooks.snap = function()
		local ap, asz = icon.AbsolutePosition, icon.AbsoluteSize
		local vp = gui.AbsoluteSize
		local left = (ap.X + asz.X / 2) < vp.X / 2
		local x = left and 10 or (vp.X - asz.X - 10)
		local y = math.clamp(ap.Y, 10, math.max(10, vp.Y - asz.Y - 10))
		tween(icon, { Position = UDim2.fromOffset(x, y) }, 0.3, Enum.EasingStyle.Back)
	end

	hooks.refreshIcon = function()
		local enabled = hooks.iconReady and S.showIcon
		icon.Size = UDim2.fromOffset(S.iconSize, S.iconSize)
		icon.Visible = enabled and not S.iconDocked
		edgeTab.Visible = enabled and S.iconDocked
	end

	hooks.dock = function()
		local ap, asz = icon.AbsolutePosition, icon.AbsoluteSize
		local vp = gui.AbsoluteSize
		local cy = ap.Y + asz.Y / 2
		local left = (ap.X + asz.X / 2) < vp.X / 2
		edgeTab.AnchorPoint = Vector2.new(left and 0 or 1, 0.5)
		edgeArrow.Text = left and ">" or "<"
		edgeTab.Position = UDim2.new(left and 0 or 1, left and -24 or 24, 0, cy)
		S.iconDocked = true
		hooks.refreshIcon()
		tween(edgeTab, { Position = UDim2.new(left and 0 or 1, 0, 0, cy) }, 0.35, Enum.EasingStyle.Back)
		play("Close")
	end

	hooks.undock = function()
		local left = edgeTab.AnchorPoint.X == 0
		local cy = edgeTab.AbsolutePosition.Y + edgeTab.AbsoluteSize.Y / 2
		local size = S.iconSize
		local vp = gui.AbsoluteSize
		icon.Position = UDim2.fromOffset(
			left and 10 or (vp.X - size - 10),
			math.clamp(cy - size / 2, 10, math.max(10, vp.Y - size - 10))
		)
		S.iconDocked = false
		hooks.refreshIcon()
		local isc = icon:FindFirstChildOfClass("UIScale")
		if isc then
			isc.Scale = 0
			tween(isc, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
		end
		play("Open")
	end
	edgeTab.MouseButton1Click:Connect(function()
		hooks.undock()
	end)
end

------------------------------------------------------------
-- Tabs / open / hide
------------------------------------------------------------
local currentTab = 1
local function setTab(i, silent)
	currentTab = i
	pageHome.Visible = (i == 1)
	pageOutfit.Visible = (i == 2)
	pageChar.Visible = (i == 3)
	pageSet.Visible = (i == 4)
	bar.Visible = (i == 2 or i == 3) -- Apply/Reset sa Outfit at Character lang
	settingsBar.Visible = (i == 4)
	tween(indicator, { Position = UDim2.fromOffset(6, 64 + (i - 1) * 56) }, 0.3, Enum.EasingStyle.Back)
	for j = 1, #tabButtons do
		local c = (j == i) and WHITE or MUTED
		tabLabels[j].TextColor3 = c
		tabIcons[j].setColor(c)
	end
	if i == 1 and home.update then
		pcall(home.update)
	end
	if not silent then
		play("Click")
	end
end
for i, b in ipairs(tabButtons) do
	b.MouseButton1Click:Connect(function()
		setTab(i)
	end)
end
setTab(1, true)

local isOpen = false
local fit = 1

-- paliitin automatic kung maliit ang screen
local function updateFit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	fit = math.clamp(math.min((vp.Y - 24) / WIN_H, (vp.X - 24) / WIN_W, 1), 0.5, 1) * S.scale
	if isOpen then
		winScale.Scale = fit
	end
end
do
	local cam = workspace.CurrentCamera
	if cam then
		connect(cam:GetPropertyChangedSignal("ViewportSize"), updateFit)
	end
	updateFit()
end

local function setOpen(open)
	if open == isOpen then
		return
	end
	isOpen = open
	if open then
		window.Visible = true
		window.GroupTransparency = 1
		winScale.Scale = fit * 0.86
		tween(window, { GroupTransparency = 0 }, 0.25)
		tween(winScale, { Scale = fit }, 0.4, Enum.EasingStyle.Back)
		play("Open")
		if currentTab == 1 and home.update then
			pcall(home.update)
		end
	else
		for _, tb in ipairs({ shirtBox, pantsBox, accBox, maxBox, headBox, faceBox, hairBox }) do
			tb:ReleaseFocus()
		end
		tween(window, { GroupTransparency = 1 }, 0.2)
		tween(winScale, { Scale = fit * 0.9 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		play("Close")
		task.delay(0.22, function()
			if not isOpen then
				window.Visible = false
			end
		end)
	end
end

local function toggle()
	setOpen(not isOpen)
end

minBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)
makeDraggable(icon, icon, toggle, function()
	hooks.snap()
end, function()
	hooks.quick()
end)
hooks.openTab = function(i)
	setTab(i)
	setOpen(true)
end
makeDraggable(dragZone, window)
connect(UserInputService.InputBegan, function(input, processed)
	if not processed and input.KeyCode == CONFIG.ToggleKey then
		toggle()
	end
end)

------------------------------------------------------------
-- Outfit logic
------------------------------------------------------------
local state = {
	shirt = "", pants = "", acc = {},
	head = "", face = "", hair = "",
	hairOn = false, hairColor = Color3.new(), solid = true,
	skinOn = false, skinColor = Color3.new(),
	applied = false,
}
local accIds = {}
local equipped = {}
local equippedHair = nil
local bk = setmetatable({}, { __mode = "k" }) -- per-character backups (para sa Reset)
local busy = false
local slot = 1
local slots = math.clamp(CONFIG.Slots, 1, CONFIG.MaxSlots)

local function getBk(char)
	if not bk[char] then
		bk[char] = { hairHidden = {}, hairColor = {} }
	end
	return bk[char]
end

local lastLoadErr = nil

local function loadAsset(id)
	lastLoadErr = nil
	local ok, res = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if ok and type(res) == "table" and res[1] then
		return res[1]
	end
	if not ok then
		lastLoadErr = tostring(res)
	end
	ok, res = pcall(function()
		return game:GetService("InsertService"):LoadAsset(tonumber(id))
	end)
	if ok and res then
		return res
	end
	if not ok and not lastLoadErr then
		lastLoadErr = tostring(res)
	end
	return nil
end

local function httpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end
	local req = (syn and syn.request) or request or http_request or (http and http.request)
	if req then
		ok, body = pcall(function()
			local res = req({ Url = url, Method = "GET" })
			return res and res.Body
		end)
		if ok and type(body) == "string" and #body > 0 then
			return body
		end
	end
	return nil
end

-- catalog shirt/pants id -> actual texture template
-- returns template, resolved  (resolved = true kung na-verify na valid yung ID)
local function resolveTemplate(id, className, prop, descProp)
	-- 1) game:GetObjects / LoadAsset
	local obj = loadAsset(id)
	if obj then
		local inst = (obj:IsA(className) and obj) or obj:FindFirstChildWhichIsA(className, true)
		local value = inst and inst[prop]
		obj:Destroy()
		if value and value ~= "" then
			return value, true
		end
	end
	-- 2) asset delivery XML via HttpGet
	local body = httpGet("https://assetdelivery.roblox.com/v1/asset/?id=" .. id)
	if body then
		local url = body:match("<url>%s*(.-)%s*</url>")
		if url and url ~= "" then
			return url, true
		end
		if body:sub(2, 4) == "PNG" or body:sub(1, 3) == "\255\216\255" then
			return "rbxassetid://" .. id, true -- texture id mismo yung nilagay mo
		end
	end
	-- 3) HumanoidDescription dummy
	local ok, template = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc[descProp] = tonumber(id)
		local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		local inst = model:FindFirstChildOfClass(className)
		local value = inst and inst[prop]
		model:Destroy()
		desc:Destroy()
		return value
	end)
	if ok and template and template ~= "" then
		return template, true
	end
	return "rbxassetid://" .. id, false
end

local function cleanAccessory(acc)
	acc:SetAttribute("ClothingHub", true) -- marka na galing sa script (hindi kasama sa Hair target list)
	for _, d in ipairs(acc:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local handle = acc:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		for _, c in ipairs(handle:GetChildren()) do
			if c:IsA("JointInstance") or c:IsA("WeldConstraint") then
				c:Destroy() -- weld galing sa ibang rig, aayusin pagka-attach
			end
		end
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true
	end
	return acc
end

local function loadAccessory(id)
	-- 1) GetObjects / LoadAsset
	local obj = loadAsset(id)
	if obj then
		local acc = (obj:IsA("Accessory") and obj) or obj:FindFirstChildWhichIsA("Accessory", true)
		if acc then
			if obj ~= acc then
				acc.Parent = nil
				obj:Destroy()
			end
			return cleanAccessory(acc)
		end
		obj:Destroy()
		lastLoadErr = "not an accessory ID"
	end
	-- 2) HumanoidDescription dummy (kung hindi gumana ang GetObjects)
	local ok, acc = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HatAccessory = tostring(id)
		local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		local a = model:FindFirstChildOfClass("Accessory")
		if a then
			a.Parent = nil
		end
		model:Destroy()
		desc:Destroy()
		return a
	end)
	if ok and acc then
		return cleanAccessory(acc)
	end
	return nil
end

-- siguraduhing naka-weld yung accessory sa katawan (kahit local lang)
local function ensureWeld(char, acc)
	local handle = acc:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		return
	end
	for _, c in ipairs(handle:GetChildren()) do
		if c:IsA("JointInstance") or c:IsA("WeldConstraint") then
			local p0 = c.Part0
			if p0 and p0:IsDescendantOf(char) then
				return -- may valid weld na
			end
			c:Destroy()
		end
	end
	for _, att in ipairs(handle:GetChildren()) do
		if att:IsA("Attachment") then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					local target = part:FindFirstChild(att.Name)
					if target and target:IsA("Attachment") then
						new("Weld", {
							Name = "AccessoryWeld",
							Part0 = part,
							Part1 = handle,
							C0 = target.CFrame,
							C1 = att.CFrame,
						}, handle)
						return
					end
				end
			end
		end
	end
	-- legacy hat (walang attachment)
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		new("Weld", {
			Name = "AccessoryWeld",
			Part0 = head,
			Part1 = handle,
			C0 = CFrame.new(0, head.Size.Y / 2, 0),
			C1 = acc.AttachmentPoint,
		}, handle)
	end
end

local function attachAccessory(char, hum, acc)
	pcall(function()
		hum:AddAccessory(acc)
	end)
	if acc.Parent ~= char then
		acc.Parent = char
	end
	pcall(ensureWeld, char, acc)
end

local function isOurAccessory(acc)
	if acc == equippedHair then
		return true
	end
	for _, a in pairs(equipped) do
		if a == acc then
			return true
		end
	end
	return false
end

------------------------------------------------------------
-- Head / Face
------------------------------------------------------------
local function applyHead(char, id)
	local head = char:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return false
	end
	local obj = loadAsset(id)
	if not obj then
		return false
	end
	local src = (obj:IsA("BasePart") and obj) or obj:FindFirstChild("Head", true)
	if not (src and src:IsA("BasePart")) then
		src = obj:FindFirstChildWhichIsA("BasePart", true)
	end

	local done = false
	if src then
		local b = getBk(char)
		local mesh = head:FindFirstChildOfClass("SpecialMesh")
		local srcMesh = src:FindFirstChildOfClass("SpecialMesh")
		if head:IsA("MeshPart") then
			-- R15 head
			if not b.head then
				b.head = { MeshPart = true, MeshId = head.MeshId, TextureID = head.TextureID, Size = head.Size }
			end
			if src:IsA("MeshPart") then
				done = pcall(function()
					head.MeshId = src.MeshId
					head.TextureID = src.TextureID
				end)
				pcall(function()
					head.Size = src.Size
				end)
			elseif srcMesh and srcMesh.MeshId ~= "" then
				done = pcall(function()
					head.MeshId = srcMesh.MeshId
					head.TextureID = srcMesh.TextureId
				end)
			end
		elseif mesh then
			-- R6 head
			if not b.head then
				b.head = {
					Mesh = mesh, MeshType = mesh.MeshType, MeshId = mesh.MeshId,
					TextureId = mesh.TextureId, Scale = mesh.Scale, Offset = mesh.Offset,
				}
			end
			if srcMesh then
				mesh.MeshType = srcMesh.MeshType
				mesh.MeshId = srcMesh.MeshId
				mesh.TextureId = srcMesh.TextureId
				mesh.Scale = srcMesh.Scale
				mesh.Offset = srcMesh.Offset
				done = true
			elseif src:IsA("MeshPart") then
				mesh.MeshType = Enum.MeshType.FileMesh
				mesh.MeshId = src.MeshId
				mesh.TextureId = src.TextureID
				mesh.Scale = Vector3.one
				mesh.Offset = Vector3.zero
				done = true
			end
		end
	end
	obj:Destroy()
	return done
end

local function restoreHead(char)
	local b = getBk(char)
	local h = b.head
	if not h then
		return
	end
	local head = char:FindFirstChild("Head")
	pcall(function()
		if h.MeshPart then
			head.MeshId = h.MeshId
			head.TextureID = h.TextureID
			head.Size = h.Size
		else
			local m = h.Mesh
			m.MeshType = h.MeshType
			m.MeshId = h.MeshId
			m.TextureId = h.TextureId
			m.Scale = h.Scale
			m.Offset = h.Offset
		end
	end)
	b.head = nil
end

local function applyFace(char, id)
	local head = char:FindFirstChild("Head")
	if not head then
		return false
	end
	local obj = loadAsset(id)
	local tex
	if obj then
		local decal = (obj:IsA("Decal") and obj) or obj:FindFirstChildWhichIsA("Decal", true)
		tex = decal and decal.Texture
		obj:Destroy()
	end
	tex = tex or ("rbxassetid://" .. id) -- fallback (texture id)

	local b = getBk(char)
	local face = head:FindFirstChild("face")
	if face and not face:IsA("Decal") then
		face = nil
	end
	if not face then
		face = head:FindFirstChildOfClass("Decal")
	end
	if not b.face then
		b.face = { Decal = face, Texture = face and face.Texture or nil }
	end
	if not face then
		face = new("Decal", { Name = "face", Face = Enum.NormalId.Front }, head)
		b.face.Decal = face
		b.face.Created = true
	end
	face.Texture = tex
	return true
end

local function restoreFace(char)
	local b = getBk(char)
	local f = b.face
	if not f then
		return
	end
	pcall(function()
		if f.Created then
			f.Decal:Destroy()
		elseif f.Decal then
			f.Decal.Texture = f.Texture
		end
	end)
	b.face = nil
end

------------------------------------------------------------
-- Hair + hair color
------------------------------------------------------------
local function isHairAccessory(acc)
	local ok, t = pcall(function()
		return acc.AccessoryType
	end)
	if ok and t == Enum.AccessoryType.Hair then
		return true
	end
	local h = acc:FindFirstChild("Handle")
	if h and h:FindFirstChild("HairAttachment") then
		return true
	end
	return string.find(string.lower(acc.Name), "hair", 1, true) ~= nil
end

local function originalHairs(char)
	local list = {}
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") and not isOurAccessory(acc) and isHairAccessory(acc) then
			table.insert(list, acc)
		end
	end
	return list
end

-- lahat ng pwedeng buhok: accessories (type Hair / HairAttachment / "hair" sa pangalan)
-- at mga Model/Part na may "hair" sa pangalan
local function hairTargets(char)
	local list, seen = {}, {}
	local function add(o)
		if not seen[o] then
			seen[o] = true
			table.insert(list, o)
		end
	end
	if equippedHair and equippedHair.Parent then
		add(equippedHair)
		return list
	end
	if state.hairTarget then
		for _, d in ipairs(char:GetChildren()) do
			if d.Name == state.hairTarget and not isOurAccessory(d)
				and (d:IsA("Accessory") or d:IsA("Model") or d:IsA("BasePart")) then
				add(d)
			end
		end
		if #list > 0 then
			return list
		end
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Accessory") then
			if not isOurAccessory(d) and isHairAccessory(d) then
				add(d)
			end
		elseif (d:IsA("Model") or d:IsA("BasePart"))
			and string.find(string.lower(d.Name), "hair", 1, true)
			and not d:FindFirstAncestorWhichIsA("Accessory") then
			add(d)
		end
	end
	return list
end

local function setHairHidden(char, hidden)
	local b = getBk(char)
	if hidden then
		for _, acc in ipairs(originalHairs(char)) do
			local h = acc:FindFirstChild("Handle")
			if h and h:IsA("BasePart") and b.hairHidden[acc] == nil then
				b.hairHidden[acc] = h.Transparency
				h.Transparency = 1
			end
		end
	else
		for acc, tr in pairs(b.hairHidden) do
			local h = acc:FindFirstChild("Handle")
			if h then
				h.Transparency = tr
			end
			b.hairHidden[acc] = nil
		end
	end
end

local hairInfo = { names = {}, parts = 0 } -- huling paint info (para sa status at Debug scan)

local function restoreHairColors(char)
	local b = getBk(char)
	for p, o in pairs(b.hairColor) do
		if o.conn then
			o.conn:Disconnect()
		end
		pcall(function()
			p.Color = o.Color
			if o.Material then
				p.Material = o.Material
			end
			if o.TextureID ~= nil then
				p.TextureID = o.TextureID
			end
			if o.SA then
				o.SA.Parent = p
			end
			if o.SM then
				o.SM.TextureId = o.SMTex
				o.SM.VertexColor = o.SMVC
			end
		end)
		b.hairColor[p] = nil
	end
end

-- returns kung ilang parts ang nakulayan
local function colorAccessory(char, obj, color, solid)
	local b = getBk(char)
	local parts = {}
	if obj:IsA("BasePart") then
		table.insert(parts, obj)
	end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, p in ipairs(parts) do
		local sm = p:FindFirstChildOfClass("SpecialMesh")
		local rec = b.hairColor[p]
		if not rec then
			rec = {
				Color = p.Color,
				Material = p.Material,
				TextureID = p:IsA("MeshPart") and p.TextureID or nil,
				SA = p:FindFirstChildOfClass("SurfaceAppearance"),
				SM = sm,
				SMTex = sm and sm.TextureId or nil,
				SMVC = sm and sm.VertexColor or nil,
			}
			b.hairColor[p] = rec
			-- kung ibalik ng game yung kulay, ibabalik natin agad
			rec.conn = p:GetPropertyChangedSignal("Color"):Connect(function()
				if state.hairOn and b.hairColor[p] and (state.solid or not sm) and p.Color ~= state.hairColor then
					p.Color = state.hairColor
				end
			end)
		end
		if solid or not sm then
			p.Color = color
		end
		if solid then
			pcall(function()
				p.Material = Enum.Material.SmoothPlastic
			end)
			if p:IsA("MeshPart") then
				pcall(function()
					p.TextureID = ""
				end)
			end
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				sa.Parent = nil -- reference naka-save sa backup para ma-restore
			end
			if sm then
				sm.TextureId = ""
			end
		end
		if sm then
			-- solid: Part color lang ang gagamitin (white vertex color) para hindi mag-double ang dilim
			sm.VertexColor = solid and Vector3.new(1, 1, 1) or Vector3.new(color.R, color.G, color.B)
		end
	end
	return #parts
end

local function applyHair(char, hum)
	if equippedHair then
		equippedHair:Destroy()
		equippedHair = nil
	end
	if state.hair == "" then
		setHairHidden(char, false)
		return true
	end
	local acc = loadAccessory(state.hair)
	if not acc then
		return false
	end
	setHairHidden(char, true) -- itago muna yung original hair
	attachAccessory(char, hum, acc)
	equippedHair = acc
	return true
end

-- light = true -> huwag munang i-restore (para sa live slider, walang flicker)
local function applyHairColor(char, light)
	if not light then
		restoreHairColors(char)
	end
	hairInfo.names, hairInfo.parts = {}, 0
	if not state.hairOn then
		return 0
	end
	local count = 0
	for _, obj in ipairs(hairTargets(char)) do
		count = count + colorAccessory(char, obj, state.hairColor, state.solid)
		table.insert(hairInfo.names, obj.Name)
	end
	hairInfo.parts = count
	return count
end

------------------------------------------------------------
-- Skin color
------------------------------------------------------------
local BODY_PARTS = {
	"Head", "Torso", "UpperTorso", "LowerTorso",
	"Left Arm", "Right Arm", "Left Leg", "Right Leg",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local BC_PROPS = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }

local function restoreSkin(char)
	local b = getBk(char)
	local s = b.skin
	if not s then
		return
	end
	for p, c in pairs(s.parts) do
		pcall(function()
			p.Color = c
		end)
	end
	pcall(function()
		if s.createdBC then
			s.bcInst:Destroy()
		elseif s.bc then
			for k, v in pairs(s.bc) do
				s.bcInst[k] = v
			end
		end
	end)
	b.skin = nil
end

local function applySkin(char)
	local b = getBk(char)
	if not state.skinOn then
		restoreSkin(char)
		return
	end
	if not b.skin then
		b.skin = { parts = {} }
		local bc = char:FindFirstChildOfClass("BodyColors")
		if bc then
			b.skin.bcInst = bc
			b.skin.bc = {}
			for _, k in ipairs(BC_PROPS) do
				b.skin.bc[k] = bc[k]
			end
		else
			bc = new("BodyColors", {}, char)
			b.skin.bcInst = bc
			b.skin.createdBC = true
		end
		for _, n in ipairs(BODY_PARTS) do
			local p = char:FindFirstChild(n)
			if p and p:IsA("BasePart") then
				b.skin.parts[p] = p.Color
			end
		end
	end
	local c = state.skinColor
	local bc = b.skin.bcInst
	if bc and bc.Parent then
		for _, k in ipairs(BC_PROPS) do
			bc[k] = c
		end
	end
	for p in pairs(b.skin.parts) do
		p.Color = c
	end
end

------------------------------------------------------------
-- Apply / Reset
------------------------------------------------------------
local function restoreClothing(char, className, prop, orig)
	local obj = char:FindFirstChildOfClass(className)
	if obj then
		if orig then
			obj[prop] = orig
		else
			obj:Destroy()
		end
	end
end

-- binabantayan yung shirt/pants + buhok (kung may game script na nagre-reset o late mag-load)
local function startEnforcer(char)
	local b = getBk(char)
	if b.enforcer then
		return
	end
	b.enforcer = true
	task.spawn(function()
		while char.Parent and gui.Parent do
			task.wait(1)
			if not state.applied then
				break
			end
			pcall(function()
				for _, def in ipairs({
					{ "Shirt", "ShirtTemplate", b.shirtTpl },
					{ "Pants", "PantsTemplate", b.pantsTpl },
				}) do
					local className, prop, want = def[1], def[2], def[3]
					if want then
						local obj = char:FindFirstChildOfClass(className)
						if not obj then
							obj = new(className, { Name = className }, char)
						end
						if obj[prop] ~= want then
							obj[prop] = want
						end
						for _, c in ipairs(char:GetChildren()) do
							if c:IsA(className) and c ~= obj then
								c:Destroy()
							end
						end
					end
				end
				if state.hairOn then
					applyHairColor(char, true)
				end
				-- accessories na natanggal ng game, ibalik
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					b.retry = b.retry or {}
					for i, a in pairs(equipped) do
						local id = state.acc[i]
						if a.Parent ~= char and id and id ~= "" and (b.retry[i] or 0) < 3 then
							b.retry[i] = (b.retry[i] or 0) + 1
							local fresh = loadAccessory(id)
							if fresh then
								attachAccessory(char, hum, fresh)
								equipped[i] = fresh
							end
						end
					end
				end
			end)
		end
		b.enforcer = nil
	end)
end

local function applyToCharacter(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return 0, 0, { "No humanoid found" }
	end
	local b = getBk(char)
	local okCount, failCount, notes = 0, 0, {}
	b.retry = {}
	local function tally(ok, note)
		if ok then
			okCount = okCount + 1
		else
			failCount = failCount + 1
			if note then
				table.insert(notes, note)
			end
		end
	end
	local function try(fn, ...)
		local ok, res = pcall(fn, ...)
		return ok and res
	end

	-- clothing (save originals first)
	if b.shirt == nil then
		local s = char:FindFirstChildOfClass("Shirt")
		local p = char:FindFirstChildOfClass("Pants")
		b.shirt = s and s.ShirtTemplate or false
		b.pants = p and p.PantsTemplate or false
	end
	local function clothing(id, className, prop, key, label)
		if id ~= "" then
			local ok, tpl, resolved = pcall(resolveTemplate, id, className, prop, className)
			if ok and tpl then
				local obj = char:FindFirstChildOfClass(className) or new(className, { Name = className }, char)
				obj[prop] = tpl
				b[key] = tpl
			end
			tally(ok and resolved, label .. " ID not found")
		elseif b[key] then
			b[key] = nil
			local orig
			if className == "Shirt" then
				orig = b.shirt
			else
				orig = b.pants
			end
			restoreClothing(char, className, prop, orig)
		end
	end
	clothing(state.shirt, "Shirt", "ShirtTemplate", "shirtTpl", "Shirt")
	clothing(state.pants, "Pants", "PantsTemplate", "pantsTpl", "Pants")

	-- accessories
	for i = 1, CONFIG.MaxSlots do
		if equipped[i] then
			equipped[i]:Destroy()
			equipped[i] = nil
		end
		local id = state.acc[i]
		if id and id ~= "" then
			local acc = loadAccessory(id)
			if acc then
				attachAccessory(char, hum, acc)
				equipped[i] = acc
				tally(true)
			else
				tally(false, "Acc " .. i .. ": " .. string.sub(lastLoadErr or "can't load ID", 1, 36))
			end
		end
	end

	-- character
	if state.head ~= "" then
		tally(try(applyHead, char, state.head), "Head can't be applied")
	else
		pcall(restoreHead, char)
	end
	if state.face ~= "" then
		tally(try(applyFace, char, state.face), "Face can't load")
	else
		pcall(restoreFace, char)
	end
	if state.hair ~= "" then
		tally(try(applyHair, char, hum), "Hair: " .. string.sub(lastLoadErr or "can't load ID", 1, 36))
	else
		pcall(applyHair, char, hum)
	end
	local okp, painted = pcall(applyHairColor, char)
	if state.hairOn then
		tally(okp and painted and painted > 0, okp and "No hair found - set Hair target" or ("Hair error: " .. string.sub(tostring(painted), 1, 30)))
	end
	pcall(applySkin, char)
	if state.skinOn then
		tally(true)
	end

	if state.applied then
		startEnforcer(char)
	end
	return okCount, failCount, notes
end

local function saveSlot()
	accIds[slot] = digits(accBox.Text)
end

local function refreshSlot()
	curLabel.Text = tostring(slot)
	maxBox.Text = tostring(slots)
	accBox.Text = accIds[slot] or ""
end

local function setSlots(n)
	saveSlot()
	slots = math.clamp(n, 1, CONFIG.MaxSlots)
	if slot > slots then
		slot = slots
	end
	refreshSlot()
end

local function changeSlot(dir)
	saveSlot()
	slot = ((slot - 1 + dir) % slots) + 1
	refreshSlot()
	play("Click")
end

maxBox.Focused:Connect(function()
	play("Click")
end)
maxBox.FocusLost:Connect(function()
	local n = tonumber(digits(maxBox.Text))
	if n and n >= 1 then
		setSlots(n)
		if n > CONFIG.MaxSlots then
			setStatus("Max is " .. CONFIG.MaxSlots .. " slots", "err")
		end
	else
		refreshSlot()
	end
end)

local function applyAll()
	if busy then
		return
	end
	local char = getChar()
	if not (char and char:FindFirstChildOfClass("Humanoid")) then
		setStatus("No character found", "err")
		play("Error")
		return
	end

	saveSlot()
	state.shirt = digits(shirtBox.Text)
	state.pants = digits(pantsBox.Text)
	state.head = digits(headBox.Text)
	state.face = digits(faceBox.Text)
	state.hair = digits(hairBox.Text)
	state.hairOn = hairSw.Get()
	state.hairColor = hairPicker.Get()
	state.solid = solidSw.Get()
	state.skinOn = skinSw.Get()
	state.skinColor = skinPicker.Get()
	state.hairTarget = hooks.target
	state.acc = {}

	local any = state.shirt ~= "" or state.pants ~= "" or state.head ~= ""
		or state.face ~= "" or state.hair ~= "" or state.hairOn or state.skinOn
	for i = 1, slots do
		state.acc[i] = accIds[i] or ""
		if state.acc[i] ~= "" then
			any = true
		end
	end
	if not any then
		setStatus("Enter an ID or pick a color first", "err")
		play("Error")
		return
	end

	busy = true
	state.applied = true
	setStatus("Applying...")
	play("Click")
	task.spawn(function()
		local good, okCount, failCount, notes = pcall(applyToCharacter, char)
		busy = false
		if not good then
			setStatus("Something went wrong", "err")
			play("Error")
		elseif failCount > 0 then
			setStatus("Applied " .. okCount .. " | " .. ((notes and notes[1]) or (failCount .. " failed")), "err")
			play("Error")
		else
			setStatus("Applied " .. okCount .. " item(s)", "ok")
			play("Success")
		end
	end)
end

local function resetAll()
	state.applied = false
	for i, acc in pairs(equipped) do
		acc:Destroy()
		equipped[i] = nil
	end
	if equippedHair then
		equippedHair:Destroy()
		equippedHair = nil
	end
	local char = getChar()
	local b = char and bk[char]
	if char and b then
		b.shirtTpl = nil
		b.pantsTpl = nil
		if b.shirt ~= nil then
			local s = char:FindFirstChildOfClass("Shirt")
			if s then
				if b.shirt then
					s.ShirtTemplate = b.shirt
				else
					s:Destroy()
				end
			end
			local p = char:FindFirstChildOfClass("Pants")
			if p then
				if b.pants then
					p.PantsTemplate = b.pants
				else
					p:Destroy()
				end
			end
		end
		pcall(restoreHead, char)
		pcall(restoreFace, char)
		pcall(restoreHairColors, char)
		pcall(setHairHidden, char, false)
		pcall(restoreSkin, char)
	end
	setStatus("Back to original", "ok")
	play("Click")
end

prevBtn.MouseButton1Click:Connect(function()
	changeSlot(-1)
end)
nextBtn.MouseButton1Click:Connect(function()
	changeSlot(1)
end)
applyBtn.MouseButton1Click:Connect(applyAll)
resetBtn.MouseButton1Click:Connect(resetAll)

-- re-apply automatically after respawn
connect(LocalPlayer.CharacterAdded, function(char)
	table.clear(equipped)
	equippedHair = nil
	if not state.applied or not S.autoReapply then
		return
	end
	char:WaitForChild("Humanoid", 10)
	task.wait(1.5) -- let the game's own appearance load first
	task.spawn(applyToCharacter, char)
end)

------------------------------------------------------------
-- Settings logic (apply / collect / load)
------------------------------------------------------------
hooks.iconReady = false

do
	local function col2t(c)
		return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
	end
	local function t2col(t, fallback)
		if type(t) == "table" and #t >= 3 then
			return Color3.fromRGB(
				math.clamp(tonumber(t[1]) or 0, 0, 255),
				math.clamp(tonumber(t[2]) or 0, 0, 255),
				math.clamp(tonumber(t[3]) or 0, 0, 255)
			)
		end
		return fallback
	end

	hooks.collect = function()
		saveSlot()
		local acc = {}
		for i = 1, CONFIG.MaxSlots do
			if accIds[i] and accIds[i] ~= "" then
				acc[tostring(i)] = accIds[i]
			end
		end
		return {
			shirt = digits(shirtBox.Text),
			pants = digits(pantsBox.Text),
			head = digits(headBox.Text),
			face = digits(faceBox.Text),
			hair = digits(hairBox.Text),
			acc = acc,
			slots = slots,
			hairOn = hairSw.Get(),
			solid = solidSw.Get(),
			hairColor = col2t(hairPicker.Get()),
			skinOn = skinSw.Get(),
			skinColor = col2t(skinPicker.Get()),
			hairTarget = hooks.target,
		}
	end

	hooks.loadOutfit = function(d)
		if type(d) ~= "table" then
			return
		end
		shirtBox.Text = digits(d.shirt)
		pantsBox.Text = digits(d.pants)
		headBox.Text = digits(d.head)
		faceBox.Text = digits(d.face)
		hairBox.Text = digits(d.hair)
		table.clear(accIds)
		if type(d.acc) == "table" then
			for k, v in pairs(d.acc) do
				local i = tonumber(k)
				if i and i >= 1 and i <= CONFIG.MaxSlots then
					accIds[i] = digits(v)
				end
			end
		end
		if type(d.slots) == "number" then
			slots = math.clamp(math.floor(d.slots), 1, CONFIG.MaxSlots)
		end
		slot = 1
		refreshSlot()
		hairPicker.Set(t2col(d.hairColor, hairPicker.Get()))
		skinPicker.Set(t2col(d.skinColor, skinPicker.Get()))
		hairSw.Set(d.hairOn == true)
		solidSw.Set(d.solid ~= false)
		skinSw.Set(d.skinOn == true)
		hooks.target = (type(d.hairTarget) == "string") and d.hairTarget or nil
		tLabel.Text = hooks.target or "Auto"
	end

	hooks.apply = function()
		local t = SET.themes[S.theme] or SET.themes[1]
		CONFIG.Accent, CONFIG.Accent2 = t[2], t[3]
		theme.apply()
		glassBg.BackgroundTransparency = S.glass
		updateFit()
		for _, snd in pairs(sounds) do
			snd.Volume = S.volume
		end
		local okk, kc = pcall(function()
			return Enum.KeyCode[S.menuKey]
		end)
		if okk and kc then
			CONFIG.ToggleKey = kc
		end
		if hooks.refreshIcon then
			hooks.refreshIcon()
		end
	end

	hooks.act = function(name)
		if name == "apply" then
			applyAll()
		elseif name == "reset" then
			resetAll()
		end
	end
end

------------------------------------------------------------
-- Live color preview + HOME logic + startup loading screen
------------------------------------------------------------
local loadGui, blurFx, runLoading, destroyed = nil, nil, nil, false

-- live preview ng hair/skin color (hindi na kailangan pindutin ang Apply)
local liveQueued, liveKind = false, "color"
hooks.live = function(kind)
	if kind == "full" then
		liveKind = "full"
	end
	if liveQueued then
		return
	end
	liveQueued = true
	task.defer(function()
		liveQueued = false
		local full = (liveKind == "full")
		liveKind = "color"
		local char = getChar()
		if not (char and char:FindFirstChildOfClass("Humanoid")) then
			return
		end
		state.hairOn = hairSw.Get()
		state.hairColor = hairPicker.Get()
		state.solid = solidSw.Get()
		state.skinOn = skinSw.Get()
		state.skinColor = skinPicker.Get()
		state.hairTarget = hooks.target
		if state.hairOn or state.skinOn then
			state.applied = true
		end
		local ok, count = pcall(applyHairColor, char, not full)
		pcall(applySkin, char)
		if state.hairOn then
			startEnforcer(char)
			if not ok then
				setStatus("Hair error: " .. string.sub(tostring(count), 1, 40), "err")
			elseif count == 0 then
				setStatus("No hair found - set Hair target", "err")
			else
				setStatus("Hair color: " .. (hairInfo.names[1] or "hair") .. " (" .. count .. " parts)", "ok")
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local StatsService = game:GetService("Stats")
	local MarketplaceService = game:GetService("MarketplaceService")
	local GOOD, WARN, BAD = Color3.fromRGB(120, 230, 150), Color3.fromRGB(255, 205, 90), Color3.fromRGB(255, 110, 110)
	local startClock = os.clock()
	local fpsHist, pingHist = {}, {}
	local lastFps, lastPing = 0, 0
	local gameName = nil

	local function push(hist, v)
		table.insert(hist, v)
		if #hist > 20 then
			table.remove(hist, 1)
		end
	end

	local function readPing()
		local ok, v = pcall(function()
			return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and type(v) == "number" then
			return v
		end
		ok, v = pcall(function()
			return LocalPlayer:GetNetworkPing() * 1000
		end)
		if ok and type(v) == "number" then
			return v
		end
		return 0
	end

	local function deviceType()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local touch = UserInputService.TouchEnabled
		local kb = UserInputService.KeyboardEnabled
		if touch and not kb then
			return (math.min(vp.X, vp.Y) >= 600) and "Tablet" or "Phone"
		elseif UserInputService.GamepadEnabled and not kb and not touch then
			return "Console"
		end
		return "PC"
	end

	local function executorName()
		local ok, name, ver = pcall(function()
			if identifyexecutor then
				return identifyexecutor()
			end
		end)
		if ok and name then
			return tostring(name) .. (ver and (" " .. tostring(ver)) or "")
		end
		return "Unknown"
	end

	local function inputTypes()
		local t = {}
		if UserInputService.TouchEnabled then
			table.insert(t, "Touch")
		end
		if UserInputService.KeyboardEnabled then
			table.insert(t, "Keyboard")
		end
		if UserInputService.MouseEnabled then
			table.insert(t, "Mouse")
		end
		if UserInputService.GamepadEnabled then
			table.insert(t, "Gamepad")
		end
		return #t > 0 and table.concat(t, " + ") or "Unknown"
	end

	local platformName = "Unknown"
	pcall(function()
		platformName = UserInputService:GetPlatform().Name
	end)
	local execName = executorName()
	local rbxVersion = "-"
	pcall(function()
		rbxVersion = version()
	end)
	local graphicsText = "-"
	pcall(function()
		local q = UserSettings():GetService("UserGameSettings").SavedQualityLevel
		graphicsText = (q.Name:gsub("QualityLevel", "Level "))
	end)

	local function fmtTime(sec)
		sec = math.floor(sec)
		return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
	end

	local function renderBars(tileObj, hist, maxV, color)
		local n = #hist
		for i = 1, 20 do
			local bar = tileObj.bars[i]
			local val = hist[i - (20 - n)]
			if val then
				bar.Size = UDim2.fromOffset(3, math.max(2, math.floor(math.clamp(val / maxV, 0, 1) * 22)))
				bar.BackgroundColor3 = color
				bar.BackgroundTransparency = 0.1
			else
				bar.Size = UDim2.fromOffset(3, 2)
				bar.BackgroundColor3 = WHITE
				bar.BackgroundTransparency = 0.8
			end
		end
	end

	local function updateHome()
		local v = home.v

		-- FPS / ping
		local fcol = lastFps >= 50 and GOOD or (lastFps >= 30 and WARN or BAD)
		home.fps.value.Text = tostring(lastFps)
		home.fps.value.TextColor3 = fcol
		home.fps.state.Text = lastFps >= 50 and "Smooth" or (lastFps >= 30 and "OK" or "Laggy")
		renderBars(home.fps, fpsHist, 90, fcol)
		local pcol = lastPing <= 80 and GOOD or (lastPing <= 150 and WARN or BAD)
		home.ping.value.Text = string.format("%d ms", lastPing)
		home.ping.value.TextColor3 = pcol
		home.ping.state.Text = lastPing <= 80 and "Great" or (lastPing <= 150 and "OK" or "High")
		renderBars(home.ping, pingHist, 300, pcol)

		-- script status
		v.status.Text = busy and "Applying..." or "Online"
		home.dot.BackgroundColor3 = busy and WARN or GOOD
		v.uptime.Text = fmtTime(os.clock() - startClock)
		v.outfit.Text = state.applied and "Applied" or "Not applied"
		v.outfit.TextColor3 = state.applied and GOOD or WHITE
		v.last.Text = status.Text
		local n = 0
		for _ in pairs(equipped) do
			n = n + 1
		end
		v.slots.Text = n .. " / " .. slots
		v.key.Text = CONFIG.ToggleKey.Name

		-- player
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		v.display.Text = LocalPlayer.DisplayName
		v.user.Text = "@" .. LocalPlayer.Name
		v.uid.Text = tostring(LocalPlayer.UserId)
		v.age.Text = LocalPlayer.AccountAge .. " days"
		v.member.Text = LocalPlayer.MembershipType.Name
		v.rig.Text = hum and hum.RigType.Name or "-"
		v.health.Text = hum
			and string.format("%d / %d", math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5))
			or "-"
		v.server.Text = string.format("%d / %d players", #Players:GetPlayers(), Players.MaxPlayers)
		v.game.Text = gameName or "..."
		v.place.Text = tostring(game.PlaceId)

		-- device
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(0, 0)
		v.device.Text = deviceType()
		v.os.Text = platformName
		v.exec.Text = execName
		v.rbx.Text = rbxVersion
		v.res.Text = string.format("%d x %d", math.floor(vp.X), math.floor(vp.Y))
		v.input.Text = inputTypes()
		local okm, mem = pcall(function()
			return StatsService:GetTotalMemoryUsageMb()
		end)
		v.mem.Text = okm and string.format("%d MB", math.floor(mem)) or "-"
		v.gfx.Text = graphicsText

		-- debug scan
		local dchar = getChar()
		local dl = {}
		if dchar then
			local dh = dchar:FindFirstChildOfClass("Humanoid")
			table.insert(dl, "Char: " .. dchar.Name .. " (" .. (dh and dh.RigType.Name or "?") .. ")"
				.. (dchar == LocalPlayer.Character and "" or " [camera subject]"))
			local names = {}
			for _, d in ipairs(dchar:GetChildren()) do
				if d:IsA("Accessory") then
					table.insert(names, d.Name .. (isHairAccessory(d) and " [hair]" or ""))
				end
			end
			table.insert(dl, "Acc (" .. #names .. "): " .. (#names > 0 and table.concat(names, ", ") or "none"))
		else
			table.insert(dl, "Char: not found")
		end
		table.insert(dl, "Hair paint: " .. (state.hairOn
			and (hairInfo.parts .. " parts / " .. #hairInfo.names .. " obj") or "off"))
		v.scan.Text = table.concat(dl, "\n")
	end
	home.update = updateHome

	function home.loadProfile()
		pcall(function()
			home.avatar.Image = Players:GetUserThumbnailAsync(
				LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
			)
		end)
		pcall(function()
			gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
		end)
	end

	-- FPS counter (every 0.5s)
	local frames, acc = 0, 0
	connect(RunService.RenderStepped, function(dt)
		frames = frames + 1
		acc = acc + dt
		if acc >= 0.5 then
			lastFps = math.floor(frames / acc + 0.5)
			lastPing = math.floor(readPing() + 0.5)
			frames, acc = 0, 0
			push(fpsHist, lastFps)
			push(pingHist, lastPing)
			if isOpen then
				statLabel.Text = string.format("%d fps  ·  %d ms", lastFps, lastPing)
				statDot.BackgroundColor3 = (lastFps >= 50 and GOOD) or (lastFps >= 30 and WARN) or BAD
			end
			if hooks.iconDot then
				hooks.iconDot.BackgroundColor3 = state.applied and GOOD or Color3.fromRGB(130, 140, 165)
			end
			if isOpen and currentTab == 1 then
				pcall(updateHome)
			end
		end
	end)

	----------------------------------------------------------
	-- Startup loading screen (Watch Dogs style)
	----------------------------------------------------------
	runLoading = function(onDone)
		task.spawn(function()
			local finished = false
			local function finish()
				if finished or destroyed then
					return
				end
				finished = true
				onDone()
			end
			local loopConn

			local ok, err = pcall(function()
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				local DW, DH = 640, 340
				local base = math.clamp(math.min((vp.X - 24) / DW, (vp.Y - 24) / DH, 1.25), 0.45, 1.25)
				local function kp(t, val)
					return NumberSequenceKeypoint.new(t, val)
				end
				local BG = Color3.fromRGB(3, 6, 14)
				local ICE = Color3.fromRGB(205, 235, 255)
				local BLUE = Color3.fromRGB(70, 170, 255)
				local DIM = Color3.fromRGB(110, 135, 165)
				local RED = Color3.fromRGB(255, 45, 85)
				local CYAN = Color3.fromRGB(0, 255, 240)
				local GREEN = Color3.fromRGB(120, 255, 170)
				local CODE = Enum.Font.Code
				local LEFT, RIGHT, CENTER = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center

				loadGui = new("ScreenGui", {
					Name = "ClothingHubLoader",
					ResetOnSpawn = false,
					IgnoreGuiInset = true,
					DisplayOrder = 1000,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				})
				loadGui.Parent = getGuiParent()

				local fadeBg, fadeText = {}, {}
				local bg = new("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = BG,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ClipsDescendants = true,
				}, loadGui)
				tween(bg, { BackgroundTransparency = 0.03 }, 0.3)

				-- grid
				for i = 1, 15 do
					table.insert(fadeBg, new("Frame", {
						Position = UDim2.new(i / 16, 0, 0, 0),
						Size = UDim2.new(0, 1, 1, 0),
						BackgroundColor3 = BLUE,
						BackgroundTransparency = 0.93,
						BorderSizePixel = 0,
					}, bg))
				end
				for i = 1, 9 do
					table.insert(fadeBg, new("Frame", {
						Position = UDim2.new(0, 0, i / 10, 0),
						Size = UDim2.new(1, 0, 0, 1),
						BackgroundColor3 = BLUE,
						BackgroundTransparency = 0.93,
						BorderSizePixel = 0,
					}, bg))
				end

				-- sweeping scan bar
				local scan = new("Frame", {
					Position = UDim2.new(0, 0, 0, -90),
					Size = UDim2.new(1, 0, 0, 90),
					BackgroundColor3 = BLUE,
					BorderSizePixel = 0,
				}, bg)
				new("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({ kp(0, 1), kp(0.5, 0.88), kp(1, 1) }),
				}, scan)
				table.insert(fadeBg, scan)
				TweenService:Create(
					scan,
					TweenInfo.new(2.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
					{ Position = UDim2.new(0, 0, 1, 0) }
				):Play()

				-- vignette
				for _, top in ipairs({ true, false }) do
					local v = new("Frame", {
						AnchorPoint = Vector2.new(0, top and 0 or 1),
						Position = UDim2.new(0, 0, top and 0 or 1, 0),
						Size = UDim2.new(1, 0, 0.3, 0),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
					}, bg)
					new("UIGradient", { Rotation = top and 90 or -90, Transparency = NumberSequence.new(0.1, 1) }, v)
					table.insert(fadeBg, v)
				end

				-- falling hex data columns
				local function hexLine()
					return string.format("%04X %02X %02X", math.random(0, 65535), math.random(0, 255), math.random(0, 255))
				end
				local colLabels, colLines = {}, {}
				for i = 1, 7 do
					local lines = {}
					for _ = 1, 26 do
						table.insert(lines, hexLine())
					end
					colLines[i] = lines
					local xs = (i - 1) / 7 + 0.015
					local lab = new("TextLabel", {
						Position = UDim2.new(xs, 0, 0, -340),
						Size = UDim2.fromOffset(90, 340),
						BackgroundTransparency = 1,
						Font = CODE,
						Text = table.concat(lines, "\n"),
						TextSize = 10,
						TextColor3 = BLUE,
						TextTransparency = 0.86,
						TextXAlignment = LEFT,
						TextYAlignment = Enum.TextYAlignment.Top,
					}, bg)
					colLabels[i] = lab
					table.insert(fadeText, lab)
					TweenService:Create(
						lab,
						TweenInfo.new(7 + math.random() * 6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, math.random() * 3),
						{ Position = UDim2.new(xs, 0, 1, 0) }
					):Play()
				end

				-- main layout (640 x 340 design space)
				local root = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.fromOffset(DW, DH),
					BackgroundColor3 = ICE,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ClipsDescendants = true,
				}, loadGui)
				new("UIScale", { Scale = base }, root)

				local function lbl(parent, text, x, y, w, h, size, color, xalign, font)
					return new("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(x, y),
						Size = UDim2.fromOffset(w, h),
						Font = font or CODE,
						Text = text,
						TextSize = size,
						TextColor3 = color,
						TextXAlignment = xalign or LEFT,
					}, parent)
				end
				local function brackets(parent, w, h, len, th, color)
					local function bar(x, y, bw, bh)
						new("Frame", {
							Position = UDim2.fromOffset(x, y),
							Size = UDim2.fromOffset(bw, bh),
							BackgroundColor3 = color,
							BorderSizePixel = 0,
							ZIndex = 4,
						}, parent)
					end
					bar(0, 0, len, th)
					bar(0, 0, th, len)
					bar(w - len, 0, len, th)
					bar(w - th, 0, th, len)
					bar(0, h - th, len, th)
					bar(0, h - len, th, len)
					bar(w - len, h - th, len, th)
					bar(w - th, h - len, th, len)
				end

				-- top bar
				lbl(root, string.format("cHub OS // WARDROBE NODE 0x%04X", math.random(4096, 65535)), 0, 0, 320, 16, 11, BLUE)
				local recDot = new("Frame", {
					Position = UDim2.fromOffset(DW - 236, 4),
					Size = UDim2.fromOffset(8, 8),
					BackgroundColor3 = RED,
					BorderSizePixel = 0,
				}, root)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, recDot)
				TweenService:Create(
					recDot,
					TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
					{ BackgroundTransparency = 1 }
				):Play()
				lbl(root, "TRACKING USER", DW - 222, 0, 110, 16, 11, RED)
				local clock = lbl(root, os.date("%H:%M:%S"), DW - 100, 0, 100, 16, 11, BLUE, RIGHT)
				new("Frame", {
					Position = UDim2.fromOffset(0, 22),
					Size = UDim2.fromOffset(DW, 1),
					BackgroundColor3 = BLUE,
					BackgroundTransparency = 0.7,
					BorderSizePixel = 0,
				}, root)

				-- profile scan panel (kaliwa)
				local avatarBox = new("Frame", {
					Position = UDim2.fromOffset(0, 40),
					Size = UDim2.fromOffset(124, 124),
					BackgroundColor3 = Color3.fromRGB(8, 18, 34),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
				}, root)
				local avatarImg = new("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "",
					ImageColor3 = Color3.fromRGB(170, 215, 255),
					ImageTransparency = 0.1,
					ScaleType = Enum.ScaleType.Crop,
				}, avatarBox)
				local avatarHint = lbl(avatarBox, "SCANNING...", 0, 52, 124, 18, 11, BLUE, CENTER)
				brackets(avatarBox, 124, 124, 14, 2, CYAN)
				local scanLine = new("Frame", {
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = CYAN,
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, avatarBox)
				TweenService:Create(
					scanLine,
					TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Position = UDim2.new(0, 0, 1, -2) }
				):Play()

				local profKeys = { "NAME", "USER", "ID", "AGE", "DEVICE" }
				local profVals = {}
				for i, key in ipairs(profKeys) do
					local y = 176 + (i - 1) * 19
					lbl(root, key, 0, y, 52, 16, 11, BLUE)
					local v = lbl(root, "????", 54, y, 150, 16, 11, ICE)
					v.TextTruncate = Enum.TextTruncate.AtEnd
					profVals[i] = v
				end

				-- logo + glitch title
				local logo = makeIcon("hanger", root, 46, ICE)
				logo.box.Position = UDim2.fromOffset(230, 52)

				local glitch = {}
				local function makeGlitch(text, x, y, w, h, size, font)
					local function mk(color, z, tr)
						return new("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(x, y),
							Size = UDim2.fromOffset(w, h),
							Font = font,
							Text = text,
							TextSize = size,
							TextColor3 = color,
							TextTransparency = tr,
							TextXAlignment = LEFT,
							ZIndex = z,
						}, root)
					end
					local g = { r = mk(RED, 1, 0.45), c = mk(CYAN, 2, 0.45), b = mk(ICE, 3, 0), text = text, x = x, y = y }
					table.insert(glitch, g)
					return g
				end
				local function setGlitch(g, text, color)
					g.text = text
					g.b.Text, g.r.Text, g.c.Text = text, text, text
					g.b.TextColor3 = color
				end
				local titleG = makeGlitch("CLOTHINGHUB", 286, 50, 354, 48, 34, Enum.Font.GothamBlack)
				lbl(root, "// by JAYVEE", 288, 100, 300, 16, 12, BLUE)
				lbl(root, "everything is connected.", 288, 118, 300, 14, 11, DIM)

				-- terminal log
				new("Frame", {
					Position = UDim2.fromOffset(224, 146),
					Size = UDim2.fromOffset(1, 112),
					BackgroundColor3 = BLUE,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
				}, root)
				local logLabel = new("TextLabel", {
					Position = UDim2.fromOffset(232, 146),
					Size = UDim2.fromOffset(408, 112),
					BackgroundTransparency = 1,
					Font = CODE,
					Text = "",
					RichText = true,
					TextSize = 12,
					TextColor3 = ICE,
					TextXAlignment = LEFT,
					TextYAlignment = Enum.TextYAlignment.Top,
					LineHeight = 1.1,
				}, root)
				local logLines = {}
				local function renderLog(extra)
					local shown = {}
					local startI = math.max(1, #logLines - 6)
					for i = startI, #logLines do
						table.insert(shown, logLines[i])
					end
					if extra then
						table.insert(shown, extra)
					end
					logLabel.Text = table.concat(shown, "\n")
				end

				-- segmented progress
				local ticks, TICKS = {}, 60
				for i = 1, TICKS do
					ticks[i] = new("Frame", {
						Position = UDim2.fromOffset(232 + (i - 1) * (408 / TICKS), 270),
						Size = UDim2.fromOffset(4, 12),
						BackgroundColor3 = BLUE,
						BackgroundTransparency = 0.86,
						BorderSizePixel = 0,
					}, root)
				end
				local pct = lbl(root, "00%", DW - 150, 226, 150, 36, 28, ICE, RIGHT)
				local stepLabel = lbl(root, "[0/6] STANDBY", 232, 288, 300, 16, 11, BLUE)
				lbl(root, "v" .. CONFIG.Version, DW - 100, 288, 100, 16, 11, DIM, RIGHT)
				lbl(root, "// all systems are being monitored", 0, 322, 400, 14, 10, DIM)

				local pctValue = new("NumberValue", { Value = 0 }, loadGui)
				local lastFilled = -1
				pctValue.Changed:Connect(function(val)
					pct.Text = string.format("%02d%%", math.floor(val + 0.5))
					local filled = math.floor(val / 100 * TICKS + 0.5)
					if filled ~= lastFilled then
						lastFilled = filled
						for i, tk in ipairs(ticks) do
							if i <= filled then
								tk.BackgroundColor3 = (i == filled) and WHITE or ICE
								tk.BackgroundTransparency = (i == filled) and 0 or 0.1
							else
								tk.BackgroundColor3 = BLUE
								tk.BackgroundTransparency = 0.86
							end
						end
					end
				end)

				-- text scramble reveal (para sa profile info)
				local function scramble(label, final)
					local glyphs = {}
					local okU = pcall(function()
						for _, cp in utf8.codes(final) do
							table.insert(glyphs, utf8.char(cp))
						end
					end)
					if not okU or #glyphs == 0 then
						label.Text = final
						return
					end
					local pool = "01#%&@$?ABCDEF"
					local n = #glyphs
					for step = 1, 12 do
						local out = {}
						for i = 1, n do
							if i <= n * step / 12 then
								out[i] = glyphs[i]
							else
								local r = math.random(1, #pool)
								out[i] = string.sub(pool, r, r)
							end
						end
						label.Text = table.concat(out)
						task.wait(0.04)
					end
					label.Text = final
				end
				local function revealProfile()
					if home.avatar and home.avatar.Image ~= "" then
						avatarImg.Image = home.avatar.Image
						avatarHint.Visible = false
					else
						avatarHint.Text = "NO IMAGE"
					end
					local vals = {
						LocalPlayer.DisplayName,
						"@" .. LocalPlayer.Name,
						tostring(LocalPlayer.UserId),
						LocalPlayer.AccountAge .. " days",
						deviceType() .. " / " .. execName,
					}
					for i, v in ipairs(vals) do
						task.spawn(scramble, profVals[i], v)
					end
				end

				-- intro: flicker boot
				play("Open")
				for i = 1, 8 do
					titleG.b.TextTransparency = (i % 2 == 0) and 0 or 0.85
					task.wait(0.05)
				end
				titleG.b.TextTransparency = 0

				-- glitch engine (RGB split + corrupt text) + hex rain + clock
				local GLYPHS = "01#%&@$?/|<>"
				local function corrupt(str)
					local out = {}
					for i = 1, #str do
						local ch = string.sub(str, i, i)
						if ch ~= " " and math.random() < 0.18 then
							local r = math.random(1, #GLYPHS)
							ch = string.sub(GLYPHS, r, r)
						end
						out[i] = ch
					end
					return table.concat(out)
				end
				local nextBurst, burstUntil, bursting = os.clock() + 0.8, 0, false
				local lastCol, lastClock = 0, 0
				loopConn = connect(RunService.Heartbeat, function()
					local now = os.clock()
					if not bursting and now >= nextBurst then
						bursting = true
						burstUntil = now + 0.1 + math.random() * 0.12
						nextBurst = now + 0.8 + math.random() * 1.6
						for _, g in ipairs(glitch) do
							local txt = corrupt(g.text)
							g.b.Text, g.r.Text, g.c.Text = txt, txt, txt
						end
					elseif bursting and now >= burstUntil then
						bursting = false
						for _, g in ipairs(glitch) do
							g.b.Text, g.r.Text, g.c.Text = g.text, g.text, g.text
						end
					end
					for _, g in ipairs(glitch) do
						local ox = bursting and math.random(-7, 7) or 1
						local oy = bursting and math.random(-2, 2) or 0
						g.r.Position = UDim2.fromOffset(g.x + ox, g.y + oy)
						g.c.Position = UDim2.fromOffset(g.x - ox, g.y - oy)
						g.b.TextTransparency = bursting and (math.random() * 0.35) or 0
					end
					if now - lastCol > 0.12 then
						lastCol = now
						local ci = math.random(1, #colLabels)
						local lines = colLines[ci]
						lines[math.random(1, #lines)] = hexLine()
						colLabels[ci].Text = table.concat(lines, "\n")
					end
					if now - lastClock > 0.5 then
						lastClock = now
						clock.Text = os.date("%H:%M:%S")
					end
				end)

				-- steps
				local TOTAL, stepNo = 6, 0
				local OKTAG = ' <font color="#78ffaa">[OK]</font>'
				table.insert(logLines, "cHub OS // secure boot")
				table.insert(logLines, "link established" .. OKTAG)
				renderLog()
				local function runStep(title, target, minT, logText, work)
					stepNo = stepNo + 1
					stepLabel.Text = string.format("[%d/%d] %s", stepNo, TOTAL, title)
					tween(pctValue, { Value = target }, minT + 0.3, Enum.EasingStyle.Quad)
					local t0 = os.clock()
					local done = false
					task.spawn(function()
						if work then
							pcall(work)
						end
						done = true
					end)
					local line = "> " .. logText
					for i = 1, #line do
						renderLog(string.sub(line, 1, i) .. "_")
						task.wait(0.01)
					end
					local tw = os.clock()
					while not done and os.clock() - tw < 6 do
						task.wait(0.05)
					end
					local el = os.clock() - t0
					if el < minT then
						task.wait(minT - el)
					end
					table.insert(logLines, line .. " " .. string.rep(".", math.max(2, 40 - #line)) .. OKTAG)
					renderLog()
					play("Click")
				end

				runStep("DETECTING DEVICE", 16, 0.4, "scan device: " .. deviceType() .. " / " .. execName, nil)
				runStep("LOADING AUDIO MODULES", 34, 0.4, "load audio modules", function()
					local list = {}
					for _, snd in pairs(sounds) do
						table.insert(list, snd)
					end
					game:GetService("ContentProvider"):PreloadAsync(list)
				end)
				runStep("SYNCING CHARACTER MODEL", 52, 0.4, "sync character model", function()
					local t0 = os.clock()
					while not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
						and os.clock() - t0 < 4 do
						task.wait(0.1)
					end
				end)
				runStep("PROFILING USER", 74, 0.4, "profile user: @" .. LocalPlayer.Name, function()
					home.loadProfile()
				end)
				revealProfile()
				runStep("DECRYPTING WARDROBE", 90, 0.5, "decrypt wardrobe database", nil)
				runStep("BUILDING INTERFACE", 100, 0.4, "build interface", function()
					home.heroName.Text = LocalPlayer.DisplayName
					pcall(updateHome)
				end)

				-- access granted
				stepLabel.Text = "[6/6] ACCESS GRANTED"
				table.insert(logLines, '<font color="#78ffaa">> ACCESS GRANTED // welcome @' .. LocalPlayer.Name .. "</font>")
				renderLog()
				setGlitch(titleG, "ACCESS GRANTED", GREEN)
				play("Success")
				task.wait(0.9)

				-- CRT shutdown -> main UI
				tween(root, { Size = UDim2.fromOffset(DW, 3) }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(0.22)
				root.BackgroundTransparency = 0.1
				tween(root, { Size = UDim2.fromOffset(0, 3) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tween(bg, { BackgroundTransparency = 1 }, 0.45)
				for _, f in ipairs(fadeBg) do
					tween(f, { BackgroundTransparency = 1 }, 0.4)
				end
				for _, t in ipairs(fadeText) do
					tween(t, { TextTransparency = 1 }, 0.4)
				end
				task.wait(0.15)
				finish() -- lalabas na yung main UI habang nagfe-fade yung loader
				task.wait(0.5)
			end)

			if not ok then
				warn("[ClothingHub] loader error: " .. tostring(err))
				setStatus("Loader: " .. string.sub(tostring(err), 1, 44), "err")
			end
			if loopConn then
				loopConn:Disconnect()
			end
			if loadGui then
				loadGui:Destroy()
				loadGui = nil
			end
			if blurFx then
				blurFx:Destroy()
				blurFx = nil
			end
			finish()
		end)
	end
end

------------------------------------------------------------
-- Destroy + launch
------------------------------------------------------------
local function Destroy()
	destroyed = true
	if loadGui then
		loadGui:Destroy()
	end
	if blurFx then
		blurFx:Destroy()
	end
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	for _, s in pairs(sounds) do
		s:Destroy()
	end
	for _, acc in pairs(equipped) do
		acc:Destroy()
	end
	if equippedHair then
		equippedHair:Destroy()
	end
	gui:Destroy()
end
hooks.save = function()
	if not writefile then
		setSetStatus("Executor can't save files", "err")
		play("Error")
		return
	end
	local ok, err = pcall(function()
		writefile(SET.file, game:GetService("HttpService"):JSONEncode({
			version = 1,
			settings = S,
			outfit = hooks.collect(),
		}))
	end)
	if ok then
		setSetStatus("Saved: " .. SET.file, "ok")
		play("Success")
	else
		setSetStatus("Save failed: " .. string.sub(tostring(err), 1, 30), "err")
		play("Error")
	end
end

hooks.unload = function()
	if not hooks.armed then
		hooks.armed = true
		unloadBtn.Text = "Tap again"
		play("Click")
		task.delay(3, function()
			if hooks.armed and unloadBtn.Parent then
				hooks.armed = false
				unloadBtn.Text = "Unload"
			end
		end)
		return
	end
	play("Close")
	pcall(resetAll) -- ibalik muna yung original na itsura
	task.wait(0.25)
	Destroy()
	env.ClothingHub = nil
end

env.ClothingHub = { Destroy = Destroy }

if savedData and type(savedData.outfit) == "table" then
	pcall(hooks.loadOutfit, savedData.outfit)
end
refreshSlot()
icon.Visible = false

local function showMain()
	hooks.iconReady = true
	hooks.refreshIcon()
	if icon.Visible then
		local isc = icon:FindFirstChildOfClass("UIScale")
		if isc then
			isc.Scale = 0
			tween(isc, { Scale = 1 }, 0.55, Enum.EasingStyle.Back)
		end
	end
	setOpen(true)
	if S.autoApplySaved and savedData and type(savedData.outfit) == "table" then
		task.delay(1.2, function()
			if not destroyed then
				applyAll()
			end
		end)
	end
end

if CONFIG.ShowLoading then
	runLoading(showMain)
else
	showMain()
end
