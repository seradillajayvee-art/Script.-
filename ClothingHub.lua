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
local CONFIG = {
	Title = "ClothingHub",
	Slots = 7, -- default lang, pwede mo palitan sa UI (tap yung number after "/")
	MaxSlots = 20,
	Accent = Color3.fromRGB(10, 132, 255),
	Volume = 0.6,
	ToggleKey = Enum.KeyCode.RightShift,
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
	Position = UDim2.new(0, 3, 0, 3),
	Size = UDim2.new(0.5, -3, 1, -6),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
}, tabs)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, indicator)
addRim(indicator, 1, 0.4)

local tabButtons = {}
for i, name in ipairs({ "Outfit", "Character" }) do
	tabButtons[i] = new("TextButton", {
		Position = UDim2.new((i - 1) * 0.5, 0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
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
local hairSw = makeSwitch(hairHdr, false)
local hairPicker = colorPicker(pageChar, 6, CONFIG.HairPresets, Color3.fromRGB(74, 48, 32), pageChar, function()
	hairSw.Set(true) -- auto-on pag nag-edit ng kulay
end)

local solidRow = sectionRow(pageChar, "Solid color", 7, 24)
local solidSw = makeSwitch(solidRow, true)

local skinHdr = sectionRow(pageChar, "Skin Color", 8, 24)
local skinSw = makeSwitch(skinHdr, false)
local skinPicker = colorPicker(pageChar, 9, CONFIG.SkinPresets, Color3.fromRGB(255, 224, 189), pageChar, function()
	skinSw.Set(true)
end)

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
local function setTab(i, silent)
	pageOutfit.Visible = (i == 1)
	pageChar.Visible = (i == 2)
	tween(indicator, {
		Position = (i == 1) and UDim2.new(0, 3, 0, 3) or UDim2.new(0.5, 0, 0, 3),
	}, 0.3)
	for j, b in ipairs(tabButtons) do
		b.TextColor3 = (j == i) and WHITE or MUTED
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

-- catalog shirt/pants id -> actual texture template
local function resolveTemplate(id, className, prop)
	local obj = loadAsset(id)
	if obj then
		local inst = (obj:IsA(className) and obj) or obj:FindFirstChildWhichIsA(className, true)
		if inst then
			local value = inst[prop]
			obj:Destroy()
			return value
		end
		obj:Destroy()
	end
	return "rbxassetid://" .. id -- fallback (works if you pasted the texture id)
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
	return ok and t == Enum.AccessoryType.Hair
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

local function colorAccessory(char, acc, color, solid)
	local b = getBk(char)
	for _, p in ipairs(acc:GetDescendants()) do
		if p:IsA("BasePart") then
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
	end
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

local function applyHairColor(char)
	restoreHairColors(char)
	if not state.hairOn then
		return
	end
	local targets
	if equippedHair and equippedHair.Parent then
		targets = { equippedHair }
	else
		targets = originalHairs(char)
	end
	for _, acc in ipairs(targets) do
		colorAccessory(char, acc, state.hairColor, state.solid)
	end
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
local function applyToCharacter(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return 0, 0
	end
	local b = getBk(char)
	local okCount, failCount = 0, 0
	local function tally(ok)
		if ok then
			okCount = okCount + 1
		else
			failCount = failCount + 1
		end
	end
	local function try(fn, ...)
		local ok, res = pcall(fn, ...)
		return ok and res
	end

	-- clothing
	if b.shirt == nil then
		local s = char:FindFirstChildOfClass("Shirt")
		local p = char:FindFirstChildOfClass("Pants")
		b.shirt = s and s.ShirtTemplate or false
		b.pants = p and p.PantsTemplate or false
	end
	if state.shirt ~= "" then
		local ok = pcall(function()
			local tpl = resolveTemplate(state.shirt, "Shirt", "ShirtTemplate")
			local shirt = char:FindFirstChildOfClass("Shirt") or new("Shirt", { Name = "Shirt" }, char)
			shirt.ShirtTemplate = tpl
		end)
		tally(ok)
	end
	if state.pants ~= "" then
		local ok = pcall(function()
			local tpl = resolveTemplate(state.pants, "Pants", "PantsTemplate")
			local pants = char:FindFirstChildOfClass("Pants") or new("Pants", { Name = "Pants" }, char)
			pants.PantsTemplate = tpl
		end)
		tally(ok)
	end

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
				tally(false)
			end
		end
	end

	-- character
	if state.head ~= "" then
		tally(try(applyHead, char, state.head))
	else
		pcall(restoreHead, char)
	end
	if state.face ~= "" then
		tally(try(applyFace, char, state.face))
	else
		pcall(restoreFace, char)
	end
	if state.hair ~= "" then
		tally(try(applyHair, char, hum))
	else
		pcall(applyHair, char, hum)
	end
	pcall(applyHairColor, char)
	if state.hairOn then
		tally(true)
	end
	pcall(applySkin, char)
	if state.skinOn then
		tally(true)
	end

	return okCount, failCount
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
		local good, okCount, failCount = pcall(applyToCharacter, char)
		busy = false
		if not good then
			setStatus("Something went wrong", "err")
			play("Error")
		elseif failCount > 0 then
			setStatus("Applied " .. okCount .. " | " .. failCount .. " failed", "err")
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
-- Destroy + launch
------------------------------------------------------------
local function Destroy()
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
setOpen(true)
