local combat = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Combat")

local UIS = game:GetService("UserInputService")
local RUN = game:GetService("RunService")

local target

function getHRP(chr)
	local HRP = chr:FindFirstChild("HumanoidRootPart") or chr:FindFirstChild("Torso") or chr:FindFirstChild("UpperTorso")
	return HRP
end


UIS.InputBegan:Connect(function(input, gp)
    if (input.KeyCode == Enum.KeyCode.Q) and not(gp) then
        local nearestPlayers = {}

		for i, v in pairs(game.Players:GetPlayers()) do
			if getHRP(v.Character) and getHRP(game.Players.LocalPlayer.Character) and v ~= game.Players.LocalPlayer then
				local distance = (getHRP(v.Character).Position - getHRP(game.Players.LocalPlayer.Character).Position).Magnitude

				table.insert(nearestPlayers, {v, distance})
			end
		end

		table.sort(nearestPlayers, 
			function(a, b)
				return a[2] < b[2]
			end
		)

		target = nearestPlayers[1][1] or game.Players.LocalPlayer
        
        -- combat:FireServer(1)
        wait(0.5)
        combat:FireServer(target.Character)
    end
end)