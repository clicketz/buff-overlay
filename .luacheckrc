std = "lua51"
max_line_length = false
exclude_files = {
    ".luacheckrc",
    "Libs/",
}
ignore = {
    "11./SLASH_.*", -- slash handler
}
globals = {
    "_G",
    "C_Spell",
    "BuffOverlay",
    "LibStub",
    "GetSpellTexture",
    "GetTime",
    "CompactUnitFrame_UpdateAuras",
    "InCombatLockdown",
    "SlashCmdList",
    "GetCVarBool",
    "CompactRaidFrameManager_GetSetting",
    "CreateFrame",
    "UIParent",
    "IsInRaid",
    "IsInInstance",
    "GetNumGroupMembers",
    "CompactRaidFrameManager",
    "CompactRaidFrameContainer",
    "UnitBuff",
    "BUFF_STACKS_OVERFLOW",
    "CooldownFrame_Set",
    "CooldownFrame_Clear",
    "hooksecurefunc",
    "GetAddOnMetadata",
    "BuffOverlay_GetClasses",
    "CLASS_ICON_TCOORDS",
    "CLASS_SORT_ORDER",
    "MISC",
    "GetSpellInfo",
    "LOCALIZED_CLASS_NAMES_MALE",
    "MAX_CLASSES",
    "Spell",
    "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
    "format",
}
