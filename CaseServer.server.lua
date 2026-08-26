-- CaseServer.server.lua
-- Положи этот Script в ServerScriptService в Roblox Studio.
-- Он создаёт RemoteEvent сам, поэтому вручную создавать его не нужно.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShopItems = ReplicatedStorage:WaitForChild("ShopItems")

local openCaseEvent = ReplicatedStorage:FindFirstChild("OpenCase")
if not openCaseEvent then
	openCaseEvent = Instance.new("RemoteEvent")
	openCaseEvent.Name = "OpenCase"
	openCaseEvent.Parent = ReplicatedStorage
end

local cooldown = {}
local COOLDOWN = 1

local function getRandomTool()
	local tools = {}
	for _, item in ipairs(ShopItems:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(tools, item)
		end
	end

	if #tools == 0 then
		return nil
	end

	return tools[math.random(1, #tools)]
end

local function giveTool(player, tool)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return false end

	local character = player.Character
	if character and character:FindFirstChild(tool.Name) then
		return true
	end
	if backpack:FindFirstChild(tool.Name) then
		return true
	end

	local clone = tool:Clone()
	clone.Parent = backpack
	return true
end

openCaseEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if cooldown[player] and now - cooldown[player] < COOLDOWN then
		return
	end
	cooldown[player] = now

	local winner = getRandomTool()
	if not winner then
		warn("CaseServer: в ReplicatedStorage.ShopItems нет Tool")
		return
	end

	giveTool(player, winner)
	openCaseEvent:FireClient(player, winner.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldown[player] = nil
end)
