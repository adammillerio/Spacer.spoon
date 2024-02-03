--- === Spacer ===
---
--- Name and switch Mission Control spaces in the menu bar
---
--- Download: [https://github.com/adammillerio/Spacer.spoon/archive/refs/heads/main.zip](https://github.com/adammillerio/Spacer.spoon/archive/refs/heads/main.zip)
local obj = {}
obj.__index = obj

-- Spacer.logger
-- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = nil

obj.menuBar = nil

obj.spaceWatcher = nil

obj.spaceNames = nil

local function getSpaceName(spaceID)
    spaceName = obj.spaceNames[spaceID]
    if spaceName == nil then return tostring(spaceID) end

    return spaceName
end

local function setMenuText()
    focusedSpace = hs.spaces.focusedSpace()
    spaceName = getSpaceName(focusedSpace)

    obj.menuBar:setTitle(spaceName)
end

local function spaceChanged(spaceNum) setMenuText() end

local function menuItemClicked(spaceID, modifiers, menuItem)
    if modifiers['alt'] then
        _, inputSpaceName = hs.dialog.textPrompt('Input Space Name',
                                                 'Enter New Space Name')
        obj.spaceNames[spaceID] = inputSpaceName
    else
        hs.spaces.gotoSpace(spaceID)
    end
end

local function menuHandler()
    menuItems = {}

    screen = hs.screen.mainScreen()
    spaces = hs.spaces.allSpaces()
    screenSpaces = spaces[screen:getUUID()]

    for i, spaceID in ipairs(screenSpaces) do
        menuItem = {}

        menuItem['fn'] = function(modifiers, menuItem)
            menuItemClicked(spaceID, modifiers, menuItem)
        end
        menuItem['title'] = getSpaceName(spaceID)

        table.insert(menuItems, menuItem)
    end

    return menuItems
end

function obj:init()
    obj.logger = hs.logger.new('Spacer')

    obj.menuBar = hs.menubar.new()
    obj.menuBar:setMenu(menuHandler)

    obj.spaceWatcher = hs.spaces.watcher.new(spaceChanged)

    obj.spaceNames = {}

    setMenuText()
end

function obj:start() obj.spaceWatcher:start() end

function obj:stop() obj.spaceWatcher:stop() end

return obj
