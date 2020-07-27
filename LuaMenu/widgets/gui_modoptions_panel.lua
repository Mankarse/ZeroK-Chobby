function widget:GetInfo()
	return {
		name    = 'Modoptions Panel',
		desc    = 'Implements the modoptions panel.',
		author  = 'GoogleFrog',
		date    = '29 July 2016',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Structure
local modoptionDefaults = {}
local modoptionStructure = {}

-- Variables
local battleLobby
local localModoptions = {}
local modoptionControlNames = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility Function

local function UpdateControlValue(key, value)
	if not modoptionControlNames then
		return
	end
	local control = modoptionControlNames[key]
	if control then
		if control.SetText then -- editbox
			control:SetText(value)
			control:FocusUpdate()
		elseif control.Select and control.itemKeyToName then -- combobox
			control:Select(control.itemKeyToName[value])
		elseif control.SetToggle then -- checkbox
			control:SetToggle(value == true or value == 1 or value == "1")
		end
	end
end

local function TextFromNum(num, step)

	-- remove excess accuracy
	local places = 0
	if step < 0.01  then
		places = 3
	elseif step < 0.1 then
		places = 2
	elseif step < 1 then
		places = 1
	end
	local text = string.format("%." .. places .. "f", num)

	-- remove trailing 0s
	while text:find("%.") and (text:find("0", text:len()) or text:find("%.", text:len())) do
		text = text:sub(0, text:len() - 1)
	end

	return text
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Option Control Handling

local function ProcessListOption(data, index)
	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local defaultItem = 1
	local defaultKey = localModoptions[data.key] or data.def

	local items = {}
	local itemNameToKey = {}
	local itemKeyToName = {}
	for i, itemData in pairs(data.items) do
		items[i] = itemData.name
		itemNameToKey[itemData.name] = itemData.key
		itemKeyToName[itemData.key] = itemData.name

		if itemData.key == defaultKey then
			defaultItem = i
		end
	end

	local list = ComboBox:New {
		x = 340,
		y = 1,
		width = 180,
		height = 30,
		items = items,
		font = WG.Chobby.Configuration:GetFont(2),
		itemFontSize = WG.Chobby.Configuration:GetFont(2).size,
		selectByName = true,
		selected = defaultItem,
		OnSelectName = {
			function (obj, selectedName)
				localModoptions[data.key] = itemNameToKey[selectedName]
			end
		},
		itemKeyToName = itemKeyToName -- Not a chili key
	}
	modoptionControlNames[data.key] = list

	return Control:New {
		x = 0,
		y = index*32,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			list
		}
	}
end

local function ProcessBoolOption(data, index)
	local checked = false
	if localModoptions[data.key] == nil then
		if modoptionDefaults[data.key] == "1" then
			checked = true
		end
	elseif localModoptions[data.key] == "1" then
		checked = true
	end

	local checkBox = Checkbox:New {
		x = 5,
		y = index*32,
		width = 355,
		height = 40,
		boxalign = "right",
		boxsize = 20,
		caption = data.name,
		checked = checked,
		font = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,

		OnChange = {
			function (obj, newState)
				localModoptions[data.key] = tostring((newState and 1) or 0)
			end
		},
	}
	modoptionControlNames[data.key] = checkBox

	return checkBox
end

local function ProcessNumberOption(data, index)

	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local numberBox = EditBox:New {
		x = 340,
		y = 1,
		width = 180,
		height = 30,
		text   = oldText,
		useIME = false,
		fontSize = WG.Chobby.Configuration:GetFont(2).size,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end

				local newValue = tonumber(obj.text)

				if not newValue then
					obj:SetText(oldText)
					return
				end

				-- Bound the number
				newValue = math.min(data.max, math.max(data.min, newValue))
				-- Round to step size
				newValue = math.floor(newValue/data.step + 0.5)*data.step + 0.01*data.step

				oldText = TextFromNum(newValue, data.step)
				localModoptions[data.key] = oldText
				obj:SetText(oldText)
			end
		}
	}
	modoptionControlNames[data.key] = numberBox

	return Control:New {
		x = 0,
		y = index*32,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			numberBox
		}
	}
end

local function ProcessStringOption(data, index)

	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local textBox = EditBox:New {
		x = 340,
		y = 1,
		width = 180,
		height = 30,
		text   = oldText,
		useIME = false,
		fontSize = WG.Chobby.Configuration:GetFont(2).size,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end
				localModoptions[data.key] = obj.text
			end
		}
	}
	modoptionControlNames[data.key] = textBox

	return Control:New {
		x = 0,
		y = index*32,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			textBox
		}
	}
end

local function PopulateTab(options)
	-- list = combobox
	-- bool = tickbox
	-- number = sliderbar (with label)
	-- string = editBox

	local contentsPanel = ScrollPanel:New {
		x = 6,
		right = 5,
		y = 10,
		bottom = 8,
		horizontalScrollbar = false,
	}

	for i = 1, #options do
		local data = options[i]
		if data.type == "list" then
			contentsPanel:AddChild(ProcessListOption(data, #contentsPanel.children))
		elseif data.type == "bool" then
			contentsPanel:AddChild(ProcessBoolOption(data, #contentsPanel.children))
		elseif data.type == "number" then
			contentsPanel:AddChild(ProcessNumberOption(data, #contentsPanel.children))
		elseif data.type == "string" then
			contentsPanel:AddChild(ProcessStringOption(data, #contentsPanel.children))
		end
	end
	return {contentsPanel}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Modoptions Window Handler

local function CreateModoptionWindow()
	local modoptionsSelectionWindow = Window:New {
		caption = "",
		name = "modoptionsSelectionWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 920,
		height = 500,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	localModoptions = Spring.Utilities.CopyTable(battleLobby:GetMyBattleModoptions() or {})
	modoptionControlNames = {}

	local tabs = {}

	local tabWidth = 120

	for key, data in pairs(modoptionStructure.sections) do
		local caption = modoptionStructure.sectionTitles[data.title] or data.title
		local fontSize = 2
		local tooltip = nil
		local origCaption = caption
		caption = StringUtilities.GetTruncatedStringWithDotDot(caption, Font:New(WG.Chobby.Configuration:GetFont(fontSize)), tabWidth)
		if origCaption ~= caption then
			tooltip = origCaption
		end
		tabs[#tabs + 1] = {
			name = key,
			caption = caption,
			tooltip = tooltip,
			font = WG.Chobby.Configuration:GetFont(fontSize),
			children = PopulateTab(data.options)
		}
	end

	local tabPanel = Chili.DetachableTabPanel:New {
		x = 4,
		right = 4,
		y = 49,
		bottom = 75,
		padding = {0, 0, 0, 0},
		minTabWidth = tabWidth,
		tabs = tabs,
		parent = modoptionsSelectionWindow,
		OnTabChange = {
		}
	}

	local tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 0,
		y = 0,
		right = 0,
		height = 60,
		resizable = false,
		draggable = false,
		padding = {18, 6, 18, 0},
		parent = modoptionsSelectionWindow,
		children = {
			Line:New {
				classname = "line_solid",
				x = 0,
				y = 52,
				right = 0,
				bottom = 0,
			},
			tabPanel.tabBar
		}
	}
	local function CancelFunc()
		modoptionsSelectionWindow:Dispose()
	end

	local buttonAccept, buttonMods, modSelection

	function GetModSelection()
		local function SetGameFail()
		end

		local function SetGameSucess(name)
			buttonMods.caption = name
			modSelection = name
		end

		local Configuration = WG.Chobby.Configuration
		WG.Chobby.GameListWindow(SetGameFail, SetGameSucess, Configuration and Configuration.gameConfig.modBlacklist, i18n("select_mod"))
	end

	local function AcceptFunc()
		screen0:FocusControl(buttonAccept) -- Defocus the text entry
		battleLobby:SetModOptions(localModoptions)
		if modSelection then
			battleLobby:SelectGame(modSelection)
		end
		modoptionsSelectionWindow:Dispose()
	end

	local function ResetFunc()
		for key, value in pairs(modoptionDefaults) do
			UpdateControlValue(key, value)
		end
		localModoptions = {}
		
		modSelection = false
		buttonMods.caption = i18n("select_mod")
	end

	buttonMods = Button:New {
		x = 10,
		right = 513,
		bottom = 1,
		height = 70,
		caption = i18n("select_mod"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "option_button",
		OnClick = {
			function()
				GetModSelection()
			end
		},
	}

	Button:New {
		right = 294,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("reset"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "option_button",
		OnClick = {
			function()
				ResetFunc()
			end
		},
	}

	buttonAccept = Button:New {
		right = 150,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("apply"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "action_button",
		OnClick = {
			function()
				AcceptFunc()
			end
		},
	}

	local buttonCancel = Button:New {
		right = 6,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
	}

	local popupHolder = WG.Chobby.PriorityPopup(modoptionsSelectionWindow, CancelFunc, AcceptFunc)
end

local function InitializeModoptionsDisplay()
	local currentLobby = battleLobby

	local mainScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		horizontalScrollbar = false,
	}

	local lblText = TextBox:New {
		x = 1,
		right = 1,
		y = 1,
		autoresize = true,
		font = WG.Chobby.Configuration:GetFont(1),
		text = "",
		parent = mainScrollPanel,
	}

	local function OnSetModOptions(listener, modoptions)
		local text = ""
		local empty = true
		modoptions = modoptions or {}
		for key, value in pairs(modoptions) do
			if modoptionDefaults[key] == nil or modoptionDefaults[key] ~= value then
				text = text .. "\255\120\120\120" .. tostring(key) .. " = \255\255\255\255" .. tostring(value) .. "\n"
				empty = false
			end
		end
		lblText:SetText(text)

		if mainScrollPanel.parent then
			if empty and mainScrollPanel.visible then
				mainScrollPanel:Hide()
			end
			if (not empty) and (not mainScrollPanel.visible) then
				mainScrollPanel:Show()
			end
		end
	end
	battleLobby:AddListener("OnSetModOptions", OnSetModOptions)
	battleLobby:AddListener("OnResetModOptions", OnSetModOptions)

	local externalFunctions = {}

	function externalFunctions.Update()
		if currentLobby then
			currentLobby:RemoveListener("OnSetModOptions", OnSetModOptions)
			currentLobby:RemoveListener("OnResetModOptions", OnSetModOptions)
		end
		battleLobby:AddListener("OnSetModOptions", OnSetModOptions)
		battleLobby:RemoveListener("OnResetModOptions", OnSetModOptions)
		currentLobby = battleLobby

		OnSetModOptions()
	end

	function externalFunctions.GetControl()
		return mainScrollPanel
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local modoptionsDisplay

local ModoptionsPanel = {}

function ModoptionsPanel.LoadModotpions(gameName, newBattleLobby)
	battleLobby = newBattleLobby

	modoptions = WG.Chobby.Configuration.gameConfig.defaultModoptions
	modoptionDefaults = {}
	modoptionStructure = {
		sectionTitles = {},
		sections = {}
	}
	if not modoptions then
		return
	end

	-- Set modoptionDefaults
	for i = 1, #modoptions do
		local data = modoptions[i]
		if data.key and (not data.noLobby) and (data.def ~= nil) then
			if type(data.def) == "boolean" then
				modoptionDefaults[data.key] = tostring((data.def and 1) or 0)
			elseif type(data.def) == "number" then
				-- can't use tostring because of float inaccuracy, eg. 0.6 ends up as "0.6000000002"
				modoptionDefaults[data.key] = TextFromNum(data.def, data.step)
			else
				modoptionDefaults[data.key] = tostring(data.def)
			end
		end
	end

	-- Populate the sections
	for i = 1, #modoptions do
		local data = modoptions[i]
		if data.type == "section" then
			modoptionStructure.sectionTitles[data.key] = data.name
		elseif not data.noLobby then
			if data.section then
				modoptionStructure.sections[data.section] = modoptionStructure.sections[data.section] or {
					title = data.section,
					options = {}
				}

				local options = modoptionStructure.sections[data.section].options
				options[#options + 1] = data
			end
		end
	end
end

function ModoptionsPanel.ShowModoptions()
	CreateModoptionWindow()
end

function ModoptionsPanel.GetModoptionsControl()
	if not modoptionsDisplay then
		modoptionsDisplay = InitializeModoptionsDisplay()
	else
		modoptionsDisplay.Update()
	end
	return modoptionsDisplay.GetControl()
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Initialization

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.ModoptionsPanel = ModoptionsPanel
end
