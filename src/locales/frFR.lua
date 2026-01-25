--[[
    PintaGroupFinder - French (France) Locale
    
    French translations for PintaGroupFinder.
    Contribute translations at: https://github.com/Pinta365/group-finder
]]

-- Only load if this is the current locale (memory optimization)
if GetLocale() == "frFR" then
    PGF_LOCALE_frFR = {
    -- Quick Apply
    ["QUICK_APPLY"] = "Application rapide :",
    ["ENABLE"] = "Activer",
    ["ENABLE_QUICK_APPLY"] = "Activer l'application rapide",
    ["ENABLE_QUICK_APPLY_DESC"] = "Cliquez sur un groupe pour vous inscrire instantanément avec les rôles sélectionnés.",
    ["ENABLE_QUICK_APPLY_SHIFT"] = "Maintenez Maj lors du clic pour afficher la boîte de dialogue.",
    ["ROLES"] = "Rôles :",
    ["NOTE"] = "Note :",
    ["APPLICATION_NOTE"] = "Note de candidature",
    ["APPLICATION_NOTE_DESC"] = "Cette note sera envoyée avec votre candidature.",
    ["APPLICATION_NOTE_PERSIST"] = "La note persiste entre les inscriptions.",
    ["AUTO_ACCEPT_PARTY"] = "Accepter automatiquement le groupe",
    ["AUTO_ACCEPT_PARTY_TITLE"] = "Acceptation automatique du groupe",
    ["AUTO_ACCEPT_PARTY_DESC"] = "Accepter automatiquement lorsque votre chef de groupe s'inscrit.",
    
    -- Rating
    ["MIN_RATING"] = "Note min. :",
    ["MIN_RATING_TITLE"] = "Note minimale du chef",
    ["MIN_RATING_DESC"] = "Afficher uniquement les groupes où le chef a au moins cette note M+.\nMettez 0 ou laissez vide pour désactiver.",
    
    -- Difficulty
    ["DIFFICULTY"] = "Difficulté :",
    ["DIFFICULTY_NORMAL_DESC"] = "Afficher les donjons en difficulté Normale.",
    ["DIFFICULTY_HEROIC_DESC"] = "Afficher les donjons en difficulté Héroïque.",
    ["DIFFICULTY_MYTHIC_DESC"] = "Afficher les donjons Mythiques (sans clé).",
    ["DIFFICULTY_MYTHICPLUS_DESC"] = "Afficher les donjons Mythiques+ (avec clé).",
    
    -- Playstyle
    ["PLAYSTYLE"] = "Style de jeu :",
    ["PLAYSTYLE_LEARNING_DESC"] = "Afficher les groupes avec le style de jeu Apprentissage.",
    ["PLAYSTYLE_RELAXED_DESC"] = "Afficher les groupes avec le style de jeu Détendu.",
    ["PLAYSTYLE_COMPETITIVE_DESC"] = "Afficher les groupes avec le style de jeu Compétitif.",
    ["PLAYSTYLE_CARRY_DESC"] = "Afficher les groupes proposant un boost.",
    
    -- Roles
    ["HAS_ROLE"] = "A le rôle :",
    ["HAS_TANK"] = "A un tank",
    ["HAS_HEALER"] = "A un soigneur",
    ["HAS_TANK_DESC"] = "Afficher uniquement les groupes qui ont déjà un tank.",
    ["HAS_HEALER_DESC"] = "Afficher uniquement les groupes qui ont déjà un soigneur.",
    }
end
