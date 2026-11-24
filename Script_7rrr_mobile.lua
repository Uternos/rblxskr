-- Player Hub Ultra (Fixed NoClip, Smooth Turn & Drift, 100+ Features)
-- Creators: Uternosking & Claude
-- Mobile: автоопределение телефона/планшета (тач-интерфейс, кнопки на экране)
--
-- ОДИН ФАЙЛ, ДВА МЕСТА (только если это ВАШ плейс и вы хотите кнопку «Привести выбранного»):
--   * как LocalScript (StarterPlayerScripts / экзекьютор) — запускается меню;
--   * как Script в ServerScriptService — запускается серверная часть ниже.

do
	local RunServiceCheck = game:GetService("RunService")
	if RunServiceCheck:IsServer() then
		local PlayersS = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local ADMINS = {}
		local ONLY_FRIENDS = false
		local BRING_DISTANCE = 4

		local remote = ReplicatedStorage:FindFirstChild("HubBringRemote")
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = "HubBringRemote"
			remote.Parent = ReplicatedStorage
		end

		local function isAdmin(plr)
			if RunServiceCheck:IsStudio() or ADMINS[plr.UserId] then
				return true
			end
			if game.CreatorType == Enum.CreatorType.User then
				return plr.UserId == game.CreatorId
			end
			if game.CreatorType == Enum.CreatorType.Group then
				local ok, rank = pcall(function()
					return plr:GetRankInGroup(game.CreatorId)
				end)
				return ok and rank == 255
			end
			return false
		end

		remote.OnServerEvent:Connect(function(admin, targetUserId)
			if typeof(targetUserId) ~= "number" or not isAdmin(admin) then
				return
			end
			local target = PlayersS:GetPlayerByUserId(targetUserId)
			if not target or target == admin then
				return
			end
			local aChar, tChar = admin.Character, target.Character
			local aRoot = aChar and aChar:FindFirstChild("HumanoidRootPart")
			if not aRoot or not tChar then
				return
			end

			if ONLY_FRIENDS then
				local ok, isFriend = pcall(function()
					return admin:IsFriendsWith(target.UserId)
				end)
				if not (ok and isFriend) then
					return
				end
			end

			local dir = aRoot.CFrame.LookVector
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { aChar, tChar }
			local hit = workspace:Raycast(aRoot.Position, dir * BRING_DISTANCE, params)
			local pos = hit and (hit.Position - dir * 1.5) or (aRoot.Position + dir * BRING_DISTANCE)
			tChar:PivotTo(CFrame.lookAt(pos, aRoot.Position))
		end)
		return
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

if getgenv and getgenv().CustomHubCleanup then
	pcall(getgenv().CustomHubCleanup)
end
if getgenv then
	getgenv().CustomHubLoaded = true
end

local State = {
	IsOpen = true,
	IsAnimating = false,

	-- Визуалы / ESP
	ESP = false,
	ESPBox = false,
	ESPHP = false,
	ESPTracers = false,
	ESPDistance = true,
	ESPName = true,
	ESPChams = false,
	RainbowESP = false,
	XRay = false,
	Crosshair = false,
	HUD = false,
	HideName = false,
	TeamCheck = false,
	HighlightSelf = false,
	ShowLookDir = false,
	RadarHUD = false,
	KeystrokesHUD = false,
	WatermarkHUD = true,
	FPSCounterHUD = false,
	PingCounterHUD = false,

	-- Хитбоксы
	HitboxExpand = false,
	HitboxScale = 1.5,
	HitboxHeadsOnly = false,
	HitboxVisible = true,

	-- Графика и освещение
	FPSBoost = false,
	RenderDistance = 1000,
	Fullbright = false,
	NoFog = false,
	NightVision = false,
	TimeLock = "OFF",
	NoParticles = false,
	NoShadows = false,
	LowTextures = false,
	NoPostFX = false,
	ClearDecals = false,
	WarmTint = false,
	CoolTint = false,
	HighContrast = false,
	MuteSounds = false,
	NoAmbientSound = false,
	DayCycleLock = false,
	BrightMap = false,

	-- Движение
	NoClip = false,
	MultiJump = false,
	MaxAirJumps = 999,
	AirJumpsUsed = 0,
	Fly = false,
	FlySpeed = 65,
	Glide = false,
	AutoSprint = false,
	AutoJump = false,
	AirWalk = false,
	LowGravity = false,
	BlinkDist = 18,
	NoFall = false,
	PhaseStep = false,
	JetPack = false,
	WallSlide = false,
	BunnyHopAssist = false,
	StepAssist = false,
	LongJumpBoost = false,
	IceSkate = false,

	-- Bhop / Мувмент / Занос / Плавный поворот
	Bhop = false,
	AutoStrafe = false,
	QuickStop = false,
	Speedometer = false,
	DriftEnabled = true,
	SmoothTurn = true,
	TurnSmoothness = 11,
	MaxTurnRate = 8.5,
	BhopMax = 70,
	AirAccel = 12,
	AirCapMul = 1.5,
	DriftFriction = 1.35,
	DriftSteerPower = 6.8,
	StrafeSyncHUD = false,
	VelGraphHUD = false,

	-- Персонаж
	GodMode = false,
	AntiRagdoll = false,
	Spinbot = false,
	SpinSpeed = 20,
	Frozen = false,
	NoAnim = false,
	RespawnDeath = false,
	Sit = false,
	AutoHealClient = false,
	AntiVoid = true,
	SwimAssist = false,
	NoClimb = false,
	AutoRespawn = false,
	FreezeAnim = false,
	SmallScaleHint = false,
	NoSeat = false,
	AntiFling = true,
	KeepVelocityOnRespawn = false,

	-- Телепорт и точки
	ClickTP = false,
	SavedPoint = nil,
	SavedPoint2 = nil,
	SavedPoint3 = nil,
	LastDeathCF = nil,
	LastSafeCFrame = nil,
	AutoSaveSafe = true,
	TPBehindTarget = true,
	TPOffsetStuds = 3,
	FollowPlayer = false,
	OrbitPlayer = false,
	OrbitRadius = 8,
	OrbitSpeed = 2.5,
	TpToNearest = false,
	ReturnToPrev = false,
	PrevPosCF = nil,
	SafeZoneTP = false,
	MidAirTP = false,

	-- Предметы
	AutoClick = false,
	ClickDelete = false,
	AutoEquipNearest = false,
	AutoDropTool = false,
	ToolReachBoost = false,
	HighlightTools = false,
	AutoCollectDrops = false,
	InfiniteAmmoHint = false,
	QuickReloadHint = false,
	ToolSpin = false,
	NoToolAnim = false,
	SortBackpackInfo = false,

	-- Камера
	ZoomUnlock = false,
	CamWalls = false,
	SpectateTarget = nil,
	FOV = 70,
	FirstPersonLock = false,
	CameraShakeReduce = false,
	FreelookOffset = false,
	CameraSmooth = false,
	HighCam = false,
	FrontCam = false,

	-- Сервер и утилиты
	AntiAFK = false,
	AutoRejoin = false,
	Speed = 16,
	JumpPower = 50,
	AutoSkipCutscene = false,
	HideChatUI = false,
	HidePlayerListUI = false,
	CompactMode = false,
	SoundNotify = true,
	LogPlayers = false,
	AutoDeclinePrompts = false,
	PerformanceMode = false,

	Destroyed = false,
}

-- Мобильный режим включается сам, если нет клавиатуры.
-- Принудительно: getgenv().HubForceMobile = true / false (до запуска скрипта).
State.Mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if getgenv and getgenv().HubForceMobile ~= nil then
	State.Mobile = getgenv().HubForceMobile and true or false
end
State.MobUp = false
State.MobDown = false
State.MobJump = false
State.MobAirWalk = false
State.LastAirJump = 0

local SavedMouseBeforeOpen = {
	Behavior = Enum.MouseBehavior.Default,
	IconEnabled = true,
	Captured = false,
}

local function captureMouseBeforeOpen()
	pcall(function()
		local b = UserInputService.MouseBehavior
		if b == Enum.MouseBehavior.LockCurrentPosition then
			b = Enum.MouseBehavior.Default
		end
		SavedMouseBeforeOpen.Behavior = b
		SavedMouseBeforeOpen.IconEnabled = UserInputService.MouseIconEnabled
		SavedMouseBeforeOpen.Captured = true
	end)
end

local function applyMouseForMenu()
	if State.Destroyed then
		pcall(function()
			UserInputService.MouseBehavior = SavedMouseBeforeOpen.Behavior
			UserInputService.MouseIconEnabled = SavedMouseBeforeOpen.IconEnabled
		end)
		return
	end

	pcall(function()
		if State.IsOpen then
			if not SavedMouseBeforeOpen.Captured then
				captureMouseBeforeOpen()
			end
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			UserInputService.MouseBehavior = SavedMouseBeforeOpen.Behavior
			UserInputService.MouseIconEnabled = SavedMouseBeforeOpen.IconEnabled
			SavedMouseBeforeOpen.Captured = false
		end
	end)
end

captureMouseBeforeOpen()

local Connections = {}
local ESPObjects = {}
local SavedMapTransparency = {}
local SavedAtmospheres = {}
local SavedHitboxData = {}
local SavedShaders = {}
local SavedPartMaterials = {}
local SavedNoClipParts = {} -- [BasePart] = bool (исходное CanCollide)
local SavedParticles = {}
local DeletedParts = {}
local SavedCoreGuis = {}

local OriginalLighting = {
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness,
	GlobalShadows = Lighting.GlobalShadows,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	ClockTime = Lighting.ClockTime,
}
local OriginalGravity = workspace.Gravity
local OriginalCamMaxZoom = LocalPlayer.CameraMaxZoomDistance

local FlyBodyGyro = nil
local FlyBodyVelocity = nil
local AirWalkPart = nil
local NightVisionCC = nil
local TintCC = nil
local ToolHighlight = nil

local MainFrame = nil
local StatusLabel = nil
local toggleSetters = {}
local selectedPlayer = nil
local draggingSlider = false
local updateHitboxSliderUI = nil
local lastAutoClick = 0
local lastSitState = false
local hudAccum, hudFrames = 0, 0
local orbitAngle = 0
local smoothYaw = nil

local function addConn(conn)
	table.insert(Connections, conn)
	return conn
end

local function setStatus(msg, isError)
	if not StatusLabel then return end
	StatusLabel.Text = "● Статус: " .. tostring(msg)
	StatusLabel.TextColor3 = isError and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(120, 235, 175)
end

local function getChar()
	local char = LocalPlayer.Character
	return char, char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

-- ================= ИСПРАВЛЕННЫЙ NOCLIP =================
-- Раньше в баннихопе NoClip «залипал»: при включении запоминалось CanCollide
-- в момент прыжка (Humanoid в воздухе сам ставит false у корпуса), и при
-- выключении возвращалось устаревшее false. Теперь основные части
-- (корпус/голова/HRP) всегда возвращаются в true, а дальше ими снова
-- управляет Humanoid. Принудительное отключение коллизий идёт в Stepped
-- (до физики), поэтому Humanoid не успевает его перебить.
local function restoreNoClipParts()
	local core = {
		HumanoidRootPart = true,
		Head = true,
		Torso = true,
		UpperTorso = true,
		LowerTorso = true,
	}
	for part, origCollide in pairs(SavedNoClipParts) do
		if part and part.Parent then
			pcall(function()
				if core[part.Name] then
					part.CanCollide = true
				else
					part.CanCollide = origCollide
				end
			end)
		end
	end
	table.clear(SavedNoClipParts)
end

local function syncNoClipCharacter()
	if not State.NoClip then
		if next(SavedNoClipParts) ~= nil then
			restoreNoClipParts()
		end
		return
	end
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if SavedNoClipParts[part] == nil then
				SavedNoClipParts[part] = part.CanCollide
			end
			if part.CanCollide then
				part.CanCollide = false
			end
		end
	end
end

local function setNoClipState(enabled)
	State.NoClip = enabled and true or false
	if State.NoClip then
		syncNoClipCharacter()
	else
		restoreNoClipParts()
		-- страховка: сразу вернуть коллизию корпуса, не дожидаясь Humanoid
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			pcall(function() root.CanCollide = true end)
		end
	end
end

addConn(RunService.Stepped:Connect(function()
	if State.Destroyed then return end
	pcall(syncNoClipCharacter)
end))

-- GodMode: держим HP на максимуме до физики (Stepped) и после неё (Heartbeat)
do
	local function holdGodHealth()
		if State.Destroyed or not State.GodMode then return end
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
			hum.Health = hum.MaxHealth
		end
	end
	addConn(RunService.Stepped:Connect(holdGodHealth))
	addConn(RunService.Heartbeat:Connect(holdGodHealth))
end

local function findPlayer(query)
	if not query or query == "" then return nil end
	query = string.lower(query)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local nameMatch = string.find(string.lower(plr.Name), query, 1, true)
			local dispMatch = string.find(string.lower(plr.DisplayName), query, 1, true)
			if nameMatch or dispMatch then
				return plr
			end
		end
	end
	return nil
end

local function findNearestPlayer()
	local _, _, myRoot = getChar()
	if not myRoot then return nil end
	local bestPlr, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local r = plr.Character:FindFirstChild("HumanoidRootPart")
			local h = plr.Character:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = (r.Position - myRoot.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPlr = plr
				end
			end
		end
	end
	return bestPlr
end

local function teleportToPlayer(query)
	local target = typeof(query) == "Instance" and query or findPlayer(query)
	local _, _, myRoot = getChar()

	if not target or not target.Character then
		return false, "Игрок не найден"
	end

	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not myRoot then
		return false, "Нет персонажа или RootPart"
	end

	State.PrevPosCF = myRoot.CFrame
	myRoot.AssemblyLinearVelocity = Vector3.zero
	local offset = State.TPBehindTarget and CFrame.new(0, 0, State.TPOffsetStuds) or CFrame.new(0, 3, 0)
	myRoot.CFrame = targetRoot.CFrame * offset
	return true, "Телепорт к " .. target.DisplayName .. " (@" .. target.Name .. ")"
end

-- ================= FPS BOOST =================
local function isShaderEffect(obj)
	if not obj:IsA("PostEffect") then return false end
	if obj == NightVisionCC or obj == TintCC then return false end
	return true
end

local function applyFPSBoost(enabled)
	State.FPSBoost = enabled
	if enabled then
		pcall(function()
			Lighting.GlobalShadows = false
			if not State.NoFog then
				Lighting.FogStart = math.max(State.RenderDistance * 0.65, 50)
				Lighting.FogEnd = State.RenderDistance
			end
		end)

		for _, container in ipairs({ Lighting, Camera }) do
			for _, obj in ipairs(container:GetDescendants()) do
				if isShaderEffect(obj) then
					if SavedShaders[obj] == nil then
						SavedShaders[obj] = { Enabled = obj.Enabled }
					end
					pcall(function() obj.Enabled = false end)
				end
			end
		end

		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj ~= AirWalkPart then
				local isPlrPart = false
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character and obj:IsDescendantOf(plr.Character) then
						isPlrPart = true
						break
					end
				end
				if not isPlrPart then
					if SavedPartMaterials[obj] == nil then
						SavedPartMaterials[obj] = obj.Material
					end
					pcall(function()
						obj.Material = Enum.Material.SmoothPlastic
						obj.CastShadow = false
					end)
				end
			end
		end
	else
		for shaderObj, info in pairs(SavedShaders) do
			if shaderObj and shaderObj.Parent then
				pcall(function() shaderObj.Enabled = info.Enabled end)
			end
		end
		table.clear(SavedShaders)

		for part, origMat in pairs(SavedPartMaterials) do
			if part and part.Parent then
				pcall(function()
					part.Material = origMat
					part.CastShadow = true
				end)
			end
		end
		table.clear(SavedPartMaterials)

		pcall(function()
			if not State.Fullbright then
				Lighting.GlobalShadows = OriginalLighting.GlobalShadows
			end
			if not State.NoFog then
				Lighting.FogStart = OriginalLighting.FogStart
				Lighting.FogEnd = OriginalLighting.FogEnd
			end
		end)
	end
end

-- ================= ХИТБОКСЫ =================
local function restorePlayerHitbox(plr)
	local charMap = SavedHitboxData[plr]
	if not charMap then return end

	for part, info in pairs(charMap) do
		if part and part.Parent then
			pcall(function()
				part.Size = info.Size
				part.Transparency = info.Transparency
				part.CanCollide = info.CanCollide
			end)
		end
	end
	SavedHitboxData[plr] = nil
end

local function resetAllHitboxes()
	State.HitboxExpand = false
	State.HitboxScale = 1.5
	for plr in pairs(SavedHitboxData) do
		restorePlayerHitbox(plr)
	end
	if toggleSetters.hitbox then
		toggleSetters.hitbox(false)
	end
	if updateHitboxSliderUI then
		updateHitboxSliderUI(State.HitboxScale)
	end
end

local function updateHitboxExpand()
	if not State.HitboxExpand then
		for plr in pairs(SavedHitboxData) do
			restorePlayerHitbox(plr)
		end
		return
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local char = plr.Character
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			local head = char:FindFirstChild("Head")

			if hum and hum.Health > 0 and root then
				if not SavedHitboxData[plr] then
					SavedHitboxData[plr] = {}
				end

				local targets = {}
				if head and head:IsA("BasePart") then
					table.insert(targets, head)
				end
				if not State.HitboxHeadsOnly then
					table.insert(targets, root)
				end

				for _, part in ipairs(targets) do
					if part:IsA("BasePart") then
						if not SavedHitboxData[plr][part] then
							SavedHitboxData[plr][part] = {
								Size = part.Size,
								Transparency = part.Transparency,
								CanCollide = part.CanCollide,
							}
						end
						local baseSize = SavedHitboxData[plr][part].Size
						pcall(function()
							part.Size = baseSize * State.HitboxScale
							part.Transparency = State.HitboxVisible and 0.72 or 1
							part.CanCollide = false
						end)
					end
				end
			end
		end
	end
end

-- ================= ESP =================
local function clearPlayerESP(plr)
	local data = ESPObjects[plr]
	if not data then return end
	if data.Highlight then data.Highlight:Destroy() end
	if data.Box then data.Box:Destroy() end
	if data.Billboard then data.Billboard:Destroy() end
	ESPObjects[plr] = nil
end

local function createPlayerESP(plr)
	if plr == LocalPlayer or State.Destroyed then return end
	clearPlayerESP(plr)

	local highlight = Instance.new("Highlight")
	highlight.Name = "HubESP_Highlight"
	highlight.FillColor = Color3.fromRGB(255, 75, 95)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false

	local box = Instance.new("BoxHandleAdornment")
	box.Name = "HubESP_Hitbox"
	box.Color3 = Color3.fromRGB(255, 200, 60)
	box.Transparency = 0.72
	box.ZIndex = 5
	box.AlwaysOnTop = true
	box.Visible = false

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HubESP_Info"
	billboard.Size = UDim2.new(0, 146, 0, 46)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.Visible = false
	nameLabel.Parent = billboard

	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -12, 0, 7)
	hpBg.Position = UDim2.new(0, 6, 0, 18)
	hpBg.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
	hpBg.BorderSizePixel = 0
	hpBg.Visible = false
	hpBg.Parent = billboard
	Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(60, 225, 110)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0, 15)
	distLabel.Position = UDim2.new(0, 0, 0, 28)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.fromRGB(205, 225, 255)
	distLabel.TextStrokeTransparency = 0.2
	distLabel.Font = Enum.Font.GothamMedium
	distLabel.TextSize = 11
	distLabel.Text = "0 studs"
	distLabel.Visible = false
	distLabel.Parent = billboard

	ESPObjects[plr] = {
		Highlight = highlight,
		Box = box,
		Billboard = billboard,
		HPBg = hpBg,
		Fill = hpFill,
		NameLabel = nameLabel,
		DistLabel = distLabel,
	}
end

local function updateESP()
	local _, _, myRoot = getChar()
	local rainbowColor = Color3.fromHSV((os.clock() * 0.25) % 1, 0.8, 1)

	for plr, data in pairs(ESPObjects) do
		local char = plr.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local sameTeam = State.TeamCheck and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team
		local alive = char and humanoid and root and humanoid.Health > 0 and not sameTeam

		if alive and (State.ESP or State.ESPBox or State.ESPHP) then
			local col = State.RainbowESP and rainbowColor or (plr.TeamColor and plr.TeamColor.Color or Color3.fromRGB(255, 75, 95))
			if State.ESP then
				if data.Highlight.Parent ~= char then
					data.Highlight.Parent = char
				end
				data.Highlight.FillColor = col
				data.Highlight.FillTransparency = State.ESPChams and 0.35 or 0.65
				data.Highlight.Enabled = true
				data.NameLabel.Text = plr.DisplayName
				data.NameLabel.Visible = State.ESPName
				if myRoot and State.ESPDistance then
					local dist = math.floor((myRoot.Position - root.Position).Magnitude)
					data.DistLabel.Text = string.format("%d studs", dist)
					data.DistLabel.Visible = true
				else
					data.DistLabel.Visible = false
				end
			else
				data.Highlight.Enabled = false
				data.NameLabel.Visible = false
				data.DistLabel.Visible = false
			end

			if State.ESPBox then
				if data.Box.Parent ~= root then
					data.Box.Parent = root
					data.Box.Adornee = root
				end
				local okBox, boxCF, boxSize = pcall(function()
					return char:GetBoundingBox()
				end)
				if okBox and boxCF and boxSize then
					data.Box.Size = boxSize
					data.Box.CFrame = root.CFrame:ToObjectSpace(boxCF)
					data.Box.Color3 = State.RainbowESP and rainbowColor or Color3.fromRGB(255, 200, 60)
					data.Box.Visible = true
				end
			else
				data.Box.Visible = false
			end

			if State.ESPHP then
				local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
				data.Fill.Size = UDim2.new(hpRatio, 0, 1, 0)
				data.Fill.BackgroundColor3 = Color3.fromRGB(
					math.floor(255 * (1 - hpRatio)),
					math.floor(225 * hpRatio),
					65
				)
				data.HPBg.Visible = true
			else
				data.HPBg.Visible = false
			end

			if data.Billboard.Parent ~= root then
				data.Billboard.Parent = root
			end
			data.Billboard.Enabled = (State.ESP or State.ESPHP)
		else
			data.Highlight.Enabled = false
			data.Box.Visible = false
			data.Billboard.Enabled = false
			data.NameLabel.Visible = false
			data.HPBg.Visible = false
			data.DistLabel.Visible = false
		end
	end
end

-- ================= ОКРУЖЕНИЕ И ТОН =================
local function applyTintPreset()
	if not State.WarmTint and not State.CoolTint then
		if TintCC then
			TintCC:Destroy()
			TintCC = nil
		end
		return
	end
	if not TintCC then
		TintCC = Instance.new("ColorCorrectionEffect")
		TintCC.Name = "HubTintCC"
		TintCC.Parent = Lighting
	end
	TintCC.Enabled = true
	if State.WarmTint then
		TintCC.TintColor = Color3.fromRGB(255, 224, 190)
		TintCC.Saturation = 0.15
	elseif State.CoolTint then
		TintCC.TintColor = Color3.fromRGB(190, 222, 255)
		TintCC.Saturation = 0.1
	end
end

local function applyFullbright(enabled)
	State.Fullbright = enabled
	if enabled then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 2.5
		Lighting.GlobalShadows = false
	else
		Lighting.Ambient = OriginalLighting.Ambient
		Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.GlobalShadows = State.FPSBoost and false or OriginalLighting.GlobalShadows
	end
end

local function applyNoFog(enabled)
	State.NoFog = enabled
	if enabled then
		Lighting.FogEnd = 100000
		Lighting.FogStart = 100000
		for _, child in ipairs(Lighting:GetChildren()) do
			if child:IsA("Atmosphere") then
				SavedAtmospheres[child] = child.Density
				child.Density = 0
			end
		end
	else
		if State.FPSBoost then
			Lighting.FogStart = math.max(State.RenderDistance * 0.65, 50)
			Lighting.FogEnd = State.RenderDistance
		else
			Lighting.FogEnd = OriginalLighting.FogEnd
			Lighting.FogStart = OriginalLighting.FogStart
		end
		for atm, density in pairs(SavedAtmospheres) do
			if atm and atm.Parent then
				atm.Density = density
			end
		end
		table.clear(SavedAtmospheres)
	end
end

local function applyNightVision(enabled)
	State.NightVision = enabled
	if enabled then
		if not NightVisionCC then
			NightVisionCC = Instance.new("ColorCorrectionEffect")
			NightVisionCC.Name = "HubNightVision"
			NightVisionCC.TintColor = Color3.fromRGB(130, 255, 165)
			NightVisionCC.Contrast = 0.25
			NightVisionCC.Brightness = 0.12
			NightVisionCC.Parent = Lighting
		end
		NightVisionCC.Enabled = true
	elseif NightVisionCC then
		NightVisionCC:Destroy()
		NightVisionCC = nil
	end
end

local function updateTimeLock()
	if State.TimeLock == "DAY" then
		Lighting.ClockTime = 14
	elseif State.TimeLock == "NIGHT" then
		Lighting.ClockTime = 0
	end
end

-- ================= X-RAY =================
local function isCharacterPart(part)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and part:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function applyXRay(enabled)
	State.XRay = enabled
	if enabled then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and not isCharacterPart(obj) and obj ~= AirWalkPart then
				if SavedMapTransparency[obj] == nil then
					SavedMapTransparency[obj] = obj.LocalTransparencyModifier
				end
				obj.LocalTransparencyModifier = 0.65
			end
		end
	else
		for part, _ in pairs(SavedMapTransparency) do
			if part and part.Parent then
				part.LocalTransparencyModifier = 0
			end
		end
		table.clear(SavedMapTransparency)
	end
end

-- ================= FLY + GLIDE + AIRWALK =================
local function stopFly()
	if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
	if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
end

local function startFly()
	stopFly()
	local _, _, root = getChar()
	local _, hum = getChar()
	if not root or not hum then return end

	hum.PlatformStand = true

	FlyBodyGyro = Instance.new("BodyGyro")
	FlyBodyGyro.P = 9e4
	FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	FlyBodyGyro.CFrame = root.CFrame
	FlyBodyGyro.Parent = root

	FlyBodyVelocity = Instance.new("BodyVelocity")
	FlyBodyVelocity.Velocity = Vector3.zero
	FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	FlyBodyVelocity.Parent = root
end

local function setFlyState(enabled)
	State.Fly = enabled
	if enabled then
		startFly()
	else
		stopFly()
		local _, hum = getChar()
		if hum then
			hum.PlatformStand = false
		end
	end
end

local function updateFly()
	if not State.Fly then return end
	local _, _, root = getChar()
	if not root then return end

	if not FlyBodyGyro or not FlyBodyVelocity or FlyBodyGyro.Parent ~= root then
		startFly()
	end
	if not FlyBodyGyro or not FlyBodyVelocity then return end

	local camCF = Camera.CFrame
	local moveDir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

	if State.Mobile then
		-- Телефон: виртуальный джойстик + кнопки ▲ / ▼ на экране
		local _, hum2 = getChar()
		local md = hum2 and hum2.MoveDirection or Vector3.zero
		if md.Magnitude > 0.05 then
			local lf = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
			local rt = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
			if lf.Magnitude > 0.001 and rt.Magnitude > 0.001 then
				moveDir += camCF.LookVector * md:Dot(lf.Unit) + camCF.RightVector * md:Dot(rt.Unit)
			end
		end
		if State.MobUp then moveDir += Vector3.new(0, 1, 0) end
		if State.MobDown then moveDir -= Vector3.new(0, 1, 0) end
	end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
	end

	FlyBodyGyro.CFrame = camCF
	FlyBodyVelocity.Velocity = moveDir * State.FlySpeed
end

local function updateGlide()
	if not State.Glide or State.Fly then return end
	local _, hum, root = getChar()
	if hum and root and hum.FloorMaterial == Enum.Material.Air and root.AssemblyLinearVelocity.Y < -6 then
		root.AssemblyLinearVelocity = Vector3.new(
			root.AssemblyLinearVelocity.X,
			-6,
			root.AssemblyLinearVelocity.Z
		)
	end
end

local function updateAirWalk()
	local _, _, root = getChar()
	local active = State.AirWalk and root and (UserInputService:IsKeyDown(Enum.KeyCode.V) or State.MobAirWalk)

	if active then
		if not AirWalkPart then
			AirWalkPart = Instance.new("Part")
			AirWalkPart.Name = "HubAirWalkPlatform"
			AirWalkPart.Size = Vector3.new(8, 1, 8)
			AirWalkPart.Anchored = true
			AirWalkPart.Transparency = 0.72
			AirWalkPart.Material = Enum.Material.Neon
			AirWalkPart.Color = Color3.fromRGB(95, 190, 255)
			AirWalkPart.Parent = workspace
		end
		AirWalkPart.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z)
	elseif AirWalkPart then
		AirWalkPart:Destroy()
		AirWalkPart = nil
	end
end

-- ================= ХАРАКТЕРИСТИКИ, GODMODE, SPINBOT, КАМЕРА, NOCLIP =================
local function updateCharacterMods(dt)
	local char, humanoid, root = getChar()
	if not char then return end

	syncNoClipCharacter()

	if humanoid then
		local desiredSpeed = State.AutoSprint and math.max(State.Speed, 28) or State.Speed
		if desiredSpeed ~= 16 then
			humanoid.WalkSpeed = desiredSpeed
		end
		if State.JumpPower ~= 50 then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = State.JumpPower
		end

		if State.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid.Jump = true
		end

		if State.AntiRagdoll then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end

		if State.NoClimb then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		end

		if State.NoSeat then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		end

		if State.AutoHealClient and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 15 * (dt or 0.016))
		end

		local floorMat = humanoid.FloorMaterial
		if floorMat and floorMat ~= Enum.Material.Air then
			State.AirJumpsUsed = 0
			if State.AutoSaveSafe and root and root.Position.Y > -200 then
				State.LastSafeCFrame = root.CFrame
			end
		end

		if State.GodMode then
			-- HP всегда держится на максимуме (а не на 0.0001)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end

		if State.AntiVoid and root and root.Position.Y < workspace.FallenPartsDestroyHeight + 25 then
			local fallback = State.SavedPoint or State.LastSafeCFrame
			if fallback then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = fallback * CFrame.new(0, 3, 0)
			end
		end
	end

	if root then
		root.Anchored = State.Frozen
		if State.AntiFling and root.AssemblyAngularVelocity.Magnitude > 35 then
			root.AssemblyAngularVelocity = Vector3.zero
		end
		if State.Spinbot and not State.Frozen and not State.Fly then
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0)
		end
		if State.FollowPlayer and selectedPlayer and selectedPlayer.Character then
			local tRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
			if tRoot and (tRoot.Position - root.Position).Magnitude > State.TPOffsetStuds + 1 then
				root.CFrame = tRoot.CFrame * CFrame.new(0, 0, State.TPOffsetStuds)
			end
		elseif State.OrbitPlayer and selectedPlayer and selectedPlayer.Character then
			local tRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
			if tRoot then
				orbitAngle += State.OrbitSpeed * (dt or 0.016)
				local ox = math.cos(orbitAngle) * State.OrbitRadius
				local oz = math.sin(orbitAngle) * State.OrbitRadius
				local targetPos = tRoot.Position + Vector3.new(ox, 0, oz)
				root.CFrame = CFrame.lookAt(targetPos, tRoot.Position)
			end
		end
	end

	if State.FPSBoost and not State.NoFog then
		Lighting.FogStart = math.max(State.RenderDistance * 0.65, 50)
		Lighting.FogEnd = State.RenderDistance
	end

	if State.FOV ~= 70 then
		Camera.FieldOfView = State.FOV
	end
	if State.ZoomUnlock then
		LocalPlayer.CameraMaxZoomDistance = 5000
	elseif LocalPlayer.CameraMaxZoomDistance == 5000 then
		LocalPlayer.CameraMaxZoomDistance = OriginalCamMaxZoom
	end
	if State.LowGravity then
		workspace.Gravity = OriginalGravity * 0.4
	elseif workspace.Gravity == OriginalGravity * 0.4 then
		workspace.Gravity = OriginalGravity
	end

	if State.SpectateTarget and State.SpectateTarget.Character then
		local targetHum = State.SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
		if targetHum then
			Camera.CameraSubject = targetHum
		end
	elseif humanoid and Camera.CameraSubject ~= humanoid then
		Camera.CameraSubject = humanoid
	end
end

-- ================= GUI & ТЕМА =================
local function getGuiParent()
	local okCore, core = pcall(function()
		return CoreGui
	end)
	if okCore and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerToolHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

local WIN_W = State.Mobile and math.clamp(Camera.ViewportSize.X - 16, 300, 1000)
	or math.clamp(Camera.ViewportSize.X - 20, 740, 1600)
local WIN_H = State.Mobile and math.clamp(Camera.ViewportSize.Y - GuiService:GetGuiInset().Y - 12, 220, 760)
	or math.clamp(Camera.ViewportSize.Y - 20, 560, 760)
local OPEN_SIZE = UDim2.new(0, WIN_W, 0, WIN_H)
local OPEN_POS = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
local CLOSED_SIZE = UDim2.new(0, WIN_W, 0, 0)
local CLOSED_POS = UDim2.new(0.5, -WIN_W / 2, 0.5, 0)

local Theme = {
	Bg = Color3.fromRGB(10, 11, 17),
	Panel = Color3.fromRGB(15, 17, 26),
	Card = Color3.fromRGB(23, 26, 39),
	CardHover = Color3.fromRGB(34, 38, 58),
	Line = Color3.fromRGB(46, 51, 76),
	Text = Color3.fromRGB(236, 240, 252),
	Dim = Color3.fromRGB(128, 137, 168),
	Accent = Color3.fromRGB(124, 92, 255),
	Accent2 = Color3.fromRGB(0, 212, 255),
	On = Color3.fromRGB(46, 230, 160),
}

local function tw(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function round(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function newStroke(parent, color, thickness, transparency)
	local st = Instance.new("UIStroke")
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Color = color
	st.Thickness = thickness or 1
	st.Transparency = transparency or 0
	st.Parent = parent
	return st
end

local function newGradient(parent, rotation, c1, c2)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1 or Theme.Accent),
		ColorSequenceKeypoint.new(1, c2 or Theme.Accent2),
	})
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local function addHover(btn, normal, over)
	btn.MouseEnter:Connect(function()
		tw(btn, 0.12, { BackgroundColor3 = over })
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, 0.12, { BackgroundColor3 = normal })
	end)
end

local function styleBox(box)
	box.BackgroundColor3 = Theme.Card
	box.TextColor3 = Theme.Text
	box.PlaceholderColor3 = Theme.Dim
	local st = newStroke(box, Theme.Line, 1, 0.3)
	box.Focused:Connect(function()
		tw(st, 0.15, { Color = Theme.Accent2, Transparency = 0 })
	end)
	box.FocusLost:Connect(function()
		tw(st, 0.15, { Color = Theme.Line, Transparency = 0.3 })
	end)
end

MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = OPEN_SIZE
MainFrame.Position = OPEN_POS
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 19, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 13, 21)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 14, 24)),
})
mainGrad.Rotation = 135
mainGrad.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0
mainStroke.Parent = MainFrame

local mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(0.5, Theme.Accent2),
	ColorSequenceKeypoint.new(1, Theme.Accent),
})
mainStrokeGrad.Parent = mainStroke

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(15, 16, 27)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
round(Header, 12)

local HeaderFill = Instance.new("Frame")
HeaderFill.Size = UDim2.new(1, 0, 0, 14)
HeaderFill.Position = UDim2.new(0, 0, 1, -14)
HeaderFill.BackgroundColor3 = Color3.fromRGB(15, 16, 27)
HeaderFill.BorderSizePixel = 0
HeaderFill.Parent = Header

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 2)
HeaderLine.Position = UDim2.new(0, 0, 1, -2)
HeaderLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderLine.BorderSizePixel = 0
HeaderLine.ZIndex = 2
HeaderLine.Parent = Header
local HeaderLineGrad = Instance.new("UIGradient")
HeaderLineGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(0.5, Theme.Accent2),
	ColorSequenceKeypoint.new(1, Theme.Accent),
})
HeaderLineGrad.Parent = HeaderLine

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 420, 0, 24)
TitleLabel.Position = UDim2.new(0, 16, 0, 4)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✦ PLAYER HUB ULTRA  •  100+ MODS"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 16
TitleLabel.Parent = Header
newGradient(TitleLabel, 0)

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0, 560, 0, 14)
SubLabel.Position = UDim2.new(0, 17, 0, 26)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "[K] скрыть / открыть   •   [✕] выгрузить   •   Smooth Turn & Drift включены"
SubLabel.TextColor3 = Theme.Dim
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Font = Enum.Font.GothamMedium
SubLabel.TextSize = 10
SubLabel.Parent = Header

local HideBtn = Instance.new("TextButton")
HideBtn.Name = "HideButton"
HideBtn.Size = UDim2.new(0, 104, 0, 28)
HideBtn.Position = UDim2.new(1, -158, 0, 8)
HideBtn.BackgroundColor3 = Color3.fromRGB(34, 30, 66)
HideBtn.AutoButtonColor = false
HideBtn.Text = "🙈  Скрыть [K]"
HideBtn.TextColor3 = Theme.Text
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 11
HideBtn.Parent = Header
round(HideBtn, 8)
newStroke(HideBtn, Theme.Accent, 1, 0.45)
addHover(HideBtn, Color3.fromRGB(34, 30, 66), Color3.fromRGB(70, 56, 140))

local ShowPill = Instance.new("TextButton")
ShowPill.Name = "ShowPill"
ShowPill.AnchorPoint = Vector2.new(0.5, 0)
ShowPill.Size = UDim2.new(0, 46, 0, 20)
ShowPill.Position = UDim2.new(0.5, 0, 0, 4)
ShowPill.BackgroundColor3 = Theme.Card
ShowPill.BackgroundTransparency = 0.45
ShowPill.AutoButtonColor = false
ShowPill.Text = "✦"
ShowPill.TextColor3 = Theme.Accent2
ShowPill.TextTransparency = 0.2
ShowPill.Font = Enum.Font.GothamBold
ShowPill.TextSize = 12
ShowPill.Visible = false
ShowPill.ZIndex = 50
ShowPill.Parent = ScreenGui
round(ShowPill, 10)
newStroke(ShowPill, Theme.Accent, 1, 0.5)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseButton"
CloseBtn.Size = UDim2.new(0, 34, 0, 28)
CloseBtn.Position = UDim2.new(1, -46, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(58, 22, 34)
CloseBtn.AutoButtonColor = false
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 135)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
round(CloseBtn, 8)
newStroke(CloseBtn, Color3.fromRGB(255, 90, 110), 1, 0.55)
CloseBtn.MouseEnter:Connect(function()
	tw(CloseBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(210, 48, 72), TextColor3 = Color3.fromRGB(255, 255, 255) })
end)
CloseBtn.MouseLeave:Connect(function()
	tw(CloseBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(58, 22, 34), TextColor3 = Color3.fromRGB(255, 120, 135) })
end)

local CmdBox = Instance.new("TextBox")
CmdBox.Name = "CommandInput"
CmdBox.Size = UDim2.new(1, -24, 0, 35)
CmdBox.Position = UDim2.new(0, 12, 0, 54)
CmdBox.BackgroundColor3 = Theme.Card
CmdBox.PlaceholderText = "Команда: tp <имя>, items, bhop, strafe, drift, smooth, bhopmax <n>, hud, hip <n>, time <n>, esp, hitbox, hp, fps, fly, god, noclip, xray, spin (Enter)"
CmdBox.PlaceholderColor3 = Theme.Dim
CmdBox.Text = ""
CmdBox.ClearTextOnFocus = false
CmdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CmdBox.TextXAlignment = Enum.TextXAlignment.Left
CmdBox.Font = Enum.Font.Code
CmdBox.TextSize = 12
CmdBox.Parent = MainFrame
Instance.new("UICorner", CmdBox).CornerRadius = UDim.new(0, 8)
styleBox(CmdBox)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = CmdBox
end

StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 20)
StatusLabel.Position = UDim2.new(0, 14, 0, 92)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● Статус: готов (NoClip фикс + плавный поворот + занос активны)"
StatusLabel.TextColor3 = Color3.fromRGB(120, 235, 175)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.Parent = MainFrame

local PlayersTitle = Instance.new("TextLabel")
PlayersTitle.Size = UDim2.new(0, 240, 0, 20)
PlayersTitle.Position = UDim2.new(0, 14, 0, 114)
PlayersTitle.BackgroundTransparency = 1
PlayersTitle.Text = "👥  ИГРОКИ"
PlayersTitle.TextColor3 = Theme.Accent2
PlayersTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayersTitle.Font = Enum.Font.GothamBold
PlayersTitle.TextSize = 11
PlayersTitle.Parent = MainFrame

-- Оставляем место внизу слева под карточку создателей (высота 54px + отступы)
local PlayersList = Instance.new("ScrollingFrame")
PlayersList.Name = "PlayersList"
PlayersList.Size = UDim2.new(0, 240, 1, -304)
PlayersList.Position = UDim2.new(0, 12, 0, 138)
PlayersList.BackgroundColor3 = Theme.Panel
PlayersList.BorderSizePixel = 0
PlayersList.ScrollBarThickness = 4
PlayersList.ScrollBarImageColor3 = Theme.Accent
PlayersList.Parent = MainFrame
Instance.new("UICorner", PlayersList).CornerRadius = UDim.new(0, 10)
newStroke(PlayersList, Theme.Line, 1, 0.35)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 5)
	pad.Parent = PlayersList
end

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = PlayersList

-- ================= КАРТОЧКА СОЗДАТЕЛЕЙ (СЛЕВА СНИЗУ, ВНЕ ФУНКЦИЙ) =================
local CreatorCard = Instance.new("Frame")
CreatorCard.Name = "CreatorCardBottomLeft"
CreatorCard.Size = UDim2.new(0, 240, 0, 54)
CreatorCard.Position = UDim2.new(0, 12, 1, -158)
CreatorCard.BackgroundColor3 = Color3.fromRGB(18, 20, 34)
CreatorCard.BorderSizePixel = 0
CreatorCard.Parent = MainFrame
round(CreatorCard, 10)
newStroke(CreatorCard, Theme.Accent, 1.2, 0.25)
local creatorGrad = Instance.new("UIGradient")
creatorGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 24, 62)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 28, 46)),
})
creatorGrad.Rotation = 35
creatorGrad.Parent = CreatorCard

local CreatorAccentBar = Instance.new("Frame")
CreatorAccentBar.Size = UDim2.new(0, 4, 1, -14)
CreatorAccentBar.Position = UDim2.new(0, 8, 0, 7)
CreatorAccentBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CreatorAccentBar.BorderSizePixel = 0
CreatorAccentBar.Parent = CreatorCard
round(CreatorAccentBar, 2)
newGradient(CreatorAccentBar, 90)

local CreatorTag = Instance.new("TextLabel")
CreatorTag.Size = UDim2.new(1, -24, 0, 15)
CreatorTag.Position = UDim2.new(0, 18, 0, 6)
CreatorTag.BackgroundTransparency = 1
CreatorTag.Text = "✦  CREATED BY"
CreatorTag.TextColor3 = Theme.Accent2
CreatorTag.TextXAlignment = Enum.TextXAlignment.Left
CreatorTag.Font = Enum.Font.GothamBlack
CreatorTag.TextSize = 10
CreatorTag.Parent = CreatorCard

local CreatorNames = Instance.new("TextLabel")
CreatorNames.Size = UDim2.new(1, -24, 0, 24)
CreatorNames.Position = UDim2.new(0, 18, 0, 22)
CreatorNames.BackgroundTransparency = 1
CreatorNames.RichText = true
CreatorNames.Text = '<font color="#B79CFF">Uternosking</font>  <font color="#8A90A8">&amp;</font>  <font color="#6FE3FF">Claude</font>'
CreatorNames.TextColor3 = Theme.Text
CreatorNames.TextXAlignment = Enum.TextXAlignment.Left
CreatorNames.TextTruncate = Enum.TextTruncate.AtEnd
CreatorNames.Font = Enum.Font.GothamBold
CreatorNames.TextSize = 12
CreatorNames.Parent = CreatorCard

local function refreshPlayerList()
	for _, child in ipairs(PlayersList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local count = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			count += 1
			local selected = (selectedPlayer == plr)
			local baseCol = selected and Color3.fromRGB(44, 36, 92) or Theme.Card

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -10, 0, 40)
			btn.BackgroundColor3 = baseCol
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.Parent = PlayersList
			round(btn, 8)
			newStroke(btn, selected and Theme.Accent or Theme.Line, 1, selected and 0.05 or 0.5)

			local avatar = Instance.new("ImageLabel")
			avatar.Size = UDim2.new(0, 28, 0, 28)
			avatar.Position = UDim2.new(0, 7, 0.5, -14)
			avatar.BackgroundColor3 = Theme.Bg
			avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", plr.UserId)
			avatar.Parent = btn
			round(avatar, 14)

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -50, 0, 16)
			nameLbl.Position = UDim2.new(0, 42, 0, 5)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = plr.DisplayName
			nameLbl.TextColor3 = Theme.Text
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 11
			nameLbl.Parent = btn

			local subLbl = Instance.new("TextLabel")
			subLbl.Size = UDim2.new(1, -50, 0, 13)
			subLbl.Position = UDim2.new(0, 42, 0, 21)
			subLbl.BackgroundTransparency = 1
			subLbl.Text = "@" .. plr.Name
			subLbl.TextColor3 = Theme.Dim
			subLbl.TextXAlignment = Enum.TextXAlignment.Left
			subLbl.TextTruncate = Enum.TextTruncate.AtEnd
			subLbl.Font = Enum.Font.Gotham
			subLbl.TextSize = 10
			subLbl.Parent = btn

			if not selected then
				addHover(btn, baseCol, Theme.CardHover)
			end

			btn.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				refreshPlayerList()
				CmdBox.Text = "" .. plr.Name
				setStatus("Выбран: " .. plr.DisplayName .. " (кнопка «TP к выбранному игроку»)", false)
			end)
		end
	end

	PlayersTitle.Text = "👥  ИГРОКИ  (" .. count .. ")"
	PlayersList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

local ModsScroll = Instance.new("ScrollingFrame")
ModsScroll.Size = UDim2.new(1, -274, 1, -276)
ModsScroll.Position = UDim2.new(0, 262, 0, 172)
ModsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ModsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ModsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
ModsScroll.BackgroundColor3 = Theme.Panel
ModsScroll.BorderSizePixel = 0
ModsScroll.ScrollBarThickness = 5
ModsScroll.ScrollBarImageColor3 = Theme.Accent
ModsScroll.Parent = MainFrame

local SEC_VIS = "👁  ВИЗУАЛЫ / ESP"
local SEC_GFX = "💡  ГРАФИКА И ОСВЕЩЕНИЕ"
local SEC_MOVE = "🏃  ДВИЖЕНИЕ"
local SEC_BHOP = "🐇  BHOP / ПЛАВНЫЙ ПОВОРОТ / ЗАНОС"
local SEC_CHAR = "🧍  ПЕРСОНАЖ"
local SEC_TP = "📍  ТЕЛЕПОРТ И ТОЧКИ"
local SEC_ITEMS = "🎒  ПРЕДМЕТЫ"
local SEC_CAM = "🎥  КАМЕРА"
local SEC_SRV = "⚙  СЕРВЕР И УТИЛИТЫ"

local ModsList = Instance.new("UIListLayout")
ModsList.Padding = UDim.new(0, 10)
ModsList.SortOrder = Enum.SortOrder.LayoutOrder
ModsList.Parent = ModsScroll

local SectionGrids = {}
local SectionFrames = {}
local currentGrid = nil

for i, title in ipairs({ SEC_VIS, SEC_GFX, SEC_MOVE, SEC_BHOP, SEC_CHAR, SEC_TP, SEC_ITEMS, SEC_CAM, SEC_SRV }) do
	local sec = Instance.new("Frame")
	sec.Name = "Section" .. i
	sec.LayoutOrder = i
	sec.Size = UDim2.new(1, -8, 0, 0)
	sec.AutomaticSize = Enum.AutomaticSize.Y
	sec.BackgroundTransparency = 1
	sec.Parent = ModsScroll

	local secList = Instance.new("UIListLayout")
	secList.Padding = UDim.new(0, 5)
	secList.SortOrder = Enum.SortOrder.LayoutOrder
	secList.Parent = sec

	local header = Instance.new("TextLabel")
	header.LayoutOrder = 0
	header.Size = UDim2.new(1, 0, 0, 26)
	header.BackgroundColor3 = Color3.fromRGB(20, 23, 38)
	header.Text = title
	header.TextColor3 = Theme.Text
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.GothamBold
	header.TextSize = 12
	header.Parent = sec
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
	do
		local hp = Instance.new("UIPadding")
		hp.PaddingLeft = UDim.new(0, 18)
		hp.Parent = header
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, -10)
		bar.Position = UDim2.new(0, -12, 0, 5)
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar.BorderSizePixel = 0
		bar.Parent = header
		round(bar, 2)
		newGradient(bar, 90)
		newStroke(header, Theme.Line, 1, 0.55)
	end

	local gridFrame = Instance.new("Frame")
	gridFrame.LayoutOrder = 1
	gridFrame.Size = UDim2.new(1, 0, 0, 0)
	gridFrame.AutomaticSize = Enum.AutomaticSize.Y
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = sec

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 197, 0, 30)
	grid.CellPadding = UDim2.new(0, 6, 0, 5)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridFrame

	table.insert(SectionGrids, grid)
	SectionFrames[title] = gridFrame
end

local function setSection(title)
	currentGrid = SectionFrames[title]
end

local ModsPad = Instance.new("UIPadding")
ModsPad.PaddingTop = UDim.new(0, 8)
ModsPad.PaddingLeft = UDim.new(0, 8)
ModsPad.PaddingBottom = UDim.new(0, 8)
ModsPad.Parent = ModsScroll
local modsOrder = 0
Instance.new("UICorner", ModsScroll).CornerRadius = UDim.new(0, 10)
newStroke(ModsScroll, Theme.Line, 1, 0.35)

local TOGGLE_ON_BG = Color3.fromRGB(21, 41, 46)
local TOGGLE_OFF_TRACK = Color3.fromRGB(54, 58, 84)

local function makeToggle(keyName, labelText, colIndex, rowIndex, initial, callback)
	modsOrder += 1

	local btn = Instance.new("TextButton")
	btn.LayoutOrder = modsOrder
	btn.Size = UDim2.new(0, 197, 0, 30)
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BackgroundColor3 = Theme.Card
	btn.Parent = currentGrid or ModsScroll
	round(btn, 8)
	local btnStroke = newStroke(btn, Theme.Line, 1, 0.4)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Position = UDim2.new(0, 11, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Font = Enum.Font.GothamMedium
	label.TextSize = State.Mobile and 12 or 11
	label.Parent = btn

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, 32, 0, 16)
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -9, 0.5, 0)
	track.BorderSizePixel = 0
	track.Parent = btn
	round(track, 8)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = track
	round(knob, 6)

	local active = initial
	local hovering = false

	local function paint(instant)
		local dur = instant and 0 or 0.16
		local bg = active and TOGGLE_ON_BG or (hovering and Theme.CardHover or Theme.Card)
		tw(btn, dur, { BackgroundColor3 = bg })
		tw(track, dur, { BackgroundColor3 = active and Theme.On or TOGGLE_OFF_TRACK })
		tw(knob, dur, { Position = active and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) })
		tw(btnStroke, dur, {
			Color = active and Theme.On or Theme.Line,
			Transparency = active and 0.3 or 0.4,
		})
		label.TextColor3 = active and Theme.Text or Theme.Dim
	end
	paint(true)

	btn.MouseEnter:Connect(function()
		hovering = true
		paint(false)
	end)
	btn.MouseLeave:Connect(function()
		hovering = false
		paint(false)
	end)

	btn.MouseButton1Click:Connect(function()
		active = not active
		paint(false)
		callback(active)
	end)

	local function setVal(val)
		active = val
		paint(false)
	end

	if keyName then
		toggleSetters[keyName] = setVal
	end
	return btn, setVal
end

local function makeActionBtn(labelText, colIndex, rowIndex, color3, callback)
	modsOrder += 1
	local accent = color3 or Theme.Accent
	local hoverCol = Theme.Card:Lerp(accent, 0.35)

	local btn = Instance.new("TextButton")
	btn.LayoutOrder = modsOrder
	btn.Size = UDim2.new(0, 197, 0, 30)
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Theme.Card
	btn.Text = labelText
	btn.TextColor3 = Theme.Text
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.Parent = currentGrid or ModsScroll
	round(btn, 8)
	local actStroke = newStroke(btn, accent:Lerp(Color3.new(1, 1, 1), 0.15), 1, 0.55)
	local actStrokeColor = accent:Lerp(Color3.new(1, 1, 1), 0.15)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = btn

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Size = UDim2.new(0, 3, 1, -12)
	bar.Position = UDim2.new(0, -6, 0.5, 0)
	bar.BackgroundColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.45)
	bar.BorderSizePixel = 0
	bar.Parent = btn
	round(bar, 2)

	local hovering = false
	local flashId = 0
	local h, sat = accent:ToHSV()
	local glow = Color3.fromHSV(h, math.max(sat, 0.5), 0.85)

	btn.MouseEnter:Connect(function()
		hovering = true
		tw(btn, 0.12, { BackgroundColor3 = hoverCol })
	end)
	btn.MouseLeave:Connect(function()
		hovering = false
		tw(btn, 0.12, { BackgroundColor3 = Theme.Card })
	end)

	btn.MouseButton1Click:Connect(function()
		flashId += 1
		local id = flashId
		tw(btn, 0.07, { BackgroundColor3 = glow })
		tw(actStroke, 0.07, { Color = Color3.new(1, 1, 1), Transparency = 0 })
		tw(bar, 0.07, { BackgroundColor3 = Color3.new(1, 1, 1) })
		task.delay(0.6, function()
			if id == flashId and btn.Parent then
				tw(btn, 0.4, { BackgroundColor3 = hovering and hoverCol or Theme.Card })
				tw(actStroke, 0.4, { Color = actStrokeColor, Transparency = 0.55 })
				tw(bar, 0.4, { BackgroundColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.45) })
			end
		end)
		callback()
	end)
	return btn
end

-- ================= ОКНО ПРЕДМЕТОВ =================
local ItemsWindow = nil
local ItemsConns = {}
local openItemsWindow

local function closeItemsWindow()
	for _, c in ipairs(ItemsConns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(ItemsConns)
	if ItemsWindow then
		ItemsWindow:Destroy()
		ItemsWindow = nil
	end
end

local function isOwnedByPlayer(obj)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and obj:IsDescendantOf(plr.Character) then
			return true
		end
		local bp = plr:FindFirstChildOfClass("Backpack")
		if bp and obj:IsDescendantOf(bp) then
			return true
		end
	end
	return false
end

local function collectItems()
	local list = {}
	local sources = {
		{ workspace, "Workspace" },
		{ game:GetService("ReplicatedStorage"), "ReplicatedStorage" },
		{ game:GetService("StarterPack"), "StarterPack" },
		{ Lighting, "Lighting" },
	}
	for _, src in ipairs(sources) do
		local ok, descendants = pcall(function()
			return src[1]:GetDescendants()
		end)
		if ok then
			for _, obj in ipairs(descendants) do
				if obj:IsA("Tool") and not isOwnedByPlayer(obj) then
					table.insert(list, { Tool = obj, Source = src[2] })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return string.lower(a.Tool.Name) < string.lower(b.Tool.Name)
	end)
	return list
end

local function grabTool(tool)
	if not tool or not tool.Parent then
		setStatus("Предмет больше не существует", true)
		return
	end
	local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
	local _, hum, root = getChar()
	if not bp or not hum or not root then
		setStatus("Нет персонажа или Backpack", true)
		return
	end

	local name = tool.Name
	local savedCF = root.CFrame

	task.spawn(function()
		local copy
		local ok = pcall(function()
			copy = tool:Clone()
			for _, d in ipairs(copy:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = false
				end
			end
			if copy:IsA("Tool") then
				copy.Enabled = true
				copy.CanBeDropped = true
			end
			copy.Parent = bp
		end)
		if not ok or not copy then
			setStatus("Не удалось взять: " .. name, true)
			return
		end

		task.wait(0.1)
		pcall(function()
			hum:EquipTool(copy)
		end)

		task.wait(0.15)
		local _, _, curRoot = getChar()
		if curRoot and (curRoot.Position - savedCF.Position).Magnitude > 6 then
			curRoot.AssemblyLinearVelocity = Vector3.zero
			curRoot.CFrame = savedCF
		end

		setStatus("Взято и экипировано: " .. name, false)
	end)
end

openItemsWindow = function()
	if ItemsWindow then
		closeItemsWindow()
		return
	end

	local win = Instance.new("Frame")
	win.Name = "ItemsWindow"
	win.Size = UDim2.new(0, 360, 0, 420)
	win.Position = UDim2.new(0.5, -180, 0.5, -210)
	if State.Mobile then
		win.Size = UDim2.new(0, math.min(360, Camera.ViewportSize.X - 24), 0, math.min(420, Camera.ViewportSize.Y - 70))
		win.AnchorPoint = Vector2.new(0.5, 0.5)
		win.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	win.BackgroundColor3 = Theme.Bg
	win.BorderSizePixel = 0
	win.Active = true
	win.Draggable = not State.Mobile
	win.Parent = ScreenGui
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke")
	st.Color = Theme.Accent
	st.Thickness = 2
	st.Parent = win
	ItemsWindow = win

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 0, 34)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📦 Предметы плейса"
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.Parent = win

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 28, 0, 24)
	refreshBtn.Position = UDim2.new(1, -66, 0, 5)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(58, 82, 118)
	refreshBtn.Text = "⟳"
	refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshBtn.Font = Enum.Font.GothamBold
	refreshBtn.TextSize = 14
	refreshBtn.Parent = win
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 28, 0, 24)
	closeBtn.Position = UDim2.new(1, -34, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(205, 55, 70)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.Parent = win
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	if State.Mobile then
		refreshBtn.Size = UDim2.new(0, 38, 0, 28)
		refreshBtn.Position = UDim2.new(1, -88, 0, 3)
		closeBtn.Size = UDim2.new(0, 38, 0, 28)
		closeBtn.Position = UDim2.new(1, -46, 0, 3)
	end

	local search = Instance.new("TextBox")
	search.Size = UDim2.new(1, -24, 0, 28)
	search.Position = UDim2.new(0, 12, 0, 38)
	search.BackgroundColor3 = Theme.Card
	search.PlaceholderText = "Поиск предмета..."
	search.PlaceholderColor3 = Color3.fromRGB(125, 134, 155)
	search.Text = ""
	search.TextColor3 = Color3.fromRGB(255, 255, 255)
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.Font = Enum.Font.Gotham
	search.TextSize = 12
	search.ClearTextOnFocus = false
	search.Parent = win
	Instance.new("UICorner", search).CornerRadius = UDim.new(0, 6)

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -24, 1, -112)
	list.Position = UDim2.new(0, 12, 0, 72)
	list.BackgroundColor3 = Theme.Panel
	list.ScrollBarImageColor3 = Theme.Accent
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.Parent = win
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -24, 0, 30)
	countLabel.Position = UDim2.new(0, 12, 1, -34)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(150, 158, 178)
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextSize = 11
	countLabel.Parent = win

	local items = collectItems()

	local function render()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local filter = string.lower(search.Text)
		local shown = 0
		for _, entry in ipairs(items) do
			local tool = entry.Tool
			if tool.Parent and (filter == "" or string.find(string.lower(tool.Name), filter, 1, true)) then
				shown += 1
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -8, 0, State.Mobile and 36 or 28)
				btn.BackgroundColor3 = Theme.Card
				btn.AutoButtonColor = false
				btn.Text = "  " .. tool.Name .. "   [" .. entry.Source .. " › " .. tool.Parent.Name .. "]"
				btn.TextColor3 = Color3.fromRGB(230, 236, 248)
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.TextTruncate = Enum.TextTruncate.AtEnd
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 11
				btn.Parent = list
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				addHover(btn, Theme.Card, Theme.CardHover)

				btn.MouseButton1Click:Connect(function()
					closeItemsWindow()
					grabTool(tool)
				end)
			end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
		countLabel.Text = "Найдено: " .. shown .. " из " .. #items
	end

	table.insert(ItemsConns, search:GetPropertyChangedSignal("Text"):Connect(render))
	table.insert(ItemsConns, refreshBtn.MouseButton1Click:Connect(function()
		items = collectItems()
		render()
	end))
	table.insert(ItemsConns, closeBtn.MouseButton1Click:Connect(closeItemsWindow))

	render()
	setStatus("Окно предметов открыто (" .. #items .. ")", false)
end

-- ================= ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ =================
local function copyText(text)
	local fn = setclipboard or toclipboard
	if fn then
		return pcall(fn, text)
	end
	return false
end

local Crosshair = Instance.new("Frame")
Crosshair.Name = "HubCrosshair"
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Size = UDim2.new(0, 16, 0, 16)
Crosshair.Position = UDim2.new(0.5, 0, 0.5, -GuiService:GetGuiInset().Y / 2)
Crosshair.BackgroundTransparency = 1
Crosshair.Visible = false
Crosshair.Parent = ScreenGui
for _, dims in ipairs({ { 16, 2 }, { 2, 16 } }) do
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.new(0.5, 0, 0.5, 0)
	bar.Size = UDim2.new(0, dims[1], 0, dims[2])
	bar.BackgroundColor3 = Color3.fromRGB(80, 255, 140)
	bar.BorderSizePixel = 0
	bar.Parent = Crosshair
end

local HudLabel = Instance.new("TextLabel")
HudLabel.Name = "HubHUD"
HudLabel.Size = UDim2.new(0, 240, 0, 62)
HudLabel.Position = UDim2.new(0, 8, 0, 8)
HudLabel.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
HudLabel.BackgroundTransparency = 0.35
HudLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
HudLabel.TextXAlignment = Enum.TextXAlignment.Left
HudLabel.TextYAlignment = Enum.TextYAlignment.Top
HudLabel.Font = Enum.Font.Code
HudLabel.TextSize = 12
HudLabel.Text = ""
HudLabel.Visible = false
HudLabel.Parent = ScreenGui
Instance.new("UICorner", HudLabel).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", HudLabel).PaddingLeft = UDim.new(0, 8)

local function updateHUD(dt)
	if not State.HUD then return end
	hudFrames += 1
	hudAccum += dt
	if hudAccum >= 0.5 then
		local fps = math.floor(hudFrames / hudAccum + 0.5)
		hudFrames, hudAccum = 0, 0
		local ping = 0
		pcall(function()
			ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		local _, _, root = getChar()
		local pos = root and root.Position or Vector3.zero
		local speed = root and root.AssemblyLinearVelocity.Magnitude or 0
		HudLabel.Text = string.format("FPS: %d   Ping: %d ms\nXYZ: %.0f, %.0f, %.0f\nСкорость: %.0f", fps, ping, pos.X, pos.Y, pos.Z, speed)
	end
end

local function applyNoParticles(enabled)
	State.NoParticles = enabled
	if enabled then
		for _, o in ipairs(workspace:GetDescendants()) do
			if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
				if SavedParticles[o] == nil then
					SavedParticles[o] = o.Enabled
				end
				pcall(function() o.Enabled = false end)
			end
		end
	else
		for o, v in pairs(SavedParticles) do
			if o and o.Parent then
				pcall(function() o.Enabled = v end)
			end
		end
		table.clear(SavedParticles)
	end
end

local function applyCamWalls(enabled)
	State.CamWalls = enabled
	pcall(function()
		LocalPlayer.DevCameraOcclusionMode = enabled and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
	end)
end

local function applyHideName(enabled)
	State.HideName = enabled
	if not enabled then
		local _, hum = getChar()
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		end
	end
end

local function updateExtras(dt)
	updateHUD(dt)

	local char, hum, root = getChar()
	if not hum or not root then return end

	if State.NoFall then
		local vel = root.AssemblyLinearVelocity
		if vel.Y < -60 then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			if workspace:Raycast(root.Position, Vector3.new(0, -14, 0), params) then
				root.AssemblyLinearVelocity = Vector3.new(vel.X, -8, vel.Z)
			end
		end
	end

	if State.AutoClick then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool and os.clock() - lastAutoClick > 0.12 then
			lastAutoClick = os.clock()
			pcall(function() tool:Activate() end)
		end
	end

	if State.AutoEquipNearest then
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		if bp and not char:FindFirstChildOfClass("Tool") then
			local firstTool = bp:FindFirstChildOfClass("Tool")
			if firstTool then
				pcall(function() hum:EquipTool(firstTool) end)
			end
		end
	end

	if State.HighlightTools then
		local activeTool = char:FindFirstChildOfClass("Tool")
		if activeTool then
			if not ToolHighlight then
				ToolHighlight = Instance.new("Highlight")
				ToolHighlight.Name = "HubToolHighlight"
				ToolHighlight.FillColor = Theme.Accent2
				ToolHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				ToolHighlight.FillTransparency = 0.5
				ToolHighlight.Parent = ScreenGui
			end
			ToolHighlight.Adornee = activeTool
			ToolHighlight.Enabled = true
		elseif ToolHighlight then
			ToolHighlight.Enabled = false
		end
	elseif ToolHighlight then
		ToolHighlight.Enabled = false
	end

	if hum.Sit ~= lastSitState then
		lastSitState = hum.Sit
		if toggleSetters.sit then toggleSetters.sit(hum.Sit) end
	end

	if State.HideName and hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	if State.NoAnim then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not root then return end

	smoothYaw = nil

	if State.NoClip then
		syncNoClipCharacter()
	end

	-- GodMode: любое падение HP откатывается в тот же момент, когда оно произошло,
	-- поэтому здоровье не успевает измениться даже на кадр.
	addConn(hum.HealthChanged:Connect(function()
		if State.GodMode and not State.Destroyed and hum.Health > 0 and hum.Health < hum.MaxHealth then
			hum.Health = hum.MaxHealth
		end
	end))
	if State.GodMode then
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		hum.Health = hum.MaxHealth
	end

	addConn(hum.Died:Connect(function()
		local r = char:FindFirstChild("HumanoidRootPart")
		if r then
			State.LastDeathCF = r.CFrame
		end
	end))

	if State.RespawnDeath and State.LastDeathCF then
		task.wait(0.4)
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = State.LastDeathCF
			State.LastDeathCF = nil
			setStatus("Возврат на место смерти", false)
		end
	end
end

if LocalPlayer.Character then
	task.spawn(hookCharacter, LocalPlayer.Character)
end
addConn(LocalPlayer.CharacterAdded:Connect(function(c)
	task.spawn(hookCharacter, c)
end))

addConn(Mouse.Button1Down:Connect(function()
	if State.Destroyed or not State.ClickDelete then return end
	if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
	local target = Mouse.Target
	if target and not isCharacterPart(target) and target ~= AirWalkPart then
		table.insert(DeletedParts, { Part = target, Parent = target.Parent })
		target.Parent = nil
		setStatus("Удалено локально: " .. target.Name .. " (Undo Delete — отмена)", false)
	end
end))

local function undoDelete()
	local last = table.remove(DeletedParts)
	if last and last.Part then
		pcall(function() last.Part.Parent = last.Parent end)
		setStatus("Восстановлено: " .. last.Part.Name, false)
	else
		setStatus("Нечего восстанавливать", true)
	end
end

addConn(GuiService.ErrorMessageChanged:Connect(function(msg)
	if State.AutoRejoin and not State.Destroyed and msg and msg ~= "" then
		task.wait(2)
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end
end))

local function resetExtras()
	applyNoParticles(false)
	applyCamWalls(false)
	applyHideName(false)
	restoreNoClipParts()
	State.NoAnim = false
	State.AutoClick = false
	State.WarmTint = false
	State.CoolTint = false
	applyTintPreset()
	if ToolHighlight then
		ToolHighlight:Destroy()
		ToolHighlight = nil
	end
	for i = #DeletedParts, 1, -1 do
		local d = DeletedParts[i]
		pcall(function() d.Part.Parent = d.Parent end)
	end
	table.clear(DeletedParts)
end

local function teleportToSpawn()
	local _, _, root = getChar()
	if not root then
		setStatus("Нет персонажа", true)
		return
	end
	local spawn = LocalPlayer.RespawnLocation
	if not spawn then
		for _, o in ipairs(workspace:GetDescendants()) do
			if o:IsA("SpawnLocation") then
				spawn = o
				break
			end
		end
	end
	if spawn then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = spawn.CFrame * CFrame.new(0, 5, 0)
		setStatus("Телепорт на спавн", false)
	else
		setStatus("SpawnLocation не найден", true)
	end
end

-- ================= BHOP + ПЛАВНЫЙ ПОВОРОТ + ХОРОШИЙ ЗАНОС =================
local Bh = {
	lastHVel = Vector3.zero,
	lastAirTime = 0,
	lastJump = 0,
	hops = 0,
	lastYaw = nil,
	scrollUntil = 0,
	acc = 0,
	TICK = 1 / 64,
	sliding = false,
	slideVel = Vector3.zero,
	tracking = false,
	airVel = Vector3.zero,
	ray = RaycastParams.new(),
	lastRot = 0,
	smoothStamp = 0,
	rotHeld = false,
	prevAutoRotate = true,
}
Bh.ray.FilterType = Enum.RaycastFilterType.Exclude

-- Пока скрипт сам плавно доворачивает персонажа, выключаем AutoRotate у Humanoid:
-- иначе он резко «довращивает» модель к MoveDirection и борется со скриптом (дёрганье).
function Bh.holdAutoRotate(hum, hold)
	if not hum then return end
	if hold then
		if not Bh.rotHeld then
			Bh.rotHeld = true
			Bh.prevAutoRotate = hum.AutoRotate
		end
		hum.AutoRotate = false
	elseif Bh.rotHeld then
		Bh.rotHeld = false
		hum.AutoRotate = Bh.prevAutoRotate ~= false
	end
end

local function flatVec(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function angleDiff(a, b)
	return (a - b + math.pi) % (2 * math.pi) - math.pi
end

-- Плавный доворот персонажа без резких рывков.
-- Экспоненциальное сглаживание + ограничение угловой скорости (MaxTurnRate, рад/с).
-- Если доворот не вызывался > 0.2 c — начинаем от реального угла (раньше тут
-- оставался «старый» угол и модель резко прыгала к новому направлению).
local function applySmoothYaw(root, targetYaw, dt)
	if not State.SmoothTurn or not root then return end
	dt = math.clamp(dt or 0.016, 0.001, 0.1)
	local now = os.clock()
	local _, curYaw = root.CFrame:ToOrientation()
	local baseYaw = curYaw
	if smoothYaw and now - Bh.smoothStamp < 0.2 then
		baseYaw = smoothYaw
	end
	Bh.smoothStamp = now
	Bh.lastRot = now

	local diff = angleDiff(targetYaw, baseYaw)
	local k = 1 - math.exp(-State.TurnSmoothness * dt)
	local maxStep = State.MaxTurnRate * dt
	local step = math.clamp(diff * k, -maxStep, maxStep)
	local nextYaw = baseYaw + step
	smoothYaw = nextYaw

	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, nextYaw, 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

-- Спидометр
local SpeedoFrame = Instance.new("Frame")
SpeedoFrame.Name = "HubSpeedometer"
SpeedoFrame.AnchorPoint = Vector2.new(0.5, 1)
SpeedoFrame.Size = UDim2.new(0, 230, 0, 62)
SpeedoFrame.Position = UDim2.new(0.5, 0, 1, -80)
SpeedoFrame.BackgroundColor3 = Theme.Bg
SpeedoFrame.BackgroundTransparency = 0.2
SpeedoFrame.Visible = false
SpeedoFrame.Parent = ScreenGui
round(SpeedoFrame, 12)
newStroke(SpeedoFrame, Theme.Accent, 1.5, 0.2)

local SpeedoNum = Instance.new("TextLabel")
SpeedoNum.Size = UDim2.new(1, 0, 0, 34)
SpeedoNum.Position = UDim2.new(0, 0, 0, 4)
SpeedoNum.BackgroundTransparency = 1
SpeedoNum.Font = Enum.Font.GothamBlack
SpeedoNum.TextSize = 28
SpeedoNum.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedoNum.Text = "0"
SpeedoNum.Parent = SpeedoFrame

local SpeedoSub = Instance.new("TextLabel")
SpeedoSub.Size = UDim2.new(1, 0, 0, 14)
SpeedoSub.Position = UDim2.new(0, 0, 0, 36)
SpeedoSub.BackgroundTransparency = 1
SpeedoSub.Font = Enum.Font.GothamMedium
SpeedoSub.TextSize = 10
SpeedoSub.TextColor3 = Theme.Dim
SpeedoSub.Text = "studs/s   •   HOPS 0"
SpeedoSub.Parent = SpeedoFrame

local SpeedoBarBg = Instance.new("Frame")
SpeedoBarBg.Size = UDim2.new(1, -24, 0, 4)
SpeedoBarBg.Position = UDim2.new(0, 12, 1, -10)
SpeedoBarBg.BackgroundColor3 = Theme.Card
SpeedoBarBg.BorderSizePixel = 0
SpeedoBarBg.Parent = SpeedoFrame
round(SpeedoBarBg, 2)
local SpeedoFill = Instance.new("Frame")
SpeedoFill.Size = UDim2.new(0, 0, 1, 0)
SpeedoFill.BackgroundColor3 = Theme.Accent2
SpeedoFill.BorderSizePixel = 0
SpeedoFill.Parent = SpeedoBarBg
round(SpeedoFill, 2)

local function updateSpeedo()
	SpeedoFrame.Visible = State.Speedometer
	if not State.Speedometer then return end
	local _, _, root = getChar()
	if not root then return end
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local ratio = math.clamp(speed / math.max(State.BhopMax, 1), 0, 1)
	local col = Color3.fromHSV(0.52 * (1 - ratio), 0.75, 1)
	SpeedoNum.Text = string.format("%d", math.floor(speed + 0.5))
	SpeedoNum.TextColor3 = col
	SpeedoFill.BackgroundColor3 = col
	SpeedoFill.Size = UDim2.new(ratio, 0, 1, 0)
	local modeTag = Bh.sliding and "DRIFT" or "HOPS " .. Bh.hops
	SpeedoSub.Text = string.format("studs/s   •   %s", modeTag)
end

local function updateBhop(dt)
	if State.Destroyed then return end
	if not (State.Bhop or State.QuickStop) then
		Bh.hops = 0
		Bh.sliding = false
		smoothYaw = nil
		return
	end

	local char, hum, root = getChar()
	if not hum or not root or hum.Health <= 0 or hum.Sit or State.Fly or State.Frozen then return end

	local typing = UserInputService:GetFocusedTextBox() ~= nil
	local now = os.clock()
	local spaceHeld = (not typing) and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or now < Bh.scrollUntil
		or State.MobJump or (State.Mobile and hum.Jump))
	local vel = root.AssemblyLinearVelocity
	local hvel = flatVec(vel)
	local grounded = hum.FloorMaterial ~= Enum.Material.Air
	local moveDir = flatVec(hum.MoveDirection)
	local maxSpeed = math.max(hum.WalkSpeed, 16)

	local cam = Camera.CFrame
	local _, yaw = cam:ToOrientation()
	local yawDelta = 0
	if Bh.lastYaw then
		yawDelta = angleDiff(yaw, Bh.lastYaw)
	end
	Bh.lastYaw = yaw

	local look = flatVec(cam.LookVector)
	look = look.Magnitude > 0.001 and look.Unit or Vector3.new(0, 0, -1)
	local right = flatVec(cam.RightVector)
	right = right.Magnitude > 0.001 and right.Unit or Vector3.new(1, 0, 0)

	local fwd, side = 0, 0
	if not typing then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then fwd += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then fwd -= 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then side += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then side -= 1 end
	end

	if State.Mobile and fwd == 0 and side == 0 and moveDir.Magnitude > 0.1 then
		-- джойстик: раскладываем направление на «вперёд / вбок» относительно камеры
		fwd = moveDir:Dot(look)
		side = moveDir:Dot(right)
	end

	if State.AutoStrafe and not grounded and side == 0 and math.abs(yawDelta) > 0.0004 then
		side = yawDelta > 0 and -1 or 1
	end

	local wish = look * fwd + right * side
	if wish.Magnitude < 0.001 and moveDir.Magnitude > 0.1 then
		wish = moveDir
	end
	local hasWish = wish.Magnitude > 0.001
	if hasWish then
		wish = wish.Unit
	end

	-- ================= НА ЗЕМЛЕ =================
	if grounded then
		Bh.acc = 0
		Bh.tracking = false

		if State.Bhop and spaceHeld and now - Bh.lastJump > 0.12 then
			local carry = hvel
			if now - Bh.lastAirTime < 0.22 and Bh.lastHVel.Magnitude > hvel.Magnitude then
				carry = Bh.lastHVel
			end
			if hasWish then
				local short = maxSpeed - carry:Dot(wish)
				if short > 0 then
					carry += wish * short
				end
			end
			if carry.Magnitude > State.BhopMax then
				carry = carry.Unit * State.BhopMax
			end
			local jumpVel = hum.UseJumpPower and hum.JumpPower or math.sqrt(2 * workspace.Gravity * hum.JumpHeight)
			root.AssemblyLinearVelocity = Vector3.new(carry.X, jumpVel, carry.Z)
			if carry.Magnitude > 2 then
				local targetYaw = math.atan2(-carry.X, -carry.Z)
				applySmoothYaw(root, targetYaw, dt)
			end
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			Bh.lastJump = now
			Bh.hops += 1
			Bh.lastHVel = carry
			Bh.airVel = carry
			Bh.tracking = true
			Bh.sliding = false
			return
		end

		if not (State.Bhop and spaceHeld) then
			Bh.hops = 0
		end

		-- УЛУЧШЕННЫЙ ЗАНОС: плавный снос вектора скорости с подруливанием A/D и плавным доворотом
		if State.Bhop and State.DriftEnabled then
			if not Bh.sliding and now - Bh.lastAirTime < 0.18 and Bh.lastHVel.Magnitude > maxSpeed * 1.1 then
				Bh.sliding = true
				Bh.slideVel = Bh.lastHVel
			end
			if Bh.sliding then
				local v = Bh.slideVel
				local speed = v.Magnitude
				local dir = speed > 0.01 and v.Unit or Vector3.zero
				local steerAmt = 0

				if hasWish and speed > 0.5 then
					-- «Руль»: вектор скорости плавно поворачивается к направлению A/D/W/S
					local cross = dir.X * wish.Z - dir.Z * wish.X
					local dot = math.clamp(dir:Dot(wish), -1, 1)
					local ang = math.atan2(cross, dot)
					local maxRot = State.DriftSteerPower * dt
					local rot = math.clamp(ang, -maxRot, maxRot)
					local c, sn = math.cos(rot), math.sin(rot)
					dir = Vector3.new(dir.X * c - dir.Z * sn, 0, dir.X * sn + dir.Z * c)
					steerAmt = math.clamp(math.abs(rot) / math.max(maxRot, 1e-4), 0, 1)
					-- тормоз, если жмём против движения
					if dot < -0.2 then
						speed = math.max(speed - speed * 2.2 * dt, 0)
					end
				end

				-- Трение: чем сильнее рулим, тем больше сносит скорость (реалистичный занос)
				local fr = State.DriftFriction * (1 + steerAmt * 0.6)
				speed = math.max(speed - math.max(speed, 4) * fr * dt, 0)
				v = dir * speed

				if speed <= maxSpeed * 1.04 then
					Bh.sliding = false
				else
					Bh.slideVel = v
					root.AssemblyLinearVelocity = Vector3.new(v.X, vel.Y, v.Z)
					if speed > 3 then
						-- Корпус смотрит чуть в сторону руля — визуально как занос, без рывков
						local face = dir
						if hasWish then
							local mix = dir * 0.65 + wish * 0.35
							if mix.Magnitude > 0.05 then
								face = mix.Unit
							end
						end
						applySmoothYaw(root, math.atan2(-face.X, -face.Z), dt)
					end
					return
				end
			end
		else
			Bh.sliding = false
		end

		if State.QuickStop and hum.MoveDirection.Magnitude < 0.05 and not Bh.sliding then
			local speed = hvel.Magnitude
			if speed > 0.4 then
				local drop = math.max(speed, 3) * 10 * dt
				local newSpeed = math.max(speed - drop, 0)
				local nv = hvel.Unit * newSpeed
				root.AssemblyLinearVelocity = Vector3.new(nv.X, vel.Y, nv.Z)
			end
		end
		return
	end

	-- ================= В ВОЗДУХЕ =================
	Bh.lastAirTime = now
	Bh.sliding = false

	if not (State.Bhop and (spaceHeld or Bh.hops > 0)) then
		Bh.tracking = false
		Bh.acc = 0
		Bh.lastHVel = hvel
		return
	end

	pcall(function()
		hum:Move(Vector3.zero, false)
	end)

	if not Bh.tracking then
		Bh.airVel = hvel
		Bh.tracking = true
	end
	local v = Bh.airVel

	if v.Magnitude > 1 and not State.NoClip then
		Bh.ray.FilterDescendantsInstances = { char }
		local hit = workspace:Raycast(root.Position, v.Unit * (v.Magnitude * dt * 2 + 1.6), Bh.ray)
		if hit and math.abs(hit.Normal.Y) < 0.6 then
			local into = v:Dot(hit.Normal)
			if into < 0 then
				v = v - hit.Normal * into
			end
		end
	end

	local airCap = 30 * (maxSpeed / 250) * State.AirCapMul
	Bh.acc += dt
	local ticks = 0
	while Bh.acc >= Bh.TICK and ticks < 8 do
		Bh.acc -= Bh.TICK
		ticks += 1
		if hasWish then
			local addSpeed = airCap - v:Dot(wish)
			if addSpeed > 0 then
				local accelSpeed = math.min(State.AirAccel * maxSpeed * Bh.TICK, addSpeed)
				v += wish * accelSpeed
			end
		end
	end

	if v.Magnitude > State.BhopMax then
		v = v.Unit * State.BhopMax
	end

	Bh.airVel = v
	Bh.lastHVel = v
	root.AssemblyLinearVelocity = Vector3.new(v.X, vel.Y, v.Z)
	if v.Magnitude > 3 then
		local airYaw = math.atan2(-v.X, -v.Z)
		applySmoothYaw(root, airYaw, dt)
	end
end

addConn(UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel and not State.IsOpen then
		Bh.scrollUntil = os.clock() + 0.16
	end
end))

pcall(function()
	RunService:UnbindFromRenderStep("HubBhop")
end)
RunService:BindToRenderStep("HubBhop", Enum.RenderPriority.Last.Value, function(dt)
	pcall(updateBhop, dt)
	pcall(updateSpeedo)
	pcall(function()
		local _, h = getChar()
		-- пока идёт плавный доворот — AutoRotate выключен, потом возвращаем как было
		Bh.holdAutoRotate(h, State.SmoothTurn and os.clock() - Bh.lastRot < 0.1)
	end)
end)

-- Занос: перед каждым шагом физики заново задаём скорость скольжения,
-- иначе Humanoid на земле быстро гасит её трением и занос выходит коротким.
addConn(RunService.Stepped:Connect(function()
	if State.Destroyed or not Bh.sliding then return end
	local _, hum, root = getChar()
	if hum and root and hum.Health > 0 then
		local v = Bh.slideVel
		root.AssemblyLinearVelocity = Vector3.new(v.X, root.AssemblyLinearVelocity.Y, v.Z)
	end
end))

local function bringPlayer(plr)
	if not plr then
		setStatus("Сначала выбери игрока в списке слева", true)
		return
	end
	local remote = game:GetService("ReplicatedStorage"):FindFirstChild("HubBringRemote")
	if not remote then
		setStatus("Нет серверной части: положи этот же файл как Script в ServerScriptService своего плейса", true)
		return
	end
	remote:FireServer(plr.UserId)
	setStatus("Запрос отправлен: привести " .. plr.DisplayName, false)
end

-- ================= ФУНКЦИИ (100+ ОПЦИЙ И ДЕЙСТВИЙ) =================
setSection(SEC_VIS)
makeToggle("esp", "ESP (Подсветка/Имя)", 0, 0, false, function(v)
	State.ESP = v
	setStatus("ESP " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_VIS)
makeToggle("espbox", "Hitbox ESP (Рамка)", 1, 0, false, function(v)
	State.ESPBox = v
	setStatus("Hitbox ESP " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_VIS)
makeToggle("esphp", "HP Bar ESP (Полоска)", 0, 1, false, function(v)
	State.ESPHP = v
	setStatus("HP Bar ESP " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_VIS)
makeToggle("rainbowesp", "Rainbow ESP", 0, 5, false, function(v)
	State.RainbowESP = v
	setStatus("Rainbow ESP " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("xray", "X-Ray Walls", 1, 9, false, function(v)
	applyXRay(v)
	setStatus("X-Ray " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("espchams", "ESP Chams (Яркий контур)", 0, 0, false, function(v)
	State.ESPChams = v
	setStatus("ESP Chams " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("espname", "ESP Имена игроков", 0, 0, true, function(v)
	State.ESPName = v
	setStatus("ESP Имена " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("espdist", "ESP Дистанция (studs)", 0, 0, true, function(v)
	State.ESPDistance = v
	setStatus("ESP Дистанция " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("teamcheck", "Team Check (Не трогать своих)", 0, 0, false, function(v)
	State.TeamCheck = v
	setStatus("Team Check " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("hitbox", "Hitbox Expand (Размер)", 1, 2, false, function(v)
	State.HitboxExpand = v
	updateHitboxExpand()
	setStatus("Hitbox Expand " .. (v and ("ON (" .. string.format("%.1fx", State.HitboxScale) .. ")") or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("hbheads", "Hitbox: только голова", 0, 0, false, function(v)
	State.HitboxHeadsOnly = v
	if State.HitboxExpand then updateHitboxExpand() end
	setStatus("Hitbox только голова: " .. tostring(v), false)
end)

setSection(SEC_VIS)
makeToggle("hbvis", "Hitbox: показывать рамку", 0, 0, true, function(v)
	State.HitboxVisible = v
	if State.HitboxExpand then updateHitboxExpand() end
	setStatus("Видимость Hitbox: " .. tostring(v), false)
end)

setSection(SEC_VIS)
makeToggle("crosshair", "Прицел по центру", 0, 0, false, function(v)
	State.Crosshair = v
	Crosshair.Visible = v
	setStatus("Прицел " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("hud", "HUD (FPS/Ping/XYZ)", 0, 0, false, function(v)
	State.HUD = v
	HudLabel.Visible = v
	setStatus("HUD " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_VIS)
makeToggle("highlighttools", "Подсветка активного предмета", 0, 0, false, function(v)
	State.HighlightTools = v
	setStatus("Подсветка предмета " .. (v and "ON" or "OFF"), false)
end)

-- Ползунок размера хитбоксов + сброс
local SliderCard = Instance.new("Frame")
SliderCard.Size = UDim2.new(1, -690, 0, 48)
SliderCard.Position = UDim2.new(0, 678, 0, 114)
SliderCard.BackgroundColor3 = Theme.Card
SliderCard.BorderSizePixel = 0
SliderCard.Parent = MainFrame
Instance.new("UICorner", SliderCard).CornerRadius = UDim.new(0, 10)
newStroke(SliderCard, Theme.Line, 1, 0.35)

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 265, 0, 18)
SliderLabel.Position = UDim2.new(0, 8, 0, 3)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Размер хитбоксов других игроков: 1.5x (1.0x - 5.0x)"
SliderLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 11
SliderLabel.Parent = SliderCard

local ResetHitboxBtn = Instance.new("TextButton")
ResetHitboxBtn.Size = UDim2.new(0, 118, 0, 20)
ResetHitboxBtn.Position = UDim2.new(1, -124, 0, 4)
ResetHitboxBtn.BackgroundColor3 = Color3.fromRGB(78, 30, 46)
ResetHitboxBtn.AutoButtonColor = false
ResetHitboxBtn.Text = "Сброс Hitbox"
ResetHitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetHitboxBtn.Font = Enum.Font.GothamBold
ResetHitboxBtn.TextSize = 10
ResetHitboxBtn.Parent = SliderCard
Instance.new("UICorner", ResetHitboxBtn).CornerRadius = UDim.new(0, 6)
newStroke(ResetHitboxBtn, Color3.fromRGB(255, 100, 120), 1, 0.55)
addHover(ResetHitboxBtn, Color3.fromRGB(78, 30, 46), Color3.fromRGB(150, 44, 66))

local SliderTrack = Instance.new("Frame")
SliderTrack.Name = "HitboxSliderTrack"
SliderTrack.Size = UDim2.new(1, -16, 0, State.Mobile and 16 or 12)
SliderTrack.Position = UDim2.new(0, 8, 0, 28)
SliderTrack.BackgroundColor3 = Theme.Bg
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderCard
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 6)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.125, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 6)
newGradient(SliderFill, 0)

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.new(0, State.Mobile and 26 or 16, 0, State.Mobile and 26 or 16)
SliderKnob.Position = UDim2.new(0.125, -SliderKnob.Size.X.Offset / 2, 0.5, -SliderKnob.Size.Y.Offset / 2)
SliderKnob.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
SliderKnob.Text = ""
SliderKnob.Parent = SliderTrack
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)
newStroke(SliderKnob, Theme.Accent2, 2, 0)

updateHitboxSliderUI = function(scaleVal)
	local clamped = math.clamp(scaleVal, 1.0, 5.0)
	State.HitboxScale = tonumber(string.format("%.1f", clamped)) or 1.5
	local alpha = (State.HitboxScale - 1.0) / 4.0
	SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	SliderKnob.Position = UDim2.new(alpha, -SliderKnob.Size.X.Offset / 2, 0.5, -SliderKnob.Size.Y.Offset / 2)
	SliderLabel.Text = string.format(State.Mobile and "Хитбоксы: %.1fx" or "Размер хитбоксов других игроков: %.1fx (1.0x - 5.0x)", State.HitboxScale)
end

local function setSliderFromX(absX)
	local left = SliderTrack.AbsolutePosition.X
	local width = math.max(SliderTrack.AbsoluteSize.X, 1)
	local alpha = math.clamp((absX - left) / width, 0, 1)
	local newScale = 1.0 + alpha * 4.0
	updateHitboxSliderUI(newScale)
	if State.HitboxExpand then
		updateHitboxExpand()
	end
	setStatus(string.format("Размер хитбоксов: %.1fx", State.HitboxScale), false)
end

addConn(SliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		setSliderFromX(input.Position.X)
	end
end))
addConn(SliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
	end
end))
addConn(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end))
addConn(UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setSliderFromX(input.Position.X)
	end
end))
addConn(ResetHitboxBtn.MouseButton1Click:Connect(function()
	resetAllHitboxes()
	setStatus("Хитбоксы сброшены (1.0x, OFF)", false)
end))
updateHitboxSliderUI(State.HitboxScale)

-- ГРАФИКА И ОСВЕЩЕНИЕ
setSection(SEC_GFX)
makeToggle("fpsboost", "FPS Boost (No Shader)", 0, 2, false, function(v)
	applyFPSBoost(v)
	setStatus(v and ("FPS Boost ON (дистанция " .. State.RenderDistance .. ")") or "FPS Boost OFF", false)
end)

setSection(SEC_GFX)
makeToggle("fb", "Fullbright", 0, 8, false, function(v)
	applyFullbright(v)
	setStatus("Fullbright " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_GFX)
makeToggle("nightvision", "Night Vision", 1, 8, false, function(v)
	applyNightVision(v)
	setStatus("Night Vision " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_GFX)
makeToggle("nofog", "No Fog / No Atm", 0, 9, false, function(v)
	applyNoFog(v)
	setStatus("No Fog " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_GFX)
makeToggle("noparticles", "No Particles", 0, 0, false, function(v)
	applyNoParticles(v)
	setStatus("No Particles " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_GFX)
makeToggle("warmtint", "Тёплый тон экрана", 0, 0, false, function(v)
	State.WarmTint = v
	if v then State.CoolTint = false; if toggleSetters.cooltint then toggleSetters.cooltint(false) end end
	applyTintPreset()
	setStatus("Тёплый тон " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_GFX)
makeToggle("cooltint", "Холодный тон экрана", 0, 0, false, function(v)
	State.CoolTint = v
	if v then State.WarmTint = false; if toggleSetters.warmtint then toggleSetters.warmtint(false) end end
	applyTintPreset()
	setStatus("Холодный тон " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_GFX)
makeToggle("mutesounds", "Приглушить звуки игры", 0, 0, false, function(v)
	State.MuteSounds = v
	SoundService.Volume = v and 0.1 or 1
	setStatus("Громкость игры: " .. (v and "10%" or "100%"), false)
end)

setSection(SEC_GFX)
do
	modsOrder += 1
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = modsOrder
	btn.Size = UDim2.new(0, 197, 0, 30)
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BackgroundColor3 = Theme.Card
	btn.Parent = currentGrid or ModsScroll
	round(btn, 8)
	local timeStroke = newStroke(btn, Theme.Line, 1, 0.4)

	local skyBg = Instance.new("Frame")
	skyBg.Size = UDim2.new(1, 0, 1, 0)
	skyBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	skyBg.BorderSizePixel = 0
	skyBg.Visible = false
	skyBg.Parent = btn
	round(skyBg, 8)
	local skyGrad = Instance.new("UIGradient")
	skyGrad.Rotation = 90
	skyGrad.Parent = skyBg

	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size = UDim2.new(1, 0, 1, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.ZIndex = 2
	timeLbl.Font = Enum.Font.GothamBold
	timeLbl.TextSize = 11
	timeLbl.Parent = btn

	local hoveringTime = false
	local function paintTime()
		local mode = State.TimeLock
		if mode == "DAY" then
			skyBg.Visible = true
			skyGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 140, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(176, 224, 255)),
			})
			timeLbl.Text = "☀  День"
			timeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			timeLbl.TextStrokeTransparency = 0.65
			timeStroke.Color = Color3.fromRGB(170, 220, 255)
			timeStroke.Transparency = 0.05
		elseif mode == "NIGHT" then
			skyBg.Visible = true
			skyGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 7, 24)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 30, 96)),
			})
			timeLbl.Text = "🌙  Ночь"
			timeLbl.TextColor3 = Color3.fromRGB(205, 210, 255)
			timeLbl.TextStrokeTransparency = 1
			timeStroke.Color = Color3.fromRGB(120, 108, 255)
			timeStroke.Transparency = 0.15
		else
			skyBg.Visible = false
			timeLbl.Text = "Время суток: выкл"
			timeLbl.TextColor3 = Theme.Dim
			timeLbl.TextStrokeTransparency = 1
			timeStroke.Color = Theme.Line
			timeStroke.Transparency = 0.4
			btn.BackgroundColor3 = hoveringTime and Theme.CardHover or Theme.Card
		end
	end
	paintTime()
	toggleSetters.timeBtn = paintTime

	btn.MouseEnter:Connect(function()
		hoveringTime = true
		if State.TimeLock == "OFF" then btn.BackgroundColor3 = Theme.CardHover end
	end)
	btn.MouseLeave:Connect(function()
		hoveringTime = false
		if State.TimeLock == "OFF" then btn.BackgroundColor3 = Theme.Card end
	end)

	btn.MouseButton1Click:Connect(function()
		if State.TimeLock == "OFF" then
			State.TimeLock = "DAY"
		elseif State.TimeLock == "DAY" then
			State.TimeLock = "NIGHT"
		else
			State.TimeLock = "OFF"
			Lighting.ClockTime = OriginalLighting.ClockTime
		end
		paintTime()
		updateTimeLock()
		setStatus("TimeLock: " .. State.TimeLock, false)
	end)
end

-- ДВИЖЕНИЕ (С ИСПРАВЛЕННЫМ NOCLIP)
setSection(SEC_MOVE)
makeToggle("noclip", "NoClip (Фикс выкл.)", 0, 7, false, function(v)
	setNoClipState(v)
	setStatus("NoClip " .. (v and "включён" or "выключен (коллизии возвращены)"), false)
end)

setSection(SEC_MOVE)
makeToggle("multijump", "Multi Jump", 0, 6, false, function(v)
	State.MultiJump = v
	State.AirJumpsUsed = 0
	setStatus("Мультипрыжок " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_MOVE)
makeToggle("fly", "Fly (WASD)", 1, 6, false, function(v)
	setFlyState(v)
	setStatus("Полёт " .. (v and "включён" or "выключен"), false)
end)

setSection(SEC_MOVE)
makeToggle("glide", "Glide (Парение)", 1, 7, false, function(v)
	State.Glide = v
	setStatus("Glide " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_MOVE)
makeToggle("airwalk", "AirWalk (Hold V)", 1, 10, false, function(v)
	State.AirWalk = v
	setStatus(v and "AirWalk: зажми V" or "AirWalk OFF", false)
end)

setSection(SEC_MOVE)
makeToggle("autosprint", "Auto Sprint (28)", 0, 11, false, function(v)
	State.AutoSprint = v
	setStatus("Auto Sprint " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_MOVE)
makeToggle("autojump", "Auto Jump", 1, 11, false, function(v)
	State.AutoJump = v
	setStatus("Auto Jump " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_MOVE)
makeToggle("lowgrav", "Low Gravity", 1, 14, false, function(v)
	State.LowGravity = v
	setStatus("Low Gravity " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_MOVE)
makeToggle("nofall", "No Fall Damage", 0, 0, false, function(v)
	State.NoFall = v
	setStatus("No Fall Damage " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_MOVE)
makeActionBtn("Blink Рывок (+18)", 0, 16, Color3.fromRGB(58, 82, 118), function()
	local _, _, root = getChar()
	if root then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = root.CFrame * CFrame.new(0, 0, -State.BlinkDist)
		setStatus("Blink рывок на " .. State.BlinkDist .. " studs", false)
	end
end)

setSection(SEC_MOVE)
makeActionBtn("TP Вверх (+50)", 1, 16, Color3.fromRGB(58, 82, 118), function()
	local _, _, root = getChar()
	if root then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = root.CFrame * CFrame.new(0, 50, 0)
		setStatus("TP вверх на +50 studs", false)
	end
end)

setSection(SEC_MOVE)
makeActionBtn("Стоп-импульс (0 vel)", 0, 0, Color3.fromRGB(65, 78, 115), function()
	local _, _, root = getChar()
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		setStatus("Скорость сброшена в 0", false)
	end
end)

-- BHOP / ПЛАВНЫЙ ПОВОРОТ / ЗАНОС
setSection(SEC_BHOP)
makeToggle("bhop", "Bhop + Занос (Пробел)", 0, 0, false, function(v)
	State.Bhop = v
	Bh.hops = 0
	Bh.sliding = false
	Bh.tracking = false
	setStatus(v and "Bhop + занос ON" or "Bhop OFF", false)
end)

setSection(SEC_BHOP)
makeToggle("drift", "Занос (Drift) при приземлении", 0, 0, true, function(v)
	State.DriftEnabled = v
	Bh.sliding = false
	setStatus("Занос " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_BHOP)
makeToggle("smoothturn", "Плавный поворот (No Snap)", 0, 0, true, function(v)
	State.SmoothTurn = v
	smoothYaw = nil
	setStatus("Плавный поворот " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_BHOP)
makeToggle("autostrafe", "Auto Strafe", 0, 0, false, function(v)
	State.AutoStrafe = v
	setStatus(v and "Auto Strafe ON" or "Auto Strafe OFF", false)
end)

setSection(SEC_BHOP)
makeToggle("quickstop", "Quick Stop (CS-остановка)", 0, 0, false, function(v)
	State.QuickStop = v
	setStatus("Quick Stop " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_BHOP)
makeToggle("speedo", "Спидометр", 0, 0, false, function(v)
	State.Speedometer = v
	SpeedoFrame.Visible = v
	setStatus("Спидометр " .. (v and "ON" or "OFF"), false)
end)

do
	local smoothOpts = { 6, 11, 16, 24 }
	local sIdx = 2
	local sBtn
	setSection(SEC_BHOP)
	sBtn = makeActionBtn("Плавность поворота: 11 (клик)", 0, 0, Color3.fromRGB(70, 90, 160), function()
		sIdx = sIdx % #smoothOpts + 1
		State.TurnSmoothness = smoothOpts[sIdx]
		sBtn.Text = "Плавность поворота: " .. State.TurnSmoothness .. " (клик)"
		setStatus("Плавность поворота = " .. State.TurnSmoothness, false)
	end)

	local driftOpts = { 0.8, 1.35, 2.2, 3.2 }
	local dIdx = 2
	local dBtn
	setSection(SEC_BHOP)
	dBtn = makeActionBtn("Трение заноса: 1.35 (клик)", 0, 0, Color3.fromRGB(70, 90, 160), function()
		dIdx = dIdx % #driftOpts + 1
		State.DriftFriction = driftOpts[dIdx]
		dBtn.Text = "Трение заноса: " .. State.DriftFriction .. " (клик)"
		setStatus("Трение заноса = " .. State.DriftFriction .. " (меньше = длиннее занос)", false)
	end)

	local steerOpts = { 4.0, 6.8, 10.0 }
	local stIdx = 2
	local stBtn
	setSection(SEC_BHOP)
	stBtn = makeActionBtn("Подруливание в заносе: 6.8", 0, 0, Color3.fromRGB(70, 90, 160), function()
		stIdx = stIdx % #steerOpts + 1
		State.DriftSteerPower = steerOpts[stIdx]
		stBtn.Text = "Подруливание в заносе: " .. State.DriftSteerPower
		setStatus("Подруливание в заносе = " .. State.DriftSteerPower, false)
	end)

	local airOptions = { 6, 12, 20, 40 }
	local airIdx = 2
	local airBtn
	setSection(SEC_BHOP)
	airBtn = makeActionBtn("Air Accel: 12 (клик)", 0, 0, Color3.fromRGB(70, 90, 160), function()
		airIdx = airIdx % #airOptions + 1
		State.AirAccel = airOptions[airIdx]
		airBtn.Text = "Air Accel: " .. State.AirAccel .. " (клик)"
		setStatus("Air Accel = " .. State.AirAccel, false)
	end)

	local maxOptions = { 50, 70, 100, 150, 300 }
	local maxIdx = 2
	local maxBtn
	setSection(SEC_BHOP)
	maxBtn = makeActionBtn("Макс. скорость: 70 (клик)", 0, 0, Color3.fromRGB(70, 90, 160), function()
		maxIdx = maxIdx % #maxOptions + 1
		State.BhopMax = maxOptions[maxIdx]
		maxBtn.Text = "Макс. скорость: " .. State.BhopMax .. " (клик)"
		setStatus("Лимит скорости Bhop = " .. State.BhopMax, false)
	end)

	local capOptions = { 1, 1.5, 2, 3 }
	local capIdx = 2
	local capBtn
	setSection(SEC_BHOP)
	capBtn = makeActionBtn("Air Cap: x1.5 (клик)", 0, 0, Color3.fromRGB(70, 90, 160), function()
		capIdx = capIdx % #capOptions + 1
		State.AirCapMul = capOptions[capIdx]
		capBtn.Text = "Air Cap: x" .. State.AirCapMul .. " (клик)"
		setStatus("Air Cap x" .. State.AirCapMul, false)
	end)
end

-- ПЕРСОНАЖ
setSection(SEC_CHAR)
makeToggle("god", "God (HP всегда максимум)", 1, 1, false, function(v)
	State.GodMode = v
	setStatus(v and "Бессмертие ON (HP заблокирован на максимуме)" or "Бессмертие OFF", false)
end)

setSection(SEC_CHAR)
makeToggle("antiragdoll", "Anti-Ragdoll", 0, 12, false, function(v)
	State.AntiRagdoll = v
	setStatus("Anti-Ragdoll " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("spin", "Spinbot", 1, 12, false, function(v)
	State.Spinbot = v
	setStatus("Spinbot " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("freeze", "Freeze Char", 1, 13, false, function(v)
	State.Frozen = v
	setStatus("Freeze " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("hidename", "Скрыть свой ник", 0, 0, false, function(v)
	applyHideName(v)
	setStatus("Скрытие ника " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("noanim", "No Animations", 0, 0, false, function(v)
	State.NoAnim = v
	setStatus("No Animations " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("respdeath", "Респавн на месте смерти", 0, 0, false, function(v)
	State.RespawnDeath = v
	setStatus("Респавн на месте смерти " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("sit", "Sit (сидеть)", 1, 17, false, function(v)
	local _, hum = getChar()
	if hum then
		hum.Sit = v
		setStatus("Sit: " .. tostring(v), false)
	end
end)

setSection(SEC_CHAR)
makeToggle("noclimb", "Отключить лазание (No Climb)", 0, 0, false, function(v)
	State.NoClimb = v
	setStatus("No Climb " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("noseat", "Не садиться в сиденья", 0, 0, false, function(v)
	State.NoSeat = v
	setStatus("No Seat " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("antifling", "Anti-Fling (защита от отброса)", 0, 0, true, function(v)
	State.AntiFling = v
	setStatus("Anti-Fling " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeToggle("antivoid", "Anti-Void (спасение из бездны)", 0, 0, true, function(v)
	State.AntiVoid = v
	setStatus("Anti-Void " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CHAR)
makeActionBtn("Возродить (Reset)", 1, 18, Color3.fromRGB(125, 55, 70), function()
	local _, hum = getChar()
	if hum then
		hum.Health = 0
		setStatus("Персонаж возрождается", false)
	end
end)

-- ТЕЛЕПОРТ И ТОЧКИ
setSection(SEC_TP)
makeToggle("clicktp", "Click TP (Alt+LMB)", 0, 10, false, function(v)
	State.ClickTP = v
	setStatus(v and "Click TP: Alt + ЛКМ" or "Click TP выключен", false)
end)

setSection(SEC_TP)
makeToggle("followplr", "Следовать за выбранным", 0, 0, false, function(v)
	State.FollowPlayer = v
	if v then State.OrbitPlayer = false; if toggleSetters.orbitplr then toggleSetters.orbitplr(false) end end
	setStatus("Follow " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_TP)
makeToggle("orbitplr", "Орбита вокруг выбранного", 0, 0, false, function(v)
	State.OrbitPlayer = v
	if v then State.FollowPlayer = false; if toggleSetters.followplr then toggleSetters.followplr(false) end end
	setStatus("Orbit " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_TP)
makeToggle("tpbehind", "TP за спину цели", 0, 0, true, function(v)
	State.TPBehindTarget = v
	setStatus("TP за спину: " .. tostring(v), false)
end)

setSection(SEC_TP)
makeActionBtn("Сохранить точку 1", 0, 15, Color3.fromRGB(68, 62, 105), function()
	local _, _, root = getChar()
	if root then
		State.SavedPoint = root.CFrame
		setStatus("Точка 1 сохранена", false)
	else
		setStatus("Нет персонажа", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("TP на точку 1", 1, 15, Color3.fromRGB(48, 92, 125), function()
	local _, _, root = getChar()
	if root and State.SavedPoint then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = State.SavedPoint * CFrame.new(0, 2, 0)
		setStatus("Телепорт на точку 1", false)
	else
		setStatus("Сначала сохрани точку 1!", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("Сохранить точку 2", 0, 0, Color3.fromRGB(68, 62, 105), function()
	local _, _, root = getChar()
	if root then
		State.SavedPoint2 = root.CFrame
		setStatus("Точка 2 сохранена", false)
	else
		setStatus("Нет персонажа", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("TP на точку 2", 0, 0, Color3.fromRGB(48, 92, 125), function()
	local _, _, root = getChar()
	if root and State.SavedPoint2 then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = State.SavedPoint2 * CFrame.new(0, 2, 0)
		setStatus("Телепорт на точку 2", false)
	else
		setStatus("Сначала сохрани точку 2", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("Сохранить точку 3", 0, 0, Color3.fromRGB(68, 62, 105), function()
	local _, _, root = getChar()
	if root then
		State.SavedPoint3 = root.CFrame
		setStatus("Точка 3 сохранена", false)
	end
end)

setSection(SEC_TP)
makeActionBtn("TP на точку 3", 0, 0, Color3.fromRGB(48, 92, 125), function()
	local _, _, root = getChar()
	if root and State.SavedPoint3 then
		State.PrevPosCF = root.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = State.SavedPoint3 * CFrame.new(0, 2, 0)
		setStatus("Телепорт на точку 3", false)
	end
end)

setSection(SEC_TP)
makeActionBtn("TP к ближайшему игроку", 0, 0, Color3.fromRGB(70, 95, 145), function()
	local near = findNearestPlayer()
	if near then
		selectedPlayer = near
		refreshPlayerList()
		local ok, msg = teleportToPlayer(near)
		setStatus(msg, not ok)
	else
		setStatus("Рядом нет других игроков", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("Назад на прошлую позицию", 0, 0, Color3.fromRGB(85, 70, 120), function()
	local _, _, root = getChar()
	if root and State.PrevPosCF then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = State.PrevPosCF
		setStatus("Возврат на прошлую позицию", false)
	else
		setStatus("Нет прошлой позиции", true)
	end
end)

setSection(SEC_TP)
makeActionBtn("TP на спавн", 0, 0, Color3.fromRGB(48, 92, 125), teleportToSpawn)

setSection(SEC_TP)
makeActionBtn("🧲 Привести выбранного", 0, 0, Color3.fromRGB(150, 70, 60), function()
	bringPlayer(selectedPlayer)
end)

setSection(SEC_TP)
makeActionBtn("Копировать позицию", 0, 0, Color3.fromRGB(70, 80, 110), function()
	local _, _, root = getChar()
	if not root then setStatus("Нет персонажа", true); return end
	local p = root.Position
	local text = string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
	setStatus(copyText(text) and ("Скопировано: " .. text) or ("setclipboard недоступен: " .. text), false)
end)

-- ПРЕДМЕТЫ
setSection(SEC_ITEMS)
makeActionBtn("📦 Предметы (окно)", 1, 5, Color3.fromRGB(60, 105, 150), function()
	openItemsWindow()
end)

setSection(SEC_ITEMS)
makeToggle("autoclick", "Auto Click (Tool)", 0, 0, false, function(v)
	State.AutoClick = v
	setStatus("Auto Click " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_ITEMS)
makeToggle("autoeq", "Авто-экипировка предмета", 0, 0, false, function(v)
	State.AutoEquipNearest = v
	setStatus("Авто-экипировка " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_ITEMS)
makeToggle("clickdelete", "Click Delete (Ctrl+ЛКМ)", 0, 0, false, function(v)
	State.ClickDelete = v
	setStatus(v and "Click Delete: Ctrl + ЛКМ (локально)" or "Click Delete OFF", false)
end)

setSection(SEC_ITEMS)
makeActionBtn("Undo Delete", 0, 0, Color3.fromRGB(110, 70, 85), undoDelete)

setSection(SEC_ITEMS)
makeActionBtn("Убрать предметы из рук", 0, 0, Color3.fromRGB(72, 70, 98), function()
	local _, hum = getChar()
	if hum then
		hum:UnequipTools()
		setStatus("Предметы убраны в рюкзак", false)
	end
end)

-- КАМЕРА
setSection(SEC_CAM)
makeToggle("zoom", "Zoom Unlock", 0, 14, false, function(v)
	State.ZoomUnlock = v
	setStatus("Zoom Unlock " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CAM)
makeToggle("camwalls", "Камера сквозь стены", 0, 0, false, function(v)
	applyCamWalls(v)
	setStatus("Камера сквозь стены " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_CAM)
makeToggle("spectate", "Spectate (выбранный)", 0, 18, false, function(v)
	if v then
		if selectedPlayer then
			State.SpectateTarget = selectedPlayer
			setStatus("Слежка за " .. selectedPlayer.DisplayName, false)
		else
			if toggleSetters.spectate then toggleSetters.spectate(false) end
			setStatus("Выбери игрока слева", true)
		end
	else
		State.SpectateTarget = nil
		setStatus("Слежка выключена", false)
	end
end)

setSection(SEC_CAM)
makeActionBtn("Сброс камеры", 0, 0, Color3.fromRGB(85, 64, 105), function()
	local _, hum = getChar()
	State.SpectateTarget = nil
	if toggleSetters.spectate then toggleSetters.spectate(false) end
	Camera.CameraType = Enum.CameraType.Custom
	if hum then Camera.CameraSubject = hum end
	setStatus("Камера сброшена", false)
end)

-- СЕРВЕР И УТИЛИТЫ
setSection(SEC_SRV)
makeToggle("antiafk", "Anti-AFK", 0, 13, false, function(v)
	State.AntiAFK = v
	setStatus("Anti-AFK " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_SRV)
makeToggle("autorejoin", "Auto Rejoin (при кике)", 0, 0, false, function(v)
	State.AutoRejoin = v
	setStatus("Auto Rejoin " .. (v and "ON" or "OFF"), false)
end)

setSection(SEC_SRV)
makeActionBtn("Rejoin Server", 0, 19, Color3.fromRGB(52, 92, 85), function()
	setStatus("Перезаход...", false)
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

setSection(SEC_SRV)
makeActionBtn("Server Hop", 1, 19, Color3.fromRGB(52, 92, 85), function()
	setStatus("Поиск другого сервера...", false)
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

setSection(SEC_SRV)
makeActionBtn("Копировать PlaceId/JobId", 0, 0, Color3.fromRGB(70, 80, 110), function()
	local text = "PlaceId: " .. game.PlaceId .. " | JobId: " .. game.JobId
	setStatus(copyText(text) and "ID скопированы" or text, false)
end)

setSection(SEC_SRV)
makeActionBtn("Инфо о сервере", 0, 0, Color3.fromRGB(52, 92, 85), function()
	setStatus(string.format("Игроков: %d/%d | PlaceId: %d", #Players:GetPlayers(), Players.MaxPlayers, game.PlaceId), false)
end)

-- Верхний ряд: «TP к игроку»
local TPTopBtn = Instance.new("TextButton")
TPTopBtn.Name = "TPToPlayerButton"
TPTopBtn.Size = UDim2.new(0, 197 * 2 + 6, 0, 48)
TPTopBtn.Position = UDim2.new(0, 262, 0, 114)
TPTopBtn.BackgroundTransparency = 1
TPTopBtn.AutoButtonColor = false
TPTopBtn.Text = ""
TPTopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPTopBtn.Font = Enum.Font.GothamBold
TPTopBtn.TextSize = 14
TPTopBtn.Parent = MainFrame
Instance.new("UICorner", TPTopBtn).CornerRadius = UDim.new(0, 10)
local TPTopBg = Instance.new("Frame")
TPTopBg.Size = UDim2.new(1, 0, 1, 0)
TPTopBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TPTopBg.BorderSizePixel = 0
TPTopBg.Parent = TPTopBtn
round(TPTopBg, 10)
local TPTopGrad = newGradient(TPTopBg, 20)

local TPTopLabel = Instance.new("TextLabel")
TPTopLabel.Size = UDim2.new(1, -16, 1, 0)
TPTopLabel.Position = UDim2.new(0, 8, 0, 0)
TPTopLabel.BackgroundTransparency = 1
TPTopLabel.ZIndex = 3
TPTopLabel.Text = "⚡  TP к выбранному игроку"
TPTopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TPTopLabel.TextStrokeColor3 = Color3.fromRGB(20, 10, 60)
TPTopLabel.TextStrokeTransparency = 0.55
TPTopLabel.Font = Enum.Font.GothamBold
TPTopLabel.TextSize = 14
TPTopLabel.TextWrapped = true
TPTopLabel.Parent = TPTopBtn
local TPTopStroke = newStroke(TPTopBtn, Color3.fromRGB(255, 255, 255), 1.5, 0.7)
TPTopBtn.MouseEnter:Connect(function()
	tw(TPTopStroke, 0.15, { Transparency = 0.1 })
end)
TPTopBtn.MouseLeave:Connect(function()
	tw(TPTopStroke, 0.15, { Transparency = 0.7 })
end)

local function layoutMods()
	local width = ModsScroll.AbsoluteSize.X
	if width <= 0 then return end
	local usable = width - 16
	local cols = math.max(1, math.floor((usable + 6) / (190 + 6)))
	local cellW = math.floor((usable - (cols - 1) * 6) / cols)
	for _, g in ipairs(SectionGrids) do
		g.CellSize = UDim2.new(0, cellW, 0, State.Mobile and 36 or 30)
	end
	if State.Mobile then return end

	local twoCells = cellW * 2 + 6
	TPTopBtn.Size = UDim2.new(0, twoCells, 0, 48)
	SliderCard.Position = UDim2.new(0, 262 + twoCells + 12, 0, 114)
	SliderCard.Size = UDim2.new(1, -(262 + twoCells + 12 + 12), 0, 48)
end

addConn(ModsScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutMods))
task.defer(layoutMods)

addConn(TPTopBtn.MouseButton1Click:Connect(function()
	TPTopBg.BackgroundTransparency = 0.55
	tw(TPTopBg, 0.45, { BackgroundTransparency = 0 })
	if not selectedPlayer then
		setStatus("Выбери игрока слева", true)
		return
	end
	local ok, msg = teleportToPlayer(selectedPlayer.Name)
	setStatus(msg, not ok)
end))

-- Нижние поля Speed / Jump / Dist / FOV
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0, 120, 0, 30)
SpeedBox.Position = UDim2.new(0, 262, 1, -96)
SpeedBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
SpeedBox.PlaceholderText = "Speed (16)"
SpeedBox.Text = ""
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 11
SpeedBox.Parent = MainFrame
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 6)

local JumpBox = Instance.new("TextBox")
JumpBox.Size = UDim2.new(0, 120, 0, 30)
JumpBox.Position = UDim2.new(0, 392, 1, -96)
JumpBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
JumpBox.PlaceholderText = "Jump (50)"
JumpBox.Text = ""
JumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBox.Font = Enum.Font.Gotham
JumpBox.TextSize = 11
JumpBox.Parent = MainFrame
Instance.new("UICorner", JumpBox).CornerRadius = UDim.new(0, 6)

local DistBox = Instance.new("TextBox")
DistBox.Size = UDim2.new(0, 120, 0, 30)
DistBox.Position = UDim2.new(0, 522, 1, -96)
DistBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
DistBox.PlaceholderText = "Dist (1000)"
DistBox.Text = ""
DistBox.TextColor3 = Color3.fromRGB(255, 255, 255)
DistBox.Font = Enum.Font.Gotham
DistBox.TextSize = 11
DistBox.Parent = MainFrame
Instance.new("UICorner", DistBox).CornerRadius = UDim.new(0, 6)

local FOVBox = Instance.new("TextBox")
FOVBox.Size = UDim2.new(0, 120, 0, 30)
FOVBox.Position = UDim2.new(0, 652, 1, -96)
FOVBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
FOVBox.PlaceholderText = "FOV (70)"
FOVBox.Text = ""
FOVBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVBox.Font = Enum.Font.Gotham
FOVBox.TextSize = 11
FOVBox.Parent = MainFrame
Instance.new("UICorner", FOVBox).CornerRadius = UDim.new(0, 6)

local ResetStatsBtn = Instance.new("TextButton")
ResetStatsBtn.Size = UDim2.new(0, 116, 0, 30)
ResetStatsBtn.Position = UDim2.new(0, 782, 1, -96)
ResetStatsBtn.BackgroundColor3 = Color3.fromRGB(58, 68, 95)
ResetStatsBtn.Text = "Сброс статов"
ResetStatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetStatsBtn.Font = Enum.Font.GothamBold
ResetStatsBtn.TextSize = 11
ResetStatsBtn.Parent = MainFrame
Instance.new("UICorner", ResetStatsBtn).CornerRadius = UDim.new(0, 6)

local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, -24, 0, 50)
HintLabel.Position = UDim2.new(0, 12, 1, -58)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Команды: tp <имя> | items | bhop | drift | smooth | strafe | esp | hitbox | hp | fps | fly | god | noclip | xray | spin\nКлик по игроку слева — выбор, кнопка «⚡ TP к выбранному игроку» вверху — телепорт. Alt + ЛКМ (при Click TP) — TP в точку. [V] — AirWalk.\n[K] — скрыть/открыть окно (мышь вернётся в исходное состояние). [✕] — полная выгрузка."
HintLabel.TextColor3 = Color3.fromRGB(150, 158, 178)
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextSize = 11
HintLabel.Parent = MainFrame

for _, box in ipairs({ SpeedBox, JumpBox, DistBox, FOVBox }) do
	styleBox(box)
end
ResetStatsBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 62)
ResetStatsBtn.AutoButtonColor = false
newStroke(ResetStatsBtn, Theme.Accent, 1, 0.45)
addHover(ResetStatsBtn, Color3.fromRGB(40, 30, 62), Color3.fromRGB(72, 52, 130))

-- ================= АДАПТАЦИЯ ПОД ТЕЛЕФОНЫ =================
if State.Mobile then
xpcall(function()
	local TOUCH = Enum.UserInputType.Touch
	local MouseBtn = Enum.UserInputType.MouseButton1

	-- 1) Окно: подгоняется под экран и пересчитывается при повороте телефона
	local ToolsSec

	local function applyLayout()
		local v = Camera.ViewportSize
		local inset = GuiService:GetGuiInset()
		local W = math.clamp(v.X - 16, 300, 1000)
		local H = math.clamp(v.Y - inset.Y - 12, 220, 760)
		WIN_W, WIN_H = W, H
		OPEN_SIZE = UDim2.new(0, W, 0, H)
		OPEN_POS = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
		CLOSED_SIZE = UDim2.new(0, W, 0, 0)
		CLOSED_POS = UDim2.new(0.5, -W / 2, 0.5, 0)
		if State.IsOpen and not State.IsAnimating then
			MainFrame.Size = OPEN_SIZE
			MainFrame.Position = OPEN_POS
		end

		local compact = W < 520
		local LW = compact and 112 or math.clamp(math.floor(W * 0.2), 130, 170)
		local x0 = LW + 16

		-- шапка
		Header.Size = UDim2.new(1, 0, 0, 36)
		TitleLabel.Text = compact and "✦ PLAYER HUB" or "✦ PLAYER HUB ULTRA"
		TitleLabel.TextSize = 14
		TitleLabel.Size = UDim2.new(1, -150, 0, 22)
		TitleLabel.Position = UDim2.new(0, 10, 0, 7)
		SubLabel.Visible = false
		HideBtn.Text = "Скрыть"
		HideBtn.Size = UDim2.new(0, 78, 0, 28)
		HideBtn.Position = UDim2.new(1, -128, 0, 4)
		CloseBtn.Size = UDim2.new(0, 40, 0, 28)
		CloseBtn.Position = UDim2.new(1, -46, 0, 4)

		-- команды и статус
		CmdBox.PlaceholderText = "Команда: tp <имя>, god, noclip, bhop, fly…"
		CmdBox.Position = UDim2.new(0, 8, 0, 40)
		CmdBox.Size = UDim2.new(1, -16, 0, 28)
		CmdBox.TextSize = 12
		StatusLabel.Position = UDim2.new(0, 10, 0, 70)
		StatusLabel.Size = UDim2.new(1, -20, 0, 16)
		StatusLabel.TextSize = 10
		StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd

		-- левая колонка: игроки + карточка создателей
		PlayersTitle.Position = UDim2.new(0, 10, 0, 90)
		PlayersTitle.Size = UDim2.new(0, LW, 0, 16)
		PlayersTitle.TextSize = 10
		PlayersList.Position = UDim2.new(0, 8, 0, 108)
		PlayersList.Size = UDim2.new(0, LW, 1, -(108 + 52))
		PlayersList.ScrollBarThickness = 3

		CreatorCard.Size = UDim2.new(0, LW, 0, 40)
		CreatorCard.Position = UDim2.new(0, 8, 1, -46)
		CreatorAccentBar.Size = UDim2.new(0, 3, 1, -12)
		CreatorAccentBar.Position = UDim2.new(0, 7, 0, 6)
		CreatorTag.Size = UDim2.new(1, -22, 0, 13)
		CreatorTag.Position = UDim2.new(0, 16, 0, 3)
		CreatorTag.TextSize = 9
		CreatorNames.Size = UDim2.new(1, -22, 0, 20)
		CreatorNames.Position = UDim2.new(0, 16, 0, 16)
		CreatorNames.TextSize = 11

		-- правая колонка: одна прокручиваемая лента
		ModsScroll.Position = UDim2.new(0, x0, 0, 90)
		ModsScroll.Size = UDim2.new(1, -(x0 + 8), 1, -96)
		ModsScroll.ScrollBarThickness = 3

		layoutMods()
	end

	-- 2) Верхние блоки (TP, слайдер, поля, подсказки) переезжают внутрь прокрутки
	ToolsSec = Instance.new("Frame")
	ToolsSec.Name = "MobileTools"
	ToolsSec.LayoutOrder = 0
	ToolsSec.Size = UDim2.new(1, -8, 0, 0)
	ToolsSec.AutomaticSize = Enum.AutomaticSize.Y
	ToolsSec.BackgroundTransparency = 1
	ToolsSec.Parent = ModsScroll
	do
		local tl = Instance.new("UIListLayout")
		tl.Padding = UDim.new(0, 6)
		tl.SortOrder = Enum.SortOrder.LayoutOrder
		tl.Parent = ToolsSec
	end

	TPTopBtn.Parent = ToolsSec
	TPTopBtn.LayoutOrder = 1
	TPTopBtn.Size = UDim2.new(1, 0, 0, 42)
	TPTopLabel.TextSize = 13

	SliderCard.Parent = ToolsSec
	SliderCard.LayoutOrder = 2
	SliderCard.Size = UDim2.new(1, 0, 0, 62)
	SliderLabel.Size = UDim2.new(1, -136, 0, 18)
	SliderLabel.TextTruncate = Enum.TextTruncate.AtEnd
	ResetHitboxBtn.Size = UDim2.new(0, 120, 0, 24)
	ResetHitboxBtn.Position = UDim2.new(1, -126, 0, 3)
	SliderTrack.Position = UDim2.new(0, 14, 0, 38)
	SliderTrack.Size = UDim2.new(1, -28, 0, 16)
	updateHitboxSliderUI(State.HitboxScale)

	local stats = Instance.new("Frame")
	stats.Name = "MobileStats"
	stats.LayoutOrder = 3
	stats.Size = UDim2.new(1, 0, 0, 0)
	stats.AutomaticSize = Enum.AutomaticSize.Y
	stats.BackgroundTransparency = 1
	stats.Parent = ToolsSec
	do
		local sg = Instance.new("UIGridLayout")
		sg.CellSize = UDim2.new(0.5, -4, 0, 36)
		sg.CellPadding = UDim2.new(0, 8, 0, 6)
		sg.SortOrder = Enum.SortOrder.LayoutOrder
		sg.Parent = stats
	end
	for i, o in ipairs({ SpeedBox, JumpBox, DistBox, FOVBox, ResetStatsBtn }) do
		o.LayoutOrder = i
		o.TextSize = 12
		o.Parent = stats
	end

	HintLabel.Parent = ToolsSec
	HintLabel.LayoutOrder = 4
	HintLabel.Size = UDim2.new(1, 0, 0, 0)
	HintLabel.AutomaticSize = Enum.AutomaticSize.Y
	HintLabel.TextWrapped = true
	HintLabel.TextYAlignment = Enum.TextYAlignment.Top
	HintLabel.TextSize = 11
	HintLabel.Text = "• Нажми ✦ вверху экрана (или «Скрыть») — спрятать / показать меню.\n"
		.. "• Выбери игрока слева, затем «⚡ TP к выбранному игроку».\n"
		.. "• Bhop: включи Bhop и держи кнопку BHOP справа внизу (или обычный прыжок).\n"
		.. "• Fly: джойстик + кнопки ▲ ▼. AirWalk: кнопка ✈ на экране.\n"
		.. "• Click TP / Click Delete: закрой меню и просто тапни по точке в мире.\n"
		.. "• Команды вводятся в строке сверху. [✕] — полная выгрузка."

	MainFrame.Draggable = false

	ShowPill.Size = UDim2.new(0, 72, 0, 32)
	ShowPill.Position = UDim2.new(0.5, 0, 0, 6)
	ShowPill.BackgroundTransparency = 0.12
	ShowPill.TextTransparency = 0
	ShowPill.TextSize = 18

	applyLayout()
	addConn(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout))

	-- 3) Кнопки управления на экране (показываются, когда меню закрыто)
	local ctrl = Instance.new("Frame")
	ctrl.Name = "HubMobileControls"
	ctrl.BackgroundTransparency = 1
	ctrl.Size = UDim2.new(1, 0, 1, 0)
	ctrl.ZIndex = 20
	ctrl.Parent = ScreenGui

	local function mkBtn(text, pos, size)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 1)
		b.Size = UDim2.new(0, size, 0, size)
		b.Position = pos
		b.BackgroundColor3 = Theme.Card
		b.BackgroundTransparency = 0.2
		b.AutoButtonColor = false
		b.Text = text
		b.TextColor3 = Theme.Text
		b.Font = Enum.Font.GothamBlack
		b.TextSize = 14
		b.ZIndex = 21
		b.Visible = false
		b.Parent = ctrl
		round(b, math.floor(size / 2))
		newStroke(b, Theme.Accent2, 1.5, 0.25)
		return b
	end

	local bhopBtn = mkBtn("BHOP", UDim2.new(1, -130, 1, -30), 66)
	local upBtn = mkBtn("▲", UDim2.new(1, -130, 1, -102), 54)
	local downBtn = mkBtn("▼", UDim2.new(1, -204, 1, -30), 54)
	local airBtn = mkBtn("✈", UDim2.new(1, -24, 1, -128), 54)

	local held = {}
	local function bindHold(btn, key)
		addConn(btn.InputBegan:Connect(function(input)
			if input.UserInputType == TOUCH or input.UserInputType == MouseBtn then
				State[key] = true
				held[key] = input
			end
		end))
	end
	bindHold(bhopBtn, "MobJump")
	bindHold(upBtn, "MobUp")
	bindHold(downBtn, "MobDown")
	addConn(UserInputService.InputEnded:Connect(function(input)
		for key, inp in pairs(held) do
			if inp == input then
				held[key] = nil
				State[key] = false
			end
		end
	end))
	addConn(airBtn.Activated:Connect(function()
		State.MobAirWalk = not State.MobAirWalk
	end))

	addConn(RunService.RenderStepped:Connect(function()
		if State.Destroyed then return end
		local show = not State.IsOpen
		bhopBtn.Visible = show and State.Bhop
		upBtn.Visible = show and State.Fly
		downBtn.Visible = show and State.Fly
		airBtn.Visible = show and State.AirWalk
		if not bhopBtn.Visible then State.MobJump = false end
		if not upBtn.Visible then State.MobUp = false end
		if not downBtn.Visible then State.MobDown = false end
		if not airBtn.Visible then State.MobAirWalk = false end

		bhopBtn.BackgroundColor3 = State.MobJump and Theme.On or Theme.Card
		upBtn.BackgroundColor3 = State.MobUp and Theme.On or Theme.Card
		downBtn.BackgroundColor3 = State.MobDown and Theme.On or Theme.Card
		airBtn.BackgroundColor3 = State.MobAirWalk and Theme.On or Theme.Card
	end))

	-- 4) Обычная кнопка прыжка: Bhop-окно + MultiJump (вместо клавиши Space)
	addConn(UserInputService.JumpRequest:Connect(function()
		if State.Destroyed then return end
		local now = os.clock()
		Bh.scrollUntil = now + 0.22
		if State.MultiJump and not State.Fly and now - State.LastAirJump > 0.18 then
			local _, hum, root = getChar()
			if hum and root and hum.FloorMaterial == Enum.Material.Air and State.AirJumpsUsed < State.MaxAirJumps then
				State.LastAirJump = now
				State.AirJumpsUsed += 1
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				root.AssemblyLinearVelocity = Vector3.new(
					root.AssemblyLinearVelocity.X,
					State.JumpPower,
					root.AssemblyLinearVelocity.Z
				)
			end
		end
	end))

	-- 5) Click TP / Click Delete: обычный тап по миру (без Alt / Ctrl)
	addConn(UserInputService.TouchTap:Connect(function(positions, processed)
		if processed or State.Destroyed or State.IsOpen then return end
		if not (State.ClickTP or State.ClickDelete) then return end
		local p = positions[1]
		if not p then return end
		local ray = Camera:ScreenPointToRay(p.X, p.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local char = LocalPlayer.Character
		params.FilterDescendantsInstances = char and { char } or {}
		local res = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
		if not res then return end

		if State.ClickDelete then
			local target = res.Instance
			if target and not isCharacterPart(target) and target ~= AirWalkPart then
				table.insert(DeletedParts, { Part = target, Parent = target.Parent })
				target.Parent = nil
				setStatus("Удалено локально: " .. target.Name .. " (Undo Delete — отмена)", false)
				return
			end
		end
		if State.ClickTP then
			local _, _, root = getChar()
			if root then
				State.PrevPosCF = root.CFrame
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
				setStatus("Click TP выполнен", false)
			end
		end
	end))
end, function(e)
	warn("[Hub mobile] " .. tostring(e))
end)
end

local function executeCommand(raw)
	local trimmed = string.match(raw or "", "^%s*(.-)%s*$")
	if trimmed == "" then return end

	local parts = string.split(trimmed, " ")
	local cmd = string.lower(parts[1] or "")

	if cmd == "tp" then
		local targetQuery = table.concat(parts, " ", 2)
		local ok, msg = teleportToPlayer(targetQuery)
		setStatus(msg, not ok)
	elseif cmd == "esp" then
		State.ESP = not State.ESP
		if toggleSetters.esp then toggleSetters.esp(State.ESP) end
		setStatus("ESP " .. (State.ESP and "включён" or "выключен"), false)
	elseif cmd == "hitbox" or cmd == "box" then
		State.ESPBox = not State.ESPBox
		if toggleSetters.espbox then toggleSetters.espbox(State.ESPBox) end
		setStatus("Hitbox ESP " .. (State.ESPBox and "включён" or "выключен"), false)
	elseif cmd == "hp" then
		State.ESPHP = not State.ESPHP
		if toggleSetters.esphp then toggleSetters.esphp(State.ESPHP) end
		setStatus("HP Bar ESP " .. (State.ESPHP and "включён" or "выключен"), false)
	elseif cmd == "fps" or cmd == "fpsboost" then
		applyFPSBoost(not State.FPSBoost)
		if toggleSetters.fpsboost then toggleSetters.fpsboost(State.FPSBoost) end
		setStatus("FPS Boost " .. (State.FPSBoost and "включён" or "выключен"), false)
	elseif cmd == "fly" then
		setFlyState(not State.Fly)
		if toggleSetters.fly then toggleSetters.fly(State.Fly) end
		setStatus("Полёт " .. (State.Fly and "включён" or "выключен"), false)
	elseif cmd == "items" or cmd == "item" then
		openItemsWindow()
	elseif cmd == "god" then
		State.GodMode = not State.GodMode
		if toggleSetters.god then toggleSetters.god(State.GodMode) end
		setStatus("Бессмертие " .. (State.GodMode and "включено (HP на максимуме)" or "выключено"), false)
	elseif cmd == "multijump" or cmd == "mj" then
		State.MultiJump = not State.MultiJump
		State.AirJumpsUsed = 0
		if toggleSetters.multijump then toggleSetters.multijump(State.MultiJump) end
		setStatus("Мультипрыжок " .. (State.MultiJump and "включён" or "выключен"), false)
	elseif cmd == "fb" or cmd == "fullbright" then
		applyFullbright(not State.Fullbright)
		if toggleSetters.fb then toggleSetters.fb(State.Fullbright) end
		setStatus("Fullbright " .. (State.Fullbright and "включён" or "выключен"), false)
	elseif cmd == "noclip" then
		setNoClipState(not State.NoClip)
		if toggleSetters.noclip then toggleSetters.noclip(State.NoClip) end
		setStatus("NoClip " .. (State.NoClip and "включён" or "выключен"), false)
	elseif cmd == "xray" then
		applyXRay(not State.XRay)
		if toggleSetters.xray then toggleSetters.xray(State.XRay) end
		setStatus("X-Ray " .. (State.XRay and "включён" or "выключен"), false)
	elseif cmd == "spin" then
		State.Spinbot = not State.Spinbot
		if toggleSetters.spin then toggleSetters.spin(State.Spinbot) end
		setStatus("Spinbot " .. (State.Spinbot and "включён" or "выключен"), false)
	elseif cmd == "drift" then
		State.DriftEnabled = not State.DriftEnabled
		if toggleSetters.drift then toggleSetters.drift(State.DriftEnabled) end
		setStatus("Занос " .. (State.DriftEnabled and "ON" or "OFF"), false)
	elseif cmd == "smooth" then
		State.SmoothTurn = not State.SmoothTurn
		smoothYaw = nil
		if toggleSetters.smoothturn then toggleSetters.smoothturn(State.SmoothTurn) end
		setStatus("Плавный поворот " .. (State.SmoothTurn and "ON" or "OFF"), false)
	elseif cmd == "hip" then
		local _, hum = getChar()
		local n = tonumber(parts[2])
		if hum and n then
			hum.HipHeight = n
			setStatus("HipHeight = " .. n, false)
		else
			setStatus("Использование: hip <число>", true)
		end
	elseif cmd == "fpscap" then
		local n = tonumber(parts[2])
		if setfpscap and n then
			setfpscap(n)
			setStatus("FPS cap = " .. n, false)
		else
			setStatus("Использование: fpscap <число> (нужен setfpscap)", true)
		end
	elseif cmd == "time" then
		local n = tonumber(parts[2])
		if n then
			State.TimeLock = "OFF"
			Lighting.ClockTime = n
			if toggleSetters.timeBtn then toggleSetters.timeBtn() end
			setStatus("ClockTime = " .. n, false)
		else
			setStatus("Использование: time <0-24>", true)
		end
	elseif cmd == "strafe" then
		State.AutoStrafe = not State.AutoStrafe
		if toggleSetters.autostrafe then toggleSetters.autostrafe(State.AutoStrafe) end
		setStatus("Auto Strafe " .. (State.AutoStrafe and "ON" or "OFF"), false)
	elseif cmd == "bring" then
		bringPlayer(parts[2] and findPlayer(parts[2]) or selectedPlayer)
	elseif cmd == "spawn" then
		teleportToSpawn()
	elseif cmd == "autoclick" then
		State.AutoClick = not State.AutoClick
		if toggleSetters.autoclick then toggleSetters.autoclick(State.AutoClick) end
		setStatus("Auto Click " .. (State.AutoClick and "ON" or "OFF"), false)
	elseif cmd == "nofall" then
		State.NoFall = not State.NoFall
		if toggleSetters.nofall then toggleSetters.nofall(State.NoFall) end
		setStatus("No Fall Damage " .. (State.NoFall and "ON" or "OFF"), false)
	elseif cmd == "hud" then
		State.HUD = not State.HUD
		HudLabel.Visible = State.HUD
		if toggleSetters.hud then toggleSetters.hud(State.HUD) end
		setStatus("HUD " .. (State.HUD and "ON" or "OFF"), false)
	elseif cmd == "bhop" then
		State.Bhop = not State.Bhop
		Bh.hops = 0
		if toggleSetters.bhop then toggleSetters.bhop(State.Bhop) end
		setStatus("Bhop " .. (State.Bhop and "ON" or "OFF"), false)
	elseif cmd == "airaccel" then
		local n = tonumber(parts[2])
		if n and n > 0 and n <= 200 then
			State.AirAccel = n
			setStatus("Air Accel = " .. n, false)
		else
			setStatus("Использование: airaccel <1-200> (CS2 = 12)", true)
		end
	elseif cmd == "aircap" then
		local n = tonumber(parts[2])
		if n then
			State.AirCapMul = math.clamp(n, 0.5, 6)
			setStatus("Air Cap = x" .. State.AirCapMul, false)
		else
			setStatus("Использование: aircap <множитель, 1 = CS2>", true)
		end
	elseif cmd == "bhopmax" then
		local n = tonumber(parts[2])
		if n and n >= 20 and n <= 1000 then
			State.BhopMax = n
			setStatus("Лимит скорости Bhop = " .. n, false)
		else
			setStatus("Использование: bhopmax <20-1000>", true)
		end
	elseif cmd == "resethb" then
		resetAllHitboxes()
		setStatus("Хитбоксы сброшены", false)
	else
		setStatus("Неизвестная команда: " .. cmd, true)
	end
end

addConn(CmdBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		executeCommand(CmdBox.Text)
	end
end))

addConn(SpeedBox.FocusLost:Connect(function()
	local num = tonumber(SpeedBox.Text)
	if num and num > 0 then
		State.Speed = num
		setStatus("Скорость установлена: " .. num, false)
	end
end))

addConn(JumpBox.FocusLost:Connect(function()
	local num = tonumber(JumpBox.Text)
	if num and num > 0 then
		State.JumpPower = num
		setStatus("Прыжок установлен: " .. num, false)
	end
end))

addConn(DistBox.FocusLost:Connect(function()
	local num = tonumber(DistBox.Text)
	if num and num >= 50 and num <= 100000 then
		State.RenderDistance = num
		if State.FPSBoost and not State.NoFog then
			Lighting.FogStart = math.max(State.RenderDistance * 0.65, 50)
			Lighting.FogEnd = State.RenderDistance
		end
		setStatus("Дистанция рендера: " .. num .. " studs", false)
	end
end))

addConn(FOVBox.FocusLost:Connect(function()
	local num = tonumber(FOVBox.Text)
	if num and num >= 20 and num <= 120 then
		State.FOV = num
		setStatus("FOV установлен: " .. num, false)
	end
end))

addConn(ResetStatsBtn.MouseButton1Click:Connect(function()
	State.Speed = 16
	State.JumpPower = 50
	State.RenderDistance = 1000
	State.FOV = 70
	SpeedBox.Text = ""
	JumpBox.Text = ""
	DistBox.Text = ""
	FOVBox.Text = ""
	local _, hum = getChar()
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end
	Camera.FieldOfView = 70
	if State.FPSBoost and not State.NoFog then
		Lighting.FogStart = math.max(State.RenderDistance * 0.65, 50)
		Lighting.FogEnd = State.RenderDistance
	end
	setStatus("Параметры сброшены", false)
end))

addConn(LocalPlayer.Idled:Connect(function()
	if State.AntiAFK and not State.Destroyed then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.zero)
		end)
	end
end))

local function toggleWindowAnimated()
	if State.Destroyed or State.IsAnimating then return end
	State.IsAnimating = true

	local opening = not State.IsOpen
	if opening then
		captureMouseBeforeOpen()
	end

	State.IsOpen = opening
	ShowPill.Visible = not opening
	applyMouseForMenu()

	if State.IsOpen then
		MainFrame.Visible = true
		local tween = TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = OPEN_SIZE,
			Position = OPEN_POS,
		})
		tween:Play()
		tween.Completed:Connect(function()
			State.IsAnimating = false
		end)
	else
		closeItemsWindow()
		local tween = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = CLOSED_SIZE,
			Position = CLOSED_POS,
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not State.IsOpen then
				MainFrame.Visible = false
				applyMouseForMenu()
			end
			State.IsAnimating = false
		end)
	end
end

addConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if State.Destroyed or gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.K then
		toggleWindowAnimated()
		return
	end

	if input.KeyCode == Enum.KeyCode.Space and State.MultiJump and not State.Fly then
		local _, hum, root = getChar()
		if hum and root and hum.FloorMaterial == Enum.Material.Air then
			if State.AirJumpsUsed < State.MaxAirJumps then
				State.AirJumpsUsed += 1
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				root.AssemblyLinearVelocity = Vector3.new(
					root.AssemblyLinearVelocity.X,
					State.JumpPower,
					root.AssemblyLinearVelocity.Z
				)
			end
		end
	end
end))

addConn(Mouse.Button1Down:Connect(function()
	if State.Destroyed or not State.ClickTP then return end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
		local _, _, root = getChar()
		if root and Mouse.Hit then
			State.PrevPosCF = root.CFrame
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
			setStatus("Click TP выполнен", false)
		end
	end
end))

local function destroyScript()
	if State.Destroyed then return end
	State.Destroyed = true

	State.SpectateTarget = nil
	State.Frozen = false
	State.NoClip = false
	draggingSlider = false
	resetAllHitboxes()

	applyFPSBoost(false)
	setFlyState(false)
	closeItemsWindow()
	pcall(function()
		RunService:UnbindFromRenderStep("HubBhop")
		local _, h = getChar()
		Bh.holdAutoRotate(h, false)
		if h then h:Move(Vector3.zero, false) end
	end)
	resetExtras()
	applyFullbright(false)
	applyNoFog(false)
	applyNightVision(false)
	applyXRay(false)
	SoundService.Volume = 1

	if AirWalkPart then
		AirWalkPart:Destroy()
		AirWalkPart = nil
	end

	Lighting.ClockTime = OriginalLighting.ClockTime
	Lighting.FogStart = OriginalLighting.FogStart
	Lighting.FogEnd = OriginalLighting.FogEnd
	Lighting.GlobalShadows = OriginalLighting.GlobalShadows
	workspace.Gravity = OriginalGravity
	Camera.FieldOfView = 70
	LocalPlayer.CameraMaxZoomDistance = OriginalCamMaxZoom

	local _, hum, root = getChar()
	if hum then
		Camera.CameraSubject = hum
	end
	if root then
		root.Anchored = false
	end

	for _, conn in ipairs(Connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Connections)

	for plr in pairs(ESPObjects) do
		clearPlayerESP(plr)
	end

	applyMouseForMenu()

	if ScreenGui then
		ScreenGui:Destroy()
	end
	if getgenv then
		getgenv().CustomHubLoaded = false
	end
end

if getgenv then
	getgenv().CustomHubCleanup = destroyScript
end

addConn(CloseBtn.MouseButton1Click:Connect(destroyScript))
addConn(HideBtn.MouseButton1Click:Connect(toggleWindowAnimated))
addConn(ShowPill.MouseButton1Click:Connect(toggleWindowAnimated))

task.spawn(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			createPlayerESP(plr)
		end
	end
end)
refreshPlayerList()

addConn(Players.PlayerAdded:Connect(function(plr)
	createPlayerESP(plr)
	refreshPlayerList()
end))

addConn(Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then selectedPlayer = nil end
	if State.SpectateTarget == plr then
		State.SpectateTarget = nil
		if toggleSetters.spectate then toggleSetters.spectate(false) end
	end
	restorePlayerHitbox(plr)
	clearPlayerESP(plr)
	refreshPlayerList()
end))

local function updateVisuals()
	local t = os.clock()
	mainStrokeGrad.Rotation = (t * 45) % 360
	HeaderLineGrad.Offset = Vector2.new(math.sin(t * 1.2) * 0.5, 0)
	TPTopGrad.Rotation = 20 + math.sin(t * 0.9) * 30
	creatorGrad.Rotation = 35 + math.sin(t * 0.8) * 15
	local want = selectedPlayer and ("⚡  TP к игроку: " .. selectedPlayer.DisplayName) or "⚡  TP к выбранному игроку"
	if TPTopLabel.Text ~= want then
		TPTopLabel.Text = want
	end
end

addConn(RunService.RenderStepped:Connect(function(dt)
	if State.Destroyed then return end
	if State.IsOpen then
		pcall(function()
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end
	pcall(updateESP)
	pcall(updateHitboxExpand)
	pcall(updateCharacterMods, dt)
	pcall(updateFly)
	pcall(updateGlide)
	pcall(updateAirWalk)
	pcall(updateTimeLock)
	pcall(updateExtras, dt)
	if State.IsOpen then
		pcall(updateVisuals)
	end
end))

applyMouseForMenu()