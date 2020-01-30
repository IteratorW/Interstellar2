local buffer = require("doubleBuffering")
local GUI = require("GUI")
local comp = require("component")
local advancedLua = require("advancedLua")
local fs = require("filesystem")
local gpu = comp.gpu

local app = GUI.application()
local config = {
	["firstLaunchWindow"] = true,
	["enableAntifreeze"] = true
}
local colors = {}
local windows = {}
windows.minimized = {}
windows.minimizedButtons = {}

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

local function iActionButtons(x, y, width)
	local container = GUI.container(x, y, width, 1)

	container.close = container:addChild(GUI.button(1, 1, 1, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "―"))
	container.minimize = container:addChild(GUI.button(container.width, 1, 1, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "▼"))

	return container
end

local function iTitledWindow(x, y, width, height, title) 
	local window = GUI.window(x, y, width, height)

	window.backgroundPanel = window:addChild(GUI.panel(1, 1, width, height, 0xFFFFFF))
	window.titlePanel = window:addChild(GUI.panel(1, 1, width, 1, 0x0000AA))
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
	local window = iTitledWindow(x, y, 30, 10, "Debug")
	window.name = "Debug"

	window.localY = 2
	text = window:addChild(GUI.text(2, 2, 0x000000, "Minimized Windows: "..tostring(#windows.minimized)))
	window:addChild(GUI.adaptiveButton(2, 4, 3, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Reload")).onTouch = function()
		text.text = "Minimized Windows: "..tostring(#windows.minimized)
	end
    window:addChild(GUI.adaptiveButton(17, 4, 3, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Windows")).onTouch = function()
        if #windows.minimized < 1 then
            GUI.alert("No minimized windows!")
            return
        end
        
		local data = windows.minimized[1].name or "none"
		GUI.alert(#windows.minimized.."\n"..data)
    end
    window:addChild(GUI.adaptiveButton(2, 8, 2, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Show all")).onTouch = function()
		for _, window in pairs(windows.minimized) do
            windows.removeMinimizedWindow(window)
        end
	end

	return window
end

windows.firstLaunchWindow = function(x, y)
	local window = iTitledWindow(x, y, 62, 6, "Welcome to Interstellar2")
	window.name = "Interstellar2"

	window:addChild(GUI.text(2, 2, 0x000000, "You are launching Interstellar2 first time."))
	window:addChild(GUI.text(2, 3, 0x000000, "Be sure to check out settings to configure IS2 or your ship."))
	window:addChild(GUI.text(2, 4, 0x000000, "Good luck, have fun!"))

	window:addChild(GUI.button(window.width-6, window.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "OK")).onTouch = function()
		window:remove()
		app:addChild(windows.mainWindow(5, 5))

		config.firstLaunchWindow = false

		saveParams()
	end

	window:addChild(GUI.button(window.width-13, window.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Exit")).onTouch = function()
		app:stop()
	end

	return window
end

windows.mainWindow = function(x, y)
	local window = iTitledWindow(x, y, 80, 25, "Interstellar2 Main Window")
	window.name = "Main"

	window.actionButtons.close.onTouch = function()
		app:stop()
	end
	
	return window
end

windows.jumpWindow = function(x, y)
	local window = iTitledWindow(x, y, 80, 25, "Jump Window")

    local max = 20
    local x,y,z = 1, 1, 1
    local x2,y2,z2 = 1, 1, 1
    local mindx = x + x2
    local mindy = z + z2
    local mindz = y + y2
    local rotmax = 270
    local jumpX, jumpY, jumpZ = 1, 1, 1
    local rot = 0

	window:addChild(GUI.panel(1, 1, window.width, window.height, colors.window))
    window:addChild(GUI.label(1, 1, 61, 1, colors.button, "Jump")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
    window:addChild(GUI.label(2, 4, 8, 1, 0x555555, "Entered values will be clamped automatically."))
    window:addChild(GUI.label(2, 6, 16, 1, colors.textColor, "X ("..mindx.." - "..tostring(max + mindx)..")"))
    window:addChild(GUI.input(2, 7, 30, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, jumpX, "X")).onInputFinished = function(window, input, eventData, text)

    end    
    window:addChild(GUI.label(2, 9, 12, 1, colors.textColor, "Y ("..mindy.." - "..tostring(max + mindy)..")"))
    window:addChild(GUI.input(2, 10, 30, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, jumpY, "Y")).onInputFinished = function(window, input, eventData, text)

    end    
    window:addChild(GUI.label(2, 12, 14, 1, colors.textColor, "Z ("..mindz.." - "..tostring(max + mindz)..")"))
    window:addChild(GUI.input(2, 13, 30, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, jumpZ, "Z")).onInputFinished = function(window, input, eventData, text)

    end    
    window:addChild(GUI.label(2, 15, 14, 1, colors.textColor, 'CCW rotation (90 deg step)'))
    window:addChild(GUI.input(2, 16, 30, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "0", "R")).onInputFinished = function(window, input, eventData, text)

    end
    window:addChild(GUI.button(2, 18, 29, 3, colors.button, colors.textColor2, colors.buttonPressed, colors.textColor2, "Jump")).onTouch = function()

    end
    window:addChild(GUI.button(33, 18, 29, 3, colors.button, colors.textColor2, colors.buttonPressed, colors.textColor2, "Hyper")).onTouch = function()

    end

    return window
end

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
	gpu.setResolution(80, 25)
end
buffer.setResolution(res[1], res[2])

app:addChild(GUI.panel(1, 1, app.width, app.height, 0xC3C7CB))
windows.iDebug = app:addChild(GUI.textBox(app.width-33, 2, 32, 16, 0xC0C0C0, 0xFFFFFF, {"Debug info:"}, 1, 1, 0))

if config.firstLaunchWindow then
	app:addChild(windows.firstLaunchWindow(5, 5))
else
	app:addChild(windows.mainWindow(5, 5))
end

app:addChild(windows.debug(5, 30))
------------------------------------------------------------------------
app:draw(true)
app:start()
