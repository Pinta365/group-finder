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
    }
end
