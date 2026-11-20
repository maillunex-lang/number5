class_name LunexColors
extends RefCounted

## Anime Fantasy / Premium Mobile RPG palette (not purple-default AI look).

const BG_DEEP := Color("0B1220")
const BG_MID := Color("132038")
const BG_PANEL := Color("1A2A45")
const BG_PANEL_ALT := Color("243552")

const GOLD := Color("E8C56A")
const GOLD_DIM := Color("A8893E")
const GOLD_BRIGHT := Color("FFE29A")

const CYAN := Color("5EC8E8")
const TEAL := Color("2A9B8F")
const CRIMSON := Color("C4454A")
const EMERALD := Color("3DBE7A")
const AMBER := Color("E09A3E")

const TEXT_PRIMARY := Color("F4F0E6")
const TEXT_SECONDARY := Color("B8C0D0")
const TEXT_MUTED := Color("7A8499")
const TEXT_DANGER := Color("FF8A8A")

const FRAME_OUTER := Color("3A4A68")
const FRAME_INNER := Color("C9A84C")
const BUTTON_NORMAL := Color("1E334F")
const BUTTON_HOVER := Color("2A4568")
const BUTTON_PRESSED := Color("15263C")
const BUTTON_DISABLED := Color("1A2230")

const NAV_ACTIVE := Color("E8C56A")
const NAV_IDLE := Color("8A94A8")

const HP := Color("E05A5A")
const ENERGY := Color("5B9BE8")
const XP := Color("7BC96A")

const RARITY_COMMON := Color("9AA3B2")
const RARITY_RARE := Color("4A9BE8")
const RARITY_EPIC := Color("B06AE8")
const RARITY_LEGENDARY := Color("E8A84A")

static func rarity(r: String) -> Color:
	match r:
		"rare":
			return RARITY_RARE
		"epic":
			return RARITY_EPIC
		"legendary":
			return RARITY_LEGENDARY
		_:
			return RARITY_COMMON
