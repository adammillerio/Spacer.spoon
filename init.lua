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
Spacer.settingsKey = "SpacerSpaceNames"

--- Spacer.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log 
--- level for the messages coming from the Spoon.
Spacer.logger = nil

--- Spacer.logLevel
--- Variable
--- Spacer specific log level override, see hs.logger.setLogLevel for options.
Spacer.logLevel = nil

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
    -- Reload space names, in case user has deleted/moved/created spaces since
    -- last time clicking without actually changing spaces.
    self:_reloadSpaceNames()

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
    self.logger.v("Writing space names to hs.settings")

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

function Spacer:_spaceChanged(spaceID)
    -- Reload space names, in case user has created and switched to a new Desktop.
    self:_reloadSpaceNames()

    self:_setMenuText()
end

local function startswith(someStr, start) return someStr:sub(1, #start) == start end

-- TODO
-- Fix bug: Creating and moving it without entering it will cause it to temporarily
-- overwrite space names after it.
function Spacer:_reloadSpaceNames()
    self.logger.v("Reloading space names")

    changed = false

    -- Get the main screen on the device
    screen = hs.screen.mainScreen()
    -- Get all spaces on this screen
    spaces = hs.spaces.allSpaces()

    -- Get the spaces for this screen.
    screenSpaces = spaces[screen:getUUID()]

    -- Step 1: Retrieve the number of spaces we had before making any changes
    existingNumSpaces = #self.orderedSpaces
    self.logger.vf("Existing number of spaces is %d", existingNumSpaces)

    -- For every numerical index i and spaceID for spaces on this screen, from left
    -- to right.
    for i, spaceID in ipairs(screenSpaces) do
        -- Step 2: Retrieve ID of the space that was in this this position last time
        self.logger.vf("Getting existing space ID for Desktop %d", i)
        existingSpaceID = self.orderedSpaces[i]
        self.logger.vf("Existing space ID for Desktop %d: %s", i,
                       existingSpaceID)
        -- Step 3: If there was no ID in this position, then this is a newly
        --  created space in the rightmost position, so initialize and append it
        --  to the orderedSpaces and continue iteration.
        if existingSpaceID == nil then
            -- New space at end, append

            -- Make function
            spaceName = settingsSpaceNames[i]
            if spaceName == nil then
                -- Default space name to "None"
                spaceName = "None"
            end

            self.logger.vf("Setting name for new \"Desktop %d\" to \"%s\"", i,
                           spaceName)
            -- Map space ID to name
            self.spaceNames[spaceID] = spaceName
            -- Insert the space into the ordered table to record it positionally from
            -- left to right.
            table.insert(self.orderedSpaces, spaceID)

            changed = true
            goto continue
        end

        -- Step 4: Look up the assigned name for this space ID
        self.logger.vf("Getting existing space name for Desktop %d", i)
        existingSpaceName = self.spaceNames[existingSpaceID]
        self.logger.vf("Existing space name for Desktop %d: %s", i,
                       existingSpaceName)

        -- Step 5: Load the space name for the ID at this index during this run
        spaceName = self.spaceNames[spaceID]
        -- Step 6: If the resolved name now does not match the resolved name from
        --  last run, then update the ordered left-to-right set of space IDs at
        --  this index to now be the ID of the current space in this position.
        if spaceName ~= existingSpaceName then
            self.logger.vf(
                "Space Name \"%s\" for Desktop %d differs from existing space name",
                spaceName, i)

            self.orderedSpaces[i] = spaceID
            changed = true
        end

        ::continue::
    end

    -- Step 7: Check if the new number of spaces we have is less than the old
    --  one, if it is, then remove all extra indices in the orderedSpaces table.
    numSpaces = #screenSpaces
    self.logger.vf("New number of spaces is %d", numSpaces)
    if numSpaces < existingNumSpaces then
        for i = numSpaces + 1, existingNumSpaces do
            self.logger.vf("Removing deleted Desktop %d", i)
            table.remove(self.orderedSpaces, i)
        end

        changed = true
    end

    if changed then self:_writeSpaceNames() end
end

-- or default it to Desktop N
function Spacer:_loadSpaceNames()
    self.logger.vf("Loading space names from hs.settings key \"%s\"",
                   self.settingsKey)

    -- Load the persisted space names from the previous session if any.
    settingsSpaceNames = hs.settings.get(self.settingsKey)
    if settingsSpaceNames == nil then
        -- Default to empty table.
        self.logger.v("No saved space names, initializing empty table")
        settingsSpaceNames = {}
    end

    self.logger.v("Loading space names for main screen")
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
            -- Default space name to "None"
            spaceName = "None"
        end

        self.logger
            .vf("Setting name for \"Desktop %d\" to \"%s\"", i, spaceName)
        -- Map space ID to name
        self.spaceNames[spaceID] = spaceName
        -- Insert the space into the ordered table to record it positionally from
        -- left to right.
        table.insert(self.orderedSpaces, spaceID)
    end

    self.logger.vf("Loaded existing space names: %s",
                   hs.inspect(settingsSpaceNames))
    return settingsSpaceNames
end

--- Spacer:init()
--- Method
--- Spoon initializer method for Spacer.
function Spacer:init()
    self.spaceNames = {}
    self.orderedSpaces = {}
end

--- Spacer:start()
--- Method
--- Spoon start method for Spacer. Creates/starts menu bar item and space watcher.
function Spacer:start()
    -- Start logger, this has to be done in start because it relies on config.
    self.logger = hs.logger.new("Spacer")

    if self.logLevel ~= nil then self.logger.setLogLevel(self.logLevel) end

    self.logger.v("Starting Spacer")

    self:_loadSpaceNames()

    self.logger.v("Creating menubar item")
    self.menuBar = hs.menubar.new()
    self.menuBar:setMenu(self:_instanceCallback(self._menuHandler))

    -- Set space watcher to call handler on space change.
    self.logger.v("Creating and starting space watcher")
    self.spaceWatcher = hs.spaces.watcher.new(
                            self:_instanceCallback(self._spaceChanged))

    self.spaceWatcher:start()

    -- Perform an initial text set for the current space.
    self:_setMenuText()
end

--- Spacer:stop()
--- Method
--- Spoon stop method for Spacer. Deletes menu bar item and stops space watcher.
function Spacer:stop()
    self.logger.v("Deleting menubar item")
    self.menuBar:delete()

    self.logger.v("Stopping space watcher")
    self.spaceWatcher:stop()

    self._writeSpaceNames()
end

return Spacer
