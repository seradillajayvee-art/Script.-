-- ULTRA INSTINCT • JAYVEE
-- Own-game LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
--
-- Features:
-- • Password security UI
-- • Draggable security/main/minimized UI
-- • Automatic damage-triggered dodge
-- • Nearest enemy target
-- • Camera lock during dodge
-- • Touch/joystick movement cancels camera lock
-- • Optional 5-second target follow after dodge
-- • Smooth follow-stop effect
-- • UI sounds and animations
--
-- For a production game, validate damage/dodge on the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PASSWORD = "ULTRAINSTINCTBYJAYVEEV2"

local SETTINGS = {
	Enabled = true,
	AutoDodge = true,
	FollowAfterDodge = true,
	FollowDuration = 5,
	DodgeDistance = 8,
	DodgeDuration = 0.22,
	CameraSmoothness = 0.16,
	TargetRadius = 55,
	TouchMoveThreshold = 0.18,
}

local character
local humanoid
local root
local lastHealth
local dodging = false
local following = false
local followTarget
local cameraLocked = false
local followToken = 0

local function refreshCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	lastHealth = humanoid.Health
end

refreshCharacter()

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	refreshCharacter()
end)

local function makeSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 0.45
	s.Parent = SoundService
	return s
end

local clickSound = makeSound(9118828568, 0.45)
local openSound = makeSound(9118823107, 0.45)
local dodgeSound = makeSound(138186576, 0.5)
local stopSound = makeSound(9118828568, 0.35)

local function play(sound)
	pcall(function()
		sound:Play()
	end)
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
	return s
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

local function tween(obj, time, props, style, direction)
	return TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
end

--==================================================
-- UI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "UltraInstinct_JAYVEE"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local security = Instance.new("Frame")
security.Size = UDim2.fromOffset(400, 275)
security.Position = UDim2.new(0.5, -200, 0.5, -138)
security.BackgroundColor3 = Color3.fromRGB(12,12,19)
security.BackgroundTransparency = 0.04
security.Parent = gui
corner(security, 20)
stroke(security, 0.1)
draggable(security)

local secScale = Instance.new("UIScale")
secScale.Scale = 0.82
secScale.Parent = security

local secTitle = Instance.new("TextLabel")
secTitle.BackgroundTransparency = 1
secTitle.Size = UDim2.new(1,-30,0,42)
secTitle.Position = UDim2.fromOffset(15,12)
secTitle.Text = "ULTRA INSTINCT"
secTitle.Font = Enum.Font.GothamBlack
secTitle.TextSize = 27
secTitle.TextColor3 = Color3.new(1,1,1)
secTitle.Parent = security

local secSub = Instance.new("TextLabel")
secSub.BackgroundTransparency = 1
secSub.Size = UDim2.new(1,-30,0,25)
secSub.Position = UDim2.fromOffset(15,53)
secSub.Text = "SECURITY SYSTEM  •  ADMIN JAYVEE"
secSub.Font = Enum.Font.GothamBold
secSub.TextSize = 11
secSub.TextColor3 = Color3.fromRGB(155,155,175)
secSub.Parent = security

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-40,0,48)
box.Position = UDim2.fromOffset(20,92)
box.PlaceholderText = "ENTER ACCESS KEY"
box.ClearTextOnFocus = false
box.Text = ""
box.Font = Enum.Font.GothamBold
box.TextSize = 13
box.TextColor3 = Color3.new(1,1,1)
box.PlaceholderColor3 = Color3.fromRGB(120,120,135)
box.BackgroundColor3 = Color3.fromRGB(25,25,36)
box.Parent = security
corner(box, 12)

local enter = Instance.new("TextButton")
enter.Size = UDim2.new(1,-40,0,46)
enter.Position = UDim2.fromOffset(20,153)
enter.Text = "UNLOCK ULTRA INSTINCT"
enter.Font = Enum.Font.GothamBlack
enter.TextSize = 12
enter.TextColor3 = Color3.new(1,1,1)
enter.BackgroundColor3 = Color3.fromRGB(54,54,76)
enter.AutoButtonColor = false
enter.Parent = security
corner(enter, 12)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1,-40,0,28)
status.Position = UDim2.fromOffset(20,210)
status.Text = "SECURE • WAITING FOR ACCESS"
status.Font = Enum.Font.GothamBold
status.TextSize = 10
status.TextColor3 = Color3.fromRGB(145,145,165)
status.Parent = security

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(485, 365)
main.Position = UDim2.new(0.5,-242,0.5,-182)
main.BackgroundColor3 = Color3.fromRGB(11,11,18)
main.BackgroundTransparency = 0.035
main.Visible = false
main.Parent = gui
corner(main, 22)
stroke(main, 0.1)
draggable(main)

local top = Instance.new("Frame")
top.Size = UDim2.new(1,0,0,76)
top.BackgroundTransparency = 1
top.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-90,0,40)
title.Position = UDim2.fromOffset(18,8)
title.Text = "ULTRA INSTINCT"
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1,1,1)
title.Parent = top

local admin = Instance.new("TextLabel")
admin.BackgroundTransparency = 1
admin.Size = UDim2.new(1,-90,0,20)
admin.Position = UDim2.fromOffset(20,48)
admin.Text = "ADMIN  •  JAYVEE  |  OWN-GAME MODE"
admin.Font = Enum.Font.GothamBold
admin.TextSize = 10
admin.TextXAlignment = Enum.TextXAlignment.Left
admin.TextColor3 = Color3.fromRGB(150,150,170)
admin.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(38,38)
close.Position = UDim2.new(1,-52,0,16)
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextSize = 23
close.TextColor3 = Color3.fromRGB(215,215,225)
close.BackgroundColor3 = Color3.fromRGB(28,28,40)
close.AutoButtonColor = false
close.Parent = top
corner(close, 12)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-44,0,78)
info.Position = UDim2.fromOffset(22,87)
info.BackgroundColor3 = Color3.fromRGB(22,22,32)
info.Text = "INFO\nAutomatic damage-triggered dodge • nearest-enemy targeting\nJoystick movement cancels camera lock • 5s follow after dodge"
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Center
info.Font = Enum.Font.GothamMedium
info.TextSize = 11
info.TextColor3 = Color3.fromRGB(200,200,215)
info.Parent = main
corner(info, 14)

local enabledButton = Instance.new("TextButton")
enabledButton.Size = UDim2.fromOffset(207,50)
enabledButton.Position = UDim2.fromOffset(22,178)
enabledButton.Font = Enum.Font.GothamBlack
enabledButton.TextSize = 12
enabledButton.TextColor3 = Color3.new(1,1,1)
enabledButton.AutoButtonColor = false
enabledButton.Parent = main
corner(enabledButton, 13)

local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.fromOffset(207,50)
autoButton.Position = UDim2.fromOffset(244,178)
autoButton.Font = Enum.Font.GothamBlack
autoButton.TextSize = 12
autoButton.TextColor3 = Color3.new(1,1,1)
autoButton.AutoButtonColor = false
autoButton.Parent = main
corner(autoButton, 13)

local followButton = Instance.new("TextButton")
followButton.Size = UDim2.fromOffset(429,50)
followButton.Position = UDim2.fromOffset(22,238)
followButton.Font = Enum.Font.GothamBlack
followButton.TextSize = 12
followButton.TextColor3 = Color3.new(1,1,1)
followButton.AutoButtonColor = false
followButton.Parent = main
corner(followButton, 13)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1,-44,0,34)
hint.Position = UDim2.fromOffset(22,305)
hint.Text = "DODGE: incoming damage  •  MOVE JOYSTICK: cancel camera lock"
hint.Font = Enum.Font.GothamBold
hint.TextSize = 9
hint.TextColor3 = Color3.fromRGB(135,135,155)
hint.Parent = main

local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(62,62)
mini.Position = UDim2.new(0,18,0.5,-31)
mini.Text = "UI"
mini.Font = Enum.Font.GothamBlack
mini.TextSize = 16
mini.TextColor3 = Color3.new(1,1,1)
mini.BackgroundColor3 = Color3.fromRGB(17,17,27)
mini.Visible = false
mini.Parent = gui
corner(mini, 18)
stroke(mini, 0.12)
draggable(mini)

local function refreshButtons()
	enabledButton.Text = SETTINGS.Enabled and "SYSTEM  •  ON" or "SYSTEM  •  OFF"
	enabledButton.BackgroundColor3 = SETTINGS.Enabled and Color3.fromRGB(48,78,61) or Color3.fromRGB(65,38,42)

	autoButton.Text = SETTINGS.AutoDodge and "AUTO DODGE  •  ON" or "AUTO DODGE  •  OFF"
	autoButton.BackgroundColor3 = SETTINGS.AutoDodge and Color3.fromRGB(48,78,61) or Color3.fromRGB(65,38,42)

	followButton.Text = SETTINGS.FollowAfterDodge and "5 SECOND FOLLOW  •  ON" or "5 SECOND FOLLOW  •  OFF"
	followButton.BackgroundColor3 = SETTINGS.FollowAfterDodge and Color3.fromRGB(48,78,61) or Color3.fromRGB(65,38,42)
end

refreshButtons()

local function showMain()
	main.Visible = true
	main.Size = UDim2.fromOffset(450,335)
	tween(main,0.35,{Size=UDim2.fromOffset(485,365)},Enum.EasingStyle.Back):Play()
end

local function hideMain()
	tween(main,0.22,{Size=UDim2.fromOffset(450,335)},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()
	task.wait(0.2)
	main.Visible = false
	mini.Visible = true
end

enabledButton.MouseButton1Click:Connect(function()
	play(clickSound)
	SETTINGS.Enabled = not SETTINGS.Enabled
	refreshButtons()
end)

autoButton.MouseButton1Click:Connect(function()
	play(clickSound)
	SETTINGS.AutoDodge = not SETTINGS.AutoDodge
	refreshButtons()
end)

followButton.MouseButton1Click:Connect(function()
	play(clickSound)
	SETTINGS.FollowAfterDodge = not SETTINGS.FollowAfterDodge
	refreshButtons()
end)

close.MouseButton1Click:Connect(function()
	play(clickSound)
	hideMain()
end)

mini.MouseButton1Click:Connect(function()
	play(openSound)
	mini.Visible = false
	showMain()
end)

enter.MouseButton1Click:Connect(function()
	play(clickSound)
	if box.Text == PASSWORD then
		status.Text = "ACCESS GRANTED  •  ULTRA INSTINCT READY"
		status.TextColor3 = Color3.fromRGB(165,255,185)
		play(openSound)
		tween(secScale,0.25,{Scale=0.72},Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
		task.wait(0.2)
		security.Visible = false
		showMain()
	else
		status.Text = "ACCESS DENIED  •  INVALID KEY"
		status.TextColor3 = Color3.fromRGB(255,120,120)
		tween(security,0.07,{Position=UDim2.new(0.5,-190,0.5,-138)},Enum.EasingStyle.Linear,Enum.EasingDirection.InOut):Play()
		task.wait(0.07)
		tween(security,0.07,{Position=UDim2.new(0.5,-200,0.5,-138)},Enum.EasingStyle.Linear):Play()
	end
end)

--==================================================
-- Targeting
--==================================================

local function getRoot(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

local function getNearestEnemy()
	if not root then return nil end

	local best
	local bestDistance = SETTINGS.TargetRadius

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherHum = getHumanoid(other.Character)
			local otherRoot = getRoot(other.Character)

			if otherHum and otherRoot and otherHum.Health > 0 then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = other.Character
				end
			end
		end
	end

	-- Also supports NPC enemies in workspace with a Humanoid.
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) then
			local hum = getHumanoid(obj)
			local objRoot = getRoot(obj)

			if hum and objRoot and hum.Health > 0 then
				local distance = (objRoot.Position - root.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = obj
				end
			end
		end
	end

	return best
end

--==================================================
-- Effects
--==================================================

local function pulseEffect()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1,1)
	flash.BackgroundColor3 = Color3.fromRGB(235,235,255)
	flash.BackgroundTransparency = 0.72
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = gui

	tween(flash,0.32,{BackgroundTransparency=1},Enum.EasingStyle.Quint):Play()
	Debris:AddItem(flash,0.4)
end

local function stopEffect()
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(30,30)
	ring.Position = UDim2.new(0.5,-15,0.5,-15)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 101
	ring.Parent = gui
	corner(ring,50)
	local st = stroke(ring,0)
	st.Thickness = 3
	st.Transparency = 0

	tween(ring,0.45,{
		Size=UDim2.fromOffset(230,230),
		Position=UDim2.new(0.5,-115,0.5,-115)
	},Enum.EasingStyle.Quint):Play()

	tween(st,0.45,{Transparency=1},Enum.EasingStyle.Quint):Play()
	Debris:AddItem(ring,0.55)
	play(stopSound)
end

--==================================================
-- Camera / joystick cancel
--==================================================

local function setCameraLock(target)
	if not target then return end
	cameraLocked = true
end

local function releaseCameraLock()
	if cameraLocked then
		cameraLocked = false
	end
end

UIS.InputChanged:Connect(function(input)
	if not cameraLocked then return end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		if math.abs(delta.X) + math.abs(delta.Y) > 2 then
			releaseCameraLock()
		end
	end
end)

UIS.InputBegan:Connect(function(input)
	if not cameraLocked then return end

	if input.KeyCode == Enum.KeyCode.W
		or input.KeyCode == Enum.KeyCode.A
		or input.KeyCode == Enum.KeyCode.S
		or input.KeyCode == Enum.KeyCode.D
		or input.KeyCode == Enum.KeyCode.Thumbstick1 then
		releaseCameraLock()
	end
end)

-- Mobile thumbstick detection.
RunService.RenderStepped:Connect(function()
	if not cameraLocked then return end

	local state = UIS:GetGamepadState(Enum.UserInputType.Gamepad1)
	for _, input in ipairs(state) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			if input.Position.Magnitude > SETTINGS.TouchMoveThreshold then
				releaseCameraLock()
			end
		end
	end
end)

--==================================================
-- Dodge
--==================================================

local function faceTarget(targetRoot)
	if not root or not targetRoot then return end

	local direction = targetRoot.Position - root.Position
	if direction.Magnitude < 0.05 then return end

	local flat = Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude > 0.05 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	end
end

local function followTargetForFiveSeconds(target)
	if not SETTINGS.FollowAfterDodge or not target then return end

	local targetRoot = getRoot(target)
	local targetHum = getHumanoid(target)
	if not targetRoot or not targetHum then return end

	following = true
	followTarget = target
	followToken += 1
	local token = followToken

	task.spawn(function()
		local start = os.clock()

		while following and token == followToken and os.clock() - start < SETTINGS.FollowDuration do
			if not root or not root.Parent then break end
			if not targetRoot.Parent or targetHum.Health <= 0 then break end

			local desired = targetRoot.Position - targetRoot.CFrame.LookVector * 3
			local flat = Vector3.new(desired.X, root.Position.Y, desired.Z)

			root.CFrame = root.CFrame:Lerp(
				CFrame.lookAt(flat, Vector3.new(targetRoot.Position.X, flat.Y, targetRoot.Position.Z)),
				0.12
			)

			task.wait()
		end

		if token == followToken then
			following = false
			followTarget = nil
			stopEffect()
		end
	end)
end

local function dodge()
	if dodging or not SETTINGS.Enabled or not SETTINGS.AutoDodge then return end
	if not character or not humanoid or not root or humanoid.Health <= 0 then return end

	dodging = true
	followToken += 1
	following = false
	followTarget = nil

	local target = getNearestEnemy()
	local targetRoot = target and getRoot(target)

	play(dodgeSound)
	pulseEffect()

	if targetRoot then
		faceTarget(targetRoot)
		setCameraLock(target)
	end

	-- Dash sideways/backward away from the target.
	local direction
	if targetRoot then
		local away = root.Position - targetRoot.Position
		away = Vector3.new(away.X,0,away.Z)
		if away.Magnitude > 0.05 then
			direction = away.Unit
		end
	end

	if not direction then
		direction = -root.CFrame.LookVector
		direction = Vector3.new(direction.X,0,direction.Z).Unit
	end

	local startCF = root.CFrame
	local endPos = root.Position + direction * SETTINGS.DodgeDistance
	local endCF = CFrame.lookAt(endPos, endPos + root.CFrame.LookVector)

	local started = os.clock()

	while os.clock() - started < SETTINGS.DodgeDuration do
		local alpha = math.clamp((os.clock()-started)/SETTINGS.DodgeDuration,0,1)
		alpha = 1 - (1-alpha)^3
		if root and root.Parent then
			root.CFrame = startCF:Lerp(endCF,alpha)
		end
		RunService.RenderStepped:Wait()
	end

	if target and targetRoot and targetRoot.Parent then
		followTargetForFiveSeconds(target)
	end

	task.delay(0.12,function()
		dodging = false
	end)
end

-- Camera tracking while locked.
RunService.RenderStepped:Connect(function()
	if not cameraLocked or not followTarget then return end

	local targetRoot = getRoot(followTarget)
	local targetHum = getHumanoid(followTarget)

	if not targetRoot or not targetHum or targetHum.Health <= 0 then
		releaseCameraLock()
		return
	end

	local targetPosition = targetRoot.Position + Vector3.new(0,2,0)
	local current = camera.CFrame
	local desired = CFrame.lookAt(current.Position, targetPosition)
	camera.CFrame = current:Lerp(desired, SETTINGS.CameraSmoothness)
end)

--==================================================
-- Damage detection
--==================================================

local healthConnection

local function hookDamage()
	if healthConnection then
		healthConnection:Disconnect()
	end

	if not humanoid then return end
	lastHealth = humanoid.Health

	healthConnection = humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth and SETTINGS.Enabled and SETTINGS.AutoDodge then
			task.defer(dodge)
		end
		lastHealth = newHealth
	end)
end

hookDamage()

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	refreshCharacter()
	hookDamage()
end)
