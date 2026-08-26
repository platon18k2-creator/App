-- CaseServer.server.lua
-- Положи этот Script в ServerScriptService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShopItems = ReplicatedStorage:WaitForChild("ShopItems")

local openCaseEvent = ReplicatedStorage:FindFirstChild("OpenCase")
if not openCaseEvent then
	openCaseEvent = Instance.new("RemoteEvent")
	openCaseEvent.Name = "OpenCase"
	openCaseEvent.Parent = ReplicatedStorage
end

local CASE_PRICE = 1000
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

	tool:Clone().Parent = backpack
	return true
end

openCaseEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if cooldown[player] and now - cooldown[player] < COOLDOWN then
		return
	end
	cooldown[player] = now

	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")
	if not money or money.Value < CASE_PRICE then
		openCaseEvent:FireClient(player, {
			success = false,
			reason = "NOT_ENOUGH_MONEY",
			price = CASE_PRICE,
		})
		return
	end

	local winner = getRandomTool()
	if not winner then
		openCaseEvent:FireClient(player, {
			success = false,
			reason = "NO_ITEMS",
		})
		return
	end

	money.Value -= CASE_PRICE
	giveTool(player, winner)

	openCaseEvent:FireClient(player, {
		success = true,
		item = winner.Name,
		price = CASE_PRICE,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	cooldown[player] = nil
end)
