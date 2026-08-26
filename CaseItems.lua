-- CaseItems.lua
-- Не нужно вручную прописывать предметы в кейс.
-- Модуль сам берёт все Tool из ReplicatedStorage.ShopItems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopItems = ReplicatedStorage:WaitForChild("ShopItems")

local CaseItems = {}

local RARITIES = {
	{ Name = "COMMON", Chance = 60, Color = Color3.fromRGB(180, 180, 180) },
	{ Name = "RARE", Chance = 25, Color = Color3.fromRGB(70, 140, 255) },
	{ Name = "EPIC", Chance = 10, Color = Color3.fromRGB(180, 80, 255) },
	{ Name = "LEGENDARY", Chance = 5, Color = Color3.fromRGB(255, 190, 50) },
}

local function getRarity()
	local roll = math.random(1, 100)
	local sum = 0

	for _, rarity in ipairs(RARITIES) do
		sum += rarity.Chance
		if roll <= sum then
			return rarity
		end
	end

	return RARITIES[1]
end

local function getTools()
	local tools = {}

	for _, item in ipairs(ShopItems:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(tools, item)
		end
	end

	return tools
end

function CaseItems.GetAll()
	return getTools()
end

function CaseItems.GetRandom(count)
	count = math.max(1, math.floor(count or 1))

	local tools = getTools()
	local result = {}

	if #tools == 0 then
		return result
	end

	-- В одном открытии не повторяем один и тот же Tool.
	local pool = table.clone(tools)

	for _ = 1, math.min(count, #pool) do
		local index = math.random(1, #pool)
		local tool = table.remove(pool, index)
		local rarity = getRarity()

		table.insert(result, {
			Name = tool.Name,
			Tool = tool,
			Price = tool:GetAttribute("Price") or 1000,
			Rarity = rarity.Name,
			RarityChance = rarity.Chance,
			Color = rarity.Color,
		})
	end

	return result
end

function CaseItems.GetOne()
	local items = CaseItems.GetRandom(1)
	return items[1]
end

return CaseItems
