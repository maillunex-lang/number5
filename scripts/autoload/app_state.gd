extends Node
## Global player / economy stubs. Real server sync comes later.

signal currencies_changed
signal player_changed

var player_name: String = "Guest"
var player_level: int = 1
var gold: int = 12500
var diamonds: int = 320
var logged_in: bool = false

## Placeholder hero roster for Heroes screen.
var heroes: Array[Dictionary] = []

## Placeholder shop packs.
var shop_packs: Array[Dictionary] = []

## Placeholder chat messages.
var chat_messages: Array[Dictionary] = []


func _ready() -> void:
	_seed_stubs()


func login(username: String, _password: String) -> bool:
	var name := username.strip_edges()
	if name.is_empty():
		name = "Commander"
	player_name = name
	logged_in = true
	player_changed.emit()
	return true


func logout() -> void:
	logged_in = false
	player_name = "Guest"
	player_changed.emit()


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	currencies_changed.emit()


func add_diamonds(amount: int) -> void:
	diamonds = maxi(0, diamonds + amount)
	currencies_changed.emit()


func _seed_stubs() -> void:
	heroes = [
		{"id": "h1", "name": "Ashen Knight", "rarity": "Epic", "level": 12, "faction": "Light", "power": 1840},
		{"id": "h2", "name": "Moss Witch", "rarity": "Rare", "level": 10, "faction": "Nature", "power": 1520},
		{"id": "h3", "name": "Iron Howl", "rarity": "Legendary", "level": 15, "faction": "Beast", "power": 2210},
		{"id": "h4", "name": "Cinder Mage", "rarity": "Epic", "level": 11, "faction": "Fire", "power": 1690},
		{"id": "h5", "name": "Tide Guard", "rarity": "Rare", "level": 9, "faction": "Water", "power": 1380},
		{"id": "h6", "name": "Void Seer", "rarity": "Legendary", "level": 14, "faction": "Shadow", "power": 2105},
	]
	shop_packs = [
		{"id": "s1", "title": "Starter Chest", "price": "Free", "desc": "Welcome rewards (stub)"},
		{"id": "s2", "title": "Daily Gems", "price": "99 ₽", "desc": "Small diamond pack"},
		{"id": "s3", "title": "Hero Bundle", "price": "499 ₽", "desc": "Placeholder hero summons"},
		{"id": "s4", "title": "Guild Boost", "price": "199 ₽", "desc": "Guild XP boost (stub)"},
		{"id": "s5", "title": "Mega Pack", "price": "1499 ₽", "desc": "Large currency + scrolls"},
	]
	chat_messages = [
		{"channel": "World", "user": "System", "text": "Welcome to Number5 lobby."},
		{"channel": "World", "user": "AshRunner", "text": "Looking for guild mates!"},
		{"channel": "Guild", "user": "IronHowl", "text": "Boss tonight at 21:00."},
		{"channel": "Guild", "user": "MossWitch", "text": "Need 2 more for raid."},
		{"channel": "World", "user": "Cinder", "text": "Anyone farming chapter 3?"},
	]
