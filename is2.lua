local buffer = require("doubleBuffering")
local GUI = require("GUI")
local comp = require("component")
local advancedLua = require("advancedLua")
local fs = require("filesystem")
local wrapper = require("is2wrapper")

local gpu = comp.gpu

local app = GUI.application()
local config = {
	["firstLaunchWindow"] = true,
	["enableAntifreeze"] = true
}
local colors = { 
	mainColor = 0x0000AA,
	desktopBackground = 0xC3C7CB,

    textColor = 0x000000,

    button = 0xC0C0C0,
    buttonText = 0x000000,
    buttonPressed = 0x8E8E8E,
    buttonTextPressed = 0x000000,

    inputBackground = 0xC0C0C0,
    inputText = 0x383838,
    inputPlaceholderText = 0xFFFFFF,
    inputBackgroundFocused = 0xd1d1d1,
    inputTextFocused = 0x000000
}
local windows = {}
windows.minimized = {}
windows.minimizedButtons = {}
windows.apps = {}

local function saveParams()
	table.toFile("/Interstellar/params.txt", config)
end

local function loadParams()
	if not fs.exists("/Interstellar/") then
		fs.makeDirectory("/Interstellar/")
	end

	if not fs.exists("/Interstellar/params.txt") then
		saveParams()
	end

	config = table.fromFile("/Interstellar/params.txt")
end

local function iInput(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)
	local input = GUI.input(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)

	input.colors.cursor = colors.mainColor

	return input
end

local function iIntInput(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)
	local input = iInput(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)

	input.validator = function(inputText)
		if tonumber(inputText) == nil then
			return false
		end

		return true
	end

	return input
end

local function iRangedIntInput(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, min, max)
	local input = iIntInput(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, false, nil)

	input.onValidInputFinished = function(num)

	end

	input.onInputFinished = function(_, input)
		num = tonumber(input.text)

		if num < min then num = min elseif num > max then num = max end

		input.text = tostring(num)

		input.onValidInputFinished(num)
	end

	return input
end

local function iActionButtons(x, y, width)
	local container = GUI.container(x, y, width, 1)

	container.close = container:addChild(GUI.button(1, 1, 1, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "―"))
	container.minimize = container:addChild(GUI.button(container.width, 1, 1, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "▼"))

	return container
end

local function iTitledWindow(x, y, width, height, title) 
	local window = GUI.window(x, y, width, height)

	window.name = title

	window.backgroundPanel = window:addChild(GUI.panel(1, 1, width, height, 0xFFFFFF))
	window.titlePanel = window:addChild(GUI.panel(1, 1, width, 1, colors.mainColor))
	window.titleLabel = window:addChild(GUI.label(1, 1, width, height, 0xFFFFFF, title)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	window.actionButtons = window:addChild(iActionButtons(2, 2, width))
	window.actionButtons.localX = 1
	window.actionButtons.localY = 1

	window.actionButtons.close.onTouch = function()
		window:remove()
	end

	window.actionButtons.minimize.onTouch = function()
		windows.addMinimizedWindow(window)
	end

	return window
end

windows.redrawWindowIcons = function()
	for _, button in pairs(windows.minimizedButtons) do
		button:remove()
	end

	windows.minimizedButtons = {}

    for i, window in pairs(windows.minimized) do
        window:moveToBack()

        local button = GUI.framedButton(1 + i * 12 - 12, 44, 12, 6, 0x000000, 0x000000, 0xFAFAFA, 0xFAFAFA, window.name)
        button.window = window

    	button.onTouch = function()
    		windows.removeMinimizedWindow(button.window)
    	end

        app:addChild(button)
        table.insert(windows.minimizedButtons, button)
    end
end

windows.addMinimizedWindow = function(window)
    table.insert(windows.minimized, window)

    windows.redrawWindowIcons()
end

windows.removeMinimizedWindow = function(window)
    for k, window2 in pairs(windows.minimized) do
        if window == window2 then
            window:moveToFront()
            table.remove(windows.minimized, k)

            break
        end
    end

    windows.redrawWindowIcons()
end

windows.debug = function(x, y)
	local window = iTitledWindow(x, y, 30, 11, "Debug")

	window.localY = 2
	text = window:addChild(GUI.text(2, 2, 0x000000, "Minimized Windows: "..tostring(#windows.minimized)))
	window:addChild(GUI.adaptiveButton(2, 4, 3, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Reload")).onTouch = function()
		text.text = "Minimized Windows: "..tostring(#windows.minimized)
	end
    window:addChild(GUI.adaptiveButton(17, 4, 3, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Windows")).onTouch = function()
        if #windows.minimized < 1 then
            GUI.alert("No minimized windows!")
            return
        end
        
		local data = windows.minimized[1].name or "none"
		GUI.alert(#windows.minimized.."\n"..data)
    end
    window:addChild(GUI.adaptiveButton(2, 8, 2, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "ShowAll")).onTouch = function()
		for _, window in pairs(windows.minimized) do
            windows.removeMinimizedWindow(window)
        end
	end
	window:addChild(GUI.adaptiveButton(16, 8, 1, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "IWrapperDemo")).onTouch = function()
		wrapper.toggleDemoMode()
	end

	return window
end

windows.firstLaunchWindow = function(x, y)
	local window = iTitledWindow(x, y, 62, 6, "Welcome to Interstellar2")
	window.name = "Interstellar2"

	window:addChild(GUI.text(2, 2, colors.textColor, "You are launching Interstellar2 first time."))
	window:addChild(GUI.text(2, 3, colors.textColor, "Be sure to check out settings to configure IS2 or your ship."))
	window:addChild(GUI.text(2, 4, colors.textColor, "Good luck, have fun!"))

	window:addChild(GUI.button(window.width-6, window.height-1, 6, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "OK")).onTouch = function()
		window:remove()
		app:addChild(windows.mainWindow(5, 5))

		config.firstLaunchWindow = false

		saveParams()
	end

	window:addChild(GUI.button(window.width-13, window.height-1, 6, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Exit")).onTouch = function()
		app:stop()
	end

	return window
end

windows.mainWindow = function(x, y)
	local window = iTitledWindow(x, y, 80, 25, "Interstellar2 Main Window")
	window.name = "Main"

	count = 1
    for _, windowApp in pairs(windows.apps) do
		window:addChild(GUI.framedButton(2 + 12 * count - 12, 3, 12, 6, 0x000000, 0x000000, 0xFAFAFA, 0xFAFAFA, windowApp.name)).onTouch = function()
	    	if windowApp.check() then
				app:addChild(windowApp.getWindow(10, 10))
			end
		end

		count = count + 1
    end

	window.actionButtons.close.onTouch = function()
		app:stop()

		comp.gpu.setBackground(0x000000)
		comp.gpu.setForeground(0xFFFFFF)
		require("term").clear()
		print("Thanks for using Interstellar2!")
	end
	
	return window
end

windows.apps.jumpWindow = {
	name = "Jump Menu",
	currentWindow = nil,

	check = function()
		if not wrapper.shipApiAvailable() then
			GUI.alert("Ship is not available.")
			return false
		end

		return true
	end,

	update = function()
		if windows.apps.jumpWindow.currentWindow then
			x = windows.apps.jumpWindow.currentWindow.x
			y = windows.apps.jumpWindow.currentWindow.y

			windows.apps.jumpWindow.currentWindow:remove()

			app:addChild(windows.apps.jumpWindow.getWindow(x, y))
		end
	end,

	getWindow = function(x, y)
		local window = iTitledWindow(x, y, 62, 20, "Jump Window")

		wrapper.ship.setCommand("MANUAL")

		local max = wrapper.ship.getMaxJumpDistance()
		local pX, pY, pZ = wrapper.ship.getDimPositive()
	    local nX, nY, nZ = wrapper.ship.getDimNegative()

	    local maxX = max + pX + nX
	    local maxY = max + pY + nY
	    local maxZ = max + pZ + nZ

	    local rotmax = 270
	    local jumpX, jumpY, jumpZ = wrapper.ship.getMovement()
	    local rot = 0

	    window:addChild(GUI.label(2, 3, 8, 1, colors.textColor, "Entered values will be automatically limited."))

	    window:addChild(GUI.label(2, 5, 16, 1, colors.textColor, string.format("X (%s - %s)", pX + nX, maxX)))
	    window:addChild(iRangedIntInput(2, 6, 30, 1, colors.inputBackground, colors.inputText, colors.inputPlaceholderText, colors.inputBackgroundFocused, colors.inputTextFocused, jumpX, "X", -maxX, maxX)).onValidInputFinished = function(num)
	    	jumpX = num
	   		wrapper.ship.setMovement(jumpX, jumpY, jumpZ)
	    end      

	    window:addChild(GUI.label(2, 8, 12, 1, colors.textColor, string.format("Y (%s - %s)", pY + nY, maxY)))
	    window:addChild(iRangedIntInput(2, 9, 30, 1, colors.inputBackground, colors.inputText, colors.inputPlaceholderText, colors.inputBackgroundFocused, colors.inputTextFocused, jumpY, "Y", -maxY, maxY)).onValidInputFinished = function(num)
	    	jumpY = num
	    	wrapper.ship.setMovement(jumpX, jumpY, jumpZ)
	    end    

	    window:addChild(GUI.label(2, 11, 14, 1, colors.textColor, string.format("Z (%s - %s)", pZ + nZ, maxZ)))
	    window:addChild(iRangedIntInput(2, 12, 30, 1, colors.inputBackground, colors.inputText, colors.inputPlaceholderText, colors.inputBackgroundFocused, colors.inputTextFocused, jumpZ, "Z", -maxZ, maxZ)).onValidInputFinished = function(num)
	    	jumpZ = num
	   		wrapper.ship.setMovement(jumpX, jumpY, jumpZ)
	    end    

	    window:addChild(GUI.label(2, 14, 14, 1, colors.textColor, 'Clockwise rotation steps (each is 90°)'))
	    window:addChild(iRangedIntInput(2, 15, 30, 1, colors.inputBackground, colors.inputText, colors.inputPlaceholderText, colors.inputBackgroundFocused, colors.inputTextFocused, rot, "R", 1, 4)).onValidInputFinished = function(num)
	    	rot = num
	    end

	    window:addChild(GUI.button(2, 17, 29, 3, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Jump")).onTouch = function()
	    	wrapper.ship.jump(rot, jumpX, jumpY, jumpZ, false)
	    end

	    window:addChild(GUI.button(33, 17, 29, 3, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Hyperspace jump")).onTouch = function()
	    	wrapper.ship.jump(nil, nil, nil, nil, true)
	    end

		window:addChild(GUI.button(window.width - 9, 3, 9, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Refresh")).onTouch = function()
	    	windows.apps.jumpWindow.update()
	    end

    	windows.apps.jumpWindow.currentWindow = window

	    return window
	end
}

windows.apps.shipInfoWindow = {
	name = "Ship Info",
	currentWindow = nil,

	check = function()
		if not wrapper.shipApiAvailable() then
			GUI.alert("Ship is not available.")
			return false
		end

		return true
	end,

	update = function()
		if windows.apps.shipInfoWindow.currentWindow then
			x = windows.apps.shipInfoWindow.currentWindow.x
			y = windows.apps.shipInfoWindow.currentWindow.y

			windows.apps.shipInfoWindow.currentWindow:remove()

			app:addChild(windows.apps.shipInfoWindow.getWindow(x, y))
		end
	end,

	getWindow = function(x, y)
		local window = iTitledWindow(x, y, 57, 13, "Ship Info")

		local x, y, z = wrapper.ship.getPosition()

		window:addChild(GUI.label(2, 3, 8, 1, colors.textColor, "Coordinates:"))
		window:addChild(GUI.label(2, 4, 8, 1, colors.textColor, x))
		window:addChild(GUI.label(2, 5, 8, 1, colors.textColor, y))
		window:addChild(GUI.label(2, 6, 8, 1, colors.textColor, z))

		local dim = wrapper.ship.getDimensionType()
		if dim == 0 then dim = "Space" elseif dim == 1 then dim = "Hyperspace" else dim = "Unknown" end

		window:addChild(GUI.label(2, 8, 8, 1, colors.textColor, "Dimension:"))
		window:addChild(GUI.label(2, 9, 8, 1, colors.textColor, dim))

		local oX, oZ = wrapper.ship.getOrientation()

		window:addChild(GUI.label(2, 11, 8, 1, colors.textColor, "Orientation:"))
		window:addChild(GUI.label(2, 12, 8, 1, colors.textColor, string.format("X: %s, Z: %s", oX, oZ)))

		window:addChild(GUI.label(17, 3, 8, 1, colors.textColor, string.format("Name: %s", wrapper.ship.getShipName())))
		window:addChild(GUI.label(17, 5, 8, 1, colors.textColor, string.format("Mass: %s", wrapper.ship.getShipMass())))

		local assembly
		if wrapper.ship.isAssemblyValid() then assembly = "Valid" else assembly = "Invalid" end

		window:addChild(GUI.label(17, 7, 8, 1, colors.textColor, string.format("Assembly: %s", assembly)))

		local shipEnergy = wrapper.ship.getShipEnergy()
		local maxEnergy = wrapper.ship.getMaxShipEnergy()
		local energyPercents = math.floor((shipEnergy / maxEnergy) * 100)

		window:addChild(GUI.progressBar(17, 9, 40, colors.mainColor, colors.button, colors.textColor, energyPercents, true, true, "Ship energy: ", "%"))

		window:addChild(GUI.button(window.width - 9, window.height - 1, 9, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Refresh")).onTouch = function()
	    	windows.apps.shipInfoWindow.update()
	    end

	    windows.apps.shipInfoWindow.currentWindow = window

	    return window
	end
}

windows.apps.radarWindow = {
	name = "WarpRadar",
	currentWindow = nil,
	lastTextBox = {},
	scanInProcess = false,

	check = function()
		if not wrapper.radarApiAvailable() then
			GUI.alert("Radar is not available.")
			return false
		end

		return true
	end,

	update = function()
		if windows.apps.radarWindow.currentWindow then
			x = windows.apps.radarWindow.currentWindow.x
			y = windows.apps.radarWindow.currentWindow.y

			windows.apps.radarWindow.currentWindow:remove()

			app:addChild(windows.apps.radarWindow.getWindow(x, y))
		end
	end,

	getWindow = function(x, y)
		local window = iTitledWindow(x, y, 57, 40, "WarpRadar")

		local radarRadius = 1

		local energyPercents = math.floor((wrapper.radar.getRadarEnergy() / wrapper.radar.getMaxRadarEnergy()) * 100 + 0.5)
		window:addChild(GUI.button(window.width - 10, 3, 9, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Refresh")).onTouch = function()
	    	windows.apps.radarWindow.update()
	    end

		window:addChild(GUI.progressBar(2, 3, 40, colors.mainColor, colors.button, colors.textColor, energyPercents, true, true, "Radar energy: ", "%"))

	    local slider = window:addChild(GUI.slider(4, 6, 40, colors.mainColor, colors.button, colors.buttonPressed, colors.textColor, 1, 9999, 1, true, "Radar radius: ", " blocks"))

		slider.roundValues = true
		slider.onValueChanged = function()
			radarRadius = math.round(slider.value)
		end

		window:addChild(GUI.label(2, 9, 8, 1, colors.textColor, "Limit radius to current energy:"))
		switch = window:addChild(GUI.switch(35, 9, 8, colors.mainColor, colors.button, colors.buttonPressed, false))

		switch.onStateChanged = function()
			if switch.state then
				local newMaximum = 10 * (10*wrapper.radar.getRadarEnergy()^(1/3))

				slider.maximumValue = newMaximum
				
				local newSliderValue = slider.value
				if newSliderValue > newMaximum then newSliderValue = newMaximum end
				slider.value = newSliderValue

				slider.onValueChanged()
			else
				slider.maximumValue = 9999

				slider.onValueChanged()
			end
		end

		local textBox = window:addChild(GUI.textBox(2, 11, 55, 29, colors.button, colors.textColor, windows.apps.radarWindow.lastTextBox, 1, 1, 0))
		textBox.scrollBarEnabled = true

		window:addChild(GUI.button(window.width - 7, 9, 6, 1, colors.button, colors.buttonText, colors.buttonPressed, colors.buttonTextPressed, "Scan")).onTouch = function()
			if wrapper.radar.getRadarEnergy() < wrapper.radar.getRequiredEnergy(radarRadius) then
				GUI.alert("Not enough energy for this scan!")
				return
			elseif windows.apps.radarWindow.scanInProcess then
				return
			end

	    	wrapper.radar.scan(radarRadius)
	    	windows.apps.radarWindow.scanInProcess = true
	    end

	    local obj = app:addChild(GUI.object(0, 0, 1, 1))
	    obj.eventHandler = function(app, obj, event, count) 
	    	if event ~= "is2wrapperRadarScan" then
	    		return
	    	end

	    	windows.apps.radarWindow.scanInProcess = false
	    	textBox.lines = {}

	    	if count < 1 then
	    		table.insert(textBox.lines, {text = "Nothing was found :(", color = 0xFF0000})
	    		app:draw()

    			windows.apps.radarWindow.lastTextBox = textBox.lines

	    		return
    		end

	    	for i = 0, count do
	    		local objectType, name, x, y, z, mass = wrapper.radar.getResult(i)

	    		if objectType ~= nil then
	    			table.insert(textBox.lines, string.format("%s %s, X: %s, Y: %s, Z: %s, M: %s", objectType, name, x, y, z, mass))
	    		end
			end

	    	textBox:scrollToStart()
			windows.apps.radarWindow.lastTextBox = textBox.lines

			app:draw()
		end	

	    windows.apps.radarWindow.currentWindow = window

	    return window
	end
}

------------------------------------------------------------------------
local maxRes = {}
maxRes[1], maxRes[2] = gpu.maxResolution()

if gpu.getDepth() < 4 and (maxRes[1] < 80 and maxRes[2] < 25) then
	io.stderr:write("Ошибка: ваша видеокарта не подходит для данной программы.")
end

loadParams()

local res = {}
res[1], res[2] = gpu.getResolution()

if (res[1] < 100) and (res[2] < 40) then
	gpu.setResolution(160, 50)
end
buffer.setResolution(res[1], res[2])

app:addChild(GUI.panel(1, 1, app.width, app.height, colors.desktopBackground))

if config.firstLaunchWindow then
	app:addChild(windows.firstLaunchWindow(5, 5))
else
	app:addChild(windows.mainWindow(5, 5))
end

app:addChild(windows.debug(5, 30))
------------------------------------------------------------------------
app:draw(true)
app:start()