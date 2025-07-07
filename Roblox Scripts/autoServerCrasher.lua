game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fx"):Destroy()

local tblPlaces = {
	566399244, -- standard
	2569625809, -- standard 40
	570158081, -- light
	537600204, -- fire
	-- 520568240, -- water
	-- 554955560, -- grass
	-- 602048550, -- heaven
	575456646, -- sans
	1243615612, -- survival
}

while wait() do
    --[[for i, connection in pairs(getconnections(game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fx").OnClientEvent)) do
        connection:Disable() 
    end]]
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DoClientMagic"):FireServer("Storm", "Lightning Flash")
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DoMagic"):InvokeServer("Storm", "Lightning Flash", {["End"] = Vector3.new(0, 0, 0), ["Origin"] = Vector3.new(0, math.huge, 0)})

    pcall(function()
		local numPlace = tblPlaces[math.random(1, #tblPlaces)]
	
		if (math.random(0, 1) == 1) then
			if (#(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. numPlace .. "/servers/Public?sortOrder=Asc&limit=100")).data) ~= 0) then
				game:GetService("TeleportService"):Teleport(numPlace)
			end
		end
	
        local tblServers = {}

        for _, tblServer in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
	        if (type(tblServer) == "table") and (tblServer.maxPlayers > tblServer.playing) and (tblServer.id ~= game.JobId) then
		        tblServers[#tblServers + 1] = tblServer.id
	        end
        end

        if (#tblServers > 0) then
	        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, tblServers[math.random(1, #tblServers)])
        end
    end)
end
