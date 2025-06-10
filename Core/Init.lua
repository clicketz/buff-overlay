local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

Addon:NewModule('Aura')
Addon:NewModule('Bar')
Addon:NewModule('Compatibility')
Addon:NewModule('Constants')
Addon:NewModule('Data')
Addon:NewModule('Database')
Addon:NewModule('Debug')
Addon:NewModule('Event')
Addon:NewModule('Glow')
Addon:NewModule('GUI')
Addon:NewModule('LDB')
Addon:NewModule('Localization')
Addon:NewModule('Options')
Addon:NewModule('Overlay')
Addon:NewModule('Spells')
Addon:NewModule('Test')
Addon:NewModule('Util')

