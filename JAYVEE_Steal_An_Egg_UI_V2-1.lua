-- STEAL AN EGG | JAYVEE UI V2
-- Clean Roblox LocalScript UI
-- UI-only template: feature toggles are placeholders for your own game's systems.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KEY = "STEALANEGGBYJAYVEE"

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function gradient(parent, c1, c2, rotation)
    return new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rotation or 90
    }, parent)
end

local function tween(obj, props, time)
    return TweenService:Create(obj, TweenInfo.new(time or .25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://6026984224"
clickSound.Volume = 0.35
clickSound.Parent = SoundService

local openSound = Instance.new("Sound")
openSound.SoundId = "rbxassetid://12221967"
openSound.Volume = 0.25
openSound.Parent = SoundService

local function click()
    clickSound:Play()
end

local gui = new("ScreenGui", {
    Name = "JayveeStealAnEggUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

-- SECURITY
local security = new("Frame", {
    Name = "Security",
    Size = UDim2.fromOffset(390, 245),
    Position = UDim2.new(.5, -195, .5, -122),
    BackgroundColor3 = Color3.fromRGB(12, 10, 20),
    BorderSizePixel = 0
}, gui)
corner(security, 20)
stroke(security, Color3.fromRGB(145, 83, 255), 1.5, .15)
gradient(security, Color3.fromRGB(25, 18, 40), Color3.fromRGB(9, 9, 15), 135)

new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(25, 22),
    Size = UDim2.new(1, -50, 0, 34),
    Font = Enum.Font.GothamBold,
    Text = "STEAL AN EGG",
    TextColor3 = Color3.fromRGB(245, 242, 255),
    TextSize = 25,
    TextXAlignment = Enum.TextXAlignment.Left
}, security)

new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(27, 57),
    Size = UDim2.new(1, -54, 0, 25),
    Font = Enum.Font.Gotham,
    Text = "SECURITY CHECK  •  JAYVEE",
    TextColor3 = Color3.fromRGB(160, 140, 190),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, security)

local keyBox = new("TextBox", {
    Position = UDim2.fromOffset(25, 100),
    Size = UDim2.new(1, -50, 0, 48),
    BackgroundColor3 = Color3.fromRGB(8, 8, 13),
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Enter security key",
    PlaceholderColor3 = Color3.fromRGB(100, 94, 115),
    Text = "",
    TextColor3 = Color3.fromRGB(235, 230, 245),
    TextSize = 14
}, security)
corner(keyBox, 12)
stroke(keyBox, Color3.fromRGB(90, 72, 120), 1)

local unlock = new("TextButton", {
    Position = UDim2.fromOffset(25, 163),
    Size = UDim2.new(1, -50, 0, 43),
    BackgroundColor3 = Color3.fromRGB(117, 67, 220),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "UNLOCK",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    AutoButtonColor = false
}, security)
corner(unlock, 12)
gradient(unlock, Color3.fromRGB(151, 91, 255), Color3.fromRGB(91, 49, 184), 0)

local errorLabel = new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(25, 211),
    Size = UDim2.new(1, -50, 0, 20),
    Font = Enum.Font.Gotham,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 105, 130),
    TextSize = 11
}, security)

-- MAIN
local main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(780, 485),
    Position = UDim2.new(.5, -390, .5, -242),
    BackgroundColor3 = Color3.fromRGB(10, 9, 15),
    BorderSizePixel = 0,
    Visible = false
}, gui)
corner(main, 22)
stroke(main, Color3.fromRGB(130, 78, 230), 1.5, .2)
gradient(main, Color3.fromRGB(22, 17, 34), Color3.fromRGB(8, 8, 13), 135)

local top = new("Frame", {
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundTransparency = 1
}, main)

local logo = new("Frame", {
    Position = UDim2.fromOffset(20, 16),
    Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = Color3.fromRGB(111, 62, 205),
    BorderSizePixel = 0
}, top)
corner(logo, 14)
gradient(logo, Color3.fromRGB(170, 98, 255), Color3.fromRGB(78, 41, 166), 135)

new("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBlack,
    Text = "S",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 25
}, logo)

new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(74, 15),
    Size = UDim2.fromOffset(260, 28),
    Font = Enum.Font.GothamBold,
    Text = "Steal An Egg",
    TextColor3 = Color3.fromRGB(245, 242, 255),
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(75, 39),
    Size = UDim2.fromOffset(260, 20),
    Font = Enum.Font.Gotham,
    Text = "JAYVEE  •  FREE",
    TextColor3 = Color3.fromRGB(150, 130, 180),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

local close = new("TextButton", {
    Position = UDim2.new(1, -48, 0, 19),
    Size = UDim2.fromOffset(30, 30),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "×",
    TextColor3 = Color3.fromRGB(170, 160, 190),
    TextSize = 24
}, top)

local minimize = new("TextButton", {
    Position = UDim2.new(1, -84, 0, 19),
    Size = UDim2.fromOffset(30, 30),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = Color3.fromRGB(170, 160, 190),
    TextSize = 20
}, top)

local sidebar = new("Frame", {
    Position = UDim2.fromOffset(14, 80),
    Size = UDim2.fromOffset(150, 387),
    BackgroundColor3 = Color3.fromRGB(13, 12, 20),
    BorderSizePixel = 0
}, main)
corner(sidebar, 17)
stroke(sidebar, Color3.fromRGB(67, 55, 86), 1, .35)

local content = new("Frame", {
    Position = UDim2.fromOffset(178, 80),
    Size = UDim2.new(1, -192, 1, -94),
    BackgroundTransparency = 1
}, main)

local tabs = {}
local pages = {}

local function createPage(name)
    local page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(130, 85, 220),
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, content)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 5)
    }, page)
    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)
    pages[name] = page
    return page
end

local function pageTitle(page, title, subtitle)
    new("TextLabel", {
        LayoutOrder = 1,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,30),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(245,242,255),
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
    new("TextLabel", {
        LayoutOrder = 2,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,24),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Color3.fromRGB(145,135,165),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
end

local function card(page, title, desc, callback)
    local b = new("TextButton", {
        LayoutOrder = 10,
        Size = UDim2.new(1,0,0,62),
        BackgroundColor3 = Color3.fromRGB(17,15,25),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, page)
    corner(b, 14)
    stroke(b, Color3.fromRGB(62,53,78), 1, .35)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,8),
        Size = UDim2.new(1,-100,0,22),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(235,230,245),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    }, b)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,32),
        Size = UDim2.new(1,-100,0,20),
        Font = Enum.Font.Gotham,
        Text = desc,
        TextColor3 = Color3.fromRGB(125,118,142),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, b)
    local toggle = new("Frame", {
        Position = UDim2.new(1,-67,.5,-13),
        Size = UDim2.fromOffset(46,26),
        BackgroundColor3 = Color3.fromRGB(45,41,53),
        BorderSizePixel = 0
    }, b)
    corner(toggle, 13)
    local knob = new("Frame", {
        Position = UDim2.fromOffset(3,3),
        Size = UDim2.fromOffset(20,20),
        BackgroundColor3 = Color3.fromRGB(190,185,200),
        BorderSizePixel = 0
    }, toggle)
    corner(knob, 10)
    local enabled = false
    local function set(v)
        enabled = v
        click()
        tween(toggle, {BackgroundColor3 = v and Color3.fromRGB(116,67,215) or Color3.fromRGB(45,41,53)}, .18):Play()
        tween(knob, {Position = v and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)}, .18):Play()
        if callback then callback(v) end
    end
    b.MouseButton1Click:Connect(function() set(not enabled) end)
    return b
end

local home = createPage("Home")
pageTitle(home, "Welcome, JAYVEE", "Clean control center • Steal An Egg")

local info = new("Frame", {
    LayoutOrder = 10,
    Size = UDim2.new(1,0,0,145),
    BackgroundColor3 = Color3.fromRGB(17,15,25),
    BorderSizePixel = 0
}, home)
corner(info, 16)
stroke(info, Color3.fromRGB(74,60,95), 1, .3)
new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18,16),
    Size = UDim2.new(1,-36,0,28),
    Font = Enum.Font.GothamBold,
    Text = "JAYVEE",
    TextColor3 = Color3.fromRGB(177,125,255),
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left
}, info)
new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18,49),
    Size = UDim2.new(1,-36,0,75),
    Font = Enum.Font.Gotham,
    Text = "Creator: JAYVEE\nUI edition: Clean Purple\nBuilt with a simple mobile-first layout.",
    TextColor3 = Color3.fromRGB(180,173,193),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
}, info)

local farm = createPage("Farm")
pageTitle(farm, "Farm", "Automation-style controls for your own experience")
card(farm, "Auto Collect", "Toggle your own collection system.", function() end)
card(farm, "Auto Place Egg", "Toggle your own egg placement system.", function() end)
card(farm, "Auto Hatch", "Toggle your own hatching system.", function() end)
card(farm, "Auto Sell", "Toggle your own selling system.", function() end)
card(farm, "Auto Favorite", "Toggle your own favorite system.", function() end)

local fun = createPage("Fun")
pageTitle(fun, "Fun", "Simple on/off controls")
card(fun, "Instant Grab", "UI control for your own grab system.", function(enabled)
    -- Connect your own game's grab logic here.
end)
card(fun, "Anti Guard", "UI control for your own guard system.", function(enabled)
    -- Connect your own game's guard logic here.
end)
card(fun, "Anti Hit", "UI control for your own hit system.", function(enabled)
    -- Connect your own game's hit logic here.
end)
card(fun, "Anti Trap", "UI control for your own trap system.", function(enabled)
    -- Connect your own game's trap logic here.
end)
card(fun, "Add Money", "UI control for your own game's currency system.", function(enabled)
    -- Connect your own server-authorized money system here.
end)
card(fun, "Add Speed", "UI control for your own game's movement system.", function(enabled)
    -- Connect your own server-authorized speed system here.
end)

local settings = createPage("Settings")
pageTitle(settings, "Settings", "Menu configuration")

local function settingButton(title, desc, action)
    local b = new("TextButton", {
        LayoutOrder = 10,
        Size = UDim2.new(1,0,0,58),
        BackgroundColor3 = Color3.fromRGB(22,20,29),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, settings)
    corner(b, 12)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,7),
        Size = UDim2.new(1,-30,0,22),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(235,230,245),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, b)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,30),
        Size = UDim2.new(1,-30,0,18),
        Font = Enum.Font.Gotham,
        Text = desc,
        TextColor3 = Color3.fromRGB(130,123,145),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, b)
    b.MouseButton1Click:Connect(function()
        click()
        if action then action() end
    end)
end

settingButton("UI Sound", "Enable menu click sounds.", function() end)
settingButton("Compact Mode", "Switch to a smaller menu layout.", function() end)
settingButton("Reset UI", "Restore the default page.", function() end)
settingButton("About", "Steal An Egg • JAYVEE UI", function() end)

local tabNames = {"Home", "Farm", "Fun", "Settings"}
for i, name in ipairs(tabNames) do
    local b = new("TextButton", {
        Position = UDim2.fromOffset(9, 9 + (i-1)*61),
        Size = UDim2.new(1,-18,0,51),
        BackgroundColor3 = Color3.fromRGB(17,15,25),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(150,143,166),
        TextSize = 13
    }, sidebar)
    corner(b, 13)
    tabs[name] = b
    b.MouseButton1Click:Connect(function()
        click()
        for n, p in pairs(pages) do
            p.Visible = n == name
        end
        for n, t in pairs(tabs) do
            tween(t, {
                BackgroundColor3 = n == name and Color3.fromRGB(104,61,190) or Color3.fromRGB(17,15,25),
                TextColor3 = n == name and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,143,166)
            }, .2):Play()
        end
    end)
end

pages.Home.Visible = true
tabs.Home.BackgroundColor3 = Color3.fromRGB(104,61,190)
tabs.Home.TextColor3 = Color3.new(1,1,1)

-- DRAG
local dragging = false
local dragStart
local startPos

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
local savedSize = main.Size

minimize.MouseButton1Click:Connect(function()
    click()
    minimized = not minimized
    if minimized then
        tween(main, {Size = UDim2.fromOffset(320,72)}, .25):Play()
        sidebar.Visible = false
        content.Visible = false
    else
        tween(main, {Size = savedSize}, .25):Play()
        task.delay(.22, function()
            sidebar.Visible = true
            content.Visible = true
        end)
    end
end)

close.MouseButton1Click:Connect(function()
    click()
    tween(main, {BackgroundTransparency = 1}, .2):Play()
    task.wait(.2)
    main.Visible = false
end)

unlock.MouseButton1Click:Connect(function()
    click()
    if keyBox.Text == KEY then
        errorLabel.Text = "ACCESS GRANTED"
        errorLabel.TextColor3 = Color3.fromRGB(105, 255, 177)
        task.wait(.35)
        security.Visible = false
        main.Visible = true
        openSound:Play()
    else
        errorLabel.Text = "INVALID KEY"
        keyBox.Text = ""
        tween(security, {Position = UDim2.new(.5,-190,.5,-122)}, .08):Play()
        task.wait(.08)
        tween(security, {Position = UDim2.new(.5,-200,.5,-122)}, .08):Play()
        task.wait(.08)
        tween(security, {Position = UDim2.new(.5,-195,.5,-122)}, .08):Play()
    end
end)

keyBox.FocusLost:Connect(function(enter)
    if enter then
        unlock:Activate()
    end
end)