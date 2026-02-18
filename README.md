# Pinta Group Finder - World of Warcraft Addon

**Pinta Group Finder** adds filtering, quick apply, and visual improvements to the default Group Finder UI.

![Image of the filter panel](https://cdn.pinta.land/pgf/pgf_dungeon.png)

## Description

Pinta Group Finder enhances the default Group Finder UI with advanced filtering, quick apply functionality, and visual improvements. The addon provides:

* **Filtering Panels** - Filtering for Dungeons, Raids, and Delves with accordion-style collapsible sections
* **Quick Apply** - Sign up to groups with pre-selected roles, bypassing the role selection dialog
* **Visual Improvements** - Leader crown icon, specialization icons below role slots, leader M+ rating with color coding, missing role indicators, and raid class/spec indicators
* **Auto-Accept** - Automatically accept party sign-ups when your party leader applies to a group
* **Raid Filtering** - Advanced raid-specific filters including boss progress filtering and granular role requirements

## Download

You can download Pinta Group Finder from these sources:

* [Wago Addons](https://addons.wago.io/addons/group-finder)
* [CurseForge](https://www.curseforge.com/wow/addons/PintaGroupFinder)

## Slash Commands

Pinta Group Finder offers the following slash commands:

* `/pgf` or `/pintagroupfinder`: Displays a help message with available commands.
* `/pgf filter` or `/pgf panel`: Toggles the filter panel visibility.
* `/pgf debug`: Toggles debug mode for troubleshooting.
* `/pgf reset`: Resets all addon settings to their defaults and reloads the UI.

## Features

### Filter Panels

The filter panels appear automatically next to the Group Finder window when viewing the Dungeons, Raids, or Delves category. All panels feature a modern accordion-style interface with collapsible sections for better organization.

#### Dungeon Filter Panel

The dungeon filter panel allows you to:

* **Select Specific Dungeons** - Choose which dungeons to show in your search results
* **Set Minimum Rating** - Filter groups by leader's Mythic+ rating
* **Filter by Difficulty** - Show/hide Normal, Heroic, Mythic, or Mythic+ groups (all enabled by default)
* **Role Filtering** - Filter by existing roles (has tank, has healer) and hide groups incompatible with your role
* **Playstyle Filtering** - Filter by playstyle: Learning, Relaxed, Competitive, or Carry Offered (all enabled by default)
* **Custom Sorting** - Configure how search results are sorted:
  * **Primary Sort** - Sort by Age, Leader Rating, Group Size, Item Level Req., or Leader Name
  * **Secondary Sort** - Optional secondary sort criteria
  * **Sort Direction** - Choose Ascending or Descending for each sort level
  * **Disable Custom Sorting** - Use Blizzard's default sorting (enabled by default)

#### Raid Filter Panel

The raid filter panel provides advanced raid-specific filtering:

* **Select Specific Raids** - Choose which raid activities to show in your search results
* **Boss Progress Filtering** - Filter by boss progress: Any, Fresh (no bosses defeated), or Partial (some bosses defeated)
* **Difficulty Filtering** - Show/hide Normal, Heroic, or Mythic difficulty raids
* **Advanced Role Requirements** - Filter by exact role counts with operators (>=, <=, =). For example, show only groups with at least 2 healers
* **Playstyle Filtering** - Filter by playstyle: Learning, Relaxed, Competitive, or Carry Offered
* **Custom Sorting** - Configure how search results are sorted:
  * **Primary Sort** - Sort by Age, Group Size, Item Level Req., or Leader Name
  * **Secondary Sort** - Optional secondary sort criteria
  * **Sort Direction** - Choose Ascending or Descending for each sort level
  * **Disable Custom Sorting** - Use Blizzard's default sorting (enabled by default)

#### Delve Filter Panel

The delve filter panel provides filtering for group Delve content:

* **Select Specific Delves** - Choose which Delve activities to show in your search results, split between current-season and legacy Delves
* **Tier Range** - Show only groups running a specific tier range (1–11). Supports all client languages — the tier is detected from the number in the activity name regardless of locale
* **Special Tier Groups** - Separate toggle for groups whose tier shows as ? or ?? (e.g. seasonal event bosses like Ky'veza). Shown by default, uncheck to hide them
* **Playstyle Filtering** - Filter by playstyle: Learning, Relaxed, Competitive, or Carry Offered
* **Custom Sorting** - Configure how search results are sorted:
  * **Primary Sort** - Sort by Age, Group Size, Item Level Req., or Leader Name
  * **Secondary Sort** - Optional secondary sort criteria
  * **Sort Direction** - Choose Ascending or Descending for each sort level
  * **Disable Custom Sorting** - Use Blizzard's default sorting (enabled by default)

The panels automatically hide when switching to other tabs (PvP, etc.) or when returning to the category selection view. Accordion section states (expanded/collapsed) are saved and persist across sessions.

### Quick Apply

Enable Quick Apply in the filter panel to:

* **One-Click Sign-Up** - Click a group to automatically apply with your saved role preferences (Hold Shift when clicking to show the normal dialog instead)
* **Persistent Roles** - Your role selections are saved and synced with Blizzard's system
* **Custom Notes** - Automatically include a note with your application
* **Auto-Accept Party** - Automatically accept when your party leader signs up to a group

### Visual Improvements

The addon enhances group list entries with visual overlays. All features can be individually toggled in the Settings section of each filter panel.

#### Dungeon Enhancements

* **Leader Crown Icon** - A crown icon appears above the group leader's role slot, making it easy to spot who is leading
* **Specialization Icons** - Spec icons displayed below each filled role slot, showing the exact spec of each group member
* **Leader Rating Display** - The leader's M+ rating is shown next to the group name, color-coded by rating tiers
* **Missing Role Indicators** - Desaturated role icons for unfilled slots, showing what roles the group still needs

#### Raid Enhancements

* **Class/Spec Indicators** - Shows how many players of your class are already in the raid group, broken down by role (Tank, Healer, DPS) with spec icons

### Smart Filtering

The addon integrates with Blizzard's native filtering system, ensuring compatibility and performance:

* **Native Integration** - Uses Blizzard's advanced filter API for dungeons (difficulty, roles, playstyle, and minimum rating)
* **Client-Side Raid Filtering** - Raids use custom client-side filtering to enhance Blizzard's filter
* **Client-Side Delve Filtering** - Delves use fully custom client-side filtering for activity selection, tier range, and playstyle
* **Custom Sorting** - Configure custom sorting for search results with primary and secondary sort options, or use Blizzard's default sorting (default)
* **Automatic Sorting** - When custom sorting is enabled, results are sorted by application status, then by your configured primary and secondary sort criteria
* **Fallback Support** - Custom filtering logic as fallback when Blizzard's filter is unavailable

## Localization

Pinta Group Finder supports multiple languages:

* **English** - Default language (built-in)
* **German** (deDE)
* **French** (frFR)

Missing translations fall back to English automatically. Contributions for additional languages or translation improvements are welcome — see [`src/locales/README.md`](src/locales/README.md) for details.

## Troubleshooting

If you encounter any issues, try these steps:

* **Type `/pgf reset`:** This will reset the addon settings to defaults, which might resolve some problems.
* **Check for error messages:** Pay attention to any error messages in the chat frame, as they might provide clues about the issue.
* **Enable debug mode:** Type `/pgf debug` in the chat frame. This will enable debug messages, which might reveal the cause of the issue.
* **Toggle the filter panel:** Type `/pgf filter` to hide/show the filter panel if it's not appearing correctly.

## Reporting Issues

To help diagnose problems, Pinta Group Finder has a debug mode that provides more detailed information:

1. **Enable debug mode:** Type `/pgf debug` in the chat frame.
2. **Reproduce the error:** Try to reproduce the error while debug mode is enabled.
3. **Gather debug output:** Look for debug messages in your chat window along with any Lua errors.
4. **Report the issue:** Open an issue on the [GitHub repository](https://github.com/Pinta365/group-finder/issues) with:
    * A description of the issue
    * Steps to reproduce the error
    * Any relevant debug output
