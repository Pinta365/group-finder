# Pinta Group Finder - World of Warcraft Addon

**Pinta Group Finder** adds filtering, quick apply, and visual improvements to the default Group Finder UI.

![Image of the filter panel](https://cdn.pinta.land/pgf/pgf_dungeon.png)

## Download

* [Wago Addons](https://addons.wago.io/addons/group-finder)
* [CurseForge](https://www.curseforge.com/wow/addons/PintaGroupFinder)

## Features

### Filter Panels

A collapsible filter panel appears automatically next to the Group Finder window for Dungeons, Raids, Delves, Arena, and Rated Battlegrounds. Section states persist across sessions.

#### Dungeons
* Activity selection, minimum M+ rating, difficulty, role presence, playstyle, hide incompatible groups
* Custom sorting: Age, Leader Rating, Group Size, Item Level, Leader Name

#### Raids
* Activity selection, boss progress (Any / Fresh / Partial), difficulty, playstyle
* Role requirements with operators (e.g. at least 2 healers)
* Custom sorting: Age, Group Size, Item Level, Leader Name

#### Delves
* Activity selection (current-season and legacy split), tier range (1–11), special tier groups (?/??), playstyle
* Custom sorting: Age, Group Size, Item Level, Leader Name

#### PvP (Arena & Rated Battlegrounds)
* Activity selection, minimum PvP rating, playstyle
* Custom sorting: Age, PvP Rating, Group Size, Leader Name

All panels support **Quick Apply** and **Settings** sections (see below).

### Quick Apply

Enable in any filter panel to sign up with one click using saved role preferences. Hold Shift to show the normal dialog, when you for example want to sign up with a note. Roles sync with Blizzard's system and persist per character. Includes **Auto-Accept** to automatically accept when your party leader applies.

### Visual Improvements (Dungeons & Raids)

Toggleable in each panel's Settings section:

* **Leader Crown** — crown icon above the group leader's role slot
* **Spec Icons** — specialization icons below each filled role slot (dungeons)
* **Leader Rating** — M+ rating next to the group name, color-coded by tier (dungeons)
* **Missing Role Indicators** — desaturated icons for unfilled slots (dungeons)
* **Class/Spec Indicators** — count of your class already in the group, by role (raids)

## Slash Commands

* `/pgf` — Show available commands
* `/pgf filter` — Toggle filter panel
* `/pgf debug` — Toggle debug mode
* `/pgf reset` — Reset all settings to defaults

## Localization

English (default), German (deDE), French (frFR). Falls back to English automatically. Contributions welcome — see [`src/locales/README.md`](src/locales/README.md).

## Troubleshooting & Reporting Issues

1. Try `/pgf reset` to restore defaults
2. Use `/pgf debug` to enable debug output in the chat frame
3. Report issues at [GitHub](https://github.com/Pinta365/group-finder/issues) with a description, steps to reproduce, and any debug output or Lua errors
