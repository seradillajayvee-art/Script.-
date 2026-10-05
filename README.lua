local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local genv = (getgenv and getgenv()) or _G
if genv.UIJ_CONNS then
	for _, c in ipairs(genv.UIJ_CONNS) do pcall(function() c:Disconnect() end) end
end
genv.UIJ_CONNS = {}
local function track(c) table.insert(genv.UIJ_CONNS, c); return c end
pcall(function() RunService:UnbindFromRenderStep("UIJ_Aimbot") end)

local radius, enabled, showBox, counter = 12, true, true, true
local aimOn, aimSmooth, aimHead, teamCheck, soundOn = false, 0.4, true, true, true
local cooldown, lastDodge = 0.9, 0
local dodgeMode, busy = "RANDOM", false
local LOCK_TIME = 5
local lockTarget, lockUntil = nil, 0

local function getRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end

pcall(function() if workspace:FindFirstChild("UI_Hitbox") then workspace.UI_Hitbox:Destroy() end end)

local gui = Instance.new("ScreenGui")
gui.Name = "UltraInstinctUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
	local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("UltraInstinctUI")
	if old then old:Destroy() end
end)
pcall(function()
	local old = lp:WaitForChild("PlayerGui"):FindFirstChild("UltraInstinctUI")
	if old then old:Destroy() end
end)
local okMount = pcall(function() if gethui then gui.Parent = gethui() end end)
if not okMount or not gui.Parent then
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
end
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o end
local function btn(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size; b.Position = pos; b.Text = text
	b.BackgroundColor3 = color or Color3.fromRGB(40,45,70)
	b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
	b.TextScaled = true; b.AutoButtonColor = true; b.BorderSizePixel = 0; b.ZIndex = 7; b.Parent = parent
	corner(b, 8); return b
end
local function label(parent, text, size, pos, color)
	local l = Instance.new("TextLabel")
	l.Size = size; l.Position = pos; l.Text = text
	l.BackgroundTransparency = 1; l.TextColor3 = color or Color3.new(1,1,1)
	l.Font = Enum.Font.GothamBold; l.TextScaled = true; l.ZIndex = 7; l.Parent = parent
	return l
end

local FULL_H, MINI_H = 256, 56
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, FULL_H); main.Position = UDim2.new(0.5, -220, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(15,17,30); main.BorderSizePixel = 0; main.ZIndex = 5; main.ClipsDescendants = true; main.Parent = gui
corner(main, 14)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2; stroke.Color = Color3.fromRGB(150,200,255); stroke.Parent = main
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(35,40,80), Color3.fromRGB(10,10,20)); grad.Rotation = 90; grad.Parent = main

local title = label(main, "ULTRA INSTINCT", UDim2.new(1,-110,0,28), UDim2.new(0,12,0,4), Color3.fromRGB(190,225,255))
title.Font = Enum.Font.GothamBlack; title.TextXAlignment = Enum.TextXAlignment.Left
local admin = label(main, "Admin👑:JAYVEE", UDim2.new(1,-24,0,16), UDim2.new(0,12,0,33), Color3.fromRGB(255,215,90))
admin.TextXAlignment = Enum.TextXAlignment.Left

local minB = btn(main, "-", UDim2.new(0,30,0,26), UDim2.new(1,-72,0,5), Color3.fromRGB(60,70,110))
local hideB = btn(main, "X", UDim2.new(0,30,0,26), UDim2.new(1,-38,0,5), Color3.fromRGB(150,50,60))

local body = Instance.new("Frame")
body.Size = UDim2.new(1,0,1,-56); body.Position = UDim2.new(0,0,0,56)
body.BackgroundTransparency = 1; body.ZIndex = 6; body.Parent = main

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0,2,1,-16); divider.Position = UDim2.new(0.5,-1,0,0)
divider.BackgroundColor3 = Color3.fromRGB(70,90,150); divider.BorderSizePixel = 0; divider.ZIndex = 6; divider.Parent = body

local L = Instance.new("Frame")
L.Size = UDim2.new(0.5,-18,1,0); L.Position = UDim2.new(0,10,0,0); L.BackgroundTransparency = 1; L.ZIndex = 6; L.Parent = body
local R = Instance.new("Frame")
R.Size = UDim2.new(0.5,-18,1,0); R.Position = UDim2.new(0.5,8,0,0); R.BackgroundTransparency = 1; R.ZIndex = 6; R.Parent = body

local tog = btn(L, "ULTRA INSTINCT: ON", UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), Color3.fromRGB(40,150,90))
local minus = btn(L, "-1", UDim2.new(0,58,0,34), UDim2.new(0,0,0,44))
local rLabel = label(L, "", UDim2.new(1,-124,0,34), UDim2.new(0,62,0,44))
local plus = btn(L, "+1", UDim2.new(0,58,0,34), UDim2.new(1,-58,0,44))
local boxB = btn(L, "HITBOX: SHOW", UDim2.new(0.5,-3,0,32), UDim2.new(0,0,0,86))
local ctrB = btn(L, "COUNTER: ON", UDim2.new(0.5,-3,0,32), UDim2.new(0.5,3,0,86))
local sndB = btn(L, "SOUND: ON", UDim2.new(1,0,0,32), UDim2.new(0,0,0,124))
local modeB = btn(L, "DODGE: RANDOM", UDim2.new(1,0,0,32), UDim2.new(0,0,0,162))

local aimB = btn(R, "AIMBOT: OFF", UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), Color3.fromRGB(150,50,60))
local sMinus = btn(R, "-", UDim2.new(0,40,0,34), UDim2.new(0,0,0,44))
local sLabel = label(R, "", UDim2.new(1,-84,0,34), UDim2.new(0,42,0,44))
local sPlus = btn(R, "+", UDim2.new(0,40,0,34), UDim2.new(1,-40,0,44))
local tgtB = btn(R, "TARGET: HEAD", UDim2.new(1,0,0,32), UDim2.new(0,0,0,86))
local teamB = btn(R, "TEAM CHECK: ON", UDim2.new(1,0,0,32), UDim2.new(0,0,0,124))

local function refresh()
	rLabel.Text = "Radius: " .. radius
	tog.Text = "ULTRA INSTINCT: " .. (enabled and "ON" or "OFF")
	tog.BackgroundColor3 = enabled and Color3.fromRGB(40,150,90) or Color3.fromRGB(150,50,60)
	boxB.Text = "HITBOX: " .. (showBox and "SHOW" or "HIDE")
	ctrB.Text = "COUNTER: " .. (counter and "ON" or "OFF")
	sndB.Text = "SOUND: " .. (soundOn and "ON" or "OFF")
	modeB.Text = "DODGE: " .. dodgeMode
	aimB.Text = "AIMBOT: " .. (aimOn and "ON" or "OFF")
	aimB.BackgroundColor3 = aimOn and Color3.fromRGB(40,150,90) or Color3.fromRGB(150,50,60)
	sLabel.Text = "Smooth: " .. string.format("%.1f", aimSmooth)
	tgtB.Text = "TARGET: " .. (aimHead and "HEAD" or "BODY")
	teamB.Text = "TEAM CHECK: " .. (teamCheck and "ON" or "OFF")
end
refresh()

local openB = btn(gui, "UI", UDim2.new(0,46,0,46), UDim2.new(0,10,0.5,0), Color3.fromRGB(30,40,90))
openB.ZIndex = 8; openB.Visible = false

local mini = false
minB.MouseButton1Click:Connect(function()
	mini = not mini
	body.Visible = not mini
	TS:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0,440,0,mini and MINI_H or FULL_H)}):Play()
end)
hideB.MouseButton1Click:Connect(function() main.Visible = false; openB.Visible = true end)
openB.MouseButton1Click:Connect(function() main.Visible = true; openB.Visible = false end)

local function drag(frame, handle)
	local dragging, start, sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, sp = true, i.Position, frame.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end))
end
drag(main, main); drag(openB, openB)

local ids = {
	"rbxassetid://87566211283329",
	"rbxassetid://81857580097150",
	"rbxassetid://129561737395908",
	"rbxassetid://122312400582724",
	"rbxassetid://136080815136211",
}
local ready = {}
for i = 1, #ids do table.insert(ready, i) end
local onId

local function playId(id, vol)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol; s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 6)
end

task.spawn(function()
	pcall(function()
		local temp = {}
		for _, id in ipairs(ids) do
			local s = Instance.new("Sound"); s.SoundId = id; s.Parent = SoundService
			table.insert(temp, s)
		end
		game:GetService("ContentProvider"):PreloadAsync(temp)
		for _, s in ipairs(temp) do s:Destroy() end
	end)
end)

local bag, lastIdx = {}, 0
local function playDodgeSound()
	if not soundOn or #ready == 0 then return end
	if #bag == 0 then
		for _, i in ipairs(ready) do table.insert(bag, i) end
		for i = #bag, 2, -1 do
			local j = math.random(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
		if #bag > 1 and bag[#bag] == lastIdx then bag[1], bag[#bag] = bag[#bag], bag[1] end
	end
	lastIdx = table.remove(bag)
	playId(ids[lastIdx], 4)
end

tog.MouseButton1Click:Connect(function()
	enabled = not enabled
	if enabled and onId and soundOn then playId(onId, 1.5) end
	refresh()
end)
plus.MouseButton1Click:Connect(function() radius = math.min(radius + 1, 60); refresh() end)
minus.MouseButton1Click:Connect(function() radius = math.max(radius - 1, 3); refresh() end)
boxB.MouseButton1Click:Connect(function() showBox = not showBox; refresh() end)
ctrB.MouseButton1Click:Connect(function() counter = not counter; refresh() end)
sndB.MouseButton1Click:Connect(function() soundOn = not soundOn; refresh() end)
modeB.MouseButton1Click:Connect(function()
	dodgeMode = dodgeMode == "RANDOM" and "TELEPORT" or (dodgeMode == "TELEPORT" and "NORMAL" or "RANDOM")
	refresh()
end)
aimB.MouseButton1Click:Connect(function() aimOn = not aimOn; refresh() end)
sPlus.MouseButton1Click:Connect(function() aimSmooth = math.min(1, math.floor((aimSmooth + 0.1) * 10 + 0.5) / 10); refresh() end)
sMinus.MouseButton1Click:Connect(function() aimSmooth = math.max(0.1, math.floor((aimSmooth - 0.1) * 10 + 0.5) / 10); refresh() end)
tgtB.MouseButton1Click:Connect(function() aimHead = not aimHead; refresh() end)
teamB.MouseButton1Click:Connect(function() teamCheck = not teamCheck; refresh() end)

local box = Instance.new("Part")
box.Anchored = true; box.CanCollide = false; box.CanQuery = false; box.CanTouch = false
box.Material = Enum.Material.Neon; box.Color = Color3.fromRGB(150,200,255)
box.Transparency = 0.8; box.Name = "UI_Hitbox"; box.Parent = workspace

local function inHitbox(pos)
	local r = getRoot(lp.Character); if not r then return false end
	local o = r.CFrame:PointToObjectSpace(pos)
	return math.abs(o.X) <= radius / 2 and o.Z <= 3 and o.Z >= -radius and math.abs(o.Y) <= 7
end

track(RunService.Heartbeat:Connect(function()
	local r = getRoot(lp.Character)
	if r then
		box.Size = Vector3.new(radius, 6, radius)
		box.CFrame = r.CFrame * CFrame.new(0, 0, -radius / 2)
		box.Transparency = (enabled and showBox) and 0.8 or 1
	end
end))

local WHITE = Color3.new(1, 1, 1)
local ICE = Color3.fromRGB(190, 225, 255)

local function snapshot(char)
	local root = getRoot(char); if not root then return {} end
	local list = {}
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p ~= root and p.Transparency < 1 and p.Size.Magnitude < 12 then
			table.insert(list, {size = p.Size, off = root.CFrame:ToObjectSpace(p.CFrame)})
			if #list >= 14 then break end
		end
	end
	return list
end

local function newGhost(size, cf, color, transp)
	local g = Instance.new("Part")
	g.Anchored = true; g.CanCollide = false; g.CanQuery = false; g.CanTouch = false; g.CastShadow = false
	g.Material = Enum.Material.Neon; g.Color = color; g.Size = size; g.CFrame = cf
	g.Transparency = transp; g.Parent = workspace
	return g
end

local function ghostAt(list, cf, color, life, grow)
	for _, e in ipairs(list) do
		local g = newGhost(e.size, cf * e.off, color, 0.1)
		TS:Create(g, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Size = e.size * grow}):Play()
		Debris:AddItem(g, life + 0.1)
	end
end

local function flipGhost(list, a, b)
	local parts = {}
	for _, e in ipairs(list) do
		table.insert(parts, {newGhost(e.size, a * e.off, WHITE, 0.05), e.off})
	end
	local t0, dur, conn = tick(), 0.4, nil
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((tick() - t0) / dur, 0, 1)
		local e = 1 - (1 - t) ^ 3
		local base = a:Lerp(b, e) + Vector3.new(0, math.sin(math.pi * e) * 4.5, 0)
		local cf = base * CFrame.Angles(-math.pi * 2 * e, 0, 0)
		for _, pr in ipairs(parts) do
			pr[1].CFrame = cf * pr[2]
			pr[1].Transparency = 0.05 + 0.95 * (t ^ 3)
		end
		if t >= 1 then
			conn:Disconnect()
			for _, pr in ipairs(parts) do pr[1]:Destroy() end
		end
	end)
end

local function beamBetween(p1, p2, width)
	local function anchorPart(pos)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(pos); p.Parent = workspace
		local a = Instance.new("Attachment"); a.Parent = p
		Debris:AddItem(p, 0.6)
		return a
	end
	local bm = Instance.new("Beam")
	bm.Attachment0 = anchorPart(p1); bm.Attachment1 = anchorPart(p2)
	bm.Color = ColorSequence.new(WHITE); bm.LightEmission = 1; bm.LightInfluence = 0
	bm.Width0 = width; bm.Width1 = width; bm.FaceCamera = true; bm.Segments = 1
	bm.Parent = bm.Attachment0.Parent
	TS:Create(bm, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Width0 = 0, Width1 = 0}):Play()
end

local function ring(pos, size, delay)
	task.delay(delay or 0, function()
		local r = Instance.new("Part")
		r.Shape = Enum.PartType.Cylinder
		r.Anchored = true; r.CanCollide = false; r.CanQuery = false; r.CanTouch = false; r.CastShadow = false
		r.Material = Enum.Material.Neon; r.Color = WHITE; r.Transparency = 0.1
		r.Size = Vector3.new(0.4, 3, 3); r.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		r.Parent = workspace
		TS:Create(r, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.4, size, size), Transparency = 1}):Play()
		Debris:AddItem(r, 0.6)
	end)
end

local function orb(pos, size)
	local s = Instance.new("Part")
	s.Shape = Enum.PartType.Ball; s.Anchored = true; s.CanCollide = false; s.CanQuery = false; s.CanTouch = false
	s.Material = Enum.Material.Neon; s.Color = WHITE; s.Transparency = 0.2
	s.Size = Vector3.new(2, 2, 2); s.CFrame = CFrame.new(pos); s.Parent = workspace
	TS:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(size, size, size), Transparency = 1}):Play()
	Debris:AddItem(s, 0.5)
end

local function emitter(parent, props)
	local pe = Instance.new("ParticleEmitter")
	pe.LightEmission = 1; pe.LightInfluence = 0; pe.Rate = 0
	pe.Color = ColorSequence.new(WHITE, ICE)
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	for k, v in pairs(props) do pe[k] = v end
	pe.Parent = parent
	return pe
end

local function burstAt(pos)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(pos); p.Parent = workspace
	local sp = emitter(p, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(14, 34),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0)}),
	})
	sp:Emit(60)
	Debris:AddItem(p, 1.2)
end

local function fireAura(root)
	local fa = emitter(root, {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(6, 14),
		SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 0.5)}),
		Rate = 160,
	})
	task.delay(0.8, function() fa.Enabled = false end)
	Debris:AddItem(fa, 1.8)
end

local function screenFX()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = -1; cc.Contrast = 0.5; cc.Brightness = 0.2; cc.Parent = Lighting
	TS:Create(cc, TweenInfo.new(0.6), {Saturation = 0, Contrast = 0, Brightness = 0}):Play()
	Debris:AddItem(cc, 0.7)
	local bl = Instance.new("BlurEffect")
	bl.Size = 22; bl.Parent = Lighting
	TS:Create(bl, TweenInfo.new(0.45), {Size = 0}):Play()
	Debris:AddItem(bl, 0.55)
	local f = cam.FieldOfView
	TS:Create(cam, TweenInfo.new(0.08), {FieldOfView = f + 22}):Play()
	task.delay(0.08, function() TS:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {FieldOfView = f}):Play() end)
	local t0 = tick()
	pcall(function() RunService:UnbindFromRenderStep("UIJ_Shake") end)
	RunService:BindToRenderStep("UIJ_Shake", Enum.RenderPriority.Camera.Value + 2, function()
		local k = 1 - (tick() - t0) / 0.3
		if k <= 0 then RunService:UnbindFromRenderStep("UIJ_Shake"); return end
		cam.CFrame = cam.CFrame * CFrame.Angles(
			math.rad(math.random(-10, 10) / 10 * k * 1.6),
			math.rad(math.random(-10, 10) / 10 * k * 1.6),
			math.rad(math.random(-10, 10) / 10 * k * 2.4))
	end)
end

local function dodgeFX(char, startCF, endCF, list)
	local root = getRoot(char)
	local a, b = startCF.Position, endCF.Position

	ghostAt(list, startCF, WHITE, 0.8, 1.4)
	for i = 1, 6 do
		task.delay(i * 0.03, function()
			ghostAt(list, startCF:Lerp(endCF, i / 7), i % 2 == 0 and WHITE or ICE, 0.5, 1.15)
		end)
	end
	flipGhost(list, startCF, endCF)
	beamBetween(a, b, 3.5)
	beamBetween(a + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0), 2)
	beamBetween(a - Vector3.new(0, 1.5, 0), b - Vector3.new(0, 1.5, 0), 1.5)

	ring(a - Vector3.new(0, 2.8, 0), 30, 0)
	ring(a - Vector3.new(0, 2.8, 0), 20, 0.08)
	ring(b - Vector3.new(0, 2.8, 0), 36, 0.05)
	ring(b - Vector3.new(0, 2.8, 0), 24, 0.14)
	orb(a, 16)
	orb(b, 20)
	burstAt(a)
	burstAt(b)

	if root then
		pcall(fireAura, root)
		local pl = Instance.new("PointLight")
		pl.Color = WHITE; pl.Brightness = 10; pl.Range = 40; pl.Parent = root
		TS:Create(pl, TweenInfo.new(0.7), {Brightness = 0}):Play()
		Debris:AddItem(pl, 0.8)
	end

	local h = Instance.new("Highlight")
	h.FillColor = WHITE; h.OutlineColor = WHITE
	h.FillTransparency = 0; h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = char
	TS:Create(h, TweenInfo.new(0.8), {FillTransparency = 1, OutlineTransparency = 1}):Play()
	Debris:AddItem(h, 0.9)

	screenFX()
end

local function swing()
	local c = lp.Character
	local tool = c and c:FindFirstChildOfClass("Tool")
	if tool then pcall(function() tool:Activate() end) end
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local v = cam.ViewportSize
		vim:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0)
		task.wait(0.02)
		vim:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0)
	end)
	pcall(function() if mouse1click then mouse1click() end end)
	pcall(function()
		local VU = game:GetService("VirtualUser")
		VU:CaptureController()
		VU:ClickButton1(Vector2.new(0, 0))
	end)
end

local function doCounter()
	if not counter then return end
	for _ = 1, 3 do
		swing()
		task.wait(0.14)
	end
end

track(RunService.Heartbeat:Connect(function()
	if not lockTarget then return end
	if tick() > lockUntil then lockTarget = nil; return end
	local r, er = getRoot(lp.Character), getRoot(lockTarget)
	if not r or not er then lockTarget = nil; return end
	local p = r.Position
	local flat = Vector3.new(er.Position.X, p.Y, er.Position.Z)
	if (flat - p).Magnitude > 0.1 then r.CFrame = CFrame.lookAt(p, flat) end
end))

local function returnFX(list, fromCF, toCF)
	ghostAt(list, fromCF, ICE, 0.45, 1.15)
	beamBetween(fromCF.Position, toCF.Position, 2)
	ring(toCF.Position - Vector3.new(0, 2.8, 0), 18, 0)
end

local function dodge(eChar)
	if not enabled or busy or tick() - lastDodge < cooldown then return end
	local char = lp.Character
	local r, er = getRoot(char), getRoot(eChar)
	if not r or not er then return end
	busy = true
	lastDodge = tick()
	local ok = pcall(function()
		local startCF = r.CFrame
		local list = snapshot(char)
		local useTP = dodgeMode == "TELEPORT" or (dodgeMode == "RANDOM" and math.random() < 0.5)
		local side = math.random(0, 1) == 0 and -4 or 4
		local goal
		if useTP then
			goal = (er.CFrame * CFrame.new(side * 0.5, 0, 3.2)).Position
		else
			goal = (er.CFrame * CFrame.new(side, 0, 1.5)).Position
		end
		local endCF = CFrame.lookAt(goal, Vector3.new(er.Position.X, goal.Y, er.Position.Z))
		pcall(playDodgeSound)
		r.CFrame = endCF
		lockTarget = eChar
		lockUntil = tick() + LOCK_TIME
		pcall(dodgeFX, char, startCF, endCF, list)
		task.wait(0.05)
		doCounter()
		if not useTP then
			task.wait(0.1)
			local nowR = getRoot(lp.Character)
			local nowE = getRoot(eChar)
			if nowR then
				local look = nowE and Vector3.new(nowE.Position.X, startCF.Position.Y, nowE.Position.Z) or (startCF.Position + startCF.LookVector)
				local back = CFrame.lookAt(startCF.Position, look)
				local from = nowR.CFrame
				nowR.CFrame = back
				pcall(returnFX, list, from, back)
			end
		end
	end)
	busy = false
end

local P = Enum.AnimationPriority
local attackPrio = {[P.Action] = true, [P.Action2] = true, [P.Action3] = true, [P.Action4] = true}

local function hookChar(c)
	local hum = c:WaitForChild("Humanoid", 5); if not hum then return end
	local an = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
	if not an then return end
	track(an.AnimationPlayed:Connect(function(t)
		if not enabled or not attackPrio[t.Priority] then return end
		local er = getRoot(c)
		if er and inHitbox(er.Position) then dodge(c) end
	end))
end

local function hookPlayer(p)
	if p == lp then return end
	if p.Character then task.spawn(hookChar, p.Character) end
	track(p.CharacterAdded:Connect(hookChar))
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
track(Players.PlayerAdded:Connect(hookPlayer))

local function aimTarget()
	local best, bestDist = nil, math.huge
	local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Character and not (teamCheck and lp.Team and p.Team == lp.Team) then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local part = aimHead and p.Character:FindFirstChild("Head") or getRoot(p.Character)
			if hum and hum.Health > 0 and part then
				local pos, onScreen = cam:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
					if dist < bestDist then best, bestDist = part, dist end
				end
			end
		end
	end
	return best
end

RunService:BindToRenderStep("UIJ_Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
	if not aimOn then return end
	local t = aimTarget()
	if t then cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), aimSmooth) end
end)
