--[[
    PintaGroupFinder - German (Germany) Locale
    
    German translations for PintaGroupFinder.
    Contribute translations at: https://github.com/Pinta365/group-finder
]]

-- Only load if this is the current locale (memory optimization)
if GetLocale() == "deDE" then
    PGF_LOCALE_deDE = {
    -- Quick Apply
    ["QUICK_APPLY"] = "Sofort anmelden:",
    ["ENABLE"] = "Aktivieren",
    ["ENABLE_QUICK_APPLY"] = "Sofortanmeldung aktivieren",
    ["ENABLE_QUICK_APPLY_DESC"] = "Klicke auf eine Gruppe, um dich sofort mit ausgewählten Rollen anzumelden.",
    ["ENABLE_QUICK_APPLY_SHIFT"] = "Halte Umschalt beim Klicken gedrückt, um den Dialog anzuzeigen.",
    ["ROLES"] = "Rollen:",
    ["NOTE"] = "Notiz:",
    ["APPLICATION_NOTE"] = "Anmeldungsnotiz",
    ["APPLICATION_NOTE_DESC"] = "Diese Notiz wird mit deiner Anmeldung gesendet.",
    ["APPLICATION_NOTE_PERSIST"] = "Notiz bleibt zwischen Sitzungen erhalten.",
    ["AUTO_ACCEPT_PARTY"] = "Gruppe automatisch akzeptieren",
    ["AUTO_ACCEPT_PARTY_TITLE"] = "Automatische Gruppenannahme",
    ["AUTO_ACCEPT_PARTY_DESC"] = "Automatisch akzeptieren, wenn sich dein Gruppenleiter anmeldet.",
    
    -- Rating
    ["MIN_RATING"] = "Mindestwertung:",
    ["MIN_RATING_TITLE"] = "Mindestwertung des Leiters",
    ["MIN_RATING_DESC"] = "Zeige nur Gruppen, bei denen der Leiter mindestens diese M+-Wertung hat.\nAuf 0 setzen oder leer lassen, um zu deaktivieren.",
    
    -- Difficulty
    ["DIFFICULTY"] = "Schwierigkeit:",
    ["DIFFICULTY_NORMAL_DESC"] = "Zeige Dungeons mit normaler Schwierigkeitsgrad.",
    ["DIFFICULTY_HEROIC_DESC"] = "Zeige Dungeons mit heroischer Schwierigkeitsgrad.",
    ["DIFFICULTY_MYTHIC_DESC"] = "Zeige mythische Dungeons (ohne Schlüsselstein).",
    ["DIFFICULTY_MYTHICPLUS_DESC"] = "Zeige mythische+ Dungeons (mit Schlüsselstein).",
    
    -- Playstyle
    ["PLAYSTYLE"] = "Spielstil:",
    ["PLAYSTYLE_LEARNING_DESC"] = "Zeige Gruppen mit Lernspielstil.",
    ["PLAYSTYLE_RELAXED_DESC"] = "Zeige Gruppen mit entspanntem Spielstil.",
    ["PLAYSTYLE_COMPETITIVE_DESC"] = "Zeige Gruppen mit kompetitivem Spielstil.",
    ["PLAYSTYLE_CARRY_DESC"] = "Zeige Gruppen, die Boosts anbieten.",
    
    -- Roles
    ["HAS_ROLE"] = "Hat Rolle:",
    ["HAS_TANK"] = "Hat Tank",
    ["HAS_HEALER"] = "Hat Heiler",
    ["HAS_TANK_DESC"] = "Zeige nur Gruppen, die bereits einen Tank haben.",
    ["HAS_HEALER_DESC"] = "Zeige nur Gruppen, die bereits einen Heiler haben.",
    ["HIDE_INCOMPATIBLE_GROUPS"] = "Unpassende Gruppen ausblenden",
    ["HIDE_INCOMPATIBLE_GROUPS_DESC"] = "Zeige nur Gruppen, die Platz für die Rollen eurer Gruppe haben (Tank/Heiler/DPS). Solo blendet Gruppen aus, die keine deiner gewählten Rollen brauchen.",
    
    -- Role Requirements
    ["ROLE_REQUIREMENTS"] = "Rollenanforderungen",
    ["ROLE_REQ_DESC"] = "Filtere Gruppen nach exakten Rollenanzahlen (z.B. mindestens 2 Heiler).",
    ["OP_GTE"] = ">=",
    ["OP_LTE"] = "<=",
    ["OP_EQ"] = "=",
    
    -- Raids
    ["BOSS_FILTER"] = "Boss-Filter:",
    ["BOSS_FILTER_ANY"] = "Beliebig",
    ["BOSS_FILTER_FRESH"] = "Neue Instanz",
    ["BOSS_FILTER_PARTIAL"] = "Teilweiser Fortschritt",
    
    -- Accordion sections
    ["SECTION_ACTIVITIES"] = "AKTIVITÄTEN",
    ["SECTION_BOSS_FILTER"] = "BOSS-FILTER",
    ["SECTION_DIFFICULTY"] = "SCHWIERIGKEIT",
    ["SECTION_PLAYSTYLE"] = "SPIELSTIL",
    ["SECTION_MISC"] = "SONSTIGES",
    ["SECTION_ROLE_FILTERING"] = "ROLLENFILTERUNG",
    ["SECTION_QUICK_APPLY"] = "SOFORT ANMELDEN",
    ["SECTION_SETTINGS"] = "EINSTELLUNGEN",
    
    -- Activity buttons
    ["SELECT_ALL"] = "Alle auswählen",
    ["DESELECT_ALL"] = "Alle abwählen",
    
    -- Sorting
    ["SORT_PRIMARY"] = "Primäre Sortierung:",
    ["SORT_SECONDARY"] = "Sekundäre Sortierung:",
    ["SORT_DIRECTION"] = "Richtung:",
    ["SORT_AGE"] = "Alter",
    ["SORT_RATING"] = "Leiterwertung",
    ["SORT_GROUP_SIZE"] = "Gruppengröße",
    ["SORT_ILVL"] = "Gegenstandsstufe",
    ["SORT_NAME"] = "Leitername",
    ["SORT_ASC"] = "Aufsteigend",
    ["SORT_DESC"] = "Absteigend",
    ["SORT_NONE"] = "Keine",
    ["DISABLE_CUSTOM_SORTING"] = "Benutzerdefinierte Sortierung deaktivieren",
    ["DISABLE_CUSTOM_SORTING_DESC"] = "Blizzards Standard-Sortierung verwenden",
    ["SHOW_LEADER_ICON"] = "Anführer-Symbol anzeigen",
    ["SHOW_LEADER_ICON_DESC"] = "Zeigt ein Kronen-Symbol über dem Gruppenanführer in Dungeon-Suchergebnissen.",
    ["SHOW_DUNGEON_SPEC_ICONS"] = "Klassenspezialisierungs-Symbole anzeigen",
    ["SHOW_DUNGEON_SPEC_ICONS_DESC"] = "Zeigt Spezialisierungs-Symbole unter gefüllten Rollen-Slots in Dungeon-Suchergebnissen.",
    ["SHOW_LEADER_RATING"] = "Leiterwertung anzeigen",
    ["SHOW_LEADER_RATING_DESC"] = "Zeigt die Mythisch+-Wertung des Gruppenleiters neben dem Gruppennamen.",
    ["SHOW_MISSING_ROLES"] = "Fehlende Rollen anzeigen",
    ["SHOW_MISSING_ROLES_DESC"] = "Zeigt entsättigte Rollensymbole für unbesetzte Plätze in Dungeon-Suchergebnissen.",
    }
end
