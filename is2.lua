local buffer = require("doubleBuffering")
local GUI = require("GUI")
local comp = require("component")
local gpu = comp.gpu

local app = GUI.application()
local config = {
	["firstLaunchWindow"] = false,
	["enableAntifreeze"] = true
}
local windows = {}
windows.minimized = {}

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
	return window
end

windows.addMinimizedWindow = function(window)

end

windows.debug = function(x, y)
	local window = iTitledWindow(x, y, 30, 10, "Debug")
	window.name = "Debug"
	window.actionButtons.minimize.onTouch = function()
		windows.addMinimizedWindow(window)
	end

	window.localY = 2
	text = window:addChild(GUI.text(2, 2, 0x000000, "Minimized Windows: "..tostring(#windows.minimized)))
	window:addChild(GUI.adaptiveButton(2, 4, 3, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Reload")).onTouch = function()
		text.text = "Minimized Windows: "..tostring(#windows.minimized)
	end
	window:addChild(GUI.adaptiveButton(16, 7, 3, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Windows")).onTouch = function()
		local data = windows.minimized[1].name or "none"
		GUI.alert(#windows.minimized.."\n"..data)
	end

	return window
end

windows.firstLaunchWindow = function(x, y)
	local window = iTitledWindow(x, y, 60, 20, "Interstellar2 - First Launch")
	window.name = "Setup"
	window.actionButtons.minimize.onTouch = function()
		windows.addMinimizedWindow(window)
	end

	local container = window:addChild(GUI.container(1, 2, window.width, window.height-1))

	local states = {}
	states.main = function()
		container:addChild(GUI.text(2, 2, 0x000000, "Welcome to Interstellar 2."))
		container:addChild(GUI.text(2, 4, 0x000000, "It seems that you're running this program first time,"))
		container:addChild(GUI.text(2, 5, 0x000000, "so you need to configure it."))
		container:addChild(GUI.text(2, 7, 0x000000, "Press Next to proceed, Skip to go to main menu and"))
		container:addChild(GUI.text(2, 8, 0x000000, "leave the configuration on its default values and Exit"))
		container:addChild(GUI.text(2, 9, 0x000000, "to close the program."))

		container:addChild(GUI.button(container.width-6, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Next")).onTouch = function()
			container:removeChildren()
			states.conf_prog()
		end
		container:addChild(GUI.button(container.width-13, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Skip")).onTouch = function()
			container:removeChildren()
			app:addChild(windows.mainWindow(5, 5))
			window:remove()
		end
		container:addChild(GUI.button(container.width-20, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Exit")).onTouch = function()
			app:stop()
		end
	end
	states.conf_prog = function()
		container:addChild(GUI.text(2, 2, 0x000000, "This switch enables or disables AntiFreeze."))
		container:addChild(GUI.text(2, 4, 0x000000, "AntiFreeze is a function that prevents"))
		container:addChild(GUI.text(2, 5, 0x000000, "your computer from freezing after a ship jump."))
		container:addChild(GUI.text(2, 7, 0x000000, "However, if you're using a server rack"))
		container:addChild(GUI.text(2, 8, 0x000000, "it will not freeze after such events, so"))
		container:addChild(GUI.text(2, 9, 0x000000, "you can disable it."))

		container:addChild(GUI.switchAndLabel(2, 11, 30, 8, 0x0000AA, 0x1D1D1D, 0xC0C0C0, 0x000000, "Enable AntiFreeze:", true))
		container:addChild(GUI.button(container.width-6, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Next")).onTouch = function()
			container:removeChildren()
			states.before_conf_ship()
		end
		container:addChild(GUI.button(container.width-13, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Back")).onTouch = function()
			container:removeChildren()
			states.main()
		end
	end
	states.before_conf_ship = function()
		container:addChild(GUI.text(2, 2, 0x000000, "Interstellar 2 is now configured."))
		container:addChild(GUI.text(2, 4, 0x000000, "Your next step is to configure your ship sizes,"))
		container:addChild(GUI.text(2, 5, 0x000000, "but if you've already done that - press"))
		container:addChild(GUI.text(2, 6, 0x000000, "Skip, otherwise - press Configure Ship"))

		container:addChild(GUI.button(container.width-16, container.height-1, 16, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Configure Ship"))
		container:addChild(GUI.button(container.width-23, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Skip")).onTouch = function()
			container:removeChildren()
			app:addChild(windows.mainWindow(5, 5))
			window:remove()
		end
		container:addChild(GUI.button(container.width-30, container.height-1, 6, 1, 0xC0C0C0, 0x000000, 0x8E8E8E, 0x000000, "Back")).onTouch = function()
			container:removeChildren()
			states.conf_prog()
		end
	end

	states.main()

	return window
end

windows.mainWindow = function(x, y)
	local window = iTitledWindow(x, y, 80, 25, "Interstellar2 Main Window")
	window.name = "Main"

	window.actionButtons.close.onTouch = function()
		app:stop()
	end
	window.actionButtons.minimize.onTouch = function()
		windows.addMinimizedWindow(window)
	end
	
	return window
end

------------------------------------------------------------------------
local maxRes = {}
maxRes[1], maxRes[2] = gpu.maxResolution()

if gpu.getDepth() < 4 and (maxRes[1] < 80 and maxRes[2] < 25) then
	io.stderr:write("Ошибка: ваша видеокарта не подходит для данной программы.")
end

local res = {}
res[1], res[2] = gpu.getResolution()

if (res[1] < 100) and (res[2] < 40) then
	gpu.setResolution(80, 25)
end
buffer.setResolution(res[1], res[2])

app:addChild(GUI.panel(1, 1, app.width, app.height, 0xC3C7CB))
windows.iDebug = app:addChild(GUI.textBox(app.width-33, 2, 32, 16, 0xC0C0C0, 0xFFFFFF, {"Debug info:"}, 1, 1, 0))
app:addChild(windows.firstLaunchWindow(5, 5))
app:addChild(windows.debug(5, 30))
------------------------------------------------------------------------
app:draw(true)
app:start()
