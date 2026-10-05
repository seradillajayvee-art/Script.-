-- ULTRA INSTINCT UI - JAYVEE
-- Safe Roblox LocalScript for your own game.
-- Place in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "UltraInstinct_JAYVEE"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local PASSWORD = "ULTRAINSTINCTBYJAYVEEV2"

local function tween(obj, info, props)
	return TweenService:Create(obj, info, props)
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Transparency = transparency or 0
	s.Parent = parent
end

local function makeSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 0.5
	s.Parent = SoundService
	return s
end

-- UI sounds; replace IDs with your preferred audio if desired.
local clickSound = makeSound(9118828568, 0.45)
local openSound = makeSound(9118823107, 0.45)

local function play(s)
	pcall(function()
		s:Play()
	end)
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
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end)
end

-- Security UI
local security = Instance.new("Frame")
security.Size = UDim2.fromOffset(390, 250)
security.Position = UDim2.new(0.5, -195, 0.5, -125)
security.BackgroundTransparency = 0.08
security.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
security.Parent = gui
corner(security, 18)
stroke(security, 0.15)
draggable(security)

local secScale = Instance.new("UIScale")
secScale.Scale = 0.8
secScale.Parent = security

local secTitle = Instance.new("TextLabel")
secTitle.BackgroundTransparency = 1
secTitle.Size = UDim2.new(1, -30, 0, 45)
secTitle.Position = UDim2.fromOffset(15, 12)
secTitle.Text = "ULTRA INSTINCT"
secTitle.Font = Enum.Font.GothamBlack
secTitle.TextSize = 25
secTitle.TextColor3 = Color3.fromRGB(255,255,255)
secTitle.Parent = security

local secSub = Instance.new("TextLabel")
secSub.BackgroundTransparency = 1
secSub.Size = UDim2.new(1, -30, 0, 25)
secSub.Position = UDim2.fromOffset(15, 55)
secSub.Text = "SECURITY ACCESS  •  JAYVEE"
secSub.Font = Enum.Font.GothamBold
secSub.TextSize = 12
secSub.TextColor3 = Color3.fromRGB(170,170,185)
secSub.Parent = security

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 48)
box.Position = UDim2.fromOffset(20, 92)
box.PlaceholderText = "ENTER ACCESS KEY"
box.Text = ""
box.ClearTextOnFocus = false
box.TextSize = 14
box.Font = Enum.Font.GothamBold
box.TextColor3 = Color3.new(1,1,1)
box.PlaceholderColor3 = Color3.fromRGB(125,125,140)
box.BackgroundColor3 = Color3.fromRGB(28,28,40)
box.Parent = security
corner(box, 12)

local enter = Instance.new("TextButton")
enter.Size = UDim2.new(1, -40, 0, 48)
enter.Position = UDim2.fromOffset(20, 154)
enter.Text = "UNLOCK"
enter.Font = Enum.Font.GothamBlack
enter.TextSize = 14
enter.TextColor3 = Color3.new(1,1,1)
enter.BackgroundColor3 = Color3.fromRGB(55,55,75)
enter.AutoButtonColor = false
enter.Parent = security
corner(enter, 12)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -40, 0, 28)
status.Position = UDim2.fromOffset(20, 210)
status.Text = "SECURE • READY"
status.Font = Enum.Font.GothamBold
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(150,150,165)
status.Parent = security

-- Main UI
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(470, 315)
main.Position = UDim2.new(0.5, -235, 0.5, -155)
main.BackgroundColor3 = Color3.fromRGB(13,13,20)
main.BackgroundTransparency = 0.05
main.Visible = false
main.Parent = gui
corner(main, 20)
stroke(main, 0.12)
draggable(main)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,70)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-30,0,38)
title.Position = UDim2.fromOffset(15,8)
title.Text = "ULTRA INSTINCT"
title.Font = Enum.Font.GothamBlack
title.TextSize = 27
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1,1,1)
title.Parent = header

local admin = Instance.new("TextLabel")
admin.BackgroundTransparency = 1
admin.Size = UDim2.new(1,-30,0,20)
admin.Position = UDim2.fromOffset(16,43)
admin.Text = "ADMIN  •  JAYVEE"
admin.Font = Enum.Font.GothamBold
admin.TextSize = 11
admin.TextXAlignment = Enum.TextXAlignment.Left
admin.TextColor3 = Color3.fromRGB(160,160,180)
admin.Parent = header

local info = Instance.new("TextLabel")
info.Size = UDim2.fromOffset(425, 75)
info.Position = UDim2.fromOffset(22, 82)
info.BackgroundColor3 = Color3.fromRGB(24,24,34)
info.Text = "INFO\n• Mobile-friendly draggable interface\n• Security panel + smooth UI transitions\n• Designed for your own Roblox experience"
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Center
info.Font = Enum.Font.GothamMedium
info.TextSize = 12
info.TextColor3 = Color3.fromRGB(205,205,220)
info.Parent = main
corner(info, 14)

local demo = Instance.new("TextButton")
demo.Size = UDim2.fromOffset(425, 52)
demo.Position = UDim2.fromOffset(22, 172)
demo.Text = "DEMO ACTION"
demo.Font = Enum.Font.GothamBlack
demo.TextSize = 13
demo.TextColor3 = Color3.new(1,1,1)
demo.BackgroundColor3 = Color3.fromRGB(45,45,62)
demo.AutoButtonColor = false
demo.Parent = main
corner(demo, 13)

local hide = Instance.new("TextButton")
hide.Size = UDim2.fromOffset(425, 42)
hide.Position = UDim2.fromOffset(22, 235)
hide.Text = "HIDE UI"
hide.Font = Enum.Font.GothamBold
hide.TextSize = 12
hide.TextColor3 = Color3.fromRGB(190,190,205)
hide.BackgroundColor3 = Color3.fromRGB(25,25,35)
hide.AutoButtonColor = false
hide.Parent = main
corner(hide, 12)

local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(58,58)
mini.Position = UDim2.new(0,18,0.5,-29)
mini.Text = "UI"
mini.Font = Enum.Font.GothamBlack
mini.TextSize = 16
mini.TextColor3 = Color3.new(1,1,1)
mini.BackgroundColor3 = Color3.fromRGB(18,18,28)
mini.Visible = false
mini.Parent = gui
corner(mini, 18)
stroke(mini, 0.15)
draggable(mini)

local function popIn(frame)
	frame.Visible = true
	frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale + 0.03, frame.Position.Y.Offset)
	tween(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale - 0.03, frame.Position.Y.Offset)
	}):Play()
end

enter.MouseButton1Click:Connect(function()
	play(clickSound)
	if box.Text == PASSWORD then
		status.Text = "ACCESS GRANTED  •  JAYVEE"
		status.TextColor3 = Color3.fromRGB(170,255,190)
		play(openSound)

		tween(secScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.7}):Play()
		task.wait(0.22)
		security.Visible = false
		popIn(main)
	else
		status.Text = "ACCESS DENIED  •  INVALID KEY"
		status.TextColor3 = Color3.fromRGB(255,120,120)
		tween(security, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true), {
			Position = UDim2.new(0.5, -185, 0.5, -125)
		}):Play()
	end
end)

demo.MouseButton1Click:Connect(function()
	play(clickSound)
	demo.Text = "ACTION READY  ✓"
	tween(demo, TweenInfo.new(0.18), {Size = UDim2.fromOffset(410, 48)}):Play()
	task.wait(0.18)
	tween(demo, TweenInfo.new(0.18), {Size = UDim2.fromOffset(425, 52)}):Play()
	task.wait(0.4)
	demo.Text = "DEMO ACTION"
end)

hide.MouseButton1Click:Connect(function()
	play(clickSound)
	main.Visible = false
	mini.Visible = true
end)

mini.MouseButton1Click:Connect(function()
	play(openSound)
	mini.Visible = false
	popIn(main)
end)
