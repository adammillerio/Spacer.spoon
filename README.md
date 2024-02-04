# Spacer.spoon
Spacer is an expansion pack for macOS's native "Mission Control" Space manager that adds new functionality.

At the core, Spacer is a Menu Bar item which displays the current Space's "Name" and provides a menu for switching between Spaces quickly:

![Screenshot](docs/images/menu.png)

# Features

* Spaces are enumerated by their position in Mission Control from left-to-right
* All new or unnamed Spaces default to the name "None"
* Spaces can be renamed by holding Alt when clicking on a Space in the menu
* When a space is moved in Mission Control, its position will be updated in the menu
* Space names are persisted left-to-right in Hammerspoon settings between loads

# Known Issues

* Creating a Space in Mission Control and moving it to a position other than the end before entering it will cause it to overwrite the name of the Space at that position
  * This can be avoided by just being sure to enter into a Space after creation before moving it

# Installation

## Automated

Spacer can be automatically installed from my [Spoon Repository](https://github.com/adammillerio/Spoons) via [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html). See the repository README or the SpoonInstall docs for more information.

Example `init.lua` configuration which configures `SpoonInstall` and uses it to install and start Spacer:

```load
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.adammillerio = {
    url = "https://github.com/adammillerio/Spoons",
    desc = "adammillerio Personal Spoon repository",
    branch = "main"
}

spoon.SpoonInstall:andUse("Spacer", {repo = "adammillerio", start = true})
```

## Manual

Download the latest release from [here.](https://github.com/adammillerio/Spoons/raw/main/Spoons/Spacer.spoon.zip)

Unzip and either double click to load the Spoon or place the contents manually in `~/.hammerspoon/Spoons`

Then load the Spoon in `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Spacer")
```
