if not(game:IsLoaded()) then
    game.Loaded:Wait()
end

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fx"):WaitForChild("Proxy")

for _, v in next, getconnections(game.ReplicatedStorage.Remotes.Fx.OnClientEvent) do
    v:Disable()
end

game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(name, ...)
    local args = {...}
    if (name == "Lightning") then
        local pos1 = args[1]
        local pos2 = args[2]
        if ((pos1 - pos2).magnitude >= 2500) then return end
    end
    game.ReplicatedStorage.Remotes.Fx.Proxy:Fire(name,...)
end)