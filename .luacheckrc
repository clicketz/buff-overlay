std = "lua51"
max_line_length = false
exclude_files = {
	"Libs/",
	".luacheckrc"
}
ignore = {
	"11./SLASH_.*", -- slash handler
	"113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
}
globals = {
  "BuffOverlay",
  "LibStub",
  "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
	"WOW_PROJECT_ID",
  "GetSpellTexture",
  "GetTime",
  "CompactUnitFrame_UpdateAuras",
  "InCombatLockdown",
}
