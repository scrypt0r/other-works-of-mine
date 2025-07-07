if logUI_loaded then
	error("logUI is already running!", 0)
	return
end

pcall(function() getgenv().logUI_loaded = true end)

local blnEBG = false

for _, tblPlace in next, game:GetService("AssetService"):GetGamePlacesAsync():GetCurrentPage() do
	if (tblPlace.PlaceId == 566399244) then
		blnEBG = true
	end

	print(tblPlace.Name, tostring(tblPlace.PlaceId))
end

if not(blnEBG) then
	error("logUI only runs on EBG!", 0)
	return
end

if not(game:IsLoaded()) then
	local insMessage = Instance.new("Message")
	insMessage.Text = "logUI is waiting for the game to load."
	insMessage.Parent = game:GetService("CoreGui")

	game.Loaded:Wait()
end

local srvPLR = game:GetService("Players")
local srvRS = game:GetService("ReplicatedStorage")
local srvUIS = game:GetService("UserInputService")
local srvRUN = game:GetService("RunService")
local srvTween = game:GetService("TweenService")
local srvHTTP = game:GetService("HttpService")
local srvText = game:GetService("TextService")

local tblDefaultSettings = {
	["GuiSizeMultiplier"] = 1,
	["OpenCloseGuiKey"] = Enum.KeyCode.RightBracket.Name,
	["DisableGuiKey"] = Enum.KeyCode.LeftBracket.Name,
	["BarKey"] = Enum.KeyCode.BackSlash.Name,
	["BarEnabledWhileClosed"] = false,
	["ESPKey"] = Enum.KeyCode.B.Name,
	["ESPOnStartup"] = true,
	["ESPLocal"] = false,
	["ESPColorMode"] = "Health",
	["ESPHealth"] = true,
	["ESPMana"] = false,
	["ESPStamina"] = false,
	["SpeedhackKey"] = nil,
	["EnhancePunchesOnStartup"] = true,
	["FreezeKey"] = nil,
	["FloatKey"] = nil,
	["ClickTPKey"] = nil,
	["IBMKey"] = nil,
	["ViewTargetKey"] = Enum.KeyCode.V.Name,
	["TeleportToTargetKey"] = nil,
	["LaunchKey"] = nil,
	["LegitOnStartup"] = true,
	["MainColor"] = {0, 0, 17/255},
	["BarColor"] = {0, 0, 12/255},
	["TextColor"] = {0, 0, 1},
	["TextColor2"] = {0, 0, 0.5},
	["BoxColor"] = {0, 0, 38/255},
	["InnerBoxColor"] = {0, 0, 34/255}
}

local tblSettings = {}

local blnSaveCooldown = false
local voidSaveSettings = writefile and function()
	if blnSaveCooldown then repeat wait() until not(blnSaveCooldown) end
	blnSaveCooldown = true

	writefile("logUISettings.json", srvHTTP:JSONEncode(tblSettings))

	wait(3)
	blnSaveCooldown = false
end or function() end

if pcall(function() readfile("logUISettings.json") end) and not(readfile("logUISettings.json") == nil) then
	if pcall(function()
			tblSettings = srvHTTP:JSONDecode(readfile("logUISettings.json"))

			for strSetting, varValue in next, tblDefaultSettings do
				if not(tblSettings[strSetting]) then
					tblSettings[strSetting] = varValue
				end
			end
		end) then 
	else
		warn("Failure to load data! Creating a new file.")

		tblSettings = tblDefaultSettings
		voidSaveSettings()
	end
else
	tblSettings = tblDefaultSettings
	voidSaveSettings()
end

local blnOpen = true
local blnOutputting = true
local tblBarHistory = {}
local numBarIndex = 0
local strSavedText = ""
local blnBinding = false
local blnSwitchingTabs = false

local blnESPActive = tblSettings.ESPOnStartup
local blnSpeedhackActive = false
local numSpeed = 64
local blnEnhancePunchesActive = tblSettings.EnhancePunchesOnStartup
local blnFloatActive = false
local numFloatForce = 5000
local blnIBMActive = false
local blnStunActive = true
local numLaunchPower = 250

local insLPLR = srvPLR.LocalPlayer
local insTargetPLR = insLPLR
local tblPlayerData = {}

local tblGetConnections = getconnections or get_signal_cons

if tblGetConnections then
	for _, cncConnection in next, tblGetConnections(insLPLR.Idled) do
		if cncConnection["Disable"] then
			cncConnection["Disable"]()
		elseif cncConnection["Disconnect"] then
			cncConnection["Disconnect"]()
		end
	end
else
	warn("The user's exploit does not support the getconnections function, the ;stun command will not function correctly!")
end

local insESPFolder = Instance.new("Folder")
insESPFolder.Name = "ESP"
insESPFolder.Parent = srvRUN:IsStudio() and insLPLR:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local tblUpdateESPfuncs = {}

local insBox2 = Instance.new("BoxHandleAdornment")
insBox2.Name = "nilBox"
insBox2.Size = Vector3.new(4, 7, 4)
insBox2.Color3 = Color3.new(100 / 255, 100 / 255, 100 / 255)
insBox2.Transparency = 0.7
insBox2.ZIndex = 0
insBox2.AlwaysOnTop = true
insBox2.Visible = true

local insNameTag = Instance.new("BillboardGui")
insNameTag.Name = "nilNameTag"
insNameTag.Enabled = true
insNameTag.Size = UDim2.new(0, 200, 0, 50)
insNameTag.AlwaysOnTop = true
insNameTag.StudsOffset = Vector3.new(0, 3.6, 0)

local insTag = Instance.new("TextLabel", insNameTag)
insTag.Name = "Tag"
insTag.BackgroundTransparency = 1
insTag.Position = UDim2.new(0, -50, 0, 0)
insTag.Size = UDim2.new(0, 300, 0, 20)
insTag.TextSize = 20
insTag.TextColor3 = Color3.new(100 / 255, 100 / 255, 100 / 255)
insTag.TextStrokeColor3 = Color3.new(0 / 255, 0 / 255, 0 / 255)
insTag.TextStrokeTransparency = 0.4
insTag.Text = "nil"
insTag.Font = Enum.Font.SourceSansSemibold
insTag.TextScaled = false
insTag.TextTransparency = 0

local function voidUnloadCharacter(insPLR)
	local insPlayerFolder = insESPFolder:FindFirstChild(insPLR.Name)

	if insPlayerFolder then
		insPlayerFolder:ClearAllChildren()
	end
end

local function voidLoadCharacter(insPLR)
	if tblSettings.ESPLocal or not(insPLR == game.Players.LocalPlayer) then
		while not(insPLR.Character) do srvRUN.RenderStepped:Wait() end
		insPLR.Character:WaitForChild("Humanoid")

		local insPlayerFolder = insESPFolder:FindFirstChild(insPLR.Name)
		insPlayerFolder:ClearAllChildren()

		local insPlayerBox = insBox2:Clone()
		insPlayerBox.Name = insPLR.Name .. "Box"
		insPlayerBox.Adornee = insPLR.Character.HumanoidRootPart
		insPlayerBox.Parent = insPlayerFolder

		local insPlayerTag = insNameTag:Clone()
		insPlayerTag.Name = insPLR.Name .. "NameTag"
		insPlayerTag.Parent = insPlayerFolder
		insPlayerTag.Adornee = insPLR.Character:WaitForChild("HumanoidRootPart", 5)

		if not insPlayerTag.Adornee then
			return voidUnloadCharacter(insPLR)
		end

		insPlayerTag.Tag.Text = insPLR.Name
		insPlayerTag.Enabled = true

		srvRUN.RenderStepped:Wait()

		local function voidUpdateNameTag()
			--if not pcall(function()
			local numMaxHealth = math.ceil(insPLR.Character.Humanoid.MaxHealth * 10)
			local numHealth = math.ceil(insPLR.Character.Humanoid.Health * 10)
			local strHealth = "H: " .. (not(numMaxHealth == 0) and tostring(math.ceil(100 * numHealth / numMaxHealth)) or 0) .. "% [" .. tostring(numHealth) .. "|" .. tostring(numMaxHealth) .. "]"

			local numMaxMana = tblPlayerData[insPLR] and math.ceil(tblPlayerData[insPLR].MaxMana * 10) or 1000
			local numMana = tblPlayerData[insPLR] and math.ceil(tblPlayerData[insPLR].Mana * 10) or 1000
			local strMana = "M: " .. (not(numMaxMana == 0) and tostring(math.ceil(100 * numMana / numMaxMana)) or 0) .. "% [" .. tostring(numMana) .. "|" .. tostring(numMaxMana) .. "]"

			local numMaxStamina = tblPlayerData[insPLR] and math.ceil(tblPlayerData[insPLR].MaxStamina * 10) or 1000
			local numStamina = tblPlayerData[insPLR] and math.ceil(tblPlayerData[insPLR].Stamina * 10) or 1000
			local strStamina = "S: " .. (not(numMaxStamina == 0) and tostring(math.ceil(100 * numStamina / numMaxStamina)) or 0) .. "% [" .. tostring(numStamina) .. "|" .. tostring(numMaxStamina) .. "]"

			insPlayerTag.Tag.Text = insPLR.Name .. (tblSettings.ESPHealth and ("\n" .. strHealth) or "") .. (tblSettings.ESPMana and ("\n" .. strMana) or "") .. (tblSettings.ESPStamina and ("\n" .. strStamina) or "")

			if blnESPActive then
				insPlayerTag.Tag.TextTransparency = 0
				insPlayerBox.Transparency = 0.7

				if (tblSettings.ESPColorMode == "Health") then
					if (numHealth / numMaxHealth == 1) then
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(255, 255, 255)
						insPlayerBox.Color3 = Color3.fromRGB(255, 255, 255)
					elseif (numHealth / numMaxHealth == 0) then
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(0, 0, 0)
						insPlayerBox.Color3 = Color3.fromRGB(0, 0, 0)
					else
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(191, 191 * (numHealth / numMaxHealth), 191 * (numHealth / numMaxHealth))
						insPlayerBox.Color3 = Color3.fromRGB(191, 191 * (numHealth / numMaxHealth), 191 * (numHealth / numMaxHealth))
					end
				elseif (tblSettings.ESPColorMode == "Mana") then
					if (numHealth / numMaxHealth == 0) then
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(0, 0, 0)
						insPlayerBox.Color3 = Color3.fromRGB(0, 0, 0)
					else
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(0, 31 + (96 * math.min(numMana / 450, 1)), 63 + (192 * math.min(numMana / 450, 1)))
						insPlayerBox.Color3 = Color3.fromRGB(0, 31 + (96 * math.min(numMana / 450, 1)), 63 + (192 * math.min(numMana / 450, 1)))
					end
				elseif (tblSettings.ESPColorMode == "Stamina") then
					if (numHealth / numMaxHealth == 0) then
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(0, 0, 0)
						insPlayerBox.Color3 = Color3.fromRGB(0, 0, 0)
					else
						insPlayerTag.Tag.TextColor3 = Color3.fromRGB(63 + (192 * (numStamina / numMaxStamina)), 31 + (96 * (numStamina / numMaxStamina)), 0)
						insPlayerBox.Color3 = Color3.fromRGB(63 + (192 * (numStamina / numMaxStamina)), 31 + (96 * (numStamina / numMaxStamina)), 0)
					end
				end

				local _, _, numValue = insPlayerTag.Tag.TextColor3:ToHSV()

				if (numValue < 1/4) then
					insPlayerTag.Tag.TextStrokeColor3 = Color3.new(1, 1, 1)
				else
					insPlayerTag.Tag.TextStrokeColor3 = Color3.new()
				end
			else
				insPlayerTag.Tag.TextTransparency = 1
				insPlayerBox.Transparency = 1
			end
			--end) then
			--tblUpdateESPfuncs[insPLR] = nil
			--end
		end

		voidUpdateNameTag()

		tblUpdateESPfuncs[insPLR] = voidUpdateNameTag
	end
end

local function voidLoadPlayer(insPLR)
	if tblSettings.ESPLocal or not(insPLR == game.Players.LocalPlayer) then
		local insPlayerFolder = Instance.new("Folder")
		insPlayerFolder.Name = insPLR.Name
		insPlayerFolder.Parent = insESPFolder

		insPLR.CharacterAdded:Connect(function()
			if (blnESPActive == true) then
				pcall(voidLoadCharacter, insPLR)
			end
		end)

		insPLR.CharacterRemoving:Connect(function()
			pcall(voidUnloadCharacter, insPLR)
		end)

		voidLoadCharacter(insPLR)
	end
end

local function voidUnloadPlayer(insPLR)
	voidUnloadCharacter(insPLR)

	local insPlayerFolder = insESPFolder:FindFirstChild(insPLR.Name)

	if insPlayerFolder then
		insPlayerFolder:Destroy()
	end
end

for _, insPLR in next, srvPLR:GetPlayers() do
	spawn(function() pcall(voidLoadPlayer, insPLR) end)
end

srvPLR.PlayerAdded:Connect(function(insPLR)
	pcall(voidLoadPlayer, insPLR)

	insPLR.Changed:Connect(function()
		if insESPFolder:FindFirstChild(insPLR.Name) then
			voidUnloadCharacter(insPLR)

			srvRUN.RenderStepped:Wait()

			voidLoadCharacter(insPLR)
		end
	end)
end)

srvPLR.PlayerRemoving:Connect(function(insPLR)
	pcall(voidUnloadPlayer, insPLR)
end)

srvRUN:BindToRenderStep("UpdateESP", Enum.RenderPriority.Camera.Value, function()
	if blnESPActive then
		for _, insPLR in next, srvPLR:GetPlayers() do
			if insESPFolder:FindFirstChild(insPLR.Name) then
				pcall(function() tblUpdateESPfuncs[insPLR]() end)
			end
		end
	end
end)

local objMouse = insLPLR:GetMouse()
local insLCHR = insLPLR.Character or insLPLR.CharacterAdded:Wait()
local insLHRP = insLCHR:WaitForChild("HumanoidRootPart")
local insLHUM = insLCHR:WaitForChild("Humanoid")

insLCHR.DescendantAdded:Connect(function(insChild)
	if blnIBMActive and insChild:IsA("BodyMover") and not(insChild.Name == "Float") and not(insChild.Name == "Thrust") then
		srvRUN.RenderStepped:Wait()
		insChild:Destroy()
	end
end)

insLHUM.Changed:Connect(function()
	if blnSpeedhackActive then
		insLHUM.WalkSpeed = numSpeed
	end
end)

local insLANI = insLHUM:WaitForChild("Animator")
local tblAnims = {}

local function voidLoadAnims()
	while true do
		if pcall(function()
				for _, insAnimFolder in next, srvRS:WaitForChild("Animations" .. ((insLHUM.RigType == Enum.HumanoidRigType.R6) and "_R6")):GetChildren() do
					local numPriority = tonumber(insAnimFolder.Name)

					for _, insAnimation in next, insAnimFolder:GetChildren() do
						if insAnimation:IsA("Animation") then
							local insAnimTrack = insLHUM:LoadAnimation(insAnimation)
							insAnimTrack.Priority = numPriority
							tblAnims[insAnimation.Name] = {
								["Priority"] = numPriority,
								["Playing"] = false,
								insAnimTrack
							}
						else
							local tblAnimData = {
								["Mode"] = 1,
								["Priority"] = numPriority,
								["Playing"] = false
							}

							for _, insAnimation2 in next, insAnimation:GetChildren() do
								if (insAnimation2.AnimationId == "") then
									tblAnimData[tonumber(insAnimation2.Name)] = ""
								else
									local insAnimTrack = insLHUM:LoadAnimation(insAnimation2)
									insAnimTrack.Priority = numPriority
									tblAnimData[tonumber(insAnimation2.Name)] = insAnimTrack
								end
							end

							tblAnims[insAnimation.Name] = tblAnimData
						end
					end
				end
			end) 
		then break end

		srvRUN.RenderStepped:Wait()
	end
end

voidLoadAnims()

local function voidPlayAnim(strName, numFadeTime, numWeight, numSpeed)
	local tblAnimData = tblAnims[strName]

	if not(tblAnimData) then return end

	tblAnimData.Playing = true

	local numAnimTrackIndex = tblAnimData.Mode and 1 
	if not(tblAnimData[numAnimTrackIndex] == "") then
		tblAnimData[1]:Play(numFadeTime, numWeight, numSpeed)
	end
end

local function voidStopAnim(strName, numFadeTime)
	local tblAnimData = tblAnims[strName]

	if tblAnimData and tblAnimData.Playing then
		tblAnimData.Playing = false

		local numAnimTrackIndex = tblAnimData.Mode and 1
		if not(tblAnimData[numAnimTrackIndex] == "") then
			tblAnimData[1]:Stop(numFadeTime)
		end
	end
end

insLPLR.CharacterAdded:Connect(function(insCHR)
	insLCHR = insCHR
	insLHRP = insLCHR:WaitForChild("HumanoidRootPart")
	insLHUM = insLCHR:WaitForChild("Humanoid")

	insLCHR.DescendantAdded:Connect(function(insChild)
		if blnIBMActive and insChild:IsA("BodyMover") and not(insChild.Name == "Float") and not(insChild.Name == "Launch") then
			srvRUN.RenderStepped:Wait()
			insChild:Destroy()
		end
	end)

	insLHUM.Changed:Connect(function()
		if blnSpeedhackActive then
			insLHUM.WalkSpeed = numSpeed
		end
	end)

	insLANI = insLHUM:WaitForChild("Animator")

	voidLoadAnims()
end)

local insLCAM = workspace.CurrentCamera

local insIgnore = workspace:WaitForChild(".Ignore")
local insLocalFX = insIgnore:WaitForChild(".LocalEffects")
local insServerFX = insIgnore:WaitForChild(".ServerEffects")
local insAttacks = insIgnore:WaitForChild(".Attacks")

local insRSR = srvRS:WaitForChild("Remotes")

insRSR:WaitForChild("PlayerData").OnClientEvent:Connect(function(insPLR, tblData)
	tblPlayerData[insPLR] = tblData
end)

local insDCM = insRSR:WaitForChild("DoClientMagic")
local insDM = insRSR:WaitForChild("DoMagic")
local insCombat = insRSR:WaitForChild("Combat")

local blnSZChecks = false

local function blnSZCheck(insPLR)
	if blnSZChecks and insPLR.Character and insPLR.Character:FindFirstChild("ForceField") then
		return true
	end

	return false
end

local blnMouseMode = false

local function cfrGetSpawn()
	if blnMouseMode then
		return objMouse.Hit
	else
		return insTargetPLR.Character and insTargetPLR.Character:FindFirstChild("HumanoidRootPart") and not(blnSZCheck(insTargetPLR)) and insTargetPLR.Character.HumanoidRootPart.CFrame
	end
end

local blnLegitMode = tblSettings.LegitOnStartup
local numLightningFlashMultiplier = 1.5
local numGenesisRayCharge = 1
local numEchoes = 1

local tblLoopingKeys = {}

local tblExploits = {
	[1] = {
		["Name"] = "Blaze Column",
		["Color"] = Color3.new(1, 0.34901960784313724, 0.3607843137254902),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Blaze Column at the target's location. With legit mode, animations will play.\nRange Limit: 200 units",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn and ((cfrSpawn.Position - insLHRP.CFrame.Position).Magnitude < 200) then
				insDCM:FireServer("Fire", "Blaze Column", cfrSpawn.Position)

				if blnLegitMode then
					voidPlayAnim("AOE3", nil, nil, 1.6)
					spawn(function() wait(1.1) voidStopAnim("AOE3") end)

					wait(0.6)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Fire", "Blaze Column", CFrame.new(cfrSpawn.Position, cfrSpawn.Position + Vector3.yAxis))
			end
		end
	},
	[2] = {
		["Name"] = "Lightning Flash",
		["Color"] = BrickColor.new("Toothpaste").Color,
		["Image"] = "rbxassetid://531829466",
		["Description"] = "Extends Lightning Flash by a multiplier (default is 1.5). Set this multiplier with ;multiplier <num>.",
		["Function"] = function()
			local _, vc3Hit, vc3Normal = workspace:FindPartOnRayWithIgnoreList(Ray.new(insLHRP.CFrame.Position, CFrame.new(insLHRP.CFrame.Position, objMouse.Hit.Position).LookVector * 50 * numLightningFlashMultiplier), {insLCHR, insIgnore})

			insDCM:FireServer("Storm", "Lightning Flash")
			insDM:InvokeServer("Storm", "Lightning Flash", {["Origin"] = insLHRP.CFrame.Position, ["End"] = vc3Hit + vc3Normal * 2})
		end
	},
	[3] = {
		["Name"] = "Vine Trap",
		["Color"] = Color3.new(0, 0.65, 0),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Vine Trap at the target's location. With legit mode, animations will play.\nRange Limit: 200 units",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn and ((cfrSpawn.Position - insLHRP.CFrame.Position).Magnitude < 200) then
				insDCM:FireServer("Nature", "Vine Trap", cfrSpawn.Position)

				if blnLegitMode then
					voidPlayAnim("Spike Rise")
					spawn(function() wait(1) voidStopAnim("Spike Rise") end)

					wait(0.5)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Nature", "Vine Trap", CFrame.new(cfrSpawn.Position, cfrSpawn.Position + Vector3.yAxis))
			end
		end
	},
	[4] = {
		["Name"] = "Plasma Implosion",
		["Color"] = BrickColor.new("Hot pink").Color,
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Plasma Implosion at the target's location. With legit mode, animations will play.\nRange Limit: 200 units",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn and ((cfrSpawn.Position - insLHRP.CFrame.Position).Magnitude < 200) then
				insDCM:FireServer("Plasma", "Plasma Implosion", cfrSpawn.Position)

				if blnLegitMode then
					voidPlayAnim("Spike Rise")
					spawn(function() wait(1) voidStopAnim("Spike Rise") end)

					wait(0.8)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Plasma", "Plasma Implosion", CFrame.new(cfrSpawn.Position, cfrSpawn.Position + Vector3.yAxis))
			end
		end
	},
	[5] = {
		["Name"] = "Luminous Dispersion",
		["Color"] = BrickColor.new("Sunrise").Color,
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons a Luminous Dispersion at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Crystal", "Luminous Dispersion")

				if blnLegitMode then voidPlayAnim("Crystal AOE Deploy", nil, nil, 0.9) end

				insDM:InvokeServer("Crystal", "Luminous Dispersion", {["LastPosition"] = cfrSpawn.Position, ["Radius"] = 30})
			end
		end
	},
	[6] = {
		["Name"] = "Gravital Globe",
		["Color"] = BrickColor.new("Mulberry").Color,
		["Image"] = "rbxassetid://523612211",
		["Description"] = "Summons an instant Gravital Globe at the target's location, slightly offset in the air to maximize efficiency.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Gravity", "Gravital Globe")
				insDM:InvokeServer("Gravity", "Gravital Globe", {["lastPos"] = cfrSpawn.Position + Vector3.new(0, 15, 0)})
			end
		end
	},
	[7] = {
		["Name"] = "Gravitational Field",
		["Color"] = BrickColor.new("Mulberry").Color,
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons a Gravitational Field at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Gravity", "Gravitational Field")

				if blnLegitMode then
					wait(1) 
					voidPlayAnim("Spirit Projectile [REAL] Fire", nil, nil, 0.75)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Gravity", "Gravitational Field", cfrSpawn)
			end
		end
	},
	[8] = {
		["Name"] = "Amaurotic Lambent",
		["Color"] = Color3.new(1, 1, 0.05),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an Amaurotic Lambent at the target's location.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Light", "Amaurotic Lambent")
				insDM:InvokeServer("Light", "Amaurotic Lambent", {["lastPos"] = cfrSpawn.Position})
			end
		end
	},
	[9] = {
		["Name"] = "Ablaze Judgement",
		["Color"] = Color3.new(1, 1, 0.05),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons an instant Ablaze Judgement at the target's location, slightly offset underground to hit instantly. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Light", "Ablaze Judgement")

				if blnLegitMode then
					voidPlayAnim("Light Charge", nil, nil, 241/700)

					wait(3)

					voidPlayAnim("LigUlt2", nil, nil, 1)

					wait(0.25)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Light", "Ablaze Judgement", {["Origin"] = cfrSpawn.Position - Vector3.new(0, 25, 0), ["orbPos"] = cfrSpawn.Position - Vector3.new(0, 10, 0)})
			end
		end
	},
	[10] = {
		["Name"] = "Void Opening",
		["Color"] = Color3.new(0.39215686274509803, 0, 0.7843137254901961),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a Void Opening under the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Void", "Void Opening")

				if blnLegitMode then
					voidPlayAnim("Spike Rise", nil, nil, 0.2)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Void", "Void Opening", {["pos"] = cfrSpawn.Position - Vector3.new(0, 150, 0)})
			end
		end
	},
	[11] = {
		["Name"] = "Skeleton Grab",
		["Color"] = BrickColor.new("Magenta").Color,
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Skeleton Grab at the mouse cursor. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Nightmare", "Skeleton Grab")

				if blnLegitMode then
					voidPlayAnim("Wind Crouch")
					spawn(function() wait(1.5) voidPlayAnim("Wind Crouch") end)

					wait(0.9)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Nightmare", "Skeleton Grab", cfrSpawn)
			end
		end
	},
	[12] = {
		["Name"] = "Genesis Ray",
		["Color"] = Color3.new(0.4, 0.6, 0.3),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Genesis Ray towards the mouse cursor from your body, with a charge modifier that can be adjusted using ;charge <num>. Charge will increase the Genesis Ray's travel distance, travel speed, and lifespan.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Time", "Genesis Ray", insLHRP.CFrame.Position)

				if blnLegitMode then
					voidPlayAnim("Bullets", nil, nil, 0.5)

					wait(0.5)
					spawn(function()
						wait(1)

						voidStopAnim("Bullets")
					end)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Time", "Genesis Ray", {["lv"] = Vector3.new(), ["charge"] = numGenesisRayCharge})
			end
		end
	},
	[13] = {
		["Name"] = "The World",
		["Color"] = Color3.new(0.4, 0.6, 0.3),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a The World at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Time", "The World", cfrSpawn.Position)

				if blnLegitMode then
					wait(2.15)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Time", "The World", {["rhit"] = insTargetPLR.Character:FindFirstChild("HumanoidRootPart"), ["norm"] = Vector3.new(0, 0, 0), ["rpos"] = cfrSpawn.Position})
			end
		end
	},
	[14] = {
		["Name"] = "Polaris",
		["Color"] = Color3.fromRGB(88, 220, 6),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a Polaris at the target's location, slightly lowered to increase efficiency.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Aurora", "Polaris")

				if blnLegitMode then
					voidPlayAnim("Meditate", nil, nil, 0.8)

					wait(2)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Aurora", "Polaris", cfrSpawn)
			end
		end
	},
	[15] = {
		["Name"] = "Echoes",
		["Color"] = Color3.fromRGB(200, 110, 160),
		["Image"] = "rbxassetid://523612283",
		["Description"] = "Summons an instant Echoes towards the mouse cursor from your body, with a phase that can be modified using ;e <int from 1 to 3>. With legit mode, animations will play.\n 1 is Star, 2 is Flame, and 3 is Shock. Default is 1 (Star).",
		["Function"] = function()
			insDCM:FireServer("Sound", "Echoes")

			if blnLegitMode then
				wait(0.5)
			end

			insDM:InvokeServer("Sound", "Echoes", {numEchoes, objMouse.Hit.Position})
		end
	},
	[16] = {
		["Name"] = "Shattering Eruption",
		["Color"] = Color3.fromRGB(255, 119, 29),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons an instant Shattering Eruption at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn and ((cfrSpawn.Position - insLHRP.CFrame.Position).Magnitude < 150) then
				insDCM:FireServer("Explosion", "Shattering Eruption")

				if blnLegitMode then
					voidPlayAnim("Spike Rise", nil, nil, 0.2)

					wait(1.6)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Explosion", "Shattering Eruption", CFrame.new(cfrSpawn.Position, cfrSpawn.Position + Vector3.yAxis))
			end
		end
	},
	[17] = {
		["Name"] = "Illusive Atake",
		["Color"] = Color3.fromRGB(170, 45, 45),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons an instant Illusive Atake at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Illusion", "Illusive Atake")

				if blnLegitMode then
					voidPlayAnim("Illusion AOE", nil, nil, 10/9)

					wait(0.75)
					spawn(function() wait(1.5) voidStopAnim("Illusion AOE") end)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Illusion", "Illusive Atake", cfrSpawn)
			end
		end
	},
	[18] = {
		["Name"] = "Ethereal Acumen",
		["Color"] = Color3.fromRGB(170, 45, 45),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a Ethereal Acumen at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Illusion", "Ethereal Acumen")

				if blnLegitMode then
					voidPlayAnim("Crystal Ult", nil, nil, 0.1)

					wait(1.75)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Illusion", "Ethereal Acumen", cfrSpawn)
			end
		end
	},
	[19] = {
		["Name"] = "Formidable Roar",
		["Color"] = Color3.fromRGB(34, 83, 27),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons a Formidable Roar at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Dragon", "Formidable Roar")

				if blnLegitMode then
					wait(1.5)

					voidPlayAnim("Dragon Breath Fire", nil, nil, 0.8)

					spawn(function()
						wait(0.75)

						voidPlayAnim("Dragon Breath Fire", nil, nil, 0.8)
					end)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Dragon", "Formidable Roar", {cfrSpawn, 175})
			end
		end
	},
	[20] = {
		["Name"] = "Toxic Basilisk",
		["Color"] = Color3.fromRGB(190, 255, 45),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a Toxic Basilisk at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Acid", "Toxic Basilisk")

				if blnLegitMode then
					wait(1.25)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Acid", "Toxic Basilisk", {["Direction"] = CFrame.new(cfrSpawn.Position, cfrSpawn.Position + Vector3.yAxis), ["Floor"] = cfrSpawn})
			end
		end
	},
	[21] = {
		["Name"] = "Arcane Guardian",
		["Color"] = Color3.fromRGB(255, 241, 142),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons an instant Arcane Guardian at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Angel", "Arcane Guardian")

				if blnLegitMode then
					voidPlayAnim("Angel Pushup", nil, nil, 0.25)

					wait(0.5)

					voidStopAnim("Angel Pushup", nil, nil, 0.4)
					voidPlayAnim("Angel Draw", nil, nil, 2)

					coroutine.resume(coroutine.create(function()
						wait(0.5)

						voidStopAnim("Angel Draw", nil, nil, 0.4)
						voidPlayAnim("Angel Drawn", nil, nil, 0.4)
					end))

					wait(0.75 + 1/12)

					voidStopAnim("Angel Drawn", nil, nil, 1)
					voidPlayAnim("Angel Descend Static", nil, nil, 0.1)

					wait(1)

					voidStopAnim("Angel Descend Static", nil, nil, 1)
					voidPlayAnim("Angel Descend In", nil, nil, 0.5)

					wait(0.5)

					voidStopAnim("Angel Descend In", nil, nil, 0.5)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Angel", "Arcane Guardian", {["Position"] = cfrSpawn.Position + Vector3.new(0, 50, 0)})
			end
		end
	},
	[22] = {
		["Name"] = "Splitting Slime",
		["Color"] = Color3.fromRGB(178, 207, 255),
		["Image"] = "rbxassetid://523697411",
		["Description"] = "Summons a Splitting Slime at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Slime", "Splitting Slime")

				if blnLegitMode then
					voidPlayAnim("Illusion AOE", nil, nil, 10/9)

					wait(0.4)
					spawn(function() wait(1) voidStopAnim("Illusion AOE") end)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Slime", "Splitting Slime", cfrSpawn - Vector3.new(0, 20, 0))
			end
		end
	},
	[23] = {
		["Name"] = "Slime Buddies",
		["Color"] = Color3.fromRGB(178, 207, 255),
		["Image"] = "rbxassetid://561899135",
		["Description"] = "Summons a Slime Buddies at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Slime", "Slime Buddies")

				if blnLegitMode then
					voidPlayAnim("Illusion AOE", nil, nil, 10/9)

					wait(0.75)
					spawn(function() wait(1.5) voidStopAnim("Illusion AOE") end)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Slime", "Slime Buddies", cfrSpawn)
			end
		end
	},
	[24] = {
		["Name"] = "Virtual Zone",
		["Color"] = Color3.fromRGB(60, 182, 0),
		["Image"] = "rbxassetid://523612387",
		["Description"] = "Summons a Virtual Zone at the target's location. With legit mode, animations will play.",
		["Function"] = function()
			local cfrSpawn = cfrGetSpawn()

			if cfrSpawn then
				insDCM:FireServer("Technology", "Virtual Zone")

				if blnLegitMode then
					wait(0.75)

					voidPlayAnim("Crystal Ult", nil, nil, 0.1)

					wait(10.5)

					voidStopAnim("Crystal Ult", 0.4)

					cfrSpawn = cfrGetSpawn() or cfrSpawn
				end

				insDM:InvokeServer("Technology", "Virtual Zone", {cfrSpawn.Position, Vector3.new()})
			end
		end
	}
}

local inslogUI = Instance.new("ScreenGui")
local insMain = Instance.new("Frame")
local insBar = Instance.new("TextBox")
local insTitle = Instance.new("TextLabel")
local insDisableBar = Instance.new("Frame")
local insUICorner = Instance.new("UICorner")
local insDisableFill = Instance.new("Frame")
local insUICorner_2 = Instance.new("UICorner")
local insDisableLabel = Instance.new("TextLabel")
local insBox = Instance.new("ScrollingFrame")
local insUIGridLayout = Instance.new("UIGridLayout")
local insUIListLayout = Instance.new("UIListLayout")
local insFrame = Instance.new("Frame")
local insImageButton = Instance.new("ImageButton")
local insStatus = Instance.new("TextLabel")
local insTooltip = Instance.new("TextLabel")
local insTabs = Instance.new("Frame")
local insSettings = Instance.new("TextButton")
local insInfo = Instance.new("TextButton")
local insExploits = Instance.new("TextButton")

local function blnCollides(insObject)
	local vc2AbsPosition = insObject.AbsolutePosition
	local vc2AbsSize = insObject.AbsoluteSize

	return (objMouse.X > vc2AbsPosition.X) and (objMouse.X < vc2AbsSize.X + vc2AbsPosition.X) and (objMouse.Y > vc2AbsPosition.Y) and (objMouse.Y < vc2AbsSize.Y + vc2AbsPosition.Y)
end

inslogUI.Name = "logUI"
inslogUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
inslogUI.ResetOnSpawn = false
inslogUI.Parent = srvRUN:IsStudio() and insLPLR:WaitForChild("PlayerGui") or game.CoreGui

insMain.Name = "Main"
insMain.AnchorPoint = Vector2.new(0.5, 0.5)
insMain.BackgroundColor3 = Color3.fromHSV(tblSettings.MainColor[1], tblSettings.MainColor[2], tblSettings.MainColor[3])
insMain.Position = UDim2.new(0.5, 0, 0.5, 0)
insMain.Size = UDim2.new()
insMain.SizeConstraint = Enum.SizeConstraint.RelativeYY
insMain.Active = true
insMain.Draggable = true
insMain.Parent = inslogUI
Instance.new("UICorner").Parent = insMain

insBar.Name = "Bar"
insBar.BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])
insBar.BorderSizePixel = 0
insBar.Position = UDim2.new(0, 0, 0.15, 0)
insBar.Size = UDim2.new(1, 0, 0.1, 0)
insBar.Font = Enum.Font.SourceSansSemibold
insBar.Text = "Current Target | (None)"
insBar.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
insBar.TextSize = 14.000
insBar.TextWrapped = true
insBar.ClearTextOnFocus = false
insBar.Parent = insMain

insBar.Focused:Connect(function()
	numBarIndex = #tblBarHistory + 1

	if blnOutputting then
		blnOutputting = false
		insBar.Text = ""
	end

	insBar.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
end)

local function tblPLRsFromString(str)
	if (str == "") then return {} end
	str = str:lower()

	local tblMatches = {}

	for _, insPLR in ipairs(srvPLR:GetPlayers()) do
		if string.find(insPLR.Name:lower(), str) then
			table.insert(tblMatches, insPLR)
		end
	end

	return tblMatches
end

insBar.FocusLost:Connect(function(blnEntered)
	local strText = insBar.Text:lower()

	if blnEntered then
		blnOutputting = true

		if not(string.gsub(strText, " ", "") == "") then
			if not(strText == tblBarHistory[#tblBarHistory]) then
				table.insert(tblBarHistory, strText)
			end

			strText = strText .. " "

			if (string.sub(strText, 1, 1) == ";") then
				strText = string.sub(strText, 2)

				if (string.sub(strText, 1, 6) == "legit ") then
					blnLegitMode = not(blnLegitMode)

					insBar.Text = "Legit mode toggled! (" .. (blnLegitMode and "Active" or "Inactive") .. ")"
				elseif (string.sub(strText, 1, 6) == "mouse ") then
					blnMouseMode = not(blnMouseMode)

					insBar.Text = "Mouse mode toggled! (" .. (blnMouseMode and "Active" or "Inactive") .. ")"
				elseif (string.sub(strText, 1, 11) == "multiplier ") then
					local numMultiplier = tonumber(string.sub(strText, 12))

					if numMultiplier then
						numLightningFlashMultiplier = numMultiplier
						insBar.Text = "Multiplier set! (" .. numLightningFlashMultiplier .. ")"
					else
						insBar.Text = "Multiplier not set! Please input a valid number."
					end
				elseif (string.sub(strText, 1, 7) == "charge ") then
					local numCharge = tonumber(string.sub(strText, 8))

					if numCharge then
						numGenesisRayCharge = numCharge
						insBar.Text = "Charge set! (" .. numGenesisRayCharge .. ")"
					else
						insBar.Text = "Charge not set! Please input a valid number."
					end
				elseif (string.sub(strText, 1, 2) == "e ") then
					local numE = tonumber(string.sub(strText, 3))

					local tblPhases = {
						[1] = "Star",
						[2] = "Flame",
						[3] = "Shock"
					}

					if numE and tblPhases[numE] then
						numEchoes = numE
						insBar.Text = "Echoes set! (" .. tblPhases[numEchoes] .. ")"
					else
						insBar.Text = "Echoes not set! Please input a valid integer from 1 to 3."
					end
				elseif (string.sub(strText, 1, 6) == "invis ") then
					if insLCHR:FindFirstChild("Head") and insLCHR.Head:FindFirstChild("face") then
						insLCHR.Head["face"]:Destroy()
					end

					insDCM:FireServer("Spirit", "Spectral Embodiment")
					insDM:InvokeServer("Spirit", "Spectral Embodiment")

					insBar.Text = "Initializing permanent invisibility."
				elseif (string.sub(strText, 1, 4) == "def ") then
					insDCM:FireServer("Acid", "Toxic Basilisk")
					insDM:InvokeServer("Acid", "Toxic Basilisk", {["Floor"] = CFrame.new(-1999999999, -1999999999, -1999999999, -0, 1, -0, -0, 0, -1, -1, 0, -0), ["Direction"] = CFrame.new(-1999999999, -1999999999, -1999999999, -0.723236084, -0, -0.690600812, -0, 0.999999881, -0, 0.690600872, 0, -0.723236024)})

					if insLCHR:FindFirstChild("Head") then
						insLCHR.Head:WaitForChild("BodyPosition"):Destroy()
					end

					insBar.Text = "Initializing permanent 80% defense."
				elseif (string.sub(strText, 1, 6) == "speed ") then
					local numSpeed2 = tonumber(string.sub(strText, 7))

					if numSpeed2 then
						numSpeed = numSpeed2
						insBar.Text = "Speed set! (" .. numSpeed .. ")"
					else
						insBar.Text = "Speed not set! Please input a valid number."
					end
				elseif (string.sub(strText, 1, 11) == "floatforce ") then
					local numForce = tonumber(string.sub(strText, 12))

					if numForce then
						numFloatForce = numForce
						insBar.Text = "Float force set! (" .. numFloatForce .. ")"

						if insLHRP:FindFirstChild("Float") then
							insLHRP.Float.Force = Vector3.new(0, numFloatForce, 0)
						end
					else
						insBar.Text = "Float force not set! Please input a valid number."
					end
				elseif (string.sub(strText, 1, 12) == "launchpower ") then
					local numPower = tonumber(string.sub(strText, 12))

					if numPower then
						numLaunchPower = numPower
						insBar.Text = "Launch Power set! (" .. numLaunchPower .. ")"
					else
						insBar.Text = "Launch Power not set! Please input a valid number."
					end
				elseif (string.sub(strText, 1, 5) == "stun ") then
					if tblGetConnections then
						blnStunActive = not(blnStunActive)

						for _, cncConnection in next, tblGetConnections(insCombat.OnClientEvent) do
							if blnStunActive then
								if cncConnection["Enable"] then
									cncConnection["Enable"]()
								elseif cncConnection["Connect"] then
									cncConnection["Connect"]()
								end
							else
								if cncConnection["Disable"] then
									cncConnection["Disable"]()
								elseif cncConnection["Disconnect"] then
									cncConnection["Disconnect"]()
								end
							end
						end

						insBar.Text = "Stun toggled! (" .. (blnStunActive and "Active" or "Inactive") .. ")"
					else
						insBar.Text = "Your executor is not compatible with the ;stun command!"
					end
				elseif (string.sub(strText, 1, 5) == "heal ") then
					local insPLR = tblPLRsFromString(string.gsub(string.sub(strText, 6), " ", ""))[1]
					local insHRP = insPLR and insPLR.Character and insPLR.Character:FindFirstChild("HumanoidRootPart")
					
					if insHRP then
						insDCM:FireServer("Crystal", "Gleaming Harmony")
						insDM:InvokeServer("Crystal", "Gleaming Harmony", insHRP.CFrame.Position)
						
						insDCM:FireServer("Phoenix", "Blue Arson")
						insDM:InvokeServer("Phoenix", "Blue Arson", insHRP.CFrame.Position)
					else
						insDCM:FireServer("Nature", "Nature's Blessing")
						insDM:InvokeServer("Nature", "Nature's Blessing")
						insDCM:FireServer("Crystal", "Gleaming Harmony")
						insDM:InvokeServer("Crystal", "Gleaming Harmony", insLHRP.CFrame.Position)
						
						insDCM:FireServer("Phoenix", "Blue Arson")
						insDM:InvokeServer("Phoenix", "Blue Arson", insLHRP.CFrame.Position)
						
						insDCM:FireServer("Angel", "Angelic Aura")
						insDM:InvokeServer("Angel", "Angelic Aura")
					end
					
					insBar.Text = "Healing" .. (insPLR and (" " .. insPLR.Name) or "") .. "..."
				elseif (string.sub(strText, 1, 16) == "clearbarhistory ") then
					table.clear(tblBarHistory)
					numBarIndex = 1

					insBar.Text = "Bar history cleared."
				else
					insBar.Text = "Invalid command! See the Info tab for commands."
				end

				wait(1.5)
			else
				local insPLR = tblPLRsFromString(string.gsub(strText, " ", ""))[1]
				insTargetPLR = insPLR or insLPLR

				if not(insPLR) then
					insBar.Text = "Target invalid!" 

					wait(1.5)
				end
			end
		end

		if insBar:IsFocused() then return end
		insBar.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
		insBar.Text = "Current Target | " .. (not(insLPLR == insTargetPLR) and insTargetPLR.Name or "(None)")
	elseif (string.gsub(strText, " ", "") == "") then
		blnOutputting = true
		insBar.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
		insBar.Text = "Current Target | " .. (not(insLPLR == insTargetPLR) and insTargetPLR.Name or "(None)")
	end
end)

local cncUIS
cncUIS = srvUIS.InputBegan:Connect(function(tblKeyData, blnGP)
	if not(blnBinding) then
		if not(blnGP) then
			if tblSettings.OpenCloseGuiKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.OpenCloseGuiKey]) then
				if not(blnOpen) then
					insMain.Visible = not(blnOpen)
					insTabs.Visible = not(blnOpen)
				end

				blnOpen = not(blnOpen)

				insMain:TweenSize(blnOpen and UDim2.new(0.35 * tblSettings.GuiSizeMultiplier, 0, 0.21875 * tblSettings.GuiSizeMultiplier, 0) or UDim2.new(), blnOpen and Enum.EasingDirection.Out or Enum.EasingDirection.In, blnOpen and Enum.EasingStyle.Quad or Enum.EasingStyle.Back, 0.5, true)

				wait(0.5)

				insMain.Visible = blnOpen
				insTabs.Visible = blnOpen
			elseif blnOpen and tblSettings.DisableGuiKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.DisableGuiKey]) then
				local numStartTime = tick()
				
				srvTween:Create(insDisableBar, TweenInfo.new(0.25), {BackgroundTransparency = 0.75}):Play()
				srvTween:Create(insDisableFill, TweenInfo.new(0.25), {BackgroundTransparency = 0.5}):Play()
				srvTween:Create(insDisableLabel, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
				
				while blnOpen and srvUIS:IsKeyDown(Enum.KeyCode[tblSettings.DisableGuiKey]) and (tick() - numStartTime < 3) do
					insDisableFill:TweenSize(UDim2.new(srvTween:GetValue((tick() - numStartTime) / 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)
					
					srvRUN.RenderStepped:Wait()
				end
				
				if blnOpen and (tick() - numStartTime >= 3) then
					insDisableFill:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
					
					blnOpen = false
					
					insMain:TweenSize(UDim2.new(), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.5, true)
					cncUIS:Disconnect()
					
					wait(0.5)
					
					pcall(function() getgenv().logUI_loaded = false end)
					inslogUI:Destroy()
				else
					insDisableFill:TweenSize(UDim2.new(0, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
					
					srvTween:Create(insDisableBar, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
					srvTween:Create(insDisableFill, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
					srvTween:Create(insDisableLabel, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
				end
			elseif tblSettings.BarKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.BarKey]) and (tblSettings.BarEnabledWhileClosed or blnOpen) then
				insBar:CaptureFocus()

				spawn(function()
					while (string.sub(insBar.Text:lower(), string.len(insBar.Text)) == srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.BarKey]):lower()) do insBar.Text = string.sub(insBar.Text, 1, string.len(insBar.Text) - 1) srvRUN.RenderStepped:Wait() end 
				end)
			elseif tblSettings.ESPKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.ESPKey]) then
				blnESPActive = not(blnESPActive)

				for _, insPLR in next, srvPLR:GetPlayers() do
					spawn(function() pcall(blnESPActive and voidLoadPlayer or voidUnloadPlayer, insPLR) end)
				end
			elseif tblSettings.SpeedhackKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.SpeedhackKey]) then
				blnSpeedhackActive = not(blnSpeedhackActive)

				if blnSpeedhackActive then
					insLHUM.WalkSpeed = numSpeed
				end
			elseif blnEnhancePunchesActive and (tblKeyData.KeyCode == Enum.KeyCode.P) then
				local tblPlayers = {}

				for _, insPLR in next, srvPLR:GetPlayers() do
					local insHRP = insPLR.Character and insPLR.Character:FindFirstChild("HumanoidRootPart")

					if insHRP then
						table.insert(tblPlayers, {insPLR, (insHRP.CFrame.Position - insLHRP.CFrame.Position).Magnitude})
					end
				end

				table.sort(tblPlayers, function(a, b)
					return a[2] < b[2]
				end)

				for numIndex, tbl in next, tblPlayers do
					tblPlayers[numIndex] = tbl[1]
				end

				wait(0.5)

				local insCHR = (tblPlayers[1] or insLPLR).Character

				if insCHR then
					insCombat:FireServer()
				end
			elseif tblSettings.FreezeKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.FreezeKey]) then
				insLHRP.Anchored = not(insLHRP.Anchored)
			elseif tblSettings.FloatKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.FloatKey]) then
				if insLHRP:FindFirstChild("Float") then
					insLHRP.Float:Destroy()
				else
					local insBodyForce = Instance.new("BodyForce")
					insBodyForce.Force = Vector3.new(0, numFloatForce, 0)
					insBodyForce.Name = "Float"
					insBodyForce.Parent = insLHRP
				end
			elseif tblSettings.ClickTPKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.ClickTPKey]) then
				insLCHR:PivotTo(CFrame.new(objMouse.Hit.Position + Vector3.new(0, 3, 0), Vector3.new(insLHRP.CFrame.Position.X, objMouse.Hit.Position.Y + 3, insLHRP.CFrame.Position.Z)) * CFrame.Angles(0, math.rad(180), 0))
			elseif tblSettings.IBMKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.IBMKey]) then
				blnIBMActive = not(blnIBMActive)

				if blnIBMActive then
					local function voidDestroyBodyMovers(insObject)
						for _, insChild in next, insObject:GetChildren() do
							if insChild:IsA("BodyMover") and not(insChild.Name == "Float") and not(insChild.Name == "Launch") then
								insChild:Destroy()
							else
								voidDestroyBodyMovers(insChild)
							end
						end
					end

					voidDestroyBodyMovers(insLCHR)
				end
			elseif tblSettings.ViewTargetKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.ViewTargetKey]) then
				if (insLCAM.CameraSubject == insLHUM) and insTargetPLR.Character and insTargetPLR.Character:FindFirstChild("Humanoid") then
					insLCAM.CameraSubject = insTargetPLR.Character.Humanoid
				else
					insLCAM.CameraSubject = insLHUM
				end
			elseif tblSettings.TeleportToTargetKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.TeleportToTargetKey]) then
				local insHRP = insTargetPLR.Character and insTargetPLR.Character:FindFirstChild("HumanoidRootPart")
				
				if insHRP then
					insLCHR:PivotTo(insHRP.CFrame)
				end
			elseif tblSettings.LaunchKey and (tblKeyData.KeyCode == Enum.KeyCode[tblSettings.LaunchKey]) then
				if insLHRP then
					local insBVel = Instance.new("BodyVelocity")
					insBVel.Name = "Launch"
					insBVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					insBVel.P = 2000
					insBVel.Velocity = (objMouse.Hit.Position - insLHRP.CFrame.Position).Unit * numLaunchPower
					insBVel.Parent = insLHRP
					wait(0.1)
					insBVel:Destroy()
				end
			else
				for strExploitName, tblExploitData in next, tblExploits do
					if (tblKeyData.KeyCode == tblExploitData["Key"]) then
						coroutine.resume(coroutine.create(function() tblExploitData["Function"]() end))
					end
				end
			end
		elseif insBar:IsFocused() then
			if (tblKeyData.KeyCode == Enum.KeyCode.Up) then
				if (numBarIndex == #tblBarHistory + 1) then strSavedText = insBar.Text end
				numBarIndex = math.max(1, numBarIndex - 1)

				if tblBarHistory[numBarIndex] then
					insBar.Text = tblBarHistory[numBarIndex]
				end
			elseif (tblKeyData.KeyCode == Enum.KeyCode.Down) then
				if (numBarIndex == #tblBarHistory + 1) then return end
				numBarIndex = math.min(numBarIndex + 1, #tblBarHistory + 1)

				if (numBarIndex == #tblBarHistory + 1) then 
					insBar.Text = strSavedText 
				elseif tblBarHistory[numBarIndex] then
					insBar.Text = tblBarHistory[numBarIndex]
				end
			end
		end
	end
end)

insTitle.Name = "Title"
insTitle.AnchorPoint = Vector2.new(0.5, 0)
insTitle.BackgroundTransparency = 1.000
insTitle.Position = UDim2.new(0.5, 0, 0.025, 0)
insTitle.Size = UDim2.new(0.459981591, 0, 0.0883164704, 0)
insTitle.Font = Enum.Font.SourceSansBold
insTitle.Text = "logUI - Exploits"
insTitle.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insTitle.TextScaled = true
insTitle.TextSize = 14.000
insTitle.TextWrapped = true
insTitle.Parent = insMain

insDisableBar.Name = "DisableBar"
insDisableBar.AnchorPoint = Vector2.new(0.5, 0)
insDisableBar.BackgroundTransparency = 1
insDisableBar.Position = UDim2.new(0.5, 0, -0.1, 0)
insDisableBar.Size = UDim2.new(0.8, 0, 0.05, 0)
insDisableBar.BackgroundColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
insDisableBar.Parent = insMain

insUICorner.CornerRadius = UDim.new(1, 0)
insUICorner.Parent = insDisableBar

insDisableFill.Name = "DisableFill"
insDisableFill.AnchorPoint = Vector2.new(0.5, 0.5)
insDisableFill.BackgroundTransparency = 1
insDisableFill.BorderSizePixel = 0
insDisableFill.Position = UDim2.new(0.5, 0, 0.5, 0)
insDisableFill.Size = UDim2.new(0, 0, 1, 0)
insDisableFill.BackgroundColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insDisableFill.Parent = insDisableBar

insUICorner_2.CornerRadius = UDim.new(1, 0)
insUICorner_2.Parent = insDisableFill

insDisableLabel.Name = "DisableLabel"
insDisableLabel.AnchorPoint = Vector2.new(0.5, 0.5)
insDisableLabel.TextTransparency = 1
insDisableLabel.BackgroundTransparency = 1
insDisableLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
insDisableLabel.TextYAlignment = Enum.TextYAlignment.Center
insDisableLabel.BackgroundColor3 = Color3.fromHSV(tblSettings.BoxColor[1], tblSettings.BoxColor[2], tblSettings.BoxColor[3])
insDisableLabel.Parent = insDisableBar

insBox.Name = "Box"
insBox.Active = true
insBox.AnchorPoint = Vector2.new(0.5, 1)
insBox.BackgroundColor3 = Color3.fromHSV(tblSettings.BoxColor[1], tblSettings.BoxColor[2], tblSettings.BoxColor[3])
insBox.BackgroundTransparency = 0.750
insBox.BorderSizePixel = 0
insBox.Position = UDim2.new(0.5, 0, 0.933550179, 0)
insBox.Size = UDim2.new(0.924562991, 0, 0.621895134, 0)
insBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
insBox.CanvasSize = UDim2.new(0, 0, 0, 0)
insBox.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
insBox.ScrollBarThickness = 6
insBox.Parent = insMain
Instance.new("UICorner").Parent = insBox

insUIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
insUIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
insUIGridLayout.FillDirectionMaxCells = 6
insUIGridLayout.CellPadding = UDim2.new(1/25, 0, 1/20, 0)
insUIGridLayout.CellSize = UDim2.new(1/9, 0, 1/5, 0)
insUIGridLayout.Parent = insBox

insUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
insUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
insUIListLayout.FillDirection = Enum.FillDirection.Vertical
insUIListLayout.Padding = UDim.new(0, 12)

insFrame.BackgroundColor3 = Color3.fromHSV(tblSettings.InnerBoxColor[1], tblSettings.InnerBoxColor[2], tblSettings.InnerBoxColor[3])
insFrame.BorderSizePixel = 0
insFrame.Size = UDim2.new(0, 100, 0, 100)
insFrame.Visible = false

insImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
insImageButton.ImageColor3 = Color3.new()
insImageButton.Position = UDim2.new(0.05, 0, 0.5, 0)
insImageButton.Size = UDim2.new(0.9, 0, 0.9, 0)
insImageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
insImageButton.Parent = insFrame

insStatus.Name = "Status"
insStatus.AnchorPoint = Vector2.new(0.5, 0.5)
insStatus.BackgroundTransparency = 1.000
insStatus.Position = UDim2.new(0.75, 0, 0.5, 0)
insStatus.Rotation = 270.000
insStatus.Size = UDim2.new(0.9, 0, 0.4, 0)
insStatus.SizeConstraint = Enum.SizeConstraint.RelativeYY
insStatus.Font = Enum.Font.SciFi
insStatus.Text = ""
insStatus.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insStatus.TextSize = 14.000
insStatus.TextScaled = true
insStatus.Parent = insFrame

insTooltip.Name = "Tooltip"
insTooltip.AnchorPoint = Vector2.new(0.5, 1)
insTooltip.BackgroundColor3 = Color3.fromHSV(tblSettings.MainColor[1], tblSettings.MainColor[2], tblSettings.MainColor[3])
insTooltip.Font = Enum.Font.SourceSans
insTooltip.TextSize = 14
insTooltip.TextWrapped = true
insTooltip.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insTooltip.Position = UDim2.new(0.5, 0, -0.1, 0)
Instance.new("UICorner").Parent = insTooltip

local tblExploitsObjects = {}
local tblSettingsObjects = {}
local tblInfoObjects = {}

for numIndex, tblExploitData in next, tblExploits do
	local insNewFrame = insFrame:Clone()
	insNewFrame.Name = "Exploits_" .. numIndex

	insNewFrame.ImageButton.BackgroundColor3 = tblExploitData["Color"]
	insNewFrame.ImageButton.Image = tblExploitData["Image"]
	insNewFrame.LayoutOrder = numIndex

	insNewFrame.Visible = true
	insNewFrame.Parent = insBox

	insNewFrame.ImageButton.MouseButton1Up:Connect(function()
		if blnBinding then return end
		if tblExploits[numIndex].Key then
			tblExploits[numIndex].Key = nil
			insNewFrame.Status.Text = ""
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insNewFrame.Status.Text = "BIND"

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, varSetting in next, tblSettings do
					if (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblExploits[numIndex].Key = tblKeyData.KeyCode
					insNewFrame.Status.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end)

	insNewFrame.ImageButton.MouseButton2Up:Connect(function()
		local strText = tblExploitData["Name"] .. "\n\n" .. tblExploitData["Description"]

		insTooltip.Text = strText
		insTooltip.Size = UDim2.new(0.5, 6, 0, srvText:GetTextSize(strText, 14, Enum.Font.SourceSans, Vector2.new(insMain.AbsoluteSize.X * 0.5, 10000)).Y + 6)
		insTooltip.Parent = insMain
	end)

	insNewFrame.ImageButton.MouseLeave:Connect(function()
		insTooltip.Parent = nil
	end)

	table.insert(tblExploitsObjects, insNewFrame)
end

for numIndex, tblSettingData in next, {
	{"*logUI Settings"},
	{"logUI Size", {math.floor(tblSettings.GuiSizeMultiplier * 100) .. "%", "Adjusts logUI's size from 0.9 to 1.3.", function(insButton) 
		local tblSizes = {
			[1] = 1,
			[2] = 1.1,
			[3] = 1.2,
			[4] = 1.3,
			[5] = 0.9
		}

		local numNextIndex = (table.find(tblSizes, tblSettings.GuiSizeMultiplier) or 0) + 1
		if (numNextIndex > #tblSizes) then numNextIndex = 1 end
		tblSettings.GuiSizeMultiplier = tblSizes[numNextIndex]
		insButton.Text = math.floor(tblSettings.GuiSizeMultiplier * 100) .. "%"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

		insMain:TweenSize(blnOpen and UDim2.new(0.35 * tblSettings.GuiSizeMultiplier, 0, 0.21875 * tblSettings.GuiSizeMultiplier, 0) or UDim2.new(), blnOpen and Enum.EasingDirection.Out or Enum.EasingDirection.In, blnOpen and Enum.EasingStyle.Quad or Enum.EasingStyle.Back, 0.5, true)
	end}},
	{"Open/Close logUI Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.OpenCloseGuiKey]), "The key used to open and close logUI.", function(insButton)
		if blnBinding then return end
		blnBinding = true

		for _, insTab in next, insTabs:GetChildren() do
			if insTab:IsA("GuiButton") then
				insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
			end
		end

		insButton.Text = ""

		local cncBinder
		cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
			for _, tblExploit in next, tblExploits do
				if (tblExploit.Key == tblKeyData.KeyCode) then
					return
				end
			end

			for strIndex, varSetting in next, tblSettings do
				if not(strIndex == "OpenCloseGuiKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
					return
				end
			end

			if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
				tblSettings.OpenCloseGuiKey = tblKeyData.KeyCode.Name
				insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
				insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

				if insBox:FindFirstChild("Info_3") then
					insBox.Info_3.Text = "You can open/hide logUI by pressing the " .. (not(tblSettings.OpenCloseGuiKey == Enum.KeyCode.RightBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.OpenCloseGuiKey]) .. " (default ]) ") or "] ") .. "key on your keyboard. You can also disable it by holding the " .. (not(tblSettings.DisableGuiKey == Enum.KeyCode.LeftBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.DisableGuiKey]) .. " (default [) ") or "[ ") .. "key for three seconds."
				end

				cncBinder:Disconnect()
				wait()
				blnBinding = false

				for _, insTab in next, insTabs:GetChildren() do
					if insTab:IsA("GuiButton") then
						insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
					end
				end
			end
		end)
	end}},
	{"Disable logUI Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.DisableGuiKey]), "The key used to disable logUI.", function(insButton)
		if blnBinding then return end
		blnBinding = true

		for _, insTab in next, insTabs:GetChildren() do
			if insTab:IsA("GuiButton") then
				insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
			end
		end

		insButton.Text = ""

		local cncBinder
		cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
			for _, tblExploit in next, tblExploits do
				if (tblExploit.Key == tblKeyData.KeyCode) then
					return
				end
			end

			for strIndex, varSetting in next, tblSettings do
				if not(strIndex == "DisableGuiKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
					return
				end
			end

			if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
				tblSettings.DisableGuiKey = tblKeyData.KeyCode.Name
				insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
				insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

				if insBox:FindFirstChild("Info_3") then
					insBox.Info_3.Text = "You can open/hide logUI by pressing the " .. (not(tblSettings.OpenCloseGuiKey == Enum.KeyCode.RightBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.OpenCloseGuiKey]) .. " (default ]) ") or "] ") .. "key on your keyboard. You can also disable it by holding the " .. (not(tblSettings.DisableGuiKey == Enum.KeyCode.LeftBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.DisableGuiKey]) .. " (default [) ") or "[ ") .. "key for five seconds."
				end

				cncBinder:Disconnect()
				wait()
				blnBinding = false

				for _, insTab in next, insTabs:GetChildren() do
					if insTab:IsA("GuiButton") then
						insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
					end
				end
			end
		end)
	end}},
	{"Bar Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.BarKey or Enum.KeyCode.LeftControl.Name]), "The key used to quickly focus on the bar.", function(insButton)
		if blnBinding then return end
		if tblSettings.BarKey then
			tblSettings.BarKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "BarKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.BarKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Persistent Bar Key", {tblSettings.BarEnabledWhileClosed and "On" or "Off", "Toggles whether the bar key be used when logUI is closed.", function(insButton)
		if blnBinding then return end

		tblSettings.BarEnabledWhileClosed = not(tblSettings.BarEnabledWhileClosed)
		insButton.Text = tblSettings.BarEnabledWhileClosed and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"*Extra Exploits Settings"},
	{"ESP Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.ESPKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle ESP (Extrasensory Perception).", function(insButton)
		if blnBinding then return end
		if tblSettings.ESPKey then
			tblSettings.ESPKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)

				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "ESPKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.ESPKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"ESP On Startup", {tblSettings.ESPOnStartup and "On" or "Off", "The key used to toggle ESP on logUI startup.", function(insButton)
		if blnBinding then return end

		tblSettings.ESPOnStartup = not(tblSettings.ESPOnStartup)
		insButton.Text = tblSettings.ESPOnStartup and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Local ESP", {tblSettings.ESPLocal and "On" or "Off", "Toggles whether ESP affects your character.", function(insButton)
		if blnBinding then return end

		tblSettings.ESPLocal = not(tblSettings.ESPLocal)
		insButton.Text = tblSettings.ESPLocal and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

		spawn(function() pcall(tblSettings.ESPLocal and voidLoadPlayer or voidUnloadPlayer, insLPLR) end)
	end}},
	{"ESP Color Mode", {tblSettings.ESPColorMode, "Adjusts the ESP's color based on the focused setting.", function(insButton) 
		local tblModes = {
			[1] = "Health",
			[2] = "Mana",
			[3] = "Stamina"
		}

		local numNextIndex = (table.find(tblModes, tblSettings.ESPColorMode) or 0) + 1
		if (numNextIndex > #tblModes) then numNextIndex = 1 end
		tblSettings.ESPColorMode = tblModes[numNextIndex]

		insButton.Text = tblSettings.ESPColorMode
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Health ESP", {tblSettings.ESPHealth and "On" or "Off", "Toggles whether ESP includes information about Health.", function(insButton)
		if blnBinding then return end

		tblSettings.ESPHealth = not(tblSettings.ESPHealth)
		insButton.Text = tblSettings.ESPHealth and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Mana ESP", {tblSettings.ESPMana and "On" or "Off", "Toggles whether ESP includes information about Mana.", function(insButton)
		if blnBinding then return end

		tblSettings.ESPMana = not(tblSettings.ESPMana)
		insButton.Text = tblSettings.ESPMana and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Stamina ESP", {tblSettings.ESPStamina and "On" or "Off", "Toggles whether ESP includes information about Stamina.", function(insButton)
		if blnBinding then return end

		tblSettings.ESPStamina = not(tblSettings.ESPStamina)
		insButton.Text = tblSettings.ESPStamina and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Speedhack Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.SpeedhackKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle Speedhack.", function(insButton)
		if blnBinding then return end
		if tblSettings.SpeedhackKey then
			tblSettings.SpeedhackKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "SpeedhackKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.SpeedhackKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Enhance Punches", {tblSettings.EnhancePunchesOnStartup and "On" or "Off", "Toggles whether punches are enhanced.", function(insButton)
		if blnBinding then return end

		blnEnhancePunchesActive = not(blnEnhancePunchesActive)
		insButton.Text = blnEnhancePunchesActive and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Enhance Punches On Startup", {tblSettings.EnhancePunchesOnStartup and "On" or "Off", "Toggles whether punches are enhanced on startup.", function(insButton)
		if blnBinding then return end

		tblSettings.EnhancePunchesOnStartup = not(tblSettings.EnhancePunchesOnStartup)
		insButton.Text = tblSettings.EnhancePunchesOnStartup and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	{"Freeze Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.FreezeKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle Freezing.", function(insButton)
		if blnBinding then return end
		if tblSettings.FreezeKey then
			tblSettings.FreezeKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "FreezeKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.FreezeKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Float Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.FloatKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle Floating.", function(insButton)
		if blnBinding then return end
		if tblSettings.FloatKey then
			tblSettings.FloatKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "FloatKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.FloatKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Click-TP Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.ClickTPKey or Enum.KeyCode.LeftControl.Name]), "The key used to Click-TP.", function(insButton)
		if blnBinding then return end
		if tblSettings.ClickTPKey then
			tblSettings.ClickTPKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "ClickTPKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.ClickTPKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"IBM Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.IBMKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle IBM (Ignore Body Movers).", function(insButton)
		if blnBinding then return end
		if tblSettings.IBMKey then
			tblSettings.IBMKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "IBMKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.IBMKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"View Target Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.ViewTargetKey or Enum.KeyCode.LeftControl.Name]), "The key used to toggle Viewing the Target.", function(insButton)
		if blnBinding then return end
		if tblSettings.ViewTargetKey then
			tblSettings.ViewTargetKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "ViewTargetKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.ViewTargetKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Teleport To Target Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.TeleportToTargetKey or Enum.KeyCode.LeftControl.Name]), "The key used to Teleport to the Target.", function(insButton)
		if blnBinding then return end
		if tblSettings.TeleportToTargetKey then
			tblSettings.TeleportToTargetKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "TeleportToTargetKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.TeleportToTargetKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Launch Key", {srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.LaunchKey or Enum.KeyCode.LeftControl.Name]), "The key used to Launch.", function(insButton)
		if blnBinding then return end
		if tblSettings.LaunchKey then
			tblSettings.LaunchKey = nil

			insButton.Text = ""
			insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		else
			blnBinding = true

			for _, insTab in next, insTabs:GetChildren() do
				if insTab:IsA("GuiButton") then
					insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
				end
			end

			insButton.Text = ""

			local cncBinder
			cncBinder = srvUIS.InputBegan:Connect(function(tblKeyData)
				for _, tblExploit in next, tblExploits do
					if (tblExploit.Key == tblKeyData.KeyCode) then
						return
					end
				end

				for strIndex, varSetting in next, tblSettings do
					if not(strIndex == "LaunchKey") and (type(varSetting) == "string") and pcall(function() local _ = Enum.KeyCode[varSetting] end) and (Enum.KeyCode[varSetting] == tblKeyData.KeyCode) then
						return
					end
				end

				if (tblKeyData.UserInputType == Enum.UserInputType.Keyboard) then
					tblSettings.LaunchKey = tblKeyData.KeyCode.Name
					insButton.Text = srvUIS:GetStringForKeyCode(tblKeyData.KeyCode):upper()
					insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)

					cncBinder:Disconnect()
					wait()
					blnBinding = false

					for _, insTab in next, insTabs:GetChildren() do
						if insTab:IsA("GuiButton") then
							insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
						end
					end
				end
			end)
		end
	end}},
	{"Legit On Startup", {tblSettings.LegitOnStartup and "On" or "Off", "The key used to toggle Legit Mode on logUI startup.", function(insButton)
		if blnBinding then return end

		tblSettings.LegitOnStartup = not(tblSettings.LegitOnStartup)
		insButton.Text = tblSettings.LegitOnStartup and "On" or "Off"
		insButton.Size = UDim2.new(0, srvText:GetTextSize(insButton.Text, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
	end}},
	} do

	local insHolder = Instance.new("Frame")
	insHolder.Size = UDim2.new(0.95, 0, 0, 25)
	insHolder.BorderSizePixel = 0
	insHolder.BackgroundTransparency = 1
	insHolder.LayoutOrder = numIndex
	insHolder.Visible = false
	insHolder.Name = "Settings_" .. numIndex
	insHolder.Parent = insBox

	local insUIListLayout_2 = Instance.new("UIListLayout")
	insUIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
	insUIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	insUIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
	insUIListLayout_2.Padding = UDim.new(0, 6)
	insUIListLayout_2.Parent = insHolder

	local strTitle = tblSettingData[1]
	table.remove(tblSettingData, 1)

	if not(strTitle == "") then
		local insTextLabel = Instance.new("TextLabel")
		insTextLabel.Font = (string.sub(strTitle, 1, 1) == "*") and Enum.Font.SourceSansBold or Enum.Font.SourceSans
		insTextLabel.Text = (string.sub(strTitle, 1, 1) == "*") and string.sub(strTitle, 2) or strTitle
		insTextLabel.Size = UDim2.new(0, srvText:GetTextSize(strTitle, (string.sub(strTitle, 1, 1) == "*") and 20 or 16, (string.sub(strTitle, 1, 1) == "*") and Enum.Font.SourceSansBold or Enum.Font.SourceSans, Vector2.new(10000, 25)).X, 0, 25)
		insTextLabel.BackgroundTransparency = 1
		insTextLabel.TextSize = (string.sub(strTitle, 1, 1) == "*") and 20 or 16
		insTextLabel.TextWrapped = true
		insTextLabel.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
		insTextLabel.TextTransparency = 1
		insTextLabel.LayoutOrder = 0
		insTextLabel.Parent = insHolder
	end

	for numIndex2, tblButtonData in next, tblSettingData do
		local strText = tblButtonData[1]

		local insTextButton = Instance.new("TextButton")
		insTextButton.Font = Enum.Font.SourceSans
		insTextButton.Text = strText
		insTextButton.Size = UDim2.new(0, srvText:GetTextSize(strText, 16, Enum.Font.SourceSans, Vector2.new(10000, 25)).X + 6, 0, 25)
		insTextButton.BackgroundColor3 = Color3.fromHSV(tblSettings.InnerBoxColor[1], tblSettings.InnerBoxColor[2], tblSettings.InnerBoxColor[3])
		insTextButton.TextSize = 16
		insTextButton.TextWrapped = true
		insTextButton.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
		insTextButton.TextTransparency = 1
		insTextButton.LayoutOrder = numIndex2
		insTextButton.Parent = insHolder
		Instance.new("UICorner").Parent = insTextButton

		insTextButton.MouseButton1Up:Connect(function() tblButtonData[3](insTextButton) voidSaveSettings() end)

		insTextButton.MouseButton2Up:Connect(function()
			local strText = strTitle .. "\n\n" .. tblButtonData[2]

			insTooltip.Text = strText
			insTooltip.Size = UDim2.new(0.5, 6, 0, srvText:GetTextSize(strText, 14, Enum.Font.SourceSans, Vector2.new(insMain.AbsoluteSize.X * 0.5, 10000)).Y + 6)
			insTooltip.Parent = insMain
		end)

		insTextButton.MouseLeave:Connect(function()
			insTooltip.Parent = nil
		end)
	end

	table.insert(tblSettingsObjects, insHolder)
end

for numIndex, strText in next, {
	"*Overview",
	"logUI is an exploit developed by logarithmetic for Elemental Battlegrounds. It was made on Thursday, 31 March 05:51 UTC, and finished on _, _ April __:__ UTC.",
	"You can open/hide logUI by pressing the " .. (not(tblSettings.OpenCloseGuiKey == Enum.KeyCode.RightBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.OpenCloseGuiKey]) .. " (default ]) ") or "] ") .. "key on your keyboard. You can also disable it by holding the " .. (not(tblSettings.DisableGuiKey == Enum.KeyCode.LeftBracket.Name) and (srvUIS:GetStringForKeyCode(Enum.KeyCode[tblSettings.DisableGuiKey]) .. " (default [) ") or "[ ") .. "key for five seconds.",
	"If you have any additional questions about logUI that aren't answered here or any suggestions, you can DM logarithmetic on Discord.",
	"*Credits",
	"Creator - logarithmetic\nSpecial Thanks - charlie <3, Vast, Jett, Baysil, Qaat, Gamer Robot",
	"*Tabs",
	"In the Exploits tab, you will find 24 exploits for spells in the game that you may use to your advantage. Clicking on an icon will enter binding mode, in which you can press a key on the keyboard to bind the spell to a key. Pressing this key afterwards will use the exploit associated with the spell icon. Most of the exploits will require a target, but if there is no target selected it will instead target yourself. Clicking the icon again will unbind the exploit. You can right-click on an icon for more information about it. You can not bind keys with keys already bound in the Settings tab and vice versa.\nIn the Settings tab, there are a list of settings that include additional exploits that may assist your gameplay experience, as well as a few aesthetic settings. If your exploit has a file-saving feature (like Synapse X), these settings will save the next time you open logUI. You can right-click a button for more information about it. You can not bind keys with keys already bound in the Exploits tab and vice versa.\nIn the Info tab, you will find information about logUI (which is being presented to you right now, lmao).",
	"*Command Bar",
	"The command bar is the bar located right above this box. In here, you may type a fragment of someone's name in whatever capitalization and logUI will do its best to select the target you wanted. However, if no target could be found, you will be selected as the target (or None).",
	"logUI also features commands that you can use in the command bar (hence the name). These commands begin with semicolons (for example, ;command [args]). The complete list of commands are shown below:",
	";legit - Toggles legit mode. In legit mode, exploits appear to be more \"legitimate\" to others, whilst keeping the initial purpose of the exploit intact.",
	";mouse - Toggles mouse mode. In mouse mode, certain exploits that lock on the target (such as Blaze Column) will instead lock on the mouse cursor.",
	";multiplier <num> - Changes the Lightning Flash exploit's distance multiplier.",
	";charge <num> - Changes the Genesis Ray exploit's charge.",
	";e <int from 1 to 3> - Changes the Echoes exploit's phase.",
	";floatforce <num> - Adjust the float exploit's force. The default is 5000. For reference, Inertia (Gravity's Body spell) has a force of 1638."
	} do

	local insTextLabel = Instance.new("TextLabel")
	insTextLabel.Font = (string.sub(strText, 1, 1) == "*") and Enum.Font.SourceSansBold or Enum.Font.SourceSans
	insTextLabel.Text = (string.sub(strText, 1, 1) == "*") and string.sub(strText, 2) or strText
	insTextLabel.Size = UDim2.new(0.95, 0, 0, srvText:GetTextSize(strText, (string.sub(strText, 1, 1) == "*") and 20 or 16, (string.sub(strText, 1, 1) == "*") and Enum.Font.SourceSansBold or Enum.Font.SourceSans, Vector2.new(insBox.AbsoluteSize.X * 0.95, 10000)).Y)
	insTextLabel.BackgroundTransparency = 1
	insTextLabel.TextSize = (string.sub(strText, 1, 1) == "*") and 20 or 16
	insTextLabel.TextWrapped = true
	insTextLabel.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
	insTextLabel.TextTransparency = 1
	insTextLabel.LayoutOrder = numIndex
	insTextLabel.Visible = false
	insTextLabel.Name = "Info_" .. numIndex
	insTextLabel.Parent = insBox

	table.insert(tblInfoObjects, insTextLabel)
end

insBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	for _, insTextLabel in next, insBox:GetChildren() do
		if insTextLabel:IsA("TextLabel") then
			local strText = insTextLabel.Text

			insTextLabel.Size = UDim2.new(0.95, 0, 0, srvText:GetTextSize(strText, (string.sub(strText, 1, 1) == "*") and 20 or 16, (string.sub(strText, 1, 1) == "*") and Enum.Font.SourceSansBold or Enum.Font.SourceSans, Vector2.new(insBox.AbsoluteSize.X * 0.95, 10000)).Y)
		end
	end
end)

insTabs.Name = "Tabs"
insTabs.AnchorPoint = Vector2.new(0.5, 0.5)
insTabs.BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])
insTabs.BackgroundTransparency = 1
insTabs.Size = UDim2.new(0.275, 0, 0.05, 0)
insTabs.Position = UDim2.new(insMain.Position.X.Scale, insMain.Position.X.Offset, insMain.Position.Y.Scale + (insMain.Size.Y.Scale + insTabs.Size.Y.Scale) / 2, insMain.Position.Y.Offset)
insTabs.SizeConstraint = Enum.SizeConstraint.RelativeYY
insTabs.ZIndex = 0
insTabs.Parent = inslogUI
Instance.new("UICorner").Parent = insTabs

insTabs.MouseEnter:Connect(function()
	for _, insButton in next, insTabs:GetChildren() do
		if insButton:IsA("GuiObject") then
			insButton:TweenPosition(UDim2.new(insButton.Position.X.Scale, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
		end
	end
end)

insTabs.MouseLeave:Connect(function()
	for _, insButton in next, insTabs:GetChildren() do
		if insButton:IsA("GuiObject") then
			insButton:TweenPosition(UDim2.new(insButton.Position.X.Scale, 0, -0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
		end
	end
end)

insMain:GetPropertyChangedSignal("Size"):Connect(function()
	insTabs.Position = UDim2.new(insMain.Position.X.Scale, insMain.Position.X.Offset, insMain.Position.Y.Scale + (insMain.Size.Y.Scale + insTabs.Size.Y.Scale) / 2, insMain.Position.Y.Offset)
	insTabs.Size = UDim2.new(11/12 * insMain.Size.X.Scale, 0, 4/15 * insMain.Size.Y.Scale, 0)
end)

insMain:GetPropertyChangedSignal("Position"):Connect(function()
	insTabs.Position = UDim2.new(insMain.Position.X.Scale, insMain.Position.X.Offset, insMain.Position.Y.Scale + (insMain.Size.Y.Scale + insTabs.Size.Y.Scale) / 2, insMain.Position.Y.Offset)
end)

insSettings.Name = "Settings"
insSettings.BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])
insSettings.AnchorPoint = Vector2.new(0, 0.5)
insSettings.Position = UDim2.new(0.385283738, 0, -0.5, 0)
insSettings.Size = UDim2.new(0.353789061, 0, 0.75, 0)
insSettings.Font = Enum.Font.SourceSansLight
insSettings.Text = "Settings"
insSettings.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insSettings.TextScaled = true
insSettings.TextSize = 14.000
insSettings.TextWrapped = true
insSettings.Parent = insTabs
Instance.new("UICorner").Parent = insSettings

insInfo.Name = "Info"
insInfo.BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])
insInfo.AnchorPoint = Vector2.new(0, 0.5)
insInfo.Position = UDim2.new(0.758241773, 0, -0.5, 0)
insInfo.Size = UDim2.new(0.22394444, 0, 0.75, 0)
insInfo.Font = Enum.Font.SourceSansLight
insInfo.Text = "Info"
insInfo.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insInfo.TextScaled = true
insInfo.TextSize = 14.000
insInfo.TextWrapped = true
insInfo.Parent = insTabs
Instance.new("UICorner").Parent = insInfo

insExploits.Name = "Exploits"
insExploits.BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])
insExploits.AnchorPoint = Vector2.new(0, 0.5)
insExploits.Position = UDim2.new(0.01785101, 0, -0.5, 0)
insExploits.Size = UDim2.new(0.34273845, 0, 0.75, 0)
insExploits.Font = Enum.Font.SourceSansLight
insExploits.Text = "Exploits"
insExploits.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
insExploits.TextScaled = true
insExploits.TextSize = 14.000
insExploits.TextWrapped = true
insExploits.Parent = insTabs
Instance.new("UICorner").Parent = insExploits

local strCurrentTab = "Exploits"

local function voidSwitchTab(strTab)
	if (strCurrentTab == strTab) or blnBinding or blnSwitchingTabs then return end
	blnSwitchingTabs = true

	for _, insTab in next, insTabs:GetChildren() do
		if insTab:IsA("GuiButton") then
			insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor2[1], tblSettings.TextColor2[2], tblSettings.TextColor2[3])
		end
	end

	insTabs[strCurrentTab].BackgroundColor3 = Color3.fromHSV(tblSettings.BarColor[1], tblSettings.BarColor[2], tblSettings.BarColor[3])

	if (strCurrentTab == "Exploits") then
		for _, insFrame2 in next, tblExploitsObjects do
			srvTween:Create(insFrame2, TweenInfo.new(0.25), {["BackgroundTransparency"] = 1}):Play()
			srvTween:Create(insFrame2.ImageButton, TweenInfo.new(0.25), {["BackgroundTransparency"] = 1, ["ImageTransparency"] = 1}):Play()
			srvTween:Create(insFrame2.Status, TweenInfo.new(0.25), {["TextTransparency"] = 1}):Play()
		end

		wait(0.25)

		for _, insFrame2 in next, tblExploitsObjects do
			insFrame2.Visible = false
		end
	elseif (strCurrentTab == "Settings") then
		for _, insFrame2 in next, tblSettingsObjects do
			for _, insObject in next, insFrame2:GetChildren() do
				if insObject:IsA("TextLabel") then
					srvTween:Create(insObject, TweenInfo.new(0.25), {["TextTransparency"] = 1}):Play()
				elseif insObject:IsA("GuiButton") then
					srvTween:Create(insObject, TweenInfo.new(0.25), {["BackgroundTransparency"] = 1, ["TextTransparency"] = 1}):Play()
				end
			end
		end

		wait(0.25)

		for _, insFrame2 in next, tblSettingsObjects do
			insFrame2.Visible = false
		end
	elseif (strCurrentTab == "Info") then
		for _, insTextLabel in next, tblInfoObjects do
			srvTween:Create(insTextLabel, TweenInfo.new(0.25), {["TextTransparency"] = 1}):Play()
		end

		wait(0.25)

		for _, insTextLabel in next, tblInfoObjects do
			insTextLabel.Visible = false
		end
	end

	strCurrentTab = strTab
	insTitle.Text = "logUI - " .. strCurrentTab
	insTabs[strCurrentTab].BackgroundColor3 = Color3.fromHSV(tblSettings.BoxColor[1], tblSettings.BoxColor[2], tblSettings.BoxColor[3])

	if (strTab == "Exploits") then
		insUIListLayout.Parent = nil
		insUIGridLayout.Parent = insBox

		for _, insFrame2 in next, tblExploitsObjects do
			insFrame2.Visible = true

			srvTween:Create(insFrame2, TweenInfo.new(0.25), {["BackgroundTransparency"] = 0}):Play()
			srvTween:Create(insFrame2.ImageButton, TweenInfo.new(0.25), {["BackgroundTransparency"] = 0, ["ImageTransparency"] = 0}):Play()
			srvTween:Create(insFrame2.Status, TweenInfo.new(0.25), {["TextTransparency"] = 0}):Play()
		end

		wait(0.25)
	elseif (strTab == "Settings") then
		insUIListLayout.Parent = insBox
		insUIGridLayout.Parent = nil

		for _, insFrame2 in next, tblSettingsObjects do
			insFrame2.Visible = true

			for _, insObject in next, insFrame2:GetChildren() do
				if insObject:IsA("TextLabel") then
					srvTween:Create(insObject, TweenInfo.new(0.25), {["TextTransparency"] = 0}):Play()
				elseif insObject:IsA("GuiButton") then
					srvTween:Create(insObject, TweenInfo.new(0.25), {["BackgroundTransparency"] = 0, ["TextTransparency"] = 0}):Play()
				end
			end
		end

		wait(0.25)
	elseif (strTab == "Info") then
		insUIListLayout.Parent = insBox
		insUIGridLayout.Parent = nil

		for _, insTextLabel in next, tblInfoObjects do
			insTextLabel.Visible = true

			srvTween:Create(insTextLabel, TweenInfo.new(0.25), {["TextTransparency"] = 0}):Play()
		end

		wait(0.25)
	end

	for _, insTab in next, insTabs:GetChildren() do
		if insTab:IsA("GuiButton") then
			insTab.TextColor3 = Color3.fromHSV(tblSettings.TextColor[1], tblSettings.TextColor[2], tblSettings.TextColor[3])
		end
	end

	blnSwitchingTabs = false
end

for _, insTab in next, insTabs:GetChildren() do
	if insTab:IsA("GuiButton") then
		insTab.MouseButton1Up:Connect(function()
			if not(blnCollides(insTabs)) then return end

			voidSwitchTab(insTab.Name)
		end)
	end
end

insMain:TweenSize(UDim2.new(0.35 * tblSettings.GuiSizeMultiplier, 0, 0.21875 * tblSettings.GuiSizeMultiplier, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)

while wait() do
	for _, tblExploitData in next, tblExploits do
		if tblExploitData.Key and tblLoopingKeys[tblExploitData.Key] then
			coroutine.resume(coroutine.create(function() tblExploitData["Function"]() end))
		end
	end
end