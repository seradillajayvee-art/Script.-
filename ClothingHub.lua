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
	if s then
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
		Rotation = 60,
		Color = ColorSequence.new(Color3.fromRGB(120, 130, 160), Color3.fromRGB(28, 31, 44)),
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
		BackgroundColor3 = accent and CONFIG.Accent or WHITE,
		BackgroundTransparency = accent and 0.15 or 0.86,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, b)
	addRim(b, 1, 0.3)
	if accent then
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(165, 190, 255)),
		}, b)
	end
	pressFX(b)
	return b
end

local function makeDraggable(handle, target, onTap)
	local dragging, moved, dragStart, startPos = false, false, nil, nil
	connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
			local con
			con = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					con:Disconnect()
					if not moved and onTap then
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
	return obj
end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local WIN_W, WIN_H = 300, 362

local gui = new("ScreenGui", {
	Name = "ClothingHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
gui.Parent = getGuiParent()

-- Window (CanvasGroup so the whole thing can fade)
local window = new("CanvasGroup", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	Visible = false,
}, gui)
local winScale = new("UIScale", { Scale = 1 }, window)

local glass = new("Frame", {
	Name = "Glass",
	Position = UDim2.fromOffset(2, 2),
	Size = UDim2.new(1, -4, 1, -4),
	BorderSizePixel = 0,
}, window)
glassFill(glass, 0.3)
new("UICorner", { CornerRadius = UDim.new(0, 28) }, glass)
addRim(glass, 1.5, 0)

-- specular shine on top
local shine = new("Frame", {
	Position = UDim2.fromOffset(6, 5),
	Size = UDim2.new(1, -12, 0, 90),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, glass)
new("UICorner", { CornerRadius = UDim.new(0, 23) }, shine)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.86, 1) }, shine)

-- Header
local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundTransparency = 1,
}, glass)

local dragZone = new("Frame", {
	Size = UDim2.new(1, -56, 1, 0),
	BackgroundTransparency = 1,
	Active = true,
}, header)

new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(1, -18, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = CONFIG.Title,
	TextSize = 17,
	TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left,
}, dragZone)

local minBtn = glassButton(header, "", UDim2.fromOffset(28, 28), UDim2.new(1, -42, 0, 9), false)
minBtn.UICorner.CornerRadius = UDim.new(1, 0)
local glyph = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(12, 2),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, minBtn)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, glyph)

-- Tabs (segmented control)
local tabs = new("Frame", {
	Position = UDim2.fromOffset(16, 46),
	Size = UDim2.fromOffset(264, 30),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.88,
	BorderSizePixel = 0,
}, glass)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, tabs)
addRim(tabs, 1, 0.35)

local indicator = new("Frame", {
	Position = UDim2.new(0, 2, 0, 3),
	Size = UDim2.new(1 / 3, -4, 1, -6),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
}, tabs)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, indicator)
addRim(indicator, 1, 0.4)

local tabButtons = {}
for i, name in ipairs({ "Home", "Outfit", "Character" }) do
	tabButtons[i] = new("TextButton", {
		Position = UDim2.new((i - 1) / 3, 0, 0, 0),
		Size = UDim2.new(1 / 3, 0, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = WHITE,
	}, tabs)
end

-- Pages
local pageOutfit = new("Frame", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 1, -156),
	BackgroundTransparency = 1,
}, glass)
new("UIPadding", {
	PaddingLeft = UDim.new(0, 16),
	PaddingRight = UDim.new(0, 16),
	PaddingTop = UDim.new(0, 4),
}, pageOutfit)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, pageOutfit)

local pageChar = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 1, -156),
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
	PaddingLeft = UDim.new(0, 16),
	PaddingRight = UDim.new(0, 16),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 10),
}, pageChar)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, pageChar)

local pageHome = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 1, -92),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = WHITE,
	ScrollBarImageTransparency = 0.5,
}, glass)
new("UIPadding", {
	PaddingLeft = UDim.new(0, 16),
	PaddingRight = UDim.new(0, 16),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 10),
}, pageHome)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, pageHome)

-- Bottom bar (shared by both tabs)
local bar = new("Frame", {
	Position = UDim2.new(0, 0, 1, -72),
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundTransparency = 1,
}, glass)
new("Frame", {
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -32, 0, 1),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.86,
	BorderSizePixel = 0,
}, bar)

local btnRow = new("Frame", {
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.new(1, -32, 0, 38),
	BackgroundTransparency = 1,
}, bar)
local applyBtn = glassButton(btnRow, "Apply", UDim2.new(0.62, -4, 1, 0), UDim2.new(0, 0, 0, 0), true)
local resetBtn = glassButton(btnRow, "Reset", UDim2.new(0.38, -4, 1, 0), UDim2.new(0.62, 4, 0, 0), false)

local status = new("TextLabel", {
	Position = UDim2.fromOffset(16, 50),
	Size = UDim2.new(1, -32, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "Ready",
	TextSize = 12,
	TextColor3 = MUTED,
}, bar)

local function setStatus(text, kind)
	status.Text = text
	if kind == "ok" then
		status.TextColor3 = Color3.fromRGB(150, 230, 175)
	elseif kind == "err" then
		status.TextColor3 = Color3.fromRGB(255, 125, 125)
	else
		status.TextColor3 = MUTED
	end
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
		Size = UDim2.new(1, 0, 0, 36),
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
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, box)
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
			Position = UDim2.fromOffset(math.floor((i - 1) * (264 - 24) / (#presets - 1)), 0),
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
local hooks = {} -- (live color preview, nilalagay sa baba)

sectionRow(pageOutfit, "Clothing", 1, 16)
local shirtBox = inputBox(pageOutfit, "Shirt Id", 2)
local pantsBox = inputBox(pageOutfit, "Pants Id", 3)

local accRow = sectionRow(pageOutfit, "Accessory", 4, 28)
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

local accBox = inputBox(pageOutfit, "Accessory Id", 5)

------------------------------------------------------------
-- CHARACTER page
------------------------------------------------------------
sectionRow(pageChar, "Character", 1, 16)
local headBox = inputBox(pageChar, "Head Id", 2)
local faceBox = inputBox(pageChar, "Face Id", 3)
local hairBox = inputBox(pageChar, "Hair Id", 4)

local hairHdr = sectionRow(pageChar, "Hair Color", 5, 24)
local hairSw = makeSwitch(hairHdr, false, function()
	if hooks.live then
		hooks.live("full")
	end
end)
local hairPicker = colorPicker(pageChar, 6, CONFIG.HairPresets, Color3.fromRGB(74, 48, 32), pageChar, function()
	hairSw.Set(true) -- auto-on pag nag-edit ng kulay
	if hooks.live then
		hooks.live("color")
	end
end)

local solidRow = sectionRow(pageChar, "Solid color", 7, 24)
local solidSw = makeSwitch(solidRow, true, function()
	if hooks.live then
		hooks.live("full")
	end
end)

local skinHdr = sectionRow(pageChar, "Skin Color", 8, 24)
local skinSw = makeSwitch(skinHdr, false, function()
	if hooks.live then
		hooks.live("full")
	end
end)
local skinPicker = colorPicker(pageChar, 9, CONFIG.SkinPresets, Color3.fromRGB(255, 224, 189), pageChar, function()
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
	new("UIGradient", {
		Rotation = 25,
		Color = ColorSequence.new(Color3.fromRGB(10, 132, 255), Color3.fromRGB(150, 80, 255)),
	}, hero)
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
end

------------------------------------------------------------
-- Floating icon
------------------------------------------------------------
local icon = new("TextButton", {
	Name = "Icon",
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.fromOffset(54, 54),
	Position = UDim2.new(0, 14, 0.5, -27),
	BorderSizePixel = 0,
}, gui)
glassFill(icon, 0.25)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, icon)
addRim(icon, 1.5, 0)
new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "👕",
	TextSize = 26,
	TextColor3 = WHITE,
}, icon)
pressFX(icon)

------------------------------------------------------------
-- Tabs / open / hide
------------------------------------------------------------
local currentTab = 1
local function setTab(i, silent)
	currentTab = i
	pageHome.Visible = (i == 1)
	pageOutfit.Visible = (i == 2)
	pageChar.Visible = (i == 3)
	bar.Visible = (i ~= 1) -- Apply/Reset hindi kailangan sa Home
	tween(indicator, { Position = UDim2.new((i - 1) / 3, 2, 0, 3) }, 0.3)
	for j, b in ipairs(tabButtons) do
		b.TextColor3 = (j == i) and WHITE or MUTED
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
	fit = math.clamp(math.min((vp.Y - 24) / WIN_H, (vp.X - 24) / WIN_W, 1), 0.5, 1)
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
makeDraggable(icon, icon, toggle)
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

local function loadAsset(id)
	local ok, res = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if ok and type(res) == "table" and res[1] then
		return res[1]
	end
	ok, res = pcall(function()
		return game:GetService("InsertService"):LoadAsset(tonumber(id))
	end)
	if ok and res then
		return res
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

local function loadAccessory(id)
	local obj = loadAsset(id)
	if not obj then
		return nil
	end
	local acc = (obj:IsA("Accessory") and obj) or obj:FindFirstChildWhichIsA("Accessory", true)
	if not acc then
		obj:Destroy()
		return nil
	end
	for _, d in ipairs(acc:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	if obj ~= acc then
		acc.Parent = nil
		obj:Destroy()
	end
	return acc
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

local function restoreHairColors(char)
	local b = getBk(char)
	for p, o in pairs(b.hairColor) do
		pcall(function()
			p.Color = o.Color
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
		if not b.hairColor[p] then
			b.hairColor[p] = {
				Color = p.Color,
				TextureID = p:IsA("MeshPart") and p.TextureID or nil,
				SA = p:FindFirstChildOfClass("SurfaceAppearance"),
				SM = sm,
				SMTex = sm and sm.TextureId or nil,
				SMVC = sm and sm.VertexColor or nil,
			}
		end
		p.Color = color
		if solid then
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
			sm.VertexColor = Vector3.new(color.R, color.G, color.B)
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
	hum:AddAccessory(acc)
	equippedHair = acc
	return true
end

-- light = true -> huwag munang i-restore (para sa live slider, walang flicker)
local function applyHairColor(char, light)
	if not light then
		restoreHairColors(char)
	end
	if not state.hairOn then
		return 0
	end
	local count = 0
	for _, obj in ipairs(hairTargets(char)) do
		count = count + colorAccessory(char, obj, state.hairColor, state.solid)
	end
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
				hum:AddAccessory(acc)
				equipped[i] = acc
				tally(true)
			else
				tally(false, "Accessory " .. i .. " can't load")
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
		tally(try(applyHair, char, hum), "Hair ID can't load")
	else
		pcall(applyHair, char, hum)
	end
	local okp, painted = pcall(applyHairColor, char)
	if state.hairOn then
		tally(okp and painted and painted > 0, "Hair color: no hair found")
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
	local char = LocalPlayer.Character
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
	local char = LocalPlayer.Character
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
	if not state.applied then
		return
	end
	char:WaitForChild("Humanoid", 10)
	task.wait(1.5) -- let the game's own appearance load first
	task.spawn(applyToCharacter, char)
end)

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
		local char = LocalPlayer.Character
		if not (char and char:FindFirstChildOfClass("Humanoid")) then
			return
		end
		state.hairOn = hairSw.Get()
		state.hairColor = hairPicker.Get()
		state.solid = solidSw.Get()
		state.skinOn = skinSw.Get()
		state.skinColor = skinPicker.Get()
		if state.hairOn or state.skinOn then
			state.applied = true
		end
		local ok, count = pcall(applyHairColor, char, not full)
		pcall(applySkin, char)
		if state.hairOn then
			startEnforcer(char)
			if ok and count == 0 then
				setStatus("Hair color: no hair found", "err")
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
			if isOpen and currentTab == 1 then
				pcall(updateHome)
			end
		end
	end)

	----------------------------------------------------------
	-- Startup loading screen (liquid glass)
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
			local orbitConn

			local ok, err = pcall(function()
				local Lighting = game:GetService("Lighting")
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				local base = math.clamp(math.min((vp.Y - 16) / 250, (vp.X - 16) / 300, 1), 0.5, 1)
				local function kp(t, val)
					return NumberSequenceKeypoint.new(t, val)
				end
				local function ckp(t, c)
					return ColorSequenceKeypoint.new(t, c)
				end
				local PINK = Color3.fromRGB(255, 110, 200)
				local PURPLE = Color3.fromRGB(150, 80, 255)
				local CYAN = Color3.fromRGB(60, 220, 255)

				loadGui = new("ScreenGui", {
					Name = "ClothingHubLoader",
					ResetOnSpawn = false,
					IgnoreGuiInset = true,
					DisplayOrder = 1000,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				})
				loadGui.Parent = getGuiParent()

				-- real blur sa likod habang naglo-load
				pcall(function()
					blurFx = new("BlurEffect", { Name = "ClothingHubBlur", Size = 0 }, Lighting)
					tween(blurFx, { Size = 20 }, 0.9)
				end)

				local fade = {} -- {frame, finalTransparency} para ma-fade in/out
				local backdrop = new("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(5, 7, 18),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				}, loadGui)
				tween(backdrop, { BackgroundTransparency = 0.18 }, 0.8)

				-- aurora blobs (layered circles = soft glow)
				local function glow(color, size, xs, ys, dx, dy, dur)
					local holder = new("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(xs, 0, ys, 0),
						Size = UDim2.fromOffset(size, size),
						BackgroundTransparency = 1,
					}, backdrop)
					for i = 1, 6 do
						local sc = 1 - (i - 1) * 0.17
						local target = 0.94 - (i - 1) * 0.045
						local layer = new("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Size = UDim2.new(sc, 0, sc, 0),
							BackgroundColor3 = color,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
						}, holder)
						new("UICorner", { CornerRadius = UDim.new(1, 0) }, layer)
						tween(layer, { BackgroundTransparency = target }, 1.2)
						table.insert(fade, { layer, target })
					end
					TweenService:Create(
						holder,
						TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
						{ Position = UDim2.new(xs, dx, ys, dy) }
					):Play()
				end
				glow(CONFIG.Accent, 360, 0.25, 0.3, 60, 40, 5)
				glow(PURPLE, 340, 0.78, 0.32, -50, 50, 6)
				glow(PINK, 320, 0.62, 0.82, -60, -40, 5.5)
				glow(CYAN, 300, 0.2, 0.8, 50, -50, 6.5)

				-- rising sparkles
				for _ = 1, 18 do
					local sz = math.random(2, 4)
					local target = 0.4 + math.random() * 0.4
					local sp = new("Frame", {
						Position = UDim2.new(math.random(), 0, 1.05, 0),
						Size = UDim2.fromOffset(sz, sz),
						BackgroundColor3 = WHITE,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}, backdrop)
					new("UICorner", { CornerRadius = UDim.new(1, 0) }, sp)
					table.insert(fade, { sp, target })
					task.delay(math.random() * 4, function()
						if sp.Parent then
							sp.BackgroundTransparency = target
							TweenService:Create(
								sp,
								TweenInfo.new(5 + math.random() * 5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
								{ Position = UDim2.new(sp.Position.X.Scale, 0, -0.05, 0) }
							):Play()
						end
					end)
				end

				-- glass card
				local cardG = new("CanvasGroup", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.fromOffset(300, 250),
					BackgroundTransparency = 1,
					GroupTransparency = 1,
				}, loadGui)
				local cardScale = new("UIScale", { Scale = base * 0.8 }, cardG)
				local cg = new("Frame", {
					Position = UDim2.fromOffset(2, 2),
					Size = UDim2.new(1, -4, 1, -4),
					BorderSizePixel = 0,
				}, cardG)
				glassFill(cg, 0.22)
				new("UICorner", { CornerRadius = UDim.new(0, 30) }, cg)
				addRim(cg, 1.5, 0)

				local shineTop = new("Frame", {
					Position = UDim2.fromOffset(6, 5),
					Size = UDim2.new(1, -12, 0, 100),
					BackgroundColor3 = WHITE,
					BorderSizePixel = 0,
				}, cg)
				new("UICorner", { CornerRadius = UDim.new(0, 25) }, shineTop)
				new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.84, 1) }, shineTop)

				-- diagonal shine sweep
				local sweep = new("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = WHITE,
					BorderSizePixel = 0,
				}, cg)
				new("UICorner", { CornerRadius = UDim.new(0, 30) }, sweep)
				local sweepGrad = new("UIGradient", {
					Rotation = 25,
					Offset = Vector2.new(-1, 0),
					Transparency = NumberSequence.new({
						kp(0, 1), kp(0.42, 1), kp(0.5, 0.82), kp(0.58, 1), kp(1, 1),
					}),
				}, sweep)
				TweenService:Create(
					sweepGrad,
					TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.9),
					{ Offset = Vector2.new(1, 0) }
				):Play()

				-- logo orb: rotating gradient ring + orbiting dots
				local logo = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 18),
					Size = UDim2.fromOffset(90, 90),
					BackgroundTransparency = 1,
				}, cg)
				local ring = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, logo)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
				local ringStroke = new("UIStroke", { Color = WHITE, Thickness = 3, Transparency = 0 }, ring)
				local ringGrad = new("UIGradient", {
					Color = ColorSequence.new({ ckp(0, CYAN), ckp(0.5, CONFIG.Accent), ckp(1, PINK) }),
					Transparency = NumberSequence.new({ kp(0, 0), kp(0.5, 1), kp(1, 1) }),
				}, ringStroke)
				TweenService:Create(
					ringGrad,
					TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
					{ Rotation = 360 }
				):Play()

				local orb = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.fromOffset(70, 70),
					BorderSizePixel = 0,
				}, logo)
				glassFill(orb, 0.3)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, orb)
				addRim(orb, 1.5, 0)
				local emoji = new("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "👕",
					TextSize = 32,
					TextColor3 = WHITE,
				}, orb)
				local emojiScale = new("UIScale", { Scale = 1 }, emoji)
				TweenService:Create(
					emojiScale,
					TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Scale = 1.12 }
				):Play()

				local dotColors = { WHITE, CONFIG.Accent, PINK }
				local orbitDots = {}
				for i = 1, 3 do
					local dsz = (i == 1) and 7 or 5
					local d = new("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromOffset(dsz, dsz),
						BackgroundColor3 = dotColors[i],
						BorderSizePixel = 0,
					}, logo)
					new("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
					orbitDots[i] = d
				end
				local ang = 0
				orbitConn = connect(RunService.Heartbeat, function(dt)
					ang = ang + dt * 2.2
					for i, d in ipairs(orbitDots) do
						local a = ang + (i - 1) * (math.pi * 2 / 3)
						d.Position = UDim2.new(0.5, math.cos(a) * 54, 0.5, math.sin(a) * 54)
					end
				end)

				-- title (typewriter) + shimmering author
				local title = new("TextLabel", {
					Position = UDim2.fromOffset(0, 114),
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBlack,
					Text = "",
					TextSize = 28,
					TextColor3 = WHITE,
				}, cg)
				local fullTitle = CONFIG.Title
				task.spawn(function()
					task.wait(0.55)
					for i = 1, #fullTitle do
						if not title.Parent then
							return
						end
						title.Text = fullTitle:sub(1, i)
						task.wait(0.06)
					end
				end)

				local sub = new("TextLabel", {
					Position = UDim2.fromOffset(0, 150),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "by JAYVEE",
					TextSize = 14,
					TextColor3 = WHITE,
				}, cg)
				local subGrad = new("UIGradient", {
					Color = ColorSequence.new({ ckp(0, CONFIG.Accent), ckp(0.5, WHITE), ckp(1, PINK) }),
					Offset = Vector2.new(-1, 0),
				}, sub)
				TweenService:Create(
					subGrad,
					TweenInfo.new(1.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
					{ Offset = Vector2.new(1, 0) }
				):Play()

				-- progress bar
				local track = new("Frame", {
					Position = UDim2.new(0.5, -110, 0, 182),
					Size = UDim2.fromOffset(220, 8),
					BackgroundColor3 = WHITE,
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
				}, cg)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
				addRim(track, 1, 0.5)
				local fill = new("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = WHITE,
					BorderSizePixel = 0,
				}, track)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
				new("UIGradient", {
					Color = ColorSequence.new({ ckp(0, CONFIG.Accent), ckp(0.6, CYAN), ckp(1, PURPLE) }),
				}, fill)
				local gloss = new("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = WHITE,
					BorderSizePixel = 0,
				}, fill)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, gloss)
				local glossGrad = new("UIGradient", {
					Offset = Vector2.new(-1, 0),
					Transparency = NumberSequence.new({ kp(0, 1), kp(0.4, 1), kp(0.5, 0.45), kp(0.6, 1), kp(1, 1) }),
				}, gloss)
				TweenService:Create(
					glossGrad,
					TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
					{ Offset = Vector2.new(1, 0) }
				):Play()

				local stepLabel = new("TextLabel", {
					Position = UDim2.new(0.5, -110, 0, 196),
					Size = UDim2.fromOffset(170, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = "Starting...",
					TextSize = 12,
					TextColor3 = MUTED,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, cg)
				local pctLabel = new("TextLabel", {
					Position = UDim2.new(0.5, 60, 0, 196),
					Size = UDim2.fromOffset(50, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "0%",
					TextSize = 12,
					TextColor3 = WHITE,
					TextXAlignment = Enum.TextXAlignment.Right,
				}, cg)
				local footer = new("TextLabel", {
					Position = UDim2.new(0, 0, 1, -26),
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = "Preparing...",
					TextSize = 11,
					TextColor3 = Color3.fromRGB(150, 158, 180),
				}, cg)

				local progress = new("NumberValue", { Value = 0 }, loadGui)
				progress.Changed:Connect(function(val)
					fill.Size = UDim2.new(math.clamp(val / 100, 0, 1), 0, 1, 0)
					pctLabel.Text = math.floor(val + 0.5) .. "%"
				end)

				local function setStep(text)
					stepLabel.Text = text
					stepLabel.TextTransparency = 0.6
					tween(stepLabel, { TextTransparency = 0 }, 0.25)
				end
				local function runStep(text, target, minT, work)
					setStep(text)
					local t0 = os.clock()
					tween(progress, { Value = target }, minT, Enum.EasingStyle.Quad)
					if work then
						pcall(work)
					end
					local el = os.clock() - t0
					if el < minT then
						task.wait(minT - el)
					end
					play("Click")
				end

				-- intro
				play("Open")
				tween(cardG, { GroupTransparency = 0 }, 0.5)
				tween(cardScale, { Scale = base }, 0.7, Enum.EasingStyle.Back)
				task.wait(0.9)

				runStep("Detecting device...", 20, 0.8, function()
					footer.Text = string.format("%s  ·  %s  ·  %s", deviceType(), platformName, execName)
				end)
				runStep("Loading sounds...", 42, 0.8, function()
					local list = {}
					for _, snd in pairs(sounds) do
						table.insert(list, snd)
					end
					game:GetService("ContentProvider"):PreloadAsync(list)
				end)
				runStep("Syncing character...", 64, 0.8, function()
					local t0 = os.clock()
					while not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
						and os.clock() - t0 < 4 do
						task.wait(0.1)
					end
				end)
				runStep("Fetching profile...", 86, 0.8, function()
					home.loadProfile()
				end)
				runStep("Building interface...", 100, 0.7, function()
					home.heroName.Text = LocalPlayer.DisplayName
					pcall(updateHome)
				end)

				-- finale
				stepLabel.Text = "Welcome, " .. LocalPlayer.DisplayName
				stepLabel.TextColor3 = Color3.fromRGB(150, 230, 175)
				play("Success")
				task.wait(0.6)

				local ripple = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.fromOffset(40, 40),
					BackgroundTransparency = 1,
				}, loadGui)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, ripple)
				local rippleStroke = new("UIStroke", { Color = WHITE, Thickness = 3, Transparency = 0.1 }, ripple)
				tween(ripple, { Size = UDim2.fromOffset(1400, 1400) }, 0.9, Enum.EasingStyle.Quad)
				tween(rippleStroke, { Transparency = 1 }, 0.9)

				tween(cardG, { GroupTransparency = 1 }, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tween(cardScale, { Scale = base * 1.15 }, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tween(backdrop, { BackgroundTransparency = 1 }, 0.7)
				for _, item in ipairs(fade) do
					tween(item[1], { BackgroundTransparency = 1 }, 0.6)
				end
				if blurFx then
					tween(blurFx, { Size = 0 }, 0.7)
				end
				task.wait(0.3)
				finish() -- lalabas na yung main UI habang nagfe-fade yung loader
				task.wait(0.7)
			end)

			if not ok then
				warn("[ClothingHub] loader error: " .. tostring(err))
			end
			if orbitConn then
				orbitConn:Disconnect()
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
env.ClothingHub = { Destroy = Destroy }

refreshSlot()
icon.Visible = false

local function showMain()
	icon.Visible = true
	local isc = icon:FindFirstChildOfClass("UIScale")
	if isc then
		isc.Scale = 0
		tween(isc, { Scale = 1 }, 0.55, Enum.EasingStyle.Back)
	end
	setOpen(true)
end

if CONFIG.ShowLoading then
	runLoading(showMain)
else
	showMain()
end
