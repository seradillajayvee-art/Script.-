local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PASSWORD = "ULTRAINSTINCTBYJAYVEE"

local gui = Instance.new("ScreenGui")
gui.Name = "JAYVEE_SecurityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function stroke(obj, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0
	s.Color = Color3.fromRGB(120, 190, 255)
	s.Parent = obj
	return s
end

local function tween(obj, time, props, style, direction)
	local info = TweenInfo.new(
		time,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)

	return TweenService:Create(obj, info, props)
end

local function label(parent, text, size, position, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Text = text
	l.Font = font or Enum.Font.GothamBold
	l.TextColor3 = color or Color3.new(1,1,1)
	l.TextScaled = true
	l.Parent = parent
	return l
end

local function button(parent, text, size, position)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = Color3.fromRGB(25,35,60)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.AutoButtonColor = false
	b.Parent = parent
	corner(b, 10)
	stroke(b, 1.2, 0.15)

	b.MouseEnter:Connect(function()
		tween(b, 0.15, {
			BackgroundColor3 = Color3.fromRGB(40,65,105)
		}):Play()
	end)

	b.MouseLeave:Connect(function()
		tween(b, 0.15, {
			BackgroundColor3 = Color3.fromRGB(25,35,60)
		}):Play()
	end)

	return b
end

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1,1)
backdrop.BackgroundColor3 = Color3.fromRGB(3,5,12)
backdrop.BackgroundTransparency = 0.12
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(390,330)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(9,13,25)
panel.BorderSizePixel = 0
panel.Parent = backdrop
corner(panel, 22)

local panelStroke = stroke(panel, 2, 0)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(28,48,88)),
	ColorSequenceKeypoint.new(0.45,Color3.fromRGB(10,17,35)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(5,8,18))
})
gradient.Rotation = 135
gradient.Parent = panel

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1,-8,1,-8)
glow.Position = UDim2.fromOffset(4,4)
glow.BackgroundTransparency = 1
glow.BorderSizePixel = 0
glow.ZIndex = 0
glow.Parent = panel
corner(glow,20)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(0.7,0,0,2)
topLine.Position = UDim2.new(0.15,0,0,0)
topLine.BackgroundColor3 = Color3.fromRGB(150,220,255)
topLine.BorderSizePixel = 0
topLine.Parent = panel

local logo = Instance.new("TextLabel")
logo.Size = UDim2.fromOffset(72,72)
logo.Position = UDim2.new(0.5,-36,0,18)
logo.BackgroundColor3 = Color3.fromRGB(18,32,58)
logo.BorderSizePixel = 0
logo.Text = "UI"
logo.Font = Enum.Font.GothamBlack
logo.TextScaled = true
logo.TextColor3 = Color3.fromRGB(190,230,255)
logo.Parent = panel
corner(logo,36)
stroke(logo,2,0)

local title = label(
	panel,
	"ULTRA INSTINCT",
	UDim2.new(1,-30,0,34),
	UDim2.fromOffset(15,98),
	Enum.Font.GothamBlack,
	Color3.fromRGB(205,235,255)
)

local subtitle = label(
	panel,
	"SECURITY SYSTEM",
	UDim2.new(1,-30,0,18),
	UDim2.fromOffset(15,130),
	Enum.Font.GothamBold,
	Color3.fromRGB(110,170,220)
)

local admin = label(
	panel,
	"ADMIN  •  JAYVEE",
	UDim2.new(1,-30,0,18),
	UDim2.fromOffset(15,151),
	Enum.Font.GothamBold,
	Color3.fromRGB(255,215,100)
)

local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1,-50,0,48)
inputFrame.Position = UDim2.fromOffset(25,180)
inputFrame.BackgroundColor3 = Color3.fromRGB(5,9,18)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = panel
corner(inputFrame,12)
stroke(inputFrame,1.4,0.2)

local lockIcon = label(
	inputFrame,
	"🔒",
	UDim2.fromOffset(32,40),
	UDim2.fromOffset(8,4),
	Enum.Font.GothamBold
)

local input = Instance.new("TextBox")
input.Size = UDim2.new(1,-82,1,0)
input.Position = UDim2.fromOffset(42,0)
input.BackgroundTransparency = 1
input.PlaceholderText = "ENTER SECURITY KEY"
input.PlaceholderColor3 = Color3.fromRGB(90,110,140)
input.TextColor3 = Color3.fromRGB(235,245,255)
input.Text = ""
input.ClearTextOnFocus = false
input.Font = Enum.Font.GothamBold
input.TextSize = 15
input.TextXAlignment = Enum.TextXAlignment.Left
input.Parent = inputFrame

local show = button(
	inputFrame,
	"SHOW",
	UDim2.fromOffset(58,32),
	UDim2.new(1,-65,0,8)
)

local verify = button(
	panel,
	"VERIFY ACCESS",
	UDim2.new(1,-50,0,45),
	UDim2.fromOffset(25,239)
)

verify.BackgroundColor3 = Color3.fromRGB(35,95,145)

local status = label(
	panel,
	"● SYSTEM LOCKED",
	UDim2.new(1,-50,0,18),
	UDim2.fromOffset(25,292),
	Enum.Font.GothamBold,
	Color3.fromRGB(255,100,110)
)

local hidden = true
show.Activated:Connect(function()
	hidden = not hidden

	if hidden then
		input.TextTransparency = 0
		input.Text = string.rep("•",#input.Text)
		show.Text = "SHOW"
	else
		show.Text = "HIDE"
	end
end)

local function setStatus(text, color)
	status.Text = "● " .. text
	status.TextColor3 = color
end

local function shake()
	local original = panel.Position

	for i = 1,5 do
		local offset = (i % 2 == 0) and 8 or -8

		tween(panel,0.045,{
			Position = UDim2.new(
				0.5,
				offset,
				0.5,
				0
			)
		}):Play()

		task.wait(0.045)
	end

	tween(panel,0.12,{
		Position = original
	}):Play()
end

local function successAnimation()
	setStatus(
		"ACCESS GRANTED",
		Color3.fromRGB(80,255,160)
	)

	verify.Text = "✓ ACCESS GRANTED"
	verify.BackgroundColor3 = Color3.fromRGB(35,145,90)

	tween(panelStroke,0.35,{
		Color = Color3.fromRGB(80,255,170),
		Thickness = 3
	}):Play()

	tween(logo,0.35,{
		BackgroundColor3 = Color3.fromRGB(25,100,70),
		TextColor3 = Color3.fromRGB(150,255,200)
	}):Play()

	for i = 1,3 do
		tween(panel,0.12,{
			Size = UDim2.fromOffset(
				390 + i * 5,
				330 + i * 5
			)
		}):Play()
		task.wait(0.12)
	end

	tween(panel,0.35,{
		Size = UDim2.fromOffset(420,355)
	}):Play()

	task.wait(0.5)

	tween(backdrop,0.6,{
		BackgroundTransparency = 1
	}):Play()

	tween(panel,0.6,{
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5,0,0.45,0)
	}):Play()

	for _,v in ipairs(panel:GetDescendants()) do
		if v:IsA("TextLabel")
			or v:IsA("TextButton")
			or v:IsA("TextBox") then

			tween(v,0.4,{
				TextTransparency = 1
			}):Play()
		elseif v:IsA("UIStroke") then
			tween(v,0.4,{
				Transparency = 1
			}):Play()
		end
	end

	task.wait(0.65)
	gui:Destroy()
end

local verifying = false

local function verifyPassword()
	if verifying then return end
	verifying = true

	setStatus(
		"VERIFYING...",
		Color3.fromRGB(120,200,255)
	)

	verify.Text = "VERIFYING..."
	verify.BackgroundColor3 = Color3.fromRGB(50,90,140)

	local oldText = input.Text

	for i = 1,3 do
		task.wait(0.25)

		if i == 1 then
			setStatus("SCANNING KEY...",Color3.fromRGB(120,200,255))
		elseif i == 2 then
			setStatus("CHECKING ACCESS...",Color3.fromRGB(120,200,255))
		else
			setStatus("FINALIZING...",Color3.fromRGB(120,200,255))
		end
	end

	if oldText == PASSWORD then
		successAnimation()
	else
		setStatus(
			"ACCESS DENIED",
			Color3.fromRGB(255,80,95)
		)

		verify.Text = "TRY AGAIN"
		verify.BackgroundColor3 = Color3.fromRGB(125,40,50)

		shake()

		input.Text = ""

		task.wait(1)

		if gui.Parent then
			verify.Text = "VERIFY ACCESS"
			verify.BackgroundColor3 = Color3.fromRGB(35,95,145)
			setStatus(
				"SYSTEM LOCKED",
				Color3.fromRGB(255,100,110)
			)
		end
	end

	verifying = false
end

verify.Activated:Connect(verifyPassword)

input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		verifyPassword()
	end
end)

local dragging = false
local dragStart
local startPosition

local function beginDrag(inputObject)
	dragging = true
	dragStart = inputObject.Position
	startPosition = panel.Position
end

local function updateDrag(inputObject)
	if not dragging then return end

	local delta = inputObject.Position - dragStart

	panel.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

local function endDrag()
	dragging = false
end

panel.InputBegan:Connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1
		or inputObject.UserInputType == Enum.UserInputType.Touch then
		beginDrag(inputObject)
	end
end)

UIS.InputChanged:Connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseMovement
		or inputObject.UserInputType == Enum.UserInputType.Touch then
		updateDrag(inputObject)
	end
end)

UIS.InputEnded:Connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1
		or inputObject.UserInputType == Enum.UserInputType.Touch then
		endDrag()
	end
end)

local pulse = true

task.spawn(function()
	while pulse and gui.Parent do
		tween(panelStroke,1.2,{
			Transparency = 0.45
		}):Play()

		task.wait(1.2)

		tween(panelStroke,1.2,{
			Transparency = 0
		}):Play()

		task.wait(1.2)
	end
end)

task.spawn(function()
	while pulse and gui.Parent do
		tween(logo,1.5,{
			Rotation = 360
		}):Play()

		task.wait(1.5)
		logo.Rotation = 0
	end
end)

input:GetPropertyChangedSignal("Text"):Connect(function()
	if hidden then
		local raw = input.Text:gsub("•","")
		if #raw > 0 then
			input.Text = string.rep("•",#raw)
		end
	end
end)
