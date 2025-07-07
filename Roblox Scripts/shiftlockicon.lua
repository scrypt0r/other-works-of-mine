if not(game:IsLoaded()) then
	game.Loaded:Wait()
end

local objMouse = game:GetService("Players").LocalPlayer:GetMouse()

game:GetService("RunService").RenderStepped:Connect(function(numStep)
	objMouse.Icon = "rbxasset://textures/MouseLockedCursor.png"
end)