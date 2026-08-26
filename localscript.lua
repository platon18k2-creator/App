local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local PlayerSettings = require(ReplicatedStorage:WaitForChild("PlayerSettings"))
local function safeGetFOV() local f = PlayerSettings:getFOV() if f == nil then warn("[DEBUG] getFOV returned nil, using 70") return 70 end return f end
local function safeGetSetting(key, default) local v = PlayerSettings:get(key) if v == nil then return default end return v end
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== ЦВЕТА ====================
local C = {
	bg = Color3.fromRGB(14, 16, 21),
	bgLight = Color3.fromRGB(24, 28, 36),
	card = Color3.fromRGB(31, 36, 46),
	accent = Color3.fromRGB(230, 76, 76),
	accentDim = Color3.fromRGB(144, 45, 48),
	red = Color3.fromRGB(255, 98, 98),
	white = Color3.fromRGB(242, 244, 248),
	gray = Color3.fromRGB(156, 163, 175),
	darkGray = Color3.fromRGB(77, 84, 96),
}

-- ==================== ЗВУКИ ====================
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://119354387183704"
hoverSound.Volume = 0.5
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://88442833509532"
clickSound.Volume = 0.75
clickSound.Parent = SoundService

local successSound = Instance.new("Sound")
successSound.SoundId = "rbxassetid://119354387183704"
successSound.Volume = 0.6
successSound.Parent = SoundService

local errorSound = Instance.new("Sound")
errorSound.SoundId = "rbxassetid://88442833509532"
errorSound.Volume = 0.5
errorSound.Parent = SoundService

local redeemEvent = ReplicatedStorage:WaitForChild("RedeemCodeEvent")
local buyEvent = ReplicatedStorage:WaitForChild("BuyItemEvent")
local buyVariantEvent = ReplicatedStorage:WaitForChild("BuyVariantEvent")
local equipVariantEvent = ReplicatedStorage:WaitForChild("EquipVariantEvent")
local variantStateEvent = ReplicatedStorage:WaitForChild("VariantStateEvent")
local shopItemsFolder = ReplicatedStorage:WaitForChild("ShopItems")
local settingsEvent = ReplicatedStorage:WaitForChild("SettingsEvent")
local buyTitleEvent = ReplicatedStorage:WaitForChild("BuyTitleEvent")
local equipTitleEvent = ReplicatedStorage:WaitForChild("EquipTitleEvent")
local titleStateEvent = ReplicatedStorage:WaitForChild("TitleStateEvent")
local toggleUnequipEvent = ReplicatedStorage:WaitForChild("ToggleUnequipEvent")
local ownedItemsEvent = ReplicatedStorage:WaitForChild("OwnedItemsEvent")
local requestOwnedItemsEvent = ReplicatedStorage:WaitForChild("RequestOwnedItemsEvent")

-- ==================== УТИЛИТЫ ====================
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 3)
	c.Parent = parent
	return c
end

local function makeStroke(parent, thickness, color, transp)
	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.Color = color or C.white
	s.Transparency = math.max(transp or 0.5, 0.55)
	s.Parent = parent
	return s
end

local function makeGradient(parent, color1, color2, rot)
	parent.BackgroundColor3 = color1
	return nil
end

local function playHover(btn, stroke)
	local origColor = btn.BackgroundColor3
	btn.MouseEnter:Connect(function()
		if safeGetSetting('uiSounds', true) then hoverSound:Play() end
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.15), {
				Thickness = 2.5,
				Transparency = 0.1,
				Color = C.accent
			}):Play()
		end
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(
				math.min(origColor.R * 255 + 12, 255),
				math.min(origColor.G * 255 + 12, 255),
				math.min(origColor.B * 255 + 12, 255)
			)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.2), {
				Thickness = 1,
				Transparency = 0.5,
				Color = C.white
			}):Play()
		end
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = origColor
		}):Play()
	end)
end

local function playClick(btn)
	btn.MouseButton1Click:Connect(function()
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		local origSize = btn.Size
		TweenService:Create(btn, TweenInfo.new(0.06, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 3)
		}):Play()
		task.delay(0.1, function()
			if btn and btn.Parent then
				TweenService:Create(btn, TweenInfo.new(0.12), { Size = origSize }):Play()
			end
		end)
	end)
end

-- ==================== АДАПТАЦИЯ ПОД МОБИЛКИ ====================
local function getViewportSize()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1024, 768)
	if vp.X < 100 or vp.Y < 100 then
		return Vector2.new(1024, 768)
	end
	return vp
end

local isMobile = (function()
	local ui = game:GetService("UserInputService")
	local vp = getViewportSize()
	return ui.TouchEnabled or vp.X < 600
end)()

local function adaptWindow(w, h)
	local vp = getViewportSize()
	local sidePadding = isMobile and 36 or 16
	local maxW = math.max(vp.X - sidePadding, isMobile and 280 or 300)
	local maxH = math.max(vp.Y - (isMobile and 92 or 16), 240)
	local targetW = isMobile and math.floor(w * 0.86) or w
	local targetH = isMobile and math.floor(h * 0.86) or h
	return UDim2.new(0, math.min(targetW, maxW), 0, math.min(targetH, maxH))
end

local function adaptCell(baseW, baseH)
	local vp = getViewportSize()
	local maxW = math.max(math.min(vp.X - 60, 540), 240)
	local cellW = math.min(isMobile and math.floor(baseW * 0.82) or baseW, math.floor((maxW - 12) / 3))
	if cellW < 110 then cellW = math.min(baseW, math.floor((maxW - 12) / 2)) end
	if cellW < 90 then cellW = math.max(90, maxW - 12) end
	local cellH = math.max(math.floor(baseH * 0.8), math.floor(cellW * baseH / baseW))
	return UDim2.new(0, cellW, 0, cellH)
end

-- ==================== УПРАВЛЕНИЕ ОКНАМИ ====================
local activeBlur = nil
local activeWindow = nil -- ссылка на функцию закрытия текущего открытого окна

local function showBlur()
	if not activeBlur then
		activeBlur = Instance.new("BlurEffect")
		activeBlur.Size = 0
		activeBlur.Parent = Lighting
		TweenService:Create(activeBlur, TweenInfo.new(0.2), { Size = 8 }):Play()
	end
end

local function hideBlur()
	if activeBlur then
		TweenService:Create(activeBlur, TweenInfo.new(0.2), { Size = 0 }):Play()
		task.delay(0.22, function()
			if activeBlur and activeBlur.Size == 0 then
				activeBlur:Destroy()
				activeBlur = nil
			end
		end)
	end
end

local function closeActiveWindow()
	if activeWindow then
		activeWindow()
		activeWindow = nil
	end
end

-- ==================== СОЗДАНИЕ ОКНА ====================
local function createWindow(name, iconId, size)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ClipToDeviceSafeArea = true
	gui.Enabled = false
	gui.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.Parent = gui

	local aw = adaptWindow(size.X.Offset, size.Y.Offset)
	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(0, aw.X.Offset + 20, 0, aw.Y.Offset + 20)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.3
	shadow.Parent = backdrop
	makeCorner(shadow, 16)

	local window = Instance.new("Frame")
	window.Size = aw
	window.Position = UDim2.new(0.5, 0, 0.5, 0)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.BackgroundColor3 = C.bg
	window.Parent = shadow
	makeCorner(window, 18)
	makeGradient(window, C.bgLight, C.bg, 90)
	makeStroke(window, 1.5, C.accent, 0.4)

	-- A fixed header gives every window a clear visual hierarchy, even on narrow phones.
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundColor3 = C.bgLight
	header.BorderSizePixel = 0
	header.Parent = window
	makeGradient(header, Color3.fromRGB(39, 44, 55), C.bgLight, 90)

	local headerShade = Instance.new("Frame")
	headerShade.Size = UDim2.new(1, 0, 0, 1)
	headerShade.Position = UDim2.new(0, 0, 1, -1)
	headerShade.BackgroundColor3 = C.white
	headerShade.BackgroundTransparency = 0.88
	headerShade.BorderSizePixel = 0
	headerShade.Parent = header

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 3)
	topBar.BackgroundColor3 = C.accent
	topBar.Parent = window
	makeCorner(topBar, 14)
	makeGradient(topBar, C.accent, C.accentDim, 0)

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.Size = UDim2.new(0, 28, 0, 28)
	titleIcon.Position = UDim2.new(0, 18, 0, 14)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = iconId or ""
	titleIcon.Parent = window

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 0, 50)
	title.Position = UDim2.new(0, 55, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = C.white
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = name
	title.Parent = window

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -36, 0, 1)
	divider.Position = UDim2.new(0, 18, 0, 58)
	divider.BackgroundColor3 = C.accent
	divider.BackgroundTransparency = 0.7
	divider.Parent = window

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -44, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = C.red
	closeBtn.Text = "✕"
	closeBtn.Parent = window
	makeCorner(closeBtn, 8)
	local closeStroke = makeStroke(closeBtn, 1, C.red, 0.5)
	playHover(closeBtn, closeStroke)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -65)
	content.Position = UDim2.new(0, 0, 0, 65)
	content.BackgroundTransparency = 1
	content.Parent = window

	local isOpen = false
	local function close()
		if not isOpen then return end
		isOpen = false
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		TweenService:Create(window, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.5, 30)
		}):Play()
		TweenService:Create(window, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shadow, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		hideBlur()
		if activeWindow == close then activeWindow = nil end
		task.delay(0.22, function()
			gui.Enabled = false
			window.Position = UDim2.new(0.5, 0, 0.5, 0)
			window.BackgroundTransparency = 0
		end)
	end

	local function open()
		if isOpen then close() return end
		-- Закрываем другое открытое окно
		closeActiveWindow()
		isOpen = true
		activeWindow = close
		gui.Enabled = true
		window.BackgroundTransparency = 1
		window.Position = UDim2.new(0.5, 0, 0.5, -40)
		TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 }):Play()
		TweenService:Create(shadow, TweenInfo.new(0.2), { BackgroundTransparency = 0.3 }):Play()
		TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0
		}):Play()
		showBlur()
	end

	closeBtn.MouseButton1Click:Connect(close)
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- Закрываем только при клике ВНЕ окна, чтобы клики по кнопкам внутри
			-- не закрывали окно (иначе тогглы/кнопки не срабатывают)
			local pos = input.Position
			local winAbs = window.AbsolutePosition
			local winSize = window.AbsoluteSize
			local inside = pos.X >= winAbs.X and pos.X <= winAbs.X + winSize.X
				and pos.Y >= winAbs.Y and pos.Y <= winAbs.Y + winSize.Y
			if not inside then
				close()
			end
		end
	end)

	return gui, content, open, close
end

-- ==================== ОКНО КОДОВ ====================
local codesGui, codesContent, openCodes, closeCodes = createWindow("CODES", "rbxassetid://79377058817692", UDim2.new(0, 420, 0, 320))

codesContent:ClearAllChildren()

local inputBg = Instance.new("Frame")
inputBg.Size = UDim2.new(1, -40, 0, 48)
inputBg.Position = UDim2.new(0, 20, 0, 20)
inputBg.BackgroundColor3 = C.card
inputBg.Parent = codesContent
makeCorner(inputBg, 10)
local inputStroke = makeStroke(inputBg, 1, C.accent, 0.6)

local codeInput = Instance.new("TextBox")
codeInput.Size = UDim2.new(1, -24, 1, 0)
codeInput.Position = UDim2.new(0, 12, 0, 0)
codeInput.BackgroundTransparency = 1
codeInput.Font = Enum.Font.Gotham
codeInput.TextSize = 17
codeInput.TextColor3 = C.white
codeInput.PlaceholderText = "ENTER CODE..."
codeInput.PlaceholderColor3 = C.gray
codeInput.Text = ""
codeInput.ClearTextOnFocus = false
codeInput.Parent = inputBg

local redeemBtn = Instance.new("TextButton")
redeemBtn.Size = UDim2.new(1, -40, 0, 44)
redeemBtn.Position = UDim2.new(0, 20, 0, 85)
redeemBtn.BackgroundColor3 = C.accentDim
redeemBtn.Font = Enum.Font.GothamBold
redeemBtn.TextSize = 17
redeemBtn.TextColor3 = C.white
redeemBtn.Text = "REDEEM CODE"
redeemBtn.Parent = codesContent
makeCorner(redeemBtn, 10)
makeGradient(redeemBtn, C.accent, C.accentDim, 0)
local redeemStroke = makeStroke(redeemBtn, 1.5, C.accent, 0.2)
playHover(redeemBtn, redeemStroke)
playClick(redeemBtn)

local resultBg = Instance.new("Frame")
resultBg.Size = UDim2.new(1, -40, 0, 70)
resultBg.Position = UDim2.new(0, 20, 0, 150)
resultBg.BackgroundColor3 = C.card
resultBg.Visible = false
resultBg.Parent = codesContent
makeCorner(resultBg, 10)
local resultStroke = makeStroke(resultBg, 1, C.white, 0.6)

local resultIcon = Instance.new("ImageLabel")
resultIcon.Size = UDim2.new(0, 46, 0, 46)
resultIcon.Position = UDim2.new(0, 12, 0.5, 0)
resultIcon.AnchorPoint = Vector2.new(0, 0.5)
resultIcon.BackgroundTransparency = 1
resultIcon.Image = ""
resultIcon.Parent = resultBg

local resultText = Instance.new("TextLabel")
resultText.Size = UDim2.new(1, -70, 1, 0)
resultText.Position = UDim2.new(0, 68, 0, 0)
resultText.BackgroundTransparency = 1
resultText.Font = Enum.Font.GothamMedium
resultText.TextSize = 15
resultText.TextColor3 = C.white
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.Text = ""
resultText.Parent = resultBg

redeemBtn.MouseButton1Click:Connect(function()
	local code = codeInput.Text
	if code == "" then
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
		resultBg.Visible = true
		resultIcon.Image = ""
		resultText.Text = "Enter a code!"
		resultText.TextColor3 = C.red
		resultStroke.Color = C.red
		return
	end
	redeemEvent:FireServer(code)
end)

redeemEvent.OnClientEvent:Connect(function(data)
	resultBg.Visible = true
	TweenService:Create(resultBg, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -40, 0, 70)
	}):Play()
	if data.success then
		if safeGetSetting('uiSounds', true) then successSound:Play() end
		resultIcon.Image = data.icon or ""
		resultText.Text = data.message or "Success!"
		resultText.TextColor3 = C.accent
		resultStroke.Color = C.accent
		codeInput.Text = ""
	else
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
		resultIcon.Image = ""
		resultText.Text = data.message or "Error!"
		resultText.TextColor3 = C.red
		resultStroke.Color = C.red
	end
end)

-- ==================== ОКНО МАГАЗИНА ====================
local shopGui, shopContent, openShop, closeShop = createWindow("Store", "rbxassetid://5430510661", UDim2.new(0, 580, 0, 420))

-- Дисплей денег
local moneyFrame = Instance.new("Frame")
local _mw = isMobile and 120 or 160
moneyFrame.Size = UDim2.new(0, _mw, 0, isMobile and 36 or 40)
moneyFrame.Position = UDim2.new(1, -_mw - 15, 0, 8)
moneyFrame.BackgroundColor3 = C.card
moneyFrame.Parent = shopContent.Parent
makeCorner(moneyFrame, 10)
makeGradient(moneyFrame, Color3.fromRGB(25, 45, 35), C.card, 0)
local moneyStroke = makeStroke(moneyFrame, 1, C.accent, 0.3)

local moneyIcon = Instance.new("ImageLabel")
moneyIcon.Size = UDim2.new(0, 20, 0, 20)
moneyIcon.Position = UDim2.new(0, 10, 0.5, 0)
moneyIcon.AnchorPoint = Vector2.new(0, 0.5)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Image = "rbxassetid://122634913225226"
moneyIcon.Parent = moneyFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, -40, 1, 0)
moneyLabel.Position = UDim2.new(0, 36, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextSize = isMobile and 14 or 16
moneyLabel.TextColor3 = C.accent
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Text = "0"
moneyLabel.Parent = moneyFrame

local function getMoney()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local m = ls:FindFirstChild("Money")
		if m then return m.Value end
	end
	return 0
end

local function getCrystals()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Crystals")
		if c then return c.Value end
	end
	return 0
end

local function updateMoneyDisplay()
	moneyLabel.Text = tostring(getMoney())
end

-- Кристаллы
local crystalFrame = Instance.new("Frame")
local _cwid = isMobile and 120 or 160
crystalFrame.Size = UDim2.new(0, _cwid, 0, isMobile and 36 or 40)
crystalFrame.Position = UDim2.new(1, -_mw - _cwid - 25, 0, 8)
crystalFrame.BackgroundColor3 = C.card
crystalFrame.Parent = shopContent.Parent
makeCorner(crystalFrame, 10)
makeGradient(crystalFrame, Color3.fromRGB(25, 30, 50), C.card, 0)
local crystalStroke = makeStroke(crystalFrame, 1, Color3.fromRGB(100, 150, 255), 0.3)

local crystalIcon = Instance.new("ImageLabel")
crystalIcon.Size = UDim2.new(0, 20, 0, 20)
crystalIcon.Position = UDim2.new(0, 10, 0.5, 0)
crystalIcon.AnchorPoint = Vector2.new(0, 0.5)
crystalIcon.BackgroundTransparency = 1
crystalIcon.Image = "rbxassetid://120715756820928"
crystalIcon.Parent = crystalFrame

local crystalLabel = Instance.new("TextLabel")
crystalLabel.Size = UDim2.new(1, -40, 1, 0)
crystalLabel.Position = UDim2.new(0, 36, 0, 0)
crystalLabel.BackgroundTransparency = 1
crystalLabel.Font = Enum.Font.GothamBold
crystalLabel.TextSize = isMobile and 14 or 16
crystalLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
crystalLabel.TextXAlignment = Enum.TextXAlignment.Left
crystalLabel.Text = "0"
crystalLabel.Parent = crystalFrame

local function updateCrystalDisplay()
	crystalLabel.Text = tostring(getCrystals())
end

task.spawn(function()
	while task.wait(0.3) do
		updateMoneyDisplay()
		updateCrystalDisplay()
	end
end)

-- Табы магазина
local buildShopItems -- forward declaration
local currentShopTab = "Weapons"
local shopTabs = Instance.new("Frame")
shopTabs.Size = UDim2.new(1, -40, 0, 36)
shopTabs.Position = UDim2.new(0, 20, 0, 10)
shopTabs.BackgroundTransparency = 1
shopTabs.Parent = shopContent

local shopTabLayout = Instance.new("UIListLayout")
shopTabLayout.FillDirection = Enum.FillDirection.Horizontal
shopTabLayout.Padding = UDim.new(0, 6)
shopTabLayout.Parent = shopTabs

local shopTabButtons = {}
local function createShopTab(name, label, tabId)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 0, 1, 0)
	btn.Text = label
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = currentShopTab == tabId and C.white or C.gray
	btn.BackgroundColor3 = currentShopTab == tabId and C.card or C.bgLight
	btn.Parent = shopTabs
	makeCorner(btn, 8)
	local stroke = makeStroke(btn, 1, currentShopTab == tabId and C.accent or C.darkGray, currentShopTab == tabId and 0.2 or 0.7)
	btn.AutomaticSize = Enum.AutomaticSize.X
	shopTabButtons[tabId] = {btn = btn, stroke = stroke}
	playHover(btn, stroke)
	playClick(btn)
	btn.MouseButton1Click:Connect(function()
		if currentShopTab == tabId then return end
		currentShopTab = tabId
		-- Обновляем вид табов
		for id, info in pairs(shopTabButtons) do
			local isActive = id == tabId
			TweenService:Create(info.btn, TweenInfo.new(0.15), {
				BackgroundColor3 = isActive and C.card or C.bgLight,
				TextColor3 = isActive and C.white or C.gray,
			}):Play()
			TweenService:Create(info.stroke, TweenInfo.new(0.15), {
				Color = isActive and C.accent or C.darkGray,
				Transparency = isActive and 0.2 or 0.7,
			}):Play()
		end
		buildShopItems()
	end)
	return btn
end

createShopTab("Weapons", "Guns", "Weapons")
createShopTab("Variants", "Variants", "Variants")
createShopTab("Titles", "Titles", "Titles")

-- Скролл-фрейм
local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Size = UDim2.new(1, -40, 1, -100)
shopScroll.Position = UDim2.new(0, 20, 0, 55)
shopScroll.BackgroundTransparency = 1
shopScroll.ScrollBarThickness = 5
shopScroll.ScrollBarImageColor3 = C.accent
shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScroll.Parent = shopContent

local shopGrid = Instance.new("UIGridLayout")
shopGrid.CellSize = adaptCell(165, 175)
shopGrid.CellPadding = UDim2.new(0, 8, 0, 8)
shopGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopGrid.Parent = shopScroll

-- Цены (можно менять)
local shopPrices = {
	["Ak47"] = 2500,
	["Pistol"] = 1000,
	["Knife"] = 500,
}

local function getToolIcon(tool)
	if tool.TextureId and tool.TextureId ~= "" then
		return tool.TextureId
	end
	return "rbxassetid://298260830" -- дефолтная иконка
end

-- Создание 3D-превью тула в ViewportFrame
local function createToolPreview(tool, parent, size)
	local vp = Instance.new("ViewportFrame")
	vp.Size = size or UDim2.new(0, 48, 0, 48)
	vp.Position = UDim2.new(0.5, 0, 0, 12)
	vp.AnchorPoint = Vector2.new(0.5, 0)
	vp.BackgroundTransparency = 1
	vp.Parent = parent

	-- Создаём камеру для viewport
	local vcam = Instance.new("Camera")
	vcam.FieldOfView = 30
	vp.CurrentCamera = vcam

	-- Клонируем все Part/MeshPart из тула для превью
	local parts = {}
	local function collectParts(obj)
		for _, child in ipairs(obj:GetChildren()) do
			if child:IsA("BasePart") then
				local clone = child:Clone()
				clone.Anchored = true
				clone.CanCollide = false
				clone.Parent = vp
				table.insert(parts, clone)
				-- Клонируем вложенные MeshPart и т.д.
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("BasePart") then
						local sc = sub:Clone()
						sc.Anchored = true
						sc.CanCollide = false
						sc.Parent = vp
						table.insert(parts, sc)
					end
				end
			elseif child:IsA("Model") then
				collectParts(child)
			end
		end
	end
	collectParts(tool)

	if #parts == 0 then
		-- Нет партов — показываем иконку
		vp:Destroy()
		local img = Instance.new("ImageLabel")
		img.Size = size or UDim2.new(0, 48, 0, 48)
		img.Position = UDim2.new(0.5, 0, 0, 12)
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.BackgroundTransparency = 1
		img.Image = getToolIcon(tool)
		img.Parent = parent
		return
	end

	-- Вычисляем центр и размеры всех партов
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(parts) do
		minV = Vector3.new(math.min(minV.X, p.Position.X), math.min(minV.Y, p.Position.Y), math.min(minV.Z, p.Position.Z))
		maxV = Vector3.new(math.max(maxV.X, p.Position.X), math.max(maxV.Y, p.Position.Y), math.max(maxV.Z, p.Position.Z))
	end
	local center = (minV + maxV) / 2
	local size3 = maxV - minV
	local maxDim = math.max(size3.X, size3.Y, size3.Z)
	if maxDim < 0.01 then maxDim = 2 end

	-- Позиционируем камеру так, чтобы объект был виден
	local dist = maxDim * 2.5
	vcam.CFrame = CFrame.lookAt(center + Vector3.new(dist * 0.7, dist * 0.4, dist), center)

	-- Лёгкое вращение превью
	local rotateConn
	rotateConn = RunService.RenderStepped:Connect(function()
		if not vp or not vp.Parent then
			rotateConn:Disconnect()
			return
		end
		local rot = tick() * 0.5
		vcam.CFrame = CFrame.lookAt(center + Vector3.new(math.cos(rot) * dist * 0.7, dist * 0.4, math.sin(rot) * dist * 0.7), center)
	end)

	return vp
end

-- Данные о титулах (клиентская копия)
local titleData = {
	{
		Name = "Rookie",
		Price = 500,
		Currency = "Money",
		Color = "#AAAAAA",
		Description = "Starter title for beginners",
	},
	{
		Name = "Fighter",
		Price = 2000,
		Currency = "Money",
		Color = "#FF6B35",
		Description = "For real fighters",
	},
	{
		Name = "Veteran",
		Price = 5000,
		Currency = "Money",
		Color = "#9B59B6",
		Description = "Battle-tested veteran",
	},
	{
		Name = "Legend",
		Price = 15000,
		Currency = "Money",
		Color = "#FFD700",
		Description = "Title for arena legends",
	},
	{
		Name = "King",
		Price = 50000,
		Currency = "Money",
		Color = "#FF0000",
		Description = "King of fighters — the most prestigious title",
	},
}

local ownedTitles = {}
local equippedTitle = nil

-- Данные о вариантах (клиентская копия)
local variantData = {
	{
		Name = "Teleport",
		DisplayName = "TELEPORT",
		Price = 235,
		Currency = "Crystals",
		Icon = "rbxassetid://120715756820928",
		Description = "Instant teleport in the camera direction",
	},
	{
		Name = "InAir",
		DisplayName = "IN AIR",
		Price = 400,
		Currency = "Crystals",
		Icon = "rbxassetid://337291948",
		Description = "IN AIR — launch up, dash in the air and slam down creating a crater",
	},
	{
		Name = "Fly",
		DisplayName = "FLY",
		Price = 800,
		Currency = "Crystals",
		Icon = "rbxassetid://596046130",
		Description = "FLY — fly in the camera direction for up to 4 seconds. Crash into targets to knock them back far.",
	},
	{
		Name = "GoAway",
		DisplayName = "GO AWAY",
		Price = 950,
		Currency = "Crystals",
		Icon = "rbxassetid://80136104498298",
		Description = "Grab the target by the neck with the left hand, gather power and deliver a crushing blow.",
		IsGVariant = true,
	},
	{
		Name = "Rage",
		DisplayName = "RAGE",
		Price = 600,
		Currency = "Crystals",
		Icon = "rbxassetid://134685308988646",
		Description = "RAGE — new G-attack: series of hits, kick and throw with a crater",
		IsGVariant = true,
	},
	{
		Name = "PalmStrike",
		DisplayName = "PALM STRIKE",
		Price = 1200,
		Currency = "Crystals",
		Icon = "rbxassetid://108071730747470",
		Description = "PALM STRIKE — grab the head, series of hits and a final kick that knocks sideways",
		IsGVariant = true,
	},
	{
		Name = "UltraInstinct",
		DisplayName = "ULTRA INSTINCT",
		Price = 1500,
		Currency = "Crystals",
		Icon = "rbxassetid://120715756820928",
		Description = "ULTRA INSTINCT — silver aura, trail, time slow and tons of effects on dodge",
	},
	{
		Name = "InfiniteVoid",
		DisplayName = "INFINITE VOID",
		Price = 2000,
		Currency = "Crystals",
		Icon = "rbxassetid://120715756820928",
		Description = "INFINITE VOID — opens the void, pulling in the target and dealing crushing damage",
		IsGVariant = true,
	},
	{
		Name = "BottleHit",
		DisplayName = "BOTTLE HIT",
		Price = 700,
		Currency = "Crystals",
		Icon = "rbxassetid://107917072751349",
		Description = "BOTTLE HIT — weld a bottle to your hand, smash it on the enemy's head and send them ragdolling",
		IsGVariant = true,
	},
	{
		Name = "Kick",
		DisplayName = "KICK",
		Price = 500,
		Currency = "Crystals",
		Icon = "rbxassetid://13050670424",
		Description = "KICK — replaces M1 attack animations with kick combos",
		IsM1Variant = true,
	},
	{
		Name = "Slide",
		DisplayName = "SLIDE",
		Price = 350,
		Currency = "Crystals",
		Icon = "rbxassetid://13050670424",
		Description = "SLIDE — slide forward, trip the enemy and roll over them",
	},
}

local ownedVariants = {}
local equippedDashVariant = nil
local equippedGVariant = nil
local equippedM1Variant = nil

-- Купленные предметы и unequip-состояние (для магазина)
local ownedTools = {}
local unequippedTools = {}

local function isToolOwned(name)
	return table.find(ownedTools, name) ~= nil
end

local function isToolUnequipped(name)
	return table.find(unequippedTools, name) ~= nil
end

-- Получаем список купленных предметов и unequip-состояние от сервера
ownedItemsEvent.OnClientEvent:Connect(function(data)
	if data and type(data) == "table" then
		ownedTools = data.OwnedTools or {}
		unequippedTools = data.UnequippedTools or {}
		buildShopItems()
	end
end)

buildShopItems = function()
	-- Очищаем старые карточки
	for _, child in shopScroll:GetChildren() do
		if child:IsA("Frame") and (child.Name == "ShopCard" or child.Name == "VariantCard" or child.Name == "TitleCard") then
			child:Destroy()
		end
	end

	if currentShopTab == "Weapons" then
	for _, item in shopItemsFolder:GetChildren() do
		if item:IsA("Tool") then
			local price = item:GetAttribute("Price") or shopPrices[item.Name] or 1000

			local card = Instance.new("Frame")
			card.Name = "ShopCard"
			card.BackgroundColor3 = C.card
			card.Parent = shopScroll
			makeCorner(card, 10)
			makeGradient(card, Color3.fromRGB(32, 32, 44), C.card, 90)
			local cardStroke = makeStroke(card, 1, C.white, 0.6)

			-- 3D-превью тула
			local preview = createToolPreview(item, card, UDim2.new(0, 60, 0, 50))

			-- Название
			local itemName = Instance.new("TextLabel")
			itemName.Size = UDim2.new(1, -10, 0, 22)
			itemName.Position = UDim2.new(0, 5, 0, 65)
			itemName.BackgroundTransparency = 1
			itemName.Font = Enum.Font.GothamBold
			itemName.TextSize = 15
			itemName.TextColor3 = C.white
			itemName.Text = item.Name
			itemName.Parent = card

			-- Тип
			local itemType = Instance.new("TextLabel")
			itemType.Size = UDim2.new(1, -10, 0, 16)
			itemType.Position = UDim2.new(0, 5, 0, 86)
			itemType.BackgroundTransparency = 1
			itemType.Font = Enum.Font.Gotham
			itemType.TextSize = 11
			itemType.TextColor3 = C.gray
			itemType.Text = "Tool"
			itemType.Parent = card

			-- Кнопка: покупка / unequip / equip
			local actionBtn = Instance.new("TextButton")
			actionBtn.Size = UDim2.new(1, -10, 0, 32)
			actionBtn.Position = UDim2.new(0, 5, 1, -38)
			actionBtn.Font = Enum.Font.GothamBold
			actionBtn.TextSize = 14
			actionBtn.TextColor3 = C.white
			actionBtn.Parent = card
			makeCorner(actionBtn, 8)

			if isToolOwned(item.Name) then
				if isToolUnequipped(item.Name) then
					-- Куплен, но убран из инвентаря — можно вернуть
					actionBtn.Text = "EQUIP"
					actionBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 70)
					makeGradient(actionBtn, Color3.fromRGB(50, 130, 90), Color3.fromRGB(40, 100, 70), 0)
					local btnStroke = makeStroke(actionBtn, 1, C.accent, 0.3)
					playHover(actionBtn, btnStroke)
					playClick(actionBtn)
					actionBtn.MouseButton1Click:Connect(function()
						toggleUnequipEvent:FireServer(item.Name)
					end)
				else
					-- Куплен и в инвентаре — можно убрать
					actionBtn.Text = "UNEQUIP"
					actionBtn.BackgroundColor3 = Color3.fromRGB(90, 45, 45)
					makeGradient(actionBtn, Color3.fromRGB(120, 60, 60), Color3.fromRGB(90, 45, 45), 0)
					local btnStroke = makeStroke(actionBtn, 1, C.red, 0.3)
					playHover(actionBtn, btnStroke)
					playClick(actionBtn)
					actionBtn.MouseButton1Click:Connect(function()
						toggleUnequipEvent:FireServer(item.Name)
					end)
				end
			else
				-- Не куплен — кнопка покупки
				actionBtn.Text = tostring(price) .. " $"
				actionBtn.BackgroundColor3 = C.accentDim
				makeGradient(actionBtn, C.accent, C.accentDim, 0)
				local buyStroke = makeStroke(actionBtn, 1, C.accent, 0.3)
				playHover(actionBtn, buyStroke)
				playClick(actionBtn)
				actionBtn.MouseButton1Click:Connect(function()
					buyEvent:FireServer(item.Name)
				end)
			end
		end
	end
	end

	-- Варианты дэша
	if currentShopTab == "Variants" then
	for _, vdata in ipairs(variantData) do
		local isOwned = false
		for _, v in ipairs(ownedVariants) do
			if v == vdata.Name then isOwned = true break end
		end
		local isEquipped = (vdata.IsGVariant and equippedGVariant == vdata.Name) or (vdata.IsM1Variant and equippedM1Variant == vdata.Name) or ((not vdata.IsGVariant and not vdata.IsM1Variant) and equippedDashVariant == vdata.Name)

		local card = Instance.new("Frame")
		card.Name = "VariantCard"
		card.BackgroundColor3 = C.card
		card.Parent = shopScroll
		makeCorner(card, 10)
		makeGradient(card, Color3.fromRGB(42, 44, 55), C.card, 90)
		local cardStroke = makeStroke(card, 1, isEquipped and Color3.fromRGB(100, 150, 255) or C.white, isEquipped and 0.2 or 0.6)

		local vIcon = Instance.new("ImageLabel")
		vIcon.Size = UDim2.new(0, 48, 0, 48)
		vIcon.Position = UDim2.new(0.5, 0, 0, 12)
		vIcon.AnchorPoint = Vector2.new(0.5, 0)
		vIcon.BackgroundTransparency = 1
		vIcon.Image = vdata.Icon
		vIcon.Parent = card

		local vName = Instance.new("TextLabel")
		vName.Size = UDim2.new(1, -10, 0, 22)
		vName.Position = UDim2.new(0, 5, 0, 65)
		vName.BackgroundTransparency = 1
		vName.Font = Enum.Font.GothamBold
		vName.TextSize = 15
		vName.TextColor3 = C.white
		vName.Text = vdata.DisplayName
		vName.Parent = card

		local vDesc = Instance.new("TextLabel")
		vDesc.Size = UDim2.new(1, -10, 0, 28)
		vDesc.Position = UDim2.new(0, 5, 0, 87)
		vDesc.BackgroundTransparency = 1
		vDesc.Font = Enum.Font.Gotham
		vDesc.TextSize = 11
		vDesc.TextColor3 = C.gray
		vDesc.TextWrapped = true
		vDesc.Text = vdata.Description
		vDesc.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(1, -10, 0, 32)
		actionBtn.Position = UDim2.new(0, 5, 1, -38)
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 14
		actionBtn.TextColor3 = C.white
		actionBtn.Parent = card
		makeCorner(actionBtn, 8)

		if isEquipped then
			actionBtn.Text = "EQUIPPED"
			actionBtn.BackgroundColor3 = Color3.fromRGB(35, 55, 95)
			makeGradient(actionBtn, Color3.fromRGB(45, 70, 130), Color3.fromRGB(35, 55, 95), 0)
			local btnStroke = makeStroke(actionBtn, 1, Color3.fromRGB(100, 150, 255), 0.2)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				if vdata.IsM1Variant then
					equipVariantEvent:FireServer("__CLEAR_M1__")
				elseif vdata.IsGVariant then
					equipVariantEvent:FireServer("__CLEAR_G__")
				else
					equipVariantEvent:FireServer("__CLEAR_DASH__")
				end
			end)
		elseif isOwned then
			actionBtn.Text = "EQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 70)
			makeGradient(actionBtn, Color3.fromRGB(50, 130, 90), Color3.fromRGB(40, 100, 70), 0)
			local btnStroke = makeStroke(actionBtn, 1, C.accent, 0.3)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				equipVariantEvent:FireServer(vdata.Name)
			end)
		else
			actionBtn.Text = tostring(vdata.Price) .. "  💎"
			actionBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 70)
			makeGradient(actionBtn, Color3.fromRGB(40, 60, 110), Color3.fromRGB(25, 40, 70), 0)
			local btnStroke = makeStroke(actionBtn, 1, Color3.fromRGB(100, 150, 255), 0.3)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				buyVariantEvent:FireServer(vdata.Name)
			end)
		end
	end
	end

	-- Титулы
	if currentShopTab == "Titles" then
	for _, tdata in ipairs(titleData) do
		local isOwned = false
		for _, t in ipairs(ownedTitles) do
		if t == tdata.Name then isOwned = true break end
		end
		local isEquipped = equippedTitle == tdata.Name
		local titleColor = Color3.fromHex(tdata.Color)

		local card = Instance.new("Frame")
		card.Name = "TitleCard"
		card.BackgroundColor3 = C.card
		card.Parent = shopScroll
		makeCorner(card, 10)
		makeGradient(card, Color3.fromRGB(35, 25, 45), C.card, 90)
		local cardStroke = makeStroke(card, 1, isEquipped and titleColor or C.white, isEquipped and 0.2 or 0.6)

		-- Иконка титула (звезда/корона)
		local tIcon = Instance.new("TextLabel")
		tIcon.Size = UDim2.new(0, 48, 0, 48)
		tIcon.Position = UDim2.new(0.5, 0, 0, 10)
		tIcon.AnchorPoint = Vector2.new(0.5, 0)
		tIcon.BackgroundTransparency = 1
		tIcon.Font = Enum.Font.GothamBold
		tIcon.TextSize = 36
		tIcon.TextColor3 = titleColor
		tIcon.Text = "★"
		tIcon.Parent = card

		-- Название титула
		local tName = Instance.new("TextLabel")
		tName.Size = UDim2.new(1, -10, 0, 22)
		tName.Position = UDim2.new(0, 5, 0, 62)
		tName.BackgroundTransparency = 1
		tName.Font = Enum.Font.GothamBold
		tName.TextSize = 15
		tName.TextColor3 = titleColor
		tName.Text = "[" .. tdata.Name .. "]"
		tName.Parent = card

		-- Описание
		local tDesc = Instance.new("TextLabel")
		tDesc.Size = UDim2.new(1, -10, 0, 28)
		tDesc.Position = UDim2.new(0, 5, 0, 84)
		tDesc.BackgroundTransparency = 1
		tDesc.Font = Enum.Font.Gotham
		tDesc.TextSize = 11
		tDesc.TextColor3 = C.gray
		tDesc.TextWrapped = true
		tDesc.Text = tdata.Description
		tDesc.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(1, -10, 0, 32)
		actionBtn.Position = UDim2.new(0, 5, 1, -38)
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 14
		actionBtn.TextColor3 = C.white
		actionBtn.Parent = card
		makeCorner(actionBtn, 8)

		if isEquipped then
			actionBtn.Text = "EQUIPPED"
			actionBtn.BackgroundColor3 = Color3.fromRGB(50, 38, 68)
			makeGradient(actionBtn, Color3.fromRGB(65, 52, 88), Color3.fromRGB(50, 38, 68), 0)
			local btnStroke = makeStroke(actionBtn, 1, titleColor, 0.2)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				equipTitleEvent:FireServer(nil)
			end)
		elseif isOwned then
			actionBtn.Text = "EQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 70)
			makeGradient(actionBtn, Color3.fromRGB(50, 130, 90), Color3.fromRGB(40, 100, 70), 0)
			local btnStroke = makeStroke(actionBtn, 1, C.accent, 0.3)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				equipTitleEvent:FireServer(tdata.Name)
			end)
		else
			actionBtn.Text = tostring(tdata.Price) .. " $"
			actionBtn.BackgroundColor3 = Color3.fromRGB(42, 30, 52)
			makeGradient(actionBtn, Color3.fromRGB(58, 42, 72), Color3.fromRGB(42, 30, 52), 0)
			local btnStroke = makeStroke(actionBtn, 1, titleColor, 0.3)
			playHover(actionBtn, btnStroke)
			playClick(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				buyTitleEvent:FireServer(tdata.Name)
			end)
		end
	end
	end
end

-- Слушаем ответ от сервера о покупке
buyEvent.OnClientEvent:Connect(function(data)
	if data.success then
		if safeGetSetting('uiSounds', true) then successSound:Play() end
		buildShopItems()
	elseif data.alreadyOwned then
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
	else
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
	end
	for _, card in shopScroll:GetChildren() do
		if card:IsA("Frame") and card.Name == "ShopCard" then
			local btn = card:FindFirstChildWhichIsA("TextButton")
			local nameLbl = card:FindFirstChildWhichIsA("TextLabel")
			if btn and nameLbl and data.item == nameLbl.Text then
				local priceText = tostring(shopPrices[data.item] or 1000) .. " $"
				if data.success then
					btn.Text = "PURCHASED!"
					btn.TextColor3 = C.accent
					task.delay(1.5, function()
						if btn and btn.Parent then btn.Text = priceText btn.TextColor3 = C.white end
						end)
				else
					btn.Text = "NOT ENOUGH!"
					btn.TextColor3 = C.red
					task.delay(1.5, function()
						if btn and btn.Parent then btn.Text = priceText btn.TextColor3 = C.white end
						end)
				end
			end
		end
	end
end)

-- Обновляем магазин при изменении папки
shopItemsFolder.ChildAdded:Connect(buildShopItems)
shopItemsFolder.ChildRemoved:Connect(buildShopItems)
buildShopItems()

-- ==================== ОКНО ИНВЕНТАРЯ ====================
local invGui, invContent, openInv, closeInv = createWindow("INVENTORY", "rbxassetid://135273755533681", UDim2.new(0, 520, 0, 380))

local invScroll = Instance.new("ScrollingFrame")
invScroll.Size = UDim2.new(1, -40, 1, -70)
invScroll.Position = UDim2.new(0, 20, 0, 20)
invScroll.BackgroundTransparency = 1
invScroll.ScrollBarThickness = 5
invScroll.ScrollBarImageColor3 = C.accent
invScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
invScroll.Parent = invContent

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = adaptCell(100, 100)
invGrid.CellPadding = UDim2.new(0, 8, 0, 8)
invGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
invGrid.Parent = invScroll

local invEmpty = Instance.new("TextLabel")
invEmpty.Size = UDim2.new(1, 0, 0, 40)
invEmpty.Position = UDim2.new(0, 0, 0.3, 0)
invEmpty.BackgroundTransparency = 1
invEmpty.Font = Enum.Font.Gotham
invEmpty.TextSize = 16
invEmpty.TextColor3 = C.gray
invEmpty.Text = "Inventory is empty"
invEmpty.Parent = invContent

-- Получение списка инструментов без дубликатов
local function getInventoryTools()
	local tools = {}
	local seen = {}
	local char = player.Character
	local backpack = player:FindFirstChild("Backpack")

	-- Сначала экипированные (в Character)
	if char then
		for _, item in char:GetChildren() do
			if item:IsA("Tool") and not seen[item] then
				seen[item] = true
				table.insert(tools, item)
			end
		end
	end
	-- Потом в Backpack
	if backpack then
		for _, item in backpack:GetChildren() do
			if item:IsA("Tool") and not seen[item] then
				seen[item] = true
				table.insert(tools, item)
			end
		end
	end
	return tools
end

local function isToolEquipped(tool)
	local char = player.Character
	return char ~= nil and tool.Parent == char
end

local function refreshInventory()
	-- Очищаем только слоты (не трогаем UIGridLayout)
	for _, child in invScroll:GetChildren() do
		if child:IsA("Frame") and child.Name == "InvSlot" then
			child:Destroy()
		end
	end

	local tools = getInventoryTools()
	invEmpty.Visible = (#tools == 0)

	for _, tool in ipairs(tools) do
		local equipped = isToolEquipped(tool)

		local slot = Instance.new("Frame")
		slot.Name = "InvSlot"
		slot.BackgroundColor3 = C.card
		slot.Parent = invScroll
		makeCorner(slot, 10)
		makeGradient(slot, Color3.fromRGB(32, 32, 44), C.card, 90)
		local slotStroke = makeStroke(slot, 1, equipped and C.accent or C.white, equipped and 0.2 or 0.6)

		local slotIcon = Instance.new("ImageLabel")
		slotIcon.Size = UDim2.new(0, 44, 0, 44)
		slotIcon.Position = UDim2.new(0.5, 0, 0, 8)
		slotIcon.AnchorPoint = Vector2.new(0.5, 0)
		slotIcon.BackgroundTransparency = 1
		slotIcon.Image = (tool.TextureId ~= "" and tool.TextureId) or "rbxassetid://298260830"
		slotIcon.Parent = slot

		local slotName = Instance.new("TextLabel")
		slotName.Size = UDim2.new(1, -6, 0, 20)
		slotName.Position = UDim2.new(0, 3, 1, -22)
		slotName.BackgroundTransparency = 1
		slotName.Font = Enum.Font.GothamBold
		slotName.TextSize = 12
		slotName.TextColor3 = equipped and C.accent or C.white
		slotName.Text = tool.Name
		slotName.Parent = slot

		-- Клик: экипировать / снять
		slot.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if safeGetSetting('uiSounds', true) then clickSound:Play() end
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if not char or not humanoid then return end
				if isToolEquipped(tool) then
					humanoid:UnequipTools()
				else
					humanoid:EquipTool(tool)
				end
				task.wait(0.1)
				refreshInventory()
			end
		end)
	end
end

-- Слежение за изменениями инвентаря
local function bindInventoryWatcher()
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
		backpack.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
	end
end

-- Подключаемся к существующему Backpack
bindInventoryWatcher()
-- На случай респавна
player.ChildAdded:Connect(function(c)
	if c.Name == "Backpack" then
		c.ChildAdded:Connect(function(item) if item:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
		c.ChildRemoved:Connect(function(item) if item:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
		refreshInventory()
	end
end)

player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	refreshInventory()
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
end)

if player.Character then
	player.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
	player.Character.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.wait(0.05) refreshInventory() end end)
end

-- ==================== ОБРАБОТКА ВАРИАНТОВ ====================
buyVariantEvent.OnClientEvent:Connect(function(data)
	if data.success then
		if safeGetSetting('uiSounds', true) then successSound:Play() end
		if data.variant and not table.find(ownedVariants, data.variant) then
			table.insert(ownedVariants, data.variant)
		end
		buildShopItems()
	else
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
	end
end)

equipVariantEvent.OnClientEvent:Connect(function(data)
	if data.success then
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		if data.isM1Variant then
			equippedM1Variant = data.equipped
		elseif data.isGVariant then
			equippedGVariant = data.equipped
		else
			equippedDashVariant = data.equipped
		end
		buildShopItems()
		buildShopItems()
	end
end)

variantStateEvent.OnClientEvent:Connect(function(data)
	if data and type(data) == "table" then
		ownedVariants = data.OwnedVariants or {}
		equippedDashVariant = data.EquippedDashVariant or data.EquippedVariant or nil
		equippedGVariant = data.EquippedGVariant or nil
		equippedM1Variant = data.EquippedM1Variant or nil
		buildShopItems()
	end
end)

-- ==================== ОБРАБОТКА ТИТУЛОВ ====================
buyTitleEvent.OnClientEvent:Connect(function(data)
	if data.success then
		if safeGetSetting('uiSounds', true) then successSound:Play() end
		if data.title and not table.find(ownedTitles, data.title) then
			table.insert(ownedTitles, data.title)
		end
		buildShopItems()
	else
		if safeGetSetting('uiSounds', true) then errorSound:Play() end
	end
end)

equipTitleEvent.OnClientEvent:Connect(function(data)
	if data.success then
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		equippedTitle = data.equipped
		buildShopItems()
	end
end)

titleStateEvent.OnClientEvent:Connect(function(data)
	if data and type(data) == "table" then
		ownedTitles = data.OwnedTitles or {}
		equippedTitle = data.EquippedTitle or nil
		buildShopItems()
	end
end)

-- ==================== ТОПБАР-НАСТРОЙКИ (выпадающая панель) ====================
local setGui = Instance.new("ScreenGui")
setGui.Name = "Settings"
setGui.ResetOnSpawn = false
setGui.IgnoreGuiInset = true
setGui.DisplayOrder = 101
setGui.Enabled = false
setGui.Parent = playerGui

-- Затемнение (лёгкое, клик = закрыть)
local setBackdrop = Instance.new("Frame")
setBackdrop.Size = UDim2.new(1, 0, 1, 0)
setBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
setBackdrop.BackgroundTransparency = 1
setBackdrop.Parent = setGui

-- Панель настроек (выпадает сверху-справа)
local setPanel = Instance.new("Frame")
local _spw = math.min(320, getViewportSize().X - 16)
setPanel.Size = UDim2.new(0, _spw, 0, 0) -- начальная высота 0 (анимация)
setPanel.Position = UDim2.new(1, -_spw - 20, 0, -400)
setPanel.AnchorPoint = Vector2.new(0, 0)
setPanel.BackgroundColor3 = C.bg
setPanel.Parent = setBackdrop
makeCorner(setPanel, 12)
makeGradient(setPanel, C.bgLight, C.bg, 180)
local panelStroke = makeStroke(setPanel, 1.5, C.accent, 0.4)

-- Заголовок панели
local setHeader = Instance.new("Frame")
setHeader.Size = UDim2.new(1, 0, 0, 44)
setHeader.BackgroundTransparency = 1
setHeader.Parent = setPanel

local setHeaderIcon = Instance.new("ImageLabel")
setHeaderIcon.Size = UDim2.new(0, 22, 0, 22)
setHeaderIcon.Position = UDim2.new(0, 16, 0.5, 0)
setHeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
setHeaderIcon.BackgroundTransparency = 1
setHeaderIcon.Image = "rbxassetid://9405931578"
setHeaderIcon.Parent = setHeader

local setHeaderTitle = Instance.new("TextLabel")
setHeaderTitle.Size = UDim2.new(0, 200, 0, 44)
setHeaderTitle.Position = UDim2.new(0, 44, 0, 0)
setHeaderTitle.BackgroundTransparency = 1
setHeaderTitle.Font = Enum.Font.GothamBold
setHeaderTitle.TextSize = 16
setHeaderTitle.TextColor3 = C.white
setHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
setHeaderTitle.Text = "SETTINGS"
setHeaderTitle.Parent = setHeader

local setCloseBtn = Instance.new("TextButton")
setCloseBtn.Size = UDim2.new(0, 28, 0, 28)
setCloseBtn.Position = UDim2.new(1, -38, 0.5, 0)
setCloseBtn.AnchorPoint = Vector2.new(0, 0.5)
setCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
setCloseBtn.Font = Enum.Font.GothamBold
setCloseBtn.TextSize = 14
setCloseBtn.TextColor3 = C.red
setCloseBtn.Text = "✕"
setCloseBtn.Parent = setHeader
makeCorner(setCloseBtn, 6)
local setCloseStroke = makeStroke(setCloseBtn, 1, C.red, 0.5)
playHover(setCloseBtn, setCloseStroke)

-- Контейнер для строк настроек
local settingsList = Instance.new("ScrollingFrame")
settingsList.Size = UDim2.new(1, -24, 1, -60)
settingsList.Position = UDim2.new(0, 12, 0, 50)
settingsList.BackgroundTransparency = 1
settingsList.ScrollBarThickness = 4
settingsList.ScrollBarImageColor3 = C.accent
settingsList.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsList.Parent = setPanel

local setLayout = Instance.new("UIListLayout")
setLayout.Padding = UDim.new(0, 8)
setLayout.Parent = settingsList

-- Функция создания тоггл-строки
local function createToggleRow(parent, label, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = C.card
	row.Parent = parent
	makeCorner(row, 8)
	makeGradient(row, Color3.fromRGB(30, 30, 42), C.card, 90)
	local rowStroke = makeStroke(row, 1, C.white, 0.6)

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -80, 1, 0)
	labelText.Position = UDim2.new(0, 14, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.TextSize = 14
	labelText.TextColor3 = C.white
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Text = label
	labelText.Parent = row

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 46, 0, 24)
	toggleBg.Position = UDim2.new(1, -56, 0.5, 0)
	toggleBg.AnchorPoint = Vector2.new(0, 0.5)
	toggleBg.BackgroundColor3 = default and C.accentDim or C.darkGray
	toggleBg.Parent = row
	makeCorner(toggleBg, 12)

	local toggleKnob = Instance.new("Frame")
	toggleKnob.Size = UDim2.new(0, 18, 0, 18)
	toggleKnob.Position = default and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	toggleKnob.BackgroundColor3 = C.white
	toggleKnob.Parent = toggleBg
	makeCorner(toggleKnob, 9)

	local isOn = default
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = row

	toggleBtn.MouseButton1Click:Connect(function()
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		isOn = not isOn
		TweenService:Create(toggleBg, TweenInfo.new(0.15), {
			BackgroundColor3 = isOn and C.accentDim or C.darkGray
		}):Play()
		TweenService:Create(toggleKnob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = isOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		}):Play()
		callback(isOn)
	end)
	playHover(row, rowStroke)

	return toggleBtn
end

-- Отправляем настройки на сервер при изменении
local function sendSettingsToServer()
	settingsEvent:FireServer(PlayerSettings:getAll())
end

-- 1. Графика (полное отключение всех эффектов и сброс освещения)
local graphicsEffectNames = {"Bloom", "Atmosphere", "DepthOfField", "SunRays", "ColorCorrection", "Blur"}
local graphicsLightDefaults = {
	Brightness = 2,
	Ambient = Color3.fromRGB(128, 128, 128),
	OutdoorAmbient = Color3.fromRGB(128, 128, 128),
	GlobalShadows = false,
	ShadowSoftness = 0.5,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
}
local graphicsLightCustom = {
	Brightness = 4,
	Ambient = Color3.fromRGB(64, 72, 79),
	OutdoorAmbient = Color3.fromRGB(64, 72, 79),
	GlobalShadows = true,
	ShadowSoftness = 0,
	EnvironmentDiffuseScale = 0.202,
	EnvironmentSpecularScale = 0.202,
}

local function applyGraphics(on)
	-- Включаем/выключаем все пост-эффекты в Lighting
	for _, name in ipairs(graphicsEffectNames) do
		local effect = Lighting:FindFirstChild(name)
		if effect and effect:IsA("PostEffect") then
			effect.Enabled = on
		end
	end
	-- Включаем/выключаем Sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then sky.Parent = on and Lighting or nil end
	-- Включаем/выключаем Clouds в Terrain
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then clouds.Enabled = on end
	-- Сброс параметров освещения
	local target = on and graphicsLightCustom or graphicsLightDefaults
	for prop, value in pairs(target) do
		Lighting[prop] = value
	end
	-- WaterReflectance / WaterTransparency
	Workspace.Terrain.WaterReflectance = on and 1 or 0
	Workspace.Terrain.WaterTransparency = on and 1 or 0.3
end

createToggleRow(settingsList, "Graphics Quality", safeGetSetting('graphics', true), function(on)
	PlayerSettings:setGraphics(on)
	applyGraphics(on)
	sendSettingsToServer()
end)

-- 2. Звук
createToggleRow(settingsList, "UI Sounds", safeGetSetting('uiSounds', true), function(on)
	PlayerSettings:setUISounds(on)
	sendSettingsToServer()
end)

-- 3. Кровь
createToggleRow(settingsList, "Blood", safeGetSetting('blood', true), function(on)
	PlayerSettings:setBlood(on)
	sendSettingsToServer()
end)

-- ==================== НИКЕЙМ НАСТРОЙКИ ====================
local nickHeader = Instance.new("TextLabel")
nickHeader.Size = UDim2.new(1, 0, 0, 30)
nickHeader.BackgroundTransparency = 1
nickHeader.Font = Enum.Font.GothamBold
nickHeader.TextSize = 15
nickHeader.TextColor3 = C.accent
nickHeader.TextXAlignment = Enum.TextXAlignment.Left
nickHeader.Text = "NICKNAME"
nickHeader.Parent = settingsList

-- Вкл/выкл отображение ника
createToggleRow(settingsList, "Nickname Enabled", safeGetSetting('nickEnabled', true), function(on)
	PlayerSettings:setNickEnabled(on)
	sendSettingsToServer()
end)

-- Поле ввода ника
local nickRow = Instance.new("Frame")
nickRow.Size = UDim2.new(1, 0, 0, 46)
nickRow.BackgroundColor3 = C.card
nickRow.Parent = settingsList
makeCorner(nickRow, 8)
makeStroke(nickRow, 1, C.white, 0.6)

local nickLabel = Instance.new("TextLabel")
nickLabel.Size = UDim2.new(0, 90, 1, 0)
nickLabel.Position = UDim2.new(0, 14, 0, 0)
nickLabel.BackgroundTransparency = 1
nickLabel.Font = Enum.Font.GothamMedium
nickLabel.TextSize = 13
nickLabel.TextColor3 = C.white
nickLabel.TextXAlignment = Enum.TextXAlignment.Left
nickLabel.Text = "Nick:"
nickLabel.Parent = nickRow

local nickInput = Instance.new("TextBox")
nickInput.Size = UDim2.new(1, -110, 0, 30)
nickInput.Position = UDim2.new(0, 100, 0.5, 0)
nickInput.AnchorPoint = Vector2.new(0, 0.5)
nickInput.BackgroundColor3 = C.bg
nickInput.Font = Enum.Font.Gotham
nickInput.TextSize = 14
nickInput.TextColor3 = C.white
nickInput.PlaceholderText = "Your nickname..."
nickInput.PlaceholderColor3 = C.gray
-- Ник всегда равен юзернейму игрока (нельзя менять)
nickInput.Text = player.Name
nickInput.TextEditable = false
nickInput.ClearTextOnFocus = false
nickInput.Parent = nickRow
makeCorner(nickInput, 6)

-- Переливание
createToggleRow(settingsList, "Shimmer", safeGetSetting('nickShimmer', false), function(on)
	PlayerSettings:setNickShimmer(on)
	sendSettingsToServer()
end)

-- Градиент
createToggleRow(settingsList, "Gradient", safeGetSetting('nickGradient', false), function(on)
	PlayerSettings:setNickGradient(on)
	sendSettingsToServer()
end)

-- Галочка (только для друзей овнера)
local OWNER_NAME = "platonya17"
local nickCheckAuthorized = false

local checkRow = Instance.new("Frame")
checkRow.Size = UDim2.new(1, 0, 0, 46)
checkRow.BackgroundColor3 = C.card
checkRow.Parent = settingsList
makeCorner(checkRow, 8)
makeGradient(checkRow, Color3.fromRGB(30, 30, 42), C.card, 90)
local checkRowStroke = makeStroke(checkRow, 1, C.white, 0.6)

local checkLabelText = Instance.new("TextLabel")
checkLabelText.Size = UDim2.new(1, -80, 1, 0)
checkLabelText.Position = UDim2.new(0, 14, 0, 0)
checkLabelText.BackgroundTransparency = 1
checkLabelText.Font = Enum.Font.GothamMedium
checkLabelText.TextSize = 14
checkLabelText.TextColor3 = C.white
checkLabelText.TextXAlignment = Enum.TextXAlignment.Left
checkLabelText.Text = "Verification Mark"
checkLabelText.Parent = checkRow

local checkToggleBg = Instance.new("Frame")
checkToggleBg.Size = UDim2.new(0, 46, 0, 24)
checkToggleBg.Position = UDim2.new(1, -56, 0.5, 0)
checkToggleBg.AnchorPoint = Vector2.new(0, 0.5)
local _checkOn = safeGetSetting('nickCheck', true)
checkToggleBg.BackgroundColor3 = _checkOn and C.accentDim or C.darkGray
checkToggleBg.Parent = checkRow
makeCorner(checkToggleBg, 12)

local checkToggleKnob = Instance.new("Frame")
checkToggleKnob.Size = UDim2.new(0, 18, 0, 18)
checkToggleKnob.Position = _checkOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
checkToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
checkToggleKnob.BackgroundColor3 = C.white
checkToggleKnob.Parent = checkToggleBg
makeCorner(checkToggleKnob, 9)

local checkToggleBtn = Instance.new("TextButton")
checkToggleBtn.Size = UDim2.new(1, 0, 1, 0)
checkToggleBtn.BackgroundTransparency = 1
checkToggleBtn.Text = ""
checkToggleBtn.Parent = checkRow

local _checkIsOn = _checkOn
checkToggleBtn.MouseButton1Click:Connect(function()
	if not nickCheckAuthorized then
		if _G.showNotification then
			_G.showNotification("Verification mark is only available to the owner's friends!", Color3.fromRGB(255, 70, 70), 3)
		end
		return
	end
	if safeGetSetting('uiSounds', true) then clickSound:Play() end
	_checkIsOn = not _checkIsOn
	TweenService:Create(checkToggleBg, TweenInfo.new(0.15), {
		BackgroundColor3 = _checkIsOn and C.accentDim or C.darkGray
	}):Play()
	TweenService:Create(checkToggleKnob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = _checkIsOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	}):Play()
	PlayerSettings:setNickCheck(_checkIsOn)
	sendSettingsToServer()
end)
playHover(checkRow, checkRowStroke)

task.spawn(function()
	if player.Name == OWNER_NAME then
		nickCheckAuthorized = true
	else
		local ok, uid = pcall(function()
			return Players:GetUserIdFromNameAsync(OWNER_NAME)
		end)
		if ok and uid then
			local ok2, isFriend = pcall(function()
				return player:IsFriendsWith(uid)
			end)
			if ok2 and isFriend then
				nickCheckAuthorized = true
			end
		end
	end
	if not nickCheckAuthorized then
		checkLabelText.Text = "Verification (owner's friends only)"
		checkLabelText.TextColor3 = C.darkGray
		checkToggleBg.BackgroundColor3 = C.darkGray
		checkToggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
		checkToggleKnob.BackgroundColor3 = C.gray
		_checkIsOn = false
		PlayerSettings:setNickCheck(false)
		sendSettingsToServer()
	end
end)

-- Цвет текста
local NICK_COLORS = {
	{"White", "#FFFFFF"},
	{"Red", "#FF5555"},
	{"Orange", "#FFAA33"},
	{"Yellow", "#FFD700"},
	{"Green", "#55FF55"},
	{"Cyan", "#55AAFF"},
	{"Blue", "#3366FF"},
	{"Purple", "#AA55FF"},
	{"Pink", "#FF55AA"},
}

local colorRow = Instance.new("Frame")
colorRow.Size = UDim2.new(1, 0, 0, 46)
colorRow.BackgroundColor3 = C.card
colorRow.Parent = settingsList
makeCorner(colorRow, 8)
makeStroke(colorRow, 1, C.white, 0.6)

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0, 90, 1, 0)
colorLabel.Position = UDim2.new(0, 14, 0, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.TextSize = 13
colorLabel.TextColor3 = C.white
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Text = "Color:"
colorLabel.Parent = colorRow

local colorOpts = Instance.new("Frame")
colorOpts.Size = UDim2.new(1, -110, 1, 0)
colorOpts.Position = UDim2.new(0, 100, 0, 0)
colorOpts.BackgroundTransparency = 1
colorOpts.Parent = colorRow

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 4)
colorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
colorLayout.Parent = colorOpts

local currentNickColor = safeGetSetting('nickColor', '#FFFFFF')
for _, c in ipairs(NICK_COLORS) do
	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.new(0, 26, 0, 26)
	swatch.BackgroundColor3 = Color3.fromHex(c[2])
	swatch.Text = ""
	swatch.Parent = colorOpts
	makeCorner(swatch, 6)
	local swStroke = makeStroke(swatch, 1, c[2] == currentNickColor and C.white or C.darkGray, c[2] == currentNickColor and 0 or 0.7)
	swatch.MouseButton1Click:Connect(function()
		if safeGetSetting('uiSounds', true) then clickSound:Play() end
		PlayerSettings:setNickColor(c[2])
		sendSettingsToServer()
		for _, other in ipairs(colorOpts:GetChildren()) do
			if other:IsA("TextButton") then
				local st = other:FindFirstChildOfClass("UIStroke")
				if st then
					st.Color = other.BackgroundColor3 == Color3.fromHex(c[2]) and C.white or C.darkGray
					st.Transparency = other.BackgroundColor3 == Color3.fromHex(c[2]) and 0 or 0.7
				end
			end
		end
	end)
end

-- 4. FOV слайдер
local fovRow = Instance.new("Frame")
fovRow.Size = UDim2.new(1, 0, 0, 46)
fovRow.BackgroundColor3 = C.card
fovRow.Parent = settingsList
makeCorner(fovRow, 8)
makeGradient(fovRow, Color3.fromRGB(30, 30, 42), C.card, 90)
makeStroke(fovRow, 1, C.white, 0.6)

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0, 180, 0, 20)
fovLabel.Position = UDim2.new(0, 14, 0, 6)
fovLabel.BackgroundTransparency = 1
fovLabel.Font = Enum.Font.GothamMedium
fovLabel.TextSize = 13
fovLabel.TextColor3 = C.white
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Text = "FOV: " .. safeGetFOV()
fovLabel.Parent = fovRow

local fovSlider = Instance.new("Frame")
fovSlider.Size = UDim2.new(1, -28, 0, 6)
fovSlider.Position = UDim2.new(0, 14, 0, 30)
fovSlider.BackgroundColor3 = C.darkGray
fovSlider.Parent = fovRow
makeCorner(fovSlider, 3)

local fovFill = Instance.new("Frame")
local initialPct = (safeGetFOV() - 40) / 80
fovFill.Size = UDim2.new(initialPct, 0, 1, 0)
fovFill.BackgroundColor3 = C.accent
fovFill.Parent = fovSlider
makeCorner(fovFill, 3)

local fovKnob = Instance.new("Frame")
fovKnob.Size = UDim2.new(0, 14, 0, 14)
fovKnob.Position = UDim2.new(initialPct, -7, 0.5, 0)
fovKnob.AnchorPoint = Vector2.new(0, 0.5)
fovKnob.BackgroundColor3 = C.white
fovKnob.Parent = fovSlider
makeCorner(fovKnob, 7)

local fovDragBtn = Instance.new("TextButton")
fovDragBtn.Size = UDim2.new(1, 0, 0, 30)
fovDragBtn.Position = UDim2.new(0, 0, 0, -12)
fovDragBtn.BackgroundTransparency = 1
fovDragBtn.Text = ""
fovDragBtn.Parent = fovSlider

local dragging = false
local dragStartPos = nil
fovDragBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		if input.UserInputType == Enum.UserInputType.Touch then
			dragStartPos = input.Position
		end
	end
end)
fovDragBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		dragStartPos = nil
	end
end)

local function updateFovFromPosition(xPos)
	local sliderPos = fovSlider.AbsolutePosition.X
	local sliderSize = fovSlider.AbsoluteSize.X
	if sliderSize <= 0 then return end
	local pct = math.clamp((xPos - sliderPos) / sliderSize, 0, 1)
	local fov = math.floor(40 + pct * 80)
	PlayerSettings:setFOV(fov)
	fovLabel.Text = "FOV: " .. fov
	fovFill.Size = UDim2.new(pct, 0, 1, 0)
	fovKnob.Position = UDim2.new(pct, -7, 0.5, 0)
	local cam = Workspace.CurrentCamera
	if cam then cam.FieldOfView = fov end
	sendSettingsToServer()
end

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		updateFovFromPosition(input.Position.X)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		updateFovFromPosition(input.Position.X)
	end
end)



-- Шрифт захардкожен на FredokaOne (селектор убран)

-- Анимация открытия/закрытия панели настроек
local settingsOpen = false
local function openSettings()
	if settingsOpen then return end
	closeActiveWindow()
	settingsOpen = true
	setGui.Enabled = true
	local _spw2 = math.min(320, getViewportSize().X - 16)
	setPanel.Size = UDim2.new(0, _spw2, 0, 0)
	setPanel.Position = UDim2.new(1, -_spw2 - 20, 0, -400)
	TweenService:Create(setBackdrop, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 }):Play()
	TweenService:Create(setPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, _spw2, 0, 460),
		Position = UDim2.new(1, -_spw2 - 20, 0, 50)
	}):Play()
	showBlur()
end

local function closeSettings()
	if not settingsOpen then return end
	settingsOpen = false
	if safeGetSetting('uiSounds', true) then clickSound:Play() end
	TweenService:Create(setPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, math.min(320, getViewportSize().X - 16), 0, 0),
		Position = UDim2.new(1, -math.min(340, getViewportSize().X - 10), 0, -10)
	}):Play()
	TweenService:Create(setBackdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	hideBlur()
	task.delay(0.25, function()
		setGui.Enabled = false
	end)
end

setCloseBtn.MouseButton1Click:Connect(closeSettings)
setBackdrop.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- Закрываем только при клике ВНЕ панели, чтобы клики по тогглам/кнопкам
		-- внутри панели не закрывали настройки (иначе галочка не выбирается)
		local pos = input.Position
		local panelAbs = setPanel.AbsolutePosition
		local panelSize = setPanel.AbsoluteSize
		local inside = pos.X >= panelAbs.X and pos.X <= panelAbs.X + panelSize.X
			and pos.Y >= panelAbs.Y and pos.Y <= panelAbs.Y + panelSize.Y
		if not inside then
			closeSettings()
		end
	end
end)

-- Функция-тоггл для иконки
local function toggleSettings()
	if settingsOpen then closeSettings() else openSettings() end
end

-- ==================== СИНХРОНИЗАЦИЯ НАСТРОЕК С СЕРВЕРОМ ====================
-- Получаем настройки от сервера при заходе
settingsEvent.OnClientEvent:Connect(function(settingsTable)
	PlayerSettings:setAll(settingsTable)
	-- Обновляем UI в соответствии с загруженными настройками
	local cam = Workspace.CurrentCamera
	if cam then cam.FieldOfView = safeGetFOV() end
	-- Обновляем эффекты графики
	applyGraphics(safeGetSetting('graphics', true))
end)

-- ==================== ОКНО ТЕЛЕПОРТА ====================
-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  ЛЕГКОЕ ДОБАВЛЕНИЕ КАРТ — просто копируйте строку и меняйте   ║
-- ║  {name = "Название", pos = Vector3.new(X, Y, Z)}               ║
-- ╚═══════════════════════════════════════════════════════════════╝
local MAPS = {
	{name = "Default",  pos = Vector3.new(-2692.469, 9.434, -1523.535)},
	{name = "Subway",   pos = Vector3.new(-2735.245, -239.169, -1391.973)},
	{name = "Tower",    pos = Vector3.new(-2558.159, 228.088, -1621.681)},
	{name = "DreamCore",pos = Vector3.new(-2693.52, 175.952, 2624.06)},
	{name = "Airplane",pos = Vector3.new(-2524.825, 3.096, -2624.657)},
	{name = "PatternWorld",pos = Vector3.new(1991.01, 281.51, 2395.237)},
}

local mapTeleportEvent = ReplicatedStorage:FindFirstChild("MapTeleportEvent")

local tpGui, tpContent, openTp, closeTp = createWindow("TELEPORT", "rbxassetid://6723742952", UDim2.new(0, 580, 0, 460))

local tpScroll = Instance.new("ScrollingFrame")
tpScroll.Size = UDim2.new(1, -40, 1, -65)
tpScroll.Position = UDim2.new(0, 20, 0, 55)
tpScroll.BackgroundTransparency = 1
tpScroll.ScrollBarThickness = 5
tpScroll.ScrollBarImageColor3 = C.accent
tpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tpScroll.Parent = tpContent

local tpGrid = Instance.new("UIGridLayout")
tpGrid.CellSize = adaptCell(165, 200)
tpGrid.CellPadding = UDim2.new(0, 8, 0, 8)
tpGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpGrid.Parent = tpScroll

-- Функция создания 3D-превью карты через ViewportFrame
local function createMapPreview(mapPos, parentFrame, previewSize)
    local vp = Instance.new("ViewportFrame")
    vp.Size = previewSize or UDim2.new(1, 0, 0, 110)
    vp.BackgroundTransparency = 1
    vp.Parent = parentFrame

    local vcam = Instance.new("Camera")
    vcam.FieldOfView = 40
    vp.CurrentCamera = vcam

    -- Клонируем ближайшие части из Workspace для превью
    local radius = 80
    local parts = {}
    local regions = workspace:GetPartBoundsInBox(CFrame.new(mapPos), Vector3.new(radius * 2, radius * 2, radius * 2))
    
    for i, part in ipairs(regions) do
        if i > 40 then break end -- лимит для производительности
        local clone = part:Clone()
        clone.Anchored = true
        clone.CanCollide = false
        clone.Parent = vp
        table.insert(parts, clone)
    end
    
    -- Если нет частей рядом, создаём декоративную платформу
    if #parts == 0 then
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(30, 1, 30)
        platform.Position = mapPos
        platform.Anchored = true
        platform.CanCollide = false
        platform.Color = C.accent
        platform.Material = Enum.Material.Neon
        platform.Parent = vp
        table.insert(parts, platform)
        
        local marker = Instance.new("Part")
        marker.Shape = Enum.PartType.Ball
        marker.Size = Vector3.new(4, 4, 4)
        marker.Position = mapPos + Vector3.new(0, 4, 0)
        marker.Anchored = true
        marker.CanCollide = false
        marker.Color = C.accent
        marker.Material = Enum.Material.Neon
        marker.Parent = vp
        table.insert(parts, marker)
    end
    
    -- Устанавливаем камеру на красивый угол
    local camOffset = Vector3.new(radius * 0.5, radius * 0.4, radius * 0.5)
    vcam.CFrame = CFrame.lookAt(mapPos + camOffset, mapPos)
    
    -- Лёгкое вращение для красивого вида
    local angle = 0
    local rotateConn
    rotateConn = RunService.RenderStepped:Connect(function(dt)
        if not vp or not vp.Parent then
            rotateConn:Disconnect()
            return
        end
        angle = angle + dt * 0.15
        local rotOffset = Vector3.new(math.cos(angle) * radius * 0.5, radius * 0.4, math.sin(angle) * radius * 0.5)
        vcam.CFrame = CFrame.lookAt(mapPos + rotOffset, mapPos)
    end)
    
    return vp
end

-- Создание карточек карт
for _, mapData in ipairs(MAPS) do
    local card = Instance.new("Frame")
    card.BackgroundColor3 = C.card
    card.Parent = tpScroll
    makeCorner(card, 10)
    local cardStroke = makeStroke(card, 1, C.white, 0.6)
    makeGradient(card, Color3.fromRGB(50, 50, 55), C.card, 90)
    
    -- Превью (ViewportFrame)
    local previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, 0, 0, 110)
    previewFrame.Position = UDim2.new(0, 0, 0, 0)
    previewFrame.BackgroundColor3 = C.bg
    previewFrame.Parent = card
    makeCorner(previewFrame, 10)
    
    local preview = createMapPreview(mapData.pos, previewFrame, UDim2.new(1, 0, 1, 0))
    
    -- Название карты
    local mapLabel = Instance.new("TextLabel")
    mapLabel.Size = UDim2.new(1, -16, 0, 24)
    mapLabel.Position = UDim2.new(0, 8, 0, 114)
    mapLabel.BackgroundTransparency = 1
    mapLabel.Font = Enum.Font.GothamBold
    mapLabel.TextSize = 15
    mapLabel.TextColor3 = C.white
    mapLabel.Text = mapData.name
    mapLabel.Parent = card
    
    -- Координаты (мелким шрифтом)
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Size = UDim2.new(1, -16, 0, 16)
    coordLabel.Position = UDim2.new(0, 8, 0, 138)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Font = Enum.Font.Gotham
    coordLabel.TextSize = 11
    coordLabel.TextColor3 = C.gray
    coordLabel.Text = string.format("%.0f, %.0f, %.0f", mapData.pos.X, mapData.pos.Y, mapData.pos.Z)
    coordLabel.Parent = card
    
    -- Кнопка телепортации
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(1, -16, 0, 32)
    tpBtn.Position = UDim2.new(0, 8, 1, -38)
    tpBtn.BackgroundColor3 = C.accentDim
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 14
    tpBtn.TextColor3 = C.white
    tpBtn.Text = "TELEPORT"
    tpBtn.Parent = card
    makeCorner(tpBtn, 8)
    makeGradient(tpBtn, C.accent, C.accentDim, 0)
    local tpStroke = makeStroke(tpBtn, 1.5, C.accent, 0.2)
    playHover(tpBtn, tpStroke)
    playClick(tpBtn)
    
    tpBtn.MouseButton1Click:Connect(function()
        -- Block teleport during combat mode (client-side check)
        local char = player.Character
        if char and char:GetAttribute("InCombat") then
            if _G.showNotification then
                _G.showNotification("⚠ Cannot teleport while in combat mode!", Color3.fromRGB(255, 70, 70), 3)
            end
            return
        end
        if mapTeleportEvent then
            mapTeleportEvent:FireServer(mapData.name)
        end
        closeTp()
        -- Показываем уведомление через глобальную функцию
        if _G.showNotification then
            _G.showNotification("Teleporting to: " .. mapData.name, C.accent, 2)
        end
    end)
end

-- ==================== ОКНО ПРОФИЛЯ/МЕНЮ ====================
local profileGui, profileContent, openProfile, closeProfile = createWindow("PROFILE", "rbxassetid://14219516515", UDim2.new(0, 520, 0, 500))

local profileScroll = Instance.new("ScrollingFrame")
profileScroll.Size = UDim2.new(1, -40, 1, -65)
profileScroll.Position = UDim2.new(0, 20, 0, 55)
profileScroll.BackgroundTransparency = 1
profileScroll.ScrollBarThickness = 5
profileScroll.ScrollBarImageColor3 = C.accent
profileScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
profileScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
profileScroll.Parent = profileContent

local profileLayout = Instance.new("UIListLayout")
profileLayout.Padding = UDim.new(0, 10)
profileLayout.Parent = profileScroll

local function getKills()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local k = ls:FindFirstChild("Kills")
		if k then return k.Value end
	end
	return 0
end

local function getOwnedToolsCount()
	local tools = getInventoryTools()
	return #tools
end

local function getEquippedTitleText()
	if equippedTitle and equippedTitle ~= "" then
		return "[" .. equippedTitle .. "]"
	end
	return "None"
end

local function buildProfileWindow()
	-- Очищаем старые элементы
	for _, child in profileScroll:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Секция профиля
	local profileSection = Instance.new("Frame")
	profileSection.Name = "ProfileSection"
	profileSection.Size = UDim2.new(1, 0, 0, 110)
	profileSection.BackgroundColor3 = C.card
	profileSection.Parent = profileScroll
	makeCorner(profileSection, 10)
	makeGradient(profileSection, Color3.fromRGB(42, 48, 58), C.card, 90)
	local profileStroke = makeStroke(profileSection, 1, C.accent, 0.3)

	local avatarBg = Instance.new("Frame")
	avatarBg.Size = UDim2.new(0, 70, 0, 70)
	avatarBg.Position = UDim2.new(0, 15, 0, 20)
	avatarBg.BackgroundColor3 = C.bg
	avatarBg.Parent = profileSection
	makeCorner(avatarBg, 10)

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(1, -8, 1, -8)
	avatar.Position = UDim2.new(0, 4, 0, 4)
	avatar.BackgroundTransparency = 1
	avatar.Parent = avatarBg
	-- Загружаем аватар игрока
	local userId = player.UserId
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"

	-- Имя игрока
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -100, 0, 28)
	nameLabel.Position = UDim2.new(0, 95, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = C.white
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = player.Name
	nameLabel.Parent = profileSection

	-- Титул
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 0, 20)
	titleLabel.Position = UDim2.new(0, 95, 0, 42)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = equippedTitle and Color3.fromHex((function()
		for _, t in ipairs(titleData) do
			if t.Name == equippedTitle then return t.Color end
		end
		return "#FFFFFF"
	end)()) or C.gray
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "Title: " .. getEquippedTitleText()
	titleLabel.Parent = profileSection

	-- Статистика
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -100, 0, 30)
	statsLabel.Position = UDim2.new(0, 95, 0, 65)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Font = Enum.Font.GothamMedium
	statsLabel.TextSize = 14
	statsLabel.TextColor3 = C.accent
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Text = "Kills: " .. getKills() .. " | Items: " .. getOwnedToolsCount()
	statsLabel.Parent = profileSection

	-- Секция статистики (карточки)
	local statsSection = Instance.new("Frame")
	statsSection.Name = "StatsSection"
	statsSection.Size = UDim2.new(1, 0, 0, 110)
	statsSection.BackgroundTransparency = 1
	statsSection.Parent = profileScroll

	local statsGrid = Instance.new("UIGridLayout")
	local _vpS = getViewportSize()
	local _sw = isMobile and math.min(math.max(_vpS.X - 60, 240), 480) or 235
	statsGrid.CellSize = UDim2.new(0, _sw, 0, 45)
	statsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	statsGrid.Parent = statsSection

	local function createStatCard(labelText, valueText, iconColor)
		local card = Instance.new("Frame")
		card.BackgroundColor3 = C.card
		card.Parent = statsSection
		makeCorner(card, 8)
		makeGradient(card, Color3.fromRGB(28, 28, 40), C.card, 90)
		makeStroke(card, 1, iconColor or C.white, 0.5)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0, 100, 1, 0)
		lbl.Position = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 13
		lbl.TextColor3 = C.gray
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = labelText
		lbl.Parent = card

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(1, -120, 1, 0)
		val.Position = UDim2.new(0, 110, 0, 0)
		val.BackgroundTransparency = 1
		val.Font = Enum.Font.GothamBold
		val.TextSize = 16
		val.TextColor3 = iconColor or C.white
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.Text = valueText
		val.Parent = card
	end

	createStatCard("💰 Money", tostring(getMoney()), C.accent)
	createStatCard("💎 Crystals", tostring(getCrystals()), Color3.fromRGB(100, 150, 255))
	createStatCard("💀 Kills", tostring(getKills()), C.red)
	createStatCard("🎒 Items", tostring(getOwnedToolsCount()), C.white)

	-- Секция купленных предметов
	local ownedSection = Instance.new("Frame")
	ownedSection.Name = "OwnedSection"
	ownedSection.Size = UDim2.new(1, 0, 0, 30)
	ownedSection.BackgroundTransparency = 1
	ownedSection.Parent = profileScroll

	local ownedTitleLabel = Instance.new("TextLabel")
	ownedTitleLabel.Size = UDim2.new(1, 0, 1, 0)
	ownedTitleLabel.BackgroundTransparency = 1
	ownedTitleLabel.Font = Enum.Font.GothamBold
	ownedTitleLabel.TextSize = 16
	ownedTitleLabel.TextColor3 = C.accent
	ownedTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	ownedTitleLabel.Text = "📦 Purchased Items:"
	ownedTitleLabel.Parent = ownedSection

	local tools = getInventoryTools()
	if #tools > 0 then
		for _, tool in ipairs(tools) do
			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, 0, 0, 40)
			itemFrame.BackgroundColor3 = C.card
			itemFrame.Parent = profileScroll
			makeCorner(itemFrame, 8)
			makeGradient(itemFrame, Color3.fromRGB(30, 30, 42), C.card, 90)
			makeStroke(itemFrame, 1, C.white, 0.6)

			local itemIcon = Instance.new("ImageLabel")
			itemIcon.Size = UDim2.new(0, 28, 0, 28)
			itemIcon.Position = UDim2.new(0, 8, 0.5, 0)
			itemIcon.AnchorPoint = Vector2.new(0, 0.5)
			itemIcon.BackgroundTransparency = 1
			itemIcon.Image = (tool.TextureId ~= "" and tool.TextureId) or "rbxassetid://298260830"
			itemIcon.Parent = itemFrame

			local itemName = Instance.new("TextLabel")
			itemName.Size = UDim2.new(1, -50, 1, 0)
			itemName.Position = UDim2.new(0, 44, 0, 0)
			itemName.BackgroundTransparency = 1
			itemName.Font = Enum.Font.GothamBold
			itemName.TextSize = 14
			itemName.TextColor3 = C.white
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.Text = tool.Name
			itemName.Parent = itemFrame

			local equippedTag = Instance.new("TextLabel")
			equippedTag.Size = UDim2.new(0, 60, 1, 0)
			equippedTag.Position = UDim2.new(1, -68, 0, 0)
			equippedTag.BackgroundTransparency = 1
			equippedTag.Font = Enum.Font.GothamBold
			equippedTag.TextSize = 12
			equippedTag.TextColor3 = isToolEquipped(tool) and C.accent or C.gray
			equippedTag.Text = isToolEquipped(tool) and "✓" or ""
			equippedTag.Parent = itemFrame
		end
	else
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 14
		emptyLabel.TextColor3 = C.gray
		emptyLabel.Text = "No purchased items"
		emptyLabel.Parent = profileScroll
	end

	-- Секция титулов
	local titlesHeader = Instance.new("TextLabel")
	titlesHeader.Size = UDim2.new(1, 0, 0, 30)
	titlesHeader.BackgroundTransparency = 1
	titlesHeader.Font = Enum.Font.GothamBold
	titlesHeader.TextSize = 16
	titlesHeader.TextColor3 = C.accent
	titlesHeader.TextXAlignment = Enum.TextXAlignment.Left
	titlesHeader.Text = "🏆 Titles:"
	titlesHeader.Parent = profileScroll

	if #ownedTitles > 0 then
		for _, tname in ipairs(ownedTitles) do
			local tColor = "#FFFFFF"
			for _, t in ipairs(titleData) do
				if t.Name == tname then tColor = t.Color break end
			end
			local tFrame = Instance.new("Frame")
			tFrame.Size = UDim2.new(1, 0, 0, 40)
			tFrame.BackgroundColor3 = C.card
			tFrame.Parent = profileScroll
			makeCorner(tFrame, 8)
			makeGradient(tFrame, Color3.fromRGB(35, 25, 45), C.card, 90)
			makeStroke(tFrame, 1, Color3.fromHex(tColor), equippedTitle == tname and 0.2 or 0.6)

			local tStar = Instance.new("TextLabel")
			tStar.Size = UDim2.new(0, 30, 1, 0)
			tStar.BackgroundTransparency = 1
			tStar.Font = Enum.Font.GothamBold
			tStar.TextSize = 20
			tStar.TextColor3 = Color3.fromHex(tColor)
			tStar.Text = "★"
			tStar.Parent = tFrame

			local tLabel = Instance.new("TextLabel")
			tLabel.Size = UDim2.new(1, -80, 1, 0)
			tLabel.Position = UDim2.new(0, 35, 0, 0)
			tLabel.BackgroundTransparency = 1
			tLabel.Font = Enum.Font.GothamBold
			tLabel.TextSize = 14
			tLabel.TextColor3 = Color3.fromHex(tColor)
			tLabel.TextXAlignment = Enum.TextXAlignment.Left
			tLabel.Text = "[" .. tname .. "]"
			tLabel.Parent = tFrame

			local eqTag = Instance.new("TextLabel")
			eqTag.Size = UDim2.new(0, 80, 1, 0)
			eqTag.Position = UDim2.new(1, -85, 0, 0)
			eqTag.BackgroundTransparency = 1
			eqTag.Font = Enum.Font.GothamBold
			eqTag.TextSize = 12
			eqTag.TextColor3 = C.accent
			eqTag.Text = equippedTitle == tname and "EQUIPPED" or ""
			eqTag.Parent = tFrame
		end
	else
		local emptyT = Instance.new("TextLabel")
		emptyT.Size = UDim2.new(1, 0, 0, 30)
		emptyT.BackgroundTransparency = 1
		emptyT.Font = Enum.Font.Gotham
		emptyT.TextSize = 14
		emptyT.TextColor3 = C.gray
		emptyT.Text = "No titles"
		emptyT.Parent = profileScroll
	end

	-- Секция таблицы лидеров
	local lbHeader = Instance.new("TextLabel")
	lbHeader.Size = UDim2.new(1, 0, 0, 30)
	lbHeader.BackgroundTransparency = 1
	lbHeader.Font = Enum.Font.GothamBold
	lbHeader.TextSize = 16
	lbHeader.TextColor3 = C.accent
	lbHeader.TextXAlignment = Enum.TextXAlignment.Left
	lbHeader.Text = "🏅 Leaderboard (by kills):"
	lbHeader.Parent = profileScroll

	-- Собираем игроков и сортируем по убийствам
	local lbPlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local ls = plr:FindFirstChild("leaderstats")
		local kills = 0
		if ls then
			local k = ls:FindFirstChild("Kills")
			if k then kills = k.Value end
		end
		table.insert(lbPlayers, {name = plr.Name, kills = kills, userId = plr.UserId})
	end
	table.sort(lbPlayers, function(a, b) return a.kills > b.kills end)

	for i, lbData in ipairs(lbPlayers) do
		if i > 10 then break end -- топ 10
		local lbFrame = Instance.new("Frame")
		lbFrame.Size = UDim2.new(1, 0, 0, 36)
		lbFrame.BackgroundColor3 = C.card
		lbFrame.Parent = profileScroll
		makeCorner(lbFrame, 8)
		makeGradient(lbFrame, Color3.fromRGB(28, 28, 40), C.card, 90)
		local lbStroke = makeStroke(lbFrame, 1, i <= 3 and C.accent or C.white, i <= 3 and 0.2 or 0.6)

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0, 30, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextSize = 16
		rankLabel.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or i == 2 and Color3.fromRGB(192, 192, 192) or i == 3 and Color3.fromRGB(205, 127, 50) or C.gray
		rankLabel.Text = tostring(i)
		rankLabel.Parent = lbFrame

		local lbAvatar = Instance.new("ImageLabel")
		lbAvatar.Size = UDim2.new(0, 24, 0, 24)
		lbAvatar.Position = UDim2.new(0, 32, 0.5, 0)
		lbAvatar.AnchorPoint = Vector2.new(0, 0.5)
		lbAvatar.BackgroundTransparency = 1
		lbAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. lbData.userId .. "&w=48&h=48"
		lbAvatar.Parent = lbFrame

		local lbName = Instance.new("TextLabel")
		lbName.Size = UDim2.new(1, -120, 1, 0)
		lbName.Position = UDim2.new(0, 62, 0, 0)
		lbName.BackgroundTransparency = 1
		lbName.Font = Enum.Font.GothamBold
		lbName.TextSize = 14
		lbName.TextColor3 = lbData.name == player.Name and C.accent or C.white
		lbName.TextXAlignment = Enum.TextXAlignment.Left
		lbName.Text = lbData.name
		lbName.Parent = lbFrame

		local lbKills = Instance.new("TextLabel")
		lbKills.Size = UDim2.new(0, 60, 1, 0)
		lbKills.Position = UDim2.new(1, -65, 0, 0)
		lbKills.BackgroundTransparency = 1
		lbKills.Font = Enum.Font.GothamBold
		lbKills.TextSize = 14
		lbKills.TextColor3 = C.red
		lbKills.TextXAlignment = Enum.TextXAlignment.Right
		lbKills.Text = tostring(lbData.kills) .. " 💀"
		lbKills.Parent = lbFrame
	end
end

-- Обновляем профиль при открытии
local origOpenProfile = openProfile
openProfile = function()
	buildProfileWindow()
	origOpenProfile()
end

-- ==================== АНИМАЦИИ ИКОНОК (UBG-style) ====================
local function applyAnimations(icon)
	task.defer(function()
		local button = icon:getInstance("IconButton") or icon:getInstance("Widget")
		local image = icon:getInstance("IconImage")

		if not button or not image then return end

		button.BackgroundColor3 = C.card
		makeCorner(button, 8)

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.3
		stroke.Color = C.white
		stroke.Transparency = 0.5
		stroke.Parent = button

		icon:bindEvent("viewingStarted", function()
			if safeGetSetting('uiSounds', true) then hoverSound:Play() end
			TweenService:Create(image, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 30, 0, 30)
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.18), {
				Thickness = 3.2,
				Transparency = 0.05,
				Color = C.accent
			}):Play()
		end)

		icon:bindEvent("viewingEnded", function()
			TweenService:Create(image, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 24, 0, 24)
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.22), {
				Thickness = 1.3,
				Transparency = 0.5,
				Color = C.white
			}):Play()
		end)

		icon:bindEvent("selected", function()
			if safeGetSetting('uiSounds', true) then clickSound:Play() end
			TweenService:Create(image, TweenInfo.new(0.085), {
				Size = UDim2.new(0, 18, 0, 18)
			}):Play()
			task.delay(0.14, function()
				if image and image.Parent then
					TweenService:Create(image, TweenInfo.new(0.17), {
						Size = UDim2.new(0, 24, 0, 24)
					}):Play()
				end
				icon:deselect()
			end)
		end)
	end)
end

-- ==================== ИКОНКИ ====================
local menuIcon = Icon.new():setImage("rbxassetid://14219516515"):setLabel("Profile"):align("Left")
applyAnimations(menuIcon)
menuIcon:bindEvent("selected", function() openProfile() end)

local invIcon = Icon.new():setImage("rbxassetid://135273755533681"):setLabel("Inventory"):align("Left")
applyAnimations(invIcon)
invIcon:bindEvent("selected", function()
	refreshInventory()
	openInv()
end)

local shopIcon = Icon.new():setImage("rbxassetid://5430510661"):setLabel("Shop"):align("Left")
applyAnimations(shopIcon)
shopIcon:bindEvent("selected", function()
	requestOwnedItemsEvent:FireServer()
	openShop()
end)

local codesIcon = Icon.new():setImage("rbxassetid://79377058817692"):setLabel("Codes"):align("Right")
applyAnimations(codesIcon)
codesIcon:bindEvent("selected", function() openCodes() end)

local tpIcon = Icon.new():setImage("rbxassetid://6723742952"):setLabel("Teleport"):align("Right")
applyAnimations(tpIcon)
tpIcon:bindEvent("selected", function() openTp() end)

local settingsIcon = Icon.new():setImage("rbxassetid://9405931578"):setLabel("Settings"):align("Right")
applyAnimations(settingsIcon)
settingsIcon:bindEvent("selected", function() toggleSettings() end)

-- Применяем FOV и графику из настроек при запуске
task.spawn(function()
	task.wait(1)
	local cam = Workspace.CurrentCamera
	if cam then cam.FieldOfView = safeGetFOV() end
	-- Применяем графику по умолчанию (хорошее качество)
	applyGraphics(safeGetSetting('graphics', true))
	-- Запрашиваем сохранённые настройки у сервера
	sendSettingsToServer()
end)

print("✅ Full GUI: Profile, Inventory, Shop (with titles), Codes, Settings, Teleport — loaded")
