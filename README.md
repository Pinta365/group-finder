# Pinta Group Finder - World of Warcraft Addon

**Pinta Group Finder** adds filtering and quick apply functionality to the default Group Finder UI.

![Image of the filter panel](https://cdn.pinta.land/pgf/pgf_dungeon.png)

## Description

Pinta Group Finder enhances the default Group Finder UI with advanced filtering, quick apply functionality, and visual improvements. The addon provides:

* **Filtering Panels** - Filtering for both Dungeons and Raids with accordion-style collapsible sections
* **Quick Apply** - Sign up to groups with pre-selected roles, bypassing the role selection dialog
* **Visual Improvements** - See leader M+ ratings with Raider.IO color coding, class-colored role indicators, and missing role indicators
* **Auto-Accept** - Automatically accept party sign-ups when your party leader applies to a group
* **Raid Filtering** - Advanced raid-specific filters including boss progress filtering and granular role requirements

## Download

You can download Pinta Group Finder from these sources:

* [Wago Addons](https://addons.wago.io/addons/PintaGroupFinder)
* [CurseForge](https://www.curseforge.com/wow/addons/PintaGroupFinder)

## Slash Commands

Pinta Group Finder offers the following slash commands:

* `/pgf` or `/pintagroupfinder`: Displays a help message with available commands.
* `/pgf filter` or `/pgf panel`: Toggles the filter panel visibility.
* `/pgf debug`: Toggles debug mode for troubleshooting.
* `/pgf reset`: Resets all addon settings to their defaults and reloads the UI.

## Features

### Filter Panels

The filter panels appear automatically next to the Group Finder window when viewing the Dungeons or Raids category. Both panels feature a modern accordion-style interface with collapsible sections for better organization.

#### Dungeon Filter Panel

The dungeon filter panel allows you to:

* **Select Specific Dungeons** - Choose which dungeons to show in your search results
* **Set Minimum Rating** - Filter groups by leader's Mythic+ rating
* **Filter by Difficulty** - Show/hide Normal, Heroic, Mythic, or Mythic+ groups (all enabled by default)
* **Role Requirements** - Only show groups that already have a tank or healer
* **Playstyle Filtering** - Filter by playstyle: Learning, Relaxed, Competitive, or Carry Offered (all enabled by default)

#### Raid Filter Panel

The raid filter panel provides advanced raid-specific filtering:

* **Select Specific Raids** - Choose which raid activities to show in your search results
* **Boss Progress Filtering** - Filter by boss progress: Any, Fresh (no bosses defeated), or Partial (some bosses defeated)
* **Difficulty Filtering** - Show/hide Normal, Heroic, or Mythic difficulty raids
* **Advanced Role Requirements** - Filter by exact role counts with operators (>=, <=, =). For example, show only groups with at least 2 healers
* **Playstyle Filtering** - Filter by playstyle: Learning, Relaxed, Competitive, or Carry Offered

The panels automatically hide when switching to other tabs (PvP, etc.) or when returning to the category selection view. Accordion section states (expanded/collapsed) are saved and persist across sessions.

### Quick Apply

Enable Quick Apply in the filter panel to:

* **One-Click Sign-Up** - Click a group to automatically apply with your saved role preferences (Hold Shift when clicking to show the normal dialog instead)
* **Persistent Roles** - Your role selections are saved and synced with Blizzard's system
* **Custom Notes** - Automatically include a note with your application
* **Auto-Accept Party** - Automatically accept when your party leader signs up to a group

### Visual Improvements

The addon enhances group list entries with:

* **Leader Rating Display** - See the leader's M+ rating next to the group name, color-coded by Raider.IO tiers
* **Class Color Bars** - Small colored bars below role icons showing each member's class
* **Missing Role Indicators** - Visual indicators for roles the group still needs

### Smart Filtering

The addon integrates with Blizzard's native filtering system, ensuring compatibility and performance:

* **Native Integration** - Uses Blizzard's advanced filter API for dungeons (difficulty, roles, playstyle, and minimum rating)
* **Client-Side Raid Filtering** - Raids use custom client-side filtering to enhance Blizzard's filter
* **Automatic Sorting** - Results are sorted by application status, rating, and age
* **Fallback Support** - Custom filtering logic as fallback when Blizzard's filter is unavailable

## Troubleshooting

If you encounter any issues, try these steps:

* **Type `/pgf reset`:** This will reset the addon settings to defaults, which might resolve some problems.
* **Check for error messages:** Pay attention to any error messages in the chat frame, as they might provide clues about the issue.
* **Enable debug mode:** Type `/pgf debug` in the chat frame. This will enable debug messages, which might reveal the cause of the issue.
* **Toggle the filter panel:** Type `/pgf filter` to hide/show the filter panel if it's not appearing correctly.

## Debugging and Reporting Issues

To help diagnose problems, Pinta Group Finder has a debug mode that provides more detailed information. Here's how to enable it and report issues:

1. **Enable debug mode:** Type `/pgf debug` in the chat frame. This will enable debug messages, which might reveal the cause of the issue.

2. **Reproduce the error:** Try to reproduce the error you're experiencing while debug mode is enabled.

3. **Gather debug output:** Look for debug messages in your chat window along with any LUA errors you get. These messages might contain clues about the problem.

4. **Report the issue:** If you're still unable to resolve the issue, please open an issue on the [GitHub repository](https://github.com/Pinta365/group-finder/issues) and include the following information:
    * A description of the issue.
    * Steps to reproduce the error.
    * Any relevant debug output.

By providing this information, you'll help identify and fix bugs more efficiently.
