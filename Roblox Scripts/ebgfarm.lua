if not game:IsLoaded() then
	game.Loaded:Wait()
end

_G.Settings = {
	["Grind Accounts"] = {
		"imgood"
	},
	["Farm Setting"] = 2,
	["Increase Cap"] = false,
	["Level"] = -1,
	["Shards"] = -1,
	["Kills"] = -1,
	["Layer"] = 11,
	["Place"] = "standard40",
	["Assist Mode"] = false
}

local lastupdate = "GUI Last Updated: 12-9-20 9:23 PM EST"
local whitelist = false

local s = {}

local GrindAccounts
local FarmSetting
local IncreaseCap
local Level
local Shards
local Kills
local Layer
local Place
local teleportto
local AssistMode

if typeof(_G.Settings) == typeof(s) then
	s = _G.Settings

	if typeof(s["Grind Accounts"]) == "table" then
		GrindAccounts = s["Grind Accounts"]
	else
		GrindAccounts = {}
		warn("Grind Account table not found! Local Player assumed to be a Victim.")
	end

	if tonumber(s["Farm Setting"]) ~= nil then
		FarmSetting = s["Farm Setting"]
	else
		FarmSetting = 1
		warn("Farm setting not found! Farm setting set to 1.")
	end

	if typeof(s["Increase Cap"]) == "boolean" then
		IncreaseCap = s["Increase Cap"]
	else
		IncreaseCap = false
	end

	if tonumber(s["Level"]) == nil then
		Level = -1
		warn("The level limit was incorrectly specified, or was not detected! The level limit was set to -1.")
	else
		Level = math.round(s["Level"])
	end

	if tonumber(s["Shards"]) == nil then
		Shards = -1
		warn("The shards limit was incorrectly specified, or was not detected! The shards limit was set to -1.")
	else
		Shards = math.round(s["Shards"])
	end

	if tonumber(s["Kills"]) == nil then
		Kills = -1
		warn("The kills limit was incorrectly specified, or was not detected! The kills limit was set to -1.")
	else
		Kills = math.round(s["Kills"])
	end

	if tonumber(s["Layer"]) ~= nil then
		Layer = math.round(s["Layer"])
	else
		Layer = 0
		warn("The layer increment was incorrectly specified, or was not detected! The layer was set to 0.")
	end

	if typeof(s["Assist Mode"]) == "boolean" then
		AssistMode = s["Assist Mode"]
	else
		AssistMode = false
	end

	local places = {
		566399244, 
		2569625809, 
		570158081, 
		537600204,
		520568240,
		554955560,
		602048550,
		575456646,
		1713986112,
		1243615612
	}

	s["Place"] = tostring(s["Place"]):lower()

	if s["Place"] == "standard" or s["Place"] == "566399244" then
		Place = "standard"
		teleportto = places[1]
	elseif s["Place"] == "standard40" or s["Place"] == "2569625809" then
		Place = "standard40"
		teleportto = places[2]
	elseif s["Place"] == "light" or s["Place"] == "570158081" then
		Place = "light"
		teleportto = places[3]
	elseif s["Place"] == "fire" or s["Place"] == "537600204" then
		Place = "fire"
		teleportto = places[4]
	elseif s["Place"] == "water" or s["Place"] == "520568240" then
		Place = "water"
		teleportto = places[5]
	elseif s["Place"] == "grass" or s["Place"] == "554955560" then
		Place = "grass"
		teleportto = places[6]
	elseif s["Place"] == "heaven" or s["Place"] == "602048550" then
		Place = "heaven"
		teleportto = places[7]
	elseif s["Place"] == "minilovania" or s["Place"] == "sans" or s["Place"] == "575456646" then
		Place = "minilovania"
		teleportto = places[8]
	elseif s["Place"] == "default" or s["Place"] == "tournament" or s["Place"] == "1713986112" then
		Place = "default"
		teleportto = places[9]
	elseif s["Place"] == "survival" or s["Place"] == "1243615612" then
		Place = "survival"
		teleportto = places[10]
	else
		Place = "default"
		teleportto = places[9]
		warn("The place was incorrectly specified, or was not detected! Place assumed to be Tournament.")
	end
else
	warn("No settings table found! Retrieving and using default settings.")
	GrindAccounts = {}
	FarmSetting = 1
	IncreaseCap = false
	Level = -1
	Shards = -1
	Kills = -1
	Layer = 0
	Place = "default"
	AssistMode = false

	teleportto = 1713986112
end

warn("Credits: This script was made by jaden#4143! Join my discord server at discord.gg/K2wewFWWFZ.")
warn("Settings:")
warn("Grind Accounts:")
for i, v in pairs(GrindAccounts) do
	if v ~= "" then
		warn(v)
	end
end
warn("Farm Setting: " .. FarmSetting)
warn("Increase Cap enabled: " .. tostring(IncreaseCap))
warn("Specified level limit: " .. Level)
warn("Specified shards limit: " .. Shards)
warn("Specified kill limit: " .. Kills)
warn("Specified layer: " .. Layer)
warn("Specified place: " .. Place)
warn("Assist Mode enabled: " .. tostring(AssistMode))

if true then
	function _G.antiAFK()
		warn("antiidle test")
		for i, v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
			v:Disable()
			warn('Anti idle is enabled')
		end
	end

	local isGrinder = false

	for i, v in pairs(GrindAccounts) do
		if v ~= "" then
			local givenName = string.lower(v)
			local lpName = game.Players.LocalPlayer.Name
			lpName = string.lower(lpName)
			local term = string.sub(lpName, 1, string.len(lpName))

			local match = string.find(term, givenName)

			if match then
				isGrinder = true
			end
		end
	end

	local RSR = game.ReplicatedStorage.Remotes

	if whitelist == true then
		repeat wait() until game.Workspace:FindFirstChild(".Ignore")
		if game.Workspace:WaitForChild(".Ignore")['.ServerEffects'].RainPos:WaitForChild("2", 5) then
			warn("You passed the script's whitelist! Please wait while the script enables.")

			whitelist = false
		else
			warn("You didn't pass the script whitelist! Contact the scripter if you think this is a mistake.")

			local blur = Instance.new("BlurEffect")
			blur.Size = 0
			blur.Parent = game:WaitForChild("Lighting")

			for i = 1, 20 do
				blur.Size = i
				wait(.1)
			end

			local tanerror = Instance.new("ScreenGui")
			local errorlabel = Instance.new("TextLabel")
			local errorframe = Instance.new("Frame")
			local Rejoin = Instance.new("TextButton")
			local Close = Instance.new("TextButton")

			tanerror.Name = "tanerror"
			tanerror.Parent = game:WaitForChild("CoreGui")
			tanerror.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			errorlabel.Name = "errorlabel"
			errorlabel.Parent = tanerror
			errorlabel.AnchorPoint = Vector2.new(0.5, 0.5)
			errorlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			errorlabel.BackgroundTransparency = 1.000
			errorlabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			errorlabel.Size = UDim2.new(1, 0, 0.75, 0)
			errorlabel.Font = Enum.Font.SciFi
			errorlabel.Text = ""
			errorlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			errorlabel.TextScaled = true
			errorlabel.TextSize = 14.000
			errorlabel.TextStrokeTransparency = 0.000
			errorlabel.TextWrapped = true
			errorlabel.TextYAlignment = Enum.TextYAlignment.Top

			errorframe.Name = "errorframe"
			errorframe.Parent = tanerror
			errorframe.AnchorPoint = Vector2.new(0.5, 1)
			errorframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			errorframe.BackgroundTransparency = 0.500
			errorframe.Position = UDim2.new(0.5, 0, 1.25, 0)
			errorframe.Size = UDim2.new(0.300000012, 0, 0, 107)
			errorframe.ZIndex = 5

			Rejoin.Name = "Rejoin"
			Rejoin.Parent = errorframe
			Rejoin.AnchorPoint = Vector2.new(0, 0.5)
			Rejoin.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			Rejoin.BorderColor3 = Color3.fromRGB(255, 255, 255)
			Rejoin.Position = UDim2.new(0.0392644666, 0, 0.495518774, 0)
			Rejoin.Size = UDim2.new(0.449999988, 0, 0.663999975, 0)
			Rejoin.Font = Enum.Font.SciFi
			Rejoin.Text = "Rejoin"
			Rejoin.TextColor3 = Color3.fromRGB(255, 255, 255)
			Rejoin.TextScaled = true
			Rejoin.TextSize = 14.000
			Rejoin.TextWrapped = true
			Rejoin.ZIndex = 6

			Close.Name = "Close"
			Close.Parent = errorframe
			Close.AnchorPoint = Vector2.new(1, 0.5)
			Close.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			Close.BorderColor3 = Color3.fromRGB(255, 255, 255)
			Close.Position = UDim2.new(0.960476518, 0, 0.495518774, 0)
			Close.Size = UDim2.new(0.449999988, 0, 0.663999975, 0)
			Close.Font = Enum.Font.SciFi
			Close.Text = "Close"
			Close.TextColor3 = Color3.fromRGB(255, 255, 255)
			Close.TextScaled = true
			Close.TextSize = 14.000
			Close.TextWrapped = true
			Close.ZIndex = 6

			Rejoin.MouseButton1Down:Connect(function()
				errorframe:TweenPosition(
					UDim2.new(0.5, 0, 1.25, 0),
					"In",
					"Quad",
					1,
					true
				)
				wait(1)
				local ts = game:GetService("TeleportService")
				local p = game:GetService("Players").LocalPlayer

				ts:Teleport(game.PlaceId, p)
			end)

			Close.MouseButton1Down:Connect(function()
				errorframe:TweenPosition(
					UDim2.new(0.5, 0, 1.25, 0),
					"In",
					"Quad",
					1,
					true
				)

				wait(1)

				for i = 20, 0, -1 do
					errorlabel.TextTransparency = 1 - (i / 20)
					errorlabel.TextStrokeTransparency = 1 - (i / 20)
					blur.Size = i
					wait(.1)
				end

				blur.Size = 0

				blur:Destroy()
				tanerror:Destroy()
			end)

			errorframe:TweenPosition(
				UDim2.new(0.5, 0, 1, 0),
				"Out",
				"Quad",
				1,
				true
			)

			local errorText = "Your Client-ID was not found in the whitelist system.\n To be whitelisted, join scrypt0r's server,\n discord.gg/K2wewFWWFZ\n When you join, open a support ticket\n in the #support-only channel.\n Prove who you are, and your proof of purchase.\n Then, send your Roblox Client-ID which has\n been copied to your clipboard."

			local clientid = game:GetService("RbxAnalyticsService"):GetClientId()
			pcall(function() setclipboard(clientid) end)

			for i = 1, #errorText do
				local displayText = string.sub(errorText, 1, i)
				errorlabel.Text = displayText
				wait(0.075)
			end
		end
	end

	if whitelist == false then	
		local askteleport = Instance.new("ScreenGui")
		local label = Instance.new("ImageLabel")
		local accept = Instance.new("ImageButton")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local cancel = Instance.new("ImageButton")
		local farmrequest = Instance.new("TextLabel")

		askteleport.Name = "askteleport"
		askteleport.Parent = game:WaitForChild("CoreGui")
		askteleport.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		label.Name = "label"
		label.Parent = askteleport
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.BackgroundTransparency = 1.000
		label.Position = UDim2.new(0.5, 0, 0.5, 0)
		label.Size = UDim2.new(0.5, 0, 0.25, 0)
		label.SizeConstraint = Enum.SizeConstraint.RelativeYY
		label.Image = "rbxassetid://572159082"
		label.Active = true
		label.Draggable = true

		accept.Name = "accept"
		accept.Parent = label
		accept.AnchorPoint = Vector2.new(0.5, 0.5)
		accept.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		accept.BorderSizePixel = 2
		accept.Position = UDim2.new(0.25, 0, 0.699999988, 0)
		accept.Size = UDim2.new(0.19366394, 0, 0.166115731, 0)
		accept.Image = "rbxassetid://572226841"

		UIAspectRatioConstraint.Parent = label
		UIAspectRatioConstraint.AspectRatio = 2.000

		cancel.Name = "cancel"
		cancel.Parent = label
		cancel.AnchorPoint = Vector2.new(0.5, 0.5)
		cancel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		cancel.BorderSizePixel = 2
		cancel.Position = UDim2.new(0.75, 0, 0.699999988, 0)
		cancel.Size = UDim2.new(0.19366394, 0, 0.166115731, 0)
		cancel.Image = "rbxassetid://572226843"

		farmrequest.Name = "farmrequest"
		farmrequest.Parent = label
		farmrequest.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		farmrequest.BackgroundTransparency = 1.000
		farmrequest.Position = UDim2.new(0.162534431, 0, 0.137741044, 0)
		farmrequest.Size = UDim2.new(0.672176301, 0, 0.413223147, 0)
		farmrequest.Font = Enum.Font.Fantasy
		farmrequest.Text = "Click accept if you are using this account to farm kills currently, and press cancel if you are not."
		farmrequest.TextColor3 = Color3.fromRGB(255, 255, 255)
		farmrequest.TextScaled = true
		farmrequest.TextSize = 14.000
		farmrequest.TextWrapped = true

		cancel.MouseButton1Down:connect(function()
			askteleport:Destroy()
		end)

		accept.MouseButton1Down:connect(function()
			askteleport:Destroy()
		
			if game.PlaceId ~= teleportto then
				game:GetService("TeleportService"):Teleport(teleportto)
			else
				spawn(function() 
					pcall(_G.antiAFK) 
				end)
				
				local player = game.Players.LocalPlayer

				local newlayer = 100000 + (Layer * 75)

				local deathplate = Instance.new("Part")
				deathplate.Size = Vector3.new(40, 1, 40)
				deathplate.Position = Vector3.new(0, newlayer, 0)
				deathplate.Anchored = true
				deathplate.Reflectance = 0.5
				deathplate.Transparency = 0.5
				deathplate.Parent = game.Workspace

				local box = Instance.new("Part")
				box.Size = Vector3.new(40, 40, 40)
				box.Position = Vector3.new(0, newlayer + 20, 0)
				box.Anchored = true
				box.Transparency = 0.5
				box.CanCollide = false
				box.Parent = game.Workspace

				local UIS = game:GetService("UserInputService")

				UIS.InputBegan:connect(function(input, gp)
					if not gp then
						if input.KeyCode == Enum.KeyCode.L then
							RSR.DoClientMagic:FireServer("Time", "Genesis Ray", game.Players.LocalPlayer.Character.HumanoidRootPart.Position)
							RSR.DoMagic:InvokeServer("Time", "Genesis Ray", {lv = Vector3.new(0, 0, 0), charge = 1000000})
						elseif UIS:IsKeyDown(Enum.KeyCode.K) then
							_G.counting = true
							local i = 0
							while _G.counting do
								wait(1)
								i = i + 1
								if i == 5 then
									game.Players.LocalPlayer:Kick("Forced kick by client.")
								end
							end
							i = 0
						elseif input.KeyCode == Enum.KeyCode.J then
							game:GetService("TeleportService"):Teleport(game.PlaceId)
						elseif input.KeyCode == Enum.KeyCode.H then
							player.Character:BreakJoints()
						end
					end
				end)

				UIS.InputEnded:connect(function(input, typing)
					if input.KeyCode == Enum.KeyCode.K and not typing then
						_G.counting = false
					end
				end)

				function getRoot(char)
					local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
					return rootPart
				end
				
				if game.PlaceId == 1243615612 then
					local farmstatistics = Instance.new("ScreenGui")
					farmstatistics.Name = "farmstatistics"
					farmstatistics.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
					farmstatistics.Parent = game.CoreGui

					local statisticsframe = Instance.new("Frame")
					statisticsframe.Name = "statisticsframe"
					statisticsframe.AnchorPoint = Vector2.new(0.5, 0.5)
					statisticsframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					statisticsframe.BackgroundTransparency = 0.500
					statisticsframe.BorderColor3 = Color3.fromRGB(0, 0, 0)
					statisticsframe.BorderSizePixel = 0
					statisticsframe.Position = UDim2.new(0.5, 0, 0.5, 0)
					statisticsframe.Size = UDim2.new(0.300000012, 0, 0.300000012, 0)
					statisticsframe.SizeConstraint = Enum.SizeConstraint.RelativeYY
					statisticsframe.Parent = farmstatistics
					statisticsframe.Active = true
					statisticsframe.Draggable = true

					local frame = Instance.new("Frame")
					frame.Name = "frame"
					frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
					frame.Position = UDim2.new(0.0682241619, 0, 0.0744037926, 0)
					frame.Size = UDim2.new(0.854368925, 0, 0.847976983, 0)
					frame.Parent = statisticsframe

					local statistics = Instance.new("TextLabel")
					statistics.Name = "statistics"
					statistics.AnchorPoint = Vector2.new(0.5, 0.5)
					statistics.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					statistics.BackgroundTransparency = 1.000
					statistics.BorderColor3 = Color3.fromRGB(0, 0, 0)
					statistics.Position = UDim2.new(0.505323112, 0, 0.0871111229, 0)
					statistics.Size = UDim2.new(1.0103097, 0, 0.178678378, 0)
					statistics.Font = Enum.Font.SciFi
					statistics.Text = "Statistics:"
					statistics.TextColor3 = Color3.fromRGB(255, 255, 255)
					statistics.TextScaled = true
					statistics.TextSize = 14.000
					statistics.TextWrapped = true
					statistics.Parent = frame

					local data = {}

					local levels = Instance.new("TextLabel")
					levels.Name = "levels"
					levels.Text = "+nil level(s)"
					levels.Position = UDim2.new(0.499949098, 0, 0.330869198, 0)
					table.insert(data, levels)

					local kills = Instance.new("TextLabel")
					kills.Name = "kills"
					kills.Text = "+nil kill(s)"
					kills.Position = UDim2.new(0.499949098, 0, 0.442363471, 0)
					table.insert(data, kills)

					local shards = Instance.new("TextLabel")
					shards.Name = "shards"
					shards.Text = "+nil shard(s)"
					shards.Position = UDim2.new(0.499949098, 0, 0.548721313, 0)
					table.insert(data, shards)

					local diamonds = Instance.new("TextLabel")
					diamonds.Name = "diamonds"
					diamonds.Text = "+nil diamond(s)"
					diamonds.Position = UDim2.new(0.499949098, 0, 0.655079186, 0)
					table.insert(data, diamonds)

					local since = Instance.new("TextLabel")
					since.Name = "since"
					since.Parent = frame
					since.AnchorPoint = Vector2.new(0.5, 0.5)
					since.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					since.BackgroundTransparency = 1.000
					since.BorderColor3 = Color3.fromRGB(0, 0, 0)
					since.Position = UDim2.new(0.494575113, 0, 0.881646156, 0)
					since.Size = UDim2.new(1.0103097, 0, 0.227408841, 0)
					since.Font = Enum.Font.SciFi
					since.Text = "Since nil"
					since.TextColor3 = Color3.fromRGB(255, 255, 255)
					since.TextScaled = true
					since.TextSize = 18.000
					since.TextWrapped = true

					for i, v in pairs(data) do
						v.AnchorPoint = Vector2.new(0.5, 0.5)
						v.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
						v.BackgroundTransparency = 1.000
						v.BorderColor3 = Color3.fromRGB(0, 0, 0)
						v.Size = UDim2.new(1.0103097, 0, 0.113704421, 0)
						v.Font = Enum.Font.SciFi
						v.TextColor3 = Color3.fromRGB(255, 255, 255)
						v.TextScaled = true
						v.TextSize = 18.000
						v.TextWrapped = true
						v.Parent = frame
					end
					
					local firstLevel = game.Players.LocalPlayer.leaderstats.Level.Value
					local firstKills = game.Players.LocalPlayer.leaderstats.Kills.Value
					local firstShards = game.Players.LocalPlayer.leaderstats.Shards.Value
					local firstDiamonds = tonumber(game.Players.LocalPlayer.PlayerGui.Main.Frame1.Diamonds.TextLabel.Text)

					local levelsGained = 0
					local killsGained = 0
					local shardsGained = 0
					local diamondsGained = 0

					local time = os.date("*t", os.time())
					local date = string.gsub(os.date("%x", os.time()), "/", "-")

					local displayedmin
					local displayedsec

					if time.min < 10 then
						displayedmin = "0" .. time.min
					else
						displayedmin = time.min
					end

					if time.sec < 10 then
						displayedsec = "0" .. time.sec
					else
						displayedsec = time.sec
					end

					if time.hour >= 12 then
						if time.hour == 12 then
							since.Text = "Since " .. time.hour .. ":" .. displayedmin .. ":" .. displayedsec .. " PM on " .. date
						else
							since.Text = "Since " .. time.hour - 12 .. ":" .. displayedmin .. ":" .. displayedsec .. " PM on " .. date
						end
					else
						if time.hour == 0 then
							since.Text = "Since " .. time.hour + 12 .. ":" .. displayedmin .. ":" .. displayedsec .. " AM on " .. date
						else
							since.Text = "Since " .. time.hour .. ":" .. displayedmin .. ":" .. displayedsec .. " AM on " .. date
						end
					end

					spawn(function()
						while wait() do
							levelsGained = game.Players.LocalPlayer.leaderstats.Level.Value - firstLevel
							killsGained = game.Players.LocalPlayer.leaderstats.Kills.Value - firstKills
							shardsGained = (game.Players.LocalPlayer.leaderstats.Shards.Value - firstShards) + (levelsGained * 10000)
							diamondsGained = tonumber(game.Players.LocalPlayer.PlayerGui.Main.Frame1.Diamonds.TextLabel.Text) - firstDiamonds

							levels.Text = "+" .. levelsGained .. " level(s)"
							kills.Text = "+" .. killsGained .. " kill(s)"
							shards.Text = "+" .. shardsGained .. " shard(s)"
							diamonds.Text = "+" .. diamondsGained .. " diamond(s)"

							if Level >= 0 then
								if Level < 225 then
									if game.Players.LocalPlayer.leaderstats.Level.Value >= Level then
										game.Players.LocalPlayer:Kick("You reached the level limit that you specified: " .. Level)
									end
								end
							end
							if Shards >= 0 then
								if game.Players.LocalPlayer.leaderstats.Shards.Value >= Shards then
									game.Players.LocalPlayer:Kick("You reached the shards limit that you specified: " .. Shards)
								end
							end
							if Kills >= 0 then
								if game.Players.LocalPlayer.leaderstats.Kills.Value >= Kills then
									game.Players.LocalPlayer:Kick("You reached the kills limit that you specified: " .. Kills)
								end
							end
							if IncreaseCap then
								if (game.Players.LocalPlayer.leaderstats.Level.Value < Level) or (Level < 0) then
									RSR.IncreaseCap:FireServer()
								end
							end
						end 
					end)
					
					while wait() do
						repeat wait() until getRoot(player.Character)
						
						for i, v in pairs(game.Workspace.enemies:GetChildren()) do
							if getRoot(player.Character) and v:FindFirstChild("Humanoid") and (v.Humanoid.Health ~= 0) then
								v:FindFirstChild("HumanoidRootPart").Anchored = true
								v:FindFirstChild("HumanoidRootPart").CFrame = getRoot(player.Character).CFrame * CFrame.new(0, 0, -16)
							end
						end
						
						RSR.DoClientMagic:FireServer("Water", "Water Tumble", (getRoot(player.Character).CFrame * CFrame.new(0, 1, -16)).Position)
						RSR.DoMagic:InvokeServer("Water", "Water Tumble", {Position = (getRoot(player.Character).CFrame * CFrame.new(0, 1, -16))})
						
						RSR.DoClientMagic:FireServer("Earth", "Aciculated Spikes")
						RSR.DoMagic:InvokeServer("Earth", "Aciculated Spikes")
					end
				elseif AssistMode then
					local assistingPlayers = {}

					player.CharacterAdded:connect(function()
						for i, v in pairs(game.Players:GetPlayers()) do
							for i2, v2 in pairs(GrindAccounts) do
								if v2 ~= "" then
									local givenName = string.lower(v.Name)
									local givenName2 = string.lower(v2)
									local term = string.sub(givenName2, 1, string.len(givenName2))

									local match = string.find(givenName, givenName2)

									if match then
										table.insert(assistingPlayers, v.Name)
									end
								end
							end
						end

						for i, v in pairs(assistingPlayers) do
							if not game.Players:FindFirstChild(v) then
								table.remove(assistingPlayers, i)
							end
						end

						local randomNum = math.random(1, #assistingPlayers)

						repeat wait() until getRoot(player.Character) and getRoot(game.Players[assistingPlayers[randomNum]].Character)

						pcall(function()
							wait(.1)
							getRoot(player.Character).CFrame = getRoot(game.Players[assistingPlayers[randomNum]].Character).CFrame
						end)

						local humanoid = player.Character:WaitForChild("Humanoid")
						humanoid.HealthChanged:Wait()

						player.Character:BreakJoints()
					end)
				elseif isGrinder then
					local farmstatistics = Instance.new("ScreenGui")
					farmstatistics.Name = "farmstatistics"
					farmstatistics.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
					farmstatistics.Parent = game.CoreGui

					local statisticsframe = Instance.new("Frame")
					statisticsframe.Name = "statisticsframe"
					statisticsframe.AnchorPoint = Vector2.new(0.5, 0.5)
					statisticsframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					statisticsframe.BackgroundTransparency = 0.500
					statisticsframe.BorderColor3 = Color3.fromRGB(0, 0, 0)
					statisticsframe.BorderSizePixel = 0
					statisticsframe.Position = UDim2.new(0.5, 0, 0.5, 0)
					statisticsframe.Size = UDim2.new(0.300000012, 0, 0.300000012, 0)
					statisticsframe.SizeConstraint = Enum.SizeConstraint.RelativeYY
					statisticsframe.Parent = farmstatistics
					statisticsframe.Active = true
					statisticsframe.Draggable = true

					local frame = Instance.new("Frame")
					frame.Name = "frame"
					frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
					frame.Position = UDim2.new(0.0682241619, 0, 0.0744037926, 0)
					frame.Size = UDim2.new(0.854368925, 0, 0.847976983, 0)
					frame.Parent = statisticsframe

					local statistics = Instance.new("TextLabel")
					statistics.Name = "statistics"
					statistics.AnchorPoint = Vector2.new(0.5, 0.5)
					statistics.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					statistics.BackgroundTransparency = 1.000
					statistics.BorderColor3 = Color3.fromRGB(0, 0, 0)
					statistics.Position = UDim2.new(0.505323112, 0, 0.0871111229, 0)
					statistics.Size = UDim2.new(1.0103097, 0, 0.178678378, 0)
					statistics.Font = Enum.Font.SciFi
					statistics.Text = "Statistics:"
					statistics.TextColor3 = Color3.fromRGB(255, 255, 255)
					statistics.TextScaled = true
					statistics.TextSize = 14.000
					statistics.TextWrapped = true
					statistics.Parent = frame

					local data = {}

					local levels = Instance.new("TextLabel")
					levels.Name = "levels"
					levels.Text = "+nil level(s)"
					levels.Position = UDim2.new(0.499949098, 0, 0.330869198, 0)
					table.insert(data, levels)

					local kills = Instance.new("TextLabel")
					kills.Name = "kills"
					kills.Text = "+nil kill(s)"
					kills.Position = UDim2.new(0.499949098, 0, 0.442363471, 0)
					table.insert(data, kills)

					local shards = Instance.new("TextLabel")
					shards.Name = "shards"
					shards.Text = "+nil shard(s)"
					shards.Position = UDim2.new(0.499949098, 0, 0.548721313, 0)
					table.insert(data, shards)

					local diamonds = Instance.new("TextLabel")
					diamonds.Name = "diamonds"
					diamonds.Text = "+nil diamond(s)"
					diamonds.Position = UDim2.new(0.499949098, 0, 0.655079186, 0)
					table.insert(data, diamonds)

					local since = Instance.new("TextLabel")
					since.Name = "since"
					since.Parent = frame
					since.AnchorPoint = Vector2.new(0.5, 0.5)
					since.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					since.BackgroundTransparency = 1.000
					since.BorderColor3 = Color3.fromRGB(0, 0, 0)
					since.Position = UDim2.new(0.494575113, 0, 0.881646156, 0)
					since.Size = UDim2.new(1.0103097, 0, 0.227408841, 0)
					since.Font = Enum.Font.SciFi
					since.Text = "Since nil"
					since.TextColor3 = Color3.fromRGB(255, 255, 255)
					since.TextScaled = true
					since.TextSize = 18.000
					since.TextWrapped = true

					for i, v in pairs(data) do
						v.AnchorPoint = Vector2.new(0.5, 0.5)
						v.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
						v.BackgroundTransparency = 1.000
						v.BorderColor3 = Color3.fromRGB(0, 0, 0)
						v.Size = UDim2.new(1.0103097, 0, 0.113704421, 0)
						v.Font = Enum.Font.SciFi
						v.TextColor3 = Color3.fromRGB(255, 255, 255)
						v.TextScaled = true
						v.TextSize = 18.000
						v.TextWrapped = true
						v.Parent = frame
					end

					local function grinderSpawn()
						repeat wait() until getRoot(player.Character)

						pcall(function()
							if FarmSetting == 1 then
								getRoot(player.Character).CFrame = CFrame.new(Vector3.new(0, newlayer + 3, 10))
							elseif FarmSetting == 2 then
								getRoot(player.Character).CFrame = CFrame.new(Vector3.new(0, newlayer + 3, -10))
							elseif FarmSetting == 3 then
								getRoot(player.Character).CFrame = CFrame.new(Vector3.new(0, newlayer + 3, 10))
							elseif FarmSetting == 4 then
								getRoot(player.Character).CFrame =CFrame.new(Vector3.new(0, newlayer + 3, -10))
							else
								getRoot(player.Character).CFrame = CFrame.new(Vector3.new(0, newlayer + 3, 10))
							end
						end)
					end

					grinderSpawn()

					player.CharacterAdded:connect(grinderSpawn)

					local firstLevel = game.Players.LocalPlayer.leaderstats.Level.Value
					local firstKills = game.Players.LocalPlayer.leaderstats.Kills.Value
					local firstShards = game.Players.LocalPlayer.leaderstats.Shards.Value
					local firstDiamonds = tonumber(game.Players.LocalPlayer.PlayerGui.Main.Frame1.Diamonds.TextLabel.Text)

					local levelsGained = 0
					local killsGained = 0
					local shardsGained = 0
					local diamondsGained = 0

					local time = os.date("*t", os.time())
					local date = string.gsub(os.date("%x", os.time()), "/", "-")

					local displayedmin
					local displayedsec

					if time.min < 10 then
						displayedmin = "0" .. time.min
					else
						displayedmin = time.min
					end

					if time.sec < 10 then
						displayedsec = "0" .. time.sec
					else
						displayedsec = time.sec
					end

					if time.hour >= 12 then
						if time.hour == 12 then
							since.Text = "Since " .. time.hour .. ":" .. displayedmin .. ":" .. displayedsec .. " PM on " .. date
						else
							since.Text = "Since " .. time.hour - 12 .. ":" .. displayedmin .. ":" .. displayedsec .. " PM on " .. date
						end
					else
						if time.hour == 0 then
							since.Text = "Since " .. time.hour + 12 .. ":" .. displayedmin .. ":" .. displayedsec .. " AM on " .. date
						else
							since.Text = "Since " .. time.hour .. ":" .. displayedmin .. ":" .. displayedsec .. " AM on " .. date
						end
					end

					spawn(function()
						while wait() do
							levelsGained = game.Players.LocalPlayer.leaderstats.Level.Value - firstLevel
							killsGained = game.Players.LocalPlayer.leaderstats.Kills.Value - firstKills
							shardsGained = (game.Players.LocalPlayer.leaderstats.Shards.Value - firstShards) + (levelsGained * 10000)
							diamondsGained = tonumber(game.Players.LocalPlayer.PlayerGui.Main.Frame1.Diamonds.TextLabel.Text) - firstDiamonds

							levels.Text = "+" .. levelsGained .. " level(s)"
							kills.Text = "+" .. killsGained .. " kill(s)"
							shards.Text = "+" .. shardsGained .. " shard(s)"
							diamonds.Text = "+" .. diamondsGained .. " diamond(s)"

							if Level >= 0 then
								if Level < 225 then
									if game.Players.LocalPlayer.leaderstats.Level.Value >= Level then
										game.Players.LocalPlayer:Kick("You reached the level limit that you specified: " .. Level)
									end
								end
							end
							if Shards >= 0 then
								if game.Players.LocalPlayer.leaderstats.Shards.Value >= Shards then
									game.Players.LocalPlayer:Kick("You reached the shards limit that you specified: " .. Shards)
								end
							end
							if Kills >= 0 then
								if game.Players.LocalPlayer.leaderstats.Kills.Value >= Kills then
									game.Players.LocalPlayer:Kick("You reached the kills limit that you specified: " .. Kills)
								end
							end
							if IncreaseCap then
								if (game.Players.LocalPlayer.leaderstats.Level.Value < Level) or (Level < 0) then
									RSR.IncreaseCap:FireServer()
								end
							end
						end 
					end)

					warn("Grind Script successfully loaded!")
					warn(lastupdate)

					while wait(0.5) do
						if FarmSetting == 1 then
							RSR.DoClientMagic:FireServer("Water", "Water Stream")
							RSR.DoMagic:InvokeServer("Water", "Water Stream")
							wait(6)
						elseif FarmSetting == 2 then
							RSR.DoClientMagic:FireServer("Ice", "Perilous Hail")
							RSR.DoMagic:InvokeServer("Ice", "Perilous Hail")
							wait(6)
						elseif FarmSetting == 3 then
							RSR.DoClientMagic:FireServer("Gravity", "Gravital Globe")
							RSR.DoMagic:InvokeServer("Gravity", "Gravital Globe", {lastPos = Vector3.new(0, newlayer + 3, 10)})
							wait(13)
						elseif FarmSetting == 4 then
							RSR.DoClientMagic:FireServer("Gravity", "Gravital Globe")
							RSR.DoMagic:InvokeServer("Gravity", "Gravital Globe", {lastPos = Vector3.new(0, newlayer + 3, 10)})
							wait(11)
							RSR.DoClientMagic:FireServer("Ice", "Perilous Hail")
							RSR.DoMagic:InvokeServer("Ice", "Perilous Hail")
							wait(2)
						end
					end
				else
					local function victimSpawn()
						repeat wait() until getRoot(player.Character)

						pcall(function()
							wait(.1)
							getRoot(player.Character).CFrame = CFrame.new(Vector3.new(0, newlayer + 3, -10))
						end)

						local humanoid = player.Character:WaitForChild("Humanoid")
						humanoid.HealthChanged:Wait()

						player.Character:BreakJoints()
					end

					victimSpawn()

					player.CharacterAdded:connect(victimSpawn)

					warn("Victim Script successfully loaded!")
					warn(lastupdate)
				end
			end
		end)
	end
else
	warn("The script was disabled! Do not remove my credits!")
end