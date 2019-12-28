local GUI = require("GUI")
local system = require("System")
local filesystem = require("Filesystem")
local component = require("Component")
local paths = require("Paths")
local internet = require("Internet")
local json = require("JSON")
--------------------------------------------------------------------------------------------------------------------------
--Check radio exists or not
if not component.isAvailable("openfm_radio") then
	GUI.alert("This program needs a OpenFM Radio")
	return
end


local cfgPath = paths.user.applicationData .. "SimpleRadioPlayer/Stations.cfg"--Application folder path
local fm = component.openfm_radio--OpenFM Radio component
local workspace = GUI.workspace()
local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 98, 25, 0x3c3c3c))--Create Window
window.actionButtons.maximize:remove()
local config
fm.setScreenText("Simple Radio Player")

local function saveConfig()
	filesystem.writeTable(cfgPath, config, true)
end

function tableLength(table)
	local count = 0
	for _ in pairs(table) do count = count + 1 end
	return count
end

function normalizeIndexes(table)
	for j = 1, tableLength(table) do
		if table[j]==nil then
			table[j], table[j+1]=table[j+1],table[j]
		end
	end
	return table
end

--Check if the config file exists or not, if not, create it
if filesystem.exists(cfgPath) then
	config = filesystem.readTable(cfgPath)
	config=normalizeIndexes(config)
else
	config = {
		{
			url="https://www.dropbox.com/s/raw/s29m6dc9qo9pjlm/Los%20Del%20Rio%20-%20Macarena.mp3",
			color=0x43d143,
			name="Los Del Rio - Macarena",
		}
	}
	saveConfig()
end
--Check if the config file exists or not, if not, create it


local function setZeroVolume()
	for i = 1, 9 do
		fm.volDown()
	end
end

local function setVolume(volume)
	for i = 1, volume do
		fm.volUp()
	end
end


--Some Window Stuff
window:addChild(GUI.panel(1, 3, window.width, window.height, 0x2d2d2d))
window:addChild(GUI.text(6, 2, 0xc3c3c3, "Simple Radio Player"))
--Some Window Stuff


--Text and Color Inputs
local urlInput =  window:addChild(GUI.input(3, 13, 56, 3, 0x5a5a5a, 0xa5a5a5, 0x999999, 0x5a5a5a, 0x2D2D2D, "URL", "URL", true))
local nameInput =  window:addChild(GUI.input(3, 9, 56, 3, 0x5a5a5a, 0xa5a5a5, 0x999999, 0x5a5a5a, 0x2D2D2D, "Name", "Name", true))
local screenColorSelector = window:addChild(GUI.colorSelector(39, 4, 20, 3, 0x5a5a5a, "Screen color"))
--Text and Color Inputs


--Volume slider
local vSlider = window:addChild(GUI.slider(3, 6, 34, 0x66DB80, 0x0, 0x00a550, 0xAAAAAA, 1, 9, 5, false, "Volume: ", " "))
vSlider.roundValues = true
vSlider.height = 2
vSlider.onValueChanged = function()
	setZeroVolume()
	setVolume(vSlider.value)
end
--Volume slider


--Custom stations List
window:addChild(GUI.text(60, 3, 0xc3c3c3, "Custom Stations"))
local customList = window:addChild(GUI.list(60, 4, 38, 19, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xc3c3c3, false))
for i = 1, tableLength(config) do
	customList:addItem(config[i].name)
end
--Custom stations List


--Update List with custom stations
function updateList()
	local lastSelected = customList.selectedItem
	customList:remove()
	customList = window:addChild(GUI.list(60, 4, 38, 19, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xa5a5a5, false))
	for i = 1, tableLength(config) do
		customList:addItem(config[i].name)
	end
	customList.selectedItem=lastSelected
end
--Update List with custom stations


--List Utils Buttons
window:addChild(GUI.roundedButton(61, 24, 6, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "load")).onTouch = function()
	nameInput.text = config[customList.selectedItem].name
	urlInput.text = config[customList.selectedItem].url
	screenColorSelector.color = config[customList.selectedItem].color
	fm.setScreenText(nameInput.text)
	fm.setScreenColor(screenColorSelector.color)
end
window:addChild(GUI.roundedButton(69, 24, 6, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "save")).onTouch = function()
	config[customList.selectedItem].name = nameInput.text
	config[customList.selectedItem].url = urlInput.text
	config[customList.selectedItem].color = screenColorSelector.color
	config=normalizeIndexes(config)
	saveConfig()
	updateList()
end
window:addChild(GUI.roundedButton(77, 24, 5, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "new")).onTouch = function()
	if tableLength(config) >= 19 then
		GUI.alert("You can't add more than 19 stations!")
		return
	else
		local new = {
		  	url=urlInput.text,
		  	name=nameInput.text, 
		  	color=screenColorSelector.color, 
		}
		table.insert(config, new)
		config=normalizeIndexes(config)
		saveConfig()
		updateList()
	end
end
window:addChild(GUI.roundedButton(84, 24, 5, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "del")).onTouch = function()
	config[customList.selectedItem]=nil
	config=normalizeIndexes(config)
	saveConfig()
	updateList()
end
--List Utils Buttons


window:addChild(GUI.button(33, 21, 26, 3, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "srpCloud Stations")).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "srpCloud Stations")
	local tableContainer = container.layout:addChild(GUI.container(1, 1, 50, 35))
	tableContainer:addChild(GUI.panel(1, 1, 50, 1, 0x2d2d2d))
	tableContainer:addChild(GUI.text(1, 1, 0xc3c3c3, "                 Name  |  Author"))
	local shittyList = tableContainer:addChild(GUI.list(1, 2, 50, 30, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xc3c3c3, false))
	local pageText = tableContainer:addChild(GUI.text(25, 33, 0xc3c3c3, "1"))	

	local data
	function updateShit(page)
		shittyList:remove()
		shittyList = tableContainer:addChild(GUI.list(1, 2, 50, 30, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xc3c3c3, false))
		
		local req = internet.request("http://rainbowbot.xyz:1337/api/opencomputers/srp/get/"..page.."/")
		data = json.decode(req)
		for i = 1, tableLength(data) do
			shittyList:addItem(data[i].name.."  |  "..data[i].author)
		end
		pageText:remove()
		pageText = tableContainer:addChild(GUI.text(25, 33, 0xc3c3c3, page))
	end

	local pageNum = 1
	updateShit(pageNum)
	tableContainer:addChild(GUI.roundedButton(18, 33, 5, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "<")).onTouch = function()
		if pageNum <= 1 then
			pageNum = 1
			GUI.alert("Minimum page is 1!")
		else
			pageNum=pageNum-1
		end
		updateShit(pageNum)
	end
	tableContainer:addChild(GUI.roundedButton(28, 33, 5, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, ">")).onTouch = function()
		pageNum=pageNum+1
		updateShit(pageNum)
	end
	container.layout:addChild(GUI.roundedButton(17, 33, 15, 3, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Save it!")).onTouch = function()
		if tableLength(config) >= 19 then
			GUI.alert("You can't add more than 19 stations!")
			return
		else
			local new = {
			  	url=data[shittyList.selectedItem].url,
			  	name=data[shittyList.selectedItem].name, 
			  	color=0x6495ed, 
			}
			table.insert(config, new)
			config=normalizeIndexes(config)
			saveConfig()
			updateList()
		end
	end
end


window:addChild(GUI.button(3, 21, 26, 3, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Upload to srpCloud")).onTouch = function()
	if nameInput.text == "Name" or urlInput.text == "URL" or nameInput.text == "" or urlInput.text == "" then
		GUI.alert("Name or URL can't be empty!")
	else
		local new_item = {
			name=nameInput.text,
			url=urlInput.text,
			author=system.getUser():gsub("/", ""),
		}
		local data_encoded = json.encode(new_item)
		local req = internet.request("http://rainbowbot.xyz:1337/api/opencomputers/srp/upload/", data_encoded)
	end
end



--Play Button
window:addChild(GUI.button(33, 17, 26, 3, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Play")).onTouch = function()
    fm.setScreenText(nameInput.text)
    fm.setURL(urlInput.text)
    fm.stop()
    fm.start()
    fm.setScreenColor(screenColorSelector)
end
--Play Button


--Stop Button
window:addChild(GUI.button(3, 17, 26, 3, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Stop")).onTouch = function()
    fm.stop()
end
--Stop Button


--poshal04ka
window:addChild(GUI.button(58, 2, 2, 1, 0x3c3c3c, 0xa5a5a5, 0x969696, 0x3c3c3c, " ")).onTouch = function()
	setvolume(9)
	fm.setURL("https://dl.dropboxusercontent.com/s/p9vrj061kzozbd2/Untitled.mp3")
	fm.stop()
	fm.start()
	GUI.alert("Ты сука, че тыкаешь куда не надо?!")
end
--poshal04ka


--Standard Stations Buttons
window:addChild(GUI.text(3, 3, 0xc3c3c3, "Standard Stations"))
window:addChild(GUI.roundedButton(3, 4, 10, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Record")).onTouch = function()
	fm.setURL("http://air.radiorecord.ru:8101/rr_320")
	fm.setScreenText("Record")
	fm.setScreenColor(0x14FF00)
	fm.stop()
	fm.start()
end
window:addChild(GUI.roundedButton(15, 4, 10, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Europa+")).onTouch = function()
    fm.setURL("http://ep128.hostingradio.ru:8030/ep128")
    fm.setScreenText("Europa+")
    fm.setScreenColor(0x1400FF)
    fm.stop()
    fm.start()
end
window:addChild(GUI.roundedButton(27, 4, 10, 1, 0x5a5a5a, 0xa5a5a5, 0x969696, 0x5a5a5a, "Energy")).onTouch = function()
    fm.setURL("http://ic3.101.ru:8000/v1_1?setst=-1")
    fm.setScreenText("Energy")
    fm.setScreenColor(0xFF0000)
    fm.stop()
    fm.start()
end
--Standard Stations Buttons


--[[
              			  ███████
             			 █████████
            			███████████
            			 █████████
                           █████
         ██████████████████████████
             ███████████████████████
                  	██████████████████
               	         █████████████
        ██████████        ████████████
       ██        ██       █████████████
      ██        ██         ████████████
     ██        ██          █████████████ 
██████████████████████     █████████████ 
██████████████████████    █████████████ 
██════█═══██══█═══██      █████████████ 
 ███████████████████     █████████████
 ██═══█═══██══█═══██     █████████████
  █═══█═══██══█═══█      █████████████
   ████████████████      ██████ ██████
   █══█═══██══█═══█     ██████  █████
   ████████████████     ██████   █████
   █══█══██══█══██     █████    █████ 
   █══█══██══█══█      ████      ████
   █══█══██══█══█     ████       ███
   █══█══██══█══█     ███        ███ 
   ██████████████     ███         ██
   ██  █ ██  █ ██   ████         ███
    ████████████  ██████       █████

╔╗╔╦═══╗ ╔╗  ╔╦╗╔╦══╦══╦═══╦╗╔╦════╦╗
║║║║╔══╝ ║║  ║║║║║╔═╣╔╗║╔═╗║║║╠═╗╔═╣║
║╚╝║╚══╗ ║╚╗╔╝║╚╝║║ ║║║║╚═╝║║║║ ║║ ║╚══╗ 
║╔╗║╔══╝ ║╔╗╔╗╠═╗║║ ║║║║╔══╣║║║ ║║ ║╔═╗║ 
║║║║╚══╗ ║║╚╝║║╔╝║╚═╣╚╝║║  ║╚╝║ ║║ ║╚═╝║ 
╚╝╚╩═══╝ ╚╝  ╚╝╚═╩══╩══╩╝  ╚══╝ ╚╝ ╚═══╝
--]]
--------------------------------------------------------------------------------------------------------------------------------------
workspace:draw()



