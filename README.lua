-- ================= ULTRA INSTINCT : SECURITY CHECK =================
local KEY_OK = false
do
	local Players = game:GetService("Players")
	local TS = game:GetService("TweenService")
	local RS = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local UIS = game:GetService("UserInputService")
	local lp = Players.LocalPlayer

	local KEY_HASH, KEY_LEN = 822848760, 21
	local MAX_TRIES, LOCK_SECS = 3, 30

	local function hash(s)
		local h = 5381
		for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
		return h
	end

	local ICE = Color3.fromRGB(190, 225, 255)
	local GREEN = Color3.fromRGB(70, 230, 140)
	local RED = Color3.fromRGB(255, 80, 95)
	local GOLD = Color3.fromRGB(255, 215, 90)

	local g = Instance.new("ScreenGui")
	g.Name = "UI_KeyGate"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true
	g.DisplayOrder = 10000; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end

	local conns, done = {}, false
	local function on(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

	local blur = Instance.new("BlurEffect"); blur.Size = 0; blur.Parent = Lighting
	TS:Create(blur, TweenInfo.new(0.6), {Size = 24}):Play()

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1; dim.BorderSizePixel = 0; dim.Active = false; dim.Parent = g
	TS:Create(dim, TweenInfo.new(0.6), {BackgroundTransparency = 0.35}):Play()

	-- floating particles
	local dots = {}
	for i = 1, 24 do
		local s = math.random(2, 5)
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(s, s); p.BackgroundColor3 = ICE; p.BorderSizePixel = 0
		p.BackgroundTransparency = math.random(30, 80) / 100
		p.Position = UDim2.fromScale(math.random(), math.random())
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = p
		p.Parent = dim
		dots[i] = {f = p, sp = math.random(15, 60) / 1000, dr = (math.random() - 0.5) * 0.01}
	end

	-- card
	local W, H = 380, 272
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(0, 0); card.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	card.BorderSizePixel = 0; card.ClipsDescendants = true; card.Active = true; card.Parent = g
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 16); cc.Parent = card
	local bg = Instance.new("UIGradient")
	bg.Color = ColorSequence.new(Color3.fromRGB(32, 38, 78), Color3.fromRGB(8, 9, 18)); bg.Rotation = 90; bg.Parent = card

	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2.5; stroke.Color = Color3.new(1, 1, 1); stroke.Parent = card
	local sg = Instance.new("UIGradient")
	sg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255)),
	})
	sg.Parent = stroke

	local scan = Instance.new("Frame")
	scan.Size = UDim2.new(1, 0, 0, 2); scan.BackgroundColor3 = ICE
	scan.BackgroundTransparency = 0.7; scan.BorderSizePixel = 0; scan.ZIndex = 2; scan.Parent = card

	local function label(text, y, h, color, font)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -30, 0, h); l.Position = UDim2.new(0, 15, 0, y)
		l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = color or Color3.new(1, 1, 1)
		l.Font = font or Enum.Font.GothamBold; l.TextScaled = true; l.ZIndex = 3; l.Parent = card
		return l
	end

	local title = label("ULTRA INSTINCT", 14, 34, ICE, Enum.Font.GothamBlack)
	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 200, 255)); tg.Parent = title
	label("SECURITY CHECK  •  ACCESS KEY REQUIRED", 50, 14, Color3.fromRGB(130, 150, 200))
	local status = label("ENTER YOUR ACCESS KEY", 82, 18, Color3.fromRGB(200, 210, 240))

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -40, 0, 44); box.Position = UDim2.new(0, 20, 0, 110)
	box.BackgroundColor3 = Color3.fromRGB(22, 26, 50); box.BorderSizePixel = 0
	box.PlaceholderText = "ACCESS KEY"; box.PlaceholderColor3 = Color3.fromRGB(100, 110, 150)
	box.Text = ""; box.TextColor3 = Color3.new(1, 1, 1); box.Font = Enum.Font.GothamBold
	box.TextSize = 18; box.ClearTextOnFocus = false; box.ZIndex = 3; box.Parent = card
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = box
	local bs = Instance.new("UIStroke"); bs.Thickness = 1.5; bs.Color = Color3.fromRGB(70, 90, 150); bs.Parent = box

	local go = Instance.new("TextButton")
	go.Size = UDim2.new(1, -40, 0, 40); go.Position = UDim2.new(0, 20, 0, 164)
	go.BackgroundColor3 = Color3.fromRGB(60, 90, 200); go.BorderSizePixel = 0; go.Text = "UNLOCK"
	go.TextColor3 = Color3.new(1, 1, 1); go.Font = Enum.Font.GothamBlack; go.TextSize = 18
	go.AutoButtonColor = true; go.ZIndex = 3; go.Parent = card
	local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(0, 10); gc.Parent = go
	local gg = Instance.new("UIGradient")
	gg.Color = ColorSequence.new(Color3.fromRGB(110, 150, 255), Color3.fromRGB(150, 100, 255)); gg.Rotation = 0; gg.Parent = go

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, -40, 0, 6); barBack.Position = UDim2.new(0, 20, 0, 216)
	barBack.BackgroundColor3 = Color3.fromRGB(25, 30, 55); barBack.BorderSizePixel = 0; barBack.ZIndex = 3; barBack.Parent = card
	local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(1, 0); bbc.Parent = barBack
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 1, 0); bar.BackgroundColor3 = GREEN; bar.BorderSizePixel = 0; bar.ZIndex = 4; bar.Parent = barBack
	local bac = Instance.new("UICorner"); bac.CornerRadius = UDim.new(1, 0); bac.Parent = bar

	local pips = {}
	for i = 1, MAX_TRIES do
		local d = Instance.new("Frame")
		d.Size = UDim2.fromOffset(10, 10); d.AnchorPoint = Vector2.new(0.5, 0)
		d.Position = UDim2.new(0.5, (i - 2) * 18, 0, 232)
		d.BackgroundColor3 = GREEN; d.BorderSizePixel = 0; d.ZIndex = 3; d.Parent = card
		local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = d
		pips[i] = d
	end
	label("Admin👑:JAYVEE", 250, 14, GOLD)

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(26, 24); close.Position = UDim2.new(1, -34, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(150, 50, 60); close.BorderSizePixel = 0; close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1); close.Font = Enum.Font.GothamBold; close.TextSize = 14
	close.ZIndex = 5; close.Parent = card
	local xc = Instance.new("UICorner"); xc.CornerRadius = UDim.new(0, 6); xc.Parent = close

	TS:Create(card, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(W, H)}):Play()

	-- drag the card from anywhere (movement/camera stay free)
	local dragging, dstart, dpos = false, nil, nil
	on(card.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dstart, dpos = true, i.Position, card.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dstart
			card.Position = UDim2.new(dpos.X.Scale, dpos.X.Offset + d.X, dpos.Y.Scale, dpos.Y.Offset + d.Y)
		end
	end)

	-- animation loop
	local t0 = os.clock()
	on(RS.Heartbeat, function(dt)
		local t = os.clock() - t0
		sg.Rotation = (t * 90) % 360
		gg.Rotation = (t * 40) % 360
		scan.Position = UDim2.new(0, 0, 0, ((t * 110) % (H + 20)) - 10)
		for _, d in ipairs(dots) do
			local p = d.f.Position
			local y = p.Y.Scale - d.sp * dt
			if y < -0.02 then y = 1.02 end
			d.f.Position = UDim2.fromScale((p.X.Scale + d.dr * dt * 10) % 1, y)
		end
	end)

	local function cleanup()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		pcall(function() blur:Destroy() end)
		pcall(function() g:Destroy() end)
	end

	local function closeAnim(cb)
		TS:Create(blur, TweenInfo.new(0.4), {Size = 0}):Play()
		TS:Create(dim, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		TS:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)}):Play()
		task.delay(0.45, cb)
	end

	local tries, locked, busy = 0, false, false

	local function shake()
		local p0 = card.Position
		for i = 1, 8 do
			local o = (i % 2 == 0 and 1 or -1) * (16 - i * 2)
			card.Position = UDim2.new(p0.X.Scale, p0.X.Offset + o, p0.Y.Scale, p0.Y.Offset)
			task.wait(0.03)
		end
		card.Position = p0
	end

	local function setColor(c)
		TS:Create(status, TweenInfo.new(0.2), {TextColor3 = c}):Play()
		TS:Create(bs, TweenInfo.new(0.2), {Color = c}):Play()
	end

	local function success()
		busy = true
		setColor(GREEN)
		local steps = {"VERIFYING KEY...", "DECRYPTING MODULES...", "SYNCING INSTINCT...", "ACCESS GRANTED ✔"}
		for i, s in ipairs(steps) do
			status.Text = s
			TS:Create(bar, TweenInfo.new(0.3), {Size = UDim2.new(i / #steps, 0, 1, 0)}):Play()
			task.wait(0.35)
		end
		for _, p in ipairs(pips) do p.BackgroundColor3 = GREEN end
		task.wait(0.3)
		closeAnim(function() KEY_OK = true; done = true end)
	end

	local function fail()
		tries = tries + 1
		if pips[tries] then pips[tries].BackgroundColor3 = RED end
		setColor(RED)
		status.Text = "ACCESS DENIED  (" .. tries .. "/" .. MAX_TRIES .. ")"
		task.spawn(shake)
		if tries >= MAX_TRIES then
			locked = true
			go.Text = "LOCKED"
			go.BackgroundColor3 = Color3.fromRGB(90, 40, 50)
			task.spawn(function()
				for s = LOCK_SECS, 1, -1 do
					status.Text = "TOO MANY ATTEMPTS — WAIT " .. s .. "s"
					task.wait(1)
				end
				tries, locked = 0, false
				for _, p in ipairs(pips) do p.BackgroundColor3 = GREEN end
				go.Text = "UNLOCK"; go.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
				status.Text = "ENTER YOUR ACCESS KEY"; setColor(Color3.fromRGB(200, 210, 240))
			end)
		else
			task.delay(1.2, function()
				if not locked and not busy then
					status.Text = "ENTER YOUR ACCESS KEY"; setColor(Color3.fromRGB(200, 210, 240))
				end
			end)
		end
	end

	local function check()
		if locked or busy then return end
		local txt = box.Text:match("^%s*(.-)%s*$") or ""
		if #txt == KEY_LEN and hash(txt) == KEY_HASH then
			task.spawn(success)
		else
			fail()
		end
	end

	on(go.MouseButton1Click, check)
	on(box.FocusLost, function(enter) if enter then check() end end)
	on(close.MouseButton1Click, function()
		if busy then return end
		busy = true
		closeAnim(function() done = true end)
	end)

	repeat task.wait() until done
	cleanup()
end
if not KEY_OK then return end
-- ================= MAIN SCRIPT =================

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

-- ================= STATE =================
local radius, enabled, showBox, counter = 12, true, true, true
local aimOn, aimSmooth, aimHead, teamCheck, soundOn = false, 0.4, true, true, true
local cooldown, lastDodge = 0.9, 0
local dodgeMode, busy = "NORMAL", false
local backSide = "RANDOM"
local LOCK_TIME, lockOn, fxOn = 5, true, true
local freeMove = true
local returnDelay = 0.04
local lockTarget, lockUntil = nil, 0
local dodgeCount = 0
local activePower = nil
local powerStates = {}

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

-- ================= SOUND =================
local ids = {
	"rbxassetid://87566211283329",
	"rbxassetid://81857580097150",
	"rbxassetid://129561737395908",
	"rbxassetid://122312400582724",
	"rbxassetid://136080815136211",
}
local ready = {}
for i = 1, #ids do table.insert(ready, i) end

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

-- ================= HITBOX =================
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

-- ================= FX =================
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

	if fxOn then screenFX() end
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

local function doCounter(n, gap)
	if not counter then return end
	for _ = 1, (n or 3) do
		swing()
		task.wait(gap or 0.14)
	end
end

-- ================= SOFT LOCK (free movement + free camera) =================
-- Character only FACES the enemy (rotation only). Joystick/WASD and camera stay 100% yours.
local function releaseLock()
	lockTarget = nil
	lockUntil = 0
	local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if h then h.AutoRotate = true end
end

local function faceTarget(char, target)
	if not freeMove or not lockOn then return end
	local r, er = getRoot(char), getRoot(target)
	if not r or not er then return end
	local p = r.Position
	local flat = Vector3.new(er.Position.X, p.Y, er.Position.Z)
	if (flat - p).Magnitude > 0.1 then
		r.CFrame = CFrame.lookAt(p, flat)
	end
end

track(RunService.Heartbeat:Connect(function()
	if not lockTarget then return end
	local char = lp.Character
	local r, er = getRoot(char), getRoot(lockTarget)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not lockOn or tick() > lockUntil or not r or not er or not hum or hum.Health <= 0 then
		releaseLock(); return
	end
	hum.AutoRotate = false
	local p = r.Position
	local flat = Vector3.new(er.Position.X, p.Y, er.Position.Z)
	if (flat - p).Magnitude > 0.1 then
		r.CFrame = CFrame.lookAt(p, flat) -- rotation only, position/velocity untouched
	end
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
	pcall(function()
		local startCF = r.CFrame
		local list = snapshot(char)
		local useTP = dodgeMode == "TELEPORT"
		local side
		if dodgeMode == "NORMAL" then
			if backSide == "LEFT" then
				side = -1
			elseif backSide == "RIGHT" then
				side = 1
			else
				side = math.random(0, 1) == 0 and -1 or 1
			end
		else
			side = math.random(0, 1) == 0 and -1 or 1
		end
		local sx = side * (math.random(25, 40) / 10)
		local back = math.random(32, 45) / 10
		local goal = (er.CFrame * CFrame.new(sx, 0, back)).Position
		local endCF = CFrame.lookAt(goal, Vector3.new(er.Position.X, goal.Y, er.Position.Z))
		pcall(playDodgeSound)
		r.CFrame = endCF
		dodgeCount = dodgeCount + 1
		if lockOn then
			lockTarget = eChar
			lockUntil = tick() + LOCK_TIME
		end
		pcall(dodgeFX, char, startCF, endCF, list)
		task.wait(useTP and 0.05 or 0.02)
		if useTP then doCounter() else doCounter(2, 0.06) end
		if not useTP then
			task.wait(returnDelay)
			local nowR = getRoot(lp.Character)
			local nowE = getRoot(eChar)
			if nowR then
				local moved = nowR.Position - endCF.Position
				local retPos = startCF.Position + moved
				local look = nowE and Vector3.new(nowE.Position.X, retPos.Y, nowE.Position.Z) or (retPos + startCF.LookVector)
				local back = CFrame.lookAt(retPos, look)
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

-- ================= AIMBOT =================
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

-- ================= MENU =================
local ICON_B64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCACAAIADASIAAhEBAxEB/8QAHAAAAgMAAwEAAAAAAAAAAAAABQYDBAcBAggA/8QANhAAAgEDAgMGBQMEAQUAAAAAAQIDAAQRBSEGEjEHEyJBUWEycYGRoRQjscEjQlLRFTNigvDx/8QAGgEAAwEBAQEAAAAAAAAAAAAAAQIDBAAFBv/EACARAAICAgMBAQEBAAAAAAAAAAABAhEDIRIxQQRRFCL/2gAMAwEAAhEDEQA/AGpwvR9qqSxgSYOy1YBDM5fceXzqtdyMfCMED3rwT6P0IXa40+yK+jDI+dCblS2GK9POiu7aNZMevM436c1TvdkoUA2TQFkUsSR0qtOQP91ffKlm6j0odql3aWdv3l5KkSnpk7n5U0bbpAlS2wZIpLnrVS5IC7npVIa/JdzclpakqTjnc/wKF6jKyTn9dqigD+yJOU1tx/PN96MWT6oLS2GVbAGa7MH5v3+GCOfiTMHn+Az4r+SSkE=" -- (see note below)

local function loadIcon()
	local ok, res = pcall(function()
		local B = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		local map = {}
		for i = 1, 64 do map[B:byte(i)] = i - 1 end
		local s = ICON_B64:gsub('[^%w%+/=]', '')
		local out, n = {}, 0
		for i = 1, #s, 4 do
			local a, b, c, d = s:byte(i, i + 3)
			local v = (map[a] or 0) * 262144 + (map[b] or 0) * 4096 + (map[c] or 0) * 64 + (map[d] or 0)
			local x1, x2, x3 = math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256
			n = n + 1
			if d == 61 and c == 61 then out[n] = string.char(x1)
			elseif d == 61 then out[n] = string.char(x1, x2)
			else out[n] = string.char(x1, x2, x3) end
		end
		local file = "UI_jayvee_icon_v1.jpg"
		if not isfile(file) then writefile(file, table.concat(out)) end
		return (getcustomasset or getsynasset)(file)
	end)
	return ok and res or nil
end

local function buildUI()
	local C = {acc = Color3.fromRGB(108, 87, 175), acc2 = Color3.fromRGB(165, 135, 250)}
	local BG, CARD = Color3.fromRGB(13, 13, 19), Color3.fromRGB(23, 23, 34)
	local TXT, DIM = Color3.fromRGB(225, 225, 235), Color3.fromRGB(140, 140, 165)
	local OFF, LINE = Color3.fromRGB(50, 50, 68), Color3.fromRGB(44, 42, 66)
	local W, H, HEAD = 450, 330, 54
	local PY = HEAD + 44
	local PH = H - PY - 14

	-- ===== theme registry =====
	local themed, repaints = {}, {}
	local function reg(obj, prop, fn)
		obj[prop] = fn()
		table.insert(themed, {obj, prop, fn})
	end
	local function applyTheme()
		for _, t in ipairs(themed) do pcall(function() t[1][t[2]] = t[3]() end) end
		for _, f in ipairs(repaints) do pcall(f) end
	end
	local function seq(a, b) return function() return ColorSequence.new(C[a], C[b]) end end

	local function new(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local function round(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
	local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
	local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
	local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
	local function kp(t, c) return ColorSequenceKeypoint.new(t, c) end

	-- ===== icon (your photo, falls back to the diamond) =====
	local iconImgs, iconAsset = {}, nil
	local function logo(parent, sz, pos)
		local c = new("Frame", {Size = UDim2.fromOffset(sz, sz), Position = pos, BackgroundTransparency = 1}, parent)
		local d = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.6, 0.6), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0}, c)
		round(d, math.floor(sz * 0.12))
		local dg = new("UIGradient", {Rotation = 90}, d); reg(dg, "Color", seq("acc2", "acc"))
		local d2 = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.24, 0.24), Rotation = 45, BackgroundColor3 = BG, BorderSizePixel = 0}, c)
		round(d2, 2)
		local im = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BG, BorderSizePixel = 0,
			ScaleType = Enum.ScaleType.Crop, Image = "", Visible = false}, c)
		round(im, sz)
		local ims = new("UIStroke", {Thickness = 2}, im); reg(ims, "Color", function() return C.acc2 end)
		table.insert(iconImgs, im)
		if iconAsset then im.Image = iconAsset; im.Visible = true end
		return c
	end

	local function drag(frame, handle)
		local dragging, start, sp
		local st = {moved = false}
		handle.InputBegan:Connect(function(i)
			if isPress(i) then
				dragging, start, sp = true, i.Position, frame.Position
				st.moved = false
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
		track(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - start
				if d.Magnitude > 6 then st.moved = true end
				frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end))
		return st
	end

	-- ===== window =====
	local main = new("Frame", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, BackgroundTransparency = 0.05, BorderSizePixel = 0,
		ClipsDescendants = true, Active = true}, gui)
	round(main, 18)
	new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(24, 20, 40), Color3.fromRGB(10, 10, 15)), Rotation = 90}, main)
	local stroke = new("UIStroke", {Thickness = 1.8, Color = WHITE, Transparency = 0.1}, main)
	local rainbow, spin, toastOn, userScale = false, true, true, 1
	local stg = new("UIGradient", {}, stroke)
	reg(stg, "Color", function()
		if rainbow then
			return ColorSequence.new({kp(0, Color3.fromRGB(255, 70, 70)), kp(0.2, Color3.fromRGB(255, 220, 70)),
				kp(0.4, Color3.fromRGB(70, 255, 120)), kp(0.6, Color3.fromRGB(70, 200, 255)),
				kp(0.8, Color3.fromRGB(170, 90, 255)), kp(1, Color3.fromRGB(255, 70, 70))})
		end
		local dark = Color3.fromRGB(35, 32, 60)
		return ColorSequence.new({kp(0, C.acc2), kp(0.35, dark), kp(0.65, dark), kp(1, C.acc2)})
	end)

	local base = math.min(1, (gui.AbsoluteSize.X - 30) / W, (gui.AbsoluteSize.Y - 30) / H)
	if base ~= base or base <= 0.3 then base = 1 end
	local sc = new("UIScale", {Scale = base * 0.8}, main)
	TS:Create(sc, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = base}):Play()
	TS:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

	-- ===== header =====
	local header = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1}, main)
	logo(header, 38, UDim2.fromOffset(16, 8))
	local title = new("TextLabel", {Size = UDim2.fromOffset(150, 26), Position = UDim2.fromOffset(62, 14), BackgroundTransparency = 1,
		Text = "ALL POWERS", TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left}, header)
	local tgr = new("UIGradient", {}, title)
	reg(tgr, "Color", function() return ColorSequence.new(WHITE, C.acc2) end)
	local pill = new("TextLabel", {Size = UDim2.fromOffset(100, 28), Position = UDim2.fromOffset(218, 13),
		BackgroundColor3 = Color3.fromRGB(52, 52, 64), Text = "JAYVEE 👑", TextColor3 = WHITE,
		Font = Enum.Font.GothamBold, TextSize = 14}, header)
	round(pill, 14)
	local pst = new("UIStroke", {Thickness = 1.6, Color = WHITE}, pill)
	local pg = new("UIGradient", {}, pst)
	reg(pg, "Color", function() return ColorSequence.new({kp(0, C.acc), kp(0.5, C.acc2), kp(1, C.acc)}) end)

	local minB = new("TextButton", {Size = UDim2.fromOffset(32, 28), Position = UDim2.new(1, -82, 0, 13), BackgroundTransparency = 1,
		Text = "—", TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false}, main)
	local xB = new("TextButton", {Size = UDim2.fromOffset(32, 28), Position = UDim2.new(1, -46, 0, 13), BackgroundTransparency = 1,
		Text = "✕", TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 17, AutoButtonColor = false}, main)
	for _, b in ipairs({minB, xB}) do
		b.MouseEnter:Connect(function() TS:Create(b, TweenInfo.new(0.15), {TextColor3 = WHITE}):Play() end)
		b.MouseLeave:Connect(function() TS:Create(b, TweenInfo.new(0.15), {TextColor3 = DIM}):Play() end)
	end

	-- ===== tabs =====
	local order = {"Home", "Powers", "Settings"}
	local TW = (W - 24) / #order
	local tabPill = new("Frame", {Size = UDim2.fromOffset(TW - 10, 34), Position = UDim2.fromOffset(17, HEAD + 4),
		BackgroundColor3 = WHITE, BorderSizePixel = 0}, main)
	round(tabPill, 12)
	local tpg = new("UIGradient", {Rotation = 90}, tabPill)
	reg(tpg, "Color", function() return ColorSequence.new(C.acc, C.acc:Lerp(WHITE, 0.15)) end)

	local tabs, pages = {}, {}
	local function scrollPage(visible)
		local sf = new("ScrollingFrame", {Size = UDim2.fromOffset(W - 32, PH), Position = UDim2.fromOffset(16, PY),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = visible or false}, main)
		reg(sf, "ScrollBarImageColor3", function() return C.acc end)
		return sf
	end
	for i, nm in ipairs(order) do
		tabs[nm] = new("TextButton", {Size = UDim2.fromOffset(TW, 34), Position = UDim2.fromOffset(12 + (i - 1) * TW, HEAD + 4),
			BackgroundTransparency = 1, Text = nm, TextColor3 = DIM, Font = Enum.Font.GothamMedium, TextSize = 14,
			AutoButtonColor = false}, main)
		pages[nm] = scrollPage()
		new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, pages[nm])
		new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8)}, pages[nm])
	end

	local shown
	local function showPage(obj)
		if shown then shown.Visible = false end
		shown = obj
		obj.Visible = true
		obj.Position = UDim2.fromOffset(16, PY + 16)
		TS:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(16, PY)}):Play()
	end
	local function goTab(name, instant)
		for i, nm in ipairs(order) do
			local on = nm == name
			TS:Create(tabs[nm], TweenInfo.new(0.25), {TextColor3 = on and WHITE or DIM}):Play()
			if on then
				TS:Create(tabPill, TweenInfo.new(instant and 0 or 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{Position = UDim2.fromOffset(12 + (i - 1) * TW + 5, HEAD + 4)}):Play()
			end
		end
		showPage(pages[name])
	end
	for _, nm in ipairs(order) do tabs[nm].MouseButton1Click:Connect(function() goTab(nm) end) end

	-- ===== toast =====
	local function toast(msg)
		if not toastOn then return end
		local t = new("TextLabel", {Size = UDim2.fromOffset(240, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -50),
			BackgroundColor3 = BG, TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 14, Text = msg,
			BorderSizePixel = 0, ZIndex = 20}, gui)
		round(t, 17)
		new("UIStroke", {Color = C.acc, Thickness = 1.5}, t)
		TS:Create(t, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 40)}):Play()
		task.delay(1.5, function()
			TS:Create(t, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0, -50)}):Play()
			Debris:AddItem(t, 0.4)
		end)
	end

	-- ===== components =====
	local n = 0
	local function row(page, h, isBtn)
		n = n + 1
		local r = new(isBtn and "TextButton" or "Frame", {Size = UDim2.new(1, -8, 0, h), BackgroundColor3 = CARD,
			BorderSizePixel = 0, LayoutOrder = n}, page)
		if isBtn then r.Text = ""; r.AutoButtonColor = false end
		round(r, 12)
		local s = new("UIStroke", {Color = LINE, Thickness = 1}, r)
		if isBtn then
			r.MouseEnter:Connect(function()
				TS:Create(r, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(31, 30, 46)}):Play()
				TS:Create(s, TweenInfo.new(0.15), {Color = C.acc}):Play()
			end)
			r.MouseLeave:Connect(function()
				TS:Create(r, TweenInfo.new(0.15), {BackgroundColor3 = CARD}):Play()
				TS:Create(s, TweenInfo.new(0.15), {Color = LINE}):Play()
			end)
		end
		return r
	end
	local function lbl(parent, text, y, h)
		return new("TextLabel", {Size = UDim2.new(0.62, 0, 0, h or 44), Position = UDim2.fromOffset(14, y or 0),
			BackgroundTransparency = 1, Text = text, TextColor3 = TXT, Font = Enum.Font.GothamMedium, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left}, parent)
	end
	local function listPage(parent, y, h, visible)
		local sf = new("ScrollingFrame", {Size = UDim2.fromOffset(W - 32, h), Position = UDim2.fromOffset(0, y),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = visible or false}, parent)
		reg(sf, "ScrollBarImageColor3", function() return C.acc end)
		new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
		new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}, sf)
		return sf
	end

	local function toggle(page, text, get, set)
		local r = row(page, 44, true)
		lbl(r, text)
		local tr = new("Frame", {Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -60, 0.5, -12), BorderSizePixel = 0}, r)
		round(tr, 12)
		local kn = new("Frame", {Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, tr)
		round(kn, 9)
		local function paint(instant)
			local on = get()
			local ti = TweenInfo.new(instant and 0 or 0.22, Enum.EasingStyle.Quad)
			TS:Create(tr, ti, {BackgroundColor3 = on and C.acc or OFF}):Play()
			TS:Create(kn, ti, {Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)}):Play()
		end
		paint(true)
		table.insert(repaints, function() paint(true) end)
		r.MouseButton1Click:Connect(function()
			set(not get()); paint()
			toast(text .. (get() and "  •  ON" or "  •  OFF"))
		end)
	end

	local function slider(page, text, min, max, step, get, set, fmt)
		local r = row(page, 58, false)
		lbl(r, text, 4, 28)
		local val = new("TextLabel", {Size = UDim2.new(0.38, -14, 0, 28), Position = UDim2.new(0.62, 0, 0, 4), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Text = ""}, r)
		reg(val, "TextColor3", function() return C.acc2 end)
		local bar = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, -32, 0, 8), Position = UDim2.new(0, 16, 1, -20),
			BackgroundColor3 = OFF, BorderSizePixel = 0}, r)
		round(bar, 4)
		local fill = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1)}, bar)
		round(fill, 4)
		local fg = new("UIGradient", {}, fill); reg(fg, "Color", seq("acc", "acc2"))
		local kn = new("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, fill)
		round(kn, 8)
		local function paint()
			local v = get()
			fill.Size = UDim2.fromScale(math.clamp((v - min) / (max - min), 0, 1), 1)
			val.Text = fmt and fmt(v) or tostring(v)
		end
		paint()
		local dragging = false
		local function upd(x)
			local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor((min + a * (max - min)) / step + 0.5) * step
			set(math.clamp(math.floor(v * 100 + 0.5) / 100, min, max)); paint()
		end
		bar.InputBegan:Connect(function(i)
			if isPress(i) then dragging = true; page.ScrollingEnabled = false; upd(i.Position.X) end
		end)
		track(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then upd(i.Position.X) end end))
		track(UIS.InputEnded:Connect(function(i)
			if dragging and isPress(i) then dragging = false; page.ScrollingEnabled = true end
		end))
	end

	local function cycle(page, text, opts, get, set)
		local r = row(page, 44, true)
		lbl(r, text)
		local pl = new("TextLabel", {Size = UDim2.fromOffset(108, 26), Position = UDim2.new(1, -122, 0.5, -13),
			BackgroundColor3 = Color3.fromRGB(34, 30, 58), Text = get(), TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13}, r)
		round(pl, 13)
		local ps = new("UIStroke", {Thickness = 1.2}, pl); reg(ps, "Color", function() return C.acc end)
		r.MouseButton1Click:Connect(function()
			local idx = (table.find(opts, get()) or 0) % #opts + 1
			set(opts[idx]); pl.Text = opts[idx]
			toast(text .. "  •  " .. opts[idx])
		end)
	end

	local function stat(page, text)
		local r = row(page, 40, false)
		lbl(r, text, 0, 40)
		local v = new("TextLabel", {Size = UDim2.new(0.38, -14, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Text = "-"}, r)
		reg(v, "TextColor3", function() return C.acc2 end)
		return v
	end

	-- ===== power cards (cooler) =====
	local glowers = {}
	track(RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, g in ipairs(glowers) do g.Rotation = (t * 120) % 360 end
	end))

	local function powerCard(page, p)
		n = n + 1
		powerStates[p.name] = false
		local card = new("TextButton", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, LayoutOrder = n}, page)
		round(card, 14)
		new("UIGradient", {Color = ColorSequence.new(p.a:Lerp(Color3.new(0, 0, 0), p.ready and 0.7 or 0.85),
			Color3.fromRGB(15, 15, 24)), Rotation = 35}, card)
		local us = new("UIScale", {}, card)
		local st = new("UIStroke", {Thickness = p.ready and 2 or 1, Color = WHITE, Transparency = p.ready and 0 or 0.3}, card)
		local sg = new("UIGradient", {}, st)
		if p.ready then
			sg.Color = ColorSequence.new({kp(0, p.a), kp(0.5, p.b), kp(1, p.a)})
			table.insert(glowers, sg)
		else
			sg.Color = ColorSequence.new(LINE, LINE)
		end

		local halo = new("Frame", {Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, BackgroundTransparency = p.ready and 0.75 or 0.92}, card)
		round(halo, 27)
		new("UIGradient", {Color = ColorSequence.new(p.a, p.b), Rotation = 45}, halo)
		local badge = new("Frame", {Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(11, 11), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, BackgroundTransparency = p.ready and 0 or 0.5}, card)
		round(badge, 22)
		new("UIGradient", {Color = ColorSequence.new(p.a, p.b), Rotation = 45}, badge)
		new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = p.icon, TextSize = 24,
			Font = Enum.Font.GothamBold, TextColor3 = WHITE, TextTransparency = p.ready and 0 or 0.3}, badge)
		if p.sub then
			local sb = new("TextLabel", {Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(38, 38), BackgroundColor3 = BG,
				Text = p.sub, TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = WHITE, ZIndex = 3}, card)
			round(sb, 10)
			new("UIStroke", {Thickness = 1, Color = LINE}, sb)
		end

		new("TextLabel", {Size = UDim2.new(1, -74, 0, 22), Position = UDim2.fromOffset(68, 10), BackgroundTransparency = 1,
			Text = p.name, TextColor3 = p.ready and WHITE or DIM, Font = Enum.Font.GothamBlack, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, card)
		local tag = new("TextLabel", {Size = UDim2.fromOffset(p.ready and 78 or 70, 18), Position = UDim2.fromOffset(68, 36),
			BackgroundColor3 = p.ready and C.acc or Color3.fromRGB(34, 34, 48), TextColor3 = p.ready and WHITE or DIM,
			Text = p.ready and "● AVAILABLE" or "🔒 SOON", Font = Enum.Font.GothamBold, TextSize = 9}, card)
		round(tag, 9)
		if p.ready then reg(tag, "BackgroundColor3", function() return C.acc end) end

		local function sz(s) TS:Create(us, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = s}):Play() end
		card.MouseEnter:Connect(function() if p.ready then sz(1.03) end end)
		card.MouseLeave:Connect(function() sz(1) end)
		card.MouseButton1Down:Connect(function() sz(0.95) end)
		card.MouseButton1Up:Connect(function() sz(1) end)
		card.MouseButton1Click:Connect(function()
			if not p.ready then
				toast(p.name .. "  •  Coming soon")
				return
			end
			if activePower == p.name then
				powerStates[p.name] = false
				activePower = nil
				if p.onDisable then pcall(p.onDisable) end
				toast(p.name .. "  •  OFF")
				return
			end
			if activePower then
				powerStates[activePower] = false
				local oldName = activePower
				activePower = nil
				toast(oldName .. "  •  OFF")
			end
			powerStates[p.name] = true
			activePower = p.name
			if p.onEnable then pcall(p.onEnable) end
			if p.open then p.open() end
			toast(p.name .. "  •  ON")
		end)
	end

	-- ===== HOME =====
	local hp = pages["Home"]
	local banner = row(hp, 74, false)
	banner.BackgroundColor3 = WHITE
	local bg = new("UIGradient", {Rotation = 20}, banner)
	reg(bg, "Color", function() return ColorSequence.new(C.acc:Lerp(Color3.new(0, 0, 0), 0.35), Color3.fromRGB(20, 18, 34)) end)
	logo(banner, 54, UDim2.fromOffset(12, 10))
	new("TextLabel", {Size = UDim2.new(1, -84, 0, 28), Position = UDim2.fromOffset(74, 10), BackgroundTransparency = 1,
		Text = "ULTRA INSTINCT", TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left}, banner)
	new("TextLabel", {Size = UDim2.new(1, -84, 0, 20), Position = UDim2.fromOffset(74, 40), BackgroundTransparency = 1,
		Text = "Admin 👑 JAYVEE", TextColor3 = Color3.fromRGB(255, 215, 90), Font = Enum.Font.GothamBold, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left}, banner)
	local sPower = stat(hp, "Active Power")
	local sDodge = stat(hp, "Total Dodges")
	local sLock = stat(hp, "Target Lock")
	local sFps = stat(hp, "FPS")

	-- ===== character power views (Goku / Luffy grids) =====
	local function charView(titleText)
		local v = new("Frame", {Size = UDim2.fromOffset(W - 32, PH), Position = UDim2.fromOffset(16, PY),
			BackgroundTransparency = 1, Visible = false}, main)
		local bk = new("TextButton", {Size = UDim2.fromOffset(34, 30), BackgroundColor3 = CARD, Text = "‹", TextColor3 = WHITE,
			Font = Enum.Font.GothamBold, TextSize = 22, AutoButtonColor = false}, v)
		round(bk, 10)
		new("TextLabel", {Size = UDim2.fromOffset(240, 30), Position = UDim2.fromOffset(44, 0), BackgroundTransparency = 1,
			Text = titleText, TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left}, v)
		local sf = new("ScrollingFrame", {Size = UDim2.fromOffset(W - 32, PH - 38), Position = UDim2.fromOffset(0, 38),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y}, v)
		reg(sf, "ScrollBarImageColor3", function() return C.acc end)
		new("UIGridLayout", {CellSize = UDim2.new(0.5, -5, 0, 66), CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder}, sf)
		new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}, sf)
		bk.MouseButton1Click:Connect(function() showPage(pages["Powers"]) end)
		return v, sf
	end
	local gokuView, gokuGrid = charView("🐉  GOKU POWERS")
	local luffyView, luffyGrid = charView("👒  LUFFY POWERS")

	-- ===== ULTRA INSTINCT view (inside Goku Powers) =====
	local uiView = new("Frame", {Size = UDim2.fromOffset(W - 32, PH), Position = UDim2.fromOffset(16, PY), BackgroundTransparency = 1,
		Visible = false}, main)
	local back = new("TextButton", {Size = UDim2.fromOffset(34, 30), BackgroundColor3 = CARD, Text = "‹", TextColor3 = WHITE,
		Font = Enum.Font.GothamBold, TextSize = 22, AutoButtonColor = false}, uiView)
	round(back, 10)
	new("TextLabel", {Size = UDim2.fromOffset(140, 30), Position = UDim2.fromOffset(42, 0), BackgroundTransparency = 1,
		Text = "🌀 Ultra Instinct", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, uiView)
	local segBox = new("Frame", {Size = UDim2.fromOffset(228, 30), Position = UDim2.fromOffset(W - 32 - 228, 0), BackgroundColor3 = CARD,
		BorderSizePixel = 0}, uiView)
	round(segBox, 10)
	local segPill = new("Frame", {Size = UDim2.fromOffset(72, 24), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = WHITE, BorderSizePixel = 0}, segBox)
	round(segPill, 8)
	local sgg = new("UIGradient", {Rotation = 90}, segPill); reg(sgg, "Color", seq("acc", "acc"))
	local segNames = {"Dodge", "Aim", "Visual"}
	local subs, segBtns, curSub = {}, {}, nil
	for i, nm in ipairs(segNames) do
		segBtns[nm] = new("TextButton", {Size = UDim2.fromOffset(74, 30), Position = UDim2.fromOffset((i - 1) * 74, 0), BackgroundTransparency = 1,
			Text = nm, TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false}, segBox)
		subs[nm] = listPage(uiView, 38, PH - 38, false)
	end
	local function goSub(name)
		for i, nm in ipairs(segNames) do
			TS:Create(segBtns[nm], TweenInfo.new(0.2), {TextColor3 = nm == name and WHITE or DIM}):Play()
			if nm == name then
				TS:Create(segPill, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(3 + (i - 1) * 74, 3)}):Play()
			end
		end
		if curSub then subs[curSub].Visible = false end
		curSub = name
		subs[name].Visible = true
	end
	for _, nm in ipairs(segNames) do segBtns[nm].MouseButton1Click:Connect(function() goSub(nm) end) end
	back.MouseButton1Click:Connect(function() showPage(gokuView) end)

	local dp = subs.Dodge
	toggle(dp, "Ultra Instinct", function() return enabled end, function(v) enabled = v end)
	slider(dp, "Dodge Radius", 3, 60, 1, function() return radius end, function(v) radius = v end)
	cycle(dp, "Dodge Mode", {"NORMAL", "TELEPORT"}, function() return dodgeMode end, function(v) dodgeMode = v end)
	toggle(dp, "Auto Counter", function() return counter end, function(v) counter = v end)
	toggle(dp, "Target Lock", function() return lockOn end, function(v) lockOn = v; if not v then releaseLock() end end)
	toggle(dp, "Free Move", function() return freeMove end, function(v) freeMove = v; if not v then releaseLock() end end)
	cycle(dp, "Back Dodge", {"RANDOM", "LEFT", "RIGHT"}, function() return backSide end, function(v) backSide = v end)
	slider(dp, "Lock Time", 1, 10, 1, function() return LOCK_TIME end, function(v) LOCK_TIME = v end, function(v) return v .. "s" end)
	slider(dp, "Return Delay", 0, 0.3, 0.01, function() return returnDelay end, function(v) returnDelay = v end, function(v) return string.format("%.2fs", v) end)
	slider(dp, "Dodge Cooldown", 0.3, 3, 0.1, function() return cooldown end, function(v) cooldown = v end, function(v) return string.format("%.1fs", v) end)

	local ap = subs.Aim
	toggle(ap, "Aimbot", function() return aimOn end, function(v) aimOn = v end)
	slider(ap, "Smoothness", 0.1, 1, 0.1, function() return aimSmooth end, function(v) aimSmooth = v end, function(v) return string.format("%.1f", v) end)
	cycle(ap, "Aim Target", {"HEAD", "BODY"}, function() return aimHead and "HEAD" or "BODY" end, function(v) aimHead = v == "HEAD" end)
	toggle(ap, "Team Check", function() return teamCheck end, function(v) teamCheck = v end)

	local vp = subs.Visual
	toggle(vp, "Show Hitbox", function() return showBox end, function(v) showBox = v end)
	toggle(vp, "Dodge Sounds", function() return soundOn end, function(v) soundOn = v end)
	toggle(vp, "Screen Effects", function() return fxOn end, function(v) fxOn = v end)
	goSub("Dodge")

	-- ===== GOKU POWERS =====
	local gokuPowers = {
		{name = "Ultra Instinct", icon = "🌀", a = rgb(190, 215, 255), b = rgb(120, 90, 220), ready = true,
			open = function() showPage(uiView) end,
			onEnable = function() enabled = true end,
			onDisable = function() enabled = false; releaseLock() end},
		{name = "Mastered Ultra Instinct", icon = "🌌", a = rgb(230, 235, 255), b = rgb(110, 120, 200)},
		{name = "Kamehameha", icon = "💥", a = rgb(90, 190, 255), b = rgb(40, 90, 220)},
		{name = "Instant Transmission", icon = "⚡", a = rgb(255, 230, 90), b = rgb(255, 150, 40)},
		{name = "Kaioken", icon = "🔴", a = rgb(255, 110, 90), b = rgb(190, 30, 40)},
		{name = "Super Saiyan", icon = "🌟", a = rgb(255, 235, 110), b = rgb(240, 170, 30)},
		{name = "Super Saiyan 2", icon = "✨", a = rgb(255, 240, 150), b = rgb(250, 190, 40)},
		{name = "Super Saiyan 3", icon = "🔥", a = rgb(255, 220, 90), b = rgb(230, 120, 20)},
		{name = "Super Saiyan God", icon = "🩸", a = rgb(255, 120, 120), b = rgb(170, 20, 50)},
		{name = "Super Saiyan Blue", icon = "🔷", a = rgb(120, 220, 255), b = rgb(30, 110, 230)},
		{name = "Spirit Bomb", icon = "🌍", a = rgb(140, 220, 255), b = rgb(60, 130, 210)},
		{name = "Dragon Fist", icon = "🐉", a = rgb(255, 190, 80), b = rgb(200, 70, 30)},
	}
	for _, p in ipairs(gokuPowers) do powerCard(gokuGrid, p) end

	-- ===== LUFFY POWERS =====
	local luffyPowers = {
		{name = "Gomu Gomu Pistol", sub = "👊"}, {name = "Gatling", sub = "💥"},
		{name = "Gear Second", sub = "💨"}, {name = "Gear Third", sub = "🦾"},
		{name = "Gear Fourth", sub = "🦍"}, {name = "Gear Fifth", sub = "🌞"},
		{name = "Observation Haki", sub = "👁"}, {name = "Armament Haki", sub = "⚫"},
		{name = "Conqueror's Haki", sub = "👑"}, {name = "Elephant Gun", sub = "🐘"},
		{name = "Red Hawk", sub = "🔥"}, {name = "Bajrang Gun", sub = "🏔"},
	}
	for _, p in ipairs(luffyPowers) do
		p.icon = "👒"; p.a = rgb(255, 120, 90); p.b = rgb(200, 40, 50)
		powerCard(luffyGrid, p)
	end

	-- ===== POWERS TAB (Goku / Luffy + icon) =====
	local function charCard(name, emoji, a, b, total, readyCount, view)
		local r = row(pages["Powers"], 98, true)
		local bgf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, r)
		round(bgf, 12)
		new("UIGradient", {Color = ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.6), Color3.fromRGB(16, 16, 26)), Rotation = 20}, bgf)

		local ringF = new("Frame", {Size = UDim2.fromOffset(72, 72), Position = UDim2.fromOffset(14, 13), BackgroundTransparency = 1, ZIndex = 2}, r)
		round(ringF, 36)
		local rs = new("UIStroke", {Thickness = 3, Color = WHITE}, ringF)
		local rg = new("UIGradient", {Color = ColorSequence.new({kp(0, a), kp(0.5, b), kp(1, a)})}, rs)
		local face = new("Frame", {Size = UDim2.fromOffset(60, 60), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, ZIndex = 2}, ringF)
		round(face, 30)
		new("UIGradient", {Color = ColorSequence.new(a, b), Rotation = 45}, face)
		new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = emoji, TextSize = 34,
			Font = Enum.Font.GothamBold, TextColor3 = WHITE, ZIndex = 3}, face)

		new("TextLabel", {Size = UDim2.new(1, -150, 0, 28), Position = UDim2.fromOffset(100, 20), BackgroundTransparency = 1,
			Text = name, TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2}, r)
		new("TextLabel", {Size = UDim2.new(1, -150, 0, 16), Position = UDim2.fromOffset(100, 52), BackgroundTransparency = 1,
			Text = total .. " POWERS  •  " .. readyCount .. " AVAILABLE", TextColor3 = DIM, Font = Enum.Font.GothamBold,
			TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2}, r)
		local arrow = new("TextLabel", {Size = UDim2.fromOffset(30, 98), Position = UDim2.new(1, -38, 0, 0), BackgroundTransparency = 1,
			Text = "›", TextSize = 36, Font = Enum.Font.GothamBold, ZIndex = 2}, r)
		reg(arrow, "TextColor3", function() return C.acc2 end)

		track(RunService.Heartbeat:Connect(function()
			local t = os.clock()
			rg.Rotation = (t * 120) % 360
			ringF.Position = UDim2.fromOffset(14, 13 + math.sin(t * 2) * 2)
		end))
		r.MouseButton1Click:Connect(function() showPage(view) end)
	end

	charCard("GOKU", "🐉", rgb(255, 170, 60), rgb(230, 80, 30), #gokuPowers, 1, gokuView)
	charCard("LUFFY", "👒", rgb(255, 120, 90), rgb(200, 40, 50), #luffyPowers, 0, luffyView)

	-- ===== SETTINGS =====
	local sp = pages["Settings"]
	local presets = {
		{"Purple", rgb(108, 87, 175), rgb(165, 135, 250)}, {"Blue", rgb(55, 115, 220), rgb(120, 180, 255)},
		{"Cyan", rgb(30, 160, 185), rgb(110, 230, 240)}, {"Green", rgb(45, 165, 105), rgb(110, 235, 170)},
		{"Gold", rgb(200, 150, 40), rgb(255, 210, 100)}, {"Orange", rgb(215, 110, 40), rgb(255, 170, 100)},
		{"Red", rgb(195, 55, 75), rgb(255, 120, 135)}, {"Pink", rgb(205, 75, 155), rgb(255, 140, 210)},
	}
	local tr = row(sp, 74, false)
	lbl(tr, "Menu Color", 4, 28)
	local swatches = {}
	for i, ps in ipairs(presets) do
		local sw = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(14 + (i - 1) * 38, 36), BackgroundColor3 = ps[2],
			Text = "", AutoButtonColor = false}, tr)
		round(sw, 15)
		local ss = new("UIStroke", {Thickness = 2, Color = WHITE, Transparency = i == 1 and 0 or 1}, sw)
		swatches[i] = ss
		new("UIGradient", {Color = ColorSequence.new(ps[3], ps[2]), Rotation = 45}, sw)
		sw.MouseButton1Click:Connect(function()
			C.acc, C.acc2 = ps[2], ps[3]
			for j, st in ipairs(swatches) do st.Transparency = j == i and 0 or 1 end
			applyTheme()
			toast("Menu Color  •  " .. ps[1])
		end)
	end
	toggle(sp, "Rainbow Border", function() return rainbow end, function(v) rainbow = v; applyTheme() end)
	toggle(sp, "Spinning Border", function() return spin end, function(v) spin = v end)
	slider(sp, "Menu Size", 0.7, 1.2, 0.05, function() return userScale end, function(v) userScale = v; sc.Scale = base * v end,
		function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
	slider(sp, "Menu Transparency", 0, 0.6, 0.05, function() return main.BackgroundTransparency end,
		function(v) main.BackgroundTransparency = v end, function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
	toggle(sp, "Notifications", function() return toastOn end, function(v) toastOn = v end)
	local rp = row(sp, 44, true)
	lbl(rp, "Reset Menu Position")
	local rbtn = new("TextLabel", {Size = UDim2.fromOffset(60, 26), Position = UDim2.new(1, -74, 0.5, -13), BackgroundColor3 = Color3.fromRGB(34, 30, 58),
		Text = "RESET", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12}, rp)
	round(rbtn, 13)
	rp.MouseButton1Click:Connect(function()
		TS:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		toast("Menu position reset")
	end)
	local sKey = stat(sp, "Menu Key")
	sKey.Text = "RightShift"

	goTab("Home", true)

	-- ===== minimize / hide / open =====
	local mini = false
	minB.MouseButton1Click:Connect(function()
		mini = not mini
		TS:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = UDim2.fromOffset(W, mini and HEAD or H)}):Play()
	end)

	local openB = new("TextButton", {Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 12, 0.5, 0), BackgroundColor3 = BG,
		Text = "", AutoButtonColor = false, Visible = false, ZIndex = 10}, gui)
	round(openB, 27)
	logo(openB, 54, UDim2.fromOffset(0, 0))

	local function show(v)
		if v then
			main.Visible = true; openB.Visible = false
			sc.Scale = base * userScale * 0.85
			TS:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = base * userScale}):Play()
		else
			TS:Create(sc, TweenInfo.new(0.2), {Scale = base * userScale * 0.85}):Play()
			task.delay(0.2, function() main.Visible = false; openB.Visible = true end)
		end
	end
	xB.MouseButton1Click:Connect(function() show(false) end)
	drag(main, header)
	local function edge(pos, size)
		local e = new("Frame", {Position = pos, Size = size, BackgroundTransparency = 1}, main)
		drag(main, e)
	end
	edge(UDim2.fromOffset(0, HEAD), UDim2.new(0, 16, 1, -HEAD))
	edge(UDim2.new(1, -16, 0, HEAD), UDim2.new(0, 16, 1, -HEAD))
	edge(UDim2.new(0, 0, 1, -14), UDim2.new(1, 0, 0, 14))
	local ost = drag(openB, openB)
	openB.MouseButton1Click:Connect(function() if not ost.moved then show(true) end end)
	track(UIS.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == Enum.KeyCode.RightShift then show(not main.Visible) end
	end))

	-- ===== load photo icon =====
	task.spawn(function()
		iconAsset = loadIcon()
		if iconAsset then
			for _, im in ipairs(iconImgs) do im.Image = iconAsset; im.Visible = true end
		end
	end)

	-- ===== live loop =====
	local t0, fps, acc = os.clock(), 60, 0
	track(RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - t0
		if spin then stg.Rotation = (t * 70) % 360 end
		pg.Rotation = (t * 140) % 360
		fps = fps * 0.92 + (1 / math.max(dt, 1e-3)) * 0.08
		acc = acc + dt
		if acc > 0.2 and main.Visible then
			acc = 0
			sPower.Text = activePower or (enabled and "Ultra Instinct" or "None")
			sDodge.Text = tostring(dodgeCount)
			local left = lockUntil - tick()
			if lockTarget and left > 0 then
				sLock.Text = string.format("LOCKED %.1fs", left); sLock.TextColor3 = Color3.fromRGB(255, 120, 130)
			else
				sLock.Text = "IDLE"; sLock.TextColor3 = C.acc2
			end
			sFps.Text = tostring(math.floor(fps + 0.5))
		end
	end))
end

local okUI, err = pcall(buildUI)
if not okUI then warn("[UltraInstinct] UI error: " .. tostring(err)) end
