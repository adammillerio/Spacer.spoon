--- === Spacer ===
---
--- Name and switch Mission Control spaces in the menu bar
---
--- Download: [https://github.com/adammillerio/Spacer.spoon/archive/refs/heads/main.zip](https://github.com/adammillerio/Spacer.spoon/archive/refs/heads/main.zip)
---
--- Example Usage (Using [SpoonInstall](https://zzamboni.org/post/using-spoons-in-hammerspoon/)):
--- spoon.SpoonInstall:andUse(
---   "Spacer",
---   {
---     start = true
---   }
--- )
local Spacer = {}
Spacer.__index = Spacer

-- Metadata
Spacer.name = "Spacer"
Spacer.version = "0.1"
Spacer.author = "Adam Miller <adam@adammiller.io>"
Spacer.homepage = "https://github.com/adammillerio/Spacer.spoon"
Spacer.license = "MIT - https://opensource.org/licenses/MIT"

--- Spacer.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log 
--- level for the messages coming from the Spoon.
Spacer.logger = nil

--- Spacer.menuBar
--- Variable
--- hs.menubar representing the menu bar for Spacer.
Spacer.menuBar = nil

--- Spacer.spaceWatcher
--- Variable
--- hs.spaces.watcher instance used for monitoring for space changes.
Spacer.spaceWatcher = nil

--- Spacer.spaceNames
--- Variable
--- Table with key-value mapping of Space ID to it's user set name.
Spacer.spaceNames = nil

-- Retrieve the user configured name for a Space or it's ID.
function Spacer:_getSpaceName(spaceID)
    spaceName = self.spaceNames[spaceID]
    if spaceName == nil then return tostring(spaceID) end

    return spaceName
end

-- Set the menu text of the Spacer menu bar item.
function Spacer:_setMenuText()
    focusedSpace = hs.spaces.focusedSpace()
    spaceName = self:_getSpaceName(focusedSpace)

    self.menuBar:setTitle(spaceName)
end

-- Handler for user clicking one of the Spacer menu bar menu items.
-- Inputs are the space ID, a table of modifiers and their state upon selection,
-- and the menuItem table.
function Spacer:_menuItemClicked(spaceID, modifiers, menuItem)
    if modifiers['alt'] then
        -- Alt held, enter user space rename mode.
        _, inputSpaceName = hs.dialog.textPrompt("Input Space Name",
                                                 "Enter New Space Name")
        self.spaceNames[spaceID] = inputSpaceName
    else
        -- Go to the selected space.
        hs.spaces.gotoSpace(spaceID)
    end
end

-- Utility method for having instance specific callbacks.
-- Inputs are the callback fn and any arguments to be applied after the instance
-- reference.
function Spacer:_instanceCallback(callback, ...)
    return hs.fnutils.partial(callback, self, ...)
end

-- Handler for creating the Spacer menu bar menu.
function Spacer:_menuHandler()
    menuItems = {}

    screen = hs.screen.mainScreen()
    spaces = hs.spaces.allSpaces()

    -- Get the spaces for this screen.
    screenSpaces = spaces[screen:getUUID()]

    for i, spaceID in ipairs(screenSpaces) do
        menuItem = {}

        -- Set callback for space being clicked.
        menuItem["fn"] = self:_instanceCallback(self._menuItemClicked, spaceID)

        -- Set menu item to either the user name for the space or the ID.
        menuItem["title"] = self:_getSpaceName(spaceID)

        table.insert(menuItems, menuItem)
    end

    return menuItems
end

--- Spacer:init()
--- Method
--- Spoon initializer method for Spacer.
function Spacer:init()
    self.logger = hs.logger.new("Spacer")

    self.spaceNames = {}
end

--- Spacer:start()
--- Method
--- Spoon start method for Spacer. Creates/starts menu bar item and space watcher.
function Spacer:start()
    self.menuBar = hs.menubar.new()
    self.menuBar:setMenu(self:_instanceCallback(self._menuHandler))

    -- Set space watcher to update menu bar text on space change.
    self.spaceWatcher = hs.spaces.watcher.new(
                            self:_instanceCallback(self._setMenuText))

    self.spaceWatcher:start()

    -- Perform an initial text set for the current space.
    self:_setMenuText()
end

--- Spacer:stop()
--- Method
--- Spoon stop method for Spacer. Deletes menu bar item and stops space watcher.
function Spacer:stop()
    self.menuBar:delete()

    self.spaceWatcher:stop()
end

return Spacer
