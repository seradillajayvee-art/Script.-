-- JAYVEE UI
-- Roblox Studio LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// CONFIG
local SECURITY_PASSWORD = "JAYVEE"

--// CLEAN OLD UI
local old = PlayerGui:FindFirstChild("JAYVEE_UI")
if old then
	old:Destroy()
end

--// SOUNDS
local function playSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.35
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

local CLICK_SOUND = 6026984224
local OPEN_SOUND = 6895079853
local ERROR_SOUND = 138090596

--// HELPERS
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(25,25,25)
	s.Thickness = 1.5
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function makeDraggable(frame, handle)
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

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart

			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// GUI
local Gui = Instance.new("ScreenGui")
Gui.Name = "JAYVEE_UI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

--==================================================
-- SECURITY
--==================================================

local Security = Instance.new("Frame")
Security.Name = "Security"
Security.Size = UDim2.fromOffset(380, 235)
Security.Position = UDim2.new(0.5, -190, 0.5, -117)
Security.BackgroundColor3 = Color3.fromRGB(255,255,255)
Security.Parent = Gui
corner(Security, 18)
stroke(Security)

local SecurityScale = Instance.new("UIScale")
SecurityScale.Parent = Security

local SecurityTop = Instance.new("Frame")
SecurityTop.Size = UDim2.new(1,0,0,58)
SecurityTop.BackgroundColor3 = Color3.fromRGB(245,245,245)
SecurityTop.BorderSizePixel = 0
SecurityTop.Parent = Security
corner(SecurityTop,18)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1,-30,0,30)
Title.Position = UDim2.fromOffset(15,7)
Title.Font = Enum.Font.GothamBlack
Title.Text = "SECURITY"
Title.TextColor3 = Color3.fromRGB(15,15,15)
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = SecurityTop

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Size = UDim2.new(1,-30,0,20)
Subtitle.Position = UDim2.fromOffset(15,33)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "SECURITY  →  MENU"
Subtitle.TextColor3 = Color3.fromRGB(110,110,110)
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = SecurityTop

local PassBox = Instance.new("TextBox")
PassBox.Size = UDim2.new(1,-40,0,42)
PassBox.Position = UDim2.fromOffset(20,78)
PassBox.BackgroundColor3 = Color3.fromRGB(242,242,242)
PassBox.PlaceholderText = "Enter security key..."
PassBox.Text = ""
PassBox.ClearTextOnFocus = false
PassBox.Font = Enum.Font.GothamMedium
PassBox.TextColor3 = Color3.fromRGB(20,20,20)
PassBox.PlaceholderColor3 = Color3.fromRGB(130,130,130)
PassBox.TextSize = 14
PassBox.Parent = Security
corner(PassBox,12)
stroke(PassBox,0.65)

local Enter = Instance.new("TextButton")
Enter.Size = UDim2.new(1,-40,0,42)
Enter.Position = UDim2.fromOffset(20,132)
Enter.BackgroundColor3 = Color3.fromRGB(20,20,20)
Enter.Text = "ENTER  →"
Enter.Font = Enum.Font.GothamBold
Enter.TextColor3 = Color3.fromRGB(255,255,255)
Enter.TextSize = 14
Enter.AutoButtonColor = false
Enter.Parent = Security
corner(Enter,12)

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Size = UDim2.new(1,-40,0,30)
Status.Position = UDim2.fromOffset(20,184)
Status.Font = Enum.Font.GothamMedium
Status.Text = "SECURE CONNECTION"
Status.TextColor3 = Color3.fromRGB(100,100,100)
Status.TextSize = 11
Status.Parent = Security

makeDraggable(Security, SecurityTop)

--==================================================
-- MAIN MENU
--==================================================

local Main = Instance.new("Frame")
Main.Name = "MainMenu"
Main.Size = UDim2.fromOffset(720,470)
Main.Position = UDim2.new(0.5,-360,0.5,-235)
Main.BackgroundColor3 = Color3.fromRGB(255,255,255)
Main.Visible = false
Main.Parent = Gui
corner(Main,20)
stroke(Main)

local MainScale = Instance.new("UIScale")
MainScale.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1,0,0,65)
Top.BackgroundColor3 = Color3.fromRGB(245,245,245)
Top.BorderSizePixel = 0
Top.Parent = Main
corner(Top,20)

local MainTitle = Instance.new("TextLabel")
MainTitle.BackgroundTransparency = 1
MainTitle.Size = UDim2.fromOffset(300,35)
MainTitle.Position = UDim2.fromOffset(20,8)
MainTitle.Text = "JAYVEE"
MainTitle.Font = Enum.Font.GothamBlack
MainTitle.TextColor3 = Color3.fromRGB(15,15,15)
MainTitle.TextSize = 24
MainTitle.TextXAlignment = Enum.TextXAlignment.Left
MainTitle.Parent = Top

local MainSub = Instance.new("TextLabel")
MainSub.BackgroundTransparency = 1
MainSub.Size = UDim2.fromOffset(400,20)
MainSub.Position = UDim2.fromOffset(22,38)
MainSub.Text = "JUJUTSU-INSPIRED CONTROL PANEL"
MainSub.Font = Enum.Font.GothamMedium
MainSub.TextColor3 = Color3.fromRGB(120,120,120)
MainSub.TextSize = 9
MainSub.TextXAlignment = Enum.TextXAlignment.Left
MainSub.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(42,42)
Close.Position = UDim2.new(1,-53,0,11)
Close.BackgroundColor3 = Color3.fromRGB(230,230,230)
Close.Text = "×"
Close.Font = Enum.Font.GothamBold
Close.TextColor3 = Color3.fromRGB(20,20,20)
Close.TextSize = 25
Close.AutoButtonColor = false
Close.Parent = Top
corner(Close,12)

makeDraggable(Main, Top)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,150,1,-80)
Sidebar.Position = UDim2.fromOffset(15,75)
Sidebar.BackgroundColor3 = Color3.fromRGB(247,247,247)
Sidebar.Parent = Main
corner(Sidebar,15)
stroke(Sidebar,0.75)

local Tabs = {"HOME","MOVESETS","PLAYER","SETTINGS"}
local TabButtons = {}

for i,name in ipairs(Tabs) do
	local B = Instance.new("TextButton")
	B.Name = name
	B.Size = UDim2.new(1,-20,0,43)
	B.Position = UDim2.fromOffset(10,10+(i-1)*51)
	B.BackgroundColor3 = i == 1 and Color3.fromRGB(20,20,20) or Color3.fromRGB(238,238,238)
	B.Text = name
	B.Font = Enum.Font.GothamBold
	B.TextSize = 11
	B.TextColor3 = i == 1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(50,50,50)
	B.AutoButtonColor = false
	B.Parent = Sidebar
	corner(B,11)

	TabButtons[name] = B
end

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-185,1,-80)
Content.Position = UDim2.fromOffset(175,75)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}

for _,name in ipairs(Tabs) do
	local Page = Instance.new("ScrollingFrame")
	Page.Name = name .. "Page"
	Page.Size = UDim2.fromScale(1,1)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.CanvasSize = UDim2.new(0,0,0,0)
	Page.Visible = name == "HOME"
	Page.Parent = Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = Page

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0,5)
	padding.PaddingLeft = UDim.new(0,5)
	padding.PaddingRight = UDim.new(0,10)
	padding.PaddingBottom = UDim.new(0,10)
	padding.Parent = Page

	Pages[name] = Page
end

local function header(page, title, description)
	local H = Instance.new("Frame")
	H.Size = UDim2.new(1,0,0,72)
	H.BackgroundColor3 = Color3.fromRGB(248,248,248)
	H.Parent = page
	corner(H,14)
	stroke(H,0.8)

	local T = Instance.new("TextLabel")
	T.BackgroundTransparency = 1
	T.Size = UDim2.new(1,-25,0,30)
	T.Position = UDim2.fromOffset(15,10)
	T.Text = title
	T.Font = Enum.Font.GothamBlack
	T.TextSize = 20
	T.TextColor3 = Color3.fromRGB(15,15,15)
	T.TextXAlignment = Enum.TextXAlignment.Left
	T.Parent = H

	local D = Instance.new("TextLabel")
	D.BackgroundTransparency = 1
	D.Size = UDim2.new(1,-25,0,25)
	D.Position = UDim2.fromOffset(15,38)
	D.Text = description
	D.Font = Enum.Font.Gotham
	D.TextSize = 11
	D.TextColor3 = Color3.fromRGB(110,110,110)
	D.TextXAlignment = Enum.TextXAlignment.Left
	D.Parent = H
end

-- HOME
header(
	Pages.HOME,
	"JAYVEE CONTROL",
	"Clean • Fast • Mobile Friendly"
)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1,0,0,170)
Info.BackgroundColor3 = Color3.fromRGB(248,248,248)
Info.Text = [[

CREATOR
JAYVEE

ABOUT
A clean JJS-inspired interface built for
Roblox Studio projects.

Use the tabs on the left to navigate.
All interface functions are locally handled.

STATUS
● UI ONLINE
● SECURITY READY
]]
Info.Font = Enum.Font.GothamMedium
Info.TextSize = 12
Info.TextColor3 = Color3.fromRGB(35,35,35)
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.Parent = Pages.HOME
corner(Info,14)
stroke(Info,0.8)

-- MOVESETS
header(
	Pages.MOVESETS,
	"MOVESETS",
	"Select a moveset for your own Roblox Studio project."
)

local Movesets = {
	"GOJO",
	"YUJI",
	"MEGUMI",
	"TOJI",
	"HAKARI",
	"MAHITO",
	"MAKI",
	"CHOSO"
}

local selectedMoveset = "NONE"

for _,moveName in ipairs(Movesets) do
	local B = Instance.new("TextButton")
	B.Size = UDim2.new(1,0,0,48)
	B.BackgroundColor3 = Color3.fromRGB(248,248,248)
	B.Text = "  " .. moveName
	B.Font = Enum.Font.GothamBold
	B.TextSize = 12
	B.TextColor3 = Color3.fromRGB(25,25,25)
	B.TextXAlignment = Enum.TextXAlignment.Left
	B.AutoButtonColor = false
	B.Parent = Pages.MOVESETS
	corner(B,12)
	stroke(B,0.8)

	B.MouseButton1Click:Connect(function()
		selectedMoveset = moveName
		playSound(CLICK_SOUND,0.3)

		for _,obj in ipairs(Pages.MOVESETS:GetChildren()) do
			if obj:IsA("TextButton") then
				obj.BackgroundColor3 = Color3.fromRGB(248,248,248)
			end
		end

		B.BackgroundColor3 = Color3.fromRGB(225,225,225)
	end)
end

-- PLAYER
header(
	Pages.PLAYER,
	"PLAYER",
	"Local player information and visual tools."
)

local PlayerInfo = Instance.new("TextLabel")
PlayerInfo.Size = UDim2.new(1,0,0,145)
PlayerInfo.BackgroundColor3 = Color3.fromRGB(248,248,248)
PlayerInfo.Font = Enum.Font.GothamMedium
PlayerInfo.TextSize = 12
PlayerInfo.TextColor3 = Color3.fromRGB(35,35,35)
PlayerInfo.TextXAlignment = Enum.TextXAlignment.Left
PlayerInfo.TextYAlignment = Enum.TextYAlignment.Top
PlayerInfo.Parent = Pages.PLAYER
corner(PlayerInfo,14)
stroke(PlayerInfo,0.8)

local function updatePlayerInfo()
	local char = Player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	PlayerInfo.Text =
		"\n  PLAYER INFORMATION\n\n" ..
		"  Name: " .. Player.Name .. "\n" ..
		"  Display: " .. Player.DisplayName .. "\n" ..
		"  UserId: " .. tostring(Player.UserId) .. "\n" ..
		"  Health: " .. (hum and math.floor(hum.Health) or "N/A") .. "\n" ..
		"  Moveset: " .. selectedMoveset
end

updatePlayerInfo()

local Refresh = Instance.new("TextButton")
Refresh.Size = UDim2.new(1,0,0,45)
Refresh.BackgroundColor3 = Color3.fromRGB(20,20,20)
Refresh.Text = "REFRESH PLAYER INFO"
Refresh.Font = Enum.Font.GothamBold
Refresh.TextSize = 11
Refresh.TextColor3 = Color3.fromRGB(255,255,255)
Refresh.AutoButtonColor = false
Refresh.Parent = Pages.PLAYER
corner(Refresh,12)

Refresh.MouseButton1Click:Connect(function()
	updatePlayerInfo()
	playSound(CLICK_SOUND,0.3)
end)

-- Legit visual/debug toggles
local function createToggle(page, text, callback)
	local B = Instance.new("TextButton")
	B.Size = UDim2.new(1,0,0,45)
	B.BackgroundColor3 = Color3.fromRGB(248,248,248)
	B.Text = text .. "  [ OFF ]"
	B.Font = Enum.Font.GothamBold
	B.TextSize = 11
	B.TextColor3 = Color3.fromRGB(30,30,30)
	B.AutoButtonColor = false
	B.Parent = page
	corner(B,12)
	stroke(B,0.8)

	local enabled = false

	B.MouseButton1Click:Connect(function()
		enabled = not enabled
		B.Text = text .. (enabled and "  [ ON ]" or "  [ OFF ]")
		playSound(CLICK_SOUND,0.25)
		callback(enabled)
	end)
end

createToggle(Pages.PLAYER,"SHOW CHARACTER NAME",function(enabled)
	local char = Player.Character
	if not char then return end

	local head = char:FindFirstChild("Head")
	if not head then return end

	local oldTag = head:FindFirstChild("JAYVEE_NameTag")

	if enabled then
		if not oldTag then
			local bb = Instance.new("BillboardGui")
			bb.Name = "JAYVEE_NameTag"
			bb.Size = UDim2.fromOffset(160,35)
			bb.StudsOffset = Vector3.new(0,2.5,0)
			bb.AlwaysOnTop = true
			bb.Parent = head

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1,1)
			label.BackgroundTransparency = 1
			label.Text = Player.DisplayName
			label.Font = Enum.Font.GothamBold
			label.TextSize = 13
			label.TextColor3 = Color3.fromRGB(255,255,255)
			label.TextStrokeTransparency = 0.3
			label.Parent = bb
		end
	else
		if oldTag then
			oldTag:Destroy()
		end
	end
end)

-- SETTINGS
header(
	Pages.SETTINGS,
	"SETTINGS",
	"Customize the interface."
)

createToggle(Pages.SETTINGS,"UI SOUND",function(enabled)
	-- UI sound preference toggle
end)

createToggle(Pages.SETTINGS,"UI ANIMATION",function(enabled)
	-- Animation preference toggle
end)

createToggle(Pages.SETTINGS,"COMPACT MODE",function(enabled)
	if enabled then
		MainScale.Scale = 0.85
	else
		MainScale.Scale = 1
	end
end)

local Reset = Instance.new("TextButton")
Reset.Size = UDim2.new(1,0,0,45)
Reset.BackgroundColor3 = Color3.fromRGB(235,235,235)
Reset.Text = "RESET UI"
Reset.Font = Enum.Font.GothamBold
Reset.TextSize = 11
Reset.TextColor3 = Color3.fromRGB(30,30,30)
Reset.AutoButtonColor = false
Reset.Parent = Pages.SETTINGS
corner(Reset,12)

Reset.MouseButton1Click:Connect(function()
	MainScale.Scale = 1
	Main.Position = UDim2.new(0.5,-360,0.5,-235)
	playSound(CLICK_SOUND,0.3)
end)

--==================================================
-- TAB SYSTEM
--==================================================

local function switchTab(name)
	playSound(CLICK_SOUND,0.2)

	for tabName,button in pairs(TabButtons) do
		button.BackgroundColor3 =
			tabName == name
			and Color3.fromRGB(20,20,20)
			or Color3.fromRGB(238,238,238)

		button.TextColor3 =
			tabName == name
			and Color3.fromRGB(255,255,255)
			or Color3.fromRGB(50,50,50)
	end

	for pageName,page in pairs(Pages) do
		page.Visible = pageName == name
	end
end

for name,button in pairs(TabButtons) do
	button.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

--==================================================
-- CLOSE / OPEN
--==================================================

Close.MouseButton1Click:Connect(function()
	playSound(CLICK_SOUND,0.25)

	tween(Main,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{
		Size = UDim2.fromOffset(0,0)
	}).Completed:Connect(function()
		Main.Visible = false
		Main.Size = UDim2.fromOffset(720,470)
	end)
end)

-- Floating menu button
local MenuButton = Instance.new("TextButton")
MenuButton.Name = "MenuButton"
MenuButton.Size = UDim2.fromOffset(55,55)
MenuButton.Position = UDim2.new(1,-75,1,-75)
MenuButton.BackgroundColor3 = Color3.fromRGB(20,20,20)
MenuButton.Text = "J"
MenuButton.Font = Enum.Font.GothamBlack
MenuButton.TextColor3 = Color3.fromRGB(255,255,255)
MenuButton.TextSize = 22
MenuButton.Visible = false
MenuButton.AutoButtonColor = false
MenuButton.Parent = Gui
corner(MenuButton,17)

MenuButton.MouseButton1Click:Connect(function()
	playSound(OPEN_SOUND,0.25)

	Main.Visible = true
	Main.Size = UDim2.fromOffset(0,0)

	tween(Main,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
		Size = UDim2.fromOffset(720,470)
	})

	MenuButton.Visible = false
end)

--==================================================
-- SECURITY LOGIN
--==================================================

local function openMain()
	playSound(OPEN_SOUND,0.4)

	Security.Visible = false
	Main.Visible = true
	Main.Size = UDim2.fromOffset(0,0)

	tween(Main,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
		Size = UDim2.fromOffset(720,470)
	})
end

Enter.MouseButton1Click:Connect(function()
	if PassBox.Text == SECURITY_PASSWORD then
		Status.Text = "ACCESS GRANTED  ✓"
		Status.TextColor3 = Color3.fromRGB(30,130,70)

		playSound(OPEN_SOUND,0.4)

		task.wait(0.35)
		openMain()
	else
		Status.Text = "ACCESS DENIED  ✕"
		Status.TextColor3 = Color3.fromRGB(190,45,45)

		playSound(ERROR_SOUND,0.35)

		tween(Security,TweenInfo.new(0.05),{
			Position = UDim2.new(0.5,-185,0.5,-117)
		}).Completed:Connect(function()
			tween(Security,TweenInfo.new(0.05),{
				Position = UDim2.new(0.5,-195,0.5,-117)
			}).Completed:Connect(function()
				tween(Security,TweenInfo.new(0.05),{
					Position = UDim2.new(0.5,-190,0.5,-117)
				})
			end)
		end)
	end
end)

PassBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		Enter:Activate()
	end
end)

--==================================================
-- RESPONSIVE UI
--==================================================

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local viewport = camera.ViewportSize

	if viewport.X < 600 then
		MainScale.Scale = math.clamp(viewport.X / 760,0.65,0.9)
		SecurityScale.Scale = math.clamp(viewport.X / 450,0.75,1)
	else
		MainScale.Scale = 1
		SecurityScale.Scale = 1
	end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)

task.defer(function()
	task.wait(0.5)
	updateScale()
end)

-- CHARACTER UPDATE
Player.CharacterAdded:Connect(function()
	task.wait(1)
	updatePlayerInfo()
end)