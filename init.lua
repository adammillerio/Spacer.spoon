--- === Spacer ===
---
--- Name and switch Mission Control spaces in the menu bar
---
--- Download: https://github.com/adammillerio/Spoons/raw/main/Spoons/Spacer.spoon.zip
---
--- Example Usage (Using [SpoonInstall](https://zzamboni.org/post/using-spoons-in-hammerspoon/)):
--- spoon.SpoonInstall:andUse(
---   "Spacer",
---   {
---     start = true
---   }
--- )
---
--- Space names can be changed from the menubar by holding Alt while selecting
--- the desired space to rename. These are persisted between launches via the
--- hs.settings module.
local Spacer = {}
Spacer.__index = Spacer

-- Metadata
Spacer.name = "Spacer"
Spacer.version = "0.1"
Spacer.author = "Adam Miller <adam@adammiller.io>"
Spacer.homepage = "https://github.com/adammillerio/Spacer.spoon"
Spacer.license = "MIT - https://opensource.org/licenses/MIT"

--- Spacer.settingsKey
--- Constant
--- Key used for persisting space names between Hammerspoon launches via hs.settings.
Spacer.settingsKey = "SpacerSpaceName"

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

--- Spacer.orderedSpaces
--- Variable
--- Table holding an ordered list of space IDs, which is then used to resolve
--- actual space names for IDs from Spacer.spaceNames.
Spacer.orderedSpaces = nil


-- Set the menu text of the Spacer menu bar item.
function Spacer:_setMenuText()
    self.menuBar:setTitle(self.spaceNames[hs.spaces.focusedSpace()])
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
        self:_setMenuText()
        self:_writeSpaceNames()
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
    -- Create table of menu items
    menuItems = {}

    -- Iterate through the ordered space IDs from left to right.
    for i, spaceID in ipairs(self.orderedSpaces) do
        menuItem = {}

        -- Set callback to handler for space being clicked.
        menuItem["fn"] = self:_instanceCallback(self._menuItemClicked, spaceID)

        -- Set menu item to either the user name for the space or the default.
        -- Look up the name for this space ID and set it on the menu item.
        menuItem["title"] = self.spaceNames[spaceID]

        table.insert(menuItems, menuItem)
    end

    return menuItems
end

-- Add some sort of space spotlight search, ie you can just type "Printer" and it
-- will resolve that named space and send you to it.

function Spacer:_writeSpaceNames()
    -- Create a new empty ordered list of space names.
    settingsSpaceNames = {}

    -- Iterate again in order through our spaces as they are now.
    for i, spaceID in ipairs(self.orderedSpaces) do
        -- Get the current space name for this ID.
        spaceName = self.spaceNames[spaceID]
        if spaceName == nil then
            -- If somehow we don't have a name for this space, we need to abort
            -- to avoid overwriting good data with bad.
            self.logger.ef("No name for space ID, aborting write: %s", spaceID)
            return
        end

        -- Insert the space name into the ordered table.
        table.insert(settingsSpaceNames, spaceName)
    end

    -- Persist the new ordered table of space names to settings.
    hs.settings.set(self.settingsKey, settingsSpaceNames)
end

-- TODO
-- Update ordered position of a space after it is moved
-- If a space is deleted, remove it from the ordered list and space name list
-- If a space is created, look whatever name that position has persisted, if any
-- or default it to Desktop N
function Spacer:_loadSpaceNames()
    -- Load the persisted space names from the previous session if any.
    settingsSpaceNames = hs.settings.get(self.settingsKey)
    if settingsSpaceNames == nil then
        -- Default to empty table.
        settingsSpaceNames = {}
    end

    -- Get the main screen on the device
    screen = hs.screen.mainScreen()
    -- Get all spaces on this screen
    spaces = hs.spaces.allSpaces()

    -- Get the spaces for this screen.
    screenSpaces = spaces[screen:getUUID()]

    -- Iterate through spaces by index, this gives them to us from left to right.
    for i, spaceID in ipairs(screenSpaces) do
        spaceName = settingsSpaceNames[i]
        if spaceName == nil then
            -- Default space name to "Desktop N"
            spaceName = string.format("Desktop %d", i)
        end

        -- Map space ID to name
        self.spaceNames[spaceID] = spaceName
        -- Insert the space into the ordered table to record it positionally from
        -- left to right.
        table.insert(self.orderedSpaces, spaceID)
    end
end

--- Spacer:init()
--- Method
--- Spoon initializer method for Spacer.
function Spacer:init()
    self.logger = hs.logger.new("Spacer")

    self.spaceNames = {}
    self.orderedSpaces = {}
end

--- Spacer:start()
--- Method
--- Spoon start method for Spacer. Creates/starts menu bar item and space watcher.
function Spacer:start()
    self:_loadSpaceNames()

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

    self._writeSpaceNames()
end

return Spacer
