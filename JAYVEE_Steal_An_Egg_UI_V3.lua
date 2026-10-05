-- JAYVEE | STEAL AN EGG UI V3
-- Clean accordion-style UI inspired by the supplied reference.
-- The controls are UI-only and are intended to be connected to your own Roblox game's systems.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local KEY = "STEALANEGGBYJAYVEE"

local function New(class, props, parent)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end

local function Corner(p,r) New("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function Stroke(p,c,t,tr)
    New("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0},p)
end
local function Grad(p,a,b,rot)
    New("UIGradient",{Color=ColorSequence.new(a,b),Rotation=rot or 90},p)
end
local function Tw(o,props,t)
    return TweenService:Create(o,TweenInfo.new(t or .2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
end

local clickS = New("Sound",{SoundId="rbxassetid://6026984224",Volume=.28},SoundService)
local openS = New("Sound",{SoundId="rbxassetid://12221967",Volume=.22},SoundService)
local toggleS = New("Sound",{SoundId="rbxassetid://6895079853",Volume=.20},SoundService)
local function Snd(s) pcall(function() s:Play() end) end

local gui = New("ScreenGui",{Name="JAYVEE_StealAnEgg_V3",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)

-- SECURITY
local security = New("Frame",{
    Size=UDim2.fromOffset(410,270),
    Position=UDim2.new(.5,-205,.5,-135),
    BackgroundColor3=Color3.fromRGB(11,9,17),
    BorderSizePixel=0
},gui)
Corner(security,22)
Stroke(security,Color3.fromRGB(142,83,245),1.5,.12)
Grad(security,Color3.fromRGB(28,20,43),Color3.fromRGB(8,8,13),135)

local secLogo=New("Frame",{Position=UDim2.fromOffset(24,22),Size=UDim2.fromOffset(45,45),BackgroundColor3=Color3.fromRGB(112,62,211),BorderSizePixel=0},security)
Corner(secLogo,14); Grad(secLogo,Color3.fromRGB(174,104,255),Color3.fromRGB(75,38,160),135)
New("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBlack,Text="S",TextColor3=Color3.new(1,1,1),TextSize=26},secLogo)

New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(82,20),Size=UDim2.new(1,-105,0,30),Font=Enum.Font.GothamBold,Text="STEAL AN EGG",TextColor3=Color3.fromRGB(247,244,255),TextSize=23,TextXAlignment=Enum.TextXAlignment.Left},security)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(83,48),Size=UDim2.new(1,-105,0,22),Font=Enum.Font.Gotham,Text="SECURITY GATE  •  JAYVEE",TextColor3=Color3.fromRGB(155,138,182),TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},security)

local key=New("TextBox",{Position=UDim2.fromOffset(24,88),Size=UDim2.new(1,-48,0,50),BackgroundColor3=Color3.fromRGB(7,7,11),BorderSizePixel=0,ClearTextOnFocus=false,PlaceholderText="Enter security key",PlaceholderColor3=Color3.fromRGB(91,84,105),Text="",TextColor3=Color3.fromRGB(240,236,248),TextSize=14,Font=Enum.Font.Gotham},security)
Corner(key,13); Stroke(key,Color3.fromRGB(76,64,96),1,.25)

local unlock=New("TextButton",{Position=UDim2.fromOffset(24,151),Size=UDim2.new(1,-48,0,44),BackgroundColor3=Color3.fromRGB(111,64,211),BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="UNLOCK",TextColor3=Color3.new(1,1,1),TextSize=13},security)
Corner(unlock,12); Grad(unlock,Color3.fromRGB(157,93,255),Color3.fromRGB(88,46,179),0)

local secMsg=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(24,207),Size=UDim2.new(1,-48,0,22),Font=Enum.Font.Gotham,Text="",TextColor3=Color3.fromRGB(255,102,130),TextSize=11},security)

-- MAIN
local main=New("Frame",{
    Size=UDim2.fromOffset(800,500),
    Position=UDim2.new(.5,-400,.5,-250),
    BackgroundColor3=Color3.fromRGB(9,8,13),
    BorderSizePixel=0,
    Visible=false,
    ClipsDescendants=true
},gui)
Corner(main,22); Stroke(main,Color3.fromRGB(128,76,226),1.5,.18); Grad(main,Color3.fromRGB(22,16,35),Color3.fromRGB(8,8,12),135)

local top=New("Frame",{Size=UDim2.new(1,0,0,70),BackgroundTransparency=1},main)
local logo=New("Frame",{Position=UDim2.fromOffset(18,14),Size=UDim2.fromOffset(43,43),BackgroundColor3=Color3.fromRGB(111,62,208),BorderSizePixel=0},top)
Corner(logo,14); Grad(logo,Color3.fromRGB(173,102,255),Color3.fromRGB(75,39,160),135)
New("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBlack,Text="S",TextColor3=Color3.new(1,1,1),TextSize=25},logo)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(72,13),Size=UDim2.fromOffset(300,27),Font=Enum.Font.GothamBold,Text="Steal An Egg",TextColor3=Color3.fromRGB(247,244,255),TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},top)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(73,38),Size=UDim2.fromOffset(250,18),Font=Enum.Font.Gotham,Text="JAYVEE  •  FREE",TextColor3=Color3.fromRGB(149,132,175),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},top)

local min=New("TextButton",{Position=UDim2.new(1,-82,0,17),Size=UDim2.fromOffset(28,28),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="—",TextColor3=Color3.fromRGB(165,153,181),TextSize=20},top)
local close=New("TextButton",{Position=UDim2.new(1,-46,0,16),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="×",TextColor3=Color3.fromRGB(165,153,181),TextSize=23},top)

local side=New("Frame",{Position=UDim2.fromOffset(13,78),Size=UDim2.fromOffset(158,405),BackgroundColor3=Color3.fromRGB(12,11,18),BorderSizePixel=0},main)
Corner(side,17); Stroke(side,Color3.fromRGB(62,52,79),1,.3)

local pageArea=New("Frame",{Position=UDim2.fromOffset(184,78),Size=UDim2.new(1,-198,1,-92),BackgroundTransparency=1},main)
local pages={}
local tabs={}

local function makePage(name)
    local p=New("ScrollingFrame",{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(137,84,229),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},pageArea)
    New("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,6)},p)
    New("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},p)
    pages[name]=p
    return p
end

local function title(p,t,sub)
    New("TextLabel",{LayoutOrder=1,BackgroundTransparency=1,Size=UDim2.new(1,0,0,30),Font=Enum.Font.GothamBold,Text=t,TextColor3=Color3.fromRGB(247,244,255),TextSize=22,TextXAlignment=Enum.TextXAlignment.Left},p)
    New("TextLabel",{LayoutOrder=2,BackgroundTransparency=1,Size=UDim2.new(1,0,0,22),Font=Enum.Font.Gotham,Text=sub,TextColor3=Color3.fromRGB(139,128,157),TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},p)
end

-- Accordion feature, matching the supplied reference's arrow/configuration style.
local function feature(p,name,desc,configFn)
    local holder=New("Frame",{LayoutOrder=10,Size=UDim2.new(1,0,0,54),BackgroundColor3=Color3.fromRGB(17,15,24),BorderSizePixel=0,ClipsDescendants=true},p)
    Corner(holder,13); Stroke(holder,Color3.fromRGB(61,52,76),1,.32)

    local head=New("TextButton",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1,AutoButtonColor=false,Text="",ZIndex=2},holder)
    local arrow=New("TextLabel",{Position=UDim2.fromOffset(13,0),Size=UDim2.fromOffset(28,54),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="›",TextColor3=Color3.fromRGB(236,230,246),TextSize=28,ZIndex=3},head)
    New("TextLabel",{Position=UDim2.fromOffset(45,8),Size=UDim2.new(1,-75,0,20),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=name,TextColor3=Color3.fromRGB(239,235,247),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},head)
    New("TextLabel",{Position=UDim2.fromOffset(45,29),Size=UDim2.new(1,-75,0,16),BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=desc,TextColor3=Color3.fromRGB(121,113,136),TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},head)

    local body=New("Frame",{Position=UDim2.fromOffset(12,60),Size=UDim2.new(1,-24,0,95),BackgroundColor3=Color3.fromRGB(11,10,16),BorderSizePixel=0,Visible=false},holder)
    Corner(body,11); Stroke(body,Color3.fromRGB(59,49,76),1,.4)
    if configFn then configFn(body) end

    local open=false
    head.MouseButton1Click:Connect(function()
        Snd(clickS)
        open=not open
        body.Visible=open
        arrow.Text=open and "⌄" or "›"
        local h=open and 164 or 54
        Tw(holder,{Size=UDim2.new(1,0,0,h)},.22):Play()
    end)
    return holder
end

local function smallButton(parent,text,pos,size,fn)
    local b=New("TextButton",{Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(31,27,40),BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text=text,TextColor3=Color3.fromRGB(224,218,235),TextSize=10},parent)
    Corner(b,9); Stroke(b,Color3.fromRGB(72,59,91),1,.25)
    b.MouseButton1Click:Connect(function() Snd(toggleS); if fn then fn() end end)
    return b
end

local function toggle(parent,labelText,y,fn)
    New("TextLabel",{Position=UDim2.fromOffset(12,y),Size=UDim2.new(1,-80,0,24),BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=labelText,TextColor3=Color3.fromRGB(193,185,204),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},parent)
    local b=New("TextButton",{Position=UDim2.new(1,-58,0,y),Size=UDim2.fromOffset(44,24),BackgroundColor3=Color3.fromRGB(43,39,50),BorderSizePixel=0,AutoButtonColor=false,Text=""},parent)
    Corner(b,12)
    local k=New("Frame",{Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(18,18),BackgroundColor3=Color3.fromRGB(190,184,199),BorderSizePixel=0},b)
    Corner(k,9)
    local on=false
    b.MouseButton1Click:Connect(function()
        on=not on; Snd(toggleS)
        Tw(b,{BackgroundColor3=on and Color3.fromRGB(111,64,211) or Color3.fromRGB(43,39,50)},.16):Play()
        Tw(k,{Position=on and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)},.16):Play()
        if fn then fn(on) end
    end)
end

local home=makePage("Home"); title(home,"Welcome, JAYVEE","Clean menu • creator information")
local card=New("Frame",{LayoutOrder=10,Size=UDim2.new(1,0,0,150),BackgroundColor3=Color3.fromRGB(17,15,24),BorderSizePixel=0},home)
Corner(card,15); Stroke(card,Color3.fromRGB(67,56,85),1,.3)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,16),Size=UDim2.new(1,-36,0,25),Font=Enum.Font.GothamBold,Text="JAYVEE",TextColor3=Color3.fromRGB(177,125,255),TextSize=18,TextXAlignment=Enum.TextXAlignment.Left},card)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,47),Size=UDim2.new(1,-36,0,75),Font=Enum.Font.Gotham,Text="Creator: JAYVEE\nUI: Steal An Egg V3\nPurple / dark futuristic interface\nMobile-friendly • draggable • animated",TextColor3=Color3.fromRGB(177,168,190),TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},card)

local farm=makePage("Farm"); title(farm,"Farm","Tap a feature to expand its configuration")

feature(farm,"Dr Scramble Lab & Mech","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Butterfly Bloom","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Wisp Companion","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Steal","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Place Egg","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Treadmill","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Hatch & Equip","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Sell","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Sell Lab Egg","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Fuse Machine","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(farm,"Auto Favorite","Configuration",function(b) toggle(b,"Enable feature",10) end)

local fun=makePage("Fun"); title(fun,"Fun","Toggle controls • expand for configuration")
feature(fun,"Instant Grab","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(fun,"Anti Guard","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(fun,"Anti Hit","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(fun,"Anti Trap","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(fun,"Add Money","Configuration",function(b) toggle(b,"Enable feature",10) end)
feature(fun,"Add Speed","Configuration",function(b) toggle(b,"Enable feature",10) end)

local settings=makePage("Settings"); title(settings,"Settings","Menu appearance and behavior")
feature(settings,"Menu Size","Choose a preset size",function(b)
    smallButton(b,"SMALL",UDim2.fromOffset(10,10),UDim2.fromOffset(68,30))
    smallButton(b,"MEDIUM",UDim2.fromOffset(84,10),UDim2.fromOffset(78,30))
    smallButton(b,"LARGE",UDim2.fromOffset(168,10),UDim2.fromOffset(68,30))
    toggle(b,"UI sounds",52)
end)
feature(settings,"Interface","General menu settings",function(b)
    toggle(b,"Animations",10)
    toggle(b,"Compact sidebar",42)
end)

local names={"Home","Farm","Fun","Settings"}
for i,n in ipairs(names) do
    local b=New("TextButton",{Position=UDim2.fromOffset(9,9+(i-1)*59),Size=UDim2.new(1,-18,0,49),BackgroundColor3=Color3.fromRGB(17,15,24),BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text=n,TextColor3=Color3.fromRGB(150,142,166),TextSize=12},side)
    Corner(b,12); tabs[n]=b
    b.MouseButton1Click:Connect(function()
        Snd(clickS)
        for name,p in pairs(pages) do p.Visible=name==n end
        for name,t in pairs(tabs) do
            Tw(t,{BackgroundColor3=name==n and Color3.fromRGB(104,61,190) or Color3.fromRGB(17,15,24),TextColor3=name==n and Color3.new(1,1,1) or Color3.fromRGB(150,142,166)},.18):Play()
        end
    end)
end
pages.Home.Visible=true
tabs.Home.BackgroundColor3=Color3.fromRGB(104,61,190)
tabs.Home.TextColor3=Color3.new(1,1,1)

-- DRAGGABLE MAIN
local dragging=false
local dragStart,startPos
top.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=main.Position
        i.Changed:Connect(function()
            if i.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- HIDDEN MENU ICON
local menuIcon=New("TextButton",{Size=UDim2.fromOffset(54,54),Position=UDim2.new(0,16,.5,-27),BackgroundColor3=Color3.fromRGB(105,60,200),BorderSizePixel=0,Visible=false,AutoButtonColor=false,Font=Enum.Font.GothamBlack,Text="S",TextColor3=Color3.new(1,1,1),TextSize=25},gui)
Corner(menuIcon,17); Stroke(menuIcon,Color3.fromRGB(183,125,255),1.5,.15); Grad(menuIcon,Color3.fromRGB(159,91,250),Color3.fromRGB(75,39,159),135)
menuIcon.MouseButton1Click:Connect(function()
    Snd(openS); menuIcon.Visible=false; main.Visible=true
end)

local minimized=false
min.MouseButton1Click:Connect(function()
    Snd(clickS)
    minimized=not minimized
    if minimized then
        side.Visible=false; pageArea.Visible=false
        Tw(main,{Size=UDim2.fromOffset(330,70)},.22):Play()
    else
        Tw(main,{Size=UDim2.fromOffset(800,500)},.22):Play()
        task.delay(.18,function() side.Visible=true; pageArea.Visible=true end)
    end
end)

close.MouseButton1Click:Connect(function()
    Snd(clickS)
    main.Visible=false
    menuIcon.Visible=true
end)

unlock.MouseButton1Click:Connect(function()
    Snd(clickS)
    if key.Text==KEY then
        secMsg.Text="ACCESS GRANTED"
        secMsg.TextColor3=Color3.fromRGB(100,255,175)
        Snd(openS)
        task.wait(.35)
        security.Visible=false
        main.Visible=true
    else
        secMsg.Text="INVALID KEY"
        key.Text=""
        local p=security.Position
        Tw(security,{Position=p+UDim2.fromOffset(7,0)},.06):Play()
        task.wait(.06)
        Tw(security,{Position=p-UDim2.fromOffset(7,0)},.06):Play()
        task.wait(.06)
        Tw(security,{Position=p},.06):Play()
    end
end)

key.FocusLost:Connect(function(enter)
    if enter then unlock:Activate() end
end)
