-- JAYVEE | STEAL AN EGG UI V4
-- UI-only Roblox LocalScript for your own experience.
-- Place this as a LocalScript in StarterPlayerScripts or StarterGui.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local KEY = "STEALANEGGBYJAYVEE"

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius)}, obj)
end

local function outline(obj, color, thickness, transparency)
    make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, obj)
end

local function safeSound(id, volume)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or .2
    s.Parent = SoundService
    return s
end

local clickSound = safeSound("rbxassetid://6026984224", .25)
local openSound = safeSound("rbxassetid://12221967", .20)
local toggleSound = safeSound("rbxassetid://6895079853", .18)

local function play(sound)
    pcall(function() sound:Play() end)
end

local gui = make("ScreenGui", {
    Name = "JAYVEE_StealAnEgg_V4",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999
}, playerGui)

-- SECURITY WINDOW
local security = make("Frame", {
    Size = UDim2.fromOffset(390, 255),
    Position = UDim2.new(.5, -195, .5, -128),
    BackgroundColor3 = Color3.fromRGB(13, 11, 19),
    BorderSizePixel = 0
}, gui)
corner(security, 20)
outline(security, Color3.fromRGB(145, 88, 240), 1.5, .1)

local secLogo = make("Frame", {
    Position = UDim2.fromOffset(20, 20),
    Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = Color3.fromRGB(112, 64, 210),
    BorderSizePixel = 0
}, security)
corner(secLogo, 13)

make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "S",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 25
}, secLogo)

make("TextLabel", {
    Position = UDim2.fromOffset(76, 18),
    Size = UDim2.new(1, -96, 0, 30),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "STEAL AN EGG",
    TextColor3 = Color3.fromRGB(245, 242, 255),
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left
}, security)

make("TextLabel", {
    Position = UDim2.fromOffset(77, 46),
    Size = UDim2.new(1, -98, 0, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "SECURITY CHECK • JAYVEE",
    TextColor3 = Color3.fromRGB(150, 136, 172),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, security)

local keyBox = make("TextBox", {
    Position = UDim2.fromOffset(20, 83),
    Size = UDim2.new(1, -40, 0, 46),
    BackgroundColor3 = Color3.fromRGB(7, 7, 11),
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    PlaceholderText = "Enter security key",
    PlaceholderColor3 = Color3.fromRGB(92, 84, 105),
    Text = "",
    TextColor3 = Color3.fromRGB(240, 236, 248),
    TextSize = 13,
    Font = Enum.Font.Gotham
}, security)
corner(keyBox, 12)
outline(keyBox, Color3.fromRGB(72, 61, 91), 1, .2)

local unlock = make("TextButton", {
    Position = UDim2.fromOffset(20, 141),
    Size = UDim2.new(1, -40, 0, 43),
    BackgroundColor3 = Color3.fromRGB(111, 64, 211),
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "UNLOCK",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13
}, security)
corner(unlock, 11)

local status = make("TextLabel", {
    Position = UDim2.fromOffset(20, 194),
    Size = UDim2.new(1, -40, 0, 22),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Enter the key to continue.",
    TextColor3 = Color3.fromRGB(145, 133, 160),
    TextSize = 10
}, security)

-- MAIN WINDOW
local main = make("Frame", {
    Size = UDim2.fromOffset(760, 470),
    Position = UDim2.new(.5, -380, .5, -235),
    BackgroundColor3 = Color3.fromRGB(10, 9, 14),
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true
}, gui)
corner(main, 21)
outline(main, Color3.fromRGB(128, 77, 226), 1.5, .15)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 67),
    BackgroundTransparency = 1
}, main)

local logo = make("Frame", {
    Position = UDim2.fromOffset(16, 12),
    Size = UDim2.fromOffset(43, 43),
    BackgroundColor3 = Color3.fromRGB(111, 63, 207),
    BorderSizePixel = 0
}, top)
corner(logo, 13)

make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "S",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 24
}, logo)

make("TextLabel", {
    Position = UDim2.fromOffset(70, 11),
    Size = UDim2.fromOffset(250, 27),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Steal An Egg",
    TextColor3 = Color3.fromRGB(245, 242, 255),
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

make("TextLabel", {
    Position = UDim2.fromOffset(71, 36),
    Size = UDim2.fromOffset(220, 17),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "JAYVEE • FREE",
    TextColor3 = Color3.fromRGB(147, 132, 171),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

local hideButton = make("TextButton", {
    Position = UDim2.new(1, -78, 0, 16),
    Size = UDim2.fromOffset(28, 28),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = Color3.fromRGB(170, 160, 185),
    TextSize = 19
}, top)

local closeButton = make("TextButton", {
    Position = UDim2.new(1, -43, 0, 15),
    Size = UDim2.fromOffset(28, 28),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "×",
    TextColor3 = Color3.fromRGB(170, 160, 185),
    TextSize = 22
}, top)

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(12, 75),
    Size = UDim2.fromOffset(145, 380),
    BackgroundColor3 = Color3.fromRGB(13, 12, 19),
    BorderSizePixel = 0
}, main)
corner(sidebar, 16)
outline(sidebar, Color3.fromRGB(62, 52, 78), 1, .3)

local content = make("Frame", {
    Position = UDim2.fromOffset(171, 75),
    Size = UDim2.new(1, -184, 1, -87),
    BackgroundTransparency = 1
}, main)

local pages = {}
local tabs = {}

local function createPage(name)
    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(132, 82, 225),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    }, content)

    make("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 10)
    }, page)

    make("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    pages[name] = page
    return page
end

local function pageHeader(page, titleText, subText)
    make("TextLabel", {
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 29),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextColor3 = Color3.fromRGB(245, 242, 255),
        TextSize = 21,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)

    make("TextLabel", {
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subText,
        TextColor3 = Color3.fromRGB(140, 129, 157),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
end

local function toggle(parent, label, y)
    make("TextLabel", {
        Position = UDim2.fromOffset(10, y),
        Size = UDim2.new(1, -75, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextColor3 = Color3.fromRGB(200, 192, 209),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)

    local button = make("TextButton", {
        Position = UDim2.new(1, -54, 0, y),
        Size = UDim2.fromOffset(42, 23),
        BackgroundColor3 = Color3.fromRGB(43, 39, 50),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, parent)
    corner(button, 12)

    local knob = make("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = Color3.fromRGB(190, 184, 199),
        BorderSizePixel = 0
    }, button)
    corner(knob, 9)

    local enabled = false
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        play(toggleSound)
        TweenService:Create(button, TweenInfo.new(.16), {
            BackgroundColor3 = enabled and Color3.fromRGB(111, 64, 211) or Color3.fromRGB(43, 39, 50)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(.16), {
            Position = enabled and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3)
        }):Play()
    end)
end

local function accordion(page, titleText)
    local holder = make("Frame", {
        LayoutOrder = 10,
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Color3.fromRGB(17, 15, 24),
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, page)
    corner(holder, 12)
    outline(holder, Color3.fromRGB(61, 52, 76), 1, .3)

    local head = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = ""
    }, holder)

    local arrow = make("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.fromOffset(25, 52),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "›",
        TextColor3 = Color3.fromRGB(240, 234, 248),
        TextSize = 27
    }, head)

    make("TextLabel", {
        Position = UDim2.fromOffset(41, 0),
        Size = UDim2.new(1, -55, 0, 52),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextColor3 = Color3.fromRGB(239, 234, 247),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, head)

    local body = make("Frame", {
        Position = UDim2.fromOffset(10, 58),
        Size = UDim2.new(1, -20, 0, 85),
        BackgroundColor3 = Color3.fromRGB(10, 9, 15),
        BorderSizePixel = 0
    }, holder)
    corner(body, 10)
    outline(body, Color3.fromRGB(57, 48, 72), 1, .35)

    toggle(body, "Enable feature", 9)
    toggle(body, "Configuration", 39)

    body.Visible = false
    local expanded = false

    head.MouseButton1Click:Connect(function()
        play(clickSound)
        expanded = not expanded
        body.Visible = expanded
        arrow.Text = expanded and "⌄" or "›"
        TweenService:Create(holder, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, expanded and 153 or 52)
        }):Play()
    end)
end

-- HOME
local home = createPage("Home")
pageHeader(home, "Welcome, JAYVEE", "Creator information")

local info = make("Frame", {
    LayoutOrder = 10,
    Size = UDim2.new(1, 0, 0, 135),
    BackgroundColor3 = Color3.fromRGB(17, 15, 24),
    BorderSizePixel = 0
}, home)
corner(info, 14)
outline(info, Color3.fromRGB(66, 55, 84), 1, .3)

make("TextLabel", {
    Position = UDim2.fromOffset(15, 14),
    Size = UDim2.new(1, -30, 0, 24),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "JAYVEE",
    TextColor3 = Color3.fromRGB(177, 125, 255),
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left
}, info)

make("TextLabel", {
    Position = UDim2.fromOffset(15, 45),
    Size = UDim2.new(1, -30, 0, 70),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Creator: JAYVEE\nSteal An Egg UI V4\nClean • Mobile-friendly • Draggable",
    TextColor3 = Color3.fromRGB(177, 168, 190),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
}, info)

-- FARM
local farm = createPage("Farm")
pageHeader(farm, "Farm", "Press an arrow to open its configuration")

for _, name in ipairs({
    "Dr Scramble Lab & Mech",
    "Butterfly Bloom",
    "Wisp Companion",
    "Auto Steal",
    "Auto Place Egg",
    "Auto Treadmill",
    "Auto Hatch & Equip",
    "Auto Sell",
    "Auto Sell Lab Egg",
    "Auto Fuse Machine",
    "Auto Favorite"
}) do
    accordion(farm, name)
end

-- FUN
local fun = createPage("Fun")
pageHeader(fun, "Fun", "Toggle-style controls for your own experience")

for _, name in ipairs({
    "Instant Grab",
    "Anti Guard",
    "Anti Hit",
    "Anti Trap",
    "Add Money",
    "Add Speed"
}) do
    accordion(fun, name)
end

-- SETTINGS
local settings = createPage("Settings")
pageHeader(settings, "Settings", "Menu configuration")

accordion(settings, "Menu Size")
accordion(settings, "Interface")
accordion(settings, "UI Sounds")

-- TABS
for index, name in ipairs({"Home", "Farm", "Fun", "Settings"}) do
    local button = make("TextButton", {
        Position = UDim2.fromOffset(8, 8 + (index - 1) * 58),
        Size = UDim2.new(1, -16, 0, 48),
        BackgroundColor3 = Color3.fromRGB(17, 15, 24),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(150, 142, 166),
        TextSize = 12
    }, sidebar)
    corner(button, 12)
    tabs[name] = button

    button.MouseButton1Click:Connect(function()
        play(clickSound)
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end
        for tabName, tab in pairs(tabs) do
            tab.BackgroundColor3 = tabName == name and Color3.fromRGB(104, 61, 190) or Color3.fromRGB(17, 15, 24)
            tab.TextColor3 = tabName == name and Color3.new(1, 1, 1) or Color3.fromRGB(150, 142, 166)
        end
    end)
end

pages.Home.Visible = true
tabs.Home.BackgroundColor3 = Color3.fromRGB(104, 61, 190)
tabs.Home.TextColor3 = Color3.new(1, 1, 1)

-- DRAG MAIN WINDOW
local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then

        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- HIDDEN MENU ICON
local menuIcon = make("TextButton", {
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 15, .5, -26),
    BackgroundColor3 = Color3.fromRGB(105, 60, 200),
    BorderSizePixel = 0,
    Visible = false,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBlack,
    Text = "S",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 24
}, gui)
corner(menuIcon, 16)
outline(menuIcon, Color3.fromRGB(180, 125, 255), 1.5, .1)

menuIcon.MouseButton1Click:Connect(function()
    play(openSound)
    menuIcon.Visible = false
    main.Visible = true
end)

hideButton.MouseButton1Click:Connect(function()
    play(clickSound)
    main.Visible = false
    menuIcon.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
    play(clickSound)
    gui:Destroy()
end)

-- SECURITY
local function unlock()
    play(clickSound)

    if keyBox.Text == KEY then
        status.Text = "ACCESS GRANTED"
        status.TextColor3 = Color3.fromRGB(100, 255, 175)
        play(openSound)

        task.wait(.25)
        security.Visible = false
        main.Visible = true
    else
        status.Text = "INVALID KEY"
        status.TextColor3 = Color3.fromRGB(255, 100, 130)
        keyBox.Text = ""
    end
end

unlock.MouseButton1Click:Connect(unlock)

keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        unlock()
    end
end)
