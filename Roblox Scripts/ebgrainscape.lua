if game.Workspace:WaitForChild(".Ignore", 5) then
    game.Lighting:ClearAllChildren()
    
    local insClouds = Instance.new("Clouds")
    insClouds.Cover = 0.8
    insClouds.Density = 1
    insClouds.Color = Color3.fromRGB(128, 128, 128)
    insClouds.Parent = game.Workspace.Terrain
    
    local insAtmosphere = Instance.new("Atmosphere")
    insAtmosphere.Density = 0.258
    insAtmosphere.Offset = 0.182
    insAtmosphere.Color = Color3.new(1, 1, 1)
    insAtmosphere.Decay = Color3.new(1, 1, 1)
    insAtmosphere.Glare = 0.85
    insAtmosphere.Haze = 1.45
    insAtmosphere.Parent = game.Lighting
    
    local insBloom = Instance.new("BloomEffect")
    insBloom.Intensity = 1
    insBloom.Size = 24
    insBloom.Threshold = 2
    insBloom.Parent = game.Lighting
    
    local insBlur = Instance.new("BlurEffect")
    insBlur.Size = 2
    insBlur.Parent = game.Lighting
    
    local insColorCorrection = Instance.new("ColorCorrectionEffect")
    insColorCorrection.Brightness = -0.1
    insColorCorrection.Contrast = 0.1
    insColorCorrection.Saturation = 0.2
    insColorCorrection.TintColor = Color3.new(1, 1, 1)
    insColorCorrection.Name = "ColorCorrection [REAL]"
    insColorCorrection.Parent = game.Lighting
    
    local insDepthOfField = Instance.new("DepthOfFieldEffect")
    insDepthOfField.FarIntensity = 1
    insDepthOfField.FocusDistance = 250
    insDepthOfField.InFocusRadius = 1.5
    insDepthOfField.NearIntensity = 0
    insDepthOfField.Parent = game.Lighting
    
    local insSunRays = Instance.new("SunRaysEffect")
    insSunRays.Intensity = 0.047
    insSunRays.Spread = 0.797
    insSunRays.Parent = game.Lighting
    
    local insIgnore = game.Workspace:WaitForChild(".Ignore")
	local insCurrentCAM = game.Workspace.CurrentCamera
	
	local insRainAudio = Instance.new("Sound")
	insRainAudio.Looped = true
	insRainAudio.SoundId = "rbxassetid://283164593"
	insRainAudio.Volume = 1
	insRainAudio.Parent = workspace
	insRainAudio:Play()

	local insRainingPart = Instance.new("Part")
	insRainingPart.Size = Vector3.new(500, 250, 500)
	insRainingPart.Transparency = 1
	insRainingPart.Anchored = true
	insRainingPart.CanCollide = false

	local insRain = game:GetService("ReplicatedStorage"):WaitForChild("Effects"):WaitForChild("Rain")
	insRain.Texture = "rbxassetid://241868005"
	insRain.Rate = insRainingPart.Size.Magnitude
	insRain.Size = NumberSequence.new(10)
	insRain.Speed = NumberRange.new(-200)
	insRain.Color = ColorSequence.new(Color3.fromRGB(46, 126, 255))
	insRain.Lifetime = NumberRange.new(0.5)
	insRain.Parent = insRainingPart
	insRainingPart.Parent = insIgnore
	
	game:GetService("RunService"):BindToRenderStep("Rain", Enum.RenderPriority.Camera.Value, function()
	    local rcp = RaycastParams.new()
		rcp.FilterType = Enum.RaycastFilterType.Blacklist
		rcp.FilterDescendantsInstances = {insIgnore, game.Players.LocalPlayer.Character}

		local rcrRaycast = workspace:Raycast(insCurrentCAM.CFrame.Position, Vector3.new(0, 100, 0), rcp)
		if rcrRaycast then
			insRain.Enabled = false
			insRainAudio.Volume = 0.5
			return
		end
		
		insRainingPart.Position = insCurrentCAM.CFrame.Position + Vector3.new(0, 100, 0)
		insRain.Rate = insRainingPart.Size.Magnitude
		insRain.Enabled = true
		insRainAudio.Volume = 1
	end)
	
	for _, insPart in next, game.Workspace["Map"]:GetDescendants() do
	    if insPart:IsA("BasePart") then
	        if (insPart.Material == Enum.Material.Sand) then
	            insPart.Material = "Slate"
	            insPart.Color = Color3.fromRGB(99, 99, 103)
	        end
	        
	        if (insPart.Color == Color3.fromRGB(106, 57, 9)) then
	            local tblColors = {
	                Color3.fromRGB(106, 57, 9),
	                Color3.fromRGB(86, 66, 54),
	                Color3.fromRGB(118, 86, 86)
	            }
	            
	            insPart.Color = tblColors[math.random(#tblColors)]
	        end
	        
	        if (insPart.Material == Enum.Material.Grass) then
	           insPart.Color = Color3.fromRGB(78, 106, 65)
	        end
	    end
	end
	
	game.Lighting.ClockTime = 18
	local twnHour
	
	local function voidTweenHour(numTime)
	    twnHour = game:GetService("TweenService"):Create(game:GetService("Lighting"), TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ClockTime = numTime})

	    local cncCycleCompleted
	    cncCycleCompleted = twnHour.Completed:Connect(function()
		    game:GetService("Lighting").ClockTime = (game:GetService("Lighting").ClockTime < 24) and game:GetService("Lighting").ClockTime or 0
		    voidTweenHour(game:GetService("Lighting").ClockTime + 0.25)
		    cncCycleCompleted:Disconnect()
	    end)

	    twnHour:Play()
	end

    voidTweenHour(game:GetService("Lighting").ClockTime + 0.25)
end