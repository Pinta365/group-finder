# PintaGroupFinder Localization

This directory contains locale files for different languages.

## Contributing Translations

**Note:** Some translations have been created with the help of AI and may need tweaking. If you notice any typos, grammatical errors, or awkward phrasing, please feel free to open an issue report or submit a pull request!

To add a new language or improve existing translations:

1. Create a new file named after the locale code (e.g., `esES.lua` for Spanish)
2. Copy the structure from an existing locale file (e.g., `frFR.lua`)
3. Translate all the strings
4. Set the global table `PGF_LOCALE_XX` where XX is the locale code

## Locale Codes

- `enUS` / `enGB` - English (default, built-in)
- `frFR` - French (France)
- `deDE` - German (Germany)
- `esES` - Spanish (Spain)
- `esMX` - Spanish (Mexico)
- `ruRU` - Russian (Russia)
- `ptBR` - Portuguese (Brazil)
- `itIT` - Italian (Italy)
- `koKR` - Korean (Korea)
- `zhCN` - Chinese (Simplified, PRC)
- `zhTW` - Chinese (Traditional, Taiwan)

## File Structure

Each locale file should follow this structure:

```lua
--[[
    PintaGroupFinder - [Language] Locale
    Description
]]

-- Only load if this is the current locale (memory optimization)
if GetLocale() == "XX" then
    PGF_LOCALE_XX = {
        ["KEY"] = "Translation",
        -- ... more keys
    }
end
```

**Important:** The `if GetLocale() == "XX" then` check ensures the locale table is only created if it matches the user's locale, saving memory.

## Adding New Strings

When new features are added with English strings, they should:
1. Be added to `src/Locale.lua` in the `defaultLocale` table
2. Be documented here or in the main README
3. Be added to all locale files (or left as English fallback)

## Notes

- English is the default and built-in language
- If a translation key is missing, it will fall back to English
- Only keys that exist in the default locale will be accepted
- Locale files are loaded automatically based on `GetLocale()`
